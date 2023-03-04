/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

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

// File: p2pbetting/BetContract.sol


pragma solidity ^0.8.17;



interface IBetToken is IERC20 {
    function mint(address to, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

contract BetContract is Ownable {
    struct Bet {
        address user;
        uint8 resultId;
        uint256 amount;
    }

    struct Event {
        uint256 id;
        bool closed;
        uint8[] winIds;
        uint8[] refundIds;
        uint8[] halfWinIds;
        uint8[] halfRefundIds;
        Bet[] bets;
    }

    mapping(address => bool) usersClaimed;

    mapping(uint256 => Event) private _events;

    uint256 private _eventsCount = 1;

    address public betToken;

    constructor(address _betToken) {
        betToken = _betToken;
    }

    function exists(uint8[] memory _arr, uint8 _v)
        private
        pure
        returns (bool _exists)
    {
        for (uint256 i = 0; i < _arr.length; i++) {
            if (_arr[i] == _v) {
                return true;
            }
        }
    }

    function findUserBets(Bet[] memory _bets, address _address)
        private
        pure
        returns (Bet[] memory)
    {
        uint256 resultCount;
        for (uint256 i = 0; i < _bets.length; i++) {
            if (_bets[i].user == _address) {
                resultCount++;
            }
        }
        Bet[] memory result = new Bet[](resultCount);
        uint256 j;
        for (uint256 i = 0; i < _bets.length; i++) {
            if (_bets[i].user == _address) {
                result[j] = _bets[i];
                j++;
            }
        }
        return result;
    }

    function calcUserLosses(Event memory _event, Bet memory _bet)
        private
        pure
        returns (uint256)
    {
        if (
            !exists(_event.winIds, _bet.resultId) &&
            !exists(_event.refundIds, _bet.resultId) &&
            !exists(_event.halfRefundIds, _bet.resultId) &&
            !exists(_event.halfWinIds, _bet.resultId)
        ) {
            return _bet.amount;
        }
        return 0;
    }

    function calcUserRewards(
        Event memory _event,
        Bet memory _bet,
        uint256 rewards
    ) private pure returns (uint256) {
        if (exists(_event.winIds, _bet.resultId)) {
            return _bet.amount + rewards;
        }
        if (exists(_event.refundIds, _bet.resultId)) {
            return _bet.amount;
        }
        if (exists(_event.halfRefundIds, _bet.resultId)) {
            return _bet.amount / 2;
        }
        if (exists(_event.halfWinIds, _bet.resultId)) {
            return _bet.amount + rewards / 2;
        }
        return 0;
    }

    function calcUserRewardsShare(
        uint256 userBetAmount,
        uint256 targetTeamDepositsAmount,
        uint256 distributableAmount
    ) private pure returns (uint256) {
        if (userBetAmount * 100 <= targetTeamDepositsAmount) {
            return 0;
        }
        uint256 depositShare = (userBetAmount * 100) / targetTeamDepositsAmount;
        if (distributableAmount * depositShare <= 100) {
            return 0;
        }
        return (distributableAmount * depositShare) / 100;
    }

    function getEventsCount() external view returns (uint256 eventsCount) {
        return _eventsCount - 1;
    }

    function getBets(uint256 _eventId) public view returns (Bet[] memory bets) {
        return _events[_eventId].bets;
    }

    function getEvent(uint256 _eventId)
        external
        view
        returns (Event memory _event)
    {
        return _events[_eventId];
    }

    function createEvent() external onlyOwner {
        Event storage _event = _events[_eventsCount];
        _event.id = _eventsCount;
        _eventsCount++;
    }

    function closeEvent(
        uint256 _eventId,
        uint8[] memory winIds,
        uint8[] memory refundIds,
        uint8[] memory halfWinIds,
        uint8[] memory halfRefundIds
    ) external onlyOwner {
        require(_events[_eventId].id > 0, "Event does not exists");
        require(!_events[_eventId].closed, "Event already closed");
        Event storage _event = _events[_eventId];
        _event.winIds = winIds;
        _event.refundIds = refundIds;
        _event.halfRefundIds = halfRefundIds;
        _event.halfWinIds = halfWinIds;
        _event.closed = true;
    }

    function createBet(
        uint256 _eventId,
        uint8 resultId,
        uint256 _amount
    ) external {
        Event storage _event = _events[_eventId];
        require(_event.id > 0, "Event does not exists");
        require(!_event.closed, "Event closed");
        require(resultId > 0, "resultId must be greater than 0");
        require(_amount > 0, "amount must be greater than 0");
        IBetToken(betToken).burnFrom(msg.sender, _amount);
        _event.bets.push(Bet(msg.sender, resultId, _amount));
    }

    function claim(uint256 _eventId) external {
        require(!usersClaimed[msg.sender], "Prize already climed");
        uint256 rewards = calcRewards(_eventId, msg.sender);
        IBetToken(betToken).mint(msg.sender, rewards);
        usersClaimed[msg.sender] = true;
    }

    function calcRewards(uint256 _eventId, address _address)
        public
        view
        returns (uint256 _rewards)
    {
        Event memory _event = _events[_eventId];
        require(_event.id > 0, "Event does not exists");
        require(_event.closed, "The event hasn't ended yet");
        Bet[] memory _userBets = findUserBets(_event.bets, _address);
        require(_userBets.length > 0, "User does not have bets");

        uint256 distributableAmount = 0;

        if (usersClaimed[msg.sender]) {
            return 0;
        }

        for (uint256 i = 0; i < _event.bets.length; i++) {
            if (
                exists(_event.winIds, _event.bets[i].resultId) ||
                exists(_event.halfWinIds, _event.bets[i].resultId) ||
                exists(_event.refundIds, _event.bets[i].resultId)
            ) {
                continue;
            }
            if (exists(_event.halfRefundIds, _event.bets[i].resultId)) {
                distributableAmount += _event.bets[i].amount / 2;
                continue;
            }
            distributableAmount += _event.bets[i].amount;
        }

        for (uint256 i = 0; i < _userBets.length; i++) {
            uint256 targetTeamDepositsAmount;
            for (uint256 j = 0; j < _event.bets.length; j++) {
                if (_event.bets[j].resultId == _userBets[i].resultId) {
                    targetTeamDepositsAmount += _event.bets[j].amount;
                }
            }
            uint256 userRewardsShare = calcUserRewardsShare(
                _userBets[i].amount,
                targetTeamDepositsAmount,
                distributableAmount
            );

            uint256 userRewards = calcUserRewards(
                _event,
                _userBets[i],
                userRewardsShare
            );
            _rewards += userRewards;
        }
        for (uint256 i = 0; i < _userBets.length; i++) {
            uint256 userLosses = calcUserLosses(_event, _userBets[i]);
            if (_rewards < userLosses) {
                return 0;
            }
            _rewards -= userLosses;
        }
        return _rewards;
    }
}