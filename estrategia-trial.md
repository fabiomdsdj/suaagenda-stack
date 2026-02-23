# 🎯 ESTRATÉGIAS DE TRIAL - BOAS PRÁTICAS

## 📊 Opção 1: Trial como PLANO separado (✅ RECOMENDADO)

### Estrutura:
```sql
-- Tabela plans
INSERT INTO plans (id, name, price, isTrial) VALUES
(0, 'Trial', 0.00, true),      -- ← Plano Trial
(1, 'Básico', 29.90, false),
(2, 'Premium', 79.90, false),
(3, 'Enterprise', 199.90, false);

-- Tabela plan_features
-- Trial tem limites BAIXOS para incentivar upgrade
INSERT INTO plan_features ("planId", "featureId", value) VALUES
(0, 1, '2'),          -- max_users: 2
(0, 2, '5'),          -- max_services: 5
(0, 3, '10'),         -- max_contacts: 10
(0, 4, '10');         -- max_appointments: 10

-- Signatures
-- Quando criar tenant, já cria com Trial
INSERT INTO signatures ("tenantId", "planId", "isActive", start, end) VALUES
(1, 0, true, '2024-01-01', '2024-01-15'); -- ← 15 dias de trial
```

### ✅ Vantagens:
- **Simples de implementar** - Usa a mesma estrutura de planos
- **Fácil de gerenciar** - Trial aparece em relatórios junto com outros planos
- **Controle de features** - Define limites específicos pro trial
- **Upgrade natural** - Quando trial vence, só precisa atualizar planId
- **Transparente** - Usuário vê claramente que está em trial

### ❌ Desvantagens:
- Plano "0" pode confundir relatórios de receita
- Precisa sempre verificar se não é trial em algumas lógicas

---

## 📊 Opção 2: Trial como COLUNA na Signature (Alternativa)

### Estrutura:
```sql
-- Adiciona colunas na tabela signatures
ALTER TABLE signatures 
ADD COLUMN "isTrial" BOOLEAN DEFAULT false,
ADD COLUMN "trialEndsAt" TIMESTAMP;

-- Quando criar tenant novo
INSERT INTO signatures ("tenantId", "planId", "isActive", "isTrial", start, "trialEndsAt") VALUES
(1, 1, true, true, '2024-01-01', '2024-01-15'); -- ← Básico com trial
```

### ✅ Vantagens:
- Não "polui" a tabela de planos
- Trial não aparece em relatórios de planos
- Usuário já está no plano que vai pagar depois

### ❌ Desvantagens:
- Mais complexo de implementar
- Precisa lógica adicional em vários lugares
- Difícil aplicar limites diferentes durante trial

---

## 🏆 RECOMENDAÇÃO: Opção 1 (Trial como Plano)

Baseado em empresas grandes (Notion, Slack, GitHub):

```
┌─────────────────────────────────────────────────┐
│ ESTRATÉGIA RECOMENDADA: Trial como Plano 0     │
└─────────────────────────────────────────────────┘

1️⃣ Usuário se cadastra
   → Cria Tenant
   → Cria Signature com planId: 0 (Trial)
   → Define end: hoje + 15 dias

2️⃣ Durante Trial (15 dias)
   → Usa o sistema com limites baixos
   → Vê banners "Faltam X dias do trial"
   → Recebe emails incentivando upgrade

3️⃣ Trial vencendo (últimos 3 dias)
   → Modal: "Seu trial acaba em 3 dias!"
   → Botão destacado: "Escolher Plano"

4️⃣ Trial venceu (dia 16)
   → Signature.isActive = false
   → Bloqueia acesso ao sistema
   → Redireciona para /checkout
   → Dados ficam salvos (não deleta nada)

5️⃣ Usuário escolhe plano e paga
   → Cria NOVA Signature com planId: 1/2/3
   → Signature antiga (trial) fica no histórico
   → Libera acesso total
```

---

## 💻 IMPLEMENTAÇÃO PRÁTICA

### 1️⃣ Migration - Adicionar coluna isTrial

```javascript
// migrations/XXXX-add-isTrial-to-plans.js
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('plans', 'isTrial', {
      type: Sequelize.BOOLEAN,
      defaultValue: false,
      allowNull: false
    });
    
    await queryInterface.addColumn('plans', 'trialDays', {
      type: Sequelize.INTEGER,
      defaultValue: 0,
      allowNull: false
    });
  },
  
  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn('plans', 'isTrial');
    await queryInterface.removeColumn('plans', 'trialDays');
  }
};
```

### 2️⃣ Seed - Criar Plano Trial

```javascript
// seeders/XXXX-plans.js
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.bulkInsert('plans', [
      {
        id: 0,
        name: 'Trial',
        description: 'Teste grátis por 15 dias',
        price: 0.00,
        isTrial: true,
        trialDays: 15,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        id: 1,
        name: 'Básico',
        description: 'Para começar',
        price: 29.90,
        isTrial: false,
        trialDays: 0,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      // ... outros planos
    ]);
    
    // Features do Trial (limites baixos)
    await queryInterface.bulkInsert('plan_features', [
      { planId: 0, featureId: 1, value: '2', createdAt: new Date(), updatedAt: new Date() },   // 2 users
      { planId: 0, featureId: 2, value: '5', createdAt: new Date(), updatedAt: new Date() },   // 5 services
      { planId: 0, featureId: 3, value: '10', createdAt: new Date(), updatedAt: new Date() },  // 10 contacts
      { planId: 0, featureId: 4, value: '20', createdAt: new Date(), updatedAt: new Date() },  // 20 appointments
    ]);
  }
};
```

### 3️⃣ Ao Criar Tenant - Já cria com Trial

```javascript
// controllers/TenantController.js
async function createTenant(req, res) {
  const transaction = await sequelize.transaction();
  
  try {
    // 1. Cria o tenant
    const tenant = await Tenant.create({
      name: req.body.companyName,
      // ... outros dados
    }, { transaction });
    
    // 2. Cria usuário admin do tenant
    const user = await User.create({
      tenantId: tenant.id,
      name: req.body.name,
      email: req.body.email,
      // ... outros dados
    }, { transaction });
    
    // 3. 🎯 CRIA ASSINATURA TRIAL AUTOMATICAMENTE
    const trialPlan = await Plan.findOne({ where: { isTrial: true } });
    
    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + trialPlan.trialDays); // +15 dias
    
    await Signature.create({
      tenantId: tenant.id,
      planId: trialPlan.id, // 0 (Trial)
      isActive: true,
      start: startDate,
      end: endDate // ← Trial vence em 15 dias
    }, { transaction });
    
    await transaction.commit();
    
    return res.status(201).json({
      message: 'Conta criada! Você tem 15 dias de trial grátis.',
      tenant,
      user,
      trialEndsAt: endDate
    });
    
  } catch (error) {
    await transaction.rollback();
    return res.status(500).json({ error: error.message });
  }
}
```

### 4️⃣ Middleware - Verificar se Trial venceu

```javascript
// middlewares/checkTrialExpired.js
const { Signature, Plan } = require('../models');
const { Op } = require('sequelize');

module.exports = async function checkTrialExpired(req, res, next) {
  try {
    const tenantId = req.user?.tenantId;
    
    if (!tenantId) {
      return res.status(401).json({ error: 'Não autenticado' });
    }
    
    // Busca assinatura ativa
    const signature = await Signature.findOne({
      where: {
        tenantId,
        isActive: true
      },
      include: {
        model: Plan,
        as: 'plan'
      }
    });
    
    if (!signature) {
      return res.status(403).json({ 
        error: 'Nenhuma assinatura ativa',
        code: 'NO_ACTIVE_SUBSCRIPTION',
        redirectTo: '/checkout'
      });
    }
    
    // Se é trial e venceu
    if (signature.plan.isTrial && signature.end) {
      const now = new Date();
      const trialEnd = new Date(signature.end);
      
      if (now > trialEnd) {
        // Desativa o trial
        await signature.update({ isActive: false });
        
        return res.status(403).json({ 
          error: 'Seu período de trial expirou',
          code: 'TRIAL_EXPIRED',
          redirectTo: '/checkout',
          trialEndedAt: signature.end
        });
      }
      
      // Trial ainda válido, adiciona info no request
      const daysLeft = Math.ceil((trialEnd - now) / (1000 * 60 * 60 * 24));
      req.trialInfo = {
        isTrial: true,
        daysLeft,
        endsAt: signature.end
      };
    }
    
    next();
  } catch (error) {
    console.error('Erro ao verificar trial:', error);
    res.status(500).json({ error: 'Erro interno' });
  }
};
```

### 5️⃣ Frontend - Banner de Trial

```vue
<!-- components/TrialBanner.vue -->
<template>
  <div v-if="isTrial" class="bg-amber-50 border-b border-amber-200 p-4">
    <div class="max-w-7xl mx-auto flex items-center justify-between">
      <div class="flex items-center gap-2">
        <Icon name="heroicons:clock" class="h-5 w-5 text-amber-600" />
        <span class="text-sm text-amber-800">
          <strong>Trial:</strong> 
          {{ daysLeft }} {{ daysLeft === 1 ? 'dia' : 'dias' }} restantes
        </span>
      </div>
      <button
        @click="$router.push('/checkout')"
        class="bg-amber-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-amber-700"
      >
        Escolher Plano
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useSignatures } from '@/stores/useSignatures'

const signaturesStore = useSignatures()

const isTrial = computed(() => {
  return signaturesStore.currentSignature?.plan?.isTrial || false
})

const daysLeft = computed(() => {
  if (!signaturesStore.currentSignature?.end) return 0
  
  const now = new Date()
  const end = new Date(signaturesStore.currentSignature.end)
  const diff = end.getTime() - now.getTime()
  
  return Math.ceil(diff / (1000 * 60 * 60 * 24))
})
</script>
```

### 6️⃣ Cron Job - Desativar trials vencidos

```javascript
// jobs/deactivateExpiredTrials.js
const { Signature, Plan } = require('../models');
const { Op } = require('sequelize');

async function deactivateExpiredTrials() {
  try {
    console.log('🔍 Verificando trials expirados...');
    
    const expiredTrials = await Signature.findAll({
      where: {
        isActive: true,
        end: {
          [Op.lte]: new Date() // end <= hoje
        }
      },
      include: {
        model: Plan,
        as: 'plan',
        where: { isTrial: true }
      }
    });
    
    console.log(`📊 Encontrados ${expiredTrials.length} trials expirados`);
    
    for (const signature of expiredTrials) {
      await signature.update({ isActive: false });
      console.log(`❌ Trial desativado: Signature #${signature.id}`);
      
      // TODO: Enviar email notificando
      // await sendTrialExpiredEmail(signature.tenantId);
    }
    
    console.log('✅ Job concluído');
  } catch (error) {
    console.error('❌ Erro ao desativar trials:', error);
  }
}

// Executar a cada 1 hora
setInterval(deactivateExpiredTrials, 60 * 60 * 1000);

module.exports = deactivateExpiredTrials;
```

---

## 🎯 FLUXO COMPLETO DO USUÁRIO

```
┌────────────────────────────────────────────────────────┐
│ DIA 0: CADASTRO                                        │
├────────────────────────────────────────────────────────┤
│ ✅ Preenche formulário                                 │
│ ✅ Cria conta (Tenant + User)                          │
│ ✅ Sistema cria Signature com planId: 0 (Trial)        │
│ ✅ end = hoje + 15 dias                                │
│ ✅ Acessa sistema completo (com limites baixos)        │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ DIA 1-12: USANDO O TRIAL                               │
├────────────────────────────────────────────────────────┤
│ 🔔 Banner discreto: "Trial - 14 dias restantes"        │
│ ⚠️ Limites baixos (2 users, 5 services, etc)          │
│ 📧 Email dia 7: "Metade do trial, gostando?"          │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ DIA 13-15: TRIAL TERMINANDO                            │
├────────────────────────────────────────────────────────┤
│ 🚨 Banner vermelho: "3 dias restantes!"               │
│ 🔔 Modal ao login: "Trial acabando - Escolha um plano"│
│ 📧 Email diário lembrando                              │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ DIA 16: TRIAL EXPIROU                                  │
├────────────────────────────────────────────────────────┤
│ ❌ Middleware bloqueia acesso                          │
│ 🚫 Signature.isActive = false                          │
│ 🔀 Redirect automático para /checkout                  │
│ 💾 Dados ficam salvos (não deleta nada!)              │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ CONVERSÃO: ESCOLHE PLANO PAGO                          │
├────────────────────────────────────────────────────────┤
│ 💳 Preenche dados do cartão                            │
│ 💰 Processa pagamento                                   │
│ ✅ Cria NOVA Signature com planId: 1/2/3              │
│ ✅ Libera acesso total                                 │
│ 🎉 Todos os dados do trial continuam disponíveis       │
└────────────────────────────────────────────────────────┘
```

---

## 📊 COMPARAÇÃO COM OUTRAS EMPRESAS

| Empresa | Estratégia |
|---------|-----------|
| **Notion** | Trial como plano - 15 dias grátis |
| **Slack** | Trial como plano - Até 10 users grátis sempre |
| **GitHub** | Plano Free permanente + Planos pagos |
| **Stripe** | Trial opcional em qualquer plano |
| **Zoom** | Plano Free permanente com limites |

**Nossa recomendação:** Trial como plano separado (igual Notion)

---

## ✅ CHECKLIST DE IMPLEMENTAÇÃO

- [ ] Criar migration adicionando `isTrial` e `trialDays` na tabela `plans`
- [ ] Criar seed do plano Trial (id: 0)
- [ ] Definir features do trial (limites baixos)
- [ ] Modificar criação de Tenant para criar Signature com Trial
- [ ] Criar middleware `checkTrialExpired`
- [ ] Criar componente `TrialBanner.vue`
- [ ] Criar cron job para desativar trials vencidos
- [ ] Criar emails de notificação (dia 7, dia 13, dia 15, expirou)
- [ ] Criar página de checkout amigável
- [ ] Testar fluxo completo

---

## 🎁 BÔNUS: Permitir extensão de trial

```javascript
// routes/trial.routes.js
router.post('/trial/extend',
  passport.authenticate('jwt', cfg.jwtSession),
  async (req, res) => {
    const signature = await Signature.findOne({
      where: { tenantId: req.user.tenantId, isActive: true },
      include: { model: Plan, as: 'plan' }
    });
    
    if (!signature.plan.isTrial) {
      return res.status(400).json({ error: 'Não está em trial' });
    }
    
    // Estende por mais 7 dias (uma vez só)
    const newEnd = new Date(signature.end);
    newEnd.setDate(newEnd.getDate() + 7);
    
    await signature.update({ end: newEnd });
    
    return res.json({ 
      message: 'Trial estendido por mais 7 dias!',
      newEndDate: newEnd
    });
  }
);
```