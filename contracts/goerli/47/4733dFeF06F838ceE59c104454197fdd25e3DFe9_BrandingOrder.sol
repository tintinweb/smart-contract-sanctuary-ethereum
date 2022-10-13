// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract Adminer {
  address private _adminer;

  constructor() {
    _adminer = msg.sender;
  }

  modifier onlyAdminer() {
    require(adminer() == msg.sender, "Adminer: caller is not the owner");
    _;
  }

  function adminer() public view virtual returns (address) {
    return _adminer;
  }

  function transferOwnership(address newAdminer) public virtual onlyAdminer {
    require(newAdminer != address(0), "Adminer: new owner is the zero address");
    _adminer = newAdminer;
  }
}

contract BrandingOrder is Adminer {
  struct Order {
    OrderInfo info;
    bytes signature;
  }

  struct OrderInfo {
    string id;
    uint256 orderType;
    address owner;
    address contractAddress;
    uint256 tokenId;
    uint256 price;
    uint256 amount;
    uint256 createTime;
    uint256 effectTime;
  }

  struct OrderFulfill {
    string id;
    address owner;
    uint256 amount;
    uint256 time;
  }

  WETH public weth = WETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

  uint256 private _platformFee;

  string[] private _orderIds;

  mapping (string => OrderFulfill[]) private _fulfillsMap;

  mapping (string => bool) private _cancelMap;

  constructor(uint256 platformFee) {
    setPlatformFee(platformFee);
  }

  function verifyOrder(Order calldata order) public pure returns (bool) {
    OrderInfo calldata info = order.info;
    bytes32 hash = keccak256(abi.encodePacked(
      info.id,
      info.orderType,
      info.owner,
      info.contractAddress,
      info.tokenId,
      info.price,
      info.amount,
      info.createTime,
      info.effectTime
    ));
    bytes32 message = ECDSA.toEthSignedMessageHash(hash);
    address signatureOwner = ECDSA.recover(message, order.signature);
    return signatureOwner == info.owner;
  }

  function fulfillOrder(Order calldata order, uint256 amount) external payable {
    require(verifyOrder(order), "Order verification failed");

    OrderInfo calldata info = order.info;
    address owner = info.owner;

    require(owner != msg.sender, "Sender should not be the owner");
    require(!checkHasCanceled(info), "Order has canceled");
    require(!checkHasExpired(info), "Order has expired");
    require(getRemainAmount(info) >= amount, "Insufficient number of remaining");

    if (info.orderType == 0) {
      ERC1155(info.contractAddress).safeTransferFrom(owner, msg.sender, info.tokenId, amount, order.signature);

      uint256 totalPrice = amount * info.price;
      require(msg.value >= totalPrice, "Underpayment");

      (bool ownerReceiveSuccess, ) = payable(owner).call{ value: (totalPrice / 100) * (100 - _platformFee) }("");
      require(ownerReceiveSuccess, "Owner failed to receive eth");

      if (msg.value > totalPrice) {
        (bool returnSuccess, ) = msg.sender.call{ value: msg.value - totalPrice }("");
        require(returnSuccess, "Sender failed to receive eth");
      }
    } else if (info.orderType == 1) {
      ERC1155(info.contractAddress).safeTransferFrom(msg.sender, owner, info.tokenId, amount, order.signature);

      uint256 totalPrice = amount * info.price;
      uint256 platformReceiveBalance = (totalPrice / 100) * _platformFee;

      weth.transferFrom(owner, address(this), platformReceiveBalance);
      weth.transferFrom(owner, msg.sender, totalPrice - platformReceiveBalance);
    }

    string calldata orderId = info.id;
    OrderFulfill memory fulfill = OrderFulfill(orderId, msg.sender, amount, block.timestamp);
    _fulfillsMap[orderId].push(fulfill);

    if (_fulfillsMap[orderId].length == 1) {
      _orderIds.push(orderId);
    }
  }

  function cancelOrder(Order[] calldata orders) external {
    for (uint i = 0; i < orders.length; i++) {
      Order calldata order = orders[i];
      OrderInfo calldata info = order.info;

      require(msg.sender == info.owner, "Sender must be the owner");
      require(verifyOrder(order), "Order verification failed");
      
      _cancelMap[info.id] = true;
    }
  }

  function getRemainAmount(OrderInfo calldata info) public view returns (uint256) {
    uint256 remainAmount = info.amount;
    OrderFulfill[] memory fulfills = _fulfillsMap[info.id];
    for (uint256 index = 0; index < fulfills.length; index++) {
      remainAmount -= fulfills[index].amount;
    }
    return remainAmount;
  }

  function checkHasFinished(OrderInfo calldata info) public view returns (bool) {
    return getRemainAmount(info) == 0;
  }

  function checkHasCanceled(OrderInfo calldata info) public view returns (bool) {
    return _cancelMap[info.id];
  }

  function checkHasExpired(OrderInfo calldata info) public view returns (bool) {
    return info.createTime + info.effectTime < block.timestamp;
  }

  function checkIsValid(OrderInfo calldata info) public view returns (bool) {
    return !(checkHasFinished(info) || checkHasCanceled(info) || checkHasExpired(info));
  }

  function getOrderFulfills(string calldata orderId) public view returns (OrderFulfill[] memory) {
    return _fulfillsMap[orderId];
  }

  function getOrderFulfills(address owner) public view returns (OrderFulfill[] memory) {
    OrderFulfill[] memory fulfills = new OrderFulfill[](0);
    for (uint256 index = 0; index < _orderIds.length; index++) {
      OrderFulfill[] memory _fulfills = _fulfillsMap[_orderIds[index]];
      for (uint256 _index = 0; _index < _fulfills.length; _index++) {
        OrderFulfill memory fulfill = _fulfills[_index];
        if (fulfill.owner == owner) {
          fulfills = _fulfillsPush(fulfills, fulfill);
        }
      }
    }
    return fulfills;
  }

  function _fulfillsPush(OrderFulfill[] memory fulfills, OrderFulfill memory fulfill) private pure returns(OrderFulfill[] memory) {
    OrderFulfill[] memory temp = new OrderFulfill[](fulfills.length + 1);
    for (uint256 index = 0; index < fulfills.length; index++) {
      temp[index] = fulfills[index];
    }
    temp[temp.length - 1] = fulfill;
    return temp;
  }

  function setPlatformFee(uint256 platformFee) public onlyAdminer {
    require(platformFee <= 100, "Platform fee is error");
    _platformFee = platformFee;
  }

  function withdraw() external onlyAdminer {
    weth.transferFrom(
      address(this),
      msg.sender,
      weth.balanceOf(address(this))
    );
    (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		require(success, "Withdraw fail");
  }

  fallback() external payable {}
  receive() external payable {}
}

interface ERC1155 {
  function balanceOf(address owner, uint256 tokenId) external returns (uint256);
	function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}

interface WETH {
  function balanceOf(address owner) external returns (uint256);
	function transferFrom(address from, address to, uint256 balance) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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