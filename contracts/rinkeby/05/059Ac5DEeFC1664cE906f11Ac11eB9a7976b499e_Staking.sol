//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./DAO.sol";

error ownersonly();
error DAOonly();
error entergreatervalue();
error setDAOContractaddress();
error setLPContractaddress();
error setXXXTokenAddress();
error errorCallingFunction();
error stakernonexist();
error frozen();
error norewards();
error minimumstakingtime();
error votinginprogress();


/// @title Staking Contract for Ikhlas Token
/// @author Ikhlas 
/// @notice The contract does not have the Ikhlas Token hardcoded and can be used with other tokens
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.
contract Staking is ReentrancyGuard {
    /// @notice Stakes the ERC20 Token and offers rewards in return
    /// @dev Additional features can be added such as partial unstake and claim; also additional bonus for staking for longer periods
    /// @notice stakersInfo is a struct storing all the stakers information
    /// @notice staker is the address of the user / staker 
    /// @notice stakerIndex is an index based on the address; easy to identify a user when they make multiple stakes or claims
    /// @notice totalAmountStaked is sum of all staked amount (does not include rewards)
    /// @notice totalRewards is sum of all the rewards accumulated
    /// @dev totalRewards value is updated each time calRewards function is called
    /// @notice stakeTime is the block timestamp when staking started
    /// @dev stakeTime gets updated each time there is a change in stake or claim; totalRewards are updated prior to it to ensure accuracy
    struct stakersInfo{
        address staker;
        uint stakerIndex;
        uint totalAmountStaked;
        uint totalRewards;
        uint stakeTime;
    }
    /// @notice StakersInfo is a variable of struct type of stakersInfor
    /// @notice _owner is the address of the contract
    /// @notice _initialTimeStamp is the block TimeStamp at the time of executing the contract
    /// @notice rewardrate is the percentage of reward that will be allocated every step - 10 minutes 
    /// @notice _freezze is boolean that records the freeze state 
    /// @dev _freeze false means that there is no freeze 
    /// @notice targetAddress is the address of the ERC20 Token
    /// @dev The targetAddress needs to be entered in a function below after deploying this contract
    stakersInfo[] StakersInfo;
    address public owner;
    uint _initialTimeStamp;
    uint rewardrate = 3;
    uint public _stakingperiod;
    bool _freeze;
    address public targetAddress;
    address public DAOAddress;
    address public XXXTokenAddress;

    /// @notice addToIndexMap is used to map the staker address to the stakerIndex
    mapping (address => uint256) addToIndexMap; 

    /// @notice staked event is emitted when ever there is an additional stake 
    /// @notice _unstake event is emitted when there is a claim or unstake 
    event staked(address indexed staker_, uint stakerIndex_, uint stakeAmount_, uint stakeTime_);
    event _unstake(address indexed staker, uint stakerIndex, uint withdrawAmount);

    /// @notice Constructor is run only once at the time of deploying the contract
    /// @dev StakersInfo.push is done the first time to avoid errors/issues with index 0 calculation
    constructor(){
        owner = msg.sender;
        _initialTimeStamp = block.timestamp;
        StakersInfo.push();
        _stakingperiod = 1 minutes;
    }

    

    /// @notice allows this contract owner to specify the LP token contract address
    /// @dev can add additional features to limit it to be run 1 time only 
    function setLPContract (address _input) public {
        if((msg.sender != owner))
        revert ownersonly();
        targetAddress = _input;
    }


    function setDAOContract (address _input) public {
        if((msg.sender != owner))
        revert ownersonly();
        DAOAddress = _input;
    }

    function setXXXContract (address _input) public {
        if((msg.sender != owner))
        revert ownersonly();
        XXXTokenAddress = _input;
    }

    /// @notice calculates the staker's totalrewards and updates it
    /// Returns the totalRewards value
    /// @dev This function is internal and cannot be viewed and accessed by end user directly
    /// @dev TotalRewards are calculated and updated; also the block timestamp is updated to current after updating totalRewards
     function calRewards(uint _stakerIndex) internal returns(uint256){
        uint _totalRewards = (StakersInfo[_stakerIndex].totalAmountStaked + StakersInfo[_stakerIndex].totalRewards)*((block.timestamp - StakersInfo[_stakerIndex].stakeTime)/(1 minutes))*rewardrate/100;
        /// @dev if statement added to ensure incase of mathematical error; rewards are not reduced 
        if( _totalRewards > StakersInfo[_stakerIndex].totalRewards){
            StakersInfo[_stakerIndex].totalRewards = _totalRewards;
            StakersInfo[_stakerIndex].stakeTime = block.timestamp;
        }
        return StakersInfo[_stakerIndex].totalRewards;
    }

    /// @notice stake function for a user to add staking
    /// returns true if successful
    /// @dev incase if the staker is staking for the first time then the contract adds an index by going through the if statement
    /// @dev call functions are done to ERC20 token; hence it is essential that setLPContract is sepcifed prior
    /// @dev check why fallback event is not being logged if calling a non function
    function stake(uint _amount) public returns(bool success_){
        if(_amount == 0)
            revert entergreatervalue();
        if(targetAddress == 0x0000000000000000000000000000000000000000)
            revert setLPContractaddress();
        if(DAOAddress == 0x0000000000000000000000000000000000000000)
            revert setDAOContractaddress();
        if(XXXTokenAddress == 0x0000000000000000000000000000000000000000)
            revert setXXXTokenAddress();
    // require (block.timestamp >= _initialTimeStamp + 10 minutes, "Cannot stake within 10 minutes of contract being set up!");
    uint _index = addToIndexMap[msg.sender];
    if(_index == 0){
        (bool success, ) = targetAddress.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), _amount));
        if (!success)
        revert errorCallingFunction();
        StakersInfo.push();
        _index = StakersInfo.length - 1;
        StakersInfo[_index].staker = msg.sender;
        StakersInfo[_index].totalAmountStaked = _amount;
        StakersInfo[_index].stakeTime = block.timestamp;
        addToIndexMap[msg.sender] = _index;
        emit staked(msg.sender, _index, _amount, block.timestamp);
        return true;
    }
    else{
        (bool _success, ) = targetAddress.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), _amount));
        if (!_success)
        revert errorCallingFunction();
        calRewards(_index);
        StakersInfo[_index].totalAmountStaked += _amount;
        emit staked(msg.sender, _index, _amount, block.timestamp);
        return true;
    }
    }

    /// @notice claim function for a user to get the reward tokens
    /// returns true if successful
    /// @dev The totalRewards are calculated prior to transfer and then the the totalRewards are reset to 0
    function claim() public nonReentrant returns (bool success_) {
        uint _index = addToIndexMap[msg.sender];
        if (_index == 0)
        revert stakernonexist();
        if(_freeze == true)
        revert frozen();
        calRewards(_index);
        if (StakersInfo[_index].totalRewards == 0)
        revert norewards();
        (bool success, ) = XXXTokenAddress.call(abi.encodeWithSignature("mint(address,uint256)", msg.sender, StakersInfo[_index].totalRewards));
        if (!success)
        revert errorCallingFunction();
        emit _unstake(msg.sender, _index, StakersInfo[_index].totalRewards);
        StakersInfo[_index].totalRewards = 0;
        return true;
    }

    /// @notice unstake function for a user to remove staked tokens 
    /// returns true if successful
    /// @dev calculates the totalRewards then transfers the totalAmountStaked
    /// @dev It is to be noted that only the staked tokens are sent back; reward tokens will remain as it is - those can be transferred using claim function
   function unstake() public returns (bool success_) {
        uint _index = addToIndexMap[msg.sender];
        if (_index == 0)
        revert stakernonexist();
        if(block.timestamp < StakersInfo[_index].stakeTime + _stakingperiod)
        revert minimumstakingtime();
        if(_freeze == true)
        revert frozen();
        (uint _check) = DAOProject(DAOAddress).unstaking(msg.sender);
        if (_check != 5 && _check != 20) 
        revert votinginprogress();
        calRewards(_index);
        unstake_finish(_index, msg.sender);
        emit _unstake(msg.sender, _index, StakersInfo[_index].totalAmountStaked);
        return true;
   }

   function unstake_finish(uint _index, address _address) private nonReentrant returns (bool){
        uint _balance = StakersInfo[_index].totalAmountStaked;
        (bool success, ) = targetAddress.call(abi.encodeWithSignature("transfer(address,uint256)", _address,_balance));
        if (!success)
        revert errorCallingFunction();
        StakersInfo[_index].totalAmountStaked = 0;
        return true;
   }


    function balance (address _staker) public view returns (uint) {
        uint _index = addToIndexMap[_staker];
        if (_index == 0)
        revert stakernonexist();
        uint _balance = StakersInfo[_index].totalAmountStaked;
        return _balance;
    }


    function stakingperiod(uint _stakingduration) public returns (bool success) {
       if((msg.sender != DAOAddress))
       revert DAOonly();
       _stakingperiod = _stakingduration;
       return true; 
    }


    /// @notice freeze function is an admin only function; accessible by owner only. Freeze limits accesss to claim and unstake function. Staking will remain accessible.
    /// returns true if successful
   function freeze() public returns (bool success){
       if((msg.sender != owner))
       revert ownersonly();
       _freeze = !_freeze;
       return true;
   }

    /// @notice percentageChange function is an admin only function to change the reward percentage per 7 days 
    /// returns true if successful
   function percentageChange(uint256 _newPercentage) public returns (bool success){
       if((msg.sender != owner))
       revert ownersonly();
       rewardrate = _newPercentage;
       return true;
   }
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Staking.sol";

error approvalForDAOreq();
error waitforProposalEnd(uint);
error amountGreaterthanBalance(uint, uint);
error proposalClosed();
error insufficentVotingPower();
error alreadyVoted();
error needtoendProposal(uint);
error waitforProposalEndTime(uint);
error errorCalling(string);
error proposalIDdoesnotexist();
error onlyChairPerson();
error noVotes();
error nostaking();
error onlystakingcontract();
 

contract DAOProject is ReentrancyGuard {
    using Counters for Counters.Counter;

    address public chairPerson;
    address public stakingContract;
    uint public minimumQuorum;
    uint public debatingPeriodDuration;
    uint public totalVotingPower;

    Counters.Counter public proposalID; 

    struct proposal {
        uint id;
        proposalStatus status;
        uint FORvotes;
        uint AGAINSTvotes;
        uint startTime;
        bytes callData;
        address recipient;
        string description;
    }

    struct voter {
        uint votingPower;
        uint endTime;
        uint endingProposalID;
        mapping(uint => bool)voted;
    }

    enum proposalStatus {
        NONE,
        INPROGRESS,
        APPROVED,
        REJECTED
    }

    mapping(uint => proposal) public Proposal;
    mapping(address => voter) public Voter;

    event percentage (uint _percentq, uint _percentfor); 


    constructor (address _chairPerson, address _stakecontract, uint _minimumQuorum, uint _debatingPeriodDuration) {
        chairPerson = _chairPerson;
        stakingContract = _stakecontract;
        minimumQuorum = _minimumQuorum;
        debatingPeriodDuration = _debatingPeriodDuration;
    }


    function unstaking(address _address) public nonReentrant returns (uint){
        if(msg.sender != stakingContract)
            revert onlystakingcontract();
        if(Voter[_address].votingPower == 0)
        return 20;
        if(block.timestamp< Voter[_address].endTime)
            revert waitforProposalEnd (Voter[_address].endingProposalID);
        if(Proposal[Voter[_address].endingProposalID].status == proposalStatus.INPROGRESS)
            revert needtoendProposal(Voter[_address].endingProposalID);
        totalVotingPower -= Voter[_address].votingPower;
        Voter[_address].votingPower = 0;
        return 5;
    }

    function newProposal(bytes calldata _callData, address _recipient, string calldata _description) public {
        if(msg.sender != chairPerson)
            revert onlyChairPerson();
        proposalID.increment();
        Proposal[proposalID.current()] = proposal(
        proposalID.current(),
        proposalStatus.INPROGRESS,
        0,
        0,
        block.timestamp,
        _callData,
        _recipient,
        _description
        );
    }

    function voting(uint _proposalID, bool _votefor) nonReentrant public {
        if(_proposalID > proposalID.current())
            revert proposalIDdoesnotexist();
        if(Proposal[_proposalID].status != proposalStatus.INPROGRESS)
            revert proposalClosed();
        if(Voter[msg.sender].voted[_proposalID])
            revert alreadyVoted();
        
        (uint _balance) = Staking(stakingContract).balance(msg.sender);
        if (_balance == 0)
        revert nostaking();
        if (Voter[msg.sender].votingPower != 0){
            totalVotingPower -= Voter[msg.sender].votingPower;
        }
        Voter[msg.sender].votingPower = _balance;
        totalVotingPower += _balance;

        Voter[msg.sender].endingProposalID = _proposalID;
        Voter[msg.sender].endTime = Proposal[_proposalID].startTime + debatingPeriodDuration;
        Voter[msg.sender].voted[_proposalID] = true;
        if(_votefor)
        Proposal[_proposalID].FORvotes += _balance;
        else{
            Proposal[_proposalID].AGAINSTvotes += _balance;
        }
    }

    function endProposal(uint _proposalID) public {
        if(_proposalID > proposalID.current())
            revert proposalIDdoesnotexist();
        if(Proposal[_proposalID].status != proposalStatus.INPROGRESS)
            revert proposalClosed();
        if(block.timestamp < (Proposal[_proposalID].startTime + debatingPeriodDuration))
            revert waitforProposalEndTime(Proposal[_proposalID].startTime + debatingPeriodDuration);
        if((Proposal[_proposalID].FORvotes + Proposal[_proposalID].AGAINSTvotes) != 0)
        {
        uint percentQ = ((Proposal[_proposalID].FORvotes + Proposal[_proposalID].AGAINSTvotes)*100)/(totalVotingPower);
        uint percentFor = ((Proposal[_proposalID].FORvotes)*100)/(Proposal[_proposalID].FORvotes + Proposal[_proposalID].AGAINSTvotes);
        emit percentage (percentQ, percentFor);
        if((percentQ >= minimumQuorum) && (percentFor > 50)){
            Proposal[_proposalID].status = proposalStatus.APPROVED;
            (bool success, ) = (Proposal[_proposalID].recipient).call(Proposal[_proposalID].callData);
            if(!success)
            revert errorCalling(Proposal[_proposalID].description);
        }
        else
            Proposal[_proposalID].status = proposalStatus.REJECTED;
        }
        else
            Proposal[_proposalID].status = proposalStatus.REJECTED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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