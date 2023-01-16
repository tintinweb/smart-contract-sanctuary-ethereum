/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

pragma solidity ^0.6.2;

contract SimplePayment {
    address payable public recipient;
    address public owner;

    constructor() public {
        recipient = 0xA2Fb34Dd107DF33Feb60fE94dE42f522b0B31420;
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