// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
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
}

abstract contract ERC20Burnable is Context, ERC20 {
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract ERC20Stakeable is ERC20, ERC20Burnable, ReentrancyGuard {
    // Staker info
    struct Staker {
        // The deposited tokens of the Staker
        uint256 deposited;
        // Last time of details update for Deposit
        uint256 timeOfLastUpdate;
    }

    // Minimum hold time
    uint256 public minHoldTime = 182.5 days;

    // Rewards on min hold time.
    uint256 public minReward = 10;

    // Maximum hold time
    uint256 public maxHoldTime = 365 days;

    // Rewards on max hold time.
    uint256 public maxReward = 100;

    // total hold amount
    uint256 public soldTokens;

    address[] internal _stakers;

    // Mapping of address to Staker info
    mapping(address => Staker) internal stakers;

    event Invest(address indexed sender, uint256 amount); 
    event Withdraw(address indexed sender, uint256 amount);

    // Constructor function
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    // If address has no Staker struct, initiate one. If address already was a stake,
    // calculate the rewards, reset the last time of
    // deposit and then add _amount to the already deposited amount.
    // Burns the amount staked.
    function deposit(uint256 _amount) external nonReentrant {
        require(_amount >= 0, "Amount smaller than minimimum deposit");
        require(balanceOf(msg.sender) >= _amount, "Can't stake more than you own");

        Staker memory _current_stake = stakers[msg.sender];

        require(_current_stake.deposited == 0, "Already staked");
        
        stakers[msg.sender].deposited = _amount;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        _stakers.push(msg.sender);

        soldTokens += _amount;

        _burn(msg.sender, _amount);

        emit Invest(msg.sender, _amount);
    }

    // Withdraw all stake and rewards and mints them to the msg.sender
    function withdraw() external nonReentrant {
        Staker memory _current_stake = stakers[msg.sender];

        require(_current_stake.deposited > 0, "You have no deposit");
        // require(is6MonthsCompleted(msg.sender), "6 Months Locked Staking");

        uint256 _rewards;

        if (isYearCompleted(msg.sender)) {
            _rewards = calculateStakeMaxReward(msg.sender);
        } else if (is6MonthsCompleted(msg.sender)) {
            _rewards = calculateStakeMinReward(msg.sender);
        }

        uint256 _deposit = _current_stake.deposited;

        stakers[msg.sender].deposited = 0;
        stakers[msg.sender].timeOfLastUpdate = 0;

        soldTokens -= _deposit;

        uint256 _amount = _rewards + _deposit;
        _mint(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }

    // Function useful for fron-end that returns user stake and rewards by address
    function getDepositInfo(address _user) public view returns (uint256 _stake, uint256 _rewards, uint256 _since) {
        _stake = stakers[_user].deposited;
        _since = stakers[_user].timeOfLastUpdate;

        if (isYearCompleted(_user)) {
            _rewards = calculateStakeMaxReward(_user);
        } else if (is6MonthsCompleted(_user)) {
            _rewards = calculateStakeMinReward(_user);
        }

        return (_stake, _rewards, _since);
    }

    // is 1 Year completed
    function isYearCompleted(address _staker) internal view returns (bool) {
        Staker memory _current_stake = stakers[_staker];

        return (_current_stake.timeOfLastUpdate + maxHoldTime) <= block.timestamp;
    }

    // is 6 Months completed
    function is6MonthsCompleted(address _staker) internal view returns (bool) {
        Staker memory _current_stake = stakers[_staker];

        return (_current_stake.timeOfLastUpdate + minHoldTime) <= block.timestamp;
    }

    /**
      * @notice
      * calculateStakeReward is used to calculate how much a user should be rewarded for their stakes
      * and the duration the stake has been active
     */
    function calculateStakeMinReward(address _staker) internal view returns(uint256){
        Staker memory _current_stake = stakers[_staker];

        return _current_stake.deposited * minReward / 100;
    }

    /**
      * @notice
      * calculateStakeReward is used to calculate how much a user should be rewarded for their stakes
      * and the duration the stake has been active
     */
    function calculateStakeMaxReward(address _staker) internal view returns(uint256){
        Staker memory _current_stake = stakers[_staker];

        return _current_stake.deposited * maxReward / 100;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract BCLToken is ERC20Stakeable, Ownable {
    constructor() ERC20Stakeable("BcoalToken", "BCLToken") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }
    
    function setMinHoldTime(uint256 _minHoldTime) external onlyOwner {
        minHoldTime = _minHoldTime;
    }

    function setMinReward(uint256 _minReward) external onlyOwner {
        minReward = _minReward;
    }

    function setMaxHoldTime(uint256 _maxHoldTime) external onlyOwner {
        maxHoldTime = _maxHoldTime;
    }

    function setMaxReward(uint256 _maxReward) external onlyOwner {
        maxReward = _maxReward;
    }

    function getStakers() external view onlyOwner returns (address[] memory) {
        address[] memory __stakers = new address[](_stakers.length);
        for (uint256 i = 0; i < _stakers.length; i++) {
            if (stakers[_stakers[i]].deposited <= 0) {
                continue;
            }

            __stakers[i] = _stakers[i];
        }

        return __stakers;
    }
}