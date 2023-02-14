/**
 *Submitted for verification at Etherscan.io on 2023-02-13
*/

// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.18;

interface iStacks {
    function getPiecesPerStack() external view returns(uint);
    function getOwnedPieces(address _owner) external view returns (bytes32[] memory);
    function getPieceCode(uint tokenId) external view returns (string memory);
    function getPieceRarity(uint tokenId) external view returns (uint);
    function getAllPieces() external view returns (bytes32[] memory common,
                                                    bytes32[] memory uncommon,
                                                    bytes32[] memory rare);
    function getStacksForEdition(uint edition) external view returns (bytes32[] memory);
}

contract protected {
    mapping (address => bool) is_auth;
    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }
    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }
    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }
    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }
    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }
    function change_owner(address new_owner) public onlyAuth {
        owner = new_owner;
    }
    receive() external payable {}
    fallback() external payable {}
}

// SECTION Interfaces
interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC721 is ERC165 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

interface IERC721Receiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}
// !SECTION Interfaces

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error UnableDetermineTokenOwner();
error UnableGetTokenOwnerByIndex();
error URIQueryForNonexistentToken();

/**
 * @notice Updated, minimalist and gas efficient version of OpenZeppelins ERC721 contract.
 *         Includes the Metadata and Enumerable extension.
 *
 * @dev Token IDs are minted  in sequential order starting at 0 (e.g. 0, 1, 2, ...).
 *      Does not support burning tokens.
 *
 * @author beskay0x
 * Credits: chiru-labs, solmate, transmissions11, nftchance, squeebo_nft and others
 */

contract RBT_NFT is ERC721, protected {

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name = "White Rabbit NFT";
    string public symbol = "RBTNFT";
    
    string public baseURI = "https://whiterabbit.mypinata.cloud/ipfs/";
    mapping (uint256 => string) private _tokenURIs;

    function setBaseURI(string memory _baseURI) public onlyAuth {
        baseURI = _baseURI;
    }

    function setTokenURIHash(uint256 tokenId, string memory _tokenURI) public onlyAuth {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "URIQueryForNonexistentToken");
        string memory _tokenId = _tokenURIs[tokenId];
        return string(abi.encodePacked(baseURI, _tokenId));
    }
    /*///////////////////////////////////////////////////////////////
                          ERC721 STORAGE
    //////////////////////////////////////////////////////////////*/

    // Array which maps token ID to address (index is tokenID)
    address[] internal _owners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        owner = msg.sender;
        is_auth[msg.sender] = true;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x780e9d63 || // ERC165 Interface ID for ERC721Enumerable
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       ERC721ENUMERABLE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * It is not recommended to call this function on chain from another smart contract,
     * as it can become quite expensive for larger collections.
     */
    function tokenOfOwnerByIndex(address _owner, uint256 index) public view virtual returns (uint256 tokenId) {
        if (index >= balanceOf(_owner)) revert OwnerIndexOutOfBounds();

        uint256 count;
        uint256 qty = _owners.length;
        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (tokenId; tokenId < qty; tokenId++) {
                if (_owner == ownerOf(tokenId)) {
                    if (count == index) return tokenId;
                    else count++;
                }
            }
        }

        revert UnableGetTokenOwnerByIndex();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        if (index >= totalSupply()) revert TokenIndexOutOfBounds();
        return index;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     *      Iterates through _owners array -- it is not recommended to call this function
     *      from another contract, as it can become quite expensive for larger collections.
     */
    function balanceOf(address _owner) public view virtual returns (uint256) {
        if (_owner == address(0)) revert BalanceQueryForZeroAddress();

        uint256 count;
        uint256 qty = _owners.length;
        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (uint256 i; i < qty; i++) {
                if (_owner == ownerOf(i)) {
                    count++;
                }
            }
        }
        return count;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     *      Gas spent here starts off proportional to the maximum mint batch size.
     *      It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();

        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (tokenId; ; tokenId++) {
                if (_owners[tokenId] != address(0)) {
                    return _owners[tokenId];
                }
            }
        }

        revert UnableDetermineTokenOwner();
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        address _owner = ownerOf(tokenId);
        if (to == _owner) revert ApprovalToCurrentOwner();

        if (msg.sender != _owner && !isApprovedForAll(_owner, msg.sender)) revert ApprovalCallerNotOwnerNorApproved();

        _tokenApprovals[tokenId] = to;
        emit Approval(_owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        if (operator == msg.sender) revert ApproveToCaller();

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address _owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[_owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();
        if (ownerOf(tokenId) != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        bool isApprovedOrOwner = (msg.sender == from ||
            msg.sender == getApproved(tokenId) ||
            isApprovedForAll(from, msg.sender));
        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();

        // delete token approvals from previous owner
        delete _tokenApprovals[tokenId];
        _owners[tokenId] = to;

        // if token ID below transferred one isnt set, set it to previous owner
        // if tokenid is zero, skip this to prevent underflow
        if (tokenId > 0 && _owners[tokenId - 1] == address(0)) {
            _owners[tokenId - 1] = from;
        }

        emit Transfer(from, to, tokenId);
    }

    function _internalTransfer(address from, address to, uint tokenId) internal {
        if (_owners[tokenId] != from) revert TransferFromIncorrectOwner();
        if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();

        // delete token approvals from previous owner
        delete _tokenApprovals[tokenId];
        _owners[tokenId] = to;

        // if token ID below transferred one isnt set, set it to previous owner
        // if tokenid is zero, skip this to prevent underflow
        if (tokenId > 0 && _owners[tokenId - 1] == address(0)) {
            _owners[tokenId - 1] = from;
        }

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        safeTransferFrom(from, to, id, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        if (!_checkOnERC721Received(from, to, id, data)) revert TransferToNonERC721ReceiverImplementer();
    }

    /**
     * @dev Returns whether `tokenId` exists.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _owners.length;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     *      The call is not executed if the target address is not a contract.
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
        if (to.code.length == 0) return true;

        try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) revert TransferToNonERC721ReceiverImplementer();

            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Safely mints `qty` tokens and transfers them to `to`.
     *
     *      If `to` refers to a smart contract, it must implement
     *      {IERC721Receiver-onERC721Received}
     *
     *      Unlike in the standard ERC721 implementation {IERC721Receiver-onERC721Received}
     *      is only called once. If the receiving contract confirms the transfer of one token,
     *      all additional tokens are automatically confirmed too.
     */
    function _safeMint(address to, uint256 qty) internal virtual {
        _safeMint(to, qty, '');
    }

    /**
     * @dev Equivalent to {safeMint(to, qty)}, but accepts an additional data argument.
     */
    function _safeMint(
        address to,
        uint256 qty,
        bytes memory data
    ) internal virtual {
        _mint(to, qty);

        if (!_checkOnERC721Received(address(0), to, _owners.length - 1, data))
            revert TransferToNonERC721ReceiverImplementer();
    }

    /**
     * @dev Mints `qty` tokens and transfers them to `to`.
     *      Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 qty) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (qty == 0) revert MintZeroQuantity();

        uint256 _currentIndex = _owners.length;

        // Cannot realistically overflow, since we are using uint256
        unchecked {
            for (uint256 i; i < qty - 1; i++) {
                _owners.push();
                emit Transfer(address(0), to, _currentIndex + i);
            }
        }

        // set last index to receiver
        _owners.push(to);
        emit Transfer(address(0), to, _currentIndex + (qty - 1));
    }

    // SECTION Completion methods

    address public StackNFTAddress;
    iStacks public StackNFT;

    struct COMPOSED_NFT {
        bytes32[] tokenPieces;
        bool composed;
    }

    mapping (uint256 => COMPOSED_NFT) composedNFTs; // composedNFTs[tokenId] = COMPOSED_NFT

    // ANCHOR Public methods

    function getComposedNFT(uint256 tokenId) public view returns (bytes32[] memory pieces, 
                                                                    bool composed,
                                                                    address owner) {
        return (composedNFTs[tokenId].tokenPieces,
                composedNFTs[tokenId].composed,
                ownerOf(tokenId));
    }

    // NOTE This function is called to have a list of all the composed NFTs available and not available
    function getAllComposedNFTs() external view returns (bytes32[] memory _composedNFTs, 
                                                          bytes32[] memory _inactiveComposedNFTs) { 
        uint256 _length = _owners.length;
        _composedNFTs = new bytes32[](_length);
        _inactiveComposedNFTs = new bytes32[](_length);
        for (uint256 i = 0; i < _length; i++) {
            // Check if the NFT is yet to compose
            if (!composedNFTs[i].composed) {
                _composedNFTs[i] = composedNFTs[i].tokenPieces[0];
            } else {
                _inactiveComposedNFTs[i] = composedNFTs[i].tokenPieces[0];
            }
        }
        // Delete empty elements
        uint256 _composedNFTsLength = 0;
        uint256 _inactiveComposedNFTsLength = 0;
        for (uint256 i = 0; i < _length; i++) {
            if (_composedNFTs[i] != bytes32(0)) {
                _composedNFTs[_composedNFTsLength] = _composedNFTs[i];
                _composedNFTsLength++;
            }
            if (_inactiveComposedNFTs[i] != bytes32(0)) {
                _inactiveComposedNFTs[_inactiveComposedNFTsLength] = _inactiveComposedNFTs[i];
                _inactiveComposedNFTsLength++;
            }
        }
        assembly {
            mstore(_composedNFTs, _composedNFTsLength)
            mstore(_inactiveComposedNFTs, _inactiveComposedNFTsLength)
        }
    }


    // NOTE This function should be called by the owner of all the pieces of the NFT
    function composeNFT(uint256 tokenId) external safe {
        // Check if the NFT is not already composed
        require(!composedNFTs[tokenId].composed, "NFT already composed");
        // Check if the owner of the NFT is the owner of all the pieces
        bool _allPiecesOwned = _hasAllPieces(tokenId, msg.sender);
        // Transfer the NFT to the owner of the pieces
        if (_allPiecesOwned) {
            composedNFTs[tokenId].composed = true;
            _internalTransfer(address(this), msg.sender, tokenId);
        } else {
            revert("You don't own all the pieces of the NFT");
        }
    }

    function hasAllPieces(uint256 tokenId) public view returns (bool) {
        return _hasAllPieces(tokenId, msg.sender);
    }

    function _hasAllPieces(uint256 tokenId, address _owner) internal view returns (bool) {
        bytes32[] memory _tokenPieces = composedNFTs[tokenId].tokenPieces;
        bytes32[] memory _ownedPieces = StackNFT.getOwnedPieces(_owner);
        // Check if the owner of the NFT is the owner of all the pieces of the NFT
        bool _allPiecesOwned = true;
        for (uint i = 0; i < _tokenPieces.length; i++) { // For each piece of the NFT
            bool _pieceOwned = false; // Each piece starts as not owned
            for (uint j = 0; j < _ownedPieces.length; j++) { // For each piece owned
                if (_tokenPieces[i] == _ownedPieces[j]) {
                    _pieceOwned = true; // If the piece is found, we proceed to the next piece
                    break;
                }
            }
            if (!_pieceOwned) {
                _allPiecesOwned = false; // If even one piece is not owned, we stop the loop
                break;
            }
        }
        return _allPiecesOwned;
    }

    // ANCHOR Admin methods

    function setStackNFTAddress(address _address) external onlyOwner {
        StackNFTAddress = _address;
        StackNFT = iStacks(_address);
    }

    // NOTE This creates and store in the contract the composed NFT
    function createComposedNFT(bytes32[] memory tokenPieces) external onlyOwner {
        require(tokenPieces.length == 6, "Invalid number of pieces");
        uint256 tokenId = _owners.length;
        _mint(address(this), 1);
        composedNFTs[tokenId] = COMPOSED_NFT(tokenPieces, false);
    }

    // NOTE This creates and store in the contract the composed NFT automatically
    function createComposedNFTAuto(uint seed) external onlyOwner {
        uint piecesNumber = 6;
        uint256 tokenId = _owners.length;
        // Getting the pieces from the StackNFT contract
        bytes32[] memory _common;
        bytes32[] memory _uncommon;
        bytes32[] memory _rare;
        (_common, _uncommon, _rare) = StackNFT.getAllPieces();
        // Select randomly 1 rare 2 uncommon and 3 common pieces
        bytes32[] memory tokenPieces = new bytes32[](piecesNumber);
        tokenPieces[0] = _rare[uint(keccak256(abi.encodePacked(seed))) % _rare.length];
        tokenPieces[1] = _uncommon[uint(keccak256(abi.encodePacked(seed + 1))) % _uncommon.length];
        tokenPieces[2] = _uncommon[uint(keccak256(abi.encodePacked(seed + 2))) % _uncommon.length];
        tokenPieces[3] = _common[uint(keccak256(abi.encodePacked(seed + 3))) % _common.length];
        tokenPieces[4] = _common[uint(keccak256(abi.encodePacked(seed + 4))) % _common.length];
        tokenPieces[5] = _common[uint(keccak256(abi.encodePacked(seed + 5))) % _common.length];
        // Store the NFT
        composedNFTs[tokenId] = COMPOSED_NFT(tokenPieces, false);
        _mint(address(this), 1);
    }

    // !SECTION Completion methods

    // String manipulation functions
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}