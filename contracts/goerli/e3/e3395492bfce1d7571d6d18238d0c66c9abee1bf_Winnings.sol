/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

//  MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

//  MIT
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
//  MIT
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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}
//  MIT
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**
 * @title Winnings
 * @dev Implements game placing and winning logic
 */
contract Winnings is Ownable, ReentrancyGuard {

    struct Tournament {
        uint256 tournamentId;
        string identifier;
        address creator;
        uint256 firstTimeEntryFee;
        uint256 reEntryFee;
        uint256 pricePool;
        bool isNativeToken;
        address coinAddress;
        uint256 totalFundCollected;
        bool ended;
    }

    uint256 tournamentCounter = 0;
    mapping(uint256 => mapping(address => uint256)) public lockedFunds;
    mapping(uint256 => Tournament) public tournamentIdToTournament;

    event TournamentCreated(
        uint256 tournamentId,
        string identifier,
        address indexed creator,
        uint256 firstTimeEntryFee,
        uint256 reEntryFee,
        uint256 pricePool,
        bool isNativeToken,
        address coinAddress
    );

    event FundLocked(address indexed participant, uint256 fundValue);
    event TransferedWinningFunds(
        uint256 tournamentId,
        address winnerAddress,
        uint256 winningAmount
    );
    event Withdrawal(address indexed participant, uint256 amount);

    /**
     * @dev Creates a new tournament
     */
    function createTournament(
        string memory identifier,
        uint256 firstTimeEntryFee,
        uint256 reEntryFee,
        uint256 pricePool,
        bool isNativeToken,
        address coinAddress
    ) public nonReentrant {
        require(
            msg.sender != address(0),
            "Contract called from invalid address"
        );
        require(pricePool > 0, "Price pool shoule be greater than 0");

        if (!isNativeToken) {
            require(
                coinAddress != address(0),
                "Invalid coin address has been provided"
            );
        }

        address validCoinAddress = isNativeToken ? address(0) : coinAddress;
        tournamentCounter = tournamentCounter + 1;

        tournamentIdToTournament[tournamentCounter] = Tournament(    //does this properly increase the ID and assign it to the tournament?
            tournamentCounter,
            identifier,
            msg.sender,
            firstTimeEntryFee,
            reEntryFee,
            pricePool,
            isNativeToken,
            validCoinAddress,
            0,
            false
        );

        emit TournamentCreated(
            tournamentCounter,
            identifier,
            msg.sender,
            firstTimeEntryFee,
            reEntryFee,
            pricePool,
            isNativeToken,
            validCoinAddress
        );
    }

    /**
     * @dev Lock funds from participants of the tournament
     */
    function lockFunds(uint256 tournamentId) public payable nonReentrant {
        Tournament storage tournament = tournamentIdToTournament[tournamentId];
        require(tournament.creator != address(0), "Tournament not found");
        require(tournament.ended == false, "Tournament has been ended");

        uint256 oldFund = lockedFunds[tournamentId][msg.sender];
        uint256 entryFee = 0;

        if (oldFund > 0) {
            // participant is trying to re-enter
            entryFee = tournament.reEntryFee;
        } else {
            // first time entry
            entryFee = tournament.firstTimeEntryFee;
        }

        if (tournament.isNativeToken) {
            // if tournament is paid on native token
            require(entryFee == msg.value, "Funds should be equal to fee");
        } else {
            // tournament is paid on ERC20 token
            uint256 balance = IERC20(tournament.coinAddress).balanceOf(
                msg.sender
            );
            require(balance >= entryFee, "Insufficient token balance");

            // lock the tokens in contract
            bool sent = IERC20(tournament.coinAddress).transferFrom(
                msg.sender,
                address(this),
                entryFee
            );
            require(sent, "Failed to lock ERC20 coin");
        }

        lockedFunds[tournamentId][msg.sender] += entryFee;   //just keeps track of the total fee that the user has paid. View
        tournament.totalFundCollected += entryFee;

        emit FundLocked(msg.sender, entryFee);
    }

    /**
     * @dev Allows creator to end the tournamnet and send some funds
     */
    function transferWinningFunds(
        uint256 tournamentId,
        address winnerAddress,
        uint256 winningAmount
    ) public {
        Tournament storage tournament = tournamentIdToTournament[tournamentId];
        require(
            msg.sender == tournament.creator,
            "Only creator can end tournament"
        );
        require(tournament.ended == false, "Tournament has already ended");

        require(
            winningAmount <= tournament.totalFundCollected,
            "Amount should not be greater than total funds collected"
        );

        if (!tournament.ended) {          //this if-statement is unnecessary. Probs Informational Finding
            tournament.ended = true;
        }

        tournament.totalFundCollected -= winningAmount;

        if (tournament.isNativeToken) {
            (bool sent, ) = winnerAddress.call{value: winningAmount}("");
            require(sent, "Failed to send native coin");
        } else {
            bool sent = IERC20(tournament.coinAddress).transfer(
                winnerAddress,
                winningAmount
            );
            require(sent, "Failed to send ERC20 coin");
        }

        emit TransferedWinningFunds(tournamentId, winnerAddress, winningAmount);
    }

    /**
     * @dev Get tournament from id
     */
    function getTournament(uint256 tournamentId)
        public
        view
        returns (Tournament memory tournament)
    {
        return tournamentIdToTournament[tournamentId];
    }

    function withdrawalAllTournamentFunds(uint256 tournamentId)
        public
        payable
        nonReentrant
    {
        Tournament storage tournament = tournamentIdToTournament[tournamentId];
        require(address(0) != tournament.creator, "Tournament not found");
        require(tournament.ended == true, "Tournament has not ended yet");
        require(
            msg.sender == tournament.creator,
            "Only creator can withdrawl funds"
        );

        require(
            tournament.totalFundCollected > 0,
            "No funds left to withdrawal"
        );

        uint256 amount = tournament.totalFundCollected;
        tournament.totalFundCollected = 0;

        if (tournament.isNativeToken) {
            (bool sent, ) = msg.sender.call{value: amount}("");
            require(sent, "Failed to withdrawal native coin");
        } else {
            bool sent = IERC20(tournament.coinAddress).transfer(
                msg.sender,
                amount
            );
            require(sent, "Failed to withdrawal ERC20 coin");
        }

        emit Withdrawal(msg.sender, amount);
    }
}