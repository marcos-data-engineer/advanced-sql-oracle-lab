-- ============================================================================
-- PADRÃO 3: PL/SQL de Alta Performance para Processamento em Lote (Batch ETL)
-- RECURSOS: BULK COLLECT, FORALL, LIMIT, Tratamento de Exceções e Cursors Fortemente Tipados
-- OBJETIVO: Eliminar a sobrecarga de context-switch entre as engines SQL e PL/SQL
-- ============================================================================

CREATE OR REPLACE PACKAGE pkg_batch_budget_etl AS
    PROCEDURE process_quarterly_reconciliation(
        p_fiscal_year IN NUMBER,
        p_batch_size  IN NUMBER DEFAULT 1000
    );
END pkg_batch_budget_etl;
/

CREATE OR REPLACE PACKAGE BODY pkg_batch_budget_etl AS

    PROCEDURE process_quarterly_reconciliation(
        p_fiscal_year IN NUMBER,
        p_batch_size  IN NUMBER DEFAULT 1000
    ) IS
        -- Cursor de extração em lote
        CURSOR c_transactions IS
            SELECT transaction_id, allocated_amount, executed_amount
            FROM budget_transactions
            WHERE fiscal_year = p_fiscal_year;

        -- Tipagem para coleções PL/SQL indexadas em memória
        TYPE t_trans_rec IS RECORD (
            transaction_id   budget_transactions.transaction_id%TYPE,
            allocated_amount budget_transactions.allocated_amount%TYPE,
            executed_amount  budget_transactions.executed_amount%TYPE
        );
        TYPE t_trans_list IS TABLE OF t_trans_rec;
        
        l_trans_batch t_trans_list;
        l_total_processed NUMBER := 0;

    BEGIN
        OPEN c_transactions;
        LOOP
            -- Coleta em lote com limite de buffer (Bulk Collect com LIMIT para controle de PGA)
            FETCH c_transactions BULK COLLECT INTO l_trans_batch LIMIT p_batch_size;
            EXIT WHEN l_trans_batch.COUNT = 0;

            -- DML em lote usando FORALL com SAVE EXCEPTIONS (garante continuidade mesmo com erros pontuais)
            FORALL i IN 1..l_trans_batch.COUNT SAVE EXCEPTIONS
                UPDATE budget_transactions
                SET executed_amount = LEAST(l_trans_batch(i).executed_amount, l_trans_batch(i).allocated_amount),
                    transaction_date = SYSDATE
                WHERE transaction_id = l_trans_batch(i).transaction_id;

            l_total_processed := l_total_processed + l_trans_batch.COUNT;
            COMMIT; -- Commit por lote para evitar saturação de UNDO Tablespace
        END LOOP;
        CLOSE c_transactions;

        DBMS_OUTPUT.PUT_LINE('Reconciliação em lote finalizada. Registros processados: ' || l_total_processed);

    EXCEPTION
        WHEN OTHERS THEN
            IF c_transactions%ISOPEN THEN
                CLOSE c_transactions;
            END IF;
            -- Tratamento de erros em lote capturados pelo SAVE EXCEPTIONS
            IF SQLCODE = -24381 THEN
                FOR i IN 1..SQL%BULK_EXCEPTIONS.COUNT LOOP
                    DBMS_OUTPUT.PUT_LINE('Erro no registro índice ' || SQL%BULK_EXCEPTIONS(i).ERROR_INDEX ||
                                         ': ORA-' || SQL%BULK_EXCEPTIONS(i).ERROR_CODE);
                END LOOP;
            ELSE
                RAISE;
            END IF;
    END process_quarterly_reconciliation;

END pkg_batch_budget_etl;
/
