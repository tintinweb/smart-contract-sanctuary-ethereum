// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TwoPartyContract {
  /******************************************
               DATA STRUCTURES
  ******************************************/

  // Contract owners, all addresses initialize as false
  mapping(address => bool) public owners; 

  /* "multidimensional" mapping allows for one party to sign different contracts (even each contract multiple times but only once per block) with different people
     Can only sign one iteration of a specific contract between two parties once per block as we use block.number as nonce
     Originator/Initiator + Counterparty + IPFS Hash + Block Number Contract Proposed In = Contract Hash */
  mapping(address => 
    mapping(address => 
      mapping(string => 
        mapping(uint256 => bytes32)))) public contractHashes;
  
  // Keep an array of contractHashes related to each address
  mapping(address => bytes32[]) public relatedContracts;
  
  // Contract struct will hold all contract data
  struct Contract {
    string description;
    address initiator;
    string initiatorName;
    address counterparty;
    string counterpartyName;
    string ipfsHash;
    uint256 blockProposed;
    uint256 blockExecuted;
    bool executed;
    bytes initiatorSig;
    bytes counterpartySig;
    Fees paidFees;
  }

  // Store contract structs in mapping paired to contract hash
  mapping(bytes32 => Contract) public contracts;

  // Data structures used by fee mechanisms, also used to track fees paid for each contract
  struct Fees {
    uint256 createFee; // Create fee fee in USD ($1.00 = 1 * 10**18)
    uint256 signFee; // Signer fee in USD ($1.00 = 1 * 10**18)
    uint256 executeFee; // Executor fee in USD ($1.00 = 1 * 10**18)
  }
  Fees public fees;

  /******************************************
                  CONSTRUCTOR
  ******************************************/

  // Set owners and fees at deployment
  constructor() {
    owners[payable(msg.sender)] = true;
    fees.createFee = 0;
    fees.signFee = 0;
    fees.executeFee = 0;
  }

  /******************************************
                    EVENTS
  ******************************************/

  // Log when new owners are added
  event OwnerAdded(address owner);
  // Log when withdrawals happen
  event Withdrawal(address withdrawer, uint256 withdrawal);

  // Log contract hash, initiator address, counterparty address, ipfsHash/Pointer string, and blockNumber agreement is in
  event ContractCreated(
    bytes32 contractHash,
    address initiator,
    address counterparty,
    string ipfsHash,
    uint256 blockNumber);
  // Log contract hashes on their own as all contrct details in ContractCreated can be obtianed by querying contracts data mapping
  event ContractHashed(bytes32 contractHash);
  // Log contract signatures, contractHash used in verification, and the signer address to validate against
  event ContractSigned(bytes32 contractHash, address signer, bytes signature);
  // Log contract execution using hash and the block it executed in
  event ContractExecuted(bytes32 contractHash, address executor, uint256 blockNumber);
  
  // Log when any fee is paid
  event CreateFeePaid(bytes32 contractHash, address payer, uint256 fee);
  event SignFeePaid(bytes32 contractHash, address payer, uint256 fee);
  event ExecuteFeePaid(bytes32 contractHash, address payer, uint256 fee);
  // Log whenever any fee is changed
  event CreateFeeChanged(uint256 fee);
  event SignFeeChanged(uint256 fee);
  event ExecuteFeeChanged(uint256 fee);
  // Log whenever all fees are cleared
  event FeesCleared();

  /******************************************
                   MODIFIERS
  ******************************************/

  // Require msg.sender to be an owner of contract to call modified function
  modifier onlyOwner() {
    require(owners[msg.sender], "Not a contract owner");
    _;
  }

  // Check for absence of contrash hash to make sure agreement hasn't been initialized
  modifier notCreated(address _counterparty, string memory _ipfsHash) {
    require(bytes32(contractHashes[msg.sender][_counterparty][_ipfsHash][block.number]) == 0, "Contract already initiated in this block");
    _;
  }

  // Require function call by contract initiator
  modifier onlyInitiator(bytes32 _contractHash) {
    require(contracts[_contractHash].initiator == msg.sender, "Not contract initiator");
    _;
  }

  // Require function call by counterparty, mainly for calling execute contract
  modifier onlyCounterparty(bytes32 _contractHash) {
    require(contracts[_contractHash].counterparty == msg.sender, "Not contract counterparty");
    _;
  }

  // Require caller is part of an initiated contract
  modifier validParty(bytes32 _contractHash) {
    require(contracts[_contractHash].initiator == msg.sender || contracts[_contractHash].counterparty == msg.sender, "Not a contract party");
    _;
  }

  // Require contract is not executed
  modifier notExecuted(bytes32 _contractHash) {
    require(!contracts[_contractHash].executed, "Contract already executed");
    _;
  }

  // Require contract execution has occured by all parties signing
  modifier hasExecuted(bytes32 _contractHash) {
    require(contracts[_contractHash].executed, "Contract hasnt executed");
    _;
  }

  /******************************************
              INTERNAL FUNCTIONS
  ******************************************/

  // Use DEX liquidity to determine on-chain price of native token in USD to calculate fee in USD
  function getPrice() internal view {
    
  }

  // Hash of: Initiator Address + Counterparty Address + IPFS Hash + Block Number Agreement Proposed In
  function getMessageHash(address _initiator, address _counterparty, string memory _ipfsHash, uint256 _blockNum) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_initiator, _counterparty, _ipfsHash, _blockNum));
  }

  /* Hash all relevant contract data
     We prevent _counterparty from hashing because switching party address order will change hash 
     The contract hash is what each party needs to sign */
  function hashContract(address _counterparty, string memory _ipfsHash, uint256 _blockNum) internal returns (bytes32) {
    // Generate contract hash
    bytes32 contractHash = getMessageHash(msg.sender, _counterparty, _ipfsHash, _blockNum);

    // Save same contract hash for both parties. Relate hash to address in relatedContracts
    // Initiator must be only caller as changing the address order changes the hash
    contractHashes[msg.sender][_counterparty][_ipfsHash][_blockNum] = contractHash;
    relatedContracts[msg.sender].push(contractHash);
    contractHashes[_counterparty][msg.sender][_ipfsHash][_blockNum] = contractHash;
    relatedContracts[_counterparty].push(contractHash);

    emit ContractHashed(contractHash);
    return contractHash;
  }

  // Verify if signature was for messageHash and that the signer is valid, public because interface might want to use this
  function verifySignature(
    address _signer,
    bytes32 _contractHash,
    bytes memory _signature
  ) internal pure returns (bool) {
    bytes32 ethSignedMessageHash = ECDSA.toEthSignedMessageHash(_contractHash);
    return ECDSA.recover(ethSignedMessageHash, _signature) == _signer;
  }

  // Created to validate both parties have signed with validated signatures
  // Will need to be adapted if multi-party signing is ever implemented
  function verifyAllSignatures(bytes32 _contractHash) internal view returns (bool) {
    bool initiatorSigValid = verifySignature(contracts[_contractHash].initiator, _contractHash, contracts[_contractHash].initiatorSig);
    bool counterpartySigValid = verifySignature(contracts[_contractHash].counterparty, _contractHash, contracts[_contractHash].counterpartySig);
    return (initiatorSigValid == counterpartySigValid);
  }

  /******************************************
             MANAGEMENT FUNCTIONS
  ******************************************/

  // Add additional owners to contract
  function addOwner(address _owner) public onlyOwner {
    owners[payable(_owner)] = true;
    emit OwnerAdded(_owner);
  }

  // Set create fee
  function setCreateFee(uint256 _fee) public onlyOwner {
    fees.createFee = _fee;
    emit CreateFeeChanged(_fee);
  }

  // Set sign fee
  function setSignFee(uint256 _fee) public onlyOwner {
    fees.signFee = _fee;
    emit SignFeeChanged(_fee);
  }

  // Set execute fee
  function setExecuteFee(uint256 _fee) public onlyOwner {
    fees.executeFee = _fee;
    emit ExecuteFeeChanged(_fee);
  }

  // Clear all fees at once
  function clearFees() public onlyOwner {
    fees.createFee = fees.signFee = fees.executeFee = 0;
    emit FeesCleared();
  }

  /******************************************
               PUBLIC FUNCTIONS
  ******************************************/

  // Instantiate two party contract, hash critical contract data, return block number of agreement proposal
  // notCreated() prevents duplicate calls from msg.sender or the counterparty by checking for existence of contract hash
  function createTwoPartyContract(
    string memory _description,
    string memory _signerName,
    address _counterparty,
    string memory _counterpartyName,
    string memory _ipfsHash
  ) public payable notCreated(_counterparty, _ipfsHash) returns (bytes32) {
    // Ensure any create fee is paid
    require(msg.value >= fees.createFee, "msg.value less than createFee");

    // Generate contract hash with msg.sender, counterparty address, ipfs hash, and block number confirmed in
    bytes32 contractHash = hashContract(_counterparty, _ipfsHash, block.number);

    // Begin populating Contract data struct
    // Set description
    contracts[contractHash].description = _description;
    // Save contract party addresses and names
    contracts[contractHash].initiator = msg.sender;
    contracts[contractHash].initiatorName = _signerName;
    contracts[contractHash].counterparty = _counterparty;
    contracts[contractHash].counterpartyName = _counterpartyName;
    // Save contract IPFS hash/pointer
    contracts[contractHash].ipfsHash = _ipfsHash;
    // Save block number agreement proposed in
    contracts[contractHash].blockProposed = block.number;

    emit ContractCreated(contractHash, msg.sender, _counterparty, _ipfsHash, block.number);
    if (fees.createFee > 0) {
      contracts[contractHash].paidFees.createFee = msg.value;
      emit CreateFeePaid(contractHash, msg.sender, msg.value);
    }
    return contractHash;
  }

  // Commit signature to blockchain storage after verifying it is correct and that msg.sender hasn't already called signContract()
  function signContract(bytes32 _contractHash, bytes memory _signature) public payable validParty(_contractHash) notExecuted(_contractHash) {
    // Ensure any signer fee is paid
    require(msg.value >= fees.signFee);
    // Confirm signature is valid
    require(verifySignature(msg.sender, _contractHash, _signature), "Signature not valid");

    // Save initiator signature
    if (contracts[_contractHash].initiator == msg.sender) {
      // Check if already signed
      require(keccak256(contracts[_contractHash].initiatorSig) != keccak256(_signature), "Already signed");
      // Save signature
      contracts[_contractHash].initiatorSig = _signature;
      emit ContractSigned(_contractHash, msg.sender, _signature);
      if (fees.signFee > 0) {
        contracts[_contractHash].paidFees.signFee = msg.value;
        emit SignFeePaid(_contractHash, msg.sender, msg.value);
      }

    // Save counterparty signature
    } else if (contracts[_contractHash].counterparty == msg.sender) {
      // Check if already signed
      require(keccak256(contracts[_contractHash].counterpartySig) != keccak256(_signature), "Already signed");
      // Save signature
      contracts[_contractHash].counterpartySig = _signature;
      emit ContractSigned(_contractHash, msg.sender, _signature);
      if (fees.signFee > 0) {
        contracts[_contractHash].paidFees.signFee = msg.value;
        emit SignFeePaid(_contractHash, msg.sender, msg.value);
      }

    // Shouldn't ever be hit but will leave anyways
    } else {
      revert("Not a contract party");
    }
  }

  // Execute contract if all have signed and any execute fee paid
  // Only allows contract parties to execute
  function executeContract(bytes32 _contractHash) public payable validParty(_contractHash) notExecuted(_contractHash) {
    // Ensure any execute fee is paid
    require(msg.value >= fees.executeFee);
    // Check if all signatures are received
    require(contracts[_contractHash].initiatorSig.length > 0 && contracts[_contractHash].counterpartySig.length > 0, "Signature(s) missing");
    // Double check all signatures are valid
    require(verifyAllSignatures(_contractHash));
    
    contracts[_contractHash].executed = true;
    contracts[_contractHash].blockExecuted = block.number;
    emit ContractExecuted(_contractHash, msg.sender, block.number);
    if (fees.executeFee > 0) {
      contracts[_contractHash].paidFees.executeFee = msg.value;
      emit ExecuteFeePaid(_contractHash, msg.sender, msg.value);
    }
  }

  /******************************************
               PAYMENT FUNCTIONS
  ******************************************/

  // Payment handling functions if we need them, otherwise just accept and allow withdrawal to any owner
  function withdraw() public onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success);
    emit Withdrawal(msg.sender, address(this).balance);
  }
  receive() external payable {}
  fallback() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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