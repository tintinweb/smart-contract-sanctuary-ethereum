// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStaking.sol";
import "./IDAO.sol";

contract DAO is IDAO {

    uint64 public minimumQuorum;
    uint64 public debatingPeriodDuration;
    address public chairPerson;
    address public stakingAddress;

    uint256 public proposalsLength;
    //proposal id => Proposal 
    //id start from 1
    mapping(uint256 => Proposal) _proposals;
    mapping(address => Voter) _voters;

    struct Proposal {
        uint64 endDate;
        bool finished;
        uint128 countVoteDisagree;
        uint128 countVoteAgree;
        address recipient;
        bytes callData;
        //voter address => isVoted
        mapping(address => bool) votedProposals;
    }

    struct Voter {
        uint256 lengthVotedProposal;
        // voteId => proposalId
        mapping(uint256 => uint256) votedProposalIds;
    }

    constructor(address chairPerson_, uint64 minimumQuorum_, uint64 debatingPeriodDuration_) {
        chairPerson = chairPerson_;
        minimumQuorum = minimumQuorum_;
        debatingPeriodDuration = debatingPeriodDuration_;
    }

    modifier onlyChairPerson() {
        require(msg.sender == chairPerson, "DAO: Only chair person");
        _;
    }

    modifier proposalMustBeCreated(uint256 proposalId) {
        require(proposalId > 0 && proposalId <= proposalsLength, "DAO:proposal hasn't been created");
        _;
    }

    function proposal(uint256 proposalId) public view proposalMustBeCreated(proposalId) returns(
        uint64 endDate,
        uint128 countVoteAgree,
        uint128 countVoteDisagree,
        bool finished,
        address recipient,
        bytes memory callData
    ) {
        return (
        _proposals[proposalId].endDate,
        _proposals[proposalId].countVoteAgree,
        _proposals[proposalId].countVoteDisagree,
        _proposals[proposalId].finished,
        _proposals[proposalId].recipient,
        _proposals[proposalId].callData
       );
    }

    function lengthVotedProposal(address voterAddress) public view returns(uint256 lengthVotedProposal) {
        return  _voters[voterAddress].lengthVotedProposal;
    }

    function setStakingAddress(address newStaking) external virtual override onlyChairPerson {
        stakingAddress = newStaking;
    }

    function allVotesFinished(address voterAddress) public virtual override returns(bool) {

        Voter storage currentVoter =  _voters[voterAddress];

        for(uint256 voteId = 0; voteId < currentVoter.lengthVotedProposal; voteId++) {
            uint256 proposalId = _voters[voterAddress].votedProposalIds[voteId];
            if(!_proposals[proposalId].finished) {
                return false;
            }
        }

        currentVoter.lengthVotedProposal = 0;
        return true;
    }

    function addProposal(bytes memory callData, address recipient) external onlyChairPerson() {
        proposalsLength++;
        uint256 curentVoteId = proposalsLength;
        uint64 currentTime = uint64(block.timestamp);
        Proposal storage currentProposal = _proposals[curentVoteId];
        currentProposal.callData = callData;
        currentProposal.recipient = recipient;
        currentProposal.endDate = currentTime + debatingPeriodDuration;
    }

    function vote(uint256 proposalId, bool agree) external proposalMustBeCreated(proposalId) {
        address sender = msg.sender;

        Proposal storage currentProposal = _proposals[proposalId];

        require(!currentProposal.votedProposals[sender], "DAO: has voted for this proposal");

        uint64 currentTime = uint64(block.timestamp);
        require(currentTime < currentProposal.endDate, "DAO: time voting has ended");

        uint128 deposit = IStaking(stakingAddress).getLockedTokenAmount(sender);
        require(deposit > 0, "DAO:stake must be greater than 0");

        if(agree) {
            currentProposal.countVoteAgree += deposit;
        } else {
            currentProposal.countVoteDisagree += deposit;
        }

        currentProposal.votedProposals[sender] = true;

        Voter storage currentVoter = _voters[sender];

        currentVoter.votedProposalIds[currentVoter.lengthVotedProposal] = proposalId;
        currentVoter.lengthVotedProposal++;
    }

    function finishProposal(uint128 proposalId) external proposalMustBeCreated(proposalId) {
        Proposal storage currentProposal = _proposals[proposalId];
        require(!currentProposal.finished, "DAO: already finished");
        uint64 currentTime = uint64(block.timestamp);
        require(currentTime >= currentProposal.endDate, "DAO: time voting has not ended");

        currentProposal.finished = true;
        if(
            ((currentProposal.countVoteAgree + currentProposal.countVoteDisagree) >= minimumQuorum) && 
            currentProposal.countVoteAgree > currentProposal.countVoteDisagree
        ) {
            (bool success, ) = currentProposal.recipient.call{value:0 } (currentProposal.callData);
            require(success, "ERROR call function");
        }
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
pragma solidity >=0.7.0 <0.9.0;

interface IStaking {
    event Staked(address stakeHoldersAddress, uint256 amount, uint64 timeStartStake);
    event Unstaked(address stakeHoldersAddress, uint256 amount, uint64 unstakeTime);
    event Claimed(address stakeHoldersAddress, uint256 amount);

    event RewardCircleTimerUpdated(uint256 amount);
    event LockTimeUpdated(uint64 amount);
    event RewardPercentageUpdated(uint8 amount);

    function getLockedTokenAmount(address accountAddress) external view returns(uint128);
    function getCurrentSaveReward(address accountAddress) external view returns(uint64);
    function getTimeStartStake(address accountAddress) external view returns(uint64);
    
    function setDAO(address newDAOAddress) external;

    function stake(uint128 amount) external;
    function claim() external;
    function unstake() external;
    function setLockTime(uint64 newLockTime) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IDAO {
    function allVotesFinished(address voterAddress) external returns(bool);
    function setStakingAddress(address newStaking) external;
}