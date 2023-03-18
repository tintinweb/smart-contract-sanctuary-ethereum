/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

/** 
 *  SourceUnit: /home/patrick/Desktop/CONTRACTS-TOKENS-SCRIPTS-ON-ETHEREUM-POLYGON-BNBCHAIN/contracts/parametersandarguments.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: SEE LICENSE IN LICENSE
pragma solidity ^0.8.1;
//we are writing parameters and arguments
contract theparameters {
    string public sport= "football";
    function ourparameters(string memory _sport) public {
   sport = _sport;
    }
    function viewparametersandarguments() public view returns (string memory) {
        return sport;
    }
}