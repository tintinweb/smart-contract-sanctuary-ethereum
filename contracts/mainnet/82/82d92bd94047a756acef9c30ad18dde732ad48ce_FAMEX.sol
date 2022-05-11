/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract FAMEX is ERC20 {
    address private immutable FAME_Global;
    string public constant name = 'famex';
    string public constant symbol = 'FMX';
    uint8 public constant decimals = 18;
    uint256 public override totalSupply = 10**9 * 10**18;

    mapping(address => uint256) public availableBalanceOf;
    mapping(address => uint256) public lockedBalanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    modifier onlyFAME() {
        require(msg.sender == FAME_Global, "famex: caller is not approved");
        _;
    }

    constructor() {
        FAME_Global = msg.sender;
        availableBalanceOf[FAME_Global] += totalSupply;

        emit Transfer(address(0), FAME_Global, totalSupply);
    }
    
    function balanceOf(address account) external view override returns (uint256) {
        return availableBalanceOf[account] + lockedBalanceOf[account];
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = allowance[sender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = allowance[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function burn(uint256 amount) external {
        require(msg.sender != address(0), "ERC20: transfer from the zero address");

        uint256 senderBalance = availableBalanceOf[msg.sender];
        require(senderBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            availableBalanceOf[msg.sender] = senderBalance - amount;
        }
        totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = availableBalanceOf[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            availableBalanceOf[sender] = senderBalance - amount;
        }
        availableBalanceOf[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    uint256 public dDay = 7956915742; // 2222-02-22T22:22:22Z
    struct lock {
        uint256 expiry;
        uint256 amount;
    }
    mapping(address => mapping(uint256 => lock)) public locks; // address to lockId to Lock
    mapping(address => uint256) public minLockId;
    mapping(address => uint256) public maxLockId;
    uint256 private month = 30 days;

    function transferWithLock(address _to, uint256 _expiry, uint256 _amount) public {
        require(dDay + _expiry > block.timestamp, "famex: invalid expiration time");
        require(msg.sender != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(availableBalanceOf[msg.sender] >= _amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            availableBalanceOf[msg.sender] = availableBalanceOf[msg.sender] - _amount;
        }
        lockedBalanceOf[_to] += _amount;
        // uint256 lockId = ++maxLockId[_to];
        locks[_to][++maxLockId[_to]] = lock(_expiry, _amount);

        emit Transfer(msg.sender, _to, _amount);
        
    }
    function lockPreset_Team_Advisor_Partner(address _to, uint256 _amount) external {
        uint256 quarter = _amount / 4;
        transferWithLock(_to, 18 * month, quarter);
        transferWithLock(_to, 21 * month, quarter);
        transferWithLock(_to, 24 * month, quarter);
        transferWithLock(_to, 27 * month, quarter);
    }
    function lockPreset_PrivateInvestor(address _to, uint256 _amount) external {
        uint256 deci = _amount / 10;
        transferWithLock(_to, 0, deci * 2);
        for (uint256 i = 1; i < 9; i++) {
            transferWithLock(_to, i * month, deci);
        }
    }
    function lockPreset_PublicInvestor(address _to, uint256 _amount) external {
        transferWithLock(_to, 0, _amount / 2);
        transferWithLock(_to, month, _amount / 4);
        transferWithLock(_to, 2 * month, _amount / 4);
    }
    function lockPreset_Treasury(address _to, uint256 _amount) external {
        uint256 deci = _amount / 10;
        for (uint256 i = 0; i < 10; i++) {
            transferWithLock(_to, (24 + 3 * i) * month, deci);
        }
    }
    
    function unlockableBalanceOf(address _account) public view returns (uint256) {
        uint256 balance = 0;
        for (uint256 i = minLockId[_account]; i <= maxLockId[_account]; i++) {
            if (dDay + locks[_account][i].expiry < block.timestamp) {
                balance += locks[_account][i].amount;
            }
        }
        return balance;
    }
    function unlock(address _account) public {
        uint256 balance = 0;
        for (uint256 i = minLockId[_account]; i <= maxLockId[_account]; i++) {
            if (dDay + locks[_account][i].expiry < block.timestamp) {
                balance += locks[_account][i].amount;
                locks[_account][i].amount = 0;
                if (minLockId[_account] == i) {
                    minLockId[_account]++;
                }
            }
        }

        lockedBalanceOf[_account] -= balance;
        availableBalanceOf[_account] += balance;
    }
    function unlockBatch(address[] memory _accounts) external {
        for (uint256 i = 0; i < _accounts.length; i++) {
            unlock(_accounts[i]);
        }
    }

    function setDDay(uint256 _dDay) external onlyFAME {
        require(_dDay > block.timestamp, "famex: D-Day must be in the future");
        dDay = _dDay;
    }
}