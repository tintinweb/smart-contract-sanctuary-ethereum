// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./ERC721TokenUriDelegate.sol";
import "./ERC721OperatorFilter.sol";
import "./MintPass.sol";

contract QQL is
    Ownable,
    ERC721OperatorFilter,
    ERC721TokenUriDelegate,
    ERC721Enumerable
{
    MintPass immutable pass_;
    uint256 nextTokenId_ = 1;
    mapping(uint256 => bytes32) tokenSeed_;
    mapping(bytes32 => uint256) seedToTokenId_;
    mapping(uint256 => string) scriptPieces_;

    /// By default, an artist has the right to mint all of their seeds. However,
    /// they may irrevocably transfer that right, at which point the current owner
    /// of the right has exclusive opportunity to mint it.
    mapping(bytes32 => address) seedOwners_;
    /// If seed approval is given, then the approved party may claim rights for any
    /// seed.
    mapping(address => mapping(address => bool)) approvalForAllSeeds_;

    mapping(uint256 => address payable) tokenRoyaltyRecipient_;
    address payable projectRoyaltyRecipient_;
    uint256 constant PROJECT_ROYALTY_BPS = 500; // 5%
    uint256 constant TOKEN_ROYALTY_BPS = 200; // 2%
    uint256 immutable unlockTimestamp_;
    uint256 immutable maxPremintPassId_;

    event SeedTransfer(
        address indexed from,
        address indexed to,
        bytes32 indexed seed
    );
    event ApprovalForAllSeeds(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event TokenRoyaltyRecipientChange(
        uint256 indexed tokenId,
        address indexed newRecipient
    );

    event ProjectRoyaltyRecipientChange(address indexed newRecipient);

    constructor(
        MintPass pass,
        uint256 maxPremintPassId,
        uint256 unlockTimestamp
    ) ERC721("", "") {
        pass_ = pass;
        maxPremintPassId_ = maxPremintPassId;
        unlockTimestamp_ = unlockTimestamp;
    }

    function name() public pure override returns (string memory) {
        return "QQL";
    }

    function symbol() public pure override returns (string memory) {
        return "QQL";
    }

    function setScriptPiece(uint256 id, string memory data) external onlyOwner {
        if (bytes(scriptPieces_[id]).length != 0)
            revert("QQL: script pieces are immutable");

        scriptPieces_[id] = data;
    }

    function scriptPiece(uint256 id) external view returns (string memory) {
        return scriptPieces_[id];
    }

    function transferSeed(
        address from,
        address to,
        bytes32 seed
    ) external {
        if (!isApprovedOrOwnerForSeed(msg.sender, seed))
            revert("QQL: unauthorized for seed");
        if (ownerOfSeed(seed) != from) revert("QQL: wrong owner for seed");
        if (to == address(0)) revert("QQL: can't send seed to zero address");
        emit SeedTransfer(from, to, seed);
        seedOwners_[seed] = to;
    }

    function ownerOfSeed(bytes32 seed) public view returns (address) {
        address explicitOwner = seedOwners_[seed];
        if (explicitOwner == address(0)) {
            return address(bytes20(seed));
        }
        return explicitOwner;
    }

    function approveForAllSeeds(address operator, bool approved) external {
        address artist = msg.sender;
        approvalForAllSeeds_[artist][operator] = approved;
        emit ApprovalForAllSeeds(msg.sender, operator, approved);
    }

    function isApprovedForAllSeeds(address owner, address operator)
        external
        view
        returns (bool)
    {
        return approvalForAllSeeds_[owner][operator];
    }

    function isApprovedOrOwnerForSeed(address operator, bytes32 seed)
        public
        view
        returns (bool)
    {
        address seedOwner = ownerOfSeed(seed);
        if (seedOwner == operator) {
            return true;
        }
        return approvalForAllSeeds_[seedOwner][operator];
    }

    function mint(uint256 mintPassId, bytes32 seed) external returns (uint256) {
        return mintTo(mintPassId, seed, msg.sender);
    }

    /// Consumes the specified mint pass to mint a QQL with the specified seed,
    /// which will be owned by the specified recipient. The royalty stream will
    /// be owned by the original parametric artist (the address embedded in the
    /// seed).
    ///
    /// The caller must be authorized by the owner of the mint pass to operate
    /// the mint pass, and the recipient must be authorized by the owner of the
    /// seed to operate the seed.
    ///
    /// Returns the ID of the newly minted QQL token.
    function mintTo(
        uint256 mintPassId,
        bytes32 seed,
        address recipient
    ) public returns (uint256) {
        if (!isApprovedOrOwnerForSeed(recipient, seed))
            revert("QQL: unauthorized for seed");
        if (!pass_.isApprovedOrOwner(msg.sender, mintPassId))
            revert("QQL: unauthorized for pass");
        if (seedToTokenId_[seed] != 0) revert("QQL: seed already used");
        if (
            block.timestamp < unlockTimestamp_ && mintPassId > maxPremintPassId_
        ) revert("QQL: mint pass not yet unlocked");

        uint256 tokenId = nextTokenId_++;
        tokenSeed_[tokenId] = seed;
        seedToTokenId_[seed] = tokenId;
        // Royalty recipient is always the original artist, which may be
        // distinct from the minter (`msg.sender`).
        tokenRoyaltyRecipient_[tokenId] = payable(address(bytes20(seed)));
        pass_.burn(mintPassId);
        _safeMint(recipient, tokenId);
        return tokenId;
    }

    function parametricArtist(uint256 tokenId) external view returns (address) {
        bytes32 seed = tokenSeed_[tokenId];
        if (seed == bytes32(0)) revert("QQL: token does not exist");
        return address(bytes20(seed));
    }

    function setProjectRoyaltyRecipient(address payable recipient)
        public
        onlyOwner
    {
        projectRoyaltyRecipient_ = recipient;
        emit ProjectRoyaltyRecipientChange(recipient);
    }

    function projectRoyaltyRecipient() external view returns (address payable) {
        return projectRoyaltyRecipient_;
    }

    function tokenRoyaltyRecipient(uint256 tokenId)
        external
        view
        returns (address)
    {
        return tokenRoyaltyRecipient_[tokenId];
    }

    function changeTokenRoyaltyRecipient(
        uint256 tokenId,
        address payable newRecipient
    ) external {
        if (tokenRoyaltyRecipient_[tokenId] != msg.sender) {
            revert("QQL: unauthorized");
        }
        if (newRecipient == address(0)) {
            revert("QQL: can't set zero address as token royalty recipient");
        }
        emit TokenRoyaltyRecipientChange(tokenId, newRecipient);
        tokenRoyaltyRecipient_[tokenId] = newRecipient;
    }

    function getRoyalties(uint256 tokenId)
        external
        view
        returns (address payable[] memory recipients, uint256[] memory bps)
    {
        recipients = new address payable[](2);
        bps = new uint256[](2);
        recipients[0] = projectRoyaltyRecipient_;
        recipients[1] = tokenRoyaltyRecipient_[tokenId];
        if (recipients[1] == address(0)) {
            revert("QQL: royalty for nonexistent token");
        }
        bps[0] = PROJECT_ROYALTY_BPS;
        bps[1] = TOKEN_ROYALTY_BPS;
    }

    /// Returns the seed associated with the given QQL token. Returns
    /// `bytes32(0)` if and only if the token does not exist.
    function tokenSeed(uint256 tokenId) external view returns (bytes32) {
        return tokenSeed_[tokenId];
    }

    /// Returns the token ID associated with the given seed. Returns 0 if
    /// and only if no token was ever minted with that seed.
    function seedToTokenId(bytes32 seed) external view returns (uint256) {
        return seedToTokenId_[seed];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721, ERC721Enumerable, ERC721OperatorFilter)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721TokenUriDelegate, ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function unlockTimestamp() public view returns (uint256) {
        return unlockTimestamp_;
    }

    function maxPremintPassId() public view returns (uint256) {
        return maxPremintPassId_;
    }
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./ITokenUriDelegate.sol";

abstract contract ERC721TokenUriDelegate is ERC721, Ownable {
    ITokenUriDelegate private tokenUriDelegate_;

    function setTokenUriDelegate(ITokenUriDelegate delegate) public onlyOwner {
        tokenUriDelegate_ = delegate;
    }

    function tokenUriDelegate() public view returns (ITokenUriDelegate) {
        return tokenUriDelegate_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert("ERC721: invalid token ID");
        ITokenUriDelegate delegate = tokenUriDelegate_;
        if (address(delegate) == address(0)) return "";
        return delegate.tokenURI(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./IOperatorFilter.sol";

abstract contract ERC721OperatorFilter is ERC721, Ownable {
    IOperatorFilter private operatorFilter_;

    function setOperatorFilter(IOperatorFilter filter) public onlyOwner {
        operatorFilter_ = filter;
    }

    function operatorFilter() public view returns (IOperatorFilter) {
        return operatorFilter_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        if (
            from != address(0) &&
            to != address(0) &&
            !_mayTransfer(msg.sender, tokenId)
        ) {
            revert("ERC721OperatorFilter: illegal operator");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _mayTransfer(address operator, uint256 tokenId)
        private
        view
        returns (bool)
    {
        IOperatorFilter filter = operatorFilter_;
        if (address(filter) == address(0)) return true;
        if (operator == ownerOf(tokenId)) return true;
        return filter.mayTransfer(msg.sender);
    }
}

// SPDX-License-Identifier: BUSL-1.1 (see LICENSE)
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ERC721TokenUriDelegate.sol";
import "./ERC721OperatorFilter.sol";
import "./IManifold.sol";

/// @dev
/// Parameters for a piecewise-constant price function with the following
/// shape:
///
/// (1) Prior to `startTimestamp`, the price is `type(uint256).max`.
///
/// (2) At `startTimestamp`, the price jumps to `startGwei` gwei.
///     Every `dropPeriodSeconds` seconds, the price drops as follows:.
///
///     (a) Each of the first `n1` drops is for `c1 * dropGwei` gwei.
///     (b) Each of the next `n2` drops is for `c2 * dropGwei` gwei.
///     (c) Each of the next `n3` drops is for `c3 * dropGwei` gwei.
///     (d) Each subsequent drop is for `c4 * dropGwei` gwei.
///
/// (3) The price never drops below `reserveGwei` gwei.
///
/// For example, suppose that `dropPeriodSeconds` is 60, `startGwei` is 100e9,
/// `dropGwei` is 5e8, `[n1, n2, n3]` is `[10, 15, 20]`, and `[c1, c2, c3, c4]`
/// is [8, 4, 2, 1]`. Then: the price starts at 100 ETH, then drops in 4 ETH
/// increments down to 60 ETH, then drops in 2 ETH increments down to 30 ETH,
/// then drops in 1 ETH increments down to 10 ETH, then drops in 0.5 ETH
/// increments down to the reserve price.
///
/// As a special case, if `startTimestamp == 0`, the auction is considered to
/// not be scheduled yet, and the price is `type(uint256).max` at all times.
struct AuctionSchedule {
    uint40 startTimestamp;
    uint16 dropPeriodSeconds;
    uint48 startGwei;
    uint48 dropGwei;
    uint48 reserveGwei;
    uint8 n1;
    uint8 n2;
    uint8 n3;
    uint8 c1;
    uint8 c2;
    uint8 c3;
    uint8 c4;
}

library ScheduleMath {
    /// @dev The result of this function must be (weakly) monotonically
    /// decreasing. If the reported price were to increase, then users who
    /// bought mint passes at multiple price points might receive a smaller
    /// rebate than they had expected, and the owner might not be able to
    /// withdraw all the proceeds.
    function currentPrice(AuctionSchedule memory s, uint256 timestamp)
        internal
        pure
        returns (uint256)
    {
        if (s.startTimestamp == 0) return type(uint256).max;
        if (timestamp < s.startTimestamp) return type(uint256).max;
        if (s.dropPeriodSeconds == 0) return s.reserveGwei * 1 gwei;

        uint256 secondsElapsed = timestamp - s.startTimestamp;
        uint256 drops = secondsElapsed / s.dropPeriodSeconds;

        uint256 priceGwei = s.startGwei;
        uint256 dropGwei = s.dropGwei;

        uint256 inf = type(uint256).max;
        (drops, priceGwei) = doDrop(s.n1, drops, priceGwei, s.c1 * dropGwei);
        (drops, priceGwei) = doDrop(s.n2, drops, priceGwei, s.c2 * dropGwei);
        (drops, priceGwei) = doDrop(s.n3, drops, priceGwei, s.c3 * dropGwei);
        (drops, priceGwei) = doDrop(inf, drops, priceGwei, s.c4 * dropGwei);

        if (priceGwei < s.reserveGwei) priceGwei = s.reserveGwei;
        return priceGwei * 1 gwei;
    }

    function doDrop(
        uint256 limit,
        uint256 remaining,
        uint256 priceGwei,
        uint256 dropGwei
    ) private pure returns (uint256 _remaining, uint256 _priceGwei) {
        uint256 effectiveDrops = remaining;
        if (effectiveDrops > limit) effectiveDrops = limit;
        (bool ok, uint256 totalDropGwei) = SafeMath.tryMul(
            effectiveDrops,
            dropGwei
        );
        if (!ok || totalDropGwei > priceGwei) totalDropGwei = priceGwei;
        priceGwei -= totalDropGwei;
        return (remaining - effectiveDrops, priceGwei);
    }
}

/// @dev
/// A record of each buyer's interactions with the auction contract.
/// The buyer's outstanding rebate can be calculated from this receipt combined
/// with the current (or final) clearing price. Specifically, the clearing
/// value of the buyer's mint passes is `clearingPrice * numPurchased`.
/// The `netPaid` amount must never be less than the clearing value; if it's
/// greater than the clearing value, then the buyer is entitled to claim the
/// difference.
struct Receipt {
    /// The total amount that the buyer paid for all mint passes that they
    /// purchased, minus the total amount of rebates claimed so far.
    uint192 netPaid;
    /// The total number of mint passes that the buyer purchased. (This does
    /// not count any mint passes created by `reserve`.)
    uint64 numPurchased;
}

/// @dev These fields are grouped because they change at the same time and can
/// be written atomically to save on storage I/O.
struct SupplyStats {
    /// The total number of mint passes that have ever been created. This
    /// counts passes created by both `purchase` and `reserve`, and does not
    /// decrease when passes are burned.
    uint64 created;
    /// The number of mint passes that have been purchased at auction. This
    /// differs from `created_` in that it does not count mint passes created
    /// for free via `reserve`.
    uint64 purchased;
}

contract MintPass is
    Ownable,
    IManifold,
    ERC721OperatorFilter,
    ERC721TokenUriDelegate,
    ERC721Enumerable
{
    using Address for address payable;
    using ScheduleMath for AuctionSchedule;

    /// The maximum number of mint passes that may ever be created.
    uint64 immutable maxCreated_;
    SupplyStats supplyStats_;

    mapping(address => Receipt) receipts_;
    /// Whether `withdrawProceeds` has been called yet.
    bool proceedsWithdrawn_;

    AuctionSchedule schedule_;
    /// The block timestamp at which the auction ended, or 0 if the auction has
    /// not yet ended (i.e., either is still ongoing or has not yet started).
    /// The auction ends when the last mint pass is created, which may be
    /// before or after the price would hit its terminal scheduled value.
    uint256 endTimestamp_;

    /// The address permitted to burn mint passes when minting QQL tokens.
    address burner_;

    address payable projectRoyaltyRecipient_;
    address payable platformRoyaltyRecipient_;
    uint256 constant PROJECT_ROYALTY_BPS = 500; // 5%
    uint256 constant PLATFORM_ROYALTY_BPS = 200; // 2%

    /// For use in an emergency where funds are locked in the contract (e.g.,
    /// the auction gets soft-locked due to a logic error and can never be
    /// completed). After an owner calls `declareEmergency()` and waits the
    /// required duration, they can withdraw any amount of funds from the
    /// contract. Doing so *will* break the contract invariants and make future
    /// behavior of `claimRebate` and `withdrawProceeds` unpredictable, so
    /// should only be used as a last resort.
    uint256 emergencyStartTimestamp_;
    uint256 constant EMERGENCY_DELAY_SECONDS = 3 days;

    /// Emitted whenever mint passes are reserved by the owner with `reserve`.
    /// Creating mint passes with `purchase` does not emit this event.
    event MintPassReservation(
        address indexed recipient,
        uint256 firstTokenId,
        uint256 count
    );

    /// Emitted whenever mint passes are purchased at auction. The `payment`
    /// field represents the amount of Ether deposited with the message call;
    /// this may be more than the current price of the purchased mint passes,
    /// adding to the buyer's rebate, or it may be less, consuming some of the
    /// rebate.
    ///
    /// Creating mint passes with `reserve` does not emit this event.
    event MintPassPurchase(
        address indexed buyer,
        uint256 firstTokenId,
        uint256 count,
        uint256 payment,
        uint256 priceEach
    );

    /// Emitted whenever a buyer claims a rebate. This may happen more than
    /// once per buyer, since rebates can be claimed incrementally as the
    /// auction goes on. The `claimed` amount may be 0 if there is no new
    /// rebate to claim, which may happen if the price has not decreased since
    /// the last claim.
    event RebateClaim(address indexed buyer, uint256 claimed);

    /// Emitted when the contract owner withdraws the auction proceeds.
    event ProceedsWithdrawal(uint256 amount);

    /// Emitted whenever the auction schedule changes, including when the
    /// auction is first scheduled. The `schedule` value is the same as the
    /// result of the `auctionSchedule()` method; see that method for more
    /// details.
    event AuctionScheduleChange(AuctionSchedule schedule);

    event ProjectRoyaltyRecipientChanged(address payable recipient);
    event PlatformRoyaltyRecipientChanged(address payable recipient);

    event EmergencyDeclared();
    event EmergencyWithdrawal(uint256 amount);

    constructor(uint64 _maxCreated) ERC721("", "") {
        maxCreated_ = _maxCreated;
    }

    function name() public pure override returns (string memory) {
        return "QQL Mint Pass";
    }

    function symbol() public pure override returns (string memory) {
        return "QQL-MP";
    }

    /// Returns the total number of mint passes ever created.
    function totalCreated() external view returns (uint256) {
        return supplyStats_.created;
    }

    /// Returns the maximum number of mint passes that can ever be created
    /// (cumulatively, not just active at one time). That is, `totalCreated()`
    /// will never exceed `maxCreated()`.
    ///
    /// When `totalCreated() == maxCreated()`, the auction is over.
    function maxCreated() external view returns (uint256) {
        return maxCreated_;
    }

    /// Returns information about how many mint passes have been reserved by
    /// the owner, how many have been purchased at auction, and the maximum
    /// number of mint passes that will ever be created. These statistics
    /// include passes that have been burned.
    function supplyStats()
        external
        view
        returns (
            uint256 reserved,
            uint256 purchased,
            uint256 max
        )
    {
        SupplyStats memory stats = supplyStats_;
        return (stats.created - stats.purchased, stats.purchased, maxCreated_);
    }

    /// Configures the mint pass auction. Can be called multiple times,
    /// including while the auction is active. Reverts if this would cause the
    /// current price to increase or if the auction is already over.
    function updateAuctionSchedule(AuctionSchedule memory schedule)
        public
        onlyOwner
    {
        if (endTimestamp_ != 0) revert("MintPass: auction ended");
        uint256 oldPrice = currentPrice();
        schedule_ = schedule;
        uint256 newPrice = currentPrice();
        if (newPrice > oldPrice) revert("MintPass: price would increase");
        emit AuctionScheduleChange(schedule);
    }

    /// Sets a new schedule that remains at the current price forevermore.
    /// If the auction is not yet started, this unschedules the auction
    /// (regardless of whether it is scheduled or not). Otherwise, the auction
    /// remains open at the current price until a further schedule update.
    function pauseAuctionSchedule() external {
        // (no `onlyOwner` modifier; check happens in `updateAuctionSchedule`)
        uint256 price = currentPrice();
        AuctionSchedule memory schedule; // zero-initialized
        if (price != type(uint256).max) {
            uint48 priceGwei = uint48(price / 1 gwei);
            assert(priceGwei * 1 gwei == price);
            schedule.startTimestamp = 1;
            schedule.dropPeriodSeconds = 0;
            schedule.reserveGwei = priceGwei;
        }
        updateAuctionSchedule(schedule);
    }

    /// Returns the parameters of the auction schedule. These parameters define
    /// the price curve over time; see `AuctionSchedule` for semantics.
    function auctionSchedule() external view returns (AuctionSchedule memory) {
        return schedule_;
    }

    /// Returns the block timestamp at which the auction ended, or 0 if the
    /// auction has not ended yet (including if it hasn't started).
    function endTimestamp() external view returns (uint256) {
        return endTimestamp_;
    }

    /// Creates `count` mint passes owned by `recipient`. The new token IDs
    /// will be allocated sequentially (even if the recipient's ERC-721 receive
    /// hook causes more mint passes to be created in the middle); the return
    /// value is the first token ID.
    ///
    /// If this creates the final mint pass, it also ends the auction by
    /// setting `endTimestamp_`. If this would create more mint passes than the
    /// max supply supports, it reverts.
    function _createMintPasses(
        address recipient,
        uint256 count,
        bool isPurchase
    ) internal returns (uint256) {
        // Can't return a valid new token ID, and, more importantly, don't want
        // to stomp `endTimestamp_` if the auction is already over.
        if (count == 0) revert("MintPass: count is zero");

        SupplyStats memory stats = supplyStats_;
        uint256 oldCreated = stats.created;

        uint256 newCreated = stats.created + count;
        if (newCreated > maxCreated_) revert("MintPass: minted out");

        // Lossless since `newCreated <= maxCreated_ <= type(uint64).max`.
        stats.created = _losslessU64(newCreated);
        if (isPurchase) {
            // Lossless since `purchased <= created <= type(uint64).max`.
            stats.purchased = _losslessU64(stats.purchased + count);
        }

        supplyStats_ = stats;
        if (newCreated == maxCreated_) endTimestamp_ = block.timestamp;

        uint256 firstTokenId = oldCreated + 1;
        uint256 nextTokenId = firstTokenId;
        for (uint256 i = 0; i < count; i++) {
            _safeMint(recipient, nextTokenId++);
        }
        return firstTokenId;
    }

    /// @dev Helper for `_createMintPasses`.
    function _losslessU64(uint256 x) internal pure returns (uint64 result) {
        result = uint64(x);
        assert(result == x);
        return result;
    }

    /// Purchases `count` mint passes at the current auction price. Reverts if
    /// the auction has not started, if the auction has minted out, or if the
    /// value associated with this message is less than required. Returns the
    /// first token ID.
    function purchase(uint256 count) external payable returns (uint256) {
        uint256 priceEach = currentPrice();
        if (priceEach == type(uint256).max) {
            // Just a nicer error message.
            revert("MintPass: auction not started");
        }

        Receipt memory receipt = receipts_[msg.sender];

        uint256 newNetPaid = receipt.netPaid + msg.value;
        receipt.netPaid = uint192(newNetPaid);
        if (receipt.netPaid != newNetPaid) {
            // Truncation here would require cumulative payments of 2^192 wei,
            // which seems implausible.
            revert("MintPass: too large");
        }

        uint256 newNumPurchased = receipt.numPurchased + count;
        receipt.numPurchased = uint64(newNumPurchased);
        if (receipt.numPurchased != newNumPurchased) {
            // Truncation here would require purchasing 2^64 passes, which
            // would likely cause out-of-gas errors anyway.
            revert("MintPass: too large");
        }

        (bool ok, uint256 priceTotal) = SafeMath.tryMul(
            priceEach,
            receipt.numPurchased
        );
        if (!ok || receipt.netPaid < priceTotal) revert("MintPass: underpaid");

        receipts_[msg.sender] = receipt;

        uint256 firstTokenId = _createMintPasses({
            recipient: msg.sender,
            count: count,
            isPurchase: true
        });
        emit MintPassPurchase(
            msg.sender,
            firstTokenId,
            count,
            msg.value,
            priceEach
        );
        return firstTokenId;
    }

    /// Creates one or more mint passes outside of the auction process, at no
    /// cost. Returns the first token ID.
    function reserve(address recipient, uint256 count)
        external
        onlyOwner
        returns (uint256)
    {
        uint256 firstTokenId = _createMintPasses({
            recipient: recipient,
            count: count,
            isPurchase: false
        });
        emit MintPassReservation(recipient, firstTokenId, count);
        return firstTokenId;
    }

    /// Gets the record of the given buyer's purchases so far. The `netPaid`
    /// value indicates the total amount paid to the contract less any rebates
    /// claimed so far. With this data, clients can compute the amount of
    /// rebate available to the buyer at any given auction price; the rebate is
    /// given by `netPaid - currentPrice * numPurchased`.
    function getReceipt(address buyer)
        external
        view
        returns (uint256 netPaid, uint256 numPurchased)
    {
        Receipt memory receipt = receipts_[buyer];
        return (receipt.netPaid, receipt.numPurchased);
    }

    /// Computes the rebate that `buyer` is currently entitled to, and returns
    /// that amount along with the value that should be stored into
    /// `receipts_[buyer]` if they claim it.
    function _computeRebate(address buyer)
        internal
        view
        returns (uint256 rebate, Receipt memory receipt)
    {
        receipt = receipts_[buyer];
        uint256 clearingCost = currentPrice() * receipt.numPurchased;
        rebate = receipt.netPaid - clearingCost;
        // This truncation should be lossless because `clearingCost` is
        // strictly less than the prior value of `receipt.netPaid`.
        receipt.netPaid = uint192(clearingCost);
    }

    /// Gets the amount that `buyer` would currently receive if they called
    /// `claimRebate()`.
    function rebateAmount(address buyer) public view returns (uint256) {
        (uint256 rebate, ) = _computeRebate(buyer);
        return rebate;
    }

    /// Claims a rebate equal to the difference between the total amount that
    /// the buyer paid for all their mint passes and the amount that their mint
    /// passes would have cost at the clearing price. The rebate is sent to the
    /// buyer's address; see `claimTo` if this is inconvenient.
    function claimRebate() external {
        claimRebateTo(payable(msg.sender));
    }

    /// Claims a rebate equal to the difference between the total amount that
    /// the buyer paid for all their mint passes and the amount that their mint
    /// passes would have cost at the clearing price.
    function claimRebateTo(address payable recipient) public {
        (uint256 rebate, Receipt memory receipt) = _computeRebate(msg.sender);
        receipts_[msg.sender] = receipt;
        emit RebateClaim(msg.sender, rebate);
        recipient.sendValue(rebate);
    }

    /// Withdraws all the auction proceeds. This values each purchased mint
    /// pass at the final clearing price. It can only be called after the
    /// auction has ended, and it can only be called once.
    function withdrawProceeds(address payable recipient) external onlyOwner {
        if (endTimestamp_ == 0) revert("MintPass: auction not ended");
        if (proceedsWithdrawn_) revert("MintPass: already withdrawn");
        proceedsWithdrawn_ = true;
        uint256 proceeds = currentPrice() * supplyStats_.purchased;
        if (proceeds > address(this).balance) {
            // The auction price shouldn't increase, so this shouldn't happen.
            // In case it does, permit rescuing what we can.
            proceeds = address(this).balance;
        }
        emit ProceedsWithdrawal(proceeds);
        recipient.sendValue(proceeds);
    }

    /// Gets the current price of a mint pass (in wei). If the auction has
    /// ended, this returns the final clearing price. If the auction has not
    /// started, this returns `type(uint256).max`.
    function currentPrice() public view returns (uint256) {
        uint256 timestamp = block.timestamp;
        uint256 _endTimestamp = endTimestamp_;
        if (_endTimestamp != 0) timestamp = _endTimestamp;
        return schedule_.currentPrice(timestamp);
    }

    /// Returns the price (in wei) that a mint pass would cost at the given
    /// timestamp, according to the auction schedule and under the (possibly
    /// counterfactual) assumption that the auction does not end before it
    /// reaches the reserve price. That is, unlike `currentPrice()`, the result
    /// of this method does not depend on whether or when the auction has
    /// actually ended.
    function priceAt(uint256 timestamp) external view returns (uint256) {
        return schedule_.currentPrice(timestamp);
    }

    /// Sets the address that's permitted to burn mint passes when minting QQL
    /// tokens.
    function setBurner(address _burner) external onlyOwner {
        burner_ = _burner;
    }

    /// Gets the address that's permitted to burn mint passes when minting QQL
    /// tokens.
    function burner() external view returns (address) {
        return burner_;
    }

    /// Burns a mint pass. Intended to be called when minting a QQL token.
    function burn(uint256 tokenId) external {
        if (msg.sender != burner_) revert("MintPass: unauthorized");
        _burn(tokenId);
    }

    /// Checks whether the given address is approved to operate the given mint
    /// pass. Reverts if the mint pass does not exist.
    ///
    /// This is equivalent to calling and combining the results of `ownerOf`,
    /// `getApproved`, and `isApprovedForAll`, but is cheaper because it
    /// requires fewer message calls.
    function isApprovedOrOwner(address operator, uint256 tokenId)
        external
        view
        returns (bool)
    {
        return _isApprovedOrOwner(operator, tokenId);
    }

    function getRoyalties(
        uint256 /*unusedTokenId */
    )
        external
        view
        returns (address payable[] memory recipients, uint256[] memory bps)
    {
        recipients = new address payable[](2);
        bps = new uint256[](2);
        recipients[0] = projectRoyaltyRecipient_;
        recipients[1] = platformRoyaltyRecipient_;
        bps[0] = PROJECT_ROYALTY_BPS;
        bps[1] = PLATFORM_ROYALTY_BPS;
    }

    function setProjectRoyaltyRecipient(address payable projectRecipient)
        external
        onlyOwner
    {
        projectRoyaltyRecipient_ = projectRecipient;
        emit ProjectRoyaltyRecipientChanged(projectRecipient);
    }

    function projectRoyaltyRecipient() external view returns (address payable) {
        return projectRoyaltyRecipient_;
    }

    function setPlatformRoyaltyRecipient(address payable platformRecipient)
        external
        onlyOwner
    {
        platformRoyaltyRecipient_ = platformRecipient;
        emit PlatformRoyaltyRecipientChanged(platformRecipient);
    }

    function platformRoyaltyRecipient()
        external
        view
        returns (address payable)
    {
        return platformRoyaltyRecipient_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721, ERC721Enumerable, ERC721OperatorFilter)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721TokenUriDelegate, ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function declareEmergency() external onlyOwner {
        if (emergencyStartTimestamp_ != 0) return;
        emergencyStartTimestamp_ = block.timestamp;
        emit EmergencyDeclared();
    }

    function emergencyStartTimestamp() external view returns (uint256) {
        return emergencyStartTimestamp_;
    }

    function emergencyWithdraw(address payable recipient, uint256 amount)
        external
        onlyOwner
    {
        uint256 start = emergencyStartTimestamp_;
        if (start == 0 || block.timestamp < start + EMERGENCY_DELAY_SECONDS)
            revert("MintPass: declare emergency and wait");
        recipient.sendValue(amount);
        emit EmergencyWithdrawal(amount);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
pragma solidity ^0.8.8;

interface ITokenUriDelegate {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IOperatorFilter {
    function mayTransfer(address operator) external view returns (bool);
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

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * @dev Royalty interface for creator core classes
 */
interface IManifold {
    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    function getRoyalties(uint256 tokenId)
        external
        view
        returns (address payable[] memory recipients, uint256[] memory bps);
}