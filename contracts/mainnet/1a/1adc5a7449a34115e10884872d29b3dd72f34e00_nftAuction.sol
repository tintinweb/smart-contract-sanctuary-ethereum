/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

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

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)



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



interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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


//https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155.sol";

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)





/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)





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


// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)





/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

//import "../openzeppelin-4.7.3/contracts/math/SafeMath.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";
//import "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
/**
 * copyright DATARTIFACT https://www.datartifact.com
 * created for Average Life ~ https://averagelife.art
 */

contract nftAuction is EIP712 {

    AggregatorV3Interface internal priceFeed;
    address public priceFeedAddressEthUsd;
    address public auctionAddress;
    address payable public ownerAddress;
    string private constant SIGNING_DOMAIN = "Nft-Auction";
    string private constant SIGNATURE_VERSION = "1";

    //buy OTC
    struct NFTBatchVoucher {
      string nftAddress;
      string projectName;
      string ids;
      uint256 minPrice;
      bytes signature;
    }

    //amount is in $, price is in ETH
    struct price{
      uint32 Amount;
      uint32 pct50Amount;
      uint32 pct70Amount;
      uint32 pct80Amount;
      uint32 Num;
      uint32 pct50Num;
      uint32 pct70Num;
      uint32 pct80Num;
    }

    mapping (address => price) public nftPrices;
    mapping (address => address) public nftCollectionOwner;
    mapping (address => mapping(uint256 => address)) public registeredPrints;

    modifier onlyOwner() { require(ownerAddress == msg.sender, "caller is not the owner"); _; }
    error InvalidAmount (uint256 sent, uint256 minRequired);

    constructor(address _from, address _nftAddress)EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION){

      //live
      priceFeedAddressEthUsd = address(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

      priceFeed = AggregatorV3Interface(priceFeedAddressEthUsd);
      auctionAddress = address(this);
      ownerAddress = payable(msg.sender);
      //nftAddress = _nftAddress;
      //_from = Average Life owner address that holds nft's for sale
      setNftOwner(_nftAddress, _from);
      setPrices(_nftAddress,800,400,240,160,1,1,4,9);
    }

    //allow this contract to sell nft's from _from
    function setNftOwner(address _nftAddress, address _from) public onlyOwner(){
        nftCollectionOwner[_nftAddress] = _from;
        //don't forget to call approval on nft contract for from address
    }


    function setPrices(
      address _nftAddress, uint32 _Amount, uint32 _pct50Amount, uint32 _pct70Amount,uint32 _pct80Amount,
      uint32 _Num, uint32 _pct50Num, uint32 _pct70Num,uint32 _pct80Num
    ) public onlyOwner{
      // amount in usd
      price storage _price = nftPrices[_nftAddress];
      _price.Amount = _Amount;
      _price.pct50Amount = _pct50Amount;
      _price.pct70Amount = _pct70Amount;
      _price.pct80Amount = _pct80Amount;
      // amount of nfts to buy
      _price.Num = _Num;
      _price.pct50Num = _pct50Num;
      _price.pct70Num = _pct70Num;
      _price.pct80Num = _pct80Num;

    }

    function calculateEtherPrice(int _lastPrice, uint256 _amount) public returns(uint256) {

      uint adjust_price = uint(_lastPrice) * 1e10;
      uint usd = _amount * 1e18;
      uint valueEther = (usd * 1e18) / adjust_price;
      uint256 valueWei = uint256(valueEther);
      return valueWei;
    }

    function updatePrices(address _nftAddress) public returns(uint256[4] memory) {

      int lastPrice = getLatestPriceEthUsd();

      if(lastPrice > 0){

        uint256 Price = calculateEtherPrice(lastPrice, uint256(nftPrices[_nftAddress].Amount));
        uint256 pct50Price = calculateEtherPrice(lastPrice, uint256(nftPrices[_nftAddress].pct50Amount));
        uint256 pct70Price = calculateEtherPrice(lastPrice, uint256(nftPrices[_nftAddress].pct70Amount));
        uint256 pct80Price = calculateEtherPrice(lastPrice, uint256(nftPrices[_nftAddress].pct80Amount));
        uint256[4] memory prices = [Price,pct50Price,pct70Price,pct80Price];
        return prices;
      }
      else{
          revert("Could not get USD price from Chainlink feed. Please try again later.");
      }

    }

    function getPrices(address _nftAddress) public returns(uint256[4] memory){
      uint256[4] memory prices = updatePrices(_nftAddress);
      return prices;
    }

    function getLatestPriceEthUsd() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int ethprice /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return ethprice;
    }

    function getVat(uint256 _base) public view returns (uint256) {
      uint256 vat = (_base / 100) * 21;
      return vat;
    }

    function buySingle(
      address _nftAddress,
      address _from,
      address _to,
      uint256 _id,
      uint256 _amount,
      bytes memory _data
    ) public payable{

      uint256[4] memory prices = updatePrices(_nftAddress);
      uint256 vat = getVat(prices[0]);
      uint256 minimumbid = prices[0] + vat;
      if(msg.value >= minimumbid){
        IERC1155(_nftAddress).safeTransferFrom(_from,_to,_id,_amount,_data);
      }
      else{
        revert InvalidAmount({
                sent: _amount,
                minRequired: minimumbid
        });
      }


    }

    function buy(
      address _nftAddress,
      uint256[] memory _ids,
      uint256[] memory _amounts,
      bytes memory _data) public payable{

      if(_ids.length == 0){revert("No tokens.");}
      if(nftCollectionOwner[_nftAddress] == address(0)){revert("No from address.");}
      address to = msg.sender;
      uint256 value = msg.value;
      _buy(to, value, _nftAddress, _ids, _amounts, _data);
    }

    //this function will revert if tokens are not present at from address or from address is not set
    function _buy(
      address _to,
      uint256 _value,
      address _nftAddress,
      uint256[] memory _ids,
      uint256[] memory _amounts,
      bytes memory _data) internal{

      uint256 minimumbid;
      address from = nftCollectionOwner[_nftAddress];

      uint256[4] memory prices = updatePrices(_nftAddress);

      if(_ids.length == nftPrices[_nftAddress].Num){
        minimumbid = prices[0];
      }
      else if(_ids.length == nftPrices[_nftAddress].pct50Num){
        minimumbid = prices[1] * _ids.length;
      }
      else if(_ids.length == nftPrices[_nftAddress].pct70Num){
        minimumbid = prices[2] * _ids.length;
      }
      else if(_ids.length == nftPrices[_nftAddress].pct80Num){
        minimumbid = prices[3] * _ids.length;
      }
      //prevent buying more than max
      else if(_ids.length > nftPrices[_nftAddress].pct80Num){
        revert("Dont be too greedy.");
      }
      else{
        minimumbid = prices[0] * _ids.length;
      }

      uint256 vat = getVat(minimumbid);
      uint256 minimumbidvatincl = minimumbid + vat;

      if(_value >= minimumbidvatincl){
        IERC1155(_nftAddress).safeBatchTransferFrom(from, _to, _ids, _amounts, _data);
      }
      else{
        revert InvalidAmount({
                sent: _value,
                minRequired: minimumbidvatincl
        });
      }
    }

    function withdraw() public onlyOwner{

      ownerAddress.transfer(auctionAddress.balance);

    }

    function redeemBatch(
      address _nftAddress,
      NFTBatchVoucher calldata voucher,
      uint256[] memory _ids,
      uint256[] memory _amounts,
      bytes memory data) public payable returns (uint256[] memory) {
      // make sure signature is valid and get the address of the signer
      address signer = _verifyBatch(voucher);

      // make sure that the signer is authorized to sell these NFTs
      require(nftCollectionOwner[_nftAddress] == signer, "Signature invalid or unauthorized");

      // make sure that the redeemer is paying enough to cover the buyer's cost
      require(msg.value >= voucher.minPrice, "Insufficient funds to redeem");
      //can't pass calldata
      //from,to,...
      IERC1155(_nftAddress).safeBatchTransferFrom(signer, msg.sender, _ids, _amounts, data);
      return _ids;
    }

    function _batchhash(NFTBatchVoucher calldata voucher) internal view returns (bytes32) {
      return _hashTypedDataV4(keccak256(abi.encode(
        keccak256("NFTBatchVoucher(string nftAddress,string projectName,string ids,uint256 minPrice)"),
        keccak256(bytes(voucher.nftAddress)),
        keccak256(bytes(voucher.projectName)),
        keccak256(bytes(voucher.ids)),
        voucher.minPrice
      )));
    }

    function _verifyBatch(NFTBatchVoucher calldata voucher) internal view returns (address) {
      bytes32 digest = _batchhash(voucher);
      return ECDSA.recover(digest, voucher.signature);
    }

    function _ownerOf(address _nftAddress,uint256 tokenId) internal view returns (bool) {
      return IERC1155(_nftAddress).balanceOf(msg.sender, tokenId) != 0;
    }

    function registerPrint(address _nftAddress,uint256 tokenId) public{
      if(_ownerOf(_nftAddress,tokenId)){
        if(registeredPrints[_nftAddress][tokenId] == address(0)){
          registeredPrints[_nftAddress][tokenId] = msg.sender;
        }else{revert("Print already registered.");}

      }else{revert("Not owner of token.");}

    }

}