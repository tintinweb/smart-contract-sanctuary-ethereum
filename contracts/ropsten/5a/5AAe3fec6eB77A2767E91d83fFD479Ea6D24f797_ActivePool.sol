// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Libraries/SafeMath.sol";
import "./Libraries/Ownable.sol";

import "./Interfaces/IActivePool.sol";
import "./Interfaces/IERC20.sol";
import "./Interfaces/IUSDAToken.sol";


contract ActivePool is IActivePool, Ownable {
    using SafeMath for uint;
    string public constant NAME = "Archimedes ActivePool V1";

    uint public USDAEarn;
    uint public USDASpend;
    mapping(address => uint) public usdaEarnFromPools;

    mapping(address => bool) public allowedOperations;

    IUSDAToken public usdaToken;

    constructor (address _usdaTokenAddress) {
        usdaToken = IUSDAToken(_usdaTokenAddress);
    }

    function addOperationAddress(address _opAddress) external override onlyOwner {
        allowedOperations[_opAddress] = true;
        emit AddOperation(_opAddress);
    }

    function deprecatedOperationAddress(address _opAddress) external override onlyOwner {
        allowedOperations[_opAddress] = false;
        emit DeprecatedOperation(_opAddress);
    }

    // --- Pool functionality ---
    function depositColl(address _collToken, address _account, uint _amount) external override isUnlock {
        require(allowedOperations[msg.sender] == true, "ActivePool: Caller is not allowed operations");
        IERC20(_collToken).transferFrom(_account, address(this), _amount);
        emit DepositCollaterals(_collToken, _account, _amount);
    }

    function withdrawColl(address _collToken, address _account, uint _amount) external override isUnlock {
        require(allowedOperations[msg.sender] == true, "ActivePool: Caller is not allowed operations");
        IERC20(_collToken).transfer(_account, _amount);
        emit WithdrawCollaterals(_collToken, _account, _amount);
    }

    function withdrawUSDA(address _account, uint _amount) external override isUnlock {
        require(allowedOperations[msg.sender] == true, "ActivePool: Caller is not allowed operations");
        usdaToken.mint(_account,  _amount);
        emit WithdrawUSDA(_account, _amount);
    }

    function depositUSDA(address _account, uint _amount) external override isUnlock {
        require(allowedOperations[msg.sender] == true, "ActivePool: Caller is not allowed operations");
        usdaToken.burn(_account, _amount);
        emit DepositUSDA(_account, _amount);
    }

    function receiveUSDAEarned(address _pool, address _account, uint _amount) external override isUnlock {
        require(allowedOperations[msg.sender] == true, "ActivePool: Caller is not allowed operations");
        // earning fees
        usdaEarnFromPools[_pool] =  usdaEarnFromPools[_pool].add(_amount);
        USDAEarn = USDAEarn.add(_amount);
        
        usdaToken.transferFrom(_account, address(this), _amount);
        emit ReceiveEarnUSDA(_pool, _account, _amount);
    }

    function spendUSDAEarned(uint _amount) external override isUnlock {
        require(allowedOperations[msg.sender] == true, "ActivePool: Caller is not allowed operations");
        USDASpend = USDASpend.add(_amount);
        usdaToken.transfer(msg.sender, _amount);
        emit SpendEarnUSDA(msg.sender, _amount);
    }

    function totalEarnings() external view override returns (uint) {
        return USDAEarn;
    }

    function totalSpend() external view override returns (uint) {
        return USDASpend;
    }

    function getEarnFromPool(address _pool) external view override returns (uint) {
        return usdaEarnFromPools[_pool];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IActivePool {

    /// @dev Events
    event AddOperation(address _opAddress);
    event DeprecatedOperation(address _opAddress);
    event DepositCollaterals(address _pool, address _from, uint _amount);
    event WithdrawCollaterals(address _pool, address _to, uint _amount);
    event DepositUSDA(address _to, uint _amount);
    event WithdrawUSDA(address _to, uint _amount);
    event ReceiveEarnUSDA(address _pool, address _from, uint _amount);
    event SpendEarnUSDA(address _from, uint _amount);

    /**
     * @dev Set a `_opAddress` has operating authority
     */
    function addOperationAddress(address _opAddress) external;

    /**
     * @dev Deprecate operating authority of this `_opAddress`
     */
    function deprecatedOperationAddress(address _opAddress) external;

    /**
     * @dev Borrow or Leverage deposit collateral from account
     */
    function depositColl(address _collToken, address _account, uint _amount) external;

    /**
     * @dev Borrow or Leverage withdraw collateral to account
     */
    function withdrawColl(address _collToken, address _account, uint _amount) external;

    /**
     * @dev Borrow or Leverage to withdraw USDA to account
     */
    function depositUSDA(address _account, uint _amount) external;

    /**
     * @dev Borrow or Leverage deposit USDA from account to burn 
     */
    function withdrawUSDA(address _account, uint _amount) external;

    /**
     * @dev Borrow/Leverage/Redeem/Liquidation charge fee with USDA to active-pool
     */
    function receiveUSDAEarned(address _pool, address _account, uint _amount) external;

    /**
     * @dev ActivePool earning USDA for Stack distribute
     */
    function spendUSDAEarned(uint _amount) external;

    /**
     * @dev History of total income with USDA
     */
    function totalEarnings() external view returns (uint);

    /**
     * @dev History of total spend with USDA
     */
    function totalSpend() external view returns (uint);

    /**
     * @dev Get a specified with `_pool` of total income with USDA in history
     */
    function getEarnFromPool(address _pool) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 amount, 
                    uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to 
     * a value in the near future. The deadline argument can be set to uint(-1) to 
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);
    
    function version() external view returns (string memory);
    function permitTypeHash() external view returns (bytes32);
    function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./IERC2612.sol";
interface IUSDAToken is IERC20, IERC2612 {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


abstract contract Ownable {
    address private _owner;
    // permit transaction
    bool isLock = false;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Unlock(address indexed owner, bool islock);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    modifier isUnlock() {
	    require(isLock == false, "constract has been locked");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
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

    /**
    * @dev unlock contract. Only after unlock can it be traded.
    */
    function unlock() public onlyOwner returns (bool) {
        isLock = false;
        emit Unlock(msg.sender, true);
        return isLock;
    }
    
    /**
    * @dev lock contract
    */
    function lock() public onlyOwner returns (bool) {
        isLock = true;
        emit Unlock(msg.sender, false);
        return isLock;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * NOTE: This function is not safe, as it doesn’t check owner is calling it.
     * Make sure you check it before calling it.
     */
    function _renounceOwnership() internal {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}