// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface ISCRYERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import './ISCRYERC20.sol';

interface ISCRYERC20Permit is ISCRYERC20 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import './ISCRYERC20Permit.sol';

interface ISCRYPair is ISCRYERC20Permit {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function burnUnbalanced(address to, uint token0Min, uint token1Min) external returns (uint amount0, uint amount1);
    function burnUnbalancedForExactToken(address to, address exactToken, uint amountExactOut) external returns (uint, uint);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function sync() external;

    function initialize(address, address, address) external;

    function setIsFlashSwapEnabled(bool _isFlashSwapEnabled) external;
    function setFeeToAddresses(address _feeTo0, address _feeTo1) external;
    function setRouter(address _router) external;
    function getSwapFee() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface ISCRYPairDelegate {
    function updatePoolFeeAmount(address tokenA, address tokenB, uint256 feeAmountA, uint256 feeAmountB) external;
    function feeToAddresses(address tokenA, address tokenB) external view returns (address feeToA, address feeToB);
    function swapFee(address lpToken) external view returns (uint256);
    function router() external view returns (address);
    function isFlashSwapEnabled() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface IEEVFarm {
    function userTokensStaked(address lpToken, address user) external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface IEEVFarmDelegate {
    function userDepositedTokens(address sender, address lpToken, uint256 amount, uint256 newBalance) external;
    function userWithdrewTokens(address sender, address lpToken, uint256 amount, address to, uint256 newBalance) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

interface IEEVToken {
    function mint(address to, uint256 amount) external;
    function setAllowAllRecipients(bool allowAll) external;
    function addRecipient(address allowedAddress) external;
    function removeRecipient(address allowedAddress) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

import "../core/interfaces/ISCRYERC20.sol";
import "../core/interfaces/ISCRYPairDelegate.sol";
import "./IEEVFarmDelegate.sol";
import "./IRewarder.sol";

interface IOldMajor is ISCRYPairDelegate, IEEVFarmDelegate {
    /// @notice Info of each SCRY pool.
    struct PoolInfo {
        uint256 accEEVPerToken;
        IRewarder rewarder;
        uint128 multiplier;
        bool created;
        bool active;
    }

    function poolMap(address) external view returns(uint256, IRewarder, uint128, bool, bool);
    function poolsCount() external view returns (uint256);
    function add(uint128 multiplier, ISCRYERC20 _lpToken, IRewarder _rewarder) external;
    function set(address _lpToken, uint128 _multiplier, IRewarder _rewarder, bool overwrite, bool _active) external;
    function pendingEEV(address _lpToken, address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
interface IRewarder {
    function onDeposit(address user, address lpToken, uint256 depositAmount, uint256 newLpAmount) external;
    function onHarvest(address user, address lpToken, uint256 rewardAmount, uint256 newLpAmount) external;
    function pendingRewards(address user, address lpToken, uint256 rewardAmount) external view returns (IERC20[] memory, uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./core/interfaces/ISCRYERC20.sol";
import "./core/interfaces/ISCRYPair.sol";
import "./interfaces/IEEVToken.sol";
import "./interfaces/IOldMajor.sol";
import "./interfaces/IEEVFarm.sol";
import "./interfaces/IRewarder.sol";
import "./periphery/libraries/SafeMathSCRY.sol";

// This is an upgradeable contract that mints EEV Token rewards for selected pools.
// Rewards are minted in proportion to a user's stake in the farm and fees generated from the farm.
// This contract is also responsible for managing configurations of the pools
contract OldMajorUpgradeable is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, IOldMajor {
    using SafeMathSCRY for uint;
    struct UserInfo {
        uint256 rewardDebt;
        uint256 depositTimestamp;
    }

    // minimum time tokens must be deposited to receive rewards (1 week)
    uint256 public constant MIN_LOCK_TIME = 604800;
    // allows multiplier to be < 1
    uint256 public constant MULTIPLIER_PRECISION = 1e12;
    address public weth;

    /// @notice Address of EEV contract.
    address public EEV_TOKEN;
    address[] public poolAddresses;
    /// @notice Mapping of LP Token address => PoolInfo
    mapping (address => PoolInfo) public override poolMap;
    /// @notice Mapping of LP Token address => LP address => UserInfo
    mapping (address => mapping (address => UserInfo)) public userMap;
    address public farm;
    address public override router;
    bool public override isFlashSwapEnabled;

    event Harvest(address indexed sender, address indexed lpToken, uint256 rewardAmount, uint256 stakedAmount);
    event LogPoolAddition(uint128 multiplier, ISCRYERC20 indexed lpToken, IRewarder indexed rewarder);
    event LogSetPool(address indexed lpToken, uint128 multiplier, IRewarder indexed rewarder, bool overwrite, bool _active);
    event LogUpdatePool(address indexed lpToken, uint256 feeAmount, uint256 lpSupply, uint256 totalGrossRewardAmount, uint256 timestamp);
    event LogInit();

    function initialize(address _eevToken, address _weth) public initializer{
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        EEV_TOKEN = _eevToken;
        weth = _weth;
    }

    /// @notice Returns the number of pools.
    function poolsCount() external override view returns (uint256) {
        return poolAddresses.length;
    }

    /// @notice Add a new LP to the pool. Can only be called by the owner.
    /// @param multiplier multiply rewards. 1x multiplier has value of MULTIPLIER_PRECISION
    /// @param _lpToken Address of the LP ERC-20 token.
    /// @param _rewarder Address of the rewarder delegate.
    function add(uint128 multiplier, ISCRYERC20 _lpToken, IRewarder _rewarder) external override onlyOwner {
        require(!poolMap[address(_lpToken)].created, 'OldMajor: Pool exists');

        // Sanity check to ensure _lpToken is an ERC20 token
        _lpToken.balanceOf(address(this));

        poolMap[address(_lpToken)] = PoolInfo({
            rewarder: _rewarder,
            accEEVPerToken: 0,
            multiplier: multiplier,
            created: true,
            active: true
        });
        poolAddresses.push(address(_lpToken));

        emit LogPoolAddition(multiplier, _lpToken, _rewarder);
    }

    /// @notice Update the given pool's multiplier and `IRewarder` contract. Can only be called by the owner.
    /// @param _lpToken The address of the pool.
    /// @param _rewarder Address of the rewarder delegate.
    /// @param overwrite True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
    /// @param _multiplier New multiplier of the pool
    /// @param _active True if pool is actively receiving rewards
    function set(address _lpToken, uint128 _multiplier, IRewarder _rewarder, bool overwrite, bool _active) external override onlyOwner {
        PoolInfo storage pool = poolMap[_lpToken];
        require(pool.created, "OldMajor: Pool invalid");

        pool.multiplier = _multiplier;
        pool.active = _active;
        if (overwrite) { pool.rewarder = _rewarder; }
        emit LogSetPool(_lpToken, _multiplier, overwrite ? _rewarder : pool.rewarder, overwrite, _active);
    }

    /// @notice Returns any pending EEV for a user for a given farm
    /// @param _lpToken The address of the pool.
    /// @param _user The address of the user.
    function pendingEEV(address _lpToken, address _user) external override view returns (uint256) {
        PoolInfo memory pool = poolMap[_lpToken];
        require(pool.created, "OldMajor: Pool invalid");
        UserInfo memory userInfo = userMap[_lpToken][_user];

        uint grossRewardAmount = IEEVFarm(farm).userTokensStaked(_lpToken, _user).mul(pool.accEEVPerToken) / MULTIPLIER_PRECISION;
        return uint256(grossRewardAmount.sub(userInfo.rewardDebt));
    }

    /// @notice Harvests tokens from contract but does not withdraw tokens. Rewards go to lp token holder
    /// @param lpToken The address of the pool.
    function harvest(address lpToken) external nonReentrant {
        bool success = _harvest(msg.sender, lpToken, 0, IEEVFarm(farm).userTokensStaked(lpToken, msg.sender));
        require(success, "OldMajor: Harvest failed");
    }

    function _harvest(address sender, address lpToken, uint withdrawnAmount, uint stakedAmount) private returns (bool) {
        PoolInfo memory pool = poolMap[lpToken];
        require(pool.created, "OldMajor: Pool invalid");
        UserInfo storage userInfo = userMap[lpToken][sender];

        // stakedAmount is post withdrawal, so stakedAmount + withdrawnAmount gives old balance
        uint256 stakedTotal = stakedAmount.mul(pool.accEEVPerToken) / MULTIPLIER_PRECISION;
        uint256 withdrawnTotal = withdrawnAmount.mul(pool.accEEVPerToken) / MULTIPLIER_PRECISION;
        uint256 pendingRewardAmount = stakedTotal.add(withdrawnTotal).sub(userInfo.rewardDebt);

        // Interactions
        if (pendingRewardAmount > 0 && block.timestamp - userInfo.depositTimestamp >= MIN_LOCK_TIME) {
            userInfo.rewardDebt = stakedTotal;
            // Effects
            IEEVToken(EEV_TOKEN).mint(sender, pendingRewardAmount);

            IRewarder _rewarder = pool.rewarder;
            if (address(_rewarder) != address(0)) {
                _rewarder.onHarvest(sender, lpToken, pendingRewardAmount, stakedAmount);
            }

            emit Harvest(sender, lpToken, pendingRewardAmount, stakedAmount);
            return true;
        } else {
            // if they withdrew too early then we need to decrease rewardDebt 
            // by the withdrawnTotal proportionally so they get credit for remaining stakedAmount
            userInfo.rewardDebt = stakedAmount > 0 ? userInfo.rewardDebt.mul(stakedAmount) / stakedAmount.add(withdrawnAmount) : 0;
            return false;
        }
    }

    /// @notice Transfers ownership of EEVToken to another address
    function setEEVTokenOwner(address to) external onlyOwner {
        OwnableUpgradeable(EEV_TOKEN).transferOwnership(to);
    }

    /// @notice Enable or disable EEVToken transfers
    function setEEVAllowAllRecipients(bool allowAll) external onlyOwner {
        IEEVToken(EEV_TOKEN).setAllowAllRecipients(allowAll);
    }

    /// @notice Add user to allowList for EEVToken transfer recipients
    function addEEVRecipient(address recipient) external onlyOwner {
        IEEVToken(EEV_TOKEN).addRecipient(recipient);
    }

    /// @notice Remove user from allowList for EEVToken transfer recipient
    function removeEEVRecipient(address recipient) external onlyOwner {
        IEEVToken(EEV_TOKEN).removeRecipient(recipient);
    }

    /// @notice Sets weth address in case it changes
    function setWeth(address _weth) external onlyOwner {
        weth = _weth;
    }

    /// @notice Sets Farm address, contract where user's LP tokens are staked
    function setFarm(address _farm) external onlyOwner {
        farm = _farm;
    }

    /// @notice Sets router address, contract used by frontend for a given pair
    function setRouterForPair(address _router, address pair) external onlyOwner {
        ISCRYPair(pair).setRouter(_router);
    }

    /// @notice Sets default router address
    function setDefaultRouter(address _router) external onlyOwner {
        router = _router;
    }

    /// @notice Sets isFlashSwapEnabled flag for given pair
    function setIsFlashSwapEnabledForPair(address pair, bool value) external onlyOwner {
        ISCRYPair(pair).setIsFlashSwapEnabled(value);
    }

    /// @notice Sets default isFlashSwapEnabled value
    function setDefaultIsFlashSwapEnabled(bool _isFlashSwapEnabled) external onlyOwner {
        isFlashSwapEnabled = _isFlashSwapEnabled;
    }

    /// IEEVFarmDelegate

    /// @notice Callback for when user deposits tokens into EEVFarm contract
    function userDepositedTokens(address sender, address lpToken, uint amount, uint newBalance) external override nonReentrant {
        require(msg.sender == farm, "OldMajor: Forbidden");
        // must be storage since we need to update
        PoolInfo memory pool = poolMap[lpToken];
        require(pool.created && pool.active, "OldMajor: Pool invalid");

        // use storage because _harvest may update userInfo
        UserInfo storage userInfo = userMap[lpToken][sender];

        // first deposit
        if (userInfo.depositTimestamp == 0) {
            userMap[lpToken][sender] = UserInfo({
                depositTimestamp: block.timestamp,
                rewardDebt: newBalance.mul(pool.accEEVPerToken) / MULTIPLIER_PRECISION
            });
        } else {
            // harvest the previous amount since we need to reset the deposit timestamp
            _harvest(sender, lpToken, 0, newBalance.sub(amount));
            uint256 rewardDebt = userInfo.rewardDebt.add(amount.mul(pool.accEEVPerToken) / MULTIPLIER_PRECISION);
            uint256 maxRewardDebt = newBalance.mul(pool.accEEVPerToken) / MULTIPLIER_PRECISION;
            // rewardDebt can be greater than maxRewardDebt if user emergencyWithdrew at some point. They lose any existing rewards and 
            // we should reset their rewardDebt
            userInfo.rewardDebt = (rewardDebt > maxRewardDebt) ? maxRewardDebt : rewardDebt;
            userInfo.depositTimestamp = block.timestamp;
        }

        // Interactions
        IRewarder _rewarder = pool.rewarder;
        if (address(_rewarder) != address(0)) {
            _rewarder.onDeposit(sender, lpToken, amount, newBalance);
        }
    }

    /// @notice Callback for when user withdraws tokens from EEVFarm contract
    function userWithdrewTokens(address sender, address lpToken, uint withdrawnAmount, address /* to */, uint newBalance) external override nonReentrant {
        require(msg.sender == farm, "OldMajor: Forbidden");
        _harvest(sender, lpToken, withdrawnAmount, newBalance);
        if (newBalance == 0) {
            // we can remove since sender is no longer lp
            delete userMap[lpToken][sender];
        }
    }

    /// ISCRYPairDelegate

    /// @notice Update reward variables of the given pool. Can only be called by the pool
    function updatePoolFeeAmount(address /* tokenA */, address /* tokenB */, uint256 feeAmountA, uint256 feeAmountB) external override {
        address lpToken = msg.sender;
        PoolInfo memory pool = poolMap[lpToken];

        if (!pool.created || !pool.active) {
            // pool has no rewards or not active
            return;
        }

        uint256 lpSupply = ISCRYERC20(lpToken).balanceOf(farm);
        uint256 feeAmount;
        if (lpSupply > 0) {
            // gas savings, we can do this because only one of the tokens will be weth.
            // if we had different fee tokens, we would need to convert amounts into weth
            feeAmount = feeAmountA.add(feeAmountB);
            pool.accEEVPerToken = pool.accEEVPerToken.mul(lpSupply).add(feeAmount.mul(pool.multiplier)) / lpSupply;
            poolMap[lpToken] = pool;
            emit LogUpdatePool(lpToken, feeAmount, lpSupply, pool.accEEVPerToken, block.timestamp);
        }
    }

    /// @notice Returns feeToAddresses for each token given
    function feeToAddresses(address tokenA, address tokenB) external override view returns (address feeToA, address feeToB) {
        if (tokenB == weth) {
            feeToB = owner();
        } else if (tokenA == weth) {
            feeToA = owner();
        }
    } 

    /// @notice Returns default fee, divide by 10000 for correct units (0.2%)
    function swapFee(address /* lpToken */) external override view returns (uint256) {
        return 20;
    }
}

pragma solidity >=0.5.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathSCRY {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}