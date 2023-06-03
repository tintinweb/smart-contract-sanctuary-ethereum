// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IPinkAntiBot {
  function setTokenOwner(address owner) external;

  function onPreTransferCheck(
    address from,
    address to,
    uint256 amount
  ) external;
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    address internal _owner;
    mapping(address => uint256) private _basic_balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromReward;
    bool public fee_off; 
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    // pinksale AntiBot
    IPinkAntiBot public pinkAntiBot;
    bool public antiBotEnabled  = false;
    uint256 totalFees;
    struct Holders{
            uint256 timestamp;
            uint256 fee_stamp;
        }
    mapping(address => Holders) public holders;
    address internal _marketing;
    address internal _buyback;
    uint256 marketing_fee = 0;
    uint256 burn_fee      = 0;
    uint256 rewards_fee   = 0;
    uint256 buyback_fee   = 0;
    uint256 all_fee = marketing_fee + burn_fee + rewards_fee + buyback_fee;

    constructor(
        string memory name_, 
        string memory symbol_,
        uint256 totalSupply_,
        address marketing_,
        address buyback_,
        address pinkAntiBot_
        ) {
        totalSupply_ = totalSupply_ * 10 ** 18;
        _name = name_;
        _symbol = symbol_;        
        _owner = msg.sender;   
        _buyback = buyback_;        
        _marketing = marketing_;     
        _totalSupply = totalSupply_;
        _isExcludedFromFee[msg.sender] = true;
        _basic_balances[msg.sender] = totalSupply_;        
        emit Transfer(address(0), msg.sender, totalSupply_);
        // Initiate PinkAntiBot instance from its address
        pinkAntiBot = IPinkAntiBot(pinkAntiBot_);
        // Register deployer as the owner of this token with PinkAntiBot contract
        pinkAntiBot.setTokenOwner(msg.sender);
        // Enable using PinkAntiBot in this contract       
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
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
        uint256 show_balance;
         if (_isExcludedFromReward[account]) {
             show_balance =  _basic_balances[account];
        } else { 
             show_balance =  _basic_balances[account] + (totalFees - holders[account].fee_stamp) * _basic_balances[account] / _totalSupply;
        }
        return show_balance;
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
        // When you done launching, you can call setUsingAntiBot(false) to
        // disable PinkAntiBot in your token instead of interacting with the
        // PinkAntiBot contract
        if (antiBotEnabled) {
        // Check for malicious transfers
        pinkAntiBot.onPreTransferCheck(from, to, amount);
        }        
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = balanceOf(from);
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");  
        if ( _isExcludedFromFee[from] ||  _isExcludedFromFee[to] || fee_off) {
            _basic_balances[from] = fromBalance - amount;
            _basic_balances[to]  = balanceOf(to) + amount;
            emit Transfer(from, to, amount);
        } else {
            _basic_balances[from] = fromBalance - amount;
            _basic_balances[to]  = balanceOf(to) + amount * (100 - all_fee) / 100;
            emit Transfer(from, to, amount * (100 - all_fee) / 100);
            //rewards  
            holders[from].fee_stamp = totalFees;
            holders[to].fee_stamp = totalFees;
            totalFees += amount * rewards_fee / 100;
            //burn
            _totalSupply -= amount * burn_fee / 100;
            emit Transfer(from, address(0), amount * burn_fee / 100);
            //marketing 
            _basic_balances[_marketing]  = balanceOf(_marketing) + amount * marketing_fee / 100;     
            emit Transfer(from, _marketing, amount * marketing_fee  / 100);
            //buyback
             _basic_balances[_buyback]  = balanceOf(_buyback) + amount * buyback_fee / 100; 
        }
        _afterTokenTransfer(from, to, amount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function excludeFromReward(address account) public onlyOwner {
        _isExcludedFromReward[account] = true;
    }
    
    function includeInReward(address account) public onlyOwner {
        _isExcludedFromReward[account] = false;
    }

    function flip_fee_off() public onlyOwner {
        fee_off = !fee_off;
    }   
    
    function flip_antiBotEnabled() public onlyOwner {
        antiBotEnabled = !antiBotEnabled;
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