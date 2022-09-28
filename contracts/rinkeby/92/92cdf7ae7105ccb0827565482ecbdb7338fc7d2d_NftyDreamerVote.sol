// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface INftyDreamsContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract NftyDreamerVote is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _nextProposalId;
    uint256[] public validTokens;
    INftyDreamsContract nftyDreamsContract;

    constructor() {
        nftyDreamsContract = INftyDreamsContract(0x36c1f502e1c438710dF22F55cAc00b677F09dFB7);
        validTokens = [1, 2, 3, 4, 5];
    }

    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint256 deadline;
        uint256 maxVotes;
        uint256[] options;
        mapping(address => uint256) voteFor;
        bool countConducted;
        bool passed;
    }
    
    mapping(uint256 => proposal) public Proposals;
    mapping(uint256 => mapping(uint256 => uint256)) private voteStatus;

    event ProposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        uint256[] options,
        address proposer
    );

    event VoteRecorded(address voter, uint256 proposal, uint256 optionId);

    event ProposalCount(uint256 id, bool passed);

    function createProposal(
        string memory _description,
        uint256[] memory _options,
        uint256 _deadline,
        uint256 _maxVotes
    ) public onlyOwner {
        _nextProposalId.increment();
        proposal storage newProposal = Proposals[_nextProposalId.current()];
        newProposal.id = _nextProposalId.current();
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = _deadline;
        newProposal.maxVotes = _maxVotes;
        newProposal.options = _options;

        emit ProposalCreated(
            _nextProposalId.current(),
            _description,
            _maxVotes,
            _options,
            msg.sender
        );
    }

    function voteOnProposal(uint256 _proposalId, uint256 _optionId) public {
        require(Proposals[_proposalId].exists, "This Proposal does not exist");
        require(
            checkVoteEligibility(msg.sender),
            "You can not vote on this Proposal"
        );
        require(
            Proposals[_proposalId].voteFor[msg.sender] == 0,
            "You have already voted on this Proposal"
        );
        require(
            block.number <= Proposals[_proposalId].deadline,
            "The deadline has passed for this Proposal"
        );

        proposal storage p = Proposals[_proposalId];

        p.voteFor[msg.sender] = _optionId;
        voteStatus[_proposalId][_optionId] += 1;

        emit VoteRecorded(msg.sender, _proposalId, _optionId);
    }

    function checkVoteEligibility(address voter) public view returns(bool){
        for(uint i = 0; i < validTokens.length; i++){
            if(nftyDreamsContract.balanceOf(voter, validTokens[i]) >= 1){
                return true;
            }
        }
        return false;
    }

    function getVotes(uint256 _proposalId, uint256 _optionId) public view returns(uint256) {
        require(Proposals[_proposalId].exists, "This Proposal does not exist");
        //require(block.number > Proposals[_proposalId].deadline, "Voting has not concluded");

        return voteStatus[_proposalId][_optionId];
    }

    function addTokenId(uint256 _tokenId) public onlyOwner {
        validTokens.push(_tokenId);
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