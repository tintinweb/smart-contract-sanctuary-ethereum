// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721Receiver.sol";
import "./Governable.sol";
import "./interfaces/IERC1155.sol";
import "./interfaces/IRoyaltyConfig.sol";

contract BounceFixedEndEnglishAuctionNFTV2 is Configurable, IERC721Receiver {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    bytes32 internal constant FeeConfigContract =       bytes32("EANFT::FeeConfigContract");
    bytes32 internal constant TxFeeRatio =              bytes32("EANFT::TxFeeRatio");
    bytes32 internal constant MinValueOfBotHolder =     bytes32("EANFT::MinValueOfBotHolder");
    bytes32 internal constant BotToken =                bytes32("EANFT::BotToken");
    bytes32 internal constant DisableErc721 =           bytes32("EANFT::DisableErc721");
    bytes32 internal constant DisableErc1155 =          bytes32("EANFT::DisableErc1155");
    uint    internal constant TypeErc721                = 0;
    uint    internal constant TypeErc1155               = 1;

    struct Pool {
        // address of pool creator
        address payable creator;
        // pool name
        string name;
        // address of sell token
        address token0;
        // address of buy token
        address token1;
        // token id of token0
        uint tokenId;
        // amount of token id of token0
        uint tokenAmount0;
        // maximum amount of token1 that creator want to swap
        uint amountMax1;
        // minimum amount of token1 that creator want to swap
        uint amountMin1;
        // minimum incremental amount of token1
        uint amountMinIncr1;
        // the duration in seconds the pool will be closed
        uint openAt;
        // the timestamp in seconds the pool will be closed
        uint closeAt;
        // NFT token type
        uint nftType;
    }

    Pool[] public pools;

    // pool index => a flag that if creator is claimed the pool
    mapping(uint => bool) public creatorClaimedP;
    // pool index => the swap pool only allow BOT holder to take part in
    mapping(uint => bool) public onlyBotHolderP;
    // pool index => the candidate of winner who bid the highest amount1 in current round
    mapping(uint => address payable) public currentBidderP;
    // pool index => the highest amount1 in current round
    mapping(uint => uint) public currentBidderAmount1P;
    // pool index => reserve amount of token1
    mapping(uint => uint) public reserveAmount1P;

    // creator address => pool index => whether the account create the pool.
    mapping(address => mapping(uint => bool)) public myCreatedP;
    // account => pool index => bid amount1
    mapping(address => mapping(uint => uint)) public myBidderAmount1P;
    // account => pool index => claim flag
    mapping(address => mapping(uint => bool)) public myClaimedP;

    // pool index => bid count
    mapping(uint => uint) public bidCountP;

    uint unlocked;
    uint public totalTxFee;
    // pool index => a flag whether pool has been cancelled
    mapping(uint => bool) public creatorCanceledP;

    event Created(address indexed sender, uint indexed index, Pool pool);
    event Bid(address indexed sender, uint indexed index, uint amount1);
    event Canceled(address indexed sender, uint indexed index, uint tokenId, uint amount0);
    event CreatorClaimed(address indexed sender, uint indexed index, uint tokenId, uint amount0, uint amount1);
    event BidderClaimed(address indexed sender, uint indexed index, uint tokenId, uint amount0, uint amount1);

    function initial(address _governor, address feeConfigContract, address botToken) public initializer {
        super.initialize(_governor);

        unlocked = 1;
        config[TxFeeRatio] = 0.01 ether;
        config[MinValueOfBotHolder] = 1 ether;

        config[FeeConfigContract] = uint(feeConfigContract);
        config[BotToken] = uint(botToken); // AUCTION
    }

    function createErc721(
        // name of the pool
        string memory name,
        // address of token0
        address token0,
        // address of token1
        address token1,
        // token id of token0
        uint tokenId,
        // maximum amount of token1
        uint amountMax1,
        // minimum amount of token1
        uint amountMin1,
        // minimum incremental amount of token1
        uint amountMinIncr1,
        // reserve amount of token1
        uint amountReserve1,
        // open at
        uint openAt,
        // duration
        uint duration,
        // only bot holder can bid the pool
        bool onlyBot
    ) public {
        require(!getDisableErc721(), "ERC721 pool is disabled");
        uint tokenAmount0 = 1;
        _create(name, token0, token1, tokenId, tokenAmount0, amountMax1, amountMin1, amountMinIncr1, amountReserve1, openAt, duration, onlyBot, TypeErc721);
    }

    function createErc1155(
        // name of the pool
        string memory name,
        // address of token0
        address token0,
        // address of token1
        address token1,
        // token id of token0
        uint tokenId,
        // amount of token id of token0
        uint tokenAmount0,
        // maximum amount of token1
        uint amountMax1,
        // minimum amount of token1
        uint amountMin1,
        // minimum incremental amount of token1
        uint amountMinIncr1,
        // reserve amount of token1
        uint amountReserve1,
        // open at
        uint openAt,
        // duration
        uint duration,
        // only bot holder can bid the pool
        bool onlyBot
    ) public {
        require(!getDisableErc1155(), "ERC1155 pool is disabled");
        _create(name, token0, token1, tokenId, tokenAmount0, amountMax1, amountMin1, amountMinIncr1, amountReserve1, openAt, duration, onlyBot, TypeErc1155);
    }

    function _create(
        // name of the pool
        string memory name,
        // address of token0
        address token0,
        // address of token1
        address token1,
        // token id of token0
        uint tokenId,
        // amount of token id of token0
        uint tokenAmount0,
        // maximum amount of token1
        uint amountMax1,
        // minimum amount of token1
        uint amountMin1,
        // minimum incremental amount of token1
        uint amountMinIncr1,
        // reserve amount of token1
        uint amountReserve1,
        // open at
        uint openAt,
        // duration
        uint duration,
        // only bot holder can bid the pool
        bool onlyBot,
        // NFT token type
        uint nftType
    ) private {
        address payable creator = msg.sender;

//        require(tx.origin == msg.sender, "disallow contract caller");
        require(tokenAmount0 != 0, "invalid tokenAmount0");
        require(amountReserve1 == 0 || amountReserve1 >= amountMin1, "invalid amountReserve1");
        require(amountMax1 == 0 || (amountMax1 >= amountReserve1 && amountMax1 >= amountMin1), "invalid amountMax1");
        require(amountMinIncr1 != 0, "invalid amountMinIncr1");
        require(duration != 0, "invalid duration");
        require(bytes(name).length <= 32, "the length of name is too long");

        // transfer tokenId of token0 to this contract
        if (nftType == TypeErc721) {
            IERC721(token0).safeTransferFrom(creator, address(this), tokenId);
        } else {
            IERC1155(token0).safeTransferFrom(creator, address(this), tokenId, tokenAmount0, "");
        }

        // creator pool
        Pool memory pool;
        pool.creator = creator;
        pool.name = name;
        pool.token0 = token0;
        pool.token1 = token1;
        pool.tokenId = tokenId;
        pool.tokenAmount0 = tokenAmount0;
        pool.amountMax1 = amountMax1;
        pool.amountMin1 = amountMin1;
        pool.amountMinIncr1 = amountMinIncr1;
        pool.openAt = openAt;
        pool.closeAt = openAt.add(duration);
        pool.nftType = nftType;

        uint index = pools.length;
        reserveAmount1P[index] = amountReserve1;
        myCreatedP[msg.sender][index] = true;
        if (onlyBot) {
            onlyBotHolderP[index] = onlyBot;
        }

        pools.push(pool);

        emit Created(msg.sender, index, pool);
    }

    function bid(
        // pool index
        uint index,
        // amount of token1
        uint amount1
    ) external payable
        lock
        isPoolExist(index)
        checkBotHolder(index)
        isPoolNotClosed(index)
    {
        address payable sender = msg.sender;

        Pool storage pool = pools[index];
//        require(tx.origin == msg.sender, "disallow contract caller");
        require(pool.creator != sender, "creator can't bid the pool created by self");
        require(pool.openAt <= now, "pool is not open");
        require(amount1 != 0, "invalid amount1");
        require(amount1 >= pool.amountMin1, "the bid amount is lower than minimum bidder amount");
        require(amount1 >= currentBidderAmount(index), "the bid amount is lower than the current bidder amount");

        if (pool.token1 == address(0)) {
            require(amount1 == msg.value, "invalid ETH amount");
        } else {
            IERC20(pool.token1).safeTransferFrom(sender, address(this), amount1);
        }

        // return ETH to previous bidder
        if (currentBidderP[index] != address(0) && currentBidderAmount1P[index] > 0) {
            if (pool.token1 == address(0)) {
                currentBidderP[index].transfer(currentBidderAmount1P[index]);
            } else {
                IERC20(pool.token1).safeTransfer(currentBidderP[index], currentBidderAmount1P[index]);
            }
        }

        // record new winner
        currentBidderP[index] = sender;
        currentBidderAmount1P[index] = amount1;
        bidCountP[index] = bidCountP[index] + 1;
        myBidderAmount1P[sender][index] = amount1;

        emit Bid(sender, index, amount1);

        if (pool.amountMax1 > 0 && pool.amountMax1 <= amount1) {
            _creatorClaim(index);
            _bidderClaim(sender, index);
        }
    }

    function cancel(uint index) external
        isPoolExist(index)
    {
        Pool memory pool = pools[index];
        require(pool.openAt > now, "cannot cancel pool when pool is open");
        require(!creatorCanceledP[index], "pool has been cancelled");
        require(isCreator(msg.sender, index), "sender is not pool's creator");

        creatorCanceledP[index] = true;

        // transfer token0 back to creator
        if (pool.nftType == TypeErc721) {
            IERC721(pool.token0).safeTransferFrom(address(this), pool.creator, pool.tokenId);
            emit Canceled(pool.creator, index, pool.tokenId, 1);
        } else {
            IERC1155(pool.token0).safeTransferFrom(address(this), pool.creator, pool.tokenId, pool.tokenAmount0, "");
            emit Canceled(pool.creator, index, pool.tokenId, pool.tokenAmount0);
        }
    }

    function creatorClaim(uint index) external
        isPoolExist(index)
        isPoolClosed(index)
    {
        require(isCreator(msg.sender, index), "sender is not pool's creator");
        _creatorClaim(index);
    }

    function _creatorClaim(uint index) private {
        require(!creatorClaimedP[index], "creator has claimed");
        creatorClaimedP[index] = true;

        Pool memory pool = pools[index];
        uint amount1 = currentBidderAmount1P[index];
        if (currentBidderP[index] != address(0) && amount1 >= reserveAmount1P[index]) {
            (uint platformFee, uint royaltyFee, uint _actualAmount1) = IRoyaltyConfig(getFeeConfigContract())
                .getFeeAndRemaining(pools[index].token0, amount1);
            uint totalFee = platformFee.add(royaltyFee);
            if (pool.token1 == address(0)) {
                // transfer ETH to creator
                if (_actualAmount1 > 0) {
                    pool.creator.transfer(_actualAmount1);
                }
                IRoyaltyConfig(getFeeConfigContract())
                    .chargeFeeETH{value: totalFee}(pools[index].token0, platformFee, royaltyFee);
            } else {
                IERC20(pool.token1).safeTransfer(pool.creator, _actualAmount1);
                IERC20(pool.token1).safeApprove(getFeeConfigContract(), totalFee);
                IRoyaltyConfig(getFeeConfigContract())
                    .chargeFeeToken(pools[index].token0, pools[index].token1, address(this), platformFee, royaltyFee);
            }
            emit CreatorClaimed(pool.creator, index, pool.tokenId, 0, amount1);
        } else {
            // transfer token0 back to creator
            if (pool.nftType == TypeErc721) {
                IERC721(pool.token0).safeTransferFrom(address(this), pool.creator, pool.tokenId);
                emit CreatorClaimed(pool.creator, index, pool.tokenId, 1, 0);
            } else {
                IERC1155(pool.token0).safeTransferFrom(address(this), pool.creator, pool.tokenId, pool.tokenAmount0, "");
                emit CreatorClaimed(pool.creator, index, pool.tokenId, pool.tokenAmount0, 0);
            }
        }
    }

    function bidderClaim(uint index) external
        isPoolExist(index)
        isPoolClosed(index)
    {
        _bidderClaim(msg.sender, index);
    }

    function withdrawFee(address payable to, uint amount) external governance {
        totalTxFee = totalTxFee.sub(amount);
        to.transfer(amount);
    }

    function withdrawToken(address token, address to, uint amount) external governance {
        IERC20(token).safeTransfer(to, amount);
    }

    function setFeeConfigContract(address feeConfigContract) external governance {
        config[FeeConfigContract] = uint(feeConfigContract);
    }

    function transferGovernor(address _governor) external {
        require(msg.sender == governor || governor == address(0), "invalid governor");
        governor = _governor;
    }

    function _bidderClaim(address payable sender, uint index) private {
        require(currentBidderP[index] == sender, "sender is not winner");
        require(!myClaimedP[sender][index], "sender has claimed");
        myClaimedP[sender][index] = true;

        uint amount1 = currentBidderAmount1P[index];
        Pool memory pool = pools[index];
        if (amount1 >= reserveAmount1P[index]) {
            // transfer token0 to bidder
            if (pool.nftType == TypeErc721) {
                IERC721(pool.token0).safeTransferFrom(address(this), sender, pool.tokenId);
                emit BidderClaimed(sender, index, pool.tokenId, 1, 0);
            } else {
                IERC1155(pool.token0).safeTransferFrom(address(this), sender, pool.tokenId, pool.tokenAmount0, "");
                emit BidderClaimed(sender, index, pool.tokenId, pool.tokenAmount0, 0);
            }
        } else {
            // transfer token1 back to bidder
            if (pool.token1 == address(0)) {
                sender.transfer(amount1);
            } else {
                IERC20(pool.token1).safeTransfer(sender, amount1);
            }
            emit BidderClaimed(sender, index, pool.tokenId, 0, amount1);
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns(bytes4) {
        return this.onERC1155Received.selector;
    }

    function getPoolCount() external view returns (uint) {
        return pools.length;
    }

    function currentBidderAmount(uint index) public view returns (uint) {
        Pool memory pool = pools[index];
        uint amount = pool.amountMin1;

        if (currentBidderP[index] != address(0)) {
            amount = currentBidderAmount1P[index].add(pool.amountMinIncr1);
        } else if (pool.amountMin1 == 0) {
            amount = pool.amountMinIncr1;
        }

        return amount;
    }

    function isCreator(address target, uint index) private view returns (bool) {
        if (pools[index].creator == target) {
            return true;
        }
        return false;
    }

    function getMinValueOfBotHolder() public view returns (uint) {
        return config[MinValueOfBotHolder];
    }

    function getDisableErc721() public view returns (bool) {
        return config[DisableErc721] != 0;
    }

    function getDisableErc1155() public view returns (bool) {
        return config[DisableErc1155] != 0;
    }

    function getBotToken() public view returns (address) {
        return address(config[BotToken]);
    }

    function getFeeConfigContract() public view returns (address) {
        return address(config[FeeConfigContract]);
    }

    modifier checkBotHolder(uint index) {
        if (onlyBotHolderP[index]) {
            require(
                getMinValueOfBotHolder() > 0 && IERC20(getBotToken()).balanceOf(msg.sender) >= getMinValueOfBotHolder(),
                "BOT is not enough"
            );
        }
        _;
    }

    modifier isPoolClosed(uint index) {
        require(pools[index].closeAt <= now || creatorClaimedP[index], "this pool is not closed");
        _;
    }

    modifier isPoolNotClosed(uint index) {
        require(pools[index].closeAt > now && !creatorClaimedP[index], "this pool is closed");
        _;
    }

    modifier isPoolExist(uint index) {
        require(index < pools.length, "this pool does not exist");
        _;
    }

    modifier lock() {
        require(unlocked == 1, 'LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.2;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

pragma solidity ^0.6.2;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

pragma solidity ^0.6.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}


contract Governable is Initializable {
    address public governor;

    event GovernorshipTransferred(address indexed previousGovernor, address indexed newGovernor);

    /**
     * @dev Contract initializer.
     * called once by the factory at time of deployment
     */
    function initialize(address governor_) virtual public initializer {
        governor = governor_;
        emit GovernorshipTransferred(address(0), governor);
    }

    modifier governance() {
        require(msg.sender == governor);
        _;
    }

    /**
     * @dev Allows the current governor to relinquish control of the contract.
     * @notice Renouncing to governorship will leave the contract without an governor.
     * It will not be possible to call the functions with the `governance`
     * modifier anymore.
     */
    function renounceGovernorship() public governance {
        emit GovernorshipTransferred(governor, address(0));
        governor = address(0);
    }

    /**
     * @dev Allows the current governor to transfer control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function transferGovernorship(address newGovernor) public governance {
        _transferGovernorship(newGovernor);
    }

    /**
     * @dev Transfers control of the contract to a newGovernor.
     * @param newGovernor The address to transfer governorship to.
     */
    function _transferGovernorship(address newGovernor) internal {
        require(newGovernor != address(0));
        emit GovernorshipTransferred(governor, newGovernor);
        governor = newGovernor;
    }
}


contract Configurable is Governable {

    mapping (bytes32 => uint) internal config;
    
    function getConfig(bytes32 key) public view returns (uint) {
        return config[key];
    }
    function getConfig(bytes32 key, uint index) public view returns (uint) {
        return config[bytes32(uint(key) ^ index)];
    }
    function getConfig(bytes32 key, address addr) public view returns (uint) {
        return config[bytes32(uint(key) ^ uint(addr))];
    }

    function _setConfig(bytes32 key, uint value) internal {
        if(config[key] != value)
            config[key] = value;
    }
    function _setConfig(bytes32 key, uint index, uint value) internal {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function _setConfig(bytes32 key, address addr, uint value) internal {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
    
    function setConfig(bytes32 key, uint value) external governance {
        _setConfig(key, value);
    }
    function setConfig(bytes32 key, uint index, uint value) external governance {
        _setConfig(bytes32(uint(key) ^ index), value);
    }
    function setConfig(bytes32 key, address addr, uint value) public governance {
        _setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transfered from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IRoyaltyConfig {
    function getFeeAndRemaining(address brand, uint amount) external view returns (uint platformFee, uint royaltyFee, uint remaining);

    function chargeFeeETH(address brand, uint platformFee, uint royaltyFee) external payable;

    function chargeFeeToken(address brand, address token, address from, uint platformFee, uint royaltyFee) external;
}

pragma solidity ^0.6.0;

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