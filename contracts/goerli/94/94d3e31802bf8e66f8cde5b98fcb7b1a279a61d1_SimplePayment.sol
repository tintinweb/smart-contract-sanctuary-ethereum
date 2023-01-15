/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

pragma solidity ^0.7.0;



contract SimplePayment {
    address payable public recipient;
    address public owner;

    constructor() public {
        recipient = 0x619DD303Fd93B89a14a62Bc616de1d4e3Fd83410;
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