/**
 *Submitted for verification at Etherscan.io on 2022-10-16
*/

pragma solidity ^0.5.0;

contract HelloWorld{
    string public hello = "Test";

    uint256[] public numbers;

    constructor(uint256[] memory initData) public {
        numbers = initData;
    }
}