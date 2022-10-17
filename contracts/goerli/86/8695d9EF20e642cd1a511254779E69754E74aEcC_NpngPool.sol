//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title No Pool No Game : Pool Contract
/// @author Perrin GRANDNE
/// @notice Contract for Deposit and Withdraw on the Pool
/// @custom:experimental This is an experimental contract.

import {NpngGame} from "./NpngGame.sol";

/// @notice Only the ERC-20 functions we need
interface IERC20 {
    /// @notice Get the balance of aUSDC in No Pool No Game
    /// @notice and balance of USDC from the Player
    function balanceOf(address acount) external view returns (uint);

    /// @notice Approve the deposit of USDC from No Pool No Game to Aave
    function approve(address spender, uint amount) external returns (bool);

    /// @notice Confirm the allowed amount before deposit
    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    /// @notice Withdraw USDC from No Pool No Game
    function transfer(address recipient, uint amount) external returns (bool);

    /// @notice Transfer USDC from User to No Pool No Game
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    /// @notice Mint NPNGaUSDC when user deposits on the pool
    function mint(address sender, uint amount) external;

    /// @notice Burn NPNGaUSDC when user withdraws from the pool
    function burn(address sender, uint amount) external;
}

/// @notice Only the PoolAave functions we need
interface PoolAave {
    /// @notice Deposit USDC to Aave Pool
    function supply(
        address asset,
        uint amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /// @notice Withdraw USDC from Aave Pool
    function withdraw(
        address asset,
        uint amount,
        address to
    ) external;
}

/// BEGINNING OF THE CONTRACT
contract NpngPool is NpngGame {
    struct EndContest {
        uint poolValue;
        uint prizePool;
        uint rewards;
    }

    /// @notice balance of Users in the Pool
    mapping(address => uint) private balanceOfUser;

    /// @notice Sum of all deposits during the current contest
    uint private currentContestDeposits;

    /// @notice Sum of all witdhraws during the current contest
    uint private currentContestWithdraws;

    /// @notice Record the last Contest of Deposit
    mapping(address => uint) private lastIdContestOfDeposit;

    /// @notice Pool Value and Rewards at the end of each contest
    mapping(uint => EndContest) private endContest;

    mapping(uint => uint) private remainedUnclaimedRewardsPerContest;

    /// @notice balance of total claimed rewards per player
    mapping(address => uint) private balanceOfClaimedRewards;

    IERC20 private usdcToken;
    IERC20 private aUsdcToken;
    IERC20 private npngToken;
    PoolAave private poolAave;

    constructor() {
        usdcToken = IERC20(0xA2025B15a1757311bfD68cb14eaeFCc237AF5b43);
        poolAave = PoolAave(0x368EedF3f56ad10b9bC57eed4Dac65B26Bb667f6);
        aUsdcToken = IERC20(0x1Ee669290939f8a8864497Af3BC83728715265FF);
        npngToken = IERC20(0x8ad6d963600F5c45DaBd5fF6faA04d51A6D549f0);

        endContest[0].poolValue = 0;
        endContest[0].prizePool = 0;
        endContest[0].rewards = 0;
    }

    /// WRITE FUNCTIONS

    /// @notice Update the NPNG Token address if a new contract is deployed
    function changeNpngTokenAddress(address _newAddress) public onlyOwner {
        npngToken = IERC20(_newAddress);
    }

    /// @notice Deposit USDC on Pool which will be deposited on Aave and get the same amount ofNPNGaUSCD
    function depositOnAave(uint _amount) public {
        require(
            _amount <= usdcToken.balanceOf(msg.sender),
            "Insufficent amount of USDC"
        );
        require(
            _amount <= usdcToken.allowance(msg.sender, address(this)),
            "Insufficient allowed USDC"
        );
        usdcToken.transferFrom(msg.sender, address(this), _amount);
        usdcToken.approve(address(poolAave), _amount);
        poolAave.supply(address(usdcToken), _amount, address(this), 0);
        balanceOfUser[msg.sender] += _amount;
        currentContestDeposits += _amount;
        npngToken.mint(msg.sender, _amount);
        lastIdContestOfDeposit[msg.sender] = NpngGame.currentIdContest;
    }

    /// @notice Withdraw from the Pool, it will be withdraw from Aave and NPNG Token will be burnt
    function withdraw(uint _amount) public {
        require(balanceOfUser[msg.sender] >= _amount, "Insufficient balance");
        require(
            lastIdContestOfDeposit[msg.sender] + 2 <= NpngGame.currentIdContest,
            "Please wait 2 contests after your deposit to witdraw"
        );
        poolAave.withdraw(address(usdcToken), _amount, address(this));
        usdcToken.transfer(msg.sender, _amount);
        balanceOfUser[msg.sender] -= _amount;
        currentContestWithdraws += _amount;
        npngToken.burn(msg.sender, _amount);
    }

    /// @notice update the Id of the contest based on the block.timestamp and the game frequence
    /// @notice save info about Pool states from the previous id Contest
    function updateContest() public {
        require(
            msg.sender == recorderAddress,
            "You are not allowed to update contest!"
        );
        require(
            block.timestamp >=
                NpngGame.lastContestTimestamp + NpngGame.gameFrequence,
            "No contest update!"
        );
        lastContestTimestamp = block.timestamp;
        uint contestPoolValue = endContest[currentIdContest - 1].poolValue +
            currentContestDeposits -
            currentContestWithdraws +
            endContest[currentIdContest - 1].rewards;
        uint aavePoolValue = aUsdcToken.balanceOf(address(this));
        uint contestPrizePool = aavePoolValue - contestPoolValue;
        uint rewardsPerContest = getRewardsPerContest(
            currentIdContest,
            contestPrizePool
        );
        endContest[currentIdContest].poolValue = contestPoolValue;
        endContest[currentIdContest].prizePool = contestPrizePool;
        endContest[currentIdContest].rewards = rewardsPerContest;

        remainedUnclaimedRewardsPerContest[
            currentIdContest
        ] = rewardsPerContest;
        currentContestDeposits = 0;
        currentContestWithdraws = 0;
        currentIdContest++;
    }

    /// @notice Record the contest played by the player to verify if he can and save his request
    function getPlay() public {
        require(balanceOfUser[msg.sender] > 0, "No deposit, No Game!");
        NpngGame.requestPlaying();
    }

    /// @notice Save the score after the play
    function saveScore(address _player, uint _score) public {
        require(
            msg.sender == recorderAddress,
            "You are not allowed to save a score!"
        );
        require(
            contestPlayerStatus[_player][currentIdContest].requested == true,
            "No request from player"
        );
        require(
            contestPlayerStatus[_player][currentIdContest].played == false,
            "Player already played"
        );
        NpngGame.contestsResult[currentIdContest].push(
            ContestsResult(_player, _score, balanceOfUser[_player])
        );
        contestPlayerStatus[_player][currentIdContest].played = true;
        numberOfPlayersPerContest[currentIdContest]++;
    }

    function claim() public {
        uint onClaiming = 0;
        uint reward;
        for (uint i = currentIdContest - 1; i > 0; i--) {
            if (contestPlayerStatus[msg.sender][i].claimed == true) {
                break;
            } else {
                reward = getRewardPerPlayerPerContest(msg.sender, i);
                onClaiming += reward;
                remainedUnclaimedRewardsPerContest[i] -= reward;
                contestPlayerStatus[msg.sender][i].claimed = true;
            }
        }
        if (onClaiming > 0) {
            balanceOfUser[msg.sender] += onClaiming;
            balanceOfClaimedRewards[msg.sender] += onClaiming;
            npngToken.mint(msg.sender, onClaiming);
        }
    }

    /// READ FUNCTIONS
    function getUserBalance(address _account) public view returns (uint) {
        return (balanceOfUser[_account]);
    }

    ///@notice Get all the rewards claimed from a player
    function getTotalClaimedRewards(address _account)
        public
        view
        returns (uint)
    {
        return (balanceOfClaimedRewards[_account]);
    }

    function getWinnersInfo(uint _idContest)
        public
        view
        returns (ContestsResult[11] memory)
    {
        uint playerScore;
        uint winnersDeposit = 0;
        ContestsResult[11] memory winnersRank;

        for (uint i = 0; i < contestsResult[_idContest].length; i++) {
            playerScore = contestsResult[_idContest][i].score;
            uint rank = 1;
            for (uint j = 0; j < contestsResult[_idContest].length; j++) {
                if (playerScore < contestsResult[_idContest][j].score) {
                    rank++;
                }
            }
            if (rank < 11) {
                winnersDeposit += contestsResult[_idContest][i].balancePlayer;
                winnersRank[rank].player = contestsResult[_idContest][i].player;
                winnersRank[rank].score = contestsResult[_idContest][i].score;
                winnersRank[rank].balancePlayer = contestsResult[_idContest][i]
                    .balancePlayer;
            }
        }
        winnersRank[0].balancePlayer = winnersDeposit;
        return (winnersRank);
    }

    function getRewardsPerContest(uint _idContest, uint _globalPrizePool)
        public
        view
        returns (uint)
    {
        ContestsResult[11] memory winnersRank = getWinnersInfo(_idContest);
        uint winnersDeposit = winnersRank[0].balancePlayer;
        uint totalRewards;
        for (uint i = 1; i < 11; i++) {
            totalRewards +=
                (((_globalPrizePool * winnersRank[i].balancePlayer * 10**6) /
                    winnersDeposit) * (101 - i)**5) /
                10**16;
        }
        return (totalRewards);
    }

    function getRewardPerPlayerPerContest(address _player, uint _idContest)
        public
        view
        returns (uint)
    {
        ContestsResult[11] memory winnersRank = getWinnersInfo(_idContest);
        uint winnersDeposit = winnersRank[0].balancePlayer;
        uint reward = 0;
        for (uint i = 1; i < 11; i++) {
            if (_player == winnersRank[i].player) {
                reward =
                    (((endContest[_idContest].prizePool *
                        winnersRank[i].balancePlayer *
                        10**6) / winnersDeposit) * (101 - i)**5) /
                    10**16;
                break;
            }
        }
        return (reward);
    }

    /// @notice table of last 10 contests for a player, used for ranking history in the Page Account
    function getAccountTable(address _player)
        public
        view
        returns (AccountTable[10] memory)
    {
        AccountTable[10] memory accountTable;
        uint indexDecrement;
        uint j = 0;
        uint lastClosedIdContest = currentIdContest - 1;
        uint contestRank;
        if (lastClosedIdContest < 10) {
            indexDecrement = lastClosedIdContest;
        } else {
            indexDecrement = 10;
        }
        for (
            uint i = lastClosedIdContest;
            i > lastClosedIdContest - indexDecrement;
            i--
        ) {
            contestRank = getContestRank(i, _player);
            if (contestRank > 0 && contestRank < 11) {
                accountTable[j] = AccountTable({
                    idContest: i,
                    rank: contestRank,
                    participant: numberOfPlayersPerContest[i],
                    prize: getRewardPerPlayerPerContest(_player, i)
                });
            } else {
                accountTable[j] = AccountTable({
                    idContest: i,
                    rank: contestRank,
                    participant: numberOfPlayersPerContest[i],
                    prize: 0
                });
            }
            j++;
        }
        return (accountTable);
    }

    /// @notice table of top 10 players for a contest, used for modal contest in the Page Account
    function getContestTable(uint _idContest)
        public
        view
        returns (ContestTable[10] memory)
    {
        ContestTable[10] memory contestTable;
        ContestsResult[11] memory winnersRank = getWinnersInfo(_idContest);
        uint winnersDeposit = winnersRank[0].balancePlayer;
        for (uint i = 0; i < 10; i++) {
            uint j = i + 1;
            contestTable[i].rank = j;
            contestTable[i].score = winnersRank[j].score;
            contestTable[i].player = winnersRank[j].player;
            contestTable[i].prize =
                (((endContest[_idContest].prizePool *
                    winnersRank[j].balancePlayer *
                    10**6) / winnersDeposit) * (101 - i)**5) /
                10**16;
        }
        return (contestTable);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title No Pool No Game : Game Contract
/// @author Perrin GRANDNE
/// @notice Contract for Playing Memory Game
/// @custom:experimental This is an experimental contract.

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NpngGame is Pausable, Ownable {
    /// @notice struct for saving results of Player on each contest
    /// @notice we record the balance of the Player for the Contest to avoid big deposit after winning
    struct ContestsResult {
        address player;
        uint score;
        uint balancePlayer;
    }

    /// @notice struct for recording status of the player
    /// @notice Did he request to play, did he play, did he claimed ?
    struct RequestPlaying {
        bool requested;
        bool played;
        bool claimed;
    }

    struct ContestTable {
        uint rank;
        uint score;
        address player;
        uint prize;
    }

    struct AccountTable {
        uint idContest;
        uint rank;
        uint participant;
        uint prize;
    }

    /// @notice Array of scores per player and per contest
    mapping(uint => ContestsResult[]) internal contestsResult;

    mapping(uint => uint) internal numberOfPlayersPerContest;

    /// @notice mapping for status of the player for each contest
    mapping(address => mapping(uint => RequestPlaying))
        internal contestPlayerStatus;

    /// @notice Frequence of contests
    uint internal gameFrequence;

    uint internal currentIdContest;
    uint internal lastContestTimestamp;

    /// @notice Address with rights for recording score (backend)
    address internal recorderAddress;

    constructor() {
        /// @notice initiate the start date for the first contest and the id of the contest
        lastContestTimestamp = block.timestamp;
        currentIdContest = 1;
        //1 week = 604800s ; 1 day = 86400s ; 5 minutes = 300s
        gameFrequence = 86400;
        recorderAddress = 0x000000000000000000000000000000000000dEaD;
    }

    /// WRITE FUNCTIONS

    ///Pausable functions
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Record a request of a player for playing (when you click on Play)
    function requestPlaying() internal {
        require(
            contestPlayerStatus[msg.sender][currentIdContest].requested ==
                false,
            "You already requested"
        );
        require(
            contestPlayerStatus[msg.sender][currentIdContest].played == false,
            "Player already played"
        );
        contestPlayerStatus[msg.sender][currentIdContest].requested = true;
    }

    function changeGameFrequence(uint _newFrequence) public onlyOwner {
        gameFrequence = _newFrequence;
    }

    function changeRecorder(address _newRecorderAddress) public onlyOwner {
        recorderAddress = _newRecorderAddress;
    }

    /// READ FUNCTIONS
    function getIdContest() public view returns (uint) {
        return (currentIdContest);
    }

    /// @notice Get the end of the current contest in Timestamp
    function getEndOfContest() public view returns (uint) {
        uint endOfContest = lastContestTimestamp + gameFrequence;
        return (endOfContest);
    }

    /// @notice Get the rank of a player for a specific contest
    function getContestRank(uint _idContest, address _player)
        public
        view
        returns (uint)
    {
        uint playerIndex;
        uint playerScore;
        uint rank = 1;
        /// @notice Find the index of the player in the contest
        /// @notice if no index found, rank=0
        for (uint i = 0; i < contestsResult[_idContest].length; i++) {
            if (_player == contestsResult[_idContest][i].player) {
                playerIndex = i;
                playerScore = contestsResult[_idContest][i].score;
                break;
            }
            if (i + 1 == contestsResult[_idContest].length) {
                return (0);
            }
        }
        /// @notice rank the player from his score,
        /// @notice start with rank 1, increment if a better score is found
        for (uint i = 0; i < contestsResult[_idContest].length; i++) {
            if (playerScore > contestsResult[_idContest][i].score) {
                rank++;
            }
        }
        return (rank);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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