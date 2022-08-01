// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { INFT } from "./interfaces/INFT.sol";
import { I_ERC2981 } from "./interfaces/I_ERC2981.sol";
import { IFacilitator } from "./interfaces/IFacilitator.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Facilitator is IFacilitator, Ownable, Pausable, ReentrancyGuard {

    //------------------- Errors ---------------------//

    error NotAFactoryOrOwner();
    error ZeroAddress();
    error NFTNotListed();
    error AlreadyListed();
    error NotOpenForPurchase();
    error InsufficientFundsSent();
    error IncorrectArrayLength();
    error MintPriceIsZero();
    error InvalidSignature();
    error ZeroAuthorisedPurchaseSigner();
    error ZeroFundCollector();
    error ExceedingAllowedMaxSupply();

    //------------------- Store variables ----------------//

    /// Signature nonce count
    uint256 public nonce;
    /// Authorised signer for the NFT Purcahse transactions.
    address public authorisedPurchaseSigner;

    /// Address of the nftFactory.
    address public immutable nftFactory;
    /// Address which collects all the funds of the sale.
    address public fundCollector;

    /// Fixed eth price per USD.
    /// TODO - Only for MWP.
    uint256 public ETH_PRICE = 1700;

    struct ListingDetails {
        /// Base price of the NFT project, In terms of ETH
        uint256[] basePrices;
        /// maximum token Id supported for provided series.
        uint256[] maxTokenIds;
        /// Series
        string[] series;
        /// Already sold NFT count.
        uint256 soldCount;
        /// Switch to facilitate the purchase of the nft project.
        bool isOpenForPurchase;
    }

    /// Mapping to keep track the listed nfts with the contract.
    mapping(address => bool) public listedNFTs;

    /// Mapping to keep track of the listing details corresponds to the nft.
    mapping(address => ListingDetails) public listings;

    /// Emitted when nft is open for purchase.
    event OpenForPurchase();

    /// Emitted when nft is close for purchase.
    event CloseForPurchase();

    /// Emitted when the nft get listed with the facilitator contract.
    event NFTListed(address _nft, uint256[] _basePrice, uint256[] _maxTokenIds, string[] _series);

    /// Emitted when the provided nft get unlisted.
    event NFTUnlisted(address _nft);

    /// Emitted when authorised signer changes.
    event AuthorisedSignerChanged(address _newSigner);

    /// Emitted when fund collector changes.
    event FundCollectorChanged(address _newFundCollector);

    /// Emitted when the NFT get purchased.
    event NFTPurchased(
        address indexed _nft,
        address indexed _receiver,
        address _royaltyReceiver,
        uint256 _tokenId,
        uint256 _mintFeePaid,
        uint256 _royaltyFeePaid
    );

    /// @notice Initializer of the contract.
    /// @param _nftFactory Address of the factory contract.
    constructor(address _nftFactory, address _authorisedPurchaseSigner, address _fundCollector) {
        nftFactory = _nftFactory;
        if (_authorisedPurchaseSigner == address(0)) {
            revert ZeroAuthorisedPurchaseSigner();
        }
        if (_fundCollector == address(0)) {
            revert ZeroFundCollector();
        }
        authorisedPurchaseSigner = _authorisedPurchaseSigner;
        fundCollector = _fundCollector;
    }

    /// @notice only factory or owner can call this
    modifier onlyFactoryOrOwner {
        if (msg.sender != nftFactory && owner() != msg.sender) {
            revert NotAFactoryOrOwner();
        }
        _;
    }

    /// @notice Function to provide the ownership of the minting of the given nft.
    /// @param nft Address of the nft whose purchase would be allowed.
    /// @param basePrices Base prices of the NFT during the primary sales for different series.
    /// @param series Supoorted series for a given nft sale.
    function addNFTInPrimaryMarket(
        address nft,
        uint256[] calldata basePrices,
        string[] calldata series,
        uint256[] calldata maxTokenIdForSeries
    )   external
        onlyFactoryOrOwner
        whenNotPaused
    {
        if (basePrices.length == uint256(0)) {
            revert MintPriceIsZero();
        }
        if (maxTokenIdForSeries.length != basePrices.length || series.length != basePrices.length) {
            revert IncorrectArrayLength();
        }
        if (nft == address(0)) {
            revert ZeroAddress();
        }
        // Should not be already listed.
        if (listedNFTs[nft]) {
            revert AlreadyListed();
        }

        listedNFTs[nft] = true;
        listings[nft] = ListingDetails({ basePrices: basePrices, maxTokenIds: maxTokenIdForSeries, series: series, isOpenForPurchase: true, soldCount: uint256(0) });

        // Emit event
        emit NFTListed(nft, basePrices, maxTokenIdForSeries, series);
        emit OpenForPurchase();
    }

    /// @notice Returns the listing details of an nft.
    function getListedNftDetails(address nft) external view returns(uint256[] memory, uint256[] memory, string[] memory, bool) {
        return (listings[nft].basePrices, listings[nft].maxTokenIds, listings[nft].series, listings[nft].isOpenForPurchase);
    }

    /// @dev Only for MWP.
    /// @notice Set new ETH price.
    /// @param newPrice Value of ETH in terms of USD.
    function setETHPrice(uint256 newPrice) external onlyOwner whenNotPaused {
        ETH_PRICE = newPrice;
    }

    /// @notice Allow the owner to remove the given NFT from the listings.
    /// @param nft Address of the NFT that needs to be unlisted.
    function removeNFTFromPrimaryMarket(address nft) external onlyOwner whenNotPaused {
        if (!listedNFTs[nft]) {
            revert NFTNotListed();
        }
        listedNFTs[nft] = false;
        delete listings[nft];

        // Emit logs
        emit NFTUnlisted(nft);
    }

    /// @notice Allow to change the aurhorised signer.
    /// @dev Not going to change the signer on the fly, A designated downtime would be provided during the change
    /// so least possibility of the frontrun from the owner side.
    /// @param newAuthorisedSigner New address set as the authorised signer.
    function changeAuthorisedSigner(address newAuthorisedSigner) external onlyOwner whenNotPaused {
        if (newAuthorisedSigner == address(0)) {
            revert ZeroAddress();
        }
        authorisedPurchaseSigner = newAuthorisedSigner;
        emit AuthorisedSignerChanged(newAuthorisedSigner);
    }

    /// @notice Allow a user to purchase the NFT.
    /// @param nft Address of the NFT which need to get purcahse.
    /// @param receiver Address of the receiver.
    /// @param tokenURI URI for the tokenId that get minted.
    function purchaseNFT(address nft, address receiver, string memory tokenURI) external payable nonReentrant whenNotPaused {
        if (!listedNFTs[nft]) {
            revert NFTNotListed();
        }

        // Access the details of the listing .
        ListingDetails memory _details = listings[nft];

        // Derive prices.
        uint256 price = _derivePrices(_details);

        // Check whether purchase of nft is allowed or not.
        if (!_details.isOpenForPurchase) {
            revert NotOpenForPurchase();
        }
        // Validate whether the sufficient funds are sent by the purchaser.
        if (msg.value < price) {
            revert InsufficientFundsSent();
        }
        // Get the `tokenId` to mint next.
        uint256 tokenId = INFT(nft).nextTokenId();
        // Receiver of the NFT
        address recv = receiver == address(0) ? receiver : msg.sender;
        uint256 mintFee = price;
        // Getting royalty information
        (address rRecv, uint256 rAmt) = I_ERC2981(nft).royaltyInfo(tokenId, price);

        if ((rRecv != address(0) && rAmt != uint256(0)) && rAmt < price) {
            payable(rRecv).transfer(rAmt);
            mintFee = price - rAmt;
        }
        // Transfer minting funds to the veiovia
        payable(fundCollector).transfer(mintFee);

        // Check whether there is any funds remain in the contract for the msg.sender.
        uint256 remainingBalance = msg.value - price;
        if (remainingBalance > 0) {
            payable(msg.sender).transfer(remainingBalance);
        }
        // Update to `soldCount`
        listings[nft].soldCount += 1;
        // Transfer of nft to the purchaser.
        INFT(nft).mint(recv, tokenURI);
        emit NFTPurchased(nft, recv, rRecv, tokenId, mintFee, rAmt);
    }

    function _derivePrices(ListingDetails memory _details) internal view returns(uint256 prices) {
        uint256 length = _details.basePrices.length;
        for (uint256 i = 0; i < length; i++) {
            if (_details.soldCount < _details.maxTokenIds[i]) {
                return ETH_PRICE * 1e18 / _details.basePrices[i] / 100;
            }
        }
        revert ExceedingAllowedMaxSupply();
    }

    /// @notice Allow owner of the facilitator contract to close the purchase of the given NFT.
    /// @param nft Address of the nft whose purchase need to be closed.
    function closePurchase(address nft) external onlyOwner {
        if (!listedNFTs[nft]) {
            revert NFTNotListed();
        }
        listings[nft].isOpenForPurchase = false;
        emit CloseForPurchase();
    }

    /// @notice Allow owner of the facilitator contract to update the fundCollector address.
    /// @param _fundCollector Address of the new fund collector.
    function changeFundCollector(address _fundCollector) external onlyOwner {
        if (_fundCollector == address(0)) {
            revert ZeroAddress();
        }
        fundCollector = _fundCollector;
        emit FundCollectorChanged(_fundCollector);
    }

    /// @notice allow the owner to pause some of the functionalities offered by the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice allow the owner to unpause the contract.
    function unpause() external onlyOwner {
        _unpause();
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
pragma solidity 0.8.15;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFT is IERC721 {

    /// @notice Initialize the NFT collection.
    /// @param _maxSupply maximum supply of a collection.
    /// @param baseUri base Url of the nft's metadata.
    /// @param _name name of the collection.
    /// @param _symbol symbol of the collection.
    /// @param _owner owner of the collection.
    /// @param _minter Address of the minter allowed to mint tokenIds.
    /// @param _royaltyReceiver Beneficary of the royalty.
    /// @param _feeNumerator Percentage of fee charged as royalty.
    function initialize(
        uint256 _maxSupply,
        string calldata baseUri,
        string calldata _name,
        string calldata _symbol,
        address _owner,
        address _minter,
        address _royaltyReceiver,
        uint96 _feeNumerator
    ) external;

    /// @notice Mint a token and assign it to an address.
    /// @param _to NFT transferred to the given address.
    /// @param _tokenURI URI for token metadata.
    function mint(
        address _to,
        string memory _tokenURI
    )
        external;

    function nextTokenId() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

///
/// @dev Interface for the NFT Royalty Standard
///
interface I_ERC2981 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IFacilitator {

    /// @notice Function to provide the ownership of the minting of the given nft.
    /// @param nft Address of the nft whose purchase would be allowed.
    /// @param basePrices Base prices of the NFT during the primary sales for different series.
    /// @param series Supoorted series for a given nft sale.
    function addNFTInPrimaryMarket(address nft, uint256[] calldata basePrices, string[] calldata series, uint256[] calldata _maxTokenIdForSeries) external;

    /// @notice Allow the owner to remove the given NFT from the listings.
    /// @param nft Address of the NFT that needs to be unlisted.
    function removeNFTFromPrimaryMarket(address nft) external;

    /// @notice Allow a user to purchase the NFT.
    /// @param nft Address of the NFT which need to get purcahse.
    /// @param receiver Address of the receiver.
    /// @param tokenURI URI for the tokenId that get minted.
    function purchaseNFT(address nft, address receiver, string calldata tokenURI) external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
            /// @solidity memory-safe-assembly
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
            /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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