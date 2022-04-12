/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

pragma solidity ^0.8.4;

contract ReturnTest {
    uint256 public result;

    function square(uint256 value) external returns (uint256) {
        result = value * value;
        return result;
    }

}