// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Params.sol";
import "./interfaces/IValidators.sol";
import "./Admin.sol";

contract Proposal is Params, Admin, IProposal {
    // How long a proposal will exist
    uint256 public proposalLastingPeriod;

    uint256 public proposalEffectivePeriod;

    // record
    // mapping(address => bool) public pass;
    mapping(bytes32 => bool) public pass;

    struct ProposalInfo {
        // who propose this proposal
        address proposer;
        // propose who to be a validator
        address dst;
        // optional detail info of proposal
        string details;
        // time create proposal
        uint256 createTime;
        //
        // vote info
        //
        // number agree this proposal
        uint16 agree;
        // number reject this proposal
        uint16 reject;
        // means you can get proposal of current vote.
        bool resultExist;
    }

    struct VoteInfo {
        address voter;
        uint256 voteTime;
        bool auth;
    }

    //  candiate address => the id of the latest proposal for the candidate
    mapping(address => bytes32) public latest;
    //  proposal id => proposalInfo
    mapping(bytes32 => ProposalInfo) public proposals;
    mapping(address => mapping(bytes32 => VoteInfo)) public votes;

    event LogCreateProposal(
        bytes32 indexed id,
        address indexed proposer,
        address indexed dst,
        uint256 time
    );
    event LogVote(
        bytes32 indexed id,
        address indexed voter,
        bool auth,
        uint256 time
    );
    event LogPassProposal(
        bytes32 indexed id,
        address indexed dst,
        uint256 time
    );
    event LogRejectProposal(
        bytes32 indexed id,
        address indexed dst,
        uint256 time
    );
    event LogSetUnpassed(address indexed val, bytes32 id, uint256 time);

    modifier onlyValidator() {
        // FIXME: is candidate?
        require(
            VALIDATOR_CONTRACT.isActiveValidator(msg.sender),
            "Validator only"
        );
        _;
    }

    function initialize(
        address _admin,
        address _validatorsContract,
        address _punishContract,
        address _proposalContract,
        address _reservePool,
        uint256 _epoch
    ) external initializer {
        _Admin_Init(_admin);
        _setAddressesAndEpoch(
            _validatorsContract,
            _punishContract,
            _proposalContract,
            _reservePool,
            _epoch
        );
        proposalLastingPeriod = 7 days;
        proposalEffectivePeriod = 30 days;
    }

    function createProposal(address dst, string calldata details)
        external
        onlyAdmin
        returns (bytes32)
    {
        // generate proposal id
        bytes32 id = keccak256(
            abi.encodePacked(msg.sender, dst, details, block.timestamp)
        );
        require(bytes(details).length <= 3000, "Details too long");
        require(proposals[id].createTime == 0, "Proposal already exists");

        ProposalInfo memory proposal;
        proposal.proposer = msg.sender;
        proposal.dst = dst;
        proposal.details = details;
        proposal.createTime = block.timestamp;

        proposals[id] = proposal;
        latest[dst] = id;

        emit LogCreateProposal(id, msg.sender, dst, block.timestamp);
        return id;
    }

    function isProposalPassed(address val, bytes32 id)
        external
        view
        override
        returns (bool)
    {
        require(latest[val] == id, "not matched");
        if (
            block.timestamp >
            proposals[id].createTime +
                proposalLastingPeriod +
                proposalEffectivePeriod
        ) {
            return false;
        } else {
            return pass[id];
        }
    }

    function getLatestProposalId(address val) external view returns (bytes32) {
        return latest[val];
    }

    function voteProposal(bytes32 id, bool auth)
        external
        onlyValidator
        returns (bool)
    {
        require(proposals[id].createTime != 0, "Proposal not exist");
        require(
            votes[msg.sender][id].voteTime == 0,
            "You can't vote for a proposal twice"
        );
        require(
            block.timestamp < proposals[id].createTime + proposalLastingPeriod,
            "Proposal expired"
        );

        votes[msg.sender][id].voteTime = block.timestamp;
        votes[msg.sender][id].voter = msg.sender;
        votes[msg.sender][id].auth = auth;
        emit LogVote(id, msg.sender, auth, block.timestamp);

        // update dst status if proposal is passed
        if (auth) {
            proposals[id].agree = proposals[id].agree + 1;
        } else {
            proposals[id].reject = proposals[id].reject + 1;
        }

        if (pass[id] || proposals[id].resultExist) {
            // do nothing if dst already passed or rejected.
            return true;
        }

        if (
            proposals[id].agree >=
            VALIDATOR_CONTRACT.getActiveValidators().length / 2 + 1
        ) {
            pass[id] = true;
            proposals[id].resultExist = true;

            emit LogPassProposal(id, proposals[id].dst, block.timestamp);

            return true;
        }

        if (
            proposals[id].reject >=
            VALIDATOR_CONTRACT.getActiveValidators().length / 2 + 1
        ) {
            pass[id] = false;
            proposals[id].resultExist = true;
            emit LogRejectProposal(id, proposals[id].dst, block.timestamp);
        }

        return true;
    }

    function setUnpassed(address val, bytes32 id)
        external
        onlyValidatorsContract
        returns (bool)
    {
        // set validator unpass
        pass[id] = false;

        emit LogSetUnpassed(val, id, block.timestamp);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./interfaces/IValidators.sol";
import "./interfaces/IPunish.sol";
import "./interfaces/IProposal.sol";
import "./interfaces/IReservePool.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
 
contract Params is Initializable {

    // System contracts addresses 
    IValidators public  VALIDATOR_CONTRACT; // solhint-disable var-name-mixedcase
    IPunish public  PUBLISH_CONTRACT;       // solhint-disable var-name-mixedcase
    IProposal public  PROPOSAL_CONTRACT;    // solhint-disable var-name-mixedcase
    IReservePool public RESERVEPOOL_CONTRACT; // solhint-disable var-name-mixedcase
    uint256 public EPOCH; // solhint-disable var-name-mixedcase

    // System params
    uint16 public constant MAX_VALIDATORS = 29;

    function _onlyMiner() private view {
        require(msg.sender == block.coinbase, "Miner only");
    }
    

    modifier onlyMiner() {
        _onlyMiner();
        _;
    }
    function _onlyPunishContract() private view {
        require(msg.sender == address(PUBLISH_CONTRACT), "Punish contract only");
    }

    modifier onlyPunishContract() {
        _onlyPunishContract();
        _;
    }
    

    modifier onlyBlockEpoch {
        require(block.number % EPOCH == 0, "Block epoch only");
        _;
    }

    modifier onlyValidatorsContract() {
        require(msg.sender == address(VALIDATOR_CONTRACT), "Validators contract only");
        _;

    }

    function _setAddressesAndEpoch(
            address _validatorsContract,
            address _punishContract,
            address _proposalContract,
            address _reservePool,
            uint256 epoch
    ) internal initializer{
        VALIDATOR_CONTRACT = IValidators(payable(_validatorsContract));
        PUBLISH_CONTRACT = IPunish(payable(_punishContract));
        PROPOSAL_CONTRACT = IProposal(payable(_proposalContract));
        RESERVEPOOL_CONTRACT = IReservePool(payable(_reservePool));
        EPOCH = epoch;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


interface IValidators {


    // Info of each pool.
    struct PoolInfo {
        address validator;   // Address of validator.
        address manager; 
        uint256 selfBallots;      // The validator's Margin in ballots
        uint256 selfBallotsRewardsDebt;  // The validator's reward debt corresponding to selfBallots 
        uint256 feeShares;   // The commission rate in 1/10000 
        uint256 pendingFee;  // The pending commission fee of the validator 
        uint256 feeDebt;     // The validators's commission fee debt, i.e, commission fees already withdrawn 
        uint256 lastRewardBlock;   // Last block number that the validator is rewarded
        uint256 feeSettLockingEndTime;  // feeShares can not be changed before feeSettLockingEndTime 
        uint256 suppliedBallots; // Total ballots voted to this validator 
        uint256 accRewardPerShare; // Accumulated KCSs per share, times 1e12.
        uint256 voterNumber; // The number of votes of the validator 
        uint256 electedNumber; // The number of times the validator is rewarded.
        bool enabled;    
    }

    // The detailed information of a validator 
    struct Description {
        string website;
        string email;
        string details;
    }

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many ballot tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
    }


    // Info of each pool.
    struct VotingData {
        address validator;          //  The address of the validator 
        uint256 validatorBallot;    //  The total ballots of the validator 
        uint256 feeShares;          //  The commission rate of the validator in 1/10000
        uint256 ballot;             //  The user's ballots in this validator 
        uint256 pendingReward;          // The user's pending reward 
        uint256 revokingBallot;         // The user's revoking ballots 
        uint256 revokeLockingEndTime;   // The user can withdraw KSCs corresponding to revokingBallot after revokeLockingEndTime
    }

    // The Revoking info of a user's ballots
    struct RevokingInfo {
        uint256 amount; // The amount of ballots that user is revoking 
        uint256 lockingEndTime; // The user can withdraw his/her revoking ballots after lockingEndTime
    }

    enum Operation {Distributed, UpdatedValidators}

    function punish(address validator, bool remove) external; 


  
    // @dev This can only be called by the miner from the KCC node. 
    function distributeBlockReward() external payable;
    
    function updateActiveValidatorSet(address[] calldata newSet)  external;

    function getTopValidators()  external view returns (address[] memory); 

    function isActiveValidator(address val) external view returns (bool);

    function getActiveValidators() external view returns (address[] memory);

    function getPoolenabled(address val) external view returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";

contract Admin is Initializable {
    address public admin;

    // solhint-disable func-name-mixedcase
    function _Admin_Init(address _admin) internal initializer {
        admin = _admin;
    }

    function _onlyAdmin() private view {
        require(msg.sender == admin, "must be admin");
    }

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    function changeAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPunish {
    function punish(address _val) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


interface IProposal {

    function isProposalPassed(address val, bytes32 id) external view returns(bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IReservePool {
    function withdrawBlockReward() external returns (uint256);
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}