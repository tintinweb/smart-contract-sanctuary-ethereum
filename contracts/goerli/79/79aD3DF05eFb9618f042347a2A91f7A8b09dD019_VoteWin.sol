// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract VoteWin is Pausable, Ownable {

    uint public feeService = 10; // 10%
    struct Match {
        mapping(uint => uint) team; // team A/B => teamIndex
        mapping(uint => uint) totalVote; // team A/B => teamIndex
        uint startTime;
        uint endTime;
        uint result; // 1 => A win; 2 => B win; 3 cancel
        string description;
    }
    struct User {
        uint totalVoted;
        mapping(uint => mapping(uint => uint)) team; // day => match index => team side
        mapping(uint => mapping(uint => uint)) matchAmount; // day => match index => voted amount
        mapping(uint => mapping(uint => bool)) usersClaimed; // day => match => is claimed
    }
    mapping(uint => uint[]) public matchs; // day => match detail index
    mapping(uint => mapping(uint => Match)) public matchDetails; // day => match index => detail
    mapping(address => User) public users;

    IERC20 public immutable voteToken;

    event Vote(address user, uint _day, uint _matchIndex, uint amount);
    event UnVote(address user, uint _day, uint _matchIndex, uint amount);
    event SetRank(uint _rank, uint _matchIndex);
    event ClaimWin(address user, uint _day, uint _matchIndex);

    constructor(IERC20 _voteToken) {
        voteToken = _voteToken;
    }
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function userAllocate(address user, uint _day, uint _matchIndex, uint _teamSide) public view returns(uint) {
        return 100 * users[user].matchAmount[_day][_matchIndex] / matchDetails[_day][_matchIndex].totalVote[_teamSide];
    }
    function userTotalVote(address user, uint _day, uint _matchIndex) public view returns(uint _teamSide, uint _total) {
        _teamSide = users[user].team[_day][_matchIndex];
        _total = users[user].matchAmount[_day][_matchIndex];
    }
    function winAmount(address user, uint _day, uint _matchIndex, uint _teamSide) public view returns(uint) {
        uint lostSide = _teamSide == 1 ? 2 : 1;
        return userAllocate(user, _day, _matchIndex, _teamSide) * matchDetails[_day][_matchIndex].totalVote[lostSide] / 100;
    }
    function claimWin(uint _day, uint _matchIndex) external whenNotPaused {
        User storage u = users[_msgSender()];
        Match storage r = matchDetails[_day][_matchIndex];
        require(r.result > 0, 'VoteWin::claimWin: Running');
        require(u.matchAmount[_day][_matchIndex] > 0, 'VoteWin::claimWin: Not Vote');
        require(u.team[_day][_matchIndex] == r.result, 'VoteWin::claimWin: Not Win');
        require(!u.usersClaimed[_day][_matchIndex], 'VoteWin::claimWin: claimed');

        uint _winAmount = winAmount(_msgSender(), _day, _matchIndex, r.result);
        uint _fee = feeService * _winAmount / 100;
        voteToken.transfer(owner(), _fee);
        voteToken.transfer(_msgSender(), _winAmount - _fee);
        u.usersClaimed[_day][_matchIndex] = true;
        emit ClaimWin(_msgSender(), _day, _matchIndex);
    }
    function getDays() public view returns(uint) {
        return block.timestamp / 1 days;
    }
    function vote(uint _day, uint _matchIndex, uint _teamSide, uint amount) external whenNotPaused {
        require(amount > 0, 'VoteWin::vote: invalid amount');
        require(block.timestamp < matchDetails[_day][_matchIndex].startTime, 'VoteWin::vote: match is started');
        voteToken.transferFrom(_msgSender(), address(this), amount);
        uint userTeamSide = users[_msgSender()].team[_day][_matchIndex];
        uint _userTotalVote = users[_msgSender()].matchAmount[_day][_matchIndex];
        if(userTeamSide > 0 && _teamSide != userTeamSide) {
            matchDetails[_day][_matchIndex].totalVote[userTeamSide] -= _userTotalVote;
            matchDetails[_day][_matchIndex].totalVote[_teamSide] += _userTotalVote;
        }
        users[_msgSender()].team[_day][_matchIndex] = _teamSide;
        users[_msgSender()].matchAmount[_day][_matchIndex] += amount;

        matchDetails[_day][_matchIndex].totalVote[_teamSide] += amount;
        emit Vote(_msgSender(), _day, _matchIndex, amount);
    }
    function getMatchs(uint __day, uint __matchIndex) external view returns(uint teamA, uint teamB, uint totalVoteTeamA, uint totalVoteTeamB,
        uint startTime,
        uint endTime,
        uint result,  string memory description) {
        uint _day = __day;
        uint _matchIndex = __matchIndex;
        return (matchDetails[_day][_matchIndex].team[1], matchDetails[_day][_matchIndex].team[2], matchDetails[_day][_matchIndex].totalVote[1],
        matchDetails[_day][_matchIndex].totalVote[2],
        matchDetails[_day][_matchIndex].startTime,
        matchDetails[_day][_matchIndex].endTime,
        matchDetails[_day][_matchIndex].result, matchDetails[_day][_matchIndex].description);
    }
    function getMatchsLength(uint _day) external view returns(uint) {
        return matchs[_day].length;
    }
    function updateMatch(uint _day, uint _matchIndex, uint startTime, uint endTime, uint teamIndexA, uint teamIndexB) external onlyOwner whenPaused {
        require(matchDetails[_day][_matchIndex].startTime > 0, 'VoteWin::setMatch: match is not existed');
        require(startTime > block.timestamp, 'VoteWin::vote: invalid startTime');
        require(endTime > startTime, 'VoteWin::vote: invalid endTime');
        matchDetails[_day][_matchIndex].team[1] = teamIndexA;
        matchDetails[_day][_matchIndex].team[2] = teamIndexB;
        matchDetails[_day][_matchIndex].startTime = startTime;
        matchDetails[_day][_matchIndex].endTime = endTime;
    }

    function setMatch(uint _day, uint _matchIndex, uint startTime, uint endTime, uint teamIndexA, uint teamIndexB) public onlyOwner whenPaused {
        require(matchDetails[_day][_matchIndex].startTime == 0, 'VoteWin::setMatch: match existed');
        require(startTime > block.timestamp, 'VoteWin::vote: invalid startTime');
        require(endTime > startTime, 'VoteWin::vote: invalid endTime');
        matchDetails[_day][_matchIndex].team[1] = teamIndexA;
        matchDetails[_day][_matchIndex].team[2] = teamIndexB;
        matchDetails[_day][_matchIndex].startTime = startTime;
        matchDetails[_day][_matchIndex].endTime = endTime;
        matchs[_day].push(_matchIndex);
    }

    function setMatchs(uint[] memory _days, uint[] memory _matchIndexs, uint[] memory startTimes, uint[] memory endTimes, uint[] memory teamIndexAs, uint[] memory teamIndexBs) external onlyOwner whenPaused {
        for(uint i = 0; i < _days.length; i++) {
            setMatch(_days[i], _matchIndexs[i], startTimes[i], endTimes[i], teamIndexAs[i], teamIndexBs[i]);
        }
    }

    function setMatchResult(uint _day, uint _matchIndex, uint _result) external onlyOwner whenPaused {
        matchDetails[_day][_matchIndex].result = _result;
    }

    function unVote(uint _day, uint _matchIndex, uint amount) external whenNotPaused {
        require(block.timestamp < matchDetails[_day][_matchIndex].startTime, 'VoteWin::unVote: Ended');
        require(users[_msgSender()].matchAmount[_day][_matchIndex] >= amount, 'VoteWin::unVote: Invalid Amount');
        uint _fee = feeService * amount / 100;
        voteToken.transfer(owner(), _fee);
        voteToken.transfer(_msgSender(), amount - _fee);
        users[_msgSender()].matchAmount[_day][_matchIndex] -= amount;

        uint userTeamSide = users[_msgSender()].team[_day][_matchIndex];
        matchDetails[_day][_matchIndex].totalVote[userTeamSide] -= amount;
        emit UnVote(_msgSender(), _day, _matchIndex, amount);
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