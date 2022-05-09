// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "BaseContract.sol";
import "RangoCBridgeProxy.sol";
import "RangoAnyswap.sol";
import "RangoThorchain.sol";

contract RangoV1 is BaseContract, RangoCBridgeProxy, RangoAnyswap, RangoThorchain {
    // [DELAYED] TODO: Move safeApprove somehow to creation time: addUniswapV2Factory or a separate function
    // [DELAYED] TODO: Check gas fee for creating the exchange variable
    // [DELAYED] TODO: add destroy to contract with admin access, may not be a good idea
    // [DONE] TODO: Add parameters for fee amount and affiliate
    // [DONE] TODO: add Event log
    // [DONE] TODO: use safemath
    // [DONE] TODO: Check reentrancy, read about it first
    // [DONE] TODO: add pause to contract with admin access
    // [DONE] TODO: add a proxy delegatecall contract
    // TODO: study upgrading contract issues + pausable problem on that
    // TODO: use security analysis tools
    // TODO: use CI/CD
    // TODO: test native ETH token transfer for uniswap-v2
    // TODO: remove ERC20.sol and use openzeppelin
    // TODO: remove approve and replace with IERC20(?).safeIncreaseAllowance
    // TODO: try send back to original chain based on https://github.com/celer-network/sgn-v2-contracts/blob/main/contracts/message/apps/TransferSwapSendBack.sol
    // TODO: make destination swap optional
    // TODO: what is onlyEOA?  modifier onlyEOA() {
    //        require(msg.sender == tx.origin, "Not EOA");
    //        _;
    //    }
    // TODO: check destination swaps in cbridge-IM whitelisted
    // TODO: enabled native swap for non-bridge function
    // TODO: update formula -> uint totalInputAmount = request.feeIn + request.affiliateIn + request.amountIn;
    // TODO: separate cbridge contract into another one
    // TODO: add refund for native token
    // TODO: add other anyswap functions
    // TODO: add other uniswap-v2 functions
    // TODO: limit cbridge/anyswap contracts to be called only from owner or Rango contract
    // TODO: handle duplicate constructors all over contracts
    // TODO: implement celer-im refund/fallback correctly
    // TODO: set a maximum value for fee and affiliate values to prevent mistakes
    // TODO: test executeMessageWithTransferFallback if it works

    constructor(address _nativeWrappedAddress) {
        nativeWrappedAddress = _nativeWrappedAddress;
    }

    function initialize() public initializer {
        feeContractAddress = NULL_ADDRESS;
        rangoCBridgeAddress = NULL_ADDRESS;
        anyswapAddresses = new address[](0);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "Ownable.sol";
import "SafeMath.sol";
import "ReentrancyGuard.sol";
import "Pausable.sol";
import "Initializable.sol";
import "ERC20.sol";
import "TransferHelper.sol";
import "IWETH.sol";
import "IThorchainRouter.sol";

contract BaseContract is Pausable, Initializable, Ownable, ReentrancyGuard {
    using SafeMath for uint;

    address payable feeContractAddress;
    address nativeWrappedAddress;
    address payable constant NULL_ADDRESS = payable(0x0000000000000000000000000000000000000000);
    mapping(address => bool) public whitelistContracts;

    event FeeReward(address token, address wallet, uint amount);
    event AffiliateReward(address token, address wallet, uint amount);
    event CallResult(address target, bool success, bytes returnData);

    struct Call {address payable target; bytes callData;}

    struct Result {bool success; bytes returnData;}

    struct SwapRequest {
        address fromToken;
        address toToken;
        uint amountIn;
        uint feeIn;
        uint affiliateIn;
        address payable affiliatorAddress;
    }

    function addWhitelist(address _factory) external onlyOwner {
        whitelistContracts[_factory] = true;
    }

    function removeWhitelist(address _factory) external onlyOwner {
        require(whitelistContracts[_factory], 'Factory not found');
        delete whitelistContracts[_factory];
    }

    function updateFeeContractAddress(address payable _address) external onlyOwner {
        feeContractAddress = _address;
    }

    function refund(address _tokenAddress, uint256 _amount) external onlyOwner {
        ERC20 ercToken = ERC20(_tokenAddress);
        uint balance = ercToken.balanceOf(address(this));
        require(balance >= _amount, 'Insufficient balance');

        TransferHelper.safeTransfer(_tokenAddress, msg.sender, _amount);
    }

    function onChainSwaps(
        SwapRequest memory request,
        Call[] calldata calls
    ) external whenNotPaused nonReentrant returns (bytes[] memory) {
        (bytes[] memory result, uint outputAmount) = onChainSwapsInternal(request, calls);
        TransferHelper.safeTransfer(request.toToken, msg.sender, outputAmount);
        return result;
    }

    function onChainSwapsInternal(
        SwapRequest memory request,
        Call[] calldata calls
    ) internal nonReentrant returns (bytes[] memory, uint) {

        ERC20 ercToken = ERC20(request.toToken);
        uint balanceBefore;
        if (request.fromToken == address(0)) {
            balanceBefore = address(this).balance;
        }
        else {
            balanceBefore = ercToken.balanceOf(address(this));
        }

        bytes[] memory result = callSwapsAndFees(request, calls);

        uint balanceAfter;
        if (request.toToken == address(0)) {
            balanceAfter = address(this).balance;
        } else {
            balanceAfter = ercToken.balanceOf(address(this));
        }

        require(balanceAfter - balanceBefore > 0, "No balance found to bridge");

        uint secondaryBalance = balanceAfter - balanceBefore;
        return (result, secondaryBalance);
    }

    function callSwapsAndFees(
        SwapRequest memory request,
        Call[] calldata calls
    ) private returns (bytes[] memory) {

        for (uint256 i = 0; i < calls.length; i++) {
            require(whitelistContracts[calls[i].target], "Contact not whitelisted");
        }

        // Get all the money from user
        uint totalInputAmount = request.feeIn + request.affiliateIn + request.amountIn;

        bool isNative = false;
        if (request.fromToken == address(0)) {
            isNative = true;
        }
        if (!isNative) {
            approve(request.fromToken, calls[0].target, totalInputAmount);
            // Transfer from wallet to contract
            TransferHelper.safeTransferFrom(request.fromToken, msg.sender, address(this), totalInputAmount);
        }

        // Get Platform fee
        if (request.feeIn > 0 && feeContractAddress != NULL_ADDRESS) {
            TransferHelper.safeTransfer(request.fromToken, feeContractAddress, request.feeIn);
            emit FeeReward(request.fromToken, feeContractAddress, request.feeIn);
        }

        // Get affiliator fee
        if (request.affiliateIn > 0) {
            require(request.affiliatorAddress != NULL_ADDRESS, "Invalid affiliatorAddress");
            TransferHelper.safeTransfer(request.fromToken, request.affiliatorAddress, request.affiliateIn);
            emit AffiliateReward(request.fromToken, request.affiliatorAddress, request.affiliateIn);
        }

        bytes[] memory returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            emit CallResult(calls[i].target, success, ret);
            require(success, string(abi.encodePacked("Call failed, index:", i)));
            returnData[i] = ret;
        }

        return returnData;
    }

    function approve(address token, address to, uint value) internal {
        TransferHelper.safeApprove(token, to, 0);
        TransferHelper.safeApprove(token, to, value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
library SafeMath {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ERC20 {
    function balanceOf(address tokenOwner) external returns (uint balance);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IThorchainRouter {
    function depositWithExpiry(
        address payable vault,
        address asset,
        uint amount,
        string calldata memo,
        uint expiration) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "BaseContract.sol";
import "IRangoCBridge.sol";

contract RangoCBridgeProxy is BaseContract {
    address rangoCBridgeAddress;

    function updateRangoCBridgeAddress(address _address) external onlyOwner {
        rangoCBridgeAddress = _address;
    }

    function cBridgeIMNative(
        SwapRequest memory request,
        Call[] calldata calls,

        address _receiverContract, // The receiver app contract address, not recipient
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        uint _sgnFee,

        RangoCBridgeModels.RangoCBridgeInterChainMessage memory imMessage
    ) external payable whenNotPaused nonReentrant {
        require(rangoCBridgeAddress != NULL_ADDRESS, 'cBridge address in Rango contract not set');

        uint minimumRequiredValue = request.feeIn + request.affiliateIn + request.amountIn + _sgnFee;
        require(msg.value >= minimumRequiredValue, 'Send more ETH to cover sgnFee + input amount');

        cBridgeIMInternal(request, calls, _receiverContract, _dstChainId, _nonce, _maxSlippage, _sgnFee, imMessage, true);
    }


    function cBridgeIM(
        SwapRequest memory request,
        Call[] calldata calls,

        address _receiverContract, // The receiver app contract address, not recipient
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        uint _sgnFee,

        RangoCBridgeModels.RangoCBridgeInterChainMessage memory imMessage
    ) external payable whenNotPaused nonReentrant {
        require(rangoCBridgeAddress != NULL_ADDRESS, 'cBridge address in Rango contract not set');

        uint nativeInput = msg.value - _sgnFee;
        require(nativeInput >= 0, 'sgnFee is bigger than the input');

        cBridgeIMInternal(request, calls, _receiverContract, _dstChainId, _nonce, _maxSlippage, _sgnFee, imMessage, false);
    }

    function cBridgeIMInternal(
        SwapRequest memory request,
        Call[] calldata calls,

        address _receiverContract, // The receiver app contract address, not recipient
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        uint _sgnFee,

        RangoCBridgeModels.RangoCBridgeInterChainMessage memory imMessage,
        bool isNative
    ) private {
        (, uint out) = onChainSwapsInternal(request, calls);
        approve(request.toToken, rangoCBridgeAddress, out);

        IRangoCBridge(rangoCBridgeAddress).cBridgeIM{value: _sgnFee}(
            request.toToken,
            out,
            _receiverContract,
            _dstChainId,
            _nonce,
            _maxSlippage,
            _sgnFee,
            imMessage
        );
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "BaseContract.sol";
import "RangoCBridgeModels.sol";

interface IRangoCBridge {
    function cBridgeIM(
        address _fromToken,
        uint _inputAmount,
        address _receiverContract, // The receiver app contract address, not recipient
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        uint _sgnFee,

        RangoCBridgeModels.RangoCBridgeInterChainMessage memory imMessage
    ) external payable;

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library RangoCBridgeModels {
    struct RangoCBridgeInterChainMessage {
        uint64 dstChainId;
        address dexAddress;
        address fromToken;
        address toToken;
        uint amountOutMin;
        address[] path;
        uint deadline;
        bool nativeOut;
        address originalSender;
        address recipient;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "Anyswap.sol";
import "BaseContract.sol";

contract RangoAnyswap is BaseContract {
    address[] anyswapAddresses;

    function addAnyswapAddress(address _address) external onlyOwner {
        anyswapAddresses.push(_address);
    }

    function removeAnyswapAddress(uint256 _index) external onlyOwner {
        anyswapAddresses[_index] = anyswapAddresses[anyswapAddresses.length - 1];
        anyswapAddresses.pop();
    }

    function anyswapOut(
        SwapRequest memory request,
        Call[] calldata calls,

        address anyswapAddress,
        address _to,
        uint _toChainID
    ) external whenNotPaused nonReentrant {
        (, uint outputAmount) = onChainSwapsInternal(request, calls);
        approve(request.toToken, anyswapAddress, outputAmount);

        checkAnyswapAddress(anyswapAddress);
        Anyswap anyswap = Anyswap(anyswapAddress);
        anyswap.anySwapOut(request.toToken, _to, outputAmount, _toChainID);
    }

    function anyswapOutUnderlying(
        SwapRequest memory request,
        Call[] calldata calls,

        address anyswapAddress,
        address _to,
        uint _toChainID
    ) external whenNotPaused nonReentrant {
        (, uint outputAmount) = onChainSwapsInternal(request, calls);
        approve(request.toToken, anyswapAddress, outputAmount);

        checkAnyswapAddress(anyswapAddress);
        Anyswap anyswap = Anyswap(anyswapAddress);
        anyswap.anySwapOutUnderlying(request.toToken, _to, outputAmount, _toChainID);
    }

    function checkAnyswapAddress(address _address) private {
        bool isValidAddress = false;
        for (uint i = 0; i < anyswapAddresses.length; i++) {
            if (anyswapAddresses[i] == _address) {
                isValidAddress = true;
            }
        }
        require(isValidAddress, "Input address does not match the anyswap router address");
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface Anyswap {
    function anySwapOut(address token, address to, uint amount, uint toChainID) external;
    function anySwapOutUnderlying(address token, address to, uint amount, uint toChainID) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "BaseContract.sol";
import "IThorchainRouter.sol";

contract RangoThorchain is BaseContract {
    //    address rangoThorchainAddress;
    //
    //    function updateRangoThorchainAddress(address _address) external onlyOwner {
    //        rangoThorchainAddress = _address;
    //    }

    //    function swapIn(
    function swapInToThorchain(
        SwapRequest memory request,
        Call[] calldata calls,
        address tcRouter,
        address tcVault,
        string calldata thorchainMemo,
        uint expiration
    ) external payable whenNotPaused nonReentrant {
        require(whitelistContracts[tcRouter], "given thorchain router not whitelisted");
        if (request.fromToken == address(0)) {require(msg.value > 0, "zero input while fromToken is native");}

        // do the on-chain swaps
        uint outputAmount;
        uint value = 0;
        if (calls.length > 0) {
            (, outputAmount) = onChainSwapsInternal(request, calls);
            value = outputAmount;
        } else if (request.toToken == address(0)) {
            value = msg.value;
            outputAmount = msg.value;
            // TODO: require msg.value equal to request.amountIn ?
        }

        IThorchainRouter(tcRouter).depositWithExpiry{value : value}(
            payable(tcVault),  // address payable vault,
            request.toToken, // ETH ? TODO  // address asset,
            outputAmount,  // uint amount,
            thorchainMemo,  // string calldata memo,
            expiration  // uint expiration) external payable;
        );
    }

    //    function swapOut(address token, address to, uint256 amountOutMin) external payable whenNotPaused nonReentrant // TODO: limit to be called only by thorchain router?
    //    {
    //        address[] memory path = new address[](2);
    //        path[0] = nativeWrappedAddress;
    //        path[1] = token;
    //        swapRouter.swapExactETHForTokens{value : msg.value}( // todo: implement multiple contracts each for uniswap v2, v3, sushi etc? or just use existing thorchain routers?
    //            amountOutMin,
    //            path,
    //            to,
    //            type(uint).max // deadline
    //        );
    //    }
}