// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
pragma solidity >=0.8.0 <0.9.0;

import "./MultiSigWallet.sol";

contract MultiSigFactory {
  MultiSigWallet[] public multiSigs;
  mapping(address => bool) existsMultiSig;

  event Create(
    uint indexed contractId,
    address indexed contractAddress,
    address creator,
    address burner,
    address[] owners,
    uint signaturesRequired
  );

  event Owners(
    address indexed contractAddress,
    address[] owners,
    uint256 indexed signaturesRequired
  );


  constructor() {}

  modifier onlyRegistered() {
    require(existsMultiSig[msg.sender], "caller not registered to use logger");
    _;
  }

  function emitOwners(
    address _contractAddress,
    address[] memory _owners,
    uint256 _signaturesRequired
  ) external onlyRegistered {
    emit Owners(_contractAddress, _owners, _signaturesRequired);
  }

  function create(
    uint256 _chainId,
    address _burner,
    address[] memory _owners,
    uint _signaturesRequired
  ) public payable {
    uint id = numberOfMultiSigs();

    MultiSigWallet multiSig = (new MultiSigWallet){value: msg.value}(_chainId, _burner, _owners, _signaturesRequired, address(this));
    multiSigs.push(multiSig);
    existsMultiSig[address(multiSig)] = true;

    emit Create(id, address(multiSig), msg.sender, _burner, _owners, _signaturesRequired);
    emit Owners(address(multiSig), _owners, _signaturesRequired);
  }

  function numberOfMultiSigs() public view returns(uint) {
    return multiSigs.length;
  }

  function getMultiSig(uint256 _index)
    public
    view
    returns (
      address multiSigAddress,
      uint signaturesRequired,
      uint balance
    ) {
      MultiSigWallet multiSig = multiSigs[_index];
      return (address(multiSig), multiSig.signaturesRequired(), address(multiSig).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// never forget the OG simple sig wallet: https://github.com/christianlundkvist/simple-multisig/blob/master/contracts/SimpleMultiSig.sol

pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./MultiSigFactory.sol";

contract MultiSigWallet {
	using ECDSA for bytes32;
  MultiSigFactory private multiSigFactory;

	event Deposit(address indexed sender, uint amount, uint balance);
	event ExecuteTransaction( address indexed owner, address payable to, uint256 value, bytes data, uint256 nonce, bytes32 hash, bytes result);
	event Owner( address indexed owner, bool added);
	event Burner( address indexed burner, bool added);

	mapping(address => bool) public isOwner;

  address[] public owners;

	address public burner;

	uint public signaturesRequired;
	uint public nonce;
	uint public chainId;

  modifier onlyOwner() {
    require(isOwner[msg.sender] || msg.sender == burner, "Not owner");
    _;
  }

  modifier onlySelf() {
    require(msg.sender == address(this), "Not Self");
    _;
  }

  modifier requireNonZeroSignatures(uint _signaturesRequired) {
    require(_signaturesRequired > 0, "Must be non-zero sigs required");
    _;
  }

  constructor(uint256 _chainId, address _burner, address[] memory _owners, uint _signaturesRequired, address _factory) payable requireNonZeroSignatures(_signaturesRequired) {
    multiSigFactory = MultiSigFactory(_factory);
    signaturesRequired = _signaturesRequired;
		burner = _burner;
		emit Burner(burner, true);
    for (uint i = 0; i < _owners.length; i++) {
      address owner = _owners[i];

      require(owner!=address(0), "constructor: zero address");
      require(!isOwner[owner], "constructor: owner not unique");

      isOwner[owner] = true;
      owners.push(owner);

      emit Owner(owner,isOwner[owner]);
    }

    chainId = _chainId;
  }

  function addSigner(address newSigner, uint256 newSignaturesRequired) public onlySelf requireNonZeroSignatures(newSignaturesRequired) {
    require(newSigner != address(0), "addSigner: zero address");
    require(!isOwner[newSigner], "addSigner: owner not unique");

    isOwner[newSigner] = true;
    owners.push(newSigner);
    signaturesRequired = newSignaturesRequired;

    emit Owner(newSigner, isOwner[newSigner]);
    multiSigFactory.emitOwners(address(this), owners, newSignaturesRequired);
  }

  function removeSigner(address oldSigner, uint256 newSignaturesRequired) public onlySelf requireNonZeroSignatures(newSignaturesRequired) {
    require(isOwner[oldSigner], "removeSigner: not owner");

     _removeOwner(oldSigner);
    signaturesRequired = newSignaturesRequired;

    emit Owner(oldSigner, isOwner[oldSigner]);
    multiSigFactory.emitOwners(address(this), owners, newSignaturesRequired);
  }

	function cancelBurner() public onlySelf {
		emit Burner(burner, false);
		burner = address(0x0);
	}

	function changeBurner(address newBurner) public onlySelf {
		if(burner != address(0x0)) emit Burner(burner, false);
		burner = newBurner;
		emit Burner(burner, true);
	}


  function _removeOwner(address _oldSigner) private {
    isOwner[_oldSigner] = false;
    uint256 ownersLength = owners.length;
    address[] memory poppedOwners = new address[](owners.length);
    for (uint256 i = ownersLength - 1; i >= 0; i--) {
      if (owners[i] != _oldSigner) {
        poppedOwners[i] = owners[i];
        owners.pop();
      } else {
        owners.pop();
        for (uint256 j = i; j < ownersLength - 1; j++) {
          owners.push(poppedOwners[j]);
        }
        return;
      }
    }
  }

  function updateSignaturesRequired(uint256 newSignaturesRequired) public onlySelf requireNonZeroSignatures(newSignaturesRequired) {
    signaturesRequired = newSignaturesRequired;
  }

  function executeTransaction( address payable to, uint256 value, bytes memory data, bytes[] memory signatures)
      public
      onlyOwner
      returns (bytes memory)
  {
    bytes32 _hash =  getTransactionHash(nonce, to, value, data);

    nonce++;

	   if(to == address(this)) {
			uint256 validSignatures;
	    address duplicateGuard;
	    for (uint i = 0; i < signatures.length; i++) {
	        address recovered = recover(_hash, signatures[i]);
	        require(recovered > duplicateGuard, "executeTransaction: duplicate or unordered signatures");
	        duplicateGuard = recovered;

	        if (isOwner[recovered]) {
	          validSignatures++;
	        }
	    }
	    require(validSignatures >= signaturesRequired, "executeTransaction: not enough valid signatures");
		} else {
			address recovered = recover(_hash, signatures[0]);
			require(recovered == burner, "executeTransaction: not burner"); // can add || isOwner[recovered] to let hard wallet sign also?
		}

    (bool success, bytes memory result) = to.call{value: value}(data);
    require(success, "executeTransaction: tx failed");

    emit ExecuteTransaction(msg.sender, to, value, data, nonce-1, _hash, result);
    return result;
  }

  function getTransactionHash( uint256 _nonce, address to, uint256 value, bytes memory data ) public view returns (bytes32) {
    return keccak256(abi.encodePacked(address(this), chainId, _nonce, to, value, data));
  }

  function recover(bytes32 _hash, bytes memory _signature) public pure returns (address) {
    return _hash.toEthSignedMessageHash().recover(_signature);
  }

  receive() payable external {
    emit Deposit(msg.sender, msg.value, address(this).balance);
  }
}