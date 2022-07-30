// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import {OptimizedERC721 as ERC721} from "./base/optimized/OptimizedERC721.sol";

import {ASingleAllowlistMerkle} from "../whitelist/ASingleAllowlistMerkle.sol";
import {AMultiFounderslistMerkle} from "../whitelist/AMultiFounderslistMerkle.sol";

import "../auction/ABaseDutchLinearAuction.sol";

import "./reveal/ABaseNFTCommitment.sol";
import "./metadata/MetadataLink.sol";

//  ____  __.
// |    |/ _|____   ____ ______   ___________  ______
// |      <_/ __ \_/ __ \\____ \_/ __ \_  __ \/  ___/
// |    |  \  ___/\  ___/|  |_> >  ___/|  | \/\___ \
// |____|__ \___  >\___  >   __/ \___  >__|  /____  >
//         \/   \/     \/|__|        \/           \/

error ExceedingReservedSupply();
error ExceedingAllowlistSupply();
error ExceedingFoundersSupply();
error ExceedingMaxAuctionSupply();

error FoundersAndAllowlistNotStarted();
error FoundersAndAllowlistEnded();
error FoundersAndAllowlistNotEnded();

error CannotSetMintDurationToZero();

error InsufficientETH();
error MaxMintPerTxnExceeded();
error MaxMintPerAddressExceeded();
error OwnerPullExceedAllowed();
error UserAlreadyRefunded();
error PassedMaxRefundTime();

error ExceedingFoundersListEntitlements();
error AllowlistAlreadyMinted();

/// @title Keepers NFT Contract
/// @author Karmabadger
/// @notice This is the main NFT contract for Keepers.
/// @dev This contract is used to mint NFTs for Keepers.
contract KeepersOptimized is
    ERC721,
    ASingleAllowlistMerkle,
    AMultiFounderslistMerkle,
    ABaseDutchLinearAuction,
    ABaseNFTCommitment,
    Pausable
{
    uint256 public immutable maxReservedSupply = 200; // Number of NFTs that have been reserved.
    uint256 public immutable maxAllowlistSupply = 1000; // Number of NFTs on the allowlist.
    uint256 public immutable maxFoundersListSupply = 300; // Number of NFTs on the Founders List.
    uint256 public immutable maxAuctionSupply = 8500; // Number of NFTs on the auction.

    uint16 public mintedReservedSupply = 0;
    uint16 public mintedAllowlistSupply = 0;
    uint16 public mintedFounderslistSupply = 0;
    uint16 public mintedAuctionSupply = 0;

    uint64 public foundersAndAllowlistDuration;
    uint64 public foundersAndAllowlistStartTime;
    uint64 public foundersAndAllowlistEndTime;
    uint256 public ownerPulledETHAmountFromSales = 0; // the amount of ETH the owner has pulled
    uint256 public ownerPulledETHAmountFromAuction = 0; // the amount of ETH the owner has pulled from the auction

    uint256 public constant MAX_MINT_PER_TXN = 5;
    uint256 public constant MAX_MINT_PER_ADDRESS = 20;
    uint256 public constant MAX_REFUND_TIME = 2 days;

    mapping(address => uint256) public totalPaidForMints;
    uint256 public lowestPrice = type(uint256).max; // the lowest price of the auction

    modifier listMintStarted() {
        if (block.timestamp < auctionEndTime) revert FoundersAndAllowlistNotStarted();
        _;
    }

    modifier listMintNotEnded() {
        if (block.timestamp > auctionEndTime + foundersAndAllowlistDuration)
            revert FoundersAndAllowlistEnded();
        _;
    }

    /// @notice This is the constructor for the Keepers NFT contract.
    /// @dev sets the default admin role of the contract.
    /// @param _owner the default admin to be set to the contract
    constructor(
        address _owner,
        bytes32 _AllowlistMerkleRoot,
        bytes32 _foundersListMerkleRoot,
        uint64 _auctionStartTime,
        uint64 _auctionDuration,
        uint64 _foundersAndAllowlistDuration,
        IMetadata _metadata
    )
        ERC721("Keepers", "KPR", _metadata)
        ASingleAllowlistMerkle(_AllowlistMerkleRoot)
        AMultiFounderslistMerkle(_foundersListMerkleRoot)
        ABaseDutchLinearAuction(_auctionStartTime, _auctionDuration)
    {
        setFoundersAndAllowlistDuration(_foundersAndAllowlistDuration);
        setTime(_auctionStartTime);
        transferOwnership(_owner);
    }

    /* The following functions are overrides required by Solidity. */

    function setMetadata(IMetadata metadata_) external onlyOwner {
        _metadata = metadata_;
    }

    /* Pausable */

    /// @notice Pause the contract.
    /// @dev Only the DEFAULT_ADMIN_ROLE can pause the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract.
    /// @dev Only the DEFAULT_ADMIN_ROLE can unpause the contract.
    function unpause() external onlyOwner {
        _unpause();
    }

    function setFoundersAndAllowlistDuration(uint64 _foundersAndAllowlistDuration)
        public
        onlyOwner
    {
        if (_foundersAndAllowlistDuration == 0) revert CannotSetMintDurationToZero();
        foundersAndAllowlistDuration = _foundersAndAllowlistDuration;
    }

    function setTime(uint64 _auctionStartTime) public virtual onlyOwner {
        _setAuctionTime(_auctionStartTime);
        if (_auctionStartTime == 0) revert CannotSetStartTimeToZero();
        foundersAndAllowlistStartTime = _auctionStartTime + auctionDuration;
        foundersAndAllowlistEndTime =
            _auctionStartTime +
            auctionDuration +
            foundersAndAllowlistDuration;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function _maxSupply() internal pure override returns (uint256) {
        return maxAuctionSupply + maxReservedSupply + maxAllowlistSupply + maxFoundersListSupply;
    }

    function maxSupply() external pure returns (uint256) {
        return _maxSupply();
    }

    function ownerPullETH(uint256 _amount) external onlyOwner {
        if (block.timestamp > auctionEndTime + MAX_REFUND_TIME) {
            (payable(msg.sender)).transfer(_amount);
        } else if (block.timestamp > foundersAndAllowlistEndTime) {
            uint256 totalPrice = lowestPrice * mintedAllowlistSupply;
            uint256 totalPulledAmount = ownerPulledETHAmountFromSales + _amount;
            if (totalPulledAmount > totalPrice) revert OwnerPullExceedAllowed();
            ownerPulledETHAmountFromSales = totalPulledAmount;
            (payable(msg.sender)).transfer(_amount);
        } else revert FoundersAndAllowlistNotEnded();
    }

    function ownerPullAuctionETH(uint256 _amount)
        external
        virtual
        override
        onlyOwner
        whenAuctionEnded
    {
        if (block.timestamp > auctionEndTime + MAX_REFUND_TIME) {
            (payable(msg.sender)).transfer(_amount);
        } else if (block.timestamp > auctionEndTime) {
            uint256 totalPrice = lowestPrice * mintedAuctionSupply;
            uint256 totalPulledAmount = ownerPulledETHAmountFromAuction + _amount;
            if (totalPulledAmount > totalPrice) revert OwnerPullExceedAllowed();
            ownerPulledETHAmountFromAuction = totalPulledAmount;
            (payable(msg.sender)).transfer(_amount);
        } else revert AuctionNotEnded();
    }

    function userPullAllAuctionRefund()
        external
        virtual
        notContract
        whenAuctionEnded
        whenNotPaused
    {
        if (block.timestamp < auctionEndTime) revert AuctionNotEnded();
        if (block.timestamp > auctionEndTime + MAX_REFUND_TIME) revert PassedMaxRefundTime();

        uint256 refundAmount = _userRefundAmount(msg.sender);
        _addressDatas[msg.sender].userRefunded = true;

        if (refundAmount > 0) (payable(msg.sender)).transfer(refundAmount);
    }

    function _userRefundAmount(address _user) internal view returns (uint256) {
        if (_addressDatas[_user].userRefunded) revert UserAlreadyRefunded();
        uint256 totalPrice = lowestPrice * _addressDatas[_user].auctionMintedAmount;
        return totalPaidForMints[_user] - totalPrice;
    }

    function userRefundAmount(address _user) external view returns (uint256) {
        return _userRefundAmount(_user);
    }

    /// @notice Safely mints NFTs in the reserved supply.
    /// @dev Only the Owner can mint reserved NFTs.
    /// @param _to The address of the receiver
    function mintReserved(address _to, uint16 _amount) external onlyOwner {
        uint16 _curMintedReservedSupply = mintedReservedSupply + _amount;
        if (_curMintedReservedSupply > maxReservedSupply) revert ExceedingReservedSupply();
        mintedReservedSupply = _curMintedReservedSupply;
        _batchMint(_to, _amount, true, ""); // using safe batch mint bc owner might be multisig
    }

    /// @notice Safely mints NFTs from founders list.
    /// @dev free
    function mintFounderslist(
        bytes32[] calldata _merkleProof,
        uint16 _entitlementAmount,
        uint16 _amount
    )
        external
        listMintStarted
        listMintNotEnded
        onlyFounderslisted(_merkleProof, _entitlementAmount)
    {
        uint16 mintedEntitlements = _addressDatas[msg.sender].foundersListMintedAmount + _amount;
        if (mintedEntitlements > _entitlementAmount) revert ExceedingFoundersListEntitlements();
        _addressDatas[msg.sender].foundersListMintedAmount = mintedEntitlements;

        uint16 _curMintedFoundersListSupply = mintedFounderslistSupply + _amount;
        if (_curMintedFoundersListSupply > maxFoundersListSupply) revert ExceedingFoundersSupply();
        mintedFounderslistSupply = _curMintedFoundersListSupply;

        if (_amount > 1) {
            _batchMint(msg.sender, _amount, true, ""); // using safe batch mint bc owner might be multisig
        } else {
            _mint(msg.sender, true, "");
        }
    }

    /// @notice Safely mints NFTs from allowlist.
    /// @dev pays the lowest auction price
    function mintAllowlist(bytes32[] calldata _merkleProof)
        external
        payable
        listMintStarted
        listMintNotEnded
        onlyAllowlisted(_merkleProof)
    {
        if (lowestPrice > msg.value) revert InsufficientETH();

        if (_addressDatas[msg.sender].isAllowlistMinted) revert AllowlistAlreadyMinted();
        _addressDatas[msg.sender].isAllowlistMinted = true;

        uint16 _curMintedAllowlistSupply = mintedAllowlistSupply + 1;
        if (_curMintedAllowlistSupply > maxAllowlistSupply) revert ExceedingAllowlistSupply();
        mintedAllowlistSupply = _curMintedAllowlistSupply;

        _mint(msg.sender, true, ""); // using safe batch mint bc owner might be multisig
    }

    /// @notice mint function
    /// @param _amount The amount of NFTs to be minted
    /**
     ** @dev the user has to send at least the current price in ETH to buy the NFTs (extras are refunded).
     ** we removed nonReentrant since all external calls are moved to the end.
     ** transfer() only forwards 2300 gas units which garantees no reentrancy.
     ** the optimized mint() function uses _mint() which does not check ERC721Receiver since we do not allow contracts minting.
     */
    function mintAuction(uint8 _amount)
        external
        payable
        whenAuctionStarted
        whenAuctionNotEnded
        notContract
    {
        uint16 _curmintedAuctionSupply = mintedAuctionSupply + _amount;
        if (_curmintedAuctionSupply > maxAuctionSupply) revert ExceedingMaxAuctionSupply();
        mintedAuctionSupply = _curmintedAuctionSupply;

        uint256 curPrice = _currentPrice();
        uint256 totalPrice = curPrice * _amount;
        if (totalPrice > msg.value) revert InsufficientETH();
        totalPaidForMints[msg.sender] += msg.value;

        if (_amount > MAX_MINT_PER_TXN) revert MaxMintPerTxnExceeded();

        uint32 newTotalMintedForAddress = _addressDatas[msg.sender].auctionMintedAmount + _amount;
        if (newTotalMintedForAddress > MAX_MINT_PER_ADDRESS) revert MaxMintPerAddressExceeded();
        _addressDatas[msg.sender].auctionMintedAmount = newTotalMintedForAddress;

        lowestPrice = curPrice;

        if (_amount > 1) {
            _batchMint(msg.sender, _amount, false, ""); // contracts minting not allowed so not using _safeBatchMint
        } else {
            _mint(msg.sender, false, "");
        }

        emit Buy(msg.sender, curPrice, _amount);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

// forked from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.5.0/contracts/token/ERC721/ERC721.sol
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../../metadata/IMetadata.sol";

import "../../../structs/AddressData.sol";

error ERC721BalanceQueryForTheZeroAddress();
error ERC721OwnerQueryForNonExistentToken();
error ERC721MetadataURIQueryForNonExistentToken();
error ERC721ApprovalToCurrentOwner();
error ERC721ApproveCallerIsNotOwnerNorApprovedForAll();
error ERC721ApprovedQueryForNonExistentToken();
error ERC721TransferCallerIsNotOwnerNorApproved();
error ERC721TransferToNonERC721ReceiverImplementer();
error ERC721OperatorQueryForNonExistentToken();
error ERC721MintToTheZeroAddress();
error ERC721TokenAlreadyMinted();
error ERC721TransferFromIncorrectOwner();
error ERC721TransferToTheZeroAddress();
error ERC721ApproveToCaller();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract OptimizedERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    // using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    IMetadata internal _metadata;

    uint32 internal _totalSupply;

    // Im tempted to change those to uint16 tbh.
    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => AddressData) internal _addressDatas;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        IMetadata metadata_
    ) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = 0;
        _metadata = metadata_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) external view virtual override returns (uint256) {
        if (owner == address(0)) revert ERC721BalanceQueryForTheZeroAddress();
        return _addressDatas[owner].balance;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert ERC721OwnerQueryForNonExistentToken();
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    // /**
    //  * @dev See {IERC721Metadata-tokenURI}.
    //  */
    // function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    //     if (!_exists(tokenId)) revert ERC721MetadataURIQueryForNonExistentToken();

    //     string memory baseURI = _baseURI();
    //     return
    //         bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    // }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert ERC721MetadataURIQueryForNonExistentToken();

        return _metadata.tokenURI(tokenId);
    }

    // /**
    //  * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
    //  * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
    //  * by default, can be overriden in child contracts.
    //  */
    // function _baseURI() internal view virtual returns (string memory) {
    //     return "";
    // }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) external virtual override {
        address owner = OptimizedERC721.ownerOf(tokenId);
        if (to == owner) revert ERC721ApprovalToCurrentOwner();

        if (!(msg.sender == owner || isApprovedForAll(owner, msg.sender)))
            revert ERC721ApproveCallerIsNotOwnerNorApprovedForAll();

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ERC721ApprovedQueryForNonExistentToken();
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        //solhint-disable-next-line max-line-length
        if (!_isApprovedOrOwner(msg.sender, tokenId))
            revert ERC721TransferCallerIsNotOwnerNorApproved();

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
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
        if (!_isApprovedOrOwner(msg.sender, tokenId))
            revert ERC721TransferCallerIsNotOwnerNorApproved();

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
        if (!_checkOnERC721Received(from, to, tokenId, _data))
            revert ERC721TransferToNonERC721ReceiverImplementer();
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
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        if (!_exists(tokenId)) revert ERC721OperatorQueryForNonExistentToken();
        address owner = OptimizedERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
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
    function _mint(
        address to,
        bool check,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) revert ERC721MintToTheZeroAddress();
        // if (_exists(tokenId)) revert ERC721TokenAlreadyMinted();
        uint256 tokenId = _totalSupply;

        _beforeTokenTransfer(address(0), to, tokenId);

        unchecked {
            ++_addressDatas[to].balance;
            ++_totalSupply;
        }

        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        if (check && !_checkOnERC721Received(address(0), to, tokenId, data))
            revert ERC721TransferToNonERC721ReceiverImplementer();

        _afterTokenTransfer(address(0), to, tokenId);
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
    function _batchMint(
        address to,
        uint16 amount,
        bool check,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) revert ERC721MintToTheZeroAddress();

        uint32 endTokenId;
        uint32 tokenId = _totalSupply;
        unchecked {
            _totalSupply = tokenId + amount;
            _addressDatas[to].balance += amount;
            endTokenId = tokenId + amount;
        }
        if (check) {
            for (; tokenId < endTokenId; ) {
                _beforeTokenTransfer(address(0), to, tokenId);
                _owners[tokenId] = to;
                emit Transfer(address(0), to, tokenId);
                if (!_checkOnERC721Received(address(0), to, tokenId, data))
                    revert ERC721TransferToNonERC721ReceiverImplementer();
                _afterTokenTransfer(address(0), to, tokenId);
                unchecked {
                    ++tokenId;
                }
            }
        } else {
            for (; tokenId < endTokenId; ) {
                _beforeTokenTransfer(address(0), to, tokenId);
                _owners[tokenId] = to;
                emit Transfer(address(0), to, tokenId);
                _afterTokenTransfer(address(0), to, tokenId);
                unchecked {
                    ++tokenId;
                }
            }
        }
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
        address owner = OptimizedERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        unchecked {
            --_addressDatas[owner].balance;
        }
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
        if (OptimizedERC721.ownerOf(tokenId) != from) revert ERC721TransferFromIncorrectOwner();
        if (to == address(0)) revert ERC721TransferToTheZeroAddress();

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        unchecked {
            --_addressDatas[from].balance;
            ++_addressDatas[to].balance;
            _owners[tokenId] = to;
        }

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
        emit Approval(OptimizedERC721.ownerOf(tokenId), to, tokenId);
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
        if (owner == operator) revert ERC721ApproveToCaller();
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (
                bytes4 retval
            ) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721TransferToNonERC721ReceiverImplementer();
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
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./WhitelistErrors.sol";

/// @title Merkle Proof based whitelist Base Abstract Contract
/// @author karmabadger
/// @notice Uses an address and an amount
/// @dev inherit this contract to use the whitelist functionality
abstract contract ASingleAllowlistMerkle is Ownable {
    bytes32 public allowlistMerkleRoot; // root of the merkle tree

    /// @notice constructor
    /// @param _merkleRoot the root of the merkle tree
    constructor(bytes32 _merkleRoot) {
        allowlistMerkleRoot = _merkleRoot;
    }

    /// @notice only for whitelisted accounts
    /// @dev need a proof to prove that the account is whitelisted with an amount whitelisted. also needs enough allowed amount left to mint
    modifier onlyAllowlisted(bytes32[] calldata _merkleProof) {
        if (!_isAllowlisted(msg.sender, _merkleProof)) revert InvalidMerkleProof();
        _;
    }

    /* whitelist admin functions */
    /// @notice set the merkle root
    /// @dev If the merkle root is changed, the whitelist is reset
    /// @param _merkleRoot the root of the merkle tree
    function setAllowlistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        allowlistMerkleRoot = _merkleRoot;
    }

    /* whitelist user functions */
    /// @notice Check if an account is whitelisted using a merkle proof
    /// @dev verifies the merkle proof
    /// @param _account the account to check if it is whitelisted
    /// @param _merkleProof the merkle proof of for the whitelist
    /// @return true if the account is whitelisted
    function _isAllowlisted(address _account, bytes32[] calldata _merkleProof)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _merkleProof,
                allowlistMerkleRoot,
                keccak256(abi.encodePacked(_account))
            );
    }

    /// @notice Check if an account is whitelisted using a merkle proof
    /// @dev verifies the merkle proof
    /// @param _account the account to check if it is whitelisted
    /// @param _merkleProof the merkle proof of for the whitelist
    /// @return true if the account is whitelisted
    function isAllowlisted(address _account, bytes32[] calldata _merkleProof)
        external
        view
        returns (bool)
    {
        return _isAllowlisted(_account, _merkleProof);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./WhitelistErrors.sol";

/// @title Merkle Proof based whitelist Base Abstract Contract
/// @author karmabadger
/// @notice Uses an address and an amount
/// @dev inherit this contract to use the whitelist functionality
abstract contract AMultiFounderslistMerkle is Ownable {
    bytes32 public founderslistMerkleRoot; // root of the merkle tree

    // mapping(address => uint32) public whitelistMintMintedAmounts; // Whitelist minted amounts for each account.

    /// @notice constructor
    /// @param _merkleRoot the root of the merkle tree
    constructor(bytes32 _merkleRoot) {
        founderslistMerkleRoot = _merkleRoot;
    }

    /// @notice only for whitelisted accounts
    /// @dev need a proof to prove that the account is whitelisted with an amount whitelisted. also needs enough allowed amount left to mint
    modifier onlyFounderslisted(bytes32[] calldata _merkleProof, uint16 _entitlementAmount) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _entitlementAmount));
        if (!MerkleProof.verify(_merkleProof, founderslistMerkleRoot, leaf))
            revert InvalidMerkleProof();
        _;
    }

    /* whitelist admin functions */
    /// @notice set the merkle root
    /// @dev If the merkle root is changed, the whitelist is reset
    /// @param _merkleRoot the root of the merkle tree
    function setFounderslistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        founderslistMerkleRoot = _merkleRoot;
    }

    /* whitelist user functions */

    /// @notice Check if an account is whitelisted using a merkle proof
    /// @dev verifies the merkle proof
    /// @param _account the account to check if it is whitelisted
    /// @param _entitlementAmount the amount of the account to check if it is whitelisted
    /// @param _merkleProof the merkle proof of for the whitelist
    /// @return true if the account is whitelisted
    function isFounderslisted(
        address _account,
        uint16 _entitlementAmount,
        bytes32[] calldata _merkleProof
    ) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_account, _entitlementAmount));
        return MerkleProof.verify(_merkleProof, founderslistMerkleRoot, leaf);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

error AuctionNotStarted();
error AuctionEnded();
error AuctionNotEnded();
error AuctionFull();
error ContractsNotAllowed();
error AuctionAlreadyStarted();
error CannotCloseNotStartedAuction();
error CannotCloseAuctionYet();

error CannotSetStartTimeAfterEndTime();
error CannotSetEndTimeBeforeStartTime();
error CannotSetStartTimeToZero();
error CannotSetEndTimeToZero();
error CannotSetAuctionDurationToZero();

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract ABaseDutchLinearAuction is Ownable {
    event Buy(address _buyer, uint256 _price, uint256 _amount); // event emitted when a buyer buys tokens

    uint256 public constant startingPrice = 2 ether; // the starting price of the auction
    uint256 public constant endingPrice = 0.25 ether; // the ending price of the auction
    uint256 public constant discountRate = 0.05 ether; // the discount rate of the auction (in price/discountTimeInterval)
    uint256 public constant discountTimeInterval = 900 seconds; // the time unit of the discount rate

    uint64 public auctionStartTime; // The time that the auction started.
    uint64 public auctionEndTime; // The time that the auction ended.
    uint64 public auctionDuration; // The duration of the auction.

    /* modifiers */

    modifier whenAuctionStarted() {
        if (block.timestamp < auctionStartTime) revert AuctionNotStarted();
        _;
    }
    modifier whenAuctionNotEnded() {
        if (block.timestamp > auctionEndTime) revert AuctionEnded();
        _;
    }

    modifier whenAuctionEnded() {
        if (block.timestamp < auctionEndTime) revert AuctionNotEnded();
        _;
    }

    modifier notContract() {
        if (tx.origin != msg.sender) revert ContractsNotAllowed();
        _;
    }

    /// @notice constructor
    constructor(uint64 _startTime, uint64 _auctionDuration) {
        _setAuctionDuration(_auctionDuration);
        _setAuctionTime(_startTime);
    }

    /* View functions */

    /// @notice gets the current price of the auction.
    /// @dev This cannot be called before the auction has started or after it has ended.
    /// @return the current price of the auction per NFT (in wei).
    function currentPrice() external view whenAuctionStarted whenAuctionNotEnded returns (uint256) {
        return _currentPrice();
    }

    /* Auction admin functions */

    function _setAuctionTime(uint64 _startTime) internal virtual {
        if (_startTime == 0) revert CannotSetStartTimeToZero();
        auctionStartTime = _startTime;
        auctionEndTime = _startTime + auctionDuration;
    }

    function _setAuctionDuration(uint64 _duration) internal {
        if (_duration == 0) revert CannotSetAuctionDurationToZero();
        auctionDuration = _duration;
    }

    function setAuctionDuration(uint64 _duration) external onlyOwner {
        _setAuctionDuration(_duration);
    }

    function ownerPullAuctionETH(uint256 _amount) external virtual onlyOwner {
        (payable(msg.sender)).transfer(_amount);
    }

    /* internal functions */

    /// @notice gets the current price of the auction.
    /// @dev This function depends on how much time has elapsed since the auction started.
    /// @return the current price of the auction per NFT (in wei).
    function _currentPrice() internal view virtual returns (uint256) {
        uint256 _endingPrice = endingPrice;
        uint256 discount = (discountRate * (block.timestamp - auctionStartTime)) /
            discountTimeInterval;
        uint256 price = (startingPrice > discount) ? startingPrice - discount : _endingPrice; // this protects against underflow
        return (price < _endingPrice) ? _endingPrice : price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

error AlreadyCommitted();
error NotCommitted();
error AlreadyReveled();
error TooEarlyForReveal();

abstract contract ABaseNFTCommitment is Ownable {
    uint256 public futureBlockToUse;
    string public provenanceHash;

    // How far to shift the tokenID during the reveal
    uint16[] public tokenIdSwaps;
    bool public revealed = false;

    function commit(string memory _provenanceHash) external payable onlyOwner {
        // Can only commit once
        // Note: A reveal has to happen within 256 blocks or this will break
        if (futureBlockToUse != 0) revert AlreadyCommitted();

        provenanceHash = _provenanceHash;
        futureBlockToUse = block.number + 5;
    }

    function reveal() external payable onlyOwner {
        if (futureBlockToUse == 0) revert NotCommitted();

        if (block.number < futureBlockToUse) revert TooEarlyForReveal();

        if (revealed) revert AlreadyReveled();

        // Note: This is technically insufficient randomness, as a miner can
        // just throw away blocks with hashes they don't want.
        // That said, I don't expect this free mint during goblin town
        // to have > 3 ETH incentives.
        // https://soliditydeveloper.com/2019-06-23-randomness-blockchain
        // Note: We add one to this just in case the casted hash is
        // cleanly divisibly by MAX_SUPPLY
        // Trust me, this doesn't break randomness
        uint16 n = uint16(_maxSupply());
        uint256 random = uint256(blockhash(futureBlockToUse));
        for (uint16 i = n - 1; i > 0; i--) {
            random = uint256(keccak256(abi.encodePacked(random)));
            tokenIdSwaps[i] = (uint16(random % _maxSupply()) + 1);
        }

        revealed = true;
    }

    function _maxSupply() internal view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IMetadata.sol";

contract MetadataLink is IMetadata, Ownable {
    using Strings for uint256;

    string public baseURI;

    constructor(string memory _baseURIStr) {
        baseURI = _baseURIStr;
    }

    function setBaseURI(string memory _baseURIStr) external onlyOwner {
        baseURI = _baseURIStr;
    }

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return
            bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
pragma solidity ^0.8.14;

interface IMetadata {
    function setBaseURI(string memory _baseURIStr) external;

    function getBaseURI() external view returns (string memory);

    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

struct AddressData {
    // Realistically, 2**32-1 is more than enough.
    uint32 balance;
    // Keeps track of mint count with minimal overhead for tokenomics.
    uint32 auctionMintedAmount;
    bool userRefunded;
    uint16 foundersListMintedAmount;
    bool isAllowlistMinted;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

error InvalidMerkleProof();
error WhitelistAlreadyMinted();

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