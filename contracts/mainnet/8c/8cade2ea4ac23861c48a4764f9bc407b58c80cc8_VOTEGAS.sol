/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is 0x address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Functional {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    bool private _reentryKey = false;
    modifier reentryLock {
        require(!_reentryKey, "attempt reenter locked function");
        _reentryKey = true;
        _;
        _reentryKey = false;
    }
}

contract ERC20 {
    function totalSupply() external view returns (uint256){}
    function balanceOf(address account) external view returns (uint256){}
    function transfer(address recipient, uint256 amount) external returns (bool){}
    function allowance(address owner, address spender) external view returns (uint256){}
    function approve(address spender, uint256 amount) external returns (bool){}
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){}
}


//////////////////////////// START OF MAIN CONTRACT /////////////////////////////
contract VOTEGAS is Ownable, Functional {
    ERC20 GAS;  // $GAS token
    
    string public name;
    
    bool votingActive;

    uint256 minDonation;
    uint256[] collectedVotes;
    
    //mappings for staked coins
    mapping (address => uint256) timesvoted;
    mapping (address => uint256) totaldonated;

    constructor() {
    	name = "GAS Voting Contract - Use SGAS to determint the future of $GAS";
		
    	GAS = ERC20(0xDf3aD440135B1880d40C78DdE59631293Da1dC2e);
    }
    
    function initVote( uint256 numChoices) external onlyOwner {
    	delete collectedVotes;
    	
    	for (uint256 i; i < numChoices; i++){
    		collectedVotes.push(0);
    	}
    }
    
    function vote( uint256 choice, uint256 voteCount ) external payable reentryLock {
    	// voteCount in $GAS-wei
        require( votingActive, "Ballot not Open at this time" );
    	require( msg.value >= minDonation, "Invalid Donation" );
    	require( GAS.allowance(_msgSender(), address(this)) > voteCount, "Not approved" );
    	require( choice <= collectedVotes.length, "Invalid Ballot" );
    	
        timesvoted[_msgSender()] += 1;
        totaldonated[_msgSender()] += msg.value;
    	collectedVotes[choice] += voteCount / (10**18);

        GAS.transferFrom(_msgSender(), address(this), voteCount);
    }

    function activateVoting() external onlyOwner {
        votingActive = true;
    }
    
    function deactivateVoting() external onlyOwner {
        votingActive = false;
    }

    function viewResults() external view returns(uint256[] memory){
    	return collectedVotes;
    }
    
    function setMinDonation( uint256 newAmnt ) external onlyOwner {
    	// newAmnt in wei (ETH)
    	minDonation = newAmnt;
    }
    
    function withdrawAll() external onlyOwner {
    	// pull ETH
        uint256 sendAmount = address(this).balance;
        (bool success, ) = msg.sender.call{value: sendAmount}("");
        require(success, "Transaction Unsuccessful");
        
        // pull GAS
        sendAmount = GAS.balanceOf(address(this));
        GAS.transfer( _msgSender(), sendAmount );
    }
    
    function amountDonated( address checkAddress ) external view returns(uint256){
        return totaldonated[checkAddress];
    }

    function timesVoted( address checkAddress ) external view returns(uint256){
        return timesvoted[checkAddress];
    }

    function choiceCount() external view returns(uint256){
        return collectedVotes.length;
    }
}