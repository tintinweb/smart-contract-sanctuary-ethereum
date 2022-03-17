/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// File: contracts\interfaces\IAVN.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IAVN {
  event LogAuthorisationUpdated(address indexed contractAddress, bool status);
  event LogQuorumUpdated(uint256[2] quorum);
  event LogValidatorFunctionsAreEnabled(bool status);
  event LogLiftingIsEnabled(bool status);
  event LogLoweringIsEnabled(bool status);
  event LogLowerCallUpdated(bytes2 callId, uint256 numBytes);

  event LogValidatorRegistered(bytes32 indexed t1PublicKeyLHS, bytes32 t1PublicKeyRHS, bytes32 indexed t2PublicKey,
      uint256 indexed t2TransactionId);
  event LogValidatorDeregistered(bytes32 indexed t1PublicKeyLHS, bytes32 t1PublicKeyRHS, bytes32 indexed t2PublicKey,
      uint256 indexed t2TransactionId);
  event LogRootPublished(bytes32 indexed rootHash, uint256 indexed t2TransactionId);

  event LogLifted(address indexed token, address indexed t1Address, bytes32 indexed t2PublicKey, uint256 amount);
  event LogLowered(address indexed token, address indexed t1Address, bytes32 indexed t2PublicKey, uint256 amount);

  // Owner only
  function transferValidators() external;
  function setAuthorisationStatus(address contractAddress, bool status) external;
  function setQuorum(uint256[2] memory quorum) external;
  function disableValidatorFunctions() external;
  function enableValidatorFunctions() external;
  function disableLifting() external;
  function enableLifting() external;
  function disableLowering() external;
  function enableLowering() external;
  function updateLowerCall(bytes2 callId, uint256 numBytes) external;
  function recoverERC777TokensFromLegacyTreasury(address erc777Address) external;
  function recoverERC20TokensFromLegacyTreasury(address erc20Address) external;
  function liftLegacyStakes(bytes calldata t2PublicKey, uint256 amount) external;

  // Validator only
  function registerValidator(bytes memory t1PublicKey, bytes32 t2PublicKey, uint256 t2TransactionId,
      bytes calldata confirmations) external;
  function deregisterValidator(bytes memory t1PublicKey, bytes32 t2PublicKey, uint256 t2TransactionId,
      bytes calldata confirmations) external;
  function publishRoot(bytes32 rootHash, uint256 t2TransactionId, bytes calldata confirmations) external;

  // Authorised contract only
  function storeT2TransactionId(uint256 t2TransactionId) external;
  function storeRootHash(bytes32 rootHash) external;
  function storeLiftProofHash(bytes32 proofHash) external;
  function storeLoweredLeafHash(bytes32 leafHash) external;
  function unlockETH(address payable recipient, uint256 amount) external;
  function unlockERC777Tokens(address erc777Address, address recipient, uint256 amount) external;
  function unlockERC20Tokens(address erc20Address, address recipient, uint256 amount) external;

  // Public
  function getAuthorisedContracts() external view returns (address[] memory);
  function getIsPublishedRootHash(bytes32 rootHash) external view returns (bool);
  function lift(address erc20Address, bytes calldata t2PublicKey, uint256 amount) external;
  function proxyLift(address erc20Address, bytes calldata t2PublicKey, uint256 amount, address approver, uint256 proofNonce,
      bytes calldata proof) external;
  function liftETH(bytes calldata t2PublicKey) external payable;
  function lower(bytes memory leaf, bytes32[] calldata merklePath) external;
  function confirmAvnTransaction(bytes32 leafHash, bytes32[] memory merklePath) external view returns (bool);
}

// File: contracts\interfaces\IERC20.sol


pragma solidity 0.8.11;

// As described in https://eips.ethereum.org/EIPS/eip-20
interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function name() external view returns (string memory); // optional method - see eip spec
  function symbol() external view returns (string memory); // optional method - see eip spec
  function decimals() external view returns (uint8); // optional method - see eip spec
  function totalSupply() external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
}

// File: contracts\interfaces\IERC777.sol


pragma solidity 0.8.11;

// As defined in https://eips.ethereum.org/EIPS/eip-777
interface IERC777 {
  event Sent(address indexed operator, address indexed from, address indexed to, uint256 amount, bytes data,
      bytes operatorData);
  event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
  event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
  event AuthorizedOperator(address indexed operator,address indexed holder);
  event RevokedOperator(address indexed operator, address indexed holder);

  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function balanceOf(address holder) external view returns (uint256);
  function granularity() external view returns (uint256);
  function defaultOperators() external view returns (address[] memory);
  function isOperatorFor(address operator, address holder) external view returns (bool);
  function authorizeOperator(address operator) external;
  function revokeOperator(address operator) external;
  function send(address to, uint256 amount, bytes calldata data) external;
  function operatorSend(address from, address to, uint256 amount, bytes calldata data, bytes calldata operatorData) external;
  function burn(uint256 amount, bytes calldata data) external;
  function operatorBurn( address from, uint256 amount, bytes calldata data, bytes calldata operatorData) external;
}

// File: contracts\interfaces\IERC777Recipient.sol


pragma solidity 0.8.11;

// As defined in the 'ERC777TokensRecipient And The tokensReceived Hook' section of https://eips.ethereum.org/EIPS/eip-777
interface IERC777Recipient {
  function tokensReceived(address operator, address from, address to, uint256 amount, bytes calldata data,
      bytes calldata operatorData) external;
}

// File: contracts\interfaces\IAvnFTTreasury.sol


pragma solidity 0.8.11;

interface IAvnFTTreasury {
  event LogFTTreasuryPermissionUpdated(address indexed treasurer, bool status);

  function setTreasurerPermission(address treasurer, bool status) external;
  function getTreasurers() external view returns(address[] memory);
  function unlockERC777Tokens(address token, uint256 amount, bytes calldata data) external;
  function unlockERC20Tokens(address token, uint256 amount) external;
}

// File: contracts\thirdParty\interfaces\IERC1820Registry.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

// File: contracts\Owned.sol


pragma solidity 0.8.11;

contract Owned {

  address public owner = msg.sender;

  event LogOwnershipTransferred(address indexed owner, address indexed newOwner);

  modifier onlyOwner {
    require(msg.sender == owner, "Only owner");
    _;
  }

  function setOwner(address _owner)
    external
    onlyOwner
  {
    require(_owner != address(0), "Owner cannot be zero address");
    emit LogOwnershipTransferred(owner, _owner);
    owner = _owner;
  }
}

// File: ..\contracts\AVN.sol


pragma solidity 0.8.11;

contract LegacyValidatorsManager {
  uint256 public numActiveValidators;
  uint256 public validatorIdNum;
  mapping (uint256 => address) public t1Address;
  mapping (uint256 => bytes32) public t2PublicKey;
}

contract AVN is IAVN, IERC777Recipient, Owned {
  // Universal address as defined in Registry Contract Address section of https://eips.ethereum.org/EIPS/eip-1820
  IERC1820Registry constant internal ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
  // keccak256("ERC777Token")
  bytes32 constant internal ERC777_TOKEN_HASH = 0xac7fbab5f54a3ca8194167523c6753bfeb96a445279294b6125b68cce2177054;
  // keccak256("ERC777TokensRecipient")
  bytes32 constant internal ERC777_TOKENS_RECIPIENT_HASH = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;
  uint256 constant internal SIGNATURE_LENGTH = 65;
  uint256 constant internal LIFT_LIMIT = type(uint128).max;
  address constant internal PSEUDO_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  IAvnFTTreasury immutable internal LEGACY_AVN_TREASURY;
  LegacyValidatorsManager immutable internal LEGACY_AVN_VALIDATORS_MANAGER;

  mapping (uint256 => bool) public isRegisteredValidator;
  mapping (uint256 => bool) public isActiveValidator;
  mapping (address => uint256) public t1AddressToId;
  mapping (bytes32 => uint256) public t2PublicKeyToId;
  mapping (uint256 => address) public idToT1Address;
  mapping (uint256 => bytes32) public idToT2PublicKey;
  mapping (bytes2 => uint256) public numBytesToLowerData;
  mapping (address => bool) public isAuthorisedContract;
  mapping (bytes32 => bool) public isPublishedRootHash;
  mapping (uint256 => bool) public isUsedT2TransactionId;
  mapping (bytes32 => bool) public hasLowered;
  mapping (bytes32 => bool) public hasLifted;

  address[] public authorisedContracts;
  uint256[2] public quorum;

  uint256 public numActiveValidators;
  uint256 public nextValidatorId;
  uint256 public unliftedLegacyStakes;
  bool public validatorFunctionsAreEnabled;
  bool public liftingIsEnabled;
  bool public loweringIsEnabled;
  bool public validatorsTransferred;

  address immutable public avtAddress;

  constructor(address avt, LegacyValidatorsManager avnValidatorsManager, IAvnFTTreasury avnFTTreasury)
  {
    ERC1820_REGISTRY.setInterfaceImplementer(address(this), ERC777_TOKENS_RECIPIENT_HASH, address(this));
    avtAddress = avt;
    LEGACY_AVN_VALIDATORS_MANAGER = avnValidatorsManager;
    LEGACY_AVN_TREASURY = avnFTTreasury;
    numBytesToLowerData[0x2d00] = 133; // callID (2 bytes) + proof (2 prefix + 32 relayer + 32 signer + 1 prefix + 64 signature)
    numBytesToLowerData[0x2700] = 133; // callID (2 bytes) + proof (2 prefix + 32 relayer + 32 signer + 1 prefix + 64 signature)
    numBytesToLowerData[0x2702] = 2;   // callID (2 bytes)
    validatorFunctionsAreEnabled = true;
    liftingIsEnabled = true;
    loweringIsEnabled = true;
    nextValidatorId = 1;
    quorum[0] = 2;
    quorum[1] = 3;
    unliftedLegacyStakes = 2500000000000000000000000; // 2,500,000 AVT in full atto AVT
  }

  modifier onlyAuthorisedContract() {
    require(isAuthorisedContract[msg.sender], "Access denied");
    _;
  }

  modifier onlyWhenLiftingIsEnabled() {
    require(liftingIsEnabled, "Lifting currently disabled");
    _;
  }

  modifier onlyWhenValidatorFunctionsAreEnabled() {
    require(validatorFunctionsAreEnabled, "Function currently disabled");
    _;
  }

  function transferValidators()
    onlyOwner
    external
  {
    require(validatorsTransferred == false, "Validators already transferred");
    numActiveValidators = LEGACY_AVN_VALIDATORS_MANAGER.numActiveValidators();
    nextValidatorId = LEGACY_AVN_VALIDATORS_MANAGER.validatorIdNum();

    for (uint256 id = 1; id < nextValidatorId; id++) {
      idToT1Address[id] = LEGACY_AVN_VALIDATORS_MANAGER.t1Address(id);
      idToT2PublicKey[id] = LEGACY_AVN_VALIDATORS_MANAGER.t2PublicKey(id);
      t1AddressToId[idToT1Address[id]] = id;
      t2PublicKeyToId[idToT2PublicKey[id]] = id;
      isRegisteredValidator[id] = true;
      isActiveValidator[id] = true;
    }

    validatorsTransferred = true;
  }

  function setAuthorisationStatus(address contractAddress, bool status)
    onlyOwner
    external
  {
    uint256 size;

    assembly {
      size := extcodesize(contractAddress)
    }

    require(size > 0, "Only contracts");

    if (status == isAuthorisedContract[contractAddress]) {
      return;
    } else if (status) {
      isAuthorisedContract[contractAddress] = true;
      authorisedContracts.push(contractAddress);
    } else {
      isAuthorisedContract[contractAddress] = false;
      uint256 endContractAddress = authorisedContracts.length - 1;
      for (uint256 i; i < endContractAddress; i++) {
        if (authorisedContracts[i] == contractAddress) {
          authorisedContracts[i] = authorisedContracts[endContractAddress];
          break;
        }
      }
      authorisedContracts.pop();
    }
    emit LogAuthorisationUpdated(contractAddress, status);
  }

  function setQuorum(uint256[2] memory _quorum)
    onlyOwner
    public
  {
    require(_quorum[1] != 0, "Invalid: div by zero");
    require(_quorum[0] <= _quorum[1], "Invalid: above 100%");
    quorum = _quorum;
    emit LogQuorumUpdated(quorum);
  }

  function disableValidatorFunctions()
    onlyOwner
    external
  {
    validatorFunctionsAreEnabled = false;
    emit LogValidatorFunctionsAreEnabled(false);
  }

  function enableValidatorFunctions()
    onlyOwner
    external
  {
    validatorFunctionsAreEnabled = true;
    emit LogValidatorFunctionsAreEnabled(true);
  }

  function disableLifting()
    onlyOwner
    external
  {
    liftingIsEnabled = false;
    emit LogLiftingIsEnabled(false);
  }

  function enableLifting()
    onlyOwner
    external
  {
    liftingIsEnabled = true;
    emit LogLiftingIsEnabled(true);
  }

  function disableLowering()
    onlyOwner
    external
  {
    loweringIsEnabled = false;
    emit LogLoweringIsEnabled(false);
  }

  function enableLowering()
    onlyOwner
    external
  {
    loweringIsEnabled = true;
    emit LogLoweringIsEnabled(true);
  }

  function updateLowerCall(bytes2 callId, uint256 numBytes)
    onlyOwner
    external
  {
    numBytesToLowerData[callId] = numBytes;
    emit LogLowerCallUpdated(callId, numBytes);
  }

  function recoverERC777TokensFromLegacyTreasury(address erc777Address)
    onlyOwner
    external
  {
    uint256 lockedBalance = IERC777(erc777Address).balanceOf(address(LEGACY_AVN_TREASURY));
    LEGACY_AVN_TREASURY.unlockERC777Tokens(erc777Address, lockedBalance, "");
  }

  function recoverERC20TokensFromLegacyTreasury(address erc20Address)
    onlyOwner
    external
  {
    uint256 lockedBalance = IERC20(erc20Address).balanceOf(address(LEGACY_AVN_TREASURY));
    LEGACY_AVN_TREASURY.unlockERC20Tokens(erc20Address, lockedBalance);
  }

  function liftLegacyStakes(bytes calldata t2PublicKey, uint256 amount)
    onlyOwner
    external
  {
    require(amount <= unliftedLegacyStakes, "Not enough stake remaining");
    bytes32 checkedT2PublicKey = checkT2PublicKey(t2PublicKey);
    unliftedLegacyStakes = unliftedLegacyStakes - amount;
    emit LogLifted(avtAddress, address(this), checkedT2PublicKey, amount);
  }

  function registerValidator(bytes memory t1PublicKey, bytes32 t2PublicKey, uint256 t2TransactionId,
      bytes calldata confirmations)
    onlyWhenValidatorFunctionsAreEnabled
    external
  {
    require(t1PublicKey.length == 64, "T1 public key must be 64 bytes");
    address t1Address = address(uint160(uint256(keccak256(t1PublicKey))));
    uint256 id = t1AddressToId[t1Address];
    require(isRegisteredValidator[id] == false, "Validator is already registered");

    // The order of the elements is the reverse of the deregisterValidatorHash
    bytes32 registerValidatorHash = keccak256(abi.encodePacked(t1PublicKey, t2PublicKey));
    verifyConfirmations(toConfirmationHash(registerValidatorHash, t2TransactionId), confirmations);
    doStoreT2TransactionId(t2TransactionId);

    if (id == 0) {
      require(t2PublicKeyToId[t2PublicKey] == 0, "T2 public key already in use");
      id = nextValidatorId;
      idToT1Address[id] = t1Address;
      t1AddressToId[t1Address] = id;
      idToT2PublicKey[id] = t2PublicKey;
      t2PublicKeyToId[t2PublicKey] = id;
      nextValidatorId++;
    } else {
      require(idToT2PublicKey[id] == t2PublicKey, "Cannot change T2 public key");
    }

    isRegisteredValidator[id] = true;

    bytes32 t1PublicKeyLHS;
    bytes32 t1PublicKeyRHS;
    assembly {
      t1PublicKeyLHS := mload(add(t1PublicKey, 0x20))
      t1PublicKeyRHS := mload(add(t1PublicKey, 0x40))
    }

    emit LogValidatorRegistered(t1PublicKeyLHS, t1PublicKeyRHS, t2PublicKey, t2TransactionId);
  }

  function deregisterValidator(bytes memory t1PublicKey, bytes32 t2PublicKey, uint256 t2TransactionId,
      bytes calldata confirmations)
    onlyWhenValidatorFunctionsAreEnabled
    external
  {
    uint256 id = t2PublicKeyToId[t2PublicKey];
    require(isRegisteredValidator[id], "Validator is not registered");

    // The order of the elements is the reverse of the registerValidatorHash
    bytes32 deregisterValidatorHash = keccak256(abi.encodePacked(t2PublicKey, t1PublicKey));
    verifyConfirmations(toConfirmationHash(deregisterValidatorHash, t2TransactionId), confirmations);
    doStoreT2TransactionId(t2TransactionId);

    isRegisteredValidator[id] = false;
    isActiveValidator[id] = false;
    numActiveValidators--;

    bytes32 t1PublicKeyLHS;
    bytes32 t1PublicKeyRHS;
    assembly {
      t1PublicKeyLHS := mload(add(t1PublicKey, 0x20))
      t1PublicKeyRHS := mload(add(t1PublicKey, 0x40))
    }

    emit LogValidatorDeregistered(t1PublicKeyLHS, t1PublicKeyRHS, t2PublicKey, t2TransactionId);
  }

  function publishRoot(bytes32 rootHash, uint256 t2TransactionId, bytes calldata confirmations)
    onlyWhenValidatorFunctionsAreEnabled
    external
  {
    verifyConfirmations(toConfirmationHash(rootHash, t2TransactionId), confirmations);
    doStoreT2TransactionId(t2TransactionId);
    doStoreRootHash(rootHash);
    emit LogRootPublished(rootHash, t2TransactionId);
  }

  function storeT2TransactionId(uint256 t2TransactionId)
    onlyAuthorisedContract
    external
  {
    doStoreT2TransactionId(t2TransactionId);
  }

  function storeRootHash(bytes32 rootHash)
    onlyAuthorisedContract
    external
  {
    doStoreRootHash(rootHash);
  }

  function storeLiftProofHash(bytes32 proofHash)
    onlyAuthorisedContract
    external
  {
    doStoreLiftProofHash(proofHash);
  }

  function storeLoweredLeafHash(bytes32 leafHash)
    onlyAuthorisedContract
    external
  {
    doStoreLoweredLeafHash(leafHash);
  }

  function unlockETH(address payable recipient, uint256 amount)
    onlyAuthorisedContract
    external
  {
    (bool success, ) = recipient.call{value: amount}("");
    require(success, "ETH transfer failed");
  }

  function unlockERC777Tokens(address erc777Address, address recipient, uint256 amount)
    onlyAuthorisedContract
    external
  {
    IERC777(erc777Address).send(recipient, amount, "");
  }

  function unlockERC20Tokens(address erc20Address, address recipient, uint256 amount)
    onlyAuthorisedContract
    external
  {
    assert(IERC20(erc20Address).transfer(recipient, amount));
  }

  function getAuthorisedContracts()
    external
    view
    returns (address[] memory)
  {
    return authorisedContracts;
  }

  function getIsPublishedRootHash(bytes32 rootHash)
    external
    view
    returns (bool)
  {
    return isPublishedRootHash[rootHash];
  }

  function lift(address erc20Address, bytes calldata t2PublicKey, uint256 amount)
    onlyWhenLiftingIsEnabled
    external
  {
    doLift(erc20Address, msg.sender, t2PublicKey, amount);
  }

  function proxyLift(address erc20Address, bytes calldata t2PublicKey, uint256 amount, address approver, uint256 proofNonce,
      bytes calldata proof)
    onlyWhenLiftingIsEnabled
    external
  {
    if (msg.sender != approver) {
      doStoreLiftProofHash(keccak256(proof));
      bytes32 msgHash = keccak256(abi.encodePacked(erc20Address, t2PublicKey, amount, proofNonce));
      address signer = recoverSigner(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash)), proof);
      require(signer == approver, "Lift proof invalid");
    }
    doLift(erc20Address, approver, t2PublicKey, amount);
  }

  function liftETH(bytes calldata t2PublicKey)
    payable
    onlyWhenLiftingIsEnabled
    external
  {
    bytes32 checkedT2PublicKey = checkT2PublicKey(t2PublicKey);
    require(msg.value > 0, "Cannot lift zero ETH");
    emit LogLifted(PSEUDO_ETH_ADDRESS, msg.sender, checkedT2PublicKey, msg.value);
  }

  // ERC-777 automatic lifting
  function tokensReceived(address /* operator */, address from, address to, uint256 amount, bytes calldata data,
      bytes calldata /* operatorData */)
    onlyWhenLiftingIsEnabled
    external
  {
    if (from == address(LEGACY_AVN_TREASURY)) return; // recovering funds from the legacy treasury so we don't lift here
    require(to == address(this), "Tokens must be sent to this contract");
    require(amount > 0, "Cannot lift zero ERC777 tokens");
    bytes32 checkedT2PublicKey = checkT2PublicKey(data);
    require(ERC1820_REGISTRY.getInterfaceImplementer(msg.sender, ERC777_TOKEN_HASH) == msg.sender, "Token must be registered");
    IERC777 erc777Contract = IERC777(msg.sender);
    require(erc777Contract.balanceOf(address(this)) <= LIFT_LIMIT, "Exceeds ERC777 lift limit");
    emit LogLifted(msg.sender, from, checkedT2PublicKey, amount);
  }

  function lower(bytes memory leaf, bytes32[] calldata merklePath)
    external
  {
    require(loweringIsEnabled, "Lowering currently disabled");
    bytes32 leafHash = keccak256(leaf);
    require(confirmAvnTransaction(leafHash, merklePath), "Leaf or path invalid");
    doStoreLoweredLeafHash(leafHash);

    uint256 ptr;
    ptr += getCompactIntegerByteSize(leaf[ptr]); // add number of bytes encoding the leaf length
    require(uint8(leaf[ptr]) & 128 != 0, "Unsigned transaction"); // bitwise version check to ensure leaf is signed transaction
    ptr += 99; // version (1 byte) + multiAddress type (1 byte) + sender (32 bytes) + curve type (1 byte) + signature (64 bytes)
    ptr += leaf[ptr] == 0x00 ? 1 : 2; // add number of era bytes (immortal is 1, otherwise 2)
    ptr += getCompactIntegerByteSize(leaf[ptr]); // add number of bytes encoding the nonce
    ptr += getCompactIntegerByteSize(leaf[ptr]); // add number of bytes encoding the tip
    ptr += 32; // account for the first 32 EVM bytes holding the leaf's length

    bytes2 callId;

    assembly {
      callId := mload(add(leaf, ptr))
    }

    require(numBytesToLowerData[callId] != 0, "Not a lower leaf");
    ptr += numBytesToLowerData[callId];
    bytes32 t2PublicKey;
    address token;
    uint128 amount;
    address t1Address;

    assembly {
      t2PublicKey := mload(add(leaf, ptr)) // load next 32 bytes into 32 byte type starting at ptr
      token := mload(add(add(leaf, 20), ptr)) // load leftmost 20 of next 32 bytes into 20 byte type starting at ptr + 20
      amount := mload(add(add(leaf, 36), ptr)) // load leftmost 16 of next 32 bytes into 16 byte type starting at ptr + 20 + 16
      t1Address := mload(add(add(leaf, 56), ptr)) // load leftmost 20 of next 32 bytes type starting at ptr + 20 + 16 + 20
    }

    // amount was encoded in little endian so we need to reverse to big endian:
    amount = ((amount & 0xFF00FF00FF00FF00FF00FF00FF00FF00) >> 8) | ((amount & 0x00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
    amount = ((amount & 0xFFFF0000FFFF0000FFFF0000FFFF0000) >> 16) | ((amount & 0x0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
    amount = ((amount & 0xFFFFFFFF00000000FFFFFFFF00000000) >> 32) | ((amount & 0x00000000FFFFFFFF00000000FFFFFFFF) << 32);
    amount = (amount >> 64) | (amount << 64);

    if (token == PSEUDO_ETH_ADDRESS) {
      (bool success, ) = payable(t1Address).call{value: amount}("");
      require(success, "ETH transfer failed");
    } else if (ERC1820_REGISTRY.getInterfaceImplementer(token, ERC777_TOKEN_HASH) == token) {
      IERC777(token).send(t1Address, amount, "");
    } else {
      assert(IERC20(token).transfer(t1Address, amount));
    }

    emit LogLowered(token, t1Address, t2PublicKey, amount);
  }

  function confirmAvnTransaction(bytes32 leafHash, bytes32[] memory merklePath)
    public
    view
    returns (bool)
  {
    bytes32 rootHash = leafHash;

    for (uint256 i; i < merklePath.length; i++) {
      bytes32 node = merklePath[i];
      if (rootHash < node)
        rootHash = keccak256(abi.encode(rootHash, node));
      else
        rootHash = keccak256(abi.encode(node, rootHash));
    }

    return isPublishedRootHash[rootHash];
  }

  // reference: https://docs.substrate.io/v3/advanced/scale-codec/#compactgeneral-integers
  function getCompactIntegerByteSize(bytes1 checkByte)
    private
    pure
    returns (uint256 byteLength)
  {
    uint8 mode = uint8(checkByte) & 3; // the 2 least significant bits encode the byte mode so we do a bitwise AND on them

    if (mode == 0) { // single-byte mode
      byteLength = 1;
    } else if (mode == 1) { // two-byte mode
      byteLength = 2;
    } else if (mode == 2) { // four-byte mode
      byteLength = 4;
    } else {
      byteLength = uint8(checkByte >> 2) + 5; // upper 6 bits + 4 are the number of bytes following + 1 for the checkbyte itself
    }
  }

  function toConfirmationHash(bytes32 data, uint256 t2TransactionId)
    private
    view
    returns (bytes32)
  {
    return keccak256(abi.encode(data, t2TransactionId, idToT2PublicKey[t1AddressToId[msg.sender]]));
  }

  function verifyConfirmations(bytes32 msgHash, bytes memory confirmations)
    private
  {
    bytes32 ethSignedPrefixMsgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
    uint256 numConfirmations = confirmations.length / SIGNATURE_LENGTH;
    uint256 requiredConfirmations = numActiveValidators * quorum[0] / quorum[1] + 1;
    uint256 validConfirmations;
    uint256 id;
    bytes32 r;
    bytes32 s;
    uint8 v;
    bool[] memory confirmed = new bool[](nextValidatorId);

    for (uint256 i; i < numConfirmations; i++) {
      assembly {
        let offset := mul(i, SIGNATURE_LENGTH)
        r := mload(add(confirmations, add(0x20, offset)))
        s := mload(add(confirmations, add(0x40, offset)))
        v := byte(0, mload(add(confirmations, add(0x60, offset))))
      }
      if (v < 27) v += 27;
      if (v != 27 && v != 28 || uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
        continue;
      } else {
        id = t1AddressToId[ecrecover(ethSignedPrefixMsgHash, v, r, s)];

        if (isActiveValidator[id] == false) {
          if (isRegisteredValidator[id]) {
            // Here we activate any previously registered but as yet unactivated validators
            isActiveValidator[id] = true;
            numActiveValidators++;
            validConfirmations++;
            confirmed[id] = true;
          }
        } else if (confirmed[id] == false) {
          validConfirmations++;
          confirmed[id] = true;
        }
      }
      if (validConfirmations == requiredConfirmations) break;
    }

    require(validConfirmations == requiredConfirmations, "Invalid confirmations");
  }

  function doStoreT2TransactionId(uint256 t2TransactionId)
    private
  {
    require(isUsedT2TransactionId[t2TransactionId] == false, "T2 transaction must be unique");
    isUsedT2TransactionId[t2TransactionId] = true;
  }

  function doStoreRootHash(bytes32 rootHash)
    private
  {
    require(isPublishedRootHash[rootHash] == false, "Root already exists");
    isPublishedRootHash[rootHash] = true;
  }

  function doStoreLiftProofHash(bytes32 proofHash)
    private
  {
    require(hasLifted[proofHash] == false, "Lift proof already used");
    hasLifted[proofHash] = true;
  }

  function doStoreLoweredLeafHash(bytes32 leafHash)
    private
  {
    require(hasLowered[leafHash] == false, "Already lowered");
    hasLowered[leafHash] = true;
  }

  function doLift(address erc20Address, address approver, bytes memory t2PublicKey, uint256 amount)
    private
  {
    require(ERC1820_REGISTRY.getInterfaceImplementer(erc20Address, ERC777_TOKEN_HASH) == address(0), "ERC20 lift only");
    require(amount > 0, "Cannot lift zero ERC20 tokens");
    bytes32 checkedT2PublicKey = checkT2PublicKey(t2PublicKey);
    IERC20 erc20Contract = IERC20(erc20Address);
    uint256 currentBalance = erc20Contract.balanceOf(address(this));
    assert(erc20Contract.transferFrom(approver, address(this), amount));
    uint256 newBalance = erc20Contract.balanceOf(address(this));
    require(newBalance <= LIFT_LIMIT, "Exceeds ERC20 lift limit");
    emit LogLifted(erc20Address, approver, checkedT2PublicKey, newBalance - currentBalance);
  }

  function checkT2PublicKey(bytes memory t2PublicKey)
    private
    pure
    returns (bytes32 checkedT2PublicKey)
  {
    require(t2PublicKey.length == 32, "Bad T2 public key");
    checkedT2PublicKey = bytes32(t2PublicKey);
  }

  function recoverSigner(bytes32 hash, bytes memory signature)
    private
    pure
    returns (address)
  {
    if (signature.length != 65) return address(0);

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) return address(0);
    if (v < 27) v += 27;
    if (v != 27 && v != 28) return address(0);

    return ecrecover(hash, v, r, s);
  }
}