/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;
 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
 
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
 
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
 
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
 
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
 
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
 

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
} 

library WethUtils {
    IWETH public constant weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    function isWeth(address token) internal pure returns (bool) {
        return address(weth) == token;
    }

    function wrap(uint256 amount) internal {
        weth.deposit{value: amount}();
    }

    function unwrap(uint256 amount) internal {
        weth.withdraw(amount);
    }

    function transfer(address to, uint256 amount) internal {
        weth.transfer(to, amount);
    }
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;
 
    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }
 
    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }
 
    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }
 
    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }
 
    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }
 
    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
 
    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }
 
    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }
 
    event OwnershipTransferred(address owner);
}

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

interface IV3Pool{
    function slot0() external view returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
    function tickSpacing() external view returns (int24);
    function fee() external view returns (uint24);
    function token0() external view returns (address);
    function token1() external view returns (address);

}
 
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

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
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

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
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

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
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

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
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

 
contract THECOLOSSUS is IERC20, Auth, IERC721Receiver  {
    using SafeMath for uint256;
 
    address WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address public baseToken;	
    address public quoteToken;	
    string constant _name = 'TEST';
    string constant _symbol = 'TEST';
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 30_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply / 800;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) v2Pool;    
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) public BL;
    mapping(address => uint256) _holderLastBuyBlock;

    uint256 liqFee = 1000;
    uint256 devFee = 500;
    uint256 totalFee = 1500;
    uint256 feeDenominator = 10000;
    uint24 public poolFee;
    int24 public posOffset;
    int24 public tickspace;
    address public teamWallet;

 
    ISwapRouter public router;
    INonfungiblePositionManager v3POS = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    IV3Pool pair;
    uint256 launchedAt;
    bool public swapEnabled = true;
    bool public EoAMode = true;
    bool public checktoken;
    bool public pos;

    struct LiqDeposit {
        uint256 tokenID;
        int24 UT;
        int24 LT;
    }
    mapping(uint256 => LiqDeposit) public liqPosition;
    mapping(uint256 => uint256) public addLiqAmounts;

    uint256 public swapThreshold = _totalSupply / 2000; // 0.05%
    bool inSwap;
    bool inTfr;
	modifier swapping() { inSwap = true; _; inSwap = false; }
	
	modifier transferring(address sender, address recipient){
		if(shouldSwapBack(sender, recipient)){ swapBack(); }
		_;
	}
 
    constructor (address _Wallet) Auth(msg.sender) {
        router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        teamWallet = _Wallet;
        isFeeExempt[owner] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[owner] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(0xdEaD)] = true;

        _allowances[address(this)][0xE592427A0AEce92De3Edee1F18E0157C05861564] = uint256(2**256 - 1);
        _allowances[address(this)][address(this)] = uint256(2**256 - 1);
        _allowances[address(this)][0xC36442b4a4522E871399CD717aBDD847Ab11FE88] = uint256(2**256 - 1);
        _allowances[msg.sender][0xC36442b4a4522E871399CD717aBDD847Ab11FE88] = uint256(2**256 - 1);
        _allowances[msg.sender][0xE592427A0AEce92De3Edee1F18E0157C05861564] = uint256(2**256 - 1);

        IERC20(WETH).approve(0xC36442b4a4522E871399CD717aBDD847Ab11FE88,uint256(2**256 - 1));
        IERC20(WETH).approve(0xE592427A0AEce92De3Edee1F18E0157C05861564,uint256(2**256 - 1));

        _balances[owner] = _totalSupply;
        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), owner,  _totalSupply);
    }
 
    receive() external payable { }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
 
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
 
    function getLiqWallRatios() internal{
	    (,int24 tick,,,,,)= pair.slot0();
	    if(checktoken){
            if(pos){
                posTicks(tick);
            } else{
	            negTicks(tick);
            }
	    } else {
	       if(pos){
            posTicks(tick);
            } else{
	        negTicks(tick);
            }
        }
    }

    function liqReorg() internal {
        for (uint256 i = 0; i < 4; ++i) {
            removeFromPrevPos(liqPosition[i].tokenID);
        }
	    getLiqWallRatios();
	    createLiq();
	}

     function reorganiseLiq() external onlyOwner swapping{
        (,int24 tick,,,,,)= pair.slot0();
        posOffset = getOffset(tick);
        liqReorg();
    }

    function reorganiseLiqManual(int24 _LT0, int24 _HT0,int24 _LT1, int24 _HT1,int24 _LT2, int24 _HT2,int24 _LT3, int24 _HT3) external onlyOwner swapping{
        liqPosition[0].LT = _LT0;
        liqPosition[0].UT = _HT0;
        liqPosition[1].LT = _LT1;
        liqPosition[1].UT = _HT1;
        liqPosition[2].LT = _LT2;
        liqPosition[2].UT = _HT2;
        liqPosition[3].LT = _LT3;
        liqPosition[3].UT = _HT3;
        liqReorg();
    }

    function createLiq() internal{
	    uint256 tenth = _balances[address(this)].div(10);
        WethUtils.wrap(address(this).balance);
        addLiqAmounts[0] = IERC20(WETH).balanceOf(address(this));
	    addLiqAmounts[1] = tenth.mul(2);
	    addLiqAmounts[2] = tenth.mul(3);
	    addLiqAmounts[3] = tenth.mul(5);
	    uint256 addToken0Amt;
	    uint256 addToken1Amt;
	    uint256 addToken0AmtSlip;
	    uint256 addToken1AmtSlip;        
	    for (uint256 i = 0; i < 4; ++i) {
            addToken0Amt = 0;
	        addToken1Amt = 0;
            addToken0AmtSlip = 0;
            addToken1AmtSlip = 0;
	        if(checktoken && i > 0){
		        addToken0Amt = addLiqAmounts[i];
	        } else if(checktoken && i == 0){
		        addToken1Amt = addLiqAmounts[i];
	        }
            else if(!checktoken && i == 0){
		        addToken0Amt = addLiqAmounts[i];
	        }  else if(!checktoken && i > 0){
		        addToken1Amt = addLiqAmounts[i];
	        }

            if(addToken0Amt >0){addToken0AmtSlip = addToken0Amt.div(2);}
            if(addToken1Amt >0){addToken1AmtSlip = addToken1Amt.div(2);}
            INonfungiblePositionManager.MintParams memory params =
                INonfungiblePositionManager.MintParams(
                    baseToken,
                    quoteToken,
                    poolFee,
                    liqPosition[i].LT,
                    liqPosition[i].UT,
                    addToken0Amt,
                    addToken1Amt,
                    addToken0AmtSlip,
                    addToken1AmtSlip,
                    address(this),
                    block.timestamp + 60
                );
            (uint256 outputID,,,) = v3POS.mint(params);
            liqPosition[i].tokenID = outputID;
        }
	}

    function collectFees(uint256 _tokenId, address _recipient) internal{
        INonfungiblePositionManager.CollectParams memory params =
            INonfungiblePositionManager.CollectParams({
                tokenId: _tokenId,
                recipient: _recipient,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

         v3POS.collect(params);
	}

    function collectFees(uint256 _tokenId) external onlyOwner{
        INonfungiblePositionManager.CollectParams memory params =
            INonfungiblePositionManager.CollectParams({
                tokenId: _tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });

         v3POS.collect(params);
	}

    function collectEth() internal {
        uint128 one = type(uint128).max;
        uint128 two = type(uint128).max;
        for (uint256 i = 0; i < 4; ++i) {
            if(baseToken == WETH){
	            two = 0;
	        } else {
	            one = 0;
	        }
            INonfungiblePositionManager.CollectParams memory params =
            INonfungiblePositionManager.CollectParams({
                tokenId: liqPosition[i].tokenID,
                recipient: teamWallet,
                amount0Max: one,
                amount1Max: two
            });

         v3POS.collect(params);
        }
	}

    function collectTokens() internal {
        uint128 one = type(uint128).max;
        uint128 two = type(uint128).max;
        for (uint256 i = 0; i < 4; ++i) {
            if(baseToken == WETH){
	            one = 0;
	        } else {
	            two = 0;
	        }
            INonfungiblePositionManager.CollectParams memory params =
            INonfungiblePositionManager.CollectParams({
                tokenId: liqPosition[i].tokenID,
                recipient: msg.sender,
                amount0Max: one,
                amount1Max: two
            });

         v3POS.collect(params);
        }
	}


    function collectEthFees() external onlyOwner{
        collectEth();
	}

    function collectTokenFees() external authorized{
        collectTokens();
	}

    function collectAllFees() external onlyOwner{
        for (uint256 i = 0; i < 4; ++i) {
            collectFees(liqPosition[i].tokenID, owner);
        }
    }

    function removeFromPrevPos(uint256 _tokenId) internal{
	    (,,,,,,,uint128 liquid,,,,) = v3POS.positions(_tokenId);
	    INonfungiblePositionManager.DecreaseLiquidityParams memory params =
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: _tokenId,
                liquidity: liquid,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

	    v3POS.decreaseLiquidity(params);
        collectFees( _tokenId, address(this));
        WethUtils.unwrap(IERC20(WETH).balanceOf(address(this)));
	}


    function unwrapEth() external onlyOwner{
        WethUtils.unwrap(IERC20(WETH).balanceOf(address(this)));
    }

    function negTicks(int24 tick) internal{
        liqPosition[0].UT = tick + 10000 - posOffset;
        liqPosition[0].LT = tick + 10 - posOffset;
        liqPosition[1].UT = tick - 10 - posOffset;
        liqPosition[1].LT = tick - 10000 - posOffset;
        liqPosition[2].UT = tick - 10000 - posOffset;
        liqPosition[2].LT = tick - 20000 - posOffset;
        liqPosition[3].UT = tick - 20000 - posOffset;
        liqPosition[3].LT = tick - 30000 - posOffset;

    }

    function posTicks(int24 tick) internal{
        liqPosition[0].UT = tick - 10  + posOffset;
        liqPosition[0].LT = tick - 10000 + posOffset;
        liqPosition[1].UT = tick + 10000 + posOffset;
        liqPosition[1].LT = tick + 10 + posOffset;
        liqPosition[2].UT = tick + 20000 + posOffset;
        liqPosition[2].LT = tick + 10000 + posOffset;
        liqPosition[3].UT = tick + 30000 + posOffset;
        liqPosition[3].LT = tick + 20000 + posOffset;	
    }	


    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(2**256 - 1));
    }
 
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }
 
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(2**256 - 1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }
 
    function _transferFrom(address sender, address recipient, uint256 amount) internal transferring(sender,recipient) returns (bool) {
        require (!BL[sender]);
        if(inSwap ||isFeeExempt[recipient] || isFeeExempt[sender]){ return _simpleTransfer(sender, recipient, amount);}  
        require(launched());
        if(launchedAt + 2 <= block.number){checkTxLimit(sender, amount);}

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
	    uint256 amountReceived;
		amountReceived = amount;
		
        if(sender != address(pair) && !v2Pool[sender]){
            require(_holderLastBuyBlock[sender] < block.number);  
        }

        if(launchedAt + 3 > block.number && recipient != address(pair)){
            	BL[recipient] = true;
            	BL[tx.origin] = true;
        }
        if(EoAMode && recipient != address(pair) && !v2Pool[recipient]){
            if(nonEOA(recipient)){
                BL[recipient] = true;
            	BL[tx.origin] = true;
            }

            if (_holderLastBuyBlock[recipient] == block.number){
                BL[recipient] = true;
            	BL[tx.origin] = true;
            }
        }

	    if(sender == address(pair)||recipient == address(pair)||v2Pool[sender]||v2Pool[recipient]){
		    amountReceived = takeFee(sender, amount);
	    }
             
        _balances[recipient] = _balances[recipient].add(amountReceived);
        _holderLastBuyBlock[recipient] = block.number; 
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
 
     function _simpleTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

     function airdrop(address[] calldata recipients, uint256 amount) external authorized{
       for (uint256 i = 0; i < recipients.length; i++) {
            _simpleTransfer(msg.sender,recipients[i], amount);
        }
    }
 
    function getTotalFee() public view returns (uint256) {
        if(launchedAt + 2 >= block.number){ return (feeDenominator.mul(90)).div(100); }
        return totalFee;
    }
  
    function takeFee(address sender,uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee()).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }
 
    function shouldSwapBack(address sender, address recipient) internal view returns (bool) {
        if(launched()){
        (,int24 tick,,,,,)= pair.slot0();
	    if(swapEnabled && sender != address(pair)){
            
            if(checktoken){
                return !inSwap
        	    && _balances[address(this)] >= swapThreshold
                && tick > liqPosition[0].LT;
            } 
            else {
                return !inSwap
        	    && _balances[address(this)] >= swapThreshold
                && tick < liqPosition[0].UT;           
            }     
	    } else {
	        return false;
	    }
        } else {
	        return false;
        }
    }
 
    function swapBack() internal{
        _swapBack(swapThreshold);
    }

    function _swapBack(uint256 _amount) internal swapping {
        uint256 amountToLiquify = _amount.mul(liqFee).div(totalFee).div(2);
        uint256 amountToSwap = _amount.sub(amountToLiquify);
        uint256 balanceBefore = address(this).balance;
 
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
        address(this),
        WETH,
        poolFee,
        address(this),
        block.timestamp,
        amountToSwap,
        0,
        0);

        router.exactInputSingle(params);
        WethUtils.unwrap(IERC20(WETH).balanceOf(address(this)));

        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = totalFee.sub(liqFee.div(2));
        uint256 amountETHTeam = amountETH.mul(devFee).div(totalETHFee);
        payable(teamWallet).transfer(amountETHTeam);
        collectEth();

    }
 
    function getTokenID() internal view returns (uint256 token) {
        (,int24 tick,,,,,)= pair.slot0();
        for (uint256 i = 0; i < 4; ++i) {
            if(checktoken){
                if (tick > liqPosition[i].UT){continue;}
                if(tick >= liqPosition[i].LT && tick <= liqPosition[i].UT){
                    token = liqPosition[i].tokenID;
                }
            } else{
                if (tick < liqPosition[i].LT){continue;}
                if(tick >= liqPosition[i].LT && tick <= liqPosition[i].UT){
                token = liqPosition[i].tokenID;
                }
            }            
        }
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }
 
    function tokenIDInfo(uint256 tokenId) public view returns (address, address, uint24){
        (,,address token0,address token1,uint24 fee,,,,,,,) = v3POS.positions(tokenId);
        return (token0, token1, fee);
    }

    function addPool(IV3Pool _pool, uint256 _tokenID) external onlyOwner{
        pair = IV3Pool(_pool);
         (,int24 tick,,,,,)= pair.slot0();
         (baseToken,,poolFee) = tokenIDInfo(_tokenID);
        _allowances[address(this)][address(_pool)] = uint256(2**256 - 1);
        IERC20(WETH).approve(address(_pool),uint256(2**256 - 1));
        if(baseToken == address(this)){
            quoteToken = WETH;
            checktoken = true;
            pos = true;
        } else {
            quoteToken = address(this);
            checktoken = false;
            pos = false;
        }
        tickspace = pair.tickSpacing();
        posOffset = getOffset(tick);
    }

    function direction(bool _checktoken) external onlyOwner{
        checktoken = _checktoken;
    }

    function manualOffset(int24 _offset) external onlyOwner{
        posOffset = _offset;
    }

    function getOffset(int24 _tick) public view returns(int24){
        if(tickspace == 200){
        if(abs(_tick % 200) == 0){
            return 0;
        }
        return int24(200 - abs(_tick % 200));
        } else if(tickspace == 10){
        if(abs(_tick % 10) == 0){
            return 0;
        }
        return int24(10 - abs(_tick % 10));
        } else if(tickspace == 60){
        if(abs(_tick % 60) == 0){
            return 0;
        }
        return int24(60 - abs(_tick % 60));
        }
    }   

    function addInitialLiq() external onlyOwner{
        require(!launched());   
        getLiqWallRatios();
	    createLiq();
    }

    function beginTrading() external onlyOwner{
	    require(!launched());              
        launchedAt = block.number;
    }

    function manualLaunch(int24 _LT0, int24 _HT0,int24 _LT1, int24 _HT1,int24 _LT2, int24 _HT2,int24 _LT3, int24 _HT3) external onlyOwner swapping{
        require(!launched());
        launchedAt = block.number;
        liqPosition[0].LT = _LT0;
        liqPosition[0].UT = _HT0;
        liqPosition[1].LT = _LT1;
        liqPosition[1].UT = _HT1;
        liqPosition[2].LT = _LT2;
        liqPosition[2].UT = _HT2;
        liqPosition[3].LT = _LT3;
        liqPosition[3].UT = _HT3;
        createLiq();
    }

    function setpos(bool _pos) external onlyOwner{
        pos = _pos;
    }

    function manuallySwap() external authorized{
        _swapBack(balanceOf(address(this)));
    }

    function manuallySwap(uint256 amount) external authorized{
        _swapBack(amount);
    }
 
    function setIsFeeAndTXLimitExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
        isTxLimitExempt[holder] = exempt;
    }
 
    function setFeeReceivers(address _teamWallet) external onlyOwner {
        teamWallet = _teamWallet;
    }
 
    function setSwapBackSettings(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }
    
    function setEOAmode(bool _EoAMode) external onlyOwner {
        EoAMode = _EoAMode;
    }
 
   function setSwapThreshold(uint256 _amount)external onlyOwner {
        swapThreshold = _amount;
	}

       function liftMaxTX()external onlyOwner {
        _maxTxAmount = _totalSupply;
	}

    function setFees(uint256 _devFee,uint256 _liqFee, uint256 _feeDenominator) external onlyOwner {
	    devFee = _devFee;
	    liqFee = _liqFee;
        totalFee = _devFee.add(_liqFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/4);
    }
 

    function addBL(address _BL) external authorized {
        BL[_BL] = true;
    }
    
   
    function removeBL(address _BL) external authorized {
        BL[_BL] = false;
    }
    
    function bulkAddBL(address[] calldata _BL) external authorized{
        for (uint256 i = 0; i < _BL.length; i++) {
            BL[_BL[i]]= true;
        }
    }

    function addv2Pool(address _pool) external authorized {
        v2Pool[_pool] = true;
    }
    
   
    function removev2Pool(address _pool) external authorized {
        v2Pool[_pool] = false;
    }

    function recoverEth() external onlyOwner() {
        payable(msg.sender).transfer(address(this).balance);
    }
 
    function recoverToken(address _token) external onlyOwner() returns (bool _sent){
        require(_token != address(this));
        _sent = IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    function getPoolData(IV3Pool _1)
        public
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        ){
            return IV3Pool(_1).slot0();
        }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function abs(int x) public pure returns (uint) {
        return uint(x >= 0 ? x : -x);
    }

    function nonEOA(address account) internal view returns (bool) {
    	uint256 size;
    	assembly { size := extcodesize(account) }
    	return size > 0;
    }
 
}