# Estratégia Programmatic SEO — Marketplace + SaaS de Barbearias

> Plano completo para escalar até 2.000+ clientes via SEO programático, subdomínios, importação do Google Maps e arquitetura Marketplace + SaaS.

---

## Índice

1. [Visão Geral da Arquitetura](#1-visão-geral-da-arquitetura)
2. [Estrutura de URLs SEO](#2-estrutura-de-urls-seo)
3. [Tabela `barbershops`](#3-tabela-barbershops)
4. [Model Sequelize — `Barbershop`](#4-model-sequelize--barbershop)
5. [Tabela `barbershop_services`](#5-tabela-barbershop_services)
6. [Model Sequelize — `BarbershopService`](#6-model-sequelize--barbershopservice)
7. [Estratégia de Subdomínios](#7-estratégia-de-subdomínios)
8. [Importação de Barbearias do Google Maps](#8-importação-de-barbearias-do-google-maps)
9. [Plano para Escalar até 2.000+ Clientes](#9-plano-para-escalar-até-2000-clientes)

---

## 1. Visão Geral da Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                   MARKETPLACE (SEO)                     │
│         seusite.com.br  /  barbearias.com.br            │
│                                                         │
│  /barbearias/[cidade]         → página de listagem      │
│  /barbearias/[cidade]/[slug]  → página da barbearia     │
│  /servicos/[servico]          → SEO por serviço         │
│  /bairros/[bairro]            → SEO por bairro          │
└────────────────────────┬────────────────────────────────┘
                         │ CTA: "Assine e gerencie"
                         ▼
┌─────────────────────────────────────────────────────────┐
│                     SaaS (Painel)                       │
│              [slug].seusite.com.br                      │
│                                                         │
│  Agenda online    Gestão de clientes    Financeiro      │
│  Fidelidade       Notificações          Relatórios      │
└─────────────────────────────────────────────────────────┘
```

**Conceito principal:** o Marketplace gera tráfego orgânico gratuito para as barbearias, e esse tráfego é o principal argumento de venda para converter donos de barbearia em clientes pagantes do SaaS.

---

## 2. Estrutura de URLs SEO

### 2.1 Páginas de Listagem (alto volume de busca)

| URL | Intenção de busca |
|-----|-------------------|
| `/barbearias/sao-paulo` | "barbearias em são paulo" |
| `/barbearias/sao-paulo/vila-madalena` | "barbearias vila madalena" |
| `/barbearias/rio-de-janeiro` | "barbearias no rio" |
| `/servicos/corte-degrade/sao-paulo` | "onde fazer degradê em sp" |
| `/servicos/barba/curitiba` | "barba curitiba" |

### 2.2 Páginas de Barbearia (conversão)

```
/barbearias/{cidade-slug}/{barbearia-slug}

Exemplos:
  /barbearias/sao-paulo/barber-kings-pinheiros
  /barbearias/curitiba/navalha-de-ouro-centro
  /barbearias/belo-horizonte/barba-bruta-savassi
```

### 2.3 Páginas de Serviço (cauda longa)

```
/servicos/{servico-slug}
/servicos/{servico-slug}/{cidade-slug}

Exemplos:
  /servicos/corte-social
  /servicos/pigmentacao-barba/sao-paulo
  /servicos/design-sobrancelha-masculina/curitiba
```

### 2.4 Regras gerais de slug

- Sempre em **minúsculas**
- Separador: **hífen** (`-`)
- Sem acentos (usar `limax` ou `slugify`)
- Sem caracteres especiais
- Máx. 60 caracteres por segmento

---

## 3. Tabela `barbershops`

```sql
CREATE TABLE barbershops (
  id                  UUID          PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Identificação
  name                VARCHAR(150)  NOT NULL,
  slug                VARCHAR(160)  NOT NULL UNIQUE,
  subdomain           VARCHAR(63)   UNIQUE,           -- ex: "barber-kings"

  -- Status & plano
  status              VARCHAR(20)   NOT NULL DEFAULT 'pending',
                                    -- pending | active | suspended | churned
  plan                VARCHAR(20)   NOT NULL DEFAULT 'free',
                                    -- free | basic | pro | enterprise
  is_claimed          BOOLEAN       NOT NULL DEFAULT FALSE,
  imported_from       VARCHAR(30),                    -- 'google_maps' | 'manual' | 'api'

  -- Contato
  phone               VARCHAR(20),
  whatsapp            VARCHAR(20),
  email               VARCHAR(150),
  website             VARCHAR(255),

  -- Endereço
  street              VARCHAR(200),
  number              VARCHAR(20),
  complement          VARCHAR(100),
  neighborhood        VARCHAR(100),
  city                VARCHAR(100)  NOT NULL,
  city_slug           VARCHAR(110)  NOT NULL,
  state               VARCHAR(2)    NOT NULL,
  zip_code            VARCHAR(9),
  country             VARCHAR(2)    NOT NULL DEFAULT 'BR',

  -- Geolocalização
  latitude            DECIMAL(10,7),
  longitude           DECIMAL(10,7),

  -- SEO & Conteúdo
  description         TEXT,
  meta_title          VARCHAR(70),
  meta_description    VARCHAR(160),
  cover_image_url     VARCHAR(500),
  logo_url            VARCHAR(500),

  -- Avaliações (cache do Google + nativas)
  google_place_id     VARCHAR(100)  UNIQUE,
  google_rating       DECIMAL(2,1),
  google_review_count INT           DEFAULT 0,
  native_rating       DECIMAL(3,2),
  native_review_count INT           DEFAULT 0,

  -- Horários (JSON)
  opening_hours       JSONB,
  /*
    {
      "mon": { "open": "09:00", "close": "20:00" },
      "tue": { "open": "09:00", "close": "20:00" },
      ...
      "sun": null
    }
  */

  -- Dono / conta SaaS
  owner_user_id       UUID          REFERENCES users(id) ON DELETE SET NULL,

  -- Timestamps
  created_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  deleted_at          TIMESTAMPTZ                        -- soft delete
);

-- Índices
CREATE INDEX idx_barbershops_city_slug    ON barbershops (city_slug);
CREATE INDEX idx_barbershops_state        ON barbershops (state);
CREATE INDEX idx_barbershops_status       ON barbershops (status);
CREATE INDEX idx_barbershops_plan         ON barbershops (plan);
CREATE INDEX idx_barbershops_geolocation  ON barbershops USING GIST (
  ll_to_earth(latitude, longitude)
);
CREATE INDEX idx_barbershops_google_place ON barbershops (google_place_id)
  WHERE google_place_id IS NOT NULL;
```

---

## 4. Model Sequelize — `Barbershop`

```javascript
// models/Barbershop.js
const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class Barbershop extends Model {}

Barbershop.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },

    // Identificação
    name: {
      type: DataTypes.STRING(150),
      allowNull: false,
      validate: { notEmpty: true, len: [2, 150] },
    },
    slug: {
      type: DataTypes.STRING(160),
      allowNull: false,
      unique: true,
      validate: { is: /^[a-z0-9-]+$/ },
    },
    subdomain: {
      type: DataTypes.STRING(63),
      allowNull: true,
      unique: true,
      validate: { is: /^[a-z0-9-]+$/ },
    },

    // Status & plano
    status: {
      type: DataTypes.ENUM('pending', 'active', 'suspended', 'churned'),
      defaultValue: 'pending',
      allowNull: false,
    },
    plan: {
      type: DataTypes.ENUM('free', 'basic', 'pro', 'enterprise'),
      defaultValue: 'free',
      allowNull: false,
    },
    isClaimed: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
      field: 'is_claimed',
    },
    importedFrom: {
      type: DataTypes.STRING(30),
      allowNull: true,
      field: 'imported_from',
    },

    // Contato
    phone:    { type: DataTypes.STRING(20),  allowNull: true },
    whatsapp: { type: DataTypes.STRING(20),  allowNull: true },
    email:    { type: DataTypes.STRING(150), allowNull: true, validate: { isEmail: true } },
    website:  { type: DataTypes.STRING(255), allowNull: true, validate: { isUrl: true } },

    // Endereço
    street:       { type: DataTypes.STRING(200), allowNull: true },
    number:       { type: DataTypes.STRING(20),  allowNull: true },
    complement:   { type: DataTypes.STRING(100), allowNull: true },
    neighborhood: { type: DataTypes.STRING(100), allowNull: true },
    city:         { type: DataTypes.STRING(100), allowNull: false },
    citySlug:     { type: DataTypes.STRING(110), allowNull: false, field: 'city_slug' },
    state:        { type: DataTypes.STRING(2),   allowNull: false, validate: { len: [2, 2] } },
    zipCode:      { type: DataTypes.STRING(9),   allowNull: true, field: 'zip_code' },
    country:      { type: DataTypes.STRING(2),   defaultValue: 'BR', field: 'country' },

    // Geolocalização
    latitude:  { type: DataTypes.DECIMAL(10, 7), allowNull: true },
    longitude: { type: DataTypes.DECIMAL(10, 7), allowNull: true },

    // SEO & Conteúdo
    description:      { type: DataTypes.TEXT,        allowNull: true },
    metaTitle:        { type: DataTypes.STRING(70),   allowNull: true, field: 'meta_title' },
    metaDescription:  { type: DataTypes.STRING(160),  allowNull: true, field: 'meta_description' },
    coverImageUrl:    { type: DataTypes.STRING(500),  allowNull: true, field: 'cover_image_url' },
    logoUrl:          { type: DataTypes.STRING(500),  allowNull: true, field: 'logo_url' },

    // Google
    googlePlaceId:    { type: DataTypes.STRING(100),  allowNull: true, unique: true, field: 'google_place_id' },
    googleRating:     { type: DataTypes.DECIMAL(2, 1),allowNull: true, field: 'google_rating' },
    googleReviewCount:{ type: DataTypes.INTEGER,      defaultValue: 0, field: 'google_review_count' },
    nativeRating:     { type: DataTypes.DECIMAL(3, 2),allowNull: true, field: 'native_rating' },
    nativeReviewCount:{ type: DataTypes.INTEGER,      defaultValue: 0, field: 'native_review_count' },

    // Horários
    openingHours: {
      type: DataTypes.JSONB,
      allowNull: true,
      field: 'opening_hours',
    },

    // Owner
    ownerUserId: {
      type: DataTypes.UUID,
      allowNull: true,
      field: 'owner_user_id',
      references: { model: 'users', key: 'id' },
    },

    // Soft delete
    deletedAt: { type: DataTypes.DATE, allowNull: true, field: 'deleted_at' },
  },
  {
    sequelize,
    modelName: 'Barbershop',
    tableName: 'barbershops',
    underscored: true,
    paranoid: true, // habilita soft delete via deletedAt
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
  }
);

// --- Associações ---
Barbershop.associate = (models) => {
  Barbershop.hasMany(models.BarbershopService, {
    foreignKey: 'barbershop_id',
    as: 'services',
  });
  Barbershop.belongsTo(models.User, {
    foreignKey: 'owner_user_id',
    as: 'owner',
  });
  Barbershop.hasMany(models.Review, {
    foreignKey: 'barbershop_id',
    as: 'reviews',
  });
  Barbershop.hasMany(models.Appointment, {
    foreignKey: 'barbershop_id',
    as: 'appointments',
  });
};

module.exports = Barbershop;
```

---

## 5. Tabela `barbershop_services`

```sql
CREATE TABLE barbershop_services (
  id              UUID          PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Relacionamento
  barbershop_id   UUID          NOT NULL
                    REFERENCES barbershops(id) ON DELETE CASCADE,

  -- Serviço
  name            VARCHAR(120)  NOT NULL,
  slug            VARCHAR(130)  NOT NULL,
  category        VARCHAR(60),              -- 'corte' | 'barba' | 'tratamento' | 'combo'
  description     TEXT,

  -- Preço
  price           DECIMAL(8,2)  NOT NULL,
  price_min       DECIMAL(8,2),             -- para serviços com faixa de preço
  price_max       DECIMAL(8,2),

  -- Duração
  duration_min    INT           NOT NULL DEFAULT 30,  -- em minutos

  -- Visibilidade
  is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
  is_featured     BOOLEAN       NOT NULL DEFAULT FALSE,  -- destaque na página

  -- SEO (para páginas de serviço)
  seo_tag         VARCHAR(100),             -- tag canônica (ex: "corte-degrade")

  -- Ordenação
  sort_order      INT           NOT NULL DEFAULT 0,

  -- Timestamps
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- Índices
CREATE INDEX idx_bs_services_barbershop   ON barbershop_services (barbershop_id);
CREATE INDEX idx_bs_services_category     ON barbershop_services (category);
CREATE INDEX idx_bs_services_seo_tag      ON barbershop_services (seo_tag)
  WHERE seo_tag IS NOT NULL;
CREATE INDEX idx_bs_services_active       ON barbershop_services (barbershop_id, is_active)
  WHERE is_active = TRUE;

-- Constraint: slug único por barbearia
ALTER TABLE barbershop_services
  ADD CONSTRAINT uq_bs_service_slug UNIQUE (barbershop_id, slug);
```

---

## 6. Model Sequelize — `BarbershopService`

```javascript
// models/BarbershopService.js
const { DataTypes, Model } = require('sequelize');
const sequelize = require('../config/database');

class BarbershopService extends Model {}

BarbershopService.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },

    barbershopId: {
      type: DataTypes.UUID,
      allowNull: false,
      field: 'barbershop_id',
      references: { model: 'barbershops', key: 'id' },
      onDelete: 'CASCADE',
    },

    name: {
      type: DataTypes.STRING(120),
      allowNull: false,
      validate: { notEmpty: true, len: [2, 120] },
    },
    slug: {
      type: DataTypes.STRING(130),
      allowNull: false,
      validate: { is: /^[a-z0-9-]+$/ },
    },
    category: {
      type: DataTypes.STRING(60),
      allowNull: true,
      // Sugestão: usar ENUM quando categorias forem fechadas
      // type: DataTypes.ENUM('corte', 'barba', 'tratamento', 'combo', 'outro'),
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true,
    },

    // Preço
    price: {
      type: DataTypes.DECIMAL(8, 2),
      allowNull: false,
      validate: { min: 0 },
    },
    priceMin: {
      type: DataTypes.DECIMAL(8, 2),
      allowNull: true,
      field: 'price_min',
    },
    priceMax: {
      type: DataTypes.DECIMAL(8, 2),
      allowNull: true,
      field: 'price_max',
    },

    // Duração
    durationMin: {
      type: DataTypes.INTEGER,
      defaultValue: 30,
      allowNull: false,
      field: 'duration_min',
      validate: { min: 5, max: 480 },
    },

    // Flags
    isActive: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
      field: 'is_active',
    },
    isFeatured: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
      field: 'is_featured',
    },

    // SEO
    seoTag: {
      type: DataTypes.STRING(100),
      allowNull: true,
      field: 'seo_tag',
    },

    sortOrder: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
      field: 'sort_order',
    },
  },
  {
    sequelize,
    modelName: 'BarbershopService',
    tableName: 'barbershop_services',
    underscored: true,
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    indexes: [
      { unique: true, fields: ['barbershop_id', 'slug'] },
    ],
  }
);

BarbershopService.associate = (models) => {
  BarbershopService.belongsTo(models.Barbershop, {
    foreignKey: 'barbershop_id',
    as: 'barbershop',
  });
};

module.exports = BarbershopService;
```

---

## 7. Estratégia de Subdomínios

### 7.1 Como funciona

Cada barbearia que assina o plano pago ganha um subdomínio exclusivo:

```
barber-kings.seusite.com.br     → painel + agenda pública
navalha-de-ouro.seusite.com.br  → painel + agenda pública
```

### 7.2 Configuração no servidor (Nginx wildcard)

```nginx
# /etc/nginx/conf.d/wildcard.conf

server {
  listen 80;
  server_name ~^(?<subdomain>[a-z0-9-]+)\.seusite\.com\.br$;

  location / {
    proxy_pass http://localhost:3000;
    proxy_set_header Host             $host;
    proxy_set_header X-Subdomain      $subdomain;
    proxy_set_header X-Real-IP        $remote_addr;
    proxy_set_header X-Forwarded-For  $proxy_add_x_forwarded_for;
  }
}
```

> **DNS:** configurar um registro `*.seusite.com.br` apontando para o seu IP.

### 7.3 Leitura do subdomínio no Node.js / Express

```javascript
// middleware/subdomainResolver.js
const Barbershop = require('../models/Barbershop');

module.exports = async (req, res, next) => {
  const subdomain =
    req.headers['x-subdomain'] ||
    req.hostname.split('.')[0];

  // Ignora o domínio raiz e o www
  const reserved = ['www', 'app', 'api', 'admin', 'seusite'];
  if (!subdomain || reserved.includes(subdomain)) return next();

  const shop = await Barbershop.findOne({
    where: { subdomain, status: 'active' },
  });

  if (!shop) return res.status(404).send('Barbearia não encontrada');

  req.barbershop = shop;
  next();
};
```

### 7.4 Separação de contextos por subdomínio

| Subdomínio | Comportamento |
|---|---|
| `seusite.com.br` | Marketplace público (SEO) |
| `app.seusite.com.br` | Painel administrativo (SaaS) |
| `api.seusite.com.br` | API REST/GraphQL |
| `[slug].seusite.com.br` | Página pública da barbearia + agendamento |

---

## 8. Importação de Barbearias do Google Maps

### 8.1 Fluxo geral

```
Google Places API (Text Search / Nearby Search)
        ↓
  Normalização dos dados
        ↓
  Verificação de duplicata (google_place_id)
        ↓
  Inserção no banco com status = 'pending' / is_claimed = false
        ↓
  Geração automática de slug + meta SEO
        ↓
  Página pública criada → começa a ranquear
        ↓
  Dono encontra a barbearia no Google → faz claim → vira cliente SaaS
```

### 8.2 Script de importação

```javascript
// scripts/importFromGoogleMaps.js
const axios = require('axios');
const slugify = require('slugify');
const Barbershop = require('../models/Barbershop');

const GOOGLE_API_KEY = process.env.GOOGLE_MAPS_API_KEY;

async function searchBarbershops(city, pageToken = null) {
  const params = {
    query: `barbearia ${city}`,
    key: GOOGLE_API_KEY,
    language: 'pt-BR',
    type: 'hair_care',
  };
  if (pageToken) params.pagetoken = pageToken;

  const { data } = await axios.get(
    'https://maps.googleapis.com/maps/api/place/textsearch/json',
    { params }
  );
  return data;
}

async function getPlaceDetails(placeId) {
  const { data } = await axios.get(
    'https://maps.googleapis.com/maps/api/place/details/json',
    {
      params: {
        place_id: placeId,
        key: GOOGLE_API_KEY,
        fields: 'name,formatted_address,geometry,formatted_phone_number,website,opening_hours,rating,user_ratings_total,photos',
        language: 'pt-BR',
      },
    }
  );
  return data.result;
}

function parseOpeningHours(periods) {
  if (!periods) return null;
  const days = ['sun','mon','tue','wed','thu','fri','sat'];
  const result = {};
  days.forEach(d => result[d] = null);

  periods.forEach(({ open, close }) => {
    const day = days[open.day];
    result[day] = {
      open: `${open.time.slice(0,2)}:${open.time.slice(2)}`,
      close: close ? `${close.time.slice(0,2)}:${close.time.slice(2)}` : '23:59',
    };
  });
  return result;
}

async function importCity(cityName, citySlug, state) {
  let pageToken = null;
  let imported = 0;

  do {
    const data = await searchBarbershops(cityName, pageToken);

    for (const place of data.results) {
      // Verifica duplicata
      const exists = await Barbershop.findOne({
        where: { googlePlaceId: place.place_id },
      });
      if (exists) continue;

      // Busca detalhes completos
      const details = await getPlaceDetails(place.place_id);

      const name = details.name;
      const baseSlug = slugify(name, { lower: true, strict: true });
      let slug = `${baseSlug}-${citySlug}`;

      // Garante slug único
      const count = await Barbershop.count({ where: { slug } });
      if (count > 0) slug = `${slug}-${Date.now()}`;

      await Barbershop.create({
        name,
        slug,
        city: cityName,
        citySlug,
        state,
        status: 'active',
        plan: 'free',
        isClaimed: false,
        importedFrom: 'google_maps',
        googlePlaceId: place.place_id,
        googleRating: details.rating || null,
        googleReviewCount: details.user_ratings_total || 0,
        latitude: details.geometry?.location?.lat,
        longitude: details.geometry?.location?.lng,
        phone: details.formatted_phone_number || null,
        website: details.website || null,
        openingHours: parseOpeningHours(details.opening_hours?.periods),
        metaTitle: `${name} — Barbearia em ${cityName}`,
        metaDescription: `Agende seu corte na ${name}, barbearia em ${cityName}. Veja serviços, horários e avalie!`,
      });

      imported++;
      // Respeita rate limit da API
      await new Promise(r => setTimeout(r, 200));
    }

    pageToken = data.next_page_token || null;
    if (pageToken) await new Promise(r => setTimeout(r, 2000)); // Google exige delay
  } while (pageToken);

  console.log(`✅ ${imported} barbearias importadas de ${cityName}`);
}

// Uso:
// node scripts/importFromGoogleMaps.js
(async () => {
  const cidades = [
    { name: 'São Paulo',        slug: 'sao-paulo',        state: 'SP' },
    { name: 'Rio de Janeiro',   slug: 'rio-de-janeiro',   state: 'RJ' },
    { name: 'Belo Horizonte',   slug: 'belo-horizonte',   state: 'MG' },
    { name: 'Curitiba',         slug: 'curitiba',         state: 'PR' },
    { name: 'Porto Alegre',     slug: 'porto-alegre',     state: 'RS' },
  ];

  for (const cidade of cidades) {
    await importCity(cidade.name, cidade.slug, cidade.state);
  }
})();
```

### 8.3 Custo estimado da API

| Volume | Custo aprox. (Google Places) |
|--------|------------------------------|
| 1.000 barbearias | ~US$ 17 (Text Search + Details) |
| 10.000 barbearias | ~US$ 170 |
| 50.000 barbearias | ~US$ 850 |

> Alternativa mais barata: **scraping via Google Maps** com `playwright` ou usar dados públicos do **OpenStreetMap** (gratuito, categoria `amenity=barbershop`).

---

## 9. Plano para Escalar até 2.000+ Clientes

### 9.1 Funil de conversão

```
TOPO: Barbearias importadas do Google Maps (gratuito, não reclamadas)
         ↓  ranqueia no Google, gera tráfego
MEIO:  Dono da barbearia encontra a página → faz "claim"
         ↓  cria conta, valida telefone/e-mail
FUNDO: Trial gratuito de 14 dias do plano Pro
         ↓  onboarding → vê valor → converte para plano pago
RETENÇÃO: agenda, clientes, relatórios, fidelidade
```

### 9.2 Roadmap por fase

#### Fase 1 — Fundação (0–3 meses) · Meta: 100 clientes

| Ação | Detalhe |
|------|---------|
| Importar 5.000 barbearias | 10 maiores cidades do Brasil |
| Páginas SEO automáticas | cidade + barbearia + serviço |
| Sistema de claim | e-mail / WhatsApp + verificação |
| Plano Free funcional | página pública + link de agendamento básico |
| Trial 14 dias do Pro | sem cartão de crédito |

#### Fase 2 — Tração (3–6 meses) · Meta: 500 clientes

| Ação | Detalhe |
|------|---------|
| Expandir para 50 cidades | cobertura nacional |
| SEO de bairros | `/bairros/[bairro]` + `/barbearias/[cidade]/[bairro]` |
| Reviews nativos | sistema próprio de avaliação pós-corte |
| App mobile (PWA) | para barbeiros e clientes |
| Outreach ativo | WhatsApp automático para não reclamadas |

#### Fase 3 — Escala (6–12 meses) · Meta: 2.000+ clientes

| Ação | Detalhe |
|------|---------|
| 100k+ páginas indexadas | todas cidades BR + serviços + bairros |
| Programa de afiliados | barbeiros indicam outros barbeiros |
| Planos por região | franqueados / revendedores regionais |
| Integrações | Google Calendar, Mercado Pago, PagSeguro |
| API pública | para parceiros e integradores |

### 9.3 Estrutura de planos SaaS

| Plano | Preço/mês | Recursos |
|-------|-----------|----------|
| **Free** | R$ 0 | Página pública, perfil básico, link externo |
| **Basic** | R$ 49 | + Agenda online, até 2 profissionais |
| **Pro** | R$ 99 | + Clientes ilimitados, relatórios, notificações, subdomínio próprio |
| **Enterprise** | R$ 249 | + Multi-unidade, API, suporte prioritário, white-label |

### 9.4 Métricas de acompanhamento

```
MRR (Monthly Recurring Revenue)
ARR (Annual Recurring Revenue)
Churn rate mensal (meta: < 3%)
CAC (Custo de Aquisição de Cliente)
LTV (Lifetime Value)
Taxa de claim (meta: > 15% das barbearias importadas)
Taxa de conversão trial → pago (meta: > 25%)
Páginas indexadas no Google Search Console
Tráfego orgânico mensal
```

### 9.5 Projeção de receita

| Mês | Clientes | MRR estimado |
|-----|----------|-------------|
| 3   | 100      | R$ 6.000    |
| 6   | 500      | R$ 35.000   |
| 12  | 2.000    | R$ 150.000  |
| 18  | 5.000    | R$ 400.000  |

> Baseado em ticket médio de R$ 70–80/mês (mix de planos Basic + Pro).

---

## Próximos passos recomendados

- [x] Configurar banco de dados com as migrations das duas tabelas
- [ ] Criar script de seed para testar importação com uma cidade
- [x] Configurar DNS wildcard + middleware de subdomínio # já tenho tudo confgurado no projeto white-label
- [x] Implementar geração automática de `sitemap.xml` dinâmico
- [x] Configurar Google Search Console e submeter sitemap
- [ ] Criar fluxo de claim com verificação por SMS/WhatsApp

---

*Documento gerado em março de 2026.*