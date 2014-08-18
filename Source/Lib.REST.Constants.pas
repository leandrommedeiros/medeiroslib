{===============================================================================

                            REST - CONSTANTES

============================================| Leandro Medeiros (17/04/2014) |==}

unit Lib.REST.Constants;

interface

const

{*******************************************************************************

                                    LOGS

*******************************************************************************}

  WS_EXEC_LOG = 'Requisição ao Web Service' + #13+#10
              + 'Host: "%s".'   + #13+#10
              + 'Porta: "%s".'  + #13+#10
              + 'Classe: "%s".' + #13+#10
              + 'Método: "%s".' + #13+#10
              + 'Parâmetros (JSON): %s.'    + #13+#10
              + 'Retorno: %s.';

  LOG_GET_STUDY_LIST = 'Ocorreu um erro ao tentar listar os estudos para gera??o, com mensagem:' + #13 + #10;
  LOG_ONRAD_INSERT_FAIL = 'N?o foi poss?vel criar um registro para o estudo no ONRAD. Motivo desconhecido. STUDYUID: ';
  LOG_INVALID_PATH = 'Diret?rio das imagens inexistente ou inacess?vel: ';
  LOG_COMPRESS_FAIL = 'Ocorreu um erro ao compactar as imagens do estudo ';
  LOG_ONRAD_INSERT_WEB_FAIL = 'N?o foi poss?vel inserir estudo do(a) paciente "%s", '+#13+#10
                            + 'STUDYUID "%s" no ONRAD.'+#13+#10
                            + 'WebService retornou mensagem "%s".';
  LOG_ONRAD_INSERT_WEB_OK = 'Estudo do(a) paciente "%s",'+#13+#10
                          + 'STUDYUID "%s" foi gerado'+#13+#10
                          + 'com sucesso no ONRAD. Retornado ID "%d"';
  LOG_GET_LIST_COUNT = 'Pesquisa retornou %d registro(s). Iniciando exporta??o ao ONRAD e compacta??o das imagens.';
  LOG_UPD_DCM_STATUS_FAIL = 'N?o foi poss?vel alterar a situa??o das imagens via WebService';
  LOG_GET_IMAGES_PATH = 'N?o foi poss?vel buscar o diret?rio das imagens na tabela XLABDIR, mensagem do erro:' + #13 + #10;
  LOG_NO_DB_SET = 'N?o h? nenhum banco de dados configurado no arquivo INI.';
  LOG_FB_TIMEOUT = 'N?o foi poss?vel conectar-se ao banco de dados Firebird.';
  LOG_ONRAD_TIMEOUT = 'N?o foi poss?vel conectar-se ao ONRAD.';
  LOG_NO_TELERAD_PARAMS = 'N?o foi poss?vel ler as configura??es de XLABCONF_TELERADSEND' + #13 + #10
                        + 'ou a tabela est? vazia. Sistema finalizado';
  LOG_UPD_TELERADSEND = 'Imagens compactadas, por?m n?o foi poss?vel atualizar status' + #13 + #10
                      + '(XLABTELERADSEND.ISTELERADSEND) no banco de dados devido ao erro ' + #13 + #10;

{*******************************************************************************

                                  CLASSES

*******************************************************************************}

  REST_CLASS_DOCTOR   = 'TDoctor';
  REST_CLASS_MASK     = 'TMask';
  REST_CLASS_MODALITY = 'TModality';
  REST_CLASS_OPERATOR = 'TOperator';
  REST_CLASS_ORIGIN   = 'TOrigin';
  REST_CLASS_PATIENT  = 'TPatient';
  REST_CLASS_REPORT   = 'TReport';
  REST_CLASS_STUDY    = 'TStudy';
  REST_CLASS_SYSTEM   = 'TSystem';
  REST_CLASS_USER     = 'TUser';

{*******************************************************************************

                                  MÉTODOS

*******************************************************************************}

//--| Doutor |------------------------------------------------------------------

//--| Máscara |-----------------------------------------------------------------

//--| Modalidade |--------------------------------------------------------------

//--| Operador |----------------------------------------------------------------

//--| Origem |------------------------------------------------------------------

//--| Paciente |----------------------------------------------------------------

//--| Relatório |---------------------------------------------------------------

//--| Estudo |------------------------------------------------------------------

//--| Sistema |-----------------------------------------------------------------
  REST_METHOD_SYSTEM_CONN_TEST = 'ConnectionTest';

//--| Usuário |-----------------------------------------------------------------
  REST_METHOD_USER_LOGIN = 'Login';

{*******************************************************************************

                                CÓDIGOS DE ERROS

*******************************************************************************}

// Classe - Método - Erro

  //Study (8) - Insert (4)
  ERROR_COD_INVALID_ORIGIN   = '841';
  ERROR_TXT_INVALID_ORIGIN   = 'id Origem inválido/não informado.';

  ERROR_COD_INVALID_MODALITY = '842';
  ERROR_TXT_INVALID_MODALITY = 'código/id modalidade não defindo.';

  ERROR_COD_INVALID_PATIENT  = '843';
  ERROR_TXT_INVALID_PATIENT  = 'Dados do paciente não informado(s)/inválido(s).';

  ERROR_COD_INVALID_STUDYUID = '844';
  ERROR_TXT_INVALID_STUDYUID = 'StudyUID ''%s'' fornecido já está associado à outro estudo.';

  ERROR_COD_INVALID_ACCESSION_NUMBER = '845';
  ERROR_TXT_INVALID_ACCESSION_NUMBER = 'Accession Number ''%s'' fornecido já está associado à outro estudo.';

  //User (10) - IsValidUser (2)
  ERROR_COD_INVALID_SESSION = '1021';
  ERROR_TXT_INVALID_SESSION = 'Sessão inválida/expirada.';
//==============================================================================

implementation
end.
