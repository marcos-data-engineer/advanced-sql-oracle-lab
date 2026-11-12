-- ============================================================================
-- PADRÃO 1: Consultas Hierárquicas Recursivas (START WITH ... CONNECT BY PRIOR)
-- CONTEXTO: Resolução de árvores organizacionais, subordinação e recursão em DAGs
-- DIALETO: Oracle SQL Nativo (com alternativa ANSI SQL Common Table Expression - CTE)
-- ============================================================================

-- Abordagem 1: Cláusula Nativa Oracle (CONNECT BY PRIOR com SYS_CONNECT_BY_PATH e LEVEL)
SELECT 
    LEVEL AS hierarchy_depth,
    LPAD(' ', 2 * (LEVEL - 1)) || unit_name AS indented_org_hierarchy,
    unit_id,
    unit_code,
    cost_center,
    SYS_CONNECT_BY_PATH(unit_code, ' -> ') AS full_organizational_path,
    CONNECT_BY_ISLEAF AS is_terminal_node
FROM 
    enterprise_org_units
WHERE 
    active_flag = 'Y'
START WITH 
    parent_unit_id IS NULL  -- Inicia a partir das unidades matrizes / topo da organização
CONNECT BY PRIOR 
    unit_id = parent_unit_id
ORDER SIBLINGS BY 
    unit_name ASC;

-- Abordagem 2: Padrão Moderno ANSI-SQL Recursivo (Compatível com PostgreSQL, Oracle 12c+ e BigQuery)
WITH RECURSIVE org_hierarchy_cte AS (
    -- Âncora inicial (Nível 1 - Topo da corporação)
    SELECT 
        unit_id,
        unit_code,
        unit_name,
        parent_unit_id,
        1 AS hierarchy_level,
        CAST(unit_code AS VARCHAR2(500)) AS tree_path
    FROM 
        enterprise_org_units
    WHERE 
        parent_unit_id IS NULL

    UNION ALL

    -- Passo Recursivo (Filhos e subordinados)
    SELECT 
        child.unit_id,
        child.unit_code,
        child.unit_name,
        child.parent_unit_id,
        parent.hierarchy_level + 1,
        CAST(parent.tree_path || ' -> ' || child.unit_code AS VARCHAR2(500))
    FROM 
        enterprise_org_units child
    INNER JOIN 
        org_hierarchy_cte parent ON child.parent_unit_id = parent.unit_id
)
SELECT 
    hierarchy_level,
    unit_code,
    unit_name,
    tree_path
FROM 
    org_hierarchy_cte
ORDER BY 
    hierarchy_level, unit_name;
