// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/*

▄▄▄█████▓ ██░ ██ ▓█████     ██░ ██ ▓█████  ██▓  ██████ ▄▄▄█████▓
▓  ██▒ ▓▒▓██░ ██▒▓█   ▀    ▓██░ ██▒▓█   ▀ ▓██▒▒██    ▒ ▓  ██▒ ▓▒
▒ ▓██░ ▒░▒██▀▀██░▒███      ▒██▀▀██░▒███   ▒██▒░ ▓██▄   ▒ ▓██░ ▒░
░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄    ░▓█ ░██ ▒▓█  ▄ ░██░  ▒   ██▒░ ▓██▓ ░ 
  ▒██▒ ░ ░▓█▒░██▓░▒████▒   ░▓█▒░██▓░▒████▒░██░▒██████▒▒  ▒██▒ ░ 
  ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░    ▒ ░░▒░▒░░ ▒░ ░░▓  ▒ ▒▓▒ ▒ ░  ▒ ░░   
    ░     ▒ ░▒░ ░ ░ ░  ░    ▒ ░▒░ ░ ░ ░  ░ ▒ ░░ ░▒  ░ ░    ░    
  ░       ░  ░░ ░   ░       ░  ░░ ░   ░    ▒ ░░  ░  ░    ░      
          ░  ░  ░   ░  ░    ░  ░  ░   ░  ░ ░        ░           
                                                                
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../Models/PaymentsShared.sol";
import "../Interfaces/I_TokenCharacter.sol"; 

contract BuyCharactersPhased is Ownable, PaymentsShared {

    using ECDSA for bytes32;

    //phases
    enum PHASE{ PAUSED, ONE, TWO, PUBLIC }
    PHASE public currentPhase = PHASE.PAUSED;

    uint256 public constant MAX_MINTABLE = 10000;
    uint256 public TOKEN_PRICE = 0.09 ether;

    uint256 public P1_TOKENS_PER_MINT = 1;
    uint256 public MINTS_PER_TRANSACTION = 5;

    I_TokenCharacter tokenCharacter;
    
    //events
    event SalePhaseChanged(uint256 newStage);

    //Allowlist verification
    address authority;
    string salt = "ALLOW_LIST_HEIST";

    mapping(address => uint8) public ALMints;

    constructor(address _tokenCharacterAddress, address signer) {
        tokenCharacter = I_TokenCharacter(_tokenCharacterAddress);
        authority = signer;
    }

    function buy(uint8 amountToBuy, bytes memory signature) external payable {

        require(amountToBuy > 0, "Buy at least 1");
        require(msg.sender == tx.origin,"EOA only");

        //check price and soft supply
        require(msg.value >= TOKEN_PRICE * amountToBuy,"Not enough ETH");
        require(tokenCharacter.totalSupply() + amountToBuy < MAX_MINTABLE + 1,"Sold out");

        //phase 1: AL + wallet limit
        if (currentPhase == PHASE.ONE)
        {
            require(verifySignature(signature, msg.sender), "Wrong signature");
            require(ALMints[msg.sender] + amountToBuy < P1_TOKENS_PER_MINT + 1,"Over AL allocation");
            ALMints[msg.sender] += amountToBuy;
        }
        //phase 2: AL + transaction limit
        else if (currentPhase == PHASE.TWO)
        {
            require (amountToBuy < MINTS_PER_TRANSACTION + 1,"Over max per transaction");
            require(verifySignature(signature, msg.sender), "Wrong signature");
        }
        //phase 3: public + transaction limit
        else if (currentPhase == PHASE.PUBLIC)
        {
            require(amountToBuy < MINTS_PER_TRANSACTION + 1,"Over max per transaction");
        }
        else 
        {
            revert("Sale is not live");
        }

        //Do minting
        tokenCharacter.Mint(amountToBuy, msg.sender);

    }

    function getPrice() external view returns (uint256) {
      return TOKEN_PRICE;
    }

    //Variables
    function setPrice(uint256 newPrice) external onlyOwner {
      TOKEN_PRICE = newPrice;
    }

    function setPhase1Amount(uint256 newAmount) external onlyOwner {
      P1_TOKENS_PER_MINT = newAmount;
    }

    function setTransactionLimit(uint256 newAmount) external onlyOwner {
      MINTS_PER_TRANSACTION = newAmount;
    }

    //Allowlist minting
    function verifySignature (bytes memory signature, address senderAddress)
        internal view returns (bool)
    {
        //generate message, hash it, and compare signature
        bytes memory message = abi.encodePacked(senderAddress,salt);
        bytes32 messagehash = keccak256(message);
        address signingAddress = messagehash.toEthSignedMessageHash().recover(signature);

        return signingAddress == authority;
    }

    function setSalt(string memory newSalt) external onlyOwner {
        salt = newSalt;
    }

    function setSigner(address newSigningAddress) external onlyOwner {
        authority = newSigningAddress;
    }

    //Start phases and pause 
    function pauseSale() external onlyOwner {
      currentPhase = PHASE.PAUSED;
      emit SalePhaseChanged(uint256(currentPhase));
    }

    function getPhase() external view returns (uint256) {
      return uint256(currentPhase);
    }

    function getWalletMints(address minter) external view returns (uint256) {
      return ALMints[minter];
    }

    function startPhaseOne() external onlyOwner {
      currentPhase = PHASE.ONE;
      emit SalePhaseChanged(uint256(currentPhase));
    }

    function startPhaseTwo() external onlyOwner {
      currentPhase = PHASE.TWO;
      emit SalePhaseChanged(uint256(currentPhase));
    }

    function startPublicSale() external onlyOwner {
      currentPhase = PHASE.PUBLIC;
      emit SalePhaseChanged(uint256(currentPhase));
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//simple payments handling for splitting between fixed wallets
contract PaymentsShared is Ownable, ReentrancyGuard {

    address WalletA = 0x0939D5c0DAb578ae7DA3cf11bfd4b7e5dc53CD45;
    address WalletB = 0x670c38d686DA822bcc96c565ceE1DD7E007D1544;
    address WalletC = 0x42D2339cA21C7D5df409326068c5CE5975dB5A39;
    address WalletD = 0xBa643BE38D25867E2062890ee5D42aA6879F5586;

    //payments
    function withdrawAll() external nonReentrant onlyOwner {          

        uint256 ticks = address(this).balance / 1000;

        (bool success, ) = WalletA.call{value: ticks * 250}(""); //25%
        require(success, "Transfer failed.");

        payable(WalletB).transfer(ticks * 100); //10%
        payable(WalletC).transfer(ticks * 325); //32.5%
        payable(WalletD).transfer(address(this).balance); //32.5%
    }

    function withdrawSafety() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//Interface for characters NFT
interface I_TokenCharacter {

    function Mint(uint8, address) external; //amount, to
    
    function totalSupply() external view returns (uint256);
    function setApprovalForAll(address, bool) external;  //address, operator
    function transferFrom(address, address, uint256) external;
    function ownerOf(uint256) external view returns (address); //who owns this token
    function _ownerOf16(uint16) external view returns (address);

    function addController(address) external;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}