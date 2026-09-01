CREATE DATABASE IF NOT EXISTS projeto_pix;
USE projeto_pix;

CREATE TABLE contas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome_titular VARCHAR(100) NOT NULL,
    saldo DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status_conta VARCHAR(20) NOT NULL DEFAULT 'ATIVA'
);

CREATE TABLE logs_transferencias_pix (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    conta_origem INT NOT NULL,
    conta_destino INT NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    data_hora DATETIME NOT NULL,
    status_operacao VARCHAR(50) NOT NULL,
    FOREIGN KEY (conta_origem) REFERENCES contas(id),
    FOREIGN KEY (conta_destino) REFERENCES contas(id)
);

INSERT INTO contas (nome_titular, saldo, status_conta) VALUES ('João (Conta 1)', 500.00, 'ATIVA');
INSERT INTO contas (nome_titular, saldo, status_conta) VALUES ('Maria (Conta 2)', 100.00, 'ATIVA');

DELIMITER //
CREATE PROCEDURE sp_realizar_transferencia_pix(
    IN p_id_conta_origem INT,
    IN p_id_conta_destino INT,
    IN p_valor_pix DECIMAL(10,2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Erro critico na transacao Pix: Operacao cancelada (Rollback efetuado).';
    END;

    START TRANSACTION;
    UPDATE contas SET saldo = saldo - p_valor_pix WHERE id = p_id_conta_origem;
    UPDATE contas SET saldo = saldo + p_valor_pix WHERE id = p_id_conta_destino;

    INSERT INTO logs_transferencias_pix (conta_origem, conta_destino, valor, data_hora, status_operacao)
    VALUES (p_id_conta_origem, p_id_conta_destino, p_valor_pix, NOW(), 'CONCLUIDO');
    COMMIT;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_previne_saldo_negativo_pix
BEFORE UPDATE ON contas
FOR EACH ROW
BEGIN
    IF NEW.saldo < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Operacao Negada: Saldo insuficiente para realizar a transferencia Pix.';
    END IF;

    IF OLD.status_conta = 'INATIVA' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Operacao Negada: Conta origem encontra-se inativa ou bloqueada.';
    END IF;
END //
DELIMITER ;

CALL sp_realizar_transferencia_pix(1, 2, 50.00);

CREATE ROLE role_app_pix;
CREATE ROLE role_auditor_pix;

GRANT SELECT ON projeto_pix.contas TO role_app_pix;
GRANT SELECT ON projeto_pix.logs_transferencias_pix TO role_app_pix;
GRANT EXECUTE ON PROCEDURE projeto_pix.sp_realizar_transferencia_pix TO role_app_pix;

REVOKE INSERT, UPDATE, DELETE ON projeto_pix.contas FROM role_app_pix;
REVOKE INSERT, UPDATE, DELETE ON projeto_pix.logs_transferencias_pix FROM role_app_pix;

GRANT SELECT ON projeto_pix.* TO role_auditor_pix;
REVOKE INSERT, UPDATE, DELETE, EXECUTE ON projeto_pix.* FROM role_auditor_pix;

CREATE USER 'app_backend'@'localhost' IDENTIFIED BY 'senha123';
GRANT role_app_pix TO 'app_backend'@'localhost';
SET DEFAULT ROLE role_app_pix FOR 'app_backend'@'localhost';

EXPLAIN
SELECT c.nome_titular, l.valor, l.data_hora
FROM contas c
INNER JOIN logs_transferencias_pix l ON c.id = l.conta_origem
WHERE l.data_hora >= '2026-08-01 00:00:00'
  AND l.status_operacao = 'CONCLUIDO';

CREATE INDEX idx_logs_data_status
ON logs_transferencias_pix (data_hora, status_operacao);

EXPLAIN
SELECT c.nome_titular, l.valor, l.data_hora
FROM contas c
INNER JOIN logs_transferencias_pix l ON c.id = l.conta_origem
WHERE l.data_hora >= '2026-08-01 00:00:00'
  AND l.status_operacao = 'CONCLUIDO';

-- AVISO IMPORTANTE DE TESTE DE SEGURANÇA:
-- Para testar o bloqueio abaixo, você DEVE SAIR do usuário Administrador (root).
-- Conecte-se no banco usando o usuário 'app_backend' (senha: senha123), descomente a linha abaixo e execute.
-- UPDATE contas SET saldo = 1000000.00 WHERE id = 1;