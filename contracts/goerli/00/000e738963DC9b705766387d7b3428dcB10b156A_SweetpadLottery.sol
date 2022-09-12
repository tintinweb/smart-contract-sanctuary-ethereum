//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRandomNumberGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 lotteryId) external returns (bytes32 requestId);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;
// Imported OZ helper contracts
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/proxy/Initializable.sol";
// Inherited allowing for ownership of contract
import "@openzeppelin/contracts/access/Ownable.sol";
// Allows for intergration with ChainLink VRF
import "./interfaces/IRandomNumberGenerator.sol";
// Interface for Lottery NFT to mint tokens
import "./interfaces/ISweetpadTicket.sol";


// Allows for time manipulation. Set to 0x address on test/mainnet deploy
// import "./Testable.sol";

contract SweetpadLottery is Ownable {
    // Libraries
    using SafeMath for uint256;
    // Safe ERC20
    using SafeERC20 for IERC20;
    // Address functionality
    using Address for address;

    // State variables
    // Instance of Cake token (collateral currency for lotto)
    // IERC20 internal cake_;
    // Storing of the NFT
    // TODO check
    // ISweetpadTicket internal nft_;
    // Storing of the randomness generator
    IRandomNumberGenerator internal randomGenerator_;
    // Request ID for random number
    bytes32 internal requestId_;
    // Counter for lottery IDs
    uint256 private lotteryIdCounter_;

    // Lottery size
    uint16 public sizeOfLottery_;
    // Max range for numbers (starting at 0)
    uint16 public maxValidRange_;

    // Represents the status of the lottery
    enum Status {
        NotStarted, // The lottery has not started yet
        Open, // The lottery is open for ticket purchases
        Closed, // The lottery is no longer open for ticket purchases
        Completed // The lottery has been closed and the numbers drawn
    }
    // All the needed info around a lottery
    struct LottoInfo {
        uint256 lotteryID; // ID for lotto
        Status lotteryStatus; // Status for lotto
        address ido;
        // uint256 prizePoolInCake;    // The amount of cake for prize money
        // uint256 costPerTicket;      // Cost per ticket in $cake
        // uint8[] prizeDistribution;  // The distribution for prize money
        uint256 startingTimestamp; // Block timestamp for star of lotto
        uint256 closingTimestamp; // Block timestamp for end of entries
        uint16[] winningNumbers; // The winning numbers
    }
    // Lottery ID's to info
    mapping(uint256 => LottoInfo) internal allLotteries_;
    mapping(uint256 => uint256) public rendomNumbers;
    mapping(address => uint256) public idoToId;

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event RequestNumbers(uint256 lotteryId, bytes32 requestId);

    event UpdatedSizeOfLottery(address admin, uint16 newLotterySize);

    event UpdatedMaxRange(address admin, uint16 newMaxRange);

    event LotteryOpen(uint256 lotteryId, uint256 ticketSupply);

    event LotteryClose(uint256 lotteryId, uint256 ticketSupply);

    //-------------------------------------------------------------------------
    // MODIFIERS
    //-------------------------------------------------------------------------

    modifier onlyRandomGenerator() {
        require(msg.sender == address(randomGenerator_), "Only random generator");
        _;
    }

    modifier notContract() {
        require(!address(msg.sender).isContract(), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    //-------------------------------------------------------------------------
    // CONSTRUCTOR
    //-------------------------------------------------------------------------

    constructor(
        // address _cake,
        // address _timer,
        uint8 _sizeOfLotteryNumbers,
        uint16 _maxValidNumberRange // uint8 _bucketOneMaxNumber, // TODO check // address lotteryNFT_ // Testable(_timer)
    ) {
        // require(
        //     _discountForBucketOne < _discountForBucketTwo &&
        //     _discountForBucketTwo < _discountForBucketThree,
        //     "Discounts must increase"
        // );
        // require(
        //     _cake != address(0),
        //     "Contracts cannot be 0 address"
        // );
        require(_sizeOfLotteryNumbers != 0 && _maxValidNumberRange != 0, "Lottery setup cannot be 0");
        // require(lotteryNFT_ != address(0), "Contracts cannot be 0 address");
        // nft_ = ISweetpadTicket(lotteryNFT_);
        // cake_ = IERC20(_cake);
        sizeOfLottery_ = _sizeOfLotteryNumbers;
        maxValidRange_ = _maxValidNumberRange;

        // bucketOneMax_ = _bucketOneMaxNumber;
        // bucketTwoMax_ = _bucketTwoMaxNumber;
        // discountForBucketOne_ = _discountForBucketOne;
        // discountForBucketTwo_ = _discountForBucketTwo;
        // discountForBucketThree_ = _discountForBucketThree;
    }

    // function initialize(
    //     address _lotteryNFT,
    //     address _IRandomNumberGenerator
    // )
    //     external
    //     initializer
    //     onlyOwner()
    // {
    //     require(
    //         _lotteryNFT != address(0) &&
    //         _IRandomNumberGenerator != address(0),
    //         "Contracts cannot be 0 address"
    //     );
    //     nft_ = ILotteryNFT(_lotteryNFT);
    //     randomGenerator_ = IRandomNumberGenerator(_IRandomNumberGenerator);
    // }

    function getBasicLottoInfo(uint256 _lotteryId) external view returns (LottoInfo memory) {
        return (allLotteries_[_lotteryId]);
    }

    function getMaxRange() external view returns (uint16) {
        return maxValidRange_;
    }

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------

    //-------------------------------------------------------------------------
    // Restricted Access Functions (onlyOwner)

    function setRendomGenerator(address randomNumberGenerator_) external onlyOwner {
        require(randomNumberGenerator_ != address(0), "Contracts cannot be 0 address");
        randomGenerator_ = IRandomNumberGenerator(randomNumberGenerator_);
    }

    function updateSizeOfLottery(uint16 _newSize) external onlyOwner {
        require(sizeOfLottery_ != _newSize, "Cannot set to current size");
        require(sizeOfLottery_ != 0, "Lottery size cannot be 0");
        sizeOfLottery_ = _newSize;

        emit UpdatedSizeOfLottery(msg.sender, _newSize);
    }

    function updateMaxRange(uint16 _newMaxRange) external onlyOwner {
        require(maxValidRange_ != _newMaxRange, "Cannot set to current size");
        require(maxValidRange_ != 0, "Max range cannot be 0");
        maxValidRange_ = _newMaxRange;

        emit UpdatedMaxRange(msg.sender, _newMaxRange);
    }

    function drawWinningNumbers(uint256 _lotteryId) external onlyOwner {
        // Checks that the lottery is past the closing block
        require(
            allLotteries_[_lotteryId].closingTimestamp <= block.timestamp,
            "Cannot set winning numbers during lottery"
        );
        // Checks lottery numbers have not already been drawn
        require(allLotteries_[_lotteryId].lotteryStatus == Status.Open || allLotteries_[_lotteryId].lotteryStatus == Status.NotStarted, "Lottery State incorrect for draw");
        // Sets lottery status to closed
        allLotteries_[_lotteryId].lotteryStatus = Status.Closed;
        // Requests a random number from the generator
        requestId_ = randomGenerator_.getRandomNumber(_lotteryId);
        // Emits that random number has been requested
        emit RequestNumbers(_lotteryId, requestId_);
    }

    function numbersDrawn(
        uint256 _lotteryId,
        bytes32 _requestId,
        uint256 _randomNumber
    ) external onlyRandomGenerator {
        require(allLotteries_[_lotteryId].lotteryStatus == Status.Closed, "Draw numbers first");
        if (requestId_ == _requestId) {
            allLotteries_[_lotteryId].lotteryStatus = Status.Completed;
            // allLotteries_[_lotteryId].winningNumbers = _split(_randomNumber); // TODO
        }
        rendomNumbers[_lotteryId] = _randomNumber;
        // TODO fix
        // emit LotteryClose(_lotteryId, nft_.getTotalSupply());
    }

    function getWiningNumbers(uint256 _lotteryId) external {
        require(allLotteries_[_lotteryId].lotteryStatus == Status.Completed, "Draw numbers first");
        allLotteries_[_lotteryId].winningNumbers = _split(rendomNumbers[_lotteryId]);
    }

    // * @param   _prizeDistribution An array defining the distribution of the
    //  *          prize pool. I.e if a lotto has 5 numbers, the distribution could
    //  *          be [5, 10, 15, 20, 30] = 100%. This means if you get one number
    //  *          right you get 5% of the pool, 2 matching would be 10% and so on.
    //  * @param   _prizePoolInCake The amount of Cake available to win in this
    //  *          lottery.

    /**
     * @param   _startingTimestamp The block timestamp for the beginning of the
     *          lottery.
     * @param   _closingTimestamp The block timestamp after which no more tickets
     *          will be sold for the lottery. Note that this timestamp MUST
     *          be after the starting block timestamp.
     */
    //  TODO add functionaliti to connect lottery and ido
    function createNewLotto(
        // uint8[] calldata _prizeDistribution,
        // uint256 _prizePoolInCake,
        // uint256 _costPerTicket,
        uint256 _startingTimestamp,
        uint256 _closingTimestamp,
        address _ido
    ) external onlyOwner returns (uint256 lotteryId) {
        require(_startingTimestamp != 0 && _startingTimestamp < _closingTimestamp, "Timestamps for lottery invalid");
        require(idoToId[_ido] == 0, "SweetpadLottery: Lottery for current IDO contract was already created");
        // Incrementing lottery ID
        lotteryIdCounter_ = lotteryIdCounter_ + 1;
        lotteryId = lotteryIdCounter_;
        uint16[] memory winningNumbers = new uint16[](sizeOfLottery_);
        Status lotteryStatus;
        if (_startingTimestamp >= block.timestamp) {
            lotteryStatus = Status.Open;
        } else {
            lotteryStatus = Status.NotStarted;
        }
        // Saving data in struct
        LottoInfo memory newLottery = LottoInfo(
            lotteryId,
            lotteryStatus,
            _ido,
            // _prizePoolInCake,
            // _costPerTicket,
            // _prizeDistribution,
            _startingTimestamp,
            _closingTimestamp,
            winningNumbers
        );
        allLotteries_[lotteryId] = newLottery;
        idoToId[_ido] = lotteryId;
        // TODO fix
        // Emitting important information around new lottery.
        // emit LotteryOpen(
        //     lotteryId,
        //     nft_.getTotalSupply()
        // );
    }

    //-------------------------------------------------------------------------
    // General Access Functions

    // claim reward don't remove!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    // function claimReward(uint256 _lotteryId, uint256 _tokenId) external notContract() {
    //     // Checking the lottery is in a valid time for claiming
    //     require(
    //         allLotteries_[_lotteryId].closingTimestamp <= block.timestamp,
    //         "Wait till end to claim"
    //     );
    //     // Checks the lottery winning numbers are available
    //     require(
    //         allLotteries_[_lotteryId].lotteryStatus == Status.Completed,
    //         "Winning Numbers not chosen yet"
    //     );
    //     require(
    //         nft_.getOwnerOfTicket(_tokenId) == msg.sender,
    //         "Only the owner can claim"
    //     );
    //     // Sets the claim of the ticket to true (if claimed, will revert)
    //     require(
    //         nft_.claimTicket(_tokenId, _lotteryId),
    //         "Numbers for ticket invalid"
    //     );
    //     // Getting the number of matching tickets
    //     uint8 matchingNumbers = _getNumberOfMatching(
    //         nft_.getTicketNumbers(_tokenId),
    //         allLotteries_[_lotteryId].winningNumbers
    //     );
    //     // Getting the prize amount for those matching tickets
    //     uint256 prizeAmount = _prizeForMatching(
    //         matchingNumbers,
    //         _lotteryId
    //     );
    //     // Removing the prize amount from the pool
    //     allLotteries_[_lotteryId].prizePoolInCake = allLotteries_[_lotteryId].prizePoolInCake.sub(prizeAmount);
    //     // Transfering the user their winnings
    //     cake_.safeTransfer(address(msg.sender), prizeAmount);
    // }

    //-------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //-------------------------------------------------------------------------

    // TODO start tickets ids from 1 and check if user number is 0 breack
    // TODO fix functionality
    function getNumberOfMatching(uint16[] memory _usersNumbers, uint16[] memory _winningNumbers)
        public
        pure
        returns (uint8 noOfMatching)
    {
        // Loops through all wimming numbers
        for (uint256 i = 0; i < _winningNumbers.length; i++) {
            // If the winning numbers and user numbers match
            if (_usersNumbers[i] == _winningNumbers[i]) {
                // The number of matching numbers incrases
                noOfMatching += 1;
            }
        }
    }

    function _split(uint256 _randomNumber) internal view returns (uint16[] memory) {
        // Temparary storage for winning numbers
        uint16[] memory winningNumbers = new uint16[](sizeOfLottery_);
        // Loops the size of the number of tickets in the lottery
        for (uint256 i = 0; i < sizeOfLottery_; i++) {
            uint256 duplicated;
            // Encodes the random number with its position in loop
            bytes32 hashOfRandom = keccak256(abi.encodePacked(_randomNumber, i));
            // Casts random number hash into uint256
            uint256 numberRepresentation = uint256(hashOfRandom);
            // Sets the winning number position to a uint16 of random hash number
            for (uint256 j = 0; j < winningNumbers.length; j++) {
                if (winningNumbers[j] > 0) {
                    if (winningNumbers[j] == uint16(numberRepresentation.mod(maxValidRange_))) {
                        duplicated += 1;
                    }
                }
            }
            if (duplicated > 0) {
                continue;
            }
            winningNumbers[i] = uint16(numberRepresentation.mod(maxValidRange_));
        }
        return winningNumbers;
    }

    function getOpenLotteries() public view returns (uint256[] memory openLotteries) {
        for (uint256 i = 1; i <= lotteryIdCounter_; i++) {
            if (allLotteries_[i].closingTimestamp > block.timestamp) {
                openLotteries[i - 1] = allLotteries_[i].lotteryID;
            }
        }
        return openLotteries;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
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

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface ISweetpadTicket is IERC721, IERC721Metadata {
    function totalTickets() external returns (uint256);

    function mint(
        address,
        uint256,
        address
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "./interfaces/ISweetpadNFTFreezing.sol";
import "./interfaces/ISweetpadNFT.sol";
import "./interfaces/ISweetpadTicket.sol";

import "./SweetpadLottery.sol";


contract SweetpadNFTFreezing is ISweetpadNFTFreezing, Ownable, ERC721Holder {
    /// @notice Blocks per day for BSC
    uint256 private constant BLOCKS_PER_DAY = 10; // TODO for mainnet change to 28674
    uint256 private constant MIN_PERIOD = 182 * BLOCKS_PER_DAY;
    uint256 private constant MAX_PERIOD = 1095 * BLOCKS_PER_DAY;

    ISweetpadNFT public override nft;
    ISweetpadTicket public override ticket;
    SweetpadLottery public override lottery;

    /// @notice NFT id -> frozen NFT data
    mapping(uint256 => NFTData) public override nftData;
    /// @notice user address -> NFT id's freezed by user
    mapping(address => uint256[]) public userNFTs;
    mapping(uint256 => uint256) public ticketsPerNFT;
    mapping(address => mapping(address => uint256[])) public ticketsForIdo;

    constructor(address _nft, address _ticket) {
        setSweetpadNFT(_nft);
        setSweetpadTicket(_ticket);
    }

    /**
     * @notice Freeze Sweetpad NFT
     * @param nftId: the id of the NFT
     * @param freezePeriod: freezing period in blocks
     */
    function freeze(uint256 nftId, uint256 freezePeriod) external override {
        uint256 ticketsToMint = freezePeriod == MAX_PERIOD
            ? nft.getTicketsQuantityById(nftId) * 2
            : nft.getTicketsQuantityById(nftId);

        uint256 freezeEndBlock = _freeze(nftId, freezePeriod, ticketsToMint);

        emit Froze(msg.sender, nftId, freezeEndBlock, ticketsToMint);

        nft.safeTransferFrom(msg.sender, address(this), nftId);
    }

    /**
     * @notice Freeze Sweetpad NFTs
     * @param nftIds: the ids of the NFT
     * @param freezePeriods: freezing periods in blocks
     */
    function freezeBatch(uint256[] calldata nftIds, uint256[] calldata freezePeriods) external override {
        require(nftIds.length == freezePeriods.length, "SweetpadNFTFreezing: Array lengths is not equal");

        uint256 len = nftIds.length;
        uint256[] memory ticketsToMintBatch = new uint256[](len);
        uint256[] memory freezeEndBlocks = new uint256[](len);
        ticketsToMintBatch = nft.getTicketsQuantityByIds(nftIds);

        for (uint256 i = 0; i < len; i++) {
            if (freezePeriods[i] == MAX_PERIOD) {
                ticketsToMintBatch[i] = ticketsToMintBatch[i] * 2;
            }
            freezeEndBlocks[i] = _freeze(nftIds[i], freezePeriods[i], ticketsToMintBatch[i]);
        }
        emit FrozeBatch(msg.sender, nftIds, freezeEndBlocks, ticketsToMintBatch);

        nft.safeBatchTransferFrom(msg.sender, address(this), nftIds, "0x00");
    }

    function unfreeze(uint256 nftId) external override {
        _unfreeze(nftId);

        emit Unfroze(msg.sender, nftId);

        nft.safeTransferFrom(address(this), msg.sender, nftId);
    }

    function unfreezeBatch(uint256[] calldata nftIds) external override {
        for (uint256 i = 0; i < nftIds.length; i++) {
            _unfreeze(nftIds[i]);
        }

        emit UnfrozeBatch(msg.sender, nftIds);

        nft.safeBatchTransferFrom(address(this), msg.sender, nftIds, "");
    }

    function participate(address sweetpadIdo_) external {
        require(userNFTs[msg.sender].length > 0, "SweetpadIDO: User doesn't have NFTs staked");
        for (uint256 i; i < userNFTs[msg.sender].length; i++) {
            ticket.mint(msg.sender, ticketsPerNFT[userNFTs[msg.sender][i]], sweetpadIdo_);
        }
    }

    /**
     * @notice Returns NFTs frozen by the user
     */
    function getNftsFrozeByUser(address user) external view override returns (uint256[] memory) {
        return userNFTs[user];
    }

    function getTicketsForIdo(address user_, address ido_) external view override returns(uint256[] memory) {
        return ticketsForIdo[user_][ido_];
    }

    function blocksPerDay() external pure override returns (uint256) {
        return BLOCKS_PER_DAY;
    }

    function minFreezePeriod() external pure override returns (uint256) {
        return MIN_PERIOD;
    }

    function maxFreezePeriod() external pure override returns (uint256) {
        return MAX_PERIOD;
    }

    function setSweetpadNFT(address newNft) public override onlyOwner {
        require(newNft != address(0), "SweetpadNFTFreezing: NFT contract address can't be 0");
        nft = ISweetpadNFT(newNft);
    }

    function setSweetpadTicket(address newTicket) public override onlyOwner {
        require(newTicket != address(0), "SweetpadNFTFreezing: Ticket contract address can't be 0");
        ticket = ISweetpadTicket(newTicket);
    }

    function setSweetpadLottery(address lottery_) public override onlyOwner {
        require(lottery_ != address(0), "SweetpadNFTFreezing: Ticket contract address can't be 0");
        lottery = SweetpadLottery(lottery_);
    }

    // TODO add only lottery
    // TODO add requiers
    function addTickets(
        address to_,
        address ido_,
        uint256 ticketId_
    ) external override {
        ticketsForIdo[to_][ido_].push(ticketId_);
    }

    function _freeze(
        uint256 nftId,
        uint256 freezePeriod,
        uint256 ticketsToMint_
    ) private returns (uint256 freezeEndBlock) {
        require(freezePeriod >= MIN_PERIOD && freezePeriod <= MAX_PERIOD, "SweetpadNFTFreezing: Wrong freeze period");

        freezeEndBlock = freezePeriod + block.number;

        nftData[nftId] = NFTData({freezer: msg.sender, freezeEndBlock: freezeEndBlock});

        userNFTs[msg.sender].push(nftId);

        ticketsPerNFT[nftId] = ticketsToMint_;
    }

    function _unfreeze(uint256 nftId) private {
        NFTData memory _nftData = nftData[nftId];
        // slither-disable-next-line incorrect-equality
        require(
            checkAbilityToUnfreeze(msg.sender),
            "SweetpadNFTFreezing: You are participating in IDO that doesn't closed yet"
        );
        require(_nftData.freezer == msg.sender, "SweetpadNFTFreezing: Wrong unfreezer");
        require(_nftData.freezeEndBlock <= block.number, "SweetpadNFTFreezing: Freeze period don't passed");
        // slither-disable-next-line costly-loop
        delete nftData[nftId];

        uint256[] memory _userNFTs = userNFTs[msg.sender];
        uint256 len = _userNFTs.length;
        for (uint256 i = 0; i < len; i++) {
            if (_userNFTs[i] == nftId) {
                if (i != len - 1) {
                    userNFTs[msg.sender][i] = userNFTs[msg.sender][len - 1];
                }
                userNFTs[msg.sender].pop();

                break;
            }
        }
        delete ticketsPerNFT[nftId];
    }

    function checkAbilityToUnfreeze(address user_) internal view returns (bool) {
        if ((lottery.getOpenLotteries()).length > 0) {
            for (uint256 i; i < (lottery.getOpenLotteries()).length; i++) {
                if (ticketsForIdo[user_][(lottery.getBasicLottoInfo((lottery.getOpenLotteries())[i])).ido].length > 0) {
                    return false;
                } else {
                    return true;
                }
            }
        } else {
            return true;
        }
    }
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

pragma solidity ^0.8.7;

import "./ISweetpadNFT.sol";
import "./ISweetpadTicket.sol";
import "../SweetpadLottery.sol";

interface ISweetpadNFTFreezing {
    struct NFTData {
        // Account that froze NFT
        address freezer;
        // block after which freezer can unfreeze NFT
        uint256 freezeEndBlock;
    }

    function freeze(uint256, uint256) external;

    function freezeBatch(uint256[] calldata, uint256[] calldata) external;

    function unfreeze(uint256) external;

    function unfreezeBatch(uint256[] calldata) external;

    function blocksPerDay() external pure returns (uint256);

    function minFreezePeriod() external pure returns (uint256);

    function maxFreezePeriod() external pure returns (uint256);

    function nft() external view returns (ISweetpadNFT);

    function ticket() external view returns (ISweetpadTicket);

    function lottery() external view returns (SweetpadLottery);

    function nftData(uint256) external view returns (address, uint256);

    function getNftsFrozeByUser(address) external view returns (uint256[] memory);
    function getTicketsForIdo(address, address) external view returns(uint256[] memory);

    function setSweetpadNFT(address) external;

    function setSweetpadTicket(address) external;

    function setSweetpadLottery(address) external;

    // function tiketsForIdo(address, address) external returns(uint256[] memory);

    function addTickets(
        address,
        address,
        uint256
    ) external;

    event Froze(address indexed user, uint256 nftId, uint256 freezeEndBlock, uint256 ticketsMinted);

    event FrozeBatch(address indexed user, uint256[] nftIds, uint256[] freezeEndBlocks, uint256[] ticketsMinted);

    event Unfroze(address indexed user, uint256 nftId);

    event UnfrozeBatch(address indexed user, uint256[] nftId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface ISweetpadNFT is IERC721, IERC721Metadata {
    enum Tier {
        One,
        Two,
        Three
    }

    function idToTier(uint256) external view returns (Tier);

    function tierToBoost(Tier) external view returns (uint256);

    function getTicketsQuantityById(uint256) external view returns (uint256);

    function getTicketsQuantityByIds(uint256[] calldata) external view returns (uint256[] calldata);

    function getUserNfts(address) external view returns (uint256[] memory);

    function setBaseURI(string memory) external;

    function currentID() external view returns (uint256);

    function safeMint(address, Tier) external;

    function safeMintBatch(address, Tier[] memory) external;

    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        bytes memory
    ) external;

    /// @notice Emitted when new NFT is minted
    event Create(uint256 indexed, Tier indexed, address indexed);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/ISweetpadTicket.sol";
import "./interfaces/ISweetpadNFT.sol";
import "./interfaces/ISweetpadNFTFreezing.sol";


contract SweetpadTicket is ISweetpadTicket, ERC721, Ownable {
    uint256 public override totalTickets;
    // TODO check if fe need this
    ISweetpadNFT public sweetpadNFT;
    ISweetpadNFTFreezing public nftFreezing;

    uint256 private constant BLOCKS_PER_DAY = 10; // TODO for mainnet change to 28674
    uint256 private constant MAX_PERIOD = 1095 * BLOCKS_PER_DAY;

    mapping(address => uint256) public currentId;

    struct NFTData {
        // Account that froze NFT
        address freezer;
        // block after which freezer can unfreeze NFT
        uint256 freezeEndBlock;
        // Block number to freez
        uint256 period;
    }

    constructor(ISweetpadNFT sweetpadNFT_) ERC721("Sweet Ticket", "SWTT") {
        sweetpadNFT = sweetpadNFT_;
    }

    function setNFTFreezing(ISweetpadNFTFreezing nftFreezing_) external onlyOwner {
        nftFreezing = nftFreezing_;
    }

    function mint(
        address to_,
        uint256 amount_, 
        address sweetpadIdo_ 
    ) external override onlyOwner {
        // TODO
        for (uint256 i; i < amount_; i++) {
            currentId[sweetpadIdo_]++;
            _mint(to_, currentId[sweetpadIdo_]);
            nftFreezing.addTickets(to_, sweetpadIdo_, currentId[sweetpadIdo_]);
        }
    }

// TODO fix to revert safeTransferFrom too
    function transferFrom(
        address,
        address,
        uint256
    ) public virtual override(ERC721, IERC721) {
        revert("SweetpadTicket: can't transfer tickets");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./interfaces/ISweetpadTicket.sol";
import "./interfaces/ISweetpadFreezing.sol";
import "./interfaces/ISweetpadNFTFreezing.sol";
// TODO write Interfaces
import "./SweetpadLottery.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SweetpadIDO is AccessControl {
    using SafeERC20 for IERC20;
    ISweetpadTicket public sweetpadTicket;
    ISweetpadFreezing public sweetpadFreezing;
    ISweetpadNFTFreezing public sweetpadNFTFreezing;
    SweetpadLottery public sweetpadLottery;
    uint256 public percentForLottery;
    uint256 public percentForGuaranteedAllocation;
    uint256 public totalPower;
    uint256 public commission;
    uint256 public tokensToSell;
    uint256 public availableTokensToSell;
    uint256 public tokenPrice;
    // amount of BUSD per ticket that user can buy tokens
    uint256 public allocationPerTicket;
    uint256 public idoSaleStart;
    uint256 public idoSecondSaleStart;
    uint256 public idoSaleEnd;
    uint256 public idoSecondSaleEnd;
    // TODO set correct address
    IERC20 public BUSD = IERC20(0x9B704206Bde93fa3b4Bd903b2634FfFa2f4084cf);
    IERC20 public asset;
    // TODO add comment how to get value for role
    bytes32 public constant CLIENT_ROLE = 0xa5ff3ec7a96cdbba4d2d5172d66bbc73c6db3885f29b21be5da9fa7a7c025232;
    mapping(address => bool) public unlockedToSecondStage;
    mapping(address => uint256) public tokensBoughtFirstStage;
    mapping(address => uint256) public tokensBoughtSecondStage;
    uint256 private powerForSecondStage;

    constructor(
        ISweetpadTicket sweetpadTicket_,
        ISweetpadFreezing sweetpadFreezing_,
        ISweetpadNFTFreezing sweetpadNFTFreezing_,
        SweetpadLottery sweetpadLottery_,
        IERC20 asset_,
        address client_,
        address admin_
    ) {
        sweetpadTicket = sweetpadTicket_;
        sweetpadFreezing = sweetpadFreezing_;
        sweetpadNFTFreezing = sweetpadNFTFreezing_;
        sweetpadLottery = sweetpadLottery_;
        asset = asset_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(CLIENT_ROLE, client_);
    }

    function setup(
        uint256 lotteryPercent_,
        uint256 guarantedPercent_,
        uint256 totalPower_,
        uint256 commission_,
        uint256 tokensToSell_,
        uint256 tokenPrice_,
        uint256 allocationPerTicket_,
        // block numbers to control ido sale start and end
        uint256 idoSaleStart_,
        uint256 idoSaleEnd_,
        uint256 idoSecondSaleStart_,
        uint256 idoSecondSaleEnd_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            lotteryPercent_ > 100 && lotteryPercent_ <= 1500,
            "SweetpadIDO: Trying to set incorrect percent for lottery allocation"
        );
        require(
            guarantedPercent_ >= 8500 && guarantedPercent_ <= 9900,
            "SweetpadIDO: Trying to set incorrect percent for guaranted allocation"
        );
        require(guarantedPercent_ + lotteryPercent_ == 10000, "SweetpadIDO: Incorrect percents");
        require(totalPower_ > 0, "SweetpadIDO: TotalPower can't be zero");
        require(tokensToSell_ > 0, "SweetpadIDO: TokensToSell can't be zero");
        require(tokenPrice_ > 0, "SweetpadIDO: TokenPrice can't be zero");
        require(allocationPerTicket_ > 0, "SweetpadIDO: Allocation per ticket can't be zero");
        require(idoSaleStart_ >= block.number, "SweetpadIDO: Invalid block number");
        require(idoSaleEnd_ > idoSaleStart_, "SweetpadIDO: IDO sale end block must be greater then start block");
        require(
            idoSecondSaleStart_ > idoSaleEnd_,
            "SweetpadIDO: IDO second sale start block must be greater then first end block"
        );
        require(
            idoSecondSaleStart_ <= idoSecondSaleEnd_,
            "SweetpadIDO: IDO second sale end block must be greater then start block"
        );
        percentForLottery = lotteryPercent_;
        percentForGuaranteedAllocation = guarantedPercent_;
        totalPower = totalPower_;
        commission = commission_;
        tokensToSell = tokensToSell_;
        availableTokensToSell = tokensToSell_;
        tokenPrice = tokenPrice_;
        allocationPerTicket = allocationPerTicket_;

        idoSaleStart = idoSaleStart_;
        idoSaleEnd = idoSaleEnd_;
        idoSecondSaleStart = idoSecondSaleStart_;
        idoSecondSaleEnd = idoSecondSaleEnd_;
    }

    function buyFirstStage(uint256 amount_) external {
        require(idoSaleStart <= block.number && idoSaleEnd > block.number, "SweetpadIDO: Wrong period to buy");
        require(amount_ > 0, "SweetpadIDO: Amount must be greater then zero");
        uint256 userPower = sweetpadFreezing.totalPower(msg.sender);
        require(userPower > 0, "SweetpadIDO: User's power can't be zero");
        // TODO write view function and use it
        // TODO write view function to get availableTokenPrice and availabletokens count
        uint256 availableTokens = (tokensToSell * 1e18 * percentForGuaranteedAllocation * userPower) /
            10000 /
            totalPower;
        uint256 availableTokensPrice = (availableTokens * tokenPrice) /
            10000 /
            totalPower -
            tokensBoughtFirstStage[msg.sender];
        require(availableTokensPrice >= amount_, "SweetpadIDO: Trying to buy more then available");
        // User pays for tokens
        BUSD.safeTransferFrom(msg.sender, address(this), amount_);
        tokensBoughtFirstStage[msg.sender] += (amount_ * 1e18) / tokenPrice;
        // User get assets
        asset.safeTransfer(msg.sender, (amount_ * 1e18) / tokenPrice);
        availableTokensToSell -= (amount_ * 1e18) / tokenPrice;

        if (availableTokens - tokensBoughtFirstStage[msg.sender] == 0) {
            unlockedToSecondStage[msg.sender] = true;
            powerForSecondStage += userPower;
        }
    }

    function buySecondStage(uint256 amount_) external {
        require(
            idoSecondSaleStart <= block.number && idoSecondSaleEnd > block.number,
            "SweetpadIDO: Wrong period to buy"
        );
        require(amount_ > 0, "SweetpadIDO: Amount must be greater then zero");
        uint256 userPower = sweetpadFreezing.totalPower(msg.sender);
        require(userPower > 0, "SweetpadIDO: User's power can't be zero");
        require(unlockedToSecondStage[msg.sender], "SweetpadIDO: User can't buy tokens from second stage");
        uint256 availableTokensSecondStage = (availableTokensToSell * userPower) /
            powerForSecondStage -
            tokensBoughtSecondStage[msg.sender];
        require(
            availableTokensSecondStage >= tokensBoughtSecondStage[msg.sender],
            "SweetpadIDO: User already bought max amount of tokens"
        );
        uint256 availableTokensPriceSecondStage = availableTokensSecondStage * tokenPrice;
        require(availableTokensPriceSecondStage >= amount_, "SweetpadIDO: Trying to buy more then available");
        // User pays for tokens
        BUSD.safeTransferFrom(msg.sender, address(this), amount_);
        // User get assets
        asset.safeTransfer(msg.sender, (amount_ * 1e18) / tokenPrice);
        tokensBoughtSecondStage[msg.sender] += (amount_ * 1e18) / tokenPrice;
        availableTokensToSell -= (amount_ * 1e18) / tokenPrice;
    }

    function buyFromWonTickets(uint256 amount_) external {
        // uint256 numberOfTickets = getNumberOfWinningTickets(msg.sender);
        uint256 allocation = getAllocationFromLottery(msg.sender);
        require(allocation >= amount_, "SweetpadIDO: Insufficient allocation");
        // User pays for tokens
        BUSD.safeTransferFrom(msg.sender, address(this), amount_);
        // User get assets
        asset.safeTransfer(msg.sender, (amount_ * 1e18) / tokenPrice);
    }

    function getWinningTicketsNumber() external view returns (uint256) {
        return getNumberOfWinningTickets(msg.sender);
    }

    function getNumberOfWinningTickets(address user_) public view returns (uint256 numberOfWinningTickets) {
        uint16[] memory winningNumbers = (sweetpadLottery.getBasicLottoInfo(sweetpadLottery.idoToId(address(this))))
            .winningNumbers;
        uint256[] memory tickets = sweetpadNFTFreezing.getTicketsForIdo(user_, address(this));
        for (uint256 i; i < winningNumbers.length; i++) {
            for (uint256 j; j < tickets.length; j++) {
                if (tickets[j] == 0) {
                    continue;
                }
                if (winningNumbers[i] == tickets[j]) {
                    if (j != tickets.length - 1) {
                        tickets[j] = tickets[tickets.length - 1];
                    }
                    tickets[tickets.length - 1] = 0;
                    numberOfWinningTickets += 1;
                }
            }
        }
        return numberOfWinningTickets;
    }

    function getAllocationFromLottery(address user_) public view returns (uint256 allocation) {
        uint256 numberOfTickets = getNumberOfWinningTickets(user_);
        allocation = numberOfTickets * allocationPerTicket;
        return allocation;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "ApeSwap-AMM-Periphery/contracts/interfaces/IApeRouter02.sol";

interface ISweetpadFreezing {
    struct FreezeInfo {
        uint256 frozenUntil; // blockNumber when can be unfrozen
        uint256 period; // Number of blocks that tokens are frozen
        uint256 frozenAmount; // Amount of tokens are frozen
        uint256 power; // power of current frozen amount
        uint8 asset; // Variable to identify if the token is SWT or LP
    }

    function freezeInfo(address, uint256)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint8
        );

    function sweetToken() external view returns (IERC20);

    function lpToken() external view returns (IERC20);

    function router() external view returns (IApeRouter02);

    function multiplier() external view returns (uint256);

    function totalFrozenSWT() external view returns (uint256);

    function totalFrozenLP() external view returns (uint256);

    function getBlocksPerDay() external pure returns (uint256);

    function getMinFreezePeriod() external pure returns (uint256);

    function getMaxFreezePeriod() external pure returns (uint256);

    function totalPower(address) external view returns (uint256);

    function freezeSWT(uint256, uint256) external;

    function freezeLP(uint256, uint256) external;

    function freezeWithBNB(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) external payable;

    function unfreezeSWT(uint256, uint256) external;

    function unfreezeLP(uint256) external;

    function setMultiplier(uint256) external;

    function setLPToken(IERC20) external;

    function getFreezes(address) external view returns (FreezeInfo[] memory);

    function getPower(uint256, uint256) external pure returns (uint256);

    /// @notice Emitted when tokens are frozen
    event Freeze(uint256 id, address indexed account, uint256 amount, uint256 power, uint8 asset);
    /// @notice Emitted when tokens are unFrozen
    event UnFreeze(uint256 id, address indexed account, uint256 power, uint8 asset);
    /// @notice Emmited when multiplier reseted
    event MultiplierReseted(uint256 oldMultiplier, uint256 newMultiplier);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

pragma solidity >=0.6.2;

import './IApeRouter01.sol';

interface IApeRouter02 is IApeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IApeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ISweetpadFreezing.sol";

/**
 * @title SweetpadFreezing
 * @dev Contract module which provides functionality to freeze assets on contract and get allocation.
 */
contract SweetpadFreezing is ISweetpadFreezing, Ownable {
    using SafeERC20 for IERC20;

    uint16 private constant DAYS_IN_YEAR = 100;

    // TODO, we need to change BLOCKS_PER_DAY to a real one before deploying a mainnet
    uint256 private constant BLOCKS_PER_DAY = 1;

    // Min period counted with blocks that user can freeze assets
    uint256 private constant MIN_FREEZE_PERIOD = 50 * BLOCKS_PER_DAY;

    // Max period counted with blocks that user can freeze assets
    uint256 private constant MAX_FREEZE_PERIOD = 300 * BLOCKS_PER_DAY;

    // TODO set correct mainnet addresses before deploying
    address public constant ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    /// @dev Multiplier to colculate power while freezing with LP
    uint256 public override multiplier;

    uint256 public override totalFrozenSWT;

    uint256 public override totalFrozenLP;

    /// @dev The data for each account
    mapping(address => FreezeInfo[]) public override freezeInfo;

    /// @dev The data for each account, returns totalPower
    mapping(address => uint256) public override totalPower;

    IERC20 public override sweetToken;
    IERC20 public override lpToken;

    IApeRouter02 public override router = IApeRouter02(ROUTER_ADDRESS);

    /**
     * @notice Initialize contract
     */
    constructor(IERC20 sweetToken_) {
        require(address(sweetToken_) != address(0), "SweetpadFreezing: Token address cant be Zero address");
        sweetToken = sweetToken_;
    }

    receive() external payable {
        return;
    }

    fallback() external payable {
        return;
    }

    /**
     * @notice Freeze SWT tokens
     * @param amount_ Amount of tokens to freeze
     * @param period_ Period of freezing
     */
    function freezeSWT(uint256 amount_, uint256 period_) external override {
        uint256 power = getPower(amount_, period_);
        require(power >= 10000 ether, "SweetpadFreezing: At least 10.000 xSWT is required");
        _freeze(msg.sender, amount_, period_, power, 0);
        _transferAssetsToContract(msg.sender, amount_, 0);
    }

    /**
     * @notice Freeze LP tokens
     * @param amount_ Amount of tokens to freeze
     * @param period_ Period of freezing
     */
    function freezeLP(uint256 amount_, uint256 period_) external override {
        uint256 power = (getPower(amount_, period_) * multiplier) / 100;
        require(power >= 10000 ether, "SweetpadFreezing: At least 10.000 xSWT is required");
        _freeze(msg.sender, amount_, period_, power, 1);
        _transferAssetsToContract(msg.sender, amount_, 1);
    }

    /**
     * @notice Transfer BNB to contract and Freeze LP
     * @param period_ Period of freezing
     * @param amountOutMin The minimum amount of output tokens while swaping
     * @param amountTokenMin Min token amount desiered while adding liquidity
     * @param amountETHMin Min ETH amount desiered while adding liquidity
     * @param deadline_ Timestamp after which the transaction will revert.
     */
    function freezeWithBNB(
        uint256 period_,
        uint256 amountOutMin,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline_
    ) external payable override {
        // slither-disable-next-line reentrancy-events
        uint256[] memory swapResult = _swapExactETHForSwtTokens(msg.value / 2, amountOutMin, deadline_);

        uint256 tokenAmount = swapResult[1];

        // slither-disable-next-line reentrancy-events
        uint256 liquidity = _addLiquidityETH(
            msg.sender,
            msg.value / 2,
            address(sweetToken),
            tokenAmount,
            amountTokenMin,
            amountETHMin,
            deadline_
        );

        uint256 power = (getPower(liquidity, period_) * multiplier) / 100;
        require(power >= 10000 ether, "SweetpadFreezing: At least 10.000 xSWT is required");
        _freeze(msg.sender, liquidity, period_, power, 1);
    }

    /**
     * @notice Unfreeze SWT tokens
     * @param id_ Id of freezing
     * @param amount_ Amount of tokens to unfreeze
     */
    function unfreezeSWT(uint256 id_, uint256 amount_) external override {
        FreezeInfo memory freezeData = freezeInfo[msg.sender][id_];
        require(freezeData.asset == 0, "SweetpadFreezing: Wrong ID");
        require(freezeData.frozenAmount != 0, "SweetpadFreezing: Frozen amount is Zero");
        require(freezeData.frozenAmount >= amount_, "SweetpadFreezing: Insufficient frozen amount");
        require(block.number >= freezeData.frozenUntil, "SweetpadFreezing: Locked period dosn`t pass");
        uint256 expectedPower = getPower(freezeData.frozenAmount - amount_, freezeData.period);
        require(
            expectedPower >= 10000 ether || expectedPower == 0,
            "SweetpadFreezing: At least 10.000 xSWT is required"
        );
        uint256 powerDelta = getPower(amount_, freezeData.period);
        _unfreezeSWT(msg.sender, id_, amount_, powerDelta);
    }

    /**
     * @notice Unfreeze LP tokens
     * @param id_ Id of freezing
     */
    function unfreezeLP(uint256 id_) external override {
        FreezeInfo memory freezeData = freezeInfo[msg.sender][id_];
        require(freezeData.asset == 1, "SweetpadFreezing: Wrong ID");
        require(block.number >= freezeData.frozenUntil, "SweetpadFreezing: Locked period dosn`t pass");
        _unfreezeLP(msg.sender, id_);
    }

    /**
     * @notice Set multiplier to calculate power while freezing with LP
     * @param multiplier_ Shows how many times the power will be greater for  user while staking with LP
     */
    function setMultiplier(uint256 multiplier_) external override onlyOwner {
        uint256 oldMultiplier = multiplier;
        require(multiplier_ != 0, "SweetpadFreezing: Multiplier can't be zero");
        multiplier = multiplier_;
        emit MultiplierReseted(oldMultiplier, multiplier);
    }

    /**
     * @notice Set LP token
     * @param lpToken_ Address of BNB/SWT LP
     */
    function setLPToken(IERC20 lpToken_) external override onlyOwner {
        require(address(lpToken_) != address(0), "SweetpadFreezing: LP token address cant be Zero address");
        lpToken = lpToken_;
    }

    function getFreezes(address account_) external view override returns (FreezeInfo[] memory) {
        return freezeInfo[account_];
    }

    function getBlocksPerDay() external pure override returns (uint256) {
        return BLOCKS_PER_DAY;
    }

    function getMinFreezePeriod() external pure override returns (uint256) {
        return MIN_FREEZE_PERIOD;
    }

    function getMaxFreezePeriod() external pure override returns (uint256) {
        return MAX_FREEZE_PERIOD;
    }

    function getPower(uint256 amount_, uint256 period_) public pure override returns (uint256 power) {
        require(MIN_FREEZE_PERIOD <= period_ && period_ <= MAX_FREEZE_PERIOD, "SweetpadFreezing: Wrong period");
        if (period_ == MIN_FREEZE_PERIOD) {
            power = amount_ / 2;
            return power;
        }

        if (period_ > MIN_FREEZE_PERIOD && period_ <= DAYS_IN_YEAR * BLOCKS_PER_DAY) {
            power = (period_ * amount_) / DAYS_IN_YEAR / BLOCKS_PER_DAY;
            return power;
        }

        power = ((period_ + DAYS_IN_YEAR * BLOCKS_PER_DAY) * amount_) / (DAYS_IN_YEAR * 2) / BLOCKS_PER_DAY;
        return power;
    }

    function _freeze(
        address account_,
        uint256 amount_,
        uint256 period_,
        uint256 power_,
        uint8 asset_
    ) private {
        freezeInfo[account_].push(
            FreezeInfo({
                frozenUntil: block.number + period_,
                period: period_,
                frozenAmount: amount_,
                power: power_,
                asset: asset_
            })
        );
        totalPower[account_] += power_;

        if (asset_ == 0) {
            totalFrozenSWT += amount_;
        } else {
            totalFrozenLP += amount_;
        }

        emit Freeze(freezeInfo[account_].length - 1, account_, amount_, power_, asset_);
    }

    function _transferAssetsToContract(
        address from,
        uint256 amount,
        uint8 asset_
    ) private {
        IERC20 asset = sweetToken;
        if (asset_ == 1) {
            asset = lpToken;
        }
        asset.safeTransferFrom(from, address(this), amount);
    }

    function _unfreezeSWT(
        address account_,
        uint256 id_,
        uint256 amount_,
        uint256 power_
    ) private {
        if (amount_ == freezeInfo[account_][id_].frozenAmount) {
            totalPower[account_] -= freezeInfo[account_][id_].power;
            delete freezeInfo[account_][id_];
        } else {
            totalPower[account_] -= power_;
            freezeInfo[account_][id_].frozenAmount -= amount_;
            freezeInfo[account_][id_].power -= power_;
        }

        totalFrozenSWT -= amount_;

        emit UnFreeze(id_, account_, amount_, 0);

        sweetToken.safeTransfer(account_, amount_);
    }

    function _unfreezeLP(address account_, uint256 id_) private {
        FreezeInfo memory freezeData = freezeInfo[account_][id_];
        totalPower[account_] -= freezeData.power;
        uint256 amount = freezeData.frozenAmount;
        delete freezeInfo[account_][id_];
        totalFrozenLP -= amount;

        emit UnFreeze(id_, account_, amount, 1);

        lpToken.safeTransfer(account_, amount);
    }

    function _transferBackUnusedAssets(
        address to,
        uint256 ethAmount,
        uint256 tokenAmount,
        uint256 ethAmountAdded,
        uint256 tokenAmountAdded
    ) private {
        uint256 ethToTransfer = ethAmount - ethAmountAdded;
        uint256 tokenToTransfer = tokenAmount - tokenAmountAdded;

        if (ethToTransfer > 0) {
            payable(to).transfer(ethToTransfer);
        }

        if (tokenToTransfer > 0) {
            sweetToken.safeTransfer(to, tokenToTransfer);
        }
    }

    function _addLiquidityETH(
        address account,
        uint256 ethAmount,
        address token,
        uint256 tokenAmount,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline_
    ) private returns (uint256) {
        // slither-disable-next-line reentrancy-events
        sweetToken.safeApprove(ROUTER_ADDRESS, tokenAmount);

        (uint256 amountTokenAdded, uint256 amountETHAdded, uint256 liquidity) = router.addLiquidityETH{
            value: ethAmount
        }(token, tokenAmount, amountTokenMin, amountETHMin, address(this), deadline_);

        _transferBackUnusedAssets(account, ethAmount, tokenAmount, amountETHAdded, amountTokenAdded);

        sweetToken.safeApprove(ROUTER_ADDRESS, 0);

        return liquidity;
    }

    function _swapExactETHForSwtTokens(
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline_
    ) private returns (uint256[] memory amounts) {
        address[] memory path = new address[](2);

        // slither-disable-next-line naming-convention
        path[0] = router.WETH();
        path[1] = address(sweetToken);

        amounts = router.swapExactETHForTokens{value: amount}(amountOutMin, path, address(this), deadline_);
        return amounts;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;
// Imported OZ helper contracts
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/proxy/Initializable.sol";
// Inherited allowing for ownership of contract
import "@openzeppelin/contracts/access/Ownable.sol";
// Allows for intergration with ChainLink VRF
// Interface for Lottery NFT to mint tokens
import "../interfaces/ISweetpadTicket.sol";


// Allows for time manipulation. Set to 0x address on test/mainnet deploy
// import "./Testable.sol";

contract SweetpadLotteryMock is Ownable {
    // Libraries
    using SafeMath for uint256;
    // Safe ERC20
    using SafeERC20 for IERC20;
    // Address functionality
    using Address for address;

    // State variables
    // Instance of Cake token (collateral currency for lotto)
    // IERC20 internal cake_;
    // Storing of the NFT
    // TODO check
    // ISweetpadTicket internal nft_;
    // Storing of the randomness generator
    // Request ID for random number
    bytes32 internal requestId_;
    // Counter for lottery IDs
    uint256 private lotteryIdCounter_;

    // Lottery size
    uint16 public sizeOfLottery_;
    // Max range for numbers (starting at 0)
    uint16 public maxValidRange_;

    // Represents the status of the lottery
    enum Status {
        NotStarted, // The lottery has not started yet
        Open, // The lottery is open for ticket purchases
        Closed, // The lottery is no longer open for ticket purchases
        Completed // The lottery has been closed and the numbers drawn
    }
    // All the needed info around a lottery
    struct LottoInfo {
        uint256 lotteryID; // ID for lotto
        Status lotteryStatus; // Status for lotto
        address ido;
        // uint256 prizePoolInCake;    // The amount of cake for prize money
        // uint256 costPerTicket;      // Cost per ticket in $cake
        // uint8[] prizeDistribution;  // The distribution for prize money
        uint256 startingTimestamp; // Block timestamp for star of lotto
        uint256 closingTimestamp; // Block timestamp for end of entries
        uint16[] winningNumbers; // The winning numbers
    }
    // Lottery ID's to info
    mapping(uint256 => LottoInfo) public allLotteries_;
    mapping(uint256 => uint256) internal rendomNumbers;
    mapping(address => uint256) public idoToId;

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event RequestNumbers(uint256 lotteryId, bytes32 requestId);

    event UpdatedSizeOfLottery(address admin, uint16 newLotterySize);

    event UpdatedMaxRange(address admin, uint16 newMaxRange);

    event LotteryOpen(uint256 lotteryId, uint256 ticketSupply);

    event LotteryClose(uint256 lotteryId, uint256 ticketSupply);

    //-------------------------------------------------------------------------
    // MODIFIERS
    //-------------------------------------------------------------------------

    //-------------------------------------------------------------------------
    // CONSTRUCTOR
    //-------------------------------------------------------------------------

    constructor(
        // address _cake,
        // address _timer,
        uint8 _sizeOfLotteryNumbers,
        uint16 _maxValidNumberRange // uint8 _bucketOneMaxNumber, // TODO check // address lotteryNFT_ // Testable(_timer)
    ) {
        // require(
        //     _discountForBucketOne < _discountForBucketTwo &&
        //     _discountForBucketTwo < _discountForBucketThree,
        //     "Discounts must increase"
        // );
        // require(
        //     _cake != address(0),
        //     "Contracts cannot be 0 address"
        // );
        require(_sizeOfLotteryNumbers != 0 && _maxValidNumberRange != 0, "Lottery setup cannot be 0");
        // require(lotteryNFT_ != address(0), "Contracts cannot be 0 address");
        // nft_ = ISweetpadTicket(lotteryNFT_);
        // cake_ = IERC20(_cake);
        sizeOfLottery_ = _sizeOfLotteryNumbers;
        maxValidRange_ = _maxValidNumberRange;

        // bucketOneMax_ = _bucketOneMaxNumber;
        // bucketTwoMax_ = _bucketTwoMaxNumber;
        // discountForBucketOne_ = _discountForBucketOne;
        // discountForBucketTwo_ = _discountForBucketTwo;
        // discountForBucketThree_ = _discountForBucketThree;
    }

    // function initialize(
    //     address _lotteryNFT,
    //     address _IRandomNumberGenerator
    // )
    //     external
    //     initializer
    //     onlyOwner()
    // {
    //     require(
    //         _lotteryNFT != address(0) &&
    //         _IRandomNumberGenerator != address(0),
    //         "Contracts cannot be 0 address"
    //     );
    //     nft_ = ILotteryNFT(_lotteryNFT);
    //     randomGenerator_ = IRandomNumberGenerator(_IRandomNumberGenerator);
    // }

    function getBasicLottoInfo(uint256 _lotteryId) external view returns (LottoInfo memory) {
        return (allLotteries_[_lotteryId]);
    }

    function getMaxRange() external view returns (uint16) {
        return maxValidRange_;
    }

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------

    //-------------------------------------------------------------------------
    // Restricted Access Functions (onlyOwner)

    function updateSizeOfLottery(uint16 _newSize) external onlyOwner {
        require(sizeOfLottery_ != _newSize, "Cannot set to current size");
        require(sizeOfLottery_ != 0, "Lottery size cannot be 0");
        sizeOfLottery_ = _newSize;

        emit UpdatedSizeOfLottery(msg.sender, _newSize);
    }

    function updateMaxRange(uint16 _newMaxRange) external onlyOwner {
        require(maxValidRange_ != _newMaxRange, "Cannot set to current size");
        require(maxValidRange_ != 0, "Max range cannot be 0");
        maxValidRange_ = _newMaxRange;

        emit UpdatedMaxRange(msg.sender, _newMaxRange);
    }

    function getWiningNumbers(uint256 _lotteryId) external {
        // require(allLotteries_[_lotteryId].lotteryStatus == Status.Completed, "Draw numbers first");
        allLotteries_[_lotteryId].winningNumbers = [1, 1, 1, 1, 5, 6, 7, 8, 9];

    }

    // * @param   _prizeDistribution An array defining the distribution of the
    //  *          prize pool. I.e if a lotto has 5 numbers, the distribution could
    //  *          be [5, 10, 15, 20, 30] = 100%. This means if you get one number
    //  *          right you get 5% of the pool, 2 matching would be 10% and so on.
    //  * @param   _prizePoolInCake The amount of Cake available to win in this
    //  *          lottery.

    /**
     * @param   _startingTimestamp The block timestamp for the beginning of the
     *          lottery.
     * @param   _closingTimestamp The block timestamp after which no more tickets
     *          will be sold for the lottery. Note that this timestamp MUST
     *          be after the starting block timestamp.
     */
    //  TODO add functionaliti to connect lottery and ido
    function createNewLotto(
        // uint8[] calldata _prizeDistribution,
        // uint256 _prizePoolInCake,
        // uint256 _costPerTicket,
        uint256 _startingTimestamp,
        uint256 _closingTimestamp,
        address _ido
    ) external onlyOwner returns (uint256 lotteryId) {
        // require(
        //     _prizeDistribution.length == sizeOfLottery_,
        //     "Invalid distribution"
        // );
        // uint256 prizeDistributionTotal = 0;
        // for (uint256 j = 0; j < _prizeDistribution.length; j++) {
        //     prizeDistributionTotal = prizeDistributionTotal.add(
        //         uint256(_prizeDistribution[j])
        //     );
        // }
        // Ensuring that prize distribution total is 100%
        // require(
        //     prizeDistributionTotal == 100,
        //     "Prize distribution is not 100%"
        // );
        // require(
        //     _prizePoolInCake != 0 && _costPerTicket != 0,
        //     "Prize or cost cannot be 0"
        // );
        // require(_startingTimestamp != 0 && _startingTimestamp < _closingTimestamp, "Timestamps for lottery invalid");
        require(idoToId[_ido] == 0, "SweetpadLottery: Lottery for current IDO contract was already created");
        // Incrementing lottery ID
        lotteryIdCounter_ = lotteryIdCounter_ + 1;
        lotteryId = lotteryIdCounter_;
        uint16[] memory winningNumbers = new uint16[](sizeOfLottery_);
        Status lotteryStatus;
        // if (_startingTimestamp >= block.timestamp) {
        lotteryStatus = Status.Open;
        // } else {
        //     lotteryStatus = Status.NotStarted;
        // }
        // Saving data in struct
        LottoInfo memory newLottery = LottoInfo(
            lotteryId,
            lotteryStatus,
            _ido,
            // _prizePoolInCake,
            // _costPerTicket,
            // _prizeDistribution,
            _startingTimestamp,
            _closingTimestamp,
            winningNumbers
        );
        allLotteries_[lotteryId] = newLottery;
        idoToId[_ido] = lotteryId;
        // TODO fix
        // Emitting important information around new lottery.
        // emit LotteryOpen(
        //     lotteryId,
        //     nft_.getTotalSupply()
        // );
    }

    //-------------------------------------------------------------------------
    // General Access Functions

    // claim reward don't remove!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    // function claimReward(uint256 _lotteryId, uint256 _tokenId) external notContract() {
    //     // Checking the lottery is in a valid time for claiming
    //     require(
    //         allLotteries_[_lotteryId].closingTimestamp <= block.timestamp,
    //         "Wait till end to claim"
    //     );
    //     // Checks the lottery winning numbers are available
    //     require(
    //         allLotteries_[_lotteryId].lotteryStatus == Status.Completed,
    //         "Winning Numbers not chosen yet"
    //     );
    //     require(
    //         nft_.getOwnerOfTicket(_tokenId) == msg.sender,
    //         "Only the owner can claim"
    //     );
    //     // Sets the claim of the ticket to true (if claimed, will revert)
    //     require(
    //         nft_.claimTicket(_tokenId, _lotteryId),
    //         "Numbers for ticket invalid"
    //     );
    //     // Getting the number of matching tickets
    //     uint8 matchingNumbers = _getNumberOfMatching(
    //         nft_.getTicketNumbers(_tokenId),
    //         allLotteries_[_lotteryId].winningNumbers
    //     );
    //     // Getting the prize amount for those matching tickets
    //     uint256 prizeAmount = _prizeForMatching(
    //         matchingNumbers,
    //         _lotteryId
    //     );
    //     // Removing the prize amount from the pool
    //     allLotteries_[_lotteryId].prizePoolInCake = allLotteries_[_lotteryId].prizePoolInCake.sub(prizeAmount);
    //     // Transfering the user their winnings
    //     cake_.safeTransfer(address(msg.sender), prizeAmount);
    // }

    //-------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //-------------------------------------------------------------------------

    // TODO start tickets ids from 1 and check if user number is 0 breack
    // TODO fix functionality
    function getNumberOfMatching(uint16[] memory _usersNumbers, uint16[] memory _winningNumbers)
        public
        pure
        returns (uint8 noOfMatching)
    {
        // Loops through all wimming numbers
        for (uint256 i = 0; i < _winningNumbers.length; i++) {
            // If the winning numbers and user numbers match
            if (_usersNumbers[i] == _winningNumbers[i]) {
                // The number of matching numbers incrases
                noOfMatching += 1;
            }
        }
    }

    function _split() public view returns (uint16[] memory) {
        // Temparary storage for winning numbers
        uint16[] memory winningNumbers = new uint16[](sizeOfLottery_);
        // Loops the size of the number of tickets in the lottery
        for (uint256 i = 0; i < sizeOfLottery_; i++) {
        uint256 duplicated;
            // Encodes the random number with its position in loop
            bytes32 hashOfRandom = keccak256(
                abi.encodePacked("0x8ba28b464185c48a3e1a05aec7116d926a90695d7360ceac9cc4b8e4369b52e5", i)
            );
            // Casts random number hash into uint256
            uint256 numberRepresentation = uint256(hashOfRandom);
            // Sets the winning number position to a uint16 of random hash number
            for (uint256 j = 0; j < winningNumbers.length; j++) {
                if (winningNumbers[j] > 0) {
                    if (winningNumbers[j] == uint16(numberRepresentation.mod(maxValidRange_))) {
                        duplicated += 1;
                    }
                }
            }
            if(duplicated>0){
                continue;
            }
            winningNumbers[i] = uint16(numberRepresentation.mod(maxValidRange_));
        }
        return winningNumbers;
    }

    function getOpenLotteries() public view returns (uint256[] memory openLotteries) {
        for (uint256 i = 1; i <= lotteryIdCounter_; i++) {
            if (allLotteries_[i].closingTimestamp > block.timestamp) {
                openLotteries[i - 1] = allLotteries_[i].lotteryID;
            }
        }
        return openLotteries;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ISweetpadNFT.sol";

/**
 * @title SweetpadNFT
 * @dev Contract module which provides functionality to mint new ERC721 tokens
 *      Each token connected with image. The image saves on IPFS. Also each token belongs one of the Sweet tiers, and give
 *      some tickets for lottery.
 */
contract SweetpadNFT is ISweetpadNFT, ERC721, Ownable {
    using Counters for Counters.Counter;

    /// @dev ERC721 id, Indicates a specific token or token type
    Counters.Counter private idCounter;

    string private baseURI = "ipfs://";

    /// @dev The data for each SweetpadNFT token
    mapping(uint256 => Tier) public override idToTier;
    mapping(Tier => uint256) public override tierToBoost;

    /// @dev Array of user NFTs
    mapping(address => uint256[]) public userNFTs;

    /**
     * @notice Initialize contract
     */
    constructor() ERC721("Sweet Dragon", "SWTD") {
        tierToBoost[Tier.One] = 5;
        tierToBoost[Tier.Two] = 12;
        tierToBoost[Tier.Three] = 30;
    }

    /*** External user-defined functions ***/
    function setBaseURI(string memory baseURI_) external override onlyOwner {
        baseURI = baseURI_;
    }

    function currentID() external view override returns (uint256) {
        return idCounter.current();
    }

    /**
     * @notice Function to get tickets quantity by tokens id.
     * @param id_ Token id
     * @return ticketsQuantity Tickets quantity
     */
    function getTicketsQuantityById(uint256 id_) external view override returns (uint256) {
        return tierToBoost[idToTier[id_]];
    }

    /**
     * @notice Function to get tickets quantity by tokens ids.
     * @param ids_ Array of token ids
     * @return ticketsQuantity Array of tickets quantity
     */
    function getTicketsQuantityByIds(uint256[] calldata ids_) external view override returns (uint256[] memory) {
        uint256[] memory ticketsQuantity = new uint256[](ids_.length);
        for (uint256 i = 0; i < ids_.length; i++) {
            ticketsQuantity[i] = tierToBoost[idToTier[ids_[i]]];
        }
        return ticketsQuantity;
    }

    /**
     * @notice Transfer token to another account
     * @param to_ The address of the token receiver
     * @param id_ token id
     * @param data_ The _data argument MAY be re-purposed for the new context.
     */
    function safeTransfer(
        address to_,
        uint256 id_,
        bytes memory data_
    ) external {
        _safeTransfer(msg.sender, to_, id_, data_);

        popNFT(msg.sender, id_);
        pushNFT(to_, id_);
    }

    /**
     * @notice Transfer tokens to another account
     * @param to_ The address of the tokens receiver
     * @param ids_ Array of token ids
     * @param data_ The _data argument MAY be re-purposed for the new context.
     */
    function safeBatchTransfer(
        address to_,
        uint256[] memory ids_,
        bytes memory data_
    ) external {
        for (uint256 i = 0; i < ids_.length; i++) {
            _safeTransfer(msg.sender, to_, ids_[i], data_);

            popNFT(msg.sender, ids_[i]);
            pushNFT(to_, ids_[i]);
        }
    }

    /**
     * @notice Transfer tokens from 'from' to 'to'
     * @param from_ The address of the tokens owner
     * @param to_ The address of the tokens receiver
     * @param ids_ Array of token ids
     * @param data_ The _data argument MAY be re-purposed for the new context.
     */
    function safeBatchTransferFrom(
        address from_,
        address to_,
        uint256[] memory ids_,
        bytes memory data_
    ) external override {
        for (uint256 i = 0; i < ids_.length; i++) {
            safeTransferFrom(from_, to_, ids_[i], data_);

            popNFT(from_, ids_[i]);
            pushNFT(to_, ids_[i]);
        }
    }

    /**
     * @notice Mint new 721 standard token
     * @param tier_ tier
     */
    function safeMint(address account_, Tier tier_) external override onlyOwner {
        _mint(account_, tier_);
    }

    /**
     * @notice Mint new ERC721 standard tokens in one transaction
     * @param account_ The address of the owner of tokens
     * @param tiers_ Array of tiers
     */
    function safeMintBatch(address account_, Tier[] memory tiers_) external override onlyOwner {
        for (uint256 i = 0; i < tiers_.length; i++) {
            _mint(account_, tiers_[i]);
        }
    }

    function supportsInterface(bytes4 interfaceId) public pure override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId;
    }

    function tokenURI(uint256 tokenId_) public view override(ERC721, IERC721Metadata) returns (string memory) {
        return
            _exists(tokenId_) ? string(abi.encodePacked(_baseURI(), Strings.toString(tokenId_), ".json")) : _baseURI();
    }

    /**
     * @notice Returns user NFTs
     */
    function getUserNfts(address user) external view override returns (uint256[] memory) {
        return userNFTs[user];
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Mint new 721 standard token
     * @param tier_ tier
     */
    function _mint(address account_, Tier tier_) private {
        idCounter.increment();
        uint256 id = idCounter.current();

        _safeMint(account_, id);
        idToTier[id] = tier_;

        pushNFT(account_, id);

        emit Create(id, tier_, account_);
    }

    function pushNFT(address user, uint256 nftId) internal {
        userNFTs[user].push(nftId);
    }

    function popNFT(address user, uint256 nftId) internal {
        uint256[] memory _userNFTs = userNFTs[user];
        uint256 len = _userNFTs.length;

        for (uint256 i = 0; i < len; i++) {
            if (_userNFTs[i] == nftId) {
                if (i != len - 1) {
                    userNFTs[user][i] = userNFTs[user][len - 1];
                }
                userNFTs[user].pop();

                break;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SweetpadToken is ERC20 {
    constructor() ERC20("Sweetpad Token", "SWT") {
        _mint(msg.sender, 1e8 * 1e18);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AssetMock is ERC20 {
    constructor() ERC20("Asset", "AT") {
        _mint(msg.sender, 1e8 * 1e18);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}