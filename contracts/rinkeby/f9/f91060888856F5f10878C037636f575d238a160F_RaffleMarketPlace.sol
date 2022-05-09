// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

import "./interfaces/IRaffleFactory.sol";

error Goobig__NotOwner();
error Goobig__TransferFailed();
error Goobig__InvalidTicketType();
error Goobig__InvalidDuration();
error Goobig__InvalidNFTAddress();
error Goobig__InvalidFee();
error Goobig__NotAvailableRaffle();
error Goobig__InvalidBuyTickets();
error Goobig__NotEnoughBuyTickets();
error Goobig__SendMoreToRegisterRaffle();
error Goobig__InvalidCancel();
error Goobig__InvalidExcute();
error Goobig__UpkeepNotNeeded(
    uint256 totalRaffles,
    uint256 totalActiveRaffles,
    uint256 raffleId
);
error Goobig__NotSeller();

/* Type declarations */
enum RaffleState {
    OPEN,
    PENDING,
    CANCELED,
    CLOSED
}

contract RaffleMarketPlace is
    Ownable,
    ERC721Holder,
    VRFConsumerBaseV2,
    KeeperCompatibleInterface
{
    using SafeMath for uint256;

    struct RaffleData {
        address raffleAddress;
        address nftAddress;
        uint256 tokenId;
        uint256 totalTickets;
        uint256 ticketPrice;
        uint256 totalPrice;
        uint256 duration;
        address seller;
        uint256 created;
        uint256 soldTickets;
        RaffleState raffleState;
    }
    /* Fee Variables */
    uint256 public constant MAX_FEE_BY_MILLION = 30000; // 3%
    uint256 public s_feeByMillion;

    /* Chainlnk VRF Variables */
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    mapping(uint256 => uint256) private requestIdToRaffleId;

    /* Raffle Variables */
    uint256 public s_registerFee;
    uint256 public MAX_ONETIME_PURCHASE = 5;
    uint256[3] public NUMBER_OF_TICKETS_BY_TYPE = [10, 100, 1000];
    mapping(uint256 => RaffleData) public s_raffles;

    uint256 public s_totalRaffleCounter;
    address public s_raffleFactoryAddress;
    uint256 public s_pendingPreiod;

    uint private unlocked = 1;

    /* Events */
    event ChangedFee(uint256 feeByMillion);
    event ChangedRegisterFee(uint256 registerFee);
    event ChaingedPendingPeriod(uint256 pendingPeriod);

    event RaffleRegister(
        uint256 indexed raffleId,
        address indexed seller,
        address indexed nftAddress,
        uint256 tokenId,
        address raffleAddress,
        uint256 ticketPrice,
        uint256 totalTickets,
        uint256 duration,
        uint256 timeStamp
    );

    event SoldTickets(
        uint256 indexed raffleId,
        address indexed buyer,
        uint256 indexed tickets
    );

    event RequestedRaffleWinner(
        uint256 indexed raffleId,
        uint256 indexed requestId
    );

    event WinnerPicked(uint256 indexed raffleId, uint256 indexed winnerTicket);

    event SoldNFT(
        uint256 indexed raffleId,
        address indexed from,
        address indexed to,
        address nftAddress,
        uint256 tokenId
    );

    event ExcuteRaffle(uint256 indexed raffleId);
    event CancelRaffle(uint256 indexed raffleId);

    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint32 callbackGasLimit,
        address raffleFactoryAddress,
        uint256 pendingPreiod
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_registerFee = 1e16; // for Only Test
        s_totalRaffleCounter = 0;
        s_feeByMillion = 30000; // 3%
        s_raffleFactoryAddress = raffleFactoryAddress;
        s_pendingPreiod = pendingPreiod;
    }

    modifier lock() {
        require(unlocked == 1, "Goobig: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function setFeeByMillion(uint256 feeByMillion) external lock onlyOwner {
        if (feeByMillion > MAX_FEE_BY_MILLION) {
            revert Goobig__InvalidFee();
        }
        s_feeByMillion = feeByMillion;
        emit ChangedFee(s_feeByMillion);
    }

    function setRegisterFee(uint256 registerFee) external lock onlyOwner {
        s_registerFee = registerFee;
        emit ChangedRegisterFee(registerFee);
    }

    function setPendingPeriod(uint256 pendingPeriod) external lock onlyOwner {
        s_pendingPreiod = pendingPeriod;
        emit ChaingedPendingPeriod(pendingPeriod);
    }

    function registerRaffle(
        address nftAddress,
        uint256 tokenId,
        uint256 ticketType,
        uint256 ticketPrice,
        uint256 duration
    ) external payable lock {
        if (msg.value < s_registerFee) {
            revert Goobig__SendMoreToRegisterRaffle();
        }
        IERC721 nftCollection = IERC721(nftAddress);
        address assetOwner = nftCollection.ownerOf(tokenId);

        if (assetOwner != msg.sender) {
            revert Goobig__NotOwner();
        }
        if (ticketType > 2 || ticketType < 0) {
            revert Goobig__InvalidTicketType();
        }
        if (duration < 3600) {
            revert Goobig__InvalidDuration();
        }

        nftCollection.safeTransferFrom(assetOwner, address(this), tokenId);

        uint256 totalTickets = NUMBER_OF_TICKETS_BY_TYPE[ticketType];
        IRaffleFactory raffleFactory = IRaffleFactory(s_raffleFactoryAddress);
        address raffleAddress = raffleFactory.createRaffle(nftAddress, tokenId);
        RaffleData memory raffle = RaffleData({
            raffleAddress: raffleAddress,
            nftAddress: nftAddress,
            tokenId: tokenId,
            totalTickets: totalTickets,
            ticketPrice: ticketPrice,
            totalPrice: ticketPrice.mul(totalTickets),
            duration: duration,
            seller: msg.sender,
            created: block.timestamp,
            soldTickets: 0,
            raffleState: RaffleState.OPEN
        });
        uint256 totalRaffleCounter = s_totalRaffleCounter;
        s_raffles[totalRaffleCounter] = raffle;
        s_totalRaffleCounter = totalRaffleCounter + 1;
        emit RaffleRegister(
            totalRaffleCounter,
            msg.sender,
            nftAddress,
            tokenId,
            raffleAddress,
            ticketPrice,
            totalTickets,
            duration,
            block.timestamp
        );
    }

    function buyTickets(uint256 raffleId, uint256 tickets) public payable lock {
        if (raffleId >= s_totalRaffleCounter) {
            revert Goobig__NotAvailableRaffle();
        }
        RaffleData storage raffle = s_raffles[raffleId];
        if (raffle.created + raffle.duration + s_pendingPreiod < block.timestamp) {
            revert Goobig__NotAvailableRaffle();
        }
        uint256 soldTickets = raffle.soldTickets;
        address raffleAddress = raffle.raffleAddress;
        uint256 ticketPrice = raffle.ticketPrice;
        uint256 totalTickets = raffle.totalTickets;

        if (tickets > MAX_ONETIME_PURCHASE || tickets == 0) {
            revert Goobig__InvalidBuyTickets();
        }
        if (soldTickets + tickets > totalTickets) {
            revert Goobig__InvalidBuyTickets();
        }
        if (msg.value < ticketPrice.mul(tickets)) {
            revert Goobig__NotEnoughBuyTickets();
        }
        IRaffleFactory raffleFactory = IRaffleFactory(s_raffleFactoryAddress);
        raffleFactory.buyRaffleTickets(raffleAddress, msg.sender, tickets);
        raffle.soldTickets = soldTickets + tickets;
        emit SoldTickets(raffleId, msg.sender, tickets);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool _upkeepNeeded = false;
        for (uint256 i = 0; i < s_totalRaffleCounter; i++) {
            RaffleData memory raffle = s_raffles[i];
            if (raffle.raffleState == RaffleState.OPEN) {
                /* check if all tickets was sold in every open raffles */
                if (raffle.soldTickets == raffle.totalTickets) {
                    _upkeepNeeded = true;
                    break;
                }
                /* check if time is over in every open raffles */
                if (raffle.created + raffle.duration < block.timestamp) {
                    _upkeepNeeded = true;
                    break;
                }
            } else if (raffle.raffleState == RaffleState.PENDING) {
                /* check the pending period */
                if (
                    raffle.created + raffle.duration + s_pendingPreiod <
                    block.timestamp
                ) {
                    _upkeepNeeded = true;
                    break;
                }
            }
        }
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = _upkeepNeeded && hasBalance;
        return (upkeepNeeded, "0x0");
    }

    /**
     * Once `checkUpkeep` is returning `true`, this function is called and Chainlink VRF call to get a random winner.
     */
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");

        if (upkeepNeeded) {
            /** process for single VRF ----------------  */
            for (uint256 i = 0; i < s_totalRaffleCounter; i++) {
                RaffleData storage raffle = s_raffles[i];
                if (raffle.raffleState == RaffleState.OPEN) {
                    /* check if all tickets was sold in every active raffles */
                    if (raffle.soldTickets == raffle.totalTickets) {
                        sellNft(i);
                        break;
                    }
                    /* check if time is over in every active raffles */
                    if (raffle.created + raffle.duration < block.timestamp) {
                        raffle.raffleState = RaffleState.PENDING;
                    }
                } else if (raffle.raffleState == RaffleState.PENDING) {
                    if (
                        raffle.created + raffle.duration + s_pendingPreiod <
                        block.timestamp
                    ) {
                        if (raffle.soldTickets > 0) {
                            sellNft(i);
                        } else {
                            refundNFT(i);
                        }
                        break;
                    }
                }
            }
        }
    }

    function sellNft(uint256 raffleId) internal {
        RaffleData storage raffle = s_raffles[raffleId];
        raffle.raffleState = RaffleState.CLOSED; // closed
        /** process choose the winner */
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        requestIdToRaffleId[requestId] = raffleId;
        emit RequestedRaffleWinner(raffleId, requestId);
    }

    function excuteRaffle(uint256 raffleId) external lock {
        RaffleData memory raffle = s_raffles[raffleId];
        if (msg.sender != raffle.seller) {
            revert Goobig__NotSeller();
        }
        if (raffle.raffleState != RaffleState.PENDING) {
            revert Goobig__InvalidExcute();
        }
        sellNft(raffleId);
        emit ExcuteRaffle(raffleId);
    }

    function refundNFT(uint256 raffleId) internal {
        RaffleData storage raffle = s_raffles[raffleId];
        raffle.raffleState = RaffleState.CANCELED;
        IERC721 nftContract = IERC721(raffle.nftAddress);
        raffle.raffleState = RaffleState.CANCELED;
        nftContract.transferFrom(address(this), raffle.seller, raffle.tokenId);
        emit CancelRaffle(raffleId);
    }

    function cancelRaffle(uint256 raffleId) external lock {
        RaffleData storage raffle = s_raffles[raffleId];
        if (msg.sender != raffle.seller) {
            revert Goobig__NotSeller();
        }
        if (raffle.raffleState != RaffleState.PENDING) {
            revert Goobig__InvalidCancel();
        }
        IRaffleFactory raffleFactory = IRaffleFactory(s_raffleFactoryAddress);
        for (uint256 i = 0; i < raffle.soldTickets; i++) {
            address payable buyer = payable(
                raffleFactory.ownerOfTicket(raffle.raffleAddress, i)
            );
            (bool success, ) = buyer.call{value: raffle.ticketPrice}("");
            if (!success) {
                revert Goobig__TransferFailed();
            }
        }
        IERC721 nftContract = IERC721(raffle.nftAddress);
        raffle.raffleState = RaffleState.CANCELED;
        nftContract.transferFrom(address(this), raffle.seller, raffle.tokenId);
        emit CancelRaffle(raffleId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 raffleId = requestIdToRaffleId[requestId];
        RaffleData memory raffle = s_raffles[raffleId];
        uint256 winnerTicket = randomWords[0] % raffle.soldTickets;
        address payable seller = payable(raffle.seller);
        IRaffleFactory raffleFactory = IRaffleFactory(s_raffleFactoryAddress);
        address winner = raffleFactory.ownerOfTicket(
            raffle.raffleAddress,
            winnerTicket
        );
        /** Fee management */
        // send NFT to winner;
        IERC721 nftContract = IERC721(raffle.nftAddress);
        nftContract.transferFrom(address(this), winner, raffle.tokenId);
        // send ETH to seller
        uint256 cost = raffle.ticketPrice.mul(raffle.soldTickets);
        uint256 fee = cost.mul(s_feeByMillion).div(1000000);
        (bool success1, ) = seller.call{value: cost.sub(fee)}("");
        if (!success1) {
            revert Goobig__TransferFailed();
        }
        // send ETH to owner
        address payable feeAcount = payable(owner());
        (bool success2, ) = feeAcount.call{value: fee}("");
        if (!success2) {
            revert Goobig__TransferFailed();
        }

        emit WinnerPicked(raffleId, winnerTicket);
        emit SoldNFT(
            raffleId,
            seller,
            winner,
            raffle.nftAddress,
            raffle.tokenId
        );
    }

    /** get functions */
    function getRaffles() public view returns (RaffleData[] memory raffles) {
        raffles = new RaffleData[](s_totalRaffleCounter);
        for (uint256 i = 0; i < s_totalRaffleCounter; i++) {
            raffles[i] = s_raffles[i];
        }
        return raffles;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRaffleFactory {
    function createRaffle(address nftAddress, uint256 tokenId)
        external
        returns (address);

    function buyRaffleTickets(
        address raffleAddress,
        address to,
        uint256 tickets
    ) external;

    function ownerOfTicket(address raffleAddress, uint256 ticketId) external view returns (address);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
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