pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: Unlicensed

library SafeMath {
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IFantasyNftFunding {
    function getSpendingBalance(address _user) external view returns (uint256);
    function lockUnlockSpendingBalanceLeague(address[5] memory _userAddresses, uint256 _amount, uint256 _type, uint256 _payoutType) external;
    function transferWagerFromLoserToWinner(address _winner, address _loser, uint256 _betAmount) external;
    function transferToEscrowPriorToDistribution(address _user, uint256 _betAmount ) external;
}

contract FantasyNftLeague {
    using SafeMath for uint256;

    address public owner;
    IFantasyNftFunding public fundingContract;

    uint256 public leaguesCount;

    enum BetStatus {
        FIRSTPLAYERIN,
        ABANDONPREPAIRING,
        ADDITIONALUSERSIN,
        BETFINISHED
    }

    /// @notice Each league consists of an array of gamer structs
    mapping(uint256 => IndividualGamer[]) public leagueGamers;

    /// @notice See BetStatus for various status
    mapping(uint256 => BetStatus) public leaguesStatus;

    /// @notice Each user can be involved in multiple leagues
    mapping(address => uint256[]) public leaguesInvolved;

    /// @notice Leagues still awaiting new players
    uint256[] public openLeagues;

    struct IndividualGamer {
        address gamerAddress;
        uint256 usdStaked;
        uint256 payoutType;
        bool didWin;
        uint256 creationTime;
    }

    struct FetchedResult {
        uint256 pairId;
        BetStatus status;
        IndividualGamer[] leagueParticipants;
    }

    event LeagueCreated(
        address indexed creator,
        uint256 betAmount,
        uint256 payoutType,
        uint256 pairId,
        uint256 timestamp
    );
    event LeagueAbandoned(
        address indexed creator,
        uint256 betAmount,
        uint256 pairId,
        uint256 timestamp
    );
    event AdditionalPlayerJoined(
        address indexed creator,
        uint256 betAmount,
        uint256 pairId,
        uint256 timestamp
    );
    event PostGameUpdates(
        uint256 pairId,
        uint256 timestamp
    );

    constructor(address _fundingContract) {
        owner = msg.sender;
        fundingContract= IFantasyNftFunding(_fundingContract);
    }

    /// @notice Creates a league
    /// @param _betAmount Amount to bet
    /// @param _payoutType 0: Winner take all; 1: Top 3; 2: Top 5
    function createLeague(uint256 _betAmount, uint256 _payoutType) public {

        require(fundingContract.getSpendingBalance(msg.sender) >= _betAmount,"Balance too low");
        require(_payoutType==0 || _payoutType==1 || _payoutType==2, "Invalid Payout Type");
        fundingContract.lockUnlockSpendingBalanceLeague([address(msg.sender), address(0), address(0), address(0), address(0)], _betAmount, 1, 99);


        IndividualGamer memory gamerStruc = IndividualGamer({
            gamerAddress: msg.sender,
            usdStaked: _betAmount,
            payoutType: _payoutType,
            didWin: false,
            creationTime: block.timestamp
        });

        leagueGamers[leaguesCount].push(gamerStruc);
        leaguesStatus[leaguesCount] = BetStatus.FIRSTPLAYERIN;
        leaguesInvolved[msg.sender].push(leaguesCount);
        openLeagues.push(leaguesCount);
        leaguesCount++;

        emit LeagueCreated(
            msg.sender,
            _betAmount,
            _payoutType,
            leaguesCount - 1,
            block.timestamp
        );
    }

    /// @notice Abandon league when there is only 1 person in the league
    /// @param pairId League ID number
    function abandonLeague(uint256 pairId) public {
        require(
            leagueGamers[pairId].length == 1 &&
                leaguesStatus[pairId] == BetStatus.FIRSTPLAYERIN,
            "Can only abandon if no other users have joined"
        );
        require(
            leagueGamers[pairId][0].gamerAddress == msg.sender,
            "No permission to abandon"
        );

        uint256 betAmount = leagueGamers[pairId][0].usdStaked;


        leagueGamers[pairId].pop();
        leaguesStatus[pairId] = BetStatus.ABANDONPREPAIRING;
        removeFromIntArray(leaguesInvolved[msg.sender], pairId);
        removeFromIntArray(openLeagues, pairId);


        fundingContract.lockUnlockSpendingBalanceLeague([address(msg.sender), address(0), address(0), address(0), address(0)], betAmount, 0, 99);

        emit LeagueAbandoned(
            msg.sender,
            betAmount,
            pairId,
            block.timestamp
        );
    }


    /// @notice Allows users to join an existing league
    /// @param pairId League ID number
    /// @param _betAmount Amount to bet
    function joinExistingLeague(
        uint256 pairId,
        uint256 _betAmount
    ) public {

        require(leagueGamers[pairId].length >= 1 && (leaguesStatus[pairId] == BetStatus.FIRSTPLAYERIN || leaguesStatus[pairId] == BetStatus.ADDITIONALUSERSIN), "League Not Open");
        require(leagueGamers[pairId][0].usdStaked == _betAmount, "Unequal Amount Wagered");
        require(fundingContract.getSpendingBalance(msg.sender) >= _betAmount,"Balance too low");
        require(checkIfInLeague(msg.sender,pairId)==false, "Already in this league");

        fundingContract.lockUnlockSpendingBalanceLeague([address(msg.sender), address(0), address(0), address(0), address(0)], _betAmount, 1, 99);

        IndividualGamer memory gamerStruc = IndividualGamer({
            gamerAddress: msg.sender,
            usdStaked: _betAmount,
            payoutType: leagueGamers[pairId][0].payoutType,
            didWin: false,
            creationTime: block.timestamp
        });
        leagueGamers[pairId].push(gamerStruc);
        leaguesStatus[pairId] = BetStatus.ADDITIONALUSERSIN;
        leaguesInvolved[msg.sender].push(pairId);


        emit AdditionalPlayerJoined(
            msg.sender,
            _betAmount,
            pairId,
            block.timestamp
        );
    }


    /// @notice Called by admin to properly distribute payouts, protocol fees, etc.
    /// @param pairId League ID number
    /// @param winnerAddresses Always submit an array with the Top 5 winners IN ORDER, even if the payout type is not "Top 5"; If there are not enough players in the league, use address(0) for blank addresses
    function resolveLeague(uint256 pairId, address[5] memory winnerAddresses) public {
        require(leaguesStatus[pairId] == BetStatus.FIRSTPLAYERIN || leaguesStatus[pairId] == BetStatus.ADDITIONALUSERSIN, "Cannot settle league");
        require(msg.sender == owner, "No permission");


        leaguesStatus[pairId] = BetStatus.BETFINISHED;
        uint totalStaked;
        
        for(uint i = 0; i < leagueGamers[pairId].length; i++){
            uint thisUserStaked=leagueGamers[pairId][i].usdStaked;
            address thisUserAddress=leagueGamers[pairId][i].gamerAddress;
            totalStaked=totalStaked+thisUserStaked;
            fundingContract.transferToEscrowPriorToDistribution(thisUserAddress, thisUserStaked);
        }

        
        fundingContract.lockUnlockSpendingBalanceLeague(
            winnerAddresses,
            totalStaked,
            2,
            leagueGamers[pairId][0].payoutType
        );
        
        removeFromIntArray(openLeagues, pairId);

        emit PostGameUpdates(
            pairId,
            block.timestamp
        );
    }


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////Utility Functions

    /// @notice Fetches league history of a user
    /// @param userAddress gamer's address to fetch data for
    /// @return fetchedHistory array of league data
    function fetchLeaguesOfUser(address userAddress)
        public
        view
        returns (FetchedResult[] memory)
    {
        uint256[] memory participatedGames = leaguesInvolved[userAddress];

        FetchedResult[] memory fetchedHistory = new FetchedResult[](
            participatedGames.length
        );

        for (uint256 i = 0; i < participatedGames.length; i++) {
            FetchedResult memory thisResult = FetchedResult({
                pairId: participatedGames[i],
                status: leaguesStatus[participatedGames[i]],
                leagueParticipants: leagueGamers[participatedGames[i]]
            });
            fetchedHistory[i] = thisResult;
        }

        return fetchedHistory;
    }

    /// @notice Fetches leagues that are waiting for users to join
    /// @return fetchedOpenLeagues array of open leagues
    function fetchOpenLeagues()
        public
        view
        returns (FetchedResult[] memory)
    {
        FetchedResult[] memory fetchedOpenLeagues = new FetchedResult[](
            openLeagues.length
        );

        for (uint256 i = 0; i < openLeagues.length; i++) {
            FetchedResult memory thisResult = FetchedResult({
                pairId: openLeagues[i],
                status: leaguesStatus[openLeagues[i]],
                leagueParticipants: leagueGamers[openLeagues[i]]
            });
            fetchedOpenLeagues[i] = thisResult;
        }
        return fetchedOpenLeagues;
    }

    /// @notice Fetches info of a specific League
    /// @param pairId League ID number
    /// @return thisResult individual League Data
    function fetchIndividualLeague(uint256 pairId)
        public
        view
        returns (FetchedResult memory)
    {
        FetchedResult memory thisResult = FetchedResult({
            pairId: pairId,
            status: leaguesStatus[pairId],
            leagueParticipants: leagueGamers[pairId]
        });
        return thisResult;
    }

    /// @notice Checks if the user belongs to a certain league
    /// @param user1 User to check
    /// @param leagueID ID of league to query
    function checkIfInLeague(address user1, uint leagueID) public view returns (bool){
        
        for(uint256 i = 0; i < leagueGamers[leagueID].length; i++){
            address thisUser = leagueGamers[leagueID][i].gamerAddress;

            if(thisUser==user1){
                return true;
            }
        }
        return false;

    }

    /// @notice Utility function used to remove an integer corresponding to a League ID number from an integer array
    /// @param arrayOfInterest the array
    /// @param pairId Bet ID number to remove from the array
    function removeFromIntArray(uint256[] storage arrayOfInterest, uint256 pairId) internal {
        for (uint256 i = 0; i < arrayOfInterest.length; i++) {
            if (arrayOfInterest[i] == pairId) {
                for (uint256 j = i; j < arrayOfInterest.length - 1; j++) {
                    ///uses more gas than unordered deletion
                    arrayOfInterest[j] = arrayOfInterest[j + 1];
                }
                arrayOfInterest.pop();
            }
        }
    }
}