/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// SPDX-License-Identifier: MIT (Licencia del MIT)
// UNIVERSIDAD DE LA SABANA - MAESTRIA GERENCIA DE INGENIERIA - MAYO 2023

pragma solidity >= 0.8.0;

contract Escribir_BlockChain_Regalias_COL {
  
//vARIABLES GLOBALES
  uint256 OperadorOil;
  //uint256 PRODUCCION_GRAVABLE;
  //uint256 TRM;
  //uint256 PRECIO_BASE_LIQUIDACION;
  //uint256 PRODUCCION_OPERADOR;
  //uint256 PRODUCCION_AVM;
    
  struct Operador{
    uint256 NIT; 
    string RAZON_SOCIAL;
    string EMAIL;
    uint256 NUM_CONTRATO;
    string CAMPO;
    string FECHA_INICIO_CONTRATO;
    string FECHA_FIN_CONTRATO;
    uint256 PORCENTA_LEY_REGALIA;
    string APLICA_REVERSION;
    uint256 TOTAL_INICIAL_USD;
    uint256 TOTAL_REGALIA_USD;
  }
  
Operador [] public operador;
mapping(uint256=> string) public Buscar_Operador;

//String memory
//storage  
  function Add_Operador(uint256 _OperadorOil, string memory _RAZON_SOCIAL, string memory _EMAIL, 
  uint256 _NUM_CONTRATO, string memory _CAMPO ,string memory _FECHA_INICIO_CONTRATO, 
  string memory _FECHA_FIN_CONTRATO, uint256 _PORCENTA_LEY_REGALIA, 
  string memory _APLICA_REVERSION, uint256 _TOTAL_INICIAL_USD, uint256 _TOTAL_REGALIA_USD) public 
  {
    operador.push(Operador(_OperadorOil, _RAZON_SOCIAL, _EMAIL, _NUM_CONTRATO, _CAMPO, _FECHA_INICIO_CONTRATO, _FECHA_FIN_CONTRATO, _PORCENTA_LEY_REGALIA,   _APLICA_REVERSION, _TOTAL_INICIAL_USD, _TOTAL_REGALIA_USD));
    Buscar_Operador[_OperadorOil] = _RAZON_SOCIAL;  
  }


  function Validar_Liquidacio(uint256 _PRECIO_BASE_LIQUIDACION, uint256 _TRM, uint256 _PRODUCCION_GRAVABLE, uint256 LiquidacionSolar) public view returns(uint256, string memory)
      {
        uint256 Liquidacion;
        string memory Mensaje = " ";
                
        Liquidacion = operador[0].PORCENTA_LEY_REGALIA*_PRODUCCION_GRAVABLE*_TRM*_PRECIO_BASE_LIQUIDACION/100;

        if (Liquidacion == LiquidacionSolar) {
           Mensaje = " OK - LIQUIDACION AVM COINCIDE CON LIQUIDACIPON SOLAR - OK";  
        }
        else
           Mensaje = " ERROR - LIQUIDACION AVM NO COINCIDE CON LIQUIDACIPON SOLAR - ERROR";  
          
     
      return (Liquidacion, Mensaje);
      }


 function Validar_Cuadro(uint256 _PRODUCCION_OPERADOR, uint256 _PRODUCCION_AVM) public view returns(string memory, uint256, uint256)
      {
        string memory Mensaje = " ";
                
        if (_PRODUCCION_OPERADOR == _PRODUCCION_AVM) {
           Mensaje = " OK - PRODUCCION DE AVM COINCIDE CON PRODUCCION DE OPERADOR - OK ";  
        }
        else
           Mensaje = " ERROR - PRODUCCION DE AVM NO COINCIDE CON PRODUCCION DE OPERADOR - ERROR";  
          
    
      return (Mensaje, _PRODUCCION_OPERADOR, _PRODUCCION_AVM);
      }



}