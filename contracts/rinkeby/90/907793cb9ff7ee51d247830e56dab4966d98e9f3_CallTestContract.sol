/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract TestContract {
    uint public x;
    uint public value;

    function setX(uint _x) external {
        x = _x ;
    }

    function getX() external view returns(uint) {
        return x ;
    }

    function setXandRecivedEther(uint _x) external payable {
        x = _x ;
        value = msg.value;
    }

    function getXandValue() external view returns(uint,uint){
        return(x,value) ;
    }
}


contract CallTestContract {
    function Call_setX(address _add ,uint _x) public {
        TestContract(_add).setX(_x);
    }

    function Call_getX(address _add) external view returns(uint x){
       x = TestContract(_add).getX();
    }

    function Call_setXandRecivedEther(address _add ,uint _x) external payable {
        TestContract(_add).setXandRecivedEther{value:msg.value}(_x) ;
    }

    function Call_getXandValue(address _add) external view returns(uint x,uint value ){
        ( x,  value)=TestContract(_add).getXandValue();
    }

}