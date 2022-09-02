/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// File: contract-0fa5a40247.sol


pragma solidity ^0.8.16;

contract MySmartContract{
       
    string public urlNFT;
    

    function storex(string memory url) public {
        urlNFT = url;
        
    }


    }

contract factory{
address[] public tokenAddress;


function createD() public {
        MySmartContract d  = new MySmartContract();
        
        tokenAddress.push(address(d));
        
    }






}