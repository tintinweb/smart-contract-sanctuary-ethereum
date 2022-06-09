// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *
 *████████████████████████████████████████████████████████████████████
 *██▀▄─██▄─██─▄█─▄─▄─█─▄▄─███─▄▄▄▄█─▄─▄─█▄─▄▄▀█─▄▄─█▄─█─▄█▄─▄▄─█─▄▄▄▄█
 *██─▀─███─██─████─███─██─███▄▄▄▄─███─████─▄─▄█─██─██─▄▀███─▄█▀█▄▄▄▄─█
 *▀▄▄▀▄▄▀▀▄▄▄▄▀▀▀▄▄▄▀▀▄▄▄▄▀▀▀▄▄▄▄▄▀▀▄▄▄▀▀▄▄▀▄▄▀▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▄▀▄▄▄▄▄▀
 * 
 *                                                     𝔟𝔶 🅐🅙🅡🅔🅩🅘🅐
 *
 *   A self contained mechanism to originate and print dynamic line strokes based on 
 *       - token Id 
 *       - secret seed 
 *       - blockchain transactions.
 *   
 *  The tokenURI produces different output based on these factors and the generated art pattern changes constantly
 *  producing unique and rare combinations of stroke color, pattern and origin for each token at a given point.
 *   
 */

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./StrokePatternGenerator.sol";


contract AutoStrokes is ERC721A, Ownable {
  
  uint256 maxSupply;
  string secretSeed;

    constructor() ERC721A("AutoStrokes", "as") {}

    function setContractParams(string memory _secretSeed, uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
        secretSeed = _secretSeed;
    }
    
    function mint(address recipient, uint256 quantity) external payable{
        require(totalSupply() + quantity <= maxSupply, "Not enough tokens left");
        require(recipient == owner(), "Only owner can mint the tokens");
        _safeMint(recipient, quantity);
    }
    
    function getUniqueCode(uint256 tokenId, uint occurence) internal view returns (string memory) {
        return Strings.toHexString(uint256(keccak256(abi.encodePacked(tokenId, occurence, secretSeed, block.timestamp, block.difficulty))));
    }

    function _baseURI() internal pure override returns (string memory) {
        return "";
    }

    function getStrokeVariation(uint256 tokenId) internal pure returns(uint8){
        uint8[35] memory variationIndicators = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35];
        return variationIndicators[tokenId % 35];
    }

    
    function getBackgroundDetails(uint256 tokenId) internal pure returns(string memory, string memory){
        string[9] memory backgroundColorCodes = ['2A0A0A', '123456', '033E3E', '000000', '254117', '3b2f2f', '560319', '36013f', '3D0C02'];
        string[9] memory backgroundColorNames = ['Seal Brown', 'Deep Sea Blue', 'Deep Teal', 'Black', 'Forest Green', 'Dark Coffee', 'Dark Scarlet', 'Deep Purple', 'Black Bean'];
        return (backgroundColorCodes[tokenId % 9], backgroundColorNames[tokenId % 9]);
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        uint8 variationIndicator = getStrokeVariation(tokenId);
        uint8 numberOfStrokesToPrint = StrokePatternGenerator.getNumberOfStrokesToPrint(getStrokeVariation(tokenId));
       (string memory x, string memory y, string memory originLineTag, string memory originPlan, string memory description) = StrokePatternGenerator.getStrokeOriginParameters(variationIndicator, tokenId, secretSeed);

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{', getProperties(tokenId,numberOfStrokesToPrint,x,y,originPlan, variationIndicator), '"name": "Auto Strokes #', Strings.toString(tokenId), '", "description": "',description,'", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(printStrokes(tokenId, numberOfStrokesToPrint, x, y, originLineTag))), '"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function printStrokes(uint256 tokenId, uint8 numberOfStrokesToPrint, string memory x, string memory y, string memory originLineTag) internal view returns (string memory) {        
        string memory prefixTag = getPrefixTag(tokenId);
        string memory suffixTag = getSuffixTag(x, y);
        string memory uniqueCode = getUniqueCode(tokenId, 1);
        string memory strokeSet = StrokePatternGenerator.getStrokePattern(uniqueCode, x, y, 1, secretSeed);
        string memory strokes = string(abi.encodePacked(prefixTag, originLineTag, strokeSet));

        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 2);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 3);

        if(numberOfStrokesToPrint == 60) {
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 4);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 5);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 6);
        } 

        else if (numberOfStrokesToPrint == 90) {
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 4);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 5);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 6);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 7);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 8);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 9);
        } 
        
        else if (numberOfStrokesToPrint == 120){
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 4);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 5);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 6);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 7);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 8);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 9);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 10);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 11);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 12);
        }

        else if (numberOfStrokesToPrint == 150){
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 4);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 5);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 6);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 7);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 8);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 9);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 10);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 11);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 12);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 13);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 14);
        strokes = getUpdatedStrokeSet(tokenId, strokes, x, y, 15);
        }
        return string(abi.encodePacked(strokes,  suffixTag));
    }

    function getUpdatedStrokeSet(uint256 tokenId, string memory strokes ,string memory x, string memory y, uint8 occurence) internal view returns (string memory){
        string memory uniqueCode = getUniqueCode(tokenId, occurence);
        string memory strokeSet = StrokePatternGenerator.getStrokePattern(uniqueCode, x, y, occurence, secretSeed);
        return string(abi.encodePacked(strokes, strokeSet));
    }

    function getPrefixTag (uint256 tokenId) internal pure returns (string memory) {           
        string[3] memory prefixTag;
        prefixTag[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"> <rect width="100%" height="100%" fill="#';
        (string memory colorCode,) = getBackgroundDetails(tokenId);
        prefixTag[1] = colorCode;
        prefixTag[2] = '"/>';
        return string(abi.encodePacked(prefixTag[0], prefixTag[1], prefixTag[2]));
    }

    function getSuffixTag (string memory x, string memory y) internal pure returns (string memory) {
        string[5] memory suffixTag;
        suffixTag[0] = '<circle cx="';
        suffixTag[1] = x;
        suffixTag[2] = '" cy="';
        suffixTag[3] = y;
        suffixTag[4] = '" r="3" stroke="black" fill="white"/></svg>';
        return string(abi.encodePacked(suffixTag[0], suffixTag[1], suffixTag[2], suffixTag[3], suffixTag[4]));
    }

    function getProperties(uint256 tokenId, uint8 numberOfStrokesToPrint, string memory x, string memory y, string memory originPlan, uint8 variationIndicator) internal pure returns (string memory) {
        (,string memory colorName) = getBackgroundDetails(tokenId);
        string memory originBehaviour = StrokePatternGenerator.getOriginBehaviour(variationIndicator);
        return string(abi.encodePacked('"attributes" : [ {"trait_type" : "Background","value" : "', colorName,'"},{"trait_type" : "Origin","value" : "', originBehaviour,'"},{"trait_type" : "Origin Path","value" : "', originPlan,'"},{"trait_type" : "Stroke Count","value" : "',Strings.toString(numberOfStrokesToPrint),'"},{"trait_type" : "Coordinates","value" : "(',x,',',y,')"}],'));
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
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
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        safeTransferFrom(from, to, tokenId, '');
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
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex &&
            !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev This is equivalent to _burn(tokenId, false)
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
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
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
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
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

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
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
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

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
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * 
 * A custom library for the project Auto Strokes.
 *                          
 *                             𝔟𝔶 🅐🅙🅡🅔🅩🅘🅐
 *
 */
 
import "@openzeppelin/contracts/utils/Strings.sol";

library StrokePatternGenerator {

    function getNumberOfStrokesToPrint(uint8 variationIndicator) public pure returns (uint8) { 
        if (variationIndicator == 1 || variationIndicator == 6 ||variationIndicator == 11 ||variationIndicator == 16 ||variationIndicator == 21 ||variationIndicator == 26 || variationIndicator == 31) {
            return 30;
            }
        else if (variationIndicator == 2|| variationIndicator == 7 ||variationIndicator == 12 ||variationIndicator == 17 ||variationIndicator == 22 ||variationIndicator == 27 ||variationIndicator == 32) {
            return 60;
            }
        else if (variationIndicator == 3|| variationIndicator == 8 ||variationIndicator == 13 ||variationIndicator == 18 ||variationIndicator == 23 ||variationIndicator == 28 ||variationIndicator == 33) {
            return 90;
            }
        else if (variationIndicator == 4|| variationIndicator == 9 ||variationIndicator == 14 ||variationIndicator == 19 ||variationIndicator == 24 ||variationIndicator == 29 ||variationIndicator == 34) {
            return 120;
            }    
        return 150;
    }

    function getStrokeOriginParameters(uint8 variationIndicator, uint256 tokenId, string memory secretSeed) public view returns (string memory, string memory, string memory, string memory, string memory) { 
        string memory x;
        string memory y;
        uint256 xInt;
        uint256 yInt;

        if (variationIndicator == 1 || variationIndicator == 2 ||variationIndicator == 3 ||variationIndicator == 4 ||variationIndicator == 5) {
            x = Strings.toString(getOriginOrdinate(tokenId, 1, secretSeed));
            return (x, x, getOriginIndLineTag('0', '0', '350', '350'),'Major Diagonal', 'Strokes originates on major diagonal. Refresh the metadata and observe the change of stroke pattern, color and coordinates.');
            }
        else if (variationIndicator == 6 ||variationIndicator == 7 ||variationIndicator == 8 || variationIndicator == 9 || variationIndicator == 10) {
           xInt = getOriginOrdinate(tokenId, 2, secretSeed);
           yInt = 350 - xInt;
           return (Strings.toString(xInt), Strings.toString(yInt), getOriginIndLineTag('350', '0', '0', '350'),'Minor Diagonal','Strokes originates on minor diagonal. Refresh the metadata and observe the change of stroke pattern, color and coordinates.');
            }
        else if (variationIndicator == 11|| variationIndicator == 12 ||variationIndicator == 13 ||variationIndicator == 14 ||variationIndicator == 15) {
            y = Strings.toString(getOriginOrdinate(tokenId, 3, secretSeed));
            return ('175', y, getOriginIndLineTag('175', '0', '175', '350'),'Vertical', 'Strokes originates on a vertical line. Refresh the metadata and observe the change of stroke pattern, color and coordinates.');
            }
        else if (variationIndicator == 16|| variationIndicator == 17 ||variationIndicator == 18 ||variationIndicator == 19 ||variationIndicator == 20) {
            x = Strings.toString(getOriginOrdinate(tokenId, 4, secretSeed));
            return (x, '175', getOriginIndLineTag('0', '175', '350', '175'),'Horizontal', 'Strokes originates on a horizontal line. Refresh the metadata and observe the change of stroke pattern, color and coordinates.');
            }
        else if (variationIndicator == 21|| variationIndicator == 22 ||variationIndicator == 23 || variationIndicator == 24 || variationIndicator == 25) {

           uint256 decision =  getDecisionFactor(tokenId, 5, secretSeed);

            if(decision == 1) {
              yInt =  getYOrdinateRect(tokenId, 6, secretSeed);
              y = Strings.toString(yInt);


              if(yInt == 50 || yInt == 300) {
                   x = Strings.toString(getXOrdinateRect(tokenId, 7, secretSeed));
                }
                else {
                   xInt = getDecisionFactor(tokenId, 8, secretSeed);
                   if (xInt == 1) {
                       x = '40';
                   }
                   else {
                       x = '310';
                   }
                }
            }
            else {
            xInt = getXOrdinateRect(tokenId, 6, secretSeed);
            x = Strings.toString(xInt);

                if(xInt == 40 || xInt == 310) {
                    y = Strings.toString(getYOrdinateRect(tokenId, 7, secretSeed));
                }
                else {
                   yInt = getDecisionFactor(tokenId,8, secretSeed);
                   if (yInt == 1) {
                       y = '50';
                   }
                   else {
                       y = '300';
                   }
                }
            }
            return (x, y, getRectOriginIndLineTag(),'Rectangle','Strokes originates on a rectangle. Refresh the metadata and observe the change of stroke pattern, color and coordinates.');    
            }
        else if (variationIndicator == 26|| variationIndicator == 27 ||variationIndicator == 28 || variationIndicator == 29 || variationIndicator == 30) {
            return ('175', '175', '','Center','Strokes originates at the center. Refresh the metadata and observe the change of stroke pattern and color.');    
            }    
         else {
            x = Strings.toString(getOriginOrdinate(tokenId, 9, secretSeed));
            y = Strings.toString(getOriginOrdinate(tokenId, 10, secretSeed));
            return (x, y, '','Anywhere', 'Strokes can originate anywhere on the viewbox. Refresh the metadata and observe the change of stroke pattern, color and coordinates.');
            }            
    }

    function getOriginBehaviour(uint8 variationIndicator) public pure returns (string memory) { 
         if (variationIndicator == 26|| variationIndicator == 27 ||variationIndicator == 28 || variationIndicator == 29 || variationIndicator == 30) {
            return "Fixed";
         }
         else {
             return "Varying";
         }
    }

    function getStrokePattern(string memory code, string memory xOrdinate, string memory yOrdinate, uint8 occurence, string memory secretSeed) public view returns (string memory) {
        string[65] memory stroke;
        stroke[0] = '<line x1="';
        stroke[1] = xOrdinate;
        stroke[2] = '" y1="';
        stroke[3] = yOrdinate;
        stroke[4] ='" x2="';
        stroke[5] =  Strings.toString(getToOrdinate(1, occurence, secretSeed));
        stroke[6] = '" y2="';
        stroke[7] =  Strings.toString(getToOrdinate(2, occurence, secretSeed));
        stroke[8] = '" style="stroke:#';
        stroke[9] = getStrokeColorCode(code, 2, 8);

        stroke[10] = getStrokeCommonTag(xOrdinate, yOrdinate);
        stroke[11] =  Strings.toString(getToOrdinate(3, occurence, secretSeed));
        stroke[12] = '" y2="';
        stroke[13] =  Strings.toString(getToOrdinate(4, occurence, secretSeed));
        stroke[14] = '" style="stroke:#';
        stroke[15] = getStrokeColorCode(code, 8, 14);

        stroke[16] =  stroke[10];
        stroke[17] =  Strings.toString(getToOrdinate(5, occurence, secretSeed));
        stroke[18] = '" y2="';
        stroke[19] =  Strings.toString(getToOrdinate(6, occurence, secretSeed));
        stroke[20] = '" style="stroke:#';
        stroke[21] = getStrokeColorCode(code, 14, 20);

        stroke[22] =  stroke[10];
        stroke[23] =  Strings.toString(getToOrdinate(7, occurence, secretSeed));
        stroke[24] = '" y2="';
        stroke[25] =  Strings.toString(getToOrdinate(8, occurence, secretSeed));
        stroke[26] = '" style="stroke:#';
        stroke[27] = getStrokeColorCode(code, 20, 26);

        stroke[28] =  stroke[10];
        stroke[29] =  Strings.toString(getToOrdinate(9, occurence, secretSeed));
        stroke[30] = '" y2="';
        stroke[31] =  Strings.toString(getToOrdinate(10, occurence, secretSeed));
        stroke[32] = '" style="stroke:#';
        stroke[33] = getStrokeColorCode(code, 26, 32);        

        stroke[34] =  stroke[10];
        stroke[35] =  Strings.toString(getToOrdinate(11, occurence, secretSeed));
        stroke[36] = '" y2="';
        stroke[37] =  Strings.toString(getToOrdinate(12, occurence, secretSeed));
        stroke[38] = '" style="stroke:#';
        stroke[39] = getStrokeColorCode(code, 32, 38);    

        stroke[40] =  stroke[10];
        stroke[41] =  Strings.toString(getToOrdinate(13, occurence, secretSeed));
        stroke[42] = '" y2="';
        stroke[43] =  Strings.toString(getToOrdinate(14, occurence, secretSeed));
        stroke[44] = '" style="stroke:#';
        stroke[45] = getStrokeColorCode(code, 38, 44);     

        stroke[46] =  stroke[10];
        stroke[47] =  Strings.toString(getToOrdinate(15, occurence, secretSeed));
        stroke[48] = '" y2="';
        stroke[49] =  Strings.toString(getToOrdinate(16, occurence, secretSeed));
        stroke[50] = '" style="stroke:#';
        stroke[51] = getStrokeColorCode(code, 44, 50);            
             
        stroke[52] = stroke[10];
        stroke[53] =  Strings.toString(getToOrdinate(17, occurence, secretSeed));
        stroke[54] = '" y2="';
        stroke[55] =  Strings.toString(getToOrdinate(18, occurence, secretSeed));
        stroke[56] = '" style="stroke:#';
        stroke[57] = getStrokeColorCode(code, 50, 56);                

        stroke[58] = stroke[10];
        stroke[59] =  Strings.toString(getToOrdinate(19, occurence, secretSeed));
        stroke[60] = '" y2="';
        stroke[61] =  Strings.toString(getToOrdinate(20, occurence, secretSeed));
        stroke[62] = '" style="stroke:#';
        stroke[63] = getStrokeColorCode(code, 56, 62);  
        stroke[64] = '"/>';

        string memory output = string(abi.encodePacked(stroke[0], stroke[1], stroke[2], stroke[3], stroke[4], stroke[5], stroke[6], stroke[7], stroke[8], stroke[9], stroke[10]));
        output = string(abi.encodePacked(output, stroke[11], stroke[12], stroke[13], stroke[14], stroke[15], stroke[16], stroke[17], stroke[18], stroke[19], stroke[20]));
        output = string(abi.encodePacked(output, stroke[21], stroke[22], stroke[23], stroke[24], stroke[25], stroke[26], stroke[27], stroke[28], stroke[29], stroke[30]));
        output = string(abi.encodePacked(output, stroke[31], stroke[32], stroke[33], stroke[34], stroke[35], stroke[36], stroke[37], stroke[38], stroke[39], stroke[40]));
        output = string(abi.encodePacked(output, stroke[41], stroke[42], stroke[43], stroke[44], stroke[45], stroke[46], stroke[47], stroke[48], stroke[49], stroke[50]));
        output = string(abi.encodePacked(output, stroke[51], stroke[52], stroke[53], stroke[54], stroke[55], stroke[56], stroke[57], stroke[58], stroke[59], stroke[60]));
        output = string(abi.encodePacked(output, stroke[61], stroke[62], stroke[63], stroke[64]));

        return output;
    }

    function getStrokeCommonTag(string memory xOrdinate, string memory yOrdinate) internal pure returns (string memory) {
        string[5] memory common;
        common[0] = '"/><line x1="';
        common[1] = xOrdinate;
        common[2] = '" y1="';
        common[3] = yOrdinate;
        common[4] ='" x2="';
        return string(abi.encodePacked(common[0], common[1], common[2], common[3], common[4]));
    }

    function getOriginIndLineTag(string memory x1, string memory y1, string memory x2, string memory y2) internal pure returns (string memory) {
        string[20] memory originIndLine;
        originIndLine[0] = '<line stroke-dasharray="3,10" x1="';
        originIndLine[1] = x1;
        originIndLine[2] = '" y1="';
        originIndLine[3] = y1;
        originIndLine[4] = '" x2="';
        originIndLine[5] = x2;
        originIndLine[6] = '" y2="';
        originIndLine[7] = y2;
        originIndLine[8] = '" opacity="0.05" style="stroke:white"/>';
        return string(abi.encodePacked(originIndLine[0], originIndLine[1], originIndLine[2], originIndLine[3], originIndLine[4], originIndLine[5], originIndLine[6], originIndLine[7], originIndLine[8]));
    }

    function getRectOriginIndLineTag() internal pure returns (string memory){
        return '<line stroke-dasharray="3,10" x1="40" y1="50" x2="310" y2="50" opacity="0.05" style="stroke:white"/><line stroke-dasharray="3,10" x1="40" y1="50" x2="40" y2="300" opacity="0.05" style="stroke:white"/><line stroke-dasharray="3,10" x1="310" y1="50" x2="310" y2="300" opacity="0.05" style="stroke:white"/><line stroke-dasharray="3,10" x1="40" y1="300" x2="310" y2="300" opacity="0.05" style="stroke:white"/>';
    }
    
    function getStrokeColorCode(string memory code, uint8 startIndex, uint8 endIndex) internal pure returns(string memory) {
     bytes memory codebytes = bytes(code);
     bytes memory result = new bytes(endIndex-startIndex);
       for(uint256 i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = codebytes[i];
        }return string(result);
    }

    function getToOrdinate(uint8 factor, uint256 occurence, string memory secretSeed) internal view returns(uint256){
        return uint256(keccak256(abi.encodePacked(factor, occurence, secretSeed, block.timestamp))) % 350;
    }

    function getOriginOrdinate(uint256 tokenId, uint8 factor, string memory secretSeed) internal view returns(uint256){
        return uint256(keccak256(abi.encodePacked(tokenId, factor, secretSeed, block.timestamp, block.difficulty))) % 350;
    }

    function getXOrdinateRect(uint256 tokenId, uint8 factor, string memory secretSeed) internal view returns(uint256){
        return uint256(keccak256(abi.encodePacked(tokenId, factor, secretSeed, block.timestamp, block.difficulty))) % 271 + 40;
    }

    function getYOrdinateRect(uint256 tokenId, uint8 factor, string memory secretSeed) internal view returns(uint256){
        return uint256(keccak256(abi.encodePacked(tokenId, factor, secretSeed, block.timestamp, block.difficulty))) % 251 + 50;
    }

    function getDecisionFactor(uint256 tokenId, uint8 factor, string memory secretSeed) internal view returns(uint256){
        return uint256(keccak256(abi.encodePacked(tokenId, factor, secretSeed, block.timestamp, block.difficulty))) % 2 + 1;
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