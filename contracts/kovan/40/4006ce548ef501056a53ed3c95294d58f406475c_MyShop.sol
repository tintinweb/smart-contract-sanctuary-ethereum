/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

pragma solidity ^0.8.0;

contract MyShop {
    address public owner;
    mapping (address => uint) public payments;

    constructor() {
        owner = msg.sender;
    }

    function payForItem() public payable {
        payments[msg.sender] = msg.value;
    }

    function getMoney() public {
        require(msg.sender == owner);
        address payable _to = payable(owner);
        address _addressContract = address(this);
        _to.transfer(_addressContract.balance); 
    }
}