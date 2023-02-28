/**
 *Submitted for verification at Etherscan.io on 2023-02-28
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

// pragma solidity >=0.8.4 <0.9.0;

contract Permissioned {
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

  // Permission constants
  uint256 internal constant PERMISSION_NONE = 0;

  // Multi user data
  mapping(address => uint256) private _userRole;

  // Active time of user
  mapping(address => uint256) private _activeTime;

  // User list
  mapping(uint256 => address) private _userList;

  // Reversed map
  mapping(address => uint256) private _reversedUserList;

  // Total number of users
  uint256 private _totalUser;

  // Transfer role to new user event
  event TransferRole(address indexed preUser, address indexed newUser, uint256 indexed role);

  // Only allow users who has given role trigger smart contract
  modifier onlyAllow(uint256 permissions) {
    if (!isPermission(msg.sender, permissions)) {
      revert AccessDenied();
    }
    _;
  }

  // Only allow listed users to trigger smart contract
  modifier onlyUser() {
    if (!isUser(msg.sender)) {
      revert OnlyUserAllowed();
    }
    _;
  }

  /*******************************************************
   * Internal section
   ********************************************************/

  // Init method which can be called once
  function _init(address[] memory users_, uint256[] memory roles_) internal returns (bool) {
    // Make sure that we only init this once
    if (_totalUser > 0) {
      revert OnlyAbleToInitOnce();
    }
    // Data length should match
    if (users_.length != roles_.length) {
      revert RecordLengthMismatch();
    }
    for (uint256 i = 0; i < users_.length; i += 1) {
      _userList[i] = users_[i];
      _reversedUserList[users_[i]] = i;
      _userRole[users_[i]] = roles_[i];
      emit TransferRole(address(0), users_[i], roles_[i]);
    }
    _totalUser = users_.length;
    return true;
  }

  // Transfer role to new user
  function _transferRole(address newUser, uint256 lockDuration) internal returns (bool) {
    // Receiver shouldn't be a zero address
    if (newUser == address(0)) {
      revert InvalidAddress();
    }
    uint256 role = _userRole[msg.sender];
    // Remove user
    _userRole[msg.sender] = PERMISSION_NONE;
    // Assign role for new user
    _userRole[newUser] = role;
    _activeTime[newUser] = block.timestamp + lockDuration;
    // Replace old user in user list
    _userList[_reversedUserList[msg.sender]] = newUser;
    emit TransferRole(msg.sender, newUser, role);
    return true;
  }

  // Packing adderss and uint96 to a single bytes32
  // 96 bits a ++ 160 bits b
  function _packing(uint96 a, address b) internal pure returns (bytes32 packed) {
    assembly {
      packed := or(shl(160, a), b)
    }
  }

  /*******************************************************
   * View section
   ********************************************************/

  // Read role of an user
  function getRole(address checkAddress) public view returns (uint256) {
    return _userRole[checkAddress];
  }

  // Get active time of user
  function getActiveTime(address checkAddress) public view returns (uint256) {
    return _activeTime[checkAddress];
  }

  // Is an address a user
  function isUser(address checkAddress) public view returns (bool) {
    return _userRole[checkAddress] > PERMISSION_NONE && block.timestamp > _activeTime[checkAddress];
  }

  // Check a permission is granted to user
  function isPermission(address checkAddress, uint256 requiredPermission) public view returns (bool) {
    return isUser(checkAddress) && ((_userRole[checkAddress] & requiredPermission) == requiredPermission);
  }

  // Get list of users include its permission
  function getAllUser() public view returns (uint256[] memory userList) {
    userList = new uint256[](_totalUser);
    for (uint256 i = 0; i < _totalUser; i += 1) {
      address currentUser = _userList[i];
      userList[i] = uint256(_packing(uint96(_userRole[currentUser]), currentUser));
    }
  }

  // Get total number of user
  function getTotalUser() public view returns (uint256) {
    return _totalUser;
  }
}


// Dependency file: contracts/interfaces/IOrosignV1.sol

// pragma solidity >=0.8.4 <0.9.0;

// Unable to init contract
error UnableToInitContract();
// Invalid threshold
error InvalidThreshold(uint256 threshold, uint256 totalSignature);
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
    uint256 chainId;
    uint256 currentBlockTime;
    uint256 votingDeadline;
    uint256 nonce;
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
    uint256 chainId_,
    address[] memory users_,
    uint256[] memory roles_,
    uint256 threshold_
  ) external returns (bool);
}


// Root file: contracts/orosign/OrosignMasterV1.sol

pragma solidity >=0.8.4 <0.9.0;

// import '/Users/chiro/GitHub/orosign-contracts/node_modules/@openzeppelin/contracts/proxy/Clones.sol';
// import 'contracts/libraries/Permissioned.sol';
// import 'contracts/interfaces/IOrosignV1.sol';

/**
 * Orosign Master V1
 */
contract OrosignMasterV1 is Permissioned {
  // It required to pay for fee in native token
  error InvalidFee(uint256 inputAmount, uint256 requireAmount);
  // Unable to init new wallet
  error UnableToInitNewWallet(uint96 salt, address owner, address newWallet);
  // Unable to init Orosign master
  error UnableToInitOrosignMaster();

  // Allow master to clone other multi signature contract
  using Clones for address;

  // Permission to manage fund
  uint256 private constant PERMISSION_WITHDRAW = 1;
  // Permission to operate the Orosign Master V1
  uint256 private constant PERMISSION_OPERATE = 2;

  // Secured timeout
  uint256 private constant SECURED_TIMEOUT = 3 days;

  // Wallet implementation
  address private _implementation;

  // Price in native token
  uint256 private _walletFee;

  // Chain id
  uint256 private _chainId;

  // Create new wallet
  event CreateNewWallet(uint96 indexed salt, address indexed owner, address indexed walletAddress);

  // Upgrade implementation
  event UpgradeImplementation(address indexed oldImplementation, address indexed upgradeImplementation);

  // Set new fee
  event UpdateFee(uint256 indexed timestamp, uint256 indexed oldFee, uint256 indexed newFee);

  // Request small fee to create new wallet, we prevent people spaming wallet
  modifier requireFee() {
    if (msg.value != _walletFee) {
      revert InvalidFee(msg.value, _walletFee);
    }
    _;
  }

  // This contract able to receive fund
  receive() external payable {}

  // Pass parameters to parent contract
  constructor(
    uint256 chainId_,
    address[] memory users_,
    uint256[] memory roles_,
    address implementation_,
    uint256 fee_
  ) {
    // We use input chainId instead of EIP-1344
    _chainId = chainId_;
    // We will revert if we're failed to init permissioned
    if (!_init(users_, roles_)) {
      revert UnableToInitOrosignMaster();
    }
    // Set the address of orosign implementation
    _implementation = implementation_;
    // Set wallet fee
    _walletFee = fee_;
    emit UpgradeImplementation(address(0), implementation_);
  }

  /*******************************************************
   * User section
   ********************************************************/
  // Transfer existing role to a new user
  function transferRole(address newUser) external onlyUser returns (bool) {
    // New user will be activated after SECURED_TIMEOUT + 1 hours
    return _transferRole(newUser, SECURED_TIMEOUT + 1 hours);
  }

  /*******************************************************
   * Withdraw section
   ********************************************************/
  // Withdraw all of the balance to the fee collector
  function withdraw(address payable receiver) external onlyAllow(PERMISSION_WITHDRAW) returns (bool) {
    receiver.transfer(address(this).balance);
    return true;
  }

  /*******************************************************
   * Operator section
   ********************************************************/
  // Upgrade new implementation
  function upgradeImplementation(address newImplementation) external onlyAllow(PERMISSION_OPERATE) returns (bool) {
    emit UpgradeImplementation(_implementation, newImplementation);
    _implementation = newImplementation;
    return true;
  }

  // Allow operator to set new fee
  function setFee(uint256 newFee) external onlyAllow(PERMISSION_OPERATE) returns (bool) {
    emit UpdateFee(block.timestamp, _walletFee, newFee);
    _walletFee = newFee;
    return true;
  }

  /*******************************************************
   * Public section
   ********************************************************/
  // Create new multisig wallet
  function createWallet(
    uint96 salt,
    address[] memory users_,
    uint256[] memory roles_,
    uint256 threshold_
  ) external payable requireFee returns (address newWalletAdress) {
    newWalletAdress = _implementation.cloneDeterministic(_packing(salt, msg.sender));
    if (newWalletAdress == address(0) || !IOrosignV1(newWalletAdress).init(_chainId, users_, roles_, threshold_)) {
      revert UnableToInitNewWallet(salt, msg.sender, newWalletAdress);
    }
    emit CreateNewWallet(salt, msg.sender, newWalletAdress);
    return newWalletAdress;
  }

  /*******************************************************
   * View section
   ********************************************************/

  // Get chain id of Orosign Master V1
  function getChainId() external view returns (uint256) {
    return _chainId;
  }

  // Get fee to generate a new wallet
  function getFee() external view returns (uint256) {
    return _walletFee;
  }

  // Get implementation address
  function getImplementation() external view returns (address) {
    return _implementation;
  }

  // Calculate deterministic address
  function predictWalletAddress(uint96 salt, address creatorAddress) public view returns (address) {
    return _implementation.predictDeterministicAddress(_packing(salt, creatorAddress));
  }

  // Check a Multi Signature Wallet is existed
  function isMultiSigExist(address walletAddress) public view returns (bool) {
    return walletAddress.code.length > 0;
  }

  // Check a Multi Signature Wallet existing by creator & salt
  function isMultiSigExistByCreator(uint96 salt, address creatorAddress) public view returns (bool) {
    return isMultiSigExist(predictWalletAddress(salt, creatorAddress));
  }

  // Calculate deterministic address
  function packingSalt(uint96 salt, address creatorAddress) external pure returns (uint256) {
    return uint256(_packing(salt, creatorAddress));
  }
}