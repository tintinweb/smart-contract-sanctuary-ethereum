/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// File: save.sol



pragma solidity ^0.8.16;

contract SmartNFT{
    string[] public arr;
    string public urlNFT;
    string public descripcion;

    function Enviar(string memory url, string memory descrip) public {
        urlNFT = url;
        descripcion = descrip;
        
    }
    function Guardar(
    ) public returns(string[] memory){  
    
        arr.push(urlNFT);  
        arr.push(descripcion);  
        
    
        return arr;  
    }  


    }