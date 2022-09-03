// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./redstone/PriceAware.sol";

import "./libraries/Bet.sol";
import "./libraries/Constants.sol";

contract BinaryBet is PriceAware {
    function isSignerAuthorized(address _receivedSigner) public view virtual override returns (bool) {
        return _receivedSigner == 0xf786a909D559F5Dee2dc6706d8e5A81728a39aE9; // redstone-rapid
    }

    function isTimestampValid(uint256 _receivedTimestamp) public view virtual override returns (bool) {
        return true;
    }

    struct Take {
        uint256 amount;
        uint256 end;
    }

    address public maker;

    uint256 public lastEnd;
    uint256 public issued;
    uint256 public volume;
    string public symbol;

    Bet.Details public details;

    mapping(uint256 => Take) public takes;

    address public immutable hackabetInstance;

    event Claim();
    event Exercise(uint256 id);

    modifier onlyHackabet() {
        require(msg.sender == hackabetInstance, "only hackabet");
        _;
    }

    modifier onlyMaker() {
        require(msg.sender == maker, "only maker");
        _;
    }

    constructor(address _hackabetInstance) {
        require(_hackabetInstance != address(0), "hackabet invalid");
        hackabetInstance = _hackabetInstance;
        lastEnd = type(uint128).max;
    }

    function initAndTake(
        address maker_,
        address taker,
        uint256 amount,
        uint256 volume_,
        string memory symbol_,
        bytes calldata detailsPacked
    ) external returns (uint256 id) {
        require(lastEnd == 0, "already initialized");
        maker = maker_;
        volume = volume_;
        symbol = symbol_;
        details = Bet.unpackBetDetails(detailsPacked);

        return take(taker, amount);
    }

    function take(address taker, uint256 amount) public onlyHackabet returns (uint256 id) {
        require(issued + amount <= volume, "volume not available");

        issued += amount;
        uint256 end = lastEnd = block.timestamp + details.period;
        id = takeId(taker, block.number);

        takes[id] = Take({ amount: takes[id].amount + amount, end: end });

        return id;
    }

    function claim() external onlyMaker {
        require(block.timestamp > lastEnd, "not expired");

        (uint256 price, uint256 timestamp) = getPriceFromMsg(bytes32(bytes(symbol)));

        require(lastEnd <= timestamp && timestamp <= lastEnd + details.window, "incorrect oracle timestamp");

        if (details.up) {
            require(price <= details.price, "Price passed");
        } else {
            require(price >= details.price, "Price passed");
        }

        uint256 balance = IERC20(Constants.USDC).balanceOf(address(this));
        require(balance > 0, "nothing to claim");

        emit Claim();

        IERC20(Constants.USDC).transfer(maker, balance);
    }

    function exercise(uint256 id) external {
        (uint256 price, uint256 timestamp) = getPriceFromMsg(bytes32(bytes(symbol)));

        (uint256 amount, uint256 end) = (takes[id].amount, takes[id].end);

        require(end <= timestamp && timestamp <= end + details.window, "incorrect oracle timestamp");
        require(amount > 0, "amount is 0");

        if (details.up) {
            require(price >= details.price, "Price not passed");
        } else {
            require(price <= details.price, "Price not passed");
        }

        takes[id].amount = 0;
        takes[id].end = 0;

        emit Exercise(id);

        IERC20(Constants.USDC).transfer(addressFromId(id), amount);
    }

    function takeId(address taker, uint256 blockNumber) public pure returns (uint256) {
        require(blockNumber < (1 << 64), "blockNumber too high");
        return (uint256(uint160(taker)) << 64) | blockNumber;
    }

    function addressFromId(uint256 id) internal pure returns (address) {
        return address(uint160(id >> 64));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

library Bet {
    struct Details {
        bool up;
        uint256 price;
        uint256 period;
        uint256 window;
    }

    function unpackBetDetails(bytes calldata details) internal pure returns (Details memory out) {
        require(details.length == 128, "Invalid details length");
        // solhint-disable no-inline-assembly
        assembly {
            calldatacopy(add(out, sub(0x20, 32)), details.offset, 32)
            calldatacopy(add(out, sub(0x40, 32)), add(details.offset, 32), 32)
            calldatacopy(add(out, sub(0x60, 32)), add(details.offset, 64), 32)
            calldatacopy(add(out, sub(0x80, 32)), add(details.offset, 96), 32)
        }
    }

    function packBinaryBetDetails(Details memory details) internal pure returns (bytes memory) {
        return abi.encodePacked(details.up, details.price, details.period, details.window);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

library Constants {
    address public constant USDC = 0x7e020F035eAAE2dFCA821Cc58ec240fbf658a7f3;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract PriceAware {
    using ECDSA for bytes32;

    uint256 constant _MAX_DATA_TIMESTAMP_DELAY = 3 * 60; // 3 minutes
    uint256 constant _MAX_BLOCK_TIMESTAMP_DELAY = 15; // 15 seconds

    /* ========== VIRTUAL FUNCTIONS (MAY BE OVERRIDEN IN CHILD CONTRACTS) ========== */

    function getMaxDataTimestampDelay() public view virtual returns (uint256) {
        return _MAX_DATA_TIMESTAMP_DELAY;
    }

    function getMaxBlockTimestampDelay() public view virtual returns (uint256) {
        return _MAX_BLOCK_TIMESTAMP_DELAY;
    }

    function isSignerAuthorized(address _receviedSigner) public view virtual returns (bool);

    function isTimestampValid(uint256 _receivedTimestamp) public view virtual returns (bool) {
        // Getting data timestamp from future seems quite unlikely
        // But we've already spent too much time with different cases
        // Where block.timestamp was less than dataPackage.timestamp.
        // Some blockchains may case this problem as well.
        // That's why we add MAX_BLOCK_TIMESTAMP_DELAY
        // and allow data "from future" but with a small delay
        require(
            (block.timestamp + getMaxBlockTimestampDelay()) > _receivedTimestamp,
            "Data with future timestamps is not allowed"
        );

        return
            block.timestamp < _receivedTimestamp || block.timestamp - _receivedTimestamp < getMaxDataTimestampDelay();
    }

    /* ========== FUNCTIONS WITH IMPLEMENTATION (CAN NOT BE OVERRIDEN) ========== */

    function getPriceFromMsg(bytes32 symbol) internal view returns (uint256, uint256) {
        bytes32[] memory symbols = new bytes32[](1);
        symbols[0] = symbol;
        (uint256[] memory prices, uint256 timestamp) = getPricesFromMsg(symbols);
        return (prices[0], timestamp);
    }

    function getPricesFromMsg(bytes32[] memory symbols) internal view returns (uint256[] memory, uint256) {
        // The structure of calldata witn n - data items:
        // The data that is signed (symbols, values, timestamp) are inside the {} brackets
        // [origina_call_data| ?]{[[symbol | 32][value | 32] | n times][timestamp | 32]}[size | 1][signature | 65]

        // 1. First we extract dataSize - the number of data items (symbol,value pairs) in the message
        uint8 dataSize; //Number of data entries
        assembly {
            // Calldataload loads slots of 32 bytes
            // The last 65 bytes are for signature
            // We load the previous 32 bytes and automatically take the 2 least significant ones (casting to uint16)
            dataSize := calldataload(sub(calldatasize(), 97))
        }

        // 2. We calculate the size of signable message expressed in bytes
        // ((symbolLen(32) + valueLen(32)) * dataSize + timeStamp length
        uint16 messageLength = uint16(dataSize) * 64 + 32; //Length of data message in bytes

        // 3. We extract the signableMessage

        // (That's the high level equivalent 2k gas more expensive)
        // bytes memory rawData = msg.data.slice(msg.data.length - messageLength - 65, messageLength);

        bytes memory signableMessage;
        assembly {
            signableMessage := mload(0x40)
            mstore(signableMessage, messageLength)
            // The starting point is callDataSize minus length of data(messageLength), signature(65) and size(1) = 66
            calldatacopy(add(signableMessage, 0x20), sub(calldatasize(), add(messageLength, 66)), messageLength)
            mstore(0x40, add(signableMessage, 0x20))
        }

        // 4. We first hash the raw message and then hash it again with the prefix
        // Following the https://github.com/ethereum/eips/issues/191 standard
        bytes32 hash = keccak256(signableMessage);
        bytes32 hashWithPrefix = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

        // 5. We extract the off-chain signature from calldata

        // (That's the high level equivalent 2k gas more expensive)
        // bytes memory signature = msg.data.slice(msg.data.length - 65, 65);
        bytes memory signature;
        assembly {
            signature := mload(0x40)
            mstore(signature, 65)
            calldatacopy(add(signature, 0x20), sub(calldatasize(), 65), 65)
            mstore(0x40, add(signature, 0x20))
        }

        // 6. We verify the off-chain signature against on-chain hashed data

        address signer = hashWithPrefix.recover(signature);
        require(isSignerAuthorized(signer), "Signer not authorized");

        // 7. We extract timestamp from callData

        uint256 dataTimestamp;
        assembly {
            // Calldataload loads slots of 32 bytes
            // The last 65 bytes are for signature + 1 for data size
            // We load the previous 32 bytes
            dataTimestamp := calldataload(sub(calldatasize(), 98))
        }

        // 8. We validate timestamp
        require(isTimestampValid(dataTimestamp), "Data timestamp is invalid");

        return _readFromCallData(symbols, uint256(dataSize), messageLength, dataTimestamp);
    }

    function _readFromCallData(
        bytes32[] memory symbols,
        uint256 dataSize,
        uint16 messageLength,
        uint256 timestamp
    ) private pure returns (uint256[] memory, uint256) {
        uint256[] memory values;
        uint256 i;
        uint256 j;
        uint256 readyAssets;
        bytes32 currentSymbol;

        // We iterate directly through call data to extract the values for symbols
        assembly {
            let start := sub(calldatasize(), add(messageLength, 66))

            values := msize()
            mstore(values, mload(symbols))
            mstore(0x40, add(add(values, 0x20), mul(mload(symbols), 0x20)))

            for {
                i := 0
            } lt(i, mload(symbols)) {
                i := add(i, 1)
            } {
                currentSymbol := mload(add(add(symbols, 32), mul(i, 32)))
                for {
                    j := 0
                } lt(j, dataSize) {
                    j := add(j, 1)
                } {
                    if eq(calldataload(add(start, mul(j, 64))), currentSymbol) {
                        mstore(add(add(values, 32), mul(i, 32)), calldataload(add(add(start, mul(j, 64)), 32)))
                        readyAssets := add(readyAssets, 1)
                    }

                    if eq(readyAssets, mload(symbols)) {
                        i := dataSize
                    }
                }
            }
        }

        return (values, timestamp);
    }
}