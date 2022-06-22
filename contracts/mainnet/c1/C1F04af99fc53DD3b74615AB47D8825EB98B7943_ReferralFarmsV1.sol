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
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../chainAddress/ChainAddress.sol";
import "../interfaces/IERC20.sol";
import "../confirmations/types.sol";
// import "../oracles/OracleEffectsV1.sol";
// import "../support/DevRescuableOnTestnets.sol";

// Attrace Referral Farms V1
//
// A farm can be thought of as a "farm deposit". A single owner can have multiple deposits for different reward tokens and different farms.
// Token farms aggregated are a virtual/logical concept: UI's can render and groups these together as "Farms per token" and can group further "Aggregated farming value per token" and so on.
//
// This contract manages these deposits by sponsor (sponsor=msg.sender).
contract ReferralFarmsV1 is Ownable {

  // Pointer to oracles confirmations contract
  ConfirmationsResolver confirmationsAddr;

  // The farm reward token deposits remaining
  // farmHash => deposit remaining
  // Where farmHash = hash(encode(chainId,sponsor,rewardTokenDefn,referredTokenDefn))
  mapping(bytes32 => uint256) private farmDeposits;

  // Mapping which tracks which effects have been executed at the account token level (and thus are burned).
  // account => token => offset
  mapping(address => mapping(address => uint256)) private accountTokenConfirmationOffsets;

  // Mapping which tracks which effects have been executed at the farm level (and thus are burned).
  // Tracks sponsor withdraw offsets.
  // farmHash => offset
  mapping(bytes32 => uint256) private farmConfirmationOffsets;

  // Max-reward value per farm/confirmation, used by claim flows to act as a fail-safe to ensure the rewards don't overflow in the unlikely event of a bug/attack.
  mapping(bytes32 => uint256) private farmConfirmationRewardMax;

  // Tracks the remaining rewards that can be transferred per confirmation
  // farmHash -> confirmation number -> { initialized, valueRemaining }
  mapping(bytes32 => mapping(uint256 => FarmConfirmationRewardRemaining)) private farmConfirmationRewardRemaining;

  // Emitted whenever a farm is increased (which guarantees creation). Occurs multiple times per farm.
  event FarmExists(address indexed sponsor, bytes24 indexed rewardTokenDefn, bytes24 indexed referredTokenDefn, bytes32 farmHash);

  // Emitted whenever a farm is increased
  event FarmDepositIncreased(bytes32 indexed farmHash, uint128 delta);

  // Emitted when a sponsor _requests_ to withdraw their funds.
  // UI's can use the value here to indicate the change to the farm.
  // Promoters can be notified to stop promoting this farm.
  event FarmDepositDecreaseRequested(bytes32 indexed farmHash, uint128 value, uint128 confirmation);

  // Emitted whenever a farm deposit decrease is claimed
  event FarmDepositDecreaseClaimed(bytes32 indexed farmHash, uint128 delta);

  // Dynamic field to control farm behavior. 
  event FarmMetastate(bytes32 indexed farmHash, bytes32 indexed key, bytes value);

  // Emitted when rewards have been harvested by an account
  event RewardsHarvested(address indexed caller, bytes24 indexed rewardTokenDefn, bytes32 indexed farmHash, uint128 value, bytes32 leafHash);

  bytes32 constant CONFIRMATION_REWARD = "confirmationReward";

  function configure(address confirmationsAddr_) external onlyOwner {
    confirmationsAddr = ConfirmationsResolver(confirmationsAddr_);
  }

  function getFarmDepositRemaining(bytes32 farmHash) external view returns (uint256) {
    return farmDeposits[farmHash];
  }

  // Returns the confirmation offset per account per reward token
  function getAccountTokenConfirmationOffset(address account, address token) external view returns (uint256) {
    return accountTokenConfirmationOffsets[account][token];
  }

  // Getter to step through the history of farm confirmation rewards over time
  function getFarmConfirmationRewardMax(bytes32 farmHash) external view returns (uint256) {
    return farmConfirmationRewardMax[farmHash];
  }

  // Increase referral farm using ERC20 reward token (also creates any non-existing farm)
  function increaseReferralFarm(bytes24 rewardTokenDefn, bytes24 referredTokenDefn, uint128 rewardDeposit, KeyVal[] calldata metastate) external {
    require(
      rewardDeposit > 0 && rewardTokenDefn != ChainAddressExt.getNativeTokenChainAddress(), 
      "400: invalid"
    );

    // First transfer the reward token deposit to this
    IERC20(ChainAddressExt.toAddress(rewardTokenDefn)).transferFrom(msg.sender, address(this), uint256(rewardDeposit));

    // Increase the farm (this doubles as security)
    bytes32 farmHash = toFarmHash(msg.sender, rewardTokenDefn, referredTokenDefn);
    farmDeposits[farmHash] += rewardDeposit;
    
    // Inform listeners about this new farm and allow discovering the farmHash (since we don't store it)
    emit FarmExists(msg.sender, rewardTokenDefn, referredTokenDefn, farmHash);

    // Emit creation and increase of deposit
    emit FarmDepositIncreased(farmHash, rewardDeposit);

    // Handle metastate
    handleMetastateChange(farmHash, metastate);
  }

  // Configure additional metastate for a farm
  function configureMetastate(bytes24 rewardTokenDefn, bytes24 referredTokenDefn, KeyVal[] calldata metastate) external {
    // FarmHash calculation doubles as security
    bytes32 farmHash = toFarmHash(msg.sender, rewardTokenDefn, referredTokenDefn);
    handleMetastateChange(farmHash, metastate);
  }

  function handleMetastateChange(bytes32 farmHash, KeyVal[] calldata metastate) private {
    for(uint256 i = 0; i < metastate.length; i++) {
      // Manage the confirmation reward rate changes
      if(metastate[i].key == CONFIRMATION_REWARD) {
        processConfirmationRewardChangeRequest(farmHash, metastate[i].value);
      }

      emit FarmMetastate(farmHash, metastate[i].key, metastate[i].value);
    }

    // Checks if the confirmationReward has at least one value or throws error that it's required
    require(farmConfirmationRewardMax[farmHash] > 0, "400: confirmationReward");
  }

  // It should be impossible to change history.
  function processConfirmationRewardChangeRequest(bytes32 farmHash, bytes calldata value) private {
    (uint128 reward, ) = abi.decode(value, (uint128, uint128));
    if(reward > farmConfirmationRewardMax[farmHash]) {
      farmConfirmationRewardMax[farmHash] = reward;
    }
  }

  // -- HARVEST REWARDS

  // Validates against double spend
  function validateEntitlementsSetOffsetOrRevert(address rewardToken, TokenEntitlement[] calldata entitlements) private {
    require(entitlements.length > 0, "400: entitlements");
    uint128 min = entitlements[0].confirmation;
    uint128 max;
    
    // Search min/max from list
    for(uint256 i = 0; i < entitlements.length; i++) {
      if(entitlements[i].confirmation < min) {
        min = entitlements[i].confirmation;
      }
      if(entitlements[i].confirmation > max) {
        max = entitlements[i].confirmation;
      }
    }
    
    // Validate against double spend
    require(accountTokenConfirmationOffsets[msg.sender][rewardToken] < min, "401: double spend");

    // Store the new offset to protect against double spend
    accountTokenConfirmationOffsets[msg.sender][rewardToken] = max;
  }

  // Check the requested amount against the limits and update confirmation remaining value to protect against re-entrancy
  function adjustFarmConfirmationRewardRemainingOrRevert(bytes32 farmHash, uint128 confirmation, uint128 value) private {
    // Find reward remaining or initialize the first time it's used
    uint128 rewardRemaining;
    if(farmConfirmationRewardRemaining[farmHash][confirmation].initialized == false) {
      // First initializes the farmConfirmationRewardRemaining...valueRemaining
      rewardRemaining = uint128(farmConfirmationRewardMax[farmHash]); 
    } else {
      rewardRemaining = farmConfirmationRewardRemaining[farmHash][confirmation].valueRemaining;
    }

    // Adjust reward
    rewardRemaining -= value; // Underflow will throw here on insufficient confirmation balance.
    farmConfirmationRewardRemaining[farmHash][confirmation] = FarmConfirmationRewardRemaining(true, rewardRemaining);

    // Ensure sufficient deposit is left for this farm
    farmDeposits[farmHash] -= value; // Underflow will throw here on insufficient balance.
  }

  // Collect rewards entitled by the oracles.
  // Function has been tested to support 2000 requests, each carrying 20 proofs.
  function harvestRewardsNoGapcheck(HarvestTokenRequest[] calldata reqs, bytes32[][][] calldata proofs) external {
    require(reqs.length > 0 && proofs.length == reqs.length, "400: request");

    // Execute requests by reward token
    for(uint256 i = 0; i < reqs.length; i++) {
      HarvestTokenRequest calldata req = reqs[i];
      require(uint32(block.chainid) == ChainAddressExt.toChainId(req.rewardTokenDefn), "400: chain");
      address rewardTokenAddr = ChainAddressExt.toAddress(req.rewardTokenDefn);

      // Validate nonces and protects against re-entrancy.
      validateEntitlementsSetOffsetOrRevert(rewardTokenAddr, reqs[i].entitlements);

      // Check entitlements and sum reward value
      uint128 rewardValueSum = 0;
      for(uint256 j = 0; j < req.entitlements.length; j++) {
        TokenEntitlement calldata entitlement = req.entitlements[j];

        // Check if its a valid call
        bytes32 leafHash = makeLeafHash(req.rewardTokenDefn, entitlement);
        bytes32 computedHash = MerkleProof.processProof(proofs[i][j], leafHash);
        // bytes32 computedHash = OracleEffectsV1.computeRoot(leafHash, proofs[i][j]);
        (uint128 confirmation, ) = confirmationsAddr.getConfirmation(computedHash);
        require(confirmation > 0, "401: not finalized proof");  

        adjustFarmConfirmationRewardRemainingOrRevert(entitlement.farmHash, entitlement.confirmation, entitlement.value);

        emit RewardsHarvested(msg.sender, req.rewardTokenDefn, entitlement.farmHash, entitlement.value, leafHash);

        rewardValueSum += entitlement.value;
      }

      // Transfer the value using ERC20 implementation
      if(rewardValueSum > 0) {
        IERC20(rewardTokenAddr).transfer(msg.sender, rewardValueSum);
      }
    }
  }

  // -- Sponsor withdrawals

  // Called by a sponsor to request extracting (unused) funds.
  // This will be picked up by the oracle, who will reduce the deposit in it's state and provide a valid claim for extracting the value.
  function requestDecreaseReferralFarm(bytes24 rewardTokenDefn, bytes24 referredTokenDefn, uint128 value) external {
    // Farm hash doubles as security
    bytes32 farmHash = toFarmHash(msg.sender, rewardTokenDefn, referredTokenDefn);
    require(farmDeposits[farmHash] > 0, "400: deposit");

    // For good ux, replace value here with max if it overflows the deposit
    if(value > farmDeposits[farmHash]) {
      value = uint128(farmDeposits[farmHash]);
    }
    
    // Emit event for oracle trie calculation
    (uint128 headConfirmation, ) = confirmationsAddr.getConfirmation(confirmationsAddr.getHead());
    emit FarmDepositDecreaseRequested(farmHash, value, headConfirmation);
  }

  // Can be called by the sponsor after the confirmation has included the decrease request.
  // Sponsor then collects a proof which allows to extract the value.
  function claimReferralFarmDecrease(bytes24 rewardTokenDefn, bytes24 referredTokenDefn, uint128 confirmation, uint128 value, bytes32[] calldata proof) external {
    // Farm hash doubles as security
    bytes32 farmHash = toFarmHash(msg.sender, rewardTokenDefn, referredTokenDefn);

    // Check if this request is already burned (protect against double-spend and re-entrancy)
    require(confirmation > farmConfirmationOffsets[farmHash], "400: invalid or burned");

    // Burn the request
    farmConfirmationOffsets[farmHash] = confirmation;

    // Calculate leaf hash
    bytes32 leafHash = makeDecreaseLeafHash(farmHash, confirmation, value);
    
    // Check that the proof is valid (the oracle keeps a state of decrease requests, requests are bound to their request confirmation)
    // bytes32 computedHash = OracleEffectsV1.computeRoot(leafHash, proof);
    bytes32 computedHash = MerkleProof.processProof(proof, leafHash);
    (uint128 searchConfirmation, ) = confirmationsAddr.getConfirmation(computedHash);
    require(searchConfirmation > 0, "401: not finalized proof");

    // Failsafe against any bugs
    if(farmDeposits[farmHash] < value) {
      value = uint128(farmDeposits[farmHash]);
    }

    // Avoid re-entrancy on value before transfer
    farmDeposits[farmHash] -= value;

    // Transfer the value
    address rewardTokenAddr = ChainAddressExt.toAddress(rewardTokenDefn);
    IERC20(rewardTokenAddr).transfer(msg.sender, value);

    // Emit event of decrease in farm value
    emit FarmDepositDecreaseClaimed(farmHash, value);
  }

  function makeLeafHash(bytes24 rewardTokenDefn, TokenEntitlement calldata entitlement) private view returns (bytes32) {
    return keccak256(abi.encode(
      ChainAddressExt.toChainAddress(block.chainid, address(confirmationsAddr)), 
      ChainAddressExt.toChainAddress(block.chainid, address(this)),
      msg.sender, 
      rewardTokenDefn,
      entitlement
    ));
  }

  function makeDecreaseLeafHash(bytes32 farmHash, uint128 confirmation, uint128 value) private view returns (bytes32) {
    return keccak256(abi.encode(
      ChainAddressExt.toChainAddress(block.chainid, address(confirmationsAddr)), 
      ChainAddressExt.toChainAddress(block.chainid, address(this)),
      farmHash,
      confirmation,
      value
    ));
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

struct KeyVal {
  bytes32 key;
  bytes value;
}

struct FarmConfirmationRewardRemaining {
  bool initialized;
  uint128 valueRemaining;
}

// Entitlements for a reward token
struct HarvestTokenRequest {
  // The reward token
  bytes24 rewardTokenDefn;

  // Entitlements for this token which can be verified against the confirmation hashes
  TokenEntitlement[] entitlements;
}

// An entitlement to token value, which can be harvested, if confirmed by the oracles
struct TokenEntitlement {
  // The farm deposit
  bytes32 farmHash;

  // Reward token value which can be harvested
  uint128 value;

  // The confirmation number during which this entitlement was generated
  uint128 confirmation;
}

// Farm Hash - represents a single sponsor owned farm.
function toFarmHash(address sponsor, bytes24 rewardTokenDefn, bytes24 referredTokenDefn) view returns (bytes32 farmHash) {
  return keccak256(abi.encode(block.chainid, sponsor, rewardTokenDefn, referredTokenDefn));
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

// import "hardhat/console.sol";

// Core new data type: *`chaddress`*, an address with chain information encoded into it.
// bytes24 with 4 chainId bytes followed by 20 address bytes.
//
// example for 0xAA97FED7413A944118Db403Ce65116DCc4D381E2 addr on chainId 1:
// hex-encoded: 0x00000001aa97fed7413a944118db403ce65116dcc4d381e2
// eg:           [ChainId.Address.................................]
// hex-parts:   0x[00000001][aa97fed7413a944118db403ce65116dcc4d381e2]

// Hardhat-upgrades doesn't support user defined types..
// type ChainAddress is bytes24;

// Helper tooling for ChainAddress
library ChainAddressExt {

  function toChainId(bytes24 chAddr) internal pure returns (uint32 chainId) {
    return uint32(bytes4(chAddr)); // Slices off the first 4 bytes
  }

  function toAddress(bytes24 chAddr) internal pure returns (address addr) {
    return address(bytes20(bytes24(uint192(chAddr) << 32)));
  }

  function toChainAddress(uint256 chainId, address addr) internal pure returns (bytes24) {
    uint192 a = uint192(chainId);
    a = a << 160;
    a = a | uint160(addr);
    return bytes24(a);
  }

  // For the native token we set twice the chainId (which is easily checked, identifies different chains and distinguishes from real addresses)
  function getNativeTokenChainAddress() internal view returns (bytes24) {
    // [NNNN AAAAAAAAAAAAAAAAAAAA]
    // [0001 00000000000000000001] for eth-mainnet chainId: 1
    uint192 rewardToken = uint192(block.chainid);
    rewardToken = rewardToken << 160;
    rewardToken = rewardToken | uint160(block.chainid);
    return bytes24(rewardToken);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}