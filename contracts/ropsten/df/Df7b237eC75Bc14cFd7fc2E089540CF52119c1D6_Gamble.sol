// SPDX-License-Identifier: GPL-3.0

// pragma solidity >=0.8.0;
pragma solidity ^0.8.0;


//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/52eeebecda140ebaf4ec8752ed119d8288287fac/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";



// TODO:
// Add auto settlement and deposit for auto settlement
// The deployer can call auto settlement at deployer's cost and deployer 
// can get the deposit for the bet. If the bets are called to settle by 
// the better, better will get the deposit back
contract Gamble {

    using SafeMath for uint256;
    using SafeMath for uint40;
    using SafeMath for uint;

    // Number of outcomes in roulette
    uint immutable ROULETTE_MODULO;

    // Bet for each game
    uint constant BET_AMOUNT = 0 ether;

    // House fee (not used at the moment)
    uint constant HOUSE_FEE = 500;

    // House owner
    address immutable public owner;

    event BetPlaced(address indexed better, uint amount);
    event BetSettlerd(address indexed betted, uint amount);
    event Cashout(uint256 amount);

    event Settled(uint winCount, uint loseCount, uint256 winAmount);

    // Only Owner Modifier for owner's operations
    modifier OnlyOwner {
        require(msg.sender == owner, "Only owner can do this operation.\n");
        _;
    }

    // a structure for committed bets
    struct Bet {
        // amount of ether for the bet
        uint amount;
        // Modulo for the game
        uint modulo;
        // Betted value
        uint bettedValue;
        // Block number of when the bet is placed
        uint40 blockNumber;
    }

    // a structure for settled bets
    struct SettledBet {
        // amount of ether for the bet
        uint amount;
        // Betted value
        uint bettedValue;
        // Bet outcome, win - true, lose - false
        bool win;
        // amount of ether winned for the bet
        uint winAmount;
        // Block number of when the bet is placed
        uint40 blockNumber;
    }

    // Mapping for all betters' committed bets
    mapping (address => Bet[]) CommittedBets;
    // Mapping for all betters' settled bets
    // TODO: Need to clear the array after the bets settled for more than certain amount of time
    mapping (address => SettledBet[]) SettledBets;

    // Constructor for the Gamble smart contract
    // Set the contract deployer as owner
    // TODO: add owner transfer function
    constructor (uint modulo) payable {
        owner = msg.sender;
        ROULETTE_MODULO = modulo;
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /*
        Betting Logic:
        Using blockhash as a random number generator. Whenever a bet is placed,
        the block number will be stored in the Bet object. The better can call 
        settle to settle the bet(s). The settle function will find the blockhash 
        for the block with the block number specified in the Bet object. The outcome
        of a bet can only be revealed after the bet transcation is done. Depending
        on the modulo the better's chosen, the outcome of the bet is determined by
        the remainder of blockhash divided by the bet modulo. If the better has 
        betted on the exact value as the outcome for that block, the better wins 
        the bet and gets the amount of ether betted for the bet and winning rewards. 
    */

    // Place a single bet
    // value    -   Outcome that better wants to bet on 
    // It will create an Bet object to store all required information. The object will 
    // be stored in the mapping given the better's address. 
    function placeBet(uint value) external payable {
        // check if the ether sent by gambler is correct
        // require(msg.value == BET_AMOUNT, "Unequal amount of bet payment!\n");

        // create the Bet object
        Bet memory bet = Bet(
            // amount of ether the better made for the transcation
            msg.value,
            // modulo for the bet
            ROULETTE_MODULO,
            // betted value
            value,
            // block number
            uint40(block.number)
        );
        // Push the Bet object to the Bet array associated with better's address in mapping
        CommittedBets[msg.sender].push(bet);

        emit BetPlaced(msg.sender, value);

    }

    // Settle a bet/bets in one transcation
    // It will first check how many bets are ready to be settled. 
    // Bets that are ready to be settled have a block number that is smaller than the current 
    // block number so the contract can check the outcome for the bet in previous blocks. 
    // Then, it will settle all the bets that are ready to be settled by comparing the betted
    // value and the outcome. winCount, lostCount, totalWinAmount
    function settleBet() external payable returns (uint winCount, uint lostCount, uint256 totalWinAmount) {
        // total number of bets that are placed by the better
        uint numberOfBets = CommittedBets[msg.sender].length;
        // check if there are any bets placed and not settled, if there is no such bet, 
        // there is no need to settle.
        require(numberOfBets > 0, "No bets made!\n");
        // number of bets that are ready to be settled
        uint numberOfBetsReady = 0;

        // blockhash for a block
        uint256 blockValue;
        // total amount of ether won by the better
        uint256 totalWinAmount = 0;
        // total number of bets won
        uint winCount = 0;

        // Count the number of bets that are ready to be settled
        // if there exists a blockhash for that block 
        for (uint k = 0; k < CommittedBets[msg.sender].length; k++) {
            // Get the blockhash for the block 
            blockValue = uint256(blockhash(CommittedBets[msg.sender][k].blockNumber));
            // Check if the block has a blockhash
            // If a block does not have a blockhash, the blocks after this block also 
            // does not have a blockhash, so no need to continue to count
            // TODO: fix blocks that are too old to have a blockhash (>255 blocks old)
            if (blockValue == 0) {
                break;
            }
            require(blockValue != 0, "BlockValue is empty!\n");
            // Add one to number of bets that are ready to settle
            numberOfBetsReady += 1;
            
            // Amount of ether won in this round
            uint256 winAmount = 0;
            // win/lose status 
            bool win = false;

            // If the remainder of blockhash divided by modulo is the same as better's 
            // betted value, better wins the round. 
            if (CommittedBets[msg.sender][k].bettedValue == blockValue.mod(ROULETTE_MODULO)) {
                win = true;
                // Better wins module * betted ether amount 
                winAmount = CommittedBets[msg.sender][k].amount.mul(ROULETTE_MODULO);
                // Add the rewards for the current round to the overall rewards for this
                // settlement
                totalWinAmount = totalWinAmount.add(winAmount);
                winCount += 1;
            }
            // Create a SettledBet object to record the round for front-end processing
            SettledBet memory settledBet = SettledBet(
                CommittedBets[msg.sender][k].amount,
                CommittedBets[msg.sender][k].bettedValue,
                win,
                winAmount,
                CommittedBets[msg.sender][k].blockNumber
            );
            // Add the object to the mapping for SettledBets associated with better's address
            addToSettledBets(settledBet);
        }
        // Transfer the total winning amount of the ether to the better
        payable(msg.sender).transfer(totalWinAmount);
        // Lose count 
        uint lostCount = numberOfBetsReady - winCount;
        emit Settled(winCount, lostCount, totalWinAmount);

        // Below is to pop all the settled bets out of the Bet array
        uint i = 0;
        uint j = numberOfBetsReady;
        // Swap the position of unsettled bets to the start of the array
        for (j; j < CommittedBets[msg.sender].length; j++){
            CommittedBets[msg.sender][i] = CommittedBets[msg.sender][j];
            i += 1;
        }
        // Pop the rest Bets out of the array to free memory
        while (i < numberOfBets) {
            CommittedBets[msg.sender].pop();
            i += 1;
        }
        return (winCount, lostCount, totalWinAmount);
    }

    // Push the SettledBet object to the mapping for settled bets
    function addToSettledBets(SettledBet memory bet) internal {
        SettledBets[msg.sender].push(bet);
    }

    // Actual batch bet function, can be used to place multiple bets in one transcation
    function batchBet(uint[] calldata values) external payable {
        require(values.length > 0, "No input values!\n");
        for (uint i = 0; i < values.length; i++) {
            Bet memory bet = Bet(
                // amount of ether the better made for the transcation
                uint256(msg.value).div(values.length),
                // modulo for the bet
                ROULETTE_MODULO,
                // betted value
                values[i],
                // block number
                uint40(block.number)
            );
            CommittedBets[msg.sender].push(bet);
        // Push the Bet object to the Bet array associated with better's address in mapping
        }
        // emit BetPlaced(msg.sender, value);
    }

    // Batch bet, can be used to place bets for future bets
    // vales    -   array of betted values
    // times    -   array of index of round to place bets, all values have to be non-negative
    //              0 means place bets on current round, other values (let's say x) mean that 
    //              place bets in next xth round. 
    // Notes: when user places bets the future blocks, user should wait for a couple of future 
    //        blocks are mined to save number of transaction needed to settle.
    //      !!Need to use string for stakes in Remix    
    function batchBetForFuture(uint[] calldata values, 
        uint256[] calldata stakes, 
        uint[] calldata rounds) external payable {
            require(values.length > 0, "No input values!\n");
            require(values.length == stakes.length, "The lengths of values and stakes are not equal!\n");
            require(values.length == rounds.length, "The lengths of values and rounds are not equal!\n");
            require(_sumOfStakes(stakes) == msg.value, "Amount ether received is different from stakes sum!\n");
            for (uint i = 0; i < values.length; i++) {
                require(rounds[i] >= 0, "No past block can be used for new bets");
                Bet memory bet = Bet(
                    // amount of ether the better made for the transcation
                    stakes[i],
                    // modulo for the bet
                    ROULETTE_MODULO,
                    // betted value
                    values[i],
                    // block number
                    uint40(block.number + rounds[i])
                );
                // Push the Bet object to the Bet array associated with better's address in mapping
                CommittedBets[msg.sender].push(bet); 
        }
        // emit BetPlaced(msg.sender, value);
    }

    // Cashout function for the owner to transfer all the ether out
    // of the smart contract
    function cashOut() OnlyOwner external payable {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit Cashout(balance);
    }

    // Get balance of the smart contract 
    function getPool() external view returns (uint256) {
        return address(this).balance;
    }

    // Get total number of committed bets of the better
    function getCommittedBetsNumber() external view returns (uint) {
        return CommittedBets[msg.sender].length;
    }

    // Get the value that better bets on in round 
    function getBettedValue(uint round) external view returns (uint) {
        require(round > 0 && round <= CommittedBets[msg.sender].length, "No such bet exists!\n");
        return CommittedBets[msg.sender][round-1].bettedValue;
    }

    // Get total number of settled bets of the better
    function getSettledBetNumber() external view returns (uint) {
        return SettledBets[msg.sender].length;
    }

    // Get the result of settled bets in round
    function getSettledBetResult(uint round) external view returns (bool win) {
        require(SettledBets[msg.sender].length >= round, 
            "No such bet settled, the round number is greater than total settled rounds\n");
        return SettledBets[msg.sender][round-1].win;
    }

    // Get the sum of the stakes
    function _sumOfStakes(uint256[] calldata stakes) public view returns (uint256) {
        require(stakes.length > 0, "No input stakes!\n");
        uint256 sum = 0;
        for (uint i = 0; i < stakes.length; i++) {
            sum = sum.add(stakes[i]);
        }
        return sum;
    }

    // Get the sumOfWinAmount, winCount and loseCount after settlement
    function summary() external view returns (uint256 sumOfWinAmount, uint winCount, uint loseCount) {
        require(SettledBets[msg.sender].length > 0, "There are no settled bets");
        sumOfWinAmount = 0;
        winCount = 0;
        for (uint i = 0; i < SettledBets[msg.sender].length; i++) {
            sumOfWinAmount += SettledBets[msg.sender][i].winAmount;
            if (SettledBets[msg.sender][i].win) {
                winCount += 1;
            }
        }
        return (sumOfWinAmount, winCount, SettledBets[msg.sender].length - winCount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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