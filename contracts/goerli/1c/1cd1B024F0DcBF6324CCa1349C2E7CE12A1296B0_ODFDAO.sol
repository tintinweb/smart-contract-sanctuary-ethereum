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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/access/Ownable.sol";

contract $Ownable is Ownable {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address owner_) Ownable(owner_) {}

    function $_checkOwner() external view {
        super._checkOwner();
    }

    function $_transferOwnership(address newOwner) external {
        super._transferOwnership(newOwner);
    }

    function $_msgSender() external view returns (address ret0) {
        (ret0) = super._msgSender();
    }

    function $_msgData() external view returns (bytes memory ret0) {
        (ret0) = super._msgData();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/interfaces/IODFDao.sol";

contract $IODFDao is IODFDao {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/ODFDao.sol";

contract $ODFDAO is ODFDAO {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address receiver_, address votingToken_) ODFDAO(receiver_, votingToken_) {}

    function $_checkOwner() external view {
        super._checkOwner();
    }

    function $_transferOwnership(address newOwner) external {
        super._transferOwnership(newOwner);
    }

    function $_msgSender() external view returns (address ret0) {
        (ret0) = super._msgSender();
    }

    function $_msgData() external view returns (bytes memory ret0) {
        (ret0) = super._msgData();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address owner_) {
        _transferOwnership(owner_);
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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        require(
            newOwner != address(0),
            'Ownable: new owner is the zero address'
        );
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
pragma solidity ^0.8.17;

interface IODFDao {
    /**
     * @notice Error to revert when an argument is invalid.
     */
    error InvalidArgument();

    /**
     * @notice Error to revert when the proposal is not available to vote.
     * @dev The proposal is not available to vote when the current time is
     * before the start time or after the end time.
     */
    error VoteOver();

    /**
     * @notice Error to revert when the account has already voted.
     */
    error AccountAlreadyVoted();

    /**
     * @notice Error to revert when the account is frozen.
     */
    error AccountIsFrozen();

    /**
     * @notice Error to revert when the proposal is not available to execute.
     * @dev The proposal is not available to execute when the current time is
     * before the end time or it doesn't have enough votes.
     */
    error CannotExecute();

    /**
     * @notice Event to emit when a proposal is created.
     */
    event ProposalCreated(uint256 id, uint256 start, uint256 end, string uri);

    /**
     * @notice Event to emit when a vote is casted.
     */
    event Voted(uint256 id, address account, bool approval, uint256 timestamp);

    /**
     * notice Event to emit when account is frozen.
     */
    event Frozen(address account, bool status);

    /**
     * @notice Event to emit when a proposal is executed.
     */
    event Executed(uint256 id, uint256 timestamp);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './access/Ownable.sol';
import './interfaces/IODFDao.sol';

contract ODFDAO is Ownable, IODFDao {
    using Counters for Counters.Counter;
    Counters.Counter private _proposalCounter;

    /**
     * @notice Save the address of the token to use as voting.
     */
    IERC20 public immutable votingToken;

    /**
     * @notice Start DAO contract and ERC20 used as voting.
     * @param receiver_ Address of the receiver of the contract ownership.
     * @param votingToken_ Address of token to use as voting.
     */
    constructor(address receiver_, address votingToken_) Ownable(receiver_) {
        votingToken = IERC20(votingToken_);
    }

    /**
     * @dev Enum to save the status of a proposal.
     */
    enum ProposalStatus {
        Pending,
        Approved,
        Rejected
    }

    /**
     * @dev Struct to save the data of a proposal.
     */
    struct Proposal {
        uint256 start;
        uint256 end;
        uint256 approvals;
        uint256 rejections;
        ProposalStatus status;
        uint256 minimumVotes;
        string uri;
        mapping(address => bool) voted;
    }

    /**
     * @dev Struct to save the data of a proposal as return value.
     */
    struct ProposalView {
        uint256 start;
        uint256 end;
        uint256 approvals;
        uint256 rejections;
        ProposalStatus status;
        uint256 minimumVotes;
        string uri;
    }

    /**
     * @notice Mapping to save the proposals.
     * @dev The id is the key of the mapping.
     * ID => Proposal
     */
    mapping(uint256 => Proposal) public proposals;

    /**
     * @dev mapping to save the frozen accounts.
     * @dev The address is the key of the mapping.
     * address => status
     */
    mapping(address => bool) private _frozen;

    /**
     * @dev modifier to check if the account is frozen.
     */
    modifier notFrozen() {
        if (_frozen[msg.sender]) revert AccountIsFrozen();
        _;
    }

    /**
     * @notice Create a proposal.
     * @param start_ Start date of the proposal.
     * @param end_ End date of the proposal.
     * @param minimumVotes_ Minimum votes required to take in consideration the proposal.
     * @param uri_ URI of the proposal.
     */
    function createProposal(
        uint256 start_,
        uint256 end_,
        uint256 minimumVotes_,
        string memory uri_
    ) external notFrozen {
        if (start_ > end_) revert InvalidArgument();
        if (start_ < block.timestamp) revert InvalidArgument();
        if (bytes(uri_).length == 0) revert InvalidArgument();

        _proposalCounter.increment();
        uint256 id = _proposalCounter.current();

        proposals[id].start = start_;
        proposals[id].end = end_;
        proposals[id].uri = uri_;
        proposals[id].minimumVotes = minimumVotes_;

        emit ProposalCreated(id, start_, end_, uri_);
    }

    /**
     * @notice Vote a proposal.
     * @param id_ ID of the proposal.
     * @param approval_ True if the vote is approval, false if it is rejection.
     */
    function vote(uint256 id_, bool approval_) external notFrozen {
        votingToken.transferFrom(msg.sender, address(this), 1);
        Proposal storage proposal = proposals[id_];
        if (proposal.status != ProposalStatus.Pending) revert VoteOver();
        if (proposal.start > block.timestamp) revert VoteOver();
        if (proposal.end < block.timestamp) revert VoteOver();
        if (proposal.voted[msg.sender]) revert AccountAlreadyVoted();

        proposal.voted[msg.sender] = true;

        if (approval_) {
            proposal.approvals++;
        } else {
            proposal.rejections++;
        }

        emit Voted(id_, msg.sender, approval_, block.timestamp);
    }

    /**
     * @notice Freeze an account.
     * @param account_ Address of the account to freeze.
     * @param status_ True to freeze the account, false to unfreeze.
     */
    function setFrozen(address account_, bool status_) external onlyOwner {
        _frozen[account_] = status_;
        emit Frozen(account_, status_);
    }

    /**
     * @notice Execute a proposal.
     * @param id_ ID of the proposal.
     */
    function execute(uint256 id_) external {
        Proposal storage proposal = proposals[id_];
        if (proposal.status != ProposalStatus.Pending) revert CannotExecute();
        if (proposal.end > block.timestamp) revert CannotExecute();
        uint256 approvals = proposal.approvals;
        uint256 rejections = proposal.rejections;
        if ((approvals + rejections) < proposal.minimumVotes)
            revert CannotExecute();

        if (approvals > rejections) {
            proposal.status = ProposalStatus.Approved;
        } else {
            proposal.status = ProposalStatus.Rejected;
        }

        // Execute proposal

        emit Executed(id_, block.timestamp);
    }

    function getProposals() external view returns (ProposalView[] memory) {
        uint256 currentId = _proposalCounter.current();
        if (currentId == 0) return new ProposalView[](0);
        ProposalView[] memory result = new ProposalView[](currentId);
        for (uint256 i = currentId; i > 0; ) {
            result[i - 1] = ProposalView(
                proposals[i].start,
                proposals[i].end,
                proposals[i].approvals,
                proposals[i].rejections,
                proposals[i].status,
                proposals[i].minimumVotes,
                proposals[i].uri
            );
            unchecked {
                i--;
            }
        }
        return result;
    }
}