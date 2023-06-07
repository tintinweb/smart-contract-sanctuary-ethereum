/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

pragma solidity ^0.8.9;

contract Storage {
    uint public number = 0;
    // After deployment, this is stored on the blockchain
     
     function store(uint256 _value) public {
        number = _value;
    }

    }