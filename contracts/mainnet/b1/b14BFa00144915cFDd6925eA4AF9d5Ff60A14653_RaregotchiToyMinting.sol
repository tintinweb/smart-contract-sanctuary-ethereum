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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface RaregotchiToyInterface {
    function batchMint(
        address destinationAddress,
        uint256[] calldata tokenIds
    ) external;
    function isOpen(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RaregotchiToyInterface.sol";

contract RaregotchiToyMinting is Ownable {
    RaregotchiToyInterface toyContract;

    uint16 public totalTokens = 3000;
    uint16 public totalSupply = 0;

    uint256 public mintPrice = 0.25 ether;

    bool private isFrozen = false;

    address public signerAddress;

    mapping(uint8 => mapping(address => uint8)) public mintedPerWalletByStage;
    mapping(uint16 => uint16) private tokenMatrix;

    modifier callerIsUser() {
        // solium-disable-next-line security/no-tx-origin
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
     * @dev Allows to withdraw the Ether in the contract
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Set the pet contract address
     */
    function setToyContractAddress(address _address) external onlyOwner {
        toyContract = RaregotchiToyInterface(_address);
    }

    /**
     * @dev Set the total amount of tokens
     */
    function setTotalTokens(uint16 _totalTokens) external onlyOwner {
        totalTokens = _totalTokens;
    }

    /**
     * @dev Set the mint price
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * @dev Sets the address that generates the signatures for whitelisting
     */
    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    function devMint(address _to, uint16[] calldata _tokenIds)
        external
        onlyOwner
    {
        uint256[] memory tokenIds = new uint256[](_tokenIds.length);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            useTokenId(_tokenIds[i]);
            tokenIds[i] = _tokenIds[i];
        }

        totalSupply += uint16(tokenIds.length);
        toyContract.batchMint(_to, tokenIds);
    }

    function marketingMint(uint16 amount) external onlyOwner {
        require(totalSupply < totalTokens, "Not tokens left to be minted");

        uint16 _amount = amount;

        if (totalSupply + _amount > totalTokens) {
            _amount = totalTokens - totalSupply;
        }

        uint256[] memory tokenIds = new uint256[](_amount);

        uint16 tmpTotalMintedTokens = totalSupply;
        totalSupply += _amount;

        for (uint256 i; i < _amount; i++) {
            tokenIds[i] = _getTokenToBeMinted(tmpTotalMintedTokens);
            tmpTotalMintedTokens++;
        }

        toyContract.batchMint(msg.sender, tokenIds);
    }

    function mint(
        uint8 amount,
        uint8 stage,
        uint8 maxAmount,
        uint256 fromTimestamp,
        bytes calldata signature
    ) external payable callerIsUser {
        bytes32 messageHash = generateMintHash(
            amount,
            stage,
            maxAmount,
            msg.sender,
            fromTimestamp
        );
        address recoveredWallet = ECDSA.recover(messageHash, signature);
        require(
            recoveredWallet == signerAddress,
            "Invalid signature for the caller"
        );
        require(block.timestamp >= fromTimestamp, "Too early to mint");
        require(totalSupply < totalTokens, "Not tokens left to be minted");
        require(amount > 0, "At least one token should be minted");

        uint8 _amount = amount;

        if (totalSupply + _amount > totalTokens) {
            _amount = uint8(totalTokens - totalSupply);
        }

        require(
            mintedPerWalletByStage[stage][msg.sender] + _amount <= maxAmount,
            "Caller cannot mint more tokens"
        );

        uint256 totalMintPrice = mintPrice * _amount;

        require(
            msg.value >= totalMintPrice,
            "Not enough Ether to mint the tokens"
        );

        if (msg.value > totalMintPrice) {
            payable(msg.sender).transfer(msg.value - totalMintPrice);
        }

        uint256[] memory tokenIds = new uint256[](_amount);

        uint16 tmpTotalMintedTokens = totalSupply;
        mintedPerWalletByStage[stage][msg.sender] += _amount;
        totalSupply += _amount;

        for (uint256 i; i < _amount; i++) {
            tokenIds[i] = _getTokenToBeMinted(tmpTotalMintedTokens);
            tmpTotalMintedTokens++;
        }

        toyContract.batchMint(msg.sender, tokenIds);
    }

    function getAvailableTokens() public view returns (uint16) {
        return totalTokens - totalSupply;
    }

    // Private and Internal functions

    function generateMintHash(
        uint8 amount,
        uint8 stage,
        uint8 maxAmount,
        address _address,
        uint256 _fromTimestamp
    ) internal pure returns (bytes32) {
        bytes32 _hash = keccak256(
            abi.encodePacked(
                _address, // 20 bytes
                _fromTimestamp, // 32 bytes(uint256)
                amount, // 1 byte (uint8)
                stage, // 1 byte (uint8)
                maxAmount // 1 bytes (uint16)
            )
        );

        bytes memory result = abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            _hash
        );

        return keccak256(result);
    }

    /**
     * @dev Returns a random available token to be minted
     *
     * Code used as reference:
     * https://github.com/1001-digital/erc721-extensions/blob/main/contracts/RandomlyAssigned.sol
     */
    function _getTokenToBeMinted(uint16 _totalMintedTokens)
        private
        returns (uint16)
    {
        uint16 maxIndex = totalTokens - _totalMintedTokens;
        uint16 random = _getRandomNumber(maxIndex, _totalMintedTokens);

        uint16 tokenId = tokenMatrix[random];

        if (tokenMatrix[random] == 0) {
            tokenId = random;
        }

        tokenMatrix[maxIndex - 1] == 0
            ? tokenMatrix[random] = maxIndex - 1
            : tokenMatrix[random] = tokenMatrix[maxIndex - 1];

        return tokenId + 1;
    }

    function useTokenId(uint16 _id) private {
        uint16 maxIndex = totalTokens - totalSupply;
        uint16 nonRandom = _id - 1;

        uint16 tokenId = tokenMatrix[nonRandom];

        if (tokenMatrix[nonRandom] == 0) {
            tokenId = nonRandom;
        }

        tokenMatrix[maxIndex - 1] == 0
            ? tokenMatrix[nonRandom] = maxIndex - 1
            : tokenMatrix[nonRandom] = tokenMatrix[maxIndex - 1];
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint16 _upper, uint16 _totalMintedTokens)
        private
        view
        returns (uint16)
    {
        uint16 random = uint16(
            uint256(
                keccak256(
                    abi.encodePacked(
                        _totalMintedTokens,
                        blockhash(block.number - 1),
                        block.coinbase,
                        block.difficulty,
                        msg.sender
                    )
                )
            )
        );

        return random % _upper;
    }
}