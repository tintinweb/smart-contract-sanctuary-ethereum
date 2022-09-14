/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

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

/// @author Limitr
/// @title ERC721 token receiver interface
/// @dev Interface for any contract that wants to support safeTransfers from ERC721 asset contracts.
interface IERC721Receiver {
    /// @notice Whenever an {IERC721} `tokenId` token is transferred to this contract
    ///      by `operator` from `from`, this function is called.
    ///      It must return its Solidity selector to confirm the token transfer.
    ///      If any other value is returned or the interface is not implemented
    ///      by the recipient, the transfer will be reverted.
    ///      The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
    /// @param operator The sender of the token
    /// @param from The owner of the token
    /// @param tokenId The token ID
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// double linked list
struct DLL {
    mapping(uint256 => uint256) _next;
    mapping(uint256 => uint256) _prev;
}

// double linked list handling
library DoubleLinkedList {
    // first entry
    function first(DLL storage dll) internal view returns (uint256) {
        return dll._next[0];
    }

    // last entry
    function last(DLL storage dll) internal view returns (uint256) {
        return dll._prev[0];
    }

    // next entry
    function next(DLL storage dll, uint256 current)
        internal
        view
        returns (uint256)
    {
        return dll._next[current];
    }

    // previous entry
    function previous(DLL storage dll, uint256 current)
        internal
        view
        returns (uint256)
    {
        return dll._prev[current];
    }

    // insert at the beginning
    function insertBeginning(DLL storage dll, uint256 value) internal {
        insertAfter(dll, value, 0);
    }

    // insert at the end
    function insertEnd(DLL storage dll, uint256 value) internal {
        insertBefore(dll, value, 0);
    }

    // insert after an entry
    function insertAfter(
        DLL storage dll,
        uint256 value,
        uint256 _prev
    ) internal {
        uint256 _next = dll._next[_prev];
        dll._next[_prev] = value;
        dll._prev[_next] = value;
        dll._next[value] = _next;
        dll._prev[value] = _prev;
    }

    // insert before an entry
    function insertBefore(
        DLL storage dll,
        uint256 value,
        uint256 _next
    ) internal {
        uint256 _prev = dll._prev[_next];
        dll._next[_prev] = value;
        dll._prev[_next] = value;
        dll._next[value] = _next;
        dll._prev[value] = _prev;
    }

    // remove an entry
    function remove(DLL storage dll, uint256 value) internal {
        uint256 p = dll._prev[value];
        uint256 n = dll._next[value];
        dll._prev[n] = p;
        dll._next[p] = n;
        dll._prev[value] = 0;
        dll._next[value] = 0;
    }
}

// sorted double linked list
struct SDLL {
    mapping(uint256 => uint256) _next;
    mapping(uint256 => uint256) _prev;
}

// sorted double linked list handling
library SortedDoubleLinkedList {
    // first entry
    function first(SDLL storage s) internal view returns (uint256) {
        return s._next[0];
    }

    // last entry
    function last(SDLL storage s) internal view returns (uint256) {
        return s._prev[0];
    }

    // next entry
    function next(SDLL storage s, uint256 current)
        internal
        view
        returns (uint256)
    {
        return s._next[current];
    }

    // previous entry
    function previous(SDLL storage s, uint256 current)
        internal
        view
        returns (uint256)
    {
        return s._prev[current];
    }

    // insert with a pointer
    function insertWithPointer(
        SDLL storage s,
        uint256 value,
        uint256 pointer
    ) internal returns (bool) {
        uint256 n = pointer;
        while (true) {
            n = s._next[n];
            if (n == 0 || n > value) {
                break;
            }
        }
        uint256 p = s._prev[n];
        s._next[p] = value;
        s._prev[n] = value;
        s._next[value] = n;
        s._prev[value] = p;
        return true;
    }

    // insert using 0 as a pointer
    function insert(SDLL storage s, uint256 value) internal returns (bool) {
        return insertWithPointer(s, value, 0);
    }

    // remove an entry
    function remove(SDLL storage s, uint256 value) internal {
        uint256 p = s._prev[value];
        uint256 n = s._next[value];
        s._prev[n] = p;
        s._next[p] = n;
        s._prev[value] = 0;
        s._next[value] = 0;
    }
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

/// @dev Order data
struct Order {
    uint256 price;
    uint256 amount;
    address trader;
}

/// @dev trade handler
struct TradeHandler {
    uint256 amountIn;
    uint256 amountOut;
    uint256 availableAmountIn;
}

/// @dev trade handler methods
library TradeHandlerLib {
    function update(
        TradeHandler memory _trade,
        uint256 amountIn,
        uint256 amountOut
    ) internal pure {
        _trade.amountIn += amountIn;
        _trade.amountOut += amountOut;
        _trade.availableAmountIn -= amountIn;
    }
}

/// @author Limitr
/// @title Trade vault contract for Limitr
contract LimitrVault is ILimitrVault {
    using DoubleLinkedList for DLL;
    using SortedDoubleLinkedList for SDLL;
    using TradeHandlerLib for TradeHandler;

    address private _deployer;

    constructor() {
        _deployer = msg.sender;
    }

    /// @notice Initialize the market. Must be called by the factory once at deployment time
    /// @param _token0 The first token of the pair
    /// @param _token1 The second token of the pair
    function initialize(address _token0, address _token1) external override {
        require(registry == address(0), "LimitrVault: already initialized");
        require(
            _token0 != _token1,
            "LimitrVault: base and counter tokens are the same"
        );
        require(_token0 != address(0), "LimitrVault: zero address not allowed");
        require(_token1 != address(0), "LimitrVault: zero address not allowed");
        token0 = _token0;
        token1 = _token1;
        registry = msg.sender;
        _oneToken[_token0] = 10**IERC20(_token0).decimals();
        _oneToken[_token1] = 10**IERC20(_token1).decimals();
        feePercentage = 2 * 10**15; // 0.2 %
    }

    /// @return The fee percentage represented as a value between 0 and 10^18
    uint256 public override feePercentage;

    /// @notice Set a new fee (must be smaller than the current, for the `feeReceiverSetter` only)
    ///         Emits a NewFeePercentage event
    /// @param newFeePercentage The new fee in the format described in `feePercentage`
    function setFeePercentage(uint256 newFeePercentage)
        external
        override
        onlyAdmin
    {
        require(
            newFeePercentage < feePercentage,
            "LimitrVault: can only set a smaller fee"
        );
        uint256 oldPercentage = feePercentage;
        feePercentage = newFeePercentage;
        emit NewFeePercentage(oldPercentage, newFeePercentage);
    }

    // factory and token addresses

    /// @return The registry address
    address public override registry;

    /// @return The first token of the pair
    address public override token0;

    /// @return The second token of the pair
    address public override token1;

    // price listing functions

    /// @return The first price on the order book for the provided `token`
    /// @param token Must be `token0` or `token1`
    function firstPrice(address token) public view override returns (uint256) {
        return _prices[token].first();
    }

    /// @return The last price on the order book for the provided `token`
    /// @param token Must be `token0` or `token1`
    function lastPrice(address token) public view override returns (uint256) {
        return _prices[token].last();
    }

    /// @return The previous price to the pointer for the provided `token`
    /// @param token Must be `token0` or `token1`
    /// @param current The current price
    function previousPrice(address token, uint256 current)
        public
        view
        override
        returns (uint256)
    {
        return _prices[token].previous(current);
    }

    /// @return The next price to the current for the provided `token`
    /// @param token Must be `token0` or `token1`
    /// @param current The current price
    function nextPrice(address token, uint256 current)
        public
        view
        override
        returns (uint256)
    {
        return _prices[token].next(current);
    }

    /// @return N prices after current for the provided `token`
    /// @param token Must be `token0` or `token1`
    /// @param current The current price
    /// @param n The number of prices to return
    function prices(
        address token,
        uint256 current,
        uint256 n
    ) external view override returns (uint256[] memory) {
        SDLL storage priceList = _prices[token];
        uint256 c = current;
        uint256[] memory r = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            c = priceList.next(c);
            if (c == 0) {
                break;
            }
            r[i] = c;
        }
        return r;
    }

    /// @return n price pointers for the provided price for the provided `token`
    /// @param token Must be `token0` or `token1`
    /// @param price The price to insert
    /// @param nPointers The number of pointers to return
    function pricePointers(
        address token,
        uint256 price,
        uint256 nPointers
    ) external view override returns (uint256[] memory) {
        uint256[] memory r = new uint256[](nPointers);
        uint256 c;
        SDLL storage priceList = _prices[token];
        if (_lastOrder[token][price] != 0) {
            c = price;
        } else {
            c = 0;
            while (c < price) {
                c = priceList.next(c);
                if (c == 0) {
                    break;
                }
            }
        }
        for (uint256 i = 0; i < nPointers; i++) {
            c = priceList.previous(c);
            if (c == 0) {
                break;
            }
            r[i] = c;
        }
        return r;
    }

    // orders listing functions

    /// @return The ID of the first order for the provided `token`
    /// @param token Must be `token0` or `token1`
    function firstOrder(address token) public view override returns (uint256) {
        return _orders[token].first();
    }

    /// @return The ID of the last order for the provided `token`
    /// @param token Must be `token0` or `token1`
    function lastOrder(address token) public view override returns (uint256) {
        return _orders[token].last();
    }

    /// @return The ID of the previous order for the provided `token`
    /// @param token Must be `token0` or `token1`
    /// @param currentID Pointer to the current order
    function previousOrder(address token, uint256 currentID)
        public
        view
        override
        returns (uint256)
    {
        return _orders[token].previous(currentID);
    }

    /// @return The ID of the next order for the provided `token`
    /// @param token Must be `token0` or `token1`
    /// @param currentID Pointer to the current order
    function nextOrder(address token, uint256 currentID)
        public
        view
        override
        returns (uint256)
    {
        return _orders[token].next(currentID);
    }

    /// @notice Returns `n` order IDs from the `current` for the provided `token`
    /// @param token Must be `token0` or `token1`
    /// @param current The current ID
    /// @param n The number of IDs to return
    function orders(
        address token,
        uint256 current,
        uint256 n
    ) external view override returns (uint256[] memory) {
        uint256 c = current;
        uint256[] memory r = new uint256[](n);
        DLL storage orderList = _orders[token];
        for (uint256 i = 0; i < n; i++) {
            c = orderList.next(c);
            if (c == 0) {
                break;
            }
            r[i] = c;
        }
        return r;
    }

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
        override
        returns (
            uint256[] memory id,
            uint256[] memory price,
            uint256[] memory amount,
            address[] memory trader
        )
    {
        uint256 c = current;
        id = new uint256[](n);
        price = new uint256[](n);
        amount = new uint256[](n);
        trader = new address[](n);
        for (uint256 i = 0; i < n; i++) {
            c = _orders[token].next(c);
            if (c == 0) {
                break;
            }
            id[i] = c;
            Order memory t = orderInfo[token][c];
            price[i] = t.price;
            amount[i] = t.amount;
            trader[i] = t.trader;
        }
    }

    /// @return Returns the token for sale of the provided `orderID`
    /// @param orderID The order ID
    function orderToken(uint256 orderID)
        public
        view
        override
        returns (address)
    {
        return
            orderInfo[token0][orderID].trader != address(0) ? token0 : token1;
    }

    /// @notice Returns the order data
    mapping(address => mapping(uint256 => Order)) public override orderInfo;

    /// @return The last assigned order ID
    uint256 public override lastID;

    /// liquidity functions

    /// @return Return the available liquidity at a particular price, for the provided `token`
    mapping(address => mapping(uint256 => uint256))
        public
        override liquidityByPrice;

    /// @notice Return the available liquidity until `maxPrice`
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
        override
        returns (uint256[] memory price, uint256[] memory priceLiquidity)
    {
        uint256 c = current;
        price = new uint256[](n);
        priceLiquidity = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            c = _prices[token].next(c);
            if (c == 0) {
                break;
            }
            price[i] = c;
            priceLiquidity[i] = liquidityByPrice[token][c];
        }
    }

    /// @return The total liquidity available for the provided `token`
    mapping(address => uint256) public override totalLiquidity;

    // trader order listing functions

    /// @return The ID of the first order of the `trader` for the provided `token`
    /// @param token The token to list
    /// @param trader The trader
    function firstTraderOrder(address token, address trader)
        public
        view
        override
        returns (uint256)
    {
        return _traderOrders[token][trader].first();
    }

    /// @return The ID of the last order of the `trader` for the provided `token`
    /// @param token The token to list
    /// @param trader The trader
    function lastTraderOrder(address token, address trader)
        public
        view
        override
        returns (uint256)
    {
        return _traderOrders[token][trader].last();
    }

    /// @return The ID of the previous order of the `trader` for the provided `token`
    /// @param token The token to list
    /// @param trader The trader
    /// @param currentID Pointer to a trade
    function previousTraderOrder(
        address token,
        address trader,
        uint256 currentID
    ) public view override returns (uint256) {
        return _traderOrders[token][trader].previous(currentID);
    }

    /// @return The ID of the next order of the `trader` for the provided `token`
    /// @param token The token to list
    /// @param trader The trader
    /// @param currentID Pointer to a trade
    function nextTraderOrder(
        address token,
        address trader,
        uint256 currentID
    ) public view override returns (uint256) {
        return _traderOrders[token][trader].next(currentID);
    }

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
    ) external view override returns (uint256[] memory) {
        uint256 c = current;
        uint256[] memory r = new uint256[](n);
        DLL storage traderOrderList = _traderOrders[token][trader];
        for (uint256 i = 0; i < n; i++) {
            c = traderOrderList.next(c);
            if (c == 0) {
                break;
            }
            r[i] = c;
        }
        return r;
    }

    // fee calculation functions

    /// @return The amount corresponding to the fee from a provided `amount`
    /// @param amount The traded amount
    function feeOf(uint256 amount) public view override returns (uint256) {
        if (feePercentage == 0 || amount == 0) {
            return 0;
        }
        return (amount * feePercentage) / 10**18;
    }

    /// @return The amount to collect as fee for the provided `amount`
    /// @param amount The amount traded
    function feeFor(uint256 amount) public view override returns (uint256) {
        if (feePercentage == 0 || amount == 0) {
            return 0;
        }
        return (amount * feePercentage) / (10**18 - feePercentage);
    }

    /// @return The amount available after collecting the fee from the provided `amount`
    /// @param amount The total amount
    function withoutFee(uint256 amount) public view override returns (uint256) {
        return amount - feeOf(amount);
    }

    /// @return The provided `amount` with added fee
    /// @param amount The amount without fee
    function withFee(uint256 amount) public view override returns (uint256) {
        return amount + feeFor(amount);
    }

    // trade amounts calculation functions

    /// @return The cost of `amountOut` of `wantToken` at the provided `price`.
    ///         Fees not included
    /// @param wantToken The token to receive
    /// @param amountOut The amount of `wantToken` to receive
    function costAtPrice(
        address wantToken,
        uint256 amountOut,
        uint256 price
    ) public view override returns (uint256) {
        if (price == 0 || amountOut == 0) {
            return 0;
        }
        return (price * amountOut) / _oneToken[wantToken];
    }

    /// @return The return of trading `amountIn` for `wantToken` at then provided
    ///         `price`. Fees not included.
    /// @param wantToken The token to receive
    /// @param amountIn The cost
    /// @param price The trade price
    function returnAtPrice(
        address wantToken,
        uint256 amountIn,
        uint256 price
    ) public view override returns (uint256) {
        if (price == 0 || amountIn == 0) {
            return 0;
        }
        return (_oneToken[wantToken] * amountIn) / price;
    }

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
    ) public view override returns (uint256 amountIn, uint256 amountOut) {
        return
            _returnAtMaxPrice(
                wantToken,
                costAtPrice(wantToken, maxAmountOut, maxPrice),
                maxPrice
            );
    }

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
    ) public view override returns (uint256 amountIn, uint256 amountOut) {
        return _returnAtMaxPrice(wantToken, maxAmountIn, maxPrice);
    }

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
    ) public override returns (uint256) {
        (uint256 orderID, bool created) = _newOrderWithPointer(
            gotToken,
            price,
            amount,
            trader,
            deadline,
            0
        );
        require(created, "LimitrVault: can't create new order");
        return orderID;
    }

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
    ) public override returns (uint256) {
        (uint256 orderID, bool created) = _newOrderWithPointer(
            gotToken,
            price,
            amount,
            trader,
            deadline,
            pointer
        );
        require(created, "LimitrVault: can't create new order");
        return orderID;
    }

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
    ) public override returns (uint256) {
        for (uint256 i = 0; i < pointers.length; i++) {
            (uint256 orderID, bool created) = _newOrderWithPointer(
                gotToken,
                price,
                amount,
                trader,
                deadline,
                pointers[i]
            );
            if (created) {
                return orderID;
            }
        }
        revert("LimitrVault: can't create new order");
    }

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
    ) public override withinDeadline(deadline) senderAllowed(orderID) lock {
        address t = orderToken(orderID);
        Order memory _order = orderInfo[t][orderID];
        uint256 _amount = amount != 0 ? amount : _order.amount;
        _cancelOrder(t, orderID, amount);
        _withdrawToken(t, receiver, _amount);
    }

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
    )
        public
        override
        withinDeadline(deadline)
        validToken(wantToken)
        lock
        isTrading
        returns (uint256, uint256)
    {
        return _trade(wantToken, maxPrice, maxAmountIn, receiver, _postTrade);
    }

    // trader balances

    /// @return The trader balance available to withdraw
    mapping(address => mapping(address => uint256))
        public
        override traderBalance;

    /// @notice Withdraw trader balance
    /// @param token Must be `token0` or `token1`
    /// @param to The receiver address
    /// @param amount The amount to withdraw
    function withdraw(
        address token,
        address to,
        uint256 amount
    ) external override lock {
        _withdraw(token, msg.sender, to, amount);
    }

    /// @notice Withdraw on behalf of a trader. Can only be called by the router
    /// @param token Must be `token0` or `token1`
    /// @param trader The trader to handle
    /// @param receiver The receiver of the tokens
    /// @param amount The amount to withdraw
    function withdrawFor(
        address token,
        address trader,
        address receiver,
        uint256 amount
    ) external override {
        address router = ILimitrRegistry(registry).router();
        require(msg.sender == router, "LimitrVault: not the router");
        _withdraw(token, trader, receiver, amount);
    }

    /// @return If an address is allowed to handle a order
    /// @param sender The sender address
    /// @param tokenId The orderID / tokenId
    function isAllowed(address sender, uint256 tokenId)
        public
        view
        override
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        return
            sender == owner ||
            isApprovedForAll[owner][sender] ||
            sender == _approvals[tokenId] ||
            sender == ILimitrRegistry(registry).router();
    }

    /// @return The version of the vault implementation
    function implementationVersion() external pure override returns (uint16) {
        return 1;
    }

    /// @return The address of the vault implementation
    function implementationAddress() external view override returns (address) {
        bytes memory code = address(this).code;
        require(code.length == 51, "LimitrVault: expecting 51 bytes of code");
        uint160 r;
        for (uint256 i = 11; i < 31; i++) {
            r = (r << 8) | uint8(code[i]);
        }
        return address(r);
    }

    // ERC165

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(ILimitrVault).interfaceId;
    }

    // ERC721

    /// @return The number of tokens/orders owned by owner
    mapping(address => uint256) public override balanceOf;

    /// @return If the operator is allowed to manage all tokens/orders of owner
    mapping(address => mapping(address => bool))
        public
        override isApprovedForAll;

    /// @notice Returns the owner of a token/order. The ID must be valid
    /// @param tokenId The token/order ID
    /// @return owner The owner of a token/order. The ID must be valid
    function ownerOf(uint256 tokenId)
        public
        view
        override
        ERC721TokenMustExist(tokenId)
        returns (address)
    {
        address t = orderInfo[token0][tokenId].trader;
        if (t != address(0)) {
            return t;
        }
        return orderInfo[token1][tokenId].trader;
    }

    /// @notice Approves an account to transfer the token/order with the given ID.
    ///         The token/order must exists
    /// @param to The address of the account to approve
    /// @param tokenId the token/order
    function approve(address to, uint256 tokenId) public override lock {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        bool allowed = msg.sender == owner ||
            isApprovedForAll[owner][msg.sender];
        require(allowed, "ERC721: not the owner or operator");
        _ERC721Approve(owner, to, tokenId);
    }

    /// @notice Returns the address approved to transfer the token/order with the given ID
    ///         The token/order must exists
    /// @param tokenId the token/order
    /// @return The address approved to transfer the token/order with the given ID
    function getApproved(uint256 tokenId)
        public
        view
        override
        ERC721TokenMustExist(tokenId)
        returns (address)
    {
        return _approvals[tokenId];
    }

    /// @notice Approves or removes the operator for the caller tokens/orders
    /// @param operator The operator to be approved/removed
    /// @param approved Set true to approve, false to remove
    function setApprovalForAll(address operator, bool approved)
        public
        override
        lock
    {
        require(msg.sender != operator, "ERC721: can't approve yourself");
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Transfers the ownership of the token/order. Can be called by the owner
    ///         or approved operators
    /// @param from The token/order owner
    /// @param to The new owner
    /// @param tokenId The token/order ID to transfer
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _ERC721Transfer(from, to, tokenId);
    }

    /// @notice Safely transfers the token/order. It checks contract recipients are aware
    ///         of the ERC721 protocol to prevent tokens from being forever locked.
    /// @param from The token/order owner
    /// @param to the new owner
    /// @param tokenId The token/order ID to transfer
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @notice Safely transfers the token/order. It checks contract recipients are aware
    ///         of the ERC721 protocol to prevent tokens from being forever locked.
    /// @param from The token/order owner
    /// @param to the new owner
    /// @param tokenId The token/order ID to transfer
    /// @param _data The data to be passed to the onERC721Received() call
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        _ERC721SafeTransfer(from, to, tokenId, _data);
    }

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
        override
        validToken(profitToken)
        returns (
            uint256 profitIn,
            uint256 profitOut,
            uint256 otherOut
        )
    {
        address other = _otherToken(profitToken);
        uint256 buyOut;
        (profitIn, buyOut) = _returnAtMaxPrice(
            other,
            withoutFee(maxAmountIn),
            maxPrice != 0 ? maxPrice : _prices[other].last()
        );
        profitIn = withFee(profitIn);
        uint256 dumpIn;
        (dumpIn, profitOut) = _returnAtMaxPrice(
            profitToken,
            withoutFee(buyOut),
            _prices[profitToken].last()
        );
        dumpIn = withFee(dumpIn);
        otherOut = buyOut - dumpIn;
    }

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
    )
        external
        override
        withinDeadline(deadline)
        validToken(profitToken)
        lock
        isTrading
        returns (uint256 profitAmount, uint256 otherAmount)
    {
        address otherToken = _otherToken(profitToken);
        // borrow borrowedProfitIn and buy otherOut with it
        uint256 p = maxPrice != 0 ? maxPrice : _prices[otherToken].last();
        (uint256 borrowedProfitIn, uint256 otherOut) = _trade(
            otherToken,
            p,
            maxBorrow,
            receiver,
            _postBorrowTrade
        );
        // borrow borrowedOtherIn and buy profitOut with it
        p = _prices[profitToken].last();
        (uint256 borrowedOtherIn, uint256 profitOut) = _trade(
            profitToken,
            p,
            otherOut,
            receiver,
            _postBorrowTrade
        );
        require(
            profitOut > borrowedProfitIn,
            "LimitrVault: no arbitrage profit"
        );
        profitAmount = profitOut - borrowedProfitIn;
        otherAmount = otherOut - borrowedOtherIn;
        _withdrawToken(profitToken, receiver, profitAmount);
        _withdrawToken(otherToken, receiver, otherAmount);
        emit ArbitrageProfitTaken(
            profitToken,
            profitAmount,
            otherAmount,
            receiver
        );
    }

    /// @notice Returns the trading status of the contract
    bool public override isTradingPaused = false;

    /// @notice Pauses trading on the vault. Can only be called by the admin
    function pauseTrading() external override onlyAdmin {
        isTradingPaused = true;
    }

    /// @notice Resumes trading on the vault. Can only be called by the admin
    function resumeTrading() external override onlyAdmin {
        isTradingPaused = false;
    }

    // modifiers

    modifier isTrading() {
        require(isTradingPaused == false, "LimitrVault: trading is paused");
        _;
    }

    modifier validToken(address token) {
        require(
            token == token0 || token == token1,
            "LimitrVault: invalid token"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            msg.sender == ILimitrRegistry(registry).admin(),
            "LimitrVault: only for the admin"
        );
        _;
    }

    modifier withinDeadline(uint256 deadline) {
        if (deadline > 0) {
            require(
                block.timestamp <= deadline,
                "LimitrVault: past the deadline"
            );
        }
        _;
    }

    bool internal _locked;

    modifier lock() {
        require(!_locked, "LimitrVault: already locked");
        _locked = true;
        _;
        _locked = false;
    }

    modifier postExecBalanceCheck(address token) {
        _;
        require(
            IERC20(token).balanceOf(address(this)) >= _expectedBalance[token],
            "LimitrVault:  Deflationary token"
        );
    }

    modifier senderAllowed(uint256 tokenId) {
        require(
            isAllowed(msg.sender, tokenId),
            "ERC721: not the owner, approved or operator"
        );
        _;
    }

    modifier ERC721TokenMustExist(uint256 tokenId) {
        require(
            orderToken(tokenId) != address(0),
            "ERC721: token does not exist"
        );
        _;
    }

    // internal variables and methods

    mapping(address => uint256) internal _oneToken;

    mapping(address => uint256) internal _expectedBalance;

    mapping(address => mapping(uint256 => uint256)) internal _lastOrder;

    mapping(address => SDLL) internal _prices;

    mapping(address => DLL) internal _orders;

    mapping(address => mapping(address => DLL)) internal _traderOrders;

    mapping(uint256 => address) private _approvals;

    function _withdraw(
        address token,
        address sender,
        address to,
        uint256 amount
    ) internal {
        require(
            traderBalance[token][sender] >= amount,
            "LimitrVault: can't withdraw(): not enough balance"
        );
        if (amount == 0) {
            amount = traderBalance[token][sender];
        }
        traderBalance[token][sender] -= amount;
        _withdrawToken(token, to, amount);
        emit TokenWithdraw(token, sender, to, amount);
    }

    function _tokenTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool ok = IERC20(token).transfer(to, amount);
        require(ok, "LimitrVault: can't transfer()");
    }

    function _tokenTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool ok = IERC20(token).transferFrom(from, to, amount);
        require(ok, "LimitrVault: can't transferFrom()");
    }

    /// @dev withdraw a token, accounting for the balance
    function _withdrawToken(
        address token,
        address to,
        uint256 amount
    ) internal postExecBalanceCheck(token) {
        _expectedBalance[token] -= amount;
        _tokenTransfer(token, to, amount);
    }

    /// @dev take a token deposit from a user
    function _depositToken(
        address token,
        address from,
        uint256 amount
    ) internal postExecBalanceCheck(token) {
        _expectedBalance[token] += amount;
        _tokenTransferFrom(token, from, address(this), amount);
    }

    /// @dev increment lastID and return it
    function _nextID() internal returns (uint256) {
        lastID++;
        return lastID;
    }

    /// @dev Creates a new order using the provided pointer
    /// @param gotToken The token to trade in
    /// @param price The trade price
    /// @param amount The amount to trade
    /// @param trader The owner of the order
    /// @param deadline Validity deadline
    /// @return orderID The order ID
    /// @return created True on success
    function _newOrderWithPointer(
        address gotToken,
        uint256 price,
        uint256 amount,
        address trader,
        uint256 deadline,
        uint256 pointer
    )
        internal
        withinDeadline(deadline)
        validToken(gotToken)
        lock
        isTrading
        returns (uint256 orderID, bool created)
    {
        (orderID, created) = _createNewOrder(
            gotToken,
            price,
            amount,
            trader,
            pointer
        );
        if (!created) {
            return (0, false);
        }
        _depositToken(gotToken, msg.sender, amount);
        emit OrderCreated(gotToken, orderID, trader, price, amount);
    }

    function _createNewOrder(
        address gotToken,
        uint256 price,
        uint256 amount,
        address trader,
        uint256 pointer
    ) internal returns (uint256, bool) {
        require(trader != address(0), "LimitrVault: zero address not allowed");
        require(amount > 0, "LimitrVault: zero amount not allowed");
        require(price > 0, "LimitrVault: zero price not allowed");
        // validate pointer
        if (pointer != 0 && _lastOrder[gotToken][pointer] == 0) {
            return (0, false);
        }
        // save the order
        uint256 orderID = _nextID();
        orderInfo[gotToken][orderID] = Order(price, amount, trader);
        // insert order into the order list and insert the price in the
        // price list if necessary
        if (!_insertOrder(gotToken, orderID, price, pointer)) {
            return (0, false);
        }
        // insert order in the trader orders
        _traderOrders[gotToken][trader].insertEnd(orderID);
        // update erc721 balance
        balanceOf[trader] += 1;
        emit Transfer(address(0), trader, orderID);
        // update the liquidity info
        liquidityByPrice[gotToken][price] += amount;
        totalLiquidity[gotToken] += amount;
        return (orderID, true);
    }

    function _insertOrder(
        address gotToken,
        uint256 orderID,
        uint256 price,
        uint256 pointer
    ) internal returns (bool) {
        mapping(uint256 => uint256) storage _last = _lastOrder[gotToken];
        // the insert point is after the last order at the same price
        uint256 _prevID = _last[price];
        if (_prevID == 0) {
            // price doesn't exist. insert it
            if (pointer != 0 && _last[pointer] == 0) {
                return false;
            }
            SDLL storage priceList = _prices[gotToken];
            if (!priceList.insertWithPointer(price, pointer)) {
                return false;
            }
            _prevID = _last[priceList.previous(price)];
        }
        _orders[gotToken].insertAfter(orderID, _prevID);
        _last[price] = orderID;
        return true;
    }

    function _cancelOrder(
        address gotToken,
        uint256 orderID,
        uint256 amount
    ) internal {
        Order memory _order = orderInfo[gotToken][orderID];
        // can only cancel up to the amount of the order
        require(
            _order.amount >= amount,
            "LimitrVault: can't cancel a bigger amount than the order size"
        );
        // 0 means full amount
        uint256 _amount = amount != 0 ? amount : _order.amount;
        uint256 remAmount = _order.amount - _amount;
        if (remAmount == 0) {
            // remove the order from the list. remove the price also if no
            // other order exists at the same price
            _removeOrder(gotToken, orderID);
        } else {
            // update the available amount
            orderInfo[gotToken][orderID].amount = remAmount;
        }
        // update the available liquidity info
        liquidityByPrice[gotToken][_order.price] -= _amount;
        totalLiquidity[gotToken] -= _amount;
        emit OrderCanceled(gotToken, orderID, _order.price, _amount);
    }

    /// @dev remove an order
    function _removeOrder(address gotToken, uint256 orderID) internal {
        uint256 orderPrice = orderInfo[gotToken][orderID].price;
        address orderTrader = orderInfo[gotToken][orderID].trader;
        DLL storage orderList = _orders[gotToken];
        // find previous order
        uint256 _prevID = orderList.previous(orderID);
        // is the previous order at the same price?
        bool prevPriceNotEqual = orderPrice !=
            orderInfo[gotToken][_prevID].price;
        // single order at the price
        bool onlyOrderAtPrice = prevPriceNotEqual &&
            orderPrice != orderInfo[gotToken][orderList.next(orderID)].price;
        // delete the order and remove it from the list
        delete orderInfo[gotToken][orderID];
        orderList.remove(orderID);
        // update _last
        mapping(uint256 => uint256) storage _last = _lastOrder[gotToken];
        if (_last[orderPrice] == orderID) {
            if (prevPriceNotEqual) {
                delete _last[orderPrice];
            } else {
                _last[orderPrice] = _prevID;
            }
        }
        if (onlyOrderAtPrice) {
            // remove price
            _prices[gotToken].remove(orderPrice);
        }
        // update trader orders and ERC721 balance
        _traderOrders[gotToken][orderTrader].remove(orderID);
        balanceOf[orderTrader] -= 1;
        emit Transfer(orderTrader, address(0), orderID);
    }

    function _ERC721SafeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _ERC721Transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _ERC721Transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal lock ERC721TokenMustExist(tokenId) senderAllowed(tokenId) {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");
        // reset approval for the order
        _approvals[tokenId] = address(0);
        // update balances
        balanceOf[from] -= 1;
        balanceOf[to] += 1;
        // update order
        address t = orderToken(tokenId);
        orderInfo[t][tokenId].trader = to;
        // update trader orders
        _traderOrders[t][from].remove(tokenId);
        _traderOrders[t][to].insertEnd(tokenId);
        emit Transfer(from, to, tokenId);
    }

    function _ERC721Approve(
        address owner,
        address to,
        uint256 tokenId
    ) internal {
        _approvals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.code.length == 0) {
            return true;
        }
        try
            IERC721Receiver(to).onERC721Received(
                msg.sender,
                from,
                tokenId,
                _data
            )
        returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch {
            return false;
        }
    }

    function _returnAtMaxPrice(
        address wantToken,
        uint256 maxAmountIn,
        uint256 maxPrice
    ) internal view returns (uint256 amountIn, uint256 amountOut) {
        uint256 orderID = 0;
        Order memory _order;
        DLL storage orderList = _orders[wantToken];
        while (true) {
            orderID = orderList.next(orderID);
            if (orderID == 0) {
                break;
            }
            _order = orderInfo[wantToken][orderID];
            if (_order.trader == address(0)) {
                break;
            }
            if (_order.price > maxPrice) {
                break;
            }
            uint256 buyAmount = returnAtPrice(
                wantToken,
                maxAmountIn,
                _order.price
            );
            if (buyAmount > _order.amount) {
                buyAmount = _order.amount;
            }
            amountOut += buyAmount;
            uint256 price = costAtPrice(wantToken, buyAmount, _order.price);
            amountIn += price;
            maxAmountIn -= price;
            if (maxAmountIn == 0) {
                break;
            }
        }
    }

    function _otherToken(address token) internal view returns (address) {
        return token == token0 ? token1 : token0;
    }

    function _tradeFirstOrder(
        address wantToken,
        address gotToken,
        TradeHandler memory trade,
        uint256 maxPrice
    ) internal returns (bool) {
        // get the order ID
        uint256 orderID = _orders[wantToken].first();
        if (orderID == 0) {
            return false;
        }
        // get the order
        Order memory _order = orderInfo[wantToken][orderID];
        if (_order.price > maxPrice) {
            return false;
        }
        uint256 buyAmount = returnAtPrice(
            wantToken,
            trade.availableAmountIn,
            _order.price
        );
        if (buyAmount > _order.amount) {
            buyAmount = _order.amount;
        }
        uint256 cost = costAtPrice(wantToken, buyAmount, _order.price);
        // update order owner balance
        traderBalance[gotToken][_order.trader] += cost;
        // update liquidity info
        liquidityByPrice[wantToken][_order.price] -= buyAmount;
        totalLiquidity[wantToken] -= buyAmount;
        // update order
        _order.amount -= buyAmount;
        if (_order.amount == 0) {
            _removeOrder(wantToken, orderID);
        } else {
            orderInfo[wantToken][orderID].amount -= buyAmount;
        }
        // update trade data
        trade.update(cost, buyAmount);
        emit OrderTaken(
            wantToken,
            orderID,
            _order.trader,
            buyAmount,
            _order.price
        );
        if (_order.amount != 0) {
            return false;
        }
        return true;
    }

    function _trade(
        address wantToken,
        uint256 price,
        uint256 maxAmountIn,
        address receiver,
        function(
            address,
            address,
            TradeHandler memory,
            address
        ) _postTradeHandler
    ) internal returns (uint256 amountIn, uint256 amountOut) {
        TradeHandler memory trade = TradeHandler(0, 0, withoutFee(maxAmountIn));
        address gotToken = _otherToken(wantToken);
        while (trade.availableAmountIn > 0) {
            if (!_tradeFirstOrder(wantToken, gotToken, trade, price)) {
                break;
            }
        }
        require(
            trade.amountIn > 0 && trade.amountOut > 0,
            "LimitrVault: no trade"
        );
        _postTradeHandler(wantToken, gotToken, trade, receiver);
        return (withFee(trade.amountIn), trade.amountOut);
    }

    // deposit payment
    // collect fee
    // withdraw purchased tokens
    function _postTrade(
        address wantToken,
        address gotToken,
        TradeHandler memory trade,
        address receiver
    ) internal {
        // deposit payment
        _depositToken(gotToken, msg.sender, trade.amountIn);
        // calculate fee
        uint256 fee = feeFor(trade.amountIn);
        // collect fee
        _tokenTransferFrom(
            gotToken,
            msg.sender,
            ILimitrRegistry(registry).feeReceiver(),
            fee
        );
        emit FeeCollected(gotToken, fee);
        // transfer purchased tokens
        _withdrawToken(wantToken, receiver, trade.amountOut);
    }

    // only collect fee from the vault
    function _postBorrowTrade(
        address,
        address gotToken,
        TradeHandler memory trade,
        address
    ) internal {
        // calculate fee
        uint256 fee = feeFor(trade.amountIn);
        // collect fee
        _withdrawToken(gotToken, ILimitrRegistry(registry).feeReceiver(), fee);
        emit FeeCollected(gotToken, fee);
    }
}