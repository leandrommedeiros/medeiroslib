![MedeirosLib2.png](https://bitbucket.org/repo/ogjnoL/images/1832895415-MedeirosLib2.png)

# Sobre #
***MedeirosLib*** é uma package para Delphi que vem sendo desenvolvida por [Leandro Medeiros](br.linkedin.com/in/medeirosleandro) desde  2010.

Todas as units são compiláveis no Embarcadero Delphi XE6 ou superior, porém também é possível aproveitar boa parte de suas bibliotecas no Borland Delphi 7.

Muitas das classes usadas no projeto são baseadas em classes nativas do Delphi, como é o caso da TSQLConnectionM (DBExpress)  e TFTPConnection (TIdFTP), portanto podem apresentar diferentes comportamentos de acordo com a versão Delphi em que estiverem rodando.

Obs.: Alguns dos códigos aqui disponíveis são otimizações e/ou adaptações de códigos encontrados em fóruns e afins.

# Como Instalar #

## Passos ##
1. Clonar Repositório
2. Adicionar referência ao código-fonte na biblioteca da IDE
3. Compilar o Pacote
4. Instalar o BPL

### Clonar Repositório ###
O projeto está parametrizado para compilar todas as units diretamente nas pastas do Delphi, portanto a clonagem do repositório pode ser feita em qualquer pasta local, porém caso não se tenha intenção de alterar os fontes do projeto recomenda-se clonar em uma subpasta no diretório de instalação do Delphi.

### Referência ao Código-fonte ###
Para que todos os fontes estejam disponíveis em quaisquer projetos que se venha à trabalhar (cláusula USES) é desejável adicioná-los diretamente ao Path do Delphi. Há um caminho diferente para cada versão do Delphi:
* **Borland Delphi 7 ****: Menu "Tools" > "Environment Options" > "Library" > "Library Path" > "..."
* ***Embarcadero Delphi XE6***: Menu "Tools" > "Options" > "Environment Options" > "Delphi Options" > "Library" > "Library Path" > "..."