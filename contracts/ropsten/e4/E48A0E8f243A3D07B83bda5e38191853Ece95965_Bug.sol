/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

pragma solidity ^0.8.0;

contract Bug {
    function test0() external view returns(uint) { //returns: 1
        return 1;
    }

    function test1() external view returns(uint) { //returns: 1
        uint value;
        value = 1;
        return value;
    }

    function test2() external view returns(uint value) { //returns: 1
        value = 1;
    }

    function test3() external view returns(uint value) { //returns: 1
        uint value_new;
        value = 1;
    }

    function test4() external view returns(uint value) { //returns: 1
        value=1;
        uint value_new;
    }

    function test5() external pure returns(uint value1, uint value2) { //returns: 1, 2
        value1 = 1;
        value2 = 2;
    }

    function test6() external view returns(uint, uint) { //returns: 1, 2
        return this.test5();
    }
}