/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract Ownable {
    address public constant ZERO = address(0);
    address public constant DEAD = address(0xdead);

    address public owner;
    modifier onlyOwner() {
        require(owner == msg.sender, "Caller =/= owner.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwner(address newOwner) external onlyOwner {
        require(newOwner != DEAD && newOwner != ZERO, "Cannot renounce.");
        owner = newOwner;
    }
}

enum ChecktWithdrawalCodes { 
    OK, // 0 - all is ok
    ACCOUNT_NOT_FOUND, // 1 - account/merchant not found
    NOT_ALLOWED_ADDRESS, // 2 - the address is not on the allowed list 
    INSUFFICIENT_FUNDS, // 3 - insufficient funds to withdraw
    WITHDRAWAL_LIMIT_EXCEED // 4 - withdrawal limit exceeded
}

struct Withdrawal {
    uint256 amount;
    uint256 timestamp;
}

struct WithdrawalLimit {
    uint8 time;
    uint256 amount;
}

struct Account {
    Withdrawal[] withdrawals;
    WithdrawalLimit withdrawalLimit;
    uint256 balance;
}


contract Merchant is Ownable {
    Withdrawal[] private _withdrawals;
    WithdrawalLimit private _withdrawalLimit;
    IERC20 private _token;
    mapping(address => bool) private _allowedAddresses;

    constructor(IERC20 token, WithdrawalLimit memory withdrawalLimit) {
        _token = token;
        _withdrawalLimit = withdrawalLimit;
    }

    function getWithdrawalLimit() external view returns(WithdrawalLimit memory) {
        return _withdrawalLimit;
    }

    function setWithdrawalLimit(uint8 time, uint256 amount) external {
        _withdrawalLimit.time = time;
        _withdrawalLimit.amount = amount;
    }

    function addAddress(address allowedAddress) external onlyOwner {
        _allowedAddresses[allowedAddress] = true;
    }

    function removeAddress(address allowedAddress) external onlyOwner {
        _allowedAddresses[allowedAddress] = false;
    }

    function withdrawCheck(address withdrawalAddress, uint256 amount) external view returns(ChecktWithdrawalCodes) {
        if (_allowedAddresses[withdrawalAddress]) {
            return ChecktWithdrawalCodes.NOT_ALLOWED_ADDRESS;
        }
        if (_withdrawalLimit.amount < amount) {
            return ChecktWithdrawalCodes.WITHDRAWAL_LIMIT_EXCEED;
        }
        if (_withdrawals.length > 0) {
            Withdrawal memory lastWithdrawal = _withdrawals[_withdrawals.length - 1];
            if (block.timestamp - lastWithdrawal.timestamp < _withdrawalLimit.time) {
                if (_withdrawalLimit.amount < lastWithdrawal.amount + amount) {
                    return ChecktWithdrawalCodes.WITHDRAWAL_LIMIT_EXCEED;
                }
            }
        }
        return ChecktWithdrawalCodes.OK;
    }

    function withdraw(address payable withdrawalAddress, uint256 amount, bool native) external onlyOwner {
        require(this.withdrawCheck(withdrawalAddress, amount) == ChecktWithdrawalCodes.OK);
        if (_withdrawals.length > 0) {
            Withdrawal storage lastWithdrawal = _withdrawals[_withdrawals.length - 1];
            if (block.timestamp - lastWithdrawal.timestamp < _withdrawalLimit.time) {
                lastWithdrawal.amount += amount;
            } else {
                _withdrawals.push(Withdrawal(amount, block.timestamp));
            }
        } else {
            _withdrawals.push(Withdrawal(amount, block.timestamp));
        }
        if (native) {
            withdrawalAddress.transfer(amount);
        } else {
            _token.transfer(withdrawalAddress, amount);
        }
    }
}


contract Wallet is Ownable {
    address public operator;
    modifier onlyOperator() {
        require(operator == msg.sender, "Caller =/= operator.");
        _;
    }
    function transferOperator(address newOperator) external onlyOwner {
        require(newOperator != DEAD && newOperator != ZERO, "Cannot renounce.");
        operator = newOperator;
    }

    // token => limits
    mapping(address => WithdrawalLimit) private _defaultWithdrawalLimits;
    // account address => token => Account
    mapping(address => mapping(address => Account)) private _accounts;
    // merchant address => token => Merchant
    mapping(address => mapping(address => Merchant)) private _merchants;

    function getWithdrawalDefaultLimit(address token) external view returns(WithdrawalLimit memory) {
        return _defaultWithdrawalLimits[token];
    }

    function setWithdrawalDefaultLimit(address token, uint8 time, uint256 amount) external onlyOwner {
        require(time > 0 && amount > 0);
        _defaultWithdrawalLimits[token] = WithdrawalLimit(time, amount);
    }

    function getAccountWithdrawalLimit(address account, address token) external view returns(WithdrawalLimit memory) {
        return _accounts[account][token].withdrawalLimit;
    }

    function setAccountWithdrawalLimit(address token, address account, uint8 time, uint256 amount) external onlyOwner {
        _accounts[account][token].withdrawalLimit = WithdrawalLimit(time, amount);
    }

    function topUpAccount(address account, address token, uint256 amount) external payable {
        if (token == address(this)) {
            require(msg.value == amount);
        } else {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }
        _accounts[account][token].balance += amount;
    }

    function withdrawAccountCheck(address token, address account, uint256 amount) external view returns(ChecktWithdrawalCodes) {
        if (token == address(this)) {
            if (address(this).balance < amount) {
                return ChecktWithdrawalCodes.INSUFFICIENT_FUNDS;
            }
        } else {
            if (IERC20(token).balanceOf(address(this)) < amount) {
                return ChecktWithdrawalCodes.INSUFFICIENT_FUNDS;
            }
        }
        if (_accounts[account][token].balance < amount) {
            return ChecktWithdrawalCodes.INSUFFICIENT_FUNDS;
        }
        WithdrawalLimit memory limit = _defaultWithdrawalLimits[token];
        if (_accounts[account][token].withdrawalLimit.time > 0 && _accounts[account][token].withdrawalLimit.amount > 0) {
            limit = _accounts[account][token].withdrawalLimit;
        }
        if (limit.amount < amount) {
            return ChecktWithdrawalCodes.WITHDRAWAL_LIMIT_EXCEED;
        }
        if (_accounts[account][token].withdrawals.length > 0) {
            Withdrawal memory lastWithdrawal = _accounts[account][token].withdrawals[_accounts[account][token].withdrawals.length - 1];
            if (block.timestamp - lastWithdrawal.timestamp < limit.time) {
                if (limit.amount < lastWithdrawal.amount + amount) {
                    return ChecktWithdrawalCodes.WITHDRAWAL_LIMIT_EXCEED;
                }
            }
        }
        return ChecktWithdrawalCodes.OK;
    }

    function withdrawAccount(address token, address account, uint256 amount) external onlyOperator {
        require(this.withdrawAccountCheck(token, account, amount) == ChecktWithdrawalCodes.OK);
        if (_accounts[account][token].withdrawals.length > 0) {
            Withdrawal storage lastWithdrawal = _accounts[account][token].withdrawals[_accounts[account][token].withdrawals.length - 1];
            if (block.timestamp - lastWithdrawal.timestamp < _accounts[account][token].withdrawalLimit.time) {
                lastWithdrawal.amount += amount;
            } else {
                _accounts[account][token].withdrawals.push(Withdrawal(amount, block.timestamp));
            }
        } else {
            _accounts[account][token].withdrawals.push(Withdrawal(amount, block.timestamp));
        }
        if (token == address(this)) {
            payable(address(this)).transfer(amount);
        } else {
            IERC20(token).transfer(account, amount);
        }
        _accounts[account][token].balance -= amount;
    }

    function getAccountBalance(address token, address account) external view returns(uint256) {
        return _accounts[account][token].balance;
    }

    function updateAccountBalance(address token, address account, uint256 balance) external onlyOperator {
        _accounts[account][token].balance = balance;
    }

    function getMerchantWithdrawalLimit(address merchant, address token) external view returns(WithdrawalLimit memory) {
        return _merchants[merchant][token].getWithdrawalLimit();
    }

    function setMerchantWithdrawalLimit(address merchant, address token, uint8 limitTime, uint256 limitAmount) external onlyOwner {
        _merchants[merchant][token].setWithdrawalLimit(limitTime, limitAmount);
    }

    function createMerchant(address merchant, address token, uint8 limitTime, uint256 limitAmount) external onlyOwner {
        _merchants[merchant][token] = new Merchant(IERC20(token), WithdrawalLimit(limitTime, limitAmount));
    }

    function addMerchantAllowedAddress(address merchant, address token, address allowedAddress) external onlyOwner {
        _merchants[merchant][token].addAddress(allowedAddress);
    }

    function removeMerchantAllowedAddress(address merchant, address token, address allowedAddress) external onlyOwner {
        _merchants[merchant][token].removeAddress(allowedAddress);
    }

    function withdrawMerchantCheck(address merchant, address token, address withdrawalAddress, uint256 amount) external view returns(ChecktWithdrawalCodes) {
        if (address(_merchants[merchant][token]) == ZERO) {
            return ChecktWithdrawalCodes.ACCOUNT_NOT_FOUND;
        }
        if (IERC20(token).balanceOf(owner) < amount) {
            return ChecktWithdrawalCodes.INSUFFICIENT_FUNDS;
        }
        return _merchants[merchant][token].withdrawCheck(withdrawalAddress, amount);
    }

    function withdrawMerchant(address merchant, address token, address payable withdrawalAddress, uint256 amount) external onlyOperator {
        require(this.withdrawMerchantCheck(merchant, token, withdrawalAddress, amount) == ChecktWithdrawalCodes.OK);
        bool native = token == address(this);
        if (native) {
            payable(address(this)).transfer(amount);
        } else {
            IERC20(token).transfer(address(_merchants[merchant][token]), amount);
        }
        _merchants[merchant][token].withdraw(withdrawalAddress, amount, native);
    }

    receive() external payable {}
}