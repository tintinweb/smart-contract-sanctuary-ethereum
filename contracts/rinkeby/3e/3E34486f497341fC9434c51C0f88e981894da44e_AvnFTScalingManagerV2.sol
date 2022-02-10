/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// File: contracts/interfaces/IAvnStorage.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IAvnStorage {
  event LogStoragePermissionUpdated(address indexed publisher, bool status);

  function setStoragePermission(address publisher, bool status) external;
  function storeT2TransactionId(uint256 _t2TransactionId) external;
  function storeT2TransactionIdAndRoot(uint256 _t2TransactionId, bytes32 rootHash) external;
  function confirmLeaf(bytes32 leafHash, bytes32[] memory merklePath) external view returns (bool);
}

// File: contracts/interfaces/IAvnFTScalingManagerV2.sol


pragma solidity 0.8.11;

interface IAvnFTScalingManagerV2 {
  event LogLifted(address indexed token, address indexed t1Address, bytes32 indexed t2PublicKey, uint256 amount);
  event LogLowered(address indexed token, address indexed t1Address, bytes32 indexed t2PublicKey, uint256 amount);
  event LogLowerCallUpdated(bytes2 callId, uint256 numBytes);

  function disableLift(bool _isDisabled) external;
  function lift(address erc20Contract, bytes32 t2PublicKey, uint256 amount) external;
  function proxyLift(address erc20Contract, bytes32 t2PublicKey, uint256 amount, address approver, uint256 proofNonce,
      bytes calldata proof) external;
  function liftETH(bytes32 t2PublicKey) external payable;
  function lower(bytes memory leaf, bytes32[] calldata merklePath) external;
  function confirmT2Transaction(bytes32 leafHash, bytes32[] memory merklePath) external view returns (bool);
  function retire() external;
  function updateLowerCall(bytes2 callId, uint256 numBytes) external;
}

// File: contracts/interfaces/IAvnFTSMStorage.sol


pragma solidity 0.8.11;

interface IAvnFTSMStorage {
  event LogFTSMStoragePermissionUpdated(address indexed publisher, bool status);

  function setStoragePermission(address publisher, bool status) external;
  function storeLiftProof(bytes32 proof) external;
  function storeLoweredLeafHash(bytes32 leafHash) external;
}

// File: contracts/interfaces/IAvnFTTreasuryV2.sol


pragma solidity 0.8.11;

interface IAvnFTTreasuryV2 {
  event LogFTTreasuryPermissionUpdated(address indexed treasurer, bool status);

  function setTreasurerPermission(address treasurer, bool status) external;
  function getTreasurers() external view returns(address[] memory);
  function unlockETH(address recipient, uint256 amount) external;
  function unlockERC777Tokens(address token, address recipient, uint256 amount) external;
  function unlockERC20Tokens(address token, address recipient, uint256 amount) external;
  function recoverERC777Tokens(address token) external;
  function recoverERC20Tokens(address token) external;
}

// File: contracts/interfaces/IERC20.sol


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

// File: contracts/interfaces/IERC777.sol


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

// File: contracts/thirdParty/interfaces/IERC1820Registry.sol


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

// File: contracts/Owned.sol


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

// File: ../contracts/AvnFTScalingManagerV2.sol


pragma solidity 0.8.11;









contract AvnFTScalingManagerV2 is IAvnFTScalingManagerV2, Owned {

  // Universal address as defined in Registry Contract Address section of https://eips.ethereum.org/EIPS/eip-1820
  IERC1820Registry constant internal ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
  // keccak256("ERC777Token")
  bytes32 constant internal ERC777_TOKEN_HASH = 0xac7fbab5f54a3ca8194167523c6753bfeb96a445279294b6125b68cce2177054;
  // keccak256("ERC777TokensRecipient")
  bytes32 constant internal ERC777_TOKENS_RECIPIENT_HASH = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;

  uint256 constant internal LIFT_LIMIT = type(uint128).max;
  address constant internal PSEUDO_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  IAvnStorage immutable public avnStorage;
  IAvnFTSMStorage immutable public avnFTSMStorage;
  IAvnFTTreasuryV2 immutable public avnFTTreasuryV2;

  bool public liftDisabled;
  mapping (bytes2 => uint256) public numBytesToLowerData;

  constructor(IAvnStorage _avnStorage, IAvnFTSMStorage _avnFTSMStorage, IAvnFTTreasuryV2 _avnFTTreasuryV2)
  {
    ERC1820_REGISTRY.setInterfaceImplementer(address(this), ERC777_TOKENS_RECIPIENT_HASH, address(this));
    avnStorage = _avnStorage;
    avnFTSMStorage = _avnFTSMStorage;
    avnFTTreasuryV2 = _avnFTTreasuryV2;
    numBytesToLowerData[0x2d00] = 133; // callID (2 bytes) + proof (2 prefix + 32 relayer + 32 signer + 1 prefix + 64 signature)
    numBytesToLowerData[0x2700] = 133; // callID (2 bytes) + proof (2 prefix + 32 relayer + 32 signer + 1 prefix + 64 signature)
    numBytesToLowerData[0x2702] = 2;   // callID (2 bytes)
  }

  modifier onlyWhenLiftEnabled() {
    require(liftDisabled == false, "Lifting currently disabled");
    _;
  }

  function disableLift(bool _isDisabled)
    onlyOwner
    external
  {
    liftDisabled = _isDisabled;
  }

  function updateLowerCall(bytes2 callId, uint256 numBytes)
    onlyOwner
    external
  {
    numBytesToLowerData[callId] = numBytes;
    emit LogLowerCallUpdated(callId, numBytes);
  }

  function lift(address _erc20Contract, bytes32 _t2PublicKey, uint256 _amount)
    onlyWhenLiftEnabled
    external
  {
    doLift(_erc20Contract, msg.sender, _t2PublicKey, _amount);
  }

  function proxyLift(address _erc20Contract, bytes32 _t2PublicKey, uint256 _amount, address _approver, uint256 _proofNonce,
      bytes calldata _proof)
    onlyWhenLiftEnabled
    external
  {
    if (msg.sender != _approver) {
      checkLiftProof(_erc20Contract, _t2PublicKey, _amount, _approver, _proofNonce, _proof);
    }
    doLift(_erc20Contract, _approver, _t2PublicKey, _amount);
  }

  function liftETH(bytes32 _t2PublicKey)
    payable
    onlyWhenLiftEnabled
    external
  {
    require(msg.value > 0, "Cannot lift zero ETH");
    payable(address(avnFTTreasuryV2)).transfer(msg.value);
    emit LogLifted(PSEUDO_ETH_ADDRESS, msg.sender, _t2PublicKey, msg.value);
  }

  function lower(bytes memory _leaf, bytes32[] calldata _merklePath)
    external
  {
    bytes32 leafHash = keccak256(_leaf);
    require(avnStorage.confirmLeaf(leafHash, _merklePath), "Leaf or path invalid");
    avnFTSMStorage.storeLoweredLeafHash(leafHash);

    uint256 ptr;
    ptr += getCompactIntegerByteSize(_leaf[ptr]); // add number of bytes encoding the leaf length
    require(uint8(_leaf[ptr]) & 128 != 0, "Not a lower leaf"); // bitwise version check to ensure leaf is a signed transaction
    ptr += 99; // add the version we just checked (1 byte) + ??? (1 byte) + sender (32 bytes) + signature (1 + 64 bytes)
    ptr += _leaf[ptr] == 0x00 ? 1 : 2; // add number of era bytes (immortal is 1, otherwise 2)
    ptr += getCompactIntegerByteSize(_leaf[ptr]); // add number of bytes encoding the nonce
    ptr += getCompactIntegerByteSize(_leaf[ptr]); // add number of bytes encoding the tip
    ptr += 32; // account for the first 32 EVM bytes holding the encodedLeaf's length

    bytes2 callId;

    assembly {
      callId := mload(add(_leaf, ptr))
    }

    require(numBytesToLowerData[callId] != 0, "Not a lower leaf");
    ptr += numBytesToLowerData[callId];
    bytes32 t2PublicKey;
    address token;
    uint128 amount;
    address t1Address;

    assembly {
      t2PublicKey := mload(add(_leaf, ptr)) // load next 32 bytes into 32 byte type starting at ptr
      token := mload(add(add(_leaf, 20), ptr)) // load leftmost 20 of next 32 bytes into 20 byte type starting at ptr + 20
      amount := mload(add(add(_leaf, 36), ptr)) // load leftmost 16 of next 32 bytes into 16 byte type starting at ptr + 20 + 16
      t1Address := mload(add(add(_leaf, 56), ptr)) // load leftmost 20 of next 32 bytes type starting at ptr + 20 + 16 + 20
    }

    // amount was encoded in little endian so we need to reverse to big endian:
    amount = ((amount & 0xFF00FF00FF00FF00FF00FF00FF00FF00) >> 8) | ((amount & 0x00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
    amount = ((amount & 0xFFFF0000FFFF0000FFFF0000FFFF0000) >> 16) | ((amount & 0x0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
    amount = ((amount & 0xFFFFFFFF00000000FFFFFFFF00000000) >> 32) | ((amount & 0x00000000FFFFFFFF00000000FFFFFFFF) << 32);
    amount = (amount >> 64) | (amount << 64);

    if (token == PSEUDO_ETH_ADDRESS) {
      IAvnFTTreasuryV2(avnFTTreasuryV2).unlockETH(t1Address, amount);
    } else if (ERC1820_REGISTRY.getInterfaceImplementer(token, ERC777_TOKEN_HASH) == token) {
      IAvnFTTreasuryV2(avnFTTreasuryV2).unlockERC777Tokens(token, t1Address, amount);
    } else {
      IAvnFTTreasuryV2(avnFTTreasuryV2).unlockERC20Tokens(token, t1Address, amount);
    }

    emit LogLowered(token, t1Address, t2PublicKey, amount);
  }

  function tokensReceived(address  /* _operator */, address _from, address _to, uint256 _amount, bytes calldata _data,
      bytes calldata /* _operatorData */)
    onlyWhenLiftEnabled
    external
  {
    require(_amount > 0, "Cannot lift zero ERC777 tokens");
    require(_to == address(this), "Tokens must be sent to this contract");
    require(ERC1820_REGISTRY.getInterfaceImplementer(msg.sender, ERC777_TOKEN_HASH) == msg.sender, "Token must be registered");

    IERC777 erc777Contract = IERC777(msg.sender);
    uint256 treasuryBalanceBeforeLift = erc777Contract.balanceOf(address(avnFTTreasuryV2));
    require(treasuryBalanceBeforeLift + _amount <= LIFT_LIMIT, "Exceeds ERC777 lift limit");
    erc777Contract.send(address(avnFTTreasuryV2), _amount, _data);
    // We check that the balance of the T1 treasury after a lift is incremeted by the exact amount lifted, since the amount
    // locked in the T1 treasury must reflect the amount created on T2. This prevents tokens which mint or burn on transfer.
    require(erc777Contract.balanceOf(address(avnFTTreasuryV2)) - treasuryBalanceBeforeLift == _amount, "Non-standard ERC777");
    emit LogLifted(msg.sender, _from, abi.decode(_data, (bytes32)), _amount);
  }

  function confirmT2Transaction(bytes32 _leafHash, bytes32[] memory _merklePath)
    external
    view
    returns (bool)
  {
    return avnStorage.confirmLeaf(_leafHash, _merklePath);
  }

  function retire()
    onlyOwner
    external
  {
    selfdestruct(payable(owner));
  }

  function getCompactIntegerByteSize(bytes1 checkByte)
    private
    pure
    returns (uint256)
  {
    uint8 mode = uint8(checkByte) & 3;

    if (mode == 0) {
      return 1;
    } else if (mode == 1) {
      return 2;
    } else if (mode == 2) {
      return 4;
    }

    return uint8(checkByte >> 2) + 5;
  }

  function lockERC20TokensInTreasury(address _erc20Contract, address _approver, uint256 _amount)
    private
  {
    IERC20 erc20Contract = IERC20(_erc20Contract);
    uint256 treasuryBalanceBeforeLift = erc20Contract.balanceOf(address(avnFTTreasuryV2));
    assert(erc20Contract.transferFrom(_approver, address(avnFTTreasuryV2), _amount));
    // We check that the balance of the T1 treasury after a lift is incremeted by the exact amount lifted, since the amount
    // locked in the T1 treasury must reflect the amount created on T2. This prevents tokens which mint or burn on transfer.
    require(erc20Contract.balanceOf(address(avnFTTreasuryV2)) - treasuryBalanceBeforeLift == _amount, "Non-standard ERC20");
  }

  function doLift(address _erc20Contract, address _approver, bytes32 _t2PublicKey, uint256 _amount)
    private
  {
    require(_amount > 0, "Cannot lift zero ERC20 tokens");
    require(IERC20(_erc20Contract).balanceOf(address(avnFTTreasuryV2)) + _amount <= LIFT_LIMIT, "Exceeds ERC20 lift limit");
    lockERC20TokensInTreasury(_erc20Contract, _approver, _amount);
    emit LogLifted(_erc20Contract, _approver, _t2PublicKey, _amount);
  }

  function checkLiftProof(address _erc20Contract, bytes32 _t2PublicKey, uint256 _amount, address _approver, uint256 _proofNonce,
      bytes memory _proof)
    private
  {
    avnFTSMStorage.storeLiftProof(keccak256(_proof));
    bytes32 msgHash = keccak256(abi.encodePacked(_erc20Contract, _t2PublicKey, _amount, _proofNonce));
    address signer = recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash)), _proof);
    require(signer == _approver, "Lift proof invalid");
  }

  function recover(bytes32 hash, bytes memory signature)
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