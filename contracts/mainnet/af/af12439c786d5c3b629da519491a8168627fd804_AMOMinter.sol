// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IAgToken.sol";
import "../interfaces/IAMO.sol";
import "../interfaces/IAMOMinter.sol";
import "../interfaces/ICoreBorrow.sol";

/// @title AMOMinter
/// @author Angle Core Team
/// @notice Manages Algorithmic Market Operations (AMOs) of the Angle Protocol
/// @dev This contract supports AMOs on the protocol's native agTokens and on any ERC20 token
/// @dev Inspired from https://github.com/FraxFinance/frax-solidity/blob/master/src/hardhat/contracts/Frax/FraxAMOMinter.sol
contract AMOMinter is Initializable, IAMOMinter {
    using SafeERC20 for IERC20;

    /// @notice `coreBorrow` used to check roles
    ICoreBorrow public coreBorrow;
    /// @notice Array of all supported AMOs
    IAMO[] public amoList;
    /// @notice Maps an AMO to whether it is whitelisted
    mapping(IAMO => uint256) public amosWhitelist;
    /// @notice Maps an AMO to whether an address can call the `sendToAMO`/`receiveFromAMO` functions associated to it
    mapping(IAMO => mapping(address => uint256)) public amosWhitelistCaller;
    /// @notice Maps an AMO to whether it is whitelisted or not for a particular token
    mapping(IAMO => mapping(IERC20 => uint256)) public amosWhitelistToken;
    /// @notice Maps each AMO to the list of tokens it currently supports
    mapping(IAMO => IERC20[]) public amoTokens;
    /// @notice Max amount borrowable by each `(AMO,token)` pair
    mapping(IAMO => mapping(IERC20 => uint256)) public borrowCaps;
    /// @notice AMO debt to the AMOMinter for a given token
    mapping(IAMO => mapping(IERC20 => uint256)) public amoDebts;

    uint256[42] private __gap;

    // =============================== Events ======================================

    event AMOAdded(IAMO indexed amo);
    event AMOMinterUpdated(address indexed _amoMinter);
    event AMORemoved(IAMO indexed amo);
    event AMORightOnTokenAdded(IAMO indexed amo, IERC20 indexed token);
    event AMORightOnTokenRemoved(IAMO indexed amo, IERC20 indexed token);
    event BorrowCapUpdated(IAMO indexed amo, IERC20 indexed token, uint256 borrowCap);
    event CoreBorrowUpdated(ICoreBorrow indexed _coreBorrow);
    event Recovered(address indexed tokenAddress, address indexed to, uint256 amountToRecover);

    // =============================== Errors ======================================

    error AMOAlreadyAdded();
    error AMONonExistent();
    error AMONotWhitelisted();
    error AMOTokenDebtNotRepaid();
    error AMOWhitelisted();
    error BorrowCapReached();
    error IncompatibleLengths();
    error NoRightsOnToken();
    error NotApprovedCaller();
    error NotGovernor();
    error SupportedTokensNotRemoved();
    error ZeroAddress();

    // =============================== Initialisation ==============================

    /// @notice Initializes the `AMOMinter` contract and the access control
    /// @param coreBorrow_ Address of the associated `CoreBorrow` contract needed for checks on roles
    function initialize(ICoreBorrow coreBorrow_) public initializer {
        if (address(coreBorrow_) == address(0)) revert ZeroAddress();
        coreBorrow = coreBorrow_;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // =============================== Modifiers ===================================

    /// @notice Checks whether the `msg.sender` has the governor role or not
    modifier onlyGovernor() {
        if (!coreBorrow.isGovernor(msg.sender)) revert NotGovernor();
        _;
    }

    /// @notice Checks whether the `msg.sender` has the guardian role or not
    modifier onlyApproved(IAMO amo) {
        if (!coreBorrow.isGovernorOrGuardian(msg.sender) && amosWhitelistCaller[amo][msg.sender] != 1)
            revert NotApprovedCaller();
        _;
    }

    // ========================= View Functions ====================================

    /// @inheritdoc IAMOMinter
    function isGovernor(address admin) external view returns (bool) {
        return coreBorrow.isGovernor(admin);
    }

    /// @inheritdoc IAMOMinter
    function isApproved(address admin) external view returns (bool) {
        return (coreBorrow.isGovernorOrGuardian(admin) || amosWhitelistCaller[IAMO(msg.sender)][admin] == 1);
    }

    /// @inheritdoc IAMOMinter
    function callerDebt(IERC20 token) external view returns (uint256) {
        return amoDebts[IAMO(msg.sender)][token];
    }

    /// @notice Returns the list of all AMOs supported by this contract
    function allAMOAddresses() external view returns (IAMO[] memory) {
        return amoList;
    }

    /// @notice Returns the list of all the tokens supported by a given AMO
    function allAMOTokens(IAMO amo) external view returns (IERC20[] memory) {
        return amoTokens[amo];
    }

    // ============================== External function ============================

    /// @notice Lets someone reimburse the debt of an AMO on behalf of this AMO
    /// @param tokens Addresses of tokens for which debt should be reduced
    /// @param amounts Amounts of debt reduction to perform
    /// @dev Caller should have approved the `AMOMinter` contract and have enough tokens in balance
    /// @dev We typically expect this function to be called by governance to balance gains and losses
    /// between AMOs
    function repayDebtFor(
        IAMO[] memory amos,
        IERC20[] memory tokens,
        uint256[] memory amounts
    ) external {
        if (tokens.length != amos.length || tokens.length != amounts.length || tokens.length == 0)
            revert IncompatibleLengths();
        for (uint256 i = 0; i < tokens.length; i++) {
            tokens[i].safeTransferFrom(msg.sender, address(this), amounts[i]);
            // Keep track of the changed debt
            amoDebts[amos[i]][tokens[i]] -= amounts[i];
        }
    }

    // ======================== Only Approved for AMO Functions ====================

    /// @inheritdoc IAMOMinter
    function sendToAMO(
        IAMO amo,
        IERC20[] memory tokens,
        bool[] memory isStablecoin,
        uint256[] memory amounts,
        bytes[] memory data
    ) external onlyApproved(amo) {
        if (tokens.length != isStablecoin.length || tokens.length != amounts.length || tokens.length == 0)
            revert IncompatibleLengths();
        // First fill the tank for the AMO
        for (uint256 i = 0; i < tokens.length; i++) {
            // Checking if `token` has been whitelisted for `amo`
            if (amosWhitelistToken[amo][tokens[i]] != 1) revert NoRightsOnToken();
            // Keeping track of the changed debt and making sure you aren't lending more than the borrow cap
            if (amoDebts[amo][tokens[i]] + amounts[i] > borrowCaps[amo][tokens[i]]) revert BorrowCapReached();
            amoDebts[amo][tokens[i]] += amounts[i];
            // Minting the token to the AMO or simply transferring collateral to it
            if (isStablecoin[i]) IAgToken(address(tokens[i])).mint(address(amo), amounts[i]);
            else tokens[i].transfer(address(amo), amounts[i]);
        }
        // Then notify to the AMO that the tank was filled
        IAMO(amo).push(tokens, amounts, data);
    }

    /// @inheritdoc IAMOMinter
    function receiveFromAMO(
        IAMO amo,
        IERC20[] memory tokens,
        bool[] memory isStablecoin,
        uint256[] memory amounts,
        address[] memory to,
        bytes[] memory data
    ) external onlyApproved(amo) {
        if (
            tokens.length != isStablecoin.length ||
            tokens.length != amounts.length ||
            tokens.length != to.length ||
            tokens.length == 0
        ) revert IncompatibleLengths();
        // First notify that we want to recover tokens
        uint256[] memory amountsAvailable = IAMO(amo).pull(tokens, amounts, data);
        // Then empty the tank of the amo
        for (uint256 i = 0; i < tokens.length; i++) {
            // No need to check if the token is whitelisted for the AMO, because otherwise there will be
            // an underflow when updating `amoDebts`
            uint256 amount = amounts[i] <= amountsAvailable[i] ? amounts[i] : amountsAvailable[i];
            // Burn the agToken from the AMO or simply transfer it to this address
            if (isStablecoin[i])
                IAgToken(address(tokens[i])).burnSelf(amount, address(amo));
                // Transfer the collateral to the AMO
            else tokens[i].safeTransferFrom(address(amo), to[i], amount);
            // Keep track of the changed debt
            amoDebts[amo][tokens[i]] -= amount;
        }
    }

    // =============================== AMO Management ==============================

    /// @notice Adds an AMO to the whitelist
    /// @param amo Address of the AMO to be whitelisted
    function addAMO(IAMO amo) public onlyGovernor {
        if (address(amo) == address(0)) revert ZeroAddress();
        if (amosWhitelist[amo] == 1) revert AMOAlreadyAdded();
        amosWhitelist[amo] = 1;
        amoList.push(amo);
        emit AMOAdded(amo);
    }

    /// @notice Removes an AMO from whitelist
    /// @param amo Address of the AMO to be removed
    /// @dev To be successfully removed the AMO should no longer be associated to a token
    function removeAMO(IAMO amo) public onlyGovernor {
        if (address(amo) == address(0)) revert ZeroAddress();
        if (amosWhitelist[amo] != 1) revert AMONonExistent();
        if (amoTokens[amo].length > 0) revert SupportedTokensNotRemoved();
        // Removing the whitelisting first
        delete amosWhitelist[amo];

        // Deletion from `amoList` list then
        IAMO[] memory amoAllowed = amoList;
        uint256 amoListLength = amoAllowed.length;
        for (uint256 i = 0; i < amoListLength - 1; i++) {
            if (amoAllowed[i] == amo) {
                // Replace the `amo` to remove with the last of the list
                amoList[i] = amoList[amoListLength - 1];
                break;
            }
        }
        // Remove last element in array
        amoList.pop();

        emit AMORemoved(amo);
    }

    /// @notice Adds right for `token` to the `amo`
    /// @param amo Address of the AMO which will have rights on `token`
    /// @param token Address of the token to be whitelisted for the `amo`
    function addTokenRightToAMO(
        IAMO amo,
        IERC20 token,
        uint256 borrowCap
    ) public onlyGovernor {
        if (address(token) == address(0)) revert ZeroAddress();
        if (amosWhitelistToken[amo][token] == 1) revert AMOWhitelisted();
        if (amosWhitelist[amo] != 1) addAMO(amo);
        amosWhitelistToken[amo][token] = 1;
        amoTokens[amo].push(token);
        borrowCaps[amo][token] = borrowCap;
        amo.setToken(token);
        emit AMORightOnTokenAdded(amo, token);
        emit BorrowCapUpdated(amo, token, borrowCap);
    }

    /// @notice Removes the right on `token` from the `amo`
    /// @param amo Address of the AMO who will lose rights on `token`
    /// @param token Address of the `token`
    function removeTokenRightFromAMO(IAMO amo, IERC20 token) public onlyGovernor {
        if (amosWhitelistToken[amo][token] != 1) revert AMONotWhitelisted();
        if (amoDebts[amo][token] > 0) revert AMOTokenDebtNotRepaid();
        // Removing the whitelisting first
        delete amosWhitelistToken[amo][token];
        // Resetting borrow cap
        delete borrowCaps[amo][token];

        // Deletion from `amoTokens[amo]` loop
        IERC20[] memory tokenAllowed = amoTokens[amo];
        uint256 amoTokensLength = tokenAllowed.length;
        for (uint256 i = 0; i < amoTokensLength - 1; i++) {
            if (tokenAllowed[i] == token) {
                // Replace the `amo` to remove with the last of the list
                amoTokens[amo][i] = amoTokens[amo][amoTokensLength - 1];
                break;
            }
        }
        // Removing the last element in an array
        amoTokens[amo].pop();
        amo.removeToken(token);

        emit AMORightOnTokenRemoved(amo, token);
        emit BorrowCapUpdated(amo, token, 0);
    }

    /// @notice Toggles the approval right for an address on an AMO
    /// @param amo Address of the AMO
    /// @param whitelistCaller Address of the caller that needs right on send / receive
    /// functions associated to the AMo
    function toggleCallerToAMO(IAMO amo, address whitelistCaller) public onlyGovernor {
        if (address(whitelistCaller) == address(0)) revert ZeroAddress();
        if (amosWhitelist[amo] != 1) revert AMONonExistent();
        amosWhitelistCaller[amo][whitelistCaller] = 1 - amosWhitelistCaller[amo][whitelistCaller];
    }

    // =============================== Setters =====================================

    /// @notice Sets the borrow cap for a given token and a given amo
    /// @param amo AMO concerned by the change
    /// @param token Token associated to the AMO
    /// @param borrowCap New borrow cap value
    function setBorrowCap(
        IAMO amo,
        IERC20 token,
        uint256 borrowCap
    ) external onlyGovernor {
        if (amosWhitelistToken[amo][token] != 1) revert AMONotWhitelisted();
        borrowCaps[amo][token] = borrowCap;
        emit BorrowCapUpdated(amo, token, borrowCap);
    }

    /// @notice Changes the AMOMinter contract and propagates this change to all underlying AMO contracts
    /// @param amoMinter Address of the new `amoMinter` contract
    function setAMOMinter(address amoMinter) external onlyGovernor {
        if (amoMinter == address(0)) revert ZeroAddress();
        IAMO[] memory amoAllowed = amoList;
        for (uint256 i = 0; i < amoAllowed.length; i++) {
            amoAllowed[i].setAMOMinter(amoMinter);
        }
        emit AMOMinterUpdated(amoMinter);
    }

    /// @notice Sets a new `coreBorrow` contract
    /// @dev This function should typically be called on all treasury contracts after the `setCore`
    /// function has been called on the `CoreBorrow` contract
    /// @dev One sanity check that can be performed here is to verify whether at least the governor
    /// calling the contract is still a governor in the new core
    function setCoreBorrow(ICoreBorrow _coreBorrow) external onlyGovernor {
        if (!_coreBorrow.isGovernor(msg.sender)) revert NotGovernor();
        coreBorrow = ICoreBorrow(_coreBorrow);
        emit CoreBorrowUpdated(_coreBorrow);
    }

    // =============================== Generic functions ===========================

    /// @notice Recovers any ERC20 token
    /// @dev Can be used to withdraw bridge tokens for them to be de-bridged on mainnet
    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 amountToRecover
    ) external onlyGovernor {
        IERC20(tokenAddress).safeTransfer(to, amountToRecover);
        emit Recovered(tokenAddress, to, amountToRecover);
    }

    /// @notice Generic function to execute arbitrary calls with the contract
    function execute(address _to, bytes calldata _data) external onlyGovernor returns (bool, bytes memory) {
        //solhint-disable-next-line
        (bool success, bytes memory result) = _to.call(_data);
        return (success, result);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title IAgToken
/// @author Angle Core Team
/// @notice Interface for the stablecoins `AgToken` contracts
/// @dev This interface only contains functions of the `AgToken` contract which are called by other contracts
/// of this module or of the first module of the Angle Protocol
interface IAgToken is IERC20Upgradeable {
    // ======================= Minter Role Only Functions ===========================

    /// @notice Lets the `StableMaster` contract or another whitelisted contract mint agTokens
    /// @param account Address to mint to
    /// @param amount Amount to mint
    /// @dev The contracts allowed to issue agTokens are the `StableMaster` contract, `VaultManager` contracts
    /// associated to this stablecoin as well as the flash loan module (if activated) and potentially contracts
    /// whitelisted by governance
    function mint(address account, uint256 amount) external;

    /// @notice Burns `amount` tokens from a `burner` address after being asked to by `sender`
    /// @param amount Amount of tokens to burn
    /// @param burner Address to burn from
    /// @param sender Address which requested the burn from `burner`
    /// @dev This method is to be called by a contract with the minter right after being requested
    /// to do so by a `sender` address willing to burn tokens from another `burner` address
    /// @dev The method checks the allowance between the `sender` and the `burner`
    function burnFrom(
        uint256 amount,
        address burner,
        address sender
    ) external;

    /// @notice Burns `amount` tokens from a `burner` address
    /// @param amount Amount of tokens to burn
    /// @param burner Address to burn from
    /// @dev This method is to be called by a contract with a minter right on the AgToken after being
    /// requested to do so by an address willing to burn tokens from its address
    function burnSelf(uint256 amount, address burner) external;

    // ========================= Treasury Only Functions ===========================

    /// @notice Adds a minter in the contract
    /// @param minter Minter address to add
    /// @dev Zero address checks are performed directly in the `Treasury` contract
    function addMinter(address minter) external;

    /// @notice Removes a minter from the contract
    /// @param minter Minter address to remove
    /// @dev This function can also be called by a minter wishing to revoke itself
    function removeMinter(address minter) external;

    /// @notice Sets a new treasury contract
    /// @param _treasury New treasury address
    function setTreasury(address _treasury) external;

    // ========================= External functions ================================

    /// @notice Checks whether an address has the right to mint agTokens
    /// @param minter Address for which the minting right should be checked
    /// @return Whether the address has the right to mint agTokens or not
    function isMinter(address minter) external view returns (bool);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IAMO
/// @author Angle Core Team
/// @notice Interface for the `AMO` contracts
/// @dev This interface only contains functions of the `AMO` contracts which need to be accessible to other
/// contracts of the protocol
interface IAMO {
    // ================================ Views ======================================

    /// @notice Helper function to access the current net balance for a particular token
    /// @param token Address of the token to look for
    /// @return Actualised value owned by the contract
    function balance(IERC20 token) external view returns (uint256);

    /// @notice Helper function to access the current debt owed to the AMOMinter
    /// @param token Address of the token to look for
    function debt(IERC20 token) external view returns (uint256);

    /// @notice Gets the current value in `token` of the assets managed by the AMO corresponding to `token`,
    /// excluding the loose balance of `token`
    /// @dev In the case of a lending AMO, the liabilities correspond to the amount borrowed by the AMO
    /// @dev `token` is used in the case where one contract handles mutiple AMOs
    function getNavOfInvestedAssets(IERC20 token) external view returns (uint256);

    // ========================== Restricted Functions =============================

    /// @notice Pulls the gains made by the protocol on its strategies
    /// @param token Address of the token to getch gain for
    /// @param to Address to which tokens should be sent
    /// @param data List of bytes giving additional information when withdrawing
    /// @dev This function cannot transfer more than the gains made by the protocol
    function pushSurplus(
        IERC20 token,
        address to,
        bytes[] memory data
    ) external;

    /// @notice Claims earned rewards by the protocol
    /// @dev In some protocols like Aave, the AMO may be earning rewards, it thus needs a function
    /// to claim it
    function claimRewards(IERC20[] memory tokens) external;

    /// @notice Swaps earned tokens through `1Inch`
    /// @param minAmountOut Minimum amount of `want` to receive for the swap to happen
    /// @param payload Bytes needed for 1Inch API
    /// @dev This function can for instance be used to sell the stkAAVE rewards accumulated by an AMO
    function sellRewards(uint256 minAmountOut, bytes memory payload) external;

    /// @notice Changes allowance for a contract
    /// @param tokens Addresses of the tokens for which approvals should be madee
    /// @param spenders Addresses to approve
    /// @param amounts Approval amounts for each address
    function changeAllowance(
        IERC20[] calldata tokens,
        address[] calldata spenders,
        uint256[] calldata amounts
    ) external;

    /// @notice Recovers any ERC20 token
    /// @dev Can be used for instance to withdraw stkAave or Aave tokens made by the protocol
    function recoverERC20(
        address tokenAddress,
        address to,
        uint256 amountToRecover
    ) external;

    // ========================== Only AMOMinter Functions =========================

    /// @notice Withdraws invested funds to make it available to the `AMOMinter`
    /// @param tokens Addresses of the token to be withdrawn
    /// @param amounts Amounts of `token` wanted to be withdrawn
    /// @param data List of bytes giving additional information when withdrawing
    /// @return amountsAvailable Idle amounts in each token at the end of the call
    /// @dev Caller should make sure that for each token the associated amount can be withdrawn
    /// otherwise the call will revert
    function pull(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes[] memory data
    ) external returns (uint256[] memory);

    /// @notice Notify that stablecoins has been minted to the contract
    /// @param tokens Addresses of the token transferred
    /// @param amounts Amounts of the tokens transferred
    /// @param data List of bytes giving additional information when depositing
    function push(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes[] memory data
    ) external;

    /// @notice Changes the reference to the `AMOMinter`
    /// @param amoMinter_ Address of the new `AMOMinter`
    /// @dev All checks are performed in the parent contract
    function setAMOMinter(address amoMinter_) external;

    /// @notice Lets the AMO contract acknowledge support for a new token
    /// @param token Token to add support for
    function setToken(IERC20 token) external;

    /// @notice Removes support for a token
    /// @param token Token to remove support for
    function removeToken(IERC20 token) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAMO.sol";

/// @title IAMO
/// @author Angle Core Team
/// @notice Interface for the `AMOMinter` contracts
/// @dev This interface only contains functions of the `AMOMinter` contract which need to be accessible
/// by other contracts of the protocol
interface IAMOMinter {
    /// @notice View function returning true if `admin` is the governor
    function isGovernor(address admin) external view returns (bool);

    /// @notice Checks whether an address is approved for `msg.sender` where `msg.sender`
    /// is expected to be an AMO
    function isApproved(address admin) external view returns (bool);

    /// @notice View function returning current token debt for the msg.sender
    /// @dev Only AMOs are expected to call this function
    function callerDebt(IERC20 token) external view returns (uint256);

    /// @notice View function returning current token debt for an amo
    function amoDebts(IAMO amo, IERC20 token) external view returns (uint256);

    /// @notice Sends tokens to be processed by an AMO
    /// @param amo Address of the AMO to transfer funds to
    /// @param tokens Addresses of tokens we want to mint/transfer to the AMO
    /// @param isStablecoin Boolean array giving the info whether we should mint or transfer the tokens
    /// @param amounts Amounts of tokens to be minted/transferred to the AMO
    /// @param data List of bytes giving additional information when depositing
    /// @dev Only an approved address for the `amo` can call this function
    /// @dev This function will mint if it is called for an agToken
    function sendToAMO(
        IAMO amo,
        IERC20[] memory tokens,
        bool[] memory isStablecoin,
        uint256[] memory amounts,
        bytes[] memory data
    ) external;

    /// @notice Pulls tokens from an AMO
    /// @param amo Address of the amo to receive funds from
    /// @param tokens Addresses of each tokens we want to burn/transfer from the AMO
    /// @param isStablecoin Boolean array giving the info on whether we should burn or transfer the tokens
    /// @param amounts Amounts of each tokens we want to burn/transfer from the amo
    /// @param data List of bytes giving additional information when withdrawing
    function receiveFromAMO(
        IAMO amo,
        IERC20[] memory tokens,
        bool[] memory isStablecoin,
        uint256[] memory amounts,
        address[] memory to,
        bytes[] memory data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

/// @title ICoreBorrow
/// @author Angle Core Team
/// @notice Interface for the `CoreBorrow` contract
/// @dev This interface only contains functions of the `CoreBorrow` contract which are called by other contracts
/// of this module
interface ICoreBorrow {
    /// @notice Checks whether an address is governor of the Angle Protocol or not
    /// @param admin Address to check
    /// @return Whether the address has the `GOVERNOR_ROLE` or not
    function isGovernor(address admin) external view returns (bool);

    /// @notice Checks whether an address is governor or a guardian of the Angle Protocol or not
    /// @param admin Address to check
    /// @return Whether the address has the `GUARDIAN_ROLE` or not
    /// @dev Governance should make sure when adding a governor to also give this governor the guardian
    /// role by calling the `addGovernor` function
    function isGovernorOrGuardian(address admin) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
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
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}