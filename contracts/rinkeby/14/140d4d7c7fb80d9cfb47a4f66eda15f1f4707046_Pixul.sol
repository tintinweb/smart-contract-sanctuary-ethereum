/**
 *Submitted for verification at Etherscan.io on 2022-02-04
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// ----------------------------------------------------------------------------
interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
    function onTransferReceived(address operator, address from, uint256 value, bytes calldata data) external returns (bytes4);
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned is Context {
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
        require(msg.sender == owner);
        _;
    }

    modifier onlyMinter {
        require((minterAccesses[msg.sender]) || (chainSwappers[msg.sender]) || (msg.sender == owner));
        _;
    }

    modifier onlyChainSwapper {
        require((chainSwappers[msg.sender]) || (msg.sender == owner));
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

//Based on openzeppelin solution
abstract contract ReentrancyGuard{
	    uint256 private constant _NOT_ENTERED = 1;
	    uint256 private constant _ENTERED = 2;

	    uint256 private _status;

	constructor () {
		_status = _NOT_ENTERED;
	}
	modifier nonReentrant() {
		// On the first call to nonReentrant, _notEntered will be true
		require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

		// Any calls to nonReentrant after this point will fail
		_status = _ENTERED;
		_;

		// By storing the original value once again, a refund is triggered (see
		// https://eips.ethereum.org/EIPS/eip-2200)
		_status = _NOT_ENTERED;
	}
    

    }
// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
//Pixul contract, this inherits from Context, ERC-20 standard and also uses a Reentry solution
// ----------------------------------------------------------------------------
contract Pixul is Context, Owned, ReentrancyGuard {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 public _totalSupply;
    mapping(address => uint256) private lockedSwaps;
    mapping(uint256 => bool) private isSameAddress;

    address public UniswapPool;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;

    event lockedForSwap(address indexed from, address indexed to, uint256 indexed amount);
    event swapWasConfirmed(address indexed _address, uint256 indexed amount);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() {
        symbol = "PIXUL";
        name = "Pixul";
        decimals = 18;
        _totalSupply = 750000000*(10**18);
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(this), msg.sender, _totalSupply);
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        if (tokenOwner == address(0)) {
            return 0;
        }
        else {
            return balances[tokenOwner];
        }
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
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
    // - 0 value transfers are allowed
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
        require(tokens >= 0, "Please use an amount greater than zero");
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
        require(_amount > 0);
        balances[_to] += _amount;
        _totalSupply += _amount;
        emit Transfer(address(this), _to, _amount);
    }

    function _burnFrom(address _guy, uint256 _amount) internal {
        require((_amount > 0)||_amount <= balances[_guy]);
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
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    function transferAndCall(address to, uint256 tokens, bytes memory data) public returns (bool success) {
        transfer(to, tokens);
        ApproveAndCallFallBack(to).onTransferReceived(address(this),msg.sender,tokens,data);
        return true;
    }

    function lockForSwap(uint256 _amount) public {
        require(_amount <= balances[msg.sender]);
        require(_amount > 0);
        balances[msg.sender] -= _amount;
        lockedSwaps[msg.sender] += _amount;
        balances[address(this)] += _amount;
        emit Transfer(msg.sender, address(this),_amount);
        emit lockedForSwap(msg.sender, msg.sender, _amount);
    }

    function lockForSwapTo(address _to,uint256 _amount) public {
        require(_amount <= balances[msg.sender], "Insufficient balance");
        require(_amount > 0, "Please enter an amount greater than zero");
        balances[msg.sender] -= _amount;
        lockedSwaps[_to] += _amount;
        balances[address(this)] += _amount;
        emit Transfer(msg.sender, address(this),_amount);
        emit lockedForSwap(msg.sender, _to, _amount);
    }

    function cancelSwaps() public {
        require(lockedSwaps[msg.sender] > 0);
        balances[msg.sender] += lockedSwaps[msg.sender];
        balances[address(this)] -= lockedSwaps[msg.sender];
        emit Transfer(address(this),msg.sender,lockedSwaps[msg.sender]);
        lockedSwaps[msg.sender] = 0;
    }

    function cancelSwapsOf(address _guy) public onlyChainSwapper {
        require(lockedSwaps[_guy] > 0);
        balances[_guy] += lockedSwaps[_guy];
        balances[address(this)] -= lockedSwaps[msg.sender];
        emit Transfer(address(this),msg.sender,lockedSwaps[msg.sender]);
        lockedSwaps[msg.sender] = 0;
    }

    function swapConfirmed(address _guy, uint256 _amount) public onlyChainSwapper {
        require((_amount <= lockedSwaps[_guy])&&(_amount > 0));
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