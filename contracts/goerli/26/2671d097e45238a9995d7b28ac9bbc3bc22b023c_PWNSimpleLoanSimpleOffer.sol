// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "MultiToken/MultiToken.sol";

import "@pwn/loan/lib/PWNSignatureChecker.sol";
import "@pwn/loan/terms/simple/factory/offer/base/PWNSimpleLoanOffer.sol";
import "@pwn/loan/terms/PWNLOANTerms.sol";
import "@pwn/PWNErrors.sol";


/**
 * @title PWN Simple Loan Simple Offer
 * @notice Loan terms factory contract creating a simple loan terms from a simple offer.
 */
contract PWNSimpleLoanSimpleOffer is PWNSimpleLoanOffer {

    string internal constant VERSION = "1.0";

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    /**
     * @dev EIP-712 simple offer struct type hash.
     */
    bytes32 constant internal OFFER_TYPEHASH = keccak256(
        "Offer(uint8 collateralCategory,address collateralAddress,uint256 collateralId,uint256 collateralAmount,address loanAssetAddress,uint256 loanAmount,uint256 loanYield,uint32 duration,uint40 expiration,address borrower,address lender,bool isPersistent,bool lateRepaymentEnabled,bytes32 nonce)"
    );

    /**
     * @notice Construct defining a simple offer.
     * @param collateralCategory Category of an asset used as a collateral (0 == ERC20, 1 == ERC721, 2 == ERC1155).
     * @param collateralAddress Address of an asset used as a collateral.
     * @param collateralId Token id of an asset used as a collateral, in case of ERC20 should be 0.
     * @param collateralAmount Amount of tokens used as a collateral, in case of ERC721 should be 1.
     * @param loanAssetAddress Address of an asset which is lended to a borrower.
     * @param loanAmount Amount of tokens which is offered as a loan to a borrower
     * @param loanYield Amount of tokens which acts as a lenders loan interest. Borrower has to pay back a borrowed amount + yield.
     * @param duration Loan duration in seconds.
     * @param expiration Offer expiration timestamp in seconds.
     * @param borrower Address of a borrower. Only this address can accept an offer. If the address is zero address, anybody with a collateral can accept the offer.
     * @param lender Address of a lender. This address has to sign an offer to be valid.
     * @param isPersistent If true, offer will not be revoked on acceptance. Persistent offer can be revoked manually.
     * @param lateRepaymentEnabled If true, a borrower can repay a loan even after an expiration date, but not after lender claims expired loan.
     * @param nonce Additional value to enable identical offers in time. Without it, it would be impossible to make again offer, which was once revoked.
     *              Can be used to create a group of offers, where accepting one offer will make other offers in the group revoked.
     */
    struct Offer {
        MultiToken.Category collateralCategory;
        address collateralAddress;
        uint256 collateralId;
        uint256 collateralAmount;
        address loanAssetAddress;
        uint256 loanAmount;
        uint256 loanYield;
        uint32 duration;
        uint40 expiration;
        address borrower;
        address lender;
        bool isPersistent;
        bool lateRepaymentEnabled;
        bytes32 nonce;
    }

    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor(address hub, address revokedOfferNonce) PWNSimpleLoanOffer(hub, revokedOfferNonce) {

    }


    /*----------------------------------------------------------*|
    |*  # OFFER MANAGEMENT                                      *|
    |*----------------------------------------------------------*/

    /**
     * @notice Make an on-chain offer.
     * @dev Function will mark an offer hash as proposed. Offer will become acceptable by a borrower without an offer signature.
     * @param offer Offer struct containing all needed offer data.
     */
    function makeOffer(Offer calldata offer) external {
        _makeOffer(getOfferHash(offer), offer.lender, offer.nonce);
    }


    /*----------------------------------------------------------*|
    |*  # IPWNSimpleLoanFactory                                 *|
    |*----------------------------------------------------------*/

    /**
     * @notice See { IPWNSimpleLoanFactory.sol }.
     */
    function getLOANTerms(
        address caller,
        bytes calldata factoryData,
        bytes calldata signature
    ) external override onlyActiveLoan returns (PWNLOANTerms.Simple memory loanTerms) {

        Offer memory offer = abi.decode(factoryData, (Offer));
        bytes32 offerHash = getOfferHash(offer);

        address lender = offer.lender;
        address borrower = caller;

        // Check that offer has been made via on-chain tx, EIP-1271 or signed off-chain
        if (offersMade[offerHash] == false)
            if (PWNSignatureChecker.isValidSignatureNow(lender, offerHash, signature) == false)
                revert InvalidSignature();

        // Check valid offer
        if (offer.expiration != 0 && block.timestamp >= offer.expiration)
            revert OfferExpired();

        if (revokedOfferNonce.isNonceRevoked(lender, offer.nonce) == true)
            revert NonceAlreadyRevoked();

        if (offer.borrower != address(0))
            if (borrower != offer.borrower)
                revert CallerIsNotStatedBorrower(offer.borrower);

        // Prepare collateral and loan asset
        MultiToken.Asset memory collateral = MultiToken.Asset({
            category: offer.collateralCategory,
            assetAddress: offer.collateralAddress,
            id: offer.collateralId,
            amount: offer.collateralAmount
        });
        MultiToken.Asset memory loanAsset = MultiToken.Asset({
            category: MultiToken.Category.ERC20,
            assetAddress: offer.loanAssetAddress,
            id: 0,
            amount: offer.loanAmount
        });

        // Create loan object
        loanTerms = PWNLOANTerms.Simple({
            lender: lender,
            borrower: borrower,
            expiration: uint40(block.timestamp) + offer.duration,
            lateRepaymentEnabled: offer.lateRepaymentEnabled,
            collateral: collateral,
            asset: loanAsset,
            loanRepayAmount: offer.loanAmount + offer.loanYield
        });

        // Revoke offer if not persistent
        if (!offer.isPersistent)
            revokedOfferNonce.revokeNonce(lender, offer.nonce);
    }


    /*----------------------------------------------------------*|
    |*  # GET OFFER HASH                                        *|
    |*----------------------------------------------------------*/

    /**
     * @notice Get an offer hash according to EIP-712.
     * @param offer Offer struct to be hashed.
     * @return Offer struct hash.
     */
    function getOfferHash(Offer memory offer) public view returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            keccak256(abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("PWNSimpleLoanSimpleOffer"),
                keccak256("1"),
                block.chainid,
                address(this)
            )),
            keccak256(abi.encodePacked(
                OFFER_TYPEHASH,
                abi.encode(
                    offer.collateralCategory,
                    offer.collateralAddress,
                    offer.collateralId,
                    offer.collateralAmount
                ), // Need to prevent `slot(s) too deep inside the stack` error
                abi.encode(
                    offer.loanAssetAddress,
                    offer.loanAmount,
                    offer.loanYield,
                    offer.duration,
                    offer.expiration,
                    offer.borrower,
                    offer.lender,
                    offer.isPersistent,
                    offer.lateRepaymentEnabled,
                    offer.nonce
                )
            ))
        ));
    }


    /*----------------------------------------------------------*|
    |*  # LOAN TERMS FACTORY DATA ENCODING                      *|
    |*----------------------------------------------------------*/

    /**
     * @notice Return encoded input data for this loan terms factory.
     * @param offer Simple loan simple offer struct to encode.
     * @return Encoded loan terms factory data that can be used as an input of `getLOANTerms` function with this factory.
     */
    function encodeLoanTermsFactoryData(Offer memory offer) external pure returns (bytes memory) {
        return abi.encode(offer);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC721.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC1155.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

import "./interfaces/ICryptoKitties.sol";


library MultiToken {

    /**
     * @title Category
     * @dev Enum representation Asset category.
     */
    enum Category {
        ERC20,
        ERC721,
        ERC1155,
        CryptoKitties
    }

    /**
     * @title Asset
     * @param category Corresponding asset category.
     * @param assetAddress Address of the token contract defining the asset.
     * @param id TokenID of an NFT or 0.
     * @param amount Amount of fungible tokens or 0 -> 1.
     */
    struct Asset {
        Category category;
        address assetAddress;
        uint256 id;
        uint256 amount;
    }


    /*----------------------------------------------------------*|
    |*  # TRANSFER ASSET                                        *|
    |*----------------------------------------------------------*/

    /**
     * transferAssetFrom
     * @dev Wrapping function for `transferFrom` calls on various token interfaces.
     *      If `source` is `address(this)`, function `transfer` is called instead of `transferFrom` for ERC20 category.
     * @param asset Struct defining all necessary context of a token.
     * @param source Account/address that provided the allowance.
     * @param dest Destination address.
     */
    function transferAssetFrom(Asset memory asset, address source, address dest) internal {
        _transferAssetFrom(asset, source, dest, false);
    }

    /**
     * safeTransferAssetFrom
     * @dev Wrapping function for `safeTransferFrom` calls on various token interfaces.
     *      If `source` is `address(this)`, function `transfer` is called instead of `transferFrom` for ERC20 category.
     * @param asset Struct defining all necessary context of a token.
     * @param source Account/address that provided the allowance.
     * @param dest Destination address.
     */
    function safeTransferAssetFrom(Asset memory asset, address source, address dest) internal {
        _transferAssetFrom(asset, source, dest, true);
    }

    function _transferAssetFrom(Asset memory asset, address source, address dest, bool isSafe) private {
        if (asset.category == Category.ERC20) {
            if (source == address(this))
                require(IERC20(asset.assetAddress).transfer(dest, asset.amount), "MultiToken: ERC20 transfer failed");
            else
                require(IERC20(asset.assetAddress).transferFrom(source, dest, asset.amount), "MultiToken: ERC20 transferFrom failed");

        } else if (asset.category == Category.ERC721) {
            if (!isSafe)
                IERC721(asset.assetAddress).transferFrom(source, dest, asset.id);
            else
                IERC721(asset.assetAddress).safeTransferFrom(source, dest, asset.id, "");

        } else if (asset.category == Category.ERC1155) {
            IERC1155(asset.assetAddress).safeTransferFrom(source, dest, asset.id, asset.amount == 0 ? 1 : asset.amount, "");

        } else if (asset.category == Category.CryptoKitties) {
            ICryptoKitties(asset.assetAddress).transferFrom(source, dest, asset.id);

        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # TRANSFER ASSET CALLDATA                               *|
    |*----------------------------------------------------------*/

    /**
     * transferAssetFromCalldata
     * @dev Wrapping function for `transferFrom` calladata on various token interfaces.
     *      If `fromSender` is true, function `transfer` is returned instead of `transferFrom` for ERC20 category.
     * @param asset Struct defining all necessary context of a token.
     * @param source Account/address that provided the allowance.
     * @param dest Destination address.
     */
    function transferAssetFromCalldata(Asset memory asset, address source, address dest, bool fromSender) pure internal returns (bytes memory) {
        return _transferAssetFromCalldata(asset, source, dest, fromSender, false);
    }

    /**
     * safeTransferAssetFromCalldata
     * @dev Wrapping function for `safeTransferFrom` calladata on various token interfaces.
     *      If `fromSender` is true, function `transfer` is returned instead of `transferFrom` for ERC20 category.
     * @param asset Struct defining all necessary context of a token.
     * @param source Account/address that provided the allowance.
     * @param dest Destination address.
     */
    function safeTransferAssetFromCalldata(Asset memory asset, address source, address dest, bool fromSender) pure internal returns (bytes memory) {
        return _transferAssetFromCalldata(asset, source, dest, fromSender, true);
    }

    function _transferAssetFromCalldata(Asset memory asset, address source, address dest, bool fromSender, bool isSafe) pure private returns (bytes memory) {
        if (asset.category == Category.ERC20) {
            if (fromSender) {
                return abi.encodeWithSignature(
                    "transfer(address,uint256)", dest, asset.amount
                );
            } else {
                return abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)", source, dest, asset.amount
                );
            }
        } else if (asset.category == Category.ERC721) {
            if (!isSafe) {
                return abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)", source, dest, asset.id
                );
            } else {
                return abi.encodeWithSignature(
                    "safeTransferFrom(address,address,uint256,bytes)", source, dest, asset.id, ""
                );
            }

        } else if (asset.category == Category.ERC1155) {
            return abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256,uint256,bytes)", source, dest, asset.id, asset.amount == 0 ? 1 : asset.amount, ""
            );

        } else if (asset.category == Category.CryptoKitties) {
            return abi.encodeWithSignature(
                "transferFrom(address,address,uint256)", source, dest, asset.id
            );

        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # PERMIT                                                *|
    |*----------------------------------------------------------*/

    /**
     * permit
     * @dev Wrapping function for granting approval via permit signature.
     * @param asset Struct defining all necessary context of a token.
     * @param owner Account/address that signed the permit.
     * @param spender Account/address that would be granted approval to `asset`.
     * @param permitData Data about permit deadline (uint256) and permit signature (64/65 bytes).
     *                   Deadline and signature should be pack encoded together.
     *                   Signature can be standard (65 bytes) or compact (64 bytes) defined in EIP-2098.
     */
    function permit(Asset memory asset, address owner, address spender, bytes memory permitData) internal {
        if (asset.category == Category.ERC20) {

            // Parse deadline and permit signature parameters
            uint256 deadline;
            bytes32 r;
            bytes32 s;
            uint8 v;

            // Parsing signature parameters used from OpenZeppelins ECDSA library
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/83277ff916ac4f58fec072b8f28a252c1245c2f1/contracts/utils/cryptography/ECDSA.sol

            // Deadline (32 bytes) + standard signature data (65 bytes) -> 97 bytes
            if (permitData.length == 97) {
                assembly {
                    deadline := mload(add(permitData, 0x20))
                    r := mload(add(permitData, 0x40))
                    s := mload(add(permitData, 0x60))
                    v := byte(0, mload(add(permitData, 0x80)))
                }
            }
            // Deadline (32 bytes) + compact signature data (64 bytes) -> 96 bytes
            else if (permitData.length == 96) {
                bytes32 vs;

                assembly {
                    deadline := mload(add(permitData, 0x20))
                    r := mload(add(permitData, 0x40))
                    vs := mload(add(permitData, 0x60))
                }

                s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
                v = uint8((uint256(vs) >> 255) + 27);
            } else {
                revert("MultiToken::Permit: Invalid permit length");
            }

            // Call permit with parsed parameters
            IERC20Permit(asset.assetAddress).permit(owner, spender, asset.amount, deadline, v, r, s);

        } else {
            // Currently supporting only ERC20 signed approvals via ERC2612
            revert("MultiToken::Permit: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # BALANCE OF                                            *|
    |*----------------------------------------------------------*/

    /**
     * balanceOf
     * @dev Wrapping function for checking balances on various token interfaces.
     * @param asset Struct defining all necessary context of a token.
     * @param target Target address to be checked.
     */
    function balanceOf(Asset memory asset, address target) internal view returns (uint256) {
        if (asset.category == Category.ERC20) {
            return IERC20(asset.assetAddress).balanceOf(target);

        } else if (asset.category == Category.ERC721) {
            return IERC721(asset.assetAddress).ownerOf(asset.id) == target ? 1 : 0;

        } else if (asset.category == Category.ERC1155) {
            return IERC1155(asset.assetAddress).balanceOf(target, asset.id);

        } else if (asset.category == Category.CryptoKitties) {
            return ICryptoKitties(asset.assetAddress).ownerOf(asset.id) == target ? 1 : 0;

        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # APPROVE ASSET                                         *|
    |*----------------------------------------------------------*/

    /**
     * approveAsset
     * @dev Wrapping function for `approve` calls on various token interfaces.
     * @param asset Struct defining all necessary context of a token.
     * @param target Account/address that would be granted approval to `asset`.
     */
    function approveAsset(Asset memory asset, address target) internal {
        if (asset.category == Category.ERC20) {
            IERC20(asset.assetAddress).approve(target, asset.amount);

        } else if (asset.category == Category.ERC721) {
            IERC721(asset.assetAddress).approve(target, asset.id);

        } else if (asset.category == Category.ERC1155) {
            IERC1155(asset.assetAddress).setApprovalForAll(target, true);

        } else if (asset.category == Category.CryptoKitties) {
            ICryptoKitties(asset.assetAddress).approve(target, asset.id);

        } else {
            revert("MultiToken: Unsupported category");
        }
    }


    /*----------------------------------------------------------*|
    |*  # ASSET CHECKS                                          *|
    |*----------------------------------------------------------*/

    /**
     * isValid
     * @dev Checks that assets amount and id is valid in stated category.
     *      This function don't check that stated category is indeed the category of a contract on a stated address.
     * @param asset Asset that is examined.
     * @return True if assets amount and id is valid in stated category.
     */
    function isValid(Asset memory asset) internal pure returns (bool) {
        // ERC20 token has to have id set to 0
        if (asset.category == Category.ERC20 && asset.id != 0)
            return false;

        // ERC721 token has to have amount set to 1
        if ((asset.category == Category.ERC721 || asset.category == Category.CryptoKitties) && asset.amount != 1)
            return false;

        // Any categories have to have non-zero amount
        if (asset.amount == 0)
            return false;

        return true;
    }

    /**
     * isSameAs
     * @dev Compare two assets, ignoring their amounts.
     * @param asset First asset to examine.
     * @param otherAsset Second asset to examine.
     * @return True if both structs represents the same asset.
     */
    function isSameAs(Asset memory asset, Asset memory otherAsset) internal pure returns (bool) {
        return
            asset.category == otherAsset.category &&
            asset.assetAddress == otherAsset.assetAddress &&
            asset.id == otherAsset.id;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC1271.sol";

import "@pwn/PWNErrors.sol";


/**
 * @title PWN Signature Checker
 * @notice Library to check if a given signature is valid for EOAs or contract accounts.
 * @dev This library is a modification of an Open-Zeppelin `SignatureChecker` library extended by a support for EIP-2098 compact signatures.
 */
library PWNSignatureChecker {

    string internal constant VERSION = "1.0";

    /**
     * @dev Function will try to recover a signer of a given signature and check if is the same as given signer address.
     *      For a contract account signer address, function will check signature validity by calling `isValidSignature` function defined by EIP-1271.
     * @param signer Address that should be a `hash` signer or a signature validator, in case of a contract account.
     * @param hash Hash of a signed message that should validated.
     * @param signature Signature of a signed `hash`. Could be empty for a contract account signature validation.
     *                  Signature can be standard (65 bytes) or compact (64 bytes) defined by EIP-2098.
     * @return True if a signature is valid.
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        // Check that signature is valid for contract account
        if (signer.code.length > 0) {
            (bool success, bytes memory result) = signer.staticcall(
                abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
            );
            return
                success &&
                result.length == 32 &&
                abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector);
        }
        // Check that signature is valid for EOA
        else {
            bytes32 r;
            bytes32 s;
            uint8 v;

            // Standard signature data (65 bytes)
            if (signature.length == 65) {
                assembly {
                    r := mload(add(signature, 0x20))
                    s := mload(add(signature, 0x40))
                    v := byte(0, mload(add(signature, 0x60)))
                }
            }
            // Compact signature data (64 bytes) - see EIP-2098
            else if (signature.length == 64) {
                bytes32 vs;

                assembly {
                    r := mload(add(signature, 0x20))
                    vs := mload(add(signature, 0x40))
                }

                s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
                v = uint8((uint256(vs) >> 255) + 27);
            } else {
                revert InvalidSignatureLength(signature.length);
            }

            return signer == ECDSA.recover(hash, v, r, s);
        }
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "@pwn/hub/PWNHubAccessControl.sol";
import "@pwn/loan/terms/simple/factory/IPWNSimpleLoanTermsFactory.sol";
import "@pwn/nonce/PWNRevokedNonce.sol";
import "@pwn/PWNErrors.sol";


abstract contract PWNSimpleLoanOffer is IPWNSimpleLoanTermsFactory, PWNHubAccessControl {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    PWNRevokedNonce immutable internal revokedOfferNonce;

    /**
     * @dev Mapping of offers made via on-chain transactions.
     *      Could be used by contract wallets instead of EIP-1271.
     *      (offer hash => is made)
     */
    mapping (bytes32 => bool) public offersMade;

    /*----------------------------------------------------------*|
    |*  # EVENTS & ERRORS DEFINITIONS                           *|
    |*----------------------------------------------------------*/

    /**
     * @dev Emitted when an offer is made via an on-chain transaction.
     */
    event OfferMade(bytes32 indexed offerHash, address indexed lender);


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor(address hub, address _revokedOfferNonce) PWNHubAccessControl(hub) {
        revokedOfferNonce = PWNRevokedNonce(_revokedOfferNonce);
    }


    /*----------------------------------------------------------*|
    |*  # OFFER MANAGEMENT                                      *|
    |*----------------------------------------------------------*/

    /**
     * @notice Make an on-chain offer.
     * @dev Function will mark an offer hash as proposed. Offer will become acceptable by a borrower without an offer signature.
     * @param offerStructHash Hash of a proposed offer.
     * @param lender Address of an offer proposer (lender).
     * @param nonce Nonce used in an offer.
     */
    function _makeOffer(bytes32 offerStructHash, address lender, bytes32 nonce) internal {
        // Check that caller is a lender
        if (msg.sender != lender)
            revert CallerIsNotStatedLender(lender);

        // Check that offer has not been made
        if (offersMade[offerStructHash] == true)
            revert OfferAlreadyExists();

        // Check that offer has not been revoked
        if (revokedOfferNonce.isNonceRevoked(lender, nonce) == true)
            revert NonceAlreadyRevoked();

        // Mark offer as made
        offersMade[offerStructHash] = true;

        emit OfferMade(offerStructHash, lender);
    }

    /**
     * @notice Helper function for revoking an offer nonce on behalf of a caller.
     * @param offerNonce Offer nonce to be revoked.
     */
    function revokeOfferNonce(bytes32 offerNonce) external {
        revokedOfferNonce.revokeNonce(msg.sender, offerNonce);
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "MultiToken/MultiToken.sol";


library PWNLOANTerms {

    /**
     * @notice Struct defining a simple loan terms.
     * @dev This struct is created by loan factories and never stored.
     * @param lender Address of a lender.
     * @param borrower Address of a borrower.
     * @param expiration Unix timestamp (in seconds) setting up a default date.
     * @param lateRepaymentEnabled If true, a borrower can repay a loan even after an expiration date, but not after lender claims expired loan.
     * @param collateral Asset used as a loan collateral. For a definition see { MultiToken dependency lib }.
     * @param asset Asset used as a loan credit. For a definition see { MultiToken dependency lib }.
     * @param loanRepayAmount Amount of a loan asset to be paid back.
     */
    struct Simple {
        address lender;
        address borrower;
        uint40 expiration;
        bool lateRepaymentEnabled;
        MultiToken.Asset collateral;
        MultiToken.Asset asset;
        uint256 loanRepayAmount;
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;


// Access control
error CallerMissingHubTag(bytes32);

// Loan contract
error LoanDefaulted(uint40);
error InvalidLoanStatus(uint256);
error NonExistingLoan();
error CallerNotLOANTokenHolder();
error LateRepaymentIsAlreadyEnabled();

// Invalid asset
error InvalidLoanAsset();
error InvalidCollateralAsset();

// LOAN token
error InvalidLoanContractCaller();

// Vault
error UnsupportedTransferFunction();

// Nonce
error NonceAlreadyRevoked();

// Signature checks
error InvalidSignatureLength(uint256);
error InvalidSignature();

// Offer
error CallerIsNotStatedLender(address);
error CallerIsNotStatedBorrower(address);
error OfferAlreadyExists();
error OfferExpired();
error CollateralIdIsNotWhitelisted();

// Request
error RequestAlreadyExists();
error RequestExpired();

// Input data
error InvalidInputData();

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICryptoKitties {
    // Required methods
    function totalSupply() external view returns (uint256 total);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV // Deprecated in v4.8
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "@pwn/hub/PWNHub.sol";
import "@pwn/hub/PWNHubTags.sol";
import "@pwn/PWNErrors.sol";


/**
 * @title PWN Hub Access Control
 * @notice Implement modifiers for PWN Hub access control.
 */
abstract contract PWNHubAccessControl {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    PWNHub immutable internal hub;


    /*----------------------------------------------------------*|
    |*  # MODIFIERS                                             *|
    |*----------------------------------------------------------*/

    modifier onlyActiveLoan() {
        if (hub.hasTag(msg.sender, PWNHubTags.ACTIVE_LOAN) == false)
            revert CallerMissingHubTag(PWNHubTags.ACTIVE_LOAN);
        _;
    }

    modifier onlyWithTag(bytes32 tag) {
        if (hub.hasTag(msg.sender, tag) == false)
            revert CallerMissingHubTag(tag);
        _;
    }


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor(address pwnHub) {
        hub = PWNHub(pwnHub);
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "@pwn/loan/terms/PWNLOANTerms.sol";


/**
 * @title PWN Simple Loan Terms Factory Interface
 * @notice Interface of a loan factory contract that builds a simple loan terms.
 */
interface IPWNSimpleLoanTermsFactory {

    /**
     * @notice Build a simple loan terms from given data.
     * @dev This function should be called only by contracts working with simple loan terms.
     * @param caller Caller of a create loan function on a loan contract.
     * @param factoryData Encoded data for a loan terms factory.
     * @param signature Signed loan factory data.
     * @return loanTerms Simple loan terms struct created from a loan factory data.
     */
    function getLOANTerms(
        address caller,
        bytes calldata factoryData,
        bytes calldata signature
    ) external returns (PWNLOANTerms.Simple memory loanTerms);

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "@pwn/hub/PWNHubAccessControl.sol";
import "@pwn/PWNErrors.sol";


/**
 * @title PWN Revoked Nonce
 * @notice Contract holding revoked nonces.
 */
contract PWNRevokedNonce is PWNHubAccessControl {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    bytes32 immutable internal accessTag;

    /**
     * @dev Mapping of revoked nonces by an address.
     *      Every address has its own nonce space.
     *      (owner => nonce => is revoked)
     */
    mapping (address => mapping (bytes32 => bool)) private revokedNonces;


    /*----------------------------------------------------------*|
    |*  # EVENTS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @dev Emitted when a nonce is revoked.
     */
    event NonceRevoked(address indexed owner, bytes32 indexed nonce);


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor(address hub, bytes32 _accessTag) PWNHubAccessControl(hub) {
        accessTag = _accessTag;
    }


    /*----------------------------------------------------------*|
    |*  # REVOKE NONCE                                          *|
    |*----------------------------------------------------------*/

    /**
     * @notice Revoke a nonce.
     * @dev Caller is used as a nonce owner.
     * @param nonce Nonce to be revoked.
     */
    function revokeNonce(bytes32 nonce) external {
        _revokeNonce(msg.sender, nonce);
    }

    /**
     * @notice Revoke a nonce on behalf of an owner.
     * @dev Only an address with associated access tag in PWN Hub can call this function.
     * @param owner Owner address of a revoking nonce.
     * @param nonce Nonce to be revoked.
     */
    function revokeNonce(address owner, bytes32 nonce) external onlyWithTag(accessTag) {
        _revokeNonce(owner, nonce);
    }

    function _revokeNonce(address owner, bytes32 nonce) private {
        // Check that nonce is not have been revoked
        if (revokedNonces[owner][nonce] == true)
            revert NonceAlreadyRevoked();

        // Revoke nonce
        revokedNonces[owner][nonce] = true;

        // Emit event
        emit NonceRevoked(owner, nonce);
    }


    /*----------------------------------------------------------*|
    |*  # IS NONCE REVOKED                                      *|
    |*----------------------------------------------------------*/

    /**
     * @notice Get information if owners nonce is revoked or not.
     * @param owner Address of a nonce owner.
     * @param nonce Nonce in question.
     * @return True if owners nonce is revoked.
     */
    function isNonceRevoked(address owner, bytes32 nonce) external view returns (bool) {
        return revokedNonces[owner][nonce];
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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

import "@pwn/PWNErrors.sol";


/**
 * @title PWN Hub
 * @notice Connects PWN contracts together into protocol via tags.
 */
contract PWNHub is Ownable {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    /**
     * @dev Mapping of address tags. (contract address => tag => is tagged)
     */
    mapping (address => mapping (bytes32 => bool)) private tags;


    /*----------------------------------------------------------*|
    |*  # EVENTS & ERRORS DEFINITIONS                           *|
    |*----------------------------------------------------------*/

    /**
     * @dev Emitted when tag is set for an address.
     */
    event TagSet(address indexed _address, bytes32 indexed tag, bool hasTag);


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor(address owner) Ownable() {
        _transferOwnership(owner);
    }


    /*----------------------------------------------------------*|
    |*  # TAG MANAGEMENT                                        *|
    |*----------------------------------------------------------*/

    /**
     * @notice Set tag to an address.
     * @dev Tag can be added or removed via this functions. Only callable by contract owner.
     * @param _address Address to which a tag is set.
     * @param tag Tag that is set to an `_address`.
     * @param _hasTag Bool value if tag is added or removed.
     */
    function setTag(address _address, bytes32 tag, bool _hasTag) public onlyOwner {
        tags[_address][tag] = _hasTag;
        emit TagSet(_address, tag, _hasTag);
    }

    /**
     * @notice Set list of tags to an address.
     * @dev Tags can be added or removed via this functions. Only callable by contract owner.
     * @param _addresses List of addresses to which tags are set.
     * @param _tags List of tags that are set to an `_address`.
     * @param _hasTag Bool value if tags are added or removed.
     */
    function setTags(address[] memory _addresses, bytes32[] memory _tags, bool _hasTag) external onlyOwner {
        if (_addresses.length != _tags.length)
            revert InvalidInputData();

        uint256 length = _tags.length;
        for (uint256 i; i < length;) {
            setTag(_addresses[i], _tags[i], _hasTag);
            unchecked { ++i; }
        }
    }


    /*----------------------------------------------------------*|
    |*  # TAG GETTER                                            *|
    |*----------------------------------------------------------*/

    /**
     * @dev Return if an address is associated with a tag.
     * @param _address Address that is examined for a `tag`.
     * @param tag Tag that should an `_address` be associated with.
     * @return True if given address has a tag.
     */
    function hasTag(address _address, bytes32 tag) external view returns (bool) {
        return tags[_address][tag];
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

library PWNHubTags {

    string internal constant VERSION = "1.0";

    /// @dev Address can mint LOAN tokens and create LOANs via loan factory contracts.
    bytes32 internal constant ACTIVE_LOAN = keccak256("PWN_ACTIVE_LOAN");

    /// @dev Address can be used as a loan terms factory for creating simple loans.
    bytes32 internal constant SIMPLE_LOAN_TERMS_FACTORY = keccak256("PWN_SIMPLE_LOAN_TERMS_FACTORY");

    /// @dev Address can revoke loan request nonces.
    bytes32 internal constant LOAN_REQUEST = keccak256("PWN_LOAN_REQUEST");
    /// @dev Address can revoke loan offer nonces.
    bytes32 internal constant LOAN_OFFER = keccak256("PWN_LOAN_OFFER");

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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