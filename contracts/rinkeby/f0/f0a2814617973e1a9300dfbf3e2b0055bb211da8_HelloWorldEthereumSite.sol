/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Defining calling contract
contract HelloWorldEthereumSite{

    function loadSite() public pure returns(string memory){
        return "<h1>Hello World!</h1><br/><p>From the Ethereum Blockchain</p>";
    }
}