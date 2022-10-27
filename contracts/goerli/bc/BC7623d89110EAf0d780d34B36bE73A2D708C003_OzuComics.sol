// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./IOzuComics.sol";
import "./OzuCuts/IOzuCuts.sol";
import "./OzuGenerative/IOzuGenerative.sol";

contract OzuComics is IOzuComics, Ownable {
  // Declare structs
  struct ComicInstance {
    address ozuGenerative;
    address ozuCuts;
    address creator;
    mapping(uint256 => mapping(address => bool)) hasMinted;
  }


  // declare variables
  address private _generativeContract;
  address private _cutsContract;
  address private _verifier;

  mapping(uint256 => ComicInstance) private _comics;


  // Declare Events
  event VerifierChanged(address newVerifier);
  event GenerativeContractChanged(address newGenerativeContract);
  event CutsContractChanged(address newCutsContract);
  
  event ComicCreated(
    uint256 comicId
  );

  event EpisodeCreated(
    uint256 comicId,
    uint256 episodeId
  );

  event EpisodeMinted(
    uint256 comicId,
    uint256 episodeId,
    uint256[] cutsIds,
    uint256[] templateIds
  );


  // declare modifier
  modifier onlyComicCreator(uint256 comicId) {
    require(_comics[comicId].creator == msg.sender, "Ozu Comics: not creator");
    _;
  }


  // Contract functions
  constructor(address __generativeContract, address __cutsContract, address __verifier) {
    _generativeContract = __generativeContract;
    _cutsContract = __cutsContract;
    _verifier = __verifier;
  }

  /**
   * @dev return the address used for message verification
   */
  function getMessageVerifier() public view override returns (address) {
    return _verifier;
  }

  /**
   * @dev change the address that verifies the message
   */
  function changeMessageVerifier(address newVerifier) public override onlyOwner {
    _verifier = newVerifier;
    emit VerifierChanged(newVerifier);
  }

  /**
   * @dev return the address used for deploying generative proxies
   */
  function getGenerativeContract() public view override returns (address) {
    return _generativeContract;
  }

  /**
   * @dev change the address used for deploying generative proxies
   */
  function changeGenerativeContract(address newGenerativeContract) public override onlyOwner {
    _generativeContract = newGenerativeContract;
    emit GenerativeContractChanged(newGenerativeContract);
  }

  /**
   * @dev return the address used for deploying Cuts proxies
   */
  function getCutsContract() public view override returns (address) {
    return _cutsContract;
  }

  /**
   * @dev change the address used for deploying Cuts proxies
   */
  function changeCutsContract(address newCutsContract) public override onlyOwner {
    _cutsContract = newCutsContract;
    emit CutsContractChanged(newCutsContract);
  }

  /**
   * @dev return the address used for deploying Cuts proxies
   */
  function getComicInfo(uint256 comicId) public view override returns (address, address, address) {
    return (_comics[comicId].ozuGenerative, _comics[comicId].ozuCuts, _comics[comicId].creator);
  }


  /**
   * @dev Function to create a comic
   * @param comicId the id of the comic to create
   * @param dataGenerative the data representing the init function for generative contract
   * @param dataCuts the data representing the init function for cuts contract
   */
  function createComic(uint256 comicId, bytes memory dataGenerative, bytes memory dataCuts, bytes calldata signature) external override returns (address, address) {
    require(_comics[comicId].ozuGenerative == address(0) && _comics[comicId].ozuCuts == address(0), "Comic already exists");
    require(_verify(_createComicHash(comicId, dataGenerative, dataCuts, msg.sender), signature), "Signature cannot be verified");

    // deploy proxy of the 2 contracts
    address generativeCollection = Clones.clone(_generativeContract);
    address cutsCollection = Clones.clone(_cutsContract);

    _comics[comicId].ozuGenerative = generativeCollection;
    _comics[comicId].ozuCuts = cutsCollection;
    _comics[comicId].creator = msg.sender;

    // check if data exists
    if (dataGenerative.length > 0 && dataCuts.length > 0) {
      // call initialize on collection
      (bool success, ) = generativeCollection.call(dataGenerative);
      (bool successBis, ) = cutsCollection.call(dataCuts);
      require(success && successBis, "Cannot deploy subCollections");
      emit ComicCreated(comicId);
      return (generativeCollection, cutsCollection);
    } else {
      revert("Factory: init data not provided");
    }
  }

  /**
   * @dev Function to mint an episode
   * @param comicId the id of the comic
   * @param episodeId the id of the episode to mint
   * @param templateIds The list of template ids to mint
   */
  function mintEpisode(uint256 comicId, uint256 episodeId, uint256[] calldata cutsIds, uint256[] calldata amounts, uint256[] calldata templateIds, bytes calldata signature) external override {
    address sender = msg.sender;
    require(_comics[comicId].hasMinted[episodeId][sender] == false, "sender has already minted");
    require(_verify(_mintHash(comicId, episodeId, cutsIds, amounts, templateIds, msg.sender), signature), "Signature cannot be verified");

    // get contracts
    IOzuCuts ozuCuts = IOzuCuts(_comics[comicId].ozuCuts);
    IOzuGenerative ozuGenerative = IOzuGenerative(_comics[comicId].ozuGenerative);

    // call contract to mint
    if(cutsIds.length > 0 && amounts.length > 0){
      ozuCuts.mintTokens(cutsIds, amounts, sender);
    }
    if(templateIds.length > 0) {
      ozuGenerative.mintTokens(templateIds.length, sender);
    }

    // now user has minted
    _comics[comicId].hasMinted[episodeId][sender] = true;

    emit EpisodeMinted(comicId, episodeId, cutsIds, templateIds);
  }

  function _verify(bytes32 digest, bytes memory signature)
    internal
    view
    returns (bool)
  {
    return (_verifier == ECDSA.recover(digest, signature));
  }

  /**
   * @dev get the hash of data to sign to mint an episode
   */
  function _mintHash(
    uint256 comicId, 
    uint256 episodeId, 
    uint256[] calldata cutsIds, 
    uint256[] calldata amounts, 
    uint256[] calldata templateIds,
    address sender
  ) internal pure returns (bytes32) {
    return (
      ECDSA.toEthSignedMessageHash(
        keccak256(abi.encodePacked(comicId, episodeId, cutsIds, amounts, templateIds, sender))
      )
    );
  }

  /**
   * @dev get the hash of data to sign to create a comic
   */
  function _createComicHash(
    uint256 comicId, 
    bytes memory dataGenerative, 
    bytes memory dataCuts, 
    address sender
  ) internal pure returns (bytes32) {
    return (
      ECDSA.toEthSignedMessageHash(
        keccak256(abi.encodePacked(comicId, dataGenerative, dataCuts, sender))
      )
    );
  }
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
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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

pragma solidity ^0.8.0;

interface IOzuComics {

  function getMessageVerifier() external view returns (address);

  function changeMessageVerifier(address newVerifier) external;

  function getGenerativeContract() external view returns (address);

  function changeGenerativeContract(address newGenerativeContract) external;

  function getCutsContract() external view returns (address);

  function changeCutsContract(address newCutsContract) external;

  function getComicInfo(uint256 comicId) external view returns (address, address, address);

  function createComic(uint256 comicId, bytes memory dataGenerative, bytes memory dataCuts, bytes calldata signature) external returns (address, address);

  function mintEpisode(uint256 comicId, uint256 episodeId,uint256[] calldata cutsIds, uint256[] calldata amounts, uint256[] calldata templateIds, bytes calldata signature) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOzuCuts {

  function initializeContract(string memory __baseURI, address __minter, address __owner) external;

  function baseURI() external view returns(string memory);

  function changeBaseURI(string memory newURI) external returns(bool);

  function changeMinter(address newMinter) external returns (bool);

  function mintTokens(uint256[] memory tokenIds, uint256[] memory amounts, address to) external returns (bool);

  function burn(address from, uint256 tokenId, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOzuGenerative {

  function initializeContract(string memory __name, string memory __symbol, string memory __baseURI, address __minter, address __owner) external;

  function baseURI() external view returns(string memory);

  function changeBaseURI(string memory newURI) external returns(bool);

  function changeMinter(address newMinter) external returns (bool);

  function mintTokens(uint256 quantity, address to) external returns (bool);

  function burn(uint256 tokenId) external returns (bool);
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