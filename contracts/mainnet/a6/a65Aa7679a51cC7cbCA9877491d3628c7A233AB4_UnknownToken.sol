/**
 *Submitted for verification at Etherscan.io on 2023-02-23
*/

pragma solidity ^0.8.14;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract UnknownToken is IERC20,IERC20Metadata {
    struct UnknownProject {
        uint blockNumber;
        address project;
        string name;
    }

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    UnknownProject[] public _projects;      //record all unknown projects.

    uint256 private _mintSupply;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _contractOwner;

    //only cntract owner call function.
    modifier onlyOwner() {
        require(msg.sender == _contractOwner);
        _;
    }

    event Deploy(address owner, string name, string symbol, uint256 supply);
    event Publish(address project, string name, uint blockNumber);
    event ChangeOwner(address account);

    constructor(address owner_, string memory name_, string memory symbol_, uint256 supply_) {
        _name = name_;
        _symbol = symbol_;
        _decimals =  0;
        _totalSupply = 0;
        _mintSupply = 100_000_000;
        _contractOwner = owner_;

        emit Deploy(owner_, name_, symbol_, supply_);
        _mint(_contractOwner, supply_);
    }

    function changeOwner(address account) external onlyOwner {
        _contractOwner = account;

        emit ChangeOwner(account);
    }

    function publish(address project, string memory name) external onlyOwner {
        _mint(_contractOwner, _mintSupply);
        _projects.push(UnknownProject(block.number, project, name));

        emit Publish(project, name, block.number);
    }

    function burnFrom(address from, uint256 amount) public returns(bool) {
        _spendAllowance(from, msg.sender, amount);
        _burn(msg.sender, amount);
        return true;
    }

    //IERC20Metadata
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
    //---

    //IERC20
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        unchecked {
            _approve(msg.sender, spender, amount);
        }
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }
    //---

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        unchecked {
            _approve(msg.sender, spender, allowance(msg.sender, spender) + addedValue);
        }
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(amount > _totalSupply)
            revert();

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        if(amount > _totalSupply)
            revert();

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        if(amount > _totalSupply)
            revert();

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}