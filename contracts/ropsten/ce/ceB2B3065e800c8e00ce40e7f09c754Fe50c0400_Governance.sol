// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4 <0.9.0;

import "./Context.sol";
import "./IERC20.sol";

contract Governance is Context {
    struct Proposal {
        uint256 id;
        string title;
        string content;
        uint256 agreeCount;
        uint256 defeatCount;
        uint256 created_at;
        uint256 expired_at;
        uint256 agreeWeight;
        uint256 defeatWeight;
        Execution execute;
    }

    struct Vote {
        bool voted;
        uint256 weight;
        bool agreement;
        uint256 created_at;
    }

    struct Execution {
        bool executed;
        bool result;
    }

    Proposal[] _proposals;
    mapping(uint256 => mapping(address => Vote)) _votes;
    // mapping(uint256 => Execution) _executes;
    IERC20 _token;
    uint256 _totalWeight;
    uint256 _limit;

    constructor(address token, uint8 limit) {
        _token = IERC20(token);
        _totalWeight = _token.totalSupply();
        _limit = _totalWeight * limit / 100;
    }

    // ----- MODIFIER ----- //
    modifier onlyDAOTokenHolder() {
        require(_token.balanceOf(_msgSender()) > 0, "caller is not DAO token holder");
        _;
    }

    // ----- EVENTS ----- //
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string title, string content, uint256 expired_at);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool agreement, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId, bool executed);

    // ----- MUTATION FUNCTIONS ----- //
    function createProposal(string memory title, string memory content, uint256 expired_at) external onlyDAOTokenHolder {
        require(!compareStrings(title, ""), "Create: title cannot be empty");
        require(!compareStrings(content, ""), "Create: content cannot be empty");

        Proposal memory newProposal;
        newProposal.id = _proposals.length;
        newProposal.title = title;
        newProposal.content = content;
        newProposal.created_at = block.timestamp;
        newProposal.expired_at = expired_at;
        newProposal.execute.executed = false;
        _proposals.push(newProposal);

        emit ProposalCreated(newProposal.id, _msgSender(), title, content, expired_at);
    }

    function vote(uint256 proposalId, bool agreement) external onlyDAOTokenHolder {
        require(!_votes[proposalId][_msgSender()].voted, "Vote: caller has already voted");
        require(_proposals[proposalId].expired_at > block.timestamp, "Vote: proposal is expired");

        uint256 weight = _token.balanceOf(_msgSender());

        if(agreement) {
            _proposals[proposalId].agreeCount += 1;
            _proposals[proposalId].agreeWeight += weight;
        } else {
            _proposals[proposalId].defeatCount += 1;
            _proposals[proposalId].defeatWeight += weight;
        }

        _votes[proposalId][_msgSender()].voted = true;
        _votes[proposalId][_msgSender()].weight = weight;
        _votes[proposalId][_msgSender()].agreement = agreement;
        _votes[proposalId][_msgSender()].created_at = block.timestamp;

        emit ProposalVoted(proposalId, _msgSender(), agreement, weight);
    }

    function executeProposal(uint256 proposalId) external onlyDAOTokenHolder {
        require(_proposals[proposalId].expired_at < block.timestamp, "Execute: proposal is in progress");
        require(!_proposals[proposalId].execute.executed, "Execute: proposal has already been executed");
        
        bool result;
        if(_proposals[proposalId].agreeWeight > _limit && _proposals[proposalId].agreeWeight > _proposals[proposalId].defeatWeight) {
            result = true;
        } else {
            result = false;
        }
        _proposals[proposalId].execute.result = result;
        _proposals[proposalId].execute.executed = true;

        emit ProposalExecuted(proposalId, result);
    }

    //  ----- INTERNAL FUNCTIONS ----- //
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // ----- VIEWS ----- //
    function executedOf(uint256 proposalId) external view returns (bool) {
        return _proposals[proposalId].execute.executed;
    }

    function getProposals() external view returns (Proposal[] memory) {
        Proposal[] memory proposals = _proposals;
        return proposals;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4 <0.9.0;

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.4 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}