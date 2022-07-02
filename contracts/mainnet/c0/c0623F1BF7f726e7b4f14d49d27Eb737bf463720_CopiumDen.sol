// SPDX-License-Identifier: UNLICENSE
// Creator: 0xYeety; Based Pixel Labs/Yeety Labs; 1 yeet = 1 yeet; 1 cope = 1 cope
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./ERC721Storage.sol";
import "./ENSResolver.sol";
import "./RoyaltyReceiver.sol";

////--------------------------------------------------------------------||||
////--------------------------------------------------------------------||||
////    ________    ____  __    __    ____     ____     _____   _____   ||||
////   ||  ||  ||  ||  ||  \\  //    //   \   //  \\   ||   \\ ||       ||||
////   ||  ||  ||  ||__||   \\//    //       //    \\  ||___// ||___    ||||
////   ||  ||  ||  ||  ||   //\\    \\       \\    //  ||      ||       ||||
////   ||      ||  ||  || _//  \\_   \\___/   \\__//   ||      ||____   ||||
////____________________________________________________________________||||
////____________________________________________________________________||||

contract CopiumDen is Ownable, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    string public PROVENANCE;
    bool provenanceSet;

    string private contractURI_;

    uint256 public mintPrice;
    uint256 public maxPossibleSupply;
    uint256 public maxAllowedMints;

    uint256 royaltyBasisPoints;

    address public immutable currency;
    address public immutable wrappedNativeCoinAddress;

    RoyaltyReceiver royaltyReceiver;
    ENSResolver resolver;
    ERC721Storage storageLayer;

    address private signerAddress;

    bool public _metadataFrozen = false;

    mapping(address => bool) public agreements;
    uint256 numAgreements = 0;

    enum MintStatus {
        NotStarted,
        Public,
        Finished
    }

    MintStatus public mintStatus = MintStatus.NotStarted;

    uint256 numPayees;
    mapping(uint256 => address) private indexer;
    mapping(address => uint256) public earningsSplit;
    mapping(address => uint256) public balances;

    //////////

    mapping(uint256 => mapping(address => uint256)) public listings;

    struct OfferData {
        string openBrk;
        address addr;
        uint256 offer;
        uint256 pos;
        string closeBrk;
    }
    mapping(uint256 => mapping(address => uint256)) public offers;
    mapping(uint256 => mapping(uint256 => address)) public offerAddressPositions;
    mapping(uint256 => uint256) public offerCounts;

    event Sale(address _from, address _to, uint256 _price);


    /**
     * @dev Throws if called by any account other than a royalty receiver/payee.
     */
    modifier onlyPayee() {
        _isPayee();
        _;
    }

    /**
     * @dev Throws if the sender is not on the royalty receiver/payee list.
     */
    function _isPayee() internal view virtual {
        require(earningsSplit[_msgSender()] > 0, "not a royalty payee");
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxPossibleSupply,
        uint256 _mintPrice,
        uint256 _royaltyBasisPoints,
        uint256 _maxAllowedMints,
        address _currency,
        address _wrappedNativeCoinAddress,
        address _royaltyReceiverAddress,
        address[] memory payees,
        uint256[] memory percentages
    ) {
        require(payees.length == percentages.length, "length mismatch");
        numPayees = payees.length;
        for (uint i = 0; i < numPayees; i++) {
            indexer[i] = payees[i];
            earningsSplit[payees[i]] = percentages[i];
        }
        maxPossibleSupply = _maxPossibleSupply;
        mintPrice = _mintPrice;
        royaltyBasisPoints = _royaltyBasisPoints;
        maxAllowedMints = _maxAllowedMints;
        currency = _currency;
        wrappedNativeCoinAddress = _wrappedNativeCoinAddress;

        resolver = new ENSResolver();

        storageLayer = new ERC721Storage(
            _name,
            _symbol,
            _maxAllowedMints,
            _mintPrice,
            _maxPossibleSupply,
            _currency,
            _wrappedNativeCoinAddress
        );

        royaltyReceiver = RoyaltyReceiver(payable(_royaltyReceiverAddress));
    }

    function _ENSResolverAddress() public view returns (address) {
        return address(resolver);
    }

    function _ERC721StorageAddress() public view returns (address) {
        return address(storageLayer);
    }

    function _RoyaltyReceiverAddress() public view returns (address) {
        return address(royaltyReceiver);
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI_ = _contractURI;
    }

    function contractURI() public view returns (string memory) {
        return contractURI_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        require(!provenanceSet);
        PROVENANCE = provenanceHash;
        provenanceSet = true;
    }

    function freezeMetadata() public onlyOwner {
        _metadataFrozen = true;
    }

    function metadataFrozen() public view returns (bool) {
        return _metadataFrozen;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        require(!_metadataFrozen, "mf");
        storageLayer._setBaseURI(baseURI);
    }

    function revealMetadata() public onlyOwner {
        storageLayer._revealMetadata();
    }

    function changeMintStatus(MintStatus _status) external onlyOwner {
        require(_status != MintStatus.NotStarted && mintStatus != MintStatus.NotStarted);
        mintStatus = _status;
    }

    function agreeToMint() external onlyPayee {
        require(!(agreements[msg.sender]), "already agreed");
        agreements[msg.sender] = true;
        numAgreements += 1;
        if (numAgreements == numPayees) {
            mintStatus = MintStatus.Public;
        }
    }

    function giftMint(uint amount, address to) public payable {
        _mint(amount, address(msg.sender), to);
    }

    function giftMintENS(uint amount, string memory ENSAddr) public payable {
        address to = resolver.resolve(ENSAddr);
        _mint(amount, address(msg.sender), to);
    }

    function mintPublic(uint amount) public payable {
        _mint(amount, address(0), address(msg.sender));
    }

    function _mint(uint _amount, address _from, address _to) internal {
        require(mintStatus == MintStatus.Public, "s");

        storageLayer.mintFn(msg.sender, _amount, _from, _to, msg.value);

        uint256 value = msg.value;
        uint256 split = value/100;
        for (uint256 i = 0; i < numPayees; i++) {
            uint256 allocation = split*(earningsSplit[indexer[i]]);
            balances[indexer[i]] += allocation;
            value -= allocation;
        }
        balances[indexer[0]] += value;

        if (totalSupply() == maxPossibleSupply) {
            mintStatus = MintStatus.Finished;
        }
    }

    // Marketplace functionality ====================
    function MKT_list(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == msg.sender, "mbo");
        require(price > 0, "zp");
        listings[tokenId][msg.sender] = price;
    }

    function MKT_deList(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender && listings[tokenId][msg.sender] > 0, "mbo;nl");
        listings[tokenId][msg.sender] = 0;
    }

    function MKT_buy(uint256 tokenId) public payable {
        address tokenOwner = ownerOf(tokenId);
        require(listings[tokenId][tokenOwner] > 0 && tokenOwner != msg.sender, "nl;io");
        require(listings[tokenId][tokenOwner] == msg.value, "wp");
        listings[tokenId][tokenOwner] = 0;
        payForSale(msg.value, tokenOwner);
        storageLayer.transferBySale(tokenOwner, msg.sender, tokenId);
        emit Sale(tokenOwner, msg.sender, msg.value);
    }

    function MKT_isListed(uint256 tokenId) public view returns (bool) {
        return (listings[tokenId][ownerOf(tokenId)] > 0);
    }

    function MKT_getPrice(uint256 tokenId) public view returns (uint256) {
        require(listings[tokenId][ownerOf(tokenId)] > 0, "nl");
        return listings[tokenId][ownerOf(tokenId)];
    }

    //////////

    function MKT_makeOffer(uint256 tokenId, uint256 price) public payable {
        require(ownerOf(tokenId) != msg.sender, "io");

        // Check if there is already an offer
        uint256 currentOffer = offers[tokenId][msg.sender];

        // Check that the supplied funds are sufficient to update the price
        require(currentOffer + msg.value == price, "ifa");

        if (currentOffer == 0) {
            offerAddressPositions[tokenId][offerCounts[tokenId]] = msg.sender;
            offerCounts[tokenId] += 1;
        }

        offers[tokenId][msg.sender] = price;
    }

    function mkt_deleteOfferInternal(uint256 tokenId, address offerer, uint256 position) private {
        offers[tokenId][offerer] = 0;

        uint256 lastIndex = offerCounts[tokenId] - 1;
        offerAddressPositions[tokenId][position] = offerAddressPositions[tokenId][lastIndex];
        offerAddressPositions[tokenId][lastIndex] = address(0);
        offerCounts[tokenId] -= 1;
    }

    function MKT_cancelOffer(uint256 tokenId, uint256 position) public {
        uint256 currentOffer = offers[tokenId][msg.sender];
        require(offerAddressPositions[tokenId][position] == msg.sender && currentOffer != 0, "no/odne");

        mkt_deleteOfferInternal(tokenId, msg.sender, position);
        (bool success, ) = payable(msg.sender).call{value: currentOffer}("");
        require(success, "tf");
    }

    function MKT_acceptOffer(uint256 tokenId, address offerer, uint256 price, uint256 position) public {
        uint256 currentOffer = offers[tokenId][offerer];
        if (msg.sender == offerer && offerer == ownerOf(tokenId)) {
            mkt_deleteOfferInternal(tokenId, msg.sender, position);
            (bool success, ) = payable(msg.sender).call{value: currentOffer}("");
            require(success, "tf");
        }
        else {
            require(ownerOf(tokenId) == msg.sender && currentOffer != 0
            && currentOffer == price && offerer == offerAddressPositions[tokenId][position], "mbo/odne/wp1/wp2");

            mkt_deleteOfferInternal(tokenId, offerer, position);
            payForSale(currentOffer, msg.sender);

            listings[tokenId][msg.sender] = 0;
            storageLayer.transferBySale(msg.sender, offerer, tokenId);
            emit Sale(msg.sender, offerer, currentOffer);
        }
    }

    function MKT_getOffers(uint256 tokenId) public view returns (OfferData[] memory) {
        OfferData[] memory offerList = new OfferData[](offerCounts[tokenId]);

        for (uint i = 0; i < offerCounts[tokenId]; i++) {
            address addr_i = offerAddressPositions[tokenId][i];
            OfferData memory od = OfferData({openBrk: "[", addr: addr_i, offer: offers[tokenId][addr_i], pos: i, closeBrk: "]"});
            offerList[i] = od;
        }

        return offerList;
    }

    function MKT_getHighestOffer(uint256 tokenId) public view returns (OfferData memory) {
        uint256 highestOffer = 0;
        address highestOfferAddress = address(0);
        uint256 highestPos = 0;

        for (uint i = 0; i < offerCounts[tokenId]; i++) {
            address addr_i = offerAddressPositions[tokenId][i];
            if (offers[tokenId][addr_i] > highestOffer) {
                highestOffer = offers[tokenId][addr_i];
                highestOfferAddress = addr_i;
                highestPos = i;
            }
        }

        return OfferData({openBrk: "[", addr: highestOfferAddress, offer: highestOffer, pos: highestPos, closeBrk: "]"});
    }

    ////////////////////////////////////////


    function payForSale(uint256 paymentValue, address paymentReceiver) private {
        uint256 royaltyPayment = ((paymentValue/100)*royaltyBasisPoints)/100;
        (bool success1, ) = payable(address(royaltyReceiver)).call{value: royaltyPayment}("");
        require(success1, "t1f");
        (bool success2, ) = payable(paymentReceiver).call{value: paymentValue - royaltyPayment}("");
        require(success2, "t2f");
    }

    receive() external payable {
        mintPublic(msg.value / mintPrice);
    }

    function withdraw() external onlyPayee() {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value:amount}("");
        require(success, "tf");
    }

    function withdrawTokens(address tokenAddress) external onlyOwner() {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }

    ////////////////////////////////////////

    // ERC721 Required Functionality

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return storageLayer.balanceOf(owner);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        storageLayer.safeTransferFrom(msg.sender, from, to, tokenId, _data);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        storageLayer.safeTransferFrom(msg.sender, from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        storageLayer.transferFrom(msg.sender, from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public override {
        storageLayer.approve(msg.sender, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        storageLayer.setApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        return storageLayer.getApproved(tokenId);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return storageLayer.isApprovedForAll(owner, operator);
    }

    //////////

    // Extra 721A Functionality

    function totalSupply() public view virtual override returns (uint256) {
        return storageLayer.totalSupply();
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return storageLayer.ownerOf(tokenId);
    }

    function name() external view override returns (string memory) {
        return storageLayer.name();
    }

    function symbol() external view override returns (string memory) {
        return storageLayer.symbol();
    }

    function tokenByIndex(uint256 index) external view override returns (uint256) {
        return storageLayer.tokenByIndex(index);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view override returns (uint256) {
        return storageLayer.tokenOfOwnerByIndex(owner, index);
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        return storageLayer.tokenURI(tokenId);
    }

    ////////////////////////////////////////

    function emitTransfer(address _from, address _to, uint256 _tokenId) public {
        emit Transfer(_from, _to, _tokenId);
    }

    function emitApproval(address _owner, address _approved, uint256 _tokenId) public {
        emit Approval(_owner, _approved, _tokenId);
    }

    function emitApprovalForAll(address _owner, address _operator, bool _approved) public {
        emit ApprovalForAll(_owner, _operator, _approved);
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

// SPDX-License-Identifier: UNLICENSE
// Creator: 0xYeety; Based Pixel Labs/Yeety Labs; 1 yeet = 1 yeet; 1 cope = 1 cope
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721Storage is Ownable {
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
    }

    struct AddressData {
        uint128 balance;
        uint128 numberMinted;
    }

    uint256 private currentIndex = 0;

    uint256 internal immutable maxBatchSize;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Base URI
    string private _baseURI;
    bool revealed = false;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) private _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;


    uint256 private mintPrice;
    uint256 private maxPossibleSupply;
    uint256 private maxAllowedMints;
    address private immutable currency;
    address private immutable wrappedNativeCoinAddress;

    /**
     * @dev
     * `maxBatchSize` refers to how much a minter can mint at a time.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxBatchSize_,
        uint256 mintPrice_,
        uint256 maxPossibleSupply_,
        address currency_,
        address wrappedNativeCoinAddress_
    ) {
        require(maxBatchSize_ > 0, "b");
        _name = name_;
        _symbol = symbol_;
        maxBatchSize = maxBatchSize_;
        mintPrice = mintPrice_;
        maxPossibleSupply = maxPossibleSupply_;
        currency = currency_;
        wrappedNativeCoinAddress = wrappedNativeCoinAddress_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return currentIndex;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(index < totalSupply(), "g");
        return index;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < balanceOf(owner), "b");
        uint256 numMintedSoFar = totalSupply();
        uint256 tokenIdsIdx = 0;
        address currOwnershipAddr = address(0);
        for (uint256 i = 0; i < numMintedSoFar; i++) {
            TokenOwnership memory ownership = _ownerships[i];
            if (ownership.addr != address(0)) {
                currOwnershipAddr = ownership.addr;
            }
            if (currOwnershipAddr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("u");
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "0");
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        require(owner != address(0), "0");
        return uint256(_addressData[owner].numberMinted);
    }

    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        require(_exists(tokenId), "t");

        uint256 lowestTokenToCheck;
        if (tokenId >= maxBatchSize) {
            lowestTokenToCheck = tokenId - maxBatchSize + 1;
        }

        for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
            TokenOwnership memory ownership = _ownerships[curr];
            if (ownership.addr != address(0)) {
                return ownership;
            }
        }

        revert("o");
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "z");

        if (revealed) {
            return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, "/", tokenId.toString(), ".json")) : "";
        }
        else {
            return _baseURI;
        }
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) public virtual onlyOwner {
        _baseURI = baseURI_;
    }

    function _revealMetadata() public virtual onlyOwner {
        revealed = true;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address msgSender, address to, uint256 tokenId) public onlyOwner {
        address owner = ownerOf(tokenId);
        require(to != owner, "o");

        require(
            msgSender == owner || isApprovedForAll(owner, msgSender),
            "a"
        );

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "a");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address msgSender, address operator, bool approved) public onlyOwner {
        require(operator != msgSender, "a");

        _operatorApprovals[msgSender][operator] = approved;
        //        emit ApprovalForAll(msgSender, operator, approved);
        ERC721TopLevel(msg.sender).emitApprovalForAll(msgSender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public onlyOwner {
        _transfer(msgSender, from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public onlyOwner {
        safeTransferFrom(msgSender, from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public onlyOwner {
        _transfer(msgSender, from, to, tokenId);
        require(
            _checkOnERC721Received(msgSender, from, to, tokenId, _data),
            "z"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < currentIndex;
    }

    function _safeMint(address msgSender, address from, address to, uint256 quantity) public onlyOwner {
        _safeMint(msgSender, from, to, quantity, "");
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` cannot be larger than the max batch size.
     *
     * Emits either one or two {Transfer} events, depending on the
     * values of {from} and {to}.
     */
    function _safeMint(
        address msgSender,
        address from,
        address to,
        uint256 quantity,
        bytes memory _data
    ) public onlyOwner {
        uint256 startTokenId = currentIndex;
        require(to != address(0), "0");
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(startTokenId), "a");
        require(quantity <= maxBatchSize, "m");

        if (from != address(0)) {
            _beforeTokenTransfers(address(0), from, startTokenId, quantity);
        }
        if (from != to) {
            _beforeTokenTransfers(from, to, startTokenId, quantity);
        }

        AddressData memory addressData = _addressData[to];
        _addressData[to] = AddressData(
            addressData.balance + uint128(quantity),
            addressData.numberMinted + uint128(quantity)
        );
        _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            if (from != address(0)) {
                ERC721TopLevel(msg.sender).emitTransfer(address(0), from, updatedIndex);
            }
            if (from != to) {
                ERC721TopLevel(msg.sender).emitTransfer(from, to, updatedIndex);
            }
            require(
                _checkOnERC721Received(msgSender, address(0), from, updatedIndex, _data) && _checkOnERC721Received(msgSender, from, to, updatedIndex, _data),
                "z"
            );
            updatedIndex++;
        }

        currentIndex = updatedIndex;
        if (from != address(0)) {
            _afterTokenTransfers(address(0), from, startTokenId, quantity);
        }
        if (from != to) {
            _afterTokenTransfers(from, to, startTokenId, quantity);
        }
    }

    function mintFn(
        address msgSender,
        uint _amount,
        address _from,
        address _to,
        uint256 _msgValue
    ) public onlyOwner {
        require(totalSupply() + _amount <= maxPossibleSupply, "m");
        require(_numberMinted(_to) + _amount <= maxBatchSize, "l");

        if (currency == wrappedNativeCoinAddress) {
            if (address(msgSender) != ERC721TopLevel(msg.sender).owner()) {
                require(mintPrice * _amount <= _msgValue, "a");
            }
        }
        else {
            IERC20 _currency = IERC20(currency);
            _currency.transferFrom(msg.sender, address(msg.sender), _amount * mintPrice);
        }

        _safeMint(msgSender, _from, _to, _amount);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transferMain(address from, address to, uint256 tokenId, TokenOwnership memory prevOwnership) private {
        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // De-list item if it was previously listed

        _addressData[from].balance -= 1;
        _addressData[to].balance += 1;
        _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId].addr == address(0)) {
            if (_exists(nextTokenId)) {
                _ownerships[nextTokenId] = TokenOwnership(prevOwnership.addr, prevOwnership.startTimestamp);
            }
        }

        ERC721TopLevel(msg.sender).emitTransfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    function _transfer(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (msgSender == prevOwnership.addr ||
        getApproved(tokenId) == msgSender ||
        isApprovedForAll(prevOwnership.addr, msgSender));

        require(isApprovedOrOwner, "a");

        require(prevOwnership.addr == from, "o");
        require(to != address(0), "0");

        _transferMain(from, to, tokenId, prevOwnership);
    }

    /**
     * Called only by the owner's marketplace functions
     */
    //    function transferBySale(
    //        address from,
    //        address to,
    //        uint256 tokenId
    //    ) public onlyOwner {
    //        _transfer(msg.sender, from, to, tokenId);
    //    }
    function transferBySale(
        address from,
        address to,
        uint256 tokenId
    ) public onlyOwner {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        _transferMain(from, to, tokenId, prevOwnership);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        //        emit Approval(owner, to, tokenId);
        ERC721TopLevel(msg.sender).emitApproval(owner, to, tokenId);
    }

    uint256 public nextOwnerToExplicitlySet = 0;

    /**
     * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
     */
    function _setOwnersExplicit(uint256 quantity) internal {
        uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
        require(quantity > 0, "q");
        uint256 endIndex = oldNextOwnerToSet + quantity - 1;
        if (endIndex > currentIndex - 1) {
            endIndex = currentIndex - 1;
        }
        // We know if the last one in the group exists, all in the group exist, due to serial ordering.
        require(_exists(endIndex), "n");
        for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
            if (_ownerships[i].addr == address(0)) {
                TokenOwnership memory ownership = ownershipOf(i);
                _ownerships[i] = TokenOwnership(ownership.addr, ownership.startTimestamp);
            }
        }
        nextOwnerToExplicitlySet = endIndex + 1;
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
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msgSender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("z");
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
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

abstract contract ERC721TopLevel {
    function emitTransfer(address _from, address _to, uint256 _tokenId) public virtual;
    function emitApproval(address _owner, address _approved, uint256 _tokenId) public virtual;
    function emitApprovalForAll(address _owner, address _operator, bool _approved) public virtual;

    //    function isListed(uint256 tokenId) public virtual returns (bool);
    function deList(uint256 tokenId) public virtual;
    function owner() public virtual returns (address);
}

// SPDX-License-Identifier: UNLICENSE
// Creator: 0xYeety; Based Pixel Labs/Yeety Labs; 1 yeet = 1 yeet; 1 cope = 1 cope
pragma solidity ^0.8.7;

contract ENSResolver {
    // Same address for Mainnet, Ropsten, Rinkerby, Gorli and other networks;
    ENS ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    function computeNameHash(bytes memory _name) private pure returns (bytes32 nameHash) {
        nameHash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        nameHash = keccak256(abi.encodePacked(keccak256(abi.encodePacked(nameHash, keccak256(abi.encodePacked("eth")))),keccak256(abi.encodePacked(_name))));
    }

    function resolve(string memory _name) public virtual view returns (address) {
        bytes memory name = abi.encodePacked(_name);
        uint nameLength = name.length;
        require(nameLength > 7, "impossible ENS address");
        require(
            name[nameLength-4] == 0x2E &&
            name[nameLength-3] == 0x65 &&
            name[nameLength-2] == 0x74 &&
            name[nameLength-1] == 0x68,
            "ENS name must end with \".eth\""
        );

        bytes memory strippedName = new bytes(nameLength-4);
        for (uint i = 0; i < nameLength-4; i++) {
            strippedName[i] = name[i];
        }

        Resolver resolver = ens.resolver(computeNameHash(strippedName));
        return resolver.addr(computeNameHash(strippedName));
    }
}

abstract contract ENS {
    function resolver(bytes32 node) public virtual view returns (Resolver);
}

abstract contract Resolver {
    function addr(bytes32 node) public virtual view returns (address);
}

// SPDX-License-Identifier: UNLICENSE
// Creator: 0xYeety; Based Pixel Labs/Yeety Labs; 1 yeet = 1 yeet; 1 cope = 1 cope
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RoyaltyReceiver is Ownable {
    uint256 numPayees;
    mapping(uint256 => address) private indexer;
    mapping(address => uint256) public royaltySplit;
    mapping(address => uint256) public balances;

    string public name;

    /**
     * @dev Throws if called by any account other than a royalty receiver/payee.
     */
    modifier onlyPayee() {
        _isPayee();
        _;
    }

    /**
     * @dev Throws if the sender is not on the royalty receiver/payee list.
     */
    function _isPayee() internal view virtual {
        require(royaltySplit[address(msg.sender)] > 0, "not a royalty payee");
    }

    constructor(string memory _name, address[] memory payees, uint256[] memory percentages) {
        require(payees.length == percentages.length, "lengths must match");
        numPayees = payees.length;
        for (uint i = 0; i < numPayees; i++) {
            indexer[i] = payees[i];
            royaltySplit[payees[i]] = percentages[i];
            balances[payees[i]] = 0;
        }
        name = _name;
    }

    receive() external payable {
        uint256 value = msg.value;
        uint256 split = value/100;
        for (uint256 i = 0; i < numPayees; i++) {
            uint256 allocation = split*(royaltySplit[indexer[i]]);
            balances[indexer[i]] += allocation;
            value -= allocation;
        }
        balances[indexer[0]] += value;
    }

    function withdraw() external onlyPayee() {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value:amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawTokens(address tokenAddress) external onlyOwner() {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function messageSender() public view returns (address) {
        return msg.sender;
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