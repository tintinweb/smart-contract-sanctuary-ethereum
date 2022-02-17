/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.4.26;

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
contract ERC20Interface {
    // function totalSupply() public returns (uint);
    // function balanceOf(address tokenOwner) public returns (uint balance);
    // function allowance(address tokenOwner, address spender) public returns (uint remaining);
    // function transfer(address to, uint tokens) public returns (bool success);
    // function approve(address spender, uint tokens) public returns (bool success);
    // function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to_1, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address indexed from, uint value);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public{}
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to_1);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public  {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract HelloCoin is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public tokenContract;
    uint256 public icoEndBlock;                              // last block number of ICO
    uint256 public maxSupply;                                // maximum token supply
    uint256 public minedTokenCount;                          // counter of mined tokens
    address public icoAddress;                               // address of ICO contract
    uint256 private multiplier;
    uint totalTaxedAmount=10;
    uint totalUniqueUsers=0;
    uint tax = 10;
    struct Miner {                                           // struct for mined tokens data
        uint256 block;
        address minerAddress;
    }
    mapping (uint256 => Miner) public minedTokens;           // mined tokens data

    mapping(address => uint) balances;    //default as private if not explicitly declare
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) internal isTokenHolder;
    event Sell(address buyer, uint256 amount);
    event MessageReward(address indexed miner, uint256 block, uint256 sta);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "HC";  //our coin's symbol
        name = "HelloCoin"; //our coin's name
        decimals = 0;
        _totalSupply = 1000000666;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public returns (uint) {
        return _totalSupply - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to_1, uint tokens) public returns (bool) {
        // require(balances[msg.sender] < tokens, "Insuficient funds");
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[to_1] = balances[to_1] + tokens - tax;
        if(!isTokenHolder[to_1]) {
            isTokenHolder[to_1] = true;
            totalUniqueUsers++;
        }
        totalTaxedAmount += tax;
        emit Transfer(msg.sender,to_1,tokens);
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
    function approve(address spender, uint tokens) public returns (bool success) {
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
    function transferFrom(address from, address to_1, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to_1] = safeAdd(balances[to_1], tokens);
        emit Transfer(from, to_1, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender,address token, uint256 tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, token, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    // function () public payable {
    //     revert();
    // }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return HelloCoin(tokenAddress).transfer(owner, tokens);
    }

    /*
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 value) public returns (bool success) {
        require(balanceOf(msg.sender) >= value);// Check if the sender has enough
        balances[msg.sender] -= value;            // Subtract from the sender
        _totalSupply -= value;                      // Updates totalSupply
        emit Burn(msg.sender, value);
        return true;
    }

    /*
     * Destroy tokens from other ccount
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address from, uint256 value) public returns (bool success) {
        require(balanceOf(msg.sender) >= value) ;// Check if the targeted balance is enough
        require(value <= allowed[from][msg.sender]);// Check allowance
        balances[from] -= value;                        // Subtract from the targeted balance
        allowed[from][msg.sender] -= value;             // Subtract from the sender's allowance
        _totalSupply -= value;                           // Update totalSupply
        emit Burn(from, value);
        return true;
    }
    function buyCoins(uint val_)public returns(bool){
        require(val_<=balances[msg.sender]);
        balances[msg.sender] = safeAdd(balances[msg.sender], val_);
        return true;
    }
    function sellCoins(address receiver,uint val_)public returns(bool){
        require(val_<=balances[msg.sender]);
        balances[msg.sender] = safeSub(balances[msg.sender], val_);
        balances[receiver]=safeAdd(balances[receiver],val_);
        emit Sell(receiver, val_);
        return true;
    }

    // function Reward() {
    //     if (icoAddress == address(0)) throw;                         // ICO address must be set up first
    //     if (msg.sender != icoAddress && msg.sender != owner) throw;  // triggering enabled only for ICO or owner
    //     if (block.number > icoEndBlock) throw;                       // rewarding enabled only before the end of ICO
    //     if (minedTokenCount * multiplier >= maxSupply) throw;
    //     if (minedTokenCount > 0) {
    //         for (uint256 i = 0; i < minedTokenCount; i++) {
    //             if (minedTokens[i].block == block.number) throw;
    //         }
    //     }
    //     _totalSupply += 1 * multiplier;
    //     balances[block.coinbase] += 1 * multiplier;                  // reward miner with one STA token
    //     minedTokens[minedTokenCount] = Miner(block.number, block.coinbase);
    //     minedTokenCount += 1;
    //     MessageReward(block.coinbase, block.number, 1 * multiplier);
    // }

    // function selfDestroy() onlyOwner {
    //     if (block.number <= icoEndBlock+14*5760) throw;           // allow to suicide STA token after around 2 weeks from the end of ICO
    //     suicide(this);
    // }
}