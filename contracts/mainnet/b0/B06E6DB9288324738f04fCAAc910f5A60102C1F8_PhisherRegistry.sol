pragma solidity ^0.8.13;
//SPDX-License-Identifier: MIT

import "./Delegatable.sol";
import "./caveat-enforcers/RevokableOwnableDelegatable.sol";

contract PhisherRegistry is RevokableOwnableDelegatable {

  constructor(string memory name) RevokableOwnableDelegatable(name) {}

  mapping (string => bool) public isPhisher;
  event PhisherStatusUpdated(string indexed entity, bool isPhisher);
  function claimIfPhisher (string calldata identifier, bool isAccused) onlyOwner public {
    isPhisher[identifier] = isAccused;
    emit PhisherStatusUpdated(identifier, isAccused);
  }

  mapping (string => bool) public isMember;
  event MemberStatusUpdated(string indexed entity, bool isMember);
  function claimIfMember (string calldata identifier, bool isNominated) onlyOwner public {
    isMember[identifier] = isNominated;
    emit MemberStatusUpdated(identifier, isNominated);
  }

}

pragma solidity ^0.8.13;
// SPDX-License-Identifier: MIT

import "./TypesAndDecoders.sol";
import "./caveat-enforcers/CaveatEnforcer.sol";

abstract contract Delegatable is EIP712Decoder {
  event DelegationTriggered(address principal, address indexed agent);

  bytes32 public immutable domainHash;
  constructor (string memory contractName, string memory version) {
    domainHash = getEIP712DomainHash(contractName,version,block.chainid,address(this));
  }  

  // Allows external signers to submit batches of signed invocations for processing. 
  function invoke (SignedInvocation[] calldata signedInvocations) public returns (bool success) {
    for (uint i = 0; i < signedInvocations.length; i++) {
      SignedInvocation calldata signedInvocation = signedInvocations[i];
      address invocationSigner = verifyInvocationSignature(signedInvocation);
      enforceReplayProtection(invocationSigner, signedInvocations[i].invocations.replayProtection);
      _invoke(signedInvocation.invocations.batch, invocationSigner);
    }
  }

  // Allows external contracts to submit batches of invocations for processing.
  function contractInvoke (Invocation[] calldata batch) public returns (bool) {
    return _invoke(batch, msg.sender);
  }

  function _invoke (Invocation[] calldata batch, address sender) private returns (bool success) {
    for (uint x = 0; x < batch.length; x++) {
      Invocation memory invocation = batch[x];
      address intendedSender;
      address canGrant;

      // If there are no delegations, this invocation comes from the signer
      if (invocation.authority.length == 0) {
        intendedSender = sender;
        canGrant = intendedSender;
      }

      bytes32 authHash = 0x0;

      for (uint d = 0; d < invocation.authority.length; d++) {
        SignedDelegation memory signedDelegation = invocation.authority[d];
        address delegationSigner = verifyDelegationSignature(signedDelegation);

        // Implied sending account is the signer of the first delegation
        if (d == 0) {
          intendedSender = delegationSigner;
          canGrant = intendedSender;
        }

        require(delegationSigner == canGrant, "Delegation signer does not match required signer");

        Delegation memory delegation = signedDelegation.delegation;
        require(delegation.authority == authHash, "Delegation authority does not match previous delegation");

        // TODO: maybe delegations should have replay protection, at least a nonce (non order dependent),
        // otherwise once it's revoked, you can't give the exact same permission again.
        bytes32 delegationHash = GET_SIGNEDDELEGATION_PACKETHASH(signedDelegation);

        // Each delegation can include any number of caveats.
        // A caveat is any condition that may reject a proposed transaction.
        // The caveats specify an external contract that is passed the proposed tx,
        // As well as some extra terms that are used to parameterize the enforcer.
        for (uint16 y = 0; y < delegation.caveats.length; y++) {
          CaveatEnforcer enforcer = CaveatEnforcer(delegation.caveats[y].enforcer);
          bool caveatSuccess = enforcer.enforceCaveat(delegation.caveats[y].terms, invocation.transaction, delegationHash);
          require(caveatSuccess, "Caveat rejected");
        }

        // Store the hash of this delegation in `authHash`
        // That way the next delegation can be verified against it.
        authHash = delegationHash;
        canGrant = delegation.delegate;
      }

      // Here we perform the requested invocation.
      Transaction memory transaction = invocation.transaction;

      require(transaction.to == address(this), "Invocation target does not match");
      emit DelegationTriggered(intendedSender, sender);
      success = execute(
        transaction.to,
        transaction.data,
        transaction.gasLimit,
        intendedSender
      );
      require(success, "Delegator execution failed");
    }
  }

  mapping(address => mapping(uint => uint)) public multiNonce;
  function enforceReplayProtection (address intendedSender, ReplayProtection memory protection) private {
    uint queue = protection.queue;
    uint nonce = protection.nonce;
    require(nonce == (multiNonce[intendedSender][queue]+1), "One-at-a-time order enforced. Nonce2 is too small");
    multiNonce[intendedSender][queue] = nonce;
  }

  function execute(
      address to,
      bytes memory data,
      uint256 gasLimit,
      address sender
  ) internal returns (bool success) {
    bytes memory full = abi.encodePacked(data, sender);
    assembly {
      success := call(gasLimit, to, 0, add(full, 0x20), mload(full), 0, 0)
    }
  }

  function verifyInvocationSignature (SignedInvocation memory signedInvocation) public view returns (address) {
    bytes32 sigHash = getInvocationsTypedDataHash(signedInvocation.invocations);
    address recoveredSignatureSigner = recover(sigHash, signedInvocation.signature);
    return recoveredSignatureSigner;
  } 

  function verifyDelegationSignature (SignedDelegation memory signedDelegation) public view returns (address) {
    Delegation memory delegation = signedDelegation.delegation;
    bytes32 sigHash = getDelegationTypedDataHash(delegation);
    address recoveredSignatureSigner = recover(sigHash, signedDelegation.signature);
    return recoveredSignatureSigner;
  }

  function getDelegationTypedDataHash(Delegation memory delegation) public view returns (bytes32) {
    bytes32 digest = keccak256(abi.encodePacked(
      "\x19\x01",
      domainHash,
      GET_DELEGATION_PACKETHASH(delegation)
    ));
    return digest;
  }

  function getInvocationsTypedDataHash (Invocations memory invocations) public view returns (bytes32) {
    bytes32 digest = keccak256(abi.encodePacked(
      "\x19\x01",
      domainHash,
      GET_INVOCATIONS_PACKETHASH(invocations)
    ));
    return digest;
  }

  function getEIP712DomainHash(string memory contractName, string memory version, uint256 chainId, address verifyingContract) public pure returns (bytes32) {
    bytes memory encoded = abi.encode(
      EIP712DOMAIN_TYPEHASH,
      keccak256(bytes(contractName)),
      keccak256(bytes(version)),
      chainId,
      verifyingContract
    );
    return keccak256(encoded);
  }


  function _msgSender () internal view virtual returns (address sender) {
    if(msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
      }
    } else {
      sender = msg.sender;
    }
    return sender;
  }

}

pragma solidity ^0.8.13;
//SPDX-License-Identifier: MIT

import "./CaveatEnforcer.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
import "../Delegatable.sol";

abstract contract RevokableOwnableDelegatable is Ownable, CaveatEnforcer, Delegatable {

  constructor(string memory name) Delegatable(name, "1") {}

  mapping(bytes32 => bool) isRevoked;
  function enforceCaveat(
    bytes calldata terms,
    Transaction calldata transaction,
    bytes32 delegationHash
  ) public view override returns (bool) {
    require(!isRevoked[delegationHash], "Delegation has been revoked");

    // Owner methods are not delegatable in this contract:
    bytes4 targetSig = bytes4(transaction.data[0:4]);

    // transferOwnership(address newOwner)
    require(targetSig != 0xf2fde38b, "transferOwnership is not delegatable");

    // renounceOwnership() 
    require(targetSig != 0x79ba79d8, "renounceOwnership is not delegatable");

    return true;
  }

function revokeDelegation(
    SignedDelegation calldata signedDelegation,
    SignedIntentionToRevoke calldata signedIntentionToRevoke
  ) public {
    address signer = verifyDelegationSignature(signedDelegation);
    address revocationSigner = verifyIntentionToRevokeSignature(signedIntentionToRevoke);
    require(signer == revocationSigner, "Only the signer can revoke a delegation");

    bytes32 delegationHash = GET_SIGNEDDELEGATION_PACKETHASH(signedDelegation);
    isRevoked[delegationHash] = true;
  }

  function verifyIntentionToRevokeSignature(
    SignedIntentionToRevoke memory signedIntentionToRevoke
  ) public view returns (address) {
    IntentionToRevoke memory intentionToRevoke = signedIntentionToRevoke.intentionToRevoke;
    bytes32 sigHash = getIntentionToRevokeTypedDataHash(intentionToRevoke);
    address recoveredSignatureSigner = recover(sigHash, signedIntentionToRevoke.signature);
    return recoveredSignatureSigner;
  }

  function getIntentionToRevokeTypedDataHash(
    IntentionToRevoke memory intentionToRevoke
  ) public view returns (bytes32) {
    bytes32 digest = keccak256(abi.encodePacked(
      "\x19\x01",
      domainHash,
      GET_INTENTIONTOREVOKE_PACKETHASH(intentionToRevoke)
    ));
    return digest;
  }

  /**
   * This is boilerplate that must be added to any Delegatable contract if it also inherits
   * from another class that also implements _msgSender().
   */
  function _msgSender () internal view override(Delegatable, Context) returns (address sender) {
    if(msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
      }
    } else {
      sender = msg.sender;
    }
    return sender;
  }

}

pragma solidity ^0.8.13;
// SPDX-License-Identifier: MIT
import "./ECRecovery.sol";

// BEGIN EIP712 AUTOGENERATED SETUP
struct EIP712Domain {
  string name;
  string version;
  uint256 chainId;
  address verifyingContract;
}

bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

struct Invocation {
  Transaction transaction;
  SignedDelegation[] authority;
}

bytes32 constant INVOCATION_TYPEHASH = keccak256("Invocation(Transaction transaction,SignedDelegation[] authority)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)SignedDelegation(Delegation delegation,bytes signature)Transaction(address to,uint256 gasLimit,bytes data)");

struct Invocations {
  Invocation[] batch;
  ReplayProtection replayProtection;
}

bytes32 constant INVOCATIONS_TYPEHASH = keccak256("Invocations(Invocation[] batch,ReplayProtection replayProtection)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)Invocation(Transaction transaction,SignedDelegation[] authority)ReplayProtection(uint nonce,uint queue)SignedDelegation(Delegation delegation,bytes signature)Transaction(address to,uint256 gasLimit,bytes data)");

struct SignedInvocation {
  Invocations invocations;
  bytes signature;
}

bytes32 constant SIGNEDINVOCATION_TYPEHASH = keccak256("SignedInvocation(Invocations invocations,bytes signature)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)Invocation(Transaction transaction,SignedDelegation[] authority)Invocations(Invocation[] batch,ReplayProtection replayProtection)ReplayProtection(uint nonce,uint queue)SignedDelegation(Delegation delegation,bytes signature)Transaction(address to,uint256 gasLimit,bytes data)");

struct Transaction {
  address to;
  uint256 gasLimit;
  bytes data;
}

bytes32 constant TRANSACTION_TYPEHASH = keccak256("Transaction(address to,uint256 gasLimit,bytes data)");

struct ReplayProtection {
  uint nonce;
  uint queue;
}

bytes32 constant REPLAYPROTECTION_TYPEHASH = keccak256("ReplayProtection(uint nonce,uint queue)");

struct Delegation {
  address delegate;
  bytes32 authority;
  Caveat[] caveats;
}

bytes32 constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegate,bytes32 authority,Caveat[] caveats)Caveat(address enforcer,bytes terms)");

struct Caveat {
  address enforcer;
  bytes terms;
}

bytes32 constant CAVEAT_TYPEHASH = keccak256("Caveat(address enforcer,bytes terms)");

struct SignedDelegation {
  Delegation delegation;
  bytes signature;
}

bytes32 constant SIGNEDDELEGATION_TYPEHASH = keccak256("SignedDelegation(Delegation delegation,bytes signature)Caveat(address enforcer,bytes terms)Delegation(address delegate,bytes32 authority,Caveat[] caveats)");

struct IntentionToRevoke {
  bytes32 delegationHash;
}

bytes32 constant INTENTIONTOREVOKE_TYPEHASH = keccak256("IntentionToRevoke(bytes32 delegationHash)");

struct SignedIntentionToRevoke {
  bytes signature;
  IntentionToRevoke intentionToRevoke;
}

bytes32 constant SIGNEDINTENTIONTOREVOKE_TYPEHASH = keccak256("SignedIntentionToRevoke(bytes signature,IntentionToRevoke intentionToRevoke)IntentionToRevoke(bytes32 delegationHash)");

// END EIP712 AUTOGENERATED SETUP

contract EIP712Decoder is ECRecovery {

  // BEGIN EIP712 AUTOGENERATED BODY. See scripts/typesToCode.js

  function GET_EIP712DOMAIN_PACKETHASH (EIP712Domain memory _input) public pure returns (bytes32) {
    
    bytes memory encoded = abi.encode(
      EIP712DOMAIN_TYPEHASH,
      _input.name,
      _input.version,
      _input.chainId,
      _input.verifyingContract
    );
    
    return keccak256(encoded);
  }

  function GET_INVOCATION_PACKETHASH (Invocation memory _input) public pure returns (bytes32) {
    
    bytes memory encoded = abi.encode(
      INVOCATION_TYPEHASH,
      GET_TRANSACTION_PACKETHASH(_input.transaction),
      GET_SIGNEDDELEGATION_ARRAY_PACKETHASH(_input.authority)
    );
    
    return keccak256(encoded);
  }

  function GET_SIGNEDDELEGATION_ARRAY_PACKETHASH (SignedDelegation[] memory _input) public pure returns (bytes32) {
    bytes memory encoded;
    for (uint i = 0; i < _input.length; i++) {
      encoded = bytes.concat(
        encoded,
        GET_SIGNEDDELEGATION_PACKETHASH(_input[i])
      );
    }
    
    bytes32 hash = keccak256(encoded);
    return hash;
  }

  function GET_INVOCATIONS_PACKETHASH (Invocations memory _input) public pure returns (bytes32) {
    
    bytes memory encoded = abi.encode(
      INVOCATIONS_TYPEHASH,
      GET_INVOCATION_ARRAY_PACKETHASH(_input.batch),
      GET_REPLAYPROTECTION_PACKETHASH(_input.replayProtection)
    );
    
    return keccak256(encoded);
  }

  function GET_INVOCATION_ARRAY_PACKETHASH (Invocation[] memory _input) public pure returns (bytes32) {
    bytes memory encoded;
    for (uint i = 0; i < _input.length; i++) {
      encoded = bytes.concat(
        encoded,
        GET_INVOCATION_PACKETHASH(_input[i])
      );
    }
    
    bytes32 hash = keccak256(encoded);
    return hash;
  }

  function GET_SIGNEDINVOCATION_PACKETHASH (SignedInvocation memory _input) public pure returns (bytes32) {
    
    bytes memory encoded = abi.encode(
      SIGNEDINVOCATION_TYPEHASH,
      GET_INVOCATIONS_PACKETHASH(_input.invocations),
      keccak256(_input.signature)
    );
    
    return keccak256(encoded);
  }

  function GET_TRANSACTION_PACKETHASH (Transaction memory _input) public pure returns (bytes32) {
    
    bytes memory encoded = abi.encode(
      TRANSACTION_TYPEHASH,
      _input.to,
      _input.gasLimit,
      keccak256(_input.data)
    );
    
    return keccak256(encoded);
  }

  function GET_REPLAYPROTECTION_PACKETHASH (ReplayProtection memory _input) public pure returns (bytes32) {
    
    bytes memory encoded = abi.encode(
      REPLAYPROTECTION_TYPEHASH,
      _input.nonce,
      _input.queue
    );
    
    return keccak256(encoded);
  }

  function GET_DELEGATION_PACKETHASH (Delegation memory _input) public pure returns (bytes32) {
    
    bytes memory encoded = abi.encode(
      DELEGATION_TYPEHASH,
      _input.delegate,
      _input.authority,
      GET_CAVEAT_ARRAY_PACKETHASH(_input.caveats)
    );
    
    return keccak256(encoded);
  }

  function GET_CAVEAT_ARRAY_PACKETHASH (Caveat[] memory _input) public pure returns (bytes32) {
    bytes memory encoded;
    for (uint i = 0; i < _input.length; i++) {
      encoded = bytes.concat(
        encoded,
        GET_CAVEAT_PACKETHASH(_input[i])
      );
    }
    
    bytes32 hash = keccak256(encoded);
    return hash;
  }

  function GET_CAVEAT_PACKETHASH (Caveat memory _input) public pure returns (bytes32) {
    
    bytes memory encoded = abi.encode(
      CAVEAT_TYPEHASH,
      _input.enforcer,
      keccak256(_input.terms)
    );
    
    return keccak256(encoded);
  }

  function GET_SIGNEDDELEGATION_PACKETHASH (SignedDelegation memory _input) public pure returns (bytes32) {
    
    bytes memory encoded = abi.encode(
      SIGNEDDELEGATION_TYPEHASH,
      GET_DELEGATION_PACKETHASH(_input.delegation),
      keccak256(_input.signature)
    );
    
    return keccak256(encoded);
  }

  function GET_INTENTIONTOREVOKE_PACKETHASH (IntentionToRevoke memory _input) public pure returns (bytes32) {
    
    bytes memory encoded = abi.encode(
      INTENTIONTOREVOKE_TYPEHASH,
      _input.delegationHash
    );
    
    return keccak256(encoded);
  }

  function GET_SIGNEDINTENTIONTOREVOKE_PACKETHASH (SignedIntentionToRevoke memory _input) public pure returns (bytes32) {
    
    bytes memory encoded = abi.encode(
      SIGNEDINTENTIONTOREVOKE_TYPEHASH,
      keccak256(_input.signature),
      GET_INTENTIONTOREVOKE_PACKETHASH(_input.intentionToRevoke)
    );
    
    return keccak256(encoded);
  }
  // END EIP712 AUTOGENERATED BODY

}

pragma solidity ^0.8.13;
//SPDX-License-Identifier: MIT

import "../TypesAndDecoders.sol";

abstract contract CaveatEnforcer {
  function enforceCaveat (bytes calldata terms, Transaction calldata tx, bytes32 delegationHash) virtual public returns (bool);
}

pragma solidity ^0.8.13;
// SPDX-License-Identifier: MIT 

contract ECRecovery {

    /**
    * @dev Recover signer address from a message by using their signature
    * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
    * @param sig bytes signature, the signature is generated using web3.eth.sign()
    */
    function recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
// Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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