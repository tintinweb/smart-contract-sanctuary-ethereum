// SPDX-License-Identifier: MIT
pragma solidity >0.8.4;

// sign ref https://etherscan.io/address/0x3028b3a1133ba8dd499f37ef6b0158f8bc38f849#code
// sign vr, v, r, s
// note: v might be 0, but it should be 27 or 28

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libs/NftTokenHandler.sol";
import "./libs/ECDSA.sol";
import {IRoyaltyFeeManager} from "./royalty/IRoyaltyFeeManager.sol";

contract NftTrade is ReentrancyGuard, Ownable{
  using ECDSA for bytes32;
  using SafeMath for uint256;
  enum SellMethod { NOT_FOR_SELL, FIXED_PRICE, SELL_TO_HIGHEST_BIDDER, SELL_WITH_DECLINING_PRICE, ACCEPT_OFFER }

  struct Base {
    uint256 value;
  }

  struct Sale {
    address currency;
    address nftContract;
    uint256 tokenId;
    uint256 quantity;
    uint256 price;            // Declining: starting price, Fixed: exact price, Highest: starting Price.
    uint256 acceptMinPrice;   // offered price must greater or equal acceptMinPrice in all SellMethod.

    SellMethod method;

    address seller;
    address buyer; // Sale buyer address, if specified.
    uint256 nonce;
    uint256 beginTime;
    uint256 expireTime;
    uint256 maxFee;
  }
  
  struct Offer {
    address currency;
    address nftContract;
    uint256 tokenId;
    uint256 quantity;
    uint256 price;
    
    SellMethod method;

    address seller; // Offer seller address, if specified.
    address buyer;
    uint256 nonce;
    uint256 beginTime;
    uint256 expireTime;
  }

  event Dealed (
    address currency,
    address indexed nftContract,
    uint256 indexed tokenId,
    uint256 quantity,
    SellMethod method,
    address seller,
    address buyer,
    uint256 sellerNonce,
    uint256 buyerNonce,
    uint256 dealedPrice,
    uint256 dealedTime,
    uint256 indexed orderId
  );

  event DealedDetail (
    uint256 price,
    uint256 acceptMinPrice,
    uint256 saleBeginTime,
    uint256 saleExpireTime,
    uint256 offerBeginTime,
    uint256 offerExpireTime,        
    uint256 maxFee,
    uint256 realRevenue,
    uint256 roalityFee,
    address roalityFeeReceiver,
    uint256 serviceFee,
    address serviceFeeReceiver,
    uint256 indexed orderId
  );

  event DealedIndexing (
    bytes32 indexed tokenIndex,
    uint256 indexed orderId
  );

  event NonceUsed(
    address user,
    uint nonce
  );


  bytes32 private constant SALE_TYPE_HASH = keccak256("Sale(address currency,address nftContract,uint256 tokenId,uint256 quantity,uint256 price,uint256 acceptMinPrice,uint8 method,address seller,address buyer,uint256 nonce,uint256 beginTime,uint256 expireTime,uint256 maxFee,bytes data)");

  bytes32 private constant OFFER_TYPE_HASH = keccak256("Offer(address currency,address nftContract,uint256 tokenId,uint256 quantity,uint256 price,uint8 method,address seller,address buyer,uint256 nonce,uint256 beginTime,uint256 expireTime,bytes data)");
  bytes32 private constant EIP712_DOMAIN_TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

  string public name;
  string public version;
  uint256 private latestOrderId = 0;

  mapping (address => mapping (uint256 => bool)) private _nonceOfSigning;

  //Royalty Fee Manager, refers to the structure of https://looksrare.org/
  IRoyaltyFeeManager public royaltyFeeManager;

  //The fees charged from the protocol (250 = 2.5%, 100 = 1%)
  uint256 public adminFee = 250;

  address public adminFeeReceiver;

  constructor(string memory _name, string memory _version, address _royaltyFeeManager) {
    name = _name;
    version = _version;
    royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
    adminFeeReceiver = owner();

    uint256 id;
    assembly {
      id := chainid()
    }
  }

  function getChainID() private view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  function indexToken(address nftContract, uint256 tokenId) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(nftContract, tokenId));
  }

  function hashPacked(bytes32 data) private view returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        "\x19\x01",
        _deriveDomainSeparator(),
        data
      ));
  }


  function hashSale(Sale memory sale, bytes memory data) private pure returns (bytes32) {
    return keccak256(
      abi.encode(
        SALE_TYPE_HASH,
        sale,
        keccak256(data)
      ));
  }

  function hashOffer(Offer memory offer, bytes memory data) private pure returns (bytes32) {
    return keccak256(
      abi.encode(
        OFFER_TYPE_HASH,
        offer,
        keccak256(data)
      ));
  }

  function _validateSale(Sale memory sale, bytes memory data, bytes memory saleSig) private view returns (bool) {
    return hashPacked(hashSale(sale, data)).recover(saleSig) == sale.seller;
  }

  function _validateOffer(Offer memory offer, bytes memory data, bytes memory offerSig) private view returns (bool) {
    return hashPacked(hashOffer(offer, data)).recover(offerSig) == offer.buyer;
  }

  function _dealPayments(
    uint256 price,
    uint256 roality,
    uint256 comission
  ) private pure returns (uint256[3] memory) {

    uint256 serviceFee = price
      .mul(comission).div(10000);

    uint256 sellerEarned = price
      .sub(roality)
      .sub(serviceFee);

    return [sellerEarned, roality, serviceFee];
  }

  function _payByPayable(address[3] memory receivers, uint256[3] memory payments) private {
      
    if(payments[0] > 0) payable(receivers[0]).transfer(payments[0]); // seller : sellerEarned
    if(payments[1] > 0) payable(receivers[1]).transfer(payments[1]); // roalityAccount : roalityFee
    if(payments[2] > 0) payable(receivers[2]).transfer(payments[2]); // serviceAccount : serviceFee
      
  }

  function _payByERC20(
    address erc20Contract, 
    address buyer,
    uint256 price,
    address[3] memory receivers, 
    uint256[3] memory payments) private {
    
    IERC20 money = IERC20(erc20Contract);
    require(money.balanceOf(buyer) >= price, "Buyer doesn't have enough money to pay.");
    require(money.allowance(buyer, address(this)) >= price, "Buyer allowance isn't enough.");

    money.transferFrom(buyer, address(this), price);
    if(payments[0] > 0) money.transfer(receivers[0], payments[0]); // seller : sellerEarned
    if(payments[0] > 0) money.transfer(receivers[1], payments[1]); // roalityAccount : roalityFee
    if(payments[0] > 0) money.transfer(receivers[2], payments[2]); // serviceAccount : serviceFee

  }

  // condition 1/4: direct sell (msg.sender = buyer)
  // condition 2/4: auction highest bid (msg.sender = marketplace)
  // condition 3/4: auction decling (msg.sender = buyer)
  // condition 4/4: make offer (msg.sender = seller) 
  function _deal(
    Sale memory sale, bytes memory saleSig,
    Offer memory offer, bytes memory offerSig,
    bytes memory data
  ) internal returns (uint256) {

    /* calculate hash if necessary. */
    if (offer.buyer != msg.sender) {
      require(_validateOffer(offer, data, offerSig), "Invalid offer signature");
    }
    if (sale.seller != msg.sender) {
      require(_validateSale(sale, data, saleSig), "Invalid seller signature");
    }
    // require offer not expire
    require(block.timestamp >= offer.beginTime, "Sale not available yet");
    require(block.timestamp < offer.expireTime, "Sale has expired");
    // require sale not expire
    require(block.timestamp >= sale.beginTime, "Sale not available yet");
    require(block.timestamp < sale.expireTime, "Sale has expired");

    require(sale.currency == offer.currency, "Trading currency mismatch");
    require(sale.nftContract == offer.nftContract, "Trading contract mismatch");
    require(sale.tokenId == offer.tokenId, "Trading token ID mismatch");
    require(sale.quantity == offer.quantity, "Trading quantity mismatch");
    require(sale.buyer == address(0) || sale.buyer == offer.buyer, "Trading buyer mismatch");
    require(offer.seller == address(0) || offer.seller == sale.seller, "Trading seller mismatch");

    
    require(sale.method != SellMethod.NOT_FOR_SELL, "Incorrect sale method");
    require(offer.price >= sale.acceptMinPrice, "Offered price lower than expected");

    //Nonce check
    require(_nonceOfSigning[sale.seller][sale.nonce] == false, "sale nonce has been used");
    require(_nonceOfSigning[offer.buyer][offer.nonce] == false, "offer nonce has been used");

    _nonceOfSigning[sale.seller][sale.nonce] = true;
    _nonceOfSigning[offer.buyer][offer.nonce] = true;
    
    //
    // Deal flow
    //

    ++latestOrderId;
    uint dealedPrice = priceOf(sale, offer);

    (address royaltyFeeRecipient, uint256 royaltyFeeAmount) = royaltyFeeManager.calculateRoyaltyFeeAndGetRecipient(sale.nftContract, sale.tokenId, dealedPrice);
    uint256[3] memory payments = _dealPayments(dealedPrice, /* roality */ royaltyFeeAmount, /* comission */ adminFee);
    address[3] memory receivers = [sale.seller, /* roality */ royaltyFeeRecipient, /* comission */ adminFeeReceiver];
    
    //check maxFee
    require((payments[1] + payments[2]) * 10000 / dealedPrice <= sale.maxFee, "maxFee error");

    // require buyer has enough eth or weth
    if(sale.currency == address(0)) {
      if(sale.method == SellMethod.FIXED_PRICE) {
        require(offer.price == msg.value, "Offered price incorrect");
        require(msg.value == dealedPrice, "Payment amount incorrect");
        _payByPayable(receivers, payments);
      } else if(sale.method == SellMethod.SELL_WITH_DECLINING_PRICE){
        require(offer.price == msg.value, "Offered price incorrect");
        require(msg.value >= dealedPrice, "Payment amount incorrect");
        _payByPayable(receivers, payments);
        // return exchanges
        if(msg.value > dealedPrice) {
          payable(msg.sender).transfer(msg.value - dealedPrice);
        }
      } else {
        revert("wrong method");
      }
    } 
    else {
      if(sale.method == SellMethod.FIXED_PRICE || sale.method == SellMethod.ACCEPT_OFFER) {
        require(offer.price == dealedPrice, "Offered price incorrect");
        _payByERC20(sale.currency, offer.buyer, dealedPrice, receivers, payments);
      } else if(sale.method == SellMethod.SELL_TO_HIGHEST_BIDDER ) {
        require(offer.price == dealedPrice, "Offered price incorrect");
        _payByERC20(sale.currency, offer.buyer, dealedPrice, receivers, payments);
      } else if(sale.method == SellMethod.SELL_WITH_DECLINING_PRICE ) {
        require(offer.price >= dealedPrice, "Offered price incorrect");
        _payByERC20(sale.currency, offer.buyer, dealedPrice, receivers, payments);
      } else {
        revert("wrong method");
      }
    }

    NftTokenHandler.transfer(sale.nftContract, sale.tokenId, sale.quantity, sale.seller, offer.buyer, data);

    endEvent(sale, offer, payments, receivers, dealedPrice);
    
    return latestOrderId;
  }

  function endEvent (Sale memory sale, Offer memory offer, uint256[3] memory payments, address[3] memory receivers, uint256 _dealedPrice) private {
     emit Dealed(
      sale.currency ,
      sale.nftContract,
      sale.tokenId,
      sale.quantity,
      sale.method,
      sale.seller,
      offer.buyer,
      sale.nonce,
      offer.nonce,
      _dealedPrice,   
      block.timestamp, 
      latestOrderId
    );
    emit DealedDetail(
      _dealedPrice,
      sale.acceptMinPrice,
      sale.beginTime,
      sale.expireTime,
      offer.beginTime,
      offer.expireTime,
      sale.maxFee,
      payments[0],      // revenue
      payments[1],      // roalityFee 
      receivers[1],  // roalityAccount, 
      payments[2],      // serviceFee
      receivers[2],  // serviceAccount
      latestOrderId
    );
    emit DealedIndexing(
      indexToken(sale.nftContract, sale.tokenId), 
      latestOrderId
    );

    emit NonceUsed(
      sale.seller,
      sale.nonce
    );

    emit NonceUsed(
      offer.buyer,
      offer.nonce
    );
  }


  function deal(
    Sale memory sale, bytes memory saleSig,
    Offer memory offer, bytes memory offerSig,
    bytes memory data
  ) public nonReentrant payable returns (uint256) {
    return _deal(
      sale, saleSig, 
      offer, offerSig,
      data
    );
  }
  function _deriveDomainSeparator() private view returns (bytes32) {
        uint256 chainId;
        chainId = getChainID();
        return keccak256(
            abi.encode(
              EIP712_DOMAIN_TYPE_HASH,
              keccak256(bytes(name)),
              keccak256(bytes(version)),
              chainId,
              address(this)
            )
        );
    }
  function priceOf(Sale memory sale, Offer memory offer) public view returns (uint256) {   
    if(sale.method == SellMethod.FIXED_PRICE) {
      return sale.price;
    }else if(sale.method == SellMethod.SELL_WITH_DECLINING_PRICE) {
      return decliningPrice(
        sale.beginTime,
        sale.expireTime,
        sale.price,
        sale.acceptMinPrice,
        block.timestamp
      );
    }else if(sale.method == SellMethod.SELL_TO_HIGHEST_BIDDER) {
      return offer.price;
    }else if(sale.method == SellMethod.ACCEPT_OFFER) {
      return offer.price;
    }else{
      revert("wrong method");
    }
  }
  function decliningPrice(
    uint256 beginTime,
    uint256 expireTime,
    uint256 startingPrice,
    uint256 endingPrice,
    uint256 targetTime
  ) public pure returns (uint256) {
      return startingPrice.sub(
        targetTime.sub(beginTime)
        .mul(startingPrice.sub(endingPrice))
        .div(expireTime.sub(beginTime)));
  }
  function validateSale (Sale memory sale, bytes memory data, bytes memory saleSig) public view returns (bool) {
    return _validateSale(sale, data, saleSig);
  }

  function validateOffer (Offer memory offer, bytes memory data, bytes memory offerSig) public view returns (bool) {
    return _validateOffer(offer, data, offerSig);
  }
  function setNonceUsed(uint256 _nonce) external {
    require(_nonceOfSigning[msg.sender][_nonce] == false, "This Nonce has been used, the order has been established, or the Offer has been cancelled");
    _nonceOfSigning[msg.sender][_nonce] = true;
    emit NonceUsed(
      msg.sender,
      _nonce
    );
  }
  function getNonceIsUsed(address _user, uint256 _nonce) public view returns (bool) {
    return _nonceOfSigning[_user][_nonce];
  }
  function updateRoyaltyFeeManager(address _royaltyFeeManager) external onlyOwner {
    require(_royaltyFeeManager != address(0), "Owner: Cannot be null address");
    royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
  }
  function updateAdminFeeReceiver(address _adminFeeReceiver) external onlyOwner {
    require(_adminFeeReceiver != address(0), "Owner: Cannot be null address");
    adminFeeReceiver = _adminFeeReceiver;
  }
  function updateAdminFee(uint256 _adminFee) external onlyOwner {
    adminFee = _adminFee;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRoyaltyFeeManager {
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.4;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";

library NftTokenHandler {
  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

  function isOwner(
      address nftContract, 
      uint256 tokenId, 
      address account 
  ) internal view returns (bool) {

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC721)) {
        return IERC721(nftContract).ownerOf(tokenId) == account;
      }

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC1155)) {
        return IERC1155(nftContract).balanceOf(account, tokenId) > 0;
      }

      return false;

  }

  function isApproved(
      address nftContract, 
      uint256 tokenId, 
      address owner, 
      address operator
    ) internal view returns (bool) {

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC721)) {
        return IERC721(nftContract).getApproved(tokenId) == operator;
      }

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC1155)) {
        return IERC1155(nftContract).isApprovedForAll(owner, operator);
      }

      return false;
    }

  function ownedQuantity(
      address nftContract, 
      uint256 tokenId, 
      address owner
    ) internal view returns (uint256) {
      
      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC721)) {
        return IERC721(nftContract).ownerOf(tokenId) == owner ? 1 : 0;
      }

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC1155)) {
        return IERC1155(nftContract).balanceOf(owner, tokenId);
      }

      return 0;
    }

  function transfer(
      address nftContract, 
      uint256 tokenId, 
      uint256 quantity,
      address from, 
      address to, 
      bytes memory data 
    ) internal {

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC721)) {
        require(quantity == 1, "Unable to transfer more than 1 token");
        return IERC721(nftContract).safeTransferFrom(from, to, tokenId);
      }

      if(IERC165(nftContract).supportsInterface(_INTERFACE_ID_ERC1155)) {
        return IERC1155(nftContract).safeTransferFrom(from, to, tokenId, quantity, data);
      }

      revert("Unidentified NFT contract.");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

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