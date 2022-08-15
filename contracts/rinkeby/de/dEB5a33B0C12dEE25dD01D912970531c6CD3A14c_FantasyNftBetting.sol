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
    function lockUnlockSpendingBalance(address _user, uint256 _amount, uint256 _type) external;
    function transferWagerFromLoserToWinner(address _winner, address _loser, uint256 _betAmount) external;
}

interface IFantasyNftLeague {
    function checkIfInLeague(address user1, uint leagueID) external view returns (bool);
}

contract FantasyNftBetting {
    using SafeMath for uint256;

    address public owner;
    IFantasyNftFunding public fundingContract;
    IFantasyNftLeague public leagueContract;

    uint256 public pairingsCount;

    enum BetStatus {
        FIRSTPLAYERIN,
        ABANDONPREPAIRING,
        SECONDPLAYERIN,
        BETFINISHED
    }

    /// @notice Each betting match consists of an array of gamer structs
    mapping(uint256 => IndividualGamer[]) public pairingsGamers;

    /// @notice See BetStatus for various status
    mapping(uint256 => BetStatus) public pairingsStatus;

    /// @notice Each user can be involved in multiple matches
    mapping(address => uint256[]) public pairingsInvolved;

    /// @notice Betting Matches still awaiting a second player
    uint256[] public openPairings;

    struct IndividualGamer {
        address gamerAddress;
        uint256 usdStaked;
        uint256 leagueId;
        bool isConfirmed;
        bool didWin;
        uint256 creationTime;
    }

    struct FetchedResult {
        uint256 pairId;
        BetStatus status;
        IndividualGamer[] gamerPair;
    }

    event GameCreated(
        address indexed creator,
        uint256 betAmount,
        uint256 pairID,
        uint256 timestamp
    );
    event GameAbandonedPrePair(
        address indexed creator,
        uint256 betAmount,
        uint256 pairID,
        uint256 timestamp
    );
    event SecondPlayerJoined(
        address indexed creator,
        uint256 betAmount,
        uint256 pairID,
        uint256 timestamp
    );
    event PostGameUpdates(
        address indexed player1,
        address indexed player2,
        uint256 pairId,
        uint256 winner,
        uint256 timestamp
    );

    constructor(address _fundingContract,address _leagueContract) {
        owner = msg.sender;
        fundingContract= IFantasyNftFunding(_fundingContract);
        leagueContract= IFantasyNftLeague(_leagueContract);
    }

    /// @notice Creates an initial 2-person betting match
    /// @param _betAmount Amount to bet
    function createGame(uint256 _betAmount, uint256 _leagueID) public {

        require(fundingContract.getSpendingBalance(msg.sender) >= _betAmount,"Balance too low");
        require(leagueContract.checkIfInLeague(msg.sender, _leagueID) == true,"Not in this league");

        fundingContract.lockUnlockSpendingBalance(msg.sender, _betAmount, 1);

        IndividualGamer memory gamerStruc = IndividualGamer({
            gamerAddress: msg.sender,
            usdStaked: _betAmount,
            leagueId: _leagueID,
            isConfirmed: true,
            didWin: false,
            creationTime: block.timestamp
        });
        pairingsGamers[pairingsCount].push(gamerStruc);
        pairingsStatus[pairingsCount] = BetStatus.FIRSTPLAYERIN;
        pairingsInvolved[msg.sender].push(pairingsCount);
        openPairings.push(pairingsCount);
        pairingsCount++;

        emit GameCreated(
            msg.sender,
            _betAmount,
            pairingsCount - 1,
            block.timestamp
        );
    }

    /// @notice Abandon open bet when there is only 1 person in the bet
    /// @param pairId Betting match ID number
    function abandonMatchPrePairing(uint256 pairId) public {
        require(
            pairingsGamers[pairId].length == 1 &&
                pairingsStatus[pairId] == BetStatus.FIRSTPLAYERIN,
            "Can only abandon if no opponent has been found"
        );
        require(
            pairingsGamers[pairId][0].gamerAddress == msg.sender,
            "No permission to abandon"
        );

        uint256 betAmount = pairingsGamers[pairId][0].usdStaked;


        pairingsGamers[pairId].pop();
        pairingsStatus[pairId] = BetStatus.ABANDONPREPAIRING;
        removeFromIntArray(pairingsInvolved[msg.sender], pairId);
        removeFromIntArray(openPairings, pairId);


        fundingContract.lockUnlockSpendingBalance(msg.sender, betAmount, 0);

        emit GameAbandonedPrePair(
            msg.sender,
            betAmount,
            pairId,
            block.timestamp
        );
    }

    /// @notice Allows a 2nd user to join a betting pair that has already been created
    /// @param pairId Betting match ID number
    /// @param _betAmount Amount to bet
    function joinExistingGame(
        uint256 pairId,
        uint256 _betAmount
    ) public {
        //called by 2nd player
        require(pairingsGamers[pairId].length == 1 && pairingsStatus[pairId] == BetStatus.FIRSTPLAYERIN, "No Waiting Opponent");
        require(pairingsGamers[pairId][0].usdStaked == _betAmount, "Unequal Amount Wagered");
        require(fundingContract.getSpendingBalance(msg.sender) >= _betAmount,"Balance too low");
        require(leagueContract.checkIfInLeague(msg.sender, pairingsGamers[pairId][0].leagueId) == true, "Not Same League");

        fundingContract.lockUnlockSpendingBalance(msg.sender, _betAmount, 1 );

        IndividualGamer memory gamerStruc = IndividualGamer({
            gamerAddress: msg.sender,
            usdStaked: _betAmount,
            leagueId: pairingsGamers[pairId][0].leagueId,
            isConfirmed: true,
            didWin: false,
            creationTime: block.timestamp
        });
        pairingsGamers[pairId].push(gamerStruc);
        pairingsStatus[pairId] = BetStatus.SECONDPLAYERIN;
        pairingsInvolved[msg.sender].push(pairId);
        removeFromIntArray(openPairings, pairId);


        emit SecondPlayerJoined(
            msg.sender,
            _betAmount,
            pairId,
            block.timestamp
        );
    }

    /// @notice Called by admin to properly distribute bets, protocol fees, etc.
    /// @param pairId Bet ID number
    /// @param whoWon 0 for player1, 1 for player2, 99 for draw
    function settleBet(uint256 pairId, uint whoWon) public {
        require(pairingsStatus[pairId] == BetStatus.SECONDPLAYERIN, "Cannot settle bet");
        require (whoWon==0 || whoWon==1 || whoWon==99, "Invalid Winner");
        require(msg.sender == owner, "No permission");


        pairingsStatus[pairId] = BetStatus.BETFINISHED;

        address player1Address = pairingsGamers[pairId][0].gamerAddress;
        address player2Address = pairingsGamers[pairId][1].gamerAddress;
        uint256 player1UsdStaked = pairingsGamers[pairId][0].usdStaked;
        uint256 player2UsdStaked = pairingsGamers[pairId][1].usdStaked;

        if (whoWon==99) {
            //If Draw, full refund
            fundingContract.lockUnlockSpendingBalance(
                player1Address,
                player1UsdStaked,
                0
            );
            fundingContract.lockUnlockSpendingBalance(
                player2Address,
                player2UsdStaked,
                0
            );
        } 
        else {
            address winner;
            if (whoWon == 0) {
                winner = player1Address;
                fundingContract.transferWagerFromLoserToWinner(player1Address, player2Address,player2UsdStaked);
            } else {
                winner = player2Address;
                fundingContract.transferWagerFromLoserToWinner(player2Address, player1Address,player1UsdStaked);
            }
            
            fundingContract.lockUnlockSpendingBalance(
                winner,
                player1UsdStaked + player2UsdStaked,
                2
            );
        }
        
        emit PostGameUpdates(
            player1Address,
            player2Address,
            pairId,
            whoWon,
            block.timestamp
        );
    }


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////Utility Functions

    /// @notice Fetches betting history of a user
    /// @param userAddress gamer's address to fetch data for
    /// @return fetchedHistory array of betting data
    function fetchBetsOfUser(address userAddress)
        public
        view
        returns (FetchedResult[] memory)
    {
        uint256[] memory participatedMatches = pairingsInvolved[userAddress];

        FetchedResult[] memory fetchedHistory = new FetchedResult[](
            participatedMatches.length
        );

        for (uint256 i = 0; i < participatedMatches.length; i++) {
            FetchedResult memory thisResult = FetchedResult({
                pairId: participatedMatches[i],
                status: pairingsStatus[participatedMatches[i]],
                gamerPair: pairingsGamers[participatedMatches[i]]
            });
            fetchedHistory[i] = thisResult;
        }

        return fetchedHistory;
    }

    /// @notice Fetches betting matches that are waiting for users to join
    /// @return fetchedOpenMatches array of open matches
    function fetchOpenMatches()
        public
        view
        returns (FetchedResult[] memory)
    {
        FetchedResult[] memory fetchedOpenMatches = new FetchedResult[](
            openPairings.length
        );

        for (uint256 i = 0; i < openPairings.length; i++) {
            FetchedResult memory thisResult = FetchedResult({
                pairId: openPairings[i],
                status: pairingsStatus[openPairings[i]],
                gamerPair: pairingsGamers[openPairings[i]]
            });
            fetchedOpenMatches[i] = thisResult;
        }
        return fetchedOpenMatches;
    }

    /// @notice Fetches info of a specific betting match
    /// @param pairId Bet ID number
    /// @return thisResult individual betting match data
    function fetchIndividualBet(uint256 pairId)
        public
        view
        returns (FetchedResult memory)
    {
        FetchedResult memory thisResult = FetchedResult({
            pairId: pairId,
            status: pairingsStatus[pairId],
            gamerPair: pairingsGamers[pairId]
        });
        return thisResult;
    }

    /// @notice Utility function used to remove an integer corresponding to a bet ID number from an integer array
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