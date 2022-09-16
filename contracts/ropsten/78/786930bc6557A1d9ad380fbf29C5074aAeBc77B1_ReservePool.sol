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

import "./Params.sol";
import "./interfaces/IReservePool.sol";
import "./Admin.sol";

contract ReservePool is Params, Admin, IReservePool {
    enum State {
        DISABLED,
        ENABLED
    }

    // The Block Reward for each block
    uint256 public blockRewardAmount;
    // The maximum block reward amount
    uint256 public constant MAX_BLOCK_REWARD_AMOUNT = 100 ether;
    // Has block reward already withdrawn from this block?
    mapping(uint256 => uint256) internal _rewardWithdrawnRecords;

    // Events

    // Withdraw from reservePool
    event Withdraw(address indexed actor, uint256 amount);

    // Deposit to reservePool
    event Deposit(address indexed actor, uint256 amount);

    constructor() public {
        admin = msg.sender;
    }

    // The state of the reservePool:
    //  - DISABLED: no egc can be withrawn from the reservePool
    //  - ENABLED: egc can be withdrawn from the reservePool
    State public state;

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
        state = State.ENABLED; // enabled after initialized
    }

    // Withdraw Block Reward from ReservePool
    // This method can only be called once per block and can only be called by ValidatorsContract.
    //
    //  @returns:  the amount withdrawn from ReservePool and received by msg.sender
    //
    function withdrawBlockReward()
        external
        override
        onlyValidatorsContract
        returns (uint256)
    {
        require(
            _rewardWithdrawnRecords[block.number] == 0,
            "multiple withdrawals in a single block"
        );

        if (state != State.ENABLED) {
            // reservePool not enabled
            return 0;
        }

        uint256 amount;

        if (address(this).balance > blockRewardAmount) {
            amount = blockRewardAmount;
        } else {
            amount = address(this).balance;
        }

        _rewardWithdrawnRecords[block.number] = 1;

        // solhint-disable avoid-low-level-calls
        (bool success, ) = msg.sender.call{value: amount}(new bytes(0));
        require(success, "ReservePool: egc transfer failed");

        emit Withdraw(msg.sender, amount);

        return amount;
    }

    // Set the state of reservePool:
    //   @params newState
    function setState(State newState) external onlyAdmin {
        require(
            newState == State.DISABLED || newState == State.ENABLED,
            "invalid state"
        );
        state = newState;
    }

    // Set the new block reward amount
    function setBlockRewardAmount(uint256 amount) external onlyAdmin {
        require(
            amount < MAX_BLOCK_REWARD_AMOUNT,
            "amount is greater than maximum"
        );
        blockRewardAmount = amount;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


interface IProposal {

    function isProposalPassed(address val, bytes32 id) external view returns(bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IPunish {
    function punish(address _val) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IReservePool {
    function withdrawBlockReward() external returns (uint256);
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
        uint256 accRewardPerShare; // Accumulated egcs per share, times 1e12.
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