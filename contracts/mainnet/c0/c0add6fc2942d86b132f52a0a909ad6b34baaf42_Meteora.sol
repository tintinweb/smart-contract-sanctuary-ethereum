/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/** 
 * METEORA
 *
 * Lunaris Incorporation - 2022
 * https://meteora.lunaris.inc
 *
 * TGE contract of the METEORA MRA Token, following the
 * ERC20 standard on Ethereum.
 *
 * Audited on 17/03/2022 - info: meteora(at)lunaris.inc
 * 
 * TOTAL FIXED SUPPLY: 100,000,000 MRA
 * 
**/

contract Meteora {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    address private Lunaris;
    uint8 private _decimals;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;
    
    constructor() {
        _name = "Meteora";
        _symbol = "MRA";
        _decimals = 18;
        _totalSupply = 100000000 * (10 ** 18);
        
        // Owner - Lunaris Incorporation
        Lunaris = address(0xf0fA5BC481aDB0ed35c180B52aDCBBEad455e808);
        
        // All of the tokens are sent to the Lunaris Wallet
        // then sent to external distribution contracts following
        // the Tokenomics documents.
        //
        // Please check out https://meteora.lunaris.inc for more information.
        _balances[Lunaris] = _totalSupply;
    }
    
    /*******************/
    /* ERC20 FUNCTIONS */
    /*******************/
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        
        require(currentAllowance >= amount, "METEORA: You do not have enough allowance to perform this action!");
        
        _transfer(sender, recipient, amount);
        
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    
    /*************************/
    /* ADDITIONNAL FUNCTIONS */
    /*************************/
    
    /** 
     * MRA is burnable. Any MRA owner can burn his tokens if need be.
     * The total supply is updated accordingly.
    **/
    
    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    
    /**********************/
    /* CONTRACT FUNCTIONS */
    /**********************/
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "METEORA: The sender cannot be the Zero Address!");
        require(recipient != address(0), "METEORA: The recipient cannot be the Zero Address!");
        
        uint256 senderBalance = _balances[sender];
        
        require(senderBalance >= amount, "METEORA: Sender does not have enough MRA for this operation!");
        
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "METEORA: The owner cannot be the Zero Address!");
        require(spender != address(0), "METEORA: The spender cannot be the Zero Address!");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _burn(address owner, uint256 amount) private {
        uint256 accountBalance = _balances[owner];
        
        require(owner != address(0), "METEORA: Owner cannot be the Zero Address!");
        require(accountBalance >= amount, "METEORA: You do not have enough tokens to burn!");
        
        unchecked {
            _balances[owner] = accountBalance - amount;
        }
        
        _totalSupply -= amount;
        
        emit Burned(owner, amount);
    }
    
    /**********/
    /* EVENTS */
    /**********/
    
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Burned(address indexed burner, uint256 amount);
    
    /***********/
    /* CONTEXT */
    /***********/
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}