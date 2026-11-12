-- ============================================================================
-- PADRÃO 4: Técnicas de Sanitização e Mascaramento de Dados (LGPD/GDPR Compliance)
-- CONTEXTO: Mascaramento dinâmico em camada de visualização (Data Masking Views)
-- ============================================================================

-- Função utilitária de hash determinístico para anonimização de identificadores
CREATE OR REPLACE FUNCTION fn_mask_identifier(p_raw_id IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC IS
BEGIN
    IF p_raw_id IS NULL THEN
        RETURN NULL;
    END IF;
    -- Anonimização via SHA-256 truncado para exibição segura em ambientes não-produtivos
    RETURN 'ANON-' || SUBSTR(STANDARD_HASH(p_raw_id, 'SHA256'), 1, 12);
END;
/

-- View com mascaramento de dados (Dynamic Data Masking Pattern)
CREATE OR REPLACE VIEW vw_sanitized_employee_directory AS
SELECT 
    employee_id,
    fn_mask_identifier(registration_code) AS masked_registration,
    -- Mascaramento parcial de nomes: exibe primeira letra e mascara o restante
    SUBSTR(full_name_masked, 1, 1) || '*** ' || 
    SUBSTR(full_name_masked, INSTR(full_name_masked, ' ', -1) + 1, 1) || '***' AS masked_name,
    job_role,
    -- Ocultação de faixa salarial exata por banda/categoria
    CASE 
        WHEN salary_amount < 5000 THEN 'Faixa A (Até 5k)'
        WHEN salary_amount BETWEEN 5000 AND 10000 THEN 'Faixa B (5k-10k)'
        ELSE 'Faixa C (Acima de 10k)'
    END AS compensation_tier,
    EXTRACT(YEAR FROM hire_date) AS hire_year
FROM 
    enterprise_employees;
