# 📊 Sistema de Relatórios Otimizado com Limites de Plano

## 🎯 O que foi criado

### 1️⃣ **Backend (Controller + Routes)**
- ✅ `dashboard.controller.js` — Controller otimizado com 8 endpoints de relatórios
- ✅ `dashboard.routes.js` — Rotas com proteção de limites via `subscriptionGuard`

### 2️⃣ **Frontend (Pages + Composables)**
- ✅ `relatorios.vue` — Página completa de relatórios com verificação de acesso
- ✅ `useDashboard.ts` — Composable tipado para consumir a API

### 3️⃣ **Seeds Corrigidos**
- ✅ `seeds-corrigido.js` — Seeds com UTF-8 forçado para evitar ### nos acentos

---

## 🚀 Como Implementar

### **Passo 1: Backend**

Substitua o controller existente:
```bash
# Copie o arquivo dashboard.controller.js para:
backend/src/controllers/dashboard.controller.js
```

Substitua as rotas existentes:
```bash
# Copie o arquivo dashboard.routes.js para:
backend/src/routes/dashboard.routes.js
```

### **Passo 2: Frontend**

Crie a página de relatórios:
```bash
# Copie o arquivo relatorios.vue para:
frontend/pages/admin/relatorios.vue
```

Crie o composable:
```bash
# Copie o arquivo useDashboard.ts para:
frontend/composables/useDashboard.ts
```

### **Passo 3: Seeds (Corrigir Acentos)**

Rode o seed corrigido:
```bash
# No backend, rode:
npx sequelize-cli db:seed:all --seeders-path seeders/corrigido
```

Ou execute manualmente no MySQL Workbench:
```sql
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- Cole aqui os INSERTs do arquivo seeds-corrigido.js
```

---

## 📋 Endpoints Disponíveis

### **Básicos (todos os planos)**
```
GET /dashboard/overview        — Métricas principais
GET /dashboard/daily-chart     — Gráfico diário de agendamentos
```

### **Premium (requer feature 'relatorios')**
```
GET /dashboard/revenue          — Faturamento por período
GET /dashboard/top-services     — Top 10 serviços mais vendidos
GET /dashboard/top-employees    — Top 10 funcionários
GET /dashboard/peak-hours       — Horários de pico
GET /dashboard/client-activity  — Clientes novos vs recorrentes
GET /dashboard/monthly-revenue  — Receita mensal (gráfico anual)
```

---

## 🔒 Proteção de Limites

### **Como funciona**

1. **Backend** — O middleware `subscriptionGuard` bloqueia endpoints premium:
```javascript
router.get(
  '/revenue',
  subscriptionGuard({ requireFeatures: ['relatorios'] }),
  DashboardController.revenue
);
```

2. **Frontend** — A página verifica acesso ANTES de renderizar:
```vue
<template>
  <div v-if="!hasReportsAccess">
    ⚠️ Relatórios não disponíveis no seu plano
  </div>
  <div v-else>
    <!-- Conteúdo dos relatórios -->
  </div>
</template>

<script setup>
const { getLimit } = usePlan()

const hasReportsAccess = computed(() => {
  const limit = getLimit('relatorios')
  return limit === 'true' || limit === true || limit === 'Ilimitado'
})
</script>
```

---

## 🎨 Features da Página de Relatórios

### ✅ **Cards de Métricas**
- 💰 Receita Total
- 📅 Total de Agendamentos
- 👥 Clientes Ativos
- ✅ Taxa de Comparecimento

### ✅ **Gráficos Interativos**
- 📈 Receita Diária (Line Chart)
- ⏰ Horários de Pico (Bar Chart)

### ✅ **Rankings**
- 🏆 Top 5 Serviços Mais Vendidos
- 👨‍💼 Top 5 Funcionários

### ✅ **Filtros de Período**
- Últimos 7 dias
- Últimos 30 dias
- Últimos 90 dias
- Período personalizado (data início/fim)

### ✅ **Exportação (Premium)**
- Botão de exportar (apenas planos >= 3)
- Mostra modal de upgrade se não tiver acesso

---

## 🔧 Otimizações Implementadas

### **1. Queries Otimizadas**
- ✅ Uso de `fn()` e `col()` do Sequelize para agregações
- ✅ Joins apenas quando necessário
- ✅ Índices implícitos em `tenantId`, `start`, `createdAt`

### **2. Cache-Ready**
- ✅ Endpoints separados (fácil cachear individualmente)
- ✅ Parâmetros de data para invalidar cache

### **3. Segurança**
- ✅ Autenticação obrigatória em todas as rotas
- ✅ Validação de plano no backend (subscriptionGuard)
- ✅ Validação de plano no frontend (composable)

---

## 🗂️ Estrutura de Planos

| Plano | ID | Relatórios | Exportar |
|-------|-----|-----------|----------|
| **Free** | 1 | ❌ | ❌ |
| **Solo** | 2 | ❌ | ❌ |
| **Equipe Pequena** | 3 | ✅ | ✅ |
| **Equipe Média** | 4 | ✅ | ✅ |
| **Avançada** | 5 | ✅ | ✅ |

---

## 📝 TODO (Próximos Passos)

### Backend
- [ ] Implementar cache Redis nos endpoints de relatórios
- [ ] Adicionar endpoint de exportação (CSV/PDF)
- [ ] Criar índices específicos para otimizar queries pesadas

### Frontend
- [ ] Adicionar skeleton loading nos gráficos
- [ ] Implementar exportação em CSV
- [ ] Adicionar comparação de períodos (ex: vs mês anterior)
- [ ] Criar dashboard personalizável (drag & drop widgets)

### Seeds
- [ ] Verificar charset das tabelas no banco
```sql
SHOW CREATE TABLE plans;
SHOW CREATE TABLE features;
SHOW CREATE TABLE plan_features;
```

---

## 🐛 Troubleshooting

### **Acentos aparecem como ###**

**Solução:**
```sql
-- 1. Alterar charset do database
ALTER DATABASE seu_database CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 2. Alterar charset das tabelas
ALTER TABLE plans CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE features CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 3. Rodar seeds novamente
npx sequelize-cli db:seed:all
```

### **Relatórios não aparecem**

**Checklist:**
1. ✅ Usuário está autenticado?
2. ✅ Plano do tenant tem `relatorios: 'true'`?
3. ✅ `fetchPlan()` foi chamado no plugin?
4. ✅ `isLoaded` está `true` nas stores?

```javascript
// Debug no console do navegador:
const plan = usePlan()
console.log('Plano atual:', plan.currentPlan.value)
console.log('Features:', plan.features.value)
console.log('Tem relatórios?', plan.getLimit('relatorios'))
```

---

## 📚 Referências

- [Sequelize Aggregations](https://sequelize.org/docs/v6/core-concepts/model-querying-basics/#aggregations)
- [Chart.js Documentation](https://www.chartjs.org/docs/latest/)
- [Vue 3 Composition API](https://vuejs.org/guide/extras/composition-api-faq.html)

---

## 🎉 Conclusão

Agora você tem:
✅ Sistema de relatórios completo  
✅ Proteção por limites de plano  
✅ Seeds com acentos corrigidos  
✅ Frontend responsivo e otimizado  
✅ Backend com queries performáticas  

**Bora testar! 🚀**