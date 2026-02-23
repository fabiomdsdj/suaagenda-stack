# 🔐 Autenticação Socket.io - Adaptado para seu Passport JWT

## ✅ Você já tem:

- Passport JWT configurado
- `jwtSecret` em `config/config.js`
- Estratégia JWT que busca `User` por `jwtPayload.id`

## 🚀 Implementação Simplificada

---

## PASSO 1: Criar Middleware Socket.io

**📁 Arquivo:** `backend/src/middlewares/socketAuth.js`

```javascript
const jwt = require('jsonwebtoken');
const { jwtSecret } = require('../../config/config');
const { User } = require('../models');

/**
 * Middleware de autenticação Socket.io
 * Reutiliza a mesma lógica do Passport JWT
 */
async function socketAuthMiddleware(socket, next) {
  try {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🔐 [SOCKET AUTH] Verificando autenticação...');
    console.log(`   Socket ID: ${socket.id}`);
    
    // 1️⃣ Extrair token (mesmo formato que o Passport: "Bearer token")
    let token = socket.handshake.auth?.token;
    
    // Também aceitar do header Authorization
    if (!token && socket.handshake.headers?.authorization) {
      const authHeader = socket.handshake.headers.authorization;
      if (authHeader.startsWith('Bearer ')) {
        token = authHeader.substring(7); // Remove "Bearer "
      }
    }
    
    if (!token) {
      console.error('❌ [SOCKET AUTH] Token não fornecido');
      return next(new Error('Authentication error: Token não fornecido'));
    }
    
    console.log('   Token recebido ✓');
    
    // 2️⃣ Verificar token (mesma lógica do Passport)
    const jwtPayload = jwt.verify(token, jwtSecret);
    console.log(`   Token válido - User ID: ${jwtPayload.id}`);
    
    // 3️⃣ Buscar usuário (exatamente como o Passport faz)
    const user = await User.findOne({
      where: {
        id: jwtPayload.id
      }
    });
    
    if (!user) {
      console.error('❌ [SOCKET AUTH] Usuário não encontrado');
      return next(new Error('Authentication error: Usuário não encontrado'));
    }
    
    console.log(`✅ [SOCKET AUTH] Usuário autenticado: ${user.email || user.id}`);
    console.log(`   User ID: ${user.id}`);
    console.log(`   Tenant ID: ${user.tenantId}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // 4️⃣ Adicionar user ao socket (igual req.user do Passport)
    socket.user = user;
    
    // 5️⃣ Permitir conexão
    next();
    
  } catch (err) {
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.error('❌ [SOCKET AUTH] Erro de autenticação');
    console.error(`   Erro: ${err.message}`);
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    if (err.name === 'JsonWebTokenError') {
      return next(new Error('Authentication error: Token inválido'));
    }
    if (err.name === 'TokenExpiredError') {
      return next(new Error('Authentication error: Token expirado'));
    }
    
    return next(new Error('Authentication error: Erro de autenticação'));
  }
}

module.exports = socketAuthMiddleware;
```

---

## PASSO 2: Aplicar Middleware no Socket.io

**📁 Arquivo:** `backend/socket.js`

```javascript
const { Server } = require('socket.io');
const { instrument } = require('@socket.io/admin-ui');
const socketAuthMiddleware = require('./src/middlewares/socketAuth');

let io;

function initSocket(server) {
  console.log('🔄 Inicializando Socket.io...');
  
  io = new Server(server, {
    path: '/socket.io/',
    cors: {
      origin: process.env.FRONTEND_URL || true, // ⚠️ Usar env var em produção
      methods: ["GET", "POST"],
      credentials: true
    },
    transports: ['polling', 'websocket'],
    allowEIO3: true,
    pingTimeout: 60000,
    pingInterval: 25000,
  });

  // 🔐 APLICAR MIDDLEWARE DE AUTENTICAÇÃO
  io.use(socketAuthMiddleware);

  // Admin UI (só em dev)
  if (process.env.NODE_ENV !== 'production') {
    instrument(io, { auth: false });
    console.log('🎛️ Admin UI: https://admin.socket.io');
  }

  io.on('connection', (socket) => {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('🎉 Cliente CONECTADO (Autenticado)');
    console.log(`   Socket ID: ${socket.id}`);
    console.log(`   User ID: ${socket.user.id}`);
    console.log(`   Email: ${socket.user.email || 'N/A'}`);
    console.log(`   Tenant ID: ${socket.user.tenantId}`);
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // 🔒 JOIN com validação de tenant
    socket.on('join', (requestedTenantId) => {
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log('📥 [SOCKET] Evento "join" recebido');
      console.log(`   User: ${socket.user.email || socket.user.id}`);
      console.log(`   Tenant do usuário: ${socket.user.tenantId}`);
      console.log(`   Tenant requisitado: ${requestedTenantId}`);
      
      // 🔐 VALIDAÇÃO CRÍTICA: Usuário só pode entrar na sala do SEU tenant
      const userTenantId = socket.user.tenantId;
      const requestedTenant = parseInt(requestedTenantId);
      
      if (userTenantId !== requestedTenant) {
        console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.error('🚨 [SECURITY] TENTATIVA DE ACESSO NÃO AUTORIZADO!');
        console.error(`   User ID: ${socket.user.id}`);
        console.error(`   Email: ${socket.user.email || 'N/A'}`);
        console.error(`   Tenant próprio: ${userTenantId}`);
        console.error(`   Tenant requisitado: ${requestedTenant}`);
        console.error(`   IP: ${socket.handshake.address}`);
        console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        
        socket.emit('error', {
          message: 'Acesso negado: Você não tem permissão para acessar este tenant',
          code: 'FORBIDDEN'
        });
        
        // TODO: Logar tentativa de invasão em arquivo/banco
        // logSecurityEvent('UNAUTHORIZED_TENANT_ACCESS', {...})
        
        return;
      }
      
      // ✅ Autorizado - Entrar na sala
      const roomName = String(userTenantId);
      
      console.log(`   ✅ Autorizado! Entrando na sala "${roomName}"`);
      console.log(`   Salas ANTES:`, Array.from(socket.rooms));
      
      socket.join(roomName);
      
      console.log(`   Salas DEPOIS:`, Array.from(socket.rooms));
      
      const roomClients = io.sockets.adapter.rooms.get(roomName);
      const clientCount = roomClients ? roomClients.size : 0;
      
      console.log(`   Total de clientes na sala: ${clientCount}`);
      
      if (roomClients) {
        console.log(`   IDs dos clientes:`, Array.from(roomClients));
      }
      
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // Confirmar entrada
      socket.emit('joined:tenant', {
        tenantId: roomName,
        socketId: socket.id,
        userId: socket.user.id,
        message: `Conectado à sala do tenant ${roomName}`,
        clientsInRoom: clientCount
      });
      
      console.log(`✅ [SOCKET] Confirmação 'joined:tenant' enviada`);
    });

    socket.on('disconnect', (reason) => {
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      console.log('❌ Cliente desconectado');
      console.log(`   User: ${socket.user.email || socket.user.id}`);
      console.log(`   Socket ID: ${socket.id}`);
      console.log(`   Razão: ${reason}`);
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    });

    // Mensagem de boas-vindas
    socket.emit('welcome', {
      message: 'Conectado ao servidor!',
      socketId: socket.id,
      user: {
        id: socket.user.id,
        email: socket.user.email,
        tenantId: socket.user.tenantId
      }
    });
    
    console.log(`📤 [SOCKET] Mensagem 'welcome' enviada`);
  });

  console.log('✅ Socket.io inicializado com autenticação JWT');
  return io;
}

function getIO() {
  if (!io) throw new Error('Socket.io não inicializado!');
  return io;
}

function emitToRoom(room, event, data) {
  if (!io) {
    console.error('❌ [SOCKET] Socket.io não inicializado');
    return;
  }
  
  const roomName = String(room);
  
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`📡 [SOCKET] Tentando emitir evento`);
  console.log(`   Evento: ${event}`);
  console.log(`   Para sala: "${roomName}"`);
  
  const roomClients = io.sockets.adapter.rooms.get(roomName);
  const clientCount = roomClients ? roomClients.size : 0;
  
  console.log(`   Clientes na sala: ${clientCount}`);
  
  if (roomClients) {
    console.log(`   IDs dos clientes:`, Array.from(roomClients));
  }
  
  if (!roomClients || roomClients.size === 0) {
    console.warn(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
    console.warn(`⚠️ [SOCKET] ALERTA: Nenhum cliente na sala "${roomName}"!`);
    console.warn(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
    return;
  }
  
  io.to(roomName).emit(event, data);
  console.log(`✅ [SOCKET] Evento "${event}" emitido para ${clientCount} cliente(s)`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}

function emitToAll(event, data) {
  if (!io) {
    console.error('❌ [SOCKET] Socket.io não inicializado');
    return;
  }
  console.log(`📡 [SOCKET] Emitindo ${event} para TODOS os clientes`);
  io.emit(event, data);
}

function emitToClient(socketId, event, data) {
  if (!io) {
    console.error('❌ [SOCKET] Socket.io não inicializado');
    return;
  }
  console.log(`📡 [SOCKET] Emitindo ${event} para cliente: ${socketId}`);
  io.to(socketId).emit(event, data);
}

module.exports = { 
  initSocket, 
  getIO,
  emitToRoom,
  emitToAll,
  emitToClient
};
```

---

## PASSO 3: Frontend - Pegar Token do AuthStore

Você provavelmente já tem uma store de autenticação. Vou mostrar como integrar:

**📁 Arquivo:** `frontend/plugins/socket.client.ts`

```typescript
import { io, type Socket } from 'socket.io-client'
import { defineNuxtPlugin } from '#app'

export default defineNuxtPlugin((nuxtApp) => {
  const config = useRuntimeConfig()
  const socketUrl = config.public.apiBaseUrl || 'http://localhost:3011'

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  console.log('🔌 [SOCKET PLUGIN] Inicializando...')
  console.log(`   URL: ${socketUrl}`)
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')

  // 🔐 PEGAR TOKEN DO AUTHSTORE (adapte ao seu caso)
  const authStore = useAuthStore()
  const token = authStore.token // OU authStore.user?.token, etc

  if (!token) {
    console.error('❌ [SOCKET PLUGIN] Token não encontrado!')
    console.error('   Usuário não está autenticado.')
    console.error('   Socket.io não será inicializado.')
    
    // Retornar socket dummy para evitar erros
    nuxtApp.provide('socket', {
      connected: false,
      on: () => {},
      off: () => {},
      emit: () => {},
      disconnect: () => {}
    })
    return
  }

  console.log('🔐 [SOCKET PLUGIN] Token encontrado')
  console.log(`   Token: ${token.substring(0, 20)}...`)

  // 🔐 CONECTAR COM TOKEN
  const socket: Socket = io(socketUrl, {
    path: '/socket.io/',
    transports: ['polling', 'websocket'],
    autoConnect: true,
    withCredentials: true,
    reconnection: true,
    reconnectionAttempts: 5,
    reconnectionDelay: 1000,
    
    // 🔥 ENVIAR TOKEN (formato Bearer compatível com Passport)
    auth: {
      token: token // Socket.io vai enviar isso no handshake
    }
  })

  socket.on('connect', () => {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    console.log('✅ [SOCKET PLUGIN] Conectado (Autenticado)!')
    console.log(`   Socket ID: ${socket.id}`)
    console.log(`   Transport: ${socket.io.engine.transport.name}`)
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  })

  socket.on('connect_error', (error) => {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    console.error('💥 [SOCKET PLUGIN] Erro de conexão')
    console.error(`   Mensagem: ${error.message}`)
    
    // 🔐 Se for erro de autenticação, fazer logout
    if (error.message.includes('Authentication error')) {
      console.error('   ⚠️ Token inválido ou expirado!')
      console.error('   Fazendo logout...')
      
      // Fazer logout (adapte ao seu authStore)
      authStore.logout()
      
      // Redirecionar para login
      navigateTo('/login')
    }
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  })

  socket.on('disconnect', (reason) => {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    console.log('❌ [SOCKET PLUGIN] Desconectado')
    console.log(`   Razão: ${reason}`)
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  })

  socket.on('welcome', (data) => {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    console.log('👋 [SOCKET PLUGIN] Welcome recebido')
    console.log('   Mensagem:', data.message)
    console.log('   User:', data.user)
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  })

  socket.on('error', (data) => {
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    console.error('❌ [SOCKET PLUGIN] Erro do servidor:', data)
    
    if (data.code === 'FORBIDDEN') {
      console.error('   🚨 Tentativa de acesso não autorizado!')
      alert('Acesso negado: ' + data.message)
    }
    console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  })

  // 🔥 AUTO-JOIN na sala do tenant do usuário
  socket.on('connect', () => {
    const tenantId = authStore.tenant?.id || authStore.user?.tenantId
    
    if (tenantId) {
      console.log(`🚪 [SOCKET PLUGIN] Auto-join na sala do tenant ${tenantId}`)
      socket.emit('join', tenantId)
    } else {
      console.warn('⚠️ [SOCKET PLUGIN] TenantId não encontrado no authStore')
    }
  })

  socket.on('joined:tenant', (data) => {
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
    console.log('✅ [SOCKET PLUGIN] Entrou na sala!')
    console.log('   Dados:', data)
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
  })

  nuxtApp.provide('socket', socket)

  if (process.client) {
    window.addEventListener('beforeunload', () => {
      console.log('🧹 [SOCKET PLUGIN] Desconectando...')
      socket.disconnect()
    })
  }
})
```

---

## PASSO 4: Adaptar AuthStore (se necessário)

Se você ainda não tem o token acessível na store, adicione:

**📁 Arquivo:** `frontend/stores/auth.ts` (ou similar)

```typescript
export const useAuthStore = defineStore('auth', () => {
  const token = ref<string | null>(null)
  const user = ref<any>(null)
  const tenant = ref<any>(null)

  // Carregar do localStorage ao iniciar
  if (process.client) {
    const savedToken = localStorage.getItem('auth_token')
    if (savedToken) {
      token.value = savedToken
    }
  }

  const login = async (credentials: any) => {
    // Fazer login via API
    const response = await $fetch('/auth/login', {
      method: 'POST',
      body: credentials
    })
    
    // Salvar token
    token.value = response.token
    user.value = response.user
    tenant.value = response.tenant
    
    // Persistir no localStorage
    if (process.client) {
      localStorage.setItem('auth_token', response.token)
    }
  }

  const logout = () => {
    token.value = null
    user.value = null
    tenant.value = null
    
    if (process.client) {
      localStorage.removeItem('auth_token')
    }
  }

  return {
    token,
    user,
    tenant,
    login,
    logout
  }
})
```

---

## 🧪 TESTAR

### Teste 1: Conectar com token válido

```javascript
// Faça login normalmente
await authStore.login({ email: 'user@example.com', password: '123' })

// Socket deve conectar automaticamente e mostrar:
// ✅ Conectado (Autenticado)!
// ✅ Entrou na sala!
```

### Teste 2: Tentar conectar sem token

```javascript
// Fazer logout
authStore.logout()

// Recarregar página
// Socket NÃO deve conectar
// Log: ❌ Token não encontrado!
```

### Teste 3: Tentar entrar em sala não autorizada

```javascript
// No console do browser
window.$nuxt.$socket.emit('join', 999) // Tenant que não é o seu

// Deve mostrar:
// ❌ Erro: Acesso negado
// 🚨 TENTATIVA DE ACESSO NÃO AUTORIZADO (no backend)
```

---

## 📋 Checklist de Implementação

- [ ] Criar arquivo `middlewares/socketAuth.js`
- [ ] Atualizar `socket.js` com `io.use(socketAuthMiddleware)`
- [ ] Atualizar `socket.client.ts` para enviar token
- [ ] Garantir que `authStore.token` está disponível
- [ ] Testar login + conexão socket
- [ ] Testar tentativa de acesso não autorizado
- [ ] Verificar logs de segurança

---

## 🎯 Diferenças do seu sistema:

✅ **Usa o mesmo JWT que o Passport**
✅ **Usa o mesmo `jwtSecret`**
✅ **Busca `User` da mesma forma**
✅ **Compatível 100% com sua auth REST**

---

**Pronto! Agora seu Socket.io está seguro e integrado com seu sistema de auth existente! 🔐**