// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import {LendOrder, RentOffer} from "../constant/RentalStructs.sol";
import "./BaseRentalMarket.sol";
import "./IRentalMarket1155.sol";
import "../bank/IBank1155.sol";

contract RentalMarket1155 is BaseRentalMarket, IRentalMarket1155 {
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner_,
        address admin_,
        address bank_
    ) public initializer {
        require(IBank(bank_).supportsInterface(type(IBank1155).interfaceId));
        _initialize(owner_, admin_, bank_);
    }

    function registerBank(address oNFT, address bank) external onlyAdmin {
        require(IBank(bank).supportsInterface(type(IBank1155).interfaceId));
        _registerBank(oNFT, bank);
    }

    function fulfillLendOrder1155(
        LendOrder calldata lendOrder,
        Signature calldata signature,
        uint64 tokenAmount,
        uint256 cycleAmount,
        IBank1155.RentingRecord[] calldata toDeletes
    ) external payable whenNotPaused nonReentrant {
        require(cycleAmount >= lendOrder.minCycleAmount, "invalid cycleAmount");
        bytes32 orderHash = _hashStruct_LendOrder(lendOrder);
        _validateOrder(
            lendOrder.maker,
            lendOrder.taker,
            lendOrder.nonce,
            orderHash
        );
        _validateSignature(lendOrder.maker, orderHash, signature);
        uint256 duration = lendOrder.price.cycle * cycleAmount;
        uint256 rentExpiry = block.timestamp + duration;
        require(duration <= maxDuration, "The duration is too long");
        require(
            rentExpiry <= lendOrder.maxRentExpiry,
            "The duration is too long"
        );
        _handleFrozen(lendOrder, tokenAmount, toDeletes);
        IBank1155.RecordParam memory param = IBank1155.RecordParam(
            0,
            lendOrder.nft.tokenType,
            lendOrder.nft.token,
            lendOrder.nft.tokenId,
            tokenAmount,
            lendOrder.maker,
            msg.sender,
            rentExpiry
        );
        IBank1155(bankOf(lendOrder.nft.token)).createUserRecord(param);

        _distributePayment(
            lendOrder.price,
            cycleAmount,
            tokenAmount,
            lendOrder.fees,
            lendOrder.maker,
            msg.sender
        );

        emit LendOrderFulfilled(
            orderHash,
            lendOrder.nft,
            lendOrder.price,
            tokenAmount,
            cycleAmount,
            lendOrder.maker,
            msg.sender
        );
    }

    function fulfillRentOffer1155(
        RentOffer calldata rentOffer,
        Signature calldata signature,
        IBank1155.RentingRecord[] calldata toDeletes
    ) public whenNotPaused nonReentrant {
        bytes32 offerHash = _hashStruct_RentOffer(rentOffer);
        _validateOrder(
            rentOffer.maker,
            rentOffer.taker,
            rentOffer.nonce,
            offerHash
        );
        require(
            block.timestamp <= rentOffer.offerExpiry,
            "The offer has expired"
        );
        _validateSignature(rentOffer.maker, offerHash, signature);
        IBank1155 bank = IBank1155(bankOf(rentOffer.nft.token));
        bank.deleteUserRecords(toDeletes);
        uint256 duration = rentOffer.price.cycle * rentOffer.cycleAmount;
        require(duration <= maxDuration, "The duration is too long");
        uint256 rentExpiry = block.timestamp + duration;
        IBank1155.RecordParam memory param = IBank1155.RecordParam(
            0,
            rentOffer.nft.tokenType,
            rentOffer.nft.token,
            rentOffer.nft.tokenId,
            rentOffer.nft.amount,
            msg.sender,
            rentOffer.maker,
            rentExpiry
        );
        bank.createUserRecord(param);

        _distributePayment(
            rentOffer.price,
            rentOffer.cycleAmount,
            rentOffer.nft.amount,
            rentOffer.fees,
            msg.sender,
            rentOffer.maker
        );
        cancelledOrFulfilled[offerHash] = true;

        emit RentOfferFulfilled(
            offerHash,
            rentOffer.nft,
            rentOffer.price,
            rentOffer.nft.amount,
            rentOffer.cycleAmount,
            msg.sender,
            rentOffer.maker
        );
    }

    function _handleFrozen(
        LendOrder calldata lendOrder,
        uint64 tokenAmount,
        IBank1155.RentingRecord[] calldata toDeletes
    ) internal {
        IBank1155 bank = IBank1155(bankOf(lendOrder.nft.token));
        bank.deleteUserRecords(toDeletes);
        uint256 frozenAmount = bank.frozenAmountOf(
            lendOrder.nft.token,
            lendOrder.nft.tokenId,
            lendOrder.maker
        );
        require(
            frozenAmount + tokenAmount <= lendOrder.nft.amount,
            "insufficient remaining amount"
        );
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {TokenType} from "../constant/TokenEnums.sol";
import "../erc5006/IERC5006.sol";

interface IBank1155 {
    struct RecordParam {
        uint256 recordId;
        TokenType tokenType;
        address oNFT;
        uint256 oNFTId;
        uint256 oNFTAmount;
        address owner;
        address user;
        uint256 expiry;
    }

    struct RentingRecord{
        TokenType tokenType;
        address oNFT;
        uint256 oNFTId;
        address lender;
        uint256 recordId;
    }

    struct Renting{
        address lender;
        uint256 amount;
    }

    event CreateUserRecord(RecordParam param);

    event DeleteUserRecord(RentingRecord param);

    function createUserRecord(RecordParam memory param) external;

    function deleteUserRecords(RentingRecord[] calldata toDeletes) external;

    function frozenAmountOf(
        address oNFT,
        uint256 oNFTId,
        address from
    ) external view returns (uint256);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import "./IRentalMarket.sol";

interface IRentalMarket1155 is IRentalMarket {

}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../lib/Pauseable.sol";
import "../lib/ENSReverseRegistrar.sol";
import "../bank/IBank.sol";
import "./IRentalMarket.sol";
import "../validater/EIP712.sol";
import "../validater/IMetadataChecker.sol";
import {Fee} from "../constant/BaseStructs.sol";

abstract contract BaseRentalMarket is
    IRentalMarket,
    Pauseable,
    ENSReverseRegistrar,
    ReentrancyGuardUpgradeable,
    Multicall,
    EIP712
{
    /* Storage */
    mapping(bytes32 => bool) internal cancelledOrFulfilled;
    mapping(address => uint256) internal nonces;
    mapping(address => address) internal bankMap;
    address internal _baseBank;
    uint256 internal maxDuration;
    uint256[64] private __gap;

    function _initialize(
        address owner_,
        address admin_,
        address baseBank_
    ) internal onlyInitializing {
        __ReentrancyGuard_init();
        _initOwnable(owner_, admin_);
        _baseBank = baseBank_;
        IBank(_baseBank).bindMarket(address(this));
        _hashDomain();
        isPausing = false;
        maxDuration = 86400 * 180;
    }

    function nonceOf(address account) public view returns (uint256) {
        return nonces[account];
    }

    function bankOf(address oNFT) public view returns (address) {
        return bankMap[oNFT] == address(0) ? _baseBank : bankMap[oNFT];
    }

    function _registerBank(address oNFT, address bank) internal {
        IBank(bank).bindMarket(address(this));
        bankMap[oNFT] = bank;
    }

    function cancelLendOrder(LendOrder calldata lendOrder) public {
        require(
            msg.sender == lendOrder.maker,
            "only maker can cancel the order"
        );
        bytes32 orderHash = _hashStruct_LendOrder(lendOrder);
        if(cancelledOrFulfilled[orderHash]) return;
        cancelledOrFulfilled[orderHash] = true;
        emit OrderCancelled(orderHash);
    }

    function cancelRentOffer(RentOffer calldata rentOffer) public {
        require(
            msg.sender == rentOffer.maker,
            "only maker can cancel the offer"
        );
        bytes32 offerHash = _hashStruct_RentOffer(rentOffer);
        if(cancelledOrFulfilled[offerHash]) return;
        cancelledOrFulfilled[offerHash] = true;
        emit OfferCancelled(offerHash);
    }

    /**
     * @dev Cancel all current orders for a user, preventing them from being matched. Must be called by the trader of the order
     */
    function incrementNonce() external {
        nonces[msg.sender] += 1;
        emit NonceIncremented(msg.sender, nonces[msg.sender]);
    }

    function _distributePayment(
        RentalPrice calldata price,
        uint256 cycleAmount,
        uint256 nftAmount,
        Fee[] calldata fees,
        address lender,
        address renter
    ) internal {
        uint256 totalPrice = price.pricePerCycle * cycleAmount * nftAmount;
        uint16 totalFeesRate;
        for (uint256 i = 0; i < fees.length; i++) {
            totalFeesRate += fees[i].rate;
        }
        uint256 totalFee = (totalPrice * totalFeesRate) / 100_000;
        uint256 leftTotalPrice = totalPrice - totalFee;
        if (price.paymentToken == address(0)) {
            require(msg.value >= totalPrice, "payment is not enough");
            Address.sendValue(payable(lender), leftTotalPrice);
            if (msg.value > totalPrice) {
                Address.sendValue(payable(renter), msg.value - totalPrice);
            }
            for (uint256 i = 0; i < fees.length; i++) {
                Address.sendValue(
                    fees[i].recipient,
                    (totalPrice * fees[i].rate) / 100_000
                );
            }
        } else {
            SafeERC20.safeTransferFrom(
                IERC20(price.paymentToken),
                renter,
                lender,
                leftTotalPrice
            );
            for (uint256 i = 0; i < fees.length; i++) {
                SafeERC20.safeTransferFrom(
                    IERC20(price.paymentToken),
                    renter,
                    fees[i].recipient,
                    (totalPrice * fees[i].rate) / 100_000
                );
            }
        }
    }

    function _validateOrder(
        address maker,
        address taker,
        uint256 nonce,
        bytes32 orderHash
    ) internal view {
        require(taker == address(0) || taker == msg.sender, "invalid taker");
        require(nonce == nonces[maker], "nonce already expired");
        require(
            !cancelledOrFulfilled[orderHash],
            "Be cancelled or fulfilled already"
        );
    }

    function _validateMetadata(
        NFT calldata nft,
        Metadata calldata metadata
    ) internal view {
        if (metadata.checker != address(0)) {
            bool isValid = IMetadataChecker(metadata.checker).check(
                nft.token,
                nft.tokenId,
                metadata.metadataHash
            );
            require(isValid, "metadata is invalid");
        }
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import {NFT, Fee, Metadata} from "./BaseStructs.sol";

struct RentalPrice {
    address paymentToken;
    uint256 pricePerCycle;
    uint256 cycle;
}

struct LendOrder {
    address maker;
    address taker; //private order
    NFT nft;
    RentalPrice price;
    uint256 minCycleAmount;
    uint256 maxRentExpiry;
    uint256 nonce;
    uint256 salt;
    uint64 durationId;
    Fee[] fees;
    Metadata metadata;
}

struct RentOffer {
    address maker;
    address taker; //private order
    NFT nft;
    RentalPrice price;
    uint256 cycleAmount;
    uint256 offerExpiry;
    uint256 nonce;
    uint256 salt;
    Fee[] fees;
    Metadata metadata;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

enum TokenType {
    ERC721,
    ERC721_subNFT, //Reserved Field
    ERC721_vNFT, //Reserved Field
    ERC1155,
    ERC4907,
    ERC5006,
    ERC20,
    NATIVE
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

interface IERC5006 {
    struct UserRecord {
        uint256 tokenId;
        address owner;
        uint64 amount;
        address user;
        uint64 expiry;
    }
    /**
     * @dev Emitted when permission (for `user` to use `amount` of `tokenId` token owned by `owner`
     * until `expiry`) is given.
     */
    event CreateUserRecord(
        uint256 recordId,
        uint256 tokenId,
        uint64 amount,
        address owner,
        address user,
        uint64 expiry
    );
    /**
     * @dev Emitted when record of `recordId` is deleted. 
     */
    event DeleteUserRecord(uint256 recordId);

    /**
     * @dev Returns the usable amount of `tokenId` tokens  by `account`.
     */
    function usableBalanceOf(address account, uint256 tokenId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the amount of frozen tokens of token type `id` by `account`.
     */
    function frozenBalanceOf(address account, uint256 tokenId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the `UserRecord` of `recordId`.
     */
    function userRecordOf(uint256 recordId)
        external
        view
        returns (UserRecord memory);

    /**
     * @dev Gives permission to `user` to use `amount` of `tokenId` token owned by `owner` until `expiry`.
     *
     * Emits a {CreateUserRecord} event.
     *
     * Requirements:
     *
     * - If the caller is not `owner`, it must be have been approved to spend ``owner``'s tokens
     * via {setApprovalForAll}.
     * - `owner` must have a balance of tokens of type `id` of at least `amount`.
     * - `user` cannot be the zero address.
     * - `amount` must be greater than 0.
     * - `expiry` must after the block timestamp.
     */
    function createUserRecord(
        address owner,
        address user,
        uint256 tokenId,
        uint64 amount,
        uint64 expiry
    ) external returns (uint256);

    /**
     * @dev Atomically delete `record` of `recordId` by the caller.
     *
     * Emits a {DeleteUserRecord} event.
     *
     * Requirements:
     *
     * - the caller must have allowance.
     */
    function deleteUserRecord(uint256 recordId) external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;
import {RentalPrice} from "../constant/RentalStructs.sol";
import {NFT} from "../constant/BaseStructs.sol";

interface IRentalMarket {
    event OrderCancelled(bytes32 hash);
    event OfferCancelled(bytes32 hash);
    event NonceIncremented(address trader, uint256 newNonce);
    event LendOrderFulfilled(
        bytes32 hash,
        NFT nft,
        RentalPrice price,
        uint256 amount,
        uint256 cycleAmount,
        address lender,
        address renter
    );
    event RentOfferFulfilled(
        bytes32 hash,
        NFT nft,
        RentalPrice price,
        uint256 amount,
        uint256 cycleAmount,
        address lender,
        address renter
    );
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import {TokenType} from "./TokenEnums.sol";

enum SignatureVersion {
    EIP712,
    EIP1271
}

struct NFT {
    TokenType tokenType;
    address token;
    uint256 tokenId;
    uint256 amount;
}

struct Fee {
    uint16 rate;
    address payable recipient;
}

struct Signature {
    bytes signature;
    SignatureVersion signatureVersion;
}

struct Metadata {
    bytes32 metadataHash;
    address checker;
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {TokenType} from "../constant/TokenEnums.sol";
import {NFT} from "../constant/BaseStructs.sol";

interface IBank is IERC165 {
    function bindMarket(address market_) external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;
import "./OwnableUpgradeable.sol";

abstract contract Pauseable is OwnableUpgradeable {
    event Paused(address account);
    event Unpaused(address account);
    bool public isPausing;

    modifier whenNotPaused() {
        require(!isPausing, "Pausable: paused");
        _;
    }

    function setPause(bool pause_) external onlyAdmin {
        isPausing = pause_;
        if (isPausing) {
            emit Paused(address(this));
        } else {
            emit Unpaused(address(this));
        }
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";
import "./OwnableUpgradeable.sol";

abstract contract ENSReverseRegistrar is OwnableUpgradeable {
    function ENS_setName(string memory name) public onlyAdmin {
        uint256 id;
        assembly {
            id := chainid()
        }
        bytes memory _data = abi.encodeWithSignature("setName(string)", name);
        require(id == 1, "not mainnet");
        Address.functionCall(
            address(0x084b1c3C81545d370f3634392De611CaaBFf8148),
            _data
        );
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.13;

interface IMetadataChecker {
    function check(
        address nft721,
        uint256 nftId,
        bytes32 metadataHash
    ) external view returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {LendOrder, RentalPrice, RentOffer} from "../constant/RentalStructs.sol";
import {NFT, Fee, SignatureVersion, Signature, Metadata} from "../constant/BaseStructs.sol";
import {SignatureVerificationErrors} from "./SignatureVerificationErrors.sol";
import {EIP1271Interface} from "./EIP1271Interface.sol";

/**
 * @title EIP712
 * @dev Contains all of the order hashing functions for EIP712 compliant signatures
 */
contract EIP712 is SignatureVerificationErrors {
    // Signature-related
    bytes32 internal constant EIP2098_allButHighestBitMask = (
        0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    );
    bytes32 internal constant NFT_TYPEHASH =
        keccak256(
            "NFT(uint8 tokenType,address token,uint256 tokenId,uint256 amount)"
        );
    bytes32 internal constant RENTAL_PRICE_TYPEHASH =
        keccak256(
            "RentalPrice(address paymentToken,uint256 pricePerCycle,uint256 cycle)"
        );

    bytes32 internal constant FEE_TYPEHASH =
        keccak256("Fee(uint16 rate,address recipient)");

    bytes32 internal constant METADATA_TYPEHASH =
        keccak256("Metadata(bytes32 metadataHash,address checker)");

    bytes32 internal constant LEND_ORDER_TYPEHASH =
        keccak256(
            "LendOrder(address maker,address taker,NFT nft,RentalPrice price,uint256 minCycleAmount,uint256 maxRentExpiry,uint256 nonce,uint256 salt,uint64 durationId,Fee[] fees,Metadata metadata)Fee(uint16 rate,address recipient)Metadata(bytes32 metadataHash,address checker)NFT(uint8 tokenType,address token,uint256 tokenId,uint256 amount)RentalPrice(address paymentToken,uint256 pricePerCycle,uint256 cycle)"
        );
    bytes32 internal constant RENT_OFFER_TYPEHASH =
        keccak256(
            "RentOffer(address maker,address taker,NFT nft,RentalPrice price,uint256 cycleAmount,uint256 offerExpiry,uint256 nonce,uint256 salt,Fee[] fees,Metadata metadata)Fee(uint16 rate,address recipient)Metadata(bytes32 metadataHash,address checker)NFT(uint8 tokenType,address token,uint256 tokenId,uint256 amount)RentalPrice(address paymentToken,uint256 pricePerCycle,uint256 cycle)"
        );

    bytes32 internal constant DOMAIN =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 internal constant NAME = keccak256("Double");
    bytes32 internal constant VERSION = keccak256("1.0.0");
    bytes32 DOMAIN_SEPARATOR;

    function _hashDomain() internal {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(DOMAIN, NAME, VERSION, block.chainid, address(this))
        );
    }

    function _getEIP712Hash(bytes32 structHash) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(hex"1901", DOMAIN_SEPARATOR, structHash)
            );
    }

    function _hashStruct_NFT(NFT calldata nft) internal pure returns (bytes32) {
        return keccak256(abi.encode(NFT_TYPEHASH, nft));
    }

    function _hashStruct_Metadata(
        Metadata calldata metadata
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(METADATA_TYPEHASH, metadata));
    }

    function _hashStruct_RentalPrice(
        RentalPrice calldata price
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(RENTAL_PRICE_TYPEHASH, price));
    }

    function _hashFee(Fee calldata fee) internal pure returns (bytes32) {
        return keccak256(abi.encode(FEE_TYPEHASH, fee.rate, fee.recipient));
    }

    function _packFees(Fee[] calldata fees) internal pure returns (bytes32) {
        bytes32[] memory feeHashes = new bytes32[](fees.length);
        for (uint256 i = 0; i < fees.length; i++) {
            feeHashes[i] = _hashFee(fees[i]);
        }
        return keccak256(abi.encodePacked(feeHashes));
    }

    function _hashStruct_LendOrder(
        LendOrder calldata order
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    LEND_ORDER_TYPEHASH,
                    order.maker,
                    order.taker,
                    _hashStruct_NFT(order.nft),
                    _hashStruct_RentalPrice(order.price),
                    order.minCycleAmount,
                    order.maxRentExpiry,
                    order.nonce,
                    order.salt,
                    order.durationId,
                    _packFees(order.fees),
                    _hashStruct_Metadata(order.metadata)
                )
            );
    }

    function _hashStruct_RentOffer(
        RentOffer calldata rentOffer
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    RENT_OFFER_TYPEHASH,
                    rentOffer.maker,
                    rentOffer.taker,
                    _hashStruct_NFT(rentOffer.nft),
                    _hashStruct_RentalPrice(rentOffer.price),
                    rentOffer.cycleAmount,
                    rentOffer.offerExpiry,
                    rentOffer.nonce,
                    rentOffer.salt,
                    _packFees(rentOffer.fees),
                    _hashStruct_Metadata(rentOffer.metadata)
                )
            );
    }

    function _validateSignature(
        address signer,
        bytes32 orderHash,
        Signature memory signature
    ) internal view {
        bytes32 hashToSign = _getEIP712Hash(orderHash);
        _assertValidSignature(signer, hashToSign, signature.signature);
    }

    /**
     * @dev Internal view function to verify the signature of an order. An
     *      ERC-1271 fallback will be attempted if either the signature length
     *      is not 64 or 65 bytes or if the recovered signer does not match the
     *      supplied signer. Note that in cases where a 64 or 65 byte signature
     *      is supplied, only standard ECDSA signatures that recover to a
     *      non-zero address are supported.
     *
     * @param signer    The signer for the order.
     * @param digest    The digest to verify the signature against.
     * @param signature A signature from the signer indicating that the order
     *                  has been approved.
     */
    function _assertValidSignature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        // Declare r, s, and v signature parameters.
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signer.code.length > 0) {
            // If signer is a contract, try verification via EIP-1271.
            _assertValidEIP1271Signature(signer, digest, signature);

            // Return early if the ERC-1271 signature check succeeded.
            return;
        } else if (signature.length == 64) {
            // If signature contains 64 bytes, parse as EIP-2098 signature. (r+s&v)
            // Declare temporary vs that will be decomposed into s and v.
            bytes32 vs;

            (r, vs) = abi.decode(signature, (bytes32, bytes32));

            s = vs & EIP2098_allButHighestBitMask;

            v = SafeCast.toUint8(uint256(vs >> 255)) + 27;
        } else if (signature.length == 65) {
            (r, s) = abi.decode(signature, (bytes32, bytes32));
            v = uint8(signature[64]);

            // Ensure v value is properly formatted.
            if (v != 27 && v != 28) {
                revert BadSignatureV(v);
            }
        } else {
            revert InvalidSignature();
        }

        // Attempt to recover signer using the digest and signature parameters.
        address recoveredSigner = ecrecover(digest, v, r, s);

        // Disallow invalid signers.
        if (recoveredSigner == address(0) || recoveredSigner != signer) {
            revert InvalidSigner();
            // Should a signer be recovered, but it doesn't match the signer...
        }
    }

    /**
     * @dev Internal view function to verify the signature of an order using
     *      ERC-1271 (i.e. contract signatures via `isValidSignature`).
     *
     * @param signer    The signer for the order.
     * @param digest    The signature digest, derived from the domain separator
     *                  and the order hash.
     * @param signature A signature (or other data) used to validate the digest.
     */
    function _assertValidEIP1271Signature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view {
        if (
            EIP1271Interface(signer).isValidSignature(digest, signature) !=
            EIP1271Interface.isValidSignature.selector
        ) {
            revert InvalidSigner();
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

contract OwnableUpgradeable {
    address public owner;
    address public pendingOwner;
    address public admin;

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewOwner(address oldOwner, address newOwner);
    event NewPendingOwner(address oldPendingOwner, address newPendingOwner);

    function _initOwnable(address owner_, address admin_) internal {
        require(owner_ != address(0), "owner_ cannot be Zero Address");
        owner = owner_;
        admin = admin_;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "onlyPendingOwner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin || msg.sender == owner, "onlyAdmin");
        _;
    }

    function transferOwnership(address _pendingOwner) public onlyOwner {
        emit NewPendingOwner(pendingOwner, _pendingOwner);
        pendingOwner = _pendingOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit NewOwner(owner, address(0));
        emit NewAdmin(admin, address(0));
        emit NewPendingOwner(pendingOwner, address(0));

        owner = address(0);
        pendingOwner = address(0);
        admin = address(0);
    }

    function acceptOwner() public onlyPendingOwner {
        emit NewOwner(owner, pendingOwner);
        owner = pendingOwner;

        address newPendingOwner = address(0);
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function setAdmin(address newAdmin) public onlyOwner {
        emit NewAdmin(admin, newAdmin);
        admin = newAdmin;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.7;

interface EIP1271Interface {
    function isValidSignature(bytes32 digest, bytes calldata signature)
        external
        view
        returns (bytes4);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.7;

/**
 * @title SignatureVerificationErrors
 * @author 0age
 * @notice SignatureVerificationErrors contains all errors related to signature
 *         verification.
 */
interface SignatureVerificationErrors {
    /**
     * @dev Revert with an error when a signature that does not contain a v
     *      value of 27 or 28 has been supplied.
     *
     * @param v The invalid v value.
     */
    error BadSignatureV(uint8 v);

    /**
     * @dev Revert with an error when the signer recovered by the supplied
     *      signature does not match the offerer or an allowed EIP-1271 signer
     *      as specified by the offerer in the event they are a contract.
     */
    error InvalidSigner();

    /**
     * @dev Revert with an error when a signer cannot be recovered from the
     *      supplied signature.
     */
    error InvalidSignature();

    /**
     * @dev Revert with an error when an EIP-1271 call to an account fails.
     */
    error BadContractSignature();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}