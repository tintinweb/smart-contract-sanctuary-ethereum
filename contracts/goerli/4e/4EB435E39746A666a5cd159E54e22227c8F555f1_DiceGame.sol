// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./BaseGame.sol";

contract DiceGame is Ownable, BaseGame {
    using ECDSA for bytes32;

    /* ============ Structs ============ */

    struct Game {
        uint256 fee;
        PlayerInfo player1;
        PlayerInfo player2;
        address winner;
        uint8[] results;
    }

    /* ============ State Variables ============ */

    mapping(bytes32 => Game) public games;

    constructor(address _vault, uint16 _fee) BaseGame(_vault, _fee) {
        this;
    }

    /* ============ Views ============ */

    /**
     * @param _gameId GameId to get results
     * @notice Returns game result with winner address
     * @return Address of winner
     */
    function getGameResults(bytes32 _gameId) public view returns (address,uint8[] memory) {
        return (games[_gameId].winner,games[_gameId].results);
    }

    /* ============ Game Functions ============ */

    function newGame(
        PlayerInfo calldata player1,
        PlayerInfo calldata player2,
        uint256 nonce,
        bytes memory signature
    ) external override notUsedNonce(nonce) {
        uint256 fee = getFee(player1, player2);
        require(player1.ethBalance >= fee, "DICE: Insufficient Player1 Eth Balance");
        require(player2.ethBalance >= fee, "DICE: Insufficient Player2 Eth Balance");

        bytes32 gameId = keccak256(abi.encode(address(this), player1, player2, nonce));
        require(gameId.toEthSignedMessageHash().recover(signature) == verifier, "DICE: Invalid signature");

        lockAssets(player1, player2, nonce);

        Game storage game = games[gameId];
        game.player1 = player1;
        game.player2 = player2;
        game.fee = fee;

        emit NewGame(gameId, player1, player2);
    }

    function endGame(
        bytes32 gameId,
        address winner,
        uint8[] memory results,
        bytes memory signature
    ) external override {
        bytes32 _hash = keccak256(abi.encode(address(this), gameId, winner));
        require(_hash.toEthSignedMessageHash().recover(signature) == verifier, "DICE: Invalid signature");

        Game storage game = games[gameId];
        game.winner = winner;
        game.results = results;

        PlayerInfo memory player1 = game.player1;
        PlayerInfo memory player2 = game.player2;
        unlockAssets(player1, player2);

        // If draw happens, BE will send ZERO address as the winner
        if (winner == address(0x0)) {
            emit GameOver(gameId, 0, address(0x0));
            return;
        }
        require(winner == player1.player || winner == player2.player, "DICE: Invalid winner address");
        PlayerInfo memory loser = winner == player1.player ? player2 : player1;
        vault.setMatchResult(winner, loser.player, loser.ethBalance, game.fee, loser.tokens, loser.tokenIds);

        emit GameOver(gameId, 0, winner);
    }

    function emergencyEndGame(bytes32 gameId) external override onlyOwner {
        Game memory game = games[gameId];
        require(game.player1.player != address(0x0), "invalid game id");
        require(game.winner == address(0x0), "it's a finished game");

        unlockAssets(game.player1, game.player2);

        emit GameOver(gameId, 0, address(0x0));
    }
}

// SPDX-License-Identifier: MIT
/*solhint-disable*/
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../interfaces/IVault.sol";

contract BaseGame is Ownable {
    using ECDSA for bytes32;

    struct PlayerInfo {
        address player;
        address[] tokens;
        uint256[] tokenIds;
        uint256 ethBalance;
    }

    IVault public vault;

    address public verifier;

    /// @dev Our protocol cut fees at the end of every game from winner. base 10000
    uint16 public feeRate;

    mapping(uint256 => bool) private usedNonce;

    /* ============ Events ============ */

    event NewGame(bytes32 indexed gameId, PlayerInfo player1, PlayerInfo player2);
    event GameOver(bytes32 indexed gameId, uint256 indexed requestId, address winner);

    modifier notUsedNonce(uint256 nonce) {
        require(usedNonce[nonce] == false, "expired nonce");
        _;
    }

    constructor(address _vault, uint16 fee) {
        vault = IVault(_vault);
        feeRate = fee;
    }

    function setVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "invalid verifier address");
        verifier = _verifier;
    }

    function setFee(uint16 newFee) external onlyOwner {
        require(newFee <= 10000, "invalid fee");
        feeRate = newFee;
    }

    function lockAssets(
        PlayerInfo calldata player1,
        PlayerInfo calldata player2,
        uint256 nonce
    ) internal {
        usedNonce[nonce] = true;
        vault.lockAssets(player1.player, player1.tokens, player1.tokenIds, player1.ethBalance);
        vault.lockAssets(player2.player, player2.tokens, player2.tokenIds, player2.ethBalance);
    }

    function unlockAssets(PlayerInfo memory player1, PlayerInfo memory player2) internal {
        vault.unlockAssets(player1.player, player1.tokens, player1.tokenIds, player1.ethBalance);
        vault.unlockAssets(player2.player, player2.tokens, player2.tokenIds, player2.ethBalance);
    }

    function newGame(
        PlayerInfo calldata player1,
        PlayerInfo calldata player2,
        uint256 nonce,
        bytes memory signature
    ) external virtual {}

    function endGame(
        bytes32 gameId,
        address winner,
        uint8[] memory results,
        bytes memory signature
    ) external virtual {}

    function emergencyEndGame(bytes32 gameId) external virtual onlyOwner {}

    /**
     * @notice Function to get fees from 2 players info
     * @return Fee
     */
    function getFee(PlayerInfo memory player1, PlayerInfo memory player2) internal view returns (uint256) {
        if (vault.feeType() == IVault.FeeType.FixedFee) {
            return vault.fee();
        } else if (vault.feeType() == IVault.FeeType.RatedFee) {
            return ((player1.ethBalance + player2.ethBalance) * vault.fee()) / 10000;
        }
        return 0;
    }

    function verifyMessage(bytes32 hash, bytes memory signature) external pure returns (address) {
        return hash.toEthSignedMessageHash().recover(signature);
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
pragma solidity ^0.8.16;

import "../interfaces/IController.sol";

interface IVault {
    enum FeeType {
        NoFee,
        FixedFee,
        RatedFee
    }

    function feeType() external view returns (FeeType);

    function fee() external view returns (uint256);

    function controller() external view returns (IController);

    function lockAssets(
        address _user,
        address[] calldata _tokens,
        uint256[] calldata _tokenIds,
        uint256 _ethAmount
    ) external;

    function lockFairSpin(address[] memory _users, uint256[] memory _ethAmounts) external;

    function unlockAssets(
        address _user,
        address[] calldata _tokens,
        uint256[] calldata _tokenIds,
        uint256 _ethAmount
    ) external;

    function unlockFairSpin(address[] calldata _users, uint256[] calldata _ethAmounts) external;

    function setMatchResult(
        address _winner,
        address _loser,
        uint256 _ethValue,
        uint256 _fee,
        address[] calldata _tokens,
        uint256[] calldata _tokenIds
    ) external;

    function setFairSpinResult(
        address _winner,
        address[] memory _losers,
        uint256[] memory _ethValues,
        uint256 total,
        uint256 _fee
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IController {
    function isGameContract(address) external view returns (bool);
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