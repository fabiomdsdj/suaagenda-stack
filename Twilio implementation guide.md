# Integração Twilio - Com Sequelize Migrations

## 1. Migrations Sequelize

### Migration 1: Adicionar campos Twilio em whatsapp_credit_wallets

```javascript
// migrations/YYYYMMDDHHMMSS-add-twilio-fields-to-wallets.js

'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('whatsapp_credit_wallets', 'twilio_account_sid', {
      type: Sequelize.STRING(255),
      allowNull: true,
      after: 'balance'
    });

    await queryInterface.addColumn('whatsapp_credit_wallets', 'twilio_auth_token', {
      type: Sequelize.STRING(255),
      allowNull: true,
      after: 'twilio_account_sid'
    });

    await queryInterface.addColumn('whatsapp_credit_wallets', 'twilio_phone_number', {
      type: Sequelize.STRING(20),
      allowNull: true,
      after: 'twilio_auth_token'
    });

    await queryInterface.addColumn('whatsapp_credit_wallets', 'twilio_whatsapp_number', {
      type: Sequelize.STRING(20),
      allowNull: true,
      after: 'twilio_phone_number'
    });

    await queryInterface.addColumn('whatsapp_credit_wallets', 'twilio_enabled', {
      type: Sequelize.BOOLEAN,
      defaultValue: false,
      allowNull: false,
      after: 'twilio_whatsapp_number'
    });

    // Adicionar índice para performance
    await queryInterface.addIndex('whatsapp_credit_wallets', ['twilio_enabled'], {
      name: 'idx_wallets_twilio_enabled'
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeIndex('whatsapp_credit_wallets', 'idx_wallets_twilio_enabled');
    await queryInterface.removeColumn('whatsapp_credit_wallets', 'twilio_enabled');
    await queryInterface.removeColumn('whatsapp_credit_wallets', 'twilio_whatsapp_number');
    await queryInterface.removeColumn('whatsapp_credit_wallets', 'twilio_phone_number');
    await queryInterface.removeColumn('whatsapp_credit_wallets', 'twilio_auth_token');
    await queryInterface.removeColumn('whatsapp_credit_wallets', 'twilio_account_sid');
  }
};
```

### Migration 2: Criar tabela whatsapp_messages

```javascript
// migrations/YYYYMMDDHHMMSS-create-whatsapp-messages.js

'use strict';

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.createTable('whatsapp_messages', {
      id: {
        type: Sequelize.INTEGER,
        primaryKey: true,
        autoIncrement: true,
        allowNull: false
      },
      tenant_id: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'tenants', // Ajuste se sua tabela tiver outro nome
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
      },
      wallet_id: {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'whatsapp_credit_wallets',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL'
      },
      message_sid: {
        type: Sequelize.STRING(255),
        allowNull: true,
        unique: true
      },
      direction: {
        type: Sequelize.STRING(20),
        allowNull: false,
        comment: 'outbound ou inbound'
      },
      from_number: {
        type: Sequelize.STRING(20),
        allowNull: false
      },
      to_number: {
        type: Sequelize.STRING(20),
        allowNull: false
      },
      body: {
        type: Sequelize.TEXT,
        allowNull: true
      },
      status: {
        type: Sequelize.STRING(50),
        allowNull: false,
        defaultValue: 'queued'
      },
      error_code: {
        type: Sequelize.INTEGER,
        allowNull: true
      },
      error_message: {
        type: Sequelize.TEXT,
        allowNull: true
      },
      message_type: {
        type: Sequelize.STRING(20),
        allowNull: true,
        comment: 'template ou free'
      },
      cost: {
        type: Sequelize.DECIMAL(10, 4),
        allowNull: true
      },
      sent_at: {
        type: Sequelize.DATE,
        allowNull: true
      },
      delivered_at: {
        type: Sequelize.DATE,
        allowNull: true
      },
      created_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      },
      updated_at: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP')
      }
    });

    // Índices para performance
    await queryInterface.addIndex('whatsapp_messages', ['tenant_id'], {
      name: 'idx_wpp_messages_tenant'
    });

    await queryInterface.addIndex('whatsapp_messages', ['message_sid'], {
      name: 'idx_wpp_messages_sid'
    });

    await queryInterface.addIndex('whatsapp_messages', ['status'], {
      name: 'idx_wpp_messages_status'
    });

    await queryInterface.addIndex('whatsapp_messages', ['from_number'], {
      name: 'idx_wpp_messages_from'
    });

    await queryInterface.addIndex('whatsapp_messages', ['to_number'], {
      name: 'idx_wpp_messages_to'
    });

    await queryInterface.addIndex('whatsapp_messages', ['created_at'], {
      name: 'idx_wpp_messages_created'
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeIndex('whatsapp_messages', 'idx_wpp_messages_created');
    await queryInterface.removeIndex('whatsapp_messages', 'idx_wpp_messages_to');
    await queryInterface.removeIndex('whatsapp_messages', 'idx_wpp_messages_from');
    await queryInterface.removeIndex('whatsapp_messages', 'idx_wpp_messages_status');
    await queryInterface.removeIndex('whatsapp_messages', 'idx_wpp_messages_sid');
    await queryInterface.removeIndex('whatsapp_messages', 'idx_wpp_messages_tenant');
    await queryInterface.dropTable('whatsapp_messages');
  }
};
```

### Executar Migrations

```bash
# Criar migrations
npx sequelize-cli migration:generate --name add-twilio-fields-to-wallets
npx sequelize-cli migration:generate --name create-whatsapp-messages

# Copiar o código acima para os arquivos gerados

# Executar
npx sequelize-cli db:migrate

# Reverter (se necessário)
npx sequelize-cli db:migrate:undo
```

---

## 2. Models Atualizados

### Model: WhatsappCreditWallet (atualizado)

```javascript
// models/WhatsappCreditWallet.js
module.exports = (sequelize, DataTypes) => {
  const WhatsappCreditWallet = sequelize.define(
    'WhatsappCreditWallet',
    {
      tenantId: {
        type: DataTypes.INTEGER,
        field: 'tenant_id'
      },
      balance: {
        type: DataTypes.DECIMAL(10, 2)
      },
      
      // 🆕 Campos Twilio
      twilioAccountSid: {
        type: DataTypes.STRING(255),
        field: 'twilio_account_sid',
        allowNull: true
      },
      twilioAuthToken: {
        type: DataTypes.STRING(255),
        field: 'twilio_auth_token',
        allowNull: true
      },
      twilioPhoneNumber: {
        type: DataTypes.STRING(20),
        field: 'twilio_phone_number',
        allowNull: true
      },
      twilioWhatsappNumber: {
        type: DataTypes.STRING(20),
        field: 'twilio_whatsapp_number',
        allowNull: true
      },
      twilioEnabled: {
        type: DataTypes.BOOLEAN,
        defaultValue: false,
        allowNull: false,
        field: 'twilio_enabled'
      }
    },
    {
      tableName: 'whatsapp_credit_wallets',
      underscored: true
    }
  );

  WhatsappCreditWallet.associate = (models) => {
    WhatsappCreditWallet.hasMany(
      models.WhatsappCreditTransaction,
      { foreignKey: 'walletId', as: 'transactions' }
    );
    
    // 🆕 Relacionamento com mensagens
    WhatsappCreditWallet.hasMany(
      models.WhatsappMessage,
      { foreignKey: 'walletId', as: 'messages' }
    );
  };

  return WhatsappCreditWallet;
};
```

### Model: WhatsappMessage (novo)

```javascript
// models/WhatsappMessage.js
module.exports = (sequelize, DataTypes) => {
  const WhatsappMessage = sequelize.define(
    'WhatsappMessage',
    {
      tenantId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        field: 'tenant_id'
      },
      walletId: {
        type: DataTypes.INTEGER,
        allowNull: true,
        field: 'wallet_id'
      },
      messageSid: {
        type: DataTypes.STRING(255),
        unique: true,
        allowNull: true,
        field: 'message_sid'
      },
      direction: {
        type: DataTypes.STRING(20),
        allowNull: false,
        validate: {
          isIn: [['outbound', 'inbound']]
        }
      },
      fromNumber: {
        type: DataTypes.STRING(20),
        allowNull: false,
        field: 'from_number'
      },
      toNumber: {
        type: DataTypes.STRING(20),
        allowNull: false,
        field: 'to_number'
      },
      body: {
        type: DataTypes.TEXT,
        allowNull: true
      },
      status: {
        type: DataTypes.STRING(50),
        allowNull: false,
        defaultValue: 'queued'
      },
      errorCode: {
        type: DataTypes.INTEGER,
        allowNull: true,
        field: 'error_code'
      },
      errorMessage: {
        type: DataTypes.TEXT,
        allowNull: true,
        field: 'error_message'
      },
      messageType: {
        type: DataTypes.STRING(20),
        allowNull: true,
        field: 'message_type',
        comment: 'template ou free'
      },
      cost: {
        type: DataTypes.DECIMAL(10, 4),
        allowNull: true
      },
      sentAt: {
        type: DataTypes.DATE,
        allowNull: true,
        field: 'sent_at'
      },
      deliveredAt: {
        type: DataTypes.DATE,
        allowNull: true,
        field: 'delivered_at'
      }
    },
    {
      tableName: 'whatsapp_messages',
      underscored: true
    }
  );

  WhatsappMessage.associate = (models) => {
    WhatsappMessage.belongsTo(models.WhatsappCreditWallet, {
      foreignKey: 'walletId',
      as: 'wallet'
    });
  };

  return WhatsappMessage;
};
```

---

## 3. Services

### twilioService.js

```javascript
// services/twilioService.js
const twilio = require('twilio');
const { WhatsappCreditWallet } = require('../models');

/**
 * Obter cliente Twilio do tenant
 */
async function getTenantClient(tenantId) {
  const wallet = await WhatsappCreditWallet.findOne({
    where: { 
      tenantId, 
      twilioEnabled: true 
    }
  });

  if (!wallet || !wallet.twilioAccountSid || !wallet.twilioAuthToken) {
    throw new Error('Twilio não configurado para este tenant');
  }

  return {
    client: twilio(wallet.twilioAccountSid, wallet.twilioAuthToken),
    wallet
  };
}

/**
 * Enviar mensagem via Twilio
 */
async function sendMessage(tenantId, to, message) {
  const { client, wallet } = await getTenantClient(tenantId);

  // Formatar número WhatsApp
  const toFormatted = to.startsWith('whatsapp:') ? to : `whatsapp:${to}`;
  const fromFormatted = wallet.twilioWhatsappNumber.startsWith('whatsapp:') 
    ? wallet.twilioWhatsappNumber 
    : `whatsapp:${wallet.twilioWhatsappNumber}`;

  const result = await client.messages.create({
    to: toFormatted,
    from: fromFormatted,
    body: message
  });

  return {
    success: true,
    messageSid: result.sid,
    status: result.status,
    to: result.to,
    from: result.from,
    dateCreated: result.dateCreated
  };
}

/**
 * Buscar status da mensagem
 */
async function getMessageStatus(tenantId, messageSid) {
  const { client } = await getTenantClient(tenantId);
  
  const message = await client.messages(messageSid).fetch();
  
  return {
    sid: message.sid,
    status: message.status,
    errorCode: message.errorCode,
    errorMessage: message.errorMessage,
    price: message.price,
    priceUnit: message.priceUnit
  };
}

/**
 * Validar credenciais Twilio
 */
async function validateCredentials(accountSid, authToken) {
  try {
    const client = twilio(accountSid, authToken);
    await client.api.accounts(accountSid).fetch();
    return { valid: true };
  } catch (error) {
    return { 
      valid: false, 
      error: error.message 
    };
  }
}

module.exports = {
  sendMessage,
  getMessageStatus,
  validateCredentials,
  getTenantClient
};
```

### whatsappService.js (atualizado)

```javascript
// services/whatsappService.js
const { sendMessage } = require('./twilioService');
const { debitWallet, creditWallet } = require('./whatsappCreditService');
const { WhatsappMessage } = require('../models');

/**
 * Tipos de mensagem e custos
 */
const COSTS = {
  template: 0.1925,  // Mensagem com template aprovado
  free: 0.0275,      // Mensagem em janela de 24h
};

/**
 * Enviar WhatsApp com débito de créditos
 */
async function send({
  tenantId,
  to,
  message,
  type = 'free',
  referenceId,
}) {
  const cost = COSTS[type];

  // 1️⃣ Debitar créditos ANTES de enviar
  await debitWallet({
    tenantId,
    amount: cost,
    description: `WhatsApp ${type} para ${to}`,
    referenceId,
  });

  try {
    // 2️⃣ Enviar via Twilio
    const result = await sendMessage(tenantId, to, message);

    // 3️⃣ Registrar mensagem enviada
    const messageRecord = await WhatsappMessage.create({
      tenantId,
      messageSid: result.messageSid,
      direction: 'outbound',
      fromNumber: result.from,
      toNumber: result.to,
      body: message,
      status: result.status,
      messageType: type,
      cost: cost,
      sentAt: new Date()
    });

    return {
      success: true,
      message: messageRecord,
      twilioResponse: result
    };

  } catch (error) {
    // ❌ Se falhar, reembolsar créditos
    await creditWallet({
      tenantId,
      amount: cost,
      description: `Reembolso - falha ao enviar para ${to}`
    });

    throw error;
  }
}

/**
 * Processar mensagem recebida (webhook)
 */
async function processIncoming(webhookData) {
  const { MessageSid, From, To, Body } = webhookData;

  // Identificar tenant pelo número
  const { WhatsappCreditWallet } = require('../models');
  
  const wallet = await WhatsappCreditWallet.findOne({
    where: { 
      twilioWhatsappNumber: To.replace('whatsapp:', '')
    }
  });

  if (!wallet) {
    console.warn('[INCOMING] Tenant não encontrado para número:', To);
    return null;
  }

  // Registrar mensagem recebida
  const message = await WhatsappMessage.create({
    tenantId: wallet.tenantId,
    walletId: wallet.id,
    messageSid: MessageSid,
    direction: 'inbound',
    fromNumber: From,
    toNumber: To,
    body: Body,
    status: 'received',
    messageType: 'incoming',
    cost: 0 // Não cobramos por receber
  });

  return message;
}

/**
 * Atualizar status da mensagem
 */
async function updateMessageStatus({ messageSid, status, errorCode, errorMessage }) {
  const message = await WhatsappMessage.findOne({
    where: { messageSid }
  });

  if (!message) {
    console.warn('[UPDATE STATUS] Mensagem não encontrada:', messageSid);
    return null;
  }

  // Atualizar
  await message.update({
    status,
    errorCode: errorCode || null,
    errorMessage: errorMessage || null,
    deliveredAt: status === 'delivered' ? new Date() : null
  });

  // ✅ Se falhou, reembolsar créditos
  if ((status === 'failed' || status === 'undelivered') && message.cost > 0) {
    await creditWallet({
      tenantId: message.tenantId,
      amount: message.cost,
      description: `Reembolso - mensagem ${messageSid} falhou`
    });
  }

  return message;
}

module.exports = {
  send,
  processIncoming,
  updateMessageStatus,
  COSTS
};
```

---

## 4. Middleware checkWhatsappCredit.js (atualizado)

```javascript
// middlewares/checkWhatsappCredit.js
const { WhatsappCreditWallet } = require('../models');
const { COSTS } = require('../services/whatsappService');

module.exports = async function checkWhatsappCredit(req, res, next) {
  try {
    const tenantId = req.user?.tenantId || req.body.tenantId;
    
    if (!tenantId) {
      return res.status(400).json({ error: 'Tenant não identificado' });
    }

    // Buscar wallet
    const wallet = await WhatsappCreditWallet.findOne({
      where: { tenantId }
    });

    if (!wallet) {
      return res.status(404).json({ error: 'Wallet não encontrada' });
    }

    // ✅ Verificar se Twilio está configurado
    if (!wallet.twilioEnabled) {
      return res.status(400).json({ 
        error: 'Twilio não configurado',
        message: 'Configure suas credenciais Twilio primeiro'
      });
    }

    // ✅ Verificar créditos suficientes
    const messageType = req.body.type || 'free';
    const requiredAmount = COSTS[messageType];

    if (!requiredAmount) {
      return res.status(400).json({ 
        error: 'Tipo de mensagem inválido',
        validTypes: Object.keys(COSTS)
      });
    }

    if (parseFloat(wallet.balance) < requiredAmount) {
      return res.status(402).json({
        error: 'Créditos insuficientes',
        balance: parseFloat(wallet.balance),
        required: requiredAmount
      });
    }

    req.whatsappWallet = wallet;
    next();

  } catch (err) {
    console.error('[CHECK CREDIT]', err);
    return res.status(500).json({ error: 'Erro ao validar crédito' });
  }
};
```

---

## 5. Controllers

### whatsappController.js

```javascript
// controllers/whatsappController.js
const whatsappService = require('../services/whatsappService');
const { WhatsappMessage } = require('../models');
const { Op } = require('sequelize');

class WhatsappController {
  
  /**
   * POST /api/whatsapp/send
   */
  static async sendMessage(req, res) {
    try {
      const { tenantId } = req.user;
      const { to, message, type = 'free', referenceId } = req.body;

      if (!to || !message) {
        return res.status(400).json({ 
          error: 'Campos obrigatórios: to, message' 
        });
      }

      const result = await whatsappService.send({
        tenantId,
        to,
        message,
        type,
        referenceId
      });

      res.json({
        success: true,
        message: result.message,
        messageSid: result.twilioResponse.messageSid
      });

    } catch (error) {
      console.error('[WHATSAPP SEND]', error);
      res.status(500).json({ 
        error: error.message || 'Erro ao enviar mensagem'
      });
    }
  }

  /**
   * GET /api/whatsapp/messages
   */
  static async getMessages(req, res) {
    try {
      const { tenantId } = req.user;
      const { 
        page = 1, 
        limit = 20, 
        direction,
        status,
        search 
      } = req.query;

      const where = { tenantId };
      
      if (direction) where.direction = direction;
      if (status) where.status = status;
      
      if (search) {
        where[Op.or] = [
          { fromNumber: { [Op.like]: `%${search}%` } },
          { toNumber: { [Op.like]: `%${search}%` } },
          { body: { [Op.like]: `%${search}%` } }
        ];
      }

      const { count, rows } = await WhatsappMessage.findAndCountAll({
        where,
        order: [['createdAt', 'DESC']],
        limit: parseInt(limit),
        offset: (page - 1) * limit
      });

      res.json({
        messages: rows,
        pagination: {
          total: count,
          page: parseInt(page),
          limit: parseInt(limit),
          pages: Math.ceil(count / limit)
        }
      });

    } catch (error) {
      console.error('[WHATSAPP LIST]', error);
      res.status(500).json({ error: error.message });
    }
  }

  /**
   * GET /api/whatsapp/messages/:messageSid
   */
  static async getMessageStatus(req, res) {
    try {
      const { tenantId } = req.user;
      const { messageSid } = req.params;

      const message = await WhatsappMessage.findOne({
        where: { tenantId, messageSid }
      });

      if (!message) {
        return res.status(404).json({ error: 'Mensagem não encontrada' });
      }

      // Buscar status atualizado da Twilio
      const twilioService = require('../services/twilioService');
      const twilioStatus = await twilioService.getMessageStatus(
        tenantId, 
        messageSid
      );

      // Atualizar no banco se mudou
      if (twilioStatus.status !== message.status) {
        await whatsappService.updateMessageStatus({
          messageSid,
          status: twilioStatus.status,
          errorCode: twilioStatus.errorCode,
          errorMessage: twilioStatus.errorMessage
        });
      }

      res.json({
        message,
        twilioStatus
      });

    } catch (error) {
      console.error('[WHATSAPP STATUS]', error);
      res.status(500).json({ error: error.message });
    }
  }

  /**
   * GET /api/whatsapp/conversations
   */
  static async getConversations(req, res) {
    try {
      const { tenantId } = req.user;
      const { page = 1, limit = 20 } = req.query;

      // Query para agrupar por contato
      const conversations = await WhatsappMessage.findAll({
        attributes: [
          [sequelize.fn('DISTINCT', sequelize.col('from_number')), 'contact'],
          [sequelize.fn('MAX', sequelize.col('created_at')), 'lastMessageAt'],
          [sequelize.fn('COUNT', sequelize.col('id')), 'messageCount']
        ],
        where: { 
          tenantId,
          direction: 'inbound' 
        },
        group: ['from_number'],
        order: [[sequelize.fn('MAX', sequelize.col('created_at')), 'DESC']],
        limit: parseInt(limit),
        offset: (page - 1) * limit,
        raw: true
      });

      res.json({
        conversations,
        page: parseInt(page),
        limit: parseInt(limit)
      });

    } catch (error) {
      console.error('[CONVERSATIONS]', error);
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = WhatsappController;
```

### twilioConfigController.js

```javascript
// controllers/twilioConfigController.js
const { WhatsappCreditWallet } = require('../models');
const { validateCredentials } = require('../services/twilioService');

class TwilioConfigController {
  
  /**
   * POST /api/twilio/configure
   */
  static async configure(req, res) {
    try {
      const { tenantId } = req.user;
      const { 
        accountSid, 
        authToken, 
        phoneNumber, 
        whatsappNumber 
      } = req.body;

      if (!accountSid || !authToken || !whatsappNumber) {
        return res.status(400).json({ 
          error: 'Campos obrigatórios: accountSid, authToken, whatsappNumber'
        });
      }

      // Validar credenciais
      const validation = await validateCredentials(accountSid, authToken);
      
      if (!validation.valid) {
        return res.status(400).json({ 
          error: 'Credenciais Twilio inválidas',
          details: validation.error
        });
      }

      // Atualizar wallet
      const wallet = await WhatsappCreditWallet.findOne({
        where: { tenantId }
      });

      if (!wallet) {
        return res.status(404).json({ error: 'Wallet não encontrada' });
      }

      await wallet.update({
        twilioAccountSid: accountSid,
        twilioAuthToken: authToken,
        twilioPhoneNumber: phoneNumber,
        twilioWhatsappNumber: whatsappNumber,
        twilioEnabled: true
      });

      res.json({
        success: true,
        message: 'Twilio configurado com sucesso',
        config: {
          twilioEnabled: true,
          phoneNumber: wallet.twilioPhoneNumber,
          whatsappNumber: wallet.twilioWhatsappNumber
        }
      });

    } catch (error) {
      console.error('[TWILIO CONFIG]', error);
      res.status(500).json({ error: error.message });
    }
  }

  /**
   * GET /api/twilio/config
   */
  static async getConfig(req, res) {
    try {
      const { tenantId } = req.user;

      const wallet = await WhatsappCreditWallet.findOne({
        where: { tenantId },
        attributes: [
          'twilioEnabled', 
          'twilioPhoneNumber', 
          'twilioWhatsappNumber'
        ]
      });

      if (!wallet) {
        return res.status(404).json({ error: 'Wallet não encontrada' });
      }

      res.json({
        configured: wallet.twilioEnabled || false,
        phoneNumber: wallet.twilioPhoneNumber,
        whatsappNumber: wallet.twilioWhatsappNumber
      });

    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }

  /**
   * DELETE /api/twilio/configure
   */
  static async remove(req, res) {
    try {
      const { tenantId } = req.user;

      const wallet = await WhatsappCreditWallet.findOne({
        where: { tenantId }
      });

      if (!wallet) {
        return res.status(404).json({ error: 'Wallet não encontrada' });
      }

      await wallet.update({
        twilioAccountSid: null,
        twilioAuthToken: null,
        twilioPhoneNumber: null,
        twilioWhatsappNumber: null,
        twilioEnabled: false
      });

      res.json({
        success: true,
        message: 'Configuração Twilio removida'
      });

    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
}

module.exports = TwilioConfigController;
```

### webhookController.js

```javascript
// controllers/webhookController.js
const twilio = require('twilio');
const whatsappService = require('../services/whatsappService');

class WebhookController {
  
  /**
   * POST /webhooks/twilio/status
   */
  static async handleStatus(req, res) {
    try {
      // Validar assinatura Twilio
      const twilioSignature = req.headers['x-twilio-signature'];
      const url = `${process.env.API_URL}${req.originalUrl}`;
      
      const isValid = twilio.validateRequest(
        process.env.TWILIO_AUTH_TOKEN,
        twilioSignature,
        url,
        req.body
      );

      if (!isValid) {
        console.warn('[WEBHOOK] Assinatura inválida');
        return res.status(403).send('Forbidden');
      }

      const { 
        MessageSid, 
        MessageStatus, 
        ErrorCode, 
        ErrorMessage 
      } = req.body;

      // Atualizar status
      await whatsappService.updateMessageStatus({
        messageSid: MessageSid,
        status: MessageStatus,
        errorCode: ErrorCode,
        errorMessage: ErrorMessage
      });

      res.status(200).send('OK');

    } catch (error) {
      console.error('[WEBHOOK STATUS]', error);
      res.status(500).send('Error');
    }
  }

  /**
   * POST /webhooks/twilio/incoming
   */
  static async handleIncoming(req, res) {
    try {
      const twilioSignature = req.headers['x-twilio-signature'];
      const url = `${process.env.API_URL}${req.originalUrl}`;
      
      const isValid = twilio.validateRequest(
        process.env.TWILIO_AUTH_TOKEN,
        twilioSignature,
        url,
        req.body
      );

      if (!isValid) {
        console.warn('[WEBHOOK] Assinatura inválida');
        return res.status(403).send('Forbidden');
      }

      // Processar mensagem recebida
      await whatsappService.processIncoming(req.body);

      // Responder à Twilio
      res.type('text/xml');
      res.send('<Response></Response>');

    } catch (error) {
      console.error('[WEBHOOK INCOMING]', error);
      res.status(500).send('Error');
    }
  }
}

module.exports = WebhookController;
```

---

## 6. Routes

```javascript
// routes/whatsapp.js
const express = require('express');
const router = express.Router();
const WhatsappController = require('../controllers/whatsappController');
const TwilioConfigController = require('../controllers/twilioConfigController');
const WebhookController = require('../controllers/webhookController');
const checkWhatsappCredit = require('../middlewares/checkWhatsappCredit');
const { authenticateToken } = require('../middlewares/auth');

// 🔒 Configuração Twilio
router.post('/twilio/configure', authenticateToken, TwilioConfigController.configure);
router.get('/twilio/config', authenticateToken, TwilioConfigController.getConfig);
router.delete('/twilio/configure', authenticateToken, TwilioConfigController.remove);

// 🔒 Mensagens
router.post('/send', authenticateToken, checkWhatsappCredit, WhatsappController.sendMessage);
router.get('/messages', authenticateToken, WhatsappController.getMessages);
router.get('/messages/:messageSid', authenticateToken, WhatsappController.getMessageStatus);
router.get('/conversations', authenticateToken, WhatsappController.getConversations);

// 🌐 Webhooks (públicos)
router.post('/webhooks/status', WebhookController.handleStatus);
router.post('/webhooks/incoming', WebhookController.handleIncoming);

module.exports = router;
```

---

## 7. Registrar Routes no App

```javascript
// app.js ou server.js
const whatsappRoutes = require('./routes/whatsapp');

app.use('/api/whatsapp', whatsappRoutes);
```

---

## 8. Comandos Sequelize CLI

```bash
# Criar migrations
npx sequelize-cli migration:generate --name add-twilio-fields-to-wallets
npx sequelize-cli migration:generate --name create-whatsapp-messages

# Executar migrations
npx sequelize-cli db:migrate

# Verificar status
npx sequelize-cli db:migrate:status

# Reverter última migration
npx sequelize-cli db:migrate:undo

# Reverter todas
npx sequelize-cli db:migrate:undo:all

# Reverter até migration específica
npx sequelize-cli db:migrate:undo --name YYYYMMDDHHMMSS-create-whatsapp-messages.js
```

---

## 9. Exemplo de Uso - Frontend

```javascript
// 1️⃣ Configurar Twilio
async function configureTwilio(credentials) {
  const response = await fetch('/api/whatsapp/twilio/configure', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({
      accountSid: 'ACxxxxx...',
      authToken: 'your_token',
      phoneNumber: '+5511999999999',
      whatsappNumber: '+5511999999999'
    })
  });
  return await response.json();
}

// 2️⃣ Enviar mensagem
async function sendMessage(to, message, type = 'free') {
  const response = await fetch('/api/whatsapp/send', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify({ to, message, type })
  });
  return await response.json();
}

// 3️⃣ Listar mensagens
async function getMessages(filters = {}) {
  const params = new URLSearchParams(filters);
  const response = await fetch(`/api/whatsapp/messages?${params}`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  return await response.json();
}

// 4️⃣ Conversas
async function getConversations() {
  const response = await fetch('/api/whatsapp/conversations', {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  return await response.json();
}
```

---

## 10. Variáveis de Ambiente

```bash
# .env

# API
API_URL=https://seu-dominio.com
PORT=3000

# Database
DB_HOST=localhost
DB_NAME=seu_db
DB_USER=postgres
DB_PASSWORD=postgres
DB_DIALECT=postgres

# Twilio (para validação de webhooks)
TWILIO_AUTH_TOKEN=seu_token_master

# JWT
JWT_SECRET=seu_secret
```

---

## 11. Checklist de Implementação

- [ ] Instalar dependência: `npm install twilio`
- [ ] Criar migration 1: add-twilio-fields-to-wallets
- [ ] Criar migration 2: create-whatsapp-messages
- [ ] Executar: `npx sequelize-cli db:migrate`
- [ ] Atualizar model WhatsappCreditWallet
- [ ] Criar model WhatsappMessage
- [ ] Criar twilioService.js
- [ ] Atualizar whatsappService.js
- [ ] Atualizar checkWhatsappCredit.js
- [ ] Criar WhatsappController
- [ ] Criar TwilioConfigController
- [ ] Criar WebhookController
- [ ] Criar routes
- [ ] Registrar routes no app
- [ ] Configurar webhooks no Twilio Console
- [ ] Testar configuração
- [ ] Testar envio
- [ ] Testar webhooks

---

## 12. Estrutura Final de Arquivos

```
backend/
├── migrations/
│   ├── YYYYMMDD-add-twilio-fields-to-wallets.js
│   └── YYYYMMDD-create-whatsapp-messages.js
├── models/
│   ├── WhatsappCreditWallet.js (atualizado)
│   ├── WhatsappCreditTransaction.js (existente)
│   └── WhatsappMessage.js (novo)
├── services/
│   ├── twilioService.js (novo)
│   ├── whatsappService.js (atualizado)
│   └── whatsappCreditService.js (existente)
├── controllers/
│   ├── whatsappController.js (novo)
│   ├── twilioConfigController.js (novo)
│   └── webhookController.js (novo)
├── middlewares/
│   └── checkWhatsappCredit.js (atualizado)
└── routes/
    └── whatsapp.js (novo)
```

---

Pronto! Agora com **Sequelize Migrations** completas e código production-ready! 🚀