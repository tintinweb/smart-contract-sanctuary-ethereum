/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface WETH9 {
    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

/// @author Limitr
/// @title ERC20 token interface
interface IERC20 {
    /// @notice Approval is emitted when a token approval occurs
    /// @param owner The address that approved an allowance
    /// @param spender The address of the approved spender
    /// @param value The amount approved
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /// @notice Transfer is emitted when a transfer occurs
    /// @param from The address that owned the tokens
    /// @param to The address of the new owner
    /// @param value The amount transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @return Token name
    function name() external view returns (string memory);

    /// @return Token symbol
    function symbol() external view returns (string memory);

    /// @return Token decimals
    function decimals() external view returns (uint8);

    /// @return Total token supply
    function totalSupply() external view returns (uint256);

    /// @param owner The address to query
    /// @return owner balance
    function balanceOf(address owner) external view returns (uint256);

    /// @param owner The owner ot the tokens
    /// @param spender The approved spender of the tokens
    /// @return Allowed balance for spender
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /// @notice Approves the provided amount to the provided spender address
    /// @param spender The spender address
    /// @param amount The amount to approve
    /// @return true on success
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers tokens to the provided address
    /// @param to The new owner address
    /// @param amount The amount to transfer
    /// @return true on success
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Transfers tokens from an approved address to the provided address
    /// @param from The tokens owner address
    /// @param to The new owner address
    /// @param amount The amount to transfer
    /// @return true on success
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

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
/// @title Limitr router interface
interface ILimitrRouter {
    /// @return The address for the registry
    function registry() external view returns (address);

    /// @return The address for WETH
    function weth() external view returns (address);

    // order creation functions

    /// @notice Creates a new order using 0 as price pointer
    /// @param gotToken The token to trade in
    /// @param wantToken The token to receive in exchange
    /// @param price The order price
    /// @param amount The amount of `gotToken` to trade
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @return The order ID
    function newOrder(
        address gotToken,
        address wantToken,
        uint256 price,
        uint256 amount,
        address trader,
        uint256 deadline
    ) external returns (uint256);

    /// @notice Creates a new order using the provided `pointer`
    /// @param gotToken The token to trade in
    /// @param wantToken The token to receive in exchange
    /// @param price The order price
    /// @param amount The amount of `gotToken` to trade
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @param pointer The start pointer
    /// @return The order ID
    function newOrderWithPointer(
        address gotToken,
        address wantToken,
        uint256 price,
        uint256 amount,
        address trader,
        uint256 deadline,
        uint256 pointer
    ) external returns (uint256);

    /// @notice Creates a new order using the provided `pointers`
    /// @param gotToken The token to trade in
    /// @param wantToken The token to receive in exchange
    /// @param price The order price
    /// @param amount The amount of `gotToken` to trade
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @param pointers The potential pointers
    /// @return The order ID
    function newOrderWithPointers(
        address gotToken,
        address wantToken,
        uint256 price,
        uint256 amount,
        address trader,
        uint256 deadline,
        uint256[] memory pointers
    ) external returns (uint256);

    /// @notice Creates a new ETH order order using 0 as price pointer
    /// @param wantToken The token to receive in exchange
    /// @param price The order price
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @return The order ID
    function newETHOrder(
        address wantToken,
        uint256 price,
        address trader,
        uint256 deadline
    ) external payable returns (uint256);

    /// @notice Creates a new ETH order using the provided `pointer`
    /// @param wantToken The token to receive in exchange
    /// @param price The order price
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @param pointer The start pointer
    /// @return The order ID
    function newETHOrderWithPointer(
        address wantToken,
        uint256 price,
        address trader,
        uint256 deadline,
        uint256 pointer
    ) external payable returns (uint256);

    /// @notice Creates a new ETH order using the provided `pointers`
    /// @param wantToken The token to receive in exchange
    /// @param price The order price
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @param pointers The potential pointers
    /// @return The order ID
    function newETHOrderWithPointers(
        address wantToken,
        uint256 price,
        address trader,
        uint256 deadline,
        uint256[] memory pointers
    ) external payable returns (uint256);

    // order cancellation functions

    /// @notice Cancel an WETH order and receive ETH
    /// @param wantToken The other token of the pair WETH/xxxxx
    /// @param orderID The order ID
    /// @param amount The amount to cancel. 0 cancels the total amount
    /// @param receiver The receiver of the remaining unsold tokens
    /// @param deadline Validity deadline
    function cancelETHOrder(
        address wantToken,
        uint256 orderID,
        uint256 amount,
        address payable receiver,
        uint256 deadline
    ) external;

    // trading functions

    /// @notice Trades up to `maxAmountIn` of `gotToken` for `wantToken` from the
    ///         vault with a maximum price (per order). This function includes
    ///         the fee in the limit set by `maxAmountIn`
    /// @param wantToken The token to trade in
    /// @param gotToken The token to receive
    /// @param maxPrice The price of the trade
    /// @param maxAmountIn The maximum amount to spend
    /// @param receiver The receiver of the tokens
    /// @param deadline Validity deadline
    /// @return cost The amount of `gotToken` spent
    /// @return received The amount of `wantToken` received
    function tradeAtMaxPrice(
        address wantToken,
        address gotToken,
        uint256 maxPrice,
        uint256 maxAmountIn,
        address receiver,
        uint256 deadline
    ) external returns (uint256 cost, uint256 received);

    /// @notice Trades up to `maxAmountIn` of `gotToken` for ETH from the
    ///         vault with a maximum price (per order). This function includes
    ///         the fee in the limit set by `maxAmountIn`
    /// @param gotToken The other token of the pair WETH/xxxxx
    /// @param maxPrice The price of the trade
    /// @param maxAmountIn The maximum amount to spend
    /// @param receiver The receiver of the tokens
    /// @param deadline Validity deadline
    /// @return cost The amount spent
    /// @return received The amount of ETH received
    function tradeForETHAtMaxPrice(
        address gotToken,
        uint256 maxPrice,
        uint256 maxAmountIn,
        address payable receiver,
        uint256 deadline
    ) external returns (uint256 cost, uint256 received);

    /// @notice Trades ETH for `wantToken` from the vault with a maximum price
    ///         (per order). This function includes the fee in the limit set by `msg.value`
    /// @param wantToken The token to receive
    /// @param maxPrice The price of the trade
    /// @param receiver The receiver of the tokens
    /// @param deadline Validity deadline
    /// @return cost The amount of ETH spent
    /// @return received The amount of `wantToken` received
    function tradeETHAtMaxPrice(
        address wantToken,
        uint256 maxPrice,
        address receiver,
        uint256 deadline
    ) external payable returns (uint256 cost, uint256 received);

    /// @notice Withdraw trader balance in ETH
    /// @param gotToken The other token of the pair WETH/xxxxx
    /// @param to The receiver address
    /// @param amount The amount to withdraw
    function withdrawETH(
        address gotToken,
        address payable to,
        uint256 amount
    ) external;
}

/// @author Limitr
/// @notice This is the vault router, which handles wrapping/unwrapping ETH and
///         vault creation
contract LimitrRouter is ILimitrRouter {
    /// @return The address for the registry
    address public immutable override registry;

    /// @return The address for WETH
    address public immutable override weth;

    constructor(address _weth, address _registry) {
        weth = _weth;
        registry = _registry;
    }

    receive() external payable {}

    // order creation functions

    /// @notice Creates a new order using 0 as price pointer
    /// @param gotToken The token to trade in
    /// @param wantToken The token to receive in exchange
    /// @param price The order price
    /// @param amount The amount of `gotToken` to trade
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @return The order ID
    function newOrder(
        address gotToken,
        address wantToken,
        uint256 price,
        uint256 amount,
        address trader,
        uint256 deadline
    ) external override returns (uint256) {
        return
            newOrderWithPointer(
                gotToken,
                wantToken,
                price,
                amount,
                trader,
                deadline,
                0
            );
    }

    /// @notice Creates a new order using the provided `pointer`
    /// @param gotToken The token to trade in
    /// @param wantToken The token to receive in exchange
    /// @param price The order price
    /// @param amount The amount of `gotToken` to trade
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @param pointer The start pointer
    /// @return The order ID
    function newOrderWithPointer(
        address gotToken,
        address wantToken,
        uint256 price,
        uint256 amount,
        address trader,
        uint256 deadline,
        uint256 pointer
    ) public override returns (uint256) {
        uint256[] memory pointers = new uint256[](1);
        pointers[0] = pointer;
        return
            newOrderWithPointers(
                gotToken,
                wantToken,
                price,
                amount,
                trader,
                deadline,
                pointers
            );
    }

    /// @notice Creates a new order using the provided `pointers`
    /// @param gotToken The token to trade in
    /// @param wantToken The token to receive in exchange
    /// @param price The order price
    /// @param amount The amount of `gotToken` to trade
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @param pointers The potential pointers
    /// @return The order ID
    function newOrderWithPointers(
        address gotToken,
        address wantToken,
        uint256 price,
        uint256 amount,
        address trader,
        uint256 deadline,
        uint256[] memory pointers
    ) public override returns (uint256) {
        ILimitrVault v = _getOrCreateVault(gotToken, wantToken);
        _tokenTransferFrom(gotToken, msg.sender, address(this), amount);
        _tokenApprove(gotToken, address(v), amount);
        return
            v.newOrderWithPointers(
                gotToken,
                price,
                amount,
                trader,
                deadline,
                pointers
            );
    }

    /// @notice Creates a new ETH order order using 0 as price pointer
    /// @param wantToken The token to receive in exchange
    /// @param price The order price
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @return The order ID
    function newETHOrder(
        address wantToken,
        uint256 price,
        address trader,
        uint256 deadline
    ) external payable override returns (uint256) {
        return newETHOrderWithPointer(wantToken, price, trader, deadline, 0);
    }

    /// @notice Creates a new ETH order using the provided `pointer`
    /// @param wantToken The token to receive in exchange
    /// @param price The order price
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @param pointer The start pointer
    /// @return The order ID
    function newETHOrderWithPointer(
        address wantToken,
        uint256 price,
        address trader,
        uint256 deadline,
        uint256 pointer
    ) public payable override returns (uint256) {
        uint256[] memory pointers = new uint256[](1);
        pointers[0] = pointer;
        return
            newETHOrderWithPointers(
                wantToken,
                price,
                trader,
                deadline,
                pointers
            );
    }

    /// @notice Creates a new ETH order using the provided `pointers`
    /// @param wantToken The token to receive in exchange
    /// @param price The order price
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @param pointers The potential pointers
    /// @return The order ID
    function newETHOrderWithPointers(
        address wantToken,
        uint256 price,
        address trader,
        uint256 deadline,
        uint256[] memory pointers
    ) public payable override returns (uint256) {
        ILimitrVault v = _getOrCreateVault(weth, wantToken);
        uint256 amt = _wrapBalance();
        _tokenApprove(weth, address(v), amt);
        return
            v.newOrderWithPointers(
                weth,
                price,
                amt,
                trader,
                deadline,
                pointers
            );
    }

    // order cancellation functions

    /// @notice Cancel an WETH order and receive ETH
    /// @param wantToken The other token of the pair WETH/xxxxx
    /// @param orderID The order ID
    /// @param amount The amount to cancel. 0 cancels the total amount
    /// @param receiver The receiver of the remaining unsold tokens
    /// @param deadline Validity deadline
    function cancelETHOrder(
        address wantToken,
        uint256 orderID,
        uint256 amount,
        address payable receiver,
        uint256 deadline
    ) external override {
        ILimitrVault v = _getExistingVault(weth, wantToken);
        require(v.isAllowed(msg.sender, orderID), "LimitrRouter: not allowed");
        v.cancelOrder(orderID, amount, address(this), deadline);
        _unwrapBalance();
        _returnETHBalance(receiver);
    }

    // trading functions

    /// @notice Trades up to `maxAmountIn` of `gotToken` for `wantToken` from the
    ///         vault with a maximum price (per order). This function includes
    ///         the fee in the limit set by `maxAmountIn`
    /// @param wantToken The token to trade in
    /// @param gotToken The token to receive
    /// @param maxPrice The price of the trade
    /// @param maxAmountIn The maximum amount to spend
    /// @param receiver The receiver of the tokens
    /// @param deadline Validity deadline
    /// @return cost The amount of `gotToken` spent
    /// @return received The amount of `wantToken` received
    function tradeAtMaxPrice(
        address wantToken,
        address gotToken,
        uint256 maxPrice,
        uint256 maxAmountIn,
        address receiver,
        uint256 deadline
    ) external override returns (uint256 cost, uint256 received) {
        ILimitrVault v = _getExistingVault(wantToken, gotToken);
        _tokenTransferFrom(gotToken, msg.sender, address(this), maxAmountIn);
        _tokenApprove(gotToken, address(v), maxAmountIn);
        (cost, received) = v.tradeAtMaxPrice(
            wantToken,
            maxPrice,
            maxAmountIn,
            receiver,
            deadline
        );
        _returnTokenBalance(gotToken, msg.sender);
    }

    /// @notice Trades up to `maxAmountIn` of `gotToken` for ETH from the
    ///         vault with a maximum price (per order). This function includes
    ///         the fee in the limit set by `maxAmountIn`
    /// @param gotToken The other token of the pair WETH/xxxxx
    /// @param maxPrice The price of the trade
    /// @param maxAmountIn The maximum amount to spend
    /// @param receiver The receiver of the tokens
    /// @param deadline Validity deadline
    /// @return cost The amount spent
    /// @return received The amount of ETH received
    function tradeForETHAtMaxPrice(
        address gotToken,
        uint256 maxPrice,
        uint256 maxAmountIn,
        address payable receiver,
        uint256 deadline
    ) external override returns (uint256 cost, uint256 received) {
        ILimitrVault v = _getExistingVault(weth, gotToken);
        _tokenTransferFrom(gotToken, msg.sender, address(this), maxAmountIn);
        _tokenApprove(gotToken, address(v), maxAmountIn);
        (cost, received) = v.tradeAtMaxPrice(
            weth,
            maxPrice,
            maxAmountIn,
            address(this),
            deadline
        );
        _unwrapBalance();
        _returnETHBalance(receiver);
        _returnTokenBalance(gotToken, msg.sender);
    }

    /// @notice Trades ETH for `wantToken` from the vault with a maximum price
    ///         (per order). This function includes the fee in the limit set by `msg.value`
    /// @param wantToken The token to receive
    /// @param maxPrice The price of the trade
    /// @param receiver The receiver of the tokens
    /// @param deadline Validity deadline
    /// @return cost The amount of ETH spent
    /// @return received The amount of `wantToken` received
    function tradeETHAtMaxPrice(
        address wantToken,
        uint256 maxPrice,
        address receiver,
        uint256 deadline
    ) external payable override returns (uint256 cost, uint256 received) {
        ILimitrVault v = _getExistingVault(weth, wantToken);
        uint256 maxAmountIn = _wrapBalance();
        _tokenApprove(weth, address(v), maxAmountIn);
        (cost, received) = v.tradeAtMaxPrice(
            wantToken,
            maxPrice,
            maxAmountIn,
            receiver,
            deadline
        );
        _unwrapBalance();
        _returnETHBalance(payable(msg.sender));
    }

    /// @notice Withdraw trader balance in ETH
    /// @param gotToken The other token of the pair WETH/xxxxx
    /// @param to The receiver address
    /// @param amount The amount to withdraw
    function withdrawETH(
        address gotToken,
        address payable to,
        uint256 amount
    ) external override {
        ILimitrVault v = _getExistingVault(weth, gotToken);
        v.withdrawFor(weth, msg.sender, address(this), amount);
        _unwrapBalance();
        _returnETHBalance(to);
    }

    // internal / private functions

    function _getOrCreateVault(address tokenA, address tokenB)
        internal
        returns (ILimitrVault)
    {
        ILimitrRegistry r = ILimitrRegistry(registry);
        address v = r.vaultFor(tokenA, tokenB);
        if (v == address(0)) {
            v = r.createVault(tokenA, tokenB);
        }
        return ILimitrVault(v);
    }

    function _getExistingVault(address tokenA, address tokenB)
        internal
        view
        returns (ILimitrVault)
    {
        address v = ILimitrRegistry(registry).vaultFor(tokenA, tokenB);
        require(v != address(0), "LimitrRouter: vault doesn't exist");
        return ILimitrVault(v);
    }

    function _returnETHBalance(address payable receiver) internal {
        uint256 amt = address(this).balance;
        if (amt == 0) {
            return;
        }
        receiver.transfer(amt);
    }

    function _returnTokenBalance(address token, address receiver) internal {
        IERC20 t = IERC20(token);
        uint256 amt = t.balanceOf(address(this));
        if (amt == 0) {
            return;
        }
        _tokenTransfer(token, receiver, amt);
    }

    function _tokenApprove(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IERC20(token).approve(spender, amount);
    }

    function _tokenTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool ok = IERC20(token).transfer(to, amount);
        require(ok, "LimitrRouter: can't transfer()");
    }

    function _tokenTransferFrom(
        address token,
        address owner,
        address to,
        uint256 amount
    ) internal {
        bool ok = IERC20(token).transferFrom(owner, to, amount);
        require(ok, "LimitrRouter: can't transferFrom()");
    }

    function _wrapBalance() internal returns (uint256) {
        uint256 amt = address(this).balance;
        WETH9(weth).deposit{value: amt}();
        return amt;
    }

    function _unwrapBalance() internal {
        uint256 amt = IERC20(weth).balanceOf(address(this));
        if (amt == 0) {
            return;
        }
        WETH9(weth).withdraw(amt);
    }
}