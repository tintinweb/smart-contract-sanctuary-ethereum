// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./libs/erc721a/contracts/ERC721A.sol";
import "./EtherscentAccordsDistribution.sol";
import "./EtherscentDesc.sol";
import "./EtherscentSVG.sol";
import "./libs/JSONGenerator.sol";

contract EtherscentMain is Ownable, ERC721A, EtherscentAccordsDistribution, EtherscentDesc, EtherscentSVG {

    // uint256 public currentPreparedFormulaIdx;

    struct TokenMintInfo {
        uint8 formulaType; // 1 not use, 2 use special
        uint256 formulaIdx;
        uint256 prevBlockHash;
        AccordsRange accordsRange;
    }

    struct TokenDetailedInfo {
        string tokenName;
        string description;
        string IPLicense; // By default, dafaultIPLicensing is applied to tokens.
    }
    
    mapping(uint256 => TokenDetailedInfo) private __tokenDetailedInfo;

    mapping(uint256 => TokenMintInfo) private __tokenMintInfo;

    address public minter;

    string dafaultIPLicense; // This variable uses a url (by mirror.xyz or similar content creators) to link to IP licensing terms, such license applies to all tokens except those that have been voted by the community for a special license. 
    string defaultTokenName;
    string defaultDescription;

    constructor() ERC721A("EtherScent formula", "FORMULA") {
        minter = msg.sender;
        defaultTokenName = "EtherScent";
        defaultDescription = "EtherScent formula";
    }

    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }

// #####################################

    function mint_random(uint256 quantity) public onlyMinter returns (uint256, uint256) {
        __tokenMintInfo[_currentIndex] = TokenMintInfo({
            formulaType: 1, 
            formulaIdx: 0,
            prevBlockHash: uint256(blockhash(block.number - 1)),
            accordsRange: AccordsRange({
                topRange: _topAccords.length, 
                strongRange: _strongAccords.length, 
                midRange: _midAccords.length, 
                weakRange: _weakAccords.length
            })
        });
        return _safeMint(minter, quantity);
    }

    function mint_special(uint256 quantity, uint256 startIdx) public onlyMinter returns (uint256, uint256) {
        require(quantity + startIdx <= _specialFormulas.length);
        __tokenMintInfo[_currentIndex] = TokenMintInfo({
            formulaType: 2, 
            formulaIdx: startIdx,
            prevBlockHash: 0,
            accordsRange: AccordsRange({
                topRange: 0,
                strongRange: 0,
                midRange: 0,
                weakRange: 0
            })
        });
        return _safeMint(minter, quantity);
    }

// #####################################

    function recordAccords(uint256[] memory _accords, string[] memory _accordsName) public onlyOwner {
        require (_accords.length == _accordsName.length);
        uint256 accords_len = _accords.length;
        for (uint256 i; i < accords_len; ++i) {
            _accordsNameMap[_accords[i]] = _accordsName[i];
        }
    }

    function addAccordsWithData(uint256 which, uint256[2][] memory _accordsWithData, string[] memory _accordsName) public onlyOwner {
        require (_accordsWithData.length == _accordsName.length);
        uint256 accordsWithData_len = _accordsWithData.length;
        if (which == 0) { // top
            for (uint256 i; i < accordsWithData_len; ++i) {
                _topAccords.push(_accordsWithData[i]);
                _accordsNameMap[_accordsWithData[i][0]] = _accordsName[i];
            }
        } else if (which == 1) { // strong
            for (uint256 i; i < accordsWithData_len; ++i) {
                _strongAccords.push(_accordsWithData[i]);
                _accordsNameMap[_accordsWithData[i][0]] = _accordsName[i];
            }
        } else if (which == 2) { // mid
            for (uint256 i; i < accordsWithData_len; ++i) {
                _midAccords.push(_accordsWithData[i]);
                _accordsNameMap[_accordsWithData[i][0]] = _accordsName[i];
            }
        } else if (which == 3) { // weak
            for (uint256 i; i < accordsWithData_len; ++i) {
                _weakAccords.push(_accordsWithData[i]);
                _accordsNameMap[_accordsWithData[i][0]] = _accordsName[i];
            }
        } else {
            revert();
        }
    }

    function addSpecialFormulas(uint256[2][][] memory _formulas, uint8[8][] memory _filters) public onlyOwner {
        uint256 formulas_len = _formulas.length;
        for (uint256 i; i < formulas_len; ++i) {
            _specialFormulas.push(_formulas[i]);
            _specialFormulasFilter.push(_filters[i]);
        }
    }

// #####################################

    function _setPersonalInfo(uint256 tokenId, string memory tokenName, string memory description) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);
        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());
        require(bytes(tokenName).length < 12);
        require(bytes(description).length < 100);
        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();

        __tokenDetailedInfo[tokenId] = TokenDetailedInfo({tokenName: tokenName, description: description, IPLicense: ""});
    }

    function setPersonalInfo(uint256 tokenId, string memory tokenName, string memory description) external {
        _setPersonalInfo(tokenId, tokenName, description);
    }

    // metadata URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId));
        (TokenMintInfo memory tokenMintInfo, uint256 offset) = getTokenMintInfo(tokenId);
        if (tokenMintInfo.formulaType == 1) {
            return __tokenURI_random(tokenId, tokenMintInfo);
        } else if (tokenMintInfo.formulaType == 2) {
            return __tokenURI_special(tokenId, tokenMintInfo, offset);
        } else {
            return "";
        }
    }

    function __tokenURI_random(uint256 tokenId, TokenMintInfo memory tokenMintInfo) private view returns (string memory) {
        uint256 seed = uint256(keccak256(abi.encodePacked(tokenMintInfo.prevBlockHash, tokenId)));
        (uint256[] memory accords, uint256[] memory dis) = _accordsDistribution_random(seed, tokenMintInfo.accordsRange);
        string memory tokenName = bytes(__tokenDetailedInfo[tokenId].tokenName).length > 0 ? __tokenDetailedInfo[tokenId].tokenName : defaultTokenName;
        string memory description = bytes(__tokenDetailedInfo[tokenId].description).length > 0 ? __tokenDetailedInfo[tokenId].description : defaultDescription;
        (string memory name, string memory propertyJson) = _generateDesc(tokenId, tokenName, accords, dis);
        JSONGenerator.TokenUriParams memory tokenUriParams = JSONGenerator.TokenUriParams(name, description, propertyJson, _generateSVG(seed, accords, dis));
        return JSONGenerator.generateUri(tokenUriParams);
    }

    function __tokenURI_special(uint256 tokenId, TokenMintInfo memory tokenMintInfo, uint256 offset) private view returns (string memory) {
        (uint256[] memory accords, uint256[] memory dis) = _accordsDistribution_special(tokenMintInfo.formulaIdx + offset);
        string memory tokenName = bytes(__tokenDetailedInfo[tokenId].tokenName).length > 0 ? __tokenDetailedInfo[tokenId].tokenName : defaultTokenName;
        string memory description = bytes(__tokenDetailedInfo[tokenId].description).length > 0 ? __tokenDetailedInfo[tokenId].description : defaultDescription;
        (string memory name, string memory propertyJson) = _generateDesc(tokenId, tokenName, accords, dis);
        JSONGenerator.TokenUriParams memory tokenUriParams = JSONGenerator.TokenUriParams(name, description, propertyJson, _generateSVG_special(tokenMintInfo.formulaIdx + offset, accords, dis));
        return JSONGenerator.generateUri(tokenUriParams);
    }

    // minter
    function setMinter(address newMinter) public onlyOwner returns (address) {
        minter = newMinter;
        return minter;
    }

    // license
    function setIPLicense(string memory license) external onlyOwner {
        dafaultIPLicense = license;
    }

    function batchSetSpecialLicenses(uint256[] memory tokenIds, string[] memory licenses) external onlyOwner {
        uint256 len = tokenIds.length;
        require(len == licenses.length);
        for (uint256 i; i < len; ++i) {
            __tokenDetailedInfo[tokenIds[i]].IPLicense = licenses[i];
        }
    }

    // Token Info 

    function getOwnershipData(uint256 tokenId) public view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    function getTokenDetailedInfo(uint256 tokenId) public view returns (TokenDetailedInfo memory) {
        return __tokenDetailedInfo[tokenId];
    }

    function getTokenMintInfo(uint256 tokenId) public view returns (TokenMintInfo memory tokenMintInfo, uint256 offset) {
        uint256 curr = tokenId;
        offset = 0;
        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                tokenMintInfo = __tokenMintInfo[curr];
                if (!ownership.burned) {
                    if (tokenMintInfo.formulaType != 0) {
                        return (tokenMintInfo, offset);
                    }
                    while (true) {
                        --curr;
                        ++offset;
                        tokenMintInfo = __tokenMintInfo[curr];
                        if (tokenMintInfo.formulaType != 0) {
                            return (tokenMintInfo, offset);
                        }
                    }
                }
            }
        }
        revert();   
    }

    function burn(uint256 tokenId) public onlyMinter {
        _burn(tokenId);
    }

}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A is IERC721, IERC721Metadata {
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
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

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
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
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
        // Keeps track of burn count with minimal overhead for tokenomics.
        // uint64 numberBurned;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * 
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '../../Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

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
contract ERC721A is Context, ERC165, IERC721A {
    using Address for address;
    using Strings for uint256;

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
    function totalSupply() public view override returns (uint256) {
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
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    // function _numberBurned(address owner) internal view returns (uint256) {
    //     return uint256(_addressData[owner].numberBurned);
    // }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr) if (curr < _currentIndex) {
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

        if (_msgSender() != owner) if(!isApprovedForAll(owner, _msgSender())) {
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
        if (to.isContract()) if(!_checkContractOnERC721Received(from, to, tokenId, _data)) {
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
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal returns (uint256, uint256) {
        return _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal returns (uint256, uint256) {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
        return (startTokenId, quantity);
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
    function _mint(address to, uint256 quantity) internal returns (uint256, uint256) {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
        return (startTokenId, quantity);
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
            // addressData.numberBurned += 1;

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
     * @dev for example, 2,2 to 02; 3,3 to 003
     */
    function toFixedSizeString(uint256 value, uint256 size) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        require(size >= digits);
        bytes memory buffer = new bytes(size);
        for (uint8 i; i < size - digits; ++i) {
            buffer[i] = bytes1(uint8(48));
        }
        digits = size;
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

    function subString(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        // abcdefg  2-5 cdef  0123
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex+1);
        for(uint i = startIndex; i <= endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Strings.sol";

library PRFAndSort {
    using Strings for uint256;

    function pseudorandom_hash(bytes memory seed, uint m) internal pure returns (uint r) {
        unchecked {
            r = uint(keccak256(abi.encodePacked(seed, "EtherScent")))%m;
        }
    }

    function pseudorandom_hash(uint seed, uint m) internal pure returns (uint r) {
        r = pseudorandom_hash(abi.encodePacked(seed.toString()), m);
    }

    function pseudorandom_hash(uint seed, uint min, uint max) internal pure returns (uint r) {
        r = pseudorandom_hash(seed, max+1-min) + min;
    }

    function pseudorandom_array(uint seed, uint q, uint min, uint max) internal pure returns (uint[] memory) {
        require(max > min);
        uint[] memory arr = new uint[](q);
        uint i;
        uint j;
        while (i < q) {
            uint r = pseudorandom_hash(seed + j, max+1-min) + min;
            bool duplicate = _checkDuplicate(arr, i, r);
            if (duplicate) {
                ++j;
                continue;
            }
            arr[i] = r;
            ++i;
            ++j;
        }
        return arr;
    }

    function pseudorandom_array_with_fix_sum(uint seed, uint q, uint s) internal pure returns (uint[] memory) {
        uint[] memory arr = new uint[](q+1);
        uint i;
        uint j;
        while (arr[q-2] == 0) {
            uint r = pseudorandom_hash(seed+j, s-1) + 1;
            bool duplicate = _checkDuplicate(arr, i, r);
            if (duplicate) {
                ++j;
                continue;
            }
            arr[i] = r;
            ++i;
            ++j;
        }
        arr[q-1] = uint(0);
        arr[q] = s;
        arr = _getDiffArray(arr);
        return arr;
    }

    function _checkDuplicate(uint[] memory arr, uint i, uint r) private pure returns (bool) {
        for (uint i_; i_ < i; ++i_) {
            if (arr[i_] == r) {
                return true;
            }
        }
        return false;
    }

    function _getDiffArray(uint[] memory arr) private pure returns (uint[] memory) {
        uint q_ = arr.length - 1;
        uint[] memory resArr = new uint[](q_);
        arr = quickSort(arr);
        uint i;
        uint j = 1;
        while (j <= q_) {
            resArr[i] = arr[i] - arr[j];
            ++i;
            ++j;
        }
        return resArr;
    }

    function _quickSort(uint[] memory arr, int left, int right) private pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] > pivot) ++i;
            while (pivot > arr[uint(j)]) --j;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                ++i;
                --j;
            }
        }
        if (left < j)
            _quickSort(arr, left, j);
        if (i < right)
            _quickSort(arr, i, right);
    }

    function quickSort(uint[] memory arr) internal pure returns (uint[] memory) {
        _quickSort(arr, int(0), int(arr.length-1));
        return arr;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Base64.sol";

library JSONGenerator {
    struct TokenUriParams {
        string name;
        string desc;
        string propertyJson;
        string svg;
    }

    function generateUri(TokenUriParams memory params) internal pure returns (string memory tokenUri) {
        string memory svg = generateSvg(params);
        tokenUri = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', params.name, '","description":"', params.desc, '",', params.propertyJson, '"image":"', 'data:image/svg+xml;base64,', svg, '"}')
                    )
                )
            )
        );
    }

    function generateSvg(TokenUriParams memory params) internal pure returns (string memory svg) {
        svg = Base64.encode(bytes(params.svg));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./libs/PRFAndSort.sol";

contract EtherscentSVGFilters {
    using Strings for uint256;

    uint8[8][] internal _specialFormulasFilter;

    function ___getTableValues(uint256 tv_times) private pure returns (string memory tv) {
        bytes4 v = "0 1 ";
        for (uint256 i; i < tv_times; ++i) {
            tv = string(abi.encodePacked(tv, v));
        }
    }

    function __pickFilterParams(uint256 seed) private pure returns (uint256 bf, uint256 xs, uint256 ys, uint256 sc, uint256 std, uint256 tv_times) {
        bf = PRFAndSort.pseudorandom_hash(seed >> 16, 0, 30);
        xs = PRFAndSort.pseudorandom_hash(seed >> 24, 4);
        ys = PRFAndSort.pseudorandom_hash(seed >> 32, 4);
        sc = PRFAndSort.pseudorandom_hash(seed >> 40, 10, 250);
        std = PRFAndSort.pseudorandom_hash(seed >> 48, 0, 15);
        tv_times = PRFAndSort.pseudorandom_hash(seed >> 56, 1, 4);
    }

    function ___feMerge() private pure returns (string memory) {
        return "<feMerge result='text'><feMergeNode in='SourceGraphic'/></feMerge>";
    }

    function __generateFilters(uint256 bf, uint256 xs, uint256 ys, uint256 sc, uint256 std, uint256 tv_times) private pure returns (string memory filters) {
        bytes4 kws = "RGBA";
        filters = string(abi.encodePacked(
            "<filter id='f1'>",
            ___feMerge(),
            "<feTurbulence type='fractalNoise' baseFrequency='0.",
            bf.toFixedSizeString(2),
            "7' numOctaves='1' result='warp'/><feDisplacementMap xChannelSelector='",
            kws[xs],
            "' yChannelSelector='",
            kws[ys],
            "' scale='",
            sc.toString(),
            "' in='text' in2='warp'/></filter><filter id='f2'>",
            ___feMerge(),
            "<feGaussianBlur stdDeviation='",
            std.toString(),
            "' edgeMode='duplicate'/><feComponentTransfer><feFuncA type='discrete' tableValues='",
            ___getTableValues(tv_times),
            "'/></feComponentTransfer></filter>"
        ));
    }

    function _generateFilters(uint256 seed) internal pure returns (string memory filters) {
        (uint256 bf, uint256 xs, uint256 ys, uint256 sc, uint256 std, uint256 tv_times) = __pickFilterParams(seed);
        filters = __generateFilters(bf, xs, ys, sc, std, tv_times);
    }

    function _generateFilters_special(uint256 idx) internal view returns (string memory filters) {
        (uint256 bf, uint256 xs, uint256 ys, uint256 sc, uint256 std, uint256 tv_times) = (
            _specialFormulasFilter[idx][2],
            _specialFormulasFilter[idx][3],
            _specialFormulasFilter[idx][4],
            _specialFormulasFilter[idx][5],
            _specialFormulasFilter[idx][6],
            _specialFormulasFilter[idx][7]
        );
        filters = __generateFilters(bf, xs, ys, sc, std, tv_times);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./libs/PRFAndSort.sol";

contract EtherscentSVGCSS {
    using Strings for uint256;

    function __cssHeader() private pure returns (string memory) {
        return "<style type='text/css'>";
    }

    function __cssFooter() private pure returns (string memory) {
        return "</style>";
    }
    
    function __cssMainPart(uint256[] memory accords) private pure returns (string memory css_colors) {
        uint256 accords_len = accords.length;
        for (uint256 i; i < accords_len; ++i) {
            css_colors = string(abi.encodePacked(css_colors, ".c", i.toString(), "{fill:#", Strings.subString(accords[i].toHexString(), 2, 7), ";}"));
        }
        css_colors = string(abi.encodePacked(css_colors, ".b{fill:none;}"));
    }

    function _generateCSS(uint256[] memory accords) internal pure returns (string memory css) {
        css = string(abi.encodePacked(__cssHeader(), __cssMainPart(accords), __cssFooter()));
    } 
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./EtherscentSVGFilters.sol";
import "./EtherscentSVGCSS.sol";

contract EtherscentSVG is EtherscentSVGFilters, EtherscentSVGCSS {
    using Strings for uint256;

    function __getHeader() private pure returns (string memory header) {
        header = string(abi.encodePacked("<svg version='1' xmlns='http://www.w3.org/2000/svg' x='0px' y='0px' viewBox='0 0 503 653' style='enable-background:new 0 0 503 653;'>"));
    }

    function __getFooter() private pure returns (string memory footer) {
        footer = "</g><rect class='b' width='503' height='653'/></svg>";
    }

    function __x_y(uint256 n, uint256 r, uint256 d, uint256 sx, uint256 sy) private pure returns (uint256 x, uint256 y) {
        unchecked {
            if (n % r < r/2+1) {
                x = sx + d*2*(n%r);
                y = sy + d*2*(n/r);
            } else {
                y = sy + d + d*2*((n-r/2)/r);
                x = sx + d + d*2*((n-r/2)%r-1);
            }
        }
    }

    function __getFilterSequence(uint256 seed) private pure returns (uint256 f1, uint256 f2) {
        uint256 flag = PRFAndSort.pseudorandom_hash(seed >> 8, 11);
        if (flag >= 0 && flag < 4) {
            (f1,f2) = (1,2);
        } else if (flag >= 4 && flag < 8 ) {
            (f1,f2) = (2,1);
        } else if (flag >= 8 && flag < 10) {
            (f1,f2) = (1,1);
        } else {
            (f1,f2) = (2,0);
        }
    }

    function __getTransmission(uint256 f1, uint256 f2) private pure returns (string memory transmission) {
        transmission = string(abi.encodePacked(
            "<g filter='url(#f",
            f1.toString(),
            ") url(#f",
            f2.toString(),
            ")'>"
        ));
    }

    function __generateRect(uint256[] memory dis) private pure returns (string memory rects) {
        // [3,5,6,8,9,11]
        uint256 dis_len = dis.length;
        uint256 n;
        uint256 q;
        for (uint256 i; i < dis_len; ++i) {
            q = dis[i];
            for (uint256 j; j < q; ++j) {
                (uint256 x, uint256 y) = __x_y(n, 13, 37, 11, 12); // n,r,d,sx,sy
                rects = string(abi.encodePacked(rects, "<rect x='", x.toString(), ".1'", " y='", y.toString(), ".1' width='37' height='37' class='c", i.toString(), "'/>"));
                ++n;
            }
        }
    }

    function _generateSVG(uint256 seed, uint256[] memory accords, uint256[] memory dis) internal pure returns (string memory) {
        // require(accords.length == dis.length);
        (uint256 f1, uint256 f2) = __getFilterSequence(seed);
        return string(
            abi.encodePacked(
                __getHeader(),
                _generateCSS(accords),
                _generateFilters(seed),
                __getTransmission(f1, f2),
                __generateRect(dis),
                __getFooter()
            )
        );
    }

    function _generateSVG_special(uint256 idx, uint256[] memory accords, uint256[] memory dis) internal view returns (string memory) {
        // require(accords.length == dis.length);
        return string(
            abi.encodePacked(
                __getHeader(),
                _generateCSS(accords),
                _generateFilters_special(idx),
                __getTransmission(
                    _specialFormulasFilter[idx][0],
                    _specialFormulasFilter[idx][1]
                ),
                __generateRect(dis),
                __getFooter()
            )
        );
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./libs/Strings.sol";

contract EtherscentDesc {
    using Strings for uint256;

    mapping(uint256 => string) internal _accordsNameMap;

    function _generateDesc(uint256 tokenId, string memory tokenName, uint256[] memory accords, uint256[] memory dis) internal view  returns (string memory name, string memory propertyJson) {
        name = string(abi.encodePacked(tokenName, " #", tokenId.toString()));
        propertyJson = __generatePropertyJson(accords, dis);
    }

    function __generatePropertyJson(uint256[] memory accords, uint256[] memory dis) private view returns (string memory propertyJson) {
        uint256 len = accords.length;
        propertyJson = '"attributes":[';
        for (uint256 i; i < len; ++i) {
            propertyJson = string(abi.encodePacked(propertyJson, '{"trait_type":"', _accordsNameMap[accords[i]], '","value":"', dis[i].toString(), '"}'));
            if (i != len - 1) propertyJson = string(abi.encodePacked(propertyJson, ','));
        }
        propertyJson = string(abi.encodePacked(propertyJson, '],'));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./libs/PRFAndSort.sol";

contract EtherscentAccordsDistribution {
    uint256[2][] internal _topAccords;
    uint256[2][] internal _strongAccords;
    uint256[2][] internal _midAccords;
    uint256[2][] internal _weakAccords;

    struct AccordsQuantity {
        uint256 topQuantity;
        uint256 strongQuantity;
        uint256 midQuantity;
        uint256 weakQuantity;
        uint256 sumQuantity;
    }

    struct AccordsRange {
        uint256 topRange;
        uint256 strongRange;
        uint256 midRange;
        uint256 weakRange;
    }

    /*
    [
        [
            [#color, quantity],[#color2, quantity]
        ],
        [
            [#color3, quantity]
        ],
    ]
    */
    // uint256[2][][] internal _preparedFormulas;
    uint256[2][][] internal _specialFormulas;

    function __pickAccordsQuantities(uint256 seed) private pure returns (AccordsQuantity memory q) {
        uint8[6] memory accordsQuantities = [5,6,7,8,9,10];
        uint256 r = PRFAndSort.pseudorandom_hash(seed >> 2, 6);
        q.sumQuantity = accordsQuantities[r];
        q.topQuantity = 1;
        q.strongQuantity = (q.sumQuantity-1)/4;
        q.midQuantity = (q.sumQuantity+1)/4+1;
        q.weakQuantity = q.sumQuantity/2-1;
    }

    function ____sum(uint256[2][] memory arr) private pure returns (uint256 sum) {
        uint256 arr_len = arr.length;
        for (uint256 i; i < arr_len; ++i) {
            sum += arr[i][1];
        }
    }

    function ____contains(uint256[] memory arr, uint256 currentIdx, uint256 element) private pure returns (bool contained) {
        for (uint256 i; i < currentIdx; ++i) {
            if (arr[i] == element) {
                contained = true;
                break;
            }
        }
    }

    function ___loop(uint256 seed, uint256[] memory res, uint256 currentIdx, uint256[2][] memory arr, uint256 range) private pure returns (uint256 target) {
        uint32 tag = 1;
        uint256 rd;
        uint256 s;
        while (true) {
            rd = (seed / tag) % (____sum(arr)) + 1;
            s = 0;
            for (uint8 i; i < range; ++i) {
                s += arr[i][1];
                if (s >= rd) {
                    target = arr[i][0];
                    break;
                }
            }
            if (!____contains(res, currentIdx, target)) {
                break;
            }
            ++tag;
        }
    }

    function __pickAccords(uint256 seed, AccordsQuantity memory q, AccordsRange memory range) private view returns (uint256[] memory resAccords) {
        resAccords = new uint[](q.sumQuantity);
        resAccords[0] = ___loop(seed, resAccords, 0, _topAccords, range.topRange);
        for (uint256 i=1; i <= q.strongQuantity; ++i) {
            resAccords[i] = ___loop(seed+i, resAccords, i, _strongAccords, range.strongRange);
        }
        for (uint256 i=q.strongQuantity+1; i <= q.strongQuantity+q.midQuantity; ++i) {
            resAccords[i] = ___loop(seed+i, resAccords, i, _midAccords, range.midRange);
        }
        for (uint256 i=q.strongQuantity+q.midQuantity+1; i <= q.strongQuantity+q.midQuantity+q.weakQuantity; ++i) {
            resAccords[i] = ___loop(seed+i, resAccords, i, _weakAccords, range.weakRange);
        }
    }

    function __pickDistribution(uint256 seed, AccordsQuantity memory q, uint256 s) private pure returns (uint256[] memory dis) {
        dis = PRFAndSort.pseudorandom_array_with_fix_sum(seed >> 4, q.sumQuantity, s);
        dis = PRFAndSort.quickSort(dis);
    }

    function _accordsDistribution_random(uint256 seed, AccordsRange memory range) internal view returns (uint256[] memory accords, uint256[] memory dis) {
        AccordsQuantity memory q = __pickAccordsQuantities(seed);
        accords = __pickAccords(seed, q, range);
        dis = __pickDistribution(seed, q, 111);
    }

    function _accordsDistribution_special(uint256 idx) internal view returns (uint256[] memory accords, uint256[] memory dis) {
        uint256[2][] memory accordsWithQuantity = _specialFormulas[idx];
        uint256 accordsWithQuantity_len = accordsWithQuantity.length;
        accords = new uint256[](accordsWithQuantity_len);
        dis = new uint256[](accordsWithQuantity_len);
        for (uint256 i; i < accordsWithQuantity_len; ++i) {
            accords[i] = accordsWithQuantity[i][0];
            dis[i] = accordsWithQuantity[i][1];
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