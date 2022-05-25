/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract platzi_datos_1 {

    string nombre;
    uint edad;
    bool esDesarollador;
    address cartera;
     enum StatusDesarrollador { JUNIOR, SENIOR }
    StatusDesarrollador statusElegido;

 //////////////////CONSTRUCTOR
    /* constructor (string memory _nombre, uint _edad, bool _esDesarollador, address _cartera){
        nombre = _nombre;
        edad = 23;
        esDesarollador = _esDesarollador;
        cartera = _cartera;
    } */

  //////////////////NOMBRE
    //funcion para devolver valor nombre
    function deVolverNombre() public view returns (string memory){
        return nombre;
    } 
    //funcion para ingresar nombre
     function cambiarNombre(string memory _nombre) public{
        nombre = _nombre;
    } 

    ///////////EDAD

    //funcion para devolver valor edad
    function deVolverEdad() public view returns (uint){
        return edad;
    } 
    //funcion para ingresar edad
     function cambiarEdad(uint _edad) public{
        edad = _edad;
    }


    ////////BOOOLEAN

    function deVolverEsDesarrollador () public view returns(bool){
        return esDesarollador;
    }

     //funcion para ingresar es desarrikkadir
     function cambiarDesarrollador(bool _esDesarollador) public{
        esDesarollador = _esDesarollador;
    }


     ////////CARTERA

    function deVolverCartera () public view returns(address){
        return cartera;
    }

     //funcion para ingresar es desarrikkadir
     function cambiar_cartera(address _cartera) public{
        cartera = _cartera;
    }

    //////ENUM

    function devolverStatusDesarollador() public view returns(StatusDesarrollador){
        return statusElegido;
    }

    function cambiarStatusDesarollador(uint posicion) public{
        if(posicion == 0) statusElegido = StatusDesarrollador.JUNIOR;
        if(posicion == 1) statusElegido = StatusDesarrollador.SENIOR;
    }

    //////////////////TIPOS DE VISILIDAD

  

    function darVisibilidad() public view returns (string memory){
        return esVisible();
    }


  function esVisible() private view returns (string memory){
        return "soy visible prueba";
    }
    



      
        // end contructor
    
// finde linea de contrato    
}