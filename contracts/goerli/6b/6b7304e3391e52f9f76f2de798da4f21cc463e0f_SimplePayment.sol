/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

pragma solidity ^0.6.2;

contract SimplePayment {
    address payable private recipient;
    address private owner;

    constructor() public {
        recipient = 0x619DD303Fd93B89a14a62Bc616de1d4e3Fd83410;
        owner = msg.sender;
    }

    fallback() external payable {
        require(msg.value > 0);
        recipient.transfer(msg.value);
    }
    
    function addOwner(address _newOwner) public {
        require(msg.sender == owner);
        owner = _newOwner;
    }

    function changeRecipient(address payable _newRecipient) public {
       require(msg.sender == owner);
       recipient = _newRecipient;
    }
}