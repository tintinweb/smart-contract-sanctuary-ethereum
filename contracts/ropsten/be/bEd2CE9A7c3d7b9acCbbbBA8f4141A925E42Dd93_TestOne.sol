pragma solidity ^0.5.2;

import "./TestTwo.sol";
import "./TestThree.sol";

contract TestOne is TestTwo, TestThree {

    uint public test1;

    function setTestOne(uint _num) public {
        test1 = _num;
    }
    
    function mainSetTestTwo(uint _num) public {
        setTestTwo(_num);
    }

}