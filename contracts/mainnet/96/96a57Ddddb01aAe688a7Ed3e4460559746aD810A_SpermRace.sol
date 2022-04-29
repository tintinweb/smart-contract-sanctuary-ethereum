// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SpermRace is Ownable {
    using ECDSA for bytes32;

    uint internal immutable MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    IERC721 spermGameContract;

    mapping(uint => uint) public eggTokenIdToSpermTokenIdBet;
    mapping(uint => bool) public uniqueTokenIds;

    bool inProgress;
    bool enforceRaceEntrySignature;

    uint public constant TOTAL_EGGS = 1778;
    uint public constant TOTAL_SUPPLY = 8888;

    uint public maxParticipantsInRace = 4000;
    uint public numOfFertilizationSpermTokens = 2;
    uint public raceEntryFee = 0 ether;
    uint public bettingFee = 0 ether;

    uint[] public tokenIdParticipants;
    uint[] public raceRandomNumbers;
    uint[] public participantsInRound;
    uint[] public fertilizedTokenIds = new uint[]((TOTAL_EGGS / 256) + 1);

    address private operatorAddress;

    constructor(address _spermGameContractAddress) {
        spermGameContract = IERC721(_spermGameContractAddress);
        operatorAddress = msg.sender;
        inProgress = false;
        enforceRaceEntrySignature = false;
    }

    function enterRace(uint[] calldata tokenIds, bytes[] calldata signatures) external payable enforceMaxParticipantsInRace(tokenIds.length) enforceSignatureEntry(tokenIds, signatures) {
        require(inProgress, "Sperm race is not in progress");
        require(msg.value >= raceEntryFee, "Insufficient fee supplied to enter race");
        for (uint i = 0; i < tokenIds.length; i++) {
            require((tokenIds[i] % 5) != 0, "One of the supplied tokenIds is not a sperm");
            require(spermGameContract.ownerOf(tokenIds[i]) == msg.sender, "Not the owner of one or more of the supplied tokenIds");

            tokenIdParticipants.push(tokenIds[i]);
        }
    }

    function fertilize(uint eggTokenId, uint[] calldata spermTokenIds, bytes[] memory signatures) external {
        require(!inProgress, "Sperm race is ongoing");

        require((eggTokenId % 5) == 0, "Supplied eggTokenId is not an egg");
        require(spermGameContract.ownerOf(eggTokenId) == msg.sender, "Not the owner of the egg");
        require(spermTokenIds.length == numOfFertilizationSpermTokens, "Must bring along the correct number of sperms");
        require(spermTokenIds.length == signatures.length, "Each sperm requires a signatures");
        require(!isFertilized(eggTokenId), "Egg tokenId is already fertilized");

        setFertilized(eggTokenId);

        for (uint i = 0; i < spermTokenIds.length; i++) {
            require((spermTokenIds[i] % 5) != 0, "One or more of the supplied spermTokenIds is not a sperm");
            isTokenInFallopianPool(spermTokenIds[i], signatures[i]);
            require(!isFertilized(spermTokenIds[i]), "One of the spermTokenIds has already fertilized an egg");
            setFertilized(spermTokenIds[i]);
        }
    }

    function bet(uint eggTokenId, uint spermTokenId) external payable {
        require(!inProgress || (raceRandomNumbers.length == 0), "Race is already in progress");
        require(msg.value >= bettingFee, "Insufficient fee to place bet");
        require(spermGameContract.ownerOf(eggTokenId) == msg.sender, "Not the owner of the egg");
        require((eggTokenId % 5) == 0, "Supplied eggTokenId is not an egg");
        require((spermTokenId % 5) != 0, "Supplied spermTokenId is not a sperm");

        eggTokenIdToSpermTokenIdBet[eggTokenId] = spermTokenId;
    }

    function calculateTraitsFromTokenId(uint tokenId) public pure returns (uint) {
        if ((tokenId == 409) || (tokenId == 1386) || (tokenId == 1499) || (tokenId == 1556) || (tokenId == 1971) || (tokenId == 2561) || (tokenId == 3896) || (tokenId == 4719) || (tokenId == 6044) || (tokenId == 6861) || (tokenId == 8348) || (tokenId == 8493)) {
            return 12;
        }

        uint magicNumber = 69420;
        uint iq = (uint(keccak256(abi.encodePacked(tokenId, magicNumber, "IQ"))) % 4) + 1;
        uint speed = (uint(keccak256(abi.encodePacked(tokenId, magicNumber, "Speed"))) % 4) + 1;
        uint strength = (uint(keccak256(abi.encodePacked(tokenId, magicNumber, "Strength"))) % 4) + 1;

        return iq + speed + strength;
    }

    function progressRace(uint num) external onlyOwner {
        require(inProgress, "Races must be in progress to progress");
        uint randomNumber = random(tokenIdParticipants.length);
        for (uint i = 0; i < num; i++) {
            randomNumber >>= 8;
            raceRandomNumbers.push(randomNumber);
            participantsInRound.push(tokenIdParticipants.length);
        }
    }

    function toggleRace() external onlyOwner {
        inProgress = !inProgress;
    }

    function setOperatorAddress(address _address) external onlyOwner {
        operatorAddress = _address;
    }

    function resetRace() external onlyOwner {
        require(!inProgress, "Sperm race is ongoing");

        delete tokenIdParticipants;
        delete raceRandomNumbers;
        delete participantsInRound;
        fertilizedTokenIds = new uint[]((TOTAL_EGGS / 256) + 1);
    }

    function leaderboard(uint index) external view returns (uint[] memory, uint[] memory) {
        uint[] memory leaders = new uint[](participantsInRound[index]);
        uint[] memory progress = new uint[](participantsInRound[index]);
        uint[] memory tokenRaceTraits = new uint[](8888);

        // copy over all the tokenIdParticipants into the leader array
        // calculate all the battle traits one time
        for (uint i = 0; i < participantsInRound[index]; i++) {
            leaders[i] = tokenIdParticipants[i];
            tokenRaceTraits[tokenIdParticipants[i]] = calculateTraitsFromTokenId(tokenIdParticipants[i]);
        }

        // Fisher-Yates shuffle
        for (uint k = 0; k < participantsInRound[index]; k++) {
            uint randomIndex = raceRandomNumbers[index] % (participantsInRound[index] - k);
            uint randomValA = leaders[randomIndex];
            uint randomValB = progress[randomIndex];

            leaders[randomIndex] = leaders[k];
            leaders[k] = randomValA;

            progress[randomIndex] = progress[k];
            progress[k] = randomValB;
        }

        for (uint j = 0; j < participantsInRound[index]; j = j + 2) {
            // You are a winner if you're the edge case in a odd number of tokenIdParticipants
            if (j == (participantsInRound[index] - 1)) {
                progress[j]++;
            } else {
                uint scoreA = tokenRaceTraits[leaders[j]];
                uint scoreB = tokenRaceTraits[leaders[j+1]];

                if ((raceRandomNumbers[index] % (scoreA + scoreB)) < scoreA) {
                    progress[j]++;
                } else {
                   progress[j+1]++;
                }
            }
        }

       return (leaders, progress);
    }

    function setMaxParticipantsInRace(uint _maxParticipants) external onlyOwner {
        maxParticipantsInRace = _maxParticipants;
    }

    function setNumOfFertilizationSpermTokens(uint _numOfTokens) external onlyOwner {
        numOfFertilizationSpermTokens = _numOfTokens;
    }

    function setRaceEntryFee(uint _entryFee) external onlyOwner {
        raceEntryFee = _entryFee;
    }

    function setBettingFee(uint _bettingFee) external onlyOwner {
        bettingFee = _bettingFee;
    }

    function setEnforceRaceEntrySignature (bool _enableSignature) external onlyOwner {
        enforceRaceEntrySignature = _enableSignature;
    }

    function getTokenIdParticipants() external view returns (uint[] memory) {
        return tokenIdParticipants;
    }

    function random(uint seed) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(tx.origin, blockhash(block.number - 1), block.timestamp, seed)));
    }

    function isValidSignature(bytes32 hash, bytes memory signature) internal view returns (bool isValid) {
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return signedHash.recover(signature) == operatorAddress;
    }

    function isTokenInFallopianPool(uint tokenId, bytes memory signature) internal view {
        bytes32 msgHash = keccak256(abi.encodePacked(tokenId));
        require(isValidSignature(msgHash, signature), "Invalid signature");
    }

    function isFertilized(uint tokenId) public view returns (bool) {
        uint[] memory bitMapList = fertilizedTokenIds;
        uint partitionIndex = tokenId / 256;
        uint partition = bitMapList[partitionIndex];
        if (partition == MAX_INT) {
            return true;
        }
        uint bitIndex = tokenId % 256;
        uint bit = partition & (1 << bitIndex);
        return (bit != 0);
    }

    function setFertilized(uint tokenId) internal {
        uint[] storage bitMapList = fertilizedTokenIds;
        uint partitionIndex = tokenId / 256;
        uint partition = bitMapList[partitionIndex];
        uint bitIndex = tokenId % 256;
        bitMapList[partitionIndex] = partition | (1 << bitIndex);
    }

    function numOfRounds() external view returns (uint) {
        return raceRandomNumbers.length;
    }

    function numOfParticipants() external view returns (uint) {
        return tokenIdParticipants.length;
    }

    modifier enforceMaxParticipantsInRace(uint num) {
        require((tokenIdParticipants.length + num) <= maxParticipantsInRace, "Race participants has reached the maximum allowed");
        _;
    }

    modifier enforceSignatureEntry(uint[] calldata tokenIds, bytes[] calldata signatures) {
        if (enforceRaceEntrySignature) {
            require(tokenIds.length == signatures.length, "Number of signatures must match number of tokenIds");
            for (uint i = 0; i < tokenIds.length; i++) {
                bytes32 msgHash = keccak256(abi.encodePacked(tokenIds[i]));
                require(isValidSignature(msgHash, signatures[i]), "Invalid signature");
            }
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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