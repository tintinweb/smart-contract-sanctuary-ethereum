/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IJumpstart {
    /// @return The names of the available uris
    function JS_names() external view returns (string[] memory);

    /// @return The uris for the provided `name`
    /// @param name The name of the uri to retrieve
    function JS_get(string memory name) external view returns (string memory);

    /// @return All uris
    function JS_getAll()
        external
        view
        returns (string[] memory, string[] memory);
}

interface IJumpstartManager {
    /// @notice Add an URL to the URL list
    /// @param name The name of the uri to add
    /// @param uri The URI
    function JS_add(string calldata name, string calldata uri) external;

    /// @notice Remove the URI from the list
    /// @param name The name of the uri to remove
    function JS_remove(string calldata name) external;

    /// @notice Update an existing URL
    /// @param name The name of the URI to update
    /// @param newUri The new URI
    function JS_update(string calldata name, string calldata newUri) external;
}

interface ILimitrRegistry is IJumpstart, IJumpstartManager {
    // events

    /// @notice VaultImplementationUpdated is emitted when a new vault implementation is set
    /// @param newVaultImplementation Then new vault implementation
    event VaultImplementationUpdated(address indexed newVaultImplementation);

    /// @notice AdminUpdated is emitted when a new admin is set
    /// @param newAdmin Then new admin
    event AdminUpdated(address indexed newAdmin);

    /// @notice FeeReceiverUpdated is emitted when a new fee receiver is set
    /// @param newFeeReceiver Then new fee receiver
    event FeeReceiverUpdated(address indexed newFeeReceiver);

    /// @notice VaultCreated is emitted when a new vault is created and added to the registry
    /// param vault The address of the vault created
    /// @param token0 One of the tokens in the pair
    /// @param token1 the other token in the pair
    event VaultCreated(
        address indexed vault,
        address indexed token0,
        address indexed token1
    );

    /// @notice Initialize addresses
    /// @param _router The address of the router
    /// @param _vaultScanner The address of the vault scanner
    /// @param _vaultImplementation The vault implementation
    function initialize(
        address _router,
        address _vaultScanner,
        address _vaultImplementation
    ) external;

    /// @return The admin address
    function admin() external view returns (address);

    /// @notice Transfer the admin rights. Emits AdminUpdated
    /// @param newAdmin The new admin
    function transferAdmin(address newAdmin) external;

    /// @return The fee receiver address
    function feeReceiver() external view returns (address);

    /// @notice Set a new fee receiver. Emits FeeReceiverUpdated
    /// @param newFeeReceiver The new fee receiver
    function setFeeReceiver(address newFeeReceiver) external;

    /// @return The router address
    function router() external view returns (address);

    /// @return The vault implementation address
    function vaultImplementation() external view returns (address);

    /// @notice Set a new vault implementation. Emits VaultImplementationUpdated
    /// @param newVaultImplementation The new vault implementation
    function setVaultImplementation(address newVaultImplementation) external;

    /// @notice Create a new vault
    /// @param tokenA One of the tokens in the pair
    /// @param tokenB the other token in the pair
    /// @return The vault address
    function createVault(address tokenA, address tokenB)
        external
        returns (address);

    /// @return The number of available vaults
    function vaultsCount() external view returns (uint256);

    /// @return The vault at index idx
    /// @param idx The vault index
    function vault(uint256 idx) external view returns (address);

    /// @return The n vaults at index idx
    /// @param idx The vault index
    /// @param n The number of vaults
    function vaults(uint256 idx, uint256 n)
        external
        view
        returns (address[] memory);

    /// @return The address of the vault for the trade pair tokenA/tokenB
    /// @param tokenA One of the tokens in the pair
    /// @param tokenB the other token in the pair
    function vaultFor(address tokenA, address tokenB)
        external
        view
        returns (address);

    /// @return The address for the vault with the provided hash
    /// @param hash The vault hash
    function vaultByHash(bytes32 hash) external view returns (address);

    /// @notice Calculate the hash for a vault
    /// @param tokenA One of the tokens in the pair
    /// @param tokenB the other token in the pair
    /// @return The vault hash
    function vaultHash(address tokenA, address tokenB)
        external
        pure
        returns (bytes32);

    /// @return The address of the vault scanner
    function vaultScanner() external view returns (address);
}

/// @author Limitr
/// @title ERC165 interface needed for the ERC721 implementation
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/// @author Limitr
/// @title ERC721 interface for the Limit vault
interface IERC721 is IERC165 {
    // events

    /// @notice Transfer is emitted when an order is transferred to a new owner
    /// @param from The order owner
    /// @param to The new order owner
    /// @param tokenId The token/order ID transferred
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /// @notice Approval is emitted when the owner approves approved to transfer tokenId
    /// @param owner The token/order owner
    /// @param approved The address approved to transfer the token/order
    /// @param tokenId the token/order ID
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /// @notice ApprovalForAll is emitted when the owner approves operator sets a new approval flag (true/false) for all tokens/orders
    /// @param owner The tokens/orders owner
    /// @param operator The operator address
    /// @param approved The approval status for all tokens/orders
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /// @param owner The tokens/orders owner
    /// @return balance The number of tokens/orders owned by owner
    function balanceOf(address owner) external view returns (uint256 balance);

    /// @notice Returns the owner of a token/order. The ID must be valid
    /// @param tokenId The token/order ID
    /// @return owner The owner of a token/order. The ID must be valid
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /// @notice Approves an account to transfer the token/order with the given ID.
    ///         The token/order must exists
    /// @param to The address of the account to approve
    /// @param tokenId the token/order
    function approve(address to, uint256 tokenId) external;

    /// @notice Returns the address approved to transfer the token/order with the given ID
    ///         The token/order must exists
    /// @param tokenId the token/order
    /// @return operator The address approved to transfer the token/order with the given ID
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /// @notice Approves or removes the operator for the caller tokens/orders
    /// @param operator The operator to be approved/removed
    /// @param _approved Set true to approve, false to remove
    function setApprovalForAll(address operator, bool _approved) external;

    /// @notice Returns if the operator is allowed to manage all tokens/orders of owner
    /// @param owner The owner of the tokens/orders
    /// @param operator The operator
    /// @return If the operator is allowed to manage all tokens/orders of owner
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /// @notice Transfers the ownership of the token/order. Can be called by the owner
    ///         or approved operators
    /// @param from The token/order owner
    /// @param to The new owner
    /// @param tokenId The token/order ID to transfer
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /// @notice Safely transfers the token/order. It checks contract recipients are aware
    ///         of the ERC721 protocol to prevent tokens from being forever locked.
    /// @param from The token/order owner
    /// @param to the new owner
    /// @param tokenId The token/order ID to transfer
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /// @notice Safely transfers the token/order. It checks contract recipients are aware
    ///         of the ERC721 protocol to prevent tokens from being forever locked.
    /// @param from The token/order owner
    /// @param to the new owner
    /// @param tokenId The token/order ID to transfer
    /// @param data The data to be passed to the onERC721Received() call
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

/// @author Limitr
/// @title Trade vault contract interface for Limitr
interface ILimitrVault is IERC721 {
    // events

    /// @notice NewFeePercentage is emitted when a new fee receiver is set
    /// @param oldFeePercentage The old fee percentage
    /// @param newFeePercentage The new fee percentage
    event NewFeePercentage(uint256 oldFeePercentage, uint256 newFeePercentage);

    /// @notice OrderCreated is emitted when a new order is created
    /// @param token The token traded in, will be either token0 or token1
    /// @param id The id of the order
    /// @param trader The trader address
    /// @param price The price of the order
    /// @param amount The amount deposited
    event OrderCreated(
        address indexed token,
        uint256 indexed id,
        address indexed trader,
        uint256 price,
        uint256 amount
    );

    /// @notice OrderCanceled is emitted when a trader cancels (even if partially) an order
    /// @param token The token traded in, will be either token0 or token1
    /// @param id The order id
    /// @param price The order price
    /// @param amount The amount canceled
    event OrderCanceled(
        address indexed token,
        uint256 indexed id,
        uint256 indexed price,
        uint256 amount
    );

    /// @notice OrderTaken is emitted when an order is taken (even if partially) from the vault
    /// @param token The token sold
    /// @param id The order id
    /// @param owner The owner of the order
    /// @param amount The amount traded
    /// @param price The trade price
    event OrderTaken(
        address indexed token,
        uint256 indexed id,
        address indexed owner,
        uint256 amount,
        uint256 price
    );

    /// @notice TokenWithdraw is emitted when an withdrawal is requested by a trader
    /// @param token The token withdrawn
    /// @param owner The owner of the funds
    /// @param receiver The receiver of the tokens
    /// @param amount The amount withdrawn
    event TokenWithdraw(
        address indexed token,
        address indexed owner,
        address indexed receiver,
        uint256 amount
    );

    /// @notice ArbitrageProfitTaken is emitted when an arbitrage profit is taken
    /// @param profitToken The main profit token
    /// @param profitAmount The amount of `profitToken` received
    /// @param otherAmount The amount of received of the other token of the vault
    /// @param receiver The profit receiver
    event ArbitrageProfitTaken(
        address indexed profitToken,
        uint256 profitAmount,
        uint256 otherAmount,
        address indexed receiver
    );

    /// @notice FeeCollected is emitted when the fee on a trade is collected
    /// @param token The fee token
    /// @param amount The amount collected
    event FeeCollected(address indexed token, uint256 amount);

    /// @notice TradingPaused is emitted when trading is paused by the admin
    event TradingPaused();

    /// @notice TradingResumed is emitted when trading is paused by the admin
    event TradingResumed();

    /// @notice Initialize the market. Must be called by the factory once at deployment time
    /// @param _token0 The first token of the pair
    /// @param _token1 The second token of the pair
    function initialize(address _token0, address _token1) external;

    // fee functions

    /// @return The fee percentage represented as a value between 0 and 10^18
    function feePercentage() external view returns (uint256);

    /// @notice Set a new fee (must be smaller than the current, for the `feeReceiverSetter` only)
    ///         Emits a NewFeePercentage event
    /// @param newFeePercentage The new fee in the format described in `feePercentage`
    function setFeePercentage(uint256 newFeePercentage) external;

    // factory and token addresses

    /// @return The registry address
    function registry() external view returns (address);

    /// @return The first token of the pair
    function token0() external view returns (address);

    /// @return The second token of the pair
    function token1() external view returns (address);

    // price listing functions

    /// @return The first price on the order book for the provided `token`
    /// @param token Must be `token0` or `token1`
    function firstPrice(address token) external view returns (uint256);

    /// @return The last price on the order book for the provided `token`
    /// @param token Must be `token0` or `token1`
    function lastPrice(address token) external view returns (uint256);

    /// @return The previous price to the pointer for the provided `token`
    /// @param token Must be `token0` or `token1`
    /// @param current The current price
    function previousPrice(address token, uint256 current)
        external
        view
        returns (uint256);

    /// @return The next price to the current for the provided `token`
    /// @param token Must be `token0` or `token1`
    /// @param current The current price
    function nextPrice(address token, uint256 current)
        external
        view
        returns (uint256);

    /// @return N prices after current for the provided `token`
    /// @param token Must be `token0` or `token1`
    /// @param current The current price
    /// @param n The number of prices to return
    function prices(
        address token,
        uint256 current,
        uint256 n
    ) external view returns (uint256[] memory);

    /// @return n price pointers for the provided price for the provided `token`
    /// @param token Must be `token0` or `token1`
    /// @param price The price to insert
    /// @param nPointers The number of pointers to return
    function pricePointers(
        address token,
        uint256 price,
        uint256 nPointers
    ) external view returns (uint256[] memory);

    // orders functions

    /// @return The ID of the first order for the provided `token`
    /// @param token Must be `token0` or `token1`
    function firstOrder(address token) external view returns (uint256);

    /// @return The ID of the last order for the provided `token`
    /// @param token Must be `token0` or `token1`
    function lastOrder(address token) external view returns (uint256);

    /// @return The ID of the previous order for the provided `token`
    /// @param token Must be `token0` or `token1`
    /// @param currentID Pointer to the current order
    function previousOrder(address token, uint256 currentID)
        external
        view
        returns (uint256);

    /// @return The ID of the next order for the provided `token`
    /// @param token Must be `token0` or `token1`
    /// @param currentID Pointer to the current order
    function nextOrder(address token, uint256 currentID)
        external
        view
        returns (uint256);

    /// @notice Returns n order IDs from the current for the provided `token`
    /// @param token Must be `token0` or `token1`
    /// @param current The current ID
    /// @param n The number of IDs to return
    function orders(
        address token,
        uint256 current,
        uint256 n
    ) external view returns (uint256[] memory);

    /// @notice Returns the order data for `n` orders of the provided `token`,
    ///         starting after `current`
    /// @param token Must be `token0` or `token1`
    /// @param current The current ID
    /// @param n The number of IDs to return
    /// @return id Array of order IDs
    /// @return price Array of prices
    /// @return amount Array of amounts
    /// @return trader Array of traders
    function ordersInfo(
        address token,
        uint256 current,
        uint256 n
    )
        external
        view
        returns (
            uint256[] memory id,
            uint256[] memory price,
            uint256[] memory amount,
            address[] memory trader
        );

    /// @notice Returns the order data for the provided `token` and `orderID`
    /// @param token Must be `token0` or `token1`
    /// @param orderID ID of the order
    /// @return price The price for the order
    /// @return amount The amount of the base token for sale
    /// @return trader The owner of the order
    function orderInfo(address token, uint256 orderID)
        external
        view
        returns (
            uint256 price,
            uint256 amount,
            address trader
        );

    /// @return Returns the token for sale of the provided `orderID`
    /// @param orderID The order ID
    function orderToken(uint256 orderID) external view returns (address);

    /// @return The last assigned order ID
    function lastID() external view returns (uint256);

    /// liquidity functions

    /// @return Return the available liquidity at a particular price, for the provided `token`
    /// @param token Must be `token0` or `token1`
    /// @param price The price
    function liquidityByPrice(address token, uint256 price)
        external
        view
        returns (uint256);

    /// @notice Return `n` of the available prices and liquidity, starting at `current`, for the provided `token`
    /// @param token Must be `token0` or `token1`
    /// @param current The current price
    /// @param n The number of prices to return
    /// @return price Array of prices
    /// @return priceLiquidity Array of liquidity
    function liquidity(
        address token,
        uint256 current,
        uint256 n
    )
        external
        view
        returns (uint256[] memory price, uint256[] memory priceLiquidity);

    /// @return The total liquidity available for the provided `token`
    /// @param token Must be `token0` or `token1`
    function totalLiquidity(address token) external view returns (uint256);

    // trader order functions

    /// @return The ID of the first order of the `trader` for the provided `token`
    /// @param token The token to list
    /// @param trader The trader
    function firstTraderOrder(address token, address trader)
        external
        view
        returns (uint256);

    /// @return The ID of the last order of the `trader` for the provided `token`
    /// @param token The token to list
    /// @param trader The trader
    function lastTraderOrder(address token, address trader)
        external
        view
        returns (uint256);

    /// @return The ID of the previous order of the `trader` for the provided `token`
    /// @param token The token to list
    /// @param trader The trader
    /// @param currentID Pointer to a trade
    function previousTraderOrder(
        address token,
        address trader,
        uint256 currentID
    ) external view returns (uint256);

    /// @return The ID of the next order of the `trader` for the provided `token`
    /// @param token The token to list
    /// @param trader The trader
    /// @param currentID Pointer to a trade
    function nextTraderOrder(
        address token,
        address trader,
        uint256 currentID
    ) external view returns (uint256);

    /// @notice Returns n order IDs from `current` for the provided `token`
    /// @param token The `token` to list
    /// @param trader The trader
    /// @param current The current ID
    /// @param n The number of IDs to return
    function traderOrders(
        address token,
        address trader,
        uint256 current,
        uint256 n
    ) external view returns (uint256[] memory);

    // fee calculation functions

    /// @return The amount corresponding to the fee from a provided `amount`
    /// @param amount The traded amount
    function feeOf(uint256 amount) external view returns (uint256);

    /// @return The amount to collect as fee for the provided `amount`
    /// @param amount The amount traded
    function feeFor(uint256 amount) external view returns (uint256);

    /// @return The amount available after collecting the fee from the provided `amount`
    /// @param amount The total amount
    function withoutFee(uint256 amount) external view returns (uint256);

    /// @return The provided `amount` with added fee
    /// @param amount The amount without fee
    function withFee(uint256 amount) external view returns (uint256);

    // trade amounts calculation functions

    /// @return The cost of `amountOut` of `wantToken` at the provided `price`.
    ///         Fees not included
    /// @param wantToken The token to receive
    /// @param amountOut The amount of `wantToken` to receive
    /// @param price The trade price
    function costAtPrice(
        address wantToken,
        uint256 amountOut,
        uint256 price
    ) external view returns (uint256);

    /// @return The return of trading `amountIn` for `wantToken` at then provided
    ///         `price`. Fees not included.
    /// @param wantToken The token to receive
    /// @param amountIn The cost
    /// @param price The trade price
    function returnAtPrice(
        address wantToken,
        uint256 amountIn,
        uint256 price
    ) external view returns (uint256);

    /// @notice The cost/return of up to `maxAmountOut` of `wantToken` at a
    ///         maximum of `maxPrice`. Fees not included
    /// @param wantToken The token to receive
    /// @param maxAmountOut The maximum return
    /// @param maxPrice The max price
    /// @return amountIn The cost
    /// @return amountOut The return
    function costAtMaxPrice(
        address wantToken,
        uint256 maxAmountOut,
        uint256 maxPrice
    ) external view returns (uint256 amountIn, uint256 amountOut);

    /// @notice The cost/return of trading up to `maxAmountIn` for `wantToken`
    ///         at a maximum price of `maxPrice`. Fees not included.
    /// @param wantToken The token to receive
    /// @param maxAmountIn The maximum cost
    /// @param maxPrice The max price
    /// @return amountIn The cost
    /// @return amountOut The return
    function returnAtMaxPrice(
        address wantToken,
        uint256 maxAmountIn,
        uint256 maxPrice
    ) external view returns (uint256 amountIn, uint256 amountOut);

    // order creation functions

    /// @notice Creates a new order order using 0 as price pointer
    /// @param gotToken The token to trade in
    /// @param price The order price
    /// @param amount The amount of `gotToken` to trade
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @return The order ID
    function newOrder(
        address gotToken,
        uint256 price,
        uint256 amount,
        address trader,
        uint256 deadline
    ) external returns (uint256);

    /// @notice Creates a new order using a `pointer`
    /// @param gotToken The token to trade in
    /// @param price The order price
    /// @param amount The amount of `gotToken` to trade
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @param pointer The start pointer
    /// @return The order ID
    function newOrderWithPointer(
        address gotToken,
        uint256 price,
        uint256 amount,
        address trader,
        uint256 deadline,
        uint256 pointer
    ) external returns (uint256);

    /// @notice Creates a new order using an array of possible `pointers`
    /// @param gotToken The token to trade in
    /// @param price The order price
    /// @param amount The amount of `gotToken` to trade
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @param pointers The potential pointers
    /// @return The order ID
    function newOrderWithPointers(
        address gotToken,
        uint256 price,
        uint256 amount,
        address trader,
        uint256 deadline,
        uint256[] memory pointers
    ) external returns (uint256);

    // order cancellation functions

    /// @notice Cancel an order
    /// @param orderID The order ID
    /// @param amount The amount to cancel. 0 cancels the total amount
    /// @param receiver The receiver of the remaining unsold tokens
    /// @param deadline Validity deadline
    function cancelOrder(
        uint256 orderID,
        uint256 amount,
        address receiver,
        uint256 deadline
    ) external;

    // trading functions

    /// @notice Trades up to `maxAmountIn` for `wantToken` with a `maxPrice`
    ///         (per order). This function includes the fee in the limit set
    ///         by `maxAmountIn`
    /// @param wantToken The token to receive
    /// @param maxPrice The price of the trade
    /// @param maxAmountIn The maximum cost
    /// @param receiver The receiver of the tokens
    /// @param deadline Validity deadline
    /// @return cost The amount spent
    /// @return received The amount of `wantToken` received
    function tradeAtMaxPrice(
        address wantToken,
        uint256 maxPrice,
        uint256 maxAmountIn,
        address receiver,
        uint256 deadline
    ) external returns (uint256 cost, uint256 received);

    // trader balances

    /// @return The trader balance available to withdraw
    /// @param token Must be `token0` or `token1`
    /// @param trader The trader address
    function traderBalance(address token, address trader)
        external
        view
        returns (uint256);

    /// @notice Withdraw trader balance
    /// @param token Must be `token0` or `token1`
    /// @param to The receiver address
    /// @param amount The amount to withdraw
    function withdraw(
        address token,
        address to,
        uint256 amount
    ) external;

    /// @notice Withdraw on behalf of a trader. Can only be called by the router
    /// @param token Must be `token0` or `token1`
    /// @param trader The trader to handle
    /// @param amount The amount to withdraw
    function withdrawFor(
        address token,
        address trader,
        address receiver,
        uint256 amount
    ) external;

    // function arbitrage_trade() external;

    /// @return If an address is allowed to handle a order
    /// @param sender The sender address
    /// @param tokenId The orderID / tokenId
    function isAllowed(address sender, uint256 tokenId)
        external
        view
        returns (bool);

    /// @return The version of the vault implementation
    function implementationVersion() external view returns (uint16);

    /// @return The address of the vault implementation
    function implementationAddress() external view returns (address);

    /// @notice Returns the estimated profit for an arbitrage trade
    /// @param profitToken The token to take profit in
    /// @param maxAmountIn The maximum amount of `profitToken` to borrow
    /// @param maxPrice The maximum purchase price
    /// @return profitIn The amount to borrow of the `profitToken`
    /// @return profitOut The total amount to receive `profitToken`
    /// @return otherOut the amount of the other token of the vault to receive
    function arbitrageAmountsOut(
        address profitToken,
        uint256 maxAmountIn,
        uint256 maxPrice
    )
        external
        view
        returns (
            uint256 profitIn,
            uint256 profitOut,
            uint256 otherOut
        );

    /// @notice Buys from one side of the vault with borrowed funds and dumps on
    ///         the other side
    /// @param profitToken The token to take profit in
    /// @param maxBorrow The maximum amount of `profitToken` to borrow
    /// @param maxPrice The maximum purchase price
    /// @param receiver The receiver of the arbitrage profits
    /// @param deadline Validity deadline
    function arbitrageTrade(
        address profitToken,
        uint256 maxBorrow,
        uint256 maxPrice,
        address receiver,
        uint256 deadline
    ) external returns (uint256 profitAmount, uint256 otherAmount);

    /// @notice Returns the trading status of the contract
    function isTradingPaused() external view returns (bool);

    /// @notice Pauses trading on the vault. Can only be called by the admin
    function pauseTrading() external;

    /// @notice Resumes trading on the vault. Can only be called by the admin
    function resumeTrading() external;
}

/// @author Limitr
/// @notice This is the contract for the Limitr main registry
contract LimitrRegistry is ILimitrRegistry {
    /// @return The admin address
    address public override admin;

    /// @return The router address
    address public override router;

    /// @return The vault implementation address
    address public override vaultImplementation;

    /// @return The fee receiver address
    address public override feeReceiver;

    /// @notice The vault at index idx
    address[] public override vault;

    /// @return The address for the vault with the provided hash
    mapping(bytes32 => address) public override vaultByHash;

    /// @return The address of the vault scanner
    address public override vaultScanner;

    address private _deployer;

    constructor() {
        admin = msg.sender;
        feeReceiver = msg.sender;
        _deployer = msg.sender;
    }

    /// @notice Initialize addresses
    /// @param _router The address of the router
    /// @param _vaultScanner The address of the vault scanner
    /// @param _vaultImplementation The vault implementation
    function initialize(
        address _router,
        address _vaultScanner,
        address _vaultImplementation
    ) external override {
        require(msg.sender == _deployer, "LimitrRegistry: not the deployer");
        require(router == address(0), "LimitrRegistry: already initialized");
        router = _router;
        vaultScanner = _vaultScanner;
        vaultImplementation = _vaultImplementation;
    }

    string[] internal _uriNames;

    /// @return The names of the available uris
    function JS_names() external view override returns (string[] memory) {
        return _uriNames;
    }

    /// @return The uris for the provided `name`
    mapping(string => string) public override JS_get;

    /// @return All uris
    function JS_getAll()
        external
        view
        override
        returns (string[] memory, string[] memory)
    {
        string[] memory rn = new string[](_uriNames.length);
        string[] memory ru = new string[](_uriNames.length);
        for (uint256 i = 0; i < _uriNames.length; i++) {
            rn[i] = _uriNames[i];
            ru[i] = JS_get[rn[i]];
        }
        return (rn, ru);
    }

    /// @notice Add an URL to the URL list
    /// @param name The name of the uri to add
    /// @param uri The URI
    function JS_add(string calldata name, string calldata uri)
        external
        override
        onlyAdmin
    {
        require(bytes(JS_get[name]).length == 0, "JSM: Already exists");
        _uriNames.push(name);
        JS_get[name] = uri;
    }

    /// @notice Remove the URI from the list
    /// @param name The name of the uri to remove
    function JS_remove(string calldata name) external override onlyAdmin {
        bytes32 nameK = keccak256(abi.encodePacked(name));
        for (uint256 i = 0; i < _uriNames.length; i++) {
            if (nameK != keccak256(abi.encodePacked(_uriNames[i]))) {
                continue;
            }
            _uriNames[i] = _uriNames[_uriNames.length - 1];
            _uriNames.pop();
            delete JS_get[name];
            return;
        }
        require(true == false, "JSM: Not found");
    }

    /// @notice Update an existing URL
    /// @param name The name of the URI to update
    /// @param newUri The new URI
    function JS_update(string calldata name, string calldata newUri)
        external
        override
        onlyAdmin
    {
        require(bytes(JS_get[name]).length != 0, "JSM: Not found");
        JS_get[name] = newUri;
    }

    /// @notice Transfer the admin rights. Emits AdminUpdated
    /// @param newAdmin The new admin
    function transferAdmin(address newAdmin) external override onlyAdmin {
        admin = newAdmin;
        emit AdminUpdated(newAdmin);
    }

    /// @notice Set a new fee receiver. Emits FeeReceiverUpdated
    /// @param newFeeReceiver The new fee receiver
    function setFeeReceiver(address newFeeReceiver)
        external
        override
        onlyAdmin
    {
        feeReceiver = newFeeReceiver;
        emit FeeReceiverUpdated(newFeeReceiver);
    }

    /// @notice Set a new vault implementation. Emits VaultImplementationUpdated
    /// @param newVaultImplementation The new vault implementation
    function setVaultImplementation(address newVaultImplementation)
        external
        override
        onlyAdmin
    {
        vaultImplementation = newVaultImplementation;
        emit VaultImplementationUpdated(newVaultImplementation);
    }

    /// @notice Create a new vault
    /// @param tokenA One of the tokens in the pair
    /// @param tokenB the other token in the pair
    /// @return The vault address
    function createVault(address tokenA, address tokenB)
        external
        override
        noZeroAddress(tokenA)
        noZeroAddress(tokenB)
        returns (address)
    {
        require(tokenA != tokenB, "LimitrRegistry: equal src and dst tokens");
        (address t0, address t1) = _sortTokens(tokenA, tokenB);
        bytes32 hash = keccak256(abi.encodePacked(t0, t1));
        require(
            vaultByHash[hash] == address(0),
            "LimitrRegistry: vault already exists"
        );
        address addr = _deployClone(vaultImplementation);
        ILimitrVault(addr).initialize(t0, t1);
        vaultByHash[hash] = addr;
        vault.push(addr);
        emit VaultCreated(addr, t0, t1);
        return addr;
    }

    /// @return The number of available vaults
    function vaultsCount() external view override returns (uint256) {
        return vault.length;
    }

    /// @return The `n` vaults at index `idx`
    /// @param idx The vault index
    /// @param n The number of vaults
    function vaults(uint256 idx, uint256 n)
        public
        view
        override
        returns (address[] memory)
    {
        address[] memory r = new address[](n);
        for (uint256 i = 0; i < n && idx + i < vault.length; i++) {
            r[i] = vault[idx + i];
        }
        return r;
    }

    /// @return The address of the vault for the trade pair tokenA/tokenB
    /// @param tokenA One of the tokens in the pair
    /// @param tokenB the other token in the pair
    function vaultFor(address tokenA, address tokenB)
        external
        view
        override
        noZeroAddress(tokenA)
        noZeroAddress(tokenB)
        returns (address)
    {
        require(
            tokenA != tokenB,
            "LimitrRegistry: equal base and counter tokens"
        );
        return vaultByHash[_vaultHash(tokenA, tokenB)];
    }

    /// @notice Calculate the hash for a vault
    /// @param tokenA One of the tokens in the pair
    /// @param tokenB the other token in the pair
    /// @return The vault hash
    function vaultHash(address tokenA, address tokenB)
        public
        pure
        override
        returns (bytes32)
    {
        require(tokenA != tokenB, "LimitrRegistry: equal src and dst tokens");
        return _vaultHash(tokenA, tokenB);
    }

    // modifiers

    /// @dev Check for 0 address
    modifier noZeroAddress(address addr) {
        require(addr != address(0), "LimitrRegistry: zero address not allowed");
        _;
    }

    /// @dev only for the admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "LimitrRegistry: not the admin");
        _;
    }

    // private/internal functions

    function _sortTokens(address a, address b)
        internal
        pure
        returns (address, address)
    {
        return a < b ? (a, b) : (b, a);
    }

    function _vaultHash(address a, address b) internal pure returns (bytes32) {
        (address t0, address t1) = _sortTokens(a, b);
        return keccak256(abi.encodePacked(t0, t1));
    }

    function _buildCloneBytecode(address impl)
        internal
        pure
        returns (bytes memory)
    {
        // calldatacopy(0, 0, calldatasize())
        // 3660008037

        // 0x36 CALLDATASIZE
        // 0x60 PUSH1 0x00
        // 0x80 DUP1
        // 0x37 CALLDATACOPY

        // let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
        // 600080368173xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx5af4

        // 0x60 PUSH1 0x00
        // 0x80 DUP1
        // 0x36 CALLDATASIZE
        // 0x81 DUP2
        // 0x73 PUSH20 <concat-address-here>
        // 0x5A GAS
        // 0xF4 DELEGATECALL

        // returndatacopy(0, 0, returndatasize())
        // 3d6000803e

        // 0x3D RETURNDATASIZE
        // 0x60 PUSH1 0x00
        // 0x80 DUP1
        // 0x3E RETURNDATACOPY

        // switch result
        // case 0 { revert(0, returndatasize()) }
        // case 1 { return(0, returndatasize()) }
        // 60003d91600114603157fd5bf3

        // 0x60 PUSH1 0x00
        // 0x3D RETURNDATASIZE
        // 0x91 SWAP2
        // 0x60 PUSH1 0x01
        // 0x14 EQ
        // 0x60 PUSH1 0x31
        // 0x57 JUMPI
        // 0xFD REVERT
        // 0x5B JUMPEST
        // 0xF3 RETURN

        return
            bytes.concat(
                bytes(hex"3660008037600080368173"),
                bytes20(impl),
                bytes(hex"5af43d6000803e60003d91600114603157fd5bf3")
            );
    }

    function _prependCloneConstructor(address impl)
        internal
        pure
        returns (bytes memory)
    {
        // codecopy(0, ofs, codesize() - ofs)
        // return(0, codesize() - ofs)

        // 0x60 PUSH1 0x0D
        // 0x80 DUP1
        // 0x38 CODESIZE
        // 0x03 SUB
        // 0x80 DUP1
        // 0x91 SWAP2
        // 0x60 PUSH1 0x00
        // 0x39 CODECOPY
        // 0x60 PUSH1 0x00
        // 0xF3 RETURN
        // <concat-contract-code-here>

        // 0x600D80380380916000396000F3xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        return
            bytes.concat(
                hex"600D80380380916000396000F3",
                _buildCloneBytecode(impl)
            );
    }

    function _deployClone(address impl)
        internal
        returns (address deploymentAddr)
    {
        bytes memory code = _prependCloneConstructor(impl);
        assembly {
            deploymentAddr := create(callvalue(), add(code, 0x20), mload(code))
        }
        require(
            deploymentAddr != address(0),
            "LimitrRegistry: clone deployment failed"
        );
    }
}