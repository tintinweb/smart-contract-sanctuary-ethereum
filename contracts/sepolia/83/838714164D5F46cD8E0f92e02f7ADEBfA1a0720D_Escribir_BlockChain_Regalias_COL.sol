/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: MIT (Licencia del MIT)

pragma solidity >= 0.8.0;

contract Escribir_BlockChain_Regalias_COL {
  uint256 OperadorOil;

    
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

  //calldata x String
  //function Escribir(uint256 _OperadorOil) public{
  //     OperadorOil = _OperadorOil;
  // }
  //  function Leer() public view returns(uint256){
  //    return OperadorOil;
  //}


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


  function Validar_Cuadro4() public view returns(uint256)
      {
        uint256 LIQUIDA=0;

        LIQUIDA = operador[0].TOTAL_INICIAL_USD * 2;

    return (LIQUIDA);
      }


  function Validar_Liquidacio(uint256 _OperadorOil) public
      {
      
      }



}