# Nova Lista de Tenants - Documentação

## 🎯 Melhorias Implementadas

### 1. **Sistema de Permissões Robusto**
- ✅ Verifica corretamente `systemRoleId === 1` para MASTER_ADMIN
- ✅ Verifica permissões individuais (`tenants.view_all`, `tenants.create`, etc.)
- ✅ Suporta usuários com `salesAgentId` (veem apenas seus tenants)
- ✅ Mensagem clara quando não há permissões
- ✅ Debug info toggleável para troubleshooting

### 2. **Interface Responsiva**
- 📱 **Mobile**: Cards otimizados para telas pequenas
- 💻 **Desktop**: Tabela completa com todas as informações
- 🎨 Design moderno com Tailwind CSS
- ⚡ Animações suaves e feedback visual

### 3. **Funcionalidades Avançadas**
- 🔍 **Busca em tempo real** com debounce (500ms)
- 🎛️ **Filtros múltiplos**:
  - Status (Ativo, Inativo, Trial, Suspenso)
  - Sales Agent (apenas para usuários com `view_all`)
  - Busca por texto (nome, email, CPF, CNPJ)
- 🧹 Botão para limpar todos os filtros
- 📊 Contador de tenants

### 4. **Estados da Interface**
- ⏳ **Loading**: Spinner animado durante carregamento
- 📭 **Empty State**: Mensagem amigável quando não há tenants
- ⚠️ **Sem Permissão**: Explicação clara com opção de debug
- ❌ **Erro**: Tratamento adequado de erros da API

### 5. **Ações Contextuais**
- ✏️ **Editar**: Apenas se tiver permissão `tenants.update`
- 🗑️ **Excluir**: Apenas se tiver permissão `tenants.delete` + confirmação
- 👁️ **Ver Detalhes**: Ao clicar em qualquer lugar do card/linha
- ➕ **Criar**: Botão destacado se tiver permissão `tenants.create`

### 6. **Segurança e Validação**
- 🔒 Todas as ações verificam permissões antes de executar
- 🚫 Alertas amigáveis quando usuário não tem permissão
- 🔐 Respeita a hierarquia: MASTER_ADMIN > permissões específicas > salesAgentId
- 📝 Logs detalhados no console para debug

---

## 📋 Estrutura de Permissões

### Hierarquia de Acesso:

```
1. MASTER_ADMIN (systemRoleId = 1)
   └─ Acesso total a tudo, sem restrições

2. Admin/Manager com 'tenants.view_all'
   ├─ Vê todos os tenants
   ├─ Pode filtrar por salesAgent
   └─ Ações dependem de outras permissões

3. Sales Agent (com salesAgentId)
   ├─ Vê apenas tenants vinculados a ele
   ├─ Não pode filtrar por outros salesAgents
   └─ Ações dependem de permissões

4. Usuário sem permissões
   └─ Não acessa a lista de tenants
```

### Permissões Verificadas:

| Permissão | Descrição | Efeito |
|-----------|-----------|--------|
| `tenants.view_all` | Ver todos os tenants | Acesso irrestrito à lista |
| `tenants.create` | Criar tenants | Mostra botão "Criar Tenant" |
| `tenants.update` | Editar tenants | Mostra botão "Editar" |
| `tenants.delete` | Excluir tenants | Mostra botão "Excluir" |

---

## 🎨 Componentes da Interface

### Header
```vue
<div class="flex justify-between">
  <div>
    <h1>Tenants</h1>
    <p>X tenants ativos</p>
  </div>
  <button v-if="canCreate">Criar Tenant</button>
</div>
```

### Filtros
```vue
<div class="filters">
  <select v-model="statusFilter">Status</select>
  <select v-if="canViewAll">Sales Agent</select>
  <input v-model="searchQuery" placeholder="Buscar...">
  <button v-if="hasActiveFilters">Limpar</button>
</div>
```

### Desktop: Tabela
```
| Tenant | Contato | Status | Vendedor* | Ações |
|--------|---------|--------|-----------|-------|
| Avatar | Email   | Badge  | Nome      | Icons |
| Nome   | Phone   |        |           |       |
```
*Coluna "Vendedor" só aparece para usuários com `canViewAll`

### Mobile: Cards
```
┌─────────────────────────────┐
│ 🔵 Avatar                   │
│    Nome                     │
│    Empresa                  │
│    📧 Email                 │
│    📱 Telefone              │
│    👨‍💼 Vendedor*            │
│    [Editar] [Excluir]      │
└─────────────────────────────┘
```

---

## 🔧 Uso e Configuração

### Instalação
Copie o arquivo `tenants-list-rewritten.vue` para:
```
pages/admin/tenants/index.vue
```

### Dependências
- ✅ `@/stores/useTenant` - Store de tenants (Pinia)
- ✅ `@/stores/auth` - Store de autenticação (Pinia)
- ✅ `vue-router` - Navegação
- ✅ Tailwind CSS - Estilos

### Rotas Esperadas
```javascript
/admin/tenants              // Lista (este componente)
/admin/tenants/novo         // Criar novo
/admin/tenants/:id          // Ver detalhes
/admin/tenants/:id/editar   // Editar
```

---

## 🧪 Testes Recomendados

### Teste 1: MASTER_ADMIN
```
✅ Deve ver todos os tenants
✅ Deve ver coluna "Vendedor"
✅ Deve poder filtrar por Sales Agent
✅ Deve ver todos os botões de ação
✅ Não deve ver mensagem de "Sem Permissão"
```

### Teste 2: Admin com view_all
```
✅ Deve ver todos os tenants
✅ Deve ver coluna "Vendedor"
✅ Deve poder filtrar por Sales Agent
✅ Botões de ação dependem de outras permissões
```

### Teste 3: Sales Agent
```
✅ Deve ver apenas seus tenants
❌ Não deve ver coluna "Vendedor"
❌ Não deve poder filtrar por Sales Agent
✅ Botões de ação dependem de permissões
```

### Teste 4: Usuário sem Permissões
```
❌ Deve ver mensagem "Sem Permissão"
❌ Não deve carregar lista de tenants
✅ Deve poder visualizar debug info
```

---

## 🐛 Troubleshooting

### Problema: "Sem Permissão" para MASTER_ADMIN
**Causa:** `systemRoleId` não está definido ou não é `1`

**Solução:**
1. Verificar se `authStore.user.systemRoleId === 1`
2. Verificar se `authStore.user.systemRole === 'MASTER_ADMIN'`
3. Ativar debug info para ver os valores
4. Verificar se o backend está retornando `systemRoleId` no `/me`

### Problema: Lista vazia mesmo tendo tenants
**Causa:** Permissões ou filtros incorretos

**Solução:**
1. Verificar logs do console
2. Abrir Network tab e ver a resposta da API
3. Verificar se o filtro de `salesAgentId` está correto
4. Limpar filtros com o botão "Limpar"

### Problema: Botões de ação não aparecem
**Causa:** Usuário não tem as permissões necessárias

**Solução:**
1. Verificar `userPermissions` no debug info
2. Conferir se as permissões estão sendo carregadas do backend
3. MASTER_ADMIN deve ver todos os botões automaticamente

### Problema: Erro ao filtrar
**Causa:** Backend não suporta os parâmetros de filtro

**Solução:**
1. Verificar se o backend aceita `status`, `salesAgentId`, `search`
2. Ver logs do servidor para identificar erro
3. Ajustar os parâmetros enviados no `fetchTenantsWithFilters`

---

## 📊 Dados Esperados

### Tenant Object (TenantUI)
```typescript
interface TenantUI {
  id: number
  firstName: string
  lastName: string | null
  fullName?: string // gerado automaticamente
  email: string | null
  avatar: string | null
  officeName: string | null
  cpf: string | null
  cnpj: string | null
  phone: string | null
  mobilePhone: string | null
  tenantStatusId: number | null
  salesAgentId: string | null
  status?: {
    name: string
    color: string
  }
  salesAgent?: {
    id: string
    firstName: string
    lastName: string
    email: string
  }
}
```

### Auth User Object
```typescript
interface User {
  id: number
  email: string
  systemRoleId: number // 1 = MASTER_ADMIN
  systemRole?: string // 'MASTER_ADMIN'
  salesAgentId?: string | null
  permissions: string[] // ['tenants.view_all', 'tenants.create', ...]
}
```

---

## 🚀 Próximas Melhorias Sugeridas

### Features:
- [ ] Paginação (carregar mais resultados)
- [ ] Ordenação por coluna (nome, data, status)
- [ ] Exportar para CSV/Excel
- [ ] Ações em lote (excluir múltiplos)
- [ ] Quick actions (ativar/desativar status)
- [ ] Visualização em grid (além de lista)

### UX:
- [ ] Skeleton loading (em vez de spinner)
- [ ] Toast notifications (sucesso/erro)
- [ ] Animações de transição entre estados
- [ ] Drag & drop para reordenar
- [ ] Favoritos/Pins

### Performance:
- [ ] Virtual scrolling para listas grandes
- [ ] Cache de filtros no localStorage
- [ ] Lazy loading de imagens
- [ ] Prefetch de detalhes ao hover

---

## 📝 Changelog

### v2.0.0 - Reescrita Completa
- ✨ Nova interface responsiva
- ✨ Sistema de permissões robusto
- ✨ Filtros avançados com debounce
- ✨ Estados de loading/empty/error
- ✨ Debug info toggleável
- ✨ Mobile-first design
- 🐛 Corrigido problema com MASTER_ADMIN
- 🐛 Corrigido verificação de permissões
- 📚 Documentação completa

---

## 💡 Dicas de Uso

1. **Debug Mode**: Ative o modo debug quando estiver troubleshooting permissões
2. **Console Logs**: Monitore o console durante desenvolvimento
3. **Network Tab**: Verifique as requisições para identificar problemas de API
4. **Permissões**: Configure corretamente as permissões no backend
5. **MASTER_ADMIN**: Sempre teste com MASTER_ADMIN primeiro

---

## 🤝 Suporte

Se encontrar problemas:
1. Ative o debug info na interface
2. Verifique os logs do console (frontend e backend)
3. Confirme que o backend está retornando os dados corretos
4. Verifique se todas as permissões estão configuradas