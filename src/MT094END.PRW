#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} MT094END
Ponto de entrada na liberação de documentos (MATA094)
Enviar e-mail para o fornecedor na última aprovação
@type function
@version P12
@author João Carlos da Silva
@since 04/05/2023
/*/
User Function MT094END() //ExecBlock("MT094END",.F.,.F.,{(oFieldSCR:GetValue("CR_NUM")),(oFieldSCR:GetValue("CR_TIPO")),Val(Substr(cIdOption,3,1)),(oFieldSCR:GetValue("CR_FILIAL"))})
Local cDoc     := PARAMIXB[1]
Local cTipo    := PARAMIXB[2]
Local nOpc     := PARAMIXB[3]
Local cFilDoc  := PARAMIXB[4]

Local aArea    := Nil
Local aAreaSC7 := Nil

If cTipo == "PC"
	If nOpc == 1 .or. nOpc == 3 //1=Aprovar,2=Estornar,3=Aprovar pelo Superior,4=Transferir para Superior,5=Rejeitar,6=Bloquear
		aArea      := GetArea()
		aAreaSC7   := SC7->(GetArea())

		cDoc := PadR(cDoc,Len(SC7->C7_NUM)) //Ajusta o tamanho do número do pedido

		SC7->(dbSetOrder(1)) //C7_FILIAL+C7_NUM+C7_ITEM+C7_SEQUEN
		SC7->(dbSeek(cFilDoc+cDoc)) //Posiciona no SC7
		If SC7->(!Eof())
			If SC7->C7_CONAPRO == "L"
				U_GPKCOM02("Enviar") //Enviar o pedido de compra para o fornecedor
			EndIf
		EndIf

		RestArea(aAreaSC7)
		RestArea(aArea)
	EndIf
EndIf

Return
//-----------------------------------------------------------------------------
