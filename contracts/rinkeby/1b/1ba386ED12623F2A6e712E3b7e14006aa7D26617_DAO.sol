//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStaking.sol";


contract DAO {

    struct ProposalInfo{
        uint256 amountOfVotesFor;
        uint256 amountOfVotesAgainst;
        uint256 startTime;
        uint256 lastsUntil;
        address recipient;
        bytes callData;
        string description;
    }

    address public chairPerson;
    address public stakingAddress;
    uint256 public minQuorum;
    uint256 public duration;
    uint256 public proposalId;

    mapping (uint256=>ProposalInfo) public proposal;
    mapping (address=>uint256) public freezeTokensUntil;
    mapping (address => mapping(uint256 => bool)) public isUserVoted;

    event ProposalAdded(bytes callData, address recipient, string description);
    event UserVoted(address user, uint256 proposalId, bool vote);
    event ProposalFinishedSuccessfully(uint256 id);
    event ProposalFailed(uint256 id, string reason);

    modifier onlyChairPerson(){
        require(msg.sender == chairPerson, "Only chair person can add proposal");
        _;
    }
    constructor(address _chairPerson, address _stakingAddress, uint256 _minQuorum, uint256 _duration) {
        chairPerson = _chairPerson;
        stakingAddress = _stakingAddress;
        minQuorum = _minQuorum;
        duration = _duration;
    }

    function addProposal(bytes memory _callData, address _recipient, string memory _description) external onlyChairPerson{
        proposal[proposalId].callData = _callData;
        proposal[proposalId].recipient = _recipient;
        proposal[proposalId].description = _description;
        proposal[proposalId].startTime = block.timestamp;
        proposal[proposalId].lastsUntil = block.timestamp+duration;
        proposalId+=1;
        emit ProposalAdded(_callData, _recipient, _description);
    }

    function vote(uint256 id, bool _vote) external {
        require(proposal[id].startTime != 0, "Proposal with that id doesn't exist");
        require(!isUserVoted[msg.sender][id], "Sender has already voted");
        uint256 amountOfStakedTokens = IStaking(stakingAddress).getAmountofStakedTokens(msg.sender);
        require(amountOfStakedTokens > 0, "There isn't any tokens on sender's staking balance");
        require(proposal[id].lastsUntil > block.timestamp, "Voting time is over");

        if(freezeTokensUntil[msg.sender]<proposal[id].lastsUntil){
            freezeTokensUntil[msg.sender] = proposal[id].lastsUntil;
        }

        _vote ? proposal[id].amountOfVotesFor+=amountOfStakedTokens : proposal[id].amountOfVotesAgainst+=amountOfStakedTokens;
        isUserVoted[msg.sender][id] = true;
        emit UserVoted(msg.sender, id, _vote);
    }

    function finishProposal(uint256 id) external {
        require(proposal[id].startTime != 0, "Proposal with that id doesn't exist");
        require(proposal[id].lastsUntil < block.timestamp, "It's too soon to finish this proposal");

        if (proposal[id].amountOfVotesFor+proposal[id].amountOfVotesAgainst < countMinAmountOfVotes()){
            emit ProposalFailed(id, "Not enough votes");
        }
        else if (proposal[id].amountOfVotesFor>proposal[id].amountOfVotesAgainst){
            bool result = callFunc(proposal[id].recipient, proposal[id].callData);
            if (result){
                emit ProposalFinishedSuccessfully(id);
            }
            else{
                emit ProposalFailed(id, "Error in call func");
            }
        }
        else{
            emit ProposalFailed(id, "The majority of participants vote against");
        }
        delete proposal[proposalId];
    }

    function countMinAmountOfVotes() public view returns(uint256){
        return IERC20(IStaking(stakingAddress).lpToken()).totalSupply()/100*minQuorum;

    }

    function callFunc(address recipient, bytes memory signature) public returns(bool){   
        (bool success, ) = recipient.call(signature);
        return success;
    }

    function getUsersDeposit(address userAdd) external view returns (uint256) {
        return IStaking(stakingAddress).getAmountofStakedTokens(userAdd);
    }

    function getFreezeUntillForUser(address userAdd) external view returns (uint256) {
        return freezeTokensUntil[userAdd];
    }

    function checkIfUserVoted(address userAdd, uint256 propId) external view returns (bool) {
        return isUserVoted[userAdd][propId];
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IStaking {
    function stake(uint256 amount) external;

    function lpToken() external view returns(address);

    function claim() external;

    function unstake() external;
    
    function countReward(address _user) external view returns(uint256);

    function setRewardTime(uint256 newRewardTime) external;

    function setRewardPercent(uint8 newRewardPercent) external;

    function setFreezingTimeForLP(uint256 newFreezingTime) external;

    function getRewardDebt(address _user) external view returns(uint256);

    function getAmountofStakedTokens(address _user) external view returns(uint256);

    function addDaoAddress(address dao) external;

}