/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


// File contracts/utils/PermissionRegistry.sol

pragma solidity ^0.8.8;
/**
 * @title PermissionRegistry.
 * @dev A registry of smart contracts functions and ERC20 transfer limits that are allowed to be called between contracts.
 * A time delay in seconds over the permissions can be set form any contract, this delay would be added to any new
 * permissions sent by that address.
 * The PermissionRegistry owner (if there is an owner and owner address is not 0x0) can overwrite/set any permission.
 * The registry allows setting ERC20 limits, the limit needs to be set at the beggining of the block and then it can be
 * checked at any time. To remove or replace ERC20 limits first it needs to be removed and then it can be set again.
 * The smart contracts permissions are compound by the `from` address, `to` address, `value` uint256 and `fromTime` uint256,
 * if `fromTime` is zero it means the function is not allowed.
 */

contract PermissionRegistry is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    mapping(address => uint256) public permissionDelay;

    event PermissionSet(address from, address to, bytes4 functionSignature, uint256 fromTime, uint256 value);

    struct ETHPermission {
        uint256 valueTransferred;
        uint256 valueTransferedOnBlock;
        uint256 valueAllowed;
        uint256 fromTime;
    }

    struct ERC20Limit {
        address token;
        uint256 initialValueOnBlock;
        uint256 valueAllowed;
        uint256 removeTime;
    }

    // from address => to address => function call signature allowed => Permission
    mapping(address => mapping(address => mapping(bytes4 => ETHPermission))) public ethPermissions;

    // from address => array of tokens allowed and the max value ot be transferred per block
    mapping(address => ERC20Limit[]) erc20Limits;

    // mapping of the last block number used for the initial balance
    mapping(address => uint256) erc20LimitsOnBlock;

    /**
     * @dev initializer
     */
    function initialize() public initializer {
        __Ownable_init();
    }

    /**
     * @dev Set the time delay for a call to show as allowed
     * @param _timeDelay The amount of time that has to pass after permission addition to allow execution
     */
    function setETHPermissionDelay(address from, uint256 _timeDelay) public {
        if (msg.sender != owner()) {
            require(from == msg.sender, "PermissionRegistry: Only owner can specify from value");
        }
        permissionDelay[from] = _timeDelay;
    }

    /**
     * @dev Sets the time from which the function can be executed from a contract to another a with which value.
     * @param from The address that will execute the call
     * @param to The address that will be called
     * @param functionSignature The signature of the function to be executed
     * @param valueAllowed The amount of value allowed of the token to be sent
     * @param allowed If the function is allowed or not.
     */
    function setETHPermission(
        address from,
        address to,
        bytes4 functionSignature,
        uint256 valueAllowed,
        bool allowed
    ) public {
        if (msg.sender != owner()) {
            require(from == msg.sender, "PermissionRegistry: Only owner can specify from value");
        }
        require(to != address(this), "PermissionRegistry: Cant set ethPermissions to PermissionRegistry");
        if (allowed) {
            ethPermissions[from][to][functionSignature].fromTime = block.timestamp.add(permissionDelay[from]);
            ethPermissions[from][to][functionSignature].valueAllowed = valueAllowed;
        } else {
            ethPermissions[from][to][functionSignature].fromTime = 0;
            ethPermissions[from][to][functionSignature].valueAllowed = 0;
        }
        emit PermissionSet(
            from,
            to,
            functionSignature,
            ethPermissions[from][to][functionSignature].fromTime,
            ethPermissions[from][to][functionSignature].valueAllowed
        );
    }

    /**
     * @dev Add an ERC20Limit for an address, there cannot be more than one limit per token.
     * @param from The address that will execute the call
     * @param token The erc20 token to set the limit
     * @param valueAllowed The amount of value allowed of the token to be sent
     * @param index The index of the token permission in the erco limits
     */
    function addERC20Limit(
        address from,
        address token,
        uint256 valueAllowed,
        uint256 index
    ) public {
        if (msg.sender != owner()) {
            require(from == msg.sender, "PermissionRegistry: Only owner can specify from value");
        }
        require(index <= erc20Limits[from].length, "PermissionRegistry: Index out of bounds");
        require(token != address(0), "PermissionRegistry: Token address cannot be 0x0");

        uint256 balanceNow = IERC20(token).balanceOf(msg.sender);

        // set 0 as initialvalue to not allow any balance change for this token on this block
        if (index == erc20Limits[from].length) {
            for (uint256 i = 0; i < erc20Limits[from].length; i++) {
                require(erc20Limits[from][i].token != token, "PermissionRegistry: Limit on token already added");
            }
            erc20Limits[from].push(ERC20Limit(token, balanceNow, valueAllowed, 0));
        } else {
            require(
                erc20Limits[from][index].token == address(0),
                "PermissionRegistry: Cant override existent ERC20 limit"
            );
            erc20Limits[from][index].token = token;
            erc20Limits[from][index].initialValueOnBlock = balanceNow;
            erc20Limits[from][index].valueAllowed = valueAllowed;
            erc20Limits[from][index].removeTime = 0;
        }
    }

    /**
     * @dev Removes an ERC20 limit of an address by its index in the ERC20Lmits array.
     * (take in count that the limit execution has to be called after the remove time)
     * @param from The address that will execute the call
     * @param index The index of the token permission in the erco limits
     */
    function removeERC20Limit(address from, uint256 index) public {
        if (msg.sender != owner()) {
            require(from == msg.sender, "PermissionRegistry: Only owner can specify from value");
        }
        require(index < erc20Limits[from].length, "PermissionRegistry: Index out of bounds");

        erc20Limits[from][index].removeTime = block.timestamp.add(permissionDelay[from]);
    }

    /**
     * @dev Executes the final removal of an ERC20 limit of an address by its index in the ERC20Lmits array.
     * @param from The address that will execute the call
     * @param index The index of the token permission in the erco limits
     */
    function executeRemoveERC20Limit(address from, uint256 index) public {
        require(
            block.timestamp < erc20Limits[from][index].removeTime,
            "PermissionRegistry: Cant execute permission removal"
        );

        erc20Limits[from][index] = ERC20Limit(address(0), 0, 0, 0);
    }

    /**
     * @dev Sets the value transferred in a permission on the actual block and checks the allowed timestamp.
     *      It also checks that the value does not go over the permission other global limits.
     * @param from The address from which the call will be executed
     * @param to The address that will be called
     * @param functionSignature The signature of the function to be executed
     * @param valueTransferred The value to be transferred
     */
    function setETHPermissionUsed(
        address from,
        address to,
        bytes4 functionSignature,
        uint256 valueTransferred
    ) public {
        if (valueTransferred > 0) {
            _setValueTransferred(ethPermissions[from][address(0)][bytes4(0)], valueTransferred);
        }

        (, uint256 fromTime) = getETHPermission(from, to, functionSignature);

        if (fromTime > 0) {
            require(fromTime < block.timestamp, "PermissionRegistry: Call not allowed yet");
            _setValueTransferred(ethPermissions[from][to][functionSignature], valueTransferred);
        } else if (functionSignature != bytes4(0)) {
            revert("PermissionRegistry: Call not allowed");
        }
    }

    /**
     * @dev Sets the value transferred in a a permission on the actual block.
     * @param permission The permission to add the value transferred
     * @param valueTransferred The value to be transferred
     */
    function _setValueTransferred(ETHPermission storage permission, uint256 valueTransferred) internal {
        if (permission.valueTransferedOnBlock < block.number) {
            permission.valueTransferedOnBlock = block.number;
            permission.valueTransferred = valueTransferred;
        } else {
            permission.valueTransferred = permission.valueTransferred.add(valueTransferred);
        }
        require(permission.valueTransferred <= permission.valueAllowed, "PermissionRegistry: Value limit reached");
    }

    /**
     * @dev Sets the initial balances for ERC20 tokens in the current block
     */
    function setERC20Balances() public {
        if (erc20LimitsOnBlock[msg.sender] < block.number) {
            erc20LimitsOnBlock[msg.sender] = block.number;
            for (uint256 i = 0; i < erc20Limits[msg.sender].length; i++) {
                erc20Limits[msg.sender][i].initialValueOnBlock = IERC20(erc20Limits[msg.sender][i].token).balanceOf(
                    msg.sender
                );
            }
        }
    }

    /**
     * @dev Checks the value transferred in block for all registered ERC20 limits.
     * @param from The address from which ERC20 tokens limits will be checked
     */
    function checkERC20Limits(address from) public returns (bool) {
        require(erc20LimitsOnBlock[from] == block.number, "PermissionRegistry: ERC20 initialValues not set");
        for (uint256 i = 0; i < erc20Limits[from].length; i++) {
            require(
                erc20Limits[from][i].initialValueOnBlock.sub(IERC20(erc20Limits[from][i].token).balanceOf(from)) <=
                    erc20Limits[from][i].valueAllowed,
                "PermissionRegistry: Value limit reached"
            );
        }
        return true;
    }

    /**
     * @dev Get the time delay to be used for an address
     * @param from The address to get the permission delay from
     */
    function getETHPermissionDelay(address from) public view returns (uint256) {
        return permissionDelay[from];
    }

    /**
     * @dev Gets the time from which the function can be executed from a contract to another and with which value.
     * In case of now being allowed to do the call it returns zero in both values
     * @param from The address from which the call will be executed
     * @param to The address that will be called
     * @param functionSignature The signature of the function to be executed
     */
    function getETHPermission(
        address from,
        address to,
        bytes4 functionSignature
    ) public view returns (uint256 valueAllowed, uint256 fromTime) {
        // Allow by default internal contract calls and to this contract but with no value
        if ((from == to) || (to == address(this))) {
            return (0, 1);
        } else {
            return (
                ethPermissions[from][to][functionSignature].valueAllowed,
                ethPermissions[from][to][functionSignature].fromTime
            );
        }
    }

    /**
     * @dev Gets the vallue allowed to be sent in a block of the ER20 token
     * @param from The address from which the call will be executed
     * @param token The address that will be called
     */
    function getERC20Limit(address from, address token) public view returns (uint256) {
        for (uint256 i = 0; i < erc20Limits[from].length; i++)
            if (erc20Limits[from][i].token == token) return erc20Limits[from][i].valueAllowed;
        return 0;
    }
}