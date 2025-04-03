```md
# Processo de Alteração de Condição de Pagamento para o FoccoERP

Este processo foi desenvolvido para o sistema FoccoERP com o objetivo de alterar automaticamente a condição de pagamento no cadastro dos fornecedores em meses com 31 dias. O processo é composto por uma tabela de log, uma sequência e uma procedure que realiza as alterações necessárias.

## Estrutura do Processo

### 1. Tabela de Log: `TLOG_COND_PAGTO`
A tabela `TLOG_COND_PAGTO` é utilizada para registrar todas as alterações realizadas na condição de pagamento, bem como eventuais erros ocorridos durante o processo.

**Estrutura da Tabela:**
```sql
CREATE TABLE TLOG_COND_PAGTO (
    ID NUMBER PRIMARY KEY,
    DATA_ALTERACAO DATE,
    COND_PAGTO_ANTIGO VARCHAR2(2),
    COND_PAGTO_NOVO VARCHAR2(2),
    ID_VENC_FORN NUMBER,
    LOG VARCHAR2(4000)
);
```

### 2. Sequência: `SEQ_TLOG_COND_PAGTO`
A sequência `SEQ_TLOG_COND_PAGTO` é utilizada para gerar os valores únicos para a coluna `ID` da tabela de log.

**Criação da Sequência:**
```sql
CREATE SEQUENCE SEQ_TLOG_COND_PAGTO
START WITH 1;
```

### 3. Procedure: `P_ALT_COND_PAGTO_FORN`
A procedure `P_ALT_COND_PAGTO_FORN` é responsável por realizar as alterações na condição de pagamento dos fornecedores. Ela segue as seguintes regras de negócio:

- **Dia 01 de meses com 31 dias:** Atualiza a condição de pagamento para `42`.
- **Dia 02 de meses com 31 dias:** Retorna a condição de pagamento para `41`.

Além disso, a procedure registra todas as alterações na tabela de log e trata possíveis erros.

**Fluxo da Procedure:**
1. Verifica o dia atual e o último dia do mês.
2. Se for dia 01 e o mês tiver 31 dias:
   - Insere um registro na tabela de log indicando a alteração de `41` para `42`.
   - Atualiza a condição de pagamento para `42` na tabela `TVENC_FORN`.
3. Se for dia 02 e o mês tiver 31 dias:
   - Insere um registro na tabela de log indicando a alteração de `42` para `41`.
   - Atualiza a condição de pagamento para `41` na tabela `TVENC_FORN`.
4. Em caso de erro:
   - Realiza rollback.
   - Insere um registro na tabela de log com a mensagem de erro.

**Código da Procedure:**
```sql
CREATE OR REPLACE PROCEDURE P_ALT_COND_PAGTO_FORN IS
    DIA NUMBER := TO_NUMBER(TO_CHAR(SYSDATE,'DD'));
    ULT_DIA NUMBER := TO_NUMBER(TO_CHAR(LAST_DAY(SYSDATE),'DD'));
    DIA_1 CONSTANT NUMBER := 1;
    DIA_2 CONSTANT NUMBER := 2;
    DIA_31 CONSTANT NUMBER := 31;
    PRAZO_PAGTO41 CONSTANT VARCHAR2(2) := '41';
    PRAZO_PAGTO42 CONSTANT VARCHAR2(2) := '42';
    ERRO VARCHAR2(4000);
BEGIN
    IF DIA = DIA_1 AND ULT_DIA = DIA_31 THEN
        INSERT INTO TLOG_COND_PAGTO
        SELECT SEQ_TLOG_COND_PAGTO.NEXTVAL, SYSDATE, PRAZO_PAGTO41, PRAZO_PAGTO42, ID, 'Alteração de Cond_Pagto de 41 para 42'
        FROM TVENC_FORN
        WHERE PRAZO_PGTO = PRAZO_PAGTO41;

        UPDATE TVENC_FORN
        SET PRAZO_PGTO = PRAZO_PAGTO42
        WHERE PRAZO_PGTO = PRAZO_PAGTO41;

        COMMIT;
    END IF;

    IF DIA = DIA_2 AND ULT_DIA = DIA_31 THEN
        INSERT INTO TLOG_COND_PAGTO
        SELECT SEQ_TLOG_COND_PAGTO.NEXTVAL, SYSDATE, PRAZO_PAGTO42, PRAZO_PAGTO41, ID, 'Alteração de Cond_Pagto de 42 para 41'
        FROM TVENC_FORN
        WHERE PRAZO_PGTO = PRAZO_PAGTO42;

        UPDATE TVENC_FORN
        SET PRAZO_PGTO = PRAZO_PAGTO41
        WHERE PRAZO_PGTO = PRAZO_PAGTO42;

        COMMIT;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        ERRO := SQLERRM;
        INSERT INTO TLOG_COND_PAGTO
        SELECT SEQ_TLOG_COND_PAGTO.NEXTVAL, SYSDATE, 'Erro', 'Erro', ID, ERRO
        FROM TVENC_FORN
        WHERE PRAZO_PGTO IN (PRAZO_PAGTO41, PRAZO_PAGTO42);
        RAISE_APPLICATION_ERROR(-20001, 'Erro ao alterar condição de pagamento.');
END;
```

## Como Utilizar

1. **Criação da Tabela e Sequência:**
   - Execute os scripts de criação da tabela `TLOG_COND_PAGTO` e da sequência `SEQ_TLOG_COND_PAGTO`.

2. **Criação da Procedure:**
   - Execute o script de criação da procedure `P_ALT_COND_PAGTO_FORN`.

3. **Execução da Procedure:**
   - Agende a execução da procedure `P_ALT_COND_PAGTO_FORN` para rodar diariamente no banco de dados.

4. **Monitoramento:**
   - Verifique a tabela `TLOG_COND_PAGTO` para acompanhar as alterações realizadas e possíveis erros.

## Observações

- Certifique-se de que a tabela `TVENC_FORN` existe e contém os dados necessários para a execução do processo.
- A procedure foi projetada para lidar com meses de 31 dias. Em outros meses, nenhuma alteração será realizada.
- Em caso de erros, a mensagem será registrada na tabela de log e o processo será interrompido.

Este processo foi desenvolvido para atender às necessidades específicas do FoccoERP e pode ser adaptado conforme necessário.
```