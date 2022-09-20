// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract Darcon {
 uint256 private num;
    constructor(uint256 _num){
        num = _num;
    }
    function doWork() external
    {
        selfdestruct(payable(0));
    }
    function getNum() public view returns(uint){
        return num;
    }
}