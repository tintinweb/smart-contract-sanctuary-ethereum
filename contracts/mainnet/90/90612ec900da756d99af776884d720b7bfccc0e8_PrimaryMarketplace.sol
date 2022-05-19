/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// Sources flattened with hardhat v2.9.2 https://hardhat.org

// File @openzeppelin/contracts/security/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}


// File contracts/interfaces/IHabitatNFT.sol


pragma solidity ^0.8.0;

interface IHabitatNFT {
  function mint(
    address account,
    uint256 id,
    uint256 amount,
    uint96 editionRoyalty,
    bytes memory data
  ) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;
  
  function burn(
    address from,
    uint256 id,
    uint256 amount
    ) external;
}


// File contracts/PrimaryMarketplace.sol


pragma solidity ^0.8.0;



contract PrimaryMarketplace is ReentrancyGuard {
  using ECDSA for bytes32;
  using Counters for Counters.Counter;

  event AddItem(uint256 indexed _itemID);
  struct Edition {
    uint256 itemId;
    address nftContract;
    uint256 tokenId;
    uint256 totalAmount;
    uint256 availableAmount;
    uint256 price;
    uint256 royalty;
    address seller;
    bool isHighestBidAuction;
  }

  mapping(uint256 => Edition) private idToEdition;
  mapping(address => bool) private creatorsWhitelist;
  mapping(address => uint256) public creatorBalances;

  Counters.Counter private _itemIds;
  AggregatorV3Interface private priceFeed;
  address private owner;

  constructor(address priceAggregatorAddress) {
    owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceAggregatorAddress);
  }

  function buyEdition(uint256 itemId, uint256 amount)
    external
    payable
    nonReentrant
    onlyAvailableEdition(itemId)
  {
    require(!idToEdition[itemId].isHighestBidAuction, "NOT_PERMITTED");
    uint256 pricePerItemInUSD = idToEdition[itemId].price;
    uint256 pricePerItem = pricePerItemInUSD * priceInWEI();
    uint256 price = pricePerItem * amount;
    require(msg.value >= price, "WRONG_PRICE");
    creatorBalances[idToEdition[itemId].seller] = msg.value;

    _safeTransfer(itemId, amount, msg.sender);
  }

  function payForBid(
    uint256 itemId,
    uint256 price,
    bytes memory signature
  ) external payable nonReentrant {
    require(idToEdition[itemId].isHighestBidAuction, "AUCTION_NOT_EXIST");
    address verifiedSigner = recoverSignerAddress(msg.sender, price, signature);
    require(verifiedSigner == owner, "NOT_AUTHORIZED");
    require(msg.value >= price * priceInWEI(), "WRONG_PRICE");
    creatorBalances[idToEdition[itemId].seller] = msg.value;
    _safeTransfer(itemId, 1, msg.sender);
  }

  function transferEdition(
    uint256 itemId,
    uint256 amount,
    address receiver
  ) external nonReentrant onlyOwner {
    _safeTransfer(itemId, amount, receiver);
  }

  function addEdition(
    address nftContract,
    uint256 tokenId,
    uint256 amount,
    uint256 price,
    uint96 royalty,
    address seller,
    bool isHighestBidAuction
  ) external nonReentrant onlyOwnerOrCreator {
    _itemIds.increment();
    uint256 itemId = _itemIds.current();

    uint256 amountToMint = amount;

    if (isHighestBidAuction) {
      amountToMint = 1;
    }

    idToEdition[itemId] = Edition(
      itemId,
      nftContract,
      tokenId,
      amountToMint,
      amountToMint,
      price,
      royalty,
      seller,
      isHighestBidAuction
    );

    emit AddItem(itemId);

    IHabitatNFT(nftContract).mint(seller, tokenId, amountToMint, royalty, "");
  }

  function addCreator(address creator) external onlyOwner {
    creatorsWhitelist[creator] = true;
  }

  function burnToken(uint256 itemId) external onlyOwnerOrCreator {
    uint256 amount = idToEdition[itemId].availableAmount;
    idToEdition[itemId].availableAmount = 0;
    IHabitatNFT(idToEdition[itemId].nftContract).burn(
      idToEdition[itemId].seller,
      idToEdition[itemId].tokenId,
      amount
    );
  }

  function withdraw(address receiver) external onlyOwnerOrCreator nonReentrant {
    uint256 amount;

    if (owner == msg.sender) {
      amount = address(this).balance;
    } else {
      amount = creatorBalances[msg.sender];
      require(amount > 0, "OUT_OF_MONEY");
      creatorBalances[msg.sender] -= amount;
    }

    payable(receiver).transfer(amount);
  }

  function closeMarket(address receiver) external onlyOwner {
    selfdestruct(payable(receiver));
  }

  function itemPrice(uint256 itemId)
    external
    view
    onlyAvailableEdition(itemId)
    returns (uint256)
  {
    uint256 pricePerItemInUSD = idToEdition[itemId].price;
    uint256 pricePerItem = pricePerItemInUSD * priceInWEI();
    return pricePerItem;
  }

  function fetchEditions() external view returns (Edition[] memory) {
    uint256 itemCount = _itemIds.current();
    uint256 currentIndex = 0;
    Edition[] memory items = new Edition[](itemCount);
    for (uint256 i = 0; i < itemCount; ) {
      Edition memory currentItem = idToEdition[i + 1];
      items[currentIndex] = currentItem;
      currentIndex += 1;

      unchecked {
        ++i;
      }
    }
    return items;
  }

  function fetchCreatorEditions(address habitatNFTCreatorAddress)
    external
    view
    returns (Edition[] memory)
  {
    uint256 itemCount = _itemIds.current();
    uint256 resultCount = 0;
    uint256 currentIndex = 0;
    for (uint256 i = 0; i < itemCount; ) {
      if (idToEdition[i + 1].nftContract == habitatNFTCreatorAddress) {
        resultCount += 1;
      }
      unchecked {
        ++i;
      }
    }
    Edition[] memory result = new Edition[](resultCount);
    for (uint256 i = 0; i < itemCount; ) {
      Edition memory currentItem = idToEdition[i + 1];

      if (currentItem.nftContract == habitatNFTCreatorAddress) {
        result[currentIndex] = currentItem;
        currentIndex += 1;
      }

      unchecked {
        ++i;
      }
    }
    return result;
  }

  function priceInWEI() public view returns (uint256) {
    return uint256(1e18 / uint256(_priceOfETH() / 10**_decimals()));
  }

  function hashTransaction(address account, uint256 price)
    internal
    pure
    returns (bytes32)
  {
    bytes32 dataHash = keccak256(abi.encodePacked(account, price));
    return
      keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash));
  }

  function recoverSignerAddress(
    address account,
    uint256 price,
    bytes memory signature
  ) internal pure returns (address) {
    bytes32 hash = hashTransaction(account, price);
    return hash.recover(signature);
  }

  function _safeTransfer(
    uint256 itemId,
    uint256 amount,
    address receiver
  ) internal {
    uint256 availableAmount = idToEdition[itemId].availableAmount;
    require(availableAmount >= amount, "OUT_OF_STOCK");

    idToEdition[itemId].availableAmount -= amount;

    IHabitatNFT(idToEdition[itemId].nftContract).safeTransferFrom(
      idToEdition[itemId].seller,
      receiver,
      idToEdition[itemId].tokenId,
      amount,
      ""
    );
  }

  function _priceOfETH() private view returns (uint256) {
    (
      uint80 roundID,
      int256 price,
      uint256 startedAt,
      uint256 timeStamp,
      uint80 answeredInRound
    ) = priceFeed.latestRoundData();
    (roundID, startedAt, timeStamp, answeredInRound);
    return uint256(price);
  }

  function _decimals() private view returns (uint256) {
    uint256 decimals = uint256(priceFeed.decimals());
    return decimals;
  }

  modifier onlyOwnerOrCreator() {
    require(
      creatorsWhitelist[msg.sender] || msg.sender == owner,
      "NOT_AUTHORIZED"
    );
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "NOT_AUTHORIZED");
    _;
  }

  modifier onlyAvailableEdition(uint256 itemId) {
    require(idToEdition[itemId].nftContract != address(0), "NOT_EXIST");
    _;
  }
}