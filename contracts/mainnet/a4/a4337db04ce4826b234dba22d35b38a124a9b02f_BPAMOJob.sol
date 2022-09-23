// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../interfaces/external/curve/IMetaPool2.sol";
import "../../interfaces/IAMO.sol";
import "../../interfaces/IAMOMinter.sol";
import "../../interfaces/ICurveBPAMO.sol";

/// @title ConvexBPAMOJob
/// @author Angle Core Team
/// @notice Keeper permisionless contract to rebalance an AMO dealing with Curve pools where an
/// agXXX is paired with another pegged asset
/// @dev This contract can be called to mint on a Curve pool an agXXX when there are less of this agXXX than of the
/// other asset. Similarly, it can be called to withdraw when there are more of the agXXX than of the other asset.
contract BPAMOJob is Initializable {
    /// @notice Decimal normalizer between agTokens and the other token
    uint256 private constant _DECIMAL_NORMALIZER = 10**12;

    /// @notice Reference to the `AmoMinter` contract
    IAMOMinter public amoMinter;
    /// @notice Maps an address to whether it is whitelisted
    mapping(address => uint256) public whitelist;

    // =================================== ERRORS ==================================

    error ZeroAddress();
    error NotGovernor();
    error NotKeeper();

    // =============================== INITIALIZATION ==============================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice Initializes the contract
    /// @param amoMinter_ Address of the AMOMinter
    function initialize(address amoMinter_) external initializer {
        if (amoMinter_ == address(0)) revert ZeroAddress();
        amoMinter = IAMOMinter(amoMinter_);
    }

    // ================================= MODIFIERS =================================

    /// @notice Checks whether the `msg.sender` is governor
    modifier onlyGovernor() {
        if (!amoMinter.isGovernor(msg.sender)) revert NotGovernor();
        _;
    }

    /// @notice Checks whether the `msg.sender` is approved
    modifier onlyKeeper() {
        if (whitelist[msg.sender] == 0) revert NotKeeper();
        _;
    }

    // =================================== SETTER ==================================

    /// @notice Toggles the approval right for an address
    /// @param whitelistCaller Address of the caller that needs right on `adjust`
    function toggleWhitelist(address whitelistCaller) public onlyGovernor {
        if (address(whitelistCaller) == address(0)) revert ZeroAddress();
        whitelist[whitelistCaller] = 1 - whitelist[whitelistCaller];
    }

    // =============================== VIEW FUNCTION ===============================

    /// @notice Returns the current state of the AMO that is to say whether liquidity should be added or removed
    /// and how much should be added or removed
    /// @param amo Address of the AMO to check
    /// @return addLiquidity Whether liquidity should be added or removed through the AMO on the Curve pool
    /// @return delta How much can be added or removed
    function currentState(ICurveBPAMO amo) public view returns (bool addLiquidity, uint256 delta) {
        (address curvePool, address agToken, uint256 indexAgToken) = amo.keeperInfo();
        return _currentState(curvePool, amo, agToken, indexAgToken);
    }

    // ============================== KEEPER FUNCTION ==============================

    /// @notice Adjusts the AMO by automatically minting and depositing, or withdrawing and burning the exact
    /// amount needed to put the Curve pool back at balance
    /// @param amo Address of the AMO to adjust
    /// @return addLiquidity Whether liquidity was added or removed after calling this function
    /// @return delta How much was added or removed from the Curve pool
    function adjust(ICurveBPAMO amo) external onlyKeeper returns (bool addLiquidity, uint256 delta) {
        (address curvePool, address agToken, uint256 indexAgToken) = amo.keeperInfo();
        (addLiquidity, delta) = _currentState(curvePool, amo, agToken, indexAgToken);

        uint256[] memory amounts = new uint256[](1);
        IERC20[] memory tokens = new IERC20[](1);
        bool[] memory isStablecoin = new bool[](1);
        address[] memory to = new address[](1);
        bytes[] memory data = new bytes[](1);
        amounts[0] = delta;
        tokens[0] = IERC20(agToken);
        isStablecoin[0] = true;
        data[0] = addLiquidity ? abi.encode(0) : abi.encode(type(uint256).max);

        if (addLiquidity) amoMinter.sendToAMO(IAMO(address(amo)), tokens, isStablecoin, amounts, data);
        else amoMinter.receiveFromAMO(IAMO(address(amo)), tokens, isStablecoin, amounts, to, data);
    }

    // ================================== INTERNAL =================================

    /// @notice Internal version of the `currentState` function
    function _currentState(
        address curvePool,
        ICurveBPAMO amo,
        address agToken,
        uint256 indexAgToken
    ) public view returns (bool addLiquidity, uint256 delta) {
        uint256[2] memory balances = IMetaPool2(curvePool).get_balances();
        // we need to mint agTokens
        if (balances[indexAgToken] < balances[1 - indexAgToken] * _DECIMAL_NORMALIZER)
            return (true, balances[1 - indexAgToken] * _DECIMAL_NORMALIZER - balances[indexAgToken]);
        else {
            uint256 currentDebt = amoMinter.amoDebts(IAMO(address(amo)), IERC20(address(agToken)));
            delta = balances[indexAgToken] - balances[1 - indexAgToken] * _DECIMAL_NORMALIZER;
            delta = currentDebt > delta ? delta : currentDebt;
            return (false, delta);
        }
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

import "./IMetaPoolBase.sol";

uint256 constant N_COINS = 2;

//solhint-disable
interface IMetaPool2 is IMetaPoolBase {
    function coins() external view returns (uint256[N_COINS] memory);

    function get_balances() external view returns (uint256[N_COINS] memory);

    function get_previous_balances() external view returns (uint256[N_COINS] memory);

    function get_price_cumulative_last() external view returns (uint256[N_COINS] memory);

    function get_twap_balances(
        uint256[N_COINS] memory _first_balances,
        uint256[N_COINS] memory _last_balances,
        uint256 _time_elapsed
    ) external view returns (uint256[N_COINS] memory);

    function calc_token_amount(uint256[N_COINS] memory _amounts, bool _is_deposit) external view returns (uint256);

    function calc_token_amount(
        uint256[N_COINS] memory _amounts,
        bool _is_deposit,
        bool _previous
    ) external view returns (uint256);

    function add_liquidity(uint256[N_COINS] memory _amounts, uint256 _min_mint_amount) external returns (uint256);

    function add_liquidity(
        uint256[N_COINS] memory _amounts,
        uint256 _min_mint_amount,
        address _receiver
    ) external returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx,
        uint256[N_COINS] memory _balances
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256[N_COINS] memory _balances
    ) external view returns (uint256);

    function remove_liquidity(uint256 _burn_amount, uint256[N_COINS] memory _min_amounts)
        external
        returns (uint256[N_COINS] memory);

    function remove_liquidity(
        uint256 _burn_amount,
        uint256[N_COINS] memory _min_amounts,
        address _receiver
    ) external returns (uint256[N_COINS] memory);

    function remove_liquidity_imbalance(uint256[N_COINS] memory _amounts, uint256 _max_burn_amount)
        external
        returns (uint256);

    function remove_liquidity_imbalance(
        uint256[N_COINS] memory _amounts,
        uint256 _max_burn_amount,
        address _receiver
    ) external returns (uint256);
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

//solhint-disable
interface ICurveBPAMO {
    function keeperInfo()
        external
        view
        returns (
            address,
            address,
            uint256
        );
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//solhint-disable
interface IMetaPoolBase is IERC20 {
    function admin_fee() external view returns (uint256);

    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address _receiver
    ) external returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address _receiver
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

    function calc_withdraw_one_coin(
        uint256 _burn_amount,
        int128 i,
        bool _previous
    ) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received,
        address _receiver
    ) external returns (uint256);

    function admin_balances(uint256 i) external view returns (uint256);

    function withdraw_admin_fees() external;
}