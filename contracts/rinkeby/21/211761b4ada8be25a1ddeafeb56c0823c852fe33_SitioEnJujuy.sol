/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// Este contrato representa virtualmente a un sitio real en Jujuy
pragma solidity ^0.8.10;

contract SitioEnJujuy {
// Atributos del sitio virtual
    address public duenio;
    uint public direccion;
    bool public estaEnVenta;
    uint public precio;


    constructor(
        address duenio_,
        uint direccion_,
        bool estaEnVenta_,
        uint precio_
    ) {
        duenio=duenio_;
        direccion=direccion_;
        estaEnVenta=estaEnVenta_;
        precio = precio_;
    }

    function cambiar_precio(uint NuevoPrecio) external
    {
        // Requerimiento
        // msg.sender -> el que manda la transaccion
        require(msg.sender == duenio, "Usted no es el duenio no puede cambiar de precio");
        precio = NuevoPrecio;
    }
}