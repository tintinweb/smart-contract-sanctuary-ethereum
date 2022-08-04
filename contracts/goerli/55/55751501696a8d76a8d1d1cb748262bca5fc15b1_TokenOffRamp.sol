//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import './interface/ITokenOffRamp.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

//import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

// TODO Add UUIDv4 checker for strings
// TODO Test for reentrancy and other exploits

/// @title Kiara Exchange Contract
/// @author GMI STUDIOS PTY LTD
/// @notice Handle ERC20 transactions when performing a Finance Exchange
/// @dev MUST BE DEPLOYED WITH WORKING MULTISIG
/// @dev Requires a backend wallet to interact with centralised database using Web3
contract TokenOffRamp is ITokenOffRamp, Pausable {
    address private multisig;
    address private backend;
    address private vault;

    enum TradeStatus {
        NOT_CREATED,
        TRANSFER_CONFIRMED,
        REFUNDED,
        COMPLETED
    }

    struct Trade {
        TradeStatus status;
        address from;
        address fromTokenAddress;
        bytes8 toCurrency;
        uint256 fromAmount;
        uint256 expireAt;
    }

    mapping(bytes32 => Trade) public tradeForId;
    mapping(address => bool) public supportedCryptoCurrencies;
    mapping(bytes8 => bool) public supportedFiatCurrencies;

    /// @dev DEPLOY USING A WORKING MULTISIG
    /// @param _backend Wallet address for Backend operations
    /// @param _vault Exchange vault address for withdrawing funds to
    constructor(address _backend, address _vault) Pausable() {
        multisig = msg.sender;
        backend = _backend;
        vault = _vault;
    }

    modifier onlyMultisig() {
        require(msg.sender == multisig, 'Only Multisig wallet can access');
        _;
    }

    modifier onlyBackend() {
        require(msg.sender == backend, 'Only Backend wallet can access');
        _;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == backend || msg.sender == multisig,
            'Only Multisig wallet or Backend can access'
        );
        _;
    }

    modifier onlyCustomerOrAdmin(bytes32 tradeId) {
        require(
            msg.sender == backend ||
                msg.sender == multisig ||
                msg.sender == tradeForId[tradeId].from,
            'Only Admin or User Wallet associated with trade can access'
        );
        _;
    }

    modifier tradeNotExist(bytes32 tradeId) {
        require(tradeForId[tradeId].status == TradeStatus.NOT_CREATED, 'Trade already exists');
        _;
    }

    modifier tradeNotProcessed(bytes32 tradeId) {
        require(
            tradeForId[tradeId].status == TradeStatus.TRANSFER_CONFIRMED,
            "Trade has already been processed or doesn't exist"
        );
        _;
    }

    modifier onlySupportedCryptocurrency(address token) {
        require(supportedCryptoCurrencies[token], 'Cryptocurrency is not supported');
        _;
    }

    modifier onlySupportedFiatCurrency(bytes8 currencyCode) {
        require(supportedFiatCurrencies[currencyCode], 'Fiat Currency is not supported');
        _;
    }

    // User/Backend Functions

    /// @notice Create a new on-chain trade request
    /// @dev If id not in database and is valid, mark as unverified in database and create new customer
    /// @param id UUIDv4 for trade
    /// @param fromTokenAddress ERC20 token to exchange from
    /// @param toCurrency Fiat Currency to exchange to
    /// @param fromAmount Amount of ERC20 token to exchange
    /// @param expireAt UNIX Timestamp for trade expiry
    function createTrade(
        bytes32 id,
        address fromTokenAddress,
        bytes8 toCurrency,
        uint256 fromAmount,
        uint256 expireAt
    )
        public
        override
        whenNotPaused
        tradeNotExist(id)
        onlySupportedCryptocurrency(fromTokenAddress)
        onlySupportedFiatCurrency(toCurrency)
    {
        require(expireAt > block.timestamp, "Trade Expires before it's created");

        IERC20 token = IERC20(fromTokenAddress);
        require(token.transferFrom(msg.sender, address(this), fromAmount));

        Trade memory trade = Trade(
            TradeStatus.TRANSFER_CONFIRMED,
            msg.sender,
            fromTokenAddress,
            toCurrency,
            fromAmount,
            expireAt
        );
        tradeForId[id] = trade;
        emit CreateTrade(id);
    }

    /// @notice Refund a created trade
    /// @dev if it's not completed or refunded already
    /// @param id UUIDv4 for trade
    function refundTrade(bytes32 id)
        public
        override
        whenNotPaused
        onlyCustomerOrAdmin(id)
        tradeNotProcessed(id)
    {
        IERC20 token = IERC20(tradeForId[id].fromTokenAddress);
        Trade memory trade = tradeForId[id];
        require(token.transfer(trade.from, trade.fromAmount));
        trade.status = TradeStatus.REFUNDED;
        tradeForId[id] = trade;
        emit RefundTrade(id);
    }

    /// @notice Mark trade as completed
    /// @dev once verified by backend that it's been processed
    /// @param id UUIDv4 for trade
    function completeTrade(bytes32 id)
        public
        override
        whenNotPaused
        onlyAdmin
        tradeNotProcessed(id)
    {
        require(tradeForId[id].expireAt > block.timestamp, 'Trade has expired');
        tradeForId[id].status = TradeStatus.COMPLETED;
        emit CompleteTrade(id);
    }

    // Backend Functions

    /// @notice Add new cryptocurrency to support
    /// @dev Make sure it's also in the database
    /// @param tokenAddress ERC20 Token to support
    function addSupportedCryptocurrency(address tokenAddress)
        public
        override
        whenNotPaused
        onlyAdmin
    {
        require(supportedCryptoCurrencies[tokenAddress] == false, 'Currency already added');
        supportedCryptoCurrencies[tokenAddress] = true;
        emit AddSupportedCryptocurrency(msg.sender, tokenAddress);
    }

    /// @notice Remove a supported cryptocurrency
    /// @dev Make sure it's also removed in database
    /// @param tokenAddress ERC20 Token to remove
    function removeSupportedCryptocurrency(address tokenAddress)
        public
        override
        whenNotPaused
        onlyAdmin
    {
        require(supportedCryptoCurrencies[tokenAddress] == true, 'Currency not supported already');
        supportedCryptoCurrencies[tokenAddress] = false;
        emit RemoveSupportedCryptocurrency(msg.sender, tokenAddress);
    }

    /// @notice Add a new supported Fiat Currency
    /// @dev Make sure it's also added in database
    /// @param currencyCode ISO 4217 Currency Code to add
    function addSupportedFiatCurrency(bytes8 currencyCode) public override whenNotPaused onlyAdmin {
        require(supportedFiatCurrencies[currencyCode] == false, 'Currency already added');
        supportedFiatCurrencies[currencyCode] = true;
        emit AddSupportedFiatCurrency(msg.sender, currencyCode);
    }

    /// @notice Remove a supported Fiat Currency
    /// @dev Make sure it's also removed from database
    /// @param currencyCode ISO 4217 Currency Code to remove
    function removeSupportedFiatCurrency(bytes8 currencyCode)
        public
        override
        whenNotPaused
        onlyAdmin
    {
        require(supportedFiatCurrencies[currencyCode] == true, 'Currency not supported already');
        supportedFiatCurrencies[currencyCode] = false;
        emit RemoveSupportedFiatCurrency(msg.sender, currencyCode);
    }

    /// @notice Withdraw token to vault
    /// @param _token ERC20 Token to withdraw
    /// @param amount Amount of token to withdraw
    function withdraw(address _token, uint256 amount) public override whenNotPaused onlyAdmin {
        IERC20 token = IERC20(_token);
        require(token.transfer(vault, amount));
        emit WithdrawToken(msg.sender, _token, amount);
    }

    // Emergency Functions

    /// @notice Withdraw all balance of supplied ERC20 Tokens to vault
    /// @param tokens ERC20 Tokens to withdraw
    function emergencyWithdrawAll(address[] memory tokens) public override whenPaused onlyMultisig {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            uint256 balance = token.balanceOf(address(this));
            require(token.transfer(vault, balance));
            emit EmergencyWithdraw(msg.sender, tokens[i], balance);
        }
    }

    /// @notice Withdraw all balance of a ERC20 Token to vault
    /// @param _token ERC20 Token to withdraw
    function emergencyWithdrawToken(address _token) public override whenPaused onlyMultisig {
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(vault, balance));
        emit EmergencyWithdraw(msg.sender, _token, balance);
    }

    /// @notice Set a new vault address
    /// @param _vault Address of new vault
    function setNewVault(address _vault) public override whenPaused onlyMultisig {
        require(vault != _vault, 'Address already is vault');
        require(_vault != address(0), 'Address cannot be null address');
        address oldVault = vault;
        vault = _vault;
        emit UpdatedVault(msg.sender, oldVault, vault);
    }

    /// @notice Set a new backend address
    /// @param _backend Address of new backend wallet
    function setNewBackend(address _backend) public override whenPaused onlyMultisig {
        require(backend != _backend, 'Address already is backend');
        require(_backend != address(0), 'Address cannot be null address');
        address oldBackend = backend;
        backend = _backend;
        emit UpdatedBackend(msg.sender, oldBackend, backend);
    }

    /// @notice Set a new multisig wallet
    /// @param _multisig Address of new multisig wallet
    function setNewMultisig(address _multisig) public override whenPaused onlyMultisig {
        require(multisig != _multisig, 'Address already is multisig');
        require(_multisig != address(0), 'Address cannot be null address');
        address oldMultisig = multisig;
        multisig = _multisig;
        emit UpdatedMultisig(msg.sender, oldMultisig, multisig);
    }

    // Misc

    fallback() external {
        revert();
    }

    receive() external payable {
        revert();
    }

    function pause() public onlyMultisig {
        _pause();
    }

    function unpause() public onlyMultisig {
        _unpause();
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ITokenOffRamp {
    // operator refers to the person who called the function
    event CreateTrade(bytes32 indexed id);
    event RefundTrade(bytes32 indexed id);
    event CompleteTrade(bytes32 indexed id);

    event AddSupportedCryptocurrency(address indexed operator, address indexed tokenAddress);
    event RemoveSupportedCryptocurrency(address indexed operator, address indexed tokenAddress);
    event AddSupportedFiatCurrency(address indexed operator, bytes8 indexed currencyCode);
    event RemoveSupportedFiatCurrency(address indexed operator, bytes8 indexed currencyCode);

    event UpdatedBackend(
        address indexed operator,
        address indexed previousBackend,
        address indexed newBackend
    );
    event UpdatedVault(
        address indexed operator,
        address indexed oldVault,
        address indexed newVault
    );
    event UpdatedMultisig(
        address indexed operator,
        address indexed oldMultisig,
        address indexed newMultisig
    );

    event WithdrawToken(address indexed operator, address indexed token, uint256 amount);
    event EmergencyWithdraw(address indexed operator, address indexed token, uint256 amount);

    // Trade Functions
    function createTrade(
        bytes32 id,
        address fromTokenAddress,
        bytes8 toCurrency,
        uint256 fromAmount,
        uint256 expireAt
    ) external;

    function refundTrade(bytes32 id) external;

    function completeTrade(bytes32 id) external;

    // Operator/Owner Functions
    function addSupportedCryptocurrency(address tokenAddress) external;

    function removeSupportedCryptocurrency(address tokenAddress) external;

    function addSupportedFiatCurrency(bytes8 currencyCode) external;

    function removeSupportedFiatCurrency(bytes8 currencyCode) external;

    // Emergency Functions
    function withdraw(address _token, uint256 amount) external;

    function emergencyWithdrawAll(address[] memory _tokens) external;

    function emergencyWithdrawToken(address _token) external;

    function setNewMultisig(address _multisig) external;

    function setNewBackend(address _backend) external;

    function setNewVault(address _vault) external;
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