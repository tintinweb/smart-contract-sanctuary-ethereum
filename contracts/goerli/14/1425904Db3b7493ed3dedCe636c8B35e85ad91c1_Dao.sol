// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/ierc20.sol";
import "./interfaces/IDao.sol";

contract Dao is IDao {

    using Counters for Counters.Counter;

    address public chairPerson;
    address public voteToken;
    uint public minimumQuorumBP;
    uint public debatingPeriodDuration;
    uint public totalSupply;

    Counters.Counter private proposalId;

    mapping(address => uint) deposits;
    mapping(uint => Proposal) public proposals;
    mapping(address => uint) public tokenFreeze;

    struct Proposal {
        bytes callData;
        address recipient;
        string description;
        mapping(address => mapping(Answer => uint)) votes;

        uint totalYes;
        uint totalNo;
        uint totalVotes;
        uint startDate;
        uint endDate;

        Counters.Counter totalVoters;
    }

    constructor(
        address _chairPerson,
        address _voteToken,
        uint _minimumQuorumBP, 
        uint _debatingPeriodDuration
    ) {
        chairPerson = _chairPerson;
        voteToken = _voteToken;
        minimumQuorumBP = _minimumQuorumBP;
        debatingPeriodDuration = _debatingPeriodDuration;
    }

    modifier onlyDao() {
        if (address(this) != msg.sender) {
            revert OnlyDaoCanCallTheMethod();
        }
        _;
    }

    function deposit(uint _amount) external {
        IERC20(voteToken).transferFrom(msg.sender, address(this), _amount);
        deposits[msg.sender] += _amount;
        totalSupply += _amount;
        emit Deposit(msg.sender, _amount, deposits[msg.sender], totalSupply);
    }

    function addProposal(
        bytes calldata _callData, address _recipient, string calldata _description
    )
        external 
    {
        if (msg.sender != chairPerson) {
            revert YouAreNotTheChairMan();
        }

        uint _proposalId = proposalId.current();

        Proposal storage proposal = proposals[_proposalId];
        proposal.callData = _callData;
        proposal.recipient =  _recipient;
        proposal.description = _description;
        proposal.startDate = block.timestamp;
        proposal.endDate = block.timestamp + debatingPeriodDuration;


        proposalId.increment();
        emit ProposalAdded(_callData, _proposalId, _recipient, _description);
    }

    function vote(uint _proposalId, bool _answer) external {
        Answer answer;
        Proposal storage proposal = proposals[_proposalId];
        bool alreadyVoted;

        if (proposal.votes[msg.sender][Answer.No] > 0) {
            alreadyVoted = true;
            proposal.totalVotes -= proposal.votes[msg.sender][Answer.No];
            proposal.totalNo -= proposal.votes[msg.sender][Answer.No];
            proposal.votes[msg.sender][Answer.No] = 0;
        }
        if (proposal.votes[msg.sender][Answer.Yes] > 0) {
            alreadyVoted = true;
            proposal.totalVotes -= proposal.votes[msg.sender][Answer.Yes];
            proposal.totalYes -= proposal.votes[msg.sender][Answer.Yes];
            proposal.votes[msg.sender][Answer.Yes] = 0;
        }

        uint totalVotes = deposits[msg.sender];

        if (_answer) {
            answer = Answer.Yes;
            proposal.totalYes += totalVotes;
        } else {
            answer = Answer.No;
            proposal.totalNo  += totalVotes;
        }

        proposal.votes[msg.sender][answer] = totalVotes;
        proposal.totalVotes += totalVotes;

        if (alreadyVoted != true) {
            proposal.totalVoters.increment();
        }

        tokenFreeze[msg.sender] = block.timestamp + debatingPeriodDuration;
        
        emit VoteAdded(_proposalId, alreadyVoted, uint(answer), totalVotes);
    }

    function finish(uint _proposalId) external {

        if (proposals[_proposalId].endDate > block.timestamp) {
            revert ProposalDebatingPeriodDurationNotPass();
        }
        
        if (proposals[_proposalId].totalVotes < (totalSupply * minimumQuorumBP / 10000)) {
            revert ProposalDoesNotGetMinimumQuorum(
                {_totalVotes: proposals[_proposalId].totalVotes}
            );
        }

        if (proposals[_proposalId].totalYes > proposals[_proposalId].totalNo) {
            (bool success, ) = proposals[_proposalId].recipient.call{value: 0}(
                proposals[_proposalId].callData
            );

            if (success) {
                emit ProposalSuccess(
                    proposals[_proposalId].totalYes,
                    proposals[_proposalId].totalNo
                );
            } else {
                emit ProposalFail(
                    proposals[_proposalId].totalYes,
                    proposals[_proposalId].totalNo
                );
            }

        } else {
            emit ProposalFail(
                proposals[_proposalId].totalYes,
                proposals[_proposalId].totalNo
            );
        }
    }

    function withdrawal(uint _amount) external {
        if (block.timestamp > tokenFreeze[msg.sender]) {
            IERC20(voteToken).transfer(msg.sender, _amount);
            emit Withdrawal(msg.sender, _amount);
        } else {
            revert YourTokensStillFreeze();
        }
    }

    function changeParam (uint _percent, uint _days) external onlyDao {
        minimumQuorumBP = _percent;
        debatingPeriodDuration = _days * 24 * 60 * 60;
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

interface IERC20 {

    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // Views funcs
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);

    // Funcs
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function mint(address _to, uint256 _amount) external;
    function burn(uint256 _amount) external;
    function burnFrom(address _from, uint256 _amount) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDao {

    enum Answer{
        No,
        Yes
    }

    /// The caller is not the ChairMan
    error YouAreNotTheChairMan();
    /// Your tokens are still involved to voting
    error YourTokensStillFreeze();
    /// Proposal doen`t get minimum quorum
    error ProposalDoesNotGetMinimumQuorum(uint _totalVotes);
    /// Proposal debating period duration is not pass
    error ProposalDebatingPeriodDurationNotPass();
    /// Only DAO can call the method
    error OnlyDaoCanCallTheMethod();

    event Deposit(address _from, uint _amount, uint _total, uint _totalSupply);
    event ProposalAdded(bytes _callData, uint _id, address _recepient, string _description);
    event Call();
    event VoteAdded(uint _proposalId, bool revote, uint _answer, uint votes);
    event Withdrawal(address _to, uint _amount);
    event ProposalFail(uint _totalYes, uint _totalNo);
    event ProposalSuccess(uint _totalYes, uint _totalNo);
}