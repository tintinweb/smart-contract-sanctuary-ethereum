// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.14;

//
//                                 (((((((((((()                                 
//                              (((((((((((((((((((                              
//                            ((((((           ((((((                            
//                           (((((               (((((                           
//                         (((((/                 ((((((                         
//                        (((((                     (((((                        
//                      ((((((                       ((((()                      
//                     (((((                           (((((                     
//                   ((((((                             (((((                    
//                  (((((                                                        
//                ((((((                        (((((((((((((((                  
//               (((((                       (((((((((((((((((((((               
//             ((((((                      ((((((             (((((.             
//            (((((                      ((((((.               ((((((            
//          ((((((                     ((((((((                  (((((           
//         (((((                      (((((((((                   ((((((         
//        (((((                     ((((((.(((((                    (((((        
//       (((((                     ((((((   (((((                    (((((       
//      (((((                    ((((((      ((((((                   (((((      
//      ((((.                  ((((((          (((((                  (((((      
//      (((((                .((((((            ((((((                (((((      
//       ((((()            (((((((                (((((             ((((((       
//        .(((((((      (((((((.                   ((((((((     ((((((((         
//           ((((((((((((((((                         ((((((((((((((((           
//                .((((.                                    (((()         
//                                  
//                               attrace.com
//

// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../settings/SettingsV1.sol";
import "../settings/SettingValidatorV1.sol";

// Oracle Authority 
//
// A single instance of this contract represent a genesis state for Attrace oracles to bootstrap from.
//
// Oracles start up with an OracleAuthorityV1 address and use it to resolve all their initialization state.
// After being operational, the oracles react to planned changes (and cancellations of planned changes if they are not yet in effect).
//
// This allows efficient internal design of the derived block code. All changes have to be announced, so all code can switch and prepare before processing blocks.
//
// This contract can live on a different chain than the pacemaker.
// All changes done to the oracles are event-like encoded on-chain and emitted. 
//
// The contract can encode start before it's deployment time, allowing oracles to plug into chains from historical points before it's deployment time.
// Any changes after deployment have to wait until oracles are synced upto change times.
//
// The DAO will become owner of this contract.
//
// The contract applies "irreversible" behavior: even the future DAO cannot revert historically activated changes for those time periods.
//
contract OracleAuthorityV1 is Ownable {
  
  // Pluggable setting validator
  SettingValidatorV1 public settingValidator;

  // Settings change history
  // releaseTime=0 indicates genesis setting
  Setting[] private changeHistory;

  // Static keys to set self address
  bytes32 constant AUTHORITY = "authority";
  bytes32 constant SETTING_VALIDATOR = "settingValidator";

  // Emitted whenever a setting change is planned
  event SettingConfigured(bytes32 indexed path0, bytes32 indexed pathIdx, bytes32[] path, uint64 releaseTime, bytes value);

  // Emitted whenever planned settings are cancelled
  event PendingSettingCancelled(bytes32 indexed path0, bytes32 indexed pathIdx, Setting setting);

  // When created, it's created with a genesis state
  constructor(Setting[] memory genesisSettings) {
    // Inject our own address to guarantee a unique genesis state related to this authority contract
    addSetting(Setting(settingToPath(AUTHORITY), 0, abi.encode(block.chainid, address(this))));

    // Add the requested genesis properties
    for(uint i = 0; i < genesisSettings.length; i++) {
      require(genesisSettings[i].releaseTime == 0, "400");
      addSetting(genesisSettings[i]);
    }

    // It's required to configure a setting validator during deployment
    require(address(settingValidator) != address(0), "400: settings");
  }

  // Return changeHistory size
  function changeCount() external view returns (uint256) {
    return changeHistory.length;
  }

  // Get a specific change from the change history
  function getChange(uint256 idx) external view returns (Setting memory) {
    return changeHistory[idx];
  }

  // Plan all future oracle changes. 
  // When planning new changes, you replace all previous planned changed.
  function planChanges(Setting[] calldata settings) external onlyOwner {
    // Remove any planned changes which have not been activated yet
    for(uint256 i = changeHistory.length-1; i >= 0; i--) {
      // Keep already active changes
      if(changeHistory[i].releaseTime <= block.timestamp) {
        break;
      }
      // Remove one entry from the end of the array
      emit PendingSettingCancelled(changeHistory[i].path[0], hashPath(changeHistory[i].path), changeHistory[i]);
      changeHistory.pop();
    }

    // Plan the new changes
    uint256 lastTime;
    for(uint i = 0; i < settings.length; i++) {
      require(
        // Validates it's a planned change
        settings[i].releaseTime > block.timestamp
        // Validates order
        && (lastTime > 0 ? settings[i].releaseTime >= lastTime : true)
        // Validates if it's allowed to change this setting
        && (settingValidator.isValidUnlockedSetting(settings[i].path, settings[i].releaseTime, settings[i].value) == true)
        , "400");

      // Plan setting + emit event
      addSetting(settings[i]);

      // Track last time
      lastTime = settings[i].releaseTime;
    }
  }

  function addSetting(Setting memory setting) private {
    // Activate setting validator changes, these apply instantly
    if(setting.path[0] == SETTING_VALIDATOR) {
      (address addr) = abi.decode(setting.value, (address));
      require(addr != address(0), "400");
      settingValidator = SettingValidatorV1(addr); // SettingValidator ignores the history concept
    }

    changeHistory.push(setting);
    emit SettingConfigured(setting.path[0], hashPath(setting.path), setting.path, setting.releaseTime, setting.value);
  }

  // -- don't accept raw ether
  receive() external payable {
    revert('unsupported');
  }

  // -- reject any other function
  fallback() external payable {
    revert('unsupported');
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

function settingToPath(bytes32 setting) pure returns (bytes32[] memory) {
  bytes32[] memory path = new bytes32[](1);
  path[0] = setting;
  return path;
}

function hashPath(bytes32[] memory path) pure returns (bytes32) {
  return keccak256(abi.encode(path));
}

struct Setting {
  // Setting path identifier, the key. Can also encode array values.
  // Eg: [b32str("hardFork")]
  bytes32[] path;

  // Pacemaker block time where the change activates in seconds.
  // Code activates on the first block.timestamp > releaseTime.
  uint64 releaseTime;

  // Optional bbi-encoded bytes value. Can contain any structure.
  // Value encoding should be supported by the runtime at that future block height.
  // Eg: codebase url hints
  bytes value;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

interface SettingValidatorV1 {
  function isValidUnlockedSetting(bytes32[] calldata path, uint64 releaseTime, bytes calldata value) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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