// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
contract Destructor {
 uint256 public num = 3;
    constructor(){
    }
    function doWork() external
    {
        selfdestruct(payable(0));
    }

    function getNum() public view returns(uint){
        return num;
    }
}