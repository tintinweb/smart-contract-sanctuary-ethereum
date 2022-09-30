/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol

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

// File: stakingContract.sol


pragma solidity 0.8.17;

interface IBEP20 {
    
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
}

interface PreSale {

    function getTotalBuyers() external view returns(uint256);
    function getTokenBuyersInfo(uint256 _tokenBuyer) external view returns(address, uint256);
    function getTotalSoldTokens() external view returns(uint256);
}

contract StakingContract {
    using SafeMath for uint256;

    IBEP20 public genToken;
    IBEP20 public arenaToken;
    IBEP20 public busdToken;
    PreSale public preSale;

    struct Stake {
        uint256 amount;
        uint256 genBonus;
        uint256 areenaBonus;
    }

    struct Player {
        uint256 battleCount;
        uint256 walletLimit;
        uint256 withdrawTime;
        uint256 activeBattles;
        uint256 winingBattles;
        uint256 losingBattles;
        uint256 totalGenBonus;
        uint256 referalAmount;
        uint256 totalArenaTokens;
        uint256 totalAmountStaked;
        uint256 genAmountPlusBonus;
        mapping(uint256 => Stake) battleRecord;
    }

    struct Battle {
        bool active;
        bool joined;
        bool leaved;
        bool completed;
        address loser;
        address winner;
        address joiner;
        address creator;
        uint256 battleTime;
        uint256 endingTime;
        uint256 stakeAmount;
        uint256 startingTime;
        uint256 riskPercentage;
        uint256 creatorStartingtime;
    }

    struct referenceInfo {
        uint256 creatorReferalAmount;
        uint256 joinerReferalAmount;
        address battleCreator;
        address battleJoiner;
        address creatorReferalPerson;
        address joinerReferalPerson;
    }

    bool public saleEnabled;
    address public owner;
    uint256 public battleId;
    uint256 public totalAreena;
    uint256 public saleEndTime;
    uint256 public saleStartTime;
    uint256 public genBonusPercentage;
    uint256 public lowerMileStone;
    uint256 public uppermileStone;
    uint256 public areenaInCirculation;
    uint256 public genRewardPercentage;
    uint256 public genRewardMultiplicationValue;

    uint256 private minimumStake = 25;
    uint256[5] public stakeOptions = [25, 100, 250, 500, 1000];
    uint256[5] public riskOptions = [25, 50, 75];

    mapping(uint256 => Battle) public battles;
    mapping(address => Player) public players;
    mapping(address => uint256[]) public playerBattleIds;
    mapping(uint256 => referenceInfo) public referalPerson;
    mapping(address => uint256) private genLastTransaction;
    mapping(address => uint256) private referalLastTransaction;
    mapping(address => uint256) public areenaLastTransactionForGen;
    mapping(address => uint256) public areenaLastTransactionForBusd;
    mapping(uint256 => mapping(address => uint256)) public stakeCount;
    mapping(address => mapping(address => bool)) public alreadyBatteled;
    mapping(uint256 => mapping(address => mapping(address => uint256))) public referalTime;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public claimRferalAmount;

    address private busdWallet = 0x1D375435c8EfA3e489ef002d2d0B1E7Eb3CC62Fe;
    address private areenaWallet = 0x1D375435c8EfA3e489ef002d2d0B1E7Eb3CC62Fe;
    address private preSaleWallet = 0x1F811008eE5C9A3f9AD128571a0507Fe591A4043;
    address private treasuryWallet = 0x1D375435c8EfA3e489ef002d2d0B1E7Eb3CC62Fe;

    // address private treasuryWallet = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    // address private areenaWallet = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    // address private busdWallet = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    // address private preSaleWallet = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;



    event genSellInfo(address genBuyer, uint256 genAmount, uint256 busdAmount);
    event leaveBattleDetails(address creator, address joiner, uint256 _battleId);
    event loserDetails(uint256 indexed looserStakedAmount, uint256 looserGenBonus);
    event areenaBooster(address buyer, uint256 priceUserPaid, uint256 newWalletLimit);
    event areenaTokenSold(address sellerAddress, uint256 lowerMileStone, uint256 upperMileStone);
    event claimReferalAmount(uint256 referalAmount, uint256 nextTime, uint256 castleAmount);
    event battleJoiner(address indexed battleJoiner, uint256 stakeAmount, uint256 indexed battleId);
    event createBattle(address indexed battleCreator, uint256 stakeAmount, uint256 indexed battleId);
    event battleCreator(address indexed battleCreator, uint256 stakeAmount, uint256 indexed battleId);
    event SellThroughDashboard(bool bonusEnabled, uint256 _amount, uint256 _bonusAmount, uint256 _time);
    event SellThroughAreena(uint256 areenaPrice, uint256 _totalAmountOfGen, uint256 _AddedInCastle);
    event winnerDetails(uint256 indexed winnerStakedAmount, uint256 winnerGenBonus, uint256 indexed winnerAreenaBonus);
    event withdrawThreePercentage(address withdrawerAddress, uint256 withdrawAmount, uint256 remainingAmount, uint256 nextTime);
    event withdrawFivePercentage(address withdrawerAddress, uint256 withdrawAmount, uint256 remainingAmount, uint256 nextTime);
    event withdrawSevenPercentage(address withdrawerAddress, uint256 withdrawAmount, uint256 remainingAmount, uint256 nextTime);
    event referalInfo(address joinerRefaralPerson, address creatorReferalPerson, uint256 joinerReferalAmount, 
          uint256 creatorReferalAmount, uint256 battleId, uint256 joinerReferalTime, uint256 creatorReferalTime);



    constructor(address _genToken, address _busdToken, address _preSale) {
       
        owner = msg.sender;
        genToken = IBEP20(_genToken);
        busdToken = IBEP20(_busdToken);
        preSale = PreSale(_preSale);
        genRewardPercentage = 416667000000000; //0.000416667%
        genRewardMultiplicationValue = 1e9;
        totalAreena = 10000 * 1e18;
    }




    function checkOption(uint256 amount) internal view returns (uint256) {
        uint256 value;
        for (uint256 i = 0; i < 5; i++) {
            if (amount == stakeOptions[i]) {
                value = stakeOptions[i];
                break;
            }
        }
        if (value != 0) {
            return value;
        } else {
            return amount;
        }
    }

    function CreateBattle( uint256 _amount, uint256 _riskPercentage, address _referalPerson) external {
        
        Player storage player = players[msg.sender];

        Battle storage battle = battles[battleId];
        battle.creator = msg.sender;

        uint256 stakeAmount = checkOption(_amount);
        stakeAmount = stakeAmount.mul(1e18);

        require( stakeAmount >= minimumStake, "You must stake atleast 25 Gen tokens to enter into the battle.");
        require( stakeAmount <= (stakeOptions[4].mul(1e18)), "You can not stake more then 1000 Gen tokens to create a battle.");

        require((genToken.balanceOf(battle.creator) + player.genAmountPlusBonus) >= stakeAmount, "You does not have sufficent amount of gen Token.");
        require(_riskPercentage == riskOptions[0] || _riskPercentage == riskOptions[1] || _riskPercentage == riskOptions[2],"Please chose the valid risk percentage.");

        require(battle.creator != address(0), "Player address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");

        if (genToken.balanceOf(battle.creator) < stakeAmount) {
            
            uint256 amountFromUser = genToken.balanceOf(battle.creator);
            
            genToken.transferFrom(battle.creator, address(this), amountFromUser);

            uint256 amountFromAddress = stakeAmount - amountFromUser;
            player.genAmountPlusBonus -= amountFromAddress;

        } else {
            genToken.transferFrom(battle.creator, address(this), stakeAmount);
        }

        emit createBattle(battle.creator, stakeAmount, battleId);

        referalPerson[battleId].creatorReferalPerson = _referalPerson;
        referalPerson[battleId].battleCreator = battle.creator;
        playerBattleIds[battle.creator].push(battleId);

        battleId++;
        battle.stakeAmount = stakeAmount;
        battle.riskPercentage = _riskPercentage;
        battle.creatorStartingtime = block.timestamp;
    }

    uint256 private creatorReferalAmount;
    uint256 private joinerReferalAmount;
    uint256 private sendCreatorDeductionAmount;
    uint256 private sendJoinerDeductionAmount;

    uint256 private joinerAfterDeductedAmount;

    function JoinBattle(uint256 _amount, uint256 _battleId, address _joinerReferalPerson ) public {
        
        Battle storage battle = battles[_battleId];
        Player storage player = players[msg.sender];
        battle.joiner = msg.sender;

        uint256 stakeAmount = _amount.mul(1e18);

        require(!battle.joined && !battle.leaved && battle.stakeAmount != 0,"You can not join this battle. This battle in not created yet!.");
        require(!battle.joined && !battle.leaved,"You can not join this battle. This battle may be already joined or completed.");

        require(!alreadyBatteled[battle.creator][battle.joiner],"You can not create or join new battles with same person.");
        require(!alreadyBatteled[battle.joiner][battle.creator],"You can not create or join new battles with same person.");

        require(stakeAmount == battle.stakeAmount,"Enter the exact amount of tokens to be a part of this battle.");
        require((genToken.balanceOf(battle.joiner) + player.genAmountPlusBonus) >= stakeAmount,"You does not have sufficent amount of gen Token.");

        require(battle.joiner != address(0), "Player address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");

        players[battle.creator].battleCount++;
        if (battle.creator != battle.joiner) {
            player.battleCount++;
        }

        battle.startingTime = block.timestamp;
        battle.active = true;
        battle.joined = true;

        players[battle.creator].activeBattles++;
        if (battle.creator != battle.joiner) {
            player.activeBattles++;
        }

        stakeCount[_battleId][battle.creator] = players[battle.creator].battleCount;
        stakeCount[_battleId][battle.joiner] = players[battle.joiner].battleCount;

        // playerBattleIds[battle.joiner].push(_battleId);

        uint256 creatorDeductedAmount = calculateCreatorPercentage(stakeAmount);
        uint256 creatorAfterDeductedAmount = stakeAmount - creatorDeductedAmount;

        uint256 joinerDeductedAmount = calculateJoinerPercentage(stakeAmount);
        joinerAfterDeductedAmount = stakeAmount - joinerDeductedAmount;

        if (genToken.balanceOf(msg.sender) < stakeAmount) {
            
            uint256 amountFromUser = genToken.balanceOf(battle.joiner);
            genToken.transferFrom(battle.joiner, address(this), amountFromUser);

            uint256 amountFromAddress = stakeAmount - amountFromUser;
            player.genAmountPlusBonus -= amountFromAddress;
        
        } else {
            genToken.transferFrom(battle.joiner, address(this), stakeAmount);
        }

        ////////// Joiner_Referal_section /////////////

        joinerReferalAmount = calculateReferalPercentage(stakeAmount);

        referalPerson[_battleId].battleJoiner = battle.joiner;
        referalPerson[_battleId].joinerReferalPerson = _joinerReferalPerson;
        referalPerson[_battleId].joinerReferalAmount = joinerReferalAmount;

        sendJoinerDeductionAmount = joinerDeductedAmount - joinerReferalAmount;
        genToken.transfer(treasuryWallet, sendJoinerDeductionAmount);

        players[_joinerReferalPerson].referalAmount += joinerReferalAmount;

        uint256 joinerReferalTime = block.timestamp;
        referalTime[_battleId][battle.joiner][_joinerReferalPerson] = joinerReferalTime;

        settingReferalInfo(joinerReferalTime, joinerReferalAmount, _joinerReferalPerson, battle.joiner);

        ////////// Creator_Referal_section /////////////

        creatorReferalAmount = calculateReferalPercentage(stakeAmount);

        referalPerson[_battleId].creatorReferalAmount = creatorReferalAmount;

        sendCreatorDeductionAmount = creatorDeductedAmount - creatorReferalAmount;
        genToken.transfer(treasuryWallet, sendCreatorDeductionAmount);

        players[referalPerson[_battleId].creatorReferalPerson].referalAmount += creatorReferalAmount;

        uint256 creatorReferalTime = block.timestamp;
        referalTime[_battleId][battle.creator][referalPerson[_battleId].creatorReferalPerson] = creatorReferalTime;

        settingReferalInfo(creatorReferalTime, creatorReferalAmount, referalPerson[_battleId].creatorReferalPerson, battle.creator);

        alreadyBatteled[battle.creator][battle.joiner] = true;
        alreadyBatteled[battle.joiner][battle.creator] = true;

        player.totalAmountStaked += joinerAfterDeductedAmount;
        players[battle.creator].totalAmountStaked += creatorAfterDeductedAmount;
        players[battle.creator].battleRecord[stakeCount[_battleId][battle.creator]].amount = creatorAfterDeductedAmount;
        players[battle.joiner].battleRecord[stakeCount[_battleId][battle.joiner]].amount = joinerAfterDeductedAmount;

        emit referalInfo(
            _joinerReferalPerson,
            referalPerson[_battleId].creatorReferalPerson,
            referalPerson[_battleId].joinerReferalAmount,
            referalPerson[_battleId].creatorReferalAmount,
            _battleId,
            joinerReferalTime,
            creatorReferalTime
        );

        emit battleJoiner(battle.joiner, stakeAmount, _battleId);

        emit battleCreator(
            battle.creator,
            players[battle.creator]
                .battleRecord[players[battle.creator].battleCount]
                .amount,
            _battleId
        );
    }

    function settingReferalInfo(uint256 _referalTime, uint256 _referalAmount, address _referalPerson, address _battlePerson) internal {
        claimRferalAmount[_battlePerson][_referalPerson][_referalTime] = _referalAmount;
    }

     function calculateCreatorPercentage(uint256 _amount) public pure returns (uint256){

        uint256 _initialPercentage = 2000; // 20 %
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateJoinerPercentage(uint256 _amount) public pure returns (uint256){

        uint256 _initialPercentage = 3000; // 30 %
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateReferalPercentage(uint256 _amount) public pure returns (uint256){

        uint256 _initialPercentage = 500; // 5 %
        return _amount.mul(_initialPercentage).div(10000);
    }

// ========================== Leave Battle Functions ============================================

    uint256 private totalMinutes;

    function LeaveBattle(uint256 _battleId) public {
        
        Battle storage battle = battles[_battleId];

        require(msg.sender == battle.creator || msg.sender == battle.joiner,"You must be a part of a battle before leaving it.");
        require(!battle.leaved,"You canot join this battle because battle creator Already leaved.");

        require(msg.sender != address(0), "Player address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");

        if (!battle.joined) {
            if (block.timestamp < (battle.startingTime + 15 minutes)) //////////////////////48 hours add
            {
                uint256 _tokenAmount = battle.stakeAmount;

                uint256 deductedAmount = calculateSendBackPercentage(_tokenAmount);

                _tokenAmount = _tokenAmount - deductedAmount;
                players[battle.creator].genAmountPlusBonus += _tokenAmount; 
                genToken.transfer(treasuryWallet, deductedAmount);

                battle.leaved = true;
            } else {
                players[battle.creator].genAmountPlusBonus += battle.stakeAmount;
                battle.leaved = true;
            }

        } else {
            
            require(!battle.completed, "This battle is already ended.");

            if (msg.sender == battle.creator) {
                battle.loser = battle.creator;
                battle.winner = battle.joiner;
            } else {
                battle.loser = battle.joiner;
                battle.winner = battle.creator;
            }

            uint256 losertokenAmount = players[battle.loser].battleRecord[stakeCount[_battleId][battle.loser]].amount;
            uint256 winnertokenAmount = players[battle.winner].battleRecord[stakeCount[_battleId][battle.winner]].amount;

            totalMinutes = calculateTotalMinutes(block.timestamp, battle.startingTime);

            uint256 loserGenReward = calculateRewardInGen(losertokenAmount, totalMinutes);
            uint256 winnerGenReward = calculateRewardInGen(winnertokenAmount, totalMinutes);

            uint256 riskDeductionFromLoser = calculateRiskPercentage(loserGenReward, battle.riskPercentage);

            uint256 loserFinalGenReward = loserGenReward - riskDeductionFromLoser;

            uint256 winnerAreenaReward = calculateRewardInAreena( battle.stakeAmount, totalMinutes);

            uint256 sendWinnerGenReward = winnerGenReward + riskDeductionFromLoser + winnertokenAmount;
            uint256 sendLoserGenReward = losertokenAmount + loserFinalGenReward;

            areenaInCirculation += winnerAreenaReward;
            battle.endingTime = block.timestamp;
            battle.battleTime = totalMinutes;
            battle.completed = true;
            battle.active = false;

            players[battle.winner].winingBattles++;
            players[battle.winner].genAmountPlusBonus += sendWinnerGenReward;
            players[battle.winner].totalArenaTokens += winnerAreenaReward;
            players[battle.loser].losingBattles++;
            players[battle.loser].genAmountPlusBonus += sendLoserGenReward;
            players[battle.winner].totalGenBonus += (winnerGenReward + riskDeductionFromLoser);
            players[battle.loser].totalGenBonus += loserFinalGenReward;

            players[battle.winner].battleRecord[stakeCount[_battleId][battle.winner]].genBonus = (winnerGenReward + riskDeductionFromLoser);
            players[battle.winner].battleRecord[stakeCount[_battleId][battle.winner]].areenaBonus = winnerAreenaReward;
            players[battle.loser].battleRecord[stakeCount[_battleId][battle.loser]].genBonus = loserFinalGenReward;

            if (battle.creator != battle.joiner) {
                players[battle.winner].activeBattles--;
            }
            players[battle.loser].activeBattles--;

            emit leaveBattleDetails(
                battle.creator, 
                battle.joiner, 
                _battleId
            );

            emit winnerDetails(
                winnertokenAmount,
                (winnerGenReward + riskDeductionFromLoser),
                winnerAreenaReward
            );

            emit loserDetails(
                losertokenAmount, 
                loserFinalGenReward
            );
        }
    }


    function calculateSendBackPercentage(uint256 _amount) public pure returns (uint256){

        uint256 _initialPercentage = 300; // 3 %
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateTotalMinutes(uint256 _endingTime, uint256 _startingTime) public pure returns (uint256 _totalMinutes){

        _totalMinutes = ((_endingTime - _startingTime) / 60); // in minutes!
        return _totalMinutes;
    }

    function calculateRewardInGen(uint256 _amount, uint256 _totalMinutes) public view returns (uint256){

        uint256 _initialPercentage = genRewardPercentage;
        _initialPercentage = (_initialPercentage * _totalMinutes).div(genRewardMultiplicationValue);

        uint256 value = ((_amount.mul(_initialPercentage)).div(100 * genRewardMultiplicationValue));
        
        return value;
    }

    function calculateRiskPercentage(uint256 _amount, uint256 _riskPercentage)
        public
        pure
        returns (uint256)
    {
        uint256 _initialPercentage = _riskPercentage.mul(100);
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateZValue(uint256 zValue) public pure returns (uint256) {

        return (zValue % 100 == 0) ? (zValue / 100) : ((zValue / 100) + 1);
    }

    function calculateRewardInAreena(uint256 _amount, uint256 _battleLength) public view returns (uint256){

        uint256 realAreena = (totalAreena - areenaInCirculation).div(1e18);
        return (((calculateZValue(realAreena) * _amount).div(525600)).mul(_battleLength)).div(100);
    }


//========================== Gen Withdraw Functions ====================================


    function GenWithdraw(uint256 _percentage) external {
        Player storage player = players[msg.sender];

        require(player.genAmountPlusBonus > 0,"You do not have sufficent amount of tokens to withdraw.");

        if (_percentage == 3) {
            
            require(genLastTransaction[msg.sender] < block.timestamp,"You canot withdraw amount before 13 minutes");
            genLastTransaction[msg.sender] = block.timestamp + 13 minutes; //hours/////////////////////////

            uint256 sendgenReward = calculateWithdrawThreePercentage(player.genAmountPlusBonus);
            genToken.transfer(msg.sender, sendgenReward);

            player.genAmountPlusBonus -= sendgenReward;
            player.withdrawTime = genLastTransaction[msg.sender];

            emit withdrawThreePercentage(
                msg.sender,
                sendgenReward,
                player.genAmountPlusBonus,
                genLastTransaction[msg.sender]
            );

        } else if (_percentage == 5) {

            require(genLastTransaction[msg.sender] < block.timestamp,"You canot withdraw amount before 15 minutes");
            genLastTransaction[msg.sender] = block.timestamp + 15 minutes; //hours//////////////////////

            uint256 sendgenReward = calculateWithdrawFivePercentage(player.genAmountPlusBonus);
            genToken.transfer(msg.sender, sendgenReward);

            player.genAmountPlusBonus -= sendgenReward;
            player.withdrawTime = genLastTransaction[msg.sender];

            emit withdrawFivePercentage(
                msg.sender,
                sendgenReward,
                player.genAmountPlusBonus,
                genLastTransaction[msg.sender]
            );

        } else if (_percentage == 7) {

            require(genLastTransaction[msg.sender] < block.timestamp,"You canot withdraw amount before 17 minutes");
            genLastTransaction[msg.sender] = block.timestamp + 17 minutes; //hours/////////////////

            uint256 sendgenReward = calculateWithdrawSevenPercentage(player.genAmountPlusBonus);
            genToken.transfer(msg.sender, sendgenReward);

            player.genAmountPlusBonus -= sendgenReward;
            player.withdrawTime = genLastTransaction[msg.sender];

            emit withdrawSevenPercentage(
                msg.sender,
                sendgenReward,
                player.genAmountPlusBonus,
                genLastTransaction[msg.sender]
            );

        } else {

            require(_percentage == 3 || _percentage == 5 || _percentage == 7,"Enter the right amount of percentage.");
        }
    }

    function calculateWithdrawThreePercentage(uint256 _amount) public pure returns (uint256){
        
        uint256 _initialPercentage = 300; // 3 %
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateWithdrawFivePercentage(uint256 _amount) public pure returns (uint256){

        uint256 _initialPercentage = 500; // 5 %
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateWithdrawSevenPercentage(uint256 _amount) public pure returns (uint256){
        
        uint256 _initialPercentage = 700; // 7 %
        return _amount.mul(_initialPercentage).div(10000);
    }


// ==========================Areena Boster Functions ==========================


    function BuyAreenaBoster() external {

        Player storage player = players[msg.sender];

        if(player.walletLimit == 0){
            player.walletLimit = 1*1e18;
        }

        uint256 _areenaBosterPrice = calculateAreenaBosterPrice();

        require(busdToken.balanceOf(msg.sender) >= _areenaBosterPrice, "You didnt have enough amount of USD to buy Areena Boster.");
        busdToken.transferFrom(msg.sender, busdWallet, _areenaBosterPrice);

        player.walletLimit += 3*1e18;

        emit areenaBooster(msg.sender, _areenaBosterPrice, player.walletLimit);
    }

    function calculateAreenaBosterPrice() public view returns (uint256) {
        
        uint256 areenaInTreasury = AreenaInTreasury();
        uint256 ABV = BusdInTreasury().mul(1e18);

        uint256 findValue = (ABV.div(areenaInTreasury));
        uint256 bosterPercentage = calculateBosterPercentage(findValue);

        return bosterPercentage;
    }

    function calculateBosterPercentage(uint256 _amount) public pure returns (uint256){
        
        uint256 _initialPercentage = 7500; // 25 * 3 = 75 %
        return _amount.mul(_initialPercentage).div(10000);
    }

    function getAreenaBosterPrice() external view returns (uint256) {
        return calculateAreenaBosterPrice();
    }




//================================Areena Functions ============================================


    


    bool private onceGreater;

    function sellAreenaByBusd(uint256 _tokenAmount) external {
        
        uint256 _realTokenAmount = _tokenAmount.mul(1e18);

        Player storage player = players[msg.sender];

        if (player.walletLimit == 0) {
            player.walletLimit = 1 * 1e18;
        }

        uint256 _walletLimit = player.walletLimit;

        require(_realTokenAmount < _walletLimit,"Please Buy Areena Boster To get All of your reward.");
        require(_realTokenAmount <= (3 * 1e18),"You can sell only three areena Token per day.");

        require(owner != address(0), "ERC20: approve from the zero address");
        require(msg.sender != address(0), "ERC20: approve to the zero address");

        require(players[msg.sender].totalArenaTokens >= _realTokenAmount,"You do not have sufficient amount of balance.");

        if (!onceGreater) {
            
            require((busdToken.balanceOf(busdWallet) + (90000 * 1e18)) >= (101000 * 1e18),"Selling of Areena token will start when BusdTreasury wallet reaches 101000.");
            onceGreater = true;
        }

        lowerMileStone = 101000 * 1e18;
        uppermileStone = 102000 * 1e18;

        require((busdToken.balanceOf(busdWallet) + (90000 * 1e18)) > lowerMileStone && 
                (busdToken.balanceOf(busdWallet) + (90000 * 1e18)) < uppermileStone,
                "Areena selling Start when busdTreasury will be greater then lower milestone.");

        if ((busdToken.balanceOf(busdWallet) + (90000 * 1e18)) > lowerMileStone && (busdToken.balanceOf(busdWallet) + (90000 * 1e18)) <= uppermileStone) {

            require(block.timestamp > areenaLastTransactionForBusd[msg.sender],"You canot sell areena token again before 24 hours.");

            uint256 sendAmount = _tokenAmount.mul(calculateAreenaPrice());
            uint256 checkBalance = (busdToken.balanceOf(busdWallet) + (90000 * 1e18)) - sendAmount;

            require(checkBalance > lowerMileStone,"You couldent sell Areena untill busd amount reaches to a certain level.");

            busdToken.transferFrom(busdWallet, msg.sender, sendAmount);

            areenaInCirculation -= _realTokenAmount;
            players[msg.sender].totalArenaTokens -= _realTokenAmount;
            totalAreena += _realTokenAmount;

            areenaLastTransactionForBusd[msg.sender] = block.timestamp + 4 minutes; //////////hours////////////////
            emit areenaTokenSold(msg.sender, lowerMileStone, uppermileStone);
        }

        uint256 walletSize = (busdToken.balanceOf(busdWallet) + (90000 * 1e18));

        if (walletSize >= uppermileStone) {
            lowerMileStone = uppermileStone.add(1000);
            uppermileStone = uppermileStone.add(1000);
        }
    }



    function sellAreenaByGen(uint256 _areenaAmount, uint256 _genPrice) external {
       
        uint256 _realTokenAmount = _areenaAmount.mul(1e18);

        Player storage player = players[msg.sender];

        require(players[msg.sender].totalArenaTokens >= _realTokenAmount,"You do not have sufficient amount of balance.");

        if (player.walletLimit == 0) {
            player.walletLimit = 1 * 1e18;
        }

        uint256 _walletLimit = player.walletLimit;

        require(_realTokenAmount < _walletLimit,"Please Buy Areena Boster To get All of your reward.");
        require(_realTokenAmount <= (3 * 1e18),"You can sell only three areena Token per day.");

        require(owner != address(0), "ERC20: approve from the zero address");
        require(msg.sender != address(0), "ERC20: approve to the zero address");

        require(block.timestamp > areenaLastTransactionForGen[msg.sender],"You canot sell areena token again before 24 hours.");

        uint256 areenaPriceInBusd = calculateAreenaPriceForGen(_areenaAmount);
        uint256 _totalAmountOfGen = (areenaPriceInBusd.mul(1e18)).div(_genPrice);

        uint256 amountAdd = calculateSellTax(_totalAmountOfGen);


        amountAdd = _totalAmountOfGen - amountAdd;

        genToken.transferFrom(treasuryWallet, address(this), _totalAmountOfGen);
        players[msg.sender].genAmountPlusBonus += amountAdd;
       
        areenaInCirculation -= _realTokenAmount;
        players[msg.sender].totalArenaTokens -= _realTokenAmount;
        totalAreena += _realTokenAmount;

        areenaLastTransactionForGen[msg.sender] = block.timestamp + 4 minutes; //////////hours////////////////

        emit SellThroughAreena(areenaPriceInBusd,_totalAmountOfGen, amountAdd);
    }

    function calculateAreenaPrice() public view returns (uint256 _areenaValue) {
        
        uint256 _busdWalletBalance = BusdInTreasury();
        _areenaValue = _busdWalletBalance.div(10000);

        uint256 _initialPercentage = 7500; // 75 %
        return _areenaValue.mul(_initialPercentage).div(10000);
    }

    function calculateAreenaPriceForGen(uint256 _areenaAmount) public view returns (uint256){
        
        uint256 _busdWalletBalance = BusdInTreasury();
        uint256 _areenaValue = _busdWalletBalance.div(10000);

        return _areenaAmount.mul(_areenaValue);
    }
    
    function getAreenaPrice() public view returns (uint256) {
        
        return calculateAreenaPrice();
    }

    
//=====================================Clain ReferalBonus =========================================

    function claimReferalBonus(uint256 _battleId) public returns (bool v) {
        
        Battle memory battle = battles[_battleId];

        if (msg.sender == referalPerson[_battleId].creatorReferalPerson){

            uint256 referallTime = referalTime[_battleId][battle.creator][msg.sender];
            require(block.timestamp > referallTime.add(7 minutes),"You can not claim bonus before 7 minutes."); //////////Add 7 days here /////////

            uint256 referallAmount = claimRferalAmount[battle.creator][msg.sender][referallTime];

            require(players[msg.sender].genAmountPlusBonus >(referallAmount.mul(5)),"Your castle gen amount must be five times of your referal amount");

            players[msg.sender].referalAmount -= referallAmount;
            players[msg.sender].genAmountPlusBonus += referallAmount;

            return true;

        } else if (msg.sender == referalPerson[_battleId].joinerReferalPerson) {
            
            uint256 referallTime = referalTime[_battleId][battle.joiner][msg.sender];
            
            require(block.timestamp > referallTime.add(7 minutes),"You can not claim bonus before 7 minutes."); //////////Add 7 days here /////////

            uint256 referallAmount = claimRferalAmount[battle.joiner][msg.sender][referallTime];
            require(players[msg.sender].genAmountPlusBonus >(referallAmount.mul(5)),"Your castle gen amount must be five times of your referal amount");

            players[msg.sender].referalAmount -= referallAmount;
            players[msg.sender].genAmountPlusBonus += referallAmount;

            return true;

        } else {

            bool referallPerson;
            require(referallPerson,"You can not claim reward because you are not the referalPerson of this battle.");

            return false;
        }
    }

//=====================================Sell Gen Through The Dashboard ====================================


    function sellGenThroughDashboard(uint256 _busdAmount, uint256 priceOfGen) public {
        //get busd in wei

        uint256 _afterBusdAmount = _busdAmount.mul(1e18);

        require(busdToken.balanceOf(msg.sender) >= _busdAmount,"You do not have sufficent amount of busd to buy gen token.");

        uint256 totalGenAmount = (_afterBusdAmount.mul(1e18)).div(priceOfGen);
        uint256 amountAdd = calculateSellTax(totalGenAmount);

        amountAdd = totalGenAmount - amountAdd;

        require(genToken.balanceOf(treasuryWallet) >= totalGenAmount,"treasury wallet didnt have sufficient amount of gen token to sell right now.");

        if (saleEnabled && (block.timestamp > saleEndTime)) {
            saleEnabled = false;
        }


        if (saleEnabled && (block.timestamp < saleEndTime)) {
            
            uint256 bonusAmount = calculateGenBonusPercentage(totalGenAmount);


            busdToken.transferFrom(msg.sender, busdWallet, _busdAmount);
            genToken.transferFrom(treasuryWallet,address(this),totalGenAmount);

            players[msg.sender].genAmountPlusBonus += amountAdd.add(bonusAmount);

            emit SellThroughDashboard(true, amountAdd, bonusAmount, block.timestamp);
            
        } else {

            busdToken.transferFrom(msg.sender, busdWallet, _busdAmount);
            genToken.transferFrom(treasuryWallet,address(this),totalGenAmount);

            players[msg.sender].genAmountPlusBonus += amountAdd;

            emit SellThroughDashboard(false, amountAdd, 0, block.timestamp);
        }
    }

    function calculateSellTax(uint256 _amount) public pure returns (uint256) {
        uint256 _initialPercentage = 1600; // 16 %
        return _amount.mul(_initialPercentage).div(10000);
    }

    function enableTheBonus(bool _enable, uint256 _endingTime,  uint256 _percentage) public onlyOwner {
        
        saleEnabled = _enable;
        saleEndTime = _endingTime;
        saleStartTime = block.timestamp;
        genBonusPercentage = _percentage;
        
    }

    function calculateGenBonusPercentage(uint256 _amount) public view returns (uint256){
        
        uint256 _initialPercentage = genBonusPercentage.mul(100);
        return _amount.mul(_initialPercentage).div(10000);
    }

    function sendSellGenThroughDashboardInformation() public view returns(bool, uint256, uint256, uint256){
        return(saleEnabled, genBonusPercentage, saleStartTime, saleEndTime);

    }
    
//============================ PreSale Info ==========================

    function sendPreSaleTokens() external {

       uint256 length  = preSale.getTotalBuyers();
       uint256 totalSoldTokens = preSale.getTotalSoldTokens();

       for(uint i = 0; i<= length; i++){

            (address _playerAddress, uint256 _noOfTokens) = preSale.getTokenBuyersInfo(i);
           
            players[_playerAddress].genAmountPlusBonus += _noOfTokens.mul(1e18);
            genToken.transferFrom(preSaleWallet, address(this), totalSoldTokens.mul(1e18));
       }
    }

    function setPreSaleWallet(address _preSaleWallet) external {
        preSaleWallet = _preSaleWallet;
    }

    function getPreSaleWallet()external view returns(address){

        return preSaleWallet;
    }

    //=============== Player Extra Information ==============

    function playerStakeDetails(address _playerAddress, uint256 battleCount) public view returns (Stake memory){
        
        Player storage player = players[_playerAddress];
        return player.battleRecord[battleCount];
    }

    // get players battle Ids whoe he create only.
    function getAllBattleIds(address _playerAddress) external view returns (uint256[] memory){
        return playerBattleIds[_playerAddress];
    }

    function setGenRewardPercentage(uint256 _percentage, uint256 value) external onlyOwner{
        
        genRewardMultiplicationValue = value;
        genRewardPercentage = _percentage.mul(value);
    }

    function getGenRewardPercentage() external view returns (uint256) {
        
        uint256 genReward = genRewardPercentage.div(genRewardMultiplicationValue);
        return genReward;
    }

    //================ All Wallet ===============

    function setTreasuryWallet(address _walletAddress) external onlyOwner {
        treasuryWallet = _walletAddress;
    }

    function setAreenaWallet(address _walletAddress) external onlyOwner {
        areenaWallet = _walletAddress;
    }

    function setBusdWallet(address _walletAddress) external onlyOwner {
        busdWallet = _walletAddress;
    }

    function plateformeEarning() public view returns (uint256) {
        return genToken.balanceOf(treasuryWallet);
    }

    function AreenaInTreasury() public view returns (uint256) {
        uint256 realAreena = totalAreena - areenaInCirculation;
        return realAreena;
    }

    function GenInTreasury() external view returns (uint256) {
        return genToken.balanceOf(treasuryWallet);
    }

    function BusdInTreasury() public view returns (uint256) {
        return (busdToken.balanceOf(busdWallet) + (90000 * 1e18));
    }

    // ================ Contract Info ==========

    function addContractBalance(uint256 _amount) external onlyOwner {
        genToken.transferFrom(treasuryWallet, address(this), _amount);
    }

    function getContractBalance() public view onlyOwner returns (uint256) {
        return genToken.balanceOf(address(this));
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
}