-- ============================================================================
-- PROJETO: Laboratório Avançado de SQL & PL/SQL Corporativo (Oracle / PostgreSQL)
-- SCHEMA DDL: Modelagem Estrutural Corporativa Sanitizada (Zero Dados Pessoais)
-- COMPATIBILIDADE: Oracle Database 12c/19c/21c & PostgreSQL 14+
-- AUTOR: Marcos Vasconcellos de Andrade
-- ============================================================================

-- 1. Tabela de Estrutura Organizacional Hierárquica (Departamentos / Filiais)
CREATE TABLE enterprise_org_units (
    unit_id            NUMBER(10) PRIMARY KEY,
    unit_code          VARCHAR2(20) NOT NULL UNIQUE,
    unit_name          VARCHAR2(100) NOT NULL,
    parent_unit_id     NUMBER(10),
    cost_center        VARCHAR2(30),
    active_flag        CHAR(1) DEFAULT 'Y' CHECK (active_flag IN ('Y', 'N')),
    created_at         TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT fk_org_parent FOREIGN KEY (parent_unit_id) REFERENCES enterprise_org_units(unit_id)
);

-- 2. Tabela de Pessoal Corporativo (Sanitizado)
CREATE TABLE enterprise_employees (
    employee_id        NUMBER(10) PRIMARY KEY,
    registration_code  VARCHAR2(20) NOT NULL UNIQUE,
    full_name_masked   VARCHAR2(100) NOT NULL,
    unit_id            NUMBER(10) NOT NULL,
    job_role           VARCHAR2(50) NOT NULL,
    salary_amount      NUMBER(12, 2) NOT NULL,
    hire_date          DATE NOT NULL,
    termination_date   DATE,
    CONSTRAINT fk_emp_unit FOREIGN KEY (unit_id) REFERENCES enterprise_org_units(unit_id)
);

-- 3. Tabela de Transações Financeiras / Alocação Orçamentária
CREATE TABLE budget_transactions (
    transaction_id     NUMBER(12) PRIMARY KEY,
    unit_id            NUMBER(10) NOT NULL,
    fiscal_year        NUMBER(4) NOT NULL,
    fiscal_quarter     NUMBER(1) CHECK (fiscal_quarter BETWEEN 1 AND 4),
    category_name      VARCHAR2(50) NOT NULL,
    allocated_amount   NUMBER(14, 2) NOT NULL,
    executed_amount    NUMBER(14, 2) NOT NULL,
    transaction_date   DATE DEFAULT SYSDATE,
    CONSTRAINT fk_trans_unit FOREIGN KEY (unit_id) REFERENCES enterprise_org_units(unit_id)
);

-- Índices B-Tree para otimização de joins analíticos
CREATE INDEX idx_emp_unit_id ON enterprise_employees(unit_id);
CREATE INDEX idx_org_parent_id ON enterprise_org_units(parent_unit_id);
CREATE INDEX idx_trans_unit_year ON budget_transactions(unit_id, fiscal_year);
