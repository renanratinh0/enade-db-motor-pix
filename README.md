#  Motor de Transações e Liquidação de Pix

Repositório acadêmico desenvolvido para a disciplina de Banco de Dados, aplicando engenharia reversa de questões do ENADE, programação procedural avançada, segurança (DCL) e otimização de performance física.

## 🚀 Tecnologias Utilizadas
- **SGBD:** MariaDB / MySQL (Ambiente XAMPP)
- **Ferramenta de Gestão:** JetBrains DataGrip
- **Conceitos Aplicados:** ACID, Stored Procedures, Triggers preventivas (BEFORE), Controle de Acesso Baseado em Papéis (Roles/DCL), Índices B-Tree e Planos de Execução (`EXPLAIN`).

## 📁 Estrutura do Projeto
- `database/setup_pix.sql`: Script consolidado contendo a criação do banco, tabelas, cargas, procedures, triggers, segurança e índices.
  
## ⚙️ Como Executar os Testes
1. Clone o repositório ou copie o conteúdo do script `setup_pix.sql`.
2. Abra o seu gerenciador de banco de dados (ex: DataGrip ou MySQL Workbench).
3. Execute o script como Administrador (`root`) para criar a infraestrutura.
4. Para testar o bloqueio de segurança (Camada de Dados vs. Aplicação), conecte-se com o usuário restrito `app_backend` (senha: `senha123`) e tente realizar um `UPDATE` direto na tabela de contas.
