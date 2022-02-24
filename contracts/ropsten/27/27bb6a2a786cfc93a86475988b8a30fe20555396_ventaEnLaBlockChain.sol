/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract ventaEnLaBlockChain{
    string texto_venta;

    function ventaBlock(string calldata _texto_venta) public{
        texto_venta=_texto_venta;
    }

    function obtenerVenta() public view returns(string memory){
        return texto_venta;
    }

}