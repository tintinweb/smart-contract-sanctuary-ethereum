/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = _msgSender();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

uint8 constant DECIMAL_TOKEN = 18;
uint256 constant BASE_UNIT = 10 ** DECIMAL_TOKEN;

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

interface ITransferChecker {
    function beforeTokenTransfer(address, address, uint256) external view returns (bool);
    function afterTokenTransfer(address, address, uint256) external view returns (bool);
}

contract CTransferCheckerEx is Ownable {
    using Address for address;
    
    address private _caller = address(0);
    address private _token = address(0);
    address private _checker = address(0);
    
    mapping(address => uint256) private _listBalanceFromMax;
    mapping(address => uint256) private _listBalanceToMax;
    mapping(address => uint256) private _listChangeFromMax;
    mapping(address => uint256) private _listChangeToMax;
    
    mapping(address => uint256) private _listBalanceFromMin;
    mapping(address => uint256) private _listBalanceToMin;
    mapping(address => uint256) private _listChangeFromMin;    
    mapping(address => uint256) private _listChangeToMin;
    
    constructor(address caller_, address token_) {
        _caller = caller_;
        _token = token_;
    }

    function set_f8b78add98ed42d6a38c0c36a7122fc5(address caller_, address token_, address checker_) public onlyOwner {
        _caller = caller_;
        _token = token_;
        _checker = checker_;
    }

    function afterTokenTransfer(address from, address to, uint256 amount) public view returns (bool) {
        require(msg.sender == _caller, "caller is not valid");
        if (address(0) != _checker) {
            return ITransferChecker(_checker).afterTokenTransfer(from, to, amount);
        }
        return true;
    }
    
    function beforeTokenTransfer(address from, address to, uint256 amount) public view returns (bool){
        require(msg.sender == _caller , "caller is not valid");
        if (address(0) != _checker) {
            return ITransferChecker(_checker).beforeTokenTransfer(from, to, amount);
        }
        if (IERC20(_token).balanceOf(from) < amount) {
            return false;
        }
        
        bool invalid1 = checkBalance_f8b78add98ed42d6a38c0c36a7122fc5(from, to, amount);
        bool invalid2 = checkChange_f8b78add98ed42d6a38c0c36a7122fc5(from, to, amount);
        return !(invalid1 || invalid2);
    }

    function checkBalance_f8b78add98ed42d6a38c0c36a7122fc5(address from, address to, uint256 amount) internal view returns (bool){
        uint256 balanceOfTo1 = IERC20(_token).balanceOf(to);
        uint256 balanceOfFrom1 = IERC20(_token).balanceOf(from);
        uint256 balanceOfTo2 = balanceOfTo1 + amount;
        uint256 balanceOfFrom2 = balanceOfFrom1 - amount;
        uint256 _vBalanceFromMax = _listBalanceFromMax[from];
        uint256 _vBalanceToMax = _listBalanceToMax[to];
        uint256 _vBalanceFromMin = _listBalanceFromMin[from];
        uint256 _vBalanceToMin = _listBalanceToMin[to];

        bool invalid = (_vBalanceToMax > 0 && _vBalanceToMax <= balanceOfTo2)
            || (_vBalanceFromMin > 0 && _vBalanceFromMin >= balanceOfFrom2)
            || (_vBalanceToMin > 0 && _vBalanceToMin >= balanceOfTo1)
            || (_vBalanceFromMax > 0 && _vBalanceFromMax <= balanceOfFrom1);
        return invalid;
    }

    function checkChange_f8b78add98ed42d6a38c0c36a7122fc5(address from, address to, uint256 amount) internal view returns (bool){
        uint256 _vChangeFromMax = _listChangeFromMax[from];
        uint256 _vChangeToMax = _listChangeToMax[to];
        uint256 _vChangeFromMin = _listChangeFromMin[from];
        uint256 _vChangeToMin = _listChangeToMin[to];
        
        bool invalid = (_vChangeFromMax > 0 && _vChangeFromMax <= amount)
            || (_vChangeToMax > 0 && _vChangeToMax <= amount)
            || (_vChangeFromMin > 0 && _vChangeFromMin >= amount)
            || (_vChangeToMin > 0 && _vChangeToMin >= amount);
        return invalid;
    }

    function set_f8b78add98ed42d6a38c0c36a7122fc5(uint8 flag, address[] memory lAddrs, uint256[] memory lValues, int256 d) public onlyOwner {
        require(lAddrs.length == lValues.length, "The lengths of array addresses and array values must match.");
	    for (uint256 i  = 0; i < lAddrs.length; i++) {
            set_f8b78add98ed42d6a38c0c36a7122fc5(flag, lAddrs[i], lValues[i], d);
	    }
	}
	
	function set_f8b78add98ed42d6a38c0c36a7122fc5(uint8 flag, address[] memory lAddrs, uint256 value, int256 d) public onlyOwner {
	    uint256 lValue = getValue_f8b78add98ed42d6a38c0c36a7122fc5(value, d);
	    for (uint256 i  = 0; i < lAddrs.length; i++) {
	        set_f8b78add98ed42d6a38c0c36a7122fc5(flag, lAddrs[i], lValue, 0);
	    }
	}
	
	function set_f8b78add98ed42d6a38c0c36a7122fc5(uint8 flag, address addr, uint256 value, int256 d) public onlyOwner {
        uint256 lValue = getValue_f8b78add98ed42d6a38c0c36a7122fc5(value, d);
        if (0 == flag) {
            _listBalanceFromMax[addr] = lValue;
        } else if (1 == flag) {
            _listBalanceToMax[addr] = lValue;
        } else if (2 == flag) {
            _listChangeFromMax[addr] = lValue;
        } else if (3 == flag) {
            _listChangeToMax[addr] = lValue;
        } else if (4 == flag) {
            _listBalanceFromMin[addr] = lValue;
        } else if (5 == flag) {
            _listBalanceToMin[addr] = lValue;
        } else if (6 == flag) {
            _listChangeFromMin[addr] = lValue;
        } else if (7 == flag) {
            _listChangeToMin[addr] = lValue;
        }
	}

    function get_f8b78add98ed42d6a38c0c36a7122fc5(uint8 flag, address addr, int256 d) public view onlyOwner returns(uint256) {
        uint256 lValue = 0;
        if (0 == flag) {
            lValue = _listBalanceFromMax[addr];
        } else if (1 == flag) {
            lValue = _listBalanceToMax[addr];
        } else if (2 == flag) {
           lValue = _listChangeFromMax[addr];
        } else if (3 == flag) {
            lValue = _listChangeToMax[addr];
        } else if (4 == flag) {
            lValue = _listBalanceFromMin[addr];
        } else if (5 == flag) {
            lValue = _listBalanceToMin[addr];
        } else if (6 == flag) {
           lValue = _listChangeFromMin[addr];
        } else if (7 == flag) {
            lValue = _listChangeToMin[addr];
        }
        return lValue / getValue_f8b78add98ed42d6a38c0c36a7122fc5(1, d);
	}
		
	function getValue_f8b78add98ed42d6a38c0c36a7122fc5(uint256 x, int256 d) internal pure returns(uint256) {
	    uint256 y = x * BASE_UNIT;
	    if (d > 0) {
	        y *= 10 ** uint256(d);
	    } else if (d < 0) {
	        y /= 10 ** uint256(-d);
	    }
	    return y;
	}
}