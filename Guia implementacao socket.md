# 🚀 Guia Completo - Implementar Ações em Tempo Real com Socket.io

## 📚 Índice

1. [Arquitetura Geral](#arquitetura-geral)
2. [Fluxo de Dados](#fluxo-de-dados)
3. [Implementar Nova Ação - Passo a Passo](#implementar-nova-ação)
4. [Exemplos Práticos](#exemplos-práticos)
5. [Padrões e Boas Práticas](#padrões-e-boas-práticas)
6. [Troubleshooting](#troubleshooting)

---

## 🏗️ Arquitetura Geral

### Componentes do Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                         FRONTEND                            │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │ Vue Page     │  │ Pinia Store  │  │ Socket Plugin   │  │
│  │ (agenda.vue) │◄─┤ (useXXX.ts)  │◄─┤ (socket.client) │  │
│  └──────────────┘  └──────────────┘  └─────────────────┘  │
│         ▲                  ▲                   ▲            │
│         │                  │                   │            │
│         │                  │                   │ WebSocket  │
│         │                  │                   │            │
└─────────┼──────────────────┼───────────────────┼────────────┘
          │                  │                   │
          │ API REST         │                   │
          │                  │                   │
┌─────────▼──────────────────▼───────────────────▼────────────┐
│                         BACKEND                             │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │ Controller   │  │ socket.js    │  │ server.js       │  │
│  │ (CRUD)       │─►│ (emitToRoom) │◄─┤ (initSocket)    │  │
│  └──────────────┘  └──────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Fluxo de Dados

### Fluxo Completo de uma Ação

```
1. USUÁRIO FAZ AÇÃO
   ↓
2. FRONTEND chama API REST (POST, PUT, DELETE)
   ↓
3. BACKEND processa no Controller
   ↓
4. BACKEND salva no Banco de Dados
   ↓
5. BACKEND emite evento Socket.io (emitToRoom)
   ↓
6. SOCKET.IO envia para todos os clientes na sala (tenant)
   ↓
7. FRONTEND recebe evento (listener na Store)
   ↓
8. STORE atualiza estado reativo
   ↓
9. VUE PAGE reage automaticamente
   ↓
10. UI ATUALIZA (calendário, lista, toast, etc)
```

### Exemplo Concreto: Criar Agendamento

```
Usuário preenche formulário
   ↓
appointmentStore.createAppointment(payload)
   ↓
POST /appointment-flow/appointment
   ↓
Controller: appointment.create()
   ↓
await Appointment.create({...})
   ↓
emitToRoom(tenantId, 'appointment:created', { appointment })
   ↓
Socket.io → broadcast para sala "1"
   ↓
Store: socket.on('appointment:created', (data) => {...})
   ↓
appointments.value.push(newAppointment)
   ↓
Vue detecta mudança reativa
   ↓
Calendário adiciona evento automaticamente
   ↓
Toast de notificação aparece
```

---

## 🛠️ Implementar Nova Ação - Passo a Passo

Vamos implementar uma ação completa do zero: **Serviços (Services)**

---

### PASSO 1: Backend - Controller

**📁 Arquivo:** `backend/src/controllers/ServiceController.js`

```javascript
const { Service } = require('../models');
const { emitToRoom } = require('../../socket');

class ServiceController {
  
  // ==========================================
  // 📝 CREATE
  // ==========================================
  async store(req, res) {
    try {
      const { name, price, durationId, description } = req.body;
      const tenantId = req.user?.tenantId;
      
      console.log('📝 [SERVICE] Criando serviço...');
      
      // 1. Criar no banco
      const service = await Service.create({
        name,
        price,
        durationId,
        description,
        tenantId
      });
      
      console.log(`✅ [SERVICE] Serviço criado: ID ${service.id}`);
      
      // 2. Buscar versão completa com relações
      const serviceFull = await Service.findByPk(service.id, {
        include: [
          { model: Duration, as: 'duration' }
        ]
      });
      
      // 3. 🔥 EMITIR EVENTO SOCKET.IO
      emitToRoom(tenantId, 'service:created', {
        service: serviceFull,
        tenantId
      });
      console.log(`🔔 [SERVICE] Evento 'service:created' emitido para tenant ${tenantId}`);
      
      // 4. Retornar resposta
      return res.status(201).json({
        success: true,
        service: serviceFull
      });
      
    } catch (err) {
      console.error('❌ [SERVICE] Erro ao criar:', err);
      return res.status(500).json({ 
        error: 'internal_error',
        message: err.message 
      });
    }
  }
  
  // ==========================================
  // ✏️ UPDATE
  // ==========================================
  async update(req, res) {
    try {
      const { id } = req.params;
      const { name, price, durationId, description } = req.body;
      const tenantId = req.user?.tenantId;
      
      console.log(`✏️ [SERVICE] Atualizando serviço ID ${id}...`);
      
      // 1. Atualizar no banco
      const [updated] = await Service.update(
        { name, price, durationId, description },
        { where: { id, tenantId } }
      );
      
      if (!updated) {
        return res.status(404).json({ 
          error: 'not_found',
          message: 'Serviço não encontrado' 
        });
      }
      
      // 2. Buscar versão atualizada
      const service = await Service.findByPk(id, {
        include: [
          { model: Duration, as: 'duration' }
        ]
      });
      
      console.log(`✅ [SERVICE] Serviço atualizado: ID ${id}`);
      
      // 3. 🔥 EMITIR EVENTO SOCKET.IO
      emitToRoom(tenantId, 'service:updated', {
        service,
        tenantId
      });
      console.log(`🔔 [SERVICE] Evento 'service:updated' emitido para tenant ${tenantId}`);
      
      // 4. Retornar resposta
      return res.status(200).json({
        success: true,
        service
      });
      
    } catch (err) {
      console.error('❌ [SERVICE] Erro ao atualizar:', err);
      return res.status(500).json({ 
        error: 'internal_error',
        message: err.message 
      });
    }
  }
  
  // ==========================================
  // 🗑️ DELETE
  // ==========================================
  async destroy(req, res) {
    try {
      const { id } = req.params;
      const tenantId = req.user?.tenantId;
      
      console.log(`🗑️ [SERVICE] Deletando serviço ID ${id}...`);
      
      // 1. Deletar no banco
      const deleted = await Service.destroy({
        where: { id, tenantId }
      });
      
      if (!deleted) {
        return res.status(404).json({ 
          error: 'not_found',
          message: 'Serviço não encontrado' 
        });
      }
      
      console.log(`✅ [SERVICE] Serviço deletado: ID ${id}`);
      
      // 2. 🔥 EMITIR EVENTO SOCKET.IO
      emitToRoom(tenantId, 'service:deleted', {
        serviceId: parseInt(id),
        tenantId
      });
      console.log(`🔔 [SERVICE] Evento 'service:deleted' emitido para tenant ${tenantId}`);
      
      // 3. Retornar resposta
      return res.status(204).send();
      
    } catch (err) {
      console.error('❌ [SERVICE] Erro ao deletar:', err);
      return res.status(500).json({ 
        error: 'internal_error',
        message: err.message 
      });
    }
  }
}

module.exports = new ServiceController();
```

**🔑 Pontos-chave:**
- ✅ Sempre buscar versão completa com `include` antes de emitir
- ✅ Emitir evento APÓS salvar no banco
- ✅ Usar nomenclatura consistente: `entity:action` (ex: `service:created`)
- ✅ Sempre passar `tenantId` no payload do evento

---

### PASSO 2: Frontend - Pinia Store

**📁 Arquivo:** `frontend/stores/useServices.ts`

```javascript
import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { Socket } from 'socket.io-client'
import { useApi } from '@/composables/useApi'
import { useAuthStore } from '@/stores/auth'

export interface Service {
  id?: number
  name: string
  price: number
  durationId?: number
  description?: string
  duration?: {
    id: number
    name: string
    milliseconds: number
  }
}

export const useServices = defineStore('services', () => {
  const { apiFetch } = useApi()
  const { $socket } = useNuxtApp()
  const socket = $socket as Socket
  const authStore = useAuthStore()

  const services = ref<Service[]>([])
  const loading = ref(false)
  const isSocketActive = ref(false)

  // ==========================================
  // 🔌 SETUP SOCKET LISTENERS
  // ==========================================
  const setupSocketListeners = () => {
    const tenantId = authStore.tenant?.id
  
    if (!tenantId) {
      console.warn('⚠️ [SERVICES] Tenant não disponível')
      return
    }
  
    if (isSocketActive.value) {
      console.log('⚠️ [SERVICES] Socket listeners já ativos')
      return
    }
  
    console.log('🔌 [SERVICES] Configurando socket listeners...')
  
    // ==========================================
    // EVENTO: Service Criado
    // ==========================================
    socket.on('service:created', (data) => {
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
      console.log('➕ [SERVICES] Novo serviço criado')
      console.log('   ID:', data.service?.id)
      console.log('   Nome:', data.service?.name)
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
      
      const exists = services.value.some(s => s.id === data.service.id)
      
      if (!exists) {
        services.value.push(data.service)
        console.log(`✅ [SERVICES] Serviço ${data.service.id} adicionado`)
      }
    })

    // ==========================================
    // EVENTO: Service Atualizado
    // ==========================================
    socket.on('service:updated', (data) => {
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
      console.log('✏️ [SERVICES] Serviço atualizado')
      console.log('   ID:', data.service?.id)
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
      
      const idx = services.value.findIndex(s => s.id === data.service.id)
      
      if (idx !== -1) {
        services.value[idx] = data.service
        console.log(`✅ [SERVICES] Serviço ${data.service.id} atualizado`)
      }
    })

    // ==========================================
    // EVENTO: Service Deletado
    // ==========================================
    socket.on('service:deleted', (data) => {
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
      console.log('🗑️ [SERVICES] Serviço deletado')
      console.log('   ID:', data.serviceId)
      console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
      
      services.value = services.value.filter(s => s.id !== data.serviceId)
      console.log(`✅ [SERVICES] Serviço ${data.serviceId} removido`)
    })

    isSocketActive.value = true
    console.log('✅ [SERVICES] Socket listeners configurados')
  }

  // ==========================================
  // 🧹 CLEANUP SOCKET
  // ==========================================
  const cleanupSocketListeners = () => {
    if (!isSocketActive.value) return

    console.log('🧹 [SERVICES] Removendo socket listeners...')
    
    socket.off('service:created')
    socket.off('service:updated')
    socket.off('service:deleted')

    isSocketActive.value = false
    console.log('✅ [SERVICES] Socket listeners removidos')
  }

  // ==========================================
  // FETCH SERVICES
  // ==========================================
  const fetchServices = async () => {
    loading.value = true
    try {
      const res = await apiFetch<Service[]>('/services')
      services.value = res
      console.log(`✅ [SERVICES] ${services.value.length} serviços carregados`)
      return services.value
    } catch (err) {
      console.error('❌ [SERVICES] Erro ao buscar:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  // ==========================================
  // CREATE SERVICE
  // ==========================================
  const createService = async (payload: Partial<Service>) => {
    loading.value = true
    try {
      const res = await apiFetch<Service>('/services', { 
        method: 'POST', 
        body: payload 
      })
      
      console.log('✅ [SERVICES] Serviço criado via API:', res.id)
      // Não adiciona aqui - socket vai disparar 'service:created'
      
      return res
    } catch (err) {
      console.error('❌ [SERVICES] Erro ao criar:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  // ==========================================
  // UPDATE SERVICE
  // ==========================================
  const updateService = async (id: number, payload: Partial<Service>) => {
    loading.value = true
    try {
      const res = await apiFetch<Service>(`/services/${id}`, { 
        method: 'PUT', 
        body: payload 
      })
      
      console.log('✅ [SERVICES] Serviço atualizado via API:', id)
      // Socket vai disparar 'service:updated'
      
      return res
    } catch (err) {
      console.error('❌ [SERVICES] Erro ao atualizar:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  // ==========================================
  // DELETE SERVICE
  // ==========================================
  const deleteService = async (id: number) => {
    loading.value = true
    try {
      await apiFetch(`/services/${id}`, { method: 'DELETE' })
      
      console.log('✅ [SERVICES] Serviço deletado via API:', id)
      // Socket vai disparar 'service:deleted'
      
    } catch (err) {
      console.error('❌ [SERVICES] Erro ao deletar:', err)
      throw err
    } finally {
      loading.value = false
    }
  }

  return {
    // State
    services,
    loading,
    isSocketActive,
    
    // Actions
    fetchServices,
    createService,
    updateService,
    deleteService,
    
    // Socket
    setupSocketListeners,
    cleanupSocketListeners,
  }
})
```

**🔑 Pontos-chave:**
- ✅ Listeners não modificam o estado diretamente na ação (ex: `createService` não faz `push`)
- ✅ Socket listeners modificam o estado reativo
- ✅ Vue detecta mudanças automaticamente
- ✅ Cleanup é importante para evitar memory leaks

---

### PASSO 3: Frontend - Vue Page

**📁 Arquivo:** `frontend/pages/services.vue`

```vue
<template>
  <div class="p-4">
    <h1 class="text-2xl font-bold mb-4">Serviços</h1>
    
    <!-- Toast de Notificação -->
    <transition name="slide-down">
      <div v-if="showNotification" class="fixed top-4 right-4 z-50">
        <div class="bg-white rounded-lg shadow-xl p-4 border-l-4 border-green-500">
          <p class="font-semibold">{{ notificationMessage }}</p>
        </div>
      </div>
    </transition>
    
    <!-- Lista de Serviços -->
    <div class="grid gap-4">
      <div
        v-for="service in services"
        :key="service.id"
        class="bg-white p-4 rounded-lg shadow"
      >
        <h3 class="font-semibold">{{ service.name }}</h3>
        <p class="text-gray-600">R$ {{ service.price }}</p>
        <p class="text-sm text-gray-500">{{ service.duration?.name }}</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { useServices } from '@/stores/useServices'

const serviceStore = useServices()

const services = computed(() => serviceStore.services)
const showNotification = ref(false)
const notificationMessage = ref('')

// ==========================================
// 🔔 SETUP LISTENERS DA PÁGINA
// ==========================================
function setupPageSocketListeners() {
  const { $socket } = useNuxtApp()
  const socket = $socket as any
  
  socket.on('service:created', (data: any) => {
    console.log('🔔 [SERVICES PAGE] Novo serviço recebido:', data)
    
    notificationMessage.value = `✨ Novo serviço: ${data.service.name}`
    showNotification.value = true
    
    setTimeout(() => {
      showNotification.value = false
    }, 3000)
  })
  
  socket.on('service:updated', (data: any) => {
    console.log('🔔 [SERVICES PAGE] Serviço atualizado:', data)
    
    notificationMessage.value = `✏️ Serviço atualizado: ${data.service.name}`
    showNotification.value = true
    
    setTimeout(() => {
      showNotification.value = false
    }, 3000)
  })
  
  socket.on('service:deleted', (data: any) => {
    console.log('🔔 [SERVICES PAGE] Serviço deletado:', data)
    
    notificationMessage.value = `🗑️ Serviço removido`
    showNotification.value = true
    
    setTimeout(() => {
      showNotification.value = false
    }, 3000)
  })
}

function cleanupPageSocketListeners() {
  const { $socket } = useNuxtApp()
  const socket = $socket as any
  
  socket.off('service:created')
  socket.off('service:updated')
  socket.off('service:deleted')
}

// ==========================================
// LIFECYCLE
// ==========================================
onMounted(async () => {
  console.log('📄 [SERVICES PAGE] Montando página...')
  
  await serviceStore.fetchServices()
  serviceStore.setupSocketListeners()
  setupPageSocketListeners()
})

onBeforeUnmount(() => {
  console.log('🧹 [SERVICES PAGE] Desmontando página...')
  
  serviceStore.cleanupSocketListeners()
  cleanupPageSocketListeners()
})
</script>

<style scoped>
.slide-down-enter-active,
.slide-down-leave-active {
  transition: all 0.3s ease;
}

.slide-down-enter-from {
  transform: translateY(-100%);
  opacity: 0;
}

.slide-down-leave-to {
  transform: translateY(-20px);
  opacity: 0;
}
</style>
```

**🔑 Pontos-chave:**
- ✅ Sempre chamar `setupSocketListeners()` no `onMounted`
- ✅ Sempre chamar `cleanupSocketListeners()` no `onBeforeUnmount`
- ✅ Listeners da página são para UI (toast, animações)
- ✅ Listeners da store são para estado (dados)

---

## 📋 Exemplos Práticos

### Exemplo 1: Clientes (Clients)

**Backend - Controller**
```javascript
// CREATE
const client = await Client.create({...})
emitToRoom(tenantId, 'client:created', { client, tenantId })

// UPDATE
const client = await Client.findByPk(id)
emitToRoom(tenantId, 'client:updated', { client, tenantId })

// DELETE
emitToRoom(tenantId, 'client:deleted', { clientId: id, tenantId })
```

**Frontend - Store**
```javascript
socket.on('client:created', (data) => {
  clients.value.push(data.client)
})

socket.on('client:updated', (data) => {
  const idx = clients.value.findIndex(c => c.id === data.client.id)
  if (idx !== -1) clients.value[idx] = data.client
})

socket.on('client:deleted', (data) => {
  clients.value = clients.value.filter(c => c.id !== data.clientId)
})
```

---

### Exemplo 2: Funcionários (Employees)

**Backend - Controller**
```javascript
// CREATE
const employee = await Employee.create({...})
emitToRoom(tenantId, 'employee:created', { employee, tenantId })

// UPDATE
const employee = await Employee.findByPk(id)
emitToRoom(tenantId, 'employee:updated', { employee, tenantId })

// DELETE
emitToRoom(tenantId, 'employee:deleted', { employeeId: id, tenantId })
```

**Frontend - Store**
```javascript
socket.on('employee:created', (data) => {
  employees.value.push(data.employee)
})

socket.on('employee:updated', (data) => {
  const idx = employees.value.findIndex(e => e.id === data.employee.id)
  if (idx !== -1) employees.value[idx] = data.employee
})

socket.on('employee:deleted', (data) => {
  employees.value = employees.value.filter(e => e.id !== data.employeeId)
})
```

---

### Exemplo 3: Produtos (Products)

**Backend - Controller**
```javascript
// CREATE
const product = await Product.create({...})
emitToRoom(tenantId, 'product:created', { product, tenantId })

// UPDATE
const product = await Product.findByPk(id)
emitToRoom(tenantId, 'product:updated', { product, tenantId })

// DELETE
emitToRoom(tenantId, 'product:deleted', { productId: id, tenantId })
```

**Frontend - Store**
```javascript
socket.on('product:created', (data) => {
  products.value.push(data.product)
})

socket.on('product:updated', (data) => {
  const idx = products.value.findIndex(p => p.id === data.product.id)
  if (idx !== -1) products.value[idx] = data.product
})

socket.on('product:deleted', (data) => {
  products.value = products.value.filter(p => p.id !== data.productId)
})
```

---

## 🎯 Padrões e Boas Práticas

### ✅ Nomenclatura de Eventos

**Padrão:** `entity:action`

```javascript
// ✅ CORRETO
'appointment:created'
'appointment:updated'
'appointment:deleted'
'client:created'
'service:updated'
'product:deleted'

// ❌ ERRADO
'createAppointment'
'appointmentCreated'
'new_appointment'
'APPOINTMENT_CREATED'
```

---

### ✅ Estrutura do Payload

**Sempre incluir:**
- O objeto completo (com relações)
- O `tenantId`
- Metadados se necessário

```javascript
// ✅ CORRETO
{
  appointment: {
    id: 1,
    start: "2026-02-07T10:00:00Z",
    client: { id: 5, firstName: "João" },
    service: { id: 3, name: "Corte" },
    employee: { id: 2, firstName: "Maria" }
  },
  tenantId: 1
}

// ❌ ERRADO
{
  id: 1,
  start: "2026-02-07T10:00:00Z"
}
```

---

### ✅ Ordem de Execução

**SEMPRE nesta ordem:**

```javascript
// 1. Modificar banco de dados
const entity = await Entity.create({...})

// 2. Buscar versão completa (se necessário)
const entityFull = await Entity.findByPk(entity.id, {
  include: [...]
})

// 3. Emitir evento Socket.io
emitToRoom(tenantId, 'entity:created', {
  entity: entityFull,
  tenantId
})

// 4. Retornar resposta HTTP
return res.status(201).json({
  success: true,
  entity: entityFull
})
```

**❌ NUNCA faça:**
```javascript
// ERRADO - Emitir antes de salvar
emitToRoom(tenantId, 'entity:created', {...})
await Entity.create({...}) // Se falhar, evento já foi emitido!
```

---

### ✅ Tratamento de Erros

**No Backend:**
```javascript
try {
  const entity = await Entity.create({...})
  emitToRoom(tenantId, 'entity:created', { entity, tenantId })
  return res.status(201).json({ entity })
} catch (err) {
  // NÃO emite evento se deu erro
  console.error('Erro:', err)
  return res.status(500).json({ error: err.message })
}
```

**No Frontend:**
```javascript
try {
  await entityStore.createEntity(payload)
  // Socket vai disparar o evento
} catch (err) {
  // Mostrar erro para o usuário
  console.error('Erro ao criar:', err)
  alert('Erro ao criar entidade')
}
```

---

### ✅ Evitar Duplicação

**Store NÃO adiciona no create/update:**
```javascript
// ✅ CORRETO
const createEntity = async (payload) => {
  const res = await apiFetch('/entities', { method: 'POST', body: payload })
  // NÃO faz: entities.value.push(res)
  // Socket vai fazer isso
  return res
}

// ❌ ERRADO
const createEntity = async (payload) => {
  const res = await apiFetch('/entities', { method: 'POST', body: payload })
  entities.value.push(res) // ❌ Vai duplicar quando socket emitir!
  return res
}
```

---

### ✅ Listeners de Página vs Store

**Store (useEntity.ts):**
- Modifica o estado (arrays, objetos)
- Dados puros
- Sem lógica de UI

**Page (entity.vue):**
- Mostra notificações (toast)
- Animações
- Lógica de UI específica

```javascript
// ✅ Store - Apenas dados
socket.on('entity:created', (data) => {
  entities.value.push(data.entity)
})

// ✅ Page - UI
socket.on('entity:created', (data) => {
  showToast(`Novo: ${data.entity.name}`)
  playSound('notification.mp3')
  triggerAnimation()
})
```

---

## 🐛 Troubleshooting

### Problema: Evento não chega no frontend

**Checklist:**
1. ✅ Backend emitiu o evento? (verificar logs)
2. ✅ Cliente está na sala? (verificar Admin UI)
3. ✅ Listener está registrado? (verificar `setupSocketListeners()`)
4. ✅ Nome do evento está correto? (case-sensitive!)

**Debug:**
```javascript
// No frontend
socket.on('entity:created', (data) => {
  console.log('🎯 EVENTO RECEBIDO:', data) // Se não aparecer, evento não chegou
})

// Listener genérico
socket.onAny((event, ...args) => {
  console.log('📡 QUALQUER EVENTO:', event, args)
})
```

---

### Problema: Evento duplicado

**Causa:** Listener registrado múltiplas vezes

**Solução:**
```javascript
// ✅ CORRETO - Verificar se já está ativo
const setupSocketListeners = () => {
  if (isSocketActive.value) {
    console.log('⚠️ Listeners já ativos')
    return // ⚠️ IMPORTANTE
  }
  
  socket.on('entity:created', ...)
  isSocketActive.value = true
}
```

---

### Problema: Estado não atualiza na UI

**Causa:** Array/objeto não é reativo

**Solução:**
```javascript
// ❌ ERRADO
services[idx] = newService // Não é reativo

// ✅ CORRETO
services.value[idx] = newService // Reativo
```

---

### Problema: Memory leak

**Causa:** Listeners não foram removidos

**Solução:**
```javascript
// ✅ SEMPRE fazer cleanup
onBeforeUnmount(() => {
  entityStore.cleanupSocketListeners()
  cleanupPageSocketListeners()
})
```

---

## 📊 Checklist de Implementação

Para cada nova entidade/ação:

### Backend
- [ ] Controller tem `emitToRoom()` no create
- [ ] Controller tem `emitToRoom()` no update
- [ ] Controller tem `emitToRoom()` no delete
- [ ] Eventos são emitidos APÓS salvar no banco
- [ ] Payload inclui objeto completo + tenantId
- [ ] Logs estão implementados

### Frontend - Store
- [ ] Store tem `setupSocketListeners()`
- [ ] Store tem `cleanupSocketListeners()`
- [ ] Listener `entity:created` implementado
- [ ] Listener `entity:updated` implementado
- [ ] Listener `entity:deleted` implementado
- [ ] `isSocketActive` evita duplicação

### Frontend - Page
- [ ] `onMounted` chama `setupSocketListeners()`
- [ ] `onBeforeUnmount` chama `cleanupSocketListeners()`
- [ ] Listeners da página são opcionais (toast/UI)
- [ ] Página usa `computed` para reatividade

### Testes
- [ ] Criar via API → Evento chega → UI atualiza
- [ ] Atualizar via API → Evento chega → UI atualiza
- [ ] Deletar via API → Evento chega → UI atualiza
- [ ] Múltiplos clientes recebem eventos
- [ ] Admin UI mostra clientes na sala

---

## 🚀 Template Rápido

### Backend Controller
```javascript
async store(req, res) {
  try {
    const entity = await Entity.create({...req.body, tenantId: req.user.tenantId})
    const entityFull = await Entity.findByPk(entity.id, { include: [...] })
    emitToRoom(req.user.tenantId, 'entity:created', { entity: entityFull, tenantId: req.user.tenantId })
    return res.status(201).json({ success: true, entity: entityFull })
  } catch (err) {
    return res.status(500).json({ error: err.message })
  }
}
```

### Frontend Store
```javascript
const setupSocketListeners = () => {
  if (isSocketActive.value) return
  socket.on('entity:created', (data) => entities.value.push(data.entity))
  socket.on('entity:updated', (data) => {
    const idx = entities.value.findIndex(e => e.id === data.entity.id)
    if (idx !== -1) entities.value[idx] = data.entity
  })
  socket.on('entity:deleted', (data) => {
    entities.value = entities.value.filter(e => e.id !== data.entityId)
  })
  isSocketActive.value = true
}
```

### Frontend Page
```javascript
onMounted(async () => {
  await entityStore.fetchEntities()
  entityStore.setupSocketListeners()
})

onBeforeUnmount(() => {
  entityStore.cleanupSocketListeners()
})
```

---

## 🎓 Recursos Adicionais

**Documentação Socket.io:**
- Emitting events: https://socket.io/docs/v4/emitting-events/
- Rooms: https://socket.io/docs/v4/rooms/
- Admin UI: https://socket.io/docs/v4/admin-ui/

**Vue Reactivity:**
- https://vuejs.org/guide/essentials/reactivity-fundamentals.html

**Pinia:**
- https://pinia.vuejs.org/core-concepts/

---

**✅ Pronto! Agora você tem tudo para implementar qualquer ação em tempo real! 🚀**