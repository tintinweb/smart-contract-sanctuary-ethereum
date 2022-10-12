//SPDX-License-Identifier: NONE

pragma solidity ^0.8.17;

import './interface/ITokenOffRampStorage.sol';
import './library/TokenOffRampTypes.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

/// @title Kiara Exchange Storage Contract
/// @author GMI STUDIOS PTY LTD
/// @notice Handle ERC20 transactions when performing a Finance Exchange
/// @dev MUST BE DEPLOYED WITH WORKING MULTISIG
/// @dev Requires a backend wallet to interact with centralised database using Web3
contract TokenOffRampStorage is ITokenOffRampStorage, Pausable {
    using SafeERC20 for IERC20;

    address public protocolOwner;
    address public protocolBackend;
    address public vault;
    address public logicContract;
    uint256 public expiryTimePeriod;
    uint256 public createTradeExpiryPeriod;

    address pendingProtocolOwner;

    mapping(bytes32 => TokenOffRampTypes.Trade) public tradeForId;
    mapping(IERC20 => bool) public supportedCryptoCurrencies;
    mapping(bytes8 => bool) public supportedFiatCurrencies;

    /// @dev DEPLOY USING A WORKING MULTISIG
    /// @param _backend Wallet address for Backend operations
    /// @param _vault Exchange vault address for withdrawing funds to
    /// @param _expiryTimePeriod Time in seconds before trades expire
    /// @param _createTradeExpiryPeriod Time in seconds before trade creation period expires
    constructor(
        address _backend,
        address _vault,
        uint256 _expiryTimePeriod,
        uint256 _createTradeExpiryPeriod
    ) Pausable() {
        protocolOwner = msg.sender;
        protocolBackend = _backend;
        vault = _vault;
        expiryTimePeriod = _expiryTimePeriod;
        createTradeExpiryPeriod = _createTradeExpiryPeriod;
    }

    modifier onlyProtocolOwner() {
        require(msg.sender == protocolOwner, 'Only Owner wallet can access');
        _;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == protocolBackend || msg.sender == protocolOwner,
            'Only Owner wallet or Backend can access'
        );
        _;
    }

    modifier onlyLogicContract() {
        require(logicContract != address(0), 'Logic contract not set');
        require(msg.sender == logicContract, 'Only Logic Contract can access');
        _;
    }

    modifier isSupportedCryptocurrency(IERC20 token) {
        require(supportedCryptoCurrencies[token], 'Cryptocurrency is not supported');
        _;
    }

    modifier isSupportedFiatCurrency(bytes8 currencyCode) {
        require(supportedFiatCurrencies[currencyCode], 'Fiat Currency is not supported');
        _;
    }

    modifier isValidAddress(address current, address target) {
        require(current != target, 'Address already current');
        require(target != address(0), 'Address cannot be null');
        require(target != msg.sender && target != tx.origin, 'Address cannot be self');
        _;
    }

    modifier isValidNumber(
        uint256 current,
        uint256 target,
        uint256 min
    ) {
        require(current != target, 'Number already current');
        require(target >= min, 'Number cannot be less than min');
        _;
    }

    modifier isRequiredStatus(bytes32 id, TokenOffRampTypes.TradeStatus status) {
        require(tradeForId[id].status == status, 'Trade status does not match requirement');
        _;
    }

    /// @notice Deposit ERC20 Token into Storage
    /// @dev Only valid contract can call, only valid tokens
    /// @param from Wallet to transfer from
    /// @param token ERC20 Token to use
    /// @param amount Amount of ERC20 to transfer
    function deposit(
        address from,
        IERC20 token,
        uint256 amount
    )
        external
        override
        whenNotPaused
        onlyLogicContract
        isSupportedCryptocurrency(token)
        returns (bool)
    {
        token.safeTransferFrom(from, address(this), amount);
        return true;
    }

    /// @notice Withdraw ERC20 Token from Storage
    /// @dev Only valid contract can call, only valid tokens
    /// @param id Trade to reference
    function withdraw(bytes32 id)
        external
        override
        whenNotPaused
        isRequiredStatus(id, TokenOffRampTypes.TradeStatus.TRANSFER_CONFIRMED)
        returns (bool)
    {
        TokenOffRampTypes.Trade storage trade = tradeForId[id];
        require(
            msg.sender == trade.from || msg.sender == logicContract,
            'Only customer or logic contract can access'
        );
        trade.status = TokenOffRampTypes.TradeStatus.REFUNDED;
        trade.fromTokenAddress.safeTransfer(trade.from, trade.fromAmount);
        return true;
    }

    /// @notice Withdraw funds to vault on trade completion
    /// @dev Only valid admin wallet can call
    /// @param id Trade to withdraw funds from.
    function withdrawToVault(bytes32 id)
        external
        override
        whenNotPaused
        onlyAdmin
        isRequiredStatus(id, TokenOffRampTypes.TradeStatus.COMPLETED)
    {
        TokenOffRampTypes.Trade storage trade = tradeForId[id];
        trade.status = TokenOffRampTypes.TradeStatus.WITHDRAWN;
        trade.fromTokenAddress.safeTransfer(vault, trade.fromAmount);
        emit WithdrawToken(msg.sender, trade.fromTokenAddress, trade.fromAmount);
    }

    /// @notice Withdraw funds to vault, used for emergency purposes only
    /// @dev ensure vault is correctly set
    /// @param token Token to withdraw
    /// @param amount Amount to withdraw
    function emergencyWithdraw(IERC20 token, uint256 amount)
        external
        override
        whenPaused
        onlyProtocolOwner
    {
        token.safeTransfer(vault, amount);
        emit WithdrawToken(msg.sender, token, amount);
    }

    // Backend Functions

    /// @notice Update trade in Trade Map
    /// @dev only valid contract can call
    /// @param id Trade ID to reference
    /// @param status Trade Status
    /// @param from Wallet that submitted trade
    /// @param fromTokenAddress ERC20 Token
    /// @param toCurrency Fiat Currency to convert to
    /// @param fromAmount ERC20 Tokens to be spent
    /// @param expiryTimestamp When the trade transaction was submitted
    function setTradeForID(
        bytes32 id,
        TokenOffRampTypes.TradeStatus status,
        address from,
        IERC20 fromTokenAddress,
        bytes8 toCurrency,
        uint256 fromAmount,
        uint256 expiryTimestamp
    ) external whenNotPaused onlyLogicContract {
        tradeForId[id] = TokenOffRampTypes.Trade(
            status,
            from,
            fromTokenAddress,
            toCurrency,
            fromAmount,
            expiryTimestamp
        );
    }

    function updateTradeStatusForID(bytes32 id, TokenOffRampTypes.TradeStatus status)
        external
        whenNotPaused
        onlyLogicContract
    {
        tradeForId[id].status = status;
    }

    /// @notice Add new cryptocurrency to support
    /// @dev Make sure it's also in the database
    /// @param tokenAddress ERC20 Token to support
    function addSupportedCryptocurrency(IERC20 tokenAddress)
        external
        override
        whenNotPaused
        onlyAdmin
    {
        require(!supportedCryptoCurrencies[tokenAddress], 'Currency already added');
        emit AddSupportedCryptocurrency(msg.sender, tokenAddress);
        supportedCryptoCurrencies[tokenAddress] = true;
    }

    /// @notice Remove a supported cryptocurrency
    /// @dev Make sure it's also removed in database
    /// @param tokenAddress ERC20 Token to remove
    function removeSupportedCryptocurrency(IERC20 tokenAddress)
        external
        override
        whenNotPaused
        onlyAdmin
    {
        require(supportedCryptoCurrencies[tokenAddress], 'Currency not supported already');
        emit RemoveSupportedCryptocurrency(msg.sender, tokenAddress);
        supportedCryptoCurrencies[tokenAddress] = false;
    }

    /// @notice Add a new supported Fiat Currency
    /// @dev Make sure it's also added in database
    /// @param currencyCode ISO 4217 Currency Code to add
    function addSupportedFiatCurrency(bytes8 currencyCode)
        external
        override
        whenNotPaused
        onlyAdmin
    {
        require(!supportedFiatCurrencies[currencyCode], 'Currency already added');
        emit AddSupportedFiatCurrency(msg.sender, currencyCode);
        supportedFiatCurrencies[currencyCode] = true;
    }

    /// @notice Remove a supported Fiat Currency
    /// @dev Make sure it's also removed from database
    /// @param currencyCode ISO 4217 Currency Code to remove
    function removeSupportedFiatCurrency(bytes8 currencyCode)
        external
        override
        whenNotPaused
        onlyAdmin
    {
        require(supportedFiatCurrencies[currencyCode], 'Currency not supported already');
        emit RemoveSupportedFiatCurrency(msg.sender, currencyCode);
        supportedFiatCurrencies[currencyCode] = false;
    }

    /// @notice Set a new vault address
    /// @param _vault Address of new vault
    function setVault(address _vault)
        external
        override
        whenPaused
        onlyProtocolOwner
        isValidAddress(vault, _vault)
    {
        emit UpdatedVault(msg.sender, vault, _vault);
        vault = _vault;
    }

    /// @notice Set a new backend address
    /// @param _backend Address of new backend wallet
    function setBackend(address _backend)
        external
        override
        whenPaused
        onlyProtocolOwner
        isValidAddress(protocolBackend, _backend)
    {
        emit UpdatedBackend(msg.sender, protocolBackend, _backend);
        protocolBackend = _backend;
    }

    /// @notice Set a new protocol owner wallet
    /// @param _owner Address of new protocol owner wallet
    function setPendingProtocolOwner(address _owner)
        external
        override
        whenPaused
        onlyProtocolOwner
        isValidAddress(protocolOwner, _owner)
    {
        pendingProtocolOwner = _owner;
    }

    /// @notice Claim pending ownership
    function claimProtocolOwner() external override whenPaused {
        require(msg.sender == pendingProtocolOwner, 'Only pending wallet can approve');
        emit UpdatedProtocolOwner(msg.sender, protocolOwner, pendingProtocolOwner);
        protocolOwner = pendingProtocolOwner;
        pendingProtocolOwner = address(0);
    }

    /// @notice Set a new logic contract
    /// @param _contract Address of new logic contract
    function setLogicContract(address _contract)
        external
        override
        whenPaused
        onlyProtocolOwner
        isValidAddress(logicContract, _contract)
    {
        emit UpdatedLogicContract(msg.sender, logicContract, _contract);
        logicContract = _contract;
    }

    /// @notice Set a new Expiry Time period for trades
    /// @param _time time period in seconds
    function setExpiryTimePeriod(uint256 _time)
        external
        override
        whenPaused
        onlyProtocolOwner
        isValidNumber(expiryTimePeriod, _time, 300)
    {
        emit UpdatedExpiryPeriod(msg.sender, expiryTimePeriod, _time);
        expiryTimePeriod = _time;
    }

    /// @notice Set a new time period before the created trade expires if left in tx pool for too long
    /// @param _time time period in seconds
    function setCreateTradeTimePeriod(uint256 _time)
        external
        override
        whenPaused
        onlyProtocolOwner
        isValidNumber(createTradeExpiryPeriod, _time, 60)
    {
        emit UpdatedCreateTradeExpiryPeriod(msg.sender, createTradeExpiryPeriod, _time);
        createTradeExpiryPeriod = _time;
    }

    // Misc

    fallback() external {
        revert();
    }

    receive() external payable {
        revert();
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyProtocolOwner {
        _unpause();
    }
}

//SPDX-License-Identifier: NONE

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../library/TokenOffRampTypes.sol';

interface ITokenOffRampStorage {
    event AddSupportedCryptocurrency(address indexed operator, IERC20 indexed tokenAddress);
    event RemoveSupportedCryptocurrency(address indexed operator, IERC20 indexed tokenAddress);
    event AddSupportedFiatCurrency(address indexed operator, bytes8 indexed currencyCode);
    event RemoveSupportedFiatCurrency(address indexed operator, bytes8 indexed currencyCode);

    event WithdrawToken(address indexed operator, IERC20 indexed token, uint256 amount);

    event UpdatedBackend(
        address indexed operator,
        address indexed previous,
        address indexed current
    );
    event UpdatedVault(address indexed operator, address indexed previous, address indexed current);
    event UpdatedProtocolOwner(
        address indexed operator,
        address indexed previous,
        address indexed current
    );
    event UpdatedLogicContract(
        address indexed operator,
        address indexed previous,
        address indexed current
    );
    event UpdatedExpiryPeriod(address indexed operator, uint256 previous, uint256 current);
    event UpdatedCreateTradeExpiryPeriod(
        address indexed operator,
        uint256 previous,
        uint256 current
    );

    // Operator/Owner Functions
    function addSupportedCryptocurrency(IERC20 tokenAddress) external;

    function removeSupportedCryptocurrency(IERC20 tokenAddress) external;

    function addSupportedFiatCurrency(bytes8 currencyCode) external;

    function removeSupportedFiatCurrency(bytes8 currencyCode) external;

    function setPendingProtocolOwner(address owner) external;

    function claimProtocolOwner() external;

    function setBackend(address backend) external;

    function setVault(address vault) external;

    function setLogicContract(address _contract) external;

    function setExpiryTimePeriod(uint256 time) external;

    function setCreateTradeTimePeriod(uint256 time) external;

    function deposit(
        address to,
        IERC20 token,
        uint256 amount
    ) external returns (bool);

    function withdraw(bytes32 id) external returns (bool);

    function withdrawToVault(bytes32 id) external;

    function emergencyWithdraw(IERC20 token, uint256 amount) external;

    function setTradeForID(
        bytes32 id,
        TokenOffRampTypes.TradeStatus status,
        address from,
        IERC20 fromTokenAddress,
        bytes8 toCurrency,
        uint256 fromAmount,
        uint256 expiryTimestamp
    ) external;

    function updateTradeStatusForID(bytes32 id, TokenOffRampTypes.TradeStatus status) external;
}

//SPDX-License-Identifier: NONE

pragma solidity ^0.8.17;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TokenOffRampTypes {
    enum TradeStatus {
        NOT_CREATED,
        TRANSFER_CONFIRMED,
        REFUNDED,
        COMPLETED,
        WITHDRAWN
    }

    struct Trade {
        TradeStatus status;
        address from;
        IERC20 fromTokenAddress;
        bytes8 toCurrency;
        uint256 fromAmount;
        uint256 expireAt;
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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