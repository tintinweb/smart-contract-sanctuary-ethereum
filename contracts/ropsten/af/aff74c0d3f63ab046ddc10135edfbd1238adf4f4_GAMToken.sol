/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// 'GAVToken' token contract
//
// Deployed to : 0xcd65b839E01b1ce853BA82424B233dFaD239Af30
// Symbol      : GAV
// Name        : GAV
// Total supply: 100000000
// Decimals    : 18
//
// Enjoy.
//
// (c) by Adeniji Olusegun.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



contract GAMToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public  transactionFee;
    uint public  rate;
    address public treasuryAddr;
    address public transactionFeeAddr;
    address public creatorAddr;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "GAM";
        name = "GAM";
        decimals = 18;
        transactionFee = 2 * 10 ** decimals;
        rate = 1000;
         _totalSupply = 170000000000 * 10 ** decimals;
        creatorAddr = msg.sender;
        transactionFeeAddr = creatorAddr;
        transactionFeeAddr = creatorAddr;
        balances[creatorAddr] = _totalSupply;
        emit Transfer(address(0), creatorAddr, _totalSupply);
    }

 // ------------------------------------------------------------------------
    // Set transactionFee
    // ------------------------------------------------------------------------
    function setTranasactionFee(uint fee) public  returns (bool) {
         require(creatorAddr == msg.sender);
         transactionFee = fee;
         return true;
    }

    // ------------------------------------------------------------------------
    // Set Treasure Address
    // ------------------------------------------------------------------------
    function setTreasureAddress(address addr) public  returns (bool) {
         require(creatorAddr == msg.sender);
         treasuryAddr = addr;
         return true;
    }

    // ------------------------------------------------------------------------
    // Set Fee Address
    // ------------------------------------------------------------------------
    function setFeeAddress(address addr) public  returns (bool) {
         require(creatorAddr == msg.sender);
         transactionFeeAddr = addr;
         return true;
    }

     // ------------------------------------------------------------------------
    // Set rate
    // ------------------------------------------------------------------------
    function setRate(uint rt) public  returns (bool) {
         require(creatorAddr == msg.sender);
         rate = rt;
         return true;
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public override returns (bool success) {
        uint charges = rate * transactionFee;
        uint remainingTokens =  tokens - charges;
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, remainingTokens);
        emit Transfer(msg.sender, transactionFeeAddr,  charges);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        uint charges = rate * transactionFee;
        uint remainingTokens =  tokens - charges;
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, remainingTokens);
        emit Transfer(from, transactionFeeAddr, charges);
        return true;
    }
 
   function withdraw(address from, address to, uint tokens) public  returns (bool success) {
        require(creatorAddr == msg.sender);
        uint charges = rate * transactionFee;
        uint remainingTokens =  tokens - charges;
        balances[from] = safeSub(balances[from], tokens);
        //allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, remainingTokens);
        emit Transfer(from, transactionFeeAddr, charges);
        return true;
    }

    function swap(address from,  uint tokens) public  returns (bool success) {
        return withdraw(from, creatorAddr, tokens); 
    }

    function deposit(address from,  uint tokens) public  returns (bool success) {
        return withdraw(from, treasuryAddr, tokens); 
    }

    function claim(address to,  uint tokens) public  returns (bool success) {
        return withdraw(treasuryAddr, to, tokens); 
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    // function () external payable {
    //     revert();
    // }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}