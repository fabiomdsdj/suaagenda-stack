  // =========================================================================
  // B3.6 — ESTORNO
  // =========================================================================

  /**
   * Reverte a comissão de um pagamento estornado (PAYMENT_REFUNDED /
   * PAYMENT_DELETED do Asaas).
   *
   * O razão é APPEND-ONLY: o crédito original nunca é apagado nem alterado.
   * Para cada crédito daquele pagamento é lançado um `reversal` espelhado —
   * mesma faixa, mesmas unidades, mesma memória de cálculo — com
   * `baseAmount` e `amount` negativos e `reversalOfId` apontando para o
   * crédito. Assim:
   *
   *   consumedUnits = SUM(credit.unitsCovered) - SUM(reversal.unitsCovered)
   *
   * volta sozinho ao valor anterior ao crédito, sem contador novo e sem tocar
   * em `paidInstallments` (aposentado), em terms ou em tiers.
   *
   * IDEMPOTÊNCIA: o mesmo refund pode chegar várias vezes. A proteção é
   * dupla — o pré-check por `reversalOfId` e, contra corrida real, a unique
   * (salesAgentCommissionId, paymentId, termId, entryType), que só admite UM
   * reversal por contrato+pagamento+faixa. O schema atual não tem coluna para
   * o id do EVENTO de refund, então dois refunds distintos do mesmo pagamento
   * (parciais, por exemplo) são indistinguíveis: o segundo é tratado como
   * reentrega do primeiro. Registrado como pendência, sem migration agora.
   *
   * @param {string} subscriptionId asaasId da Signature
   * @param {string} paymentId      payment.id do Asaas que foi estornado
   * @param {import('sequelize').Transaction} transaction transação do caller
   */
  async function reverseCommissionFromRefund(subscriptionId, paymentId, transaction) {
    if (!subscriptionId || !paymentId) return;

    const context = { subscriptionId, paymentId, flow: 'refund' };

    try {
      const signature = await Signature.findOne({
        where: { asaasId: subscriptionId },
        transaction,
      });

      if (!signature) return;

      context.tenantId = signature.tenantId;

      // paymentId NÃO é identidade de contrato: o mesmo pagamento pode ter
      // gerado lançamentos em contratos de OUTRAS assinaturas. O estorno fica
      // restrito aos contratos desta assinatura (hoje só `direct`; amanhã o
      // override entra aqui naturalmente, cada contrato revertido por si).
      const contracts = await SalesAgentCommission.findAll({
        where: { signatureId: signature.id },
        transaction,
      });

      if (contracts.length === 0) return;

      const contractIds = contracts.map((c) => c.id);

      const credits = await SalesAgentCommissionInstallment.findAll({
        where: {
          salesAgentCommissionId: contractIds,
          paymentId,
          entryType: 'credit',
        },
        order: [['installmentNumber', 'ASC']],
        transaction,
      });

      // Refund de pagamento que nunca gerou comissão (recarga wallet, tenant
      // sem agente, contrato esgotado): no-op silencioso, não é erro.
      if (credits.length === 0) {
        logger.info('[commission] refund sem crédito de comissão — nada a estornar', {
          ...context,
        });
        return;
      }

      const existingReversals = await SalesAgentCommissionInstallment.findAll({
        where: {
          salesAgentCommissionId: contractIds,
          paymentId,
          entryType: 'reversal',
        },
        attributes: ['id', 'reversalOfId'],
        transaction,
      });

      const alreadyReversed = new Set(
        existingReversals.map((r) => r.reversalOfId).filter(Boolean),
      );

      const pending = credits.filter((credit) => !alreadyReversed.has(credit.id));

      if (pending.length === 0) {
        logger.info('[commission] refund já estornado — ignorando reentrega', { ...context });
        return;
      }

      // installmentNumber é ordinal por CONTRATO — cada um continua a sua
      // própria sequência.
      const nextNumber = new Map();
      for (const contractId of new Set(pending.map((c) => c.salesAgentCommissionId))) {
        nextNumber.set(contractId, await nextInstallmentNumber(contractId, transaction));
      }

      let written = 0;

      for (const credit of pending) {
        const contractId = credit.salesAgentCommissionId;
        const installmentNumber = nextNumber.get(contractId);

        try {
          await SalesAgentCommissionInstallment.create(
            {
              salesAgentCommissionId: contractId,
              termId: credit.termId,
              paymentId: credit.paymentId,
              // Memória financeira preservada: o reversal conta a mesma
              // história do crédito, com o sinal trocado.
              paymentDate: credit.paymentDate,
              billingCycle: credit.billingCycle,
              unitFrom: credit.unitFrom,
              unitTo: credit.unitTo,
              // POSITIVO de propósito: quem subtrai é o entryType, em
              // consumedUnitsFor(). Unidades negativas somariam duas vezes.
              unitsCovered: credit.unitsCovered,
              baseAmount: negateAmount(credit.baseAmount, context),
              percentApplied: credit.percentApplied,
              amount: negateAmount(credit.amount, context),
              installmentNumber,
              referenceMonth: credit.referenceMonth,
              entryType: 'reversal',
              reversalOfId: credit.id,
              status: 'pending',
              // LEGADO: `dueDate` é NOT NULL (ver nota no caminho de crédito).
              // Copiado do crédito para não inventar data nova.
              dueDate: credit.dueDate,
            },
            { transaction },
          );

          nextNumber.set(contractId, installmentNumber + 1);
          written += 1;
        } catch (error) {
          // Corrida: outra execução do mesmo refund já gravou ESTE reversal.
          // A unique decide o vencedor; o perdedor reconhece a duplicidade e
          // segue — cada reversal é independente dos demais, então não há
          // estado parcial para propagar.
          if (isUniqueViolation(error)) {
            logger.warn('[commission] corrida no estorno — reversal já lançado', {
              ...context,
              salesAgentCommissionId: contractId,
              creditId: credit.id,
            });
            continue;
          }
          throw error;
        }
      }

      // Contrato `completed` que volta a ter unidades livres NÃO é reativado
      // aqui: status é projeção de consumedUnits e quem a recalcula é o
      // caminho de crédito, no próximo pagamento (que agora encontra
      // remaining > 0 e devolve o contrato para `active`). Estornar não é
      // vender — reativar em silêncio inventaria regra que o modelo não tem.
      for (const contract of contracts) {
        if (contract.status !== 'completed') continue;
        if (contract.totalUnits === null || contract.totalUnits === undefined) continue;

        const consumed = await consumedUnitsFor(contract.id, transaction);
        if (consumed < contract.totalUnits) {
          logger.warn(
            '[commission] contrato completed voltou a ter unidades livres após estorno — '
            + 'status será recalculado no próximo pagamento',
            {
              ...context,
              salesAgentCommissionId: contract.id,
              totalUnits: contract.totalUnits,
              consumedUnits: consumed,
            },
          );
        }
      }

      logger.info('[commission] comissão estornada', {
        ...context,
        credits: credits.length,
        reversals: written,
      });
    } catch (error) {
      // Mesma política do crédito: estorno que falha precisa aparecer.
      logger.error('[commission] falha ao estornar comissão', {
        subscriptionId,
        paymentId,
        tenantId: context.tenantId,
        error: error.message,
      });
      throw error;
    }
  }

  return { processCommissionFromPayment, reverseCommissionFromRefund };
