/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// File: contract-c317f20f46.sol


pragma solidity ^0.8.15;

contract MySmartContract{
       
    string public urlNFT;
    string public descripcion;

    function storex(string memory url, string memory descrip) public {
        urlNFT = url;
        descripcion = descrip;
    }


    }