/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/T1BetsV3.sol


pragma solidity ^0.8.0;



contract T1Bets is Ownable {
    event CreateGame(
        uint256 index,
        uint256 deadline,
        uint256 team1,
        uint256 team2,
        uint256 draw,
        uint256 minBet,
        uint256 maxBet
    );
    event UpdateGame(
        uint256 index,
        uint256 deadline,
        uint256 team1,
        uint256 team2,
        uint256 draw,
        uint256 minBet,
        uint256 maxBet
    );
    event SettleGame(uint256 index, uint8 outcome);

    event CreateBet(
        address indexed creator,
        uint256 betId,
        uint256 gameId,
        uint8 outcome,
        uint256 amount
    );
    event SettleBet(address indexed creator, uint256 betId, uint256 payout);

    event Stake(address indexed sender, uint256 amount);
    event Unstake(address indexed sender, uint256 amount);
    event Claim(address indexed sender, uint256 amount);

    error InvalidDeadline();
    error RespectMinMaxBetAmount();
    error GameDoesNotExist();
    error GameAlreadyStarted();
    error GameAlreadyFinished();
    error GameOutcomeHasToBeWithinBounds();
    error GameHasToBePending();
    error GameNotFinished();
    error BetAmountExceedsUtilization();
    error MustBeCreatorOfBet();
    error MustWinBet();
    error BetAlreadySettled();
    error StakedAmountBeingUtilized();
    error InsuffecientStakedBalance();
    error NoRewardsToClaim();

    struct UserInfo {
        uint256 staked;
        uint256 earned;
        uint256 rewardIndex;
    }

    struct Game {
        uint256 deadline;
        uint256[3] utilization; // [team1, team2, draw]
        uint256[3] odds; // [team1, team2, draw]
        uint256 minBet;
        uint256 maxBet;
        uint8 outcome;
    }

    struct Bet {
        address creator;
        uint256 gameId;
        uint256 amount;
        uint8 outcome;
    }

    uint256 public constant MULTIPLIER = 1e18;

    IERC20 public tDollar;
    uint256 public totalStaked;
    uint256 public totalRewards;
    uint256 public totalReserve;
    uint256 public totalUtilization;
    uint256 public rewardIndex;

    uint256 public gameCounter;
    uint256 public betCounter;

    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => Game) public games;
    mapping(uint256 => Bet) public bets;

    constructor (IERC20 _tDollar) {
        tDollar = _tDollar;
    }

    function createGame(
        uint256 _deadline,
        uint256[3] memory _odds,
        uint256 _minBet,
        uint256 _maxBet
    ) public onlyOwner {
        if (_deadline <= block.timestamp) revert InvalidDeadline();
        
        Game storage game = games[gameCounter];
        game.deadline = _deadline;
        game.odds = _odds;
        game.minBet = _minBet;
        game.maxBet = _maxBet;

        emit CreateGame(
            gameCounter,
            _deadline,
            _odds[0],
            _odds[1],
            _odds[2],
            _minBet,
            _maxBet
        );

        gameCounter++;
    }

    function updateGame(
        uint256 _index,
        uint256 _deadline,
        uint256[3] memory _odds,
        uint256 _minBet,
        uint256 _maxBet
    ) public onlyOwner {
        if (games[_index].outcome != 0) revert GameAlreadyFinished();

        games[_index].deadline = _deadline;
        games[_index].odds = _odds;
        games[_index].minBet = _minBet;
        games[_index].maxBet = _maxBet;

        emit UpdateGame(
            _index,
            _deadline,
            _odds[0],
            _odds[1],
            _odds[2],
            _minBet,
            _maxBet
        );
    }

    function settleGame(uint256 _gameId, uint8 _outcome) public onlyOwner {
        if (!(_outcome > 0 && _outcome < 4)) revert GameOutcomeHasToBeWithinBounds();

        Game storage game = games[_gameId];
        if (game.outcome != 0) revert GameHasToBePending();

        game.outcome = _outcome;

        totalReserve -= game.utilization[_outcome - 1];
        totalUtilization -= (game.utilization[0] + game.utilization[1] + game.utilization[2]);

        emit SettleGame(_gameId, _outcome);
    }

    function createBet(
        uint256 _gameId,
        uint8 _outcome,
        uint256 _amount
    ) public {
        if (!(_outcome > 0 && _outcome < 4)) revert GameOutcomeHasToBeWithinBounds();
        Game storage game = games[_gameId];

        if (!(game.minBet <= _amount && game.maxBet >= _amount)) revert RespectMinMaxBetAmount();
        if (game.deadline == 0) revert GameDoesNotExist();
        if (game.deadline <= block.timestamp) revert GameAlreadyStarted();
        if (game.outcome != 0) revert GameAlreadyFinished();

        uint256 payout = _amount * game.odds[_outcome - 1] / MULTIPLIER;

        if (!(totalUtilization + payout <= totalReserve)) revert BetAmountExceedsUtilization();
        require(tDollar.transferFrom(msg.sender, address(this), _amount));

        Bet storage bet = bets[betCounter];

        bet.creator = msg.sender;
        bet.gameId = _gameId;
        bet.amount = _amount;
        bet.outcome = _outcome;

        // Checks if the house is in deficit
        // replenishing the reserve takes priority
        uint256 deficit = totalStaked - totalReserve;
        if (deficit > 0) {
            if (deficit >= _amount) {
                totalReserve += _amount;
            } else {
                totalReserve += deficit;
                uint256 rewards = _amount - deficit;
                totalRewards += rewards;
                rewardIndex += (rewards * MULTIPLIER)  / totalStaked;
            }
        } else {
            totalRewards += _amount;
            rewardIndex += (_amount * MULTIPLIER) / totalStaked;
        }

        totalUtilization += payout;
        game.utilization[_outcome - 1] += payout;

        emit CreateBet(msg.sender, betCounter, _gameId, _outcome, _amount);

        betCounter++;
    }

    function settleBet(address winner, uint256 _betId) public {
        Bet storage bet = bets[_betId];

        if (bet.creator != winner) revert MustBeCreatorOfBet();
        if (games[bet.gameId].outcome == 0) revert GameNotFinished();
        if (bet.outcome != games[bet.gameId].outcome) revert MustWinBet();
        if (bet.amount == 0) revert BetAlreadySettled();

        uint256 payout = bet.amount * games[bet.gameId].odds[bet.outcome - 1] / MULTIPLIER;

        bet.amount = 0;

        tDollar.transfer(winner, payout);

        emit SettleBet(winner, _betId, payout);
    }

    function _calculateRewards(address account) private view returns (uint) {
        UserInfo memory user = userInfo[account];
        return (user.staked * (rewardIndex - user.rewardIndex)) / MULTIPLIER;
    }

    function calculateRewardsEarned(address account) external view returns (uint) {
        return userInfo[account].earned + _calculateRewards(account);
    }

    function _updateRewards(address account) private {
        UserInfo storage user = userInfo[account];
        user.earned += _calculateRewards(account);
        user.rewardIndex = rewardIndex;
    }

    function stake(uint256 _amount) public {
        require(tDollar.transferFrom(msg.sender, address(this), _amount));

        _updateRewards(msg.sender);

        userInfo[msg.sender].staked += _amount;
        totalStaked += _amount;
        totalReserve += _amount;

        emit Stake(msg.sender, _amount);
    }

    function unstake(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];

        if (!(totalReserve - totalUtilization >= _amount)) revert StakedAmountBeingUtilized();
        if (user.staked < _amount) revert InsuffecientStakedBalance();

        _updateRewards(msg.sender);

        user.staked -= _amount;
        totalStaked -= _amount;
        totalReserve -= _amount;

        tDollar.transfer(msg.sender, _amount);

        emit Unstake(msg.sender, _amount);
    }

    function claim() public {
        _updateRewards(msg.sender);

        UserInfo storage user = userInfo[msg.sender];

        uint reward = user.earned;
        if (reward > 0) {
            user.earned = 0;
            totalRewards -= reward;

            tDollar.transfer(msg.sender, reward);

            emit Claim(msg.sender, reward);
        } else {
            revert NoRewardsToClaim();
        }
    }
}