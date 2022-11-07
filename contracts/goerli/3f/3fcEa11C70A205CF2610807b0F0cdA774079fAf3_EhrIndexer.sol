// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "./Users.sol";
import "./Access.sol";
import "./EhrDocs.sol";
import "./Restrictable.sol";

contract EhrIndexer is Ownable, Multicall, Restrictable, Users, EhrDocs {
    /**
      Error codes:
    ADL - already deleted
    WTP - wrong type passed
    LST - new version of the EHR document must be the latest
    NFD - not found
    AEX - already exists
    DND - access denied
    TMT - timeout
    NNC - wrong nonce
    SIG - invalid signature
  */

  struct DataEntry {
    uint128 groupID;
    mapping (string => bytes) valueSet;
    bytes docStorIDEncr;
  }

  struct Element {
    bytes32 itemType;
    bytes32 elementType;
    bytes32 nodeID;
    bytes32 name;
    DataEntry[] dataEntries;
  }

  struct Node {
    bytes32 nodeType;
    bytes32 nodeID;
    mapping (bytes32 => Node) next;
    mapping (bytes32 => Element) items;
  }

  Node public dataSearch;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import "./Restrictable.sol";
import "./Access.sol";
import "./SignChecker.sol";

contract Users is Restrictable, Access {
  enum Role { Patient, Doctor }

  struct User {
    bytes32   id;
    bytes32   systemID;
    Role      role;
    bytes     pwdHash;
  }

  struct UserGroup {
    mapping(bytes32 => bytes) params;
    mapping(address => AccessLevel) members;
    uint membersCount;
  }

  mapping (address => User) public users;
  mapping (bytes32 => bytes32) public ehrUsers; // userID -> ehrID
  mapping (bytes32 => UserGroup) userGroups; // groupIdHash => UserGroup

  ///
  function setEhrUser(
    bytes32 userId, 
    bytes32 ehrId,
    uint nonce, 
    address signer, 
    bytes memory signature
  ) 
    external onlyAllowed(msg.sender) checkNonce(signer, nonce)
  {
    // Signature verification
    bytes32 payloadHash = keccak256(abi.encode("setEhrUser", userId, ehrId, nonce));
    require(SignChecker.signCheck(payloadHash, signer, signature), "SIG");

    ehrUsers[userId] = ehrId;
  }

  ///
  function userNew(
    address userAddr, 
    bytes32 id, 
    bytes32 systemID, 
    Role role, 
    bytes calldata pwdHash, 
    uint nonce, 
    address signer, 
    bytes memory signature
  ) external onlyAllowed(msg.sender) checkNonce(signer, nonce) {

    // Checking user existence
    require(users[userAddr].id == bytes32(0), "AEX");

    // Signature verification
    bytes32 payloadHash = keccak256(abi.encode("userAdd", userAddr, id, systemID, role, pwdHash, nonce));
    require(SignChecker.signCheck(payloadHash, signer, signature), "SIG");

    users[userAddr] = User({
      id: id, 
      systemID: systemID,
      role: role, 
      pwdHash: pwdHash
    });
  }

  function getUserPasswordHash(address userAddr) public view returns (bytes memory) {
    require(users[userAddr].id != bytes32(0), "NFD");
    return users[userAddr].pwdHash;
  }

  struct KeyValue {
    bytes32 key;
    bytes value;
  }

  struct UserGroupCreateParams {
      bytes32 groupIdHash;
      bytes groupIdEncr;
      bytes groupKeyEncr;
      KeyValue[] params;
      uint nonce;
      address signer;
      bytes signature;
  }

  function userGroupCreate(
    UserGroupCreateParams calldata p
  ) external onlyAllowed(msg.sender) checkNonce(p.signer, p.nonce) {

    // Checking user existence
    require(users[p.signer].id != bytes32(0), "NFD");

    // Signature verification
    bytes32 payloadHash = keccak256(abi.encode("userGroupCreate", p.groupIdHash, p.groupIdEncr, p.groupKeyEncr, p.params, p.nonce));
    require(SignChecker.signCheck(payloadHash, p.signer, p.signature), "SIG");

    // Checking group absence
    require(userGroups[p.groupIdHash].membersCount == 0, "AEX");

    // Creating a group
    userGroups[p.groupIdHash].members[p.signer] = AccessLevel.Owner;
    userGroups[p.groupIdHash].membersCount++;

    for(uint i; i < p.params.length; i++){
      userGroups[p.groupIdHash].params[p.params[i].key] = p.params[i].value;
    }

    // Adding a groupID to a user's group list
    accessStore[keccak256(abi.encode(p.groupIdHash, AccessKind.UserGroup))].push(Object({
      idHash: p.groupIdHash,
      idEncr: p.groupIdEncr,
      keyEncr: p.groupKeyEncr,
      level: AccessLevel.Owner
    }));
  }

  struct GroupAddUserParams {
    bytes32 groupIdHash;
    address addingUserAddr;
    AccessLevel level;
    bytes idEncr;
    bytes keyEncr;
    uint nonce;
    address signer;
    bytes signature;
  }

  function groupAddUser(GroupAddUserParams calldata p) 
    external checkNonce(p.signer, p.nonce) 
  {
    // Checking user existence
    require(users[p.addingUserAddr].id != bytes32(0), "NFD");

    // Signature verification
    bytes32 payloadHash = keccak256(abi.encode("groupAddUser", p.groupIdHash, p.addingUserAddr, p.level, p.idEncr, p.keyEncr, p.nonce));
    require(SignChecker.signCheck(payloadHash, p.signer, p.signature), "SIG");

    // Checking user not in group already
    // TODO

    // Checking access rights
    require(userGroups[p.groupIdHash].members[p.signer] == AccessLevel.Owner || 
        userGroups[p.groupIdHash].members[p.signer] == AccessLevel.Admin, "DNY");

    // Adding a user to a group
    userGroups[p.groupIdHash].members[p.addingUserAddr] = p.level;
    userGroups[p.groupIdHash].membersCount++;

    // Adding the group's secret key
    accessStore[keccak256(abi.encode(users[p.addingUserAddr].id, AccessKind.UserGroup))].push(Object({
      idHash: p.groupIdHash,
      idEncr: p.idEncr,
      keyEncr: p.keyEncr,
      level: p.level
    }));
  }

  function groupRemoveUser(
      bytes32 groupIdHash, 
      address removingUserAddr, 
      uint nonce, 
      address signer, 
      bytes calldata signature
  ) external checkNonce(signer, nonce) {

    // Checking user existence
    require(users[removingUserAddr].id != bytes32(0), "NFD");

    // Signature verification
    bytes32 payloadHash = keccak256(abi.encode("groupRemoveUser", groupIdHash, removingUserAddr, nonce));
    require(SignChecker.signCheck(payloadHash, signer, signature), "SIG");

    // Checking access rights
    require(userGroups[groupIdHash].members[signer] == AccessLevel.Owner ||
        userGroups[groupIdHash].members[signer] == AccessLevel.Admin, "DNY");

    // Removing a user from a group
    userGroups[groupIdHash].members[removingUserAddr] = AccessLevel.NoAccess;
    userGroups[groupIdHash].membersCount--;

    // Removing a group's access key
    bytes32 userIdHash = keccak256(abi.encode(users[removingUserAddr].id, AccessKind.UserGroup));
    for(uint i; i < accessStore[userIdHash].length; i++) {
      if (accessStore[userIdHash][i].idHash == groupIdHash) {
        accessStore[userIdHash][i].idHash = bytes32(0);
        accessStore[userIdHash][i].idEncr = new bytes(0);
        accessStore[userIdHash][i].keyEncr = new bytes(0);
        accessStore[userIdHash][i].level = AccessLevel.NoAccess;
        return;
      }
    }

    revert("NFD");

    //TODO Delete groupID from the list of user groups
  }

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import "./Restrictable.sol";

contract Access is Restrictable {
    enum AccessLevel { NoAccess, Owner, Admin, Read }
    enum AccessKind { Doc, DocGroup, UserGroup }

    struct Object {
        bytes32      idHash;
        bytes        idEncr;
        bytes        keyEncr;
        AccessLevel  level;
    }

    mapping(bytes32 => Object[]) accessStore;     // idHash => Object[]

    function getAccessByIdHash(
        bytes32 userIdHash, 
        bytes32 objectIdHash
    ) 
        external view returns(Object memory) 
    {
        for (uint i; i < accessStore[userIdHash].length; i++){
            if (accessStore[userIdHash][i].idHash == objectIdHash) {
                return accessStore[userIdHash][i];
            }
        }

        revert("NFD");
    }

    function getUserAccessList(bytes32 userIdHash) external view returns (Object[] memory) {
        require(accessStore[userIdHash].length > 0, "NFD");
        return accessStore[userIdHash];
    }

    function getUserAccessLevel(
        bytes32 userID,
        AccessKind kind,
        bytes32 idHash
    )
        internal view returns (AccessLevel) 
    {
        bytes32 accessID = keccak256(abi.encode(userID, kind));
        for(uint i; i < accessStore[accessID].length; i++){
            if (accessStore[accessID][i].idHash == idHash) {
                return accessStore[accessID][i].level;
            }
        }

        // Checking groups
        accessID = keccak256(abi.encode(userID, AccessKind.UserGroup));
        for (uint i = 0; i < accessStore[accessID].length; i++) {
            for (uint j = 0; j < accessStore[accessID].length; j++) {
                if (accessStore[accessID][j].idHash == idHash) {
                    return accessStore[accessID][j].level;
                }
            }
        }

        return AccessLevel.NoAccess;
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import "./Access.sol";
import "./Users.sol";

contract EhrDocs is Access, Users {

    enum DocType { Ehr, EhrAccess, EhrStatus , Composition }
    enum DocStatus { Active, Deleted }

    struct DocumentMeta {
        DocType docType;
        DocStatus status;
        bytes   CID;
        bytes   dealCID;
        bytes   minerAddress;
        bytes   docUIDEncrypted;
        bytes32 docBaseUIDHash;
        bytes32 version;
        bool    isLast;
        uint32  timestamp;
    }

    mapping (bytes32  => mapping(DocType => DocumentMeta[])) ehrDocs; // ehr_id -> docType -> DocumentMeta[]
    mapping (bytes32  => bytes32) public ehrSubject;  // subjectKey -> ehr_id
    mapping (bytes32 => bool) cids;

    ///
    function setEhrSubject(
        bytes32 subjectKey, 
        bytes32 ehrId,
        uint nonce, 
        address signer, 
        bytes calldata signature
    ) 
        external onlyAllowed(msg.sender) checkNonce(signer, nonce)
    {
        // Signature verification
        bytes32 payloadHash = keccak256(abi.encode("setEhrSubject", subjectKey, ehrId, nonce));
        require(SignChecker.signCheck(payloadHash, signer, signature), "SIG");

        ehrSubject[subjectKey] = ehrId;
    }

    struct AddEhrDocParams {
        bytes32 ehrId;
        DocumentMeta docMeta;
        bytes keyEncr;
        bytes CIDEncr;
        uint nonce;
        address signer; 
        bytes signature;
    }
    
    ///
    function addEhrDoc(
        AddEhrDocParams calldata p
    ) 
        external onlyAllowed(msg.sender) checkNonce(p.signer, p.nonce)
    {
        // Signature verification
        bytes32 payloadHash = keccak256(abi.encode("addEhrDoc", p.ehrId, p.docMeta, p.keyEncr, p.CIDEncr, p.nonce));
        require(SignChecker.signCheck(payloadHash, p.signer, p.signature), "SIG");

        bytes32 CIDHash = keccak256(abi.encode(p.docMeta.CID));
        require(cids[CIDHash] == false, "AEX");
        cids[CIDHash] = true;

        require(p.docMeta.isLast == true, "LST");
        require(users[p.signer].id != bytes32(0), "NFD");

        if (p.docMeta.docType == DocType.Ehr || p.docMeta.docType == DocType.EhrStatus) {
            for (uint i = 0; i < ehrDocs[p.ehrId][p.docMeta.docType].length; i++) {
                ehrDocs[p.ehrId][p.docMeta.docType][i].isLast = false;
            }
        }

        if (p.docMeta.docType == DocType.Composition) {
            for (uint i = 0; i < ehrDocs[p.ehrId][DocType.Composition].length; i++) {
                if (ehrDocs[p.ehrId][DocType.Composition][i].docBaseUIDHash == p.docMeta.docBaseUIDHash) {
                    ehrDocs[p.ehrId][DocType.Composition][i].isLast = false;
                }
            }
        }

        ehrDocs[p.ehrId][p.docMeta.docType].push(p.docMeta);

        bytes32 accessID = keccak256(abi.encode(users[p.signer].id, AccessKind.Doc));
        
        accessStore[accessID].push(Object({
            idHash: CIDHash,
            idEncr: p.CIDEncr,
            keyEncr: p.keyEncr,
            level: AccessLevel.Admin
        }));
    }

    ///
    function getEhrDocs(bytes32 ehrId, DocType docType) public view returns(DocumentMeta[] memory) {
        return ehrDocs[ehrId][docType];
    }

    ///
    function getLastEhrDocByType(bytes32 ehrId, DocType docType) public view returns(DocumentMeta memory) {
        for (uint i = 0; i < ehrDocs[ehrId][docType].length; i++) {
            if (ehrDocs[ehrId][docType][i].isLast == true) {
                return ehrDocs[ehrId][docType][i];
            }
        }
        revert("NFD");
    }

    ///
    function getDocByVersion(
        bytes32 ehrId,
        DocType docType,
        bytes32 docBaseUIDHash,
        bytes32 version
    )
        public view returns (DocumentMeta memory) 
    {
        for (uint i = 0; i < ehrDocs[ehrId][docType].length; i++) {
            if (ehrDocs[ehrId][docType][i].docBaseUIDHash == docBaseUIDHash && ehrDocs[ehrId][docType][i].version == version) {
                return ehrDocs[ehrId][docType][i];
            }
        }
        revert("NFD");
    }

    ///
    function getDocByTime(bytes32 ehrID, DocType docType, uint32 timestamp) 
        public view returns (DocumentMeta memory) 
    {
        DocumentMeta memory docMeta;
        for (uint i = 0; i < ehrDocs[ehrID][docType].length; i++) {
            if (ehrDocs[ehrID][docType][i].timestamp <= timestamp) {
                docMeta = ehrDocs[ehrID][docType][i];
            } else {
                break;
            }
        }

        require(docMeta.timestamp != 0, "NFD");

        return docMeta;
    }

    ///
    function getDocLastByBaseID(bytes32 ehrId, DocType docType, bytes32 docBaseUIDHash) 
        public view returns (DocumentMeta memory) 
    {
        for (uint i = 0; i < ehrDocs[ehrId][docType].length; i++) {
            if (ehrDocs[ehrId][docType][i].docBaseUIDHash == docBaseUIDHash) {
                return ehrDocs[ehrId][docType][i];
            }
        }
        revert("NFD");
    }

    ///
    function setDocAccess(
        bytes  calldata CID,
        Object calldata accessObj,
        address         userAddr,
        uint            nonce,
        address         signer,
        bytes calldata  signature
    ) 
        external checkNonce(signer, nonce) 
    {    
        // Signature verification
        bytes32 payloadHash = keccak256(abi.encode("setDocAccess", CID, accessObj, userAddr, nonce));
        require(SignChecker.signCheck(payloadHash, signer, signature), "SIG");

        User memory user = users[userAddr];
        require(user.id != bytes32(0), "NFD");
        require(users[signer].id != bytes32(0), "NFD");

        // Checking access rights
        {
            // Signer should be Owner or Admin of doc
            bytes32 CIDHash = keccak256(abi.encode(CID));
            AccessLevel signerLevel = getUserAccessLevel(users[signer].id, AccessKind.Doc, CIDHash);
            require(signerLevel == AccessLevel.Owner || signerLevel == AccessLevel.Admin, "DND");
            require(getUserAccessLevel(user.id, AccessKind.Doc, CIDHash) != AccessLevel.Owner, "DND");
        }
        
        // Request validation
        if (accessObj.level == AccessLevel.NoAccess) {
            require(accessObj.keyEncr.length == 0 && accessObj.idEncr.length == 0, "E01");
        }

        // Set access
        accessStore[keccak256(abi.encode(user.id, AccessKind.Doc))].push(accessObj);
    }

    ///
    function deleteDoc(
        bytes32 ehrId, 
        DocType docType, 
        bytes32 docBaseUIDHash, 
        bytes32 version
    ) 
        external onlyAllowed(msg.sender) 
    {
        require(docType == DocType.Composition, "WTP");
        
        for (uint i = 0; i < ehrDocs[ehrId][docType].length; i++) {
            if (ehrDocs[ehrId][docType][i].docBaseUIDHash == docBaseUIDHash && ehrDocs[ehrId][docType][i].version == version) {
                require (ehrDocs[ehrId][docType][i].status != DocStatus.Deleted, "ADL");
                ehrDocs[ehrId][docType][i].status = DocStatus.Deleted;
                return;
            }
        }
        revert("NFD");
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Restrictable is Ownable {
  mapping (address => bool) public allowedChange;
  mapping (address => uint) public nonces;

  modifier onlyAllowed(address _addr) {
    require(allowedChange[_addr] == true, "Not allowed");
    _;
  }

  modifier checkNonce(address _addr, uint nonce) {
      require(nonces[_addr] == nonce - 1, "NON");
      nonces[_addr]++;
      _;
  }

  function setAllowed(address addr, bool allowed) external onlyOwner() {
    allowedChange[addr] = allowed;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

library SignChecker {
  function signCheck(
      bytes32 payloadHash, 
      address signer, 
      bytes memory signature
  ) external view returns (bool) {
    bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash));
    return SignatureChecker.isValidSignatureNow(signer, messageHash, signature);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}