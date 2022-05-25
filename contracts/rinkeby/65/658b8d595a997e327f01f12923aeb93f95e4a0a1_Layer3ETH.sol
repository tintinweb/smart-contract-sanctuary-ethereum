/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IStargateReceiver {
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory payload
    ) external;
}

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

pragma abicoder v2;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    function unwrapWETH9(uint256 amountMinimum, address recipient)
        external
        payable;

    function refundEth() external payable;
}

abstract contract MarketplaceEventsAndErrors {
    /// @dev Event is fired when a listing is closed and token is sold on the marketplace.
    /// @param listingId The id of the listing.
    /// @param chainId The chain id that action took place.
    /// @param seller The seller and old owner of the token.
    /// @param buyer The buyer and new owner of the token.
    /// @param collectionAddress The address that the token is from.
    /// @param tokenId The id of the token.
    /// @param price The price of the listing.
    /// @param amountReceived The amount of tokens received.
    event ItemSold(
        uint256 listingId,
        uint16 chainId,
        address indexed seller,
        address indexed buyer,
        address collectionAddress,
        uint256 tokenId,
        uint256 price,
        uint256 amountReceived
    );

    /// @dev Event is fired when a listing is opened.
    /// @param listingId The id of the listing.
    /// @param chainId The chain id that action took place.
    /// @param seller The seller and old owner of the token.
    /// @param collectionAddress The address that the token is from.
    /// @param tokenId The id of the token.
    /// @param price The price of the listing.
    event ItemListed(
        uint256 listingId,
        uint16 chainId,
        address indexed seller,
        address collectionAddress,
        uint256 tokenId,
        uint256 price,
        bool isCrossChain
    );

    /// @dev Event is fired when a listing is delisted.
    /// @param listingId The id of the listing.
    /// @param chainId The chain id that action took place.
    /// @param seller The seller and lister of the token.
    event ItemDelisted(
        uint256 listingId,
        uint16 chainId,
        address indexed seller
    );

    /// @dev Event is fired when execute buy fails and buyer is refunded.
    /// @param listingId The id of the listing.
    /// @param chainId The chain id that action took place.
    /// @param buyer The buyer and receiver of the refund.
    /// @param price The price of the item.
    /// @param refundAmount The amount refunded to buyer in stable.
    event SwapFailRefund(
        uint256 listingId,
        uint16 chainId,
        address indexed buyer,
        uint256 price,
        uint256 refundAmount
    );

    /// @dev Event is fired when the amount after passing through Stargate
    /// and local DEX is insufficient to make the purchase. The buyer
    /// will then receive a refund in the native token on the chain
    /// the listing is live on.
    /// @param listingId The id of the listing.
    /// @param chainId The chain id that action took place.
    /// @param buyer The buyer and receiver of the refund.
    /// @param price The price of the item.
    /// @param refundAmount The amount refunded to buyer in native tokens.
    event PriceFailRefund(
        uint256 listingId,
        uint16 chainId,
        address indexed buyer,
        uint256 price,
        uint256 refundAmount
    );

    /// @dev Event is fired when the price of a listing is changed.
    /// @param listingId The id of the listing.
    /// @param chainId The chain id that action took place.
    /// @param seller The seller and old owner of the token.
    /// @param oldPrice The price the listing is changed from.
    /// @param newPrice The price the listing is changed to.
    event PriceChanged(
        uint256 listingId,
        uint16 chainId,
        address indexed seller,
        uint256 oldPrice,
        uint256 newPrice
    );

    /// @dev Revert when message is received from a non-authorized stargateRouter address.
    error NotFromRouter();

    /// @dev Revert when user is attempting an action that requires token ownership.
    error NotTokenOwner();

    /// @dev Revert when user is attempting an action that requires listing ownership.
    error NotListingOwner();

    /// @dev Revert when user is attempting an action that requires approval of the contract address.
    /// associated with the token
    error NotApprovedNFT();

    /// @dev Revert when action is attempted not from the contract.
    error NotFromContract();

    /// @dev Revert when funds fail to transfer to buyer.
    error FundsTransferFailure();

    /// @dev Revert when user is attempting to edit a listing that is non-existent.
    error NonexistentListing();

    /// @dev Revert when user is attempting an action that requires listing to be active locally.
    error NotActiveLocalListing();

    /// @dev Revert when user is attempting an action that requires listing to be active locally.
    error NotActiveGlobalListing();

    /// @dev Revert when user is attempting to purchase a listing for a price that is less than the current price.
    error InsufficientFunds();

    /// @dev Revert when user is attempting to purchase a listing for a price that is greater than the current price.
    error ExcessFunds();
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/// @title L3NFT
/// @author CrossChain Labs (Bradley Woolf) and Alan Le
/// @notice Cross Chain NFT Marketplace built on LayerZero
/// @dev Lives on Ethereum mainnet
contract Layer3ETH is IStargateReceiver, Ownable, MarketplaceEventsAndErrors {
    /// @notice Stargate router contract
    IStargateRouter public immutable stargateRouter;

    /// @notice DEX contract for current chain (ex. Uniswap/TraderJoe)
    ISwapRouter public immutable dexRouter;

    /// @notice Wrapped native token contract for current chain, used for wrapping and unwrapping
    IWETH9 public immutable wrappedNative;

    /// @notice USDC contract
    IERC20 public immutable USDC;

    /// @notice Index for current listing
    uint256 public currentListingIndex;

    /// @notice Current chain id
    uint16 public immutable currentChainId;

    // TODO: pack/optimize
    uint256 public intConstant = 10000;
    uint256 public fee = 200;

    /// @notice Maps chain ids to corresponding marketplace contract
    mapping(uint16 => bytes) public marketplaceAddresses;

    /// @notice Maps collection contract addresses to approval status
    mapping(address => bool) public approvedNFTs;

    /// @notice Maps key composed of contract address and token id to item listings
    mapping(bytes32 => ItemListing) public sellerListings;

    /// @notice Struct composed of details used for marketplace listings
    /// @param lister The address of the lister
    /// @param collectionAddress The address of the collection contract
    /// @param tokenId The token id of the NFT
    /// @param price The price of the NFT
    /// @param active The status of the listing
    struct ItemListing {
        uint256 listingId;
        address lister;
        address collectionAddress;
        uint256 tokenId;
        uint256 price;
        ListingStatus status;
    }

    /// @notice Defines possible states for the listing
    /// @param INACTIVE The listing is inactive and unable to be purchased
    /// @param ACTIVE_LOCAL The listing is active and able to be purchased only locally
    /// @param ACTIVE_CROSSCHAIN The listing is active and able to be purchased crosschain
    enum ListingStatus {
        INACTIVE,
        ACTIVE_LOCAL,
        ACTIVE_CROSSCHAIN
    }

    constructor(
        uint16 _currentChainId,
        address _stargateRouter,
        address _dexRouter,
        address _usdcAddress,
        address _wrappedNative
    ) {
        currentChainId = _currentChainId;
        stargateRouter = IStargateRouter(_stargateRouter);
        dexRouter = ISwapRouter(_dexRouter);
        USDC = IERC20(_usdcAddress);
        wrappedNative = IWETH9(_wrappedNative);
    }

    modifier onlyContract() {
        if (msg.sender != address(this)) revert NotFromContract();
        _;
    }

    /// @notice Restricts action to only the owner of the token
    /// @param collectionAddress The address of the collection contract
    /// @param tokenId The token id of the item
    modifier onlyTokenOwner(address collectionAddress, uint256 tokenId) {
        if (IERC721(collectionAddress).ownerOf(tokenId) != msg.sender)
            revert NotTokenOwner();
        _;
    }

    /// @notice Processes listing purchases initiated from cross-chain through Stargate router
    /// @param token Address of the native stable received (ex. USDC)
    /// @param amountLD Amount of token received from the router
    /// @param payload Byte data composed of seller listing key and address to receive NFT
    function sgReceive(
        uint16, /* chainId */
        bytes memory, /* srcAddress */
        uint256, /* nonce */
        address token,
        uint256 amountLD,
        bytes memory payload
    ) external override {
        // receive the message from stargate
        if (msg.sender != address(stargateRouter)) revert NotFromRouter();

        // decode the payload from stargate
        (address collectionAddress, uint256 tokenId, address toAddress) = abi
            .decode(payload, (address, uint256, address));

        // get item listing
        ItemListing memory listing = sellerListings[
            keccak256(abi.encodePacked(collectionAddress, tokenId))
        ];

        /*We use try/catch so trasaction does not revert*/
        try
            this._executeBuy(
                amountLD,
                listing,
                toAddress,
                collectionAddress,
                tokenId
            )
        {
            //do nothing
        } catch {
            // if buy fails, refund the buyer in stablecoin: "we swapped it to stables for you"
            USDC.transfer(toAddress, amountLD); //refund buyer USDC if buy fails
            emit SwapFailRefund(
                listing.listingId,
                currentChainId,
                toAddress,
                listing.price,
                amountLD
            );
        }
    }

    /// @notice Internal function used to execute a buy originating from cross-chain through Stargate router
    /// @param amount Amount of stables to swap for wrapped native
    /// @param listing The listing of the NFT
    /// @param buyer The address to receive the NFT
    /// @param collectionAddress The address of the collection contract
    /// @param tokenId The token id of the NFT
    function _executeBuy(
        uint256 amount,
        ItemListing calldata listing,
        address buyer,
        address collectionAddress,
        uint256 tokenId
    ) external onlyContract {
        if (listing.status != ListingStatus.ACTIVE_CROSSCHAIN)
            revert NotActiveGlobalListing();

        // swap from usdc to native wrapped currency
        // TODO: figure out where/when/how to unnwrap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(USDC),
                tokenOut: address(wrappedNative),
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        uint256 amountOut = dexRouter.exactInputSingle(params);

        // TODO: 1% tolerance? (30bps + 6bps + 30bps = 66bps, where does rest come from?)
        // confirmed 994009006764002799, so approx 60 bps accounted for

        uint256 listingPriceWithTolerance = listing.price -
            ((listing.price * 100) / intConstant);

        // if you dont get enough back, you send the buyer their eth back (means they didnt send enough money)
        // FIXME: after swapping through Uniswap result is always less than price because of 30bps fee deduction
        // amountOut + fees? (seller incurs fees if success, buyer if fail)
        if (amountOut < listingPriceWithTolerance) {
            // refund the buyer in full with native token
            // dexRouter.unwrapWETH9(amountOut, buyer);
            _unwrapNative(amountOut, buyer);

            emit PriceFailRefund(
                listing.listingId,
                currentChainId,
                buyer,
                listing.price,
                amountOut
            );
        } else {
            // keep marketplace fees in wrapped native
            uint256 sellerFee = (amountOut * fee) / intConstant;
            amountOut = amountOut - sellerFee;

            // pay seller, transfer owner, delist nft
            // TODO: handle potential error case
            _unwrapNative(amountOut, listing.lister); // pay the seller

            IERC721(collectionAddress).transferFrom(
                listing.lister,
                buyer,
                tokenId
            );
            _delist(collectionAddress, tokenId);

            emit ItemSold(
                listing.listingId,
                currentChainId,
                listing.lister,
                buyer,
                collectionAddress,
                tokenId,
                listing.price,
                amountOut
            );
        }
    }

    function _unwrapNative(uint256 amount, address recipient) internal {
        uint256 balance = wrappedNative.balanceOf(address(this));
        require(balance >= amount, "Insufficient wrapped native");

        if (balance > 0) {
            wrappedNative.withdraw(amount);
            (bool success, ) = recipient.call{value: amount}("");
            if (!success) revert FundsTransferFailure();
        }
    }

    /// @notice Purchases NFT from the marketplace on a different chain than the buyer's token
    /// @param chainId The chain id associated with the marketplace to purchase from
    /// @param collectionAddress The address of the collection contract
    /// @param tokenId The token id of the NFT
    /// @param toAddr The address to receive the NFT
    /// @param nativePrice Amount of native token you need in order to buy in the foreign token
    /// (ex. How much ETH you need to buy listing on Avalanche in AVAX?)
    function buyCrosschain(
        uint16 chainId,
        address collectionAddress,
        uint256 tokenId,
        address toAddr,
        uint256 nativePrice
    ) external payable {
        // address of marketplace to buy from
        bytes memory destAddr = marketplaceAddresses[chainId];

        // add some extra gas
        IStargateRouter.lzTxObj memory lzParams = IStargateRouter.lzTxObj(
            500000,
            0,
            "0x"
        );

        // encode the payload
        bytes memory payload = abi.encode(collectionAddress, tokenId, toAddr);

        // estimate fees
        uint256 fee = quoteLayerZeroFee(chainId, payload, lzParams);

        // currently in order to buy crosschain, buyer is forced to take on the messaging costs (confirm logic on this)
        // frontend should tack on the messaging costs from quoteLayerZeroFee to the nativePrice
        if (msg.value < fee + nativePrice) revert InsufficientFunds();
        uint256 amountWithFee = nativePrice + fee;

        // swap to usdc
        uint256 amountStable = _swapForPurchase(nativePrice);

        // TODO: Add a poolId tracker for each chain
        // swap to stargate
        stargateRouter.swap{value: fee}(
            chainId,
            1,
            1,
            payable(msg.sender),
            amountStable,
            0,
            lzParams,
            destAddr,
            payload
        );
    }

    /// @notice Quotes transaction fees to supply to use Stargate
    /// @param chainId The chain id to send the LayerZero message to
    /// @param payload The data supplied to the LayerZero message
    /// @param lzParams Additional configuration to supply to LayerZero
    function quoteLayerZeroFee(
        uint16 chainId,
        bytes memory payload,
        IStargateRouter.lzTxObj memory lzParams
    ) public view returns (uint256) {
        (uint256 fee, ) = stargateRouter.quoteLayerZeroFee(
            chainId,
            1,
            marketplaceAddresses[chainId],
            payload,
            lzParams
        );

        return fee;
    }

    /// @notice Swap native wrapped tokens (ex. WETH) for stables (ex. USDC) using local DEX
    /// @dev Stable used to bridge cross-chain with Stargate
    /// @param amount Amount of native wrapped tokens to swap for stables
    function _swapForPurchase(uint256 amount) internal returns (uint256) {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(wrappedNative),
                tokenOut: address(USDC),
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        dexRouter.exactInputSingle{value: amount}(params);
        return USDC.balanceOf(address(this));
    }

    /// @notice Purchase a same-chain listing in native tokens
    /// @param collectionAddress The address of the collection contract
    /// @param tokenId The token id of the NFT
    function buyLocal(
        address collectionAddress,
        uint256 tokenId,
        address /* toAddr */
    ) external payable {
        ItemListing memory listing = sellerListings[
            keccak256(abi.encodePacked(collectionAddress, tokenId))
        ];
        if (
            listing.status != ListingStatus.ACTIVE_LOCAL &&
            listing.status != ListingStatus.ACTIVE_CROSSCHAIN
        ) revert NotActiveLocalListing();
        if (listing.price > msg.value) revert InsufficientFunds();
        if (listing.price < msg.value) revert ExcessFunds();

        // collect fees
        uint256 listingPriceMinusFee = listing.price -
            (fee * listing.price) /
            intConstant;

        (bool success, ) = listing.lister.call{value: listingPriceMinusFee}("");
        if (!success) revert FundsTransferFailure();

        IERC721(collectionAddress).transferFrom(
            listing.lister,
            msg.sender,
            tokenId
        );
        _delist(collectionAddress, tokenId);
        emit ItemSold(
            listing.listingId,
            currentChainId,
            listing.lister,
            msg.sender,
            collectionAddress,
            tokenId,
            listing.price,
            listingPriceMinusFee
        );
    }

    /// @notice List an NFT for sale
    /// @param collectionAddress The address of the collection contract
    /// @param tokenId The token id of the NFT
    /// @param nativePrice The price of the NFT in native tokens
    function listItem(
        address collectionAddress,
        uint256 tokenId,
        uint256 nativePrice,
        bool isCrossChain
    ) external onlyTokenOwner(collectionAddress, tokenId) {
        if (!approvedNFTs[collectionAddress]) revert NotApprovedNFT();

        bytes32 key = keccak256(abi.encodePacked(collectionAddress, tokenId));
        ItemListing memory listing = ItemListing(
            currentListingIndex,
            msg.sender,
            collectionAddress,
            tokenId,
            nativePrice,
            isCrossChain
                ? ListingStatus.ACTIVE_CROSSCHAIN
                : ListingStatus.ACTIVE_LOCAL
        );
        sellerListings[key] = listing;

        currentListingIndex++;

        emit ItemListed(
            listing.listingId,
            currentChainId,
            msg.sender,
            collectionAddress,
            tokenId,
            nativePrice,
            isCrossChain
        );
    }

    /// @notice Deactivates NFT listing on-chain
    /// @param collectionAddress The address of the collection contract
    /// @param tokenId The token id of the NFT
    function delistItem(address collectionAddress, uint256 tokenId)
        external
        onlyTokenOwner(collectionAddress, tokenId)
    {
        bytes32 key = keccak256(abi.encodePacked(collectionAddress, tokenId));

        // FIXME: compare gas with modifying struct directly
        ItemListing memory listing = sellerListings[key];

        listing.status = ListingStatus.INACTIVE;

        sellerListings[key] = listing;

        emit ItemDelisted(
            listing.listingId,
            currentChainId,
            sellerListings[key].lister
        );
    }

    /// @notice Internal function for deactivating a listing
    function _delist(address collectionAddress, uint256 tokenId) internal {
        bytes32 key = keccak256(abi.encodePacked(collectionAddress, tokenId));
        sellerListings[key].status = ListingStatus.INACTIVE;
    }

    /// @notice Approves routers to spend this contracts USDC balance
    function approveRouters() public onlyOwner {
        USDC.approve(address(stargateRouter), 2**256 - 1);
        USDC.approve(address(dexRouter), 2**256 - 1);
    }

    /// @notice Configures the other marketplace addresses and their respective chain ids
    /// @param chainId The chain id associated with the marketplace
    /// @param marketplaceAddress The address of the marketplace
    function setMarketplace(uint16 chainId, bytes calldata marketplaceAddress)
        external
        onlyOwner
    {
        marketplaceAddresses[chainId] = marketplaceAddress;
    }

    /// @notice Sets the fee for the marketplace
    /// @param newFee New fee for the marketplace
    function setFee(uint256 newFee) external onlyOwner {
        fee = newFee;
    }

    /// @notice Approves an NFT contract, used to curate collections
    /// @param contractAddress The address of the NFT contract
    function addNFTContract(address contractAddress) external onlyOwner {
        approvedNFTs[contractAddress] = true;
    }

    /// @notice Removes approval for an NFT contract, used to curate collections
    /// @param contractAddress The address of the NFT contract
    function removeNFTContract(address contractAddress) external onlyOwner {
        delete approvedNFTs[contractAddress];
    }

    /// @notice Modifies price of an existing listing
    /// @param collectionAddress The address of the collection contract
    /// @param tokenId The token id of the NFT
    /// @param newPrice The new price of the NFT
    function editPrice(
        address collectionAddress,
        uint256 tokenId,
        uint256 newPrice
    ) external onlyTokenOwner(collectionAddress, tokenId) {
        //TODO: should add msg.sender to this to make the hash more secure
        bytes32 key = keccak256(abi.encodePacked(collectionAddress, tokenId));

        ItemListing memory listing = sellerListings[key];

        //TODO: check logic if this is necessary to add
        if (msg.sender != listing.lister) revert NotListingOwner();
        if (sellerListings[key].collectionAddress == address(0))
            revert NonexistentListing();

        uint256 oldPrice = sellerListings[key].price;
        listing.price = newPrice;

        sellerListings[key] = listing;

        emit PriceChanged(
            listing.listingId,
            currentChainId,
            msg.sender,
            oldPrice,
            newPrice
        );
    }

    /// @notice Retrieves listing information for a specific key
    /// @param key The key to get the associated listing for
    function getSellerListings(bytes32 key)
        external
        returns (
            uint256 listingId,
            address lister,
            address collectionAddress,
            uint256 tokenId,
            uint256 price,
            ListingStatus status
        )
    {
        ItemListing memory listing = sellerListings[key];
        listingId = listing.listingId;
        lister = listing.lister;
        collectionAddress = listing.collectionAddress;
        tokenId = listing.tokenId;
        price = listing.price;
        status = listing.status;
    }

    receive() external payable {}
}