/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

pragma solidity ^0.4.0;

contract TestContract {
    event Test0002(uint256 id, uint256 pNumber);
    mapping(address => uint256) public ValueMapping;
    mapping(uint256 => address) public IdMapping;
    string[] public AllLength;

    function setPNumber(uint256 p) {
        ValueMapping[msg.sender] = p;
        uint256 id = AllLength.push("") - 1;
        IdMapping[id] = msg.sender;
        emit Test0002(id, p);
    }
}