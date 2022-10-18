// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity ^0.8.4;

import "../util/SafeMath.sol";
import "../util/SignUtil.sol";

/**
 * Auction interface
 * NOTE: The auction contract is used to bid through virtual currency to ensure fairness and fairness in the auction.
 */
interface BaseAuction {
    //publish auction. msg.value is a reserve price and deposit.
    function publish(
        address guarantee,
        bytes calldata signHex,
        uint256 endTime,
        uint256 startPrice,
        uint256 range,
        uint256 feeRate
    ) external returns (uint256 id);

    //bidding
    function bidding(uint256 id) external payable;

    //auction end
    function endAuction(uint256 id) external returns (address winner, uint256 price);

    //loser refund
    function refund(uint256 id) external;

    //withdraw deposit. sign must be one of winner or guarantee
    function withdraw(
        uint256 id,
        bytes calldata sign1,
        bytes calldata sign2,
        uint256 couponRate,
        bytes memory couponId
    ) external;

    function info(uint256 id, address user)
        external
        view
        returns (
            uint256 sysTime,
            uint256 timestamp,
            uint256 topPrice,
            uint256 myPrice
        );

    event Transfer(address indexed from, address indexed to, uint256 value);
    event VivReturnId(uint256 id);
}

/**
 * Auction implements
 */
contract VivAuction is BaseAuction {
    using SafeMath for uint256;

    struct BidInfo {
        address guarantee;
        address publisher;
        address bidder;
        bytes signKey;
        uint256 price;
        uint256 startPrice;
        uint256 range;
        uint256 timestamp;
        uint256 feeRate;
    }

    //bidId
    uint256 _bidCount;
    //bid address list
    mapping(uint256 => address[]) _losers;
    mapping(uint256 => mapping(address => uint256)) _loserBids;
    //top info
    mapping(uint256 => BidInfo) _curBid;

    mapping(bytes => bool) _couponIds;

    function getLosers(uint256 id) external view returns (address[] memory) {
        return _losers[id];
    }

    //publish auction. msg.value is a reserve price and deposit.
    //When deal finished,  is certificate for withdraw deposit
    function publish(
        address guarantee,
        bytes calldata signHex,
        uint256 endTime,
        uint256 startPrice,
        uint256 range,
        uint256 feeRate
    ) external override returns (uint256 id) {
        require(guarantee != address(0), "VIV0045");
        require(endTime > block.timestamp, "VIV0046");
        require(range > 0, "VIV0047");

        _bidCount += 1;

        //set info
        _curBid[_bidCount].publisher = msg.sender;
        _curBid[_bidCount].guarantee = guarantee;
        _curBid[_bidCount].bidder = msg.sender;
        _curBid[_bidCount].startPrice = startPrice;
        _curBid[_bidCount].range = range;
        _curBid[_bidCount].signKey = signHex;
        _curBid[_bidCount].timestamp = endTime;
        _curBid[_bidCount].feeRate = feeRate;

        emit VivReturnId(_bidCount);

        return _bidCount;
    }

    //bidding
    function bidding(uint256 id) external payable override {
        _bidding(id, block.timestamp);
    }

    function _bidding(uint256 id, uint256 currentTime) internal {
        require(_curBid[id].timestamp > currentTime, "VIV0048");
        uint256 oldPrice = _loserBids[id][msg.sender];
        if (oldPrice == 0) {
            //first bidding
            require(msg.value >= _curBid[id].startPrice, "VIV0050");
            require((msg.value - _curBid[id].startPrice) % _curBid[id].range == 0, "VIV0049");
        } else {
            require(msg.value % _curBid[id].range == 0, "VIV0049");
        }
        uint256 newPrice = oldPrice.add(msg.value);
        require(newPrice > _curBid[id].price, "VIV0051");

        //set top price
        _loserBids[id][msg.sender] = newPrice;
        _curBid[id].bidder = msg.sender;
        _curBid[id].price = newPrice;
        _losers[id].push(msg.sender);
    }

    //auction end
    function endAuction(uint256 id) external override returns (address winner, uint256 price) {
        return _endAuction(id, block.timestamp);
    }

    function _endAuction(uint256 id, uint256 currentTime) internal returns (address winner, uint256 price) {
        require(_curBid[id].timestamp <= currentTime, "VIV0052");

        //send back for loser
        for (uint256 i = 0; i < _losers[id].length; i++) {
            address loser = _losers[id][i];
            uint256 _price = _loserBids[id][loser];
            if (loser == _curBid[id].bidder) {
                //winner, continue
                continue;
            }
            if (_price > 0) {
                payable(loser).transfer(_price);
                delete _loserBids[id][loser];
                emit Transfer(address(this), loser, _price);
            }
        }

        return (_curBid[id].bidder, _curBid[id].price);
    }

    //loser refund
    function refund(uint256 id) external override {
        //not winner anytime can withdraw deposit
        require(msg.sender != _curBid[id].bidder, "VIV0053");

        //withdraw deposit
        uint256 price = _loserBids[id][msg.sender];
        require(price > 0, "VIV0054");

        payable(msg.sender).transfer(price);
        delete _loserBids[id][msg.sender];
        emit Transfer(address(this), msg.sender, price);
    }

    //withdraw deposit. sign must be one of winner or guarantee
    function withdraw(
        uint256 id,
        bytes calldata sign1,
        bytes calldata sign2,
        uint256 couponRate,
        bytes memory couponId
    ) external override {
        _withdraw(id, sign1, sign2, couponRate, couponId, block.timestamp);
    }

    function _withdraw(
        uint256 id,
        bytes calldata sign1,
        bytes calldata sign2,
        uint256 couponRate,
        bytes memory couponId,
        uint256 currentTime
    ) internal {
        BidInfo storage bid = _curBid[id];
        require(_curBid[id].timestamp <= currentTime, "VIV0052");
        require(msg.sender == bid.publisher, "VIV0055");

        //deal end
        bytes32 hashValue = ECDSA.toEthSignedMessageHash(abi.encode(bid.signKey));
        address signAddr = ECDSA.recover(hashValue, sign1);
        require(signAddr == bid.bidder || signAddr == bid.guarantee, "VIV0056");
        //service fee
        uint256 fee = bid.price.rate(bid.feeRate);
        // Calculate the discounted price when couponRate more than 0
        if (couponRate > 0) {
            // Coupon cannot be reused
            require(!_couponIds[couponId], "VIV0006");
            // Check if platform signed
            bytes32 h = ECDSA.toEthSignedMessageHash(abi.encode(couponRate, couponId, bid.signKey));
            require(SignUtil.checkSign(h, sign2, bid.guarantee), "VIV0007");
            // Use a coupon
            fee = fee.sub(fee.rate(couponRate));
            _couponIds[couponId] = true;
        }

        if (fee > 0) {
            if (bid.price < fee) {
                fee = bid.price;
            }
            payable(bid.guarantee).transfer(fee);
            emit Transfer(address(this), bid.guarantee, fee);
        }
        uint256 amount = bid.price.sub(fee);
        if (amount > 0) {
            payable(msg.sender).transfer(amount);
            emit Transfer(address(this), msg.sender, amount);
        }
        delete _curBid[id];
        delete _loserBids[id][msg.sender];
    }

    function info(uint256 id, address user)
        external
        view
        override
        returns (
            uint256 sysTime,
            uint256 endTime,
            uint256 topPrice,
            uint256 myPrice
        )
    {
        return _info(id, user, block.timestamp);
    }

    function _info(
        uint256 id,
        address user,
        uint256 currentTime
    )
        internal
        view
        returns (
            uint256 sysTime,
            uint256 endTime,
            uint256 topPrice,
            uint256 myPrice
        )
    {
        BidInfo storage bid = _curBid[id];
        return (currentTime, bid.timestamp, bid.price, _loserBids[id][user]);
    }
}

// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * Used to verify that the signature is correct
 */
library SignUtil {
    /**
     * Verify signature
     * @param hashValue hash for sign
     * @param signedValue1 signed by one of user1, user2, user3
     * @param signedValue2 signed by one of user1, user2, user3
     * @param user1 user1
     * @param user2 user2
     * @param user3 user3
     */
    function checkSign(
        bytes32 hashValue,
        bytes memory signedValue1,
        bytes memory signedValue2,
        address user1,
        address user2,
        address user3
    ) internal pure returns (bool) {
        // if sign1 equals sign2, return false
        if (_compareBytes(signedValue1, signedValue2)) {
            return false;
        }

        // address must be one of user1, user2, user3
        address address1 = ECDSA.recover(hashValue, signedValue1);
        if (address1 != user1 && address1 != user2 && address1 != user3) {
            return false;
        }
        address address2 = ECDSA.recover(hashValue, signedValue2);
        if (address2 != user1 && address2 != user2 && address2 != user3) {
            return false;
        }
        return true;
    }

    /**
     * Verify signature
     * @param hashValue hash for sign
     * @param signedValue1 signed by one of user1, user2
     * @param signedValue2 signed by one of user1, user2
     * @param user1 user1
     * @param user2 user2
     */
    function checkSign(
        bytes32 hashValue,
        bytes memory signedValue1,
        bytes memory signedValue2,
        address user1,
        address user2
    ) internal pure returns (bool) {
        // if sign1 equals sign2, return false
        if (_compareBytes(signedValue1, signedValue2)) {
            return false;
        }

        // address must be one of user1, user2
        address address1 = ECDSA.recover(hashValue, signedValue1);
        if (address1 != user1 && address1 != user2) {
            return false;
        }
        address address2 = ECDSA.recover(hashValue, signedValue2);
        if (address2 != user1 && address2 != user2) {
            return false;
        }
        return true;
    }

    /**
     * Verify signature
     * @param hashValue hash for sign
     * @param signedValue signed by user
     * @param user User to be verified
     */
    function checkSign(
        bytes32 hashValue,
        bytes memory signedValue,
        address user
    ) internal pure returns (bool) {
        address signedAddress = ECDSA.recover(hashValue, signedValue);
        if (signedAddress != user) {
            return false;
        }
        return true;
    }

    /**
     * compare bytes
     * @param a param1
     * @param b param2
     */
    function _compareBytes(bytes memory a, bytes memory b) private pure returns (bool) {
        bytes32 s;
        bytes32 d;
        assembly {
            s := mload(add(a, 32))
            d := mload(add(b, 32))
        }
        return (s == d);
    }
}

// SPDX-License-Identifier: MIT
// Viv Contracts

pragma solidity ^0.8.4;

/**
 * Standard signed math utilities missing in the Solidity language.
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * it means: 100*2‱ = 100*2/10000
     */
    function rate(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(mul(a, b), 10000);
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