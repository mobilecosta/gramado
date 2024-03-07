#INCLUDE "PROTHEUS.CH"
#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "XMLXFUN.CH"
#INCLUDE "ap5mail.ch"
#INCLUDE 'TOPConn.ch'
#INCLUDE "TbiCode.ch"

#DEFINE DEF_DEBUG   .f. //Verifica se é para debugar
#DEFINE DEF_DEBUG99 .f. //Força informações da empresa 99

/*/{Protheus.doc} GRAIMPCUP
Importacao Arquivo XML para geração de Cupons Fiscais
@type function
@version P12
@author Alan Oliveira
@since 06/01/2022
/*/
User Function GRAIMPCUP()

	Local cFile      := Space(10)
	Local I          := 0
	Local aArq       := {}
	Local aArqEsp    := {}
	Local nDir       := 0
	Local nEsp       := 0
	Local aDir       := {}

	Local cDirXml    := fTrazDir("DirXml",{}) //Diretório com os arquivos XML (Ex.: \XMLCUPOM\)
	Local cDirIni    := fTrazDir("DirIni",{}) //Diretório com os arquivos de cada empresa (Ex.: emp_ => Início do nome do diretório: emp_01_0301)

	Local cDirEmp    := ""
	Local cDirErr    := ""
	Local cDirLid    := ""
	Local cDirRep    := ""
	Local cDirLog    := ""

	Local nTamEmp    := 0
	Local nTamFil    := 0

	Local cFiles     := "*.xml"

	Local cNomLog   := "log_graimpcup"+"_"+DtoS(Date())+"_"+StrTran(Time(),":","")+".csv"

	Local cEmpSch    := '01'
	Local cFilSch    := '0301' //'0301' //15195705000189 - GRAMADO TERMAS PARK - AQUAMOTION

	Conout("-------------GRAIMPCUP-----------------")
	Conout("    INICIANDO MONTAGEM DA EMPRESA      ")
	Conout("---------------------------------------")

///////////////////////////////////////////////////////////////////////////////
	If DEF_DEBUG99 //Força informações da empresa 99
		cEmpSch	:= "99"
		cFilSch	:= "01"
	EndIf
///////////////////////////////////////////////////////////////////////////////

	RpcClearEnv()
	RPCSetType(3)
	RpcSetEnv(cEmpSch, cFilSch , , , "FAT")

	nTamEmp := Len(cEmpAnt)
	nTamFil := Len(cFilAnt)

	Conout("-------------GRAIMPCUP-----------------------------")
	Conout("          EMPRESA ABERTA                           ")
	Conout("---------------------------------------------------")

	Conout("-------------GRAIMPCUP-----------------------------")
	Conout("        LENDO ARQUIVOS NA PASTA                    ")
	Conout("---------------------------------------------------")

	aArqEsp := fDirEsp(cDirXml,cFiles) //Lista os arquivos retornando um array de arrays com no máximo 10.000 arquivos

	nEsp := 0
	aEval(aArqEsp,{|x|nEsp+=Len(x)}) //Contagem de arquivos encontrados

	Conout("-------------GRAIMPCUP-----------------------------")
	Conout("IDENTIFICADO "+Alltrim(Str(nEsp))+" ARQUIVOS       ")
	Conout("---------------------------------------------------")

	//Move os arquivos para a pasta da empresa
	For nEsp := 1 To len(aArqEsp)
		aArq := aArqEsp[nEsp]
		For I := 1 To len(aArq)
			cFile := lower(aArq[i][1])
			fMoveArq(cDirXml,cFile) //Move o arquivo para a pasta da empresa
		Next I
	Next 

	//Importacao Arquivo XML para geração de Cupons Fiscais
	aDir := Directory(cDirXml + cDirIni + "*","D") //\XMLCUPOM\emp_* (Ex.: \XMLCUPOM\emp_01_0301)

	fConOut("Pastas "+'"'+cDirIni+'"'+" encontradas: "+AllTrim(Str(Len(aDir))),.f.,.t.) //Mostra a mensagem no ConOut e grava no arquivo de log

	For nDir := 1 to Len(aDir)
		If aDir[nDir,5] == "D"
			fConOut("Pasta: "+AllTrim(aDir[nDir,1])+" => Início de processamento",.f.,.t.) //Mostra a mensagem no ConOut e grava no arquivo de log

			cEmpSch := Subs(aDir[nDir,1],Len(cDirIni)+1          ,nTamEmp) //Pega a empresa: Ex.: emp_01_0301
			cFilSch := Subs(aDir[nDir,1],Len(cDirIni)+1+nTamEmp+1,nTamFil) //Pega a filial: Ex.: emp_01_0301

			aEmpFil := fEmpFil("Empresa+Filial",{cEmpSch,cFilSch}) //Retorna a empresa e a filial pela chave desejada
			If Empty(aEmpFil) //Empresa+Filial não encontrada
				fConOut("Pasta: "+AllTrim(aDir[nDir,1])+" => Empresa+Filial não encontrada",.f.,.t.) //Mostra a mensagem no ConOut e grava no arquivo de log
				Loop
			EndIf

			If cEmpAnt <> cEmpSch
				RpcClearEnv()
				RPCSetType(3)
				RpcSetEnv(cEmpSch, cFilSch , , , "FAT")
			Else
				cFilAnt := cFilSch
			EndIf

			//Traz os diretórios para o processamento
			cDirEmp := fTrazDir("DirEmp",aEmpFil) //Diretório com os arquivos de cada empresa (Ex.: \XMLCUPOM\emp_01_0301\)
			cDirErr := fTrazDir("DirErr",aEmpFil) //Diretório com os arquivos com erros (Ex.: \XMLCUPOM\emp_01_0301\ERROS\)
			cDirLid := fTrazDir("DirLid",aEmpFil) //Diretório com os arquivos lidos (Ex.: \XMLCUPOM\emp_01_0301\LIDOS\)
			cDirRep := fTrazDir("DirRep",aEmpFil) //Diretório com os arquivos repetidos (Ex.: \XMLCUPOM\emp_01_0301\REPETIDOS\)
			cDirLog := fTrazDir("DirLog",aEmpFil) //Diretório com os arquivos de log (Ex.: \XMLCUPOM\LOGS\log_graimpcup_20230515_090259.csv)

			aArqEsp := fDirEsp(cDirXml + aDir[nDir,1] + "\",cFiles) //Lista os arquivos retornando um array de arrays com no máximo 10.000 arquivos

			fGravaLog(cDirLog+cNomLog,"Cabec") //Grava o arquivo de log
			For nEsp := 1 To len(aArqEsp)
				aArq := aArqEsp[nEsp]
				fGravaLog(cDirLog+cNomLog,"Inicio",{"IDENTIFICADOS "+Alltrim(Str(len(aArq)))+" ARQUIVOS"}) //Grava o arquivo de log
				For I := 1 To len(aArq)
					cFile := lower(aArq[i][1])
					fConOut("Pasta: "+AllTrim(aDir[nDir,1])+" => Processando arquivo: " + cFile,.f.,.t.) //Mostra a mensagem no ConOut e grava no arquivo de log

					fGravaLog(cDirLog+cNomLog,"Processando",{cFile,StrZero(I,7)}) //Grava o arquivo de log

					XMLNFE(cDirEmp,cDirErr,cDirLid,cDirRep,cDirLog,cNomLog,cFile) //Importacao Arquivo XML para geração de Cupons Fiscais
				Next I
			Next 
			fGravaLog(cDirLog+cNomLog,"Fim",{"Fim"}) //Grava o arquivo de log

			fConOut("Pasta: "+AllTrim(aDir[nDir,1])+" => Fim de processamento",.f.,.t.) //Mostra a mensagem no ConOut e grava no arquivo de log
		EndIf
	Next

Return
//-----------------------------------------------------------------------------

/*/{Protheus.doc} XMLNFE
Importacao Arquivo XML para geração de Cupons Fiscais
@type function
@version P12
@author Fernando Amorim
@since 06/01/2022
@param cDirEmp, character, Diretório com os arquivos de cada empresa (Ex.: \XMLCUPOM\emp_01_0301\)
@param cDirErr, character, Diretório com os arquivos com erros (Ex.: \XMLCUPOM\emp_01_0301\ERROS\)
@param cDirLid, character, Diretório com os arquivos lidos (Ex.: \XMLCUPOM\emp_01_0301\LIDOS\)
@param cDirRep, character, Diretório com os arquivos repetidos (Ex.: \XMLCUPOM\emp_01_0301\REPETIDOS\)
@param cDirLog, character, Diretório com os arquivos de log
@param cNomLog, character, Nome do arquivo de log
@param cFile, character, Arquivo a ser importado
/*/
Static Function XMLNFE(cDirEmp,cDirErr,cDirLid,cDirRep,cDirLog,cNomLog,cFile) //Importacao Arquivo XML para geração de Cupons Fiscais

	Local nx, nY	:= 0
	Local _lErro 	:= .F.
	Local _lRepe	:= .F.
	Local nHdl    	:= 0
	Local aSitTrib  := {}
	Local nPrivate2 := 0
	Local oDetLin	:= Nil
	Local _cAlias	:= GetNextAlias()
	Local _cPed		:= ""
	Local oEmitente
	Local oIdent
	Local oTotal
	Local oDet
	Local oPag
	Local oXML

	Local cProd      := ""

	Local cErroAuto  := "" //Resultado do processamento
	Local aErroAuto  := {} //Resultado do processamento

	If !File(cDirEmp + cFile)
		Conout("-------------GRAIMPCUP-----------------")
		Conout("O arquivo de nome "+cFile+" nao existe! Verifique os parametros.")
		Conout("")
		fGravaLog(cDirLog+cNomLog,"NaoExiste",{cFile,"Arquivo inexistente."}) //Grava o arquivo de log
		Return
	EndIf

	nHdl := fOpen(cDirEmp+cFile,0)

	If nHdl == -1
		If !Empty(cFile)
			Conout("-------------GRAIMPCUP-----------------")
			Conout("O arquivo de nome "+cFile+" nao pode ser aberto! Verifique os parametros.")
			Conout("")
			fGravaLog(cDirLog+cNomLog,"NaoAbre",{cFile,"O arquivo nao pode ser aberto."}) //Grava o arquivo de log
		Endif
		Return
	Endif

	nTamFile := fSeek(nHdl,0,2)
	fSeek(nHdl,0,0)
	cBuffer  := Space(nTamFile)                // Variavel para criacao da linha do registro para leitura
	nBtLidos := fRead(nHdl,@cBuffer,nTamFile)  // Leitura  do arquivo XML
	fClose(nHdl)

	aadd(aSitTrib,"00")
	aadd(aSitTrib,"10")
	aadd(aSitTrib,"20")
	aadd(aSitTrib,"30")
	aadd(aSitTrib,"40")
	aadd(aSitTrib,"41")
	aadd(aSitTrib,"50")
	aadd(aSitTrib,"51")
	aadd(aSitTrib,"60")
	aadd(aSitTrib,"70")
	aadd(aSitTrib,"90")

	cAviso := ""
	cErro  := ""

	oNF := XmlParserFile( cDirEmp+cFile, "_", @cErro, @cAviso )

	If Empty(oNF) .Or. !Empty(cErro)
		fGravaLog(cDirLog+cNomLog,"Parser",{cFile,cErro}) //Grava o arquivo de log
		Return
	EndIf

	oEmitente := oNF:_NfeProc:_Nfe:_InfNfe:_Emit
	oIdent    := oNF:_NfeProc:_Nfe:_InfNfe:_IDE
	oTotal    := oNF:_NfeProc:_Nfe:_InfNfe:_Total
	oDet      := oNF:_NfeProc:_Nfe:_InfNfe:_Det
	//oPag	  := oNF:_NfeProc:_Nfe:_InfNfe:_Pag
	oPag	  := oNF:_NfeProc:_Nfe:_InfNfe:_Pag:_detPag

	oDet := IIf(ValType(oDet)=="O",{oDet},oDet)

	oPag := IIf(ValType(oPag)=="O",{oPag},oPag)

// CNPJ ou CPF
	cCgc := AllTrim(IIf(Type("oEmitente:_CPF")=="U",oEmitente:_CNPJ:TEXT,oEmitente:_CPF:TEXT))
	cCgc := Padr(cCgc,GetSx3Cache("A1_CGC", "X3_TAMANHO"))


///////////////////////////////////////////////////////////////////////////////
If .f. //multi//
///////////////////////////////////////////////////////////////////////////////


/*
Busca a Filial Correta para Inclusão de Registros na SL1, SL2, SL4
*/
If (Select(_cAlias) >0 )
	(_cAlias)->(dbCloseArea())
Endif

BeginSql Alias _cAlias
	SELECT DISTINCT
		M0_CODFIL
	FROM	
		SYS_COMPANY (NOLOCK) SYS
	WHERE
		SYS.M0_CGC = %Exp:cCgc%
		AND SYS.M0_CODIGO+SYS.M0_CODFIL != '010101'	
	AND SYS.%notdel%
EndSql

If (_cAlias)->(!Eof())
	CONOUT("GRAIMPCUP - Realizando Troca de Filial "+Alltrim((_cAlias)->M0_CODFIL))
	cFilAnt := Alltrim((_cAlias)->M0_CODFIL)
Endif


SA1->(dbSetOrder(3))
If !SA1->(DbSeek(xFilial("SA1")+cCgc))
	//Conout("-------------GRAIMPCUP-----------------")
	//Conout("O arquivo de nome "+cFile+" nao pode ser aberto! Verifique os parametros.")
	//Conout("")
Endif


///////////////////////////////////////////////////////////////////////////////
EndIf //If .f. //multi//
///////////////////////////////////////////////////////////////////////////////


If (Select(_cAlias) >0 )
	(_cAlias)->(dbCloseArea())
Endif

BeginSql Alias _cAlias

	Select Distinct
		SL1.L1_NUM, SL1.L1_SITUA
	From
		 %table:SL1% (NOLOCK) SL1
	Where
		SL1.%notdel%
	AND SL1.L1_FILIAL =  %xFilial:SL1%
	AND SL1.L1_DOC	  =  %Exp:oIdent:_nNF:text%
	AND SL1.L1_SERIE  =  %Exp:oIdent:_serie:text%
EndSql

IF (_cAlias)->(!Eof())
	If (_cAlias)->L1_SITUA  = 'RX'
		//Limpa Registros para continuar a importação.
		Conout("----------------------------------" )
		Conout("LOCALIZADO REGISTRO NA SL1 "+Alltrim((_cAlias)->L1_NUM) +" SEM PROCESSAMENTO")
		Conout("Excluindo Registros" )
		Conout("" )
		GRAIMPREG((_cAlias)->L1_NUM) //Limpa Registros das tabelas do Loja para iniciar uma nova importação
	Else
		_lRepe := .T.
	Endif
Endif

(_cAlias)->(dbCloseArea())

If !_lRepe

	//_cPed := GetSxeNum("SL1","L1_NUM")
	_cPed := ProxSL1() //Retorna o número do próximo orçamento

	fGravaLog(cDirLog+cNomLog,"Itens",{cFile,StrZero(Len(oDet),7)}) //Grava o arquivo de log

	For nX:=1 To Len(oDet)
		oDetLin := oDet[nx]

		cProd := Padr(oDetLin:_prod:_cprod:TEXT,GetSx3Cache("B1_COD", "X3_TAMANHO"))

///////////////////////////////////////////////////////////////////////////////
		If DEF_DEBUG99 //Força informações da empresa 99
			cProd := Padr("001",Len(cProd))
		EndIf
///////////////////////////////////////////////////////////////////////////////

		//Gravação Campos na SL2
		SL2->(DbSelectArea("SL2"))
		RecLock("SL2",.T.)
		SL2->L2_FILIAL  := xFilial("SL2")
		SL2->L2_NUM		:= _cPed

		DbSelectArea("SB1")
		SB1->(DbSetOrder(1))
		If!(SB1->(DbSeek(xFilial("SB1")+cProd))) //Posiciona no SB1
			Conout("----------------------------------" )
			Conout("Cupom: "+Alltrim(oIdent:_nNF:TEXT))
			Conout("Produto: "+Alltrim(cProd) +" "+Alltrim(oDetLin:_prod:_xprod:TEXT) +" nao esta cadastrado" )
			Conout("Excluindo Registros" )
			Conout("" )
			//Limpa Registros
			GRAIMPREG(_cPed) //Limpa Registros das tabelas do Loja para iniciar uma nova importação
			_lErro := .T.
			Exit

		Endif

//verifica a existencia da TAG vDesc
/*
			conout("ValType vDesc: "+VaLType("oDetLin:_PROD:_VDESC"))
			//ValType(oXML:_NFE:_CPFCNPJPRESTADOR:_CNPJ) == "U"
			//oNF:_NfeProc:_Nfe:_InfNfe:_Det
			//		conout("ValType vDesc SEM ASPAS 1: "+VaLType(oNF:_NFEPROC:_NFE:_INFNFE:_DET[nx]:_PROD:_VDESC))
			//		conout("ValType vDesc SEM ASPAS 2: "+VaLType(oDetLin:_PROD:_VDESC))
			conout("Type vDesc: "+Type("oDetLin:_PROD:_VDESC"))
			//CONOUT("XMLCHILD: "+STR(XmlChildEx(oDetLin,"_VDESC")))
			//XmlChildEx(oXml:_nfeProc:_NFe:_InfNfe:_transp,"_MODFRETE")
			//If(XmlChildEx ( oXml ,"_TAG")<>Nil)
			if XmlChildEx(oDetLin,"_VDESC") <> "U"
				CONOUT("ACHOU XMLCHILD")
			ELSE
				CONOUT("NAO ACHOU XMLCHILD")
			ENDIF

			CONOUT("XMLCHILD: "+VALTYPE(XmlChildEx(oDetLin,"_VDESC")))

			//conout("Type vDesc sem aspas: "+Type(oDetLin:_prod:_vDesc))
			conout("ValType vDesc TST1: "+VaLType("oDetLin:_PROD:_VDESC:TEXT"))
			conout("Type vDesc TST2: "+Type("oDetLin:_PROD:_VDESC:TEXT"))
//			conout("ValType vDesc S/ASPA: "+VaLType(oDetLin:_PROD:_VDESC))

		//	conout("ValType vDesc TST3: "+VaLType(oDetLin:_PROD:_VDESC))
		//	conout("Type vDesc TST4: "+Type(oDetLin:_PROD:_VDESC))
*/		
		//	oXML := XmlChildEx(oDetLin, "_VDESC")
		//	conout("Type oXML 1: "+ValType(oXML))
		oXML := XmlChildEx(oDetLin:_PROD, "_VDESC")
		conout("Type oXML 2: "+ValType(oXML))

		CONOUT("XMLCHILD 3: "+VALTYPE(XmlChildEx(oDetLin:_PROD,"_VDESC")))

		//IF ValType("oDetLin:_prod:_vDesc") <> "U"
		//Type("oDetNF:_InfNFE")<>"U"
		//IF Type(oDetLin:_prod:_vDesc) <> "U"
		IF VALTYPE(XmlChildEx(oDetLin:_PROD,"_VDESC")) <> "U"
			SL2->L2_VALDESC := Val(oDetLin:_prod:_vDesc:TEXT)
			SL2->L2_VRUNIT	:= (Val(oDetLin:_prod:_vProd:TEXT) - Val(oDetLin:_prod:_vDesc:TEXT))
			SL2->L2_VLRITEM := (Val(oDetLin:_prod:_vProd:TEXT) - Val(oDetLin:_prod:_vDesc:TEXT))
		ELSE

			SL2->L2_VRUNIT	:= Val(oDetLin:_prod:_vProd:TEXT)
			SL2->L2_VLRITEM := Val(oDetLin:_prod:_vProd:TEXT)

		ENDIF

		SL2->L2_PRODUTO   := Alltrim(cProd)
		SL2->L2_ITEM	  := fSoma1Item(oDetLin:_nItem:Text) //Soma 1 no item com duas posições
		SL2->L2_DESCRI	  := Alltrim(oDetLin:_prod:_xprod:TEXT)
		SL2->L2_QUANT	  := Val(oDetLin:_prod:_qcom:TEXT)
        //SL2->L2_VRUNIT  := (Val(oDetLin:_prod:_vProd:TEXT) - Val(oDetLin:_prod:_vDesc:TEXT))
		//SL2->L2_VRUNIT  := Val(oDetLin:_prod:_vUnCom:TEXT)
        //SL2->L2_VLRITEM := (Val(oDetLin:_prod:_vProd:TEXT) - Val(oDetLin:_prod:_vDesc:TEXT))
		//SL2->L2_VLRITEM := Val(oDetLin:_prod:_vProd:TEXT)
		//SL2->L2_VALDESC := Val(oDetLin:_prod:_vDesc:TEXT)
		SL2->L2_LOCAL 	  := SB1->B1_LOCPAD
		SL2->L2_UM		  := Alltrim(Upper(oDetLin:_prod:_utrib:TEXT))
		SL2->L2_TES		  := SB1->B1_TS

		DbSelectArea("SF4")
		SF4->(DbSetOrder(1))
		SF4->(DbSeek(xFilial("SF4")+SB1->B1_TS))

		SL2->L2_CF 		:= SF4->F4_CF
		SL2->L2_TABELA  := "001"
		SL2->L2_EMISSAO := stod(StrTran(SubStr(oIdent:_dhEmi:text,1,10),"-",""))
		SL2->L2_PRCTAB	:= Val(oDetLin:_prod:_vUnCom:TEXT)
		SL2->L2_VEND	:= "000001"
		SL2->L2_ENTREGA := "2"
		SL2->L2_BASEIPI := 0
		SL2->L2_VALIPI	:= 0
		SL2->L2_DOC     := oIdent:_nNF:text
		SL2->L2_SERIE   := oIdent:_serie:text

		nLenSit := Len(aSitTrib)

		If Valtype(XmlChildEx(oDetLin:_imposto, "_ICMS")) == "O"
			For nY := 1 To nLenSit
				nPrivate2 := nY
				If Valtype(XmlChildEx(oDetLin:_Imposto:_ICMS,"_ICMS"+aSitTrib[nPrivate2])) == "O"
					DO CASE 						
						CASE  &("oDetLin:_imposto:_ICMS:_ICMS"+aSitTrib[nY]+":REALNAME") == "ICMS60"

							If Valtype(XmlChildEx(&("oDetLin:_imposto:_ICMS:_ICMS"+aSitTrib[nY]),"_vBCEFET")) == "C"
								SL2->L2_BASEICM := Val(&("oDetLin:_imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_vBCEFET:TEXT"))
							Else
								SL2->L2_BASEICM := 0
							EndIf
							If Valtype(XmlChildEx(&("oDetLin:_imposto:_ICMS:_ICMS"+aSitTrib[nY]),"_vICMSEFET")) == "C"
								SL2->L2_VALICM  := Val(&("oDetLin:_imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_vICMSEFET:TEXT"))
							Else
								SL2->L2_VALICM  := 0
							EndIf
							If Valtype(XmlChildEx(&("oDetLin:_imposto:_ICMS:_ICMS"+aSitTrib[nY]),"_pICMSEFET")) == "C"
								SL2->L2_PICM    := Val(&("oDetLin:_imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_pICMSEFET:TEXT"))
							Else
								SL2->L2_PICM    := 0
							EndIf

						CASE  &("oDetLin:_imposto:_ICMS:_ICMS"+aSitTrib[nY]+":REALNAME") == "ICMS40"
						     	SL2->L2_MOTDICM := &("oDetLin:_imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_MOTDESICMS:TEXT")
						     	SL2->L2_DESCICM := Val(&("oDetLin:_imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_vICMSDeson:TEXT"))

						CASE  &("oDetLin:_imposto:_ICMS:_ICMS"+aSitTrib[nY]+":REALNAME") == "ICMS20"
						        SL2->L2_PREDIC  := Val(&("oDetLin:_imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_pRedBC:TEXT"))
								SL2->L2_BASEICM := Val(&("oDetLin:_imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_vBC:TEXT"))
								SL2->L2_PICM    := Val(&("oDetLin:_imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_pICMS:TEXT"))				
								SL2->L2_VALICM  := Val(&("oDetLin:_imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_vICMS:TEXT"))
						OTHERWISE
								SL2->L2_BASEICM := Val(&("oDetLin:_imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_vBC:TEXT"))
					 		    SL2->L2_VALICM  := Val(&("oDetLin:_imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_vICMS:TEXT"))
					 		    SL2->L2_PICM    := Val(&("oDetLin:_imposto:_ICMS:_ICMS"+aSitTrib[nY]+":_pICMS:TEXT"))
					ENDCASE
				EndIf
			Next nY
		Endif

		If Valtype(XmlChildEx(oDetLin:_Imposto, "_COFINS")) == "O"
			If Valtype(XmlChildEx(oDetLin:_imposto:_COFINS,"_COFINSALIQ")) == "O"
				SL2->L2_ALIQCOF := Val(oDetLin:_imposto:_COFINS:_COFINSAliq:_pCOFINS:Text)
				SL2->L2_BASECOF	:= Val(oDetLin:_imposto:_COFINS:_COFINSAliq:_vBC:Text)
				SL2->L2_VALCOFI := Val(oDetLin:_imposto:_COFINS:_COFINSAliq:_vCOFINS:Text)
			Endif
		Endif

		If Valtype(XmlChildEx(oDetLin:_Imposto, "_PIS")) == "O"
			If Valtype(XmlChildEx(oDetLin:_Imposto:_PIS,"_PISALIQ")) == "O"
				SL2->L2_ALIQPIS := Val(oDetLin:_imposto:_PIS:_PISAliq:_pPIS:Text)
				SL2->L2_BASEPIS := Val(oDetLin:_imposto:_PIS:_PISAliq:_vBC:Text)
				SL2->L2_VALPIS	:= Val(oDetLin:_imposto:_PIS:_PISAliq:_vPIS:Text)
			Endif
		Endif

		SL2->(Msunlock())

		fGravaLog(cDirLog+cNomLog,"GravouSL2",{cFile,StrZero(nX,7),SL2->L2_DOC,SL2->L2_SERIE}) //Grava o arquivo de log

	Next nx


	If !_lErro

		//Verifica mais de uma forma de pagamento

		_ValPag := 0

		if ValType(oPag) == "O"

			//CONOUT(" *** l1 retornou O")
			_ValPag += Val(oPag:_vPag:Text)

		ELSEIF ValType(oPag) == "A"
			//CONOUT(" *** l2 retornou "+ValType(oPag) )
			conout(" *** Qtd Array oPag: "+str(Len(oPag)))

			For nX:=1 To Len(oPag)
				oPagLin := oPag[nx]
				conout(" *** Conteudo oPag: "+ oPagLin:_vPag:TEXT)
				_ValPag += val(oPagLin:_vPag:TEXT)

			next nX
		ENDIF

		//Gravação de Dados de Pagamento
		SL4->(DbSelectArea("SL4"))
		RecLock("SL4",.T.)

		SL4->L4_FILIAL	:= xFilial("SL4")
		SL4->L4_NUM		:= _cPed
		SL4->L4_DATA 	:= stod(StrTran(SubStr(oIdent:_dhEmi:text,1,10),"-",""))
		SL4->L4_VALOR 	:= _ValPag //Val(oPag:_detPag:_vPag:Text)
		SL4->L4_FORMA 	:= "CN"//oPag:_detpag:_tPag:Text

		SL4->(MsUnlock())

		fGravaLog(cDirLog+cNomLog,"GravouSL4",{cFile,SL4->L4_NUM}) //Grava o arquivo de log

		//Gravação Campos na SL1
		SL1->(DbSelectArea("SL1"))
		RecLock("SL1",.T.)
		SL1->L1_FILIAL	:= xFilial("SL1")
		SL1->L1_NUM		:= _cPed
		SL1->L1_CLIENTE	:= "000001"
		SL1->L1_LOJA 	:= "01"
		SL1->L1_TIPOCLI	:= "F"

		If Valtype(XmlChildEx(oTotal:_ICMSTot,"_VPROD")) == "O"
			SL1->L1_VLRTOT 	:= (Val(oTotal:_ICMSTot:_vProd:Text) - Val(oTotal:_ICMSTot:_vDesc:Text))
			//SL1->L1_VLRTOT  := Val(oTotal:_ICMSTot:_vProd:Text)
			//SL1->L1_DESCONT := Val(oTotal:_ICMSTot:_vDesc:Text)
			SL1->L1_VLRLIQ 	:= (Val(oTotal:_ICMSTot:_vProd:Text) - Val(oTotal:_ICMSTot:_vDesc:Text))
			//SL1->L1_VLRLIQ 	:= Val(oTotal:_ICMSTot:_vProd:Text)
			SL1->L1_VALBRUT	:= Val(oTotal:_ICMSTot:_vProd:Text)
			//SL1->L1_VALBRUT	:= Val(oTotal:_ICMSTot:_vNF:Text)
			SL1->L1_VALMERC	:= Val(oTotal:_ICMSTot:_vProd:Text)
			SL1->L1_ENTRADA	:= Val(oTotal:_ICMSTot:_vNF:Text)
			SL1->L1_VALICM 	:= Val(oTotal:_ICMSTot:_vICMS:Text)
			SL1->L1_VALIPI 	:= Val(oTotal:_ICMSTot:_vIPI:Text)
		Else
			SL1->L1_VLRTOT	:= val(oTotal:vProd:Text)
			SL1->L1_DESCONT := val(oTotal:vDesc:Text)
			SL1->L1_VLRLIQ	:= val(oTotal:vProd:Text)
			//SL1->L1_VLRLIQ	:= (val(oTotal:vProd:Text) - val(oTotal:vDesc:Text))
			SL1->L1_VALBRUT	:= val(oTotal:vNF:Text)
			SL1->L1_VALMERC	:= val(oTotal:vProd:Text)
			SL1->L1_ENTRADA	:= val(oTotal:vNF:Text)
			SL1->L1_VALICM  := val(oTotal:vICMS:Text)
			SL1->L1_VALIPI	:= val(oTotal:vIPI:Text)
		Endif

		SL1->L1_DTLIM	:= stod(StrTran(SubStr(oIdent:_dhEmi:text,1,10),"-",""))
		SL1->L1_DOC		:= oIdent:_nNF:text
		SL1->L1_SERIE	:= oIdent:_serie:text
		SL1->L1_DINHEIR	:= 0
		SL1->L1_CHEQUES	:= 0
		SL1->L1_CARTAO	:= 0
		SL1->L1_PARCELA := 1
		SL1->L1_VALISS	:= 0
		SL1->L1_CONDPG	:= "001"
		SL1->L1_FORMPG	:= "CN"
		SL1->L1_CREDITO := 0
		SL1->L1_EMISSAO := stod(StrTran(SubStr(oIdent:_dhEmi:text,1,10),"-",""))
		SL1->L1_EMISNF	:= stod(StrTran(SubStr(oIdent:_dhEmi:text,1,10),"-",""))
		SL1->L1_HORA	:= SubStr(oIdent:_dhEmi:text,11,8)
		SL1->L1_ESTACAO := "001"
		SL1->L1_KEYNFCE := oNF:_NfeProc:_ProtNfe:_InfProt:_ChnFe:Text
		SL1->L1_CGCCLI	:= cCgc
		SL1->L1_SITUA 	:= "RX"
		SL1->L1_XNOMARQ := cFile
		SL1->(MsUnlock())

		fGravaLog(cDirLog+cNomLog,"GravouSL1",{cFile,SL1->L1_DOC,SL1->L1_SERIE}) //Grava o arquivo de log

	Endif

Endif

	If _lRepe
		Conout("---------GRAIMPCUP----------------" )
		Conout("Registros Repetido - "+cFile )
		Conout("----------------------------------" )
		aErroAuto := fMoveFile(cDirEmp,cDirRep,cFile) //Move o arquivo para a pasta desejada
	ElseIf _lErro
		Conout("---------GRAIMPCUP----------------" )
		Conout("Registros com Erro - "+cFile )
		Conout("----------------------------------" )
		aErroAuto := fMoveFile(cDirEmp,cDirErr,cFile) //Move o arquivo para a pasta desejada
	Else
		Conout("---------GRAIMPCUP--------------------" )
		Conout("Registros gravado com sucesso - "+cFile )
		Conout("--------------------------------------" )
		aErroAuto := fMoveFile(cDirEmp,cDirLid,cFile) //Move o arquivo para a pasta desejada
	Endif

	If !aErroAuto[1] //Problemas no processamento
		cErroAuto := aErroAuto[2] //Mensagem de erro
		fConOut(cErroAuto,.f.,.t.)
	EndIf

	_lErro 	:= .F.
	_lRepe	:= .F.

	FreeObj(oNF)
	FreeObj(oTotal)
	FreeObj(oDet)
	FreeObj(oPag)

Return
//-----------------------------------------------------------------------------

/*/{Protheus.doc} GRAIMPREG
Limpa Registros das tabelas do Loja para iniciar uma nova importação
@type function
@version P12
@author GPK
@since 06/01/2022
@param _cNunped, character, Número do orçamento
/*/
Static Function GRAIMPREG(_cNunped) //Limpa Registros das tabelas do Loja para iniciar uma nova importação

	cQuery := " DELETE FROM "+RetSqlName("SL1")+" WHERE L1_NUM = '"+_cNunped+"' "
	TCSqlExec(cQuery)

	cQuery := " DELETE FROM "+RetSqlName("SL2")+ " WHERE L2_NUM = '"+_cNunped+"' "
	TCSqlExec(cQuery)

	cQuery := " DELETE FROM "+RetSqlName("SL4")+ " WHERE L4_NUM = '"+_cNunped+"' "
	TCSqlExec(cQuery)

	//Limpa Registros para continuar a importação.
	Conout("---------GRAIMPREG----------------" )
	Conout("Registros Excluidos ---- "+_cNunped )
	Conout("----------------------------------" )

Return
//-----------------------------------------------------------------------------

/*/{Protheus.doc} ProxSL1
Retorna o número do próximo orçamento
@type function
@version P12
@author GPK
@since 06/01/2022
@return character, Número do próximo orçamento
/*/
Static Function ProxSL1() //Retorna o número do próximo orçamento

	Local cNumL1 := space(6)
	Local aAreaAnt := GetArea()
	Local cAliasQry := GetNextAlias()

	cQuery := "SELECT MAX(L1_NUM) CODSL1"
	cQuery += " FROM " + RetSqlName('SL1') + " "
	cQuery += " WHERE L1_FILIAL = '"+xFilial('SL1')+"'"
	cQuery += " AND D_E_L_E_T_ = '' "

	cQuery := ChangeQuery(cQuery)
	DbUseArea(.T.,'TOPCONN',TcGenQry(,,cQuery),cAliasQry,.F.,.T.)

	If !Empty((cAliasQry)->CODSL1)
		// Remove os espaços em branco e incrementa o valor
		cNumL1 := Soma1(AllTrim((cAliasQry)->CODSL1))
		conout("Novo orcamento criado: " + cNumL1)
	Else
		cNumL1 := "000001"
	EndIf

	(cAliasQry)->(DBCloseArea())

	RestArea(aAreaAnt)

RETURN cNumL1
//-----------------------------------------------------------------------------

/*/{Protheus.doc} fDirEsp
Lista os arquivos retornando um array de arrays com no máximo 10.000 arquivos
@type function
@version P12
@author suportetotvs
@since 13/03/2023
@param cDirXml, character, Diretório com os arquivos a serem listados
@param cFiles, character, Arquivos a serem listados
@return array, Array de arrays com no máximo 10.000 arquivos
/*/
Static Function fDirEsp(cDirXml,cFiles) //Lista os arquivos retornando um array de arrays com no máximo 10.000 arquivos
Local cDirEsp    := cDirXml + cFiles
Local cAtributos := Nil
Local uParam1    := Nil
Local lCaseSensi := Nil
Local nTypeOrder := Nil
Local aDir       := {}

aDir := fDir(cDirEsp,cAtributos,uParam1,lCaseSensi,nTypeOrder) //Lista os arquivos retornando um array de arrays com no máximo 10.000 arquivos

Return(aDir)
//-----------------------------------------------------------------------------

/*/{Protheus.doc} fDir
Lista os arquivos retornando um array de arrays com no máximo 10.000 arquivos
Devido a limitação do Directory() em retornar no máximo 10.000 arquivos
@type function
@version P12
@author suportetotvs
@since 13/03/2023
@param cDirEsp, character, Diretório com os arquivos a serem listados
@param cAtributos, character, Indica quais tipos de arquivos/diretórios devem ser incluídos no array.
@param uParam1, variant, Parâmetro de compatibilidade, não deve ser preenchido.
@param lCaseSensi, logical, Se verdadeiro (.T.), o nome do arquivo será transformado para letra maiúscula.
@param nTypeOrder, numeric, Indica o tipo de ordenação do resultado da função (1=Nome,2=Data,3=Tamanho).
@return array, Array de arrays com no máximo 10.000 arquivos
/*/
Static Function fDir(cDirEsp,cAtributos,uParam1,lCaseSensi,nTypeOrder) //Lista os arquivos retornando um array de arrays com no máximo 10.000 arquivos
Local nPos  := 0
Local nLim  := 10000
Local aDir  := {}
Local aDir0 := {}

While nPos == 0 .or. Len(aDir0) == nLim
	cAtributos := If(++nPos == 1, Nil, ":" + StrZero( (nLim * (nPos - 1)) ,5) )
	aDir0 := Directory(cDirEsp,cAtributos,uParam1,lCaseSensi,nTypeOrder)
	AAdd(aDir,aDir0)
End

Return(aDir)
//-----------------------------------------------------------------------------

/*/{Protheus.doc} fEmpFil
Retorna a empresa e a filial pela chave desejada
@type function
@version P12
@author suportetotvs
@since 20/02/2023
@param cQual, character, Chave de pesquisa desejada: CNPJ ou Empresa+Filial
@param aParam, array, Array com o CNPJ ou Empresa+Filial
@return array, Array com a empresa e a filial encontrada
/*/
Static Function fEmpFil(cQual,aParam) //Retorna a empresa e a filial pela chave desejada
Local nPos := 0
Local aSM0 := FWLoadSM0()
Local aRet := {}

///////////////////////////////////////////////////////////////////////////////
If DEF_DEBUG99 //Força informações da empresa 99
	If Upper(cQual) == Upper("Cnpj") //aParam[1] = CNPJ
		aParam[1] := aSM0[1,18]
	EndIf
EndIf
///////////////////////////////////////////////////////////////////////////////

Do Case
Case Upper(cQual) == Upper("Cnpj"          ) //aParam[1] = CNPJ
	If aParam[1] == "13820324000118"
		nPos := Ascan(aSM0,{|x| PadR(x[18],Len(aParam[1])) == aParam[1] .and. AllTrim(x[02]) == "0102"})
	Else
		nPos := Ascan(aSM0,{|x| PadR(x[18],Len(aParam[1])) == aParam[1]})
	EndIf
Case Upper(cQual) == Upper("Empresa+Filial") //aParam[1] = Empresa, aParam[2] = Filial
	nPos := Ascan(aSM0,{|x| PadR(x[01],Len(aParam[1])) + PadR(x[2],Len(aParam[2])) == aParam[1] + aParam[2]})
EndCase

If nPos > 0
	AAdd(aRet,aSM0[nPos,1])
	AAdd(aRet,aSM0[nPos,2])
EndIf

Return(aRet)
//-----------------------------------------------------------------------------

/*/{Protheus.doc} fConOut
Mostra a mensagem no ConOut e grava no arquivo de log
@type function
@version P12
@author suportetotvs
@since 14/02/2023
@param cMens, character, Mensagem a ser considerada no ConOut e na gravação do arquivo de log
@param lGravaLog, logical, Se grava no arquivo de log
/*/
Static Function fConOut(cMens,lConOut,lGravaLog) //Mostra a mensagem no ConOut e grava no arquivo de log
Local cDir := "\logs\"
Local cArq := "graimpcup_log.txt"

DEFAULT lConOut   := .t.
DEFAULT lGravaLog := .t.

If lConOut //Mostra a mensagem no ConOut
	ConOut(cMens)
EndIf

If lGravaLog //Grava no arquivo de log
    fGravaLog(cDir + cArq, cMens, .t.)
EndIf

Return
//-----------------------------------------------------------------------------

/*/{Protheus.doc} fDtoC
Retorna a data no formato DD/MM/YYYY
@type function
@version P12
@author suportetotvs
@since 14/02/2023
@param dData, date, Data a ser convertida
@return character, Data no formato DD/MM/YYYY
/*/
Static Function fDtoC(dData) //Retorna DD/MM/YYYY
Local cData:=DtoS(dData)
Return(Subs(cData,7,2)+"/"+Subs(cData,5,2)+"/"+Subs(cData,1,4))
//-----------------------------------------------------------------------------

/*/{Protheus.doc} fGravaLog
Grava o log
@type function
@version P12
@author João Carlos da Silva
@since 14/02/2023
@param cArqLog, character, Arquivo de log
@param cParam, character, Tipo do log
@param aParams, array, Parâmetros do log
/*/
Static Function fGravaLog(cArqLog,cParam,aParams) //Grava o arquivo de log
//desabilitado//Local lLog  := .f.
Local cMens := ""

Local cData     := fDtoC(Date())
Local cHora     := Time()
Local cLog      := cParam
Local cArquivo  := ""
Local cSeq      := ""
Local cMensagem := ""

Do Case
Case Upper(cParam)==Upper("Cabec"  )
	cData     := "Data"
	cHora     := "Hora"
	cLog      := "Log"
	cArquivo  := "Arquivo"
	cSeq      := "Sequencia"
	cMensagem := "Mensagem"
Case Upper(cParam)==Upper("Inicio"   )
	cMensagem := aParams[1]
Case Upper(cParam)==Upper("Fim"      )
	cMensagem := aParams[1]
Case Upper(cParam)==Upper("NaoAbre"  )
	cArquivo  := aParams[1]
	cMensagem := aParams[2]
Case Upper(cParam)==Upper("NaoExiste")
	cArquivo  := aParams[1]
	cMensagem := aParams[2]
Case Upper(cParam)==Upper("Parser"   )
	cArquivo  := aParams[1]
	cMensagem := aParams[2]
Case Upper(cParam)==Upper("Itens"    )
	cArquivo  := aParams[1]
	cMensagem := aParams[2]
Case Upper(cParam)==Upper("GravouSL2")
	cArquivo  := aParams[1]
	cSeq      := aParams[2]
	cMensagem := aParams[3]+"/"+aParams[4]
Case Upper(cParam)==Upper("GravouSL4")
	cArquivo  := aParams[1]
	cMensagem := aParams[2]
Case Upper(cParam)==Upper("GravouSL1")
	cArquivo  := aParams[1]
	cMensagem := aParams[2]+"/"+aParams[3]
Case Upper(cParam)==Upper("Processando")
	cArquivo  := aParams[1]
	cMensagem := aParams[2]
EndCase

cMens:=cData+";"+cHora+";"+cLog+";"+cArquivo+";"+cSeq+";"+cMensagem

//desabilitado//fGravaLog0(cArqLog,cMens,lLog) //Grava o arquivo de log

Return
//-----------------------------------------------------------------------------

/*/{Protheus.doc} fGravaLog0
Grava o arquivo de log
@type function
@version P12
@author suportetotvs
@since 14/02/2023
@param cArqLog, character, Nome do arquivo a ser gravado
@param cMens, character, Mensagem a ser gravada
@param lLog, logical, Se inclui a data e a hora do processamento
@return logical, Se gravou o arquivo com sucesso
/*/
Static Function fGravaLog0(cArqLog,cMens,lLog) //Grava o arquivo de log
Local nPosFim,nHandle,cBuffer

DEFAULT lLog := .f.

If lLog
	cMens:=fDtoC(Date())+" "+Time()+" => " + cMens  //Inclui a data e a hora do processamento
EndIf

If !File(cArqLog)
	nHandle:=fCreate(cArqLog,0)
	If nHandle==-1
		Alert("LOG ERROR: "+AllTrim(Str(nHandle))+" ==> Nao foi possivel criar "+cArqLog)
		Return(.f.)
	EndIf
	fClose(nHandle)
EndIf

nHandle:=fOpen(cArqLog,2)

If fError()<>0
	Alert("LOG ERROR: "+AllTrim(Str(fError()))+" ==> Nao foi possivel abrir "+cArqLog)
	Return(.f.)
EndIf

cBuffer:=cMens+Chr(13)+Chr(10)

nPosFim:=fSeek(nHandle,0,2)  //Posiciona no Fim do Arquivo

fWrite(nHandle,cBuffer,Len(cBuffer))

If fError()<>0
	Alert("LOG ERROR: "+AllTrim(Str(fError()))+" ==> Nao foi possivel gravar "+cArqLog)
	fClose(nHandle)
	Return(.f.)
EndIf

nPosFim:=fSeek(nHandle,0,2)  //Posiciona no Fim do Arquivo

fClose(nHandle)

Return(.t.)
//-----------------------------------------------------------------------------

/*/{Protheus.doc} fMoveArq
Move o arquivo para a pasta da empresa
@type function
@version p12
@author suportetotvs
@since 13/03/2023
@param cDirXml, character, Caminho da pasta com os arquivos XML
@param cFile, character, Nome do arquivo a ser movido para a pasta da empresa
/*/
Static Function fMoveArq(cDirXml,cFile) //Move o arquivo para a pasta da empresa
Local nHdl       := 0
Local nTamFile   := 0
Local cBuffer    := ""
Local nBtLidos   := 0

Local cErroAuto  := "" //Resultado do processamento
Local aErroAuto  := {} //Resultado do processamento

Local cAviso     := ""
Local cErro      := ""
Local oNF        := Nil
Local oEmitente  := Nil
Local cCgc       := ""
Local aEmpFil    := {}

Local cDirEmp    := ""
Local cDirErr    := ""
Local cDirLid    := ""
Local cDirRep    := ""
Local cDirLog    := ""

nHdl := fOpen(cDirXml+cFile,0)
If nHdl == -1
	cErroAuto := "[GRAIMPCUP]ERRO: O arquivo de nome "+cFile+" nao pode ser aberto! Verifique os parametros."
	fConOut(cErroAuto,.f.,.t.)
	Return
Endif

nTamFile := fSeek(nHdl,0,2)
fSeek(nHdl,0,0)
cBuffer  := Space(nTamFile)                // Variavel para criacao da linha do registro para leitura
nBtLidos := fRead(nHdl,@cBuffer,nTamFile)  // Leitura  do arquivo XML
fClose(nHdl)

If nBtLidos > 0
	cAviso := ""
	cErro  := ""

	oNF    := XmlParserFile( cDirXml+cFile, "_", @cErro, @cAviso )

	If oNF == Nil .or. XmlChildEx(oNF,"_NFEPROC")==Nil .or. XmlChildEx(oNF:_NFEPROC,"_NFE")==Nil .or. XmlChildEx(oNF:_NFEPROC:_NFE,"_INFNFE")==Nil .or. XmlChildEx(oNF:_NFEPROC:_NFE:_INFNFE,"_EMIT")==Nil
		cCgc := "nao_informado_" //Para mover o arquivo para a pasta erro
	Else
		oEmitente := oNF:_NfeProc:_Nfe:_InfNfe:_Emit
		cCgc := AllTrim(IIf(Type("oEmitente:_CPF")=="U",oEmitente:_CNPJ:TEXT,oEmitente:_CPF:TEXT))
	EndIf

	cCgc := Padr(cCgc,GetSx3Cache("A1_CGC", "X3_TAMANHO")) // Ajusta o tamanho do CNPJ

	aEmpFil := fEmpFil("Cnpj",{cCgc}) //Retorna a empresa e a filial pela chave desejada

	cDirEmp := fTrazDir("DirEmp",aEmpFil) //Diretório com os arquivos de cada empresa (Ex.: \XMLCUPOM\emp_01_0301\)
	cDirErr := fTrazDir("DirErr",aEmpFil) //Diretório com os arquivos com erros (Ex.: \XMLCUPOM\emp_01_0301\ERROS\)
	cDirLid := fTrazDir("DirLid",aEmpFil) //Diretório com os arquivos lidos (Ex.: \XMLCUPOM\emp_01_0301\LIDOS\)
	cDirRep := fTrazDir("DirRep",aEmpFil) //Diretório com os arquivos repetidos (Ex.: \XMLCUPOM\emp_01_0301\REPETIDOS\)
	cDirLog := fTrazDir("DirLog",aEmpFil) //Diretório com os arquivos de log (Ex.: \XMLCUPOM\LOGS\log_graimpcup_20230515_090259.csv)

	If !ExistDir(cDirEmp)
		cErroAuto := "[GRAIMPCUP]Criando a pasta: " + cDirEmp
		fConOut(cErroAuto,.f.,.t.)
		MakeDir(cDirEmp) //Ex.: \XMLCUPOM\emp_01_0301\
	EndIf
	If !ExistDir(cDirErr)
		cErroAuto := "[GRAIMPCUP]Criando a pasta: " + cDirErr
		fConOut(cErroAuto,.f.,.t.)
		MakeDir(cDirErr) //Ex.: \XMLCUPOM\emp_01_0301\ERROS\
	EndIf
	If !ExistDir(cDirLid)
		cErroAuto := "[GRAIMPCUP]Criando a pasta: " + cDirLid
		fConOut(cErroAuto,.f.,.t.)
		MakeDir(cDirLid) //Ex.: \XMLCUPOM\emp_01_0301\LIDOS\
	EndIf
	If !ExistDir(cDirRep)
		cErroAuto := "[GRAIMPCUP]Criando a pasta: " + cDirRep
		fConOut(cErroAuto,.f.,.t.)
		MakeDir(cDirRep) //Ex.: \XMLCUPOM\emp_01_0301\REPETIDOS\
	EndIf
	If !ExistDir(cDirLog)
		cErroAuto := "[GRAIMPCUP]Criando a pasta: " + cDirLog
		ConOut(cErroAuto) //Mostra a mensagem no ConOut
		MakeDir(cDirLog) //Ex.: \XMLCUPOM\emp_01_0301\LOGS\
	EndIf

	cErroAuto := "[GRAIMPCUP]Arquivo: "+AllTrim(cFile)+" CNPJ: "+AllTrim(cCgc)+" => Movendo para a pasta: " + cDirEmp
	fConOut(cErroAuto,.f.,.t.)

	//Move o arquivo para a pasta da empresa
	aErroAuto := fMoveFile(cDirXml,cDirEmp,cFile) //Move o arquivo para a pasta desejada
	If !aErroAuto[1] //Problemas no processamento
		cErroAuto := aErroAuto[2] //Mensagem de erro
		fConOut(cErroAuto,.f.,.t.)
	EndIf
Else
	cErroAuto := "[GRAIMPCUP]ERRO: Problemas na leitura do arquivo "+cFile
	fConOut(cErroAuto,.f.,.t.)
EndIf

Return
//-----------------------------------------------------------------------------

/*/{Protheus.doc} fTrazDir
Retorna o nome do diretório desejado
@type function
@version P12
@author suportetotvs
@since 20/03/2023
@param cQual, character, Qual o nível do diretório
@param aEmpFil, array, Array com a empresa e a filial
@return character, Nome do diretório desejado
/*/
Static Function fTrazDir(cQual,aEmpFil) //Retorna o nome do diretório desejado
Local cDirXml := "\XMLCUPOM\"  //Diretório com os arquivos XML (Ex.: \XMLCUPOM\)
Local cDirIni := "emp_"        //Diretório com os arquivos de cada empresa (Ex.: emp_ => Início do nome do diretório: emp_01_0301)
Local cDirEmp := ""            //Diretório com os arquivos de cada empresa (Ex.: \XMLCUPOM\emp_01_0301\)
Local cDirXXX := "error_cnpj\" //Diretório com os arquivos com CNPJ não encontrado (Ex.: \XMLCUPOM\error_cnpj\)
Local cDirErr := "ERROS\"      //Diretório com os arquivos com erros (Ex.: \XMLCUPOM\emp_01_0301\ERROS\)
Local cDirLid := "LIDOS\"      //Diretório com os arquivos lidos (Ex.: \XMLCUPOM\emp_01_0301\LIDOS\)
Local cDirRep := "REPETIDOS\"  //Diretório com os arquivos repetidos (Ex.: \XMLCUPOM\emp_01_0301\REPETIDOS\)
Local cDirLog := "LOGS\"       //Diretório com os arquivos de log (Ex.: \XMLCUPOM\LOGS\log_graimpcup_20230515_090259.csv)
Local cRet    := ""

If Empty(aEmpFil) //CNPJ não encontrado
	cDirEmp := cDirXml + cDirXXX //Diretório com os arquivos com CNPJ não encontrado (Ex.: \XMLCUPOM\error_cnpj\)
Else
	cDirEmp := cDirXml + cDirIni + AllTrim(aEmpFil[1]) + "_" + AllTrim(aEmpFil[2]) + "\" //Diretório com os arquivos de cada empresa (Ex.: \XMLCUPOM\emp_01_0301\)
EndIf

Do Case
Case Upper(cQual) == Upper("DirXml") //Diretório com os arquivos XML (Ex.: \XMLCUPOM\)
	cRet := cDirXml
Case Upper(cQual) == Upper("DirIni") //Diretório com os arquivos de cada empresa (Ex.: emp_ => Início do nome do diretório: emp_01_0301)
	cRet := cDirIni
Case Upper(cQual) == Upper("DirEmp") //Diretório com os arquivos de cada empresa (Ex.: \XMLCUPOM\emp_01_0301\)
	cRet := cDirEmp
Case Upper(cQual) == Upper("DirErr") //Diretório com os arquivos com erros (Ex.: \XMLCUPOM\emp_01_0301\ERROS\)
	cRet := cDirEmp + cDirErr
Case Upper(cQual) == Upper("DirLid") //Diretório com os arquivos lidos (Ex.: \XMLCUPOM\emp_01_0301\LIDOS\)
	cRet := cDirEmp + cDirLid
Case Upper(cQual) == Upper("DirRep") //Diretório com os arquivos repetidos (Ex.: \XMLCUPOM\emp_01_0301\REPETIDOS\)
	cRet := cDirEmp + cDirRep
Case Upper(cQual) == Upper("DirLog") //Diretório com os arquivos de log (Ex.: \XMLCUPOM\emp_01_0301\LOGS\)
	cRet := cDirEmp + cDirLog
EndCase

Return(cRet)
//-----------------------------------------------------------------------------

/*/{Protheus.doc} fMoveFile
Move o arquivo para a pasta desejada
@type function
@version P12
@author suportetotvs
@since 21/03/2023
@param cDirXml, character, Pasta de origem
@param cDirEmp, character, Pasta de destino
@param cFile, character, Nome do arquivo
@return array, Se executou com sucesso e a mensagem de sucesso ou erro
/*/
Static Function fMoveFile(cDirXml,cDirEmp,cFile) //Move o arquivo para a pasta desejada
Local cErroAuto := "" //Resultado do processamento

__CopyFile(cDirXml + cFile, cDirEmp + cFile) //Copia o arquivo para a pasta da empresa

If File(cDirEmp + cFile) //Achou o arquivo na pasta da empresa?
	FErase(cDirXml + cFile) //Apaga o arquivo no servidor
	If File(cDirXml + cFile) //Achou o arquivo no servidor?
		cErroAuto := "[GRAIMPCUP]ERRO: Problemas na exclusão do arquivo: " + cFile
		Return({.f.,cErroAuto})
	EndIf
Else
	cErroAuto := "[GRAIMPCUP]ERRO: Problemas na cópia do arquivo: "+cFile+" para a pasta: " + cDirEmp
	Return({.f.,cErroAuto})
EndIf

Return({.t.,cErroAuto})
//-----------------------------------------------------------------------------

/*/{Protheus.doc} fSoma1Item
Soma 1 no item com duas posições
@type function
@version P12
@author João Carlos da Silva
@since 03/10/2023
@param cItemDet, character, Item que veio no XML
@return character, Item com duas posições
/*/
Static Function fSoma1Item(cItemDet) //Soma 1 no item com duas posições
Local nPos  := 0
Local cItem := ""

If Val(cItemDet) <= 99
	cItem := StrZero(Val(cItemDet),2)
Else
	cItem := "99"
	For nPos := 1 to Val(cItemDet) - 99
		cItem := Soma1(cItem)
	Next
EndIf

Return(cItem)
//-----------------------------------------------------------------------------
