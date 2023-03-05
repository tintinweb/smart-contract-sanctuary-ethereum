/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// Dependency file: @openzeppelin/contracts/proxy/Clones.sol
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

// pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}


// Dependency file: contracts/libraries/Permissioned.sol

// pragma solidity 0.8.17;

// Top sender to process further
error AccessDenied();
// Only allow registered users
error OnlyUserAllowed();
// Prevent contract to be reinit
error OnlyAbleToInitOnce();
// Data length mismatch between two arrays
error RecordLengthMismatch();
// Invalid address
error InvalidAddress();
// Invalid address
error InvalidReceiver(address userAddress);

contract Permissioned {
  // Permission constants
  uint256 internal constant PERMISSION_NONE = 0;

  // Role record
  struct RoleRecord {
    uint256 index;
    uint128 role;
    uint128 activeTime;
  }

  // Multi user data
  mapping(address => RoleRecord) private role;

  // User list
  mapping(uint256 => address) private user;

  // Total number of users
  uint256 private totalUser;

  // Transfer role to new user event
  event TransferRole(address indexed preUser, address indexed newUser, uint128 indexed role);

  // Only allow active users who have given role trigger smart contract
  modifier onlyActivePermission(uint256 permissions) {
    if (!_isActivePermission(msg.sender, permissions)) {
      revert AccessDenied();
    }
    _;
  }

  // Only allow listed users to trigger smart contract
  modifier onlyActiveUser() {
    if (!_isActiveUser(msg.sender)) {
      revert OnlyUserAllowed();
    }
    _;
  }

  /*******************************************************
   * Internal section
   ********************************************************/

  // Init method which can be called once
  function _init(address[] memory userList, uint256[] memory roleList) internal {
    // Make sure that we only init this once
    if (totalUser > 0) {
      revert OnlyAbleToInitOnce();
    }
    // Data length should match
    if (userList.length != roleList.length) {
      revert RecordLengthMismatch();
    }
    // Create new role record
    RoleRecord memory newRoleRecord;
    newRoleRecord.activeTime = 0;
    for (uint256 i = 0; i < userList.length; i += 1) {
      // Store user's address -> user list
      user[i] = userList[i];
      // Mapping user address -> role
      newRoleRecord.index = i;
      newRoleRecord.role = uint128(roleList[i]);
      role[userList[i]] = newRoleRecord;
      emit TransferRole(address(0), userList[i], newRoleRecord.role);
    }
    totalUser = userList.length;
  }

  // Transfer role from msg.sender -> new user
  function _transferRole(address toUser, uint256 lockDuration) internal {
    // Receiver shouldn't be a zero address
    if (toUser == address(0)) {
      revert InvalidAddress();
    }
    // New user should not has any permissions
    if (_isUser(toUser)) {
      revert InvalidReceiver(toUser);
    }
    // Role owner
    address fromUser = msg.sender;
    // Get role of current user
    RoleRecord memory currentRole = role[fromUser];
    // Delete role record of current user
    delete role[fromUser];
    // Set lock duration for new user
    currentRole.activeTime = uint128(block.timestamp + lockDuration);
    // Assign current role -> new user
    role[toUser] = currentRole;
    // Replace old user in user list
    user[currentRole.index] = toUser;
    emit TransferRole(fromUser, toUser, currentRole.role);
  }

  /*******************************************************
   * Internal View section
   ********************************************************/

  // Packing adderss and uint96 to a single bytes32
  // 96 bits a ++ 160 bits b
  function _packing(uint96 a, address b) internal pure returns (bytes32 packed) {
    assembly {
      packed := or(shl(160, a), b)
    }
    return packed;
  }

  // Check if permission is a superset of required permission
  function _isSuperset(uint256 permission, uint256 requiredPermission) internal pure returns (bool) {
    return (permission & requiredPermission) == requiredPermission;
  }

  // Read role record of an user
  function _getRole(address checkAddress) internal view returns (RoleRecord memory roleRecord) {
    return role[checkAddress];
  }

  // Do this account has required permission?
  function _hasPermission(address checkAddress, uint256 requiredPermission) internal view returns (bool) {
    return _isSuperset(_getRole(checkAddress).role, requiredPermission);
  }

  // Is an user?
  function _isUser(address checkAddress) internal view returns (bool) {
    return _getRole(checkAddress).role > PERMISSION_NONE;
  }

  // Is an active user?
  function _isActiveUser(address checkAddress) internal view returns (bool) {
    RoleRecord memory roleRecord = _getRole(checkAddress);
    return roleRecord.role > PERMISSION_NONE && block.timestamp > roleRecord.activeTime;
  }

  // Check a subset of required permission was granted to user
  function _isActivePermission(address checkAddress, uint256 requiredPermission) internal view returns (bool) {
    return _isActiveUser(checkAddress) && _hasPermission(checkAddress, requiredPermission);
  }

  /*******************************************************
   * External View section
   ********************************************************/

  // Read role record of an user
  function getRole(address checkAddress) external view returns (RoleRecord memory roleRecord) {
    return _getRole(checkAddress);
  }

  // Is active user?
  function isActiveUser(address checkAddress) external view returns (bool) {
    return _isActiveUser(checkAddress);
  }

  // Check a subset of required permission was granted to user
  function isActivePermission(address checkAddress, uint256 requiredPermission) external view returns (bool) {
    return _isActivePermission(checkAddress, requiredPermission);
  }

  // Get list of users include its permission
  function getAllUser() external view returns (uint256[] memory allUser) {
    allUser = new uint256[](totalUser);
    for (uint256 i = 0; i < totalUser; i += 1) {
      address currentUser = user[i];
      allUser[i] = uint256(_packing(uint96(role[currentUser].role), currentUser));
    }
  }

  // Get total number of users
  function getTotalUser() external view returns (uint256) {
    return totalUser;
  }
}


// Dependency file: contracts/interfaces/IOrosignV1.sol

// pragma solidity >=0.8.4 <0.9.0;

// Invalid threshold
error InvalidThreshold(uint256 threshold, uint256 totalSigner);
// Invalid Proof Length
error InvalidProofLength(uint256 length);
// Invalid permission
error InvalidPermission(uint256 totalSinger, uint256 totalExecutor, uint256 totalCreator);
// Voting process was not pass the threshold
error ThresholdNotPassed(uint256 signed, uint256 threshold);
// Proof Chain ID mismatch
error ProofChainIdMismatch(uint256 inputChainId, uint256 requiredChainId);
// Proof invalid nonce value
error ProofInvalidNonce(uint256 inputNonce, uint256 requiredNonce);
// Proof expired
error ProofExpired(uint256 votingDeadline, uint256 currentTimestamp);
// There is no creator proof in the signature list
error ProofNoCreator();
// Insecure timeout
error InsecuredTimeout(uint256 duration);

interface IOrosignV1 {
  // Packed transaction
  struct PackedTransaction {
    uint64 chainId;
    uint64 votingDeadline;
    uint128 nonce;
    uint96 currentBlockTime;
    address target;
    uint256 value;
    bytes data;
  }

  struct OrosignV1Metadata {
    uint256 chainId;
    uint256 nonce;
    uint256 totalSigner;
    uint256 threshold;
    uint256 securedTimeout;
    uint256 blockTimestamp;
  }

  function init(
    uint256 chainId,
    address[] memory userList,
    uint256[] memory roleList,
    uint256 threshold
  ) external returns (bool);
}


// Root file: contracts/orosign/OrosignMasterV1.sol

pragma solidity 0.8.17;

// import '/Users/chiro/GitHub/orosign-contracts/node_modules/@openzeppelin/contracts/proxy/Clones.sol';
// import 'contracts/libraries/Permissioned.sol';
// import 'contracts/interfaces/IOrosignV1.sol';

// It required to pay for fee in native token
error InvalidFee(uint256 inputAmount, uint256 requireAmount);
// Unable to init new wallet
error UnableToInitNewWallet(uint96 salt, address owner, address newWallet);
// Unable to init Orosign master
error UnableToInitOrosignMaster();

/**
 * Orosign Master V1
 */
contract OrosignMasterV1 is Permissioned {
  // Allow master to clone other multi signature contract
  using Clones for address;

  struct MasterMetadata {
    uint256 chainId;
    uint256 walletFee;
    address implementation;
  }

  // Permission to manage fund
  uint256 private constant PERMISSION_WITHDRAW = 1;
  // Permission to operate the Orosign Master V1
  uint256 private constant PERMISSION_OPERATE = 2;

  // Secured timeout
  uint256 private constant SECURED_TIMEOUT = 3 days;

  // Wallet implementation
  address private implementation;

  // Creating fee for new multisignature in native token
  uint256 private walletFee;

  // Chain id
  uint256 private chainId;

  // Create new wallet
  event CreateNewWallet(uint96 indexed salt, address indexed owner, address indexed walletAddress);

  // Upgrade implementation
  event UpgradeImplementation(address indexed oldImplementation, address indexed upgradeImplementation);

  // Set new fee
  event UpdateFee(uint256 indexed timestamp, uint256 indexed oldFee, uint256 indexed newFee);

  // Request small fee to create new wallet, we prevent people spaming wallet
  modifier requireFee() {
    if (msg.value != walletFee) {
      revert InvalidFee(msg.value, walletFee);
    }
    _;
  }

  // This contract able to receive fund
  receive() external payable {}

  // Pass parameters to parent contract
  constructor(
    uint256 inputChainId,
    address[] memory userList,
    uint256[] memory roleList,
    address multisigImplementation,
    uint256 createWalletFee
  ) {
    uint256 countingWithdraw = 0;
    uint256 countingOperator = 0;

    // We will revert if we're failed to init permissioned
    _init(userList, roleList);

    for (uint256 i = 0; i < userList.length; i += 1) {
      if (_isSuperset(roleList[i], PERMISSION_WITHDRAW)) {
        countingWithdraw += 1;
      }
      if (_isSuperset(roleList[i], PERMISSION_OPERATE)) {
        countingOperator += 1;
      }
    }

    if (countingWithdraw == 0 || countingOperator == 0) {
      revert UnableToInitOrosignMaster();
    }

    // We use input chainId instead of EIP-1344
    chainId = inputChainId;

    // Set the address of orosign implementation
    implementation = multisigImplementation;

    // Set wallet fee
    walletFee = createWalletFee;

    emit UpgradeImplementation(address(0), multisigImplementation);
  }

  /*******************************************************
   * User section
   ********************************************************/

  // Transfer role to a new user
  function transferRole(address newUser) external onlyActiveUser returns (bool) {
    // New user will be activated after SECURED_TIMEOUT + 1 hours
    _transferRole(newUser, SECURED_TIMEOUT + 1 hours);
    return true;
  }

  /*******************************************************
   * Withdraw section
   ********************************************************/

  // Withdraw the balance to the fee collector
  function withdraw(address payable receiver) external onlyActivePermission(PERMISSION_WITHDRAW) returns (bool) {
    // Receiver should be a valid address
    if (receiver == address(0)) {
      revert InvalidAddress();
    }
    // Collecting fee to receiver
    receiver.transfer(address(this).balance);
    return true;
  }

  /*******************************************************
   * Operator section
   ********************************************************/

  // Upgrade new implementation
  function upgradeImplementation(
    address newImplementation
  ) external onlyActivePermission(PERMISSION_OPERATE) returns (bool) {
    // Overwrite current implementation address
    implementation = newImplementation;
    emit UpgradeImplementation(implementation, newImplementation);
    return true;
  }

  // Set new fee
  function setFee(uint256 newFee) external onlyActivePermission(PERMISSION_OPERATE) returns (bool) {
    // Overwrite current wallet fee
    walletFee = newFee;
    emit UpdateFee(block.timestamp, walletFee, newFee);
    return true;
  }

  /*******************************************************
   * External section
   ********************************************************/

  // Create new multisig wallet
  function createWallet(
    uint96 salt,
    address[] memory userList,
    uint256[] memory roleList,
    uint256 votingThreshold
  ) external payable requireFee returns (address newWalletAdress) {
    newWalletAdress = implementation.cloneDeterministic(_packing(salt, msg.sender));
    if (
      newWalletAdress == address(0) || !IOrosignV1(newWalletAdress).init(chainId, userList, roleList, votingThreshold)
    ) {
      revert UnableToInitNewWallet(salt, msg.sender, newWalletAdress);
    }
    emit CreateNewWallet(salt, msg.sender, newWalletAdress);
    return newWalletAdress;
  }

  /*******************************************************
   * Internal View section
   ********************************************************/

  // Calculate deterministic address
  function _predictWalletAddress(uint96 salt, address creatorAddress) internal view returns (address) {
    return implementation.predictDeterministicAddress(_packing(salt, creatorAddress));
  }

  // Check a Multi Signature Wallet is existed
  function _isMultiSigExist(address walletAddress) internal view returns (bool) {
    return walletAddress.code.length > 0;
  }

  /*******************************************************
   * View section
   ********************************************************/

  // Get metadata of Orosign Master V1
  function getMetadata() external view returns (MasterMetadata memory masterMetadata) {
    return MasterMetadata({ chainId: chainId, walletFee: walletFee, implementation: implementation });
  }

  // Calculate deterministic address
  function predictWalletAddress(uint96 salt, address creatorAddress) external view returns (address) {
    return _predictWalletAddress(salt, creatorAddress);
  }

  // Check a Multi Signature Wallet is existed
  function isMultiSigExist(address walletAddress) external view returns (bool) {
    return _isMultiSigExist(walletAddress);
  }

  // Check a Multi Signature Wallet existing by creator and salt
  function isMultiSigExistByCreator(uint96 salt, address creatorAddress) external view returns (bool) {
    return _isMultiSigExist(_predictWalletAddress(salt, creatorAddress));
  }

  // Pacing salt and creator address
  function packingSalt(uint96 salt, address creatorAddress) external pure returns (uint256) {
    return uint256(_packing(salt, creatorAddress));
  }
}