/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

pragma solidity ^0.8.0;
// pragma experimental ABIEncoderV2;



contract Certification {
     mapping(address => string) public certificate;
    // State Variables
    function Create( string memory abc ) public {
        certificate[msg.sender]= abc;
        

    }
}