-- ============================================================================
-- PADRÃO 2: Funções Analíticas de Janela (Window Functions) & Pivot Dimensional
-- CONTEXTO: Ranking salarial por departamento, médias móveis orçamentárias e transposição
-- ============================================================================

-- 1. Ranking Analítico e Particionamento Salarial
SELECT 
    e.employee_id,
    e.full_name_masked,
    u.unit_code,
    e.job_role,
    e.salary_amount,
    -- Ranking sem lacunas
    DENSE_RANK() OVER (PARTITION BY e.unit_id ORDER BY e.salary_amount DESC) AS salary_dense_rank,
    -- Salário médio da respectiva unidade de negócio
    ROUND(AVG(e.salary_amount) OVER (PARTITION BY e.unit_id), 2) AS dept_avg_salary,
    -- Desvio em relação à média do departamento
    ROUND(e.salary_amount - AVG(e.salary_amount) OVER (PARTITION BY e.unit_id), 2) AS diff_from_dept_avg,
    -- Percentil da remuneração dentro do setor
    PERCENT_RANK() OVER (PARTITION BY e.unit_id ORDER BY e.salary_amount ASC) AS dept_salary_percentile
FROM 
    enterprise_employees e
INNER JOIN 
    enterprise_org_units u ON e.unit_id = u.unit_id;

-- 2. Janela Móvel com Acumulado e Médias Rolantes (Budget Analytics)
SELECT 
    transaction_id,
    unit_id,
    fiscal_year,
    fiscal_quarter,
    category_name,
    executed_amount,
    -- Acumulado no ano fiscal (YTD - Year-To-Date)
    SUM(executed_amount) OVER (
        PARTITION BY unit_id, fiscal_year, category_name 
        ORDER BY fiscal_quarter 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS budget_ytd_accumulated,
    -- Comparativo direto com o trimestre anterior (LAG)
    LAG(executed_amount, 1, 0) OVER (
        PARTITION BY unit_id, fiscal_year, category_name 
        ORDER BY fiscal_quarter
    ) AS previous_quarter_amount
FROM 
    budget_transactions;

-- 3. Pivot Analítico Dimensional (Transposição Linha -> Coluna nativa no Oracle)
SELECT * FROM (
    SELECT 
        unit_id,
        fiscal_year,
        fiscal_quarter,
        executed_amount
    FROM 
        budget_transactions
)
PIVOT (
    SUM(executed_amount)
    FOR fiscal_quarter IN (1 AS Q1_EXEC, 2 AS Q2_EXEC, 3 AS Q3_EXEC, 4 AS Q4_EXEC)
)
ORDER BY 
    unit_id, fiscal_year;
