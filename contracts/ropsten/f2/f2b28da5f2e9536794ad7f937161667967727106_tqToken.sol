/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// 'TQ' CROWDSALE token contract
//
// Deployed to : 0x4c092a69A222387CE33879d5ef5dD6851eeE8F64
// Symbol      : TQ
// Name        : TQ Coin
// Total supply: 16,000,000
// Decimals    : 3
//
// Enjoy.
//
// (c) by Moritz Neto & Daniel Bar with BokkyPooBah / Bok Consulting Pty Ltd Au 2017. The MIT Licence.
// and used by Qi Deng @ uic for demo
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath { //To ensure that addition, subtraction, multiplication and division calculations are correct and reasonable.
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// Basis contract
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);// owner allows spender to send certain number of tokens
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract: indicates that the contract is owned by an account. Investors send ETH to the contract's address.

// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);//The function of the OwenershipTransfer is to transfer the ownership of a contract to another user

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract tqToken is ERC20Interface, Owned, SafeMath { // 'is' indicates an inheritance relationship, in this case fqwnToken inherits functions from the parent class ERC20Interface
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public startDate;
    uint public bonusEnds;
    uint public endDate;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed; 
	//To keep the balance corresponding to each address.
	mapping (address => uint256) public freezeOf; 
	//Two-level mapping.Holds the amount of money that a certain address A allows another address B to operate on.The outermost mapping is for a certain address A and the inner mapping is 
	//for another address B. The value is the total amount that can be manipulated (initiated transactions).

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
 
    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
 
    /* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function tqToken() public { 
        symbol = "TQ";
        name = "TQ Token"; 
        decimals = 3;  //The maximum number of decimals, i.e. the number of 10^decimals that can be split by 1 token
        bonusEnds = now + 4 weeks;// Deadline for award period
        endDate = now + 52 weeks;// ICO Deadline

    }


    // ------------------------------------------------------------------------
    // Total supply //Total number of tokens issued.
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner` 
	//To check the balance of tokens in an account.
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
       //transfer(address to, unit tokens) from the current own account to realise token transactions.
	//1. Subtract the appropriate amount from your current account.
	//2. Add the corresponding amount to the other side's account at the same time.
	//3. Call the Transfer function to do the notification.
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    	// The owner agrees that the spender can transfer currency from the owner's account and sets a limit (sets the number of tokens allowed for an account spender to use from this address.)
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
	//1. Set the number of tokens available to the spender address from msg.sender.
	//2. Call the Approval function to make a notification
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer   
    // - 0 value transfers are allowed

    // Spender needs owner's permission to transfer tokens
	// transferFrom(address from, address to, unit tokens) implements a token transaction between users (not on their own account).
	// Transfer of accounts between token owners. The transfer transaction is initiated by the from address. (4 steps)
	//1. Subtract the corresponding amount from the address 'from' Address account subtract the corresponding amount.
	//2. The allowed amount from the user of the "from" address to msg.sender is subtracted and the total operable amount from msg.sender is reduced by the corresponding amount.
	//3. The 'to' address account is increased by the corresponding amount.
	//4. Calling the Transfer function for notifications
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);// from: owner address    msg.sender: sender address��Not necessarily the owner��
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // return the token limit approved by the owner 
    // that can be transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------   
    // owner approves spender to transfer tokens from owner's account
    // The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // 1,000 TQ Tokens per 1 ETH (exchange rate)
    // ------------------------------------------------------------------------
    function () public payable {
        require(now >= startDate && now <= endDate);
        uint tokens;
        if (now <= bonusEnds) {
            tokens = msg.value * 1200;// get 20% extra reward
        } else {
            tokens = msg.value * 1000;
        }
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);// sender receives token
        _totalSupply = safeAdd(_totalSupply, tokens);
        Transfer(address(0), msg.sender, tokens);//transfer token to sender's address
        owner.transfer(msg.value);// transfer ETH to owner's address
    }



    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
	
	// Burn the tokens of the specified amount in the operator's account. 
    // When burning, the total amount of tokens will be reduced accordingly��
	function burn(uint256 _value) public returns (bool success) { 
        require(balances[msg.sender] >= _value);// Check if the sender has enough
        require(_value > 0); 
        balances[msg.sender] = safeSub(balances[msg.sender], _value);// Subtract from the sender
        _totalSupply = safeSub(_totalSupply,_value);// Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }
    
    // Freeze the specified amount of the specified account
    function freeze(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);// Check if the sender has enough
        require(_value > 0); 
        balances[msg.sender] = safeSub(balances[msg.sender], _value);// Subtract from the sender
        freezeOf[msg.sender] = safeAdd(freezeOf[msg.sender], _value);                                // Updates totalSupply
        Freeze(msg.sender, _value);
        return true;
    }

    // Unfreeze the specified amount of the specified account
    function unfreeze(uint256 _value) public returns (bool success) {
        require(freezeOf[msg.sender] >= _value);// Check if the sender has enough
        require(_value > 0); 
        freezeOf[msg.sender] = safeSub(freezeOf[msg.sender], _value);// Subtract from the sender
        balances[msg.sender] = safeAdd(balances[msg.sender], _value);
        Unfreeze(msg.sender, _value);
        return true;
    }
}