pragma solidity ^0.7.3;

contract basicsol {

    uint ui;
    function setNumber(uint i) public {
        ui = i;
    }

    function getNumber() public returns( uint i)  {
        return ui;
    }
}