/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
contract storeHash {
    address public admin;
    constructor(){
        admin = msg.sender;
    }
    modifier onlyAdmin{
        require(msg.sender == admin, "Only the admin.");// Only allow company to have access
        _;   
    }
    event Log( bytes32 _hash);

    function setReviewData( bytes32 _hash ) onlyAdmin public  {        
    emit Log(_hash);
    }
}