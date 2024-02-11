//Bibliotecas
#Include "Protheus.ch"
#Include "TopConn.ch"
#Include "RPTDef.ch"
#Include "FWPrintSetup.ch"

#DEFINE DEF_DEBUG   .t. //Verifica se é para debugar

//Variáveis utilizadas no fonte inteiro
Static nPadLeft   := 0                                                                     //Alinhamento a Esquerda
Static nPadRight  := 1                                                                     //Alinhamento a Direita
Static nPadCenter := 2                                                                     //Alinhamento Centralizado
Static nTamFundo  := 15                                                                    //Altura de fundo dos blocos com título
Static cEmpEmail  := Alltrim(SuperGetMV("MV_X_EMAIL", .F., "email@empresa.com.br"))        //Parâmetro com o e-Mail da empresa
Static nCorAzul   := RGB(062, 179, 206)                                                    //Cor Azul usada nos Títulos
Static cNomeFont  := "Arial"                                                               //Nome da Fonte Padrão
Static oFontDet   := Nil                                                                   //Fonte utilizada na impressão dos itens
Static oFontDetN  := Nil                                                                   //Fonte utilizada no cabeçalho dos itens
Static oFontRod   := Nil                                                                   //Fonte utilizada no rodapé da página
Static oFontTit   := Nil                                                                   //Fonte utilizada no Título das seções
Static oFontCab   := Nil                                                                   //Fonte utilizada na impressão dos textos dentro das seções
Static oFontCabN  := Nil                                                                   //Fonte negrita utilizada na impressão dos textos dentro das seções
Static oFontBlo   := Nil                                                                   //Fonte utilizada na impressão do bloco final
Static oFontBloN  := Nil                                                                   //Fonte utilizada na impressão do bloco final (em negrito)
Static cMaskPad   := "@E 999,999.99"                                                       //Máscara padrão de valor 
Static cMaskTel   := "@R (99) 99999999"                                                    //Máscara de telefone / fax
Static cMaskCNPJ  := "@R 99.999.999/9999-99"                                               //Máscara de CNPJ
Static cMaskCEP   := "@R 99999-999"                                                        //Máscara de CEP
Static cMaskCPF   := "@R 999.999.999-99"                                                   //Máscara de CPF
Static cMaskQtd   := PesqPict("SC7", "C7_QUANT")                                           //Máscara de quantidade
Static cMaskPrc   := PesqPict("SC7", "C7_PRECO")                                           //Máscara de preço
Static cMaskIPI   := PesqPict("SC7", "C7_IPI")                                             //Máscara de IPI
Static cMaskVlr   := PesqPict("SC7", "C7_TOTAL")                                           //Máscara de valor
Static cMaskVIcm  := PesqPict("SC7", "C7_VALICM")                                          //Máscara de Icms
Static cMaskVIpi  := PesqPict("SC7", "C7_VALIPI")                                          //Máscara de Ipi
Static cMaskFrete := PesqPict("SC7", "C7_VALFRE")                                          //Máscara de frete
Static cMaskBas   := PesqPict("SC7", "C7_BASEIPI")                                         //Máscara de base
Static aPos       := {}

/*/{Protheus.doc} GPKCOM02
Impressão gráfica genérica de Pedido de Compra (em pdf)
@type function
@version P12
@author Hitler Almeida
@since 06/01/2019
/*/
User Function GPKCOM02(cAlias,nReg,nOpc)
	Local aArea      := GetArea()
	Local aAreaC7    := SC7->(GetArea())
	Local aAreaA2    := SA2->(GetArea())
	Local aPergs     := {}
	Local aRetorn    := {}
	Local lContinua  := .t.

	Local lPergunte  := .t. //Informe os parâmetros
	Local lEnvEmail  := .t. //Envia o pedido para o e-mail do fornecedor
	Local lAuto      := .F.

	Default cAlias   := ""

	Do Case
	Case Upper(cAlias) == "SC7"      //Chamado pelo ponto de entrada MT120BRW
		lPergunte := .t.
	// Washington - 09/02/2024 - Trocar "Enviar" por "ENVIAR" 
	Case Upper(cAlias) == "ENVIAR"   //Chamado pelo ponto de entrada MT094END
		lPergunte := .f.
		lAuto     := .T.
	Otherwise                        //Chamado pelo menu específico
		lPergunte := .t.
	EndCase

	//Variáveis usadas nas outras funções
	Private cLogoEmp := fLogoEmp()
	Private cPedDe   := SC7->C7_NUM
	Private cPedAt   := SC7->C7_NUM
	Private cZeraPag := "1"

	If lPergunte //Informe os parâmetros
		//Adiciona os parametros para a pergunta
		aAdd(aPergs, {1, "Pedido De"                       , cPedDe       , "", ".T.", "SC7", ".T.", 080, .T.})
		aAdd(aPergs, {1, "Pedido Até"                      , cPedAt       , "", ".T.", "SC7", ".T.", 080, .T.})
		aAdd(aPergs, {2, "Zera a Página ao trocar Pedido"  , Val(cZeraPag), {"1=Sim","2=Não"}, 050, ".T.", .F.})
		aAdd(aPergs, {2, "Envia o pedido para o fornecedor", 2            , {"1=Sim","2=Não"}, 050, ".T.", .F.})

		//Se a pergunta for confirmada
		If ParamBox(aPergs, "Informe os parâmetros", @aRetorn, , , , , , , , .F., .F.)
			cPedDe    := aRetorn[1]
			cPedAt    := aRetorn[2]
			cZeraPag  := cValToChar(aRetorn[3])
			lEnvEmail := cValToChar(aRetorn[4]) == "1" //Envia o pedido para o e-mail do fornecedor
			lContinua := .t.
		Else
			lContinua := .f.
		EndIf
	EndIf

	If lContinua
		Processa( {|| fMontaRel(lEnvEmail,lAuto) }, "Impressão Pedidos de Compra", "Processando...")
	EndIf

	RestArea(aAreaA2)
	RestArea(aAreaC7)
	RestArea(aArea)
Return

/*/{Protheus.doc} fMontaRel
Função principal que monta o relatório
@type function
@version P12
@author Hitler Almeida
@since 06/01/2019
@param lEnvEmail, logical, Se envia e-mail para o fornecedor
/*/
Static Function fMontaRel(lEnvEmail,lAuto) //Envia o pedido para o e-mail do fornecedor
	//Variáveis usada no controle das réguas
	Local nTotIte    := 0
	Local nItAtu     := 0
	Local nTotPed    := 0
	Local nPedAtu    := 0

	//Consultas SQL
	Local cQryPed    := ""
	Local cQryIte    := ""

	//Variáveis do Relatório
	Local cNomeRel   := "pedido_compra_" + FunName() + "_" + RetCodUsr() + "_" + dToS(Date()) + "_" + StrTran(Time(), ":", "-")

	Local aSM0       := fSM0(cEmpAnt,cFilAnt) //Retorna os campos da SM0
	Local cHorReceb  := SuperGetMV("GP_COM02A", .F., "N/D") //Horário de Recebimento

	Local cTo        := ""
	Local cCC        := ""
	Local cSubject   := ""
	Local cBody      := ""
	Local aFile      := {}  //Arquivos a serem anexados
	Local lMsg       := .t. //Mostra a mensagem com sucesso ou erro

	Local cFile      := "" //Nome do arquivo Excel (.xml) a ser gerado (Ex.: \system\anexo.xml)

	Local cFilePrint := cNomeRel
	Local cDirServer := "\"
	Local nDevice    := IMP_PDF
	Local lAdjustToL := .f.
	Local cPathInSer := Nil
	Local lDisableSe := .t.
	Local lTReport   := Nil
//	Local oPrintSetu := Nil
	Local cPrinter   := Nil
	Local lServer    := .t.
	Local lPDFAsPNG  := Nil
	Local lRaw       := Nil
	Local lViewPDF   := .f.
	Local nQtdCopy   := Nil

	Private oPrintPvt
	Private cHoraEx     := Time()
	Private nPagAtu     := 1

	//Linhas e colunas
	Private nLinAtu     := 0
	Private nLinFin     := 780-210
	Private nColIni     := 010
	Private nColFin     := 550 + 250
	Private nColMeio    := (nColFin-nColIni)/2

	//Totalizadores
	Private nValorTot   := 0
	Private nTotIPI     := 0
	Private nTotICMS    := 0
	Private nTotPeso    := 0
	
	//Função que muda alinhamento e fontes
	fSetLayout()

	//Criando o objeto de impressão
	If lEnvEmail //Envia o pedido para o e-mail do fornecedor
		oPrintPvt := FWMsPrinter():New(cFilePrint,nDevice,lAdjustToL,cPathInSer,lDisableSe,lTReport,@oPrintPvt,cPrinter,lServer,lPDFAsPNG,lRaw,lViewPDF,nQtdCopy)
	Else
		oPrintPvt := FWMSPrinter():New(cNomeRel, IMP_PDF, .F., /*cStartPath*/, .T., , @oPrintPvt, , , , , .T.)
	EndIf
	oPrintPvt:cPathPDF := GetTempPath()
	oPrintPvt:SetResolution(72)
	oPrintPvt:SetLandscape()
	oPrintPvt:SetPaperSize(DMPAPER_A4)
	oPrintPvt:SetMargin(60, 60, 60, 60)

	//Selecionando os pedidos
	cQryPed := " SELECT "                                            + CRLF
	cQryPed += "    C7_NUM, "                                        + CRLF
	cQryPed += "    MIN(C7_EMISSAO) AS C7_EMISSAO, "                 + CRLF
	cQryPed += "    C7_TPFRETE, "                                    + CRLF
	cQryPed += "    C7_FORNECE, "                                    + CRLF
	cQryPed += "    C7_LOJA, "                                       + CRLF
	cQryPed += "    C7_COND, "                                       + CRLF
	cQryPed += "    ISNULL(E4_DESCRI, '') AS E4_DESCRI "             + CRLF
	cQryPed += " FROM "                                              + CRLF
	cQryPed += "    " + RetSQLName("SC7") + " SC7 "                  + CRLF
	cQryPed += "    LEFT JOIN " + RetSQLName("SA2") + " SA2 ON ( "   + CRLF
	cQryPed += "        A2_FILIAL   = '" + FWxFilial("SA2") + "' "   + CRLF
	cQryPed += "        AND A2_COD  = SC7.C7_FORNECE "               + CRLF
	cQryPed += "        AND A2_LOJA = SC7.C7_LOJA "                  + CRLF
	cQryPed += "        AND SA2.D_E_L_E_T_ = ' ' "                   + CRLF
	cQryPed += "    ) "                                              + CRLF
	cQryPed += "    LEFT JOIN " + RetSQLName("SE4") + " SE4 ON ( "   + CRLF
	cQryPed += "        E4_FILIAL     = '" + FWxFilial("SE4") + "' " + CRLF
	cQryPed += "        AND E4_CODIGO = SC7.C7_COND "                + CRLF
	cQryPed += "        AND SE4.D_E_L_E_T_ = ' ' "                   + CRLF
	cQryPed += "    ) "                                              + CRLF
	cQryPed += " WHERE "                                             + CRLF
	cQryPed += "    C7_FILIAL   = '" + FWxFilial("SC7") + "' "       + CRLF
	cQryPed += "    AND C7_NUM >= '" + cPedDe + "' "                 + CRLF
	cQryPed += "    AND C7_NUM <= '" + cPedAt + "' "                 + CRLF
	cQryPed += "    AND SC7.D_E_L_E_T_ = ' ' "                       + CRLF
	cQryPed += " GROUP BY "                                          + CRLF
	cQryPed += "    C7_NUM, "                                        + CRLF
	cQryPed += "    C7_TPFRETE, "                                    + CRLF
	cQryPed += "    C7_FORNECE, "                                    + CRLF
	cQryPed += "    C7_LOJA, "                                       + CRLF
	cQryPed += "    C7_COND, "                                       + CRLF
	cQryPed += "    E4_DESCRI "                                      + CRLF
	cQryPed += " ORDER BY "                                          + CRLF
	cQryPed += "    C7_NUM "                                         + CRLF
	TCQuery cQryPed New Alias "QRY_PED"
	TCSetField('QRY_PED', 'C7_EMISSAO', 'D')
	Count To nTotPed

	ProcRegua(nTotPed) // Numero de registros a processar
	
	//Somente se houver pedidos
	If nTotPed != 0
	
		//Enquanto houver pedidos
		QRY_PED->(DbGoTop())
		While ! QRY_PED->(EoF())
			IncProc()

			If cZeraPag == "1"
				nPagAtu := 1
			EndIf
			nPedAtu++

			//Posiciona no fornecedor
			DbSelectArea('SA2')
			SA2->(DbSetOrder(1))
			SA2->(DbSeek(FWxFilial('SA2') + QRY_PED->C7_FORNECE + QRY_PED->C7_LOJA))
			
			//Posiciona no pedido
			DbSelectArea('SC7')
			SC7->(DbSetOrder(1))
			SC7->(DbSeek(FWxFilial('SC7') + QRY_PED->C7_NUM))
			
			//Imprime o cabeçalho
			fImpCab(aSM0)
			
			//Seleciona agora os itens do pedido
			cQryIte := " SELECT "                                           + CRLF
			cQryIte += "    C7_PRODUTO, "                                   + CRLF
			cQryIte += "    C7_QUANT, "                                     + CRLF
			cQryIte += "    C7_PRECO, "                                     + CRLF
			cQryIte += "    C7_IPI, "                                       + CRLF
			cQryIte += "    C7_TOTAL, "                                     + CRLF
			cQryIte += "    C7_VALIPI, "                                    + CRLF
			cQryIte += "    C7_VALICM, "                                    + CRLF
			cQryIte += "    (B1_PESO * C7_QUANT) AS PESO, "                 + CRLF
			cQryIte += "    C7_DATPRF "                                     + CRLF
			cQryIte += "    ,C7_BASEICM "                                   + CRLF
			cQryIte += "    ,C7_BASEIPI "                                   + CRLF
			cQryIte += "    ,C7_PICM "                                      + CRLF

			cQryIte += "    ,0 C7_BASIST "                                  + CRLF
			cQryIte += "    ,0 C7_ALIIST "                                  + CRLF
			cQryIte += "    ,C7_ICMSRET C7_VLRIST "                         + CRLF

			cQryIte += "    ,C7_ITEM "                                      + CRLF
			cQryIte += "    ,C7_UM "                                        + CRLF
			cQryIte += "    ,C7_DESCRI"                                     + CRLF
			cQryIte += "    ,ISNULL(CONVERT(VARCHAR(8000),CONVERT(BINARY(8000),C7_OBSM)),'') AS C7_OBSM " + CRLF
			cQryIte += "    ,B5_CEME "                                      + CRLF
			cQryIte += " FROM "                                             + CRLF
			cQryIte += "    " + RetSQLName("SC7") + " SC7 "                 + CRLF
			cQryIte += "    LEFT  JOIN " + RetSQLName("SB1") + " SB1 ON ( " + CRLF
			cQryIte += "        B1_FILIAL = '" + FWxFilial("SB1") + "' "    + CRLF
			cQryIte += "        AND B1_COD = SC7.C7_PRODUTO "               + CRLF
			cQryIte += "        AND SB1.D_E_L_E_T_ = ' ' "                  + CRLF
			cQryIte += "    ) "                                             + CRLF
			cQryIte += "    LEFT  JOIN " + RetSQLName("SB5") + " SB5 ON ( " + CRLF
			cQryIte += "        B5_FILIAL = '" + FWxFilial("SB5") + "' "    + CRLF
			cQryIte += "        AND B5_COD = SC7.C7_PRODUTO "               + CRLF
			cQryIte += "        AND SB5.D_E_L_E_T_ = ' ' "                  + CRLF
			cQryIte += "    ) "                                             + CRLF
			cQryIte += "    LEFT JOIN " + RetSQLName("SA5") + " SA5 ON ( "  + CRLF
			cQryIte += "        A5_FILIAL = '" + FWxFilial("SA5") + "' "    + CRLF
			cQryIte += "        AND A5_PRODUTO = SC7.C7_PRODUTO "           + CRLF
			cQryIte += "        AND A5_FORNECE = SC7.C7_FORNECE "           + CRLF
			cQryIte += "        AND A5_LOJA = SC7.C7_LOJA "                 + CRLF
			cQryIte += "        AND SA5.D_E_L_E_T_ = ' ' "                  + CRLF
			cQryIte += "    ) "                                             + CRLF
			cQryIte += " WHERE "                                            + CRLF
			cQryIte += "    C7_FILIAL = '" + FWxFilial("SC7") + "' "        + CRLF
			cQryIte += "    AND C7_NUM = '" + QRY_PED->C7_NUM + "' "        + CRLF
			cQryIte += "    AND SC7.D_E_L_E_T_ = ' ' "                      + CRLF
			cQryIte += " ORDER BY "                                         + CRLF
			cQryIte += "    C7_ITEM "                                       + CRLF
			TCQuery cQryIte New Alias "QRY_ITE"
			TCSetField("QRY_ITE", "C7_DATPRF", "D")
			Count To nTotIte
			nValorTot := 0
			nTotIPI   := 0
			nTotICMS  := 0
			nTotPeso  := 0

			nItAtu := 0
			QRY_ITE->(DbGoTop())
			While ! QRY_ITE->(EoF())
				nLinAtu += 7

				nItAtu++

				nValorTot += QRY_ITE->C7_TOTAL
				nTotIPI   += QRY_ITE->C7_VALIPI
				nTotICMS  += QRY_ITE->C7_VALICM
				nTotPeso  += QRY_ITE->PESO
				
				//Imprime preço com 04 casas decimais
				cMaskPrc := StrTran(cMaskPrc,".99999999",".9999")
				cMaskPrc := StrTran(cMaskPrc,".9999999" ,".9999")
				cMaskPrc := StrTran(cMaskPrc,".999999"  ,".9999")
				cMaskPrc := StrTran(cMaskPrc,".99999"   ,".9999")

				oPrintPvt:SayAlign(nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="ItePro"}),2], QRY_ITE->C7_ITEM   ,                               oFontDet, 040, 07, , nPadLeft, )
				oPrintPvt:SayAlign(nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="CodPro"}),2], QRY_ITE->C7_PRODUTO,                               oFontDet, 040, 07, , nPadLeft, )

				nLinAtu := fImpTexto("1", aSM0, oPrintPvt, nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="DesPro"}),2], QRY_ITE->C7_DESCRI ,                               oFontDet, 450, 07, , nPadLeft, )

				oPrintPvt:SayAlign(nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="UniMed"}),2], QRY_ITE->C7_UM     ,                               oFontDet, 040, 07, , nPadRight, )
				oPrintPvt:SayAlign(nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="QtdPro"}),2], Alltrim(Transform(QRY_ITE->C7_QUANT, cMaskQtd)),   oFontDet, 040, 07, , nPadRight, )
				oPrintPvt:SayAlign(nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="VlrUni"}),2], Alltrim(Transform(QRY_ITE->C7_PRECO, cMaskPrc)),   oFontDet, 040, 07, , nPadRight, )
				oPrintPvt:SayAlign(nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="VlrTot"}),2], Alltrim(Transform(QRY_ITE->C7_TOTAL, cMaskVlr)),   oFontDet, 040, 07, , nPadRight, )

				oPrintPvt:SayAlign(nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="BasIcm"}),2], Alltrim(Transform(QRY_ITE->C7_BASEICM,cMaskBas)),  oFontDet, 040, 07, , nPadRight, )
				oPrintPvt:SayAlign(nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="AliIcm"}),2], Alltrim(Transform(QRY_ITE->C7_PICM   ,cMaskIPI)),  oFontDet, 040, 07, , nPadRight, )
				oPrintPvt:SayAlign(nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="VlrIcm"}),2], Alltrim(Transform(QRY_ITE->C7_VALICM ,cMaskVIcm)), oFontDet, 040, 07, , nPadRight, )

				oPrintPvt:SayAlign(nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="BasIst"}),2], Alltrim(Transform(QRY_ITE->C7_BASIST ,cMaskBas)),  oFontDet, 040, 07, , nPadRight, )
				oPrintPvt:SayAlign(nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="AliIst"}),2], Alltrim(Transform(QRY_ITE->C7_ALIIST ,cMaskIPI)),  oFontDet, 040, 07, , nPadRight, )
				oPrintPvt:SayAlign(nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="VlrIst"}),2], Alltrim(Transform(QRY_ITE->C7_VLRIST ,cMaskVIcm)), oFontDet, 040, 07, , nPadRight, )

				oPrintPvt:SayAlign(nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="BasIpi"}),2], Alltrim(Transform(QRY_ITE->C7_BASEIPI,cMaskBas)),  oFontDet, 040, 07, , nPadRight, )
				oPrintPvt:SayAlign(nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="AliIpi"}),2], Alltrim(Transform(QRY_ITE->C7_IPI    ,cMaskIPI)),  oFontDet, 040, 07, , nPadRight, )
				oPrintPvt:SayAlign(nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="VlrIpi"}),2], Alltrim(Transform(QRY_ITE->C7_VALIPI ,cMaskVIpi)), oFontDet, 040, 07, , nPadRight, )

				oPrintPvt:SayAlign(nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="DatEnt"}),2], dToC(QRY_ITE->C7_DATPRF),                          oFontDet, 040, 07, , nPadRight, )

				nLinAtu += 7
				nLinAtu := fImpTexto("2", aSM0, oPrintPvt, nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="DesPro"}),2], QRY_ITE->C7_DESCRI ,                               oFontDet, 450, 07, , nPadLeft, )

				If !Empty(QRY_ITE->C7_OBSM)
					nLinAtu += 7
					nLinAtu := fImpTexto("3", aSM0, oPrintPvt, nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="DesPro"}),2], Alltrim(QRY_ITE->C7_OBSM),                     oFontDet, 1000, 07, , nPadLeft, )
				EndIf

				// Washington 09/02/2024 - Tratamento 
				If !Empty(QRY_ITE->B5_CEME)
					nLinAtu += 7
					nLinAtu := fImpTexto("3", aSM0, oPrintPvt, nLinAtu, aPos[Ascan(aPos,{|x|x[1]=="DesPro"}),2], Alltrim(QRY_ITE->B5_CEME), oFontDet, 1000, 07, , nPadLeft, )
				EndIf

				nLinAtu += 7
				oPrintPvt:Line(nLinAtu + 1, nColIni, nLinAtu + 1, nColFin, RGB(200, 200, 200))

				//Se por acaso atingiu o limite da página, finaliza, e começa uma nova página
				If nLinAtu >= nLinFin
					fImpRod()
					fImpCab(aSM0)
				EndIf
				
				QRY_ITE->(DbSkip())
			EndDo
			QRY_ITE->(DbCloseArea())
			
			//Impressão do bloco final do pedido
			fImpBloco(aSM0,cHorReceb)
			
			//Imprime o rodapé
			fImpRod()
			
			QRY_PED->(DbSkip())
		EndDo
		
		//Gera o pdf para visualização
		oPrintPvt:Preview()

		If lEnvEmail //Envia o pedido para o e-mail do fornecedor
			If !Empty(SA2->A2_EMAIL)
				CpyT2S(GetTempPath() + cNomeRel + ".pdf",cDirServer,.f.) //Copia o arquivo para o servidor
				cFile := cDirServer + cNomeRel + ".pdf" //Arquivo para ser enviado como anexo

				If !File(cFile)
					ConOut("ERRO: Problemas ao copiar o arquivo " + cNomeRel + ".pdf" + " para o servidor.")
				Else
					cTo      := Lower(AllTrim(SA2->A2_EMAIL))
					cCC      := ""
					cSubject := "Pedido de Compra: " + SC7->C7_NUM
					cBody    := "Pedido de Compra: " + SC7->C7_NUM
					aFile    := {cFile}      //Arquivos a serem anexados
					lMsg     := .t.          //Mostra a mensagem com sucesso ou erro
					// Washington - 09/02/2024 - Inclusão do tratamento da variavel lAuto
					If lAuto .Or. MsgYesNo("Confirma o envio do pedido de compra para o e-mail: "+cTo+" ??")
						U_GPKMAIL(cTo,cCC,cSubject,cBody,aFile,lMsg,DEF_DEBUG) //Envia e-mail
					EndIf
					FERASE(cFile) //Apaga o arquivo enviado como anexo
				EndIf

			EndIf
		EndIf

	Else
		MsgStop("Não há pedidos!", "Atenção")
	EndIf
	QRY_PED->(DbCloseArea())
Return

/*/{Protheus.doc} fImpCab
Função que imprime o cabeçalho
@type function
@version P12
@author Hitler Almeida
@since 06/01/2019
@param aSM0, array, Array com os campos da SM0
/*/
Static Function fImpCab(aSM0)
	Local nLinCab    := 025+010
	Local nLinCabOri := nLinCab
	Local lCNPJ      := Len(Alltrim(SA2->A2_CGC)) > 11
	Local cForAux    := QRY_PED->C7_FORNECE + "/" + QRY_PED->C7_LOJA + " - " + SA2->A2_NOME
	Local cCGC       := ""

	//Dados da empresa
	Local cEmpresa   := AllTrim(cFilAnt) + " - " + Iif(Empty(fTrazSM0(aSM0,"M0_NOMECOM")), Alltrim(fTrazSM0(aSM0,"M0_NOME")), Alltrim(fTrazSM0(aSM0,"M0_NOMECOM")))
	Local cEmpEnd	 := Alltrim(fTrazSM0(aSM0,"M0_ENDENT")) 
	Local cEmpTel    := Alltrim(fTrazSM0(aSM0,"M0_TEL"))
	Local cEmpCidade := AllTrim(fTrazSM0(aSM0,"M0_CIDENT")) + " / " + fTrazSM0(aSM0,"M0_ESTENT")
	Local cEmpCnpj   := Alltrim(Transform(fTrazSM0(aSM0,"M0_CGC"), cMaskCNPJ))
	Local cEmpCep    := Alltrim(Transform(fTrazSM0(aSM0,"M0_CEPENT"), cMaskCEP))

	Local aComprador := fComprador(SC7->C7_USER)
	Local cComprador := Alltrim(aComprador[1]) + "-" + Alltrim(aComprador[2]) + " - Telefone: " + Alltrim(aComprador[3])
	Local cEmailComp := Alltrim(aComprador[4])
	Local cMunEst    := Alltrim(SA2->A2_MUN) + " / " + SA2->A2_EST + " - Bairro: " + SA2->A2_BAIRRO
	Local cDDDTel    := "(" + SA2->A2_DDD + ") " + SA2->A2_TEL

	Local nCol1      := 0 //Posição do label
	Local nCol2      := 0 //Posição do texto
	Local nCol3      := 0 //Posição do label parte 2
	Local nCol4      := 0 //Posição do texto parte 2

	cCGC := SA2->A2_CGC
	If lCNPJ
		cCGC := Iif(!Empty(cCGC), Alltrim(Transform(cCGC, cMaskCNPJ)), "-")
	Else
		cCGC := Iif(!Empty(cCGC), Alltrim(Transform(cCGC, cMaskCPF)), "-")
	EndIf

	//Iniciando Página
	oPrintPvt:StartPage()
	
	//Dados da Empresa
	oPrintPvt:Box(nLinCab, nColIni, nLinCab + 082, nColMeio - 3)
	oPrintPvt:Line(nLinCab + nTamFundo, nColIni, nLinCab + nTamFundo, nColMeio - 3)
	nLinCab += nTamFundo - 5
	nLinCab := nLinCab - 10
	oPrintPvt:SayAlign(nLinCab, nColIni + 005, "Comprador:"     , oFontTit , 060, nTamFundo, nCorAzul, nPadLeft, )
	nLinCab += 18
	oPrintPvt:SayBitmap(nLinCab, nColIni + 005, cLogoEmp, 081, 054)
	nLinCab -= 3

	nCol1 := 093 //Posição do label
	nCol2 := 143 //Posição do texto
	nCol3 := 000 //Posição do label parte 2
	nCol4 := 000 //Posição do texto parte 2

	oPrintPvt:SayAlign(nLinCab, nColIni + nCol1, "Empresa:"     , oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColIni + nCol2, cEmpresa       , oFontCab,  200, 07, , nPadLeft, )
	nLinCab += 7
	oPrintPvt:SayAlign(nLinCab, nColIni + nCol1, "CNPJ:"        , oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColIni + nCol2, cEmpCnpj       , oFontCab,  200, 07, , nPadLeft, )
	nLinCab += 7
	oPrintPvt:SayAlign(nLinCab, nColIni + nCol1, "Endereço:"    , oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColIni + nCol2, cEmpEnd        , oFontCab,  200, 07, , nPadLeft, )
	nLinCab += 7
	oPrintPvt:SayAlign(nLinCab, nColIni + nCol1, "Cidade:"      , oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColIni + nCol2, cEmpCidade     , oFontCab,  200, 07, , nPadLeft, )
	nLinCab += 7
	oPrintPvt:SayAlign(nLinCab, nColIni + nCol1, "CEP:"         , oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColIni + nCol2, cEmpCep        , oFontCab,  200, 07, , nPadLeft, )
	nLinCab += 7
	oPrintPvt:SayAlign(nLinCab, nColIni + nCol1, "Telefone:"    , oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColIni + nCol2, cEmpTel        , oFontCab,  200, 07, , nPadLeft, )
	nLinCab += 7
	oPrintPvt:SayAlign(nLinCab, nColIni + nCol1, "E-Mail Empr.:", oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColIni + nCol2, cEmpEmail      , oFontCab,  200, 07, , nPadLeft, )
	nLinCab += 7
	oPrintPvt:SayAlign(nLinCab, nColIni + nCol1, "Comprador:"   , oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColIni + nCol2, cComprador     , oFontCab,  200, 07, , nPadLeft, )
	nLinCab += 7
	oPrintPvt:SayAlign(nLinCab, nColIni + nCol1, "E-Mail Comp.:", oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColIni + nCol2, cEmailComp     , oFontCab,  200, 07, , nPadLeft, )
	nLinCab += 7

	nCol1 := 008 //Posição do label
	nCol2 := 050 //Posição do texto
	nCol3 := 200 //Posição do label parte 2
	nCol4 := 242 //Posição do texto parte 2

	//Dados do Pedido
	nLinCab := nLinCabOri
	oPrintPvt:Box(nLinCab, nColMeio + 003, nLinCab + 082, nColFin)
	oPrintPvt:Line(nLinCab + nTamFundo, nColMeio + 003, nLinCab + nTamFundo, nColFin)
	nLinCab += nTamFundo - 5

	nLinCab := nLinCab - 10
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol1, "Pedido:"                , oFontTit,  060, nTamFundo, nCorAzul, nPadLeft, )
	nLinCab += 15

	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol1, "Núm.Pedido:"            , oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol2, QRY_PED->C7_NUM          , oFontCab , 100, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol3, "Dt.Emissão:"            , oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol4, dToC(QRY_PED->C7_EMISSAO), oFontCab , 100, 07, , nPadLeft, )
	nLinCab += 7
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol1, "Fornecedor:"            , oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol2, cForAux                  , oFontCab , 200, 07, , nPadLeft, )
	nLinCab += 7
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol1, If(lCNPJ,"CNPJ:","CPF:") , oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol2, cCGC                     , oFontCab , 200, 07, , nPadLeft, )
	nLinCab += 7
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol1, "Ins.Estadual:"          , oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol2, Alltrim(SA2->A2_INSCR)   , oFontCab , 100, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol3, "Ins.Municipal:"         , oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol4, Alltrim(SA2->A2_INSCRM)  , oFontCab , 100, 07, , nPadLeft, )
	nLinCab += 7	
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol1, "A/C:"                   , oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol2, SA2->A2_CONTATO          , oFontCab,  200, 07, , nPadLeft, )
	nLinCab += 7
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol1, "Endereço:"              , oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol2, Alltrim(SA2->A2_END)     , oFontCab , 200, 07, , nPadLeft, )
	nLinCab += 7
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol1, "Cidade:"                , oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol2, cMunEst                  , oFontCab , 200, 07, , nPadLeft, )
	nLinCab += 7
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol1, "CEP:"                   , oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol2, SA2->A2_CEP              , oFontCab,  200, 07, , nPadLeft, )
	nLinCab += 7
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol1, "Telefone:"              , oFontCabN, 060, 07, , nPadLeft, )
	oPrintPvt:SayAlign(nLinCab, nColMeio + nCol2, cDDDTel                  , oFontCab,  200, 07, , nPadLeft, )
	nLinCab += 7
	
	//Título
	nLinCab := nLinCabOri + 080+007
	oPrintPvt:Box(nLinCab, nColIni, nLinCab + nTamFundo, nColFin)
	nLinCab += nTamFundo - 5
	oPrintPvt:SayAlign(nLinCab-10, nColIni, "Relação de Produtos", oFontTit, nColFin-nColIni, nTamFundo, nCorAzul, nPadCenter, )
	
	//Linha Separatório
	nLinCab += 6
	
	nLinCab += 3
	oPrintPvt:SayAlign(nLinCab, aPos[Ascan(aPos,{|x|x[1]=="ItePro"}),2] , "Item"         , oFontDetN, 035, 07, , nPadLeft , )
	oPrintPvt:SayAlign(nLinCab, aPos[Ascan(aPos,{|x|x[1]=="CodPro"}),2] , "Cód.Prod."    , oFontDetN, 035, 07, , nPadLeft , )
	oPrintPvt:SayAlign(nLinCab, aPos[Ascan(aPos,{|x|x[1]=="DesPro"}),2] , "Descrição/Obs", oFontDetN, 200, 07, , nPadLeft , )
	oPrintPvt:SayAlign(nLinCab, aPos[Ascan(aPos,{|x|x[1]=="QtdPro"}),2] , "Qtde"         , oFontDetN, 040, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinCab, aPos[Ascan(aPos,{|x|x[1]=="UniMed"}),2] , "UM"           , oFontDetN, 040, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinCab, aPos[Ascan(aPos,{|x|x[1]=="VlrUni"}),2] , "Vlr.Uni."     , oFontDetN, 040, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinCab, aPos[Ascan(aPos,{|x|x[1]=="VlrTot"}),2] , "Vlr.Tot."     , oFontDetN, 040, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinCab, aPos[Ascan(aPos,{|x|x[1]=="BasIcm"}),2] , "Base ICMS"    , oFontDetN, 040, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinCab, aPos[Ascan(aPos,{|x|x[1]=="AliIcm"}),2] , "Aliq.ICMS"    , oFontDetN, 040, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinCab, aPos[Ascan(aPos,{|x|x[1]=="VlrIcm"}),2] , "Vlr.ICMS"     , oFontDetN, 040, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinCab, aPos[Ascan(aPos,{|x|x[1]=="BasIst"}),2] , "B.ICMS-ST"    , oFontDetN, 040, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinCab, aPos[Ascan(aPos,{|x|x[1]=="AliIst"}),2] , "A.ICMS-ST"    , oFontDetN, 040, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinCab, aPos[Ascan(aPos,{|x|x[1]=="VlrIst"}),2] , "V.ICMS-ST"    , oFontDetN, 040, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinCab, aPos[Ascan(aPos,{|x|x[1]=="BasIpi"}),2] , "Base IPI"     , oFontDetN, 040, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinCab, aPos[Ascan(aPos,{|x|x[1]=="AliIpi"}),2] , "Aliq.IPI"     , oFontDetN, 040, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinCab, aPos[Ascan(aPos,{|x|x[1]=="VlrIpi"}),2] , "Vlr.IPI"      , oFontDetN, 040, 07, , nPadRight, )
	oPrintPvt:SayAlign(nLinCab, aPos[Ascan(aPos,{|x|x[1]=="DatEnt"}),2] , "Entrega"      , oFontDetN, 040, 07, , nPadRight, )

	//Atualizando a linha inicial do relatório
	nLinAtu := nLinCab + 1
Return

/*/{Protheus.doc} fImpRod
Função que imprime o rodapé
@type function
@version P12
@author Hitler Almeida
@since 06/01/2019
/*/
Static Function fImpRod()
	Local nLinRod:= nLinFin + 10
	Local cTexto := ""

	//Linha Separatória
	oPrintPvt:Line(nLinRod, nColIni, nLinRod, nColFin)
	nLinRod += 3
	
	//Dados da Esquerda
	cTexto := "Pedido: " + QRY_PED->C7_NUM + "    |    " + dToC(Date()) + "     " + cHoraEx + "     " + FunName() + "     " + UsrRetName(RetCodUsr())
	oPrintPvt:SayAlign(nLinRod, nColIni,    cTexto, oFontRod, 250, 07, , nPadLeft, )
	
	//Direita
	cTexto := "Página " + cValToChar(nPagAtu)
	oPrintPvt:SayAlign(nLinRod, nColFin-40, cTexto, oFontRod, 040, 07, , nPadRight, )
	
	//Finalizando a página e somando mais um
	oPrintPvt:EndPage()
	nPagAtu++
Return

/*/{Protheus.doc} fLogoEmp
Função que retorna o logo da empresa (igual a DANFE)
@type function
@version P12
@author Hitler Almeida
@since 06/01/2019
@return image, Logo da empresa
/*/
Static Function fLogoEmp()
	Local cCamFim     := GetTempPath()
	Local cStart      := GetSrvProfString("Startpath", "")
	Local cLogo       := cStart + "lgrl" + cEmpAnt + cFilAnt + ".BMP"

	//Copia para a temporária do s.o.
	CpyS2T(cLogo, cCamFim)
	cLogo := cCamFim + StrTran(cLogo, cStart, "")
	
	//Se o arquivo não existir na temporária, espera meio segundo para terminar a cópia
	If !File(cLogo)
		Sleep(500)
	EndIf
Return cLogo

/*/{Protheus.doc} fSetLayout
Função que muda as variáveis das colunas do layout
@type function
@version P12
@author Hitler Almeida
@since 06/01/2019
/*/
Static Function fSetLayout()
Local nColFin2 := 800

	//Definindo os alinhamentos
	AAdd(aPos,{"ItePro",0010           })
	AAdd(aPos,{"CodPro",0030           })
	AAdd(aPos,{"DesPro",0080           })
	AAdd(aPos,{"QtdPro",nColFin2 - 0560})
	AAdd(aPos,{"UniMed",nColFin2 - 0520})
	AAdd(aPos,{"VlrUni",nColFin2 - 0480})
	AAdd(aPos,{"VlrTot",nColFin2 - 0440})
	AAdd(aPos,{"BasIcm",nColFin2 - 0400})
	AAdd(aPos,{"AliIcm",nColFin2 - 0360})
	AAdd(aPos,{"VlrIcm",nColFin2 - 0320})
	AAdd(aPos,{"BasIst",nColFin2 - 0280})
	AAdd(aPos,{"AliIst",nColFin2 - 0240})
	AAdd(aPos,{"VlrIst",nColFin2 - 0200})
	AAdd(aPos,{"BasIpi",nColFin2 - 0160})
	AAdd(aPos,{"AliIpi",nColFin2 - 0120})
	AAdd(aPos,{"VlrIpi",nColFin2 - 0080})
	AAdd(aPos,{"DatEnt",nColFin2 - 0040})

	//Definindo as fontes
	oFontRod   := TFont():New(cNomeFont, , -06, , .F.)
	oFontTit   := TFont():New(cNomeFont, , -13, , .T.)
	oFontCab   := TFont():New(cNomeFont, , -07, , .F.)
	oFontCabN  := TFont():New(cNomeFont, , -07, , .T.)
	oFontDet   := TFont():New(cNomeFont, , -07, , .F.)
	oFontDetN  := TFont():New(cNomeFont, , -07, , .T.)
	oFontBlo   := TFont():New(cNomeFont, , -10, , .F.)
	oFontBloN  := TFont():New(cNomeFont, , -10, , .T.)
Return

/*/{Protheus.doc} fImpBloco
Função que imprime o bloco final do relatório
@type function
@version P12
@author Hitler Almeida
@since 06/01/2019
@param aSM0, array, Array com os campos da SM0
/*/
Static Function fImpBloco(aSM0,cHorReceb)
	Local nLinBloco  := nLinAtu + 20
	Local cTextoDesc := ""
	Local nTotDesc   := SC7->C7_DESC1 + SC7->C7_DESC2 + SC7->C7_DESC3
	Local nTotGeral  := (nValorTot - nTotDesc) + nTotIPI
	Local nTamBloco  := 175 //Tamanho do bloco de Resumo e Totais
	Local cFretePed  := ""

	Local nObs       := 0
	Local aObs       := fObs(cHorReceb) //Monta as observações do pedido
	Local nLinEnt    := nLinBloco + nTamBloco //Linha do Local de Entrega
	Local nTamEnt    := 118 //Tamanho do bloco do Local de Entrega

	Local nLinBlocoF := 0 //Início do bloco do frete

	//Se o bloco for passar do limite da página, faz uma quebra
	If nLinBloco + nTamBloco + nTamEnt >= nLinFin
		fImpRod()
		fImpCab(aSM0)
		nLinBloco := nLinAtu
		nLinEnt   := nLinBloco + nTamBloco //Linha do Local de Entrega
	EndIf
	
	//Definindo o tipo de Frete
	If QRY_PED->C7_TPFRETE == "C"
		cFretePed := "CIF"
	ElseIf QRY_PED->C7_TPFRETE == "F"
		cFretePed := "FOB"
	ElseIf QRY_PED->C7_TPFRETE == "T"
		cFretePed := "Terceiros"
	Else
		cFretePed := "Sem Frete"
	EndIf

	oPrintPvt:Box(nLinBloco, nColIni, nLinBloco + nTamBloco, nColFin)

	//Título do Bloco
	oPrintPvt:Line(nLinBloco + nTamFundo, nColIni, nLinBloco + nTamFundo, nColFin)
	nLinBloco += nTamFundo - 5
	nLinBloco := nLinBloco - 10
	oPrintPvt:SayAlign(nLinBloco, nColIni + 000, "Resumo e Totais", oFontTit, nColFin-nColIni, nTamFundo, nCorAzul, nPadCenter, )
	nLinBloco += 15

	//Imprimindo Desconto
	cTextoDesc := Alltrim(Transform(SC7->C7_DESC1, "@E 99.99")) + "     +     "
	cTextoDesc += Alltrim(Transform(SC7->C7_DESC2, "@E 99.99")) + "     +     "
	cTextoDesc += Alltrim(Transform(SC7->C7_DESC3, "@E 99.99")) + "     =     "
	cTextoDesc += Alltrim(Transform(nTotDesc,"@E 999.99"))

	oPrintPvt:SayAlign(nLinBloco, nColIni + 005, "Desconto Especial (%):", oFontBlo , 100, 08, , nPadLeft, )
	oPrintPvt:SayAlign(nLinBloco, nColIni + 105, cTextoDesc              , oFontBloN, 200, 08, , nPadLeft, )
	nLinBloco += 10
	
	oPrintPvt:Line(nLinBloco + 1, nColIni, nLinBloco + 1, nColFin, )
	nLinBloco += 2

	//Imprimindo informações auxiliares
	oPrintPvt:SayAlign(nLinBloco, nColIni + 005, "Condição de Pagamento:"                          , oFontBlo , 100, 08, , nPadLeft, )
	oPrintPvt:SayAlign(nLinBloco, nColIni + 220, "Total das Mercadorias:"                          , oFontBlo , 100, 08, , nPadRight,)
	oPrintPvt:SayAlign(nLinBloco, nColIni + 335, "Moeda:"                                          , oFontBlo , 060, 08, , nPadLeft, )
	nLinBloco += 10
	oPrintPvt:SayAlign(nLinBloco, nColIni + 005, QRY_PED->C7_COND + " - " + QRY_PED->E4_DESCRI     , oFontBloN, 300, 08, , nPadLeft, )
	oPrintPvt:SayAlign(nLinBloco, nColIni + 220, Alltrim(Transform(nValorTot - nTotDesc, cMaskVlr)), oFontBloN, 100, 08, , nPadRight,)
	oPrintPvt:SayAlign(nLinBloco, nColIni + 335, fMaskMoeda(SC7->C7_MOEDA)                         , oFontBloN, 060, 08, , nPadLeft, )
	nLinBloco += 10
	
	oPrintPvt:Line(nLinBloco - 21, nColIni + 230, nLinBloco + 1, nColIni + 230, )
	oPrintPvt:Line(nLinBloco - 21, nColIni + 330, nLinBloco + 1, nColIni + 330, )
	oPrintPvt:Line(nLinBloco - 21, nColIni + 380, nLinBloco + 1, nColIni + 380, )
	oPrintPvt:Line(nLinBloco + 01, nColIni + 000, nLinBloco + 1, nColFin + 000, )
	nLinBloco += 2
	
	//Observações
	oPrintPvt:SayAlign(nLinBloco, nColIni + 005, "Observações:"                                   , oFontBlo , 100, 08, , nPadLeft, )
	For nObs := 1 to Len(aObs)
		nLinBloco += 10
		oPrintPvt:SayAlign(nLinBloco, nColIni + 005, aObs[nObs,1], oFontDet, 010, 08, , nPadLeft, ) //oFontBloN
		oPrintPvt:SayAlign(nLinBloco, nColIni + 015, aObs[nObs,2], oFontDet, 790, 08, , nPadLeft, ) //oFontDet
	Next
	nLinBloco := nLinEnt //Linha do Local de Entrega

	nLinBloco += 10
	oPrintPvt:Line(nLinBloco + 1, nColIni, nLinBloco + 1, nColFin, )
	nLinBloco += 2
	
	//Local de Entrega
	oPrintPvt:SayAlign(nLinBloco, nColIni + 005, "Local de Entrega:",                                oFontBlo,  100, 08, , nPadLeft, )
	nLinBloco += 10
	oPrintPvt:SayAlign(nLinBloco, nColIni + 005, "Endereço: " + fTrazSM0(aSM0,"M0_ENDENT"),                      oFontBloN,  200, 08, , nPadLeft, )
	nLinBloco += 10
	oPrintPvt:SayAlign(nLinBloco, nColIni + 005, "Bairro: " + fTrazSM0(aSM0,"M0_BAIRENT"),                       oFontBloN,  200, 08, , nPadLeft, )
	nLinBloco += 10
	oPrintPvt:SayAlign(nLinBloco, nColIni + 005, "CEP: " + fTrazSM0(aSM0,"M0_CEPENT"),                           oFontBloN,  200, 08, , nPadLeft, )
	nLinBloco += 10
	oPrintPvt:SayAlign(nLinBloco, nColIni + 005, Alltrim(fTrazSM0(aSM0,"M0_CIDENT")) + " / " + fTrazSM0(aSM0,"M0_ESTENT"),   oFontBloN,  200, 08, , nPadLeft, )
	nLinBloco += 10

	oPrintPvt:Line(nLinBloco - 051, nColMeio, nLinBloco + 1, nColMeio, )
	oPrintPvt:Line(nLinBloco + 001, nColIni , nLinBloco + 1, nColFin , )
	nLinBloco += 2

	nLinBlocoF := nLinBloco //Início do bloco do frete

	//Totais e Outras Informações
	nLinBloco := nLinBlocoF //Início do bloco do frete
	oPrintPvt:SayAlign(nLinBloco, nColIni + 005, "Tp. Frete:"                                  , oFontBlo,  100, 08, , nPadLeft, )
	oPrintPvt:SayAlign(nLinBloco, nColIni + 055, cFretePed                                     , oFontBloN, 100, 08, , nPadLeft, )
	nLinBloco += 10
	oPrintPvt:SayAlign(nLinBloco, nColIni + 005, "IPI:"                                        , oFontBlo,  100, 08, , nPadLeft, )
	oPrintPvt:SayAlign(nLinBloco, nColIni + 055, Alltrim(Transform(nTotIPI, cMaskVlr))         , oFontBloN, 100, 08, , nPadLeft, )
	nLinBloco += 10
	oPrintPvt:SayAlign(nLinBloco, nColIni + 005, "Seguro:"                                     , oFontBlo,  100, 08, , nPadLeft, )
	oPrintPvt:SayAlign(nLinBloco, nColIni + 055, Alltrim(Transform(SC7->C7_SEGURO, cMaskVlr))  , oFontBloN, 100, 08, , nPadLeft, )
	nLinBloco += 10
	oPrintPvt:SayAlign(nLinBloco, nColIni + 005, "Reajuste:"                                   , oFontBlo,  100, 08, , nPadLeft, )
	oPrintPvt:SayAlign(nLinBloco, nColIni + 055, SC7->C7_REAJUST                               , oFontBloN, 100, 08, , nPadLeft, )
	nLinBloco += 10

	nLinBloco := nLinBlocoF //Início do bloco do frete
	oPrintPvt:SayAlign(nLinBloco, nColMeio+ 005, "Frete:"                                      , oFontBlo,  100, 08, , nPadLeft, )
	oPrintPvt:SayAlign(nLinBloco, nColMeio+ 055, Alltrim(Transform(SC7->C7_VALFRE, cMaskFrete)), oFontBloN, 100, 08, , nPadLeft, )
	nLinBloco += 10
	oPrintPvt:SayAlign(nLinBloco, nColMeio+ 005, "ICMS:"                                       , oFontBlo,  100, 08, , nPadLeft, )
	oPrintPvt:SayAlign(nLinBloco, nColMeio+ 055, Alltrim(Transform(nTotICMS, cMaskVlr))        , oFontBloN, 100, 08, , nPadLeft, )
	nLinBloco += 10
	oPrintPvt:SayAlign(nLinBloco, nColMeio+ 005, "Despesas:"                                   , oFontBlo,  100, 08, , nPadLeft, )
	oPrintPvt:SayAlign(nLinBloco, nColMeio+ 055, Alltrim(Transform(SC7->C7_DESPESA, cMaskVlr)) , oFontBloN, 100, 08, , nPadLeft, )
	nLinBloco += 10
	nLinBloco += 10
	
	oPrintPvt:Line(nLinBloco + 001,  nColIni,  nLinBloco + 001, nColFin, )
	nLinBloco += 2
	
	//Total Final
	oPrintPvt:SayAlign(nLinBloco, nColIni + 005, "Peso Total:"                                 , oFontBloN, 100, 08, , nPadLeft, )
	oPrintPvt:SayAlign(nLinBloco, nColIni + 055, Alltrim(Transform(nTotPeso, cMaskVlr))        , oFontBloN, 100, 08, , nPadLeft, )

	oPrintPvt:SayAlign(nLinBloco, nColMeio+ 005, "Total Geral:"                                , oFontBloN, 100, 08, , nPadLeft, )
	oPrintPvt:SayAlign(nLinBloco, nColMeio+ 055, Alltrim(Transform(nTotGeral, cMaskVlr))       , oFontBloN, 100, 08, , nPadLeft, )
	nLinBloco += 10
	
	oPrintPvt:Line(nLinBloco - 011, nColMeio, nLinBloco + 002, nColMeio, )
	nLinBloco += 2

Return
//-----------------------------------------------------------------------------

/*/{Protheus.doc} fSM0
Retorna os campos da SM0
@type function
@version P12
@author João Carlos da Silva
@since 20/04/2023
@param cEmpAnt, character, Empresa corrente
@param cFilAnt, character, Filial corrente
@return array, Array da SM0 com os campos solicitados
/*/
Static Function fSM0(cEmpAnt,cFilAnt) //Retorna os campos da SM0
Local aCampos := {}

AAdd(aCampos,"M0_NOMECOM")
AAdd(aCampos,"M0_NOME"   )
AAdd(aCampos,"M0_ENDENT" )
AAdd(aCampos,"M0_TEL"    )
AAdd(aCampos,"M0_CIDENT" )
AAdd(aCampos,"M0_BAIRENT")
AAdd(aCampos,"M0_ESTENT" )
AAdd(aCampos,"M0_CGC"    )
AAdd(aCampos,"M0_INSC"   )
AAdd(aCampos,"M0_CEPENT" )

Return( FWSM0Util():GetSM0Data(cEmpAnt,cFilAnt,aCampos) )
//-----------------------------------------------------------------------------

/*/{Protheus.doc} fTrazSM0
Retorna o campo da SM0
@type function
@version P12
@author João Carlos da Silva
@since 20/04/2023
@param aSM0, array, Array com os campos da SM0
@param cCampo, character, Campo a ser retornado
@return array, Array com informações do campo solicitado
/*/
Static Function fTrazSM0(aSM0,cCampo) //Retorna o campo da SM0
If Ascan(aSM0,{|x|x[1]==cCampo}) == 0
	Return("*"+cCampo+"*")
EndIf
Return(aSM0[Ascan(aSM0,{|x|x[1]==cCampo}),2])
//-----------------------------------------------------------------------------

User Function DWCOMA09()

u_GPKCOM02()

Return
//-----------------------------------------------------------------------------

Static Function fObs(cHorReceb) //Monta as observações do pedido
Local aRet := {}

AAdd(aRet,{"1.","DEVERÁ SER INFORMADO, OBRIGATORIAMENTE, O NÚMERO DESTE PEDIDO DE COMPPRA E O CÓDIGO DOS ITENS EM SUA NOTA FISCAL."})
AAdd(aRet,{"2.","NOTAS FISCAIS DEVEM SEMPRE ACOMPANHAR O PRODUTO NA ENTREGA."})
AAdd(aRet,{"3.","CONDIÇÕES DE PAGAMENTO CONFORME NEGOCIAÇÃO: VIA DEPÓSITO EM CONTA OU BOLETO VIA SISTEMA DDA (TENDO A RAZÃO SOCIAL DO FORNECEDOR COMO CEDENTE). PARA AMBOS OS"})
AAdd(aRet,{"  ","CASOS NF'S EMITIDAS ENTRE OS DIAS 01 ATÉ 14 SERÃO PAGAS NO DIA 12 DO MÊS SEGUINTE E NF'S EMITIDAS ENTRE OS DIAS 15 ATÉ 28 SERÃO PAGAS NO DIA 25 DO MÊS SEGUINTE."})
AAdd(aRet,{"4.","NÃO SERÃO ACEITAS NF'S EMITIDAS ENTRE OS DIAS 29 E 31 DE CADA MÊS."})
AAdd(aRet,{"5.","TODO O MATERIAL ENTREGUE NO GRUPO GRAMADO PARKS PASSARÁ POR UMA INSPEÇÃO NO RECEBIMENTO, DEVENDO ESTAR DE ACORDO COM AS INFORMAÇÕES DESTE PEDIDO. HAVENDO"})
AAdd(aRet,{"  ","DIVERGÊNCIAS, O PRODUTO ESTARÁ SUJEITO A DEVOLUÇÃO."})
AAdd(aRet,{"6.","HORÁRIO DE RECEBIMENTO DO ALMOXARIFADO: " + cHorReceb })
AAdd(aRet,{"7.","NOTAS FISCAIS DE RETORNO DE CONSERTO DEVEM VIR ACOMPANHADAS DA NOTA FISCAL DE REMESSA PARA CONSERTO."})
AAdd(aRet,{"8.","PARA FRETES FOB, AS INFORMAÇÕES REFERENTES A IDENTIFICAÇÃO DA TRANSPORTADORA CITADAS NA NOTA FISCAL, DEVEM SER AS MESMAS DO CAMPO EMISSOR NO CONHECIMENTO DE FRETE."})
AAdd(aRet,{"9.","O ARQUIVO XML, REFERENTE A EMISSÃO DO DOCUMENTO FISCAL, DEVERÁ SER ENVIADO PARA O E-MAIL RECEBIMENTOFISCAL.SNOWLAND@GRAMADOPARKS.COM"})

Return(aRet)
//-----------------------------------------------------------------------------

Static Function fComprador(cUser)
Local aAreaSY1 := SY1->(GetArea())
Local aRet := {}

SY1->(dbSetOrder(3)) //3=Y1_FILIAL+Y1_USER
SY1->(dbSeek(xFilial("SY1")+cUser)) //Posiciona no SY1
If SY1->(!Eof())
	aRet := {SY1->Y1_COD,SY1->Y1_NOME,SY1->Y1_TEL,SY1->Y1_EMAIL}
Else
	aRet := {"","","",""}
EndIf

RestArea(aAreaSY1)
Return(aRet)
//-----------------------------------------------------------------------------

Static Function fMaskMoeda(nMoeda)
Local aRet := {"REAL","DOLAR","UFIR","EURO","IENE","N/D"}
Local nRet := If(nMoeda >= 1 .and. nMoeda <= 5, nMoeda, 6)

Return(Alltrim(Str(nMoeda)) + "=" + aRet[nRet])
//-----------------------------------------------------------------------------

Static Function fImpTexto(cImprime,aSM0,oPrint,nLin,nCol,cTexto,oFont,nLargura,nAltura,xPar09,nPad,xPar11)
Local aTexto   := StrTokArr2(AllTrim(cTexto),Chr(13),.f.)
Local aLinha   := {}
Local cLinha   := ""
Local cLinha2  := ""
Local nTexto   := 0
Local nLinha   := 0

Local nTamLin  := 0 //Tamanho da linha em pixels
Local nVezes   := 0
Local lImprime := .t.

For nTexto := 1 to Len(aTexto)
//	aLinha := StrTokArr2(aTexto[nTexto]," ",.f.) //Quebra a linha em palavras
	aLinha := {aTexto[nTexto]} //Considera a linha inteira
	cLinha := ""
	For nLinha := 1 to Len(aLinha)

		cLinha := aLinha[nLinha] //Linha inteira

		While !Empty(cLinha)

			nTamLin := oPrint:GetTextWidth(cLinha, oFont, 0) //Tamanho da linha em pixels

			If nTamLin > nLargura //Se tamanho da linha em pixels for maior que tamanho reservado para impressão
				cLinha2 := fLinha2(cLinha,oPrint,oFont,nLargura) //Retorna a linha até o tamanho informado em pixels
			Else
				cLinha2 := cLinha
			EndIf

			nVezes++
			Do Case
			Case cImprime == "1" //1=Imprime só a primeira linha,2=Imprime a partir da segunda linha,3=Imprime todas as linhas
				lImprime := If(nVezes == 1, .t., .f.)
			Case cImprime == "2" //1=Imprime só a primeira linha,2=Imprime a partir da segunda linha,3=Imprime todas as linhas
				lImprime := If(nVezes == 1, .f., .t.)
			Case cImprime == "3" //1=Imprime só a primeira linha,2=Imprime a partir da segunda linha,3=Imprime todas as linhas
				lImprime := .t.
			EndCase

			If lImprime
				oPrint:SayAlign(nLin, nCol, cLinha2, oFont, nLargura, nAltura, , nPad, ) //Imprime a linha
				nLin += nAltura

				//Se por acaso atingiu o limite da página, finaliza, e começa uma nova página
				If nLin >= nLinFin
					fImpRod()
					fImpCab(aSM0)
					nLinAtu += 7
					nLin := nLinAtu
				EndIf


			EndIf

			cLinha := StrTran(cLinha,cLinha2,"") //Ajusta com o restante da linha
		End
	Next
Next

nLin -= nAltura

Return(nLin)
//-----------------------------------------------------------------------------

Static Function fLinha2(cLinha,oPrint,oFont,nLargura) //Retorna a linha até o tamanho informado em pixels
Local nPos    := 0
Local cLinha2 := "" //Retorna a linha até o tamanho informado em pixels
Local nTamLin := 0  //Tamanho da linha em pixels

For nPos := 1 to Len(cLinha)
	cLinha2 += Subs(cLinha,nPos,1) //Adiciona caracter por caracter
	nTamLin := oPrint:GetTextWidth(cLinha2, oFont, 0) //Tamanho da linha em pixels
	If nTamLin > nLargura //Se tamanho da linha em pixels for maior que tamanho reservado para impressão
		Exit
	EndIf
Next

Return(cLinha2)
//-----------------------------------------------------------------------------
