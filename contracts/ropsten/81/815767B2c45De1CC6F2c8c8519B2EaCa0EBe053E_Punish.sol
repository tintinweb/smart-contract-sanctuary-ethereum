// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./Params.sol";
import "./interfaces/IValidators.sol";
import "./Admin.sol";

contract Punish is Params, Admin {
    uint256 public punishThreshold;
    uint256 public removeThreshold;
    uint256 public decreaseRate;

    struct PunishRecord {
        uint256 missedBlocksCounter;
        uint256 index;
        bool exist;
    }

    mapping(address => PunishRecord) internal _punishRecords;
    address[] public punishValidators;

    mapping(uint256 => bool) internal _punished;
    mapping(uint256 => bool) internal _decreased;

    event LogDecreaseMissedBlocksCounter();
    event LogPunishValidator(address indexed val, uint256 time);

    modifier onlyNotPunished() {
        require(!_punished[block.number], "Already _punished");
        _;
    }

    modifier onlyNotDecreased() {
        require(!_decreased[block.number], "Already _decreased");
        _;
    }

    function initialize(
        address _validatorsContract,
        address _punishContract,
        address _proposalContract,
        address _reservePool,
        address _admin,
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
        punishThreshold = 24;
        removeThreshold = 48;
        decreaseRate = 24;
    }

    function punish(address _val) external onlyMiner onlyNotPunished {
        _punished[block.number] = true;

        // Don't punish the validator again who was jailed
        if (!VALIDATOR_CONTRACT.getPoolenabled(_val)) {
            return;
        }
        if (!_punishRecords[_val].exist) {
            _punishRecords[_val].index = punishValidators.length;
            punishValidators.push(_val);
            _punishRecords[_val].exist = true;
        }
        _punishRecords[_val].missedBlocksCounter++;

        if (_punishRecords[_val].missedBlocksCounter % removeThreshold == 0) {
            VALIDATOR_CONTRACT.punish(_val, true);
            // reset validator's missed blocks counter
            _punishRecords[_val].missedBlocksCounter = 0;
            _cleanPunishRecord(_val);
        } else if (
            _punishRecords[_val].missedBlocksCounter % punishThreshold == 0
        ) {
            VALIDATOR_CONTRACT.punish(_val, false);
        }

        emit LogPunishValidator(_val, block.timestamp); // solhint-disable-line not-rely-on-time
    }

    function decreaseMissedBlocksCounter()
        external
        onlyMiner
        onlyNotDecreased
        onlyBlockEpoch
    {
        _decreased[block.number] = true;
        if (punishValidators.length == 0) {
            return;
        }

        for (uint256 i = 0; i < punishValidators.length; i++) {
            if (
                _punishRecords[punishValidators[i]].missedBlocksCounter >
                removeThreshold / decreaseRate
            ) {
                _punishRecords[punishValidators[i]].missedBlocksCounter =
                    _punishRecords[punishValidators[i]].missedBlocksCounter -
                    removeThreshold /
                    decreaseRate;
            } else {
                _punishRecords[punishValidators[i]].missedBlocksCounter = 0;
            }
        }

        emit LogDecreaseMissedBlocksCounter();
    }

    // clean validator's punish record if one vote in
    function _cleanPunishRecord(address _val) internal {
        if (_punishRecords[_val].missedBlocksCounter != 0) {
            _punishRecords[_val].missedBlocksCounter = 0;
        }

        // remove it out of array if exist
        if (_punishRecords[_val].exist && punishValidators.length > 0) {
            if (_punishRecords[_val].index != punishValidators.length - 1) {
                address _tail = punishValidators[punishValidators.length - 1];
                punishValidators[_punishRecords[_val].index] = _tail;

                _punishRecords[_tail].index = _punishRecords[_val].index;
            }
            punishValidators.pop();
            _punishRecords[_val].index = 0;
            _punishRecords[_val].exist = false;
        }
    }

    function getPunishValidatorsLen() public view returns (uint256) {
        return punishValidators.length;
    }

    function getPunishRecord(address val) public view returns (uint256) {
        return _punishRecords[val].missedBlocksCounter;
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