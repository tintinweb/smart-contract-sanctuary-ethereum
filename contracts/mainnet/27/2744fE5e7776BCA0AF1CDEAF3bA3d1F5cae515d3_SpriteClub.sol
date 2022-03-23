// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// @@@@@@@@@@@@&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&@@@@@@@@@@@@@@@@@
// @@@@@@@@@@&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&@@@@@@@@@@@@@
// @@@@@@@&&&&&G?~^~~~~!YB&##&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&GPP5YY5PG#&&&&@@@@@@@@@@
// @@@@@@&#&#5~          :Y&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&#G7.       .^?B&&&&@@@@@@@@
// @@@@@&#&#?    .!YJ!:   :P&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&P  .......    :Y#&#&@@@@@@@
// @@@@@##&?.  .7G&&&#B7.  :G&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&Y. 7PB###B57:    Y#&&&@@@@@@
// @@@@@##&! . .#&&#&&&&?.  .JB&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&BJ~..Y&&&&&&&&&J. . ^5&#&@@@@@@
// @@@@@##&P~  .5#&####&#5^.  :?G#&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&#GJ^  .7&&#&&####&G! . 7G&#&@@@@@@
// @@@@@@##@J  ..Y#&####&&#P5?~..^7G#&&&@@@@@@@@@@@@@@@@@@@@@@@&#&&#Y~.   ^5&&#######&&Y.  :P&#&@@@@@@@
// @@@@@@&&&#J .  J&&#####&&&&&B5~  J#&#&@@@@@@@@@@@@@@@@@@@@&#&&B?:   .~JB&&#######&&J: .:G&#&&@@@@@@@
// @@@@@@@&#&P .. ^5&#####&##&&&&#~. J&##&@@@@@@@@@@@@@@@@@@&#&B?.   :?P#&&########&&7.  :B&&&&@@@@@@@@
// @@@@@@@&#&P..  .7&###########&&B: ^Y&##@@@@@@@@@@@@@@@@@&#&B?    !P&&&&########&#J.  :J&&#&@@@@@@@@@
// @@@@@@&&&&5 .. ~P&###########&#J.  ~&##&@@@@@@@@@@@@@@@@##&Y: .. [email protected]############&#!.  ^G#&&&@@@@@@@@@
// @@@@&&#&#J.   ^P&##########&&#Y    ~&##@@@@@@@@@@@@@@@@@&#&B?    ?&&&&#########&#G:  .7&&#&@@@@@@@@@
// @@@&#&&P~    7B&##########&&P!    !P&#&@@@@@@@@@@@@@@@@@@&#&BJ:.  ~5#&&&########&&J:  .5#&#&@@@@@@@@
// @@&#&#J.   :Y#&##########&&J:   ~P&&#&@@@@@@@@@@@@@@@@@@@@&&&&#PJ^  :?PB&&########&P~  .P#&&&@@@@@@@
// @&#&#Y    ~B&&##########&&7.  .7#&&&&@@@@@@@@@@@@@@@@@@@@@@@&&&&&#5~  .^Y&########&&P^  ^G&#&@@@@@@@
// @&#&P    :J&###########&#J.  .~&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&#?.  :J&&#######&&5 .:P&#&@@@@@@@
// @&#&P  . ~P&###########&#~.  :Y#&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&&:   ^&&#######&&5 .~G&#&@@@@@@@
// @&#&G:   :J&###########&#P:  .!&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&#J:  ^&&#######&P~ .:G&#&@@@@@@@
// @&&&&G^   !&&&#######&&#&&7.  .?#&#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&#B^  ^&&#######&B?   7G&&&&@@@@@
// @@&&#&#J^ .7#&&&#####&&##&&Y:   ^P&#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&#B^  ^##&#######&#Y^  ^Y&&#&@@@@
// @@@@&&&&B5~ ^5#&&#########&&P^   ^5&##@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&#Y:  ^&&######&&#&&#P7. !G&&&&@@
// @@@@@@&&&&#J  :J#&#########&&P  . ?&##&@@@@@@@@@@@@@@@@@@@@@@@@@@&#&#~.  ~&&##########&&&&5^ .G&&&&@
// @@@@@@@@&#&B.   :J&&########&G..  ?&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@&#&#. . ^&&#############&&5  ^G&#&@
// @@@@@@@@@&&#Y. . :#&&#######&G:. .J&##@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&#:   :5#&#############@5   P&#&@
// @@@@@@@@@&#&&:   ^&&#######&&P  :5#&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&#G^ . .#&#&&########&&G!  .G&#&@
// @@@@@@@@@&#&&:  :J&&######&#Y: ^G&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&&J:  .#&#&&#####&&&B?:  ~G#&&&@
// @@@@@@@@@&#&#:  !#&&####&&B7. :#&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&G~  .#&#######&#P!. :7P&&#&&@@
// @@@@@@@@@&#&#:  !&#####&##^  ^P&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&&7  .#&######&P~  ^YB&&&&&@@@@
// @@@@@@@@@&#&#:  [email protected]#####&#J:  ~&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##&7 .^#&#####&#? .:B&&&&@@@@@@@
// @@@@@@@@@&#&#~. ^P&&###&#~.  !&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&#7 .~#&#####&Y^ .Y#&#&@@@@@@@@
// @@@@@@@@@@&###~  :P&&&&&G.  :?&&#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##&5^ .^#&###&&&!  :P#&#&@@@@@@@@
// @@@@@@@@@@@&#&B?.  ~?J?!.   !B&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#&&7.  .G&&&&&#7.  :5#&#&@@@@@@@@
// @@@@@@@@@@@@&#&&G?:..      !P&##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#&&?:  ..75GP?~. . :B#&&&@@@@@@@@
// @@@@@@@@@@@@@&&&&&#BP5YYYYP#&#&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&#!  .  ...   . .7&&#&@@@@@@@@@
// @@@@@@@@@@@@@@@@&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##&G?:          :J&##&@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&&BP7~~~~~~?5B&&&&@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&&&&&&&@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&&@@@@@@@@@@@@@@@@

import './ERC721S.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract SpriteClub is ERC721S, IERC2981, Ownable, Pausable {
    using Strings for uint256;

    bool public isSpritelistSaleActive;
    bool public isRafflelistSaleActive;

    bytes32 public spritelistMerkleRoot;
    bytes32 public rafflelistMerkleRoot;
    mapping(address => uint256) public mintCounts;
    mapping(uint256 => uint256) public spriteAnswers;

    uint16 public royaltyBasisPoints;
    string public collectionURI;
    string internal metadataBaseURI;
    bool public isMetadataFinalized;
    uint256 public mintPrice;

    constructor(string memory initialMetadataBaseURI, string memory initialCollectionURI, uint16 initialRoyaltyBasisPoints, uint256 initialTransactionMintLimit, uint256 initialAddressMintLimit, uint256 initialCollectionSize, uint256 initialMintPrice)
    ERC721S('SpriteClub', 'SPRITE', initialTransactionMintLimit, initialAddressMintLimit, initialCollectionSize)
    Ownable() {
        metadataBaseURI = initialMetadataBaseURI;
        collectionURI = initialCollectionURI;
        royaltyBasisPoints = initialRoyaltyBasisPoints;
        mintPrice = initialMintPrice;
    }

    // Meta

    function royaltyInfo(uint256, uint256 salePrice) external view override returns (address, uint256) {
        return (address(this), salePrice * royaltyBasisPoints / 10000);
    }

    function contractURI() external view returns (string memory) {
        return collectionURI;
    }

    // Admin

    function setCollectionURI(string calldata newCollectionURI) external onlyOwner {
        collectionURI = newCollectionURI;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function setMetadataBaseURI(string calldata newMetadataBaseURI) external onlyOwner {
        require(!isMetadataFinalized, 'SpriteClub: metadata is now final');
        metadataBaseURI = newMetadataBaseURI;
    }

    function finalizeMetadata() external onlyOwner {
        require(!isMetadataFinalized, 'SpriteClub: metadata is already finalized');
        isMetadataFinalized = true;
    }

    function setRoyaltyBasisPoints(uint16 newRoyaltyBasisPoints) external onlyOwner {
        require(newRoyaltyBasisPoints >= 0, 'SpriteClub: royaltyBasisPoints must be >= 0');
        require(newRoyaltyBasisPoints < 5000, 'SpriteClub: royaltyBasisPoints must be < 5000 (50%)');
        royaltyBasisPoints = newRoyaltyBasisPoints;
    }

    function setIsSpritelistSaleActive(bool newIsSpritelistSaleActive) external onlyOwner {
        require(mintPrice >= 0 || !newIsSpritelistSaleActive, 'SpriteClub: cannot start if mintPrice is 0');
        require(spritelistMerkleRoot != 0, 'SpriteClub: cannot start if spritelistMerkleRoot not set');
        isSpritelistSaleActive = newIsSpritelistSaleActive;
    }

    function setIsRafflelistSaleActive(bool newIsRafflelistSaleActive) external onlyOwner {
        require(mintPrice >= 0 || !newIsRafflelistSaleActive, 'SpriteClub: cannot start if mintPrice is 0');
        require(rafflelistMerkleRoot != 0, 'SpriteClub: cannot start if rafflelistMerkleRoot not set');
        isRafflelistSaleActive = newIsRafflelistSaleActive;
    }

    function setSpritelistMerkleRoot(bytes32 newSpritelistMerkleRoot) external onlyOwner {
        spritelistMerkleRoot = newSpritelistMerkleRoot;
    }

    function setRafflelistMerkleRoot(bytes32 newRafflelistMerkleRoot) external onlyOwner {
        rafflelistMerkleRoot = newRafflelistMerkleRoot;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Metadata

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'SpriteClub: URI query for nonexistent token');
        return string(abi.encodePacked(metadataBaseURI, tokenId.toString(), '.json'));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURI;
    }

    // Minting

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override whenNotPaused() {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "SpriteClub: The caller is another contract");
        _;
    }

    function _generateMerkleLeaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verifyMerkleLeaf(bytes32 merkleLeaf, bytes32 merkleRoot, bytes32[] memory proof) internal pure returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, merkleLeaf);
    }

    function _verifyAnswer(uint256 answer) internal pure returns (bool) {
        if (answer <= 0 || answer > 60000) {
            return false;
        }
        for (uint256 i; i < 5; i++) {
            uint256 value = answer;
            for (uint256 j; j < i; j++) {
                value = value / 10;
            }
            value = value % 10;
            if (value <= 0 || value > 5) {
                return false;
            }
        }
        return true;
    }

    function spritelistMint(uint256 answer, uint256 quantity, bytes32[] calldata proof) public payable callerIsUser {
        require(isSpritelistSaleActive && mintPrice > 0, "SpriteClub: spritelist sale not active");
        require(msg.value >= mintPrice * quantity, "SpriteClub: insufficient payment");
        require(mintCounts[_msgSender()] == 0, "SpriteClub: already claimed");
        require(_verifyMerkleLeaf(_generateMerkleLeaf(_msgSender()), spritelistMerkleRoot, proof), "SpriteClub: invalid proof");
        require(_verifyAnswer(answer), "SpriteClub: answer invalid");
        mintCounts[_msgSender()] += quantity;
        spriteAnswers[currentTokenIndex] = answer;
        _mint(_msgSender(), quantity, false);
    }

    function spritelistMintWithApproval(uint256 answer, uint256 quantity, bytes32[] calldata proof, address[] calldata approvedAddresses) external payable callerIsUser {
        spritelistMint(answer, quantity, proof);
        for (uint256 i; i < approvedAddresses.length; i++) {
            _setApprovalForAll(_msgSender(), approvedAddresses[i], true);
        }
    }

    function rafflelistMint(uint256 answer, bytes32[] calldata proof) public payable callerIsUser {
        require(isRafflelistSaleActive && mintPrice > 0, "SpriteClub: rafflelist sale not active");
        require(msg.value >= mintPrice, "SpriteClub: insufficient payment");
        require(mintCounts[_msgSender()] == 0, "SpriteClub: already claimed");
        require(_verifyMerkleLeaf(_generateMerkleLeaf(_msgSender()), rafflelistMerkleRoot, proof), "SpriteClub: invalid proof");
        require(_verifyAnswer(answer), "SpriteClub: answer invalid");
        mintCounts[_msgSender()] += 1;
        spriteAnswers[currentTokenIndex] = answer;
        _mint(_msgSender(), 1, false);
    }

    function rafflelistMintWithApproval(uint256 answer, bytes32[] calldata proof, address[] calldata approvedAddresses) external payable callerIsUser {
        rafflelistMint(answer, proof);
        for (uint256 i; i < approvedAddresses.length; i++) {
            _setApprovalForAll(_msgSender(), approvedAddresses[i], true);
        }
    }

    function ownerMint(address to, uint256 quantity) external onlyOwner {
        _mint(to, quantity, true);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';


contract ERC721S is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Minting happens in order from 0 onwwards
    uint256 internal currentTokenIndex = 0;

    // Total token limit
    uint256 public immutable collectionSize;

    // Minting limit per transaction
    uint256 public immutable transactionMintLimit;

    // Minting limit per address
    uint256 public immutable addressMintLimit;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_, uint256 transactionMintLimit_, uint256 addressMintLimit_, uint256 collectionSize_) {
        _name = name_;
        _symbol = symbol_;
        transactionMintLimit = transactionMintLimit_;
        addressMintLimit = addressMintLimit_;
        collectionSize = collectionSize_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function totalSupply() public view override returns (uint256) {
        return currentTokenIndex;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < currentTokenIndex;
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721S: owner query for nonexistent token");
        return owner;
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        require(index < currentTokenIndex, "ERC721S: index out of bounds");
        return index;
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), 'ERC721S: balance query for the zero address');
        return _balances[owner];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        require(index < balanceOf(owner), "ERC721S: index out of bounds");
        uint256 tokenIndex = 0;
        for (uint256 tokenId = 0; tokenId < currentTokenIndex; tokenId++) {
            if (_owners[tokenId] == owner) {
                if (tokenIndex == index) {
                    return tokenId;
                }
                tokenIndex++;
            }
        }
        revert('ERC721S: unable to get token of owner by index');
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721S: URI query for nonexistent token');
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = _owners[tokenId];
        require(to != owner, "ERC721S: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721S: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(_owners[tokenId], to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721S: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), 'ERC721S: approved query for nonexistent token');
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721S: query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            'ERC721S: transfer to non ERC721Receiver implementer'
        );
    }

    function _mint(address to, uint256 quantity, bool shouldIgnoreLimits) internal {
        require(to != address(0), 'ERC721S: mint to the zero address');
        if (!shouldIgnoreLimits) {
            require(quantity > 0 && quantity <= transactionMintLimit, 'ERC721S: invalid quantity');
            require(_balances[to] + quantity <= addressMintLimit, "ERC721S: adress mint limit reached");
        }
        uint256 startTokenId = currentTokenIndex;
        uint256 nextCurrentTokenIndex = currentTokenIndex + quantity;
        require(nextCurrentTokenIndex <= collectionSize, 'ERC721S: quantity out of bounds');
        _beforeTokenTransfers(address(0), to, startTokenId, quantity);
        _balances[to] += quantity;
        for (; startTokenId < nextCurrentTokenIndex; startTokenId++) {
            _owners[startTokenId] = to;
            emit Transfer(address(0), to, startTokenId);
        }
        currentTokenIndex = nextCurrentTokenIndex;
    }

    function _transfer(address from, address to, uint256 tokenId) private {
        require(_owners[tokenId] == from, "ERC721S: transfer of token that is not own");
        require(to != address(0), "ERC721S: oww, dont do that! I almost got burnt!");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721S: caller is not owner nor approved");

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert('ERC721S: transfer to non ERC721Receiver implementer');
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";