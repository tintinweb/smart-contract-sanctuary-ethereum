// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

error Not__Owner();
error Address__Zero();
error Transfer__Exceed();

contract MetaToken {
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;

    //fix supply
    uint256 private immutable _totalSupply;

    //contract owner
    address private _owner;

    //event

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier OnlyOwner() {
        if (msg.sender != _owner) revert Not__Owner();
        _;
    }

    /**
     *@dev sets the values for initial supply, owner，name,symbol
     */
    constructor(
        uint256 initialSupply,
        string memory name_,
        string memory symbol_
    ) {
        _totalSupply = initialSupply;
        _owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _mint(_owner, initialSupply);
    }

    /**
     * @dev return the contract owner
     */
    function getOwner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev change contract owner
     */
    function changeOwner(address new_owner) public OnlyOwner {
        _owner = new_owner;
    }

    /**
     *@dev return the token's name
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     *@dev return the token's symbol
     */

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     *@dev return the tokens decimals
     */

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    /**
     *@dev return total supply tokens
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev return the balance of account
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balance[account];
    }

    /**
     *@dev mint tokens
     */
    function _mint(address account, uint256 amount) internal OnlyOwner {
        //require(account != address(0), "ERC20: mint to the zero address");
        if (account == address(0)) revert Address__Zero();
        _beforeTokenTransfer(address(0), account, amount);
        _balance[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     *@dev transfer tokens from sender to 'to'
     */
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     *@dev transfer from
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return (_allowances[owner][spender]);
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subedValue) public returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subedValue, "ERC20: decrease allowance below zero!");
        unchecked {
            _approve(owner, spender, currentAllowance - subedValue);
        }
        return true;
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20:insufficent allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        if (owner == address(0) || spender == address(0)) revert Address__Zero();
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        // require(from != address(0), "ERC20:transfer from zero address ");
        if (from == address(0) || to == address(0)) revert Address__Zero();
        //require(to != address(0), "ERC20:transfer to zero address");

        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balance[from];
        //require(fromBalance >= amount, "ERC20:transfer amount exceeds balance");
        if (fromBalance < amount) revert Transfer__Exceed();
        unchecked {
            _balance[from] = fromBalance - amount;
        }
        _balance[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}
}