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

import "@openzeppelin/contracts/access/Ownable.sol";
import "./types.sol";

// import "hardhat/console.sol";
// import "../interfaces/IERC20.sol";
// import "../support/DevRescuableOnTestnets.sol";

struct ConfirmationInfo {
  uint128 number;
  uint64 timestamp;
}

// Contract which represents the oracles their confirmations.
contract ConfirmationsV1 is Ownable, ConfirmationsResolver {
  // Hash of the last confirmation
  bytes32 private head;

  // Address of the oracle gate which is allowed to finalize confirmations
  address private oracleGate;

  // Amount of blocks the blockchain has evolved before another finalization is accepted.
  uint32 private finalizeBlockDiffMin;

  // Block height of the last finalization we received, parsed from the request, checked against current block height.
  uint64 private lastFinalizeAtBlockHeight;

  // Mapping of confirmations which are finalized
  mapping(bytes32 => ConfirmationInfo) private confirmations;

  // Emitted whenever the config has been changed
  event ConfigChanged(address indexed oracleGate, uint32 finalizeBlockDiffMin);

  // Emitted whenever a confirmation is finalized (claims work from finalization)
  event ConfirmationFinalized (
    bytes32 indexed confirmationHash,
    uint128 indexed number,
    bytes32 stateRoot,
    bytes32 parentHash,
    uint64 timestamp,
    bytes32 bundleHash,
    bytes32 indexed closerHash,
    uint32 blockCount,
    bytes32 blockHash,
    uint64 confirmChainBlockNr
  );

  function finalize(
    bytes32 confirmationHash,
    uint128 number,
    bytes32 stateRoot,
    bytes32 parentHash,
    uint64 timestamp,
    bytes32 bundleHash,
    bytes32 closerHash,
    uint32 blockCount,
    bytes32 blockHash,
    uint64 confirmChainBlockNr
  ) external onlyOracleGate {
    require(
      // Ensure this finalization has not yet been done before
      confirmations[confirmationHash].number == 0 
      // Verify that the confirmations form a clean chain
      && number == confirmations[head].number + 1 
      && (number > 1 ? head == parentHash : true)
      // Verify that there is sufficient blocks in between the finalization requests.
      // In a deployment which behaves periodically and is synced, this will enforce 24hr delay between tip of the confirmation chain finalizations.
      && (confirmChainBlockNr < block.number && (lastFinalizeAtBlockHeight + finalizeBlockDiffMin) <= confirmChainBlockNr)
      , "400: nochain");

    confirmations[confirmationHash] = ConfirmationInfo(number, timestamp);
    head = confirmationHash;

    // Store new block finalization offset
    lastFinalizeAtBlockHeight = confirmChainBlockNr;

    emit ConfirmationFinalized(confirmationHash, number, stateRoot, parentHash, timestamp, bundleHash, closerHash, blockCount, blockHash, confirmChainBlockNr);
  }

  function getHead() external view override returns (bytes32) {
    return head;
  }

  function getConfirmation(bytes32 confirmationHash) external view override returns(uint128 number, uint64 timestamp) {
    return (confirmations[confirmationHash].number, confirmations[confirmationHash].timestamp);
  }

  function getOracleGate() external view returns (address) {
    return oracleGate;
  }

  function configure(address oracleGate_, uint32 finalizeBlockDiffMin_) external onlyOwner {
    require(oracleGate_ != address(0) && finalizeBlockDiffMin_ > 0, "400");
    oracleGate = oracleGate_;
    finalizeBlockDiffMin = finalizeBlockDiffMin_;
    emit ConfigChanged(oracleGate_, finalizeBlockDiffMin_);
  }

  // -- MODIFIERS
  modifier onlyOracleGate {
    require(oracleGate == msg.sender, "401");
    _;
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

interface ConfirmationsResolver {
  function getHead() external view returns(bytes32);
  function getConfirmation(bytes32 confirmationHash) external view returns (uint128 number, uint64 timestamp);
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