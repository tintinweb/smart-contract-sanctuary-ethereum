// SPDX-License-Identifier: NOLICENSE

pragma solidity >=0.7.0 <0.9.0;
contract Destructor {
 uint256 public num;
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