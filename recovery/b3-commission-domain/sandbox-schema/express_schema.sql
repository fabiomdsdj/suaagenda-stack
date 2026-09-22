-- MySQL dump 10.13  Distrib 8.4.9, for Linux (x86_64)
--
-- Host: localhost    Database: express
-- ------------------------------------------------------
-- Server version	8.4.9

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `SequelizeMeta`
--

DROP TABLE IF EXISTS `SequelizeMeta`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `SequelizeMeta` (
  `name` varchar(255) COLLATE utf8mb3_unicode_ci NOT NULL,
  PRIMARY KEY (`name`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `acquisition_sources`
--

DROP TABLE IF EXISTS `acquisition_sources`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `acquisition_sources` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `slug` varchar(255) DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `active` tinyint(1) DEFAULT '1',
  `createdAt` datetime DEFAULT NULL,
  `updatedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `adresses`
--

DROP TABLE IF EXISTS `adresses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `adresses` (
  `id` int NOT NULL AUTO_INCREMENT,
  `postalCode` varchar(255) DEFAULT NULL,
  `adressName` varchar(255) DEFAULT NULL,
  `number` int DEFAULT NULL,
  `complement` varchar(255) DEFAULT NULL,
  `district` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  `clientId` int DEFAULT NULL,
  `providerId` int DEFAULT NULL,
  `employeeId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `adresses_tenantId_foreign_idx` (`tenantId`),
  KEY `adresses_userId_foreign_idx` (`userId`),
  KEY `adresses_clientId_foreign_idx` (`clientId`),
  KEY `adresses_providerId_foreign_idx` (`providerId`),
  KEY `adresses_employeeId_foreign_idx` (`employeeId`),
  CONSTRAINT `adresses_clientId_foreign_idx` FOREIGN KEY (`clientId`) REFERENCES `clients` (`id`),
  CONSTRAINT `adresses_employeeId_foreign_idx` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`),
  CONSTRAINT `adresses_providerId_foreign_idx` FOREIGN KEY (`providerId`) REFERENCES `providers` (`id`),
  CONSTRAINT `adresses_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `adresses_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ai_credits`
--

DROP TABLE IF EXISTS `ai_credits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ai_credits` (
  `id` int NOT NULL AUTO_INCREMENT,
  `used` int DEFAULT NULL,
  `limit` int DEFAULT NULL,
  `start` date DEFAULT NULL,
  `end` date DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `userId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ai_credits_userId_foreign_idx` (`userId`),
  KEY `ai_credits_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `ai_credits_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `ai_credits_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ai_usage_logs`
--

DROP TABLE IF EXISTS `ai_usage_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ai_usage_logs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `prompt` varchar(255) DEFAULT NULL,
  `result` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `userId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ai_usage_logs_userId_foreign_idx` (`userId`),
  KEY `ai_usage_logs_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `ai_usage_logs_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `ai_usage_logs_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `anamneses`
--

DROP TABLE IF EXISTS `anamneses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `anamneses` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL,
  `clientId` int NOT NULL,
  `employeeId` int DEFAULT NULL,
  `appointmentId` int DEFAULT NULL,
  `mainComplaint` text,
  `medicalHistory` text,
  `allergies` text,
  `currentMedications` text,
  `previousProcedures` text,
  `contraindications` text,
  `observations` text,
  `extraData` json DEFAULT NULL COMMENT 'Campos extras dinâmicos, ex: [{ question, answer }]',
  `status` enum('draft','completed','archived') NOT NULL DEFAULT 'completed',
  `signedAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `anamneses_tenant_id` (`tenantId`),
  KEY `anamneses_client_id` (`clientId`),
  KEY `anamneses_employee_id` (`employeeId`),
  KEY `anamneses_appointment_id` (`appointmentId`),
  KEY `anamneses_tenant_id_client_id` (`tenantId`,`clientId`),
  KEY `anamneses_status` (`status`),
  CONSTRAINT `anamneses_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `anamneses_ibfk_2` FOREIGN KEY (`clientId`) REFERENCES `clients` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `anamneses_ibfk_3` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `anamneses_ibfk_4` FOREIGN KEY (`appointmentId`) REFERENCES `appointments` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `appointment_queues`
--

DROP TABLE IF EXISTS `appointment_queues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `appointment_queues` (
  `id` int NOT NULL AUTO_INCREMENT,
  `appointmentId` int NOT NULL,
  `clientId` int NOT NULL,
  `serviceId` int NOT NULL,
  `employeeId` int NOT NULL,
  `tenantId` int NOT NULL,
  `start` varchar(255) NOT NULL,
  `end` varchar(255) NOT NULL,
  `comments` text,
  `position` int NOT NULL COMMENT 'Ordem na fila: 1 = próximo a ser notificado',
  `status` enum('aguardando','notificado','confirmado','expirado','desistiu') NOT NULL DEFAULT 'aguardando',
  `confirmationToken` varchar(36) DEFAULT NULL COMMENT 'Gerado quando status muda para notificado',
  `notifiedAt` datetime DEFAULT NULL COMMENT 'Quando o WhatsApp foi enviado',
  `notificationDeadline` datetime DEFAULT NULL COMMENT 'Prazo para confirmar após notificação (notifiedAt + 30min)',
  `bullJobId` varchar(255) DEFAULT NULL COMMENT 'ID do job de deadline no BullMQ (para cancelar se confirmar)',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `confirmationToken` (`confirmationToken`),
  UNIQUE KEY `idx_aq_confirmation_token` (`confirmationToken`),
  KEY `serviceId` (`serviceId`),
  KEY `employeeId` (`employeeId`),
  KEY `idx_aq_appointment_id` (`appointmentId`),
  KEY `idx_aq_client_id` (`clientId`),
  KEY `idx_aq_tenant_id` (`tenantId`),
  KEY `idx_aq_status` (`status`),
  KEY `idx_aq_appointment_status_position` (`appointmentId`,`status`,`position`),
  CONSTRAINT `appointment_queues_ibfk_1` FOREIGN KEY (`appointmentId`) REFERENCES `appointments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `appointment_queues_ibfk_2` FOREIGN KEY (`clientId`) REFERENCES `clients` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `appointment_queues_ibfk_3` FOREIGN KEY (`serviceId`) REFERENCES `services` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `appointment_queues_ibfk_4` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `appointment_queues_ibfk_5` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `appointment_status`
--

DROP TABLE IF EXISTS `appointment_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `appointment_status` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `color` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `appointment_status_tenantId_foreign_idx` (`tenantId`),
  KEY `appointment_status_userId_foreign_idx` (`userId`),
  CONSTRAINT `appointment_status_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `appointment_status_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `appointments`
--

DROP TABLE IF EXISTS `appointments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `appointments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `start` varchar(255) DEFAULT NULL,
  `end` varchar(255) DEFAULT NULL,
  `comments` varchar(255) DEFAULT NULL,
  `confirmationToken` varchar(255) DEFAULT NULL,
  `confirmationDeadline` datetime DEFAULT NULL,
  `confirmationStatus` enum('provisorio','confirmado','cancelado','liberado') DEFAULT 'provisorio',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `clientId` int DEFAULT NULL,
  `employeeId` int DEFAULT NULL,
  `appointmentStatusId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  `serviceId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  `employeeTimeBlockId` int DEFAULT NULL,
  `unitId` int NOT NULL,
  `websiteSubdomain` varchar(255) DEFAULT NULL COMMENT 'Subdomínio do tenant que originou o agendamento (ex: barbearia-joao)',
  `reminder1hSentAt` datetime DEFAULT NULL,
  `reminder24hSentAt` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `appointments_clientId_foreign_idx` (`clientId`),
  KEY `appointments_employeeId_foreign_idx` (`employeeId`),
  KEY `appointments_appointmentStatusId_foreign_idx` (`appointmentStatusId`),
  KEY `appointments_serviceId_foreign_idx` (`serviceId`),
  KEY `appointments_userId_foreign_idx` (`userId`),
  KEY `appointments_employeeTimeBlockId_foreign_idx` (`employeeTimeBlockId`),
  KEY `idx_appointments_tenant_created` (`tenantId`,`createdAt`) USING BTREE,
  KEY `idx_appointments_tenant_confirmation_created` (`tenantId`,`confirmationStatus`,`createdAt`) USING BTREE,
  KEY `idx_appointments_unit_created` (`unitId`,`createdAt`) USING BTREE,
  KEY `idx_appointments_tenant_appstatus_created` (`tenantId`,`appointmentStatusId`,`createdAt`) USING BTREE,
  KEY `idx_appointments_reminder_1h` (`confirmationStatus`,`start`,`reminder1hSentAt`),
  KEY `idx_appointments_reminder_24h` (`confirmationStatus`,`start`,`reminder24hSentAt`),
  CONSTRAINT `appointments_appointmentStatusId_foreign_idx` FOREIGN KEY (`appointmentStatusId`) REFERENCES `appointment_status` (`id`),
  CONSTRAINT `appointments_clientId_foreign_idx` FOREIGN KEY (`clientId`) REFERENCES `clients` (`id`),
  CONSTRAINT `appointments_employeeId_foreign_idx` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`),
  CONSTRAINT `appointments_employeeTimeBlockId_foreign_idx` FOREIGN KEY (`employeeTimeBlockId`) REFERENCES `employee_time_blocks` (`id`),
  CONSTRAINT `appointments_serviceId_foreign_idx` FOREIGN KEY (`serviceId`) REFERENCES `services` (`id`),
  CONSTRAINT `appointments_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `appointments_unitId_foreign_idx` FOREIGN KEY (`unitId`) REFERENCES `units` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `appointments_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `available_times`
--

DROP TABLE IF EXISTS `available_times`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `available_times` (
  `id` int NOT NULL AUTO_INCREMENT,
  `start` varchar(255) DEFAULT NULL,
  `end` varchar(255) DEFAULT NULL,
  `isBooked` tinyint(1) DEFAULT '0',
  `isBlocked` tinyint(1) DEFAULT '0',
  `comments` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `userId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `available_times_userId_foreign_idx` (`userId`),
  KEY `available_times_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `available_times_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `available_times_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `barbershop_analytics`
--

DROP TABLE IF EXISTS `barbershop_analytics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `barbershop_analytics` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `barbershopId` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `event` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `date` date NOT NULL,
  `count` int NOT NULL DEFAULT '1',
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_analytics_shop_event_date` (`barbershopId`,`event`,`date`),
  KEY `idx_analytics_shop` (`barbershopId`),
  CONSTRAINT `barbershop_analytics_ibfk_1` FOREIGN KEY (`barbershopId`) REFERENCES `barbershops` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `barbershop_photos`
--

DROP TABLE IF EXISTS `barbershop_photos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `barbershop_photos` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `barbershopId` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `url` varchar(1000) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'URL original da imagem (Google, Cloudinary, etc)',
  `caption` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'google_maps | upload | scraping',
  `isCover` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1 = foto de capa principal',
  `sortOrder` int NOT NULL DEFAULT '0',
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_barbershopPhotos_barbershopId` (`barbershopId`),
  KEY `idx_barbershopPhotos_sort` (`barbershopId`,`sortOrder`),
  KEY `idx_barbershopPhotos_isCover` (`isCover`),
  CONSTRAINT `barbershop_photos_ibfk_1` FOREIGN KEY (`barbershopId`) REFERENCES `barbershops` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `barbershop_services`
--

DROP TABLE IF EXISTS `barbershop_services`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `barbershop_services` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `barbershopId` char(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(130) COLLATE utf8mb4_unicode_ci NOT NULL,
  `category` varchar(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'corte | barba | tratamento | combo | outro',
  `description` text COLLATE utf8mb4_unicode_ci,
  `price` decimal(8,2) NOT NULL,
  `priceMin` decimal(8,2) DEFAULT NULL,
  `priceMax` decimal(8,2) DEFAULT NULL,
  `durationMin` int NOT NULL DEFAULT '30' COMMENT 'Duração em minutos',
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `isFeatured` tinyint(1) NOT NULL DEFAULT '0',
  `seoTag` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Tag canônica para páginas de serviço (ex: corte-degrade)',
  `sortOrder` int NOT NULL DEFAULT '0',
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_barbershopService_slug` (`barbershopId`,`slug`),
  KEY `idx_barbershopServices_barbershopId` (`barbershopId`),
  KEY `idx_barbershopServices_category` (`category`),
  KEY `idx_barbershopServices_seoTag` (`seoTag`),
  KEY `idx_barbershopServices_active_sort` (`barbershopId`,`isActive`,`sortOrder`),
  CONSTRAINT `barbershop_services_ibfk_1` FOREIGN KEY (`barbershopId`) REFERENCES `barbershops` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_service_duration_range` CHECK ((`durationMin` between 5 and 480)),
  CONSTRAINT `chk_service_price_positive` CHECK ((`price` >= 0)),
  CONSTRAINT `chk_service_price_range` CHECK (((`priceMin` is null) or (`priceMax` is null) or (`priceMin` <= `priceMax`)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `barbershops`
--

DROP TABLE IF EXISTS `barbershops`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `barbershops` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `slug` varchar(160) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subdomain` varchar(63) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('pending','active','suspended','churned') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `plan` enum('free','basic','pro','enterprise') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'free',
  `isClaimed` tinyint(1) NOT NULL DEFAULT '0' COMMENT '0 = não reclamada, 1 = reclamada pelo dono',
  `featured` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1 = aparece em destaque no portal',
  `importedFrom` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'google_maps | manual | api',
  `claimToken` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Token único enviado ao dono para confirmar o claim',
  `claimExpiresAt` datetime DEFAULT NULL,
  `claimedAt` datetime DEFAULT NULL,
  `trialEndsAt` datetime DEFAULT NULL COMMENT 'Data de término do trial Pro (14 dias após o claim)',
  `stripeCustomerId` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'ID do cliente no Stripe',
  `stripeSubscriptionId` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `whatsapp` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hasPhone` tinyint(1) NOT NULL DEFAULT '0',
  `email` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `website` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `street` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `complement` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `neighborhood` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `neighborhoodSlug` varchar(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Slug do bairro para filtros e SEO',
  `city` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `citySlug` varchar(110) COLLATE utf8mb4_unicode_ci NOT NULL,
  `state` char(2) COLLATE utf8mb4_unicode_ci NOT NULL,
  `zipCode` varchar(9) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `country` char(2) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'BR',
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `metaTitle` varchar(70) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `metaDescription` varchar(160) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `coverImageUrl` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `logoUrl` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `googlePlaceId` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `googleRating` decimal(2,1) DEFAULT NULL,
  `googleReviewCount` int NOT NULL DEFAULT '0',
  `nativeRating` decimal(3,2) DEFAULT NULL,
  `nativeReviewCount` int NOT NULL DEFAULT '0',
  `openingHours` json DEFAULT NULL COMMENT '{ mon: { open: "09:00", close: "20:00" }, ..., sun: null }',
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `deletedAt` datetime DEFAULT NULL COMMENT 'Soft delete — paranoid mode',
  `location` point DEFAULT NULL COMMENT 'POINT(longitude, latitude) — para SPATIAL INDEX',
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`),
  UNIQUE KEY `subdomain` (`subdomain`),
  UNIQUE KEY `claimToken` (`claimToken`),
  UNIQUE KEY `stripeCustomerId` (`stripeCustomerId`),
  UNIQUE KEY `stripeSubscriptionId` (`stripeSubscriptionId`),
  UNIQUE KEY `googlePlaceId` (`googlePlaceId`),
  KEY `idx_barbershops_citySlug` (`citySlug`),
  KEY `idx_barbershops_state` (`state`),
  KEY `idx_barbershops_status` (`status`),
  KEY `idx_barbershops_plan` (`plan`),
  KEY `idx_barbershops_isClaimed` (`isClaimed`),
  KEY `idx_barbershops_featured` (`featured`),
  KEY `idx_barbershops_neighborhoodSlug` (`neighborhoodSlug`),
  KEY `idx_barbershops_claimToken` (`claimToken`),
  KEY `idx_barbershops_trialEndsAt` (`trialEndsAt`),
  KEY `idx_barbershops_citySlug_status` (`citySlug`,`status`),
  KEY `idx_barbershops_city_neighborhood_status` (`citySlug`,`neighborhoodSlug`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `block_reasons`
--

DROP TABLE IF EXISTS `block_reasons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `block_reasons` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `color` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `blog_categories`
--

DROP TABLE IF EXISTS `blog_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `blog_categories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `blogId` int DEFAULT NULL COMMENT 'Referência ao blog',
  `tenantId` int DEFAULT NULL COMMENT 'Referência ao tenant (redundante mas útil para queries)',
  `label` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `blogId` (`blogId`),
  CONSTRAINT `blog_categories_ibfk_1` FOREIGN KEY (`blogId`) REFERENCES `blogs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `blog_categories_blog`
--

DROP TABLE IF EXISTS `blog_categories_blog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `blog_categories_blog` (
  `id` int NOT NULL AUTO_INCREMENT,
  `blogCategoryId` int NOT NULL,
  `blogPostId` int NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `blogCategoryId` (`blogCategoryId`),
  KEY `blogPostId` (`blogPostId`),
  CONSTRAINT `blog_categories_blog_ibfk_1` FOREIGN KEY (`blogCategoryId`) REFERENCES `blog_categories` (`id`) ON DELETE CASCADE,
  CONSTRAINT `blog_categories_blog_ibfk_2` FOREIGN KEY (`blogPostId`) REFERENCES `blog_posts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `blog_comments`
--

DROP TABLE IF EXISTS `blog_comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `blog_comments` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int DEFAULT NULL COMMENT 'Referência ao tenant (redundante mas útil para queries)',
  `name` varchar(255) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `content` text NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `blogPostId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `blog_comments_blogPostId_foreign_idx` (`blogPostId`),
  KEY `idx_blog_comments_tenant` (`tenantId`),
  CONSTRAINT `blog_comments_blogPostId_foreign_idx` FOREIGN KEY (`blogPostId`) REFERENCES `blog_posts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `blog_posts`
--

DROP TABLE IF EXISTS `blog_posts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `blog_posts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `blogId` int DEFAULT NULL COMMENT 'Referência ao blog',
  `title` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `content` longtext NOT NULL,
  `coverImage` varchar(500) DEFAULT NULL,
  `seoTitle` varchar(255) DEFAULT NULL,
  `seoDescription` text,
  `published` tinyint(1) NOT NULL DEFAULT '0',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `blogCategoryId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`),
  UNIQUE KEY `idx_posts_blog_slug` (`blogId`,`slug`),
  KEY `blog_posts_blogCategoryId_foreign_idx` (`blogCategoryId`),
  KEY `blog_posts_tenantId_foreign_idx` (`tenantId`),
  KEY `blog_posts_userId_foreign_idx` (`userId`),
  CONSTRAINT `blog_posts_blogCategoryId_foreign_idx` FOREIGN KEY (`blogCategoryId`) REFERENCES `blog_categories` (`id`),
  CONSTRAINT `blog_posts_ibfk_1` FOREIGN KEY (`blogId`) REFERENCES `blogs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `blog_posts_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `blog_posts_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `blog_responses`
--

DROP TABLE IF EXISTS `blog_responses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `blog_responses` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `content` text NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `blogCommentId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `blog_responses_blogCommentId_foreign_idx` (`blogCommentId`),
  CONSTRAINT `blog_responses_blogCommentId_foreign_idx` FOREIGN KEY (`blogCommentId`) REFERENCES `blog_comments` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `blogs`
--

DROP TABLE IF EXISTS `blogs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `blogs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL COMMENT 'Tenant dono do blog',
  `slug` varchar(100) NOT NULL COMMENT 'URL-friendly identifier (ex: master-blog, cliente-tech)',
  `title` varchar(255) NOT NULL COMMENT 'Nome público do blog',
  `description` text COMMENT 'Descrição do blog',
  `accessType` enum('public','subdomain','path') NOT NULL DEFAULT 'public' COMMENT 'public: blog.com | subdomain: blog.cliente.com | path: cliente.com/blog',
  `theme` varchar(50) DEFAULT 'default' COMMENT 'Nome do tema (default, modern, minimal, etc)',
  `primaryColor` varchar(7) DEFAULT NULL COMMENT 'Cor primária do blog (hex: #FF5733)',
  `secondaryColor` varchar(7) DEFAULT NULL COMMENT 'Cor secundária do blog',
  `logo` varchar(255) DEFAULT NULL COMMENT 'URL do logo do blog',
  `favicon` varchar(255) DEFAULT NULL COMMENT 'URL do favicon',
  `coverImage` varchar(255) DEFAULT NULL COMMENT 'Imagem de capa da home',
  `metaTitle` varchar(255) DEFAULT NULL COMMENT 'Título para SEO (meta tag)',
  `metaDescription` text COMMENT 'Descrição para SEO',
  `metaKeywords` text COMMENT 'Keywords separadas por vírgula',
  `ogImage` varchar(255) DEFAULT NULL COMMENT 'Imagem para Open Graph (compartilhamento social)',
  `facebook` varchar(255) DEFAULT NULL,
  `twitter` varchar(255) DEFAULT NULL,
  `instagram` varchar(255) DEFAULT NULL,
  `linkedin` varchar(255) DEFAULT NULL,
  `youtube` varchar(255) DEFAULT NULL,
  `googleAnalyticsId` varchar(50) DEFAULT NULL COMMENT 'Google Analytics ID (GA4)',
  `facebookPixelId` varchar(50) DEFAULT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Blog ativo/inativo',
  `publishedAt` datetime DEFAULT NULL COMMENT 'Data de publicação do blog',
  `settings` json DEFAULT NULL COMMENT 'Configurações extras (layout, sidebar, footer, etc)',
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`),
  UNIQUE KEY `idx_blogs_slug` (`slug`),
  KEY `idx_blogs_tenant` (`tenantId`),
  KEY `idx_blogs_access_active` (`accessType`,`isActive`),
  KEY `idx_blogs_tenant_active` (`tenantId`,`isActive`),
  CONSTRAINT `blogs_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `business`
--

DROP TABLE IF EXISTS `business`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `business` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cash_register_status`
--

DROP TABLE IF EXISTS `cash_register_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cash_register_status` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) DEFAULT NULL,
  `color` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cash_registers`
--

DROP TABLE IF EXISTS `cash_registers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cash_registers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `opened_at` datetime NOT NULL,
  `closed_at` datetime DEFAULT NULL,
  `opening_amount` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT 'Valor de abertura (troco inicial)',
  `closing_amount` decimal(10,2) DEFAULT NULL COMMENT 'Valor final após fechamento',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `cashRegisterStatusId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cash_registers_cashRegisterStatusId_foreign_idx` (`cashRegisterStatusId`),
  KEY `cash_registers_userId_foreign_idx` (`userId`),
  KEY `cash_registers_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `cash_registers_cashRegisterStatusId_foreign_idx` FOREIGN KEY (`cashRegisterStatusId`) REFERENCES `cash_register_status` (`id`),
  CONSTRAINT `cash_registers_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `cash_registers_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `claims`
--

DROP TABLE IF EXISTS `claims`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `claims` (
  `id` char(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT (uuid()),
  `tenantId` int NOT NULL,
  `businessId` char(36) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'id do negócio na table do segmento (sem FK — polimórfico)',
  `segmentTypeId` int NOT NULL COMMENT 'Define qual table consultar para o businessId',
  `status` enum('pending','approved','rejected','revoked') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `claimedAt` datetime DEFAULT NULL COMMENT 'Quando o dono iniciou o claim',
  `approvedAt` datetime DEFAULT NULL COMMENT 'Quando o claim foi aprovado/confirmado',
  `revokedAt` datetime DEFAULT NULL COMMENT 'Quando o claim foi revogado',
  `revokedReason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_claims_tenant_business` (`tenantId`,`businessId`,`segmentTypeId`),
  KEY `segmentTypeId` (`segmentTypeId`),
  KEY `idx_claims_tenantId` (`tenantId`),
  KEY `idx_claims_business` (`businessId`,`segmentTypeId`),
  KEY `idx_claims_status` (`status`),
  CONSTRAINT `claims_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `claims_ibfk_2` FOREIGN KEY (`segmentTypeId`) REFERENCES `segment_types` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `client_packages`
--

DROP TABLE IF EXISTS `client_packages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `client_packages` (
  `id` int NOT NULL AUTO_INCREMENT,
  `clientId` int NOT NULL,
  `packageId` int NOT NULL,
  `remainingSessions` int NOT NULL,
  `expiresAt` datetime NOT NULL,
  `createdAt` datetime DEFAULT NULL,
  `updatedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `packageId` (`packageId`),
  KEY `client_packages_client_id_expires_at_remaining_sessions` (`clientId`,`expiresAt`,`remainingSessions`),
  CONSTRAINT `client_packages_ibfk_1` FOREIGN KEY (`clientId`) REFERENCES `clients` (`id`) ON DELETE CASCADE,
  CONSTRAINT `client_packages_ibfk_2` FOREIGN KEY (`packageId`) REFERENCES `packages` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `client_status`
--

DROP TABLE IF EXISTS `client_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `client_status` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `color` varchar(255) DEFAULT NULL,
  `icon` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `client_status_tenantId_foreign_idx` (`tenantId`),
  KEY `client_status_userId_foreign_idx` (`userId`),
  CONSTRAINT `client_status_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `client_status_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `client_types`
--

DROP TABLE IF EXISTS `client_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `client_types` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `clients`
--

DROP TABLE IF EXISTS `clients`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `clients` (
  `id` int NOT NULL AUTO_INCREMENT,
  `firstName` varchar(255) NOT NULL,
  `lastName` varchar(255) DEFAULT NULL,
  `birth` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `mobilePhone` varchar(255) NOT NULL,
  `avatar` varchar(255) DEFAULT NULL,
  `rg` varchar(255) DEFAULT NULL,
  `cpf` varchar(255) DEFAULT NULL,
  `receiveNotificationOn` varchar(255) DEFAULT NULL,
  `avaliation` json DEFAULT NULL,
  `evolution` json DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `genderId` int DEFAULT NULL,
  `clientStatusId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  `clientTypeId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_clients_email_tenant` (`email`,`tenantId`),
  KEY `clients_genderId_foreign_idx` (`genderId`),
  KEY `clients_clientStatusId_foreign_idx` (`clientStatusId`),
  KEY `clients_tenantId_foreign_idx` (`tenantId`),
  KEY `clients_clientTypeId_foreign_idx` (`clientTypeId`),
  KEY `clients_userId_foreign_idx` (`userId`),
  CONSTRAINT `clients_clientStatusId_foreign_idx` FOREIGN KEY (`clientStatusId`) REFERENCES `client_status` (`id`),
  CONSTRAINT `clients_clientTypeId_foreign_idx` FOREIGN KEY (`clientTypeId`) REFERENCES `client_types` (`id`),
  CONSTRAINT `clients_genderId_foreign_idx` FOREIGN KEY (`genderId`) REFERENCES `genders` (`id`),
  CONSTRAINT `clients_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `clients_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `clinical_evolutions`
--

DROP TABLE IF EXISTS `clinical_evolutions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `clinical_evolutions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL,
  `clientId` int NOT NULL,
  `employeeId` int DEFAULT NULL,
  `appointmentId` int DEFAULT NULL,
  `anamnesisId` int DEFAULT NULL,
  `description` text NOT NULL,
  `proceduresPerformed` text,
  `results` text,
  `nextSteps` text,
  `attachments` json DEFAULT NULL COMMENT 'Array de URLs, ex: ["https://.../foto1.jpg"]',
  `extraData` json DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `unitId` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `clinical_evolutions_tenant_id` (`tenantId`),
  KEY `clinical_evolutions_client_id` (`clientId`),
  KEY `clinical_evolutions_employee_id` (`employeeId`),
  KEY `clinical_evolutions_appointment_id` (`appointmentId`),
  KEY `clinical_evolutions_anamnesis_id` (`anamnesisId`),
  KEY `clinical_evolutions_tenant_id_client_id` (`tenantId`,`clientId`),
  KEY `clinical_evolutions_unit_id` (`unitId`),
  CONSTRAINT `clinical_evolutions_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `clinical_evolutions_ibfk_2` FOREIGN KEY (`clientId`) REFERENCES `clients` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `clinical_evolutions_ibfk_3` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `clinical_evolutions_ibfk_4` FOREIGN KEY (`appointmentId`) REFERENCES `appointments` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `clinical_evolutions_ibfk_5` FOREIGN KEY (`anamnesisId`) REFERENCES `anamneses` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `clinical_evolutions_unitId_foreign_idx` FOREIGN KEY (`unitId`) REFERENCES `units` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comission_status`
--

DROP TABLE IF EXISTS `comission_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `comission_status` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comission_types`
--

DROP TABLE IF EXISTS `comission_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `comission_types` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comissions`
--

DROP TABLE IF EXISTS `comissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `comissions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `percent` int NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `comissionTypeId` int DEFAULT NULL,
  `comissionStatusId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  `salesAgentId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `comissions_comissionTypeId_foreign_idx` (`comissionTypeId`),
  KEY `comissions_comissionStatusId_foreign_idx` (`comissionStatusId`),
  KEY `comissions_tenantId_foreign_idx` (`tenantId`),
  KEY `fk_comission_sales_agent` (`salesAgentId`),
  CONSTRAINT `comissions_comissionStatusId_foreign_idx` FOREIGN KEY (`comissionStatusId`) REFERENCES `comission_status` (`id`),
  CONSTRAINT `comissions_comissionTypeId_foreign_idx` FOREIGN KEY (`comissionTypeId`) REFERENCES `comission_types` (`id`),
  CONSTRAINT `comissions_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `fk_comission_sales_agent` FOREIGN KEY (`salesAgentId`) REFERENCES `sales_agents` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `commission_entries`
--

DROP TABLE IF EXISTS `commission_entries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `commission_entries` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL,
  `salesAgentId` int NOT NULL,
  `employeeId` int DEFAULT NULL,
  `signatureId` int NOT NULL,
  `referenceMonth` varchar(7) NOT NULL,
  `subscriptionFee` decimal(10,2) NOT NULL,
  `commissionPercent` decimal(5,2) DEFAULT NULL,
  `commissionAmount` decimal(10,2) NOT NULL,
  `status` enum('open','paid','canceled') DEFAULT 'open',
  `paidAt` datetime DEFAULT NULL,
  `notes` text,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ux_commission_month` (`tenantId`,`referenceMonth`),
  KEY `idx_commission_sales_agent` (`salesAgentId`,`referenceMonth`),
  KEY `idx_ce_employee_month` (`employeeId`,`referenceMonth`),
  KEY `idx_ce_tenant_month` (`tenantId`,`referenceMonth`),
  KEY `idx_ce_status` (`status`),
  CONSTRAINT `commission_entries_employeeId_foreign_idx` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `commission_plan_tiers`
--

DROP TABLE IF EXISTS `commission_plan_tiers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `commission_plan_tiers` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `commissionPlanId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `tierOrder` int NOT NULL COMMENT 'Ordem da faixa dentro do plano: 1, 2, 3 ...',
  `fromUnit` int NOT NULL COMMENT 'Primeira unidade coberta por essa faixa (1-based)',
  `toUnit` int DEFAULT NULL COMMENT 'Última unidade coberta. NULL = faixa aberta até o fim',
  `percent` decimal(5,2) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_commission_plan_tier_order` (`commissionPlanId`,`tierOrder`),
  KEY `commission_plan_tiers_commission_plan_id` (`commissionPlanId`),
  CONSTRAINT `commission_plan_tiers_ibfk_1` FOREIGN KEY (`commissionPlanId`) REFERENCES `commission_plans` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `commission_plans`
--

DROP TABLE IF EXISTS `commission_plans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `commission_plans` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `name` varchar(255) NOT NULL COMMENT 'Nome do template de comissão. Ex: "Padrão 12 meses escalonado"',
  `description` varchar(255) DEFAULT NULL,
  `basis` enum('billing_month','payment') NOT NULL DEFAULT 'billing_month',
  `tierBasis` enum('sequence','volume') NOT NULL DEFAULT 'sequence',
  `totalUnits` int DEFAULT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `createdByUserId` int DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `commission_plans_is_active` (`isActive`),
  KEY `commission_plans_created_by_user_id` (`createdByUserId`),
  CONSTRAINT `commission_plans_ibfk_1` FOREIGN KEY (`createdByUserId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `complexities`
--

DROP TABLE IF EXISTS `complexities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `complexities` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `complexities_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `complexities_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `contact_infos`
--

DROP TABLE IF EXISTS `contact_infos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `contact_infos` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `coupon_status`
--

DROP TABLE IF EXISTS `coupon_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `coupon_status` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `label` varchar(255) DEFAULT NULL,
  `color` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `coupon_usages`
--

DROP TABLE IF EXISTS `coupon_usages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `coupon_usages` (
  `id` int NOT NULL AUTO_INCREMENT,
  `used_at` datetime NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `userId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  `discountCouponId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `coupon_usages_userId_foreign_idx` (`userId`),
  KEY `coupon_usages_tenantId_foreign_idx` (`tenantId`),
  KEY `coupon_usages_discountCouponId_foreign_idx` (`discountCouponId`),
  CONSTRAINT `coupon_usages_discountCouponId_foreign_idx` FOREIGN KEY (`discountCouponId`) REFERENCES `discount_coupons` (`id`),
  CONSTRAINT `coupon_usages_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `coupon_usages_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `customer_subscriptions`
--

DROP TABLE IF EXISTS `customer_subscriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `customer_subscriptions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `clientId` int NOT NULL,
  `tenantId` int NOT NULL,
  `planId` int NOT NULL,
  `remainingSessions` int NOT NULL,
  `sessionsPerCycle` int NOT NULL,
  `nextRenewAt` datetime NOT NULL,
  `active` tinyint(1) DEFAULT '1',
  `createdAt` datetime DEFAULT NULL,
  `updatedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tenantId` (`tenantId`),
  KEY `planId` (`planId`),
  KEY `customer_subscriptions_client_id_tenant_id_active_next_renew_at` (`clientId`,`tenantId`,`active`,`nextRenewAt`),
  CONSTRAINT `customer_subscriptions_ibfk_1` FOREIGN KEY (`clientId`) REFERENCES `clients` (`id`) ON DELETE CASCADE,
  CONSTRAINT `customer_subscriptions_ibfk_2` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `customer_subscriptions_ibfk_3` FOREIGN KEY (`planId`) REFERENCES `subscription_plans` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `discount_coupons`
--

DROP TABLE IF EXISTS `discount_coupons`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `discount_coupons` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `code` varchar(255) NOT NULL,
  `discount_type` enum('percent','fixed') NOT NULL,
  `discount_value` decimal(10,2) NOT NULL,
  `valid_from` datetime NOT NULL,
  `valid_until` datetime NOT NULL,
  `max_usage` int DEFAULT NULL,
  `used_count` int NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  `couponStatusId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `code` (`code`),
  KEY `discount_coupons_tenantId_foreign_idx` (`tenantId`),
  KEY `discount_coupons_couponStatusId_foreign_idx` (`couponStatusId`),
  KEY `discount_coupons_userId_foreign_idx` (`userId`),
  CONSTRAINT `discount_coupons_couponStatusId_foreign_idx` FOREIGN KEY (`couponStatusId`) REFERENCES `coupon_status` (`id`),
  CONSTRAINT `discount_coupons_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `discount_coupons_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `display_addresses`
--

DROP TABLE IF EXISTS `display_addresses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `display_addresses` (
  `id` int NOT NULL AUTO_INCREMENT,
  `label` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `document_types`
--

DROP TABLE IF EXISTS `document_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `document_types` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `documents`
--

DROP TABLE IF EXISTS `documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `documents` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `documentTypeId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `documents_documentTypeId_foreign_idx` (`documentTypeId`),
  KEY `documents_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `documents_documentTypeId_foreign_idx` FOREIGN KEY (`documentTypeId`) REFERENCES `document_types` (`id`),
  CONSTRAINT `documents_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `durations`
--

DROP TABLE IF EXISTS `durations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `durations` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `milliseconds` int NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `durations_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `durations_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1225 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `email_verifications`
--

DROP TABLE IF EXISTS `email_verifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `email_verifications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `userId` int NOT NULL,
  `token` varchar(64) NOT NULL,
  `expiresAt` datetime NOT NULL,
  `verifiedAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `token` (`token`),
  KEY `email_verifications_token` (`token`),
  KEY `email_verifications_user_id` (`userId`),
  CONSTRAINT `email_verifications_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `employee_availabilities`
--

DROP TABLE IF EXISTS `employee_availabilities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee_availabilities` (
  `id` int NOT NULL AUTO_INCREMENT,
  `employeeId` int NOT NULL,
  `dayOfWeek` int NOT NULL,
  `startTime` time NOT NULL,
  `endTime` time NOT NULL,
  `createdAt` datetime DEFAULT NULL,
  `updatedAt` datetime DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `employeeId` (`employeeId`),
  KEY `employee_availabilities_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `employee_availabilities_ibfk_1` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`) ON DELETE CASCADE,
  CONSTRAINT `employee_availabilities_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=157 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `employee_service`
--

DROP TABLE IF EXISTS `employee_service`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee_service` (
  `id` int NOT NULL AUTO_INCREMENT,
  `employeeId` int NOT NULL,
  `serviceId` int NOT NULL,
  `tenantId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `employeeId` (`employeeId`),
  KEY `serviceId` (`serviceId`),
  KEY `tenantId` (`tenantId`),
  KEY `userId` (`userId`),
  CONSTRAINT `employee_service_ibfk_1` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`),
  CONSTRAINT `employee_service_ibfk_2` FOREIGN KEY (`serviceId`) REFERENCES `services` (`id`),
  CONSTRAINT `employee_service_ibfk_3` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `employee_service_ibfk_4` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=419 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `employee_service_category`
--

DROP TABLE IF EXISTS `employee_service_category`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee_service_category` (
  `id` int NOT NULL AUTO_INCREMENT,
  `employeeId` int NOT NULL,
  `serviceCategoryId` int NOT NULL,
  `tenantId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `employeeId` (`employeeId`),
  KEY `serviceCategoryId` (`serviceCategoryId`),
  KEY `tenantId` (`tenantId`),
  KEY `userId` (`userId`),
  CONSTRAINT `employee_service_category_ibfk_1` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`),
  CONSTRAINT `employee_service_category_ibfk_2` FOREIGN KEY (`serviceCategoryId`) REFERENCES `service_categories` (`id`),
  CONSTRAINT `employee_service_category_ibfk_3` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `employee_service_category_ibfk_4` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `employee_status`
--

DROP TABLE IF EXISTS `employee_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee_status` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) DEFAULT NULL,
  `color` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `employee_status_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `employee_status_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `employee_time_blocks`
--

DROP TABLE IF EXISTS `employee_time_blocks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee_time_blocks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `employeeId` int NOT NULL,
  `startTime` datetime NOT NULL,
  `endTime` datetime NOT NULL,
  `otherReasons` varchar(255) DEFAULT NULL,
  `orderId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `blockReasonId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `employeeId` (`employeeId`),
  KEY `orderId` (`orderId`),
  KEY `employee_time_blocks_blockReasonId_foreign_idx` (`blockReasonId`),
  KEY `employee_time_blocks_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `employee_time_blocks_blockReasonId_foreign_idx` FOREIGN KEY (`blockReasonId`) REFERENCES `block_reasons` (`id`),
  CONSTRAINT `employee_time_blocks_ibfk_1` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`) ON DELETE CASCADE,
  CONSTRAINT `employee_time_blocks_ibfk_2` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE SET NULL,
  CONSTRAINT `employee_time_blocks_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `employee_types`
--

DROP TABLE IF EXISTS `employee_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee_types` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) DEFAULT NULL,
  `color` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `employees`
--

DROP TABLE IF EXISTS `employees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employees` (
  `id` int NOT NULL AUTO_INCREMENT,
  `firstName` varchar(255) NOT NULL,
  `lastName` varchar(255) DEFAULT NULL,
  `birth` varchar(255) DEFAULT NULL,
  `color` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `mobilePhone` varchar(255) DEFAULT NULL,
  `avatar` varchar(255) DEFAULT NULL,
  `rg` varchar(255) DEFAULT NULL,
  `cpf` varchar(255) DEFAULT NULL,
  `receiveNotificationOn` tinyint(1) DEFAULT '1',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `userId` int DEFAULT NULL,
  `comissionId` int DEFAULT NULL,
  `genderId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  `employeeStatusId` int DEFAULT NULL,
  `employeeTypeId` int DEFAULT NULL,
  `intervalBetweenAppointments` int NOT NULL DEFAULT '20' COMMENT 'Intervalo em minutos entre agendamentos (ex: 15 = 15min de folga entre cada cliente)',
  `unitId` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_employees_email_tenant` (`email`,`tenantId`),
  KEY `employees_userId_foreign_idx` (`userId`),
  KEY `employees_comissionId_foreign_idx` (`comissionId`),
  KEY `employees_genderId_foreign_idx` (`genderId`),
  KEY `employees_employeeStatusId_foreign_idx` (`employeeStatusId`),
  KEY `employees_employeeTypeId_foreign_idx` (`employeeTypeId`),
  KEY `employees_unitId_foreign_idx` (`unitId`),
  KEY `idx_employees_tenant` (`tenantId`) USING BTREE,
  CONSTRAINT `employees_comissionId_foreign_idx` FOREIGN KEY (`comissionId`) REFERENCES `comissions` (`id`),
  CONSTRAINT `employees_employeeStatusId_foreign_idx` FOREIGN KEY (`employeeStatusId`) REFERENCES `employee_status` (`id`),
  CONSTRAINT `employees_employeeTypeId_foreign_idx` FOREIGN KEY (`employeeTypeId`) REFERENCES `employee_types` (`id`),
  CONSTRAINT `employees_genderId_foreign_idx` FOREIGN KEY (`genderId`) REFERENCES `genders` (`id`),
  CONSTRAINT `employees_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `employees_unitId_foreign_idx` FOREIGN KEY (`unitId`) REFERENCES `units` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `employees_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `employees_documents`
--

DROP TABLE IF EXISTS `employees_documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employees_documents` (
  `id` int NOT NULL AUTO_INCREMENT,
  `documentId` int NOT NULL,
  `employeeId` int NOT NULL,
  `file` blob NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `documentId` (`documentId`),
  KEY `employeeId` (`employeeId`),
  CONSTRAINT `employees_documents_ibfk_1` FOREIGN KEY (`documentId`) REFERENCES `documents` (`id`),
  CONSTRAINT `employees_documents_ibfk_2` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `equipment_types`
--

DROP TABLE IF EXISTS `equipment_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `equipment_types` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL,
  `unitId` int NOT NULL,
  `name` varchar(150) NOT NULL,
  `category` varchar(100) DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `equipment_types_tenant_id` (`tenantId`),
  KEY `equipment_types_unit_id_active` (`unitId`,`active`),
  CONSTRAINT `equipment_types_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `equipment_types_ibfk_2` FOREIGN KEY (`unitId`) REFERENCES `units` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `expense_categories`
--

DROP TABLE IF EXISTS `expense_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `expense_categories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `expense_categories_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `expense_categories_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `expenses`
--

DROP TABLE IF EXISTS `expenses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `expenses` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `dueDate` datetime DEFAULT NULL,
  `entryDate` datetime DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `userId` int DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `expenseCategoryId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  `unitId` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `userId` (`userId`),
  KEY `expenses_expenseCategoryId_foreign_idx` (`expenseCategoryId`),
  KEY `expenses_tenantId_foreign_idx` (`tenantId`),
  KEY `expenses_unitId_foreign_idx` (`unitId`),
  CONSTRAINT `expenses_expenseCategoryId_foreign_idx` FOREIGN KEY (`expenseCategoryId`) REFERENCES `expense_categories` (`id`),
  CONSTRAINT `expenses_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `expenses_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `expenses_unitId_foreign_idx` FOREIGN KEY (`unitId`) REFERENCES `units` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `favorites`
--

DROP TABLE IF EXISTS `favorites`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `favorites` (
  `id` int NOT NULL AUTO_INCREMENT,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `userId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `favorites_userId_foreign_idx` (`userId`),
  KEY `favorites_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `favorites_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `favorites_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `features`
--

DROP TABLE IF EXISTS `features`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `features` (
  `id` int NOT NULL AUTO_INCREMENT,
  `key` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `description` text,
  `type` enum('boolean','number','string') NOT NULL DEFAULT 'string' COMMENT 'Tipo da feature (boolean, number, string)',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `key` (`key`),
  UNIQUE KEY `idx_features_key` (`key`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `genders`
--

DROP TABLE IF EXISTS `genders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `genders` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `icon` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `genders_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `genders_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `geo_locations`
--

DROP TABLE IF EXISTS `geo_locations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `geo_locations` (
  `id` char(36) NOT NULL,
  `type` enum('state','city','district','neighborhood') NOT NULL,
  `slug` varchar(160) NOT NULL,
  `name` varchar(150) NOT NULL,
  `parent_slug` varchar(160) DEFAULT NULL,
  `uf` char(2) DEFAULT NULL,
  `uf_slug` varchar(5) DEFAULT NULL,
  `city_slug` varchar(120) DEFAULT NULL,
  `district_slug` varchar(160) DEFAULT NULL,
  `zone` varchar(80) DEFAULT NULL,
  `region` varchar(80) DEFAULT NULL,
  `lat` decimal(10,7) DEFAULT NULL,
  `lng` decimal(10,7) DEFAULT NULL,
  `zoom` tinyint DEFAULT NULL,
  `query_suffix` varchar(200) DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `slug` (`slug`),
  KEY `idx_geo_locations_type` (`type`),
  KEY `idx_geo_locations_uf_slug` (`uf_slug`),
  KEY `idx_geo_locations_city_slug` (`city_slug`),
  KEY `idx_geo_locations_district_slug` (`district_slug`),
  KEY `idx_geo_locations_parent_slug` (`parent_slug`),
  KEY `idx_geo_locations_active` (`active`),
  KEY `idx_geo_locations_uf_city_type` (`uf_slug`,`city_slug`,`type`),
  CONSTRAINT `geo_locations_ibfk_1` FOREIGN KEY (`parent_slug`) REFERENCES `geo_locations` (`slug`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `goals`
--

DROP TABLE IF EXISTS `goals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `goals` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL,
  `employeeId` int DEFAULT NULL,
  `type` enum('revenue','appointments') NOT NULL DEFAULT 'revenue',
  `period` enum('daily','weekly','monthly') NOT NULL DEFAULT 'monthly',
  `targetValue` decimal(12,2) DEFAULT NULL,
  `referenceMonth` varchar(10) DEFAULT NULL,
  `active` tinyint(1) DEFAULT '1',
  `achievedValue` decimal(12,2) DEFAULT NULL,
  `achievedAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `employeeId` (`employeeId`),
  KEY `goals_tenant_id_period_type_active` (`tenantId`,`period`,`type`,`active`),
  KEY `goals_tenant_id_employee_id` (`tenantId`,`employeeId`),
  CONSTRAINT `goals_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `goals_ibfk_2` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `google_ads_accounts`
--

DROP TABLE IF EXISTS `google_ads_accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `google_ads_accounts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL,
  `customerId` varchar(20) DEFAULT NULL,
  `accountName` varchar(255) DEFAULT NULL,
  `refreshToken` text NOT NULL,
  `accessToken` text,
  `connected` tinyint(1) DEFAULT '1',
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `tenantId` (`tenantId`),
  CONSTRAINT `google_ads_accounts_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `google_ads_campaigns`
--

DROP TABLE IF EXISTS `google_ads_campaigns`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `google_ads_campaigns` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL,
  `googleAdsAccountId` int NOT NULL,
  `googleCampaignId` varchar(50) DEFAULT NULL,
  `nome` varchar(255) NOT NULL,
  `status` varchar(20) DEFAULT 'draft',
  `orcamentoDiario` decimal(10,2) DEFAULT NULL,
  `iaPayload` json DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `lastAiReviewAt` datetime DEFAULT NULL,
  `nextAiReviewAt` datetime DEFAULT NULL,
  `aiReviewEnabled` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `tenantId` (`tenantId`),
  KEY `googleAdsAccountId` (`googleAdsAccountId`),
  CONSTRAINT `google_ads_campaigns_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `google_ads_campaigns_ibfk_2` FOREIGN KEY (`googleAdsAccountId`) REFERENCES `google_ads_accounts` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `google_ads_master_accounts`
--

DROP TABLE IF EXISTS `google_ads_master_accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `google_ads_master_accounts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customerId` varchar(255) DEFAULT NULL,
  `accountName` varchar(255) DEFAULT NULL,
  `refreshToken` varchar(255) DEFAULT NULL,
  `accessToken` varchar(255) DEFAULT NULL,
  `connected` tinyint(1) NOT NULL DEFAULT '0',
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `google_ads_master_campaigns`
--

DROP TABLE IF EXISTS `google_ads_master_campaigns`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `google_ads_master_campaigns` (
  `id` int NOT NULL AUTO_INCREMENT,
  `googleAdsMasterAccountId` int NOT NULL,
  `googleCampaignId` varchar(255) DEFAULT NULL,
  `googleCampaignResource` varchar(255) DEFAULT NULL,
  `nome` varchar(255) DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'draft',
  `orcamentoDiario` decimal(10,2) DEFAULT NULL,
  `publicoAlvo` varchar(255) NOT NULL DEFAULT 'barbearias',
  `regiaoAlvo` varchar(255) DEFAULT NULL,
  `iaPayload` json DEFAULT NULL,
  `lastAiReviewAt` datetime DEFAULT NULL,
  `nextAiReviewAt` datetime DEFAULT NULL,
  `aiReviewEnabled` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `google_ads_master_campaigns_google_ads_master_account_id` (`googleAdsMasterAccountId`),
  KEY `google_ads_master_campaigns_status` (`status`),
  CONSTRAINT `google_ads_master_campaigns_ibfk_1` FOREIGN KEY (`googleAdsMasterAccountId`) REFERENCES `google_ads_master_accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `interaction_types`
--

DROP TABLE IF EXISTS `interaction_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `interaction_types` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `invoices`
--

DROP TABLE IF EXISTS `invoices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `invoices` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL,
  `customerName` varchar(255) NOT NULL,
  `customerDocument` varchar(255) DEFAULT NULL,
  `description` text NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `issueDate` datetime NOT NULL,
  `invoiceNumber` varchar(255) DEFAULT NULL,
  `rpsNumber` varchar(255) DEFAULT NULL,
  `xmlUrl` varchar(255) DEFAULT NULL,
  `pdfUrl` varchar(255) DEFAULT NULL,
  `status` enum('PENDING','ISSUED','CANCELLED','ERROR','REFUNDED') DEFAULT 'PENDING',
  `refundedAt` datetime DEFAULT NULL,
  `paymentId` varchar(255) DEFAULT NULL,
  `errorLog` text,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `protocol` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tenantId` (`tenantId`),
  CONSTRAINT `invoices_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `locations`
--

DROP TABLE IF EXISTS `locations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `locations` (
  `id` int NOT NULL AUTO_INCREMENT,
  `country` varchar(255) NOT NULL,
  `state` varchar(255) NOT NULL,
  `city` varchar(255) NOT NULL,
  `citySlug` varchar(255) DEFAULT NULL,
  `zone` varchar(255) DEFAULT NULL,
  `neighborhood` varchar(255) NOT NULL,
  `neighborhoodSlug` varchar(255) DEFAULT NULL,
  `address` varchar(255) NOT NULL,
  `streetNumber` varchar(255) NOT NULL,
  `complement` varchar(255) DEFAULT NULL,
  `postalCode` varchar(255) NOT NULL,
  `latitude` varchar(255) NOT NULL,
  `longitude` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `userId` int DEFAULT NULL,
  `displayAddressId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `locations_userId_foreign_idx` (`userId`),
  KEY `locations_displayAddressId_foreign_idx` (`displayAddressId`),
  KEY `locations_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `locations_displayAddressId_foreign_idx` FOREIGN KEY (`displayAddressId`) REFERENCES `display_addresses` (`id`),
  CONSTRAINT `locations_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `locations_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `loyalty_cards`
--

DROP TABLE IF EXISTS `loyalty_cards`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `loyalty_cards` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL,
  `clientId` int NOT NULL,
  `points` int NOT NULL DEFAULT '0' COMMENT 'Saldo atual de pontos',
  `lifetimePoints` int NOT NULL DEFAULT '0' COMMENT 'Total histórico acumulado — nunca decresce, usado para calcular tier',
  `tier` enum('bronze','silver','gold','diamond') NOT NULL DEFAULT 'bronze',
  `lastActivityAt` datetime DEFAULT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `loyalty_cards_tenant_client_unique` (`tenantId`,`clientId`),
  KEY `clientId` (`clientId`),
  CONSTRAINT `loyalty_cards_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `loyalty_cards_ibfk_2` FOREIGN KEY (`clientId`) REFERENCES `clients` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `loyalty_programs`
--

DROP TABLE IF EXISTS `loyalty_programs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `loyalty_programs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT '0',
  `pointsPerReal` decimal(10,2) NOT NULL DEFAULT '1.00' COMMENT 'Quantos pontos o cliente ganha por R$1 gasto em serviços',
  `redeemRatio` decimal(10,4) NOT NULL DEFAULT '0.0100' COMMENT 'Valor em R$ de cada ponto (ex: 0.01 = 1 centavo por ponto)',
  `minPointsToRedeem` int NOT NULL DEFAULT '100' COMMENT 'Mínimo de pontos para fazer um resgate',
  `expirationDays` int DEFAULT NULL COMMENT 'Dias até os pontos expirarem após a última transação. null = não expira',
  `bronzeThreshold` int DEFAULT '0' COMMENT 'Pontos lifetime para tier bronze',
  `silverThreshold` int DEFAULT '500' COMMENT 'Pontos lifetime para tier silver',
  `goldThreshold` int DEFAULT '2000' COMMENT 'Pontos lifetime para tier gold',
  `diamondThreshold` int DEFAULT '5000' COMMENT 'Pontos lifetime para tier diamond',
  `rules` json DEFAULT NULL COMMENT 'Regras extras: pontos dobrados em datas especiais, aniversário, etc.',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tenantId` (`tenantId`),
  CONSTRAINT `loyalty_programs_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `loyalty_transactions`
--

DROP TABLE IF EXISTS `loyalty_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `loyalty_transactions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `loyaltyCardId` int NOT NULL,
  `tenantId` int NOT NULL,
  `clientId` int NOT NULL,
  `appointmentId` int DEFAULT NULL,
  `orderId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `type` enum('earned','redeemed','expired','adjusted','bonus') NOT NULL,
  `points` int NOT NULL COMMENT 'Positivo = crédito, negativo = débito',
  `balanceAfter` int NOT NULL COMMENT 'Snapshot do saldo após a transação',
  `description` varchar(500) DEFAULT NULL,
  `expiresAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `clientId` (`clientId`),
  KEY `orderId` (`orderId`),
  KEY `lt_card_idx` (`loyaltyCardId`),
  KEY `lt_tenant_idx` (`tenantId`),
  KEY `lt_appointment_idx` (`appointmentId`),
  KEY `lt_type_idx` (`type`),
  CONSTRAINT `loyalty_transactions_ibfk_1` FOREIGN KEY (`loyaltyCardId`) REFERENCES `loyalty_cards` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `loyalty_transactions_ibfk_2` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `loyalty_transactions_ibfk_3` FOREIGN KEY (`clientId`) REFERENCES `clients` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `loyalty_transactions_ibfk_4` FOREIGN KEY (`appointmentId`) REFERENCES `appointments` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `loyalty_transactions_ibfk_5` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `media_types`
--

DROP TABLE IF EXISTS `media_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `media_types` (
  `id` int NOT NULL AUTO_INCREMENT,
  `label` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `medias`
--

DROP TABLE IF EXISTS `medias`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `medias` (
  `id` int NOT NULL AUTO_INCREMENT,
  `url` varchar(255) NOT NULL,
  `caption` varchar(255) DEFAULT NULL,
  `primary` tinyint(1) NOT NULL DEFAULT '0',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `userId` int DEFAULT NULL,
  `mediaTypeId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  `blogId` int DEFAULT NULL COMMENT 'Referência ao blog (se a media for de um post do blog)',
  `entityType` enum('blog_post','property','tenant','user','other') DEFAULT NULL COMMENT 'Tipo de entidade que a media pertence',
  `entityId` int DEFAULT NULL COMMENT 'ID da entidade específica (ex: postId, propertyId)',
  `filename` varchar(255) DEFAULT NULL COMMENT 'Nome do arquivo',
  `mimeType` varchar(100) DEFAULT NULL COMMENT 'Tipo MIME do arquivo',
  `size` int DEFAULT NULL COMMENT 'Tamanho em bytes',
  `type` enum('image','video','document','audio','other') DEFAULT 'image' COMMENT 'Tipo geral da media',
  `order` int DEFAULT '0' COMMENT 'Ordem de exibição',
  PRIMARY KEY (`id`),
  KEY `medias_userId_foreign_idx` (`userId`),
  KEY `medias_mediaTypeId_foreign_idx` (`mediaTypeId`),
  KEY `idx_medias_blog` (`blogId`),
  KEY `idx_medias_entity` (`entityType`,`entityId`),
  KEY `idx_medias_tenant_entity` (`tenantId`,`entityType`),
  CONSTRAINT `fk_medias_blog` FOREIGN KEY (`blogId`) REFERENCES `blogs` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `medias_mediaTypeId_foreign_idx` FOREIGN KEY (`mediaTypeId`) REFERENCES `media_types` (`id`),
  CONSTRAINT `medias_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `medias_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `meta_accounts`
--

DROP TABLE IF EXISTS `meta_accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `meta_accounts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL,
  `accessToken` text,
  `tokenExpiresAt` datetime DEFAULT NULL,
  `connected` tinyint(1) NOT NULL DEFAULT '0',
  `pagesData` json DEFAULT NULL,
  `selectedPageId` varchar(255) DEFAULT NULL,
  `selectedPageName` varchar(255) DEFAULT NULL,
  `selectedInstagramBusinessAccountId` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `meta_accounts_tenant_id` (`tenantId`),
  CONSTRAINT `meta_accounts_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `meta_master_accounts`
--

DROP TABLE IF EXISTS `meta_master_accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `meta_master_accounts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `accessToken` text,
  `tokenExpiresAt` datetime DEFAULT NULL,
  `connected` tinyint(1) NOT NULL DEFAULT '0',
  `pagesData` json DEFAULT NULL,
  `selectedPageId` varchar(255) DEFAULT NULL,
  `selectedPageName` varchar(255) DEFAULT NULL,
  `selectedInstagramBusinessAccountId` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `order_items`
--

DROP TABLE IF EXISTS `order_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_items` (
  `id` int NOT NULL AUTO_INCREMENT,
  `orderId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `serviceId` int DEFAULT NULL,
  `productId` int DEFAULT NULL,
  `quantity` int NOT NULL DEFAULT '1',
  `price` decimal(10,2) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `orderItemStatusId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `orderId` (`orderId`),
  KEY `serviceId` (`serviceId`),
  KEY `productId` (`productId`),
  KEY `order_items_orderItemStatusId_foreign_idx` (`orderItemStatusId`),
  KEY `order_items_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`serviceId`) REFERENCES `services` (`id`) ON DELETE SET NULL,
  CONSTRAINT `order_items_ibfk_3` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE SET NULL,
  CONSTRAINT `order_items_orderItemStatusId_foreign_idx` FOREIGN KEY (`orderItemStatusId`) REFERENCES `order_items` (`id`),
  CONSTRAINT `order_items_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `order_items_status`
--

DROP TABLE IF EXISTS `order_items_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_items_status` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `color` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `order_status`
--

DROP TABLE IF EXISTS `order_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_status` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `color` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `order_status_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `order_status_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `receivedCash` decimal(10,2) DEFAULT NULL,
  `receivedCreditCard` decimal(10,2) DEFAULT NULL,
  `receivedDebitCard` decimal(10,2) DEFAULT NULL,
  `subtotal` decimal(10,2) DEFAULT '0.00',
  `total` decimal(10,2) DEFAULT '0.00',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `appointmentId` int DEFAULT NULL,
  `paymentMethodId` int DEFAULT NULL,
  `orderStatusId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  `clientId` int DEFAULT NULL,
  `serviceId` int DEFAULT NULL,
  `employeeId` int DEFAULT NULL,
  `couponId` int DEFAULT NULL,
  `cashRegisterId` int DEFAULT NULL,
  `ticketId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `unitId` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `orders_appointmentId_foreign_idx` (`appointmentId`),
  KEY `orders_paymentMethodId_foreign_idx` (`paymentMethodId`),
  KEY `orders_orderStatusId_foreign_idx` (`orderStatusId`),
  KEY `orders_tenantId_foreign_idx` (`tenantId`),
  KEY `orders_clientId_foreign_idx` (`clientId`),
  KEY `orders_serviceId_foreign_idx` (`serviceId`),
  KEY `orders_employeeId_foreign_idx` (`employeeId`),
  KEY `orders_couponId_foreign_idx` (`couponId`),
  KEY `orders_cashRegisterId_foreign_idx` (`cashRegisterId`),
  KEY `orders_ticketId_foreign_idx` (`ticketId`),
  KEY `orders_unitId_foreign_idx` (`unitId`),
  CONSTRAINT `orders_appointmentId_foreign_idx` FOREIGN KEY (`appointmentId`) REFERENCES `appointments` (`id`),
  CONSTRAINT `orders_cashRegisterId_foreign_idx` FOREIGN KEY (`cashRegisterId`) REFERENCES `cash_registers` (`id`),
  CONSTRAINT `orders_clientId_foreign_idx` FOREIGN KEY (`clientId`) REFERENCES `clients` (`id`),
  CONSTRAINT `orders_couponId_foreign_idx` FOREIGN KEY (`couponId`) REFERENCES `discount_coupons` (`id`),
  CONSTRAINT `orders_employeeId_foreign_idx` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`),
  CONSTRAINT `orders_orderStatusId_foreign_idx` FOREIGN KEY (`orderStatusId`) REFERENCES `order_status` (`id`),
  CONSTRAINT `orders_paymentMethodId_foreign_idx` FOREIGN KEY (`paymentMethodId`) REFERENCES `payment_methods` (`id`),
  CONSTRAINT `orders_serviceId_foreign_idx` FOREIGN KEY (`serviceId`) REFERENCES `services` (`id`),
  CONSTRAINT `orders_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `orders_ticketId_foreign_idx` FOREIGN KEY (`ticketId`) REFERENCES `tickets` (`id`),
  CONSTRAINT `orders_unitId_foreign_idx` FOREIGN KEY (`unitId`) REFERENCES `units` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `packages`
--

DROP TABLE IF EXISTS `packages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `packages` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL,
  `name` varchar(255) NOT NULL,
  `totalSessions` int NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `durationDays` int NOT NULL,
  `createdAt` datetime DEFAULT NULL,
  `updatedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tenantId` (`tenantId`),
  CONSTRAINT `packages_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `payment_methods`
--

DROP TABLE IF EXISTS `payment_methods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payment_methods` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `payment_methods_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `payment_methods_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `permissions`
--

DROP TABLE IF EXISTS `permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `permissions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `comments` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `permissions_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `permissions_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `plan_features`
--

DROP TABLE IF EXISTS `plan_features`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `plan_features` (
  `id` int NOT NULL AUTO_INCREMENT,
  `planId` int NOT NULL,
  `featureId` int NOT NULL,
  `value` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_plan_feature` (`planId`,`featureId`),
  UNIQUE KEY `idx_plan_features_plan_feature` (`planId`,`featureId`) USING BTREE,
  KEY `idx_plan_features_feature` (`featureId`) USING BTREE,
  CONSTRAINT `plan_features_ibfk_1` FOREIGN KEY (`planId`) REFERENCES `plans` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `plan_features_ibfk_2` FOREIGN KEY (`featureId`) REFERENCES `features` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=154 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `plan_price_overrides`
--

DROP TABLE IF EXISTS `plan_price_overrides`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `plan_price_overrides` (
  `id` int NOT NULL,
  `tenantId` int NOT NULL,
  `planId` int NOT NULL,
  `createdByUserId` int DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  `discountPercent` int DEFAULT NULL,
  `startsAt` datetime DEFAULT NULL,
  `endsAt` datetime DEFAULT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `tenantId` (`tenantId`),
  KEY `planId` (`planId`),
  KEY `createdByUserId` (`createdByUserId`),
  CONSTRAINT `plan_price_overrides_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `plan_price_overrides_ibfk_2` FOREIGN KEY (`planId`) REFERENCES `plans` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `plan_price_overrides_ibfk_3` FOREIGN KEY (`createdByUserId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `plan_status`
--

DROP TABLE IF EXISTS `plan_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `plan_status` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) DEFAULT NULL,
  `color` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `userId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `plan_status_userId_foreign_idx` (`userId`),
  KEY `plan_status_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `plan_status_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `plan_status_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=172 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `plans`
--

DROP TABLE IF EXISTS `plans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `plans` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `description` text,
  `durationDays` int DEFAULT NULL,
  `price` decimal(10,2) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `planStatusId` int DEFAULT NULL,
  `whatsappCredits` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT 'Créditos de WhatsApp inclusos no plano (em R$)',
  `whatsappMonthlyCredits` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT 'Créditos mensais recorrentes de WhatsApp (em R$)',
  `isTrial` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Se true, novo tenant entra com 7 dias de trial neste plano',
  `isCustomPricing` tinyint(1) NOT NULL DEFAULT '0',
  `trialDays` int DEFAULT NULL,
  `sortOrder` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `plans_planStatusId_foreign_idx` (`planStatusId`),
  CONSTRAINT `plans_planStatusId_foreign_idx` FOREIGN KEY (`planStatusId`) REFERENCES `plan_status` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `prescription_items`
--

DROP TABLE IF EXISTS `prescription_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `prescription_items` (
  `id` int NOT NULL AUTO_INCREMENT,
  `prescriptionId` int NOT NULL,
  `description` varchar(255) NOT NULL,
  `dosage` varchar(100) DEFAULT NULL,
  `frequency` varchar(100) DEFAULT NULL,
  `duration` varchar(100) DEFAULT NULL,
  `instructions` text,
  `extraData` json DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `prescription_items_prescription_id` (`prescriptionId`),
  CONSTRAINT `prescription_items_ibfk_1` FOREIGN KEY (`prescriptionId`) REFERENCES `prescriptions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `prescriptions`
--

DROP TABLE IF EXISTS `prescriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `prescriptions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL,
  `clientId` int NOT NULL,
  `employeeId` int DEFAULT NULL,
  `appointmentId` int DEFAULT NULL,
  `clinicalEvolutionId` int DEFAULT NULL,
  `type` enum('medication','exam','orientation','other') NOT NULL DEFAULT 'medication',
  `status` enum('active','fulfilled','cancelled','expired') NOT NULL DEFAULT 'active',
  `validUntil` date DEFAULT NULL,
  `notes` text,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `prescriptions_tenant_id` (`tenantId`),
  KEY `prescriptions_client_id` (`clientId`),
  KEY `prescriptions_employee_id` (`employeeId`),
  KEY `prescriptions_appointment_id` (`appointmentId`),
  KEY `prescriptions_clinical_evolution_id` (`clinicalEvolutionId`),
  KEY `prescriptions_status` (`status`),
  KEY `prescriptions_tenant_id_client_id` (`tenantId`,`clientId`),
  CONSTRAINT `prescriptions_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `prescriptions_ibfk_2` FOREIGN KEY (`clientId`) REFERENCES `clients` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `prescriptions_ibfk_3` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `prescriptions_ibfk_4` FOREIGN KEY (`appointmentId`) REFERENCES `appointments` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `prescriptions_ibfk_5` FOREIGN KEY (`clinicalEvolutionId`) REFERENCES `clinical_evolutions` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_categories`
--

DROP TABLE IF EXISTS `product_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_categories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `product_categories_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `product_categories_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_category_product`
--

DROP TABLE IF EXISTS `product_category_product`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_category_product` (
  `id` int NOT NULL AUTO_INCREMENT,
  `productId` int NOT NULL,
  `productCategoryId` int NOT NULL,
  `tenantId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `productId` (`productId`),
  KEY `productCategoryId` (`productCategoryId`),
  KEY `tenantId` (`tenantId`),
  KEY `userId` (`userId`),
  CONSTRAINT `product_category_product_ibfk_1` FOREIGN KEY (`productId`) REFERENCES `services` (`id`),
  CONSTRAINT `product_category_product_ibfk_2` FOREIGN KEY (`productCategoryId`) REFERENCES `product_categories` (`id`),
  CONSTRAINT `product_category_product_ibfk_3` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `product_category_product_ibfk_4` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_order`
--

DROP TABLE IF EXISTS `product_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_order` (
  `id` int NOT NULL AUTO_INCREMENT,
  `quantity` int DEFAULT NULL,
  `productId` int NOT NULL,
  `orderId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `productId` (`productId`),
  KEY `orderId` (`orderId`),
  KEY `product_order_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `product_order_ibfk_1` FOREIGN KEY (`productId`) REFERENCES `products` (`id`),
  CONSTRAINT `product_order_ibfk_2` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`),
  CONSTRAINT `product_order_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_provider`
--

DROP TABLE IF EXISTS `product_provider`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_provider` (
  `id` int NOT NULL AUTO_INCREMENT,
  `productId` int NOT NULL,
  `providerId` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `productId` (`productId`),
  KEY `providerId` (`providerId`),
  CONSTRAINT `product_provider_ibfk_1` FOREIGN KEY (`productId`) REFERENCES `products` (`id`),
  CONSTRAINT `product_provider_ibfk_2` FOREIGN KEY (`providerId`) REFERENCES `providers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `products`
--

DROP TABLE IF EXISTS `products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `products` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `brand` varchar(255) NOT NULL,
  `quantity` int NOT NULL,
  `costPrice` decimal(10,2) NOT NULL,
  `salePrice` decimal(10,2) NOT NULL,
  `comments` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `products_tenantId_foreign_idx` (`tenantId`),
  KEY `products_userId_foreign_idx` (`userId`),
  CONSTRAINT `products_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `products_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `providers`
--

DROP TABLE IF EXISTS `providers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `providers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `providers_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `providers_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `publication_types`
--

DROP TABLE IF EXISTS `publication_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `publication_types` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `push_subscriptions`
--

DROP TABLE IF EXISTS `push_subscriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `push_subscriptions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `userId` int DEFAULT NULL,
  `clientId` int DEFAULT NULL,
  `tenantId` int NOT NULL,
  `endpoint` varchar(500) NOT NULL,
  `p256dh` varchar(1000) NOT NULL,
  `auth` text NOT NULL,
  `userAgent` text,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `deviceToken` text,
  `platform` enum('web','fcm') NOT NULL DEFAULT 'web',
  PRIMARY KEY (`id`),
  UNIQUE KEY `endpoint` (`endpoint`),
  KEY `push_subscriptions_tenant_id` (`tenantId`),
  KEY `push_subscriptions_tenant_client` (`tenantId`,`clientId`),
  KEY `push_subscriptions_client_tenant` (`clientId`,`tenantId`),
  KEY `push_subscriptions_user_id` (`userId`),
  CONSTRAINT `push_subscriptions_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `push_subscriptions_ibfk_2` FOREIGN KEY (`clientId`) REFERENCES `clients` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ratings`
--

DROP TABLE IF EXISTS `ratings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ratings` (
  `id` int NOT NULL AUTO_INCREMENT,
  `quantity` int DEFAULT NULL,
  `comments` varchar(255) DEFAULT NULL,
  `employeeId` int DEFAULT NULL,
  `clientId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ratings_employeeId_foreign_idx` (`employeeId`),
  KEY `ratings_clientId_foreign_idx` (`clientId`),
  KEY `ratings_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `ratings_clientId_foreign_idx` FOREIGN KEY (`clientId`) REFERENCES `clients` (`id`),
  CONSTRAINT `ratings_employeeId_foreign_idx` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`),
  CONSTRAINT `ratings_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reports`
--

DROP TABLE IF EXISTS `reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reports` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `revenueId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `expenseId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `reports_revenue_id` (`revenueId`),
  KEY `reports_expense_id` (`expenseId`),
  KEY `reports_tenant_id_created_at` (`tenantId`,`createdAt`),
  CONSTRAINT `reports_expenseId_foreign_idx` FOREIGN KEY (`expenseId`) REFERENCES `expenses` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `reports_revenueId_foreign_idx` FOREIGN KEY (`revenueId`) REFERENCES `revenues` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `revenue_categories`
--

DROP TABLE IF EXISTS `revenue_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `revenue_categories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `revenue_categories_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `revenue_categories_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `revenues`
--

DROP TABLE IF EXISTS `revenues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `revenues` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `dueDate` datetime DEFAULT NULL,
  `entryDate` datetime DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `userId` int DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `orderId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `revenueCategoryId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  `unitId` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `userId` (`userId`),
  KEY `revenues_orderId_foreign_idx` (`orderId`),
  KEY `revenues_revenueCategoryId_foreign_idx` (`revenueCategoryId`),
  KEY `revenues_tenantId_foreign_idx` (`tenantId`),
  KEY `revenues_unitId_foreign_idx` (`unitId`),
  CONSTRAINT `revenues_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `revenues_orderId_foreign_idx` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`),
  CONSTRAINT `revenues_revenueCategoryId_foreign_idx` FOREIGN KEY (`revenueCategoryId`) REFERENCES `revenue_categories` (`id`),
  CONSTRAINT `revenues_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `revenues_unitId_foreign_idx` FOREIGN KEY (`unitId`) REFERENCES `units` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `role_permission`
--

DROP TABLE IF EXISTS `role_permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_permission` (
  `id` int NOT NULL AUTO_INCREMENT,
  `permissionId` int NOT NULL,
  `roleId` int NOT NULL,
  `tenantId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `permissionId` (`permissionId`),
  KEY `roleId` (`roleId`),
  KEY `tenantId` (`tenantId`),
  KEY `userId` (`userId`),
  CONSTRAINT `role_permission_ibfk_1` FOREIGN KEY (`permissionId`) REFERENCES `permissions` (`id`),
  CONSTRAINT `role_permission_ibfk_2` FOREIGN KEY (`roleId`) REFERENCES `roles` (`id`),
  CONSTRAINT `role_permission_ibfk_3` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `role_permission_ibfk_4` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=105 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `role_user`
--

DROP TABLE IF EXISTS `role_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `role_user` (
  `id` int NOT NULL AUTO_INCREMENT,
  `userId` int NOT NULL,
  `tenantId` int DEFAULT NULL,
  `roleId` int NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `userId` (`userId`),
  KEY `tenantId` (`tenantId`),
  KEY `roleId` (`roleId`),
  CONSTRAINT `role_user_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`),
  CONSTRAINT `role_user_ibfk_2` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `role_user_ibfk_3` FOREIGN KEY (`roleId`) REFERENCES `roles` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `comments` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `roles_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `roles_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sales_agent_commission_installments`
--

DROP TABLE IF EXISTS `sales_agent_commission_installments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sales_agent_commission_installments` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `installmentNumber` int NOT NULL COMMENT 'Número da parcela: 1, 2, 3 ... commissionMonths',
  `paymentId` varchar(255) NOT NULL COMMENT 'paymentId do Asaas',
  `amount` decimal(10,2) NOT NULL COMMENT 'Valor em R$ a pagar ao agente nessa parcela',
  `dueDate` date NOT NULL COMMENT 'Data prevista de pagamento ao agente',
  `paidAt` datetime DEFAULT NULL COMMENT 'Data em que o repasse foi efetivamente pago ao agente',
  `status` enum('pending','approved','paid','cancelled') NOT NULL DEFAULT 'pending',
  `salesAgentCommissionId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `referenceMonth` varchar(255) NOT NULL,
  `approvedAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `termId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Faixa (term) que originou esse lançamento',
  `paymentDate` datetime DEFAULT NULL COMMENT 'Data do pagamento do cliente que originou o lançamento',
  `billingCycle` enum('monthly','quarterly','annual') DEFAULT NULL COMMENT 'Ciclo de cobrança da assinatura no momento do lançamento',
  `unitFrom` int DEFAULT NULL,
  `unitTo` int DEFAULT NULL,
  `unitsCovered` int DEFAULT NULL,
  `baseAmount` decimal(10,2) DEFAULT NULL COMMENT 'Base de cálculo usada: amount = baseAmount * percentApplied / 100',
  `percentApplied` decimal(5,2) DEFAULT NULL,
  `entryType` enum('credit','reversal') NOT NULL DEFAULT 'credit',
  `reversalOfId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Lançamento de crédito que esse estorno anula. Lógica de refund NÃO implementada neste ciclo',
  `payoutDueDate` date DEFAULT NULL,
  `payoutBatchId` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_commission_payment_term_entry` (`salesAgentCommissionId`,`paymentId`,`termId`,`entryType`),
  KEY `sales_agent_commission_installments_sales_agent_commission_id` (`salesAgentCommissionId`),
  KEY `sales_agent_commission_installments_due_date` (`dueDate`),
  KEY `sales_agent_commission_installments_status` (`status`),
  KEY `sales_agent_commission_installments_term_id` (`termId`),
  KEY `sales_agent_commission_installments_payment_id` (`paymentId`),
  KEY `sales_agent_commission_installments_reversal_of_id` (`reversalOfId`),
  KEY `sales_agent_commission_installments_payout_batch_id` (`payoutBatchId`),
  CONSTRAINT `sales_agent_commission_installments_ibfk_1` FOREIGN KEY (`salesAgentCommissionId`) REFERENCES `sales_agent_commissions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sales_agent_commission_installments_reversalOfId_foreign_idx` FOREIGN KEY (`reversalOfId`) REFERENCES `sales_agent_commission_installments` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `sales_agent_commission_installments_termId_foreign_idx` FOREIGN KEY (`termId`) REFERENCES `sales_agent_commission_terms` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sales_agent_commission_terms`
--

DROP TABLE IF EXISTS `sales_agent_commission_terms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sales_agent_commission_terms` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `salesAgentCommissionId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `tierOrder` int NOT NULL,
  `fromUnit` int NOT NULL,
  `toUnit` int DEFAULT NULL COMMENT 'NULL = faixa aberta até o fim do contrato',
  `percent` decimal(5,2) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sales_agent_commission_terms_sales_agent_commission_id` (`salesAgentCommissionId`),
  KEY `sales_agent_commission_terms_commission_tier_order` (`salesAgentCommissionId`,`tierOrder`),
  CONSTRAINT `sales_agent_commission_terms_ibfk_1` FOREIGN KEY (`salesAgentCommissionId`) REFERENCES `sales_agent_commissions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sales_agent_commissions`
--

DROP TABLE IF EXISTS `sales_agent_commissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sales_agent_commissions` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `percent` decimal(5,2) DEFAULT NULL COMMENT 'DEPRECADO: use sales_agent_commission_terms.percent',
  `startDate` date NOT NULL COMMENT 'Data de início da vigência (= data da assinatura)',
  `endDate` date DEFAULT NULL COMMENT 'DEPRECADO: use totalUnits / hardEndDate',
  `commissionMonths` int DEFAULT NULL COMMENT 'DEPRECADO: use totalUnits',
  `paidInstallments` int NOT NULL DEFAULT '0' COMMENT 'Contador de parcelas já pagas',
  `totalInstallments` int DEFAULT NULL COMMENT 'DEPRECADO: derivado das parcelas geradas',
  `status` enum('active','suspended','completed','cancelled') NOT NULL DEFAULT 'active',
  `salesAgentId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `tenantId` int NOT NULL,
  `signatureId` int NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `commissionPlanId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `basis` enum('billing_month','payment') NOT NULL DEFAULT 'billing_month' COMMENT 'Snapshot do basis do plano no momento da contratação',
  `tierBasis` enum('sequence','volume') NOT NULL DEFAULT 'sequence' COMMENT 'Snapshot do tierBasis do plano. ''volume'' reservado, não implementado',
  `totalUnits` int DEFAULT NULL COMMENT 'Snapshot do totalUnits do plano. NULL = ilimitado',
  `hardEndDate` date DEFAULT NULL COMMENT 'Corte duro opcional: nada é gerado depois dessa data, mesmo com unidades restantes',
  `kind` enum('direct','override') NOT NULL DEFAULT 'direct' COMMENT 'direct = agente que vendeu; override = comissão do agente pai sobre a venda',
  `parentCommissionId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Contrato direct que originou esse override. Lógica pai/filho NÃO implementada neste ciclo',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_sales_agent_commission_contract` (`salesAgentId`,`tenantId`,`signatureId`,`kind`),
  KEY `sales_agent_commissions_sales_agent_id` (`salesAgentId`),
  KEY `sales_agent_commissions_tenant_id` (`tenantId`),
  KEY `sales_agent_commissions_signature_id` (`signatureId`),
  KEY `sales_agent_commissions_status` (`status`),
  KEY `sales_agent_commissions_end_date` (`endDate`),
  KEY `sales_agent_commissions_commission_plan_id` (`commissionPlanId`),
  KEY `sales_agent_commissions_parent_commission_id` (`parentCommissionId`),
  KEY `sales_agent_commissions_kind` (`kind`),
  CONSTRAINT `sales_agent_commissions_commissionPlanId_foreign_idx` FOREIGN KEY (`commissionPlanId`) REFERENCES `commission_plans` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `sales_agent_commissions_ibfk_1` FOREIGN KEY (`salesAgentId`) REFERENCES `sales_agents` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `sales_agent_commissions_ibfk_2` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `sales_agent_commissions_ibfk_3` FOREIGN KEY (`signatureId`) REFERENCES `signatures` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `sales_agent_commissions_parentCommissionId_foreign_idx` FOREIGN KEY (`parentCommissionId`) REFERENCES `sales_agent_commissions` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sales_agent_overrides`
--

DROP TABLE IF EXISTS `sales_agent_overrides`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sales_agent_overrides` (
  `id` int NOT NULL AUTO_INCREMENT,
  `salesAgentId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `key` varchar(255) DEFAULT NULL,
  `value` int DEFAULT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `starts_at` datetime NOT NULL,
  `ends_at` datetime NOT NULL,
  `createdByUserId` int NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `salesAgentId` (`salesAgentId`),
  KEY `createdByUserId` (`createdByUserId`),
  CONSTRAINT `sales_agent_overrides_ibfk_1` FOREIGN KEY (`salesAgentId`) REFERENCES `sales_agents` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `sales_agent_overrides_ibfk_2` FOREIGN KEY (`createdByUserId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sales_agent_status`
--

DROP TABLE IF EXISTS `sales_agent_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sales_agent_status` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) DEFAULT NULL,
  `color` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sales_agents`
--

DROP TABLE IF EXISTS `sales_agents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sales_agents` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `commissionMonths` int DEFAULT '12',
  `bankName` varchar(255) DEFAULT NULL,
  `bankCode` varchar(10) DEFAULT NULL,
  `agency` varchar(20) DEFAULT NULL,
  `agencyDigit` varchar(5) DEFAULT NULL,
  `accountNumber` varchar(20) DEFAULT NULL,
  `accountDigit` varchar(5) DEFAULT NULL,
  `accountType` enum('checking','savings','pix') DEFAULT 'pix',
  `pixKey` varchar(255) DEFAULT NULL,
  `salesAgentPaiId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `createdAt` datetime DEFAULT NULL,
  `updatedAt` datetime DEFAULT NULL,
  `userId` int DEFAULT NULL,
  `salesAgentStatusId` int DEFAULT NULL,
  `defaultCommissionPlanId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sales_agents_userId_foreign_idx` (`userId`),
  KEY `sales_agents_salesAgentStatusId_foreign_idx` (`salesAgentStatusId`),
  KEY `sales_agents_defaultCommissionPlanId_foreign_idx` (`defaultCommissionPlanId`),
  CONSTRAINT `sales_agents_defaultCommissionPlanId_foreign_idx` FOREIGN KEY (`defaultCommissionPlanId`) REFERENCES `commission_plans` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `sales_agents_salesAgentStatusId_foreign_idx` FOREIGN KEY (`salesAgentStatusId`) REFERENCES `sales_agent_status` (`id`),
  CONSTRAINT `sales_agents_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `segment_types`
--

DROP TABLE IF EXISTS `segment_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `segment_types` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) DEFAULT NULL,
  `color` varchar(255) DEFAULT NULL,
  `icon` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `clinicalRecordsEnabled` tinyint(1) NOT NULL DEFAULT '0' COMMENT 'Habilita módulo de prontuário clínico (anamnese, evolução, prescrição) pro segmento',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `service_categories`
--

DROP TABLE IF EXISTS `service_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `service_categories` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `image` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `service_categories_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `service_categories_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3826 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `service_category_service`
--

DROP TABLE IF EXISTS `service_category_service`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `service_category_service` (
  `id` int NOT NULL AUTO_INCREMENT,
  `serviceId` int NOT NULL,
  `serviceCategoryId` int NOT NULL,
  `tenantId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `serviceId` (`serviceId`),
  KEY `serviceCategoryId` (`serviceCategoryId`),
  KEY `tenantId` (`tenantId`),
  KEY `userId` (`userId`),
  CONSTRAINT `service_category_service_ibfk_1` FOREIGN KEY (`serviceId`) REFERENCES `services` (`id`),
  CONSTRAINT `service_category_service_ibfk_2` FOREIGN KEY (`serviceCategoryId`) REFERENCES `service_categories` (`id`),
  CONSTRAINT `service_category_service_ibfk_3` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `service_category_service_ibfk_4` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=425 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `service_order`
--

DROP TABLE IF EXISTS `service_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `service_order` (
  `id` int NOT NULL AUTO_INCREMENT,
  `quantity` int DEFAULT NULL,
  `serviceId` int NOT NULL,
  `orderId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `employeeId` int NOT NULL,
  `tenantId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `serviceId` (`serviceId`),
  KEY `orderId` (`orderId`),
  KEY `employeeId` (`employeeId`),
  KEY `tenantId` (`tenantId`),
  KEY `userId` (`userId`),
  CONSTRAINT `service_order_ibfk_1` FOREIGN KEY (`serviceId`) REFERENCES `services` (`id`),
  CONSTRAINT `service_order_ibfk_2` FOREIGN KEY (`orderId`) REFERENCES `orders` (`id`),
  CONSTRAINT `service_order_ibfk_3` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`),
  CONSTRAINT `service_order_ibfk_4` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `service_order_ibfk_5` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `service_templates`
--

DROP TABLE IF EXISTS `service_templates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `service_templates` (
  `id` int NOT NULL AUTO_INCREMENT,
  `defaultCategoryId` int DEFAULT NULL,
  `segmentTypeId` int NOT NULL,
  `name` varchar(255) NOT NULL,
  `suggestedPrice` decimal(10,2) DEFAULT NULL,
  `defaultDurationId` int NOT NULL,
  `defaultComplexityId` int DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `defaultCategoryId` (`defaultCategoryId`),
  KEY `segmentTypeId` (`segmentTypeId`),
  KEY `defaultDurationId` (`defaultDurationId`),
  KEY `defaultComplexityId` (`defaultComplexityId`),
  CONSTRAINT `service_templates_ibfk_1` FOREIGN KEY (`defaultCategoryId`) REFERENCES `service_categories` (`id`),
  CONSTRAINT `service_templates_ibfk_2` FOREIGN KEY (`segmentTypeId`) REFERENCES `segment_types` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `service_templates_ibfk_3` FOREIGN KEY (`defaultDurationId`) REFERENCES `durations` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `service_templates_ibfk_4` FOREIGN KEY (`defaultComplexityId`) REFERENCES `complexities` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=52 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `services`
--

DROP TABLE IF EXISTS `services`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `services` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `price` decimal(6,2) DEFAULT NULL,
  `discount` decimal(5,2) DEFAULT NULL,
  `promoPrice` decimal(6,2) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `durationId` int DEFAULT NULL,
  `complexityId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  `templateId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_services_name_tenant` (`name`,`tenantId`),
  KEY `services_durationId_foreign_idx` (`durationId`),
  KEY `services_complexityId_foreign_idx` (`complexityId`),
  KEY `services_userId_foreign_idx` (`userId`),
  KEY `services_templateId_foreign_idx` (`templateId`),
  KEY `idx_services_tenant` (`tenantId`) USING BTREE,
  CONSTRAINT `services_complexityId_foreign_idx` FOREIGN KEY (`complexityId`) REFERENCES `complexities` (`id`),
  CONSTRAINT `services_durationId_foreign_idx` FOREIGN KEY (`durationId`) REFERENCES `durations` (`id`),
  CONSTRAINT `services_templateId_foreign_idx` FOREIGN KEY (`templateId`) REFERENCES `service_templates` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `services_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `services_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=421 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `signature_status`
--

DROP TABLE IF EXISTS `signature_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `signature_status` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) DEFAULT NULL,
  `color` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `userId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `signature_status_userId_foreign_idx` (`userId`),
  KEY `signature_status_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `signature_status_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `signature_status_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `signatures`
--

DROP TABLE IF EXISTS `signatures`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `signatures` (
  `id` int NOT NULL AUTO_INCREMENT,
  `asaasId` varchar(255) DEFAULT NULL,
  `customerAsaasId` varchar(255) DEFAULT NULL,
  `externalReference` varchar(255) DEFAULT NULL,
  `paymentMethod` varchar(255) DEFAULT NULL,
  `nextDueDate` date DEFAULT NULL,
  `isActive` tinyint(1) DEFAULT '1',
  `start` date NOT NULL,
  `end` date DEFAULT NULL,
  `billingCycle` enum('monthly','quarterly','annual') DEFAULT NULL COMMENT 'Ciclo de cobrança: mensal, trimestral ou anual. Null para plano gratuito.',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  `planId` int DEFAULT NULL,
  `signatureStatusId` int DEFAULT NULL,
  `lastPaymentDate` datetime DEFAULT NULL COMMENT 'Data do último pagamento recebido',
  `canceledAt` datetime DEFAULT NULL COMMENT 'Data do cancelamento da assinatura',
  `isTrial` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `signatures_signatureStatusId_foreign_idx` (`signatureStatusId`),
  KEY `idx_signatures_tenant_active` (`tenantId`,`isActive`) USING BTREE,
  KEY `idx_signatures_customer_asaas_id` (`customerAsaasId`),
  KEY `idx_signatures_tenant_status` (`tenantId`,`signatureStatusId`),
  KEY `idx_signatures_plan_id` (`planId`),
  KEY `idx_signatures_next_due_date` (`nextDueDate`),
  KEY `idx_signatures_tenant_billing_cycle` (`tenantId`,`billingCycle`),
  CONSTRAINT `signatures_planId_foreign_idx` FOREIGN KEY (`planId`) REFERENCES `plans` (`id`),
  CONSTRAINT `signatures_signatureStatusId_foreign_idx` FOREIGN KEY (`signatureStatusId`) REFERENCES `signature_status` (`id`),
  CONSTRAINT `signatures_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=925 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `status_supports`
--

DROP TABLE IF EXISTS `status_supports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `status_supports` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `comments` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stocks`
--

DROP TABLE IF EXISTS `stocks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stocks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `quantity` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  `productId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `stocks_tenantId_foreign_idx` (`tenantId`),
  KEY `stocks_productId_foreign_idx` (`productId`),
  CONSTRAINT `stocks_productId_foreign_idx` FOREIGN KEY (`productId`) REFERENCES `products` (`id`),
  CONSTRAINT `stocks_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `subscription_plans`
--

DROP TABLE IF EXISTS `subscription_plans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `subscription_plans` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL,
  `name` varchar(255) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `sessionsPerCycle` int NOT NULL,
  `cycleDays` int NOT NULL,
  `createdAt` datetime DEFAULT NULL,
  `updatedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tenantId` (`tenantId`),
  CONSTRAINT `subscription_plans_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `supports`
--

DROP TABLE IF EXISTS `supports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `supports` (
  `id` int NOT NULL AUTO_INCREMENT,
  `firstName` varchar(255) NOT NULL,
  `lastName` varchar(255) DEFAULT NULL,
  `email` varchar(255) NOT NULL,
  `receiveNotifications` tinyint(1) NOT NULL DEFAULT '1',
  `subject` varchar(255) NOT NULL,
  `otherSubject` varchar(255) DEFAULT NULL,
  `files` json DEFAULT NULL,
  `comments` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `statusId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `supports_statusId_foreign_idx` (`statusId`),
  CONSTRAINT `supports_statusId_foreign_idx` FOREIGN KEY (`statusId`) REFERENCES `status_supports` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `system_permissions`
--

DROP TABLE IF EXISTS `system_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `system_permissions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `system_role_permissions`
--

DROP TABLE IF EXISTS `system_role_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `system_role_permissions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `systemRoleId` int NOT NULL,
  `systemPermissionId` int NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `systemRoleId` (`systemRoleId`),
  KEY `systemPermissionId` (`systemPermissionId`),
  CONSTRAINT `system_role_permissions_ibfk_1` FOREIGN KEY (`systemRoleId`) REFERENCES `system_roles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `system_role_permissions_ibfk_2` FOREIGN KEY (`systemPermissionId`) REFERENCES `system_permissions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `system_roles`
--

DROP TABLE IF EXISTS `system_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `system_roles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tenant_nf_configs`
--

DROP TABLE IF EXISTS `tenant_nf_configs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tenant_nf_configs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL,
  `cityCode` varchar(255) DEFAULT NULL,
  `serviceCode` varchar(255) DEFAULT NULL,
  `taxRate` decimal(5,2) DEFAULT NULL,
  `certificatePath` varchar(255) DEFAULT NULL,
  `certificatePassword` varchar(255) DEFAULT NULL,
  `emitterType` enum('MANUAL','GATEWAY','OWN_API') DEFAULT 'MANUAL',
  `createdAt` datetime DEFAULT NULL,
  `updatedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tenantId` (`tenantId`),
  CONSTRAINT `tenant_nf_configs_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tenant_status`
--

DROP TABLE IF EXISTS `tenant_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tenant_status` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `label` varchar(255) DEFAULT NULL,
  `color` varchar(255) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tenant_types`
--

DROP TABLE IF EXISTS `tenant_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tenant_types` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) DEFAULT NULL,
  `color` varchar(255) DEFAULT NULL,
  `comments` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tenants`
--

DROP TABLE IF EXISTS `tenants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tenants` (
  `id` int NOT NULL AUTO_INCREMENT,
  `firstName` varchar(255) NOT NULL,
  `lastName` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `rg` varchar(255) DEFAULT NULL,
  `cpf` varchar(255) DEFAULT NULL,
  `cnpj` varchar(255) DEFAULT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `mobilePhone` varchar(255) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `logo` varchar(255) DEFAULT NULL,
  `officeName` varchar(255) DEFAULT NULL,
  `avatar` varchar(255) DEFAULT NULL,
  `whatsappProvider` varchar(50) DEFAULT 'wppconnect',
  `whatsappInstanceName` varchar(100) DEFAULT NULL,
  `whatsappSessionPath` varchar(255) DEFAULT NULL,
  `whatsappStatus` varchar(20) DEFAULT 'offline',
  `whatsappWebhookUrl` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `expiresTrialAt` datetime DEFAULT NULL,
  `trialExtended` tinyint(1) DEFAULT '0',
  `isDemo` tinyint(1) DEFAULT '0',
  `tenantStatusId` int DEFAULT NULL,
  `tenantTypeId` int DEFAULT NULL,
  `salesAgentId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `acquisitionSourceId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `segmentTypeId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tenants_tenantStatusId_foreign_idx` (`tenantStatusId`),
  KEY `tenants_tenantTypeId_foreign_idx` (`tenantTypeId`),
  KEY `tenants_salesAgentId_foreign_idx` (`salesAgentId`),
  KEY `tenants_acquisitionSourceId_foreign_idx` (`acquisitionSourceId`),
  KEY `tenants_segmentTypeId_foreign_idx` (`segmentTypeId`),
  CONSTRAINT `tenants_acquisitionSourceId_foreign_idx` FOREIGN KEY (`acquisitionSourceId`) REFERENCES `acquisition_sources` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `tenants_salesAgentId_foreign_idx` FOREIGN KEY (`salesAgentId`) REFERENCES `sales_agents` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `tenants_segmentTypeId_foreign_idx` FOREIGN KEY (`segmentTypeId`) REFERENCES `segment_types` (`id`),
  CONSTRAINT `tenants_tenantStatusId_foreign_idx` FOREIGN KEY (`tenantStatusId`) REFERENCES `tenant_status` (`id`),
  CONSTRAINT `tenants_tenantTypeId_foreign_idx` FOREIGN KEY (`tenantTypeId`) REFERENCES `tenant_types` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=902 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tenants_users`
--

DROP TABLE IF EXISTS `tenants_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tenants_users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `userId` int NOT NULL,
  `tenantId` int NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `userId` (`userId`),
  KEY `tenantId` (`tenantId`),
  CONSTRAINT `tenants_users_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`id`),
  CONSTRAINT `tenants_users_ibfk_2` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ticket_items`
--

DROP TABLE IF EXISTS `ticket_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ticket_items` (
  `id` int NOT NULL AUTO_INCREMENT,
  `ticketId` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `serviceId` int DEFAULT NULL,
  `productId` int DEFAULT NULL,
  `quantity` int NOT NULL DEFAULT '1',
  `price` decimal(10,2) NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  `employeeId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ticketId` (`ticketId`),
  KEY `serviceId` (`serviceId`),
  KEY `productId` (`productId`),
  KEY `ticket_items_tenantId_foreign_idx` (`tenantId`),
  KEY `ticket_items_employeeId_foreign_idx` (`employeeId`),
  CONSTRAINT `ticket_items_employeeId_foreign_idx` FOREIGN KEY (`employeeId`) REFERENCES `employees` (`id`),
  CONSTRAINT `ticket_items_ibfk_1` FOREIGN KEY (`ticketId`) REFERENCES `tickets` (`id`) ON DELETE CASCADE,
  CONSTRAINT `ticket_items_ibfk_2` FOREIGN KEY (`serviceId`) REFERENCES `services` (`id`) ON DELETE SET NULL,
  CONSTRAINT `ticket_items_ibfk_3` FOREIGN KEY (`productId`) REFERENCES `products` (`id`) ON DELETE SET NULL,
  CONSTRAINT `ticket_items_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ticket_status`
--

DROP TABLE IF EXISTS `ticket_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ticket_status` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) DEFAULT NULL,
  `color` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tickets`
--

DROP TABLE IF EXISTS `tickets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tickets` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `appointmentId` int DEFAULT NULL,
  `ticketStatusId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tickets_appointmentId_foreign_idx` (`appointmentId`),
  KEY `tickets_ticketStatusId_foreign_idx` (`ticketStatusId`),
  KEY `tickets_userId_foreign_idx` (`userId`),
  KEY `tickets_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `tickets_appointmentId_foreign_idx` FOREIGN KEY (`appointmentId`) REFERENCES `appointments` (`id`),
  CONSTRAINT `tickets_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `tickets_ticketStatusId_foreign_idx` FOREIGN KEY (`ticketStatusId`) REFERENCES `ticket_status` (`id`),
  CONSTRAINT `tickets_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `transaction_types`
--

DROP TABLE IF EXISTS `transaction_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `transaction_types` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `trial_extendeds`
--

DROP TABLE IF EXISTS `trial_extendeds`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `trial_extendeds` (
  `id` int NOT NULL AUTO_INCREMENT,
  `days` int NOT NULL DEFAULT '7',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `trial_extendeds_tenantId_foreign_idx` (`tenantId`),
  KEY `trial_extendeds_userId_foreign_idx` (`userId`),
  CONSTRAINT `trial_extendeds_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `trial_extendeds_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `unit_availabilities`
--

DROP TABLE IF EXISTS `unit_availabilities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `unit_availabilities` (
  `id` int NOT NULL AUTO_INCREMENT,
  `unitId` int NOT NULL,
  `tenantId` int NOT NULL,
  `dayOfWeek` int NOT NULL,
  `startTime` time NOT NULL,
  `endTime` time NOT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `tenantId` (`tenantId`),
  KEY `unit_availabilities_unit_id_day_of_week` (`unitId`,`dayOfWeek`),
  CONSTRAINT `unit_availabilities_ibfk_1` FOREIGN KEY (`unitId`) REFERENCES `units` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `unit_availabilities_ibfk_2` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=127 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `units`
--

DROP TABLE IF EXISTS `units`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `units` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL,
  `name` varchar(255) NOT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `number` varchar(255) DEFAULT NULL,
  `neighborhood` varchar(255) DEFAULT NULL,
  `city` varchar(255) DEFAULT NULL,
  `state` varchar(255) DEFAULT NULL,
  `zipCode` varchar(255) DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `status` varchar(255) DEFAULT 'active',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_units_tenant` (`tenantId`) USING BTREE,
  CONSTRAINT `units_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_status`
--

DROP TABLE IF EXISTS `user_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_status` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `label` varchar(255) NOT NULL,
  `color` varchar(255) NOT NULL,
  `icon` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_status_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `user_status_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` int NOT NULL AUTO_INCREMENT,
  `firstName` varchar(255) NOT NULL,
  `lastName` varchar(255) DEFAULT NULL,
  `email` varchar(255) NOT NULL,
  `phone` varchar(255) DEFAULT NULL,
  `cpf` varchar(255) DEFAULT NULL,
  `mobilePhone` varchar(255) DEFAULT NULL,
  `avatar` varchar(255) DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `facebookId` varchar(255) DEFAULT NULL,
  `fbLoginToken` varchar(255) DEFAULT NULL,
  `fbMarketingToken` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `roleId` int DEFAULT NULL,
  `genderId` int DEFAULT NULL,
  `userStatusId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  `userId` int DEFAULT NULL,
  `businessId` int DEFAULT NULL,
  `systemRoleId` int DEFAULT NULL,
  `passwordResetToken` varchar(255) DEFAULT NULL COMMENT 'Token único para redefinição de senha',
  `passwordResetExpires` datetime DEFAULT NULL COMMENT 'Data de expiração do token de redefinição',
  `emailVerified` tinyint(1) NOT NULL DEFAULT '0',
  `emailVerifiedAt` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `users_roleId_foreign_idx` (`roleId`),
  KEY `users_genderId_foreign_idx` (`genderId`),
  KEY `users_userStatusId_foreign_idx` (`userStatusId`),
  KEY `users_userId_foreign_idx` (`userId`),
  KEY `users_businessId_foreign_idx` (`businessId`),
  KEY `users_systemRoleId_foreign_idx` (`systemRoleId`),
  KEY `idx_users_tenant` (`tenantId`) USING BTREE,
  KEY `idx_users_password_reset_token` (`passwordResetToken`),
  CONSTRAINT `users_businessId_foreign_idx` FOREIGN KEY (`businessId`) REFERENCES `business` (`id`),
  CONSTRAINT `users_genderId_foreign_idx` FOREIGN KEY (`genderId`) REFERENCES `genders` (`id`),
  CONSTRAINT `users_roleId_foreign_idx` FOREIGN KEY (`roleId`) REFERENCES `roles` (`id`),
  CONSTRAINT `users_systemRoleId_foreign_idx` FOREIGN KEY (`systemRoleId`) REFERENCES `system_roles` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `users_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE SET NULL,
  CONSTRAINT `users_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`),
  CONSTRAINT `users_userStatusId_foreign_idx` FOREIGN KEY (`userStatusId`) REFERENCES `user_status` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `webhook_events`
--

DROP TABLE IF EXISTS `webhook_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `webhook_events` (
  `id` char(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `provider` varchar(255) NOT NULL,
  `externalEventId` varchar(255) NOT NULL,
  `eventType` varchar(255) NOT NULL,
  `payload` json NOT NULL,
  `status` enum('pending','processed','failed') DEFAULT 'pending',
  `errorMessage` text,
  `processedAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_provider_event` (`provider`,`externalEventId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `website_locations`
--

DROP TABLE IF EXISTS `website_locations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `website_locations` (
  `id` int NOT NULL AUTO_INCREMENT,
  `locationId` int NOT NULL,
  `tenantId` int NOT NULL,
  `userId` int NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `locationId` (`locationId`),
  KEY `tenantId` (`tenantId`),
  KEY `userId` (`userId`),
  CONSTRAINT `website_locations_ibfk_1` FOREIGN KEY (`locationId`) REFERENCES `locations` (`id`) ON DELETE CASCADE,
  CONSTRAINT `website_locations_ibfk_2` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  CONSTRAINT `website_locations_ibfk_3` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `websites`
--

DROP TABLE IF EXISTS `websites`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `websites` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) DEFAULT NULL,
  `description` longtext,
  `subdomain` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `logo` varchar(255) DEFAULT NULL,
  `favicon` varchar(255) DEFAULT NULL,
  `logoPosition` varchar(255) DEFAULT NULL,
  `primaryColor` varchar(255) DEFAULT NULL,
  `secondaryColor` varchar(255) DEFAULT NULL,
  `navColor` varchar(255) DEFAULT NULL,
  `menuPosition` varchar(255) DEFAULT NULL,
  `heroText` varchar(255) DEFAULT NULL,
  `heroSubText` varchar(255) DEFAULT NULL,
  `heroImages` json DEFAULT NULL,
  `footerText` varchar(255) DEFAULT NULL,
  `customCss` varchar(255) DEFAULT NULL,
  `facebook` varchar(255) DEFAULT NULL,
  `instagram` varchar(255) DEFAULT NULL,
  `threads` varchar(255) DEFAULT NULL,
  `twitter` varchar(255) DEFAULT NULL,
  `tiktok` varchar(255) DEFAULT NULL,
  `youtube` varchar(255) DEFAULT NULL,
  `locationsServed` json DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `userId` int DEFAULT NULL,
  `tenantId` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `websites_userId_foreign_idx` (`userId`),
  KEY `websites_tenantId_foreign_idx` (`tenantId`),
  CONSTRAINT `websites_tenantId_foreign_idx` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`),
  CONSTRAINT `websites_userId_foreign_idx` FOREIGN KEY (`userId`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `whatsapp_credit_transactions`
--

DROP TABLE IF EXISTS `whatsapp_credit_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `whatsapp_credit_transactions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `walletId` int NOT NULL,
  `type` enum('credit','debit') NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `referenceId` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `createdAt` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `whatsapp_credit_transactions_wallet_id` (`walletId`),
  CONSTRAINT `fk_transaction_wallet` FOREIGN KEY (`walletId`) REFERENCES `whatsapp_credit_wallets` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `whatsapp_credit_wallets`
--

DROP TABLE IF EXISTS `whatsapp_credit_wallets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `whatsapp_credit_wallets` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL,
  `balance` decimal(10,2) NOT NULL DEFAULT '0.00',
  `twilio_account_sid` varchar(255) DEFAULT NULL,
  `twilio_auth_token` varchar(255) DEFAULT NULL,
  `twilio_phone_number` varchar(20) DEFAULT NULL,
  `twilio_whatsapp_number` varchar(20) DEFAULT NULL,
  `twilio_enabled` tinyint(1) NOT NULL DEFAULT '0',
  `createdAt` datetime NOT NULL,
  `updatedAt` datetime NOT NULL,
  `whatsappNumber` varchar(255) DEFAULT NULL COMMENT 'Número do WhatsApp do tenant (usado para identificar tenant nos webhooks)',
  `providerConfig` json DEFAULT NULL COMMENT 'Configurações específicas do provedor (phone_number_id, etc)',
  `activeProvider` varchar(255) NOT NULL DEFAULT 'meta' COMMENT 'Provedor ativo: meta, twilio, etc',
  PRIMARY KEY (`id`),
  UNIQUE KEY `whatsapp_credit_wallets_tenant_id` (`tenantId`),
  UNIQUE KEY `whatsappNumber` (`whatsappNumber`),
  KEY `idx_wallets_twilio_enabled` (`twilio_enabled`),
  KEY `idx_whatsapp_wallets_number` (`whatsappNumber`),
  CONSTRAINT `fk_wallet_tenant` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `whatsapp_messages`
--

DROP TABLE IF EXISTS `whatsapp_messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `whatsapp_messages` (
  `id` int NOT NULL AUTO_INCREMENT,
  `tenantId` int NOT NULL,
  `walletId` int DEFAULT NULL,
  `messageSid` varchar(255) DEFAULT NULL,
  `direction` varchar(20) NOT NULL COMMENT 'outbound ou inbound',
  `fromNumber` varchar(20) NOT NULL,
  `toNumber` varchar(20) NOT NULL,
  `body` text,
  `status` varchar(50) NOT NULL DEFAULT 'queued',
  `errorCode` int DEFAULT NULL,
  `errorMessage` text,
  `messageType` varchar(20) DEFAULT NULL COMMENT 'template ou free',
  `cost` decimal(10,4) DEFAULT NULL,
  `sentAt` datetime DEFAULT NULL,
  `deliveredAt` datetime DEFAULT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `provider` varchar(255) NOT NULL DEFAULT 'meta' COMMENT 'Provedor utilizado: meta, twilio, etc',
  `metadata` json DEFAULT NULL COMMENT 'Dados extras: templates, mídia, localização, etc',
  `readAt` datetime DEFAULT NULL COMMENT 'Data/hora em que a mensagem foi lida',
  PRIMARY KEY (`id`),
  UNIQUE KEY `messageSid` (`messageSid`),
  KEY `walletId` (`walletId`),
  KEY `idx_whatsapp_messages_tenant` (`tenantId`),
  KEY `idx_whatsapp_messages_sid` (`messageSid`),
  KEY `idx_whatsapp_messages_status` (`status`),
  KEY `idx_whatsapp_messages_from` (`fromNumber`),
  KEY `idx_whatsapp_messages_to` (`toNumber`),
  KEY `idx_whatsapp_messages_created` (`createdAt`),
  KEY `idx_whatsapp_messages_provider` (`provider`),
  KEY `idx_whatsapp_messages_tenant_from` (`tenantId`,`fromNumber`),
  KEY `idx_whatsapp_messages_tenant_to` (`tenantId`,`toNumber`),
  KEY `idx_whatsapp_messages_tenant_created` (`tenantId`,`createdAt`) USING BTREE,
  KEY `idx_whatsapp_messages_tenant_type_created` (`tenantId`,`messageType`,`createdAt`) USING BTREE,
  CONSTRAINT `whatsapp_messages_ibfk_1` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `whatsapp_messages_ibfk_2` FOREIGN KEY (`walletId`) REFERENCES `whatsapp_credit_wallets` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping routines for database 'express'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-22 17:14:49
