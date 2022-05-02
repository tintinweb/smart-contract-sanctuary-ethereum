// SPDX-License-Identifier: MIT
// Created by Muhammad Irfan 
//Email address: [email protected]

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

contract ERC20 is Context, IERC20, IERC20Metadata {
    
    //mapping used in contract
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    //variables used in contract
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    bool private _paused = false;
    uint8 private _decimals;
    address private _owner;
    uint256 private _tokenPrice;
    address private _contractAddress;


    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _owner = _msgSender();
        _decimals = decimals_;
        _tokenPrice = 0.001 ether;
        _contractAddress = address(this);
    }

     modifier onlyOwner(address sender_){
        require (sender_ == _owner, "ERC20: Only owner of contract is allowed");
        _;
    }

    //Show token name
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    //Show token symbol
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    //Show number of decimals
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    //Show total supply of tokens
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    //Show balance of a given account address
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    //Display price of one token
    function tokenPrice () public view returns(uint256){
        return _tokenPrice;
    }

    function setTokenPrice(uint8 newPrice_) public onlyOwner (_msgSender()){
        require (newPrice_ < 0, "ERC Token price can not be set less then zero");
        _tokenPrice = newPrice_;
    }

    function purchaseTokens (uint256 numberOfTokens_) public payable returns(bool, uint256, uint256){
        address purchaser = _msgSender();
        uint256 requiredValue = numberOfTokens_ * _tokenPrice;
        uint256 sentValue = msg.value / (10**18);

        require (sentValue <= requiredValue, "Transfered token value is less than required value");

        _transfer(_owner, purchaser, numberOfTokens_);

        return (true,requiredValue, sentValue);
    }


    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }

    fallback() external payable {
        emit Received(_msgSender(), msg.value);
    }

    function getContractBalance() public view onlyOwner(_msgSender()) returns (uint256){
        return _contractAddress.balance;
    }

    function transferEthToOwner () public payable onlyOwner(_msgSender()) {
        uint256 transferValue = _contractAddress.balance;
        address payable receiverAddress  = payable(_owner);
        receiverAddress.transfer(transferValue);
        
    }

    //Transfer tokens from token owner account to another account
    function transfer(address to, uint256 tokens) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, tokens);
        return true;
    }

    //Show allowince given to the spender
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    //Approve allowance for spender
    function approve(address spender, uint256 tokens) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, tokens);
        return true;
    }

    //Transfer tokens from owner's account to other accounted by the approved sender
    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, tokens);
        _transfer(from, to, tokens);
        return true;
    }

    //Increase provided allowance
    function increaseAllowance(address spender, uint256 addedTokens) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedTokens);
        return true;
    }

    //Decrease provided allownce
    function decreaseAllowance(address spender, uint256 subtractedTokens) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedTokens, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedTokens);
        }

        return true;
    }

    /**
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokens
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokens);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= tokens, "ERC20: transfer tokens exceeds balance");
        unchecked {
            _balances[from] = fromBalance - tokens;
        }
        _balances[to] += tokens;

        emit Transfer(from, to, tokens);

        _afterTokenTransfer(from, to, tokens);
    }

    //Mint tokns only by owner of the contract
    function _mint(uint256 tokens) public virtual onlyOwner(_msgSender()) {
        
        _beforeTokenTransfer(address(0), _msgSender(), tokens);

        _totalSupply += tokens;
        _balances[_msgSender()] += tokens;
        emit Transfer(address(0), _msgSender(), tokens);

        _afterTokenTransfer(address(0), _msgSender(), tokens);
    }

    //Burn tokens
    function _burn(uint256 tokens) public virtual {
        
        _beforeTokenTransfer(_msgSender(), address(0), tokens);

        uint256 accountBalance = _balances[_msgSender()];
        require(accountBalance >= tokens, "ERC20: burn tokens exceeds balance");
        unchecked {
            _balances[_msgSender()] = accountBalance - tokens;
        }
        _totalSupply -= tokens;

        emit Transfer(_msgSender(), address(0), tokens);

        _afterTokenTransfer(_msgSender(), address(0), tokens);
    }

    
    function _approve(
        address owner,
        address spender,
        uint256 tokens
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = tokens;
        emit Approval(owner, spender, tokens);
    }

    
    function _spendAllowance(
        address owner,
        address spender,
        uint256 tokens
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= tokens, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - tokens);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokens
    ) internal virtual {}
    
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokens
    ) internal virtual {}
}