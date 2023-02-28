/**
 *Submitted for verification at Etherscan.io on 2023-02-28
*/

pragma solidity >=0.4.22 <0.9.0;

contract One{

    uint public number;

    function setNumber(uint _number)public {
        number = _number;
    }

    function getNumber()public view returns(uint){
        return number;
    }
}