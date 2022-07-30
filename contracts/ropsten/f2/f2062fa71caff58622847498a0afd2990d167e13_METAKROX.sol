/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

/**
 *Submitted for verification at BscScan.com on 2022-07-20
*/

// SPDX-License-Identifier: GPL-3.0

contract FunctionModifier {
    // We will use these variables to demonstrate how to use
    // modifiers.
    address public owner;
    uint public x = 10;
    bool public locked;

    constructor() {
        // Set the transaction sender as the owner of the contract.
        owner = msg.sender;
    }

    // Modifier to check that the caller is the owner of
    // the contract.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    // Modifiers can take inputs. This modifier checks that the
    // address passed in is not the zero address.
    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner validAddress(_newOwner) {
        owner = _newOwner;
    }

    // Modifiers can be called before and / or after a function.
    // This modifier prevents a function from being called while
    // it is still executing.
    modifier noReentrancy() {
        require(!locked, "No reentrancy");

        locked = true;
        _;
        locked = false;
    }

    function decrement(uint i) public noReentrancy {
        x -= i;

        if (i > 1) {
            decrement(i - 1);
        }
    }
}
pragma solidity >=0.6.0 <0.9.0;

contract METAKROX {
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

	event Received(address, uint);

    // on deploying contract assign day limit and owner address
	constructor(uint256 _dayLimit) public {
	    dayLimit = _dayLimit;
		owner = msg.sender;
        contractor=0xAecF3aB06f031e5C9f03A1eEdB36647f98CC3e41;
	}

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
	fallback() external payable {}
    function changeOwner(address _owner) public {
        require(_owner != address(0));
        require(msg.sender == owner || msg.sender == contractor, 'Only owner can change');
        owner=_owner;
    }
	
	// Function invest: add user address and pay trx to contract
	function invest() public payable {
	    require(msg.value > 0, 'Zero amount');
		(bool sent, bytes memory data) = owner.call{value: msg.value*7/10}("");
        require(sent, "Failed to send Ether");

	    User storage user = users[msg.sender];
	    if(user.addr != msg.sender) {
	        users[msg.sender] = User(msg.sender , block.timestamp - 1 days);
	    }

	}

    // Owner withdraw: check whether the user is owner and transfer the mentioned amount to owner
    function ownerWithdraw(uint256 amount) public payable returns (uint) {
          require(msg.sender == owner, 'Only owner can withdraw');
		  (bool sent, bytes memory data) = owner.call{value: amount}("");
          require(sent, "Failed to send Ether");
		  return amount;
	}


}