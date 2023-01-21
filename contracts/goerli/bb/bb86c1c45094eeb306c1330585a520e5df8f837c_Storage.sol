/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

// File: contracts/SampleContract.sol



pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    uint256 number;

    function _store(uint num) public {
        number = num;
    }

    function _retrieve() public view returns (uint){
        return number;
    }
}