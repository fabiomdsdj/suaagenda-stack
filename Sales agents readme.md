# Sales Agents - Implementação Completa

## 📋 Visão Geral

Esta implementação adiciona funcionalidades completas de CRUD para Sales Agents, seguindo o mesmo padrão usado para Tenants.

## 📁 Arquivos Criados

### Backend

1. **Controller**: `salesAgent.controller.js`
   - Métodos CRUD completos
   - Dashboard e ganhos para sales agents
   - Controle de permissões
   - Estatísticas

2. **Routes**: `salesAgent.routes.js`
   - Rotas administrativas (CRUD)
   - Rotas para sales agents verem seus dados
   - Middlewares de autenticação e permissão

### Frontend

3. **Store**: `useSalesAgent.ts`
   - Gerenciamento de estado com Pinia
   - Métodos para API

4. **Pages**:
   - `SalesAgentsPage.vue` - Listagem
   - `CreateSalesAgentPage.vue` - Criação
   - `SalesAgentDetailsPage.vue` - Detalhes/Edição

## 🔧 Instruções de Integração

### 1. Backend

#### 1.1. Copiar o Controller

```bash
# Copiar para src/controllers/
cp salesAgent.controller.js seu-projeto/src/controllers/
```

#### 1.2. Copiar as Routes

```bash
# Copiar para src/routes/v1/
cp salesAgent.routes.js seu-projeto/src/routes/v1/
```

#### 1.3. Registrar as Routes

No arquivo `src/routes/v1/index.js`:

```javascript
const salesAgentRoutes = require('./salesAgent.routes')

// ... outras routes

router.use('/sales-agents', salesAgentRoutes)
```

#### 1.4. Verificar Models

Certifique-se de que os models estão configurados corretamente:

```javascript
// No salesAgent.controller.js
const { 
  SalesAgent, 
  SalesAgentStatus, 
  Tenant, 
  User, 
  Subscription, 
  Payment 
} = require('../models')
```

### 2. Frontend

#### 2.1. Copiar o Store

```bash
# Copiar para src/stores/
cp useSalesAgent.ts seu-projeto/src/stores/
```

#### 2.2. Copiar as Pages

```bash
# Copiar para src/views/admin/sales-agents/
mkdir -p seu-projeto/src/views/admin/sales-agents
cp SalesAgentsPage.vue seu-projeto/src/views/admin/sales-agents/
cp CreateSalesAgentPage.vue seu-projeto/src/views/admin/sales-agents/
cp SalesAgentDetailsPage.vue seu-projeto/src/views/admin/sales-agents/
```

#### 2.3. Configurar Rotas Vue Router

No arquivo `src/router/index.ts`:

```typescript
{
  path: '/admin/sales-agents',
  name: 'SalesAgents',
  component: () => import('@/views/admin/sales-agents/SalesAgentsPage.vue'),
  meta: { 
    requiresAuth: true,
    requiresPermission: 'sales_agents.view_all'
  }
},
{
  path: '/admin/sales-agents/novo',
  name: 'CreateSalesAgent',
  component: () => import('@/views/admin/sales-agents/CreateSalesAgentPage.vue'),
  meta: { 
    requiresAuth: true,
    requiresPermission: 'sales_agents.create'
  }
},
{
  path: '/admin/sales-agents/:id',
  name: 'SalesAgentDetails',
  component: () => import('@/views/admin/sales-agents/SalesAgentDetailsPage.vue'),
  meta: { 
    requiresAuth: true,
    requiresPermission: 'sales_agents.view_all'
  }
}
```

#### 2.4. Adicionar ao Menu de Navegação

```vue
<!-- Em seu componente de navegação -->
<router-link 
  v-if="canManageSalesAgents"
  to="/admin/sales-agents"
  class="nav-item"
>
  <svg><!-- ícone --></svg>
  Sales Agents
</router-link>
```

### 3. Permissões

#### 3.1. Permissões Necessárias

Adicione estas permissões ao seu sistema:

```sql
INSERT INTO system_permissions (name, description) VALUES
('sales_agents.view_all', 'Ver todos os sales agents'),
('sales_agents.create', 'Criar sales agents'),
('sales_agents.update', 'Atualizar sales agents'),
('sales_agents.delete', 'Excluir sales agents'),
('commissions.view', 'Ver comissões'),
('tenants.view', 'Ver tenants (para sales agents)'),
('tenants.create', 'Criar tenants (para sales agents)');
```

#### 3.2. Atribuir Permissões

Para **MASTER_ADMIN**: Todas as permissões automaticamente

Para **Sales Agents**: 
- `commissions.view`
- `tenants.view`
- `tenants.create`

Para **Administradores**:
- `sales_agents.view_all`
- `sales_agents.create`
- `sales_agents.update`
- `sales_agents.delete`

## 🎯 Funcionalidades Implementadas

### Para Administradores (MASTER_ADMIN)

✅ Listar todos os sales agents
✅ Criar novos sales agents
✅ Editar sales agents
✅ Excluir sales agents (com validação de tenants vinculados)
✅ Ver estatísticas de cada sales agent
✅ Filtrar por status, nome, comissão

### Para Sales Agents

✅ Dashboard com métricas pessoais
✅ Ver seus próprios tenants
✅ Criar tenants vinculados automaticamente
✅ Ver ganhos/comissões
✅ Ver perfil

## 🔐 Segurança

- ✅ Autenticação obrigatória em todas as rotas
- ✅ Verificação de permissões específicas
- ✅ MASTER_ADMIN tem acesso total
- ✅ Sales agents só veem seus próprios dados
- ✅ Validação de dados no backend
- ✅ Proteção contra exclusão de sales agents com tenants vinculados

## 📊 Fluxo de Dados

### Criação de Sales Agent

1. Admin acessa `/admin/sales-agents/novo`
2. Preenche formulário (nome, telefone, comissão, status)
3. Submit → POST `/api/sales-agents`
4. Backend valida e cria
5. Redirect para detalhes do sales agent criado

### Criação de Tenant por Sales Agent

1. Sales agent acessa seu dashboard
2. Clica em "Criar Tenant"
3. Preenche formulário
4. Submit → POST `/api/tenants`
5. Backend vincula automaticamente ao `salesAgentId` do usuário
6. Tenant criado e listado nos "Meus Tenants"

## 🧪 Testes

### Testar Permissões

1. **Como MASTER_ADMIN**:
   - ✅ Deve ver todos os sales agents
   - ✅ Deve criar, editar e excluir
   - ✅ Deve ver estatísticas completas

2. **Como Sales Agent**:
   - ✅ Deve ver apenas seus dados
   - ✅ Deve ver seus tenants
   - ✅ Deve criar tenants vinculados automaticamente
   - ❌ Não deve acessar `/admin/sales-agents`

3. **Como Admin (com permissões)**:
   - ✅ Deve gerenciar sales agents
   - ✅ Deve ver todos os sales agents

### Endpoints para Testar

```bash
# Listar todos (requer sales_agents.view_all)
GET /api/sales-agents

# Ver detalhes
GET /api/sales-agents/:id

# Criar (requer sales_agents.create)
POST /api/sales-agents
{
  "name": "João Silva",
  "phone": "(11) 98765-4321",
  "commissionPercent": 40,
  "status": "active"
}

# Atualizar (requer sales_agents.update)
PUT /api/sales-agents/:id
{
  "name": "João Silva Jr.",
  "commissionPercent": 45
}

# Excluir (requer sales_agents.delete)
DELETE /api/sales-agents/:id

# Dashboard do sales agent (próprio)
GET /api/sales-agents/dashboard

# Tenants do sales agent (próprio)
GET /api/sales-agents/tenants

# Ganhos do sales agent (próprio)
GET /api/sales-agents/earnings
```

## 🐛 Troubleshooting

### Erro: "Você não tem permissão"

- Verificar se o usuário tem as permissões corretas
- Verificar se o middleware `checkSystemPermission` está funcionando
- Para MASTER_ADMIN, verificar se `systemRoleId === 1`

### Sales Agent não vê seus tenants

- Verificar se o usuário tem `salesAgentId` preenchido
- Verificar se os tenants estão vinculados corretamente
- Verificar logs do backend

### Erro ao criar tenant

- Verificar se o `salesAgentId` está sendo enviado corretamente
- Verificar se o controller está usando o `salesAgentId` do usuário
- Verificar permissão `tenants.create`

## 📝 Notas Importantes

1. **SalesAgentId é UUID**: Diferente do Tenant que usa INT, SalesAgent usa CHAR(36) UUID
2. **Comissão**: Armazenada como número (ex: 40 = 40%), não decimal
3. **Status**: String, não ID. Valores: 'active', 'inactive', 'suspended', 'on_vacation', 'terminated'
4. **Exclusão**: Bloqueada se houver tenants vinculados (soft delete ou reatribuição seria alternativa)

## 🎨 Personalizações Opcionais

### Adicionar Foto ao Sales Agent

Adicione campo `avatar` na tabela e no formulário:

```typescript
avatar?: string | null
```

### Adicionar Email

```typescript
email?: string | null
```

### Dashboard Avançado

Adicione gráficos de vendas, evolução mensal, etc.

### Relatórios

Crie página de relatórios com vendas por período, comparações, etc.

## 📞 Suporte

Em caso de dúvidas ou problemas:
1. Verificar console do browser (erros JS)
2. Verificar logs do backend
3. Verificar se todas as dependências estão instaladas
4. Verificar se o banco de dados está atualizado

---

**Versão**: 1.0.0  
**Data**: Janeiro 2026  
**Compatibilidade**: Vue 3 + Pinia + Express + Sequelize