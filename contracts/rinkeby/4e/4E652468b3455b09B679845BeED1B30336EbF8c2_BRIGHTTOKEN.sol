// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract BRIGHTTOKEN {
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _locked;
    uint256 private _totalSupply;
    uint8 public decimals = 1;

    string private _name = "BRIGHT TOKEN";
    string private _symbol = "BTK";
    address private owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Lock(address account);
    event Unlock(address account);

    modifier onlyOwner() {
        require(_msgSender() == owner, "Only Contract Owner Available.");
        _;
    }

    constructor() {
        owner = _msgSender();
        _mint(owner, 1000000);
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public {
        _transfer(_msgSender(), to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(_locked[from] == false, "Transfer from the locked address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function mint(uint256 amount) external onlyOwner {
        _mint(_msgSender(), amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) external onlyOwner {
        _burn(_msgSender(), amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function lock(address account) public onlyOwner {
        require(msg.sender != account, "Cannot Lock Owner");
        _locked[account] = true;
        emit Lock(account);
    }

    function unlock(address account) public onlyOwner {
        _locked[account] = false;
        emit Unlock(account);
    }

    function getLocked(address account) public view returns (bool) {
        return _locked[account];
    }
}