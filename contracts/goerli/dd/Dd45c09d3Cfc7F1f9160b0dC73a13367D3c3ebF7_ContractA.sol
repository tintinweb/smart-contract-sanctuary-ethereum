/**
 *Submitted for verification at Etherscan.io on 2022-06-04
*/

pragma solidity ^0.8.0;

contract ContractA {
    uint256 result;

    function add(uint256 first, uint256 second) public returns(uint256){
        result = first + second;
        return result;
    }

}