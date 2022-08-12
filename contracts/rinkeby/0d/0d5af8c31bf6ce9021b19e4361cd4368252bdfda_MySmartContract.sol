/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// File: push.sol




pragma solidity ^0.8.16;

contract MySmartContract{
    string[] public arr;
    string public urlNFT;
    string public descripcion;

    function storex(string memory url, string memory descrip) public {
        urlNFT = url;
        descripcion = descrip;
        
    }
    function array_push(
    ) public returns(string[] memory){  
    
        arr.push(urlNFT);  
        arr.push(descripcion);  
        
    
        return arr;  
    }  


    }