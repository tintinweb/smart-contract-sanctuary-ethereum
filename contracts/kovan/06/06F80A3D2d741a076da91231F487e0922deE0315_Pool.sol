// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Vesting.sol";

interface IWhitelistRegistry {
    function isWhitelisted(address _addr) external view returns (bool);
}

interface IBurnable {
    function burn(address _from, uint256 _amount) external;
}

contract Pool is Ownable, Vesting {
    using SafeERC20 for IERC20;
    /*
    Variables common to the pool
    */
    enum PoolStatus {
        UPCOMING,
        ONGOING,
        FINISHED
    }

    uint256 public maxCap;
    uint256 public saleStartTime;
    uint256 public saleEndTime;

    uint256 public maxAllocationPerUser;

    address private gameTokenAddress;
    uint256 public valueOfGameToken; // 1 bUSD equivalent

    IBurnable private xpToken =
        IBurnable(0x393F4e3D0f50A6dEB3900842365AD896e0f99266);
    IERC20 private bUSD = IERC20(0x27F4b42B1476650e54e65bBF02AaEA3798744D26);
    address private projectOwner;

    IWhitelistRegistry private whitelistRegistry;

    /*
    GUARANTEED ALLOCATION variables
    */

    // values in bUSD
    uint256 public maxCapForGuaranteedTier;
    uint256 public allocationLeftInGuaranteedTier;

    // price to buy tier in bUSD
    uint256[4] public priceForTierInBUSD;

    // price to buy tier in XP
    uint256[4] public priceForTierInXP;

    // number of slots in Guaranteed Tiers
    uint256[4] public slotsInTier;

    mapping(address => bool) public hasInvested;

    struct OverallInvestorInfo {
        uint256 totalAllocation;
        uint256 assignedGameTokens;
        uint256 claimedGameTokens;
        bool isInLottery;
        uint256 ticketCount;
        bool lotteryWon;
        uint256 allocationLost;
    }
    mapping(address => OverallInvestorInfo) public investorsInfo;

    /*
    LOTTERY ALLOCATION variables
    */

    uint256 public maxCapForLotteryTier; // max cap in bUSD
    uint256 public allocationLeftInLotteryTier;
    uint256 public winningTicketAllocation; // in bUSD

    uint256 public numberOfWinnersRequired;

    enum LotteryStatus {
        NOT_CREATED,
        STARTED,
        FINISHED
    }
    LotteryStatus public lotteryStatus = LotteryStatus.NOT_CREATED;

    struct TicketBracket {
        uint8 numberOfTickets;
        uint256 priceInXP;
    }
    TicketBracket[3] public ticketBrackets;

    uint256 private ticketId;
    mapping(uint256 => address) private ticketsOwner;

    event TokensClaimed(address indexed _investor, uint256 _amount);
    event BoughtGuaranteedTier(address indexed _investor, uint256 _allocation);
    event BoughtTickets(address indexed _investor, uint256 _numberOfTickets);

    /**
     * @param _maxCap maximum capital to be raised by this pool (bUSD)
     * @param _saleStartTime start time of the sale in epoch (seconds)
     * @param _saleEndTime end time of the sale in epoch (seconds)
     * @param _maxAllocationPerUser maximum allocation that user can get (bUSD)
     * @param _gameTokenAddress address of the game token that IGO is giving
     * @param _projectOwner address where we will send the bUSD amount
     * @param _valueOfGameToken 1 bUSD equivalent of the game token
     * @param _whitelistRegistry address of contract that maintains whitelisted address
     * @param _maxCapForGuaranteedTier maximum capital to be raised from guaranteed tiers (bUSD)
     * @param _priceForTierInBUSD an array containing prices to buy each of the Guaranteed tiers in bUSD
     * @param _priceForTierInXP an array containing prices to buy each of the Guaranteed tiers in XP
     */
    constructor(
        /* Pool Variables */
        uint256 _maxCap,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint256 _maxAllocationPerUser,
        address _gameTokenAddress,
        address _projectOwner,
        uint256 _valueOfGameToken,
        IWhitelistRegistry _whitelistRegistry,
        /* Guaranteed Allocation Variables */
        uint256 _maxCapForGuaranteedTier,
        uint256[4] memory _priceForTierInBUSD,
        uint256[4] memory _priceForTierInXP
    ) Vesting(_saleEndTime) {
        require(_maxCapForGuaranteedTier <= _maxCap, "max cap out of range");
        require(_saleStartTime < _saleEndTime, "sale time is out of range");
        require(
            _saleStartTime >= block.timestamp,
            "saleStartTime = current time"
        );
        require(_gameTokenAddress != address(0), "zero address assigned");
        require(_projectOwner != address(0), "zero address assigned");

        /* Pool Variables Initialization */
        maxCap = _maxCap;

        saleStartTime = _saleStartTime;
        saleEndTime = _saleEndTime;

        maxAllocationPerUser = _maxAllocationPerUser;

        // provide value of game token with decimal
        // ex: 2000000000000000000 ("decimal number of zeroes")
        valueOfGameToken = _valueOfGameToken;
        gameTokenAddress = _gameTokenAddress;

        projectOwner = _projectOwner;

        whitelistRegistry = _whitelistRegistry;

        /* Guaranteed Allocation variables Initialization */
        maxCapForGuaranteedTier = _maxCapForGuaranteedTier;

        allocationLeftInGuaranteedTier = maxCapForGuaranteedTier;

        for (uint256 i = 0; i < 4; i++) {
            priceForTierInBUSD[i] = _priceForTierInBUSD[i];
            priceForTierInXP[i] = _priceForTierInXP[i];
        }

        /* Lottery Allocation variables Initialization */
        maxCapForLotteryTier = maxCap - maxCapForGuaranteedTier;
        allocationLeftInLotteryTier = maxCapForLotteryTier;

        _rebalanceTierSlots();
    }

    /*
    modifiers for check
    */
    modifier _isWhitelisted(address _investor) {
        require(
            whitelistRegistry.isWhitelisted(_investor),
            "investor not whitelisted"
        );
        _;
    }

    modifier _hasAllowance(address allower, uint256 amount) {
        uint256 ourAllowance = bUSD.allowance(allower, address(this));
        require(amount <= ourAllowance, "add enough allowance");
        _;
    }

    modifier _isPoolActive() {
        require(getPoolStatus() == PoolStatus.ONGOING, "pool is not active");
        _;
    }

    /*
    GUARANTEED ALLOCATION - Start
    */

    /**
     * @notice function to buy a single slot from one of the four Guaranteed tiers.
     * @param _tierNumber which of the four tiers to buy (0, 1, 2, 3)
     */
    function buyFromTier(uint256 _tierNumber, uint256 _numberOfAllocations)
        external
        _hasAllowance(
            msg.sender,
            priceForTierInBUSD[_tierNumber] * _numberOfAllocations
        )
        _isPoolActive
        _isWhitelisted(msg.sender)
    {
        require(_tierNumber >= 0, "invalid tier selected");
        require(_tierNumber < 4, "invalid tier selected");
        require(
            allocationLeftInGuaranteedTier >
                priceForTierInBUSD[_tierNumber] * _numberOfAllocations,
            "no slots left"
        );
        require(_numberOfAllocations > 0, "invalid number of allocation");
        require(
            investorsInfo[msg.sender].totalAllocation +
                priceForTierInBUSD[_tierNumber] *
                _numberOfAllocations <=
                maxAllocationPerUser,
            "max allocation reached"
        );

        // burn XP
        xpToken.burn(
            msg.sender,
            priceForTierInXP[_tierNumber] * _numberOfAllocations
        );

        // transfer bUSD to project owner
        bUSD.safeTransferFrom(
            msg.sender,
            projectOwner,
            priceForTierInBUSD[_tierNumber] * _numberOfAllocations
        );

        allocationLeftInGuaranteedTier -=
            priceForTierInBUSD[_tierNumber] *
            _numberOfAllocations;

        investorsInfo[msg.sender].totalAllocation +=
            priceForTierInBUSD[_tierNumber] *
            _numberOfAllocations;

        investorsInfo[msg.sender].assignedGameTokens =
            (investorsInfo[msg.sender].totalAllocation / 1000000000000000000) *
            valueOfGameToken;

        if (!hasInvested[msg.sender]) {
            hasInvested[msg.sender] = true;
        }

        emit BoughtGuaranteedTier(msg.sender, priceForTierInBUSD[_tierNumber]);

        _rebalanceTierSlots();
    }

    /**
     * @notice investor can claim the game tokens once the sale ends
     */
    function claimGameTokens() external {
        require(block.timestamp > saleEndTime, "sale has not ended");
        require(block.timestamp >= claimTime, "claim period not started");
        require(hasInvested[msg.sender], "not an investor");

        uint256 claimableAmount = getUnlockedTokens(msg.sender);
        require(claimableAmount > 0, "nothing to claim");

        investorsInfo[msg.sender].claimedGameTokens += claimableAmount;

        IERC20(gameTokenAddress).safeTransfer(msg.sender, claimableAmount);

        emit TokensClaimed(msg.sender, claimableAmount);
    }

    /**
     * @notice get the number of tokens that have been unlocked for investor to claim
     * @param _investor address of the investor
     */
    function getUnlockedTokens(address _investor)
        public
        view
        returns (uint256)
    {
        uint256 assignedTokens = investorsInfo[_investor].assignedGameTokens;
        uint256 claimedTokens = investorsInfo[_investor].claimedGameTokens;
        return _getClaimableAsset(assignedTokens, claimedTokens);
    }

    /**
     * @notice get number of slots in each of the four guaranteed tiers
     */
    function getSlotsInEachTier() external view returns (uint256[4] memory) {
        return slotsInTier;
    }

    /**
     * @notice get the status of the pool
     */
    function getPoolStatus() public view returns (PoolStatus) {
        if (block.timestamp <= saleStartTime) {
            return PoolStatus.UPCOMING;
        }

        if (block.timestamp >= saleEndTime) {
            return PoolStatus.FINISHED;
        }

        return PoolStatus.ONGOING;
    }

    /**
     * @notice internal function to rebalance the number of slots
     */
    function _rebalanceTierSlots() internal {
        for (uint256 i = 0; i < 4; i++) {
            slotsInTier[i] =
                allocationLeftInGuaranteedTier /
                priceForTierInBUSD[i];
        }
    }

    /*
    GUARANTEED ALLOCATION - End
    */

    /*
    LOTTERY ALLOCATION - Start
    */

    /**
     * @notice function to create lottery (call this after deploying the pool)
     * @param _numberOfTicketsInEachBracket amount of tickets in each bracket
     * @param _priceInXPForEachBracket XP that will be burned in each bracket
     * @param _winningTicketAllocation price of each ticket (bUSD)
     */
    function createLottery(
        uint8[3] memory _numberOfTicketsInEachBracket,
        uint256[3] memory _priceInXPForEachBracket,
        uint256 _winningTicketAllocation
    ) external onlyOwner {
        require(
            getPoolStatus() == PoolStatus.UPCOMING,
            "pool has either started or ended"
        );
        require(
            lotteryStatus == LotteryStatus.NOT_CREATED,
            "lottery already created"
        );
        for (uint8 i = 0; i < 3; i++) {
            ticketBrackets[i].numberOfTickets = _numberOfTicketsInEachBracket[
                i
            ];
            ticketBrackets[i].priceInXP = _priceInXPForEachBracket[i];
        }

        winningTicketAllocation = _winningTicketAllocation;
        numberOfWinnersRequired =
            maxCapForLotteryTier /
            winningTicketAllocation;
        lotteryStatus = LotteryStatus.STARTED;
    }

    /**
     * @notice function to buy lottery tickets
     * @param _bracketNumber number of bracket to buy ticket from
     */
    function buyTickets(uint256 _bracketNumber, uint256 _numberOfBrackets)
        external
        _isWhitelisted(msg.sender)
        _hasAllowance(
            msg.sender,
            winningTicketAllocation *
                ticketBrackets[_bracketNumber].numberOfTickets *
                _numberOfBrackets
        )
        _isPoolActive
    {
        require(
            lotteryStatus == LotteryStatus.STARTED,
            "lottery is not active"
        );

        xpToken.burn(
            msg.sender,
            ticketBrackets[_bracketNumber].priceInXP * _numberOfBrackets
        );

        uint256 numberOfTickets = ticketBrackets[_bracketNumber]
            .numberOfTickets * _numberOfBrackets;

        bUSD.safeTransferFrom(
            msg.sender,
            address(this),
            winningTicketAllocation * numberOfTickets
        );

        hasInvested[msg.sender] = true;
        investorsInfo[msg.sender].isInLottery = true;

        for (uint256 i = 0; i < numberOfTickets; i++) {
            // TicketInfo memory newTicket = TicketInfo(msg.sender, tickets.length);
            // tickets.push(newTicket);
            ticketsOwner[ticketId] = msg.sender;
            ticketId += 1;
        }

        investorsInfo[msg.sender].ticketCount += numberOfTickets;
        investorsInfo[msg.sender].allocationLost +=
            winningTicketAllocation *
            numberOfTickets;

        emit BoughtTickets(msg.sender, numberOfTickets);
    }

    /**
     * @notice function to draw winners after the pool ends
     * @param _seed any random string
     */
    function drawWinners(string calldata _seed) external onlyOwner {
        require(
            getPoolStatus() == PoolStatus.FINISHED,
            "pool has not ended yet"
        );
        require(
            lotteryStatus == LotteryStatus.STARTED,
            "lottery is not active"
        );
        if (
            ticketId <= numberOfWinnersRequired /* tickets.length */
        ) {
            for (
                uint256 i = 0;
                i < ticketId; /* tickets.length */
                i++
            ) {
                // TicketInfo storage ticket = tickets[i];
                // _rewardWinner(ticket.owner);
                address owner = ticketsOwner[i];
                _rewardWinner(owner);
            }
        } else {
            for (uint256 i = 0; i < numberOfWinnersRequired; i++) {
                uint256 winningIndex = _getWinningIndex(_seed, i);
                // TicketInfo memory ticket = tickets[winningIndex];
                // tickets[winningIndex] = tickets[tickets.length - 1];
                // tickets.pop();

                // _rewardWinner(ticket.owner);
                address owner = ticketsOwner[winningIndex];
                ticketsOwner[winningIndex] = ticketsOwner[ticketId - 1];
                _rewardWinner(owner);
                ticketId -= 1;
            }
        }

        lotteryStatus = LotteryStatus.FINISHED;
    }

    /**
     * @notice internal function to reward winners
     */
    function _rewardWinner(address _owner) internal {
        investorsInfo[_owner].totalAllocation += winningTicketAllocation;

        investorsInfo[_owner].assignedGameTokens =
            (investorsInfo[_owner].totalAllocation / 1000000000000000000) *
            valueOfGameToken;

        allocationLeftInLotteryTier -= winningTicketAllocation;

        investorsInfo[_owner].lotteryWon = true;

        investorsInfo[_owner].allocationLost -= winningTicketAllocation;
    }

    /**
     * @notice internal function to get the winning ticket
     */
    function _getWinningIndex(string memory _seed, uint256 i)
        internal
        view
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(_seed, i))) % ticketId;
        // return uint256(keccak256(abi.encode(_seed, i))) % tickets.length;
    }

    /**
     * @notice function to claim back the bUSD, in case investor loses in the lottery
     */
    function claimBackBUSD() external {
        require(
            investorsInfo[msg.sender].isInLottery,
            "did not participate in lottery"
        );
        require(investorsInfo[msg.sender].lotteryWon, "nothing to claim");
        require(
            investorsInfo[msg.sender].allocationLost > 0,
            "nothing to claim"
        );
        require(
            lotteryStatus == LotteryStatus.FINISHED,
            "lottery still in progress"
        );

        investorsInfo[msg.sender].allocationLost = 0;
        bUSD.safeTransfer(msg.sender, investorsInfo[msg.sender].allocationLost);
    }

    /**
     * @notice function to transfer the bUSD to the projectOwner
     */
    function transferLotteryEarnings() external onlyOwner {
        bUSD.safeTransfer(projectOwner, bUSD.balanceOf(address(this)));
    }

    /*
    LOTTERY ALLOCATION - End
    */

    /**
     * @notice function to update the start of claiming time
     * @param _claimTime new claim time in epoch timestamp
     */
    function updateClaimTime(uint256 _claimTime) external onlyOwner {
        require(block.timestamp < claimTime, "claim time already started");
        claimTime = _claimTime;
    }

    /**
     * @notice function to give back the tokens sent directly to this contract
     */
    function emergencyWithdraw(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(getPoolStatus() == PoolStatus.FINISHED, "pool not finished");
        IERC20(_token).safeTransfer(_to, _amount);
    }
}

// bUSD: https://bscscan.com/address/0xe9e7cea3dedca5984780bafc599bd69add087d56#code

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

contract Vesting {
    struct VestingStages {
        uint256 timePeriod;
        uint256 percentage;
    }
    uint256 public claimTime;

    /**
     * @notice constructor to initial vesting periods and claim time
     * @param _claimTime epoch timestamp
     */
    constructor(uint256 _claimTime) {
        claimTime = _claimTime;
        initVestingStages();
    }

    VestingStages[] public stages;

    /**
     * @notice function to set claim/vesting policy
     * @notice 1000 -> 10%, 2500 -> 25% (of the assigned tokens to the investor NOT the assigned - claimed)
     * @notice we can write the claim policy here
     * @notice vesting stages after the first one are relative to the claim time
     */
    function initVestingStages() internal {
        uint256 vestingPeriod = 2 minutes;

        stages.push(VestingStages(0, 1000));
        /* first stage (10%) */

        stages.push(VestingStages(vestingPeriod, 2500));
        stages.push(VestingStages(12 * vestingPeriod, 3000));
        stages.push(VestingStages(24 * vestingPeriod, 4500));
        stages.push(VestingStages(36 * vestingPeriod, 6000));

        stages.push(VestingStages(48 * vestingPeriod, 10000));
        /* last stage (100% claim)  */
    }

    /**
     * @notice internal function to get current unlocked percentage
     * @return unlocked percentage value
     */
    function _getUnlockedPercentage() internal view returns (uint256) {
        if (block.timestamp < claimTime) {
            return 0;
        }

        uint256 allowedPercent;

        for (uint8 i = 0; i < stages.length; i++) {
            if (block.timestamp >= stages[i].timePeriod + claimTime) {
                allowedPercent = stages[i].percentage;
            }
        }
        return allowedPercent;
    }

    /**
     * @notice internal function to calculate claimable tokens for current vesting stage
     * @param assignedAsset number of tokens that have been assigned to investor
     * @param claimedAsset number of tokens that have been claimed by the investor
     */
    function _getClaimableAsset(uint256 assignedAsset, uint256 claimedAsset)
        internal
        view
        returns (uint256)
    {
        uint256 unlockedAsset = ((assignedAsset * _getUnlockedPercentage())) /
            10000;
        return unlockedAsset - claimedAsset;
    }

    /**
     * @notice function to get the time for next stage
     * @return epoch timestamp of next stage (0, if Vesting Period is over)
     */
    function getNextClaimTime() public view returns (uint256) {
        for (uint256 i = 0; i < stages.length; i++) {
            if (block.timestamp < stages[i].timePeriod + claimTime) {
                return stages[i].timePeriod + claimTime;
            }
        }

        return 0;
    }

    /**
     * @notice function to get the upcoming vesting stage
     * @return VestingStage { date, percentage }
     */
    function getNextStage() public view returns (VestingStages memory) {
        for (uint256 i = 0; i < stages.length; i++) {
            if (block.timestamp < stages[i].timePeriod + claimTime) {
                return stages[i];
            }
        }

        return VestingStages(0, 0);
    }

    function getNumberOfStages() external view returns (uint256) {
        return stages.length;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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