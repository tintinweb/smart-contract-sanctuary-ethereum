/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/* My ethereum token */

abstract contract ERC20Token {
    function name() public view virtual returns (string memory);

    function symbol() public view virtual returns (string memory);

    function decimals() public view virtual returns (uint8);

    function totalSupply() public view virtual returns (uint256);

    function balanceOf(address _owner)
        public
        view
        virtual
        returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        public
        virtual
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual returns (bool success);

    function approve(address _spender, uint256 _value)
        public
        virtual
        returns (bool success);

    function allowance(address _owner, address _spender)
        public
        view
        virtual
        returns (uint256 remaining);

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address _to) public {
        require(msg.sender == owner);
        newOwner = _to;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Staking is ERC20Token, Ownable {
    string public _symbol;
    string public _name;
    uint8 public _decimals;
    uint256 public _totalSupply;
    address public _minter;
    uint256 public _tokenPriceInEther;
    uint256 public _stakedReward;
    uint256 public _stakedToken;

    mapping(address => uint256) _balances;
    mapping(address => uint256) _stakedTime;
    mapping(address => uint256) _locked;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        _name = "Uber";
        _symbol = "UBR";
        _decimals = 18;
        _minter = msg.sender;
        _tokenPriceInEther = 10;
        mint(_minter, 1000 * 10**_decimals);
    }

    event Bought(uint256 amount);

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner)
        public
        view
        override
        returns (uint256 balance)
    {
        return _balances[_owner];
    }

    function allowance(address _owner, address _spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount)
        public
        virtual
        override
        returns (bool)
    {
        address _owner = _msgSender();
        _approve(_owner, _spender, _amount);
        return true;
    }

    function transfer(address to, uint256 _amount)
        public
        virtual
        override
        returns (bool)
    {
        address _owner = _msgSender();
        _transfer(_owner, to, _amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from] - _locked[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] -= amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
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

    // Create a function modifyTokenBuyPrice and restrict access only to the owner.
    function modifyTokenBuyPrice(uint256 _tokenPrice) public onlyOwner {
        require(_tokenPrice > 0);
        _tokenPriceInEther = _tokenPrice;
    }

    function buyToken(address receiver) public payable {
        uint256 amount = msg.value * _tokenPriceInEther;
        require(amount > 0, "You need to send some ether");
        require(amount <= _totalSupply, "Not enough tokens in the reserve");
        _mint(receiver, amount);
        emit Bought(amount);
    }

    function stake(uint256 _amount) external returns (bool successOrfailure) {
        require(
            _amount <= (_balances[msg.sender] - _locked[msg.sender]),
            "Your balance is to low to perform this transaction, please buy some tokens and try again"
        );
        _stakedTime[msg.sender] = currentTime();
        _locked[msg.sender] += _amount;
        return true;
    }

    function unstake(uint256 _amount) external returns (bool successOrfailure) {
        require(
            _amount <= _locked[msg.sender],
            "You have no staked token or unstake amount is greater than the staked"
        );
        _stakedTime[msg.sender] = currentTime();
        _locked[msg.sender] -= _amount;

        return true;
    }

    function claimReward() external returns (bool successOrfailure) {
        require(_locked[msg.sender] > 0, "You have no staked Token");
        require(
            currentTime() > _stakedTime[msg.sender] + 7 days,
            "reward claiming is once in a week"
        );
        uint256 _reward = 5;
        _stakedTime[msg.sender] = currentTime();
        _mint(msg.sender, _reward);
        return true;
    }

    function currentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lockedCoin() public view returns (uint256) {
        return _locked[msg.sender];
    }

    function spendable() public view returns (uint256) {
        return _balances[msg.sender] - _locked[msg.sender];
    }
}