/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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

struct Route {
    address from;
    address to;
    bool stable;
}

interface IRouter {
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

interface IFactory {
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

// File contracts/interfaces/IPhase2.sol

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

    function depositFromPhase1(
        uint256 haloAmount,
        address user,
        uint256 lockDurationInDays
    ) external;
}

abstract contract ReentrancyGuard {
    // simple re-entrancy check
    uint256 private _unlocked = 1;

    modifier lock() {
        // solhint-disable-next-line
        require(_unlocked == 1, "reentrant");
        _unlocked = 2;
        _;
        _unlocked = 1;
    }
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

// File contracts/distribution/Phase2.sol

contract Phase2 is IPhase2, ReentrancyGuard, Ownable {
    /// @dev DEPOSIT_PHASE_1_END, DEPOSIT_STABLE_END < DURATION
    uint256 private constant DURATION = 5 weeks;
    uint256 private constant DEPOSIT_PHASE_1_END = 3 weeks;
    uint256 private constant DEPOSIT_STABLE_END = 4 weeks;
    /// @dev WITHDRAW_1_END < WITHDRAW_2_END < DURATION
    uint256 private constant WITHDRAW_1_END = 3 weeks;
    uint256 private constant WITHDRAW_2_END = 4 weeks;
    uint256 private constant WITHDRAW_3_DURATION = DURATION - WITHDRAW_2_END;

    uint256 public constant ALLOCATION_FOR_Halo = 500_000 * 1 ether;
    uint256 public constant ALLOCATION_FOR_USDC = 3_500_000 * 1 ether;

    /// @dev Phase 1 address
    address public phase1;

    /// @notice Index of the current time
    uint256 public startTime;
    uint256 public endTime;

    /// @dev Supported token addresses
    address public immutable halo;
    address public immutable usdc;

    /// @dev The Halo AMM router contract
    address public immutable haloRouter;

    // @notice The halo factory contract address
    address public immutable _haloFactory;

    /// @dev The VE contract
    address public immutable _ve;

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
        require(block_timestamp > endTime, "not available yet");

        usdcPerHalo = (usdcDeposited * 1e18) / haloDeposited;

        IERC20(halo).approve(haloRouter, haloDeposited);
        IERC20(usdc).approve(haloRouter, usdcDeposited);

        {
            IFactory haloFactory = IFactory(_haloFactory);

            bool isPair = haloFactory.isPair(
                haloFactory.calculatePairAddress(usdc, halo, false)
            );

            if (!isPair) {
                haloFactory.createPair(usdc, halo, false);
            }
        }

        (uint256 used0, uint256 used1, uint256 liquidityHaloUsdc) = IRouter(
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

        require(block_timestamp > position.expireTime, "not available yet");

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

        address pair = IRouter(haloRouter).getPair(halo, usdc, false);
        IERC20(pair).transfer(msg.sender, lpShare);
    }

    /// Non-Privileged Functionality

    /// @dev Deposit from phase 1 to phase 2 Halo tokens
    /// @notice This needs to be called to participate in phase 2
    /// @param haloAmount The Halo amount user wants to deposit
    /// @param user The owner of the lp position
    /// @param lockDurationInDays The duration of the lock
    function depositFromPhase1(
        uint256 haloAmount,
        address user,
        uint256 lockDurationInDays
    ) external lock notStopped {
        require(msg.sender == phase1, "not phase1");
        require(block_timestamp <= startTime + DEPOSIT_PHASE_1_END, "closed");

        uint256 multiplier = getHaloLockMultiplier(lockDurationInDays);
        require(multiplier != 0, "invalid lock period");

        Position storage position = positions[halo][user];

        haloDeposited += haloAmount;
        totalWeightOfHalo -= position.amount * position.multiplier;

        position.expireTime = block_timestamp + lockDurationInDays;
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
        require(block_timestamp <= startTime + DEPOSIT_STABLE_END, "closed");

        uint256 multiplier = getMultiplier(stableLockDurationInDays);
        require(multiplier != 0, "invalid lock period");

        Position storage position = positions[usdc][msg.sender];

        totalWeightOfUsdc -= position.amount * position.multiplier;

        position.amount += stableAmount;
        position.expireTime = block_timestamp + stableLockDurationInDays;

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
        require(block_timestamp < _endTime, "withdrawals are locked");

        if (block_timestamp <= startTime + WITHDRAW_1_END) {
            position.amount -= stableAmount;
            position.half = position.amount / 2;
        } else if (block_timestamp < startTime + WITHDRAW_2_END) {
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
            uint256 lastClaimedTill = withdrawnTillPart3 > block_timestamp
                ? withdrawnTillPart3
                : block_timestamp;

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

    /// @notice Allows to claim Halo/USDC not deposited to be claimed after a period of 3 months
    /// @param asset The asset pool of participation that the user can claim
    /// @custom:require The position is not claimed
    /// @custom:require The amount of the position is not 0
    /// @custom:require The time passed from the end of phase2 is > 3 months
    function stakeToHalo(
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
                        ALLOCATION_FOR_Halo) /
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
        require(haloAmount != 0, "No Halo available for withdrawal");

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

    // TODO: remove
    uint256 public block_timestamp = block.timestamp;

    function setBlockTimestamp(uint256 _timestamp) external {
        block_timestamp = _timestamp;
    }

    function setPhase1(address _phase1) external {
        phase1 = _phase1;
    }
}