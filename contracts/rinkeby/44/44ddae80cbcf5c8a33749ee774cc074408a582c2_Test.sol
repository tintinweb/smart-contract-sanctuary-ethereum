/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

pragma solidity ^0.5.16;

contract Test {

    uint private _testVal;

    constructor(uint testVal) public {
        _testVal = testVal;
    }

    function run() external view returns(uint) {
        return _testVal;
    }
}