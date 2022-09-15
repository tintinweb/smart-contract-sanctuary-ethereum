// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract VoteChampion is Pausable, Ownable {

    uint public feeService = 10; // 10%

    struct Team {
        string name;
        uint totalVotedRank1;
        uint totalVotedRank2;
        uint totalVotedRank3;
        uint yourVotedRank1;
        uint yourVotedRank2;
        uint yourVotedRank3;
    }
    struct Player {
        string name;
        uint totalVoted;
    }
    struct Rank {
        string team;
        uint teamIndex;
        uint totalVote;
        bool isResult;
    }
    struct User {
        address user;
        uint totalVote;
        uint[] rankVoted;
        mapping(uint => mapping(uint => Rank)) voted; // team index => rank => detail
    }

    string[] public teams;
    string[] public players;
    uint public topScorerVoteAmount;

    mapping(uint => Rank) public ranks;
    mapping(uint => bool) public isEndTeam; // 0 => on; 1 => end vote;
    mapping(uint => bool) public isEndPlayer; // 0 => on; 1 => end vote;
    mapping(uint => mapping(uint => uint)) public userVoteRanks; // tean index => rank => total vote
    mapping(uint => uint) public userVoteTopScorer; // player index => total vote
    mapping(address => User) public users;

    IERC20 public immutable voteToken;

    event Vote(address user, uint _rank, uint _teamIndex, uint amount);
    event UnVote(address user, uint _rank, uint _teamIndex, uint amount);
    event SetRank(uint _rank, uint _teamIndex);
    event ClaimWin(address user, uint _rank, uint _teamIndex);

    constructor(string[] memory _teams, IERC20 _voteToken, string[] memory _players) {
        teams = _teams;
        voteToken = _voteToken;
        players = _players;
    }
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    function getTop3Rank() external view returns(Rank[] memory) {
        Rank[] memory r = new Rank[](3);
        r[0] = ranks[1];
        r[1] = ranks[2];
        r[2] = ranks[3];
        return r;
    }
    function userAllocate(address user, uint _rank, uint _teamIndex) public view returns(uint) {
        return 100 * users[user].voted[_teamIndex][_rank].totalVote / userVoteRanks[_teamIndex][_rank];
    }
    function winAmount(address user, uint _rank, uint _teamIndex) public view returns(uint) {
        return userAllocate(user, _rank, _teamIndex) * ranks[_rank].totalVote / 100;
    }
    function claimWin(uint _rank) external whenNotPaused {
        User storage u = users[_msgSender()];
        Rank memory r = ranks[_rank];
        require(r.isResult, 'VoteChampion::claimWin: Running');
        require(u.voted[r.teamIndex][_rank].totalVote > 0, 'VoteChampion::claimWin: Not Vote');
        require(u.voted[r.teamIndex][_rank].totalVote > 0, 'VoteChampion::claimWin: Not Vote amount');
        uint _winAmount = winAmount(_msgSender(), _rank, r.teamIndex);
        uint _fee = feeService * _winAmount / 100;
        voteToken.transfer(owner(), _fee);
        voteToken.transfer(_msgSender(), _winAmount - _fee);
        emit ClaimWin(_msgSender(), _rank, r.teamIndex);
    }
    function vote(uint _rank, uint _teamIndex, uint amount) external whenNotPaused {
        require(!isEndTeam[_teamIndex], 'VoteChampion::unVote: team Ended');
        require(_rank > 0 && _rank < 4, 'VoteChampion::vote: invalid rank');
        require(!ranks[_rank].isResult, 'VoteChampion::vote: Ended');
        voteToken.transferFrom(_msgSender(), address(this), amount);
        if(users[_msgSender()].voted[_teamIndex][_rank].totalVote == 0) users[_msgSender()].rankVoted.push(_rank);

        users[_msgSender()].user = _msgSender();
        users[_msgSender()].totalVote += amount;
        users[_msgSender()].voted[_teamIndex][_rank].totalVote += amount;

        ranks[_rank].totalVote += amount;
        userVoteRanks[_teamIndex][_rank] += amount;

        emit Vote(_msgSender(), _rank, _teamIndex, amount);
    }

    function voteTopScore(uint _playerIndex, uint amount) external whenNotPaused {
        require(!isEndPlayer[_playerIndex], 'VoteChampion::unVote: player Ended');
        voteToken.transferFrom(_msgSender(), address(this), amount);
        if(users[_msgSender()].voted[_playerIndex][4].totalVote == 0) users[_msgSender()].rankVoted.push(4);

        users[_msgSender()].user = _msgSender();
        users[_msgSender()].totalVote += amount;
        users[_msgSender()].voted[_playerIndex][4].totalVote += amount;

        topScorerVoteAmount += amount;
        userVoteTopScorer[_playerIndex] += amount;

        emit Vote(_msgSender(), 4, _playerIndex, amount);
    }

    function setTeamStatus(uint _teamIndex, bool _status) external onlyOwner {
        isEndTeam[_teamIndex] = _status;
    }
    function setRank(uint _rank, uint _teamIndex) external onlyOwner whenPaused {
        require(_rank > 0 && _rank < 4, 'VoteChampion::vote: invalid rank');
        ranks[_rank].team = teams[_teamIndex];
        ranks[_rank].teamIndex = _teamIndex;
        emit SetRank(_rank, _teamIndex);
    }
    function unVoteTopScore(uint _playerIndex, uint amount) external whenNotPaused {
        require(!isEndPlayer[_playerIndex], 'VoteChampion::unVote: player Ended');
        require(users[_msgSender()].voted[_playerIndex][4].totalVote >= amount, 'VoteChampion::unVote: Invalid Amount');
        uint _fee = feeService * amount / 100;
        voteToken.transfer(owner(), _fee);
        voteToken.transfer(_msgSender(), amount - _fee);
        users[_msgSender()].totalVote -= amount;
        users[_msgSender()].voted[_playerIndex][4].totalVote -= amount;

        topScorerVoteAmount -= amount;
        userVoteTopScorer[_playerIndex] -= amount;

        emit UnVote(_msgSender(), 4, _playerIndex, amount);
    }
    function unVote(uint _rank, uint _teamIndex, uint amount) external whenNotPaused {
        require(!ranks[_rank].isResult, 'VoteChampion::unVote: Ended');
        require(!isEndTeam[_teamIndex], 'VoteChampion::unVote: team Ended');
        require(users[_msgSender()].voted[_teamIndex][_rank].totalVote >= amount, 'VoteChampion::unVote: Invalid Amount');
        uint _fee = feeService * amount / 100;
        voteToken.transfer(owner(), _fee);
        voteToken.transfer(_msgSender(), amount - _fee);
        users[_msgSender()].totalVote -= amount;
        users[_msgSender()].voted[_teamIndex][_rank].totalVote -= amount;

        ranks[_rank].totalVote -= amount;
        userVoteRanks[_teamIndex][_rank] -= amount;

        emit UnVote(_msgSender(), _rank, _teamIndex, amount);
    }
    function getTeams(address _user) external view returns(Team[] memory){
        Team[] memory t = new Team[](teams.length);
        for(uint i = 0; i < teams.length; i++) {
            t[i] = Team(teams[i], userVoteRanks[i][1], userVoteRanks[i][2], userVoteRanks[i][3],
            users[_user].voted[i][1].totalVote, users[_user].voted[i][2].totalVote, users[_user].voted[i][3].totalVote
            );
        }
        return t;
    }
    function getPlayers() external view returns(Player[] memory){
        Player[] memory t = new Player[](players.length);
        for(uint i = 0; i < players.length; i++) {
            t[i] = Player(players[i], userVoteTopScorer[i]);
        }
        return t;
    }
    function inCaseTokensGetStuck(IERC20 _token) external onlyOwner {

        uint amount = _token.balanceOf(address(this));
        _token.transfer(msg.sender, amount);
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