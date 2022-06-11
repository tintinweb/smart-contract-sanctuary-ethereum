//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    struct Proposal {
        bytes callData;
        address recipient;
        string description;
        uint32 finishDate;
        uint256 votesFor;
        uint256 votesAgainst;
    }

    struct UserData {
        uint256 balance;
        uint32 lastFinishDate;
    }

    IERC20 private _token;
    uint32 private _debatingPeriodDuration;
    uint256 private _minimumQuorum;

    mapping(address => UserData) private _users;

    mapping(uint64 => Proposal) private _proposals;
    uint64 private _proposalCount;

    // user => (proposal id => is voted)
    mapping(address => mapping(uint64 => bool)) private _isVoted;

    event ProposalAccepted(
        uint64 proposalId,
        uint256 votesFor,
        uint256 votesAgainst,
        bytes funcResult
    );
    event ProposalDeclined(
        uint64 proposalId,
        uint256 votesFor,
        uint256 votesAgainst
    );
    event ProposalFailed(uint64 proposalId);
    event ProposalVotingStarted(
        uint64 proposalId,
        bytes callData,
        address recipient,
        string description
    );

    error InvalidProposal();
    error NotActiveProposalTime();
    error StillActiveProposalTime();
    error ActiveBalance();
    error InvalidAmount();
    error AlreadyVoted();

    modifier onlyActive(uint64 proposalId) {
        if (_proposals[proposalId].finishDate == 0) revert InvalidProposal();
        _;
    }

    constructor(
        IERC20 token,
        uint32 debatingPeriodDuration_,
        uint256 minimumQuorum_
    ) {
        _token = token;
        _debatingPeriodDuration = debatingPeriodDuration_;
        _minimumQuorum = minimumQuorum_;
    }

    function deposit(uint256 amount) external {
        _token.transferFrom(msg.sender, address(this), amount);
        _users[msg.sender].balance += amount;
    }

    function addProposal(
        bytes memory callData,
        address recipient,
        string memory description
    ) external onlyOwner {
        uint64 proposalId = _proposalCount;
        _proposalCount++;

        Proposal storage proposal_ = _proposals[proposalId];
        proposal_.callData = callData;
        proposal_.recipient = recipient;
        proposal_.description = description;
        proposal_.finishDate = uint32(block.timestamp) + _debatingPeriodDuration;

        emit ProposalVotingStarted(
            proposalId,
            callData,
            recipient,
            description
        );
    }

    function vote(
        uint64 proposalId, 
        bool isFor
    )
        external
        onlyActive(proposalId)
    {
        if (_proposals[proposalId].finishDate <= block.timestamp) revert NotActiveProposalTime();
        if (_isVoted[msg.sender][proposalId]) revert AlreadyVoted();

        _isVoted[msg.sender][proposalId] = true;
        _users[msg.sender].lastFinishDate = _proposals[proposalId].finishDate;
        if (isFor) {
            _proposals[proposalId].votesFor += _users[msg.sender].balance;
        } else {
            _proposals[proposalId].votesAgainst += _users[msg.sender].balance;
        }
    }

    function finishProposal(uint64 proposalId) external onlyActive(proposalId) {
        Proposal storage proposal_ = _proposals[proposalId];
        if (proposal_.finishDate > block.timestamp)
            revert StillActiveProposalTime();

        if (
            proposal_.votesFor + proposal_.votesAgainst >= _minimumQuorum &&
            proposal_.votesFor > proposal_.votesAgainst
        ) {
            (bool success, bytes memory res) = proposal_.recipient.call(
                proposal_.callData
            );

            if (success) {
                emit ProposalAccepted(
                    proposalId,
                    proposal_.votesFor,
                    proposal_.votesAgainst,
                    res
                );
            } else {
                emit ProposalFailed(proposalId);
            }
        } else {
            emit ProposalDeclined(
                proposalId,
                proposal_.votesFor,
                proposal_.votesAgainst
            );
        }

        delete _proposals[proposalId];
    }

    function withdraw(uint256 amount) external {
        if (_users[msg.sender].lastFinishDate > block.timestamp)
            revert ActiveBalance();
        if (_users[msg.sender].balance < amount) revert InvalidAmount();

        _token.transfer(msg.sender, amount);
        _users[msg.sender].balance -= amount;
    }

    function debatingPeriodDuration() external view returns (uint32) {
        return _debatingPeriodDuration;
    }

    function minimumQuorum() external view returns (uint256) {
        return _minimumQuorum;
    }

    function user(address addr) external view returns (UserData memory) {
        return _users[addr];
    }

    function proposal(uint64 proposalId)
        external
        view
        returns (Proposal memory)
    {
        return _proposals[proposalId];
    }

    function proposalsCount() external view returns (uint64) {
        return _proposalCount;
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