pragma solidity ^0.4.23;


// Authorization control functions
contract Ownable {
	
	// The administrator of the contract
	address private owner;
	
	// Set the owner to the original creator of the contract
	constructor() public {
		owner = msg.sender;
	}
	
	// Parameters like status can only be changed by the contract owner
	modifier onlyOwner() {
		require( 
			msg.sender == owner,
			'Only the administrator can change this'
		);
		_;
	}
	
}


// Primary contract
contract Blockchainedlove is Ownable {
	
	// Partner details and other contract parameters
    string public partner_1_name;
    string public partner_2_name;
	string public contract_date;
	bool public is_active;
	
	// Main function, executed once upon deployment
	constructor() public {
		partner_1_name = 'Andrii Shekhirev';
		partner_2_name = 'Inga Berkovica';
		contract_date = '23 June 2009';
		is_active = true;
	}
	
	// Change the status of the contract
	function updateStatus(bool _status) public onlyOwner {
		is_active = _status;
		emit StatusChanged(is_active);
	}
	
	// Record the status change event
	event StatusChanged(bool NewStatus);
	
}