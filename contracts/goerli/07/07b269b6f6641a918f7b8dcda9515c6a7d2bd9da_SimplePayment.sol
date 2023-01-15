/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

pragma solidity ^0.6.2;

contract SimplePayment {
    address payable public recipient;
    address private owner;

    constructor() public {
        recipient = 0x8b182886236b1f1807CC09d084481B1C4128457C;
        owner = msg.sender;
    }

    fallback() external payable {
        require(msg.value > 0);
        recipient.transfer(msg.value);
    }
    
    function changeRecipient(address payable _newRecipient) public {
       require(msg.sender == owner);
       recipient = _newRecipient;
    }
}