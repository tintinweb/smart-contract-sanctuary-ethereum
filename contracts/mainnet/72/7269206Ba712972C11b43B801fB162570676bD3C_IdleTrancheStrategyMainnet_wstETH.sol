pragma solidity ^0.5.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity 0.5.16;

import "./GovernableInit.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract ControllableInit is GovernableInit {

  constructor() public {
  }

  function initialize(address _storage) public initializer {
    GovernableInit.initialize(_storage);
  }

  modifier onlyController() {
    require(Storage(_storage()).isController(msg.sender), "Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((Storage(_storage()).isController(msg.sender) || Storage(_storage()).isGovernance(msg.sender)),
      "The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return Storage(_storage()).controller();
  }
}

pragma solidity 0.5.16;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./Storage.sol";

// A clone of Governable supporting the Initializable interface and pattern
contract GovernableInit is Initializable {

  bytes32 internal constant _STORAGE_SLOT = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

  modifier onlyGovernance() {
    require(Storage(_storage()).isGovernance(msg.sender), "Not governance");
    _;
  }

  constructor() public {
    assert(_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.governableInit.storage")) - 1));
  }

  function initialize(address _store) public initializer {
    _setStorage(_store);
  }

  function _setStorage(address newStorage) private {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newStorage)
    }
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    _setStorage(_store);
  }

  function _storage() internal view returns (address str) {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view returns (address) {
    return Storage(_storage()).governance();
  }
}

pragma solidity 0.5.16;

contract Storage {

  address public governance;
  address public controller;

  constructor() public {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

pragma solidity 0.5.16;

interface IController {

    event SharePriceChangeLog(
      address indexed vault,
      address indexed strategy,
      uint256 oldSharePrice,
      uint256 newSharePrice,
      uint256 timestamp
    );

    // [Grey list]
    // An EOA can safely interact with the system no matter what.
    // If you're using Metamask, you're using an EOA.
    // Only smart contracts may be affected by this grey list.
    //
    // This contract will not be able to ban any EOA from the system
    // even if an EOA is being added to the greyList, he/she will still be able
    // to interact with the whole system as if nothing happened.
    // Only smart contracts will be affected by being added to the greyList.
    // This grey list is only used in Vault.sol, see the code there for reference
    function greyList(address _target) external view returns(bool);

    function addVaultAndStrategy(address _vault, address _strategy) external;
    function doHardWork(address _vault) external;

    function salvage(address _token, uint256 amount) external;
    function salvageStrategy(address _strategy, address _token, uint256 amount) external;

    function notifyFee(address _underlying, uint256 fee) external;
    function profitSharingNumerator() external view returns (uint256);
    function profitSharingDenominator() external view returns (uint256);

    function feeRewardForwarder() external view returns(address);
    function setFeeRewardForwarder(address _value) external;

    function addHardWorker(address _worker) external;
    function addToWhitelist(address _target) external;
}

pragma solidity 0.5.16;

interface IFeeRewardForwarderV6 {
    function poolNotifyFixedTarget(address _token, uint256 _amount) external;

    function notifyFeeAndBuybackAmounts(uint256 _feeAmount, address _pool, uint256 _buybackAmount) external;
    function notifyFeeAndBuybackAmounts(address _token, uint256 _feeAmount, address _pool, uint256 _buybackAmount) external;
    function profitSharingPool() external view returns (address);
    function configureLiquidation(address[] calldata _path, bytes32[] calldata _dexes) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

interface ILiquidator {
  event Swap(
    address indexed buyToken,
    address indexed sellToken,
    address indexed target,
    address initiator,
    uint256 amountIn,
    uint256 slippage,
    uint256 total
  );

  function swapTokenOnMultipleDEXes(
    uint256 amountIn,
    uint256 amountOutMin,
    address target,
    bytes32[] calldata dexes,
    address[] calldata path
  ) external;

  function swapTokenOnDEX(
    uint256 amountIn,
    uint256 amountOutMin,
    address target,
    bytes32 dexName,
    address[] calldata path
  ) external;

  function getAllDexes() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

interface ILiquidatorRegistry {

  function universalLiquidator() external view returns(address);

  function setUniversalLiquidator(address _ul) external;

  function getPath(
    bytes32 dex,
    address inputToken,
    address outputToken
  ) external view returns(address[] memory);

  function setPath(
    bytes32 dex,
    address inputToken,
    address outputToken,
    address[] calldata path
  ) external;
}

pragma solidity 0.5.16;

interface IStrategy {
    
    function unsalvagableTokens(address tokens) external view returns (bool);
    
    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function vault() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;
    function depositArbCheck() external view returns(bool);
}

pragma solidity 0.5.16;

import "@openzeppelin/upgrades/contracts/Initializable.sol";

contract BaseUpgradeableStrategyStorage {

  bytes32 internal constant _UNDERLYING_SLOT = 0xa1709211eeccf8f4ad5b6700d52a1a9525b5f5ae1e9e5f9e5a0c2fc23c86e530;
  bytes32 internal constant _VAULT_SLOT = 0xefd7c7d9ef1040fc87e7ad11fe15f86e1d11e1df03c6d7c87f7e1f4041f08d41;

  bytes32 internal constant _REWARD_TOKEN_SLOT = 0xdae0aafd977983cb1e78d8f638900ff361dc3c48c43118ca1dd77d1af3f47bbf;
  bytes32 internal constant _REWARD_POOL_SLOT = 0x3d9bb16e77837e25cada0cf894835418b38e8e18fbec6cfd192eb344bebfa6b8;
  bytes32 internal constant _SELL_FLOOR_SLOT = 0xc403216a7704d160f6a3b5c3b149a1226a6080f0a5dd27b27d9ba9c022fa0afc;
  bytes32 internal constant _SELL_SLOT = 0x656de32df98753b07482576beb0d00a6b949ebf84c066c765f54f26725221bb6;
  bytes32 internal constant _PAUSED_INVESTING_SLOT = 0xa07a20a2d463a602c2b891eb35f244624d9068572811f63d0e094072fb54591a;

  bytes32 internal constant _PROFIT_SHARING_NUMERATOR_SLOT = 0xe3ee74fb7893020b457d8071ed1ef76ace2bf4903abd7b24d3ce312e9c72c029;
  bytes32 internal constant _PROFIT_SHARING_DENOMINATOR_SLOT = 0x0286fd414602b432a8c80a0125e9a25de9bba96da9d5068c832ff73f09208a3b;

  bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT = 0x29f7fcd4fe2517c1963807a1ec27b0e45e67c60a874d5eeac7a0b1ab1bb84447;
  bytes32 internal constant _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT = 0x414c5263b05428f1be1bfa98e25407cc78dd031d0d3cd2a2e3d63b488804f22e;
  bytes32 internal constant _NEXT_IMPLEMENTATION_DELAY_SLOT = 0x82b330ca72bcd6db11a26f10ce47ebcfe574a9c646bccbc6f1cd4478eae16b31;

  bytes32 internal constant _REWARD_CLAIMABLE_SLOT = 0xbc7c0d42a71b75c3129b337a259c346200f901408f273707402da4b51db3b8e7;
  bytes32 internal constant _MULTISIG_SLOT = 0x3e9de78b54c338efbc04e3a091b87dc7efb5d7024738302c548fc59fba1c34e6;

  constructor() public {
    assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.underlying")) - 1));
    assert(_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.vault")) - 1));
    assert(_REWARD_TOKEN_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardToken")) - 1));
    assert(_REWARD_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardPool")) - 1));
    assert(_SELL_FLOOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sellFloor")) - 1));
    assert(_SELL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sell")) - 1));
    assert(_PAUSED_INVESTING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.pausedInvesting")) - 1));

    assert(_PROFIT_SHARING_NUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.profitSharingNumerator")) - 1));
    assert(_PROFIT_SHARING_DENOMINATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.profitSharingDenominator")) - 1));

    assert(_NEXT_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementation")) - 1));
    assert(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementationTimestamp")) - 1));
    assert(_NEXT_IMPLEMENTATION_DELAY_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementationDelay")) - 1));

    assert(_REWARD_CLAIMABLE_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardClaimable")) - 1));
    assert(_MULTISIG_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.multiSig")) - 1));
  }

  function _setUnderlying(address _address) internal {
    setAddress(_UNDERLYING_SLOT, _address);
  }

  function underlying() public view returns (address) {
    return getAddress(_UNDERLYING_SLOT);
  }

  function _setRewardPool(address _address) internal {
    setAddress(_REWARD_POOL_SLOT, _address);
  }

  function rewardPool() public view returns (address) {
    return getAddress(_REWARD_POOL_SLOT);
  }

  function _setRewardToken(address _address) internal {
    setAddress(_REWARD_TOKEN_SLOT, _address);
  }

  function rewardToken() public view returns (address) {
    return getAddress(_REWARD_TOKEN_SLOT);
  }

  function _setVault(address _address) internal {
    setAddress(_VAULT_SLOT, _address);
  }

  function vault() public view returns (address) {
    return getAddress(_VAULT_SLOT);
  }

  // a flag for disabling selling for simplified emergency exit
  function _setSell(bool _value) internal {
    setBoolean(_SELL_SLOT, _value);
  }

  function sell() public view returns (bool) {
    return getBoolean(_SELL_SLOT);
  }

  function _setPausedInvesting(bool _value) internal {
    setBoolean(_PAUSED_INVESTING_SLOT, _value);
  }

  function pausedInvesting() public view returns (bool) {
    return getBoolean(_PAUSED_INVESTING_SLOT);
  }

  function _setSellFloor(uint256 _value) internal {
    setUint256(_SELL_FLOOR_SLOT, _value);
  }

  function sellFloor() public view returns (uint256) {
    return getUint256(_SELL_FLOOR_SLOT);
  }

  function _setProfitSharingNumerator(uint256 _value) internal {
    setUint256(_PROFIT_SHARING_NUMERATOR_SLOT, _value);
  }

  function profitSharingNumerator() public view returns (uint256) {
    return getUint256(_PROFIT_SHARING_NUMERATOR_SLOT);
  }

  function _setProfitSharingDenominator(uint256 _value) internal {
    setUint256(_PROFIT_SHARING_DENOMINATOR_SLOT, _value);
  }

  function profitSharingDenominator() public view returns (uint256) {
    return getUint256(_PROFIT_SHARING_DENOMINATOR_SLOT);
  }

  function allowedRewardClaimable() public view returns (bool) {
    return getBoolean(_REWARD_CLAIMABLE_SLOT);
  }

  function _setRewardClaimable(bool _value) internal {
    setBoolean(_REWARD_CLAIMABLE_SLOT, _value);
  }

  function multiSig() public view returns(address) {
    return getAddress(_MULTISIG_SLOT);
  }

  function _setMultiSig(address _address) internal {
    setAddress(_MULTISIG_SLOT, _address);
  }

  // upgradeability

  function _setNextImplementation(address _address) internal {
    setAddress(_NEXT_IMPLEMENTATION_SLOT, _address);
  }

  function nextImplementation() public view returns (address) {
    return getAddress(_NEXT_IMPLEMENTATION_SLOT);
  }

  function _setNextImplementationTimestamp(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT, _value);
  }

  function nextImplementationTimestamp() public view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT);
  }

  function _setNextImplementationDelay(uint256 _value) internal {
    setUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT, _value);
  }

  function nextImplementationDelay() public view returns (uint256) {
    return getUint256(_NEXT_IMPLEMENTATION_DELAY_SLOT);
  }

  function setBoolean(bytes32 slot, bool _value) internal {
    setUint256(slot, _value ? 1 : 0);
  }

  function getBoolean(bytes32 slot) internal view returns (bool) {
    return (getUint256(slot) == 1);
  }

  function setAddress(bytes32 slot, address _address) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _address)
    }
  }

  function setUint256(bytes32 slot, uint256 _value) internal {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, _value)
    }
  }

  function getAddress(bytes32 slot) internal view returns (address str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function getUint256(bytes32 slot) internal view returns (uint256 str) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }
}

pragma solidity 0.5.16;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./BaseUpgradeableStrategyStorage.sol";
import "../inheritance/ControllableInit.sol";
import "../interface/IController.sol";
import "../interface/IFeeRewardForwarderV6.sol";
import "../interface/ILiquidator.sol";
import "../interface/ILiquidatorRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract BaseUpgradeableStrategyUL is Initializable, ControllableInit, BaseUpgradeableStrategyStorage {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  bytes32 internal constant _UL_REGISTRY_SLOT = 0x7a4b558e8ed4a66729f4a918db093413f0f1ae77c0de7c88bea8b99e084b2a17;
  bytes32 internal constant _UL_SLOT = 0xebfe408f65547b28326a79acf512c0f9a2bf4211ece39254d7c3ec96dd3dd242;

  mapping(address => mapping(address => address[])) public storedLiquidationPaths;
  mapping(address => mapping(address => bytes32[])) public storedLiquidationDexes;

  event ProfitsNotCollected(bool sell, bool floor);
  event ProfitLogInReward(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);
  event ProfitAndBuybackLog(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);

  modifier restricted() {
    require(msg.sender == vault() || msg.sender == controller()
      || msg.sender == governance(),
      "The sender has to be the controller, governance, or vault");
    _;
  }

  // This is only used in `investAllUnderlying()`
  // The user can still freely withdraw from the strategy
  modifier onlyNotPausedInvesting() {
    require(!pausedInvesting(), "Action blocked as the strategy is in emergency state");
    _;
  }

  constructor() public BaseUpgradeableStrategyStorage() {
    assert(_UL_REGISTRY_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.ULRegistry")) - 1));
    assert(_UL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.UL")) - 1));
  }

  function initialize(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardPool,
    address _rewardToken,
    uint256 _profitSharingNumerator,
    uint256 _profitSharingDenominator,
    bool _sell,
    uint256 _sellFloor,
    uint256 _implementationChangeDelay,
    address _universalLiquidatorRegistry
  ) public initializer {
    ControllableInit.initialize(
      _storage
    );
    _setUnderlying(_underlying);
    _setVault(_vault);
    _setRewardPool(_rewardPool);
    _setRewardToken(_rewardToken);
    _setProfitSharingNumerator(_profitSharingNumerator);
    _setProfitSharingDenominator(_profitSharingDenominator);

    _setSell(_sell);
    _setSellFloor(_sellFloor);
    _setNextImplementationDelay(_implementationChangeDelay);
    _setPausedInvesting(false);
    _setUniversalLiquidatorRegistry(_universalLiquidatorRegistry);
    _setUniversalLiquidator(ILiquidatorRegistry(universalLiquidatorRegistry()).universalLiquidator());
  }

  /**
  * Schedules an upgrade for this vault's proxy.
  */
  function scheduleUpgrade(address impl) public onlyGovernance {
    _setNextImplementation(impl);
    _setNextImplementationTimestamp(block.timestamp.add(nextImplementationDelay()));
  }

  function _finalizeUpgrade() internal {
    _setNextImplementation(address(0));
    _setNextImplementationTimestamp(0);
  }

  function shouldUpgrade() external view returns (bool, address) {
    return (
      nextImplementationTimestamp() != 0
        && block.timestamp > nextImplementationTimestamp()
        && nextImplementation() != address(0),
      nextImplementation()
    );
  }

  // reward notification

  function notifyProfitInRewardToken(uint256 _rewardBalance) internal {
    if( _rewardBalance > 0 ){
      uint256 feeAmount = _rewardBalance.mul(profitSharingNumerator()).div(profitSharingDenominator());
      emit ProfitLogInReward(_rewardBalance, feeAmount, block.timestamp);
      IERC20(rewardToken()).safeApprove(controller(), 0);
      IERC20(rewardToken()).safeApprove(controller(), feeAmount);

      IController(controller()).notifyFee(
        rewardToken(),
        feeAmount
      );
    } else {
      emit ProfitLogInReward(0, 0, block.timestamp);
    }
  }

  function notifyProfitAndBuybackInRewardToken(uint256 _rewardBalance, address pool, uint256 _buybackRatio) internal {
    if( _rewardBalance > 0 ){
      uint256 feeAmount = _rewardBalance.mul(profitSharingNumerator()).div(profitSharingDenominator());
      uint256 buybackAmount = _rewardBalance.sub(feeAmount).mul(_buybackRatio).div(10000);

      address forwarder = IController(controller()).feeRewardForwarder();
      emit ProfitAndBuybackLog(_rewardBalance, feeAmount, block.timestamp);

      IERC20(rewardToken()).safeApprove(forwarder, 0);
      IERC20(rewardToken()).safeApprove(forwarder, _rewardBalance);

      IFeeRewardForwarderV6(forwarder).notifyFeeAndBuybackAmounts(
        rewardToken(),
        feeAmount,
        pool,
        buybackAmount
      );
    } else {
      emit ProfitAndBuybackLog(0, 0, block.timestamp);
    }
  }

  function _setUniversalLiquidatorRegistry(address _address) internal {
    setAddress(_UL_REGISTRY_SLOT, _address);
  }

  function universalLiquidatorRegistry() public view returns (address) {
    return getAddress(_UL_REGISTRY_SLOT);
  }

  function _setUniversalLiquidator(address _address) internal {
    setAddress(_UL_SLOT, _address);
  }

  function universalLiquidator() public view returns (address) {
    return getAddress(_UL_SLOT);
  }

  function configureLiquidation(address[] memory path, bytes32[] memory dexes) public onlyGovernance {
    address fromToken = path[0];
    address toToken = path[path.length - 1];

    require(dexes.length == path.length - 1, "lengths do not match");

    storedLiquidationPaths[fromToken][toToken] = path;
    storedLiquidationDexes[fromToken][toToken] = dexes;
  }
}

pragma solidity 0.5.16;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../../base/interface/IStrategy.sol";
import "../../base/upgradability/BaseUpgradeableStrategyUL.sol";

import "./interface/IIdleCDO.sol";
import "./interface/IWstETH.sol";
import "./interface/IDistributor.sol";
import "./interface/ILiquidityGaugeV3.sol";

contract IdleFinanceTrancheStrategy is IStrategy, BaseUpgradeableStrategyUL {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // additional storage slots (on top of BaseUpgradeableStrategy ones) are defined here
    bytes32 internal constant _IS_STETH = 0x9574989eae0060a39fe95049948b9a7bc2cfe07156ccbe6fea8f4f977bebcc04;
    bytes32 internal constant _IDLE_DISTRIBUTOR = 0xb2f7d491f85e6b66612eb5a10a2ed5d8285b176fec369924ce35cc46190bb048;
    bytes32 internal constant _LIQUIDITY_GAUGE = 0xdefb28cb4afe76becb36959ca990fb40075f668b97d0dbfc4c4da2c6e73e879a;
    bytes32 internal constant _LIQUIDITY_GAUGE_REWARD = 0xdb1165a9ca87102cffa27e10807f703b726c6ddabff7e9377e7b206ce2945fea;
    bytes32 internal constant _HODL_RATIO_SLOT = 0xb487e573671f10704ed229d25cf38dda6d287a35872859d096c0395110a0adb1;
    bytes32 internal constant _HODL_VAULT_SLOT = 0xc26d330f887c749cb38ae7c37873ff08ac4bba7aec9113c82d48a0cf6cc145f2;

    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public constant STETH = address(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    address public constant WSTETH = address(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    address public constant IDLE = address(0x875773784Af8135eA0ef43b5a374AaD105c5D39e);

    uint256 public constant ONE_TRANCHE_TOKEN = 10**18;
    uint256 public constant hodlRatioBase = 10000;
    address public constant multiSigAddr = address(0xF49440C1F012d041802b25A73e5B0B9166a75c02);

    constructor() public BaseUpgradeableStrategyUL() {
        assert(_IS_STETH == bytes32(uint256(keccak256("eip1967.strategyStorage.isstETH")) - 1));
        assert(_IDLE_DISTRIBUTOR == bytes32(uint256(keccak256("eip1967.strategyStorage.idleDistributor")) - 1));
        assert(_LIQUIDITY_GAUGE == bytes32(uint256(keccak256("eip1967.strategyStorage.liquidityGauge")) - 1));
        assert(_LIQUIDITY_GAUGE_REWARD == bytes32(uint256(keccak256("eip1967.strategyStorage.liquidityGaugeReward")) - 1));
        assert(_HODL_RATIO_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.hodlRatio")) - 1));
        assert(_HODL_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.hodlVault")) - 1));
    }

    /* ========== Initialize ========== */

    function initializeBaseStrategy(
        //  "__" for storage because we shadow _storage from GovernableInit
        address __storage,
        address _underlying,
        address _vault,
        address _rewardPool,
        address _idleDistributor,
        address _liquidityGauge,
        address _liquidityGaugeReward,
        uint256 _hodlRatio
    ) public initializer {

        uint256 profitSharingNumerator = 150;
        if (_hodlRatio >= 1500) {
          profitSharingNumerator = 0;
        } else if (_hodlRatio > 0){
          // (profitSharingNumerator - hodlRatio/10) * hodlRatioBase / (hodlRatioBase - hodlRatio)
          // e.g. with default values: (300 - 1000 / 10) * 10000 / (10000 - 1000)
          // = (300 - 100) * 10000 / 9000 = 222
          profitSharingNumerator = profitSharingNumerator.sub(_hodlRatio.div(10)) // subtract hodl ratio from profit sharing numerator
                                        .mul(hodlRatioBase) // multiply with hodlRatioBase
                                        .div(hodlRatioBase.sub(_hodlRatio)); // divide by hodlRatioBase minus hodlRatio
        }

        BaseUpgradeableStrategyUL.initialize({
            _storage: __storage,
            _underlying: _underlying,
            _vault: _vault,
            _rewardPool: _rewardPool,
            _rewardToken: WETH,
            _profitSharingNumerator: profitSharingNumerator,
            _profitSharingDenominator: 1000,
            _sell: true,
            _sellFloor: 0,
            _implementationChangeDelay: 12 hours,
            _universalLiquidatorRegistry: address(0x7882172921E99d590E097cD600554339fBDBc480)
        });

        bool isSTETH = _underlying == WSTETH;
        address underlyingTokenCDO = IIdleCDO(_rewardPool).token();

        if(isSTETH) {
            require(underlyingTokenCDO == STETH, "Invalid underlying");
        } else {
            require(underlyingTokenCDO == _underlying, "Invalid underlying");
        }

        _setIsSTETH(isSTETH);
        _setIdleDistributor(_idleDistributor);
        _setLiquidityGauge(_liquidityGauge);
        _setLiquidityGaugeReward(_liquidityGaugeReward);
        setUint256(_HODL_RATIO_SLOT, _hodlRatio);
        setAddress(_HODL_VAULT_SLOT, multiSigAddr);
    }

    /* ========== View ========== */

    function hodlRatio() public view returns (uint256) {
      return getUint256(_HODL_RATIO_SLOT);
    }

    function hodlVault() public view returns (address) {
      return getAddress(_HODL_VAULT_SLOT);
    }

    function depositArbCheck() public view returns (bool) {
        return true;
    }

    function unsalvagableTokens(address token) public view returns (bool) {
        return (token == rewardToken() || token == underlying());
    }

    function investedUnderlyingBalance() public view returns (uint256) {
        address _rewardPool = rewardPool();
        address tranche = IIdleCDO(_rewardPool).AATranche();
        uint256 trancheBalance = IERC20(tranche).balanceOf(address(this));
        uint256 liquidityGaugeBalance = ILiquidityGaugeV3(liquidityGauge()).balanceOf(address(this));
        uint256 tranchePrice = IIdleCDO(_rewardPool).tranchePrice(tranche);

        uint256 underlyingBalance = trancheBalance.add(liquidityGaugeBalance).mul(tranchePrice).div(ONE_TRANCHE_TOKEN);

        if(isSTETH()) {
            underlyingBalance = IWstETH(WSTETH).getWstETHByStETH(underlyingBalance);
        }

        return underlyingBalance;
    }

    /* ========== Internal ========== */

    function _investAll() internal {
        address _underlying = underlying();
        address _rewardPool = rewardPool();

        uint256 balance = IERC20(_underlying).balanceOf(address(this));

        if(balance == 0) {
            return;
        }

        if(isSTETH()) {
            IERC20(WSTETH).safeApprove(WSTETH, 0);
            IERC20(WSTETH).safeApprove(WSTETH, balance);

            balance = IWstETH(WSTETH).unwrap(balance);
            _underlying = STETH;
        }

        IERC20(_underlying).safeApprove(_rewardPool, 0);
        IERC20(_underlying).safeApprove(_rewardPool, balance);

        uint256 mintedShare = IIdleCDO(_rewardPool).depositAA(balance);
        address trancheToken = IIdleCDO(_rewardPool).AATranche();
        address _liquidityGauge = liquidityGauge();

        IERC20(trancheToken).safeApprove(_liquidityGauge, 0);
        IERC20(trancheToken).safeApprove(_liquidityGauge, mintedShare);
        ILiquidityGaugeV3(_liquidityGauge).deposit(mintedShare);
    }

    function _claimRewards() internal {
        IDistributor(idleDistributor()).distribute(liquidityGauge());
        if(liquidityGaugeReward() != address(0)) {
            ILiquidityGaugeV3(liquidityGauge()).claim_rewards();
        }
    }

    function _liquidateReward() internal {
        uint256 idleBalance = IERC20(IDLE).balanceOf(address(this));
        address _universalLiquidator = universalLiquidator();
        address _liquidityGaugeReward = liquidityGaugeReward();
        address _rewardToken = rewardToken();

        uint256 toHodlIdle = idleBalance.mul(hodlRatio()).div(hodlRatioBase);
        if (toHodlIdle > 0) {
          IERC20(IDLE).safeTransfer(hodlVault(), toHodlIdle);
          idleBalance = idleBalance.sub(toHodlIdle);
        }
        if(idleBalance != 0) {
            IERC20(IDLE).safeApprove(_universalLiquidator, 0);
            IERC20(IDLE).safeApprove(_universalLiquidator, idleBalance);

            ILiquidator(_universalLiquidator).swapTokenOnMultipleDEXes(
                idleBalance,
                1,
                address(this),
                storedLiquidationDexes[IDLE][_rewardToken],
                storedLiquidationPaths[IDLE][_rewardToken]
            );
        }

        if(_liquidityGaugeReward != address(0)) {
            uint256 liquidityGaugeRewardBalance = IERC20(_liquidityGaugeReward).balanceOf(address(this));
            uint256 toHodl = liquidityGaugeRewardBalance.mul(hodlRatio()).div(hodlRatioBase);
            if (toHodl > 0) {
              IERC20(_liquidityGaugeReward).safeTransfer(hodlVault(), toHodl);
              liquidityGaugeRewardBalance = liquidityGaugeRewardBalance.sub(toHodl);
            }
            if(liquidityGaugeRewardBalance != 0) {
                IERC20(_liquidityGaugeReward).safeApprove(_universalLiquidator, 0);
                IERC20(_liquidityGaugeReward).safeApprove(_universalLiquidator, liquidityGaugeRewardBalance);

                ILiquidator(_universalLiquidator).swapTokenOnMultipleDEXes(
                    liquidityGaugeRewardBalance,
                    1,
                    address(this),
                    storedLiquidationDexes[_liquidityGaugeReward][_rewardToken],
                    storedLiquidationPaths[_liquidityGaugeReward][_rewardToken]
                );
            }
        }

        uint256 rewardBalance = IERC20(_rewardToken).balanceOf(address(this));
        if (!sell() || rewardBalance < sellFloor()) {
            // Profits can be disabled for possible simplified and rapid exit
            emit ProfitsNotCollected(sell(), rewardBalance < sellFloor());
            return;
        }

        notifyProfitInRewardToken(rewardBalance);

        uint256 remainingRewardBalance = IERC20(_rewardToken).balanceOf(address(this));
        if (remainingRewardBalance == 0) {
        return;
        }

        IERC20(_rewardToken).safeApprove(_universalLiquidator, 0);
        IERC20(_rewardToken).safeApprove(_universalLiquidator, remainingRewardBalance);

        // we can accept 1 as minimum because this is called only by a trusted role
        ILiquidator(_universalLiquidator).swapTokenOnMultipleDEXes(
            remainingRewardBalance,
            1,
            address(this), // target
            storedLiquidationDexes[_rewardToken][underlying()],
            storedLiquidationPaths[_rewardToken][underlying()]
        );
    }

    /* ========== External ========== */

    function withdrawAllToVault() public restricted {
        address _rewardPool = rewardPool();
        address tranche = IIdleCDO(_rewardPool).AATranche();
        address _liquidityGauge = liquidityGauge();

        _claimRewards();
        _liquidateReward();


        uint256 liquidityGaugeBalance = ILiquidityGaugeV3(_liquidityGauge).balanceOf(address(this));
        ILiquidityGaugeV3(_liquidityGauge).withdraw(liquidityGaugeBalance);


        uint256 trancheBalance = IERC20(tranche).balanceOf(address(this));
        if(trancheBalance != 0) {
            uint256 redeemed = IIdleCDO(_rewardPool).withdrawAA(trancheBalance);

            if(isSTETH()) {
                IERC20(STETH).safeApprove(WSTETH, 0);
                IERC20(STETH).safeApprove(WSTETH, redeemed);
                IWstETH(WSTETH).wrap(redeemed);
            }
        }

        uint256 underlyingBalance = IERC20(underlying()).balanceOf(address(this));
        IERC20(underlying()).safeTransfer(vault(), underlyingBalance);
    }

    function withdrawToVault(uint256 amount) external restricted {
        uint256 entireBalance = IERC20(underlying()).balanceOf(address(this));

        if (amount > entireBalance) {
            address _rewardPool = rewardPool();
            address tranche = IIdleCDO(_rewardPool).AATranche();
            address _liquidityGauge = liquidityGauge();
            uint256 tranchePrice = IIdleCDO(_rewardPool).tranchePrice(tranche);

            uint256 amountToWithdraw = amount.sub(entireBalance);
            uint256 trancheBalanceToWithdraw = amountToWithdraw.mul(ONE_TRANCHE_TOKEN).div(tranchePrice);

            if(isSTETH()) {
                trancheBalanceToWithdraw = IWstETH(WSTETH).getStETHByWstETH(trancheBalanceToWithdraw);
            }

            ILiquidityGaugeV3(_liquidityGauge).withdraw(trancheBalanceToWithdraw);
            uint256 redeemed = IIdleCDO(_rewardPool).withdrawAA(trancheBalanceToWithdraw);

            if(isSTETH()) {
                IERC20(STETH).safeApprove(WSTETH, 0);
                IERC20(STETH).safeApprove(WSTETH, redeemed);
                IWstETH(WSTETH).wrap(redeemed);
            }
        }

        IERC20(underlying()).safeTransfer(vault(), amount);
    }

    function salvage(
        address recipient,
        address token,
        uint256 amount
    ) external onlyControllerOrGovernance {
        // To make sure that governance cannot come in and take away the coins
        require(!unsalvagableTokens(token), "token is defined as not salvagable");
        IERC20(token).safeTransfer(recipient, amount);
    }

    /*
     *   Get the reward, sell it in exchange for underlying, invest what you got.
     *   It's not much, but it's honest work.
     *
     *   Note that although `onlyNotPausedInvesting` is not added here,
     *   calling `investAllUnderlying()` affectively blocks the usage of `doHardWork`
     *   when the investing is being paused by governance.
     */
    function doHardWork() external onlyNotPausedInvesting restricted {
        _claimRewards();
        _liquidateReward();
        _investAll();
    }

    function setSell(bool s) external onlyGovernance {
        _setSell(s);
    }

    function setSellFloor(uint256 floor) external onlyGovernance {
        _setSellFloor(floor);
    }

    function finalizeUpgrade() external onlyGovernance {
        _finalizeUpgrade();
    }

    function setHodlVault(address _address) public onlyGovernance {
      setAddress(_HODL_VAULT_SLOT, _address);
    }

    function setHodlRatio(uint256 _value) public onlyGovernance {
      uint256 profitSharingNumerator = 300;
      if (_value >= 3000) {
        profitSharingNumerator = 0;
      } else if (_value > 0){
        // (profitSharingNumerator - hodlRatio/10) * hodlRatioBase / (hodlRatioBase - hodlRatio)
        // e.g. with default values: (300 - 1000 / 10) * 10000 / (10000 - 1000)
        // = (300 - 100) * 10000 / 9000 = 222
        profitSharingNumerator = profitSharingNumerator.sub(_value.div(10)) // subtract hodl ratio from profit sharing numerator
                                      .mul(hodlRatioBase) // multiply with hodlRatioBase
                                      .div(hodlRatioBase.sub(_value)); // divide by hodlRatioBase minus hodlRatio
      }
      _setProfitSharingNumerator(profitSharingNumerator);
      setUint256(_HODL_RATIO_SLOT, _value);
    }

    /* ========== Storage ========== */

    function _setIsSTETH(bool _value) internal {
        setBoolean(_IS_STETH, _value);
    }

    function isSTETH() public view returns (bool) {
        return getBoolean(_IS_STETH);
    }

    function _setIdleDistributor(address _addr) internal {
        setAddress(_IDLE_DISTRIBUTOR, _addr);
    }

    function idleDistributor() public view returns (address) {
        return getAddress(_IDLE_DISTRIBUTOR);
    }

    function _setLiquidityGauge(address _addr) internal {
        setAddress(_LIQUIDITY_GAUGE, _addr);
    }

    function liquidityGauge() public view returns (address) {
        return getAddress(_LIQUIDITY_GAUGE);
    }

    function _setLiquidityGaugeReward(address _addr) internal {
        setAddress(_LIQUIDITY_GAUGE_REWARD, _addr);
    }

    function liquidityGaugeReward() public view returns (address) {
        return getAddress(_LIQUIDITY_GAUGE_REWARD);
    }

    function() external payable {
        require(msg.sender == WETH, "direct eth transfer not allowed");
    }
}

pragma solidity 0.5.16;

import "./IdleFinanceTrancheStrategy.sol";

contract IdleTrancheStrategyMainnet_wstETH is IdleFinanceTrancheStrategy {
    constructor() public {}

    function initializeStrategy(address _storage, address _vault)
        public
        initializer
    {
        address weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        address wsteth = address(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
        address idle = address(0x875773784Af8135eA0ef43b5a374AaD105c5D39e);
        address ldo = address(0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32);

        bytes32 uniV3Dex = 0x8f78a54cb77f4634a5bf3dd452ed6a2e33432c73821be59208661199511cd94f;
        bytes32 sushiDex = 0xcb2d20206d906069351c89a2cb7cdbd96c71998717cd5a82e724d955b654f67a;

        IdleFinanceTrancheStrategy.initializeBaseStrategy(
            _storage,
            wsteth, // wstETH
            _vault,
            address(0x34dCd573C5dE4672C8248cd12A99f875Ca112Ad8), // Lido stETH AA/BB Perp Tranche
            address(0x074306BC6a6Fc1bD02B425dd41D742ADf36Ca9C6), // Distributor
            address(0x675eC042325535F6e176638Dd2d4994F645502B9), // AATranche_lido gague
            ldo, // LDO
            500 //hodl ratio: 5%
        );

        storedLiquidationDexes[idle][weth] = [sushiDex];
        storedLiquidationPaths[idle][weth] = [idle, weth];
        storedLiquidationDexes[ldo][weth] = [uniV3Dex];
        storedLiquidationPaths[ldo][weth] = [ldo, weth];
        storedLiquidationDexes[weth][wsteth] = [uniV3Dex];
        storedLiquidationPaths[weth][wsteth] = [weth, wsteth];
    }
}

pragma solidity 0.5.16;

contract IDistributor {
    function distribute(address gauge_addr) external;
}

pragma solidity 0.5.16;

contract IIdleCDO {
    function depositAA(uint256 _amount) external returns (uint256);
    function depositBB(uint256 _amount) external returns (uint256);
    function withdrawAA(uint256 _amount ) external returns (uint256);
    function withdrawBB(uint256 _amount) external returns (uint256);
    function token() external view returns (address);
    function strategyToken() external view returns (address);
    function AATranche() external view returns (address);
    function BBTranche() external view returns (address); 
    function tranchePrice(address tranche) external view returns (uint256);
}

pragma solidity 0.5.16;

contract ILiquidityGaugeV3 {
    function deposit(uint256 _value) external;
    function deposit(uint256 _value, address _addr) external;
    function deposit(uint256 _value, address _addr, bool _claim_rewards) external;
    function withdraw(uint256 _value) external;
    function withdraw(uint256 _value, bool _claim_rewards) external;
    function claim_rewards() external;
    function approve(address _spender, uint256 _value) external;
    function balanceOf(address _addr) external view returns (uint256);
}

pragma solidity 0.5.16;

contract IWstETH {
    function wrap(uint256 _stETHAmount) external returns (uint256);
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
    function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256);
}