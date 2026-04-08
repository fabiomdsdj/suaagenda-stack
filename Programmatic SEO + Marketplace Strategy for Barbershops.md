# Programmatic SEO + Marketplace Strategy for Barbershops

## Objective

Build a platform that captures Google traffic for barbershops and
converts barbers into users of an online scheduling system.

This combines:

-   **Programmatic SEO**
-   **Local marketplace listings**
-   **SaaS scheduling product**

Growth models similar to platforms like Fresha, Booksy and Treatwell.

------------------------------------------------------------------------

# 1. Core SEO Structure

Generate pages automatically:

    /barbearias/{cidade}
    /barbearias/{cidade}/{bairro}
    /barbeiros/{cidade}
    /servicos/{servico}/{cidade}
    /servicos/{servico}/{cidade}/{bairro}

Examples:

    /barbearias/santos
    /barbearias/santos/gonzaga
    /barbearias/santos/boqueirao

These pages capture searches like:

-   barbearia em santos
-   barbearia gonzaga
-   barbeiro perto

High purchase intent traffic.

------------------------------------------------------------------------

# 2. Marketplace Listing Strategy

List **all barbershops in the city**, not only users of your system.

Example page:

    Barbearias no Gonzaga – Santos

    • Barbearia Navalha
    • Barbearia Old School
    • Barbearia Canal 3

Then show:

    Esta barbearia ainda não usa agenda online.

    É dono desta barbearia?
    Crie sua agenda grátis em 5 minutos.

This converts barbers automatically.

------------------------------------------------------------------------

# 3. Growth Loop

Traffic flow:

    Google Search
       ↓
    SEO page (/barbearias/santos/gonzaga)
       ↓
    Barbershop owner sees listing
       ↓
    Clicks "Gerenciar esta barbearia"
       ↓
    Creates account

Automatic acquisition channel.

------------------------------------------------------------------------

# 4. Database Structure

## Table: barbershops

Purpose: - store barbershops discovered via SEO - store barbershops that
signed up

Fields:

  field          description
  -------------- -----------------------
  id             primary key
  name           barbershop name
  slug           SEO slug
  city           city
  neighborhood   neighborhood
  address        address
  phone          phone
  instagram      instagram
  claimed        owner claimed listing
  userId         owner user
  tenantId       tenant reference
  createdAt      timestamp
  updatedAt      timestamp

------------------------------------------------------------------------

## Sequelize Model Example

``` javascript
module.exports = (sequelize, DataTypes) => {

  const Barbershop = sequelize.define('Barbershop', {

    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },

    name: {
      type: DataTypes.STRING,
      allowNull: false,
    },

    slug: {
      type: DataTypes.STRING,
    },

    city: {
      type: DataTypes.STRING,
      allowNull: false,
    },

    neighborhood: {
      type: DataTypes.STRING,
      allowNull: false,
    },

    address: DataTypes.STRING,

    phone: DataTypes.STRING,

    instagram: DataTypes.STRING,

    claimed: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    }

  }, {
    tableName: 'barbershops',
  });

  Barbershop.associate = (models) => {

    Barbershop.belongsTo(models.User, {
      foreignKey: 'userId',
    });

    Barbershop.belongsTo(models.Tenant, {
      foreignKey: 'tenantId',
    });

  };

  return Barbershop;

};
```

------------------------------------------------------------------------

# 5. Slug Strategy (Important for SEO)

Example:

    Barbearia Navalha

Slug:

    barbearia-navalha

Page URL:

    /barbearia/barbearia-navalha-santos

This increases Google discoverability.

------------------------------------------------------------------------

# 6. Service SEO Pages

Another traffic layer:

    /corte-masculino/santos
    /barba/santos
    /corte-masculino/gonzaga

Captures searches:

-   corte masculino santos
-   barba santos
-   barba gonzaga

High search volume keywords.

------------------------------------------------------------------------

# 7. Services Table

Create table: **barbershop_services**

Purpose: associate barbershops with services they offer.

Fields:

  field          description
  -------------- ------------------
  id             primary key
  barbershopId   barbershop
  service        service name
  price          service price
  duration       service duration
  createdAt      timestamp
  updatedAt      timestamp

Example services:

    corte masculino
    barba
    corte + barba
    pezinho
    pigmentação

------------------------------------------------------------------------

## Sequelize Model Example

``` javascript
module.exports = (sequelize, DataTypes) => {

  const BarbershopService = sequelize.define('BarbershopService', {

    id: {
      type: DataTypes.INTEGER,
      autoIncrement: true,
      primaryKey: true,
    },

    service: {
      type: DataTypes.STRING,
      allowNull: false,
    },

    price: DataTypes.FLOAT,

    duration: DataTypes.INTEGER

  }, {
    tableName: 'barbershop_services',
  });

  BarbershopService.associate = (models) => {

    BarbershopService.belongsTo(models.Barbershop, {
      foreignKey: 'barbershopId',
    });

  };

  return BarbershopService;

};
```

------------------------------------------------------------------------

# 8. Subdomain Strategy

When a barber signs up:

    barbearia.suaagenda.link

Each barber receives:

-   booking page
-   SEO page
-   services page

------------------------------------------------------------------------

# 9. Regional Launch Strategy

Start with **Baixada Santista**:

-   Santos
-   São Vicente
-   Praia Grande
-   Mongaguá
-   Itanhaém
-   Peruíbe

Potential listings:

    2000+ barbershops

Even **2% conversion**:

    40 paying customers

------------------------------------------------------------------------

# 10. Scaling Potential

With programmatic SEO:

    10k – 50k indexed pages

Result:

-   continuous Google traffic
-   automatic barber acquisition
-   scalable SaaS marketplace

------------------------------------------------------------------------

# End