// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
@notice ERC721 extension that overrides the OpenZeppelin _baseURI() function to
return a prefix that can be set by the contract owner.
 */
contract BaseTokenURI is Ownable {
    /// @notice Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;

    constructor(string memory _baseTokenURI) {
        setBaseTokenURI(_baseTokenURI);
    }

    /// @notice Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /**
    @notice Concatenates and returns the base token URI and the token ID without
    any additional characters (e.g. a slash).
    @dev This requires that an inheriting contract that also inherits from OZ's
    ERC721 will have to override both contracts; although we could simply
    require that users implement their own _baseURI() as here, this can easily
    be forgotten and the current approach guides them with compiler errors. This
    favours the latter half of "APIs should be easy to use and hard to misuse"
    from https://www.infoq.com/articles/API-Design-Joshua-Bloch/.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return baseTokenURI;
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "../utils/OwnerPausable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

/**
@notice An ERC721A contract with common functionality:
 - Pausable with toggling functions exposed to Owner only
 - ERC2981 royalties
 */
contract ERC721ACommon is ERC721A, OwnerPausable, ERC2981 {
    constructor(
        string memory name,
        string memory symbol,
        address payable royaltyReciever,
        uint96 royaltyBasisPoints
    ) ERC721A(name, symbol) {
        _setDefaultRoyalty(royaltyReciever, royaltyBasisPoints);
    }

    /// @notice Requires that the token exists.
    modifier tokenExists(uint256 tokenId) {
        require(ERC721A._exists(tokenId), "ERC721ACommon: Token doesn't exist");
        _;
    }

    /// @notice Requires that msg.sender owns or is approved for the token.
    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _ownershipOf(tokenId).addr == _msgSender() ||
                getApproved(tokenId) == _msgSender(),
            "ERC721ACommon: Not approved nor owner"
        );
        _;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(!paused(), "ERC721ACommon: paused");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /// @notice Overrides supportsInterface as required by inheritance.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /// @notice Sets the royalty receiver and percentage (in units of basis
    /// points = 0.01%).
    function setDefaultRoyalty(address receiver, uint96 basisPoints)
        public
        virtual
        onlyOwner
    {
        _setDefaultRoyalty(receiver, basisPoints);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

/**
@notice Allows holders of ERC721 tokens to redeem rights to some claim; for
example, the right to mint a token of some other collection.
*/
library ERC721Redeemer {
    using BitMaps for BitMaps.BitMap;
    using Strings for uint256;

    /**
    @notice Storage value to track already-claimed redemptions for a specific
    token collection.
     */
    struct Claims {
        /**
        @dev This field MUST NOT be considered part of the public API. Instead,
        prefer `using ERC721Redeemer for ERC721Redeemer.Claims` and utilise the
        provided functions.
         */
        mapping(uint256 => uint256) _total;
    }

    /**
    @notice Storage value to track already-claimed redemptions for a specific
    token collection, given that there is only a single claim allowed per
    tokenId.
     */
    struct SingleClaims {
        /**
        @dev This field MUST NOT be considered part of the public API. Instead,
        prefer `using ERC721Redeemer for ERC721Redeemer.SingleClaims` and
        utilise the provided functions.
         */
        BitMaps.BitMap _claimed;
    }

    /**
    @notice Emitted when a token's claim is redeemed.
     */
    event Redemption(
        IERC721 indexed token,
        address indexed redeemer,
        uint256 tokenId,
        uint256 n
    );

    /**
    @notice Checks that the redeemer is allowed to redeem the claims for the
    tokenIds by being either the owner or approved address for all tokenIds, and
    updates the Claims to reflect this.
    @dev For more efficient gas usage, recurring values in tokenIds SHOULD be
    adjacent to one another as this will batch expensive operations. The
    simplest way to achieve this is by sorting tokenIds.
    @param tokenIds The token IDs for which the claims are being redeemed. If
    maxAllowance > 1 then identical tokenIds can be passed more than once; see
    dev comments.
    @return The number of redeemed claims; either 0 or tokenIds.length;
     */
    function redeem(
        Claims storage claims,
        uint256 maxAllowance,
        address redeemer,
        IERC721 token,
        uint256[] calldata tokenIds
    ) internal returns (uint256) {
        if (maxAllowance == 0 || tokenIds.length == 0) {
            return 0;
        }

        // See comment for `endSameId`.
        bool multi = maxAllowance > 1;

        for (
            uint256 i = 0;
            i < tokenIds.length; /* note increment at end */

        ) {
            uint256 tokenId = tokenIds[i];
            requireOwnerOrApproved(token, tokenId, redeemer);

            uint256 n = 1;
            if (multi) {
                // If allowed > 1 we can save on expensive operations like
                // checking ownership / remaining allowance by batching equal
                // tokenIds. The algorithm assumes that equal IDs are adjacent
                // in the array.
                uint256 endSameId;
                for (
                    endSameId = i + 1;
                    endSameId < tokenIds.length &&
                        tokenIds[endSameId] == tokenId;
                    endSameId++
                ) {} // solhint-disable-line no-empty-blocks
                n = endSameId - i;
            }

            claims._total[tokenId] += n;
            if (claims._total[tokenId] > maxAllowance) {
                revertWithTokenId(
                    "ERC721Redeemer: over allowance for",
                    tokenId
                );
            }
            i += n;

            emit Redemption(token, redeemer, tokenId, n);
        }

        return tokenIds.length;
    }

    /**
    @notice Checks that the redeemer is allowed to redeem the single claim for
    each of the tokenIds by being either the owner or approved address for all
    tokenIds, and updates the SingleClaims to reflect this.
    @param tokenIds The token IDs for which the claims are being redeemed. Only
    a single claim can be made against a tokenId.
    @return The number of redeemed claims; either 0 or tokenIds.length;
     */
    function redeem(
        SingleClaims storage claims,
        address redeemer,
        IERC721 token,
        uint256[] calldata tokenIds
    ) internal returns (uint256) {
        if (tokenIds.length == 0) {
            return 0;
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            requireOwnerOrApproved(token, tokenId, redeemer);

            if (claims._claimed.get(tokenId)) {
                revertWithTokenId(
                    "ERC721Redeemer: over allowance for",
                    tokenId
                );
            }

            claims._claimed.set(tokenId);
            emit Redemption(token, redeemer, tokenId, 1);
        }
        return tokenIds.length;
    }

    /**
    @dev Reverts if neither the owner nor approved for the tokenId.
     */
    function requireOwnerOrApproved(
        IERC721 token,
        uint256 tokenId,
        address redeemer
    ) private view {
        if (
            token.ownerOf(tokenId) != redeemer &&
            token.getApproved(tokenId) != redeemer
        ) {
            revertWithTokenId(
                "ERC721Redeemer: not approved nor owner of",
                tokenId
            );
        }
    }

    /**
    @notice Reverts with the concatenation of revertMsg and tokenId.toString().
    @dev Used to save gas by constructing the revert message only as required,
    instead of passing it to require().
     */
    function revertWithTokenId(string memory revertMsg, uint256 tokenId)
        private
        pure
    {
        revert(string(abi.encodePacked(revertMsg, " ", tokenId.toString())));
    }

    /**
    @notice Returns the number of claimed redemptions for the token.
     */
    function claimed(Claims storage claims, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return claims._total[tokenId];
    }

    /**
    @notice Returns whether the token has had a claim made against it.
     */
    function claimed(SingleClaims storage claims, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return claims._claimed.get(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @notice A Pausable contract that can only be toggled by the Owner.
contract OwnerPausable is Ownable, Pausable {
    /// @notice Pauses the contract.
    function pause() public onlyOwner {
        Pausable._pause();
    }

    /// @notice Unpauses the contract.
    function unpause() public onlyOwner {
        Pausable._unpause();
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import { Bitmaps } from "./utils/Bitmap.sol";
import { OwnerPausable } from "@divergencetech/ethier/contracts/utils/OwnerPausable.sol";

library ArtMaps {
    using Bitmaps for Bitmaps.Bitmap;
    struct ArtMap {
        uint256 supply;
        uint256 totalUsed;
        Bitmaps.Bitmap usedArt;
        bool initial;
    }

    function makeArtMap(uint256 _size, bool _initial) internal pure returns (ArtMap memory) {
        ArtMap memory artMap;
        artMap.supply = _size;
        artMap.usedArt = Bitmaps.makeBitmap(_size);
        artMap.initial = _initial;
        if (_initial) {
            artMap.totalUsed = _size;
        }
        return artMap;
    }

    function setArtInUse(ArtMap storage _artMap, uint256 _index, bool _inUse) internal {
        bool storageBit = _artMap.initial ? !_inUse : _inUse;
        if (_artMap.usedArt.get(_index) != storageBit) {
            _artMap.usedArt.set(_index, storageBit);
            if (_inUse) {
                _artMap.totalUsed++;
            } else {
                _artMap.totalUsed--;
            }
        }
    }

    // get a random unused art
    // WARNING: this function may incur a high gas cost that scales with maxSupply.
    function getRandomUnusedArt(ArtMap storage _artMap) internal view returns (uint256) {
        // choose a random index and start counting in our bitmap
        uint256 _startIndex = randInt(0, _artMap.supply);
        for (uint256 i = _startIndex; i < _artMap.supply; i++) {
            if (_artInUse(_artMap, i)) {
                continue;
            }
            // stop on the first random art after our start index
            return i;
        }
        // start from the beginning of the loop and continue until the start index
        for (uint256 i = 0; i < _startIndex; i++) {
            if (_artInUse(_artMap, i)) {
                continue;
            }
            // return the first available art
            return i;
        }
        return 0; // no art available
    }

    function _artInUse(ArtMap storage _artMap, uint256 _art) internal view returns (bool) {
        return _artMap.usedArt.get(_art);
    }
}

abstract contract RadArt is OwnerPausable {
    using ArtMaps for ArtMaps.ArtMap;

    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/

    struct ArtRef {
        uint256 artId;
        bool initial;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ArtRolled(address indexed user, uint256 indexed tokenId, bool initialArt, uint256 newArt);

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    // whether or not rerolling has been started
    bool public rerollStarted;
    // initial art is used when the bit is set to 0
    ArtMaps.ArtMap public initialArt;
    // secondary art is used when the bit is set to 1
    ArtMaps.ArtMap public secondaryArt;
    // the map of token id to art
    mapping(uint256 => ArtRef) public tokenArt;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(uint256 _initialAmount, uint256 _secondaryAmount) {
        initialArt = ArtMaps.makeArtMap(_initialAmount, true);
        secondaryArt = ArtMaps.makeArtMap(_secondaryAmount, false);
    }

    /*//////////////////////////////////////////////////////////////
                                 RE-ROLL
    //////////////////////////////////////////////////////////////*/
    /// @notice Start the rerolling process.
    function startReroll() external onlyOwner {
        rerollStarted = true;
    }

    /// @notice Reroll the art for a token.
    function _rerollArt(uint256 tokenId, bool allowFromInit) internal returns (uint256 newArt) {
        require(rerollStarted, "Reroll not started");
        uint256 totalInitFree = initialArt.supply - initialArt.totalUsed;
        uint256 totalSecondaryFree = secondaryArt.supply - secondaryArt.totalUsed;
        bool useInit = allowFromInit && totalInitFree < totalSecondaryFree;

        // get a random art from the secondary art map.
        if (useInit) {
            newArt = initialArt.getRandomUnusedArt();
            initialArt.setArtInUse(newArt, true);
        } else {
            newArt = secondaryArt.getRandomUnusedArt();
            secondaryArt.setArtInUse(newArt, true);
        }

        uint256 currentArt = tokenArt[tokenId].artId;
        if (currentArt == 0) {
            // token is currently using initial art.
            // free up the initial art
            initialArt.setArtInUse(tokenId, false);
        } else {
            // token has already been rolled.
            // free up the current art
            ArtMaps.ArtMap storage currentArtMap = tokenArt[tokenId].initial ? initialArt : secondaryArt;
            currentArtMap.setArtInUse(currentArt, false);
        }

        // set the new art for the token
        tokenArt[tokenId] = ArtRef(newArt, useInit);

        // emit the event
        emit ArtRolled(msg.sender, tokenId, useInit, newArt);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    function getArt(uint256 tokenId) public view returns (uint256 artId, bool initial) {
        ArtRef memory artRef = tokenArt[tokenId];
        return (artRef.artId, artRef.initial);
    }
}

function randInt(uint256 _min, uint256 _max) view returns (uint256) {
    require(_min < _max, "min must be less than max");
    return
        _min +
        (uint256(keccak256(abi.encodePacked(_min, _max, block.timestamp, block.number, block.difficulty, msg.sender))) %
            (_max - _min));
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

/*
╢╬╬╬╬╠╠╟╠╬╢╠╬╬╠╠╠╢╬╬╠╠╠╠╬╬╬╣▌▌▓▌▌▌▌▌▌╬╬▓▓▓▓▓▓▌▓▓▓▓▒░»=┐;»:»░»¡;":¡░¡!:░┐░░░░░!░░
╠╠╠╠╠╠╠╬╣╬╬╬╬╬╬╠╠╠╠╠╠╬╬▓████████████████████████████▌▄φφφφφφφφ╦▒φφ╦φ╦▒φ╦╦╦╦φφφφφ
▒╠▓╬▒▒▒▒▒▒▒▒╠╠╠╠╠╣╣╬▓██████████████████████████████████▓▓▌╬╟╬╢╠╟╠╠╠╠╠╟╟╠╠╠╠╠╠╠╠╠
▒╚▓╣▓▓▓▓╣╬▄▓▓▒▒╠▓▒▒▓███████████████████████████▓▓▓█▓█▓█▓▓█▓▓╬╠╠╟╠╠╠╠╢╠╠╠╠╠╬╢╠╠╠╠
▒Å▓▓▓▓▓▓█▓▓▓╬╫▌╠▓▓████████████████████▓▓████████▓█▓▓█▓▓▓▓█▓█▓▓╬╠╠╠╠╠╠╠╠╠╠╬╠╬╠╠╠╟
▒╚╚░▒╚╚╩╠╬╣▓╬╣▓╣▓███████████████▓█▓██████████████████▓█▓██▓█▓██▓╬╢╟╠╠╠╢╠╟╠╠╠╠╠╟╟
╟▒▒░░Γ▒╣▒▒░#▒▒╚▓████████████████▓██████▓████████████████████████▓╬╠╠╠╟╠╬╠╟╠╬╠╠╠╠
▒╠╠╩▒▒╟▓▓▓▓╣▓▓▓███████████████▓████████████▀╫███████████████████▓▓╬╠╠╠╠╠╠╠╠╠╬╠╠╠
▒▒▒Γ░Γ▒╬╬▀╬╣▓▓███████████████████████████▓╨░░╫████████████████████▓╬╠╠╠╠╠╠╠╠╠╠╠╠
▓▓▓▓▌╬╬╠╬▒▒▒▒████████████████████████████░¡░░!╫██████████▓╟██▓██████▌╠╠╠╠╠╠╠╠╠╠╠
███████████▓██████▓████████▀╫███████████▒∩¡░░░░╙▀▓╟████▌┤░░╫███▀▀███▌╠╠╠╠╠╠╠╠╠╠╠
███████████████████████████░╙███▌│╩╨╙██▌░░░░░░░░░░░██▓╝░░░Q▓███████▓╠╠╠╟╠╠╠╠╠╠╠╠
▓▓▓███████████████████████▌ü███▓▄▄Q░░██▒\░░░░¡░░░░░╫▓▌▓███████▀▀▀╫╬╠╠╬╠╠╟╟╠╠╠╠╠╟
╬▓╬╣╬╣╣╣╣╬▓╬████████████╩▀▒░▀▀▀▀▀▀▀███████▓▌▄µ░░░░░▀▀▀╫███████Γ░░╠╟╠╠╠╠╠╠╠╠╠╠╠╠╠
█▓▓▓▓▓▓▓▓▓▓▓▓███████████░░░░░░∩░░░Q▄▄▄▄░░░┘┤╨├░¡░░░░░▄███▄█████▒░╟╠╠╠╠╠╠╠╠╠╠╠╠╠╠
▓▓▓▓▓▓▓▓▓▓▓▓▓███████████▒░░░░░▓███▀█████▄░░░░░░░¡░░ΓΓ██████████┤Γ╬╠╠╠╠╠╬╠╠╠╠╠╠╠╠
╬╬╬╣╬╣╬╬╣╬╬╬╣▓███████████░░░▄█████████████▄░░░░░¡░░░░█████████δ░░▓╬╣╣▓▓▓▓▓▓╣╣▓▓▓
╬╬╬╬╣╬╣╬╬╬╬╬╬▓████▒░░∩░▀█▒░▀██╙█▓███████▓█▌░░¡░░░░░░░╚█████▓█▒░░╫▓████▓█▓▓▓▓▓▓▓▓
╬╣╬╢╬╬╣╬╣╬╬╬╣▓███▌░░░░░░░░░░░┤~╙█▓█████▀██▒░¡░░░░░░φ░░███▓██▒░░░▓▓▓╬╚╙╫╬╫███████
╬╬╣╬╬╬╣▓▓██▓╬▓███▓░░░░░░░░░░░░(=├▀██▓█████░░░¡░>░""░Γ░░░░░░Γ░░░╫▓▓▓▓▓▓▓█▓█▓▓▓▓▓▓
╬╫╬╬╬╬╣▓╬╟╬▓╬█████▓▄▒░░░░░░░░░∩░░│▀▀▀╫╨╨╨╨░░░¡░¡░░¡¡░░░░░░░░░░╢▓██▓▓█████████▓██
▓▓▓▓▓▓▓▓╬╬╫█████████████▓▌▒░░░░░░░░░░!░░░░¡░░░░Q▄▄▄▄▄░░░░Γ░Γ▄▓▓█████████████████
▓█████╬╣▓▓▓████████████████▓▌▒░░░░░░░░░░░░░░░░████▀▀░░░░░░▄▓▓▓██████████████████
▓▓▓╬▓▓╬╣╬╬╬╬╬╬╬╬███████████████▌▄▒░░░░░░░░░░░░░░░░░░░░½▄▓▓███▓██████████████████
▓╬╠▓▓▓▓╣╣╬╣╣╬╣▓╬████▓██████████████▓▓▌▄▄░░░░░░░░φ╦▄▄▓▓███████▓█████████████▓╠▓██
▓▌╠▓▓▓╬╬╣╬╬╬╬╬╬╬▓█▓████▓█▓╬╢▓██▓▓▓▓▓▓▓▓▓▒Σ▒▒#░#▓▓▓▓▓▓██████████████▓▓████▓▓▓╬╬╬╬
▓▓╠▓███▓▓╣╣╬╣╬╣╢▓▓▓▓▓▓██▓▓▓╣▓▓█▓▓█▓██▓╬#Γ#▒▒▒░Σ╣█████████████▓╣╬▓███▓████▓╣╣╬╣╣▓
▓▓╬▓▓▓▓▓▓▓▓▓▓█▓╬▓▓▓▓▓▓▓▓█████████████▄ΓΓ╚Γ░ΓΓΓ▐▄█████████████▓╬╬╬╫█████▓╬╬╣╬╬╬╬╬
▓▓▓▓▓▓▓▓▓▓▓█████████████████▓▓██████████▓▓▓▓▓████████████▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
▓███████████████████████████████████████████████████████╬╣╬╬╬╬╬╬╬╬╬╬╬╫╬╬╬╬╬╣╬╬╬╬
▓████████████████████████████████████████████████████████╬╬╬╬╫╬╬╬╬╬╣╬╬╬╬╬╬╬╬╣╬╬╬
██████████████████████████████████▓██▓█▓▓▓███▓██▓█████████╬╬╣╬╬╣╬╬╬╬╬╣╬╬╬╬╬╬╬╬╣╣
▓█████████████████▓▓▓▓╬╬╬██████████████████▓██▓██╣████████▓╬╬╫╬╢╬╫╬╬╬╬╬╣╬╣╬╬╬╣╬╣
██████▓█▓▓╬╬╬╬╬╬╬╬╬╬╣╬╬╬▓██████████▌▓╬▒╫▓▓▌╣██▓▓╬▒█████████▌╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬
╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬╬╬╬╬╬╣████████████╣╟▓╬╣▓▓▓▓▓▓▓▓▓╫█████████╬╬╬╬╬╣╬╬╬╬╬╬╬╬╬╣╬╬╬░
                          ;                                          
                          ED.                                  :     
                          E#Wi                                t#,    
 j.                       E###G.      .          j.          ;##W.   
 EW,                   .. E#fD#W;     Ef.        EW,        :#L:WE   
 E##j                 ;W, E#t t##L    E#Wi       E##j      .KG  ,#D  
 E###D.              j##, E#t  .E#K,  E#K#D:     E###D.    EE    ;#f 
 E#jG#W;            G###, E#t    j##f E#t,E#f.   E#jG#W;  f#.     t#i
 E#t t##f         :E####, E#t    :E#K:E#WEE##Wt  E#t t##f :#G     GK 
 E#t  :K#E:      ;W#DG##, E#t   t##L  E##Ei;;;;. E#t  :K#E:;#L   LW. 
 E#KDDDD###i    j###DW##, E#t .D#W;   E#DWWt     E#KDDDD###it#f f#:  
 E#f,t#Wi,,,   G##i,,G##, E#tiW#G.    E#t f#K;   E#f,t#Wi,,, f#D#;   
 E#t  ;#W:   :K#K:   L##, E#K##i      E#Dfff##E, E#t  ;#W:    G#t    
 DWi   ,KK: ;##D.    L##, E##D.       jLLLLLLLLL;DWi   ,KK:    t     
            ,,,      .,,  E#t                                        
                          L:                                         

*/

import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { ERC721ACommon } from "@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
import { BaseTokenURI } from "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Radlist, AddCollectionParams, ClaimRadlistParams } from "./Radlist.sol";
import { RadArt } from "./RadArt.sol";
import { Radcoin } from "./Radcoin.sol";
import { Radmath } from "./Radmath.sol";

/// @notice The Original Radbro.
/// @author 10xdegen
/// @dev This contract is the main entry point for the Radbro ecosystem.
/// It is responsible for minting new Radbro NFTs and claiming Radcoin.
/// Credit goes to the Radbro team StuxnetTypeBeat AEQEA giverrod and 10xdegen
contract Radbro is ERC721ACommon, BaseTokenURI, ReentrancyGuard, Radlist, RadArt, Radmath {
    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the Radcoin ERC20 token contract.
    Radcoin public radcoin;

    /*//////////////////////////////////////////////////////////////
                            MINT CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum number of mintable radbros.
    uint256 public constant MAX_SUPPLY = 4000;

    /// @notice Maximum amount of radbros mintable via radlist.
    uint256 public constant RADLIST_MINTABLE = 1000;

    /// @notice Maximum amount of radbros reserved for team / community.
    uint256 public constant RESERVED_SUPPLY = 400;

    /// @notice Maximum amount of radbros that can be minted via Radcoin.
    // prettier-ignore
    uint256 public constant RADCOIN_MINTABLE = MAX_SUPPLY 
        - RESERVED_SUPPLY
        - RADLIST_MINTABLE;

    /*//////////////////////////////////////////////////////////////
                             MINTING STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Total number of radbros minted from the Radlist.
    uint256 public mintedFromRadlist;

    /// @notice Total number of radbros minted from the Radlist.
    uint256 public mintedFromReserve;

    /// @notice Total number of radbros minted with Radcoin.
    uint256 public mintedFromRadcoin;

    /// @notice The current spot price for minting radbros (in $RAD).
    uint128 public spotPrice;

    /// @notice Price increase for radbro (1e18+1e17 == 10% increase) on every mint.
    uint128 public priceDelta;

    /// @notice The current price for rerolling radbro art (in $RAD).
    uint128 public radrollPrice;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event RadbroMinted(address indexed user, uint8 quantity);
    event RadlistClaimed(address indexed user, uint8 quantity);
    event ArrtRadrolled(address indexed user, uint256 indexed radbroId, uint256 newArt);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address payable _beneficiary,
        uint128 _startPrice,
        uint128 _priceDelta,
        bytes32 _merkleRoot,
        AddCollectionParams[] memory _collections
    )
        ERC721ACommon("Radbro Webring", "RADBRO", _beneficiary, 0)
        Radlist(_merkleRoot, _collections)
        RadArt(4_000, 8_000) // 4k initial art, 8k secondary art
        BaseTokenURI("")
    {
        spotPrice = _startPrice;
        priceDelta = _priceDelta;
        radrollPrice = 2 ether; // 2 RAD to radroll
    }

    /*//////////////////////////////////////////////////////////////
                               INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialize the Radcoin address.
    function initialize(address _radcoin) external onlyOwner {
        require(address(radcoin) == address(0), "Radbro: Radcoin already set");
        radcoin = Radcoin(_radcoin);
    }

    /*//////////////////////////////////////////////////////////////
                               MINTING
    //////////////////////////////////////////////////////////////*/

    /**
    @notice Mint as a member of the public (using $RAD).
     */
    function mintFromRadcoin(
        address to,
        uint256[] calldata radbroIds,
        uint256 n,
        uint256 maxInput
    ) external nonReentrant {
        require(n > 0, "Radbro: Must mint at least one");
        require(mintedFromRadcoin + n <= RADCOIN_MINTABLE, "Radbro: Cannot mint more than RADCOIN_MINTABLE");
        (uint128 newSpotPrice, uint256 inputValue) = getBuyInfo(spotPrice, priceDelta, n);

        require(inputValue <= maxInput, "Radbro: Input value exceeds maxInput");
        _spendRad(_msgSender(), radbroIds, inputValue);

        mintedFromRadcoin += n;
        spotPrice = newSpotPrice;

        _mintInternal(to, n);
    }

    /**
     * @dev Mint tokens via the Radlist.
     * @param to The address that will own the minted tokens.
     * @param params Parameters for claiming from the Radlist.
     */
    function mintFromRadlist(address to, ClaimRadlistParams calldata params) external nonReentrant {
        uint256 totalClaimed = _claimRadlist(_msgSender(), params);
        require(mintedFromRadlist + totalClaimed <= RADLIST_MINTABLE, "Radbro: Max mintable reached");

        mintedFromRadlist += totalClaimed;

        _mintInternal(to, totalClaimed);
    }

    /**
     * @dev Mint tokens reserved for the team.
     * @param to The address that will own the minted tokens.
     * @param n The number to mint.
     */
    function mintFromReserve(address to, uint256 n) external onlyOwner {
        require(mintedFromReserve + n <= RESERVED_SUPPLY, "Radbro: Max mintable from reserve reached");

        mintedFromReserve += n;

        _mintInternal(to, n);
    }

    function _mintInternal(address to, uint256 n) internal whenNotPaused {
        require(totalSupply() + n <= MAX_SUPPLY, "Radbro: Max supply reached");

        // start radcoin claim counter
        for (uint256 i = totalSupply() + 1; i <= totalSupply() + n; i++) {
            radcoin.initializeRadbro(i, block.timestamp);
        }

        _safeMint(to, n);
    }

    // override start token id to 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /*//////////////////////////////////////////////////////////////
                               ART
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Update the price for rerolling radbro art.
     */
    function setRadrollPrice(uint128 _radrollPrice) external onlyOwner {
        radrollPrice = _radrollPrice;
    }

    /**
     * @dev Radroll the art for a radbro.
     */
    function radrollArt(uint256 tokenId, uint256[] calldata radbroIds) public returns (uint256 newArt) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(ownerOf(tokenId) == _msgSender(), "ERC721: caller is not the owner");
        _spendRad(_msgSender(), radbroIds, radrollPrice);

        // if we are not yet minted out, you can only radroll into art that is past max supply
        bool allowFromInit = totalSupply() == MAX_SUPPLY;

        newArt = _rerollArt(tokenId, allowFromInit);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        (uint256 art, bool initial) = getArt(tokenId);
        if (art == 0) {
            art = tokenId;
        } else if (!initial) {
            art += 4_000;
        }
        return string(abi.encodePacked(_baseURI(), _toString(art)));
    }

    /**
    @dev Required override to select the correct baseTokenURI.
     */
    function _baseURI() internal view override(BaseTokenURI, ERC721A) returns (string memory) {
        return BaseTokenURI._baseURI();
    }

    /*//////////////////////////////////////////////////////////////
                               PAYMENTS (RADCOIN)
    //////////////////////////////////////////////////////////////*/

    /// @notice Burn Radcoin from the user's account.
    /// If there is sufficient unclaimed Radcoin to claim, claim that instead of burning.
    function _spendRad(address owner, uint256[] calldata radbroIds, uint256 amount) internal {
        require(address(radcoin) != address(0), "Radbro: Radcoin not set");

        for (uint256 i = 0; i < radbroIds.length; i++) {
            uint256 radbroId = radbroIds[i];
            require(_exists(radbroId), "Radbro: Radbro does not exist");
            require(ownerOf(radbroId) == owner, "Radbro: Not owner of Radbro");
            uint256 reward = radcoin.getClaimReward(radbroId);

            if (reward == 0) {
                continue;
            }
            if (reward >= amount) {
                radcoin.claimForRadbro(radbroId, amount);
                return;
            } else {
                radcoin.claimForRadbro(radbroId, reward);
                amount -= reward;
            }
        }

        radcoin.burnForRadbros(owner, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import "hardhat/console.sol";
/*
╢╬╬╬╬╠╠╟╠╬╢╠╬╬╠╠╠╢╬╬╠╠╠╠╬╬╬╣▌▌▓▌▌▌▌▌▌╬╬▓▓▓▓▓▓▌▓▓▓▓▒░»=┐;»:»░»¡;":¡░¡!:░┐░░░░░!░░
╠╠╠╠╠╠╠╬╣╬╬╬╬╬╬╠╠╠╠╠╠╬╬▓████████████████████████████▌▄φφφφφφφφ╦▒φφ╦φ╦▒φ╦╦╦╦φφφφφ
▒╠▓╬▒▒▒▒▒▒▒▒╠╠╠╠╠╣╣╬▓██████████████████████████████████▓▓▌╬╟╬╢╠╟╠╠╠╠╠╟╟╠╠╠╠╠╠╠╠╠
▒╚▓╣▓▓▓▓╣╬▄▓▓▒▒╠▓▒▒▓███████████████████████████▓▓▓█▓█▓█▓▓█▓▓╬╠╠╟╠╠╠╠╢╠╠╠╠╠╬╢╠╠╠╠
▒Å▓▓▓▓▓▓█▓▓▓╬╫▌╠▓▓████████████████████▓▓████████▓█▓▓█▓▓▓▓█▓█▓▓╬╠╠╠╠╠╠╠╠╠╠╬╠╬╠╠╠╟
▒╚╚░▒╚╚╩╠╬╣▓╬╣▓╣▓███████████████▓█▓██████████████████▓█▓██▓█▓██▓╬╢╟╠╠╠╢╠╟╠╠╠╠╠╟╟
╟▒▒░░Γ▒╣▒▒░#▒▒╚▓████████████████▓██████▓████████████████████████▓╬╠╠╠╟╠╬╠╟╠╬╠╠╠╠
▒╠╠╩▒▒╟▓▓▓▓╣▓▓▓███████████████▓████████████▀╫███████████████████▓▓╬╠╠╠╠╠╠╠╠╠╬╠╠╠
▒▒▒Γ░Γ▒╬╬▀╬╣▓▓███████████████████████████▓╨░░╫████████████████████▓╬╠╠╠╠╠╠╠╠╠╠╠╠
▓▓▓▓▌╬╬╠╬▒▒▒▒████████████████████████████░¡░░!╫██████████▓╟██▓██████▌╠╠╠╠╠╠╠╠╠╠╠
███████████▓██████▓████████▀╫███████████▒∩¡░░░░╙▀▓╟████▌┤░░╫███▀▀███▌╠╠╠╠╠╠╠╠╠╠╠
███████████████████████████░╙███▌│╩╨╙██▌░░░░░░░░░░░██▓╝░░░Q▓███████▓╠╠╠╟╠╠╠╠╠╠╠╠
▓▓▓███████████████████████▌ü███▓▄▄Q░░██▒\░░░░¡░░░░░╫▓▌▓███████▀▀▀╫╬╠╠╬╠╠╟╟╠╠╠╠╠╟
╬▓╬╣╬╣╣╣╣╬▓╬████████████╩▀▒░▀▀▀▀▀▀▀███████▓▌▄µ░░░░░▀▀▀╫███████Γ░░╠╟╠╠╠╠╠╠╠╠╠╠╠╠╠
█▓▓▓▓▓▓▓▓▓▓▓▓███████████░░░░░░∩░░░Q▄▄▄▄░░░┘┤╨├░¡░░░░░▄███▄█████▒░╟╠╠╠╠╠╠╠╠╠╠╠╠╠╠
▓▓▓▓▓▓▓▓▓▓▓▓▓███████████▒░░░░░▓███▀█████▄░░░░░░░¡░░ΓΓ██████████┤Γ╬╠╠╠╠╠╬╠╠╠╠╠╠╠╠
╬╬╬╣╬╣╬╬╣╬╬╬╣▓███████████░░░▄█████████████▄░░░░░¡░░░░█████████δ░░▓╬╣╣▓▓▓▓▓▓╣╣▓▓▓
╬╬╬╬╣╬╣╬╬╬╬╬╬▓████▒░░∩░▀█▒░▀██╙█▓███████▓█▌░░¡░░░░░░░╚█████▓█▒░░╫▓████▓█▓▓▓▓▓▓▓▓
╬╣╬╢╬╬╣╬╣╬╬╬╣▓███▌░░░░░░░░░░░┤~╙█▓█████▀██▒░¡░░░░░░φ░░███▓██▒░░░▓▓▓╬╚╙╫╬╫███████
╬╬╣╬╬╬╣▓▓██▓╬▓███▓░░░░░░░░░░░░(=├▀██▓█████░░░¡░>░""░Γ░░░░░░Γ░░░╫▓▓▓▓▓▓▓█▓█▓▓▓▓▓▓
╬╫╬╬╬╬╣▓╬╟╬▓╬█████▓▄▒░░░░░░░░░∩░░│▀▀▀╫╨╨╨╨░░░¡░¡░░¡¡░░░░░░░░░░╢▓██▓▓█████████▓██
▓▓▓▓▓▓▓▓╬╬╫█████████████▓▌▒░░░░░░░░░░!░░░░¡░░░░Q▄▄▄▄▄░░░░Γ░Γ▄▓▓█████████████████
▓█████╬╣▓▓▓████████████████▓▌▒░░░░░░░░░░░░░░░░████▀▀░░░░░░▄▓▓▓██████████████████
▓▓▓╬▓▓╬╣╬╬╬╬╬╬╬╬███████████████▌▄▒░░░░░░░░░░░░░░░░░░░░½▄▓▓███▓██████████████████
▓╬╠▓▓▓▓╣╣╬╣╣╬╣▓╬████▓██████████████▓▓▌▄▄░░░░░░░░φ╦▄▄▓▓███████▓█████████████▓╠▓██
▓▌╠▓▓▓╬╬╣╬╬╬╬╬╬╬▓█▓████▓█▓╬╢▓██▓▓▓▓▓▓▓▓▓▒Σ▒▒#░#▓▓▓▓▓▓██████████████▓▓████▓▓▓╬╬╬╬
▓▓╠▓███▓▓╣╣╬╣╬╣╢▓▓▓▓▓▓██▓▓▓╣▓▓█▓▓█▓██▓╬#Γ#▒▒▒░Σ╣█████████████▓╣╬▓███▓████▓╣╣╬╣╣▓
▓▓╬▓▓▓▓▓▓▓▓▓▓█▓╬▓▓▓▓▓▓▓▓█████████████▄ΓΓ╚Γ░ΓΓΓ▐▄█████████████▓╬╬╬╫█████▓╬╬╣╬╬╬╬╬
▓▓▓▓▓▓▓▓▓▓▓█████████████████▓▓██████████▓▓▓▓▓████████████▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
▓███████████████████████████████████████████████████████╬╣╬╬╬╬╬╬╬╬╬╬╬╫╬╬╬╬╬╣╬╬╬╬
▓████████████████████████████████████████████████████████╬╬╬╬╫╬╬╬╬╬╣╬╬╬╬╬╬╬╬╣╬╬╬
██████████████████████████████████▓██▓█▓▓▓███▓██▓█████████╬╬╣╬╬╣╬╬╬╬╬╣╬╬╬╬╬╬╬╬╣╣
▓█████████████████▓▓▓▓╬╬╬██████████████████▓██▓██╣████████▓╬╬╫╬╢╬╫╬╬╬╬╬╣╬╣╬╬╬╣╬╣
██████▓█▓▓╬╬╬╬╬╬╬╬╬╬╣╬╬╬▓██████████▌▓╬▒╫▓▓▌╣██▓▓╬▒█████████▌╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬
╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬╬╬╬╬╬╣████████████╣╟▓╬╣▓▓▓▓▓▓▓▓▓╫█████████╬╬╬╬╬╣╬╬╬╬╬╬╬╬╬╣╬╬╬░
                          ;                                          
                          ED.                                  :     
                          E#Wi                                t#,    
 j.                       E###G.      .          j.          ;##W.   
 EW,                   .. E#fD#W;     Ef.        EW,        :#L:WE   
 E##j                 ;W, E#t t##L    E#Wi       E##j      .KG  ,#D  
 E###D.              j##, E#t  .E#K,  E#K#D:     E###D.    EE    ;#f 
 E#jG#W;            G###, E#t    j##f E#t,E#f.   E#jG#W;  f#.     t#i
 E#t t##f         :E####, E#t    :E#K:E#WEE##Wt  E#t t##f :#G     GK 
 E#t  :K#E:      ;W#DG##, E#t   t##L  E##Ei;;;;. E#t  :K#E:;#L   LW. 
 E#KDDDD###i    j###DW##, E#t .D#W;   E#DWWt     E#KDDDD###it#f f#:  
 E#f,t#Wi,,,   G##i,,G##, E#tiW#G.    E#t f#K;   E#f,t#Wi,,, f#D#;   
 E#t  ;#W:   :K#K:   L##, E#K##i      E#Dfff##E, E#t  ;#W:    G#t    
 DWi   ,KK: ;##D.    L##, E##D.       jLLLLLLLLL;DWi   ,KK:    t     
            ,,,      .,,  E#t                                        
                          L:                                         

*/

import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";
import { FixedPointMathLib } from "solmate/src/utils/FixedPointMathLib.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Radcoins for Radbros.
/// @author 10xdegen
contract Radcoin is ERC20, ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                     EVENTS
    //////////////////////////////////////////////////////////////*/

    event Claim(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256[] radbros,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                    RADBRO
    //////////////////////////////////////////////////////////////*/

    address public immutable radbro;
    uint256 public immutable MAX_PER_RADBRO = 250 ether;
    uint256 public immutable REWARD_PER_DAY = 1 ether;

    /*//////////////////////////////////////////////////////////////
                    STATE
    //////////////////////////////////////////////////////////////*/

    struct ClaimState {
        uint256 startTime; // time
        uint256 totalClaimed; // total amount claimed
    }

    // token id to the state of the claim
    mapping(uint256 => ClaimState) public claims;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Requires caller address to match user address.
    modifier only(address user) {
        if (msg.sender != user) revert Unauthorized();

        _;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _radbro) ERC20("Radcoin", "RAD", 18) {
        radbro = _radbro;
    }

    /*//////////////////////////////////////////////////////////////
                                CLAIMING
    //////////////////////////////////////////////////////////////*/

    /// @dev test mint coins for testing
    function mintForTest(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /// @notice Each radbro starts with 0 reward.
    /// Called on new radbro mint.
    function initializeRadbro(uint256 id, uint256 startTime) external only(radbro) {
        claims[id] = ClaimState(startTime, 0);
    }

    // @notice Gets the claim state for the radbro id.
    // @param radbroId The radbro id.
    // @return The claim state.
    function getClaim(uint256 radbroId) public view returns (ClaimState memory) {
        return claims[radbroId];
    }

    // @notice Get the radcoin reward for a given radbro. Each Radbro pays 1e18 Radcoin per day.
    // @param radbroId The radbro id.
    // @return The radcoin reward.
    function getClaimRewards(uint256[] calldata radbroIds) public view returns (uint256 reward) {
        for (uint256 i = 0; i < radbroIds.length; i++) {
            uint256 radbroId = radbroIds[i];
            reward += getClaimReward(radbroId);
        }
    }

    // @notice Get the radcoin reward for a given radbro. Each Radbro pays 1e18 Radcoin per day.
    // @param radbroId The radbro id.
    // @return The radcoin reward.
    function getClaimReward(uint256 radbroId) public view returns (uint256 reward) {
        ClaimState memory claim = getClaim(radbroId);
        require(claim.startTime != 0, "NOT_INITIALIZED");
        if (claim.startTime >= block.timestamp) return 0; // should never happen

        uint256 radbroAge = block.timestamp - claim.startTime;

        uint256 totalEarned = ((radbroAge * REWARD_PER_DAY) / 1 days);
        // console.log("id, totalEarned, totalClaimed", radbroId, totalEarned, claim.totalClaimed);
        reward = totalEarned - claim.totalClaimed;
        // console.log("reward, MAX_PER_RADBRO, totalClaimed, startTime", reward, MAX_PER_RADBRO, claim.startTime);
        if (reward > MAX_PER_RADBRO - claim.totalClaimed) {
            reward = MAX_PER_RADBRO - claim.totalClaimed; // cap at MAX_PER_RADBRO per radbro
        }
    }

    /// @notice Claim RAD for a set of Radbros. Caller must be the owner of the Radbros.
    /// @param _receiver The address to receive the RAD.
    /// @param _radbros The Radbros to claim for.
    /// @return amount The amount of RAD claimed.
    function claimRadcoin(
        address _receiver,
        uint256[] calldata _radbros
    ) external nonReentrant returns (uint256 amount) {
        for (uint256 i = 0; i < _radbros.length; i++) {
            uint256 radbroId = _radbros[i];

            require(IERC721(radbro).ownerOf(radbroId) == msg.sender, "NOT_RAD_BRO");

            uint256 rewardForRadbro = getClaimReward(radbroId);
            if (rewardForRadbro > 0) {
                claims[radbroId].totalClaimed += rewardForRadbro;
                amount += rewardForRadbro;
            }
        }

        require(amount > 0, "NO_RAD_CLAIMABLE");

        _mint(_receiver, amount);
    }

    /// @notice Spend (burn) virtual radcoin without needing to mint. Can only be called by Radbro.
    /// @param radbroId The id of the radbro to burn claim from.
    /// @param amount The amount of radcoin to burn.
    function claimForRadbro(uint256 radbroId, uint256 amount) external only(radbro) {
        uint256 rewardForRadbro = getClaimReward(radbroId);
        console.log("claiming rewardForRadbro", rewardForRadbro, amount, claims[radbroId].totalClaimed);
        require(rewardForRadbro >= amount, "NOT_ENOUGH_REWARD");

        if (amount > 0) {
            claims[radbroId].totalClaimed += amount;
        }
        console.log("remaining reward", getClaimReward(radbroId));
    }

    /*//////////////////////////////////////////////////////////////
                             BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Burn any amount of radcoin from a user. Can only be called by Radbros.
    /// @param from The address of the user to burn radcoin from.
    /// @param amount The amount of radcoin to burn.
    function burnForRadbros(address from, uint256 amount) external only(radbro) {
        require(balanceOf[from] >= amount, "NOT_ENOUGH_BALANCE");
        _burn(from, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) external nonReentrant {
        require(balanceOf[account] >= amount, "NOT_ENOUGH_BALANCE");
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance[owner][spender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

/*

╢╬╬╬╬╠╠╟╠╬╢╠╬╬╠╠╠╢╬╬╠╠╠╠╬╬╬╣▌▌▓▌▌▌▌▌▌╬╬▓▓▓▓▓▓▌▓▓▓▓▒░»=┐;»:»░»¡;":¡░¡!:░┐░░░░░!░░
╠╠╠╠╠╠╠╬╣╬╬╬╬╬╬╠╠╠╠╠╠╬╬▓████████████████████████████▌▄φφφφφφφφ╦▒φφ╦φ╦▒φ╦╦╦╦φφφφφ
▒╠▓╬▒▒▒▒▒▒▒▒╠╠╠╠╠╣╣╬▓██████████████████████████████████▓▓▌╬╟╬╢╠╟╠╠╠╠╠╟╟╠╠╠╠╠╠╠╠╠
▒╚▓╣▓▓▓▓╣╬▄▓▓▒▒╠▓▒▒▓███████████████████████████▓▓▓█▓█▓█▓▓█▓▓╬╠╠╟╠╠╠╠╢╠╠╠╠╠╬╢╠╠╠╠
▒Å▓▓▓▓▓▓█▓▓▓╬╫▌╠▓▓████████████████████▓▓████████▓█▓▓█▓▓▓▓█▓█▓▓╬╠╠╠╠╠╠╠╠╠╠╬╠╬╠╠╠╟
▒╚╚░▒╚╚╩╠╬╣▓╬╣▓╣▓███████████████▓█▓██████████████████▓█▓██▓█▓██▓╬╢╟╠╠╠╢╠╟╠╠╠╠╠╟╟
╟▒▒░░Γ▒╣▒▒░#▒▒╚▓████████████████▓██████▓████████████████████████▓╬╠╠╠╟╠╬╠╟╠╬╠╠╠╠
▒╠╠╩▒▒╟▓▓▓▓╣▓▓▓███████████████▓████████████▀╫███████████████████▓▓╬╠╠╠╠╠╠╠╠╠╬╠╠╠
▒▒▒Γ░Γ▒╬╬▀╬╣▓▓███████████████████████████▓╨░░╫████████████████████▓╬╠╠╠╠╠╠╠╠╠╠╠╠
▓▓▓▓▌╬╬╠╬▒▒▒▒████████████████████████████░¡░░!╫██████████▓╟██▓██████▌╠╠╠╠╠╠╠╠╠╠╠
███████████▓██████▓████████▀╫███████████▒∩¡░░░░╙▀▓╟████▌┤░░╫███▀▀███▌╠╠╠╠╠╠╠╠╠╠╠
███████████████████████████░╙███▌│╩╨╙██▌░░░░░░░░░░░██▓╝░░░Q▓███████▓╠╠╠╟╠╠╠╠╠╠╠╠
▓▓▓███████████████████████▌ü███▓▄▄Q░░██▒\░░░░¡░░░░░╫▓▌▓███████▀▀▀╫╬╠╠╬╠╠╟╟╠╠╠╠╠╟
╬▓╬╣╬╣╣╣╣╬▓╬████████████╩▀▒░▀▀▀▀▀▀▀███████▓▌▄µ░░░░░▀▀▀╫███████Γ░░╠╟╠╠╠╠╠╠╠╠╠╠╠╠╠
█▓▓▓▓▓▓▓▓▓▓▓▓███████████░░░░░░∩░░░Q▄▄▄▄░░░┘┤╨├░¡░░░░░▄███▄█████▒░╟╠╠╠╠╠╠╠╠╠╠╠╠╠╠
▓▓▓▓▓▓▓▓▓▓▓▓▓███████████▒░░░░░▓███▀█████▄░░░░░░░¡░░ΓΓ██████████┤Γ╬╠╠╠╠╠╬╠╠╠╠╠╠╠╠
╬╬╬╣╬╣╬╬╣╬╬╬╣▓███████████░░░▄█████████████▄░░░░░¡░░░░█████████δ░░▓╬╣╣▓▓▓▓▓▓╣╣▓▓▓
╬╬╬╬╣╬╣╬╬╬╬╬╬▓████▒░░∩░▀█▒░▀██╙█▓███████▓█▌░░¡░░░░░░░╚█████▓█▒░░╫▓████▓█▓▓▓▓▓▓▓▓
╬╣╬╢╬╬╣╬╣╬╬╬╣▓███▌░░░░░░░░░░░┤~╙█▓█████▀██▒░¡░░░░░░φ░░███▓██▒░░░▓▓▓╬╚╙╫╬╫███████
╬╬╣╬╬╬╣▓▓██▓╬▓███▓░░░░░░░░░░░░(=├▀██▓█████░░░¡░>░""░Γ░░░░░░Γ░░░╫▓▓▓▓▓▓▓█▓█▓▓▓▓▓▓
╬╫╬╬╬╬╣▓╬╟╬▓╬█████▓▄▒░░░░░░░░░∩░░│▀▀▀╫╨╨╨╨░░░¡░¡░░¡¡░░░░░░░░░░╢▓██▓▓█████████▓██
▓▓▓▓▓▓▓▓╬╬╫█████████████▓▌▒░░░░░░░░░░!░░░░¡░░░░Q▄▄▄▄▄░░░░Γ░Γ▄▓▓█████████████████
▓█████╬╣▓▓▓████████████████▓▌▒░░░░░░░░░░░░░░░░████▀▀░░░░░░▄▓▓▓██████████████████
▓▓▓╬▓▓╬╣╬╬╬╬╬╬╬╬███████████████▌▄▒░░░░░░░░░░░░░░░░░░░░½▄▓▓███▓██████████████████
▓╬╠▓▓▓▓╣╣╬╣╣╬╣▓╬████▓██████████████▓▓▌▄▄░░░░░░░░φ╦▄▄▓▓███████▓█████████████▓╠▓██
▓▌╠▓▓▓╬╬╣╬╬╬╬╬╬╬▓█▓████▓█▓╬╢▓██▓▓▓▓▓▓▓▓▓▒Σ▒▒#░#▓▓▓▓▓▓██████████████▓▓████▓▓▓╬╬╬╬
▓▓╠▓███▓▓╣╣╬╣╬╣╢▓▓▓▓▓▓██▓▓▓╣▓▓█▓▓█▓██▓╬#Γ#▒▒▒░Σ╣█████████████▓╣╬▓███▓████▓╣╣╬╣╣▓
▓▓╬▓▓▓▓▓▓▓▓▓▓█▓╬▓▓▓▓▓▓▓▓█████████████▄ΓΓ╚Γ░ΓΓΓ▐▄█████████████▓╬╬╬╫█████▓╬╬╣╬╬╬╬╬
▓▓▓▓▓▓▓▓▓▓▓█████████████████▓▓██████████▓▓▓▓▓████████████▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
▓███████████████████████████████████████████████████████╬╣╬╬╬╬╬╬╬╬╬╬╬╫╬╬╬╬╬╣╬╬╬╬
▓████████████████████████████████████████████████████████╬╬╬╬╫╬╬╬╬╬╣╬╬╬╬╬╬╬╬╣╬╬╬
██████████████████████████████████▓██▓█▓▓▓███▓██▓█████████╬╬╣╬╬╣╬╬╬╬╬╣╬╬╬╬╬╬╬╬╣╣
▓█████████████████▓▓▓▓╬╬╬██████████████████▓██▓██╣████████▓╬╬╫╬╢╬╫╬╬╬╬╬╣╬╣╬╬╬╣╬╣
██████▓█▓▓╬╬╬╬╬╬╬╬╬╬╣╬╬╬▓██████████▌▓╬▒╫▓▓▌╣██▓▓╬▒█████████▌╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬
╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬╬╬╬╬╬╣████████████╣╟▓╬╣▓▓▓▓▓▓▓▓▓╫█████████╬╬╬╬╬╣╬╬╬╬╬╬╬╬╬╣╬╬╬░
                          ;                                          
                          ED.                                  :     
                          E#Wi                                t#,    
 j.                       E###G.      .          j.          ;##W.   
 EW,                   .. E#fD#W;     Ef.        EW,        :#L:WE   
 E##j                 ;W, E#t t##L    E#Wi       E##j      .KG  ,#D  
 E###D.              j##, E#t  .E#K,  E#K#D:     E###D.    EE    ;#f 
 E#jG#W;            G###, E#t    j##f E#t,E#f.   E#jG#W;  f#.     t#i
 E#t t##f         :E####, E#t    :E#K:E#WEE##Wt  E#t t##f :#G     GK 
 E#t  :K#E:      ;W#DG##, E#t   t##L  E##Ei;;;;. E#t  :K#E:;#L   LW. 
 E#KDDDD###i    j###DW##, E#t .D#W;   E#DWWt     E#KDDDD###it#f f#:  
 E#f,t#Wi,,,   G##i,,G##, E#tiW#G.    E#t f#K;   E#f,t#Wi,,, f#D#;   
 E#t  ;#W:   :K#K:   L##, E#K##i      E#Dfff##E, E#t  ;#W:    G#t    
 DWi   ,KK: ;##D.    L##, E##D.       jLLLLLLLLL;DWi   ,KK:    t     
            ,,,      .,,  E#t                                        
                          L:                                         

*/

import { OwnerPausable } from "@divergencetech/ethier/contracts/utils/OwnerPausable.sol";
import { ERC721Redeemer } from "@divergencetech/ethier/contracts/erc721/ERC721Redeemer.sol";
import { MerkleProofLib } from "solmate/src/utils/MerkleProofLib.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/*//////////////////////////////////////////////////////////////
                        PARAMETER TYPES
//////////////////////////////////////////////////////////////*/

struct AddCollectionParams {
    address collection;
    uint16 multiplier;
    uint16 maxPerWallet;
}

struct ClaimRadlistParams {
    ClaimRadlistForMerkleProof merkleProof;
    ClaimRadlistForCollection[] collections;
}

struct ClaimRadlistForMerkleProof {
    uint256 merkleAmount;
    bytes32[] merkleProof;
}

struct ClaimRadlistForCollection {
    address collection;
    uint256[] ids;
}

/// @notice Radlist, on-chain Radness verification.
/// @author 10xdegen
abstract contract Radlist is OwnerPausable {
    using ERC721Redeemer for ERC721Redeemer.SingleClaims;
    using Strings for uint16;

    /*//////////////////////////////////////////////////////////////
                                 STORAGE TYPES
    //////////////////////////////////////////////////////////////*/

    struct RadlistedCollection {
        Options options;
        Claimed claimed;
    }

    struct Options {
        uint16 multiplier;
        uint16 maxPerWallet;
    }

    struct Claimed {
        ERC721Redeemer.SingleClaims claims;
        // number claimed per wallet
        mapping(address => uint16) perWallet;
    }

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    // radlist merkle root
    bytes32 public merkleRoot;

    // claimed radlist
    mapping(address => uint16) public merkleClaimed;

    // list of radlisted nft collections
    address[] public collectionList;

    // config and state of radlisted nft collections
    mapping(address => RadlistedCollection) collections;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor.
     * @param _merkleRoot The merkle root.
     * @param _collections The radlisted collections to add.
     */
    constructor(bytes32 _merkleRoot, AddCollectionParams[] memory _collections) {
        merkleRoot = _merkleRoot;
        for (uint256 i = 0; i < _collections.length; i++) {
            uint16 multiplier = _collections[i].multiplier;
            uint16 maxPerWallet = _collections[i].maxPerWallet;
            if (multiplier == 0) multiplier = 1;
            collectionList.push(_collections[i].collection);
            collections[_collections[i].collection].options = Options(multiplier, maxPerWallet);
        }
    }

    /**
     * @dev Add a collection to the radlist.
     * @param _collections The collections to add.
     */
    function addCollections(AddCollectionParams[] memory _collections) external onlyOwner {
        for (uint256 i = 0; i < _collections.length; i++) {
            address collection = _collections[i].collection;
            uint16 multiplier = _collections[i].multiplier;
            if (multiplier == 0) multiplier = 1;
            collectionList.push(collection);
            collections[collection].options = Options(multiplier, _collections[i].maxPerWallet);
        }
    }

    /**
    @dev Update the merkle root, for adding new radlisters.
     */
    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
    @dev Check if an NFT has already been claimed.
     */
    function claimedNFT(address collection, uint256 id) public view returns (bool) {
        RadlistedCollection storage radlistedCollection = collections[collection];
        Claimed storage claimed = radlistedCollection.claimed;
        return claimed.claims.claimed(id);
    }

    function _claimRadlist(address wallet, ClaimRadlistParams calldata params) internal returns (uint16 totalClaimed) {
        // verify merkle proof
        if (params.merkleProof.merkleAmount > 0) {
            require(
                verifyMerkleProof(
                    wallet,
                    params.merkleProof.merkleAmount + merkleClaimed[wallet],
                    params.merkleProof.merkleProof
                ),
                "Radlist: invalid merkle proof"
            );
            merkleClaimed[wallet] += uint16(params.merkleProof.merkleAmount);
            totalClaimed += uint16(params.merkleProof.merkleAmount);
        }

        // claim radlisted nfts
        for (uint256 i = 0; i < params.collections.length; i++) {
            address collection = params.collections[i].collection;
            uint256[] calldata ids = params.collections[i].ids;

            RadlistedCollection storage radlistedCollection = collections[collection];
            Claimed storage claimed = radlistedCollection.claimed;
            Options storage options = radlistedCollection.options;

            // check redemption
            uint256 amount = claimed.claims.redeem(wallet, IERC721(collection), ids) * options.multiplier;

            // check max per wallet
            uint256 alreadyClaimed = claimed.perWallet[wallet];
            require(
                alreadyClaimed + amount <= options.maxPerWallet,
                string(
                    abi.encodePacked(
                        "Radlist: max per wallet exceeded",
                        " ",
                        wallet,
                        " ",
                        uint16(amount).toString(),
                        " ",
                        options.maxPerWallet.toString()
                    )
                )
            );

            // increment claimed amounts
            claimed.perWallet[wallet] = uint16(alreadyClaimed + amount);
            totalClaimed += uint16(amount);
        }
    }

    /**
     * @dev Helper fuction to get already claimed amount for a wallet.
     */
    function claimedAmount(address wallet, address collection) public view returns (uint16) {
        RadlistedCollection storage radlistedCollection = collections[collection];
        Claimed storage claimed = radlistedCollection.claimed;
        return claimed.perWallet[wallet];
    }

    /**
     * @dev Verify a merkle proof.
     * @param wallet The address to claim spots for.
     * @param amount The number of spots to claim.
     * @param merkleProof The merkle proof.
     * @return valid if the proof is valid.
     */
    function verifyMerkleProof(
        address wallet,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public view returns (bool valid) {
        if (amount == 0) return true; // no spots to claim
        bytes32 node = keccak256(abi.encodePacked(wallet, amount));
        valid = MerkleProofLib.verify(merkleProof, merkleRoot, node);
    }

    /**
     * @dev Verify radlisted NFTs.
     * @param wallet The address to claim spots for.
     * @param collection The NFT collection address.
     * @param ids The NFT ids to claim spots with.
     * @return eligibleIds The NFT ids that are valid to claim with.
     * @return claims The number of total redeemable claims for the list.
     */
    function getRadlistedNFTs(
        address wallet,
        address collection,
        uint256[] calldata ids
    ) external view returns (uint256[] memory, uint256 claims) {
        RadlistedCollection storage radlistedCollection = collections[collection];
        uint16 alreadyClaimed = radlistedCollection.claimed.perWallet[wallet];

        IERC721 nft = IERC721(collection);

        uint256[] memory eligibleIds = new uint256[](ids.length);
        uint256 eligibleCount = 0;

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (nft.ownerOf(id) == wallet && !radlistedCollection.claimed.claims.claimed(id)) {
                eligibleIds[eligibleCount] = id;
                eligibleCount++;
                claims += radlistedCollection.options.multiplier;
            }
        }

        if (claims + alreadyClaimed > radlistedCollection.options.maxPerWallet) {
            claims = radlistedCollection.options.maxPerWallet - alreadyClaimed;
        }

        return (eligibleIds, claims);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

/*
╢╬╬╬╬╠╠╟╠╬╢╠╬╬╠╠╠╢╬╬╠╠╠╠╬╬╬╣▌▌▓▌▌▌▌▌▌╬╬▓▓▓▓▓▓▌▓▓▓▓▒░»=┐;»:»░»¡;":¡░¡!:░┐░░░░░!░░
╠╠╠╠╠╠╠╬╣╬╬╬╬╬╬╠╠╠╠╠╠╬╬▓████████████████████████████▌▄φφφφφφφφ╦▒φφ╦φ╦▒φ╦╦╦╦φφφφφ
▒╠▓╬▒▒▒▒▒▒▒▒╠╠╠╠╠╣╣╬▓██████████████████████████████████▓▓▌╬╟╬╢╠╟╠╠╠╠╠╟╟╠╠╠╠╠╠╠╠╠
▒╚▓╣▓▓▓▓╣╬▄▓▓▒▒╠▓▒▒▓███████████████████████████▓▓▓█▓█▓█▓▓█▓▓╬╠╠╟╠╠╠╠╢╠╠╠╠╠╬╢╠╠╠╠
▒Å▓▓▓▓▓▓█▓▓▓╬╫▌╠▓▓████████████████████▓▓████████▓█▓▓█▓▓▓▓█▓█▓▓╬╠╠╠╠╠╠╠╠╠╠╬╠╬╠╠╠╟
▒╚╚░▒╚╚╩╠╬╣▓╬╣▓╣▓███████████████▓█▓██████████████████▓█▓██▓█▓██▓╬╢╟╠╠╠╢╠╟╠╠╠╠╠╟╟
╟▒▒░░Γ▒╣▒▒░#▒▒╚▓████████████████▓██████▓████████████████████████▓╬╠╠╠╟╠╬╠╟╠╬╠╠╠╠
▒╠╠╩▒▒╟▓▓▓▓╣▓▓▓███████████████▓████████████▀╫███████████████████▓▓╬╠╠╠╠╠╠╠╠╠╬╠╠╠
▒▒▒Γ░Γ▒╬╬▀╬╣▓▓███████████████████████████▓╨░░╫████████████████████▓╬╠╠╠╠╠╠╠╠╠╠╠╠
▓▓▓▓▌╬╬╠╬▒▒▒▒████████████████████████████░¡░░!╫██████████▓╟██▓██████▌╠╠╠╠╠╠╠╠╠╠╠
███████████▓██████▓████████▀╫███████████▒∩¡░░░░╙▀▓╟████▌┤░░╫███▀▀███▌╠╠╠╠╠╠╠╠╠╠╠
███████████████████████████░╙███▌│╩╨╙██▌░░░░░░░░░░░██▓╝░░░Q▓███████▓╠╠╠╟╠╠╠╠╠╠╠╠
▓▓▓███████████████████████▌ü███▓▄▄Q░░██▒\░░░░¡░░░░░╫▓▌▓███████▀▀▀╫╬╠╠╬╠╠╟╟╠╠╠╠╠╟
╬▓╬╣╬╣╣╣╣╬▓╬████████████╩▀▒░▀▀▀▀▀▀▀███████▓▌▄µ░░░░░▀▀▀╫███████Γ░░╠╟╠╠╠╠╠╠╠╠╠╠╠╠╠
█▓▓▓▓▓▓▓▓▓▓▓▓███████████░░░░░░∩░░░Q▄▄▄▄░░░┘┤╨├░¡░░░░░▄███▄█████▒░╟╠╠╠╠╠╠╠╠╠╠╠╠╠╠
▓▓▓▓▓▓▓▓▓▓▓▓▓███████████▒░░░░░▓███▀█████▄░░░░░░░¡░░ΓΓ██████████┤Γ╬╠╠╠╠╠╬╠╠╠╠╠╠╠╠
╬╬╬╣╬╣╬╬╣╬╬╬╣▓███████████░░░▄█████████████▄░░░░░¡░░░░█████████δ░░▓╬╣╣▓▓▓▓▓▓╣╣▓▓▓
╬╬╬╬╣╬╣╬╬╬╬╬╬▓████▒░░∩░▀█▒░▀██╙█▓███████▓█▌░░¡░░░░░░░╚█████▓█▒░░╫▓████▓█▓▓▓▓▓▓▓▓
╬╣╬╢╬╬╣╬╣╬╬╬╣▓███▌░░░░░░░░░░░┤~╙█▓█████▀██▒░¡░░░░░░φ░░███▓██▒░░░▓▓▓╬╚╙╫╬╫███████
╬╬╣╬╬╬╣▓▓██▓╬▓███▓░░░░░░░░░░░░(=├▀██▓█████░░░¡░>░""░Γ░░░░░░Γ░░░╫▓▓▓▓▓▓▓█▓█▓▓▓▓▓▓
╬╫╬╬╬╬╣▓╬╟╬▓╬█████▓▄▒░░░░░░░░░∩░░│▀▀▀╫╨╨╨╨░░░¡░¡░░¡¡░░░░░░░░░░╢▓██▓▓█████████▓██
▓▓▓▓▓▓▓▓╬╬╫█████████████▓▌▒░░░░░░░░░░!░░░░¡░░░░Q▄▄▄▄▄░░░░Γ░Γ▄▓▓█████████████████
▓█████╬╣▓▓▓████████████████▓▌▒░░░░░░░░░░░░░░░░████▀▀░░░░░░▄▓▓▓██████████████████
▓▓▓╬▓▓╬╣╬╬╬╬╬╬╬╬███████████████▌▄▒░░░░░░░░░░░░░░░░░░░░½▄▓▓███▓██████████████████
▓╬╠▓▓▓▓╣╣╬╣╣╬╣▓╬████▓██████████████▓▓▌▄▄░░░░░░░░φ╦▄▄▓▓███████▓█████████████▓╠▓██
▓▌╠▓▓▓╬╬╣╬╬╬╬╬╬╬▓█▓████▓█▓╬╢▓██▓▓▓▓▓▓▓▓▓▒Σ▒▒#░#▓▓▓▓▓▓██████████████▓▓████▓▓▓╬╬╬╬
▓▓╠▓███▓▓╣╣╬╣╬╣╢▓▓▓▓▓▓██▓▓▓╣▓▓█▓▓█▓██▓╬#Γ#▒▒▒░Σ╣█████████████▓╣╬▓███▓████▓╣╣╬╣╣▓
▓▓╬▓▓▓▓▓▓▓▓▓▓█▓╬▓▓▓▓▓▓▓▓█████████████▄ΓΓ╚Γ░ΓΓΓ▐▄█████████████▓╬╬╬╫█████▓╬╬╣╬╬╬╬╬
▓▓▓▓▓▓▓▓▓▓▓█████████████████▓▓██████████▓▓▓▓▓████████████▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
▓███████████████████████████████████████████████████████╬╣╬╬╬╬╬╬╬╬╬╬╬╫╬╬╬╬╬╣╬╬╬╬
▓████████████████████████████████████████████████████████╬╬╬╬╫╬╬╬╬╬╣╬╬╬╬╬╬╬╬╣╬╬╬
██████████████████████████████████▓██▓█▓▓▓███▓██▓█████████╬╬╣╬╬╣╬╬╬╬╬╣╬╬╬╬╬╬╬╬╣╣
▓█████████████████▓▓▓▓╬╬╬██████████████████▓██▓██╣████████▓╬╬╫╬╢╬╫╬╬╬╬╬╣╬╣╬╬╬╣╬╣
██████▓█▓▓╬╬╬╬╬╬╬╬╬╬╣╬╬╬▓██████████▌▓╬▒╫▓▓▌╣██▓▓╬▒█████████▌╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬
╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬╬╬╬╬╬╣████████████╣╟▓╬╣▓▓▓▓▓▓▓▓▓╫█████████╬╬╬╬╬╣╬╬╬╬╬╬╬╬╬╣╬╬╬░
                          ;                                          
                          ED.                                  :     
                          E#Wi                                t#,    
 j.                       E###G.      .          j.          ;##W.   
 EW,                   .. E#fD#W;     Ef.        EW,        :#L:WE   
 E##j                 ;W, E#t t##L    E#Wi       E##j      .KG  ,#D  
 E###D.              j##, E#t  .E#K,  E#K#D:     E###D.    EE    ;#f 
 E#jG#W;            G###, E#t    j##f E#t,E#f.   E#jG#W;  f#.     t#i
 E#t t##f         :E####, E#t    :E#K:E#WEE##Wt  E#t t##f :#G     GK 
 E#t  :K#E:      ;W#DG##, E#t   t##L  E##Ei;;;;. E#t  :K#E:;#L   LW. 
 E#KDDDD###i    j###DW##, E#t .D#W;   E#DWWt     E#KDDDD###it#f f#:  
 E#f,t#Wi,,,   G##i,,G##, E#tiW#G.    E#t f#K;   E#f,t#Wi,,, f#D#;   
 E#t  ;#W:   :K#K:   L##, E#K##i      E#Dfff##E, E#t  ;#W:    G#t    
 DWi   ,KK: ;##D.    L##, E##D.       jLLLLLLLLL;DWi   ,KK:    t     
            ,,,      .,,  E#t                                        
                          L:                                         

*/

import { FixedPointMathLib } from "solmate/src/utils/FixedPointMathLib.sol";

abstract contract Radmath {
    using FixedPointMathLib for uint256;

    /**
        @dev get the purchase price for a given Delta (% in wei)
     */
    function getBuyInfo(
        uint128 spotPrice,
        uint128 delta,
        uint256 numItems
    ) public pure returns (uint128 newSpotPrice, uint256 inputValue) {
        // NOTE: we assume delta is > 1, as checked by validateDelta()
        require(delta > 1, "DELTA_TOO_SMALL");
        // We only calculate changes for buying 1 or more NFTs
        require(numItems > 0, "INVALID_NUM_ITEMS");

        uint256 deltaPowN = uint256(delta).rpow(numItems, FixedPointMathLib.WAD);

        // For an exponential curve, the spot price is multiplied by delta for each item bought
        uint256 newSpotPrice_ = uint256(spotPrice).mulWadUp(deltaPowN);
        require(newSpotPrice_ <= type(uint128).max, "SPOT_PRICE_OVERFLOW");
        newSpotPrice = uint128(newSpotPrice_);

        // Spot price is assumed to be the instant sell price. To avoid arbitraging LPs, we adjust the buy price upwards.
        // If spot price for buy and sell were the same, then someone could buy 1 NFT and then sell for immediate profit.
        // EX: Let S be spot price. Then buying 1 NFT costs S ETH, now new spot price is (S * delta).
        // The same person could then sell for (S * delta) ETH, netting them delta ETH profit.
        // If spot price for buy and sell differ by delta, then buying costs (S * delta) ETH.
        // The new spot price would become (S * delta), so selling would also yield (S * delta) ETH.
        uint256 buySpotPrice = uint256(spotPrice).mulDivUp(delta, FixedPointMathLib.WAD);

        // If the user buys n items, then the total cost is equal to:
        // buySpotPrice + (delta * buySpotPrice) + (delta^2 * buySpotPrice) + ... (delta^(numItems - 1) * buySpotPrice)
        // This is equal to buySpotPrice * (delta^n - 1) / (delta - 1)
        inputValue = buySpotPrice.mulWadUp((deltaPowN - FixedPointMathLib.WAD).divWadUp(delta - FixedPointMathLib.WAD));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import "hardhat/console.sol";
/*
╢╬╬╬╬╠╠╟╠╬╢╠╬╬╠╠╠╢╬╬╠╠╠╠╬╬╬╣▌▌▓▌▌▌▌▌▌╬╬▓▓▓▓▓▓▌▓▓▓▓▒░»=┐;»:»░»¡;":¡░¡!:░┐░░░░░!░░
╠╠╠╠╠╠╠╬╣╬╬╬╬╬╬╠╠╠╠╠╠╬╬▓████████████████████████████▌▄φφφφφφφφ╦▒φφ╦φ╦▒φ╦╦╦╦φφφφφ
▒╠▓╬▒▒▒▒▒▒▒▒╠╠╠╠╠╣╣╬▓██████████████████████████████████▓▓▌╬╟╬╢╠╟╠╠╠╠╠╟╟╠╠╠╠╠╠╠╠╠
▒╚▓╣▓▓▓▓╣╬▄▓▓▒▒╠▓▒▒▓███████████████████████████▓▓▓█▓█▓█▓▓█▓▓╬╠╠╟╠╠╠╠╢╠╠╠╠╠╬╢╠╠╠╠
▒Å▓▓▓▓▓▓█▓▓▓╬╫▌╠▓▓████████████████████▓▓████████▓█▓▓█▓▓▓▓█▓█▓▓╬╠╠╠╠╠╠╠╠╠╠╬╠╬╠╠╠╟
▒╚╚░▒╚╚╩╠╬╣▓╬╣▓╣▓███████████████▓█▓██████████████████▓█▓██▓█▓██▓╬╢╟╠╠╠╢╠╟╠╠╠╠╠╟╟
╟▒▒░░Γ▒╣▒▒░#▒▒╚▓████████████████▓██████▓████████████████████████▓╬╠╠╠╟╠╬╠╟╠╬╠╠╠╠
▒╠╠╩▒▒╟▓▓▓▓╣▓▓▓███████████████▓████████████▀╫███████████████████▓▓╬╠╠╠╠╠╠╠╠╠╬╠╠╠
▒▒▒Γ░Γ▒╬╬▀╬╣▓▓███████████████████████████▓╨░░╫████████████████████▓╬╠╠╠╠╠╠╠╠╠╠╠╠
▓▓▓▓▌╬╬╠╬▒▒▒▒████████████████████████████░¡░░!╫██████████▓╟██▓██████▌╠╠╠╠╠╠╠╠╠╠╠
███████████▓██████▓████████▀╫███████████▒∩¡░░░░╙▀▓╟████▌┤░░╫███▀▀███▌╠╠╠╠╠╠╠╠╠╠╠
███████████████████████████░╙███▌│╩╨╙██▌░░░░░░░░░░░██▓╝░░░Q▓███████▓╠╠╠╟╠╠╠╠╠╠╠╠
▓▓▓███████████████████████▌ü███▓▄▄Q░░██▒\░░░░¡░░░░░╫▓▌▓███████▀▀▀╫╬╠╠╬╠╠╟╟╠╠╠╠╠╟
╬▓╬╣╬╣╣╣╣╬▓╬████████████╩▀▒░▀▀▀▀▀▀▀███████▓▌▄µ░░░░░▀▀▀╫███████Γ░░╠╟╠╠╠╠╠╠╠╠╠╠╠╠╠
█▓▓▓▓▓▓▓▓▓▓▓▓███████████░░░░░░∩░░░Q▄▄▄▄░░░┘┤╨├░¡░░░░░▄███▄█████▒░╟╠╠╠╠╠╠╠╠╠╠╠╠╠╠
▓▓▓▓▓▓▓▓▓▓▓▓▓███████████▒░░░░░▓███▀█████▄░░░░░░░¡░░ΓΓ██████████┤Γ╬╠╠╠╠╠╬╠╠╠╠╠╠╠╠
╬╬╬╣╬╣╬╬╣╬╬╬╣▓███████████░░░▄█████████████▄░░░░░¡░░░░█████████δ░░▓╬╣╣▓▓▓▓▓▓╣╣▓▓▓
╬╬╬╬╣╬╣╬╬╬╬╬╬▓████▒░░∩░▀█▒░▀██╙█▓███████▓█▌░░¡░░░░░░░╚█████▓█▒░░╫▓████▓█▓▓▓▓▓▓▓▓
╬╣╬╢╬╬╣╬╣╬╬╬╣▓███▌░░░░░░░░░░░┤~╙█▓█████▀██▒░¡░░░░░░φ░░███▓██▒░░░▓▓▓╬╚╙╫╬╫███████
╬╬╣╬╬╬╣▓▓██▓╬▓███▓░░░░░░░░░░░░(=├▀██▓█████░░░¡░>░""░Γ░░░░░░Γ░░░╫▓▓▓▓▓▓▓█▓█▓▓▓▓▓▓
╬╫╬╬╬╬╣▓╬╟╬▓╬█████▓▄▒░░░░░░░░░∩░░│▀▀▀╫╨╨╨╨░░░¡░¡░░¡¡░░░░░░░░░░╢▓██▓▓█████████▓██
▓▓▓▓▓▓▓▓╬╬╫█████████████▓▌▒░░░░░░░░░░!░░░░¡░░░░Q▄▄▄▄▄░░░░Γ░Γ▄▓▓█████████████████
▓█████╬╣▓▓▓████████████████▓▌▒░░░░░░░░░░░░░░░░████▀▀░░░░░░▄▓▓▓██████████████████
▓▓▓╬▓▓╬╣╬╬╬╬╬╬╬╬███████████████▌▄▒░░░░░░░░░░░░░░░░░░░░½▄▓▓███▓██████████████████
▓╬╠▓▓▓▓╣╣╬╣╣╬╣▓╬████▓██████████████▓▓▌▄▄░░░░░░░░φ╦▄▄▓▓███████▓█████████████▓╠▓██
▓▌╠▓▓▓╬╬╣╬╬╬╬╬╬╬▓█▓████▓█▓╬╢▓██▓▓▓▓▓▓▓▓▓▒Σ▒▒#░#▓▓▓▓▓▓██████████████▓▓████▓▓▓╬╬╬╬
▓▓╠▓███▓▓╣╣╬╣╬╣╢▓▓▓▓▓▓██▓▓▓╣▓▓█▓▓█▓██▓╬#Γ#▒▒▒░Σ╣█████████████▓╣╬▓███▓████▓╣╣╬╣╣▓
▓▓╬▓▓▓▓▓▓▓▓▓▓█▓╬▓▓▓▓▓▓▓▓█████████████▄ΓΓ╚Γ░ΓΓΓ▐▄█████████████▓╬╬╬╫█████▓╬╬╣╬╬╬╬╬
▓▓▓▓▓▓▓▓▓▓▓█████████████████▓▓██████████▓▓▓▓▓████████████▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
▓███████████████████████████████████████████████████████╬╣╬╬╬╬╬╬╬╬╬╬╬╫╬╬╬╬╬╣╬╬╬╬
▓████████████████████████████████████████████████████████╬╬╬╬╫╬╬╬╬╬╣╬╬╬╬╬╬╬╬╣╬╬╬
██████████████████████████████████▓██▓█▓▓▓███▓██▓█████████╬╬╣╬╬╣╬╬╬╬╬╣╬╬╬╬╬╬╬╬╣╣
▓█████████████████▓▓▓▓╬╬╬██████████████████▓██▓██╣████████▓╬╬╫╬╢╬╫╬╬╬╬╬╣╬╣╬╬╬╣╬╣
██████▓█▓▓╬╬╬╬╬╬╬╬╬╬╣╬╬╬▓██████████▌▓╬▒╫▓▓▌╣██▓▓╬▒█████████▌╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬
╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬╬╬╬╬╬╣████████████╣╟▓╬╣▓▓▓▓▓▓▓▓▓╫█████████╬╬╬╬╬╣╬╬╬╬╬╬╬╬╬╣╬╬╬░
                          ;                                          
                          ED.                                  :     
                          E#Wi                                t#,    
 j.                       E###G.      .          j.          ;##W.   
 EW,                   .. E#fD#W;     Ef.        EW,        :#L:WE   
 E##j                 ;W, E#t t##L    E#Wi       E##j      .KG  ,#D  
 E###D.              j##, E#t  .E#K,  E#K#D:     E###D.    EE    ;#f 
 E#jG#W;            G###, E#t    j##f E#t,E#f.   E#jG#W;  f#.     t#i
 E#t t##f         :E####, E#t    :E#K:E#WEE##Wt  E#t t##f :#G     GK 
 E#t  :K#E:      ;W#DG##, E#t   t##L  E##Ei;;;;. E#t  :K#E:;#L   LW. 
 E#KDDDD###i    j###DW##, E#t .D#W;   E#DWWt     E#KDDDD###it#f f#:  
 E#f,t#Wi,,,   G##i,,G##, E#tiW#G.    E#t f#K;   E#f,t#Wi,,, f#D#;   
 E#t  ;#W:   :K#K:   L##, E#K##i      E#Dfff##E, E#t  ;#W:    G#t    
 DWi   ,KK: ;##D.    L##, E##D.       jLLLLLLLLL;DWi   ,KK:    t     
            ,,,      .,,  E#t                                        
                          L:                                         

*/

import { OwnerPausable } from "@divergencetech/ethier/contracts/utils/OwnerPausable.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { Radbro } from "./Radbro.sol";
import { Radcoin } from "./Radcoin.sol";
import { Radmath } from "./Radmath.sol";

/// @notice RadPool for Radbros.
/// @author 10xdegen
contract RadPoolV1 is Radmath, ReentrancyGuard, OwnerPausable {
    /*//////////////////////////////////////////////////////////////
                            IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    // @notice Radbro address.
    Radbro public immutable radbro;

    // @notice Radbro address.
    Radcoin public immutable radcoin;

    /*//////////////////////////////////////////////////////////////
                            STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice The current spot price for buying radbros (in $ETH).
    uint128 public spotPrice = 3 ether;

    /// @notice 1.2% price increase per purchase. 100 sales ~ 3x price.
    uint128 public priceDelta = 1.012 ether;

    /// @notice Total number of radbros sold from the pool.
    uint128 public totalSold;

    /// @notice The max number of radbros to sell from the pool.
    uint128 public maxSupply;

    /// @notice The max number of radbros to sell per wallet.
    uint128 public maxPerWallet = 1;

    /// @notice The number of radbros sold per wallet.
    mapping(address => uint128) public soldPerWallet;

    uint256[] public availableIds = [
        uint256(683),
        684,
        685,
        686,
        687,
        688,
        689,
        690,
        691,
        692,
        693,
        694,
        695,
        696,
        697,
        698,
        699,
        700,
        701,
        702,
        703,
        704,
        705,
        706,
        707,
        708,
        709,
        711,
        712,
        713,
        714,
        715,
        716,
        717,
        718,
        719,
        720,
        721,
        722,
        723,
        724,
        725,
        726,
        727,
        728,
        729,
        730,
        732,
        733,
        734,
        735,
        736,
        737,
        738,
        739,
        740,
        741,
        742,
        743,
        744,
        745,
        746,
        747,
        748,
        749,
        750,
        751,
        752,
        753,
        755,
        756,
        757,
        758,
        759,
        760,
        761,
        762,
        763,
        765,
        766,
        767,
        768,
        769,
        770,
        771,
        772,
        773,
        774,
        775,
        776,
        777,
        778,
        779,
        780,
        786,
        787,
        788,
        790,
        791,
        792
    ];

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event BuyWithETH(address indexed caller, address indexed owner, uint256 n, uint256 cost);

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _radbro, address _radcoin) {
        radbro = Radbro(_radbro);
        radcoin = Radcoin(_radcoin);
        maxSupply = uint128(availableIds.length);
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN
    //////////////////////////////////////////////////////////////*/

    /// @notice sets spot price
    function setSpotPrice(uint128 _spotPrice) external onlyOwner {
        spotPrice = _spotPrice;
    }

    /// @notice sets the price delta
    function setPriceDelta(uint128 _priceDelta) external onlyOwner {
        priceDelta = _priceDelta;
    }

    /// @notice sets the available ids
    function setAvailableIds(uint256[] calldata _availableIds) external onlyOwner {
        availableIds = _availableIds;
        maxSupply = uint128(_availableIds.length) + totalSold;
    }

    /// @notice push ids to the available ids
    function pushAvailableIds(uint256[] calldata _availableIds) external onlyOwner {
        for (uint256 i = 0; i < _availableIds.length; i++) {
            availableIds.push(_availableIds[i]);
        }
        maxSupply += uint128(_availableIds.length);
    }

    /// @notice sets the max per wallet
    function setMaxPerWallet(uint128 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Buy n random Radbros using $RAD

    function buyWithRAD(address to, address owner, uint256 n, uint256 maxInput) external nonReentrant {
        require(n > 0, "RadPool: Must buy at least one");
        require(n <= maxSupply, "RadPool: Not enough available radbros");
        require(soldPerWallet[msg.sender] <= maxPerWallet, "RadPool: Exceeds max per wallet");

        (uint128 newSpotPrice, uint256 inputValue) = getBuyInfo(spotPrice, priceDelta, n);

        require(inputValue <= maxInput, "Radbro: Input value exceeds maxInput");

        // Transfer $RAD from caller to RadPool
        SafeTransferLib.safeTransferFrom(radcoin, msg.sender, owner, inputValue);

        spotPrice = newSpotPrice;
        totalSold += uint128(n);
        soldPerWallet[msg.sender] += uint128(n);

        // uint256 seed = getRandSeed();
        uint256 seed = 1234; // doesn't matter for now

        // Transfer radbros to buyer.
        for (uint256 i = 0; i < n; i++) {
            uint256 radbroId = popRadbroId(seed);

            radbro.safeTransferFrom(owner, to, radbroId);
        }

        emit BuyWithETH(to, owner, n, inputValue);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL
    //////////////////////////////////////////////////////////////*/

    function randUint(uint256 max, uint256 seed) internal view returns (uint256) {
        uint256 randomHash = getPsuedoRand(seed);
        return (randomHash % max);
    }

    function getPsuedoRand(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, seed)));
    }

    function popRadbroId(uint256 seed) internal returns (uint256) {
        uint256 index = randUint(availableIds.length, seed);
        uint256 radbroId = availableIds[index];
        availableIds[index] = availableIds[availableIds.length - 1];
        availableIds.pop();

        return radbroId;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

library Bitmaps {
    struct Bitmap {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function.
        // bitmaps length should be maxSupply / 256.
        uint256[] _bitmaps;
    }

    function makeBitmap(uint256 _size) internal pure returns (Bitmap memory) {
        Bitmap memory bitmap;
        bitmap._bitmaps = new uint256[](_size / 256 + 1);
        return bitmap;
    }

    using Bits for uint256;

    function set(Bitmap storage _bitmap, uint256 _index, bool _value) internal {
        uint256 _bitmapIndex = _index / 256;
        uint256 _bitIndex = _index % 256;
        if (_value) {
            _bitmap._bitmaps[_bitmapIndex] = _bitmap._bitmaps[_bitmapIndex].setBit(_bitIndex);
        } else {
            _bitmap._bitmaps[_bitmapIndex] = _bitmap._bitmaps[_bitmapIndex].clearBit(_bitIndex);
        }
    }

    function get(Bitmap storage _bitmap, uint256 _index) internal view returns (bool) {
        uint256 _bitmapIndex = _index / 256;
        uint256 _bitIndex = _index % 256;
        return _bitmap._bitmaps[_bitmapIndex].bitSet(_bitIndex);
    }
}

library Bits {
    uint256 internal constant ONE = uint256(1);

    // Sets the bit at the given 'index' in 'self' to '1'.
    // Returns the modified value.
    function setBit(uint256 self, uint256 index) internal pure returns (uint256) {
        return self | (ONE << index);
    }

    // Sets the bit at the given 'index' in 'self' to '0'.
    // Returns the modified value.
    function clearBit(uint256 self, uint256 index) internal pure returns (uint256) {
        return self & ~(ONE << index);
    }

    // Sets the bit at the given 'index' in 'self' to:
    //  '1' - if the bit is '0'
    //  '0' - if the bit is '1'
    // Returns the modified value.
    function toggleBit(uint256 self, uint256 index) internal pure returns (uint256) {
        return self ^ (ONE << index);
    }

    // Get the value of the bit at the given 'index' in 'self'.
    function bit(uint256 self, uint256 index) internal pure returns (uint256) {
        return uint256((self >> index) & 1);
    }

    // Check if the bit at the given 'index' in 'self' is set.
    // Returns:
    //  'true' - if the value of the bit is '1'
    //  'false' - if the value of the bit is '0'
    function bitSet(uint256 self, uint256 index) internal pure returns (bool) {
        return (self >> index) & 1 == 1;
    }

    // Checks if the bit at the given 'index' in 'self' is equal to the corresponding
    // bit in 'other'.
    // Returns:
    //  'true' - if both bits are '0' or both bits are '1'
    //  'false' - otherwise
    function bitEqual(uint256 self, uint256 other, uint256 index) internal pure returns (bool) {
        return ((self ^ other) >> index) & 1 == 0;
    }

    // Get the bitwise NOT of the bit at the given 'index' in 'self'.
    function bitNot(uint256 self, uint256 index) internal pure returns (uint256) {
        return uint256(1 - ((self >> index) & 1));
    }

    // Computes the bitwise AND of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitAnd(uint256 self, uint256 other, uint256 index) internal pure returns (uint256) {
        return uint256(((self & other) >> index) & 1);
    }

    // Computes the bitwise OR of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitOr(uint256 self, uint256 other, uint256 index) internal pure returns (uint256) {
        return uint256(((self | other) >> index) & 1);
    }

    // Computes the bitwise XOR of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitXor(uint256 self, uint256 other, uint256 index) internal pure returns (uint256) {
        return uint256(((self ^ other) >> index) & 1);
    }

    // Computes the index of the highest bit set in 'self'.
    // Returns the highest bit set as an 'uint256'.
    // Requires that 'self != 0'.
    function highestBitSet(uint256 self) internal pure returns (uint256 highest) {
        require(self != 0);
        uint256 val = self;
        for (uint256 i = 128; i >= 1; i >>= 1) {
            if (val & (((ONE << i) - 1) << i) != 0) {
                highest += i;
                val >>= i;
            }
        }
    }

    // Computes the index of the lowest bit set in 'self'.
    // Returns the lowest bit set as an 'uint256'.
    // Requires that 'self != 0'.
    function lowestBitSet(uint256 self) internal pure returns (uint256 lowest) {
        require(self != 0);
        uint256 val = self;
        for (uint256 i = 128; i >= 1; i >>= 1) {
            if (val & ((ONE << i) - 1) == 0) {
                lowest += i;
                val >>= i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Reference type for token approval.
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Gas optimized merkle proof verification library.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/MerkleProofLib.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        assembly {
            if proof.length {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(proof.offset, shl(5, proof.length))

                // Initialize offset to the offset of the proof in calldata.
                let offset := proof.offset

                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot where the leaf should be put in scratch space. If
                    // leaf > calldataload(offset): slot 32, otherwise: slot 0.
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    // Store elements to hash contiguously in scratch space.
                    // The xor puts calldataload(offset) in whichever slot leaf
                    // is not occupying, so 0 if leafSlot is 32, and 32 otherwise.
                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    // Reuse leaf to store the hash to reduce stack operations.
                    leaf := keccak256(0, 64) // Hash both slots of scratch space.

                    offset := add(offset, 32) // Shift 1 word per cycle.

                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) // The proof is valid if the roots match.
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}