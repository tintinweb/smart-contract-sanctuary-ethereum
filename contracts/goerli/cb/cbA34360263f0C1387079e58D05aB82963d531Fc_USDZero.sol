pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

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

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IUSDC {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor()  {
        owner = 0x1eF8855FC0DB9a88ff6842431512CC4b9bD0CC1F;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals
// ----------------------------------------------------------------------------

contract USDZero is IERC20, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    address public dead = 0x000000000000000000000000000000000000dEaD; 
    address public _usdcAddress;

    mapping(address => uint) balances;

    IUSDC public usdc;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(address usdcInitAddress) {
        symbol = "USDZ";
        name = "USDZero";
        decimals = 18;
        _totalSupply = 10000 * 10**decimals;
        _usdcAddress = usdcInitAddress;
        IUSDC _usdc = IUSDC(_usdcAddress);
        usdc = _usdc;
        balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
    }

    // ------------------------------------------------------------------------
    // Buy presale tokens
    // ------------------------------------------------------------------------
    function buyPresale(uint tokens) public returns (bool success) {
        require(tokens <= balances[address(this)], "Presale: amount must be less or equal to remaining presale funds");
        usdc.transferFrom(msg.sender, dead, tokens);
        transfer(msg.sender, tokens);
        emit Transfer(address(this), msg.sender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }

  
    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public override returns (bool success) {
        require(isContract(to) == false, "Address: sending to contracts blocked");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    receive () external payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        require(tokenAddress != address(this), "Presale: cannot transfer out presale tokens");
        return IERC20(tokenAddress).transfer(owner, tokens);
    }

    // ------------------------------------------------------------------------
    // Check if account is contract
    // ------------------------------------------------------------------------
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}