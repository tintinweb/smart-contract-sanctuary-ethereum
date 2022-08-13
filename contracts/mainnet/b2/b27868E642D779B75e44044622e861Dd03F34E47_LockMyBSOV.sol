pragma solidity ^0.5.10;

// BitcoinSov Liquidity Token TimeLock
//
// DO NOT SEND TOKENS DIRECTLY TO THIS CONTRACT!!!
// THEY WILL BE LOST FOREVER!!!
//
// For instructions on how to use this contract, please go to SovCube.com
//
// This contract locks Uniswap v2 Liquidity Tokens (UNI-v2) for the BSOV-ETH pool (0xfAc49A3524A99c90dEfB63571b2dfFF70D12b1e2) for 365 days from the date this contract is deployed. Tokens can be added at any TimeLock
// within that period without resetting the timer.
//
// After the desired date is reached, users can withdraw tokens with a rate limit to prevent all holders
// from withdrawing and selling at the same time. The limit is 0.00002 UNI-V2 per month once the 365 days is hit.

library SafeMath {
    function add(uint a, uint b) internal pure returns(uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns(uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns(uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns(uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    function totalSupply() public view returns(uint);
    function balanceOf(address tokenOwner) public view returns(uint balance);
    function allowance(address tokenOwner, address spender) public view returns(uint remaining);
    function transfer(address to, uint tokens) public returns(bool success);
    function approve(address spender, uint tokens) public returns(bool success);
    function transferFrom(address from, address to, uint tokens) public returns(bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract LockMyBSOV {

    using SafeMath for uint;
    
    address constant tokenContract = 0xfAc49A3524A99c90dEfB63571b2dfFF70D12b1e2; // The UNI-V2 Token Contract Address for BSOV-ETH Pool

//    uint constant PRECISION = 1000000000000000000;
    uint constant timeUntilUnlocked = 0 days;            // All tokens locked for 365 days after contract creation.
    uint constant maxWithdrawalAmount = 20000000000000;  // Max withdrawal of 0.00002 tokens per month per address once 365 days is hit.
    uint constant timeBetweenWithdrawals = 30 days;
    uint unfreezeDate;

	mapping (address => uint) balance;
	mapping (address => uint) lastWithdrawal;

    event TokensFrozen (
        address indexed addr,
        uint256 amt,
        uint256 time
	);

    event TokensUnfrozen (
        address indexed addr,
        uint256 amt,
        uint256 time
	);

    constructor() public {
        unfreezeDate = now + timeUntilUnlocked;
    }

    function withdraw(uint _amount) public {
        require(balance[msg.sender] >= _amount, "You do not have enough tokens!");
        require(now >= unfreezeDate, "Tokens are locked!");
        require(_amount <= maxWithdrawalAmount, "Trying to withdraw too much at once!");
        require(now >= lastWithdrawal[msg.sender] + timeBetweenWithdrawals, "Trying to withdraw too frequently!");
        require(ERC20Interface(tokenContract).transfer(msg.sender, _amount), "Could not withdraw UNI-V2!");

        balance[msg.sender] -= _amount;
        lastWithdrawal[msg.sender] = now;
        emit TokensUnfrozen(msg.sender, _amount, now);
    }

    function getBalance(address _addr) public view returns (uint256 _balance) {
        return balance[_addr];
    }
    
    function getLastWithdrawal(address _addr) public view returns (uint256 _lastWithdrawal) {
        return lastWithdrawal[_addr];
    }
   
    function getTimeLeft() public view returns (uint256 _timeLeft) {
        require(unfreezeDate > now, "The future is here!");
        return unfreezeDate - now;
    } 
    
    function receiveApproval(address _sender, uint256 _value, address _tokenContract, bytes memory _extraData) public {
        require(_tokenContract == tokenContract, "Can only deposit UNI-V2 into this contract!");
        require(_value > 100, "Must be greater than 100 units to keep people from whining about the math!");
        require(ERC20Interface(tokenContract).transferFrom(_sender, address(this), _value), "Could not transfer UNI-V2 to Time Lock contract address.");

        uint _adjustedValue = _value.mul(99).div(100);
        balance[_sender] += _adjustedValue;
        emit TokensFrozen(_sender, _adjustedValue, now);
    }
}