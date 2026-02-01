# Solução: MASTER_ADMIN Sem Permissão

## 🔴 Problema
Você está logado como MASTER_ADMIN (systemRoleId=1), mas ainda assim recebe a mensagem:
```
Sem Permissão
Você não tem permissão para visualizar ou criar tenants.
Entre em contato com o administrador do sistema.
```

## 🎯 Causa Raiz
O código estava verificando permissões no banco de dados mesmo para MASTER_ADMIN. Se as permissões não existem na tabela `system_role_permissions`, o MASTER_ADMIN é bloqueado.

## ✅ Solução

### 1. **Backend: Middlewares Corrigidos**

#### addSystemPermissionChecker.js
```javascript
// ✅ MASTER_ADMIN (systemRoleId = 1) SEMPRE tem todas as permissões
if (req.user.systemRoleId === 1) {
  console.log('✅ MASTER_ADMIN tem permissão:', permissionName);
  return true;
}
```

#### checkSystemPermission.js
```javascript
// ✅ MASTER_ADMIN (systemRoleId = 1) SEMPRE tem todas as permissões
if (req.user.systemRoleId === 1) {
  console.log('✅ MASTER_ADMIN autorizado:', requiredPermission);
  return next();
}
```

### 2. **Backend: Controller Corrigido**

#### tenant.controller.js
```javascript
// ✅ MASTER_ADMIN (systemRoleId = 1) pode ver tudo
const isMasterAdmin = user.systemRoleId === 1

// Logs para debug
console.log('👤 User:', {
  id: user.id,
  email: user.email,
  systemRoleId: user.systemRoleId,
  isMasterAdmin
});
```

### 3. **Frontend: Verificação Corrigida**

#### Página de Tenants (Vue)
```javascript
// ✅ Verificar se o usuário é MASTER_ADMIN ou tem permissão
const isMasterAdmin = computed(() => authStore.user?.systemRoleId === 1)
const hasViewAllPermission = computed(() => 
  authStore.hasPermission('tenants.view_all')
)
const canViewTenants = computed(() => 
  isMasterAdmin.value || hasViewAllPermission.value || !!authStore.salesAgentId
)
```

---

## 📋 Checklist de Implementação

### Backend:
- [ ] Substituir `app/middlewares/addSystemPermissionChecker.js`
- [ ] Substituir `app/middlewares/checkSystemPermission.js`
- [ ] Substituir `app/controllers/tenant.controller.js`
- [ ] Reiniciar o servidor Node.js
- [ ] Verificar logs do console

### Frontend:
- [ ] Atualizar lógica de verificação de permissões nas páginas
- [ ] Adicionar logs de debug temporários
- [ ] Testar o login com MASTER_ADMIN
- [ ] Verificar se as permissões são carregadas corretamente

---

## 🔍 Debug: Como Verificar

### 1. **Verificar systemRoleId do Usuário**

No backend (após login):
```javascript
console.log('User:', req.user);
console.log('System Role ID:', req.user.systemRoleId);
```

No frontend (store):
```javascript
console.log('Auth Store User:', authStore.user);
console.log('System Role ID:', authStore.user?.systemRoleId);
```

### 2. **Verificar Fluxo de Permissões**

Backend (middleware):
```javascript
console.log('✅ MASTER_ADMIN tem permissão:', permissionName);
// Deve aparecer no console do servidor
```

Frontend (página):
```javascript
console.log('🔐 Verificação de permissões:', {
  isMasterAdmin: isMasterAdmin.value,
  hasViewAllPermission: hasViewAllPermission.value,
  canViewTenants: canViewTenants.value,
  systemRoleId: authStore.user?.systemRoleId
})
```

### 3. **Testar Rotas da API**

Use ferramentas como Postman ou curl:

```bash
# Listar tenants (deve funcionar para MASTER_ADMIN)
curl -H "Authorization: Bearer SEU_TOKEN" \
  http://localhost:3000/system/tenants

# Criar tenant (deve funcionar para MASTER_ADMIN)
curl -X POST \
  -H "Authorization: Bearer SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"firstName":"Test","email":"test@test.com"}' \
  http://localhost:3000/system/tenants
```

---

## 🚨 Problemas Comuns

### Problema 1: systemRoleId não está sendo enviado
**Sintoma:** `req.user.systemRoleId` é `undefined`

**Solução:**
1. Verificar se o JWT inclui `systemRoleId` no payload
2. Verificar middleware de autenticação
3. Conferir se o `/me` endpoint retorna `systemRoleId`

### Problema 2: Frontend não reconhece MASTER_ADMIN
**Sintoma:** `authStore.user?.systemRoleId` é `undefined` no frontend

**Solução:**
1. Verificar se `fetchMe()` está sendo chamado após login
2. Conferir se o cookie `user` está sendo atualizado corretamente
3. Ver se `systemRoleId` está no objeto `user` do store

### Problema 3: Permissões não carregam no frontend
**Sintoma:** `authStore.userPermissions` está vazio

**Solução:**
1. Chamar `fetchUserPermissions()` após login
2. Ou garantir que `fetchMe()` retorna as permissões
3. Verificar se o backend está retornando as permissões no `/me`

---

## 🎓 Lógica de Permissões

### Hierarquia:
```
1. MASTER_ADMIN (systemRoleId = 1)
   └─ TEM TODAS AS PERMISSÕES (bypass total)

2. Outros roles (systemRoleId > 1)
   └─ Verificam permissões no banco de dados
      ├─ Se tem 'tenants.view_all': vê todos os tenants
      └─ Se não tem: vê apenas seus tenants (salesAgentId)

3. SalesAgent sem role de sistema
   └─ Vê apenas seus tenants (salesAgentId)
```

### Fluxo de Verificação:
```javascript
// 1. Verificar se é MASTER_ADMIN
if (user.systemRoleId === 1) {
  return true; // ✅ Autorizado
}

// 2. Verificar permissão específica no banco
const hasPermission = await checkPermissionInDatabase();
if (hasPermission) {
  return true; // ✅ Autorizado
}

// 3. Verificar se tem salesAgentId (para ver seus próprios tenants)
if (user.salesAgentId) {
  return true; // ✅ Pode ver seus próprios
}

// 4. Negar acesso
return false; // ❌ Sem permissão
```

---

## 📊 Exemplo de Dados

### Tabela: `system_users`
```sql
id | email              | systemRoleId | salesAgentId
---|--------------------|--------------|--------------
1  | admin@example.com  | 1            | NULL
2  | manager@ex.com     | 2            | NULL
3  | agent@example.com  | 3            | 'uuid-123'
```

### Tabela: `system_roles`
```sql
id | name         | label
---|--------------|---------------
1  | MASTER_ADMIN | Master Admin
2  | ADMIN        | Administrator
3  | SALES_AGENT  | Sales Agent
```

### Tabela: `system_role_permissions`
```sql
systemRoleId | systemPermissionId
-------------|--------------------
2            | 1  (tenants.view_all)
2            | 2  (tenants.create)
2            | 3  (tenants.update)
3            | 4  (tenants.create)
```

**Nota:** MASTER_ADMIN (role 1) NÃO precisa de registros em `system_role_permissions` porque tem acesso total por padrão.

---

## 🔒 Segurança

### Boas Práticas:
1. ✅ MASTER_ADMIN sempre bypass as verificações
2. ✅ Outros roles verificam no banco de dados
3. ✅ Logs detalhados para auditoria
4. ✅ Validação tanto no backend quanto no frontend
5. ✅ Mensagens de erro claras para o usuário

### Nunca Fazer:
1. ❌ Confiar apenas na verificação do frontend
2. ❌ Expor detalhes internos nas mensagens de erro
3. ❌ Usar string hardcoded para identificar MASTER_ADMIN
4. ❌ Permitir mudança de systemRoleId via API

---

## 🧪 Testes Recomendados

### Teste 1: Login como MASTER_ADMIN
```javascript
// Deve retornar todos os tenants sem restrição
GET /system/tenants
Expect: 200 OK + lista completa
```

### Teste 2: Login como Admin com Permissões
```javascript
// Deve retornar todos os tenants se tiver 'tenants.view_all'
GET /system/tenants
Expect: 200 OK + lista completa
```

### Teste 3: Login como Sales Agent
```javascript
// Deve retornar apenas tenants do salesAgentId
GET /system/tenants
Expect: 200 OK + lista filtrada
```

### Teste 4: Usuário sem Permissões
```javascript
// Deve retornar erro 403
GET /system/tenants
Expect: 403 Forbidden
```

---

## 📞 Suporte

Se após implementar todas as correções o problema persistir:

1. **Verificar console do backend** - procurar por logs de erro
2. **Verificar console do browser** - ver erros de JavaScript
3. **Verificar Network tab** - ver as respostas da API
4. **Adicionar mais logs** - nos pontos críticos do código
5. **Verificar banco de dados** - conferir dados das tabelas

---

## ✨ Resumo da Solução

A solução implementa um **bypass explícito** para MASTER_ADMIN (systemRoleId = 1) em todos os pontos de verificação de permissão, garantindo que:

1. ✅ MASTER_ADMIN nunca é bloqueado por falta de permissões
2. ✅ Outros roles continuam verificando permissões no banco
3. ✅ Logs detalhados facilitam o debug
4. ✅ Frontend e backend estão sincronizados

**Resultado esperado:** MASTER_ADMIN tem acesso total imediato, sem necessidade de configurar permissões no banco de dados.