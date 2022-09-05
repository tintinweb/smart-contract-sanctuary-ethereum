// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IFundAccount, Nav, LpDetail, LpAction, FundCreateParams} from "../interfaces/fund/IFundAccount.sol";
import {IFundManager} from "../interfaces/fund/IFundManager.sol";
import {IFundFilter} from "../interfaces/fund/IFundFilter.sol";
import {Errors} from "../libraries/Errors.sol";
import {IWETH9} from "../interfaces/external/IWETH9.sol";

contract FundAccount is IFundAccount, Initializable {
    using SafeERC20 for IERC20;
    using Address for address;

    // Contract version
    uint256 public constant version = 1;

    // FundManager
    address public manager;
    address public weth9;
    IFundFilter public fundFilter;

    // Block time when the account was opened
    uint256 public override since;

    // Block time when the account was closed
    uint256 public override closed;

    // Fund create params
    string public override name;
    address public override gp;
    uint256 public override managementFee;
    uint256 public override carriedInterest;
    address public override underlyingToken;
    address public initiator;
    uint256 public initiatorAmount;
    address public recipient;
    uint256 public recipientMinAmount;
    address[] private _allowedProtocols;
    address[] private _allowedTokens;
    mapping(address => bool) public override isProtocolAllowed;
    mapping(address => bool) public override isTokenAllowed;

    // Fund runtime data
    uint256 public override totalUnit;
    uint256 public override totalCarryInterestAmount;
    uint256 public override lastUpdateManagementFeeAmount;
    uint256 private lastUpdateManagementFeeTime;
    address[] private _lps;
    mapping(address => LpDetail) private _lpDetails;

    receive() external payable {}

    //////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////// VIEW FUNCTIONS ///////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////

    function ethBalance() external view override returns (uint256) {
        return address(this).balance;
    }

    function totalManagementFeeAmount() external view override returns (uint256) {
        return lastUpdateManagementFeeAmount + _calcManagementFeeFromLastUpdate(_calcTotalValue());
    }

    function allowedProtocols() external view override returns (address[] memory) {
        return _allowedProtocols;
    }

    function allowedTokens() external view override returns (address[] memory) {
        return _allowedTokens;
    }

    function lpList() external view override returns (address[] memory) {
        return _lps;
    }

    function lpDetailInfo(address addr) external view override returns (LpDetail memory) {
        return _lpDetails[addr];
    }

    //////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////// FUND MANAGER ONLY //////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////

    // Caller restricted for manager only
    modifier onlyManager() {
        require(msg.sender == manager, Errors.NotManager);
        _;
    }

    function initialize(FundCreateParams memory params) external override initializer {
        manager = msg.sender;
        weth9 = IFundManager(manager).weth9();
        fundFilter = IFundManager(manager).fundFilter();
        since = block.timestamp;

        name = params.name;
        gp = params.gp;
        managementFee = params.managementFee;
        carriedInterest = params.carriedInterest;
        underlyingToken = params.underlyingToken;
        initiator = params.initiator;
        initiatorAmount = params.initiatorAmount;
        recipient = params.recipient;
        recipientMinAmount = params.recipientMinAmount;
        _allowedProtocols = params.allowedProtocols;
        _allowedTokens = params.allowedTokens;

        for (uint256 i = 0; i < _allowedProtocols.length; i++) {
            isProtocolAllowed[_allowedProtocols[i]] = true;
        }
        for (uint256 i = 0; i < _allowedTokens.length; i++) {
            isTokenAllowed[_allowedTokens[i]] = true;
        }
    }

    /// @dev Approve token for 3rd party contract
    /// @param token ERC20 token for allowance
    /// @param spender 3rd party contract address
    /// @param amount Allowance amount
    function approveToken(
        address token,
        address spender,
        uint256 amount
    ) external override onlyManager {
        IERC20(token).safeApprove(spender, 0);
        IERC20(token).safeApprove(spender, amount);
    }

    /// @dev Transfers tokens from account to provided address
    /// @param token ERC20 token address which should be transferred from this account
    /// @param to Address of recipient
    /// @param amount Amount to be transferred
    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) external override onlyManager {
        IERC20(token).safeTransfer(to, amount);
    }

    /// @dev setApprovalForAll of token in the account
    /// @param token ERC721 token address
    /// @param spender Approval to address
    /// @param approved approve all or not
    function setTokenApprovalForAll(
        address token,
        address spender,
        bool approved
    ) external override onlyManager {
        IERC721(token).setApprovalForAll(spender, approved);
    }

    /// @dev Executes financial order on 3rd party service
    /// @param target Contract address which should be called
    /// @param data Call data which should be sent
    function execute(
        address target,
        bytes memory data,
        uint256 value
    ) external override onlyManager returns (bytes memory) {
        return target.functionCallWithValue(data, value);
    }

    function updateName(string memory newName) external onlyManager {
        name = newName;
    }

    function buy(address lp, uint256 amount) external onlyManager {
        Nav memory nav = _updateManagementFeeAndCalcNav();
        _buy(lp, amount, nav);
    }

    function sell(address lp, uint256 ratio) external onlyManager {
        Nav memory nav = _updateManagementFeeAndCalcNav();
        (uint256 dao, uint256 carry) = _sell(lp, ratio, nav);
        _transfer(fundFilter.daoAddress(), dao);
        _transfer(gp, carry);
    }

    function close() external onlyManager {
        closed = block.timestamp;
        Nav memory nav = _updateManagementFeeAndCalcNav();
        uint256 daoSum;
        for (uint256 i = 0; i < _lps.length; i++) {
            (uint256 dao, ) = _sell(_lps[i], 10000, nav);
            daoSum += dao;
        }
        _transfer(fundFilter.daoAddress(), daoSum);
        _collect(true);
    }

    function collect() external onlyManager {
        _updateManagementFeeAmount(_calcTotalValue());
        _collect(false);
    }

    function wrapWETH9() external onlyManager {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            IWETH9(weth9).deposit{value: balance}();
        }
    }

    function unwrapWETH9() external onlyManager {
        uint256 balance = IWETH9(weth9).balanceOf(address(this));
        if (balance > 0) {
            IWETH9(weth9).withdraw(balance);
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////////////
    ///////////////////////////////////// PRIVATE FUNCTIONS //////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////

    function _calcTotalValue() private view returns (uint256) {
        if (closed > 0) {
            return _underlyingBalance();
        } else {
            return IFundManager(manager).calcTotalValue(address(this));
        }
    }

    function _calcManagementFeeFromLastUpdate(uint256 _totalValue) private view returns (uint256) {
        return (_totalValue * managementFee * (block.timestamp - lastUpdateManagementFeeTime)) / (1e4 * 365 * 86400);
    }

    function _updateManagementFeeAmount(uint256 _totalValue) private returns (uint256 recent) {
        recent = _calcManagementFeeFromLastUpdate(_totalValue);
        lastUpdateManagementFeeAmount += recent;
        lastUpdateManagementFeeTime = block.timestamp;
    }

    function _updateManagementFeeAndCalcNav() private returns (Nav memory nav) {
        uint256 totalValue = _calcTotalValue();
        uint256 recentFee = _updateManagementFeeAmount(totalValue);
        nav = Nav(totalValue - recentFee, totalUnit);
    }

    function _buy(
        address lp,
        uint256 amount,
        Nav memory nav
    ) private {
        // Calc unit from amount & nav
        uint256 unit;
        if (totalUnit == 0) {
            // account first buy (nav = 1)
            unit = amount;
        } else {
            unit = (amount * nav.totalUnit) / nav.totalValue;
        }

        // Update lpDetail
        LpDetail storage lpDetail = _lpDetails[lp];
        if (lpDetail.totalUnit == 0) {
            // lp first buy
            if (lp != initiator) {
                require(amount >= recipientMinAmount, Errors.NotEnoughBuyAmount);
            }
            _lps.push(lp);
        }
        lpDetail.lpActions.push(LpAction(1, amount, unit, block.timestamp, 0, 0, 0, 0));
        lpDetail.totalUnit += unit;
        lpDetail.totalAmount += amount;

        // Update account
        totalUnit += unit;
    }

    function _sell(
        address lp,
        uint256 ratio,
        Nav memory nav
    ) private returns (uint256 dao, uint256 carry) {
        // Calc unit from ratio & lp's holding units
        LpDetail storage lpDetail = _lpDetails[lp];
        uint256 unit = (lpDetail.totalUnit * ratio) / 1e4;

        // Calc amount from unit & nav
        uint256 amount = (nav.totalValue * unit) / nav.totalUnit;

        // Calc principal from unit & lp's holding nav
        uint256 base = (lpDetail.totalAmount * unit) / lpDetail.totalUnit;

        // Calc gain/loss detail from amount & base
        uint256 gain;
        uint256 loss;
        if (amount >= base) {
            gain = amount - base;
            dao = (gain * fundFilter.daoProfit()) / 1e4;
            carry = ((gain - dao) * carriedInterest) / 1e4;
        } else {
            loss = base - amount;
        }

        // Update lpDetail
        lpDetail.lpActions.push(LpAction(2, amount, unit, block.timestamp, gain, loss, carry, dao));
        lpDetail.totalUnit -= unit;
        lpDetail.totalAmount -= base;

        // Update account
        totalUnit -= unit;
        totalCarryInterestAmount += carry;

        // Transfer
        if (lp != gp) {
            _transfer(lp, amount - dao - carry);
        } else {
            // merge transfers for gp
            carry = amount - dao;
        }
    }

    function _collect(bool allBalance) private {
        uint256 collectAmount;
        if (allBalance) {
            collectAmount = _underlyingBalance();
        } else {
            collectAmount = lastUpdateManagementFeeAmount;
        }
        lastUpdateManagementFeeAmount = 0;
        _transfer(gp, collectAmount);
    }

    function _underlyingBalance() private view returns (uint256) {
        if (underlyingToken == weth9) {
            return address(this).balance;
        } else {
            return IERC20(underlyingToken).balanceOf(address(this));
        }
    }

    function _transfer(address to, uint256 value) private {
        if (value > 0) {
            if (underlyingToken == weth9) {
                if (to.code.length > 0) {
                    // Smart contract may refuse to receive ETH
                    // This will block execution of closing account
                    // So send WETH to smart contract instead
                    IWETH9(weth9).deposit{value: value}();
                    IERC20(weth9).safeTransfer(to, value);
                } else {
                    payable(to).transfer(value);
                }
            } else {
                IERC20(underlyingToken).safeTransfer(to, value);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

struct Nav {
    // Net Asset Value, can't store as float
    uint256 totalValue;
    uint256 totalUnit;
}

struct LpAction {
    uint256 actionType; // 1. buy, 2. sell
    uint256 amount;
    uint256 unit;
    uint256 time;
    uint256 gain;
    uint256 loss;
    uint256 carry;
    uint256 dao;
}

struct LpDetail {
    uint256 totalAmount;
    uint256 totalUnit;
    LpAction[] lpActions;
}

struct FundCreateParams {
    string name;
    address gp;
    uint256 managementFee;
    uint256 carriedInterest;
    address underlyingToken;
    address initiator;
    uint256 initiatorAmount;
    address recipient;
    uint256 recipientMinAmount;
    address[] allowedProtocols;
    address[] allowedTokens;
}

interface IFundAccount {

    function since() external view returns (uint256);

    function closed() external view returns (uint256);

    function name() external view returns (string memory);

    function gp() external view returns (address);

    function managementFee() external view returns (uint256);

    function carriedInterest() external view returns (uint256);

    function underlyingToken() external view returns (address);

    function ethBalance() external view returns (uint256);

    function initiator() external view returns (address);

    function initiatorAmount() external view returns (uint256);

    function recipient() external view returns (address);

    function recipientMinAmount() external view returns (uint256);

    function lpList() external view returns (address[] memory);

    function lpDetailInfo(address addr) external view returns (LpDetail memory);

    function allowedProtocols() external view returns (address[] memory);

    function allowedTokens() external view returns (address[] memory);

    function isProtocolAllowed(address protocol) external view returns (bool);

    function isTokenAllowed(address token) external view returns (bool);

    function totalUnit() external view returns (uint256);

    function totalManagementFeeAmount() external view returns (uint256);

    function lastUpdateManagementFeeAmount() external view returns (uint256);

    function totalCarryInterestAmount() external view returns (uint256);

    function initialize(FundCreateParams memory params) external;

    function approveToken(
        address token,
        address spender,
        uint256 amount
    ) external;

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function setTokenApprovalForAll(
        address token,
        address spender,
        bool approved
    ) external;

    function execute(address target, bytes memory data, uint256 value) external returns (bytes memory);

    function buy(address lp, uint256 amount) external;

    function sell(address lp, uint256 ratio) external;

    function collect() external;

    function close() external;

    function updateName(string memory newName) external;

    function wrapWETH9() external;

    function unwrapWETH9() external;

}

// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

import {IFundFilter} from "./IFundFilter.sol";
import {IPaymentGateway} from "./IPaymentGateway.sol";

interface IFundManager is IPaymentGateway {
    struct AccountCloseParams {
        address account;
        bytes[] paths;
    }

    function owner() external view returns (address);
    function fundFilter() external view returns (IFundFilter);

    function getAccountsCount(address) external view returns (uint256);
    function getAccounts(address) external view returns (address[] memory);

    function buyFund(address, uint256) external payable;
    function sellFund(address, uint256) external;
    function unwrapWETH9(address) external;

    function calcTotalValue(address account) external view returns (uint256 total);

    function lpTokensOfAccount(address account) external view returns (uint256[] memory);

    function provideAccountAllowance(
        address account,
        address token,
        address protocol,
        uint256 amount
    ) external;

    function executeOrder(
        address account,
        address protocol,
        bytes calldata data,
        uint256 value
    ) external returns (bytes memory);

    function onMint(
        address account,
        uint256 tokenId
    ) external;

    function onCollect(
        address account,
        uint256 tokenId
    ) external;

    function onIncrease(
        address account,
        uint256 tokenId
    ) external;

    // @dev Emit an event when new account is created
    // @param account The fund account address
    // @param initiator The initiator address
    // @param recipient The recipient address
    event AccountCreated(address indexed account, address indexed initiator, address indexed recipient);
}

// SPDX-License-Identifier: MIT
// Decontracts Protocol. @2022
pragma solidity >=0.8.14;

struct FundFilterInitializeParams {
    address priceOracle;
    address swapRouter;
    address positionManager;
    address positionViewer;
    address protocolAdapter;
    address[] allowedUnderlyingTokens;
    address[] allowedTokens;
    address[] allowedProtocols;
    uint256 minManagementFee;
    uint256 maxManagementFee;
    uint256 minCarriedInterest;
    uint256 maxCarriedInterest;
    address daoAddress;
    uint256 daoProfit;
}

interface IFundFilter {

    event AllowedUnderlyingTokenUpdated(address indexed token, bool allowed);

    event AllowedTokenUpdated(address indexed token, bool allowed);

    event AllowedProtocolUpdated(address indexed protocol, bool allowed);

    function priceOracle() external view returns (address);

    function swapRouter() external view returns (address);

    function positionManager() external view returns (address);

    function positionViewer() external view returns (address);

    function protocolAdapter() external view returns (address);

    function allowedUnderlyingTokens() external view returns (address[] memory);

    function isUnderlyingTokenAllowed(address token) external view returns (bool);

    function allowedTokens() external view returns (address[] memory);

    function isTokenAllowed(address token) external view returns (bool);

    function allowedProtocols() external view returns (address[] memory);

    function isProtocolAllowed(address protocol) external view returns (bool);

    function minManagementFee() external view returns (uint256);

    function maxManagementFee() external view returns (uint256);

    function minCarriedInterest() external view returns (uint256);

    function maxCarriedInterest() external view returns (uint256);

    function daoAddress() external view returns (address);

    function daoProfit() external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

library Errors {
    // Create/Close Account
    string public constant InvalidInitiator = "CA0";
    string public constant InvalidRecipient = "CA1";
    string public constant InvalidGP = "CA2";
    string public constant InvalidNameLength = "CA3";
    string public constant InvalidManagementFee = "CA4";
    string public constant InvalidCarriedInterest = "CA5";
    string public constant InvalidUnderlyingToken = "CA6";
    string public constant InvalidAllowedProtocols = "CA7";
    string public constant InvalidAllowedTokens = "CA8";
    string public constant InvalidRecipientMinAmount = "CA9";

    // Others
    string public constant NotManager = "FM0";
    string public constant NotGP = "FM1";
    string public constant NotLP = "FM2";
    string public constant NotGPOrLP = "FM3";
    string public constant NotEnoughBuyAmount = "FM4";
    string public constant InvalidSellUnit = "FM5";
    string public constant NotEnoughBalance = "FM6";
    string public constant MissingAmount = "FM7";
    string public constant InvalidFundCreateParams = "FM8";
    string public constant InvalidName = "FM9";
    string public constant NotAccountOwner = "FM10";
    string public constant ContractCannotBeZeroAddress = "FM11";
    string public constant ExceedMaximumPositions = "FM12";
    string public constant NotAllowedToken = "FM13";
    string public constant NotAllowedProtocol = "FM14";
    string public constant FunctionCallIsNotAllowed = "FM15";
    string public constant PathNotAllowed = "FM16";
    string public constant ProtocolCannotBeZeroAddress = "FM17";
    string public constant CallerIsNotManagerOwner = "FM18";
    string public constant InvalidInitializeParams = "FM19";
    string public constant InvalidUpdateParams = "FM20";
    string public constant InvalidZeroAddress = "FM21";
    string public constant NotAllowedAdapter = "FM22";
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

interface IPaymentGateway {
    function weth9() external view returns (address);
}