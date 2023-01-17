/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// File: contracts/sampleContract.sol



pragma solidity 0.8.7;

contract AlwinsContract {

    uint variable;

    function storetheValue(uint num) public {
        variable = num;
    }

    function retrieveTheValue() public view returns (uint){
        return variable;
    }
}