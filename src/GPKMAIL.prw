#Include 'totvs.ch'
#INCLUDE "AP5MAIL.CH"

/*/
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������Ŀ��
���Fun��o    �SendMail  � Autor � TI1369-ALEX FONSECA   � Data �14.11.2001 ���
��������������������������������������������������������������������������Ĵ��
���          �Envio de E-mail                                              ���
��������������������������������������������������������������������������Ĵ��
���Parametros�ExpC1: Servido de E-mail                                     ���
���          �ExpC2: Conta de E-mail                                       ���
���          �ExpC3: Senha Conta E-mail                                    ���
���          �ExpC4: String Contas E-mail destino                          ���
���          �ExpC5: Assunto                                               ���
���          �ExpC6: Corpo de Texto                                        ���
���          �ExpC7: Arquivos Anexos                                       ���
��������������������������������������������������������������������������Ĵ��
���Retorno   �Logico - .T. - Operacao realizada                            ���
���          �       - .F. - Operacao NAO realizada                        ���
��������������������������������������������������������������������������Ĵ��
���Uso       � AVIS                                                        ���
���������������������������������������������������������������������������ٱ�
������������������������������������������������������������������������������
������������������������������������������������������������������������������
/*/

User Function GPKMAIL(cTo,cCC,cSubject,cBody,aFile,lMsg,lDebug)
Local cAnexos := ""
Local nAnexos := 1

	For nAnexos := 1 To Len(aFile)
		If ! Empty(cAnexos)
			cAnexos += ","
		EndIF
		cAnexos += aFile[nAnexos]
	Next

	xSendMail(cTo,cSubject,cBody,cAnexos,IsBlind(),cCC,,.T.,.F., ""  )
	
Return

Static Function xSendMail(cMailDestino,cAssunto,cTexto,cAnexos,lJob,cCopia,cEmailDe,lAutentica,lFormatoTexto, cCopOcult  )

	Local lEnvio 	:= .F.
	Local cEmailTst	:= GetSrvProfString( "MailTestList", "" )
	Local lNovoMtd  := GETMV("TI_NVMTDMA",,.T.)  
	/*
	����������������������Ŀ
	�DEFINE valores padroes�
	������������������������*/
	Default	cMailDestino:= ""
	Default cAssunto	:= ""
	Default cTexto		:= ""
	Default lJob		:= .F.
	Default	cCopia		:= ""
	Default	cCopOcult	:= ""
	Default lAutentica	:= .F.

	/*
	���������������Ŀ
	�Avalia conteudo�
	�����������������*/

	lAutentica := GetMv( 'MV_RELAUTH',,.F. )    //-- For�a autentica��o pois o parametro MV_RELAUTH do padr�o precisa estar como .F.

	If 	Empty( cMailDestino )
		cMensagem := "Conta(s) de Email Destino - NAO INFORMADA."
		If ! lJob 
			MsgStop( cMensagem ) 
		EndIf
		Return(.F.)
	EndIf
	If 	Empty( cAssunto )
		cMensagem := "Assunto do E-mail - NAO INFORMADO"
		If ! lJob 
			MsgStop( cMensagem ) 
		EndIf
		Return(.F.)
	EndIf
	If 	Empty( cTexto )
		cMensagem := "Texto do E-mail - NAO INFORMADO"
		If ! lJob 
			MsgStop( cMensagem ) 
		EndIf
		Return(.F.)
	EndIf

	//Funcao Responsavel por Alterar as Variaveis de Envio de Email no Ambiente Teste
	If !( Empty( cEmailTst ) )
		TGetEmlTst( cEmailTst, @cMailDestino, @cCopia, @cTexto )
	EndIf

	If lNovoMtd
		If  lJob
			lEnvio := SendNvMtd( cMailDestino,cAssunto,cTexto,cAnexos,lJob,cCopia,cEmailDe,lAutentica,lFormatoTexto, cCopOcult  )
		Else
			Processa( { || lEnvio := SendNvMtd( cMailDestino, cAssunto, cTexto, cAnexos, lJob, cCopia, cEmailDe, lAutentica, lFormatoTexto, cCopOcult  ) } )
		EndIf
	Else
		If  lJob
			lEnvio := SendMail2( cMailDestino,cAssunto,cTexto,cAnexos,lJob,cCopia,cEmailDe,lAutentica,lFormatoTexto, cCopOcult  )
		Else
			Processa( { || lEnvio := SendMail2( cMailDestino, cAssunto, cTexto, cAnexos, lJob, cCopia, cEmailDe, lAutentica, lFormatoTexto, cCopOcult  ) } )
		EndIf
	EndIf
Return(lEnvio)


/*/
������������������������������������������������������������������������������
������������������������������������������������������������������������������
��������������������������������������������������������������������������Ŀ��
���Fun��o    �SendMail2 � Autor � TI1369-ALEX FONSECA   � Data �14.11.2001 ���
��������������������������������������������������������������������������Ĵ��
���          �Envio de E-mail                                              ���
��������������������������������������������������������������������������Ĵ��
���Uso       � Especifico Avis                                             ���
���������������������������������������������������������������������������ٱ�
������������������������������������������������������������������������������
������������������������������������������������������������������������������
/*/
Static Function SendMail2( cMailDestino,cAssunto,cTexto,cAnexos,lJob,cCopia,cEmailDe, lAutentica, lFormatoTexto, cCopOcult  )

	Local cMailServer 	:= GETMV("MV_RELSERV")

	Local cAutMailServer:= GETMV("MV_AUTRELS",,'smtp.totvs.com.br')

	//PARA CONECTAR E ENVIAR E_MAILS
	Local cMailConta  	:= GETMV("MV_RELACNT",,'erpcorporativo@totvs.com.br')
	Local cMailSenha  	:= GETMV("MV_RELPSW")

	//PARA ATENTICAR NO SERVIDOR DE EMAIL
	Local cUsrAutent  	:= GETMV("MV_RELAUSR",,"wf")
	Local cPswAutent  	:= GETMV("MV_RELAPSW")

	DEFAULT cEmailDe 	:= GETMV("MV_RELFROM",,'erpcorporativo@totvs.com.br')

	//-- DEVE ser informado .T. sempre que o destinatario for != @microsiga.com.br
	DEFAULT lAutentica 	:= .F.
	DEFAULT	cCopia		:= ""
	DEFAULT	cCopOcult	:= ""
	DEFAULT lFormatoTexto := .F.


	lConexao			:= .F.
	lEnvio   			:= .F.
	lDesconexao			:= .F.
	lRetAutenticacao	:= .T.
	cErro_Conexao 		:= ""
	cErro_Envio			:= ""
	cErro_Desconexao	:= ""

	If 	!( lJob )
		/// Inicializa regua processamento
		ProcRegua(3)

		IncProc("Conectando ao servidor de Email !!!")
	End
	/*
	���������������������������������������������������Ŀ
	�EXECUTA conex�o ao servidor mencionado no parametro�
	�����������������������������������������������������
	*/
	If 	!(lAutentica)
		Connect Smtp Server cMailServer ACCOUNT cMailConta PASSWORD cMailSenha RESULT lConexao
	Else
		Connect Smtp Server cAutMailServer ACCOUNT cMailConta PASSWORD cMailSenha RESULT lConexao
		lRetAutenticacao := MailAuth(cUsrAutent,cPswAutent)
	Endif

	IF !lConexao
		GET MAIL ERROR cErro_Conexao
		cMensagem := "Nao foi possivel estabelecer a CONEXAO com o servidor - " + cErro_Conexao
		If ! lJob 
			MsgStop( cMensagem ) 
		EndIf
		Return( .F. )
	ENdIf

	IF !lRetAutenticacao
		cMensagem := "AUTENTICACAO falhou no servidor SMTP.TOTVS.COM.BR"
		If ! lJob 
			MsgStop( cMensagem ) 
		EndIf
		Return( .F. )
	ENdIf

	If  !( lJob )
		IncProc("Enviando Email")
	EndIf
	/*
	�������������������������Ŀ
	�EXECUTA envio da mensagem�
	���������������������������*/
	If  !( Empty( cAnexos ) )
		If  lFormatoTexto
			Send Mail From cEmailDe To cMAILDESTINO CC cCOPIA BCC cCopOcult SubJect cASSUNTO BODY cTEXTO FORMAT TEXT ATTACHMENT cANEXOS RESULT lENVIO
		Else
			Send Mail From cEmailDe To cMAILDESTINO CC cCOPIA BCC cCopOcult SubJect cASSUNTO BODY cTEXTO ATTACHMENT cANEXOS RESULT lENVIO
		EndIf
	Else
		If  lFormatoTexto
			Send Mail From cEmailDe To cMAILDESTINO CC cCOPIA BCC cCopOcult SubJect cASSUNTO BODY cTEXTO FORMAT TEXT RESULT lENVIO
		Else
			Send Mail From cEmailDe To cMAILDESTINO CC cCOPIA BCC cCopOcult SubJect cASSUNTO BODY cTEXTO RESULT lENVIO
		EndIf
	EndIf

	If !lEnvio
		Get Mail Error cErro_Envio
		cMensagem := "Nao foi possivel ENVIAR a mensagem - " + cErro_Envio
		If ! lJob 
			MsgStop( cMensagem ) 
		EndIf
		Return( .F. )
	EndIf

	If 	!( lJob )
		IncProc("Desconectando do servidor de Email !!!")
	EndIf
	/*
	�����������������������������������Ŀ
	�EXECUTA disconexao ao servidor SMTP�
	�������������������������������������*/
	DisConnect Smtp Server Result lDesconexao
	IF !lDesconexao
		Get Mail Error cErro_Desconexao
		cMensagem := "Nao foi possivel DESCONECTAR do servidor - " + cErro_Desconexao
		If ! lJob 
			MsgStop( cMensagem ) 
		EndIf
		Return( .F. )
	EndIf

Return(lEnvio)

/*
SendNvMtd
Fun��o de email para adequar a comunica��o com o smtp-pulse.com:587

@author Oswaldo Leite
@since 25/09/2022
@version 1.0
*/
Static function SendNvMtd(cMailDestino,cAssunto,cTexto,cAnexos,lJob,cCopia,cEmailDe,lAutentica,lFormatoTexto, cCopOcult)
Local cMailServer 	:= GETMV("MV_RELSERV")
Local nPort         := GETMV("TI_PORSMTP",,587)
Local cStrPort      := ":" + Alltrim( STR(nPort) )
Local lContinua     := .T.
Local cMailCtaAut  	:= GETMV("MV_RELACNT",,'erpcorporativo@totvs.com.br')
Local cMailSenha  	:= GETMV("MV_RELPSW")
Local oServer       := Nil 
Local oMessage      := Nil 
Local nArr          := 0 
Local cMAilError    := ""
Local nErro         := 0
Local cMensagem     := ""  
Local lEnvio        := .T. 
Local n1            := 0 
Local aFiles        := {}
Local cTstAnexos    := ''
DEFAULT cEmailDe 	:= GETMV("MV_RELFROM",,'erpcorporativo@totvs.com.br')
DEFAULT	cCopia		:= ""
DEFAULT	cCopOcult	:= ""
DEFAULT lAutentica 	:= .F.//sem uso
DEFAULT lFormatoTexto := .F.//sem uso

If cAnexos <> Nil 
	cTstAnexos := strtran(cAnexos, ",", "SEPARADOR" )
	If cTstAnexos != cAnexos
		aFiles        := StrTokArr2( cAnexos, "," )
	Else
		aFiles        := StrTokArr2( cAnexos, ";" )
	EndIf
EndIf

cMailServer := STRTRAN( cMailServer, cStrPort, "")

If 	!( lJob )
	ProcRegua(3)
	IncProc("Conectando ao servidor de Email !!!")
End
	
oServer := TMailManager():New()      
oServer:SetUseTLS(.T.)  
oServer:Init('', cMailServer, cMailCtaAut, cMailSenha, 0, nPort )

nArr       := oServer:SetSMTPTimeOut( 120 )       
cMAilError := oServer:GetErrorString(nArr)

If  oServer:SMTPConnect() <> 0      
	cMensagem := "Ocorreu um problema ao determinar o Time-Out do servidor SMTP ou nao foi poss�vel estabelecer a conexao com o mesmo." 
	Iif( lJob , ConOut( cMensagem ) , MsgStop( cMensagem ) ) 
	lEnvio := .F.
Else
	nErro := oServer:SmtpAuth(cMailCtaAut, cMailSenha)

	If nErro <> 0
        cMAilError := oServer:GetErrorString(nErro)
        DEFAULT cMailError := '***UNKNOW***'
        cMensagem := "Erro de Autenticacao " + Str(nErro,4) + '(' + cMAilError + ')'
		Iif( lJob , ConOut( cMensagem ) , MsgStop( cMensagem ) ) 
        oServer := Nil
    	lEnvio := .F.
    EndIf	
EndIf

If lEnvio 
   	oMessage := TMailMessage():New()         
	oMessage:Clear()                            
	
	//--Popula com os dados de envio
	oMessage:cFrom 	  := cEmailDe 
	oMessage:cTo 	  := cMailDestino 
	oMessage:cCc	  := cCopia 
	oMessage:cBcc	  := cCopOcult
	oMessage:cSubject := cAssunto
	oMessage:cBody    := cTexto  
	For n1 := 1 to Len(aFiles)
		oMessage:AttachFile( aFiles[n1] )
	Next 
		
	If oMessage:Send(oServer) != 0
		cMensagem :=  "Erro ao enviar o e-mail" 
		Iif( lJob , ConOut( cMensagem ) , MsgStop( cMensagem ) ) 
		lEnvio := .F.
	Else     
		If Empty(oMessage:cTo)
			cMensagem :=  "Erro ao enviar o e-mail" 
			Iif( lJob , ConOut( cMensagem ) , MsgStop( cMensagem ) ) 
			lEnvio := .F.
		endif
	EndIf
	        
    oMessage := Nil
                                                       
	//--Desconecta do servidor
	If oServer:SMTPDisconnect() != 0
		cMensagem := "Erro ao disconectar do servidor SMTP" 
		Iif( lJob , ConOut( cMensagem ) , MsgStop( cMensagem ) ) 
		lEnvio := .F.
	EndIf
Endif

return lEnvio 
