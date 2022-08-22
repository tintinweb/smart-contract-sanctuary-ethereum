/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// File: Arreglo.sol


pragma solidity ^0.8.16;

contract MySmartContract{
    string[] public arr;
    string public urlNFT;
    string public descripcion;
	string public direccion;

    function storex(string memory url, string memory descrip, string memory dir) public {
        urlNFT = url;
        descripcion = descrip;
        direccion = dir;
    }
    function array_push(
    ) public returns(string[] memory){  
    
        arr.push(urlNFT);  
        arr.push(descripcion);
		arr.push(direccion);	
        
    
        return arr;  
    }  

function dynamic_array() public view returns(
      string[] memory){  
     
        return (arr);  
    }  


    }