/**
 *Submitted for verification at Etherscan.io on 2022-09-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param owner An address for whom to query the balance
    /// @return The number of NFTs owned by `owner`, possibly zero
    function balanceOf(address owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 tokenId) external view returns (address);

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param operator Address to add to the set of authorized operators
    /// @param approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address operator, bool approved) external;
    
    /// @notice Query if an address is an authorized operator for another address
    /// @param owner The address that owns the NFTs
    /// @param operator The address that acts on behalf of the owner
    /// @return True if `operator` is an approved operator for `owner`, false otherwise
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param approved The new approved NFT controller
    /// @param tokenId The NFT to approve
    function approve(address approved, uint256 tokenId) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `tokenId` is not a valid NFT.
    /// @param tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 tokenId) external view returns (address);

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `from` is
    ///  not the current owner. Throws if `to` is the zero address. Throws if
    ///  `tokenId` is not a valid NFT.
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param tokenId The NFT to transfer
    function transferFrom(address from, address to, uint256 tokenId) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `from` is
    ///  not the current owner. Throws if `to` is the zero address. Throws if
    ///  `tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `to`
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param tokenId The NFT to transfer
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceId` and
    ///  `interfaceId` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param operator The address which called `safeTransferFrom` function
    /// @param from The address which previously owned the token
    /// @param tokenId The NFT identifier which is being transferred
    /// @param data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) external returns(bytes4);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/**
    Note: The ERC-165 identifier for this interface is 0x0e89341c.
*/
interface IERC1155Metadata_URI {
    /**
        @notice A distinct Uniform Resource Identifier (URI) for a given token.
        @dev URIs are defined in RFC 3986.
        The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".        
        @return URI string
    */
    function uri(uint256 tokenId) external view returns (string memory);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface IERC721Enumerable /* is ERC721 */ {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `index` >= `totalSupply()`.
    /// @param index A counter less than `totalSupply()`
    /// @return The token identifier for the `index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `index` >= `balanceOf(owner)` or if
    ///  `owner` is the zero address, representing invalid NFTs.
    /// @param owner An address where we are interested in NFTs owned by them
    /// @param index A counter less than `balanceOf(owner)`
    /// @return The token identifier for the `index`th NFT assigned to `owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

abstract contract ERC721 is IERC165, IERC721, IERC721Metadata, IERC1155Metadata_URI, IERC721Enumerable {

    mapping(address => uint256) _balances;      // owner => balance
    mapping(uint => address) _owners;           // tokenId => owner
    mapping(address => mapping(address => bool)) _operatorApprovals;    // owner => (operator => allow)
    mapping(uint => address) _tokenApprovals;    // tokenId => operator

    string _name;
    string _symbol;
    mapping (uint => string) _tokenUris;         // token => uri

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        return _tokenUris[tokenId];
    }

    function uri(uint256 tokenId) public override view returns (string memory) {
        return tokenURI(tokenId);
    }


    function supportsInterface(bytes4 interfaceId) public override pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId || 
               interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               interfaceId == type(IERC1155Metadata_URI).interfaceId ||
               interfaceId == type(IERC721Enumerable).interfaceId;
    }

    function balanceOf(address owner) public override view returns (uint256) {
        require(owner != address(0), "owner is zero address");

        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public override view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "token is not exists");
        
        return owner;
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(msg.sender != operator, "approval status for self");

        _operatorApprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);

    }

    function isApprovedForAll(address owner, address operator) public override  view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function approve(address approved, uint256 tokenId) public override  {
        address owner = ownerOf (tokenId);
        require(approved != owner, "approval status of salf");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "caller is not token owner or approval for all");

        _approve(approved, tokenId);
    }


    function getApproved(uint256 tokenId) public override  view returns (address) {
        require(_owners[tokenId] != address(0), "token is not exists");

        return _tokenApprovals[tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override  {
        require(from != address(0), "transfer form zero adress");
        require(to != address(0), "transfer to zero adress");

        address owner = ownerOf(tokenId);
        require(owner == from, "transfer from is not token owner");

        require(msg.sender == owner || msg.sender == getApproved(tokenId) || isApprovedForAll(owner, msg.sender), "caller is not owner or approval" );


        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        transferFrom(from, to, tokenId); 
        require(_checkOnErc721Resived(from, to, tokenId, data), "transfer to non ERC721Resiver implimenter");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function totalSupply() public override view returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public override view returns (uint256) {
        require(index < _allTokens.length-1, "index out of bounds");
        return _allTokens[index];
    }
    
    function tokenOfOwnerByIndex(address owner, uint256 index) public override view returns (uint256) {
        require(index < _balances[owner], "index out of bounds");
        return _ownedTokens[owner][index];
    }

    // === Private or Interanl Function ===
    function _approve(address to, uint tokenId) internal {
        _tokenApprovals[tokenId] = to;
        address owner =  ownerOf(tokenId);

        emit Approval(owner, to, tokenId);
    }

    function _checkOnErc721Resived(address from, address to, uint tokenId, bytes memory data) private returns (bool) {
        if (to.code.length <= 0) return true;

        IERC721TokenReceiver receiver = IERC721TokenReceiver(to); 

        try receiver.onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 interfaceId) {
            return interfaceId == type(IERC721TokenReceiver).interfaceId;
        } catch Error(string memory reason) {
            revert(reason);
        } catch {
            revert("transfer  to non ERC721Resiver implimenter");
        }
    }
    
    function _mint(address to, uint tokenId, string memory uri_) internal {
        require(to != address(0), "mint to zero address");
        require( _owners[tokenId] == address(0), "token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;
        _tokenUris[tokenId] = uri_;

        emit Transfer(address(0), to, tokenId);

        _addTokenToAllEnumeration(tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);

    }

    function _safeMint(address to, uint tokenId, string memory uri_, bytes memory data) internal {
        _mint(to, tokenId, uri_);

        require(_checkOnErc721Resived(address(0), to, tokenId, data), "mint  to non ERC721Resiver implimenter");        
    }

    function _safeMint(address to, uint tokenId, string memory uri_) internal {
       _safeMint(to, tokenId, uri_, "");
    }

    function _burn(uint tokenId) internal {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || msg.sender == getApproved(tokenId) || isApprovedForAll(owner, msg.sender), "caller is not owner or approval" );

        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];
        delete _tokenUris[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _removeTokenFromAllEnumeration(tokenId);
        _removeTokenFromOwnerEnumeration(owner, tokenId);
    }

    // All Enumeration
    uint[] _allTokens;
    mapping(uint => uint) _allTokensIndex;   // tokenId => index

    function _addTokenToAllEnumeration(uint tokenId) private {
        _allTokens.push(tokenId);
        _allTokensIndex[tokenId] = _allTokens.length - 1;
    }

    function _removeTokenFromAllEnumeration(uint tokenId) private {
        uint index = _allTokensIndex[tokenId];
        uint indexLast = _allTokens.length - 1;

        if (index < indexLast) {
            uint idLast = _allTokensIndex[indexLast];
            _allTokens[index] = idLast;
            _allTokensIndex[idLast] = index;
        }

        _allTokens.pop();
        delete _allTokensIndex[tokenId];
    }


    // Owner Enumeration
    mapping(address => mapping(uint => uint)) _ownedTokens;     // owner => (index => tokenId)
    mapping(uint => uint) _ownedTokensIndex;   // tokenId => index
    
    function _addTokenToOwnerEnumeration(address owner, uint tokenId) private {
        uint index = _balances[owner] - 1;
        _ownedTokens[owner][index] = tokenId;
        _ownedTokensIndex[tokenId] = index;
    }

    function _removeTokenFromOwnerEnumeration(address owner, uint tokenId) private {
        uint index = _ownedTokensIndex[tokenId];
        uint indexLast = _balances[owner];

        if (index < indexLast) {
            uint idLast = _ownedTokens[owner][indexLast];
            
            _ownedTokens[owner][index] = idLast;
            _ownedTokensIndex[idLast] = index;
        }

        delete _ownedTokens[owner][indexLast];
        delete _ownedTokensIndex[tokenId];
    }         
}

contract INFT is ERC721 {
    constructor() ERC721("INF Collectibles", "INFT") {

    }


    function create(uint tokenId, string memory uri) public {
        _mint(msg.sender, tokenId,  uri);
    }

    function burn(uint tokenId) public {
        _burn(tokenId);
    }
}