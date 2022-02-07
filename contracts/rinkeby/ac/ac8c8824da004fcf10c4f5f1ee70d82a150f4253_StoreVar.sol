/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

pragma solidity ^0.8.0;

contract StoreVar {

    uint8 public _myVar;
    event MyEvent(uint indexed _var);

    function setVar(uint8 _var) public {
        _myVar = _var;
        emit MyEvent(_var);
    }

    function getVar() public view returns (uint8) {
        return _myVar;
    }

}