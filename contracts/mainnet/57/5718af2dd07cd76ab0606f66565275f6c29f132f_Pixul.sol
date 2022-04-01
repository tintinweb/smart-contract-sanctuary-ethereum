/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT
// PIXUL Token Smart Contract for the PIXUL Ecosystem
// Contract using solidity 8 for Pixul
/**

   Pixul | Developing Crypto Solutions

   Building utilizations for crypto.

   We believe the adoption of cryptocurrency worldwide is inevitable so here at Pixul
   we aim to develop applications and technology that focus on utilizing crypto as a means of service and needs for everyday use.

   website: https://pixul.io
   telegram: https://t.me/pixulchat
   twitter: https://twitter.com/pixul_
   discord: https://discord.gg/3qHCDeB68w
   documents: https://www.pixul.io/documents

   Smart contract written by Pixul Team combined with several public contracts for optimization

*/
//
// ----------------------------------------------------------------------------
// 'Pixul' token contract
//
// Symbol      : PIXUL
// Name        : Pixul
// Supply     : 750000000
// Decimals    : 18
//
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;
    mapping (address => bool) public minterAccesses;
    mapping (address => bool) public chainSwappers;
    event AllowedMinter(address indexed _newMinter);
    event RevokedMinter(address indexed _revoked);

    event AllowedSwapper(address indexed _newSwapper);
    event RevokedSwapper(address indexed _revoked);

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Admin: onlyOwner only function");
        _;
    }

    modifier onlyMinter {
        require((minterAccesses[msg.sender]) || (chainSwappers[msg.sender]) || (msg.sender == owner), "Admin: Contract admin only");
        _;
    }

    modifier onlyChainSwapper {
        require((chainSwappers[msg.sender]) || (msg.sender == owner), "Admin: ChainSwapper only");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
        require(_newOwner != address(0), "Admin: onlyOwner can transfer contract ownership only");
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner, "Admin: newOwner can accept ownership of contract only");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    function allowMinter(address _newMinter) public onlyOwner {
        minterAccesses[_newMinter] = true;
        emit AllowedMinter(_newMinter);
    }
    function revokeMinter(address _revoked) public onlyOwner {
        minterAccesses[_revoked] = false;
        emit RevokedMinter(_revoked);
    }

    function allowSwapper(address _newSwapper) public onlyOwner {
        chainSwappers[_newSwapper] = true;
        emit AllowedSwapper(_newSwapper);
    }

    function revokeSwapper(address _revoked) public onlyOwner {
        chainSwappers[_revoked] = false;
        emit RevokedSwapper(_revoked);
    }

    function isMinter(address _guy) public view returns (bool) {
        return minterAccesses[_guy];
    }
    function isSwapper(address _guy) public view returns (bool) {
        return chainSwappers[_guy];
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// Pixul contract, this inherits from Owned
// ----------------------------------------------------------------------------
contract Pixul is Owned{
    string public symbol;
    string public name;
    uint8 public immutable decimals;
    uint256 public _totalSupply;
    mapping(address => uint256) private lockedSwaps;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;

    event lockedForSwap(address indexed from, address indexed to, uint256 indexed amount);
    event swapWasConfirmed(address indexed _address, uint256 indexed amount);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(string memory _symbol, string memory _name, uint8 _decimals) {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        _totalSupply = 750000000*(10**18);
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(this), msg.sender, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are not allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        _transfer(msg.sender, to, tokens);
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
    // - 0 value transfers are not-allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        if(from == msg.sender) {
            _transfer(msg.sender, to, tokens);
        }
        else {
            require(allowed[from][msg.sender] >= tokens, "This amount exceeds your current balance");
            if (from != address(this)) {
                allowed[from][msg.sender] -= tokens;
            }
            _transfer(from, to, tokens);
        }
        return true;
    }

    function _transfer(address from, address to, uint tokens) internal {
        require(balances[from] >= tokens, "Insufficient balance");
        require(tokens > 0, "Please use an amount greater than zero");
        balances[from] -= tokens;
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    // ------------------------------------------------------------------------
    // mints token
    // ------------------------------------------------------------------------
    function mintTo(address _to, uint256 _amount) public onlyMinter {
        require(_amount > 0, "Admin: Amount must be greater than 0");
        balances[_to] += _amount;
        _totalSupply += _amount;
        emit Transfer(address(this), _to, _amount);
    }

    function _burnFrom(address _guy, uint256 _amount) internal {
        require((_amount > 0) && _amount <= balances[_guy], "Admin: Amount must be greater than 0/guy must have enough tokens to burn");
        balances[_guy] -= _amount;
        _totalSupply -= _amount;
        emit Transfer(_guy, address(this), _amount);
    }

    function burnFrom(address _guy, uint256 _amount) public onlyOwner {
        _burnFrom(_guy, _amount);
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferAndCall(address to, uint256 tokens) public returns (bool success) {
        transfer(to, tokens);
        return true;
    }

    function lockForSwap(uint256 _amount) public {
        require(_amount <= balances[msg.sender], "Admin: Insufficient balance");
        require(_amount > 0, "Admin: You must enter an amount greater than 0");
        balances[msg.sender] -= _amount;
        lockedSwaps[msg.sender] += _amount;
        balances[address(this)] += _amount;
        emit Transfer(msg.sender, address(this),_amount);
        emit lockedForSwap(msg.sender, msg.sender, _amount);
    }

    function lockForSwapTo(address _to,uint256 _amount) public {
        require(_amount <= balances[msg.sender], "Admin: Insufficient balance");
        require(_amount > 0, "Admin: You must enter an amount greater than 0");
        balances[msg.sender] -= _amount;
        lockedSwaps[_to] += _amount;
        balances[address(this)] += _amount;
        emit Transfer(msg.sender, address(this),_amount);
        emit lockedForSwap(msg.sender, _to, _amount);
    }

    function cancelSwaps() public {
        require(lockedSwaps[msg.sender] > 0, "Admin: There are not enough tokens in this swap to cancel");
        balances[msg.sender] += lockedSwaps[msg.sender];
        balances[address(this)] -= lockedSwaps[msg.sender];
        emit Transfer(address(this),msg.sender,lockedSwaps[msg.sender]);
        lockedSwaps[msg.sender] = 0;
    }

    function cancelSwapsOf(address _guy) public onlyChainSwapper {
        require(lockedSwaps[_guy] > 0 , "Admin: This swap does not exist");
        balances[_guy] += lockedSwaps[_guy];
        balances[address(this)] -= lockedSwaps[msg.sender];
        emit Transfer(address(this),msg.sender,lockedSwaps[msg.sender]);
        lockedSwaps[msg.sender] = 0;
    }

    function swapConfirmed(address _guy, uint256 _amount) public onlyChainSwapper {
        require((_amount <= lockedSwaps[_guy])&&(_amount > 0), "Admin: Insufficient balance or amount less than 0");
        balances[address(this)] -= _amount;
        _totalSupply += _amount;
        lockedSwaps[_guy] -= _amount;
        emit swapWasConfirmed(_guy, _amount);
    }

    function pendingSwapsOf(address _guy) public view returns (uint256) {
        return lockedSwaps[_guy];
    }

    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    fallback() external {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}