// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./BettingContract.sol";

contract BetFactory {
    uint256 public counter;
    event LaunchedBet(address indexed betAddress, address indexed owner, uint256 betId, string betName);

    constructor() {
        counter = 0;
    }

    struct BetList {
        address betAddress;
        address owner;
        uint256 betId;
        string betName;
        uint timestamp;
    }

    mapping (uint256 => BetList) public betLists;

    function launchBet(string[] memory _teams, string memory _betName) external {
        BettingContract bet = new BettingContract(_teams);
        counter++;
        bet.transferOwnership(msg.sender);

        betLists[counter] = BetList(
            address(bet), 
            msg.sender, 
            counter, 
            _betName, 
            block.timestamp);

        emit LaunchedBet(address(bet), msg.sender, counter, _betName);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BettingContract is Ownable, ReentrancyGuard {
    event NewBet(address addy, uint amount, Team teamBet);

    struct Bet {
        string name;
        uint256 amount;
        uint256 totalWon;
        Team teamBet;
    }

    struct Team {
        string name;
        uint256 totalBetAmount;
    }

    // Bet[] public bets;
    Team[] public teams;

    enum State {
        started,
        closed,
        cancelled,
        executed
    }

    State public state;
    address payable conOwner;
    uint public totalBetMoney = 0;
    uint public winnerId;

    mapping(address => Bet) public bets;
    mapping(address => uint) public numBetsAddress;

    constructor(string[] memory _teams) payable {
        conOwner = payable(msg.sender);
        state = State.started;
        for (uint i = 0; i < _teams.length; i++) {
            createTeam(_teams[i]);
        }
    }

    function createTeam(string memory _name) public {
        require(state == State.started, "BBET: Bets not longer accepted");
        teams.push(Team(_name, 0));
    }

    function getTotalBetAmount(uint _teamId) public view returns (uint) {
        return teams[_teamId].totalBetAmount;
    }

    function createBet(uint _teamId) external payable nonReentrant {
        require(state == State.started, "BBET: Bets not longer accepted");
        require(msg.sender != conOwner, "BBET: Owner can't make a bet");
        require(
            numBetsAddress[msg.sender] == 0,
            "BBET: You have already placed a bet"
        );
        require(msg.value > 0.0001 ether, "BBET: Bet below minimum");

        bets[msg.sender] = Bet(
            teams[_teamId].name,
            msg.value,
            0,
            teams[_teamId]
        );
        teams[_teamId].totalBetAmount += msg.value;
        numBetsAddress[msg.sender]++;
        totalBetMoney += msg.value;

        emit NewBet(msg.sender, msg.value, teams[_teamId]);
    }

    function reportWinner(uint _teamId) public payable onlyOwner {
        require(
            state == State.closed,
            "BBET: Bet already distributed or cancelled"
        );
        winnerId = _teamId;
        state = State.executed;
    }

    function pauseForNewBets() public onlyOwner {
        require(state == State.started, "BBET: Bets not in initial state");
        state = State.closed;
    }

    function withdrawnRemaining() external onlyOwner {
        require(state == State.executed, "BBET: Bet not yet executed");
        payable(msg.sender).transfer(address(this).balance);
    }

    function cancel() external onlyOwner {
        require(
            state == State.started,
            "BBET: Bet already distributed or cancelled"
        );
        state = State.cancelled;
    }

    function recoverFunds() external nonReentrant {
        require(state == State.cancelled, "BBET: Bet not cancelled");
        require(bets[msg.sender].amount > 0, "BBET: No bet placed");
        payable(msg.sender).transfer(bets[msg.sender].amount);
    }

    function claimWinnings() external nonReentrant {
        require(state == State.executed, "BBET: Bet not executed");
        require(bets[msg.sender].amount > 0, "BBET: No bet placed");

        if (
            keccak256(abi.encodePacked((bets[msg.sender].teamBet.name))) ==
            keccak256(abi.encodePacked(teams[winnerId].name))
        ) {
            uint div = (bets[msg.sender].amount *
                (totalBetMoney / getTotalBetAmount(winnerId)));
            bets[msg.sender].totalWon = (div * 970) / 1000;
        }

        require(bets[msg.sender].totalWon > 0, "BBET: No winnings to claim");
        payable(msg.sender).transfer(bets[msg.sender].totalWon);
    }

    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    ) public virtual onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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