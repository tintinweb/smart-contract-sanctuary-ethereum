/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// SPDX-License-Identifier: MIT (Licencia del MIT)
// UNIVERSIDAD DE LA SABANA - MAESTRIA GERENCIA DE INGENIERIA - MAYO 2023

pragma solidity >= 0.8.0;

contract Escribir_BlockChain_Regalias_COL {
  
//vARIABLES GLOBALES
  uint256 CONTRATO;
  //uint256 PRODUCCION_GRAVABLE;
  //uint256 TRM;
  //uint256 PRECIO_BASE_LIQUIDACION;
  //uint256 PRODUCCION_OPERADOR;
  //uint256 PRODUCCION_AVM;
    
  struct Operador{
    uint256 CONTRATO; 
    string RAZON_SOCIAL;
    string CAMPO;
    string DEPTO;
    string MUNICIPIO;
    string APLICA_REVERSION;
    uint256 PORCENTA_LEY_REGALIA;
    }
  
Operador [] public Contrato_operador;
mapping(uint256=> string) public Buscar_Contrato;

//String memory
//storage  
  function Add_Contrato(uint256 _CONTRATO, string memory _RAZON_SOCIAL ,string memory _CAMPO, string memory _DEPTO, string memory _MUNICIPIO, string memory _APLICA_REVERSION, uint256 _PORCENTA_LEY_REGALIA) public 
  {
    Contrato_operador.push(Operador(_CONTRATO, _RAZON_SOCIAL, _CAMPO, _DEPTO, _MUNICIPIO, _APLICA_REVERSION, _PORCENTA_LEY_REGALIA));
    Buscar_Contrato[_CONTRATO] = _RAZON_SOCIAL;  
  }


  function Validar_Liquidacio(uint256 _PRECIO_BASE_LIQUIDACION, uint256 _TRM, uint256 _PRODUCCION_GRAVABLE, uint256 LiquidacionSolar) public view returns(uint256, string memory)
      {
        uint256 Liquidacion;
        string memory Mensaje = " ";
                
        Liquidacion = Contrato_operador[0].PORCENTA_LEY_REGALIA*_PRODUCCION_GRAVABLE*_TRM*_PRECIO_BASE_LIQUIDACION/100;

        if (Liquidacion == LiquidacionSolar) {
           Mensaje = " OK - LIQUIDACION AVM COINCIDE CON LIQUIDACIPON SOLAR - OK";  
        }
        else
           Mensaje = " ERROR - LIQUIDACION AVM NO COINCIDE CON LIQUIDACIPON SOLAR - ERROR";  
          
     
      return (Liquidacion, Mensaje);
      }


 function Validar_Cuadro4(uint256 _PRODUCCION_OPERADOR, uint256 _PRODUCCION_AVM) public pure returns(string memory, uint256, uint256)
      {
        string memory Mensaje = "";
                
        if (_PRODUCCION_OPERADOR == _PRODUCCION_AVM) {
           Mensaje = " OK - PRODUCCION DE AVM COINCIDE CON PRODUCCION DE OPERADOR - OK ";  
        }
        else
           Mensaje = " ERROR - PRODUCCION DE AVM NO COINCIDE CON PRODUCCION DE OPERADOR - ERROR";  
          
    
      return (Mensaje, _PRODUCCION_OPERADOR, _PRODUCCION_AVM);
      }



}