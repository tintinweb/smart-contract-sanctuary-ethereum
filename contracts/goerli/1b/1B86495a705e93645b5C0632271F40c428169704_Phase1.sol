/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// File @openzeppelin/contracts/token/ERC20/[email protected]

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File contracts/distribution/interfaces/IPhase1.sol

interface IPhase1 {
    /// @dev Represents a position for phase 1
    struct Position {
        uint256 expireTime; // The time this locking expires
        uint256 multiplier; // The calculated multiplier
        uint256 amount; // The amount of the position
        uint256 half; // The half of the position
        uint256 withdrawnOn4thDay;
        uint256 withdrawnTillPart3;
        // True if HALO LP claimed
        bool evaluated;
        // True if deposited to Phase2 or HALO locked to VE
        bool deposited;
    }

    function quoteHALO(address pair, address account)
        external
        view
        returns (uint256);

    event Initialized(uint256 startTime, uint256 endTime);
    event DepositLp(address pair, uint256 amount, uint256 lockPeriod);

    event Withdraw(address pair, uint256 amount);

    event ClaimHalo(address claimer, uint256 amount);

    event DepositToPhase2(address pair, uint256 amount, uint256 lockPeriod);
}

interface IOwnable {
    function owner() external view returns (address);

    function setOwner(address _newOwner) external;

    function acceptOwner() external;

    function deleteOwner() external;
}

contract Ownable is IOwnable {
    event NewOwner(address owner);

    address public owner;
    address public pendingOwner;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address _newOwner) external onlyOwner {
        require(_newOwner != msg.sender, "new owner = current owner");
        pendingOwner = _newOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "not pending owner");
        owner = msg.sender;
        pendingOwner = address(0);
        emit NewOwner(msg.sender);
    }

    function deleteOwner() external onlyOwner {
        require(pendingOwner == address(0), "pending owner != 0 address");
        owner = address(0);
        emit NewOwner(address(0));
    }
}

abstract contract ReentrancyGuard {
    // simple re-entrancy check
    uint256 internal _unlocked = 1;

    modifier lock() {
        // solhint-disable-next-line
        require(_unlocked == 1, "reentrant");
        _unlocked = 2;
        _;
        _unlocked = 1;
    }
}

// File contracts/interfaces/IUniswapV2Router01.sol

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File contracts/interfaces/IUniswapV2Router02.sol

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

struct Route {
    address from;
    address to;
    bool stable;
}

interface IRouterV1 {
    function getPair(
        address tokenA,
        address tokenB,
        bool stable
    ) external view returns (address pair);

    function getReserves(
        address tokenA,
        address tokenB,
        bool stable
    ) external view returns (uint256 reserveA, uint256 reserveB);

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amount, bool stable);

    function getAmountsOut(uint256 amountIn, Route[] memory routes)
        external
        view
        returns (uint256[] memory amounts);

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired
    )
        external
        view
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity
    ) external view returns (uint256 amountA, uint256 amountB);

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        bool stable,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        bool stable,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        bool stable,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// File @openzeppelin/contracts/utils/introspection/[email protected]

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

// File @openzeppelin/contracts/token/ERC721/[email protected]

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

struct Point {
    int128 bias;
    int128 slope; // amount locked / max time
    uint256 timestamp;
    uint256 blk; // block number
}

library PointLib {
    /**
     * @notice Binary search to find epoch equal to or immediately before `_block`.
     *         WARNING: If `_block` < `pointHistory[0].blk`
     *         this function returns the index of first point history `0`.
     * @dev Algorithm copied from Curve's VotingEscrow
     * @param pointHistory Mapping from uint => Point
     * @param _block Block to find
     * @param max Max epoch. Don't search beyond this epoch
     * @return min Epoch that is equal to or immediately before `_block`
     */
    function findBlockEpoch(
        mapping(uint256 => Point) storage pointHistory,
        uint256 _block,
        uint256 max
    ) internal view returns (uint256 min) {
        while (min < max) {
            // Max 128 iterations will be enough for 128-bit numbers
            // mid = ceil((min + max) / 2)
            //     = mid index if min + max is odd
            //       mid-right index if min + max is even
            uint256 mid = max - (max - min) / 2; // avoiding overflow
            if (pointHistory[mid].blk <= _block) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
    }

    /**
     * @notice Binary search to find epoch equal to or immediately before `timestamp`.
     *         WARNING: If `timestamp` < `pointHistory[0].timestamp`
     *         this function returns the index of first point history `0`.
     * @dev Algorithm almost the same as `findBlockEpoch`
     * @param pointHistory Mapping from uint => Point
     * @param timestamp Timestamp to find
     * @param max Max epoch. Don't search beyond this epoch
     * @return min Epoch that is equal to or immediately before `timestamp`
     */
    function findTimestampEpoch(
        mapping(uint256 => Point) storage pointHistory,
        uint256 timestamp,
        uint256 max
    ) internal view returns (uint256 min) {
        while (min < max) {
            // Max 128 iterations will be enough for 128-bit numbers
            // mid = ceil((min + max) / 2)
            //     = mid index if min + max is odd
            //       mid-right index if min + max is even
            uint256 mid = max - (max - min) / 2; // avoiding overflow
            if (pointHistory[mid].timestamp <= timestamp) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
    }

    /**
     * @notice Calculates bias (used for VE total supply and user balance),
     * returns 0 if bias < 0
     * @param point Point
     * @param dt time delta in seconds
     */
    function calculateBias(Point memory point, uint256 dt)
        internal
        pure
        returns (uint256)
    {
        int128 bias = point.bias - point.slope * int128(int256(dt));
        if (bias > 0) {
            return uint256(int256(bias));
        }

        return 0;
    }
}

interface IVe is IERC721Metadata {
    function halo() external view returns (address);

    function balanceOfNFT(uint256) external view returns (uint256);

    function isApprovedOrOwner(address, uint256) external view returns (bool);

    function totalSupply() external view returns (uint256);

    function setVoted(uint256 tokenId, bool _voted) external;

    function attach(uint256 tokenId) external;

    function detach(uint256 tokenId) external;

    function epoch() external view returns (uint256);

    function userPointEpoch(uint256 tokenId) external view returns (uint256);

    function pointHistory(uint256 i) external view returns (Point memory);

    function userPointHistory(uint256 tokenId, uint256 i)
        external
        view
        returns (Point memory);

    function checkpoint() external;

    function depositFor(uint256 tokenId, uint256 value) external;

    function createLockFor(
        uint256,
        uint256,
        address
    ) external returns (uint256);

    function findTimestampEpoch(uint256 _timestamp)
        external
        view
        returns (uint256);

    function findUserEpochFromTimestamp(
        uint256 _tokenId,
        uint256 _timestamp,
        uint256 _maxUserEpoch
    ) external view returns (uint256);
}

// File contracts/interfaces/IUniswapV2Pair.sol

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IFactoryV1 {
    function owner() external view returns (address);

    function numPairs() external view returns (uint256);

    function isPair(address pair) external view returns (bool);

    function getPair(
        address tokenA,
        address token,
        bool stable
    ) external view returns (address pair);

    function calculatePairAddress(
        address tokenA,
        address token,
        bool stable
    ) external view returns (address pair);

    function getConstructorArgs()
        external
        view
        returns (
            address,
            address,
            bool
        );

    function createPair(
        address tokenA,
        address tokenB,
        bool stable
    ) external returns (address pair);

    function reserves(address pair) external view returns (address reserve);
}

// File contracts/distribution/interfaces/IPhase2.sol

interface IPhase2 {
    /// @dev Represents a position for phase 2
    struct Position {
        uint256 expireTime;
        uint256 multiplier;
        uint256 amount;
        uint256 half; // The half of the position
        uint256 withdrawnOn4thDay;
        uint256 withdrawnTillPart3;
        bool staked;
        bool evaluated;
    }

    event Initialized(uint256 startTime, uint256 endTime);

    event DepositHaloFromPhase1(
        uint256 amount,
        address owner,
        uint256 lockPeriod
    );
    event DepositStable(
        address stableToken,
        uint256 stableAmount,
        uint256 stableLockDurationInDays
    );

    event WithdrawHalo(address account, uint256 amount);
    event WithdrawStable(address account, address stableToken, uint256 amount);

    event ClaimHalo(address claimer, uint256 amount);
}

// solhint-disable not-rely-on-time, reason-string, max-states-count /*
contract Phase2 is IPhase2, ReentrancyGuard, Ownable {
    /// @dev DEPOSIT_PHASE_1_END, DEPOSIT_STABLE_END < DURATION
    uint256 private constant DURATION = 5 days;
    uint256 private constant DEPOSIT_PHASE_1_END = 3 days;
    uint256 private constant DEPOSIT_STABLE_END = 4 days;
    /// @dev WITHDRAW_1_END < WITHDRAW_2_END < DURATION
    uint256 private constant WITHDRAW_1_END = 3 days;
    uint256 private constant WITHDRAW_2_END = 4 days;
    uint256 private constant WITHDRAW_3_DURATION = DURATION - WITHDRAW_2_END;

    uint256 public constant ALLOCATION_FOR_HALO = 500_000 * 1 ether;
    uint256 public constant ALLOCATION_FOR_USDC = 3_500_000 * 1 ether;

    /// @dev Phase 1 address
    address public immutable phase1;

    /// @notice Index of the current time
    uint256 public startTime;
    uint256 public endTime;

    /// @dev Supported token addresses
    address public immutable halo;
    address public immutable usdc;

    /// @dev The HALO AMM router contract
    address public immutable haloRouter;

    // @notice The halo factory contract address
    address private immutable _haloFactory;

    /// @dev The VE contract
    address private immutable _ve;

    uint256 public totalWeightOfHalo;
    uint256 public totalWeightOfUsdc;

    uint256 public haloDeposited;
    uint256 public usdcDeposited;

    uint256 public haloUsdcLP;
    uint256 public usdcPerHalo;

    address[] public depositors;
    mapping(address => bool) public isDepositor;

    /// @dev token => user address => Phase 2 position
    mapping(address => mapping(address => Position)) public positions;

    /// @notice Represents the status of the phase
    bool private _isStopped;

    modifier notStopped() {
        require(!_isStopped, "System is stopped...withdraw only");
        _;
    }

    constructor(
        address _phase1,
        address _halo,
        address _usdc,
        address ve,
        address router,
        address factory
    ) {
        require(
            _phase1 != address(0) &&
                _halo != address(0) &&
                _usdc != address(0) &&
                ve != address(0) &&
                router != address(0) &&
                factory != address(0),
            "Invalid arguments"
        );

        phase1 = _phase1;
        halo = _halo;
        usdc = _usdc;
        _ve = ve;
        haloRouter = router;
        _haloFactory = factory;

        IERC20(halo).approve(ve, type(uint256).max);
    }

    /// Privileged Functionality

    /// @dev Set the contracts address
    function initialize() external onlyOwner {
        require(startTime == 0, "initialized");

        startTime = block.timestamp;
        endTime = block.timestamp + DURATION;

        emit Initialized(block.timestamp, block.timestamp + DURATION);
    }

    /// @dev Concludes phase 2 and migrates liquidity to halo amm
    function migrateLiquidityToHaloAMM() external onlyOwner notStopped {
        require(block.timestamp > endTime, "not available yet");

        usdcPerHalo = (usdcDeposited * 1e18) / haloDeposited;

        IERC20(halo).approve(haloRouter, haloDeposited);
        IERC20(usdc).approve(haloRouter, usdcDeposited);

        {
            IFactoryV1 haloFactory = IFactoryV1(_haloFactory);

            bool isPair = haloFactory.isPair(
                haloFactory.calculatePairAddress(usdc, halo, false)
            );

            if (!isPair) {
                haloFactory.createPair(usdc, halo, false);
            }
        }

        (uint256 used0, uint256 used1, uint256 liquidityHaloUsdc) = IRouterV1(
            haloRouter
        ).addLiquidity(
                usdc,
                halo,
                false,
                usdcDeposited,
                haloDeposited,
                0,
                0,
                address(this),
                block.timestamp + 30
            );

        haloUsdcLP = liquidityHaloUsdc;

        if (usdcDeposited > used0)
            IERC20(usdc).transfer(msg.sender, usdcDeposited - used0);

        if (haloDeposited > used1)
            IERC20(halo).transfer(msg.sender, haloDeposited - used1);
    }

    /// @dev Deposits the lp tokens to the halo amm by pair
    function claimLP(address asset) external lock notStopped {
        require(asset == halo || asset == usdc, "invalid token");

        Position storage position = positions[asset][msg.sender];

        require(block.timestamp > position.expireTime, "not available yet");

        require(position.amount > 0, "amount = 0");
        require(!position.evaluated, "claimed");
        position.evaluated = true;

        uint256 lpShare = 0;
        if (asset == halo) {
            uint256 totalHalo = haloDeposited +
                ((usdcDeposited * 1e18) / usdcPerHalo);

            lpShare = (position.amount * haloUsdcLP) / totalHalo;
        } else if (asset == usdc) {
            uint256 totalUsdc = usdcDeposited +
                ((haloDeposited * usdcPerHalo) / 1e18);

            lpShare = (position.amount * haloUsdcLP) / totalUsdc;
        }
        require(lpShare != 0, "Zero lp amount");

        address pair = IRouterV1(haloRouter).getPair(halo, usdc, false);
        IERC20(pair).transfer(msg.sender, lpShare);
    }

    /// Non-Privileged Functionality

    /// @dev Deposit from phase 1 to phase 2 HALO tokens
    /// @notice This needs to be called to participate in phase 2
    /// @param haloAmount The HALO amount user wants to deposit
    /// @param user The owner of the lp position
    /// @param lockDurationInDays The duration of the lock
    function depositFromPhase1(
        uint256 haloAmount,
        address user,
        uint256 lockDurationInDays
    ) external lock notStopped {
        require(msg.sender == phase1, "not phase1");
        require(block.timestamp <= startTime + DEPOSIT_PHASE_1_END, "closed");

        uint256 multiplier = getHaloLockMultiplier(lockDurationInDays);
        require(multiplier != 0, "invalid lock period");

        Position storage position = positions[halo][user];

        haloDeposited += haloAmount;
        totalWeightOfHalo -= position.amount * position.multiplier;

        position.expireTime = block.timestamp + lockDurationInDays;
        position.amount += haloAmount;
        position.multiplier = multiplier;

        totalWeightOfHalo += position.amount * multiplier;

        if (!isDepositor[user]) {
            isDepositor[user] = true;
            depositors.push(user);
        }

        IERC20(halo).transferFrom(msg.sender, address(this), haloAmount);

        emit DepositHaloFromPhase1(haloAmount, user, lockDurationInDays);
    }

    /// @dev Deposits stable coin in the pool of chosing for user
    /// @param stableAmount The amount of stable tokens that the user wants to deposit along his halo position
    /// @param stableLockDurationInDays The duration of the lock
    function depositStable(
        uint256 stableAmount,
        uint256 stableLockDurationInDays
    ) external lock notStopped {
        require(stableAmount != 0, "amount = 0");
        require(block.timestamp <= startTime + DEPOSIT_STABLE_END, "closed");

        uint256 multiplier = getMultiplier(stableLockDurationInDays);
        require(multiplier != 0, "invalid lock period");

        Position storage position = positions[usdc][msg.sender];

        totalWeightOfUsdc -= position.amount * position.multiplier;

        position.amount += stableAmount;
        position.expireTime = block.timestamp + stableLockDurationInDays;

        position.multiplier = multiplier;
        position.half = position.amount / 2;

        usdcDeposited += stableAmount;
        totalWeightOfUsdc += position.amount * multiplier;

        if (!isDepositor[msg.sender]) {
            isDepositor[msg.sender] = true;
            depositors.push(msg.sender);
        }

        IERC20(usdc).transferFrom(msg.sender, address(this), stableAmount);

        emit DepositStable(usdc, stableAmount, stableLockDurationInDays);
    }

    /// @dev Withdraw stable token from phase2
    /// @param stableAmount The amount of stable token the user wants to withdraw
    function withdrawStable(uint256 stableAmount) external lock notStopped {
        require(stableAmount != 0, "amount = 0");

        Position storage position = positions[usdc][msg.sender];
        require(position.amount != 0, "position.amount = 0");

        uint256 _endTime = endTime;
        require(block.timestamp < _endTime, "withdrawals are locked");

        if (block.timestamp <= startTime + WITHDRAW_1_END) {
            position.amount -= stableAmount;
            position.half = position.amount / 2;
        } else if (block.timestamp < startTime + WITHDRAW_2_END) {
            require(
                position.withdrawnOn4thDay + stableAmount <= position.half,
                "withdraw amount exceeds limit on 4th day"
            );

            position.amount -= stableAmount;
            position.withdrawnOn4thDay += stableAmount;
        } else {
            // 1st withdraw | 2nd withdraw
            // withdraw = 30 | withdraw = 7.5
            uint256 _half = position.half;

            // 21600 | 21600
            uint256 withdrawnTillPart3 = position.withdrawnTillPart3;
            uint256 lastClaimedTill = withdrawnTillPart3 > block.timestamp
                ? withdrawnTillPart3
                : block.timestamp;

            uint256 claimableTime = _endTime - lastClaimedTill;

            // (50 * 64800 / 86400) = 37.5 | (20 * 43200 / 86400) = 25
            uint256 amountWithdrawable = ((_half * claimableTime) /
                WITHDRAW_3_DURATION);

            require(
                // 30 <= 37.5 | 10 <= 10 | tx reverts
                stableAmount <= amountWithdrawable,
                "Amount exceeds withdrawable"
            );

            // amount = 100 - 30 = 70 | 70 - 10 = 60
            position.amount -= stableAmount;

            // start + 4 days + 21600 + 51840
            position.withdrawnTillPart3 =
                lastClaimedTill +
                ((stableAmount * WITHDRAW_3_DURATION) / _half);
        }

        usdcDeposited -= stableAmount;
        totalWeightOfUsdc -= stableAmount * position.multiplier;

        IERC20(usdc).transfer(msg.sender, stableAmount);

        emit WithdrawStable(msg.sender, usdc, stableAmount);
    }

    /// @notice Allows to claim HALO/USDC not deposited to be claimed after a period of 3 months
    /// @param asset The asset pool of participation that the user can claim
    /// @custom:require The position is not claimed
    /// @custom:require The amount of the position is not 0
    /// @custom:require The time passed from the end of phase2 is > 3 months
    function stakeToHALO(
        address asset,
        uint256 start,
        uint256 end
    ) external notStopped onlyOwner {
        uint256 len = depositors.length;
        if (end > len) end = len - 1;

        for (uint256 i = start; i <= end; ++i) {
            address depositor = depositors[i];
            Position storage position = positions[asset][depositor];

            if (position.amount == 0 || position.staked) continue;

            position.staked = true;

            uint256 haloShare = 0;
            if (asset == halo) {
                haloShare =
                    (position.amount *
                        position.multiplier *
                        ALLOCATION_FOR_HALO) /
                    totalWeightOfHalo;
            } else if (asset == usdc)
                haloShare =
                    (position.amount *
                        position.multiplier *
                        ALLOCATION_FOR_USDC) /
                    totalWeightOfUsdc;

            if (haloShare != 0) {
                IVe(_ve).createLockFor(
                    haloShare,
                    position.expireTime - startTime,
                    depositor
                );
                emit ClaimHalo(depositor, haloShare);
            }
        }
    }

    /// @notice Calculate the multiplier based on the lock period
    function getHaloLockMultiplier(uint256 lockPeriod)
        private
        pure
        returns (uint256)
    {
        // 3 months
        if (lockPeriod == 90 days) return 1;

        // 6 months
        if (lockPeriod == 180 days) return 3;

        // 1 year
        if (lockPeriod == 365 days) return 7;

        return 0;
    }

    /// @notice Calculate the multiplier based on the lock period
    function getMultiplier(uint256 lockPeriod) private pure returns (uint256) {
        // 3 months
        if (lockPeriod == 90 days) return 4;

        // 6 months
        if (lockPeriod == 180 days) return 9;

        // 1 year
        if (lockPeriod == 365 days) return 19;

        return 0;
    }

    /// @notice Only Owner function to stop the phase and allow everyone to withdraw
    function setStop() external onlyOwner {
        _isStopped = true;
    }

    /// @notice Withdraw when stopped allows users to withdraw positions without time limits
    function withdrawWhenStoppedHalo() external lock {
        require(_isStopped, "Phase needs to be stopped");

        Position storage position = positions[halo][msg.sender];
        uint256 haloAmount = position.amount;
        require(haloAmount != 0, "No HALO available for withdrawal");

        position.amount = 0;
        IERC20(halo).transfer(msg.sender, haloAmount);

        emit WithdrawHalo(msg.sender, haloAmount);
    }

    /// @notice Withdraw when phase is stopped allows users to withdraw positions without time limits
    function withdrawWhenStoppedStable() external lock {
        require(_isStopped, "Phase needs to be stopped");

        Position storage position = positions[usdc][msg.sender];
        uint256 stableAmount = position.amount;
        require(stableAmount != 0, "No amount available for withdrawal");

        position.amount = 0;
        IERC20(usdc).transfer(msg.sender, stableAmount);

        emit WithdrawStable(msg.sender, usdc, stableAmount);
    }

    function getDepositorsCount() external view returns (uint256) {
        return depositors.length;
    }
}

// File contracts/distribution/Phase1.sol

// solhint-disable not-rely-on-time, reason-string, max-states-count /*
contract Phase1 is IPhase1, ReentrancyGuard, Ownable {
    /// @dev DEPOSIT_END < DURATION
    uint256 private constant DURATION = 5 days;
    uint256 private constant DEPOSIT_END = 3 days;
    /// @dev WITHDRAW_1_END < WITHDRAW_2_END < DURATION
    uint256 private constant WITHDRAW_1_END = 3 days;
    uint256 private constant WITHDRAW_2_END = 4 days;
    uint256 private constant WITHDRAW_3_DURATION = DURATION - WITHDRAW_2_END;

    address public immutable WETH;
    uint256 public constant HALO_PER_PAIR = 200_000 ether;

    /// @notice Index of the current time
    uint256 public startTime;
    uint256 public endTime;

    /// @notice The HALO AMM router contract
    address public immutable haloRouter;

    /// @notice The halo contract address
    address private immutable _halo;

    /// @notice The halo factory contract address
    address private immutable _haloFactory;

    /// @notice The phase 2 contract
    Phase2 public phase2;

    /// @notice The uniswap router address
    address private immutable _uniswapRouter;

    /// @notice The VE contract
    address private immutable _ve;

    /// @notice The 5 supportedPairs that we are allocating the funds for phase 1
    mapping(address => bool) public supportedPairs;

    /// @notice The supported pair addreses as array
    address[] public supportedPairsAddresses;

    /// @notice Mapping address => is stable
    mapping(address => bool) public isStablePair;

    /// @notice pair => user address => Phase 1 position
    mapping(address => mapping(address => Position)) public positions;

    /// @notice Represents the addresses of the users deposited lp
    address[] public depositors;
    mapping(address => bool) public isDepositor;

    /// @notice Represents the pair to liquidity positions after uniswap burn
    mapping(address => uint256) private _haloLPAmountsByPairs;

    /// @notice Represents the pair to liquidity positions before uniswap burn
    mapping(address => uint256) private _uniswapAmountsByPairs;

    /// @notice Represents the total weight of locked positions in phase 1
    mapping(address => uint256) private _totalWeightOfLockedPositions;

    /// @notice Represents the status of the phase
    bool private _isStopped;

    modifier notStopped() {
        require(!_isStopped, "System is stopped...withdraw only");
        _;
    }

    /// @notice Pairs array must have 1st element the USDC/USDT stable pair
    constructor(
        address weth,
        address halo,
        address uniswapRouter,
        address ve,
        address router,
        address haloFactory,
        address[] memory pairs
    ) {
        require(
            weth != address(0) &&
                halo != address(0) &&
                uniswapRouter != address(0) &&
                ve != address(0) &&
                router != address(0),
            "Invalid arguments"
        );

        WETH = weth;
        _uniswapRouter = uniswapRouter;
        _halo = halo;
        _haloFactory = haloFactory;
        _ve = ve;
        haloRouter = router;

        uint256 count = pairs.length;
        require(count <= 5, "To many entries in supported pairs...max 5");
        for (uint256 i = 0; i < count; ++i) {
            require(!supportedPairs[pairs[i]], "already added");
            supportedPairs[pairs[i]] = true;
            supportedPairsAddresses.push(pairs[i]);
        }
        isStablePair[pairs[0]] = true;

        IERC20(_halo).approve(ve, type(uint256).max);
    }

    /// Privileged Functionality

    /// @notice Set the phase 2 contract
    function setPhase2(Phase2 _phase2) external onlyOwner {
        require(address(_phase2) != address(0), "Invalid address for phase 2");

        require(
            address(phase2) == address(0),
            "Address for phase 2 already set"
        );

        phase2 = _phase2;
    }

    /// @notice Set the contracts address
    function initialize() external onlyOwner {
        require(startTime == 0, "Already initialized");

        startTime = block.timestamp;
        endTime = block.timestamp + DURATION;

        emit Initialized(block.timestamp, block.timestamp + DURATION);
    }

    /// @notice Concludes phase 1 and migrates liquidity to halo amm
    function migrateLiquidityToHaloAMM() external onlyOwner notStopped {
        require(block.timestamp >= endTime, "Not available yet");

        IFactoryV1 haloFactory = IFactoryV1(_haloFactory);
        for (uint256 i = 0; i < supportedPairsAddresses.length; ++i) {
            IUniswapV2Pair uniswapV2Pair = IUniswapV2Pair(
                supportedPairsAddresses[i]
            );

            address _token0 = uniswapV2Pair.token0();
            address _token1 = uniswapV2Pair.token1();
            uint256 liquidity;

            {
                bool isStable = isStablePair[address(uniswapV2Pair)];
                bool isPair = haloFactory.isPair(
                    haloFactory.calculatePairAddress(_token0, _token1, isStable)
                );

                if (!isPair) {
                    haloFactory.createPair(_token0, _token1, isStable);
                }
            }

            uint256 lpAmount = uniswapV2Pair.balanceOf(address(this));
            if (lpAmount == 0) {
                continue;
            }

            if (_token0 == WETH || _token1 == WETH) {
                // We reverse here since we want the token
                address token = _token0 == WETH ? _token1 : _token0;

                uniswapV2Pair.approve(_uniswapRouter, lpAmount);
                (uint256 amountToken, uint256 amountETH) = IUniswapV2Router02(
                    _uniswapRouter
                ).removeLiquidityETH(
                        token,
                        lpAmount,
                        0,
                        0,
                        address(this),
                        block.timestamp + 30
                    );

                IERC20(token).approve(haloRouter, amountToken);
                uint256 ethUtilized;
                (, ethUtilized, liquidity) = IRouterV1(haloRouter)
                    .addLiquidityETH{value: amountETH}(
                    token,
                    false,
                    amountToken,
                    0,
                    0,
                    address(this),
                    block.timestamp + 30
                );

                if (ethUtilized < amountETH)
                    payable(msg.sender).transfer(amountETH - ethUtilized);
            } else {
                uniswapV2Pair.approve(_uniswapRouter, lpAmount);

                (
                    uint256 token0Balance,
                    uint256 token1Balance
                ) = IUniswapV2Router02(_uniswapRouter).removeLiquidity(
                        _token0,
                        _token1,
                        lpAmount,
                        0,
                        0,
                        address(this),
                        block.timestamp + 30
                    );

                IERC20(_token0).approve(haloRouter, token0Balance);
                IERC20(_token1).approve(haloRouter, token1Balance);

                uint256 token0Used;
                uint256 token1Used;

                (token0Used, token1Used, liquidity) = IRouterV1(haloRouter)
                    .addLiquidity(
                        _token0,
                        _token1,
                        isStablePair[address(uniswapV2Pair)],
                        token0Balance,
                        token1Balance,
                        0,
                        0,
                        address(this),
                        block.timestamp + 30
                    );

                if (token0Used < token0Balance)
                    IERC20(_token0).transfer(
                        msg.sender,
                        token0Balance - token0Used
                    );

                if (token1Used < token1Balance)
                    IERC20(_token0).transfer(
                        msg.sender,
                        token1Balance - token1Used
                    );
            }
            _haloLPAmountsByPairs[address(uniswapV2Pair)] += liquidity;
        }
    }

    /// @notice Deposits the lp tokens to the halo amm by pair
    function stakeToHALO(
        address pair,
        uint256 start,
        uint256 end
    ) external onlyOwner notStopped {
        uint256 len = depositors.length;
        if (end > len) end = len - 1;

        for (uint256 i = start; i <= end; ++i) {
            Position storage position = positions[pair][depositors[i]];

            if (position.amount == 0 || position.deposited) continue;

            uint256 haloAmount = quoteHALO(pair, depositors[i]);
            require(haloAmount != 0, "No Halo available");

            position.deposited = true;

            IVe(_ve).createLockFor(
                haloAmount,
                position.expireTime - startTime,
                depositors[i]
            );
        }
    }

    /// @notice Withdraws ETH stuck in the smart contract if phases are stoped
    function withdrawETH() external onlyOwner {
        require(_isStopped, "Phase not stopped");
        require(address(this).balance != 0, "No ETH stuck!");

        payable(msg.sender).transfer(address(this).balance);
    }

    /// Non-Privileged Functionality

    function depositLP(
        address pair,
        uint256 amount,
        uint256 lockPeriodInDays
    ) external lock notStopped {
        _depositLP(pair, amount, lockPeriodInDays);
        IERC20(pair).transferFrom(msg.sender, address(this), amount);
    }

    /// @notice Deposit into phase 1 -> lp positions
    /// @param pair Represents the pair address of the lp that we want to deposit
    /// @param amount The amount of lps that is going to be deposited
    /// @param lockPeriodInDays The amount of days that the position is going to be locked for
    /// @custom:require The phase is phase 1
    /// @custom:require The part of phase 1 is 1 as deposits are locked on part 2 and 3
    /// @custom:require The lockPeriodInDays is one of the valid options as 90,180,365
    /// @custom:require The pair is supported to avoid random supportedPairs beign able to lock
    function _depositLP(
        address pair,
        uint256 amount,
        uint256 lockPeriodInDays
    ) internal {
        require(supportedPairs[pair], "Pair is not supported");
        require(amount != 0, "Zero amount deposit");
        require(
            block.timestamp <= startTime + DEPOSIT_END,
            "Deposits are locked"
        );

        Position storage _position = positions[pair][msg.sender];

        if (!isDepositor[msg.sender]) {
            isDepositor[msg.sender] = true;
            depositors.push(msg.sender);
        }

        uint256 multiplier = getMultiplier(lockPeriodInDays);
        require(multiplier != 0, "Invalid multiplier");

        _totalWeightOfLockedPositions[pair] -=
            _position.amount *
            _position.multiplier;

        // Set the expire timestamp for this lock based on the locked period value
        _position.expireTime = block.timestamp + lockPeriodInDays;
        // Set the multiplier
        _position.multiplier = multiplier;
        // Add to the amount that we have
        _position.amount += amount;
        // Set the half for the deposited amount
        _position.half = _position.amount / 2;

        _totalWeightOfLockedPositions[pair] += _position.amount * multiplier;

        _uniswapAmountsByPairs[pair] += amount;
        emit DepositLp(pair, amount, lockPeriodInDays);
    }

    /// @notice Deposit into phase 1 -> by adding double sided liquidity
    ///   the function will first deposit liquidity to the uniswap pool of interest and then deposit
    ///   the lp position to the phase 1 contract
    /// @param pair Represents the pair address of the lp that we want to deposit
    /// @param amount0 The amount of token0 that is going to be deposited
    /// @param amount1 The amount of token1 that is going to be deposited
    /// @param lockPeriodInDays The amount of days that the position is going to be locked for
    /// @custom:require The phase is phase 1
    /// @custom:require The part of phase 1 is 1 as deposits are locked on part 2 and 3
    /// @custom:require The lockPeriodInDays is one of the valid options as 90,180,365
    /// @custom:require The pair is supported to avoid random supportedPairs beign able to lock
    function deposit(
        address pair,
        uint256 amount0,
        uint256 amount1,
        uint256 lockPeriodInDays
    ) external payable lock notStopped {
        require(supportedPairs[pair], "Pair is not supported");

        IUniswapV2Pair uniswaPair = IUniswapV2Pair(pair);
        address _token0 = uniswaPair.token0();
        address _token1 = uniswaPair.token1();
        uint256 liquidity;

        if (_token0 == WETH || _token1 == WETH) {
            address token;
            uint256 amountETH;
            uint256 tokenBalance;
            if (_token0 == WETH) {
                token = _token1;
                amountETH = amount0;
                tokenBalance = amount1;
            } else {
                token = _token0;
                amountETH = amount1;
                tokenBalance = amount0;
            }

            require(msg.value == amountETH, "incorrect Eth amount provided");

            IERC20(token).transferFrom(msg.sender, address(this), tokenBalance);
            IERC20(token).approve(_uniswapRouter, tokenBalance);
            uint256 amountToken;
            uint256 ethUtilized;
            (amountToken, ethUtilized, liquidity) = IUniswapV2Router02(
                _uniswapRouter
            ).addLiquidityETH{value: amountETH}(
                token,
                tokenBalance,
                0,
                0,
                address(this),
                block.timestamp + 30
            );

            if (amountToken < tokenBalance)
                IERC20(token).transfer(msg.sender, tokenBalance - amountToken);

            if (ethUtilized < amountETH)
                payable(msg.sender).transfer(amountETH - ethUtilized);
        } else {
            IERC20(_token0).transferFrom(msg.sender, address(this), amount0);
            IERC20(_token1).transferFrom(msg.sender, address(this), amount1);

            IERC20(_token0).approve(_uniswapRouter, amount0);
            IERC20(_token1).approve(_uniswapRouter, amount1);

            uint256 amount0Used;
            uint256 amount1Used;

            (amount0Used, amount1Used, liquidity) = IUniswapV2Router02(
                _uniswapRouter
            ).addLiquidity(
                    _token0,
                    _token1,
                    amount0,
                    amount1,
                    0,
                    0,
                    address(this),
                    block.timestamp + 30
                );

            if (amount0Used < amount0)
                IERC20(_token0).transfer(msg.sender, amount0 - amount0Used);

            if (amount1Used < amount1)
                IERC20(_token0).transfer(msg.sender, amount1 - amount1Used);
        }
        _depositLP(pair, liquidity, lockPeriodInDays);
    }

    /// @notice Allows the user to withdraw from his position base on the part of the phase the system is in
    /// @param pair The pair the user wants to withdraw from
    /// @param amount The amount that the user wants to withdraw
    /// @custom:require The phase is phase 1
    /// @custom:require The phase needs to be in a non iddle position
    /// @custom:require The amount can not be more than 50% of the position
    /// @custom:require The pair needs to be supported
    function withdraw(address pair, uint256 amount) external lock notStopped {
        require(amount != 0, "Zero amount withdraw");

        uint256 _startTime = startTime;
        uint256 _endTime = endTime;
        require(block.timestamp < _endTime, "Withdrawals locked");

        Position storage _position = positions[pair][msg.sender];

        if (block.timestamp < _startTime + WITHDRAW_1_END) {
            // Check if the system is in part 1, user can withdraw without limitations
            _position.amount -= amount;
            _position.half = _position.amount / 2;
        } else if (block.timestamp < _startTime + WITHDRAW_2_END) {
            // Check if we are in the part 2 of the phase where deposits are locked and withdrawals are up to 50% of the amount deposited
            // Check if amount is over 50% of the position
            require(
                _position.withdrawnOn4thDay + amount <= _position.half,
                "withdrawn amount exceeds the limit on 4th day"
            );
            _position.amount -= amount;
            _position.withdrawnOn4thDay += amount;
        } else {
            // Check if we are in the part 3 of the phase where deposits are locked and withdrawls are down to 0% linearly within the day
            // 1st withdraw | 2nd withdraw
            // withdraw = 30 | withdraw = 7.5
            uint256 _half = _position.half; // 50

            // 21600 | 21600
            uint256 withdrawnTillPart3 = _position.withdrawnTillPart3;
            uint256 lastClaimedTill = withdrawnTillPart3 > block.timestamp
                ? withdrawnTillPart3
                : block.timestamp;

            uint256 claimableTime = _endTime - lastClaimedTill;

            // (50 * 64800 / 86400) = 37.5 | (20 * 43200 / 86400) = 25
            uint256 amountWithdrawable = ((_half * claimableTime) /
                WITHDRAW_3_DURATION);

            require(
                // 30 <= 37.5 | 10 <= 10 | tx reverts
                amount <= amountWithdrawable,
                "Amount exceeds withdrawable"
            );

            // amount = 100 - 30 = 70 | 70 - 10 = 60
            _position.amount -= amount;

            // start + 4 days + 21600 + 51840
            _position.withdrawnTillPart3 =
                lastClaimedTill +
                ((amount * WITHDRAW_3_DURATION) / _half);
        }

        _totalWeightOfLockedPositions[pair] -= amount * _position.multiplier;
        _uniswapAmountsByPairs[pair] -= amount;

        IERC20(pair).transfer(msg.sender, amount);
        emit Withdraw(pair, amount);
    }

    function claimLP(address pair) external lock notStopped {
        Position storage position = positions[pair][msg.sender];
        require(
            block.timestamp > position.expireTime,
            "Not ready to claim yet"
        );
        require(!position.evaluated, "Position already evaluated");
        position.evaluated = true;

        uint256 uniswapPairAmount = position.amount;
        require(uniswapPairAmount != 0, "No lp to claim");
        require(_haloLPAmountsByPairs[pair] > 0, "No LP amount");

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        address haloPair = IRouterV1(haloRouter).getPair(
            token0,
            token1,
            isStablePair[pair]
        );

        uint256 lpAmount = (uniswapPairAmount * _haloLPAmountsByPairs[pair]) /
            _uniswapAmountsByPairs[pair];

        require(lpAmount > 0, "Zero lp amount");
        IERC20(haloPair).transfer(msg.sender, lpAmount);
    }

    /// @notice Concludes the phase 1 for the user taking under consideration all the values that the user has provided
    ///   This function needs to be called by all users before advancing in phase 2
    /// @param pair The pair that the user is concluding for
    /// @param lockPeriodInDays The amount of days that the position is going to be locked for
    /// @return _ The amount that the user either moved to the non phase locked positions or to phase 2
    function depositToPhase2(address pair, uint256 lockPeriodInDays)
        external
        lock
        notStopped
        returns (uint256)
    {
        require(
            block.timestamp > endTime && address(phase2) != address(0),
            "Not available yet"
        );

        Position storage position = positions[pair][msg.sender];
        require(!position.deposited, "Already deposited");

        uint256 amount = position.amount;
        require(amount != 0, "Invalid position in phase1");

        uint256 haloAmount = quoteHALO(pair, msg.sender);
        require(haloAmount != 0, "No Halo available");

        position.deposited = true;
        IERC20(_halo).approve(address(phase2), haloAmount);

        phase2.depositFromPhase1(haloAmount, msg.sender, lockPeriodInDays);

        emit DepositToPhase2(pair, haloAmount, lockPeriodInDays);
        return amount;
    }

    /// @notice Calculate the multiplier based on the lock period
    function getMultiplier(uint256 lockPeriod) private pure returns (uint256) {
        // 3 months
        if (lockPeriod == 90 days) return 4;

        // 6 months
        if (lockPeriod == 180 days) return 9;

        // 1 year
        if (lockPeriod == 365 days) return 19;

        return 0;
    }

    /// @notice Returns the amount of halo that a user can get from the current positions in pool
    /// @param pair The pair that the function should quote for
    /// @param account The user account to quote for
    /// @return _ The Halo amount for the user
    function quoteHALO(address pair, address account)
        public
        view
        returns (uint256)
    {
        Position memory position = positions[pair][account];
        if (position.amount == 0) return 0;

        return
            (HALO_PER_PAIR * position.amount * position.multiplier) /
            _totalWeightOfLockedPositions[pair];
    }

    // solhint-disable-next-line
    receive() external payable {}

    /// @notice Only Owner function to stop the phase and allow everyone to withdraw
    function setStop() external onlyOwner {
        _isStopped = true;
    }

    /// @notice Withdraw when phase is stopped allows users to withdraw positions without time limits
    function withdrawWhenStoped(address pair) external lock {
        require(_isStopped, "Phase needs to be stoped");

        require(supportedPairs[pair], "Pair is not supported");

        Position storage _position = positions[pair][msg.sender];
        uint256 amount = _position.amount;

        require(amount != 0, "No balance");
        _position.amount = 0;

        IERC20(pair).transfer(msg.sender, amount);
        emit Withdraw(pair, amount);
    }

    function getDepositorsCount() external view returns (uint256) {
        return depositors.length;
    }
}