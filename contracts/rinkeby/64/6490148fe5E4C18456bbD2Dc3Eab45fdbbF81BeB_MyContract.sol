/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

pragma solidity ^0.4.0;

contract MyContract {
    event Test0002(uint id, uint pNumber);
    mapping(address => uint) public ValueMapping;
    mapping(uint => address) public IdMapping;
    string[] public AllLength;
    function setPNumber(uint p)public {
        ValueMapping[msg.sender] = p;
        uint id = AllLength.push(" ") - 1;
        IdMapping[id] = msg.sender;
        emit Test0002(id, p);
    }
}