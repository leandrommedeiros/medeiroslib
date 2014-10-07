![MedeirosLibSmall.png](https://bitbucket.org/repo/ogjnoL/images/2862473348-MedeirosLibSmall.png)
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

* ***Borland Delphi 7***: Menu "Tools" > "Environment Options" > "Library" > "Library Path" > "..."
* ***Embarcadero Delphi XE6***: Menu "Tools" > "Options" > "Environment Options" > "Delphi Options" > "Library" > "Library Path" > "..."

Agora basta adicionar na caixa de diálogo "Directories" o caminho para a pasta "..\MedeirosLib\Source".
Para aqueles que no passo anterior escolheram clonar o diretório dentro da pasta de instalação do Delphi é possível utilizar variáveis de ambiente para encurtar o caminho, sendo a variável "($DELPHI)" usada no Delphi 7 e "($BDS)" a variável do Delphi XE6.

***Ex.:*** "($DELPHI)\Components\MedeirosLib\Source"; "($BDS)\Components\MedeirosLib\Source".

**IMPORTANTE**: Quando na versão XE6, a MedeirosLib é compatível com a arquitetura x64, porém para utilizá-la deve-se referenciar a pasta source também na LibraryPath 64 bit. Para isso basta selecionar a plataforma "64-bit Windows", clicar novamente no botão "..." e repetir o processo de adicionar o caminho.

### Compilar o Pacote ###
Ao abrir o arquivo "..\MedeirosLib\Package\MedeirosLib.dpk" o projeto deverá compilar normalmente.

Em versões de Windows superiores ao Vista se o Delphi for instalado dentro das pastas de sistema, "Arquivos de Programas" por exemplo, é possível que as subpastas do Delphi herdem suas permissões.
Como dito anteriormente, o projeto está configurado para gerar arquivos *.dcu, *.dcp e *.bpl diretamente nas pastas do Delphi, e isso pode gerar erros.

Há duas maneiras de contornar a situação:
1. Altere as configurações de segurança da pasta de instalação do Delphi dando a permissão de "Controle Total" ao seu usuário e ao usuário Sistema (caso seu computador não esteja em um domínio é mais fácil dar permissões ao grupo "Todos").
2. Altere a pasta de saída do pacote.
No Delphi 7 basta abrir o menu "Project" > "Options" > "Directories/Conditionals" e alterar os diretórios "Output", "Unit Output" e "DCP Output".
No Delphi XE6 abra o menu "Project" > "Options" > "Delphi Compiler" e altere os diretórios "DCP Output", "Package Output" e "Unit Output".

## Instalar o BPL ##
Após compilar o pacote com sucesso há duas maneiras de instalá-lo:
1. Ainda com o projeto, aberto clique com o botão direito sobre "MedeirosLib.bpl" (Project Manager) e selecione "Install".
2. Abra o menu "Component" > "Install Package" > "Add" e navegue até o arquivo MedeirosLib.bpl que foi criado no diretório de saída escolhido.

Pronto! Agora a paleta "MedeirosLib" estará disponível na IDE e quaisquer units poderão ser referênciadas na cláusula "uses" de seus projetos, aproveite!

# Contato #
***Leandro Medeiros***

* [LinkedIn](br.linkedin.com/in/medeirosleandro)

* [BitBucket](https://bitbucket.org/leandro_medeiros)

* [GitHub](https://github.com/leandrommedeiros)

* [Facebook](https://www.facebook.com/leandro.m.medeiros)

* [Twitter](https://twitter.com/LeMedeiros10)