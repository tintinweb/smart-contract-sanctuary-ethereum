// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./structs/Structs.sol";

contract WorldCupQuiz is Ownable, ReentrancyGuard {
    IERC20 token;

    mapping(uint256 => Game) public games;

    mapping(address => uint256) public createdGames;
    mapping(address => uint256) public tickets;
    mapping(address => bool) public banned;
    mapping(address => uint256) public earnings;
    mapping(address => address) public referrals;

    // Influencers cannot change after the first ticket is bought
    address[] public influencers;
    uint256[] public influencersPercents;

    uint256 public poolCount;

    uint256 public ticketPrice = 1000000; // 1 USDT

    uint256 public minBuyIn = 1;
    uint256 public worldCupStartTime = 1668956400; // 2022-11-20 03:00:00 PM GMT

    address public server;
    address private adminSigner;

    uint256[10] percentages = [21, 17, 14, 12, 10, 8, 6, 5, 4, 3];
    uint256 public teamFunds = 0;

    // constructor
    constructor (
        address _token,
        address _server,
        address _adminSigner,
        uint256 _minBuyIn
    ) {
        token = IERC20(_token);
        server = _server;
        adminSigner = _adminSigner;
        minBuyIn = _minBuyIn;
    }

    modifier onlyServer() {
        require(msg.sender == server, "Only server can call this function.");
        _;
    }



    function buyTicket(uint256 _amount, address _referrer) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(token.allowance(msg.sender, address(this)) >= _amount * ticketPrice, "Insufficient allowance");
        if (referrals[msg.sender] != address(0)) {
            require(referrals[msg.sender] == _referrer, "Referrer cannot change");
        } else {
            referrals[msg.sender] = _referrer;
        }
        _sendFunds(msg.sender, address(this), _amount * ticketPrice);

        uint256 totalPercent = 0;
        if (referrals[msg.sender] != address(0)) {
            earnings[_referrer] += _amount * ticketPrice * 10 / 100;
            totalPercent += 10;
        }
        for (uint256 i = 0; i < influencers.length; i++) {
            uint256 percent = influencersPercents[i];
            earnings[influencers[i]] += _amount * ticketPrice * percent / 100;
            totalPercent += percent;
        }
        teamFunds += _amount * ticketPrice * (80 - totalPercent) / 100; // 40-80% of the ticket price goes to the team
        tickets[msg.sender] += _amount;
    }

    function refundTicket(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(tickets[msg.sender] >= _amount, "Insufficient tickets");
        _sendFunds(address(this), msg.sender, _amount * ticketPrice);

        uint256 totalPercent = 0;
        if(referrals[msg.sender] != address(0)) {
            earnings[referrals[msg.sender]] -= _amount * ticketPrice * 10 / 100;
            totalPercent += 10;
        }
        for (uint256 i = 0; i < influencers.length; i++) {
            uint256 percent = influencersPercents[i];
            earnings[influencers[i]] -= _amount * ticketPrice * percent / 100;
            totalPercent += percent;
        }
        teamFunds -= _amount * ticketPrice * (80 - totalPercent) / 100;
        tickets[msg.sender] -= _amount;
    }



    function createGame(uint256 _serverGameId, uint256 _ticketsRequired, Authorization memory _authorization) public {
        require(_ticketsRequired >= minBuyIn, "Tickets required must be greater than min buy in");
        if (msg.sender != server) {
            require(_ticketsRequired > 0, "Tickets required must be greater than 0");
            require(tickets[msg.sender] >= _ticketsRequired, "Insufficient tickets");
            require(createdGames[msg.sender] == 0, "You already have an ongoing/upcoming game scheduled");
            bytes32 digest = keccak256(abi.encode(_serverGameId, msg.sender));
            require(_isVerifiedCoupon(digest, _authorization), 'Invalid authorization');
        }

        _createGame(_serverGameId, _ticketsRequired, msg.sender != server);
        createdGames[msg.sender] = _serverGameId;
    }

    function startGame(uint256 gameId) public onlyServer {
        require(games[gameId]._exists, "Game does not exist");
        require(!games[gameId].started, "Game already started");
        require(games[gameId].entryCount > 0, "Game has no entries");

        games[gameId].started = true;
        games[gameId].prize = games[gameId].entryCount * games[gameId].buyIn * ticketPrice * 10 / 100;
        games[gameId].timestamp = block.timestamp;
    }

    function endGame(uint256 gameId, address winner, address[] memory top10) public onlyServer {
        require(games[gameId]._exists, "Game does not exist");
        require(games[gameId].started, "Game not started");
        require(!games[gameId].ended, "Game already ended");
        require(games[gameId].entries[winner], "Winner not in game");

        earnings[winner] += games[gameId].prize;
        uint256 top10Prize = games[gameId].prize * 10 / 100;
        for (uint256 i = 0; i < top10.length; i++) {
            // Top 10 prize is split 21% - 17% - 14% - 12% - 10% - 8% - 6% - 5% - 4% - 3%
            // top10 is sorted by points, so the first element is the 2nd place
            earnings[top10[i]] += top10Prize * percentages[i] / 100;
        }
        // TODO: send top 10 earnings
        games[gameId].ended = true;
        games[gameId].winner = winner;
    }

    function joinGame(uint256 _gameId) public {
        require(games[_gameId]._exists, "Invalid game id");
        require(!games[_gameId].started, "Game started");
        require(!banned[msg.sender], "You are banned");
        require(!games[_gameId].kicked[msg.sender], "You have been kicked from this game");

        require(tickets[msg.sender] >= games[_gameId].buyIn, "Insufficient tickets");
        tickets[msg.sender] -= games[_gameId].buyIn;
        games[_gameId].entries[msg.sender] = true;
        games[_gameId].entryCount++;
    }

    function leaveGame(uint256 _gameId) public {
        _removeFromSession(msg.sender, _gameId);
    }


    function claimFunds() public {
        require(earnings[msg.sender] > 0, "No funds to claim");
        uint256 amount = earnings[msg.sender];
        earnings[msg.sender] = 0;
        _sendFunds(address(this), msg.sender, amount);
    }
    function claimRemainingFunds(address _to) public onlyOwner {
        uint256 amount = teamFunds;
        teamFunds = 0;
        _sendFunds(address(this), _to, amount);
    }



    function kickFromGame(address _player, uint256 _gameId) public onlyServer {
        _removeFromSession(_player, _gameId);
        games[_gameId].kicked[_player] = true;
    }

    function ban(address _player, bool _status) public onlyServer {
        banned[_player] = _status;
    }



    function approveTokens(uint256 _amount) public returns(bool){
        token.approve(address(this), _amount);
        return true;
    }
    function getContractTokenBalance() public onlyOwner view returns(uint256){
        return token.balanceOf(address(this));
    }



    function _removeFromSession(address _player, uint256 _gameId) internal {
        require(games[_gameId]._exists, "Invalid game id");
        require(!games[_gameId].started, "Game started");
        require(games[_gameId].entries[_player], "Not in game");
        games[_gameId].entries[_player] = false;
        games[_gameId].entryCount--;
    }
    function _createGame(uint256 _serverGameId, uint256 _ticketsRequired, bool _includeCreator) internal {
        games[_serverGameId].id = _serverGameId;
        games[_serverGameId].buyIn = _ticketsRequired;
        games[_serverGameId].timestamp = block.timestamp;
        games[_serverGameId]._exists = true;

        if(_includeCreator){
            games[_serverGameId].entries[msg.sender] = true;
            games[_serverGameId].entryCount++;
        }
    }
    function _isVerifiedCoupon(bytes32 _digest, Authorization memory _auth) internal view returns (bool) {
        address signer = ecrecover(_digest, _auth.v, _auth.r, _auth.s);
        require(signer != address(0), 'ECDSA: invalid signature');
        return signer == adminSigner;
    }
    function _sendFunds(address _from, address _to, uint256 _amount) internal nonReentrant {
        require(token.transferFrom(_from, _to, _amount), "Transfer failed");
    }



    function emergencyOverrideTickets(address _user, uint256 _amount) public onlyOwner {
        tickets[_user] = _amount;
    }
    function emergencyRefund(address _player, uint256 _amount) public onlyOwner {
        _sendFunds(address(this), _player, _amount * ticketPrice);
        tickets[msg.sender] -= _amount;
    }
    function setAdminSigner(address _adminSigner) public onlyOwner {
        adminSigner = _adminSigner;
    }
    function updateTicketPrice(uint256 _ticketPrice) public onlyOwner {
        ticketPrice = _ticketPrice;
    }
    function addInfluencers(address[] memory _influencers, uint256[] memory _percentages) public onlyOwner {
        require(_influencers.length == _percentages.length, "Invalid input");
        for (uint256 i = 0; i < _influencers.length; i++) {
            addInfluencer(_influencers[i], _percentages[i]);
        }
    }
    function addInfluencer(address _influencer, uint256 percentage) public onlyOwner {
        influencers.push(_influencer);
        influencersPercents.push(percentage);
    }
    function removeInfluencer(address _influencer) public onlyOwner {
        for (uint256 i = 0; i < influencers.length; i++) {
            if (influencers[i] == _influencer) {
                influencers[i] = influencers[influencers.length - 1];
                influencers.pop();
                influencersPercents[i] = influencersPercents[influencersPercents.length - 1];
                influencersPercents.pop();
                break;
            }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

struct Game {
    uint256 id;
    uint256 buyIn;
    uint256 timestamp;
    uint256 entryCount;
    bool started;
    bool ended;
    uint256 prize;
    address winner;
    mapping(address => bool) entries;
    mapping(address => bool) kicked;
    bool _exists;
}

struct Authorization {
    bytes32 r;
    bytes32 s;
    uint8 v;
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