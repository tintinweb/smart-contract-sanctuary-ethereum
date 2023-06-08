// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SwisscheeseVoting is Ownable, ReentrancyGuard {
    event ProposalCreated(
        uint256 indexed proposalId,
        string title,
        uint256 optionCount,
        uint256 minTokensRequired,
        uint256 startTime,
        uint256 endTime
    );

    event ProposalStateChanged(uint256 indexed proposalId, bool enabled);

    event VoteParticipated(
        uint256 indexed proposalId,
        address indexed voter,
        uint256 voteOptionId
    );

    event FundsWithdrawn(
        address indexed toAddress,
        address indexed currencyAddress,
        uint256 amount
    );

    address public swctAddress;

    struct VoteOption {
        string content;
        address[] voters;
    }

    struct Proposal {
        string title;
        bytes descriptionHash;
        uint256 optionCount;
        uint256 minTokensRequired;
        uint256 startTime;
        uint256 endTime;
        bool enabled;
    }

    mapping(uint256 => mapping(uint256 => VoteOption)) public voteOptions;

    mapping(uint256 => address) public proposalCreators;

    mapping(uint256 => mapping(address => bool)) alreadyVoted;

    uint256 public proposalCount = 0;

    mapping(uint256 => Proposal) public proposals;

    bool public createProposalEnabled;

    uint256 public createProposalFee = 0;

    constructor(address initialSwctAddress, bool initialCreateProposalEnabled) {
        swctAddress = initialSwctAddress;
        createProposalEnabled = initialCreateProposalEnabled;
    }

    function setCreateProposalFee(uint256 fee) external onlyOwner {
        createProposalFee = fee;
    }

    function toggleCreateProposalEnabled(bool enabled) external onlyOwner {
        require(
            createProposalEnabled != enabled,
            "SwisscheeseVoting: already in desired state"
        );
        createProposalEnabled = enabled;
    }

    modifier createProposalIsEnabled() {
        require(
            msg.sender == owner() || createProposalEnabled,
            "SwisscheeseVoting: create proposal is not enabled"
        );
        _;
    }

    modifier createProposalFeeProvided() {
        require(
            msg.sender == owner() || msg.value >= createProposalFee,
            "SwisscheeseVoting: create proposal fee is not provided"
        );
        _;
    }

    function createProposal(
        Proposal calldata proposalData,
        string[] calldata voteOptionsData
    )
        external
        payable
        nonReentrant
        createProposalIsEnabled
        createProposalFeeProvided
    {
        require(
            proposalData.optionCount == voteOptionsData.length,
            "SwisscheeseVoting: option count mismatch"
        );
        proposals[proposalCount] = proposalData;
        proposalCreators[proposalCount] = msg.sender;
        for (uint256 i = 0; i < voteOptionsData.length; i++) {
            voteOptions[proposalCount][i].content = voteOptionsData[i];
        }
        ++proposalCount;
        emit ProposalCreated(
            proposalCount - 1,
            proposalData.title,
            proposalData.optionCount,
            proposalData.minTokensRequired,
            proposalData.startTime,
            proposalData.endTime
        );
    }

    modifier validProposalId(uint256 proposalId) {
        require(
            proposalId < proposalCount,
            "SwisscheeseVoting: invalid proposal id"
        );
        _;
    }

    function toggleProposalActiveState(
        uint256 proposalId,
        bool enabled
    ) external onlyOwner validProposalId(proposalId) {
        require(
            proposals[proposalId].enabled != enabled,
            "SwisscheeseVoting: proposal already in desired state"
        );
        proposals[proposalId].enabled = enabled;
        emit ProposalStateChanged(proposalId, enabled);
    }

    function vote(
        uint256 proposalId,
        uint256 voteOptionId
    ) external payable nonReentrant validProposalId(proposalId) {
        require(
            proposals[proposalId].enabled,
            "SwisscheeseVoting: proposal is not enabled"
        );
        require(
            proposals[proposalId].startTime <= block.timestamp,
            "SwisscheeseVoting: voting has not started"
        );
        require(
            proposals[proposalId].endTime >= block.timestamp,
            "SwisscheeseVoting: voting has ended"
        );
        require(
            !alreadyVoted[proposalId][msg.sender],
            "SwisscheeseVoting: already voted"
        );

        IERC20 token = IERC20(swctAddress);
        require(
            token.balanceOf(msg.sender) >=
                proposals[proposalId].minTokensRequired,
            "SwisscheeseVoting: insufficient tokens"
        );

        alreadyVoted[proposalId][msg.sender] = true;
        voteOptions[proposalId][voteOptionId].voters.push(msg.sender);
        emit VoteParticipated(proposalId, msg.sender, voteOptionId);
    }

    struct VoteOptionResult {
        string content;
        uint256 voteCount;
    }

    struct VoteResult {
        Proposal proposal;
        VoteOptionResult[] options;
        uint256 totalVoteCount;
    }

    function getVoteDetails(
        uint256 proposalId
    )
        external
        view
        validProposalId(proposalId)
        returns (VoteResult memory result)
    {
        Proposal memory proposal = proposals[proposalId];
        result.proposal = proposal;
        uint256 optionCount = proposal.optionCount;
        result.options = new VoteOptionResult[](optionCount);
        for (uint256 i = 0; i < optionCount; i++) {
            VoteOption memory option = voteOptions[proposalId][i];
            uint256 voteCount = option.voters.length;
            result.totalVoteCount += voteCount;
            result.options[i].content = option.content;
            result.options[i].voteCount = voteCount;
        }
    }

    function getVoterList(
        uint256 proposalId,
        uint256 voteOptionId
    )
        external
        view
        validProposalId(proposalId)
        returns (address[] memory result)
    {
        require(
            proposals[proposalId].optionCount > voteOptionId,
            "SwisscheeseVoting: invalid vote option id"
        );
        result = voteOptions[proposalId][voteOptionId].voters;
    }

    function withdrawFunds(
        address currencyAddress,
        uint256 amount,
        address payable toAddress
    ) external nonReentrant onlyOwner {
        if (currencyAddress == address(0)) {
            // Native Token
            require(
                amount <= address(this).balance,
                "Not enough supply of Native Token"
            );
            payable(toAddress).transfer(amount);
        } else {
            // ERC20 Token
            require(
                IERC20(currencyAddress).transfer(toAddress, amount),
                "SwisscheeseVoting: transfer failed"
            );
        }
        emit FundsWithdrawn(toAddress, currencyAddress, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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