/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
contract Funding {
 	address admin;

    constructor(){
        admin = msg.sender;
    }

	modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

	struct details{
		string cause;
		uint balance;
		uint targetLimit;
		uint commission;
	}
	// Mapping the recipient with the corresponding details
	mapping (address => details) public fundDetails;

	// An event for donation. The sender is indexed so that filtering could be done using the sender
	event donateEvent(address indexed sender, uint amount);
	
	// This function registers a new campaign. The balance amount is set to zero initially.
	// Only admin ( contract deployer ) has access to this function
	function setDetails(address _recipient, string memory _cause, uint _targetLimit, uint _commission) public{
		require(msg.sender == admin, "Access Denied"); 
		fundDetails[_recipient] = details(_cause, 0 , _targetLimit,_commission);
	}
	// This function accepts the donation by updating the balance fild for the corresponding recipient address
	function acceptDonation(address _recepient) public payable{
    
        // adding commission with the required amount
		uint actualTarget = fundDetails[_recepient].targetLimit + fundDetails[_recepient].commission;
		uint remAmount = (actualTarget - fundDetails[_recepient].balance);
		// Make sure that the amount doesnt exceed the target+commsission, during each donation
		if (msg.value <= remAmount){
        	fundDetails[_recepient].balance += msg.value;
			emit donateEvent(msg.sender,msg.value);
		}
		else{
		// If the balance exceeds the target+commission, return the remaining amount to the sender
			fundDetails[_recepient].balance = actualTarget;
			payable(msg.sender).transfer(msg.value - remAmount);
			emit donateEvent(msg.sender,(remAmount));
		}
    }

	// Gets the balance for a particular recipient
	function getBal(address _recepient) public view returns(uint){
        return fundDetails[_recepient].balance;
    }

	// Disburses the fund -> sends the target amount to the recipient address, the commission to the
	// contract deployer. Then deletes the struct mapping for the particular address
	// This function accessible by the contract deployer only
	// This function can be called even when the target amount is not achieved. i.e. Admin may need
	// to close the account by the target Date even if the target is not achieved
	function accountClosure(address _recepient) public {
       require(msg.sender == admin, "Access Denied"); 
       payable(_recepient).transfer((fundDetails[_recepient].balance-fundDetails[_recepient].commission));
       payable(admin).transfer((fundDetails[_recepient].commission));
       delete fundDetails[_recepient];
    }
}