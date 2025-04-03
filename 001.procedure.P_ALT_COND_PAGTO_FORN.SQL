
CREATE OR REPLACE PROCEDURE P_ALT_COND_PAGTO_FORN IS

		/*
		*	REGRA DE NEGÓCIO
		*	TODO MÊS QUE TIVER 31 DIAS DEVE INICIAR COM COND_PAGTO = 42
		*	E PRECISA TERMINAR COM COND_PAGTO = 41
		*
		*	* A MELHOR HIPÓTESE É CRIAR UMA ROTINA QUE ALTERA A COND_PAGTO:
		*	* Para mês com 31 dias:
		*	*  Dia 01 a meia noite -> update na tabela colocando cond_pagto = 42 
		*	*  Dia 02 a meia noite -> update na tabela colocando cond_pagto = 41
		*
		*   
		* */
	

	DIA NUMBER := TO_NUMBER(TO_CHAR(SYSDATE,'DD')); -- Pega o dia atual da execução
	ULT_DIA NUMBER := TO_NUMBER(TO_CHAR(LAST_DAY(SYSDATE),'DD')); -- Pega o último dia do mês da execução;

	DIA_1 CONSTANT NUMBER := 1; -- Dia 01 do mês
	DIA_2 CONSTANT NUMBER := 2; -- Dia 02 do mês
	DIA_31 CONSTANT NUMBER := 31; -- Dia 31 do mês

	PRAZO_PAGTO41 CONSTANT VARCHAR2(2) := '41'; -- Condição de pagamento 41
	PRAZO_PAGTO42 CONSTANT VARCHAR2(2) := '42'; -- Condição de pagamento 42
	ERRO VARCHAR2(4000);

BEGIN

	
	IF DIA = DIA_1 AND ULT_DIA = DIA_31
		THEN

			/*
			 * UPDATE PARA ALTERAR O VALOR ** COND_PAGTO = 42
			 * 
			 * */

			 INSERT INTO TLOG_COND_PAGTO
			 SELECT SEQ_TLOG_COND_PAGTO.NEXTVAL, 
					 SYSDATE, 
					 PRAZO_PAGTO41, 
					 PRAZO_PAGTO42, 
					 ID,
					 'Alteração de Cond_Pagto de 41 para 42'
			    FROM TVENC_FORN
			   WHERE PRAZO_PGTO = PRAZO_PAGTO41;

		   	 UPDATE TVENC_FORN
		  	    SET PRAZO_PGTO = PRAZO_PAGTO42
		   	 WHERE PRAZO_PGTO = PRAZO_PAGTO41;
		  
		  	 COMMIT;
	END IF;

	IF DIA = DIA_2 AND ULT_DIA = DIA_31
		THEN
		
			/*
			 * UPDATE PARA RETORNAR O VALOR PADRÃO ** COND_PAGTO = 41
			 * 
			 * */

			 INSERT INTO TLOG_COND_PAGTO
			 SELECT SEQ_TLOG_COND_PAGTO.NEXTVAL, 
					 SYSDATE, 
					 PRAZO_PAGTO42, 
					 PRAZO_PAGTO41, 
					 ID,
					 'Alteração de Cond_Pagto de 42 para 41'
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
				IF DIA = DIA_2 THEN 
					INSERT INTO TLOG_COND_PAGTO
					SELECT SEQ_TLOG_COND_PAGTO.NEXTVAL, 
							SYSDATE, 
							'Erro', 
							'Erro', 
							ID,
							ERRO
						FROM TVENC_FORN
					WHERE PRAZO_PGTO = PRAZO_PAGTO42;
				ELSE
					INSERT INTO TLOG_COND_PAGTO
					SELECT SEQ_TLOG_COND_PAGTO.NEXTVAL, 
							SYSDATE, 
							'Erro', 
							'Erro', 
							ID,
							ERRO
						FROM TVENC_FORN
					WHERE PRAZO_PGTO = PRAZO_PAGTO41;
				END IF;
			--DBMS_OUTPUT.PUT_LINE('Erro: ' || SQLERRM(SQLCODE));
			RAISE_APPLICATION_ERROR(-20001, 'Erro ao alterar condição de pagamento.');
END;
