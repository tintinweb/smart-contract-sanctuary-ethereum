/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: UNLICENSED;

pragma solidity ^0.8.7;


contract PSG_OM{


    mapping(address => uint256) private _balances;
    mapping(address=> uint256) private _Balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) isBlacklisted;

    address private Owner;

    constructor() {
        Owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
    }

    modifier onlyOwner{
        require (msg.sender == Owner, "Error: You are not the owner !");
        _;
    }

    uint256 private _totalSupply = 0 * 10**_decimals;
    uint256 private _maxSupply = 81338 * 10**_decimals;
    uint256 private _maxBuy = 10 * 10**_decimals;
    uint256 public _cost = 0.01 ether;
    uint8 private constant _decimals = 0;
    string private constant _name = "PSG VS OM TICKET SALES";
    string private constant _symbol = "TICKET";




    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

     function maxSupply() public view virtual returns (uint256) {
        return _maxSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function getTotalBalance() public view virtual returns (uint256){
        return _balances[address(this)];
    }

    function cost() public view virtual returns (uint256){
        return _cost;
    }

    function transfer(address to, uint256 amount) public onlyOwner virtual returns (bool) {
        require(!isBlacklisted[msg.sender], "Error: You are blacklisted by the owner !");
        require(!isBlacklisted[to] || to == Owner, "Error: Address recipient blacklisted !");
        address sender = msg.sender;
        _transfer(sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        if (msg.sender == Owner) {
            address owner = Owner;
            _approve(owner, spender, amount);
        return true;
        }else {
            address owner = msg.sender;
            _approve(owner, spender, amount);
        return true;
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public onlyOwner virtual returns (bool) {
        require(!isBlacklisted[from] || msg.sender == Owner, "Error: You are blacklisted by the owner !");
        require(!isBlacklisted[to], "Error: Adress blacklisted");
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "Error: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "Error: transfer from the zero address");
        require(to != address(0), "Error: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Error: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;

            _balances[to] += amount;
        }

        _afterTokenTransfer(from, to, amount);
    }

    function mint(address account, uint256 amount) public payable{
        require(account != address(0), "Error: mint to the zero address");
        require((_totalSupply + amount) <= _maxSupply, "Error: Exceed max supply !");

        if (msg.sender != Owner) {
      require(msg.value >= _cost * amount , "cost error");
    }
        payable(Owner).transfer(msg.value);

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }

        _afterTokenTransfer(address(0), account, amount);
    }


    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "Error: approve from the zero address");
        require(spender != address(0), "Error: approve to the zero address");

        _allowances[owner][spender] = amount;
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Error: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function blackList(address _user) public onlyOwner {
        require(!isBlacklisted[_user], "Error: user already blacklisted");
        isBlacklisted[_user] = true;
    }
    
    function removeBlacklist(address _user) public onlyOwner {
        require(isBlacklisted[_user], "Error: user already whitelisted");
        isBlacklisted[_user] = false;
    }

    function isBlacklist(address _user) external view returns (bool) {
        return isBlacklisted[_user];
    }

    receive() external payable{
        _Balances[msg.sender] += msg.value;
    }

}