/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

pragma solidity 0.6.12;


contract Test {

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only callable by owner");
    _;
  }

    constructor() public {
        owner = msg.sender;
    }

    
    function withdraw(uint _amount) public payable onlyOwner {
        msg.sender.call{value: _amount}("");
    }

    receive () external payable {}
}