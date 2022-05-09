// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./interfaces/IERC165.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Metadata.sol";
import "./interfaces/IERC721Enumerable.sol";
import "./interfaces/IERC721Receiver.sol";

contract ERC721 is IERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    address payable public manager;
    string public name;
    string public symbol;
    
    uint256 public mintPrice;
    uint256[] private _allTokens;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => address) private _owners;
    mapping(uint256 => uint256) private _ownedTokenIndex;
    mapping(uint256 => uint256) private _allTokensIndex;
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => string) private _tokenURI;

    constructor (string memory _name, string memory _symbol, uint256 _mintPrice) public {
        manager = address(uint160(msg.sender));
        name = _name;
        symbol = _symbol;
        mintPrice = _mintPrice;
    }
    function setMintPrice(uint256 _mintPrice) public managerOnly returns(bool){
        require(_mintPrice > mintPrice, "ERC721: Cannot set mint price less than or equal to the current mint price");
        mintPrice = _mintPrice;
        return true;
    }

    function tokenURI(uint256 tokenId) public view returns(string memory) {
        require(_exists(tokenId), "ERC721: Cannot query for non-existent token");
        return _tokenURI[tokenId];
    }
    
    function balanceOf(address owner) public view returns (uint256 balance) {
        require(owner != address(0), "ERC721: Cannot query balance of zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address owner) {
        require(_exists(tokenId), "ERC721: Cannot query for non-existent token");
        return _owners[tokenId];
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: Cannot approve owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: Cannot approve if not owner or already approved");
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address operator) {
        require(_exists(tokenId), "ERC721: Cannot get approved for non-existent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != address(0), "ERC721: Cannot set operator to zero address");
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns(bool) {
        require(owner != address(0) || operator != address(0), "ERC721: Cannot query for zero address owner or operator");
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: Cannot transfer as caller not approved or owner");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: Cannot transfer as caller not approved or owner");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) private {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: Cannot safe transfer to non ERC721Receiver");
    }

    function _exists(uint256 tokenId) private view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) private view returns (bool){
       require(_exists(tokenId), "ERC721: Cannot find spender for non-existent token");
       address owner = ownerOf(tokenId);
       return(spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function mint(address to, uint256 tokenId, string memory uri) public payable {
        _mint(to, tokenId, uri);
    }

    function safeMint(address to, uint256 tokenId, string memory uri) public payable {
        _safeMint(to, tokenId, uri, "");
    }

    function safeMint(address to, uint256 tokenId, string memory uri, bytes memory data) public  payable {
        _safeMint(to, tokenId, uri, data);
    }

    function _safeMint(address to, uint256 tokenId, string memory uri, bytes memory data) private {
        _mint(to, tokenId, uri);
        require(_checkOnERC721Received(address(0), to, tokenId, data), "ERC721: Cannot safe transfer to non ERC721Receiver");
    }

    function _mint(address to, uint256 tokenId, string memory uri) private {
        require(msg.value >= mintPrice, "ERC721: Cannot mint as value sent is low");
        require(to != address(0), "ERC721: Cannot transfer to zero address");
        require(!_exists(tokenId), "ERC721: Cannot mint an existing token");
        _beforeTokenTransfer(address(0), to, tokenId);
        _tokenURI[tokenId] = uri;
        _balances[to] += 1;
        _owners[tokenId] = to;
        manager.transfer(msg.value);
        emit Transfer(address(0), to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) private {
        require(_exists(tokenId), "ERC721: Cannot burn non-existent token");
        address owner = ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);

        _tokenURI[tokenId] = "";
        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) private {
        require(ownerOf(tokenId) == from, "ERC721: Cannot transfer from non owner account");
        require(to != address(0), "ERC721: Cannot transfer to zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) private {
        require(owner != operator, "ERC721: Cannot set owner as operator");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
    function _isContract(address account) private view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns(bool) {
        if (_isContract(to)) {
            bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data);
            return retval == IERC721Receiver(address(0)).onERC721Received.selector;
        }else {
            return true;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) private {
        if(from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        }else if(from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if(to == address(0)) {
            _removeTokenFromAllTokenEnumeration(tokenId);
        } else if(to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokenIndex[tokenId];

        if(tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokenIndex[lastTokenId] = tokenIndex;
        }

        delete _ownedTokenIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokenEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        delete _allTokensIndex[tokenId];

        _allTokens.pop();
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokenIndex[tokenId] = length;
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId) private {
        return;
    }

    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721: Global token index out of bounds");
        return _allTokens[index];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721: Owner token index out of bounds");
        return _ownedTokens[owner][index];
    }

    // InterfaceIds :
    /// Note: the ERC-165 identifier for IERC721 interface is 0x80ac58cd.
    /// Note: the ERC-165 identifier for IERC721Receiver is 0x150b7a02.
    /// Note: the ERC-165 identifier for IERC721Metadata is 0x5b5e139f.
    /// Note: the ERC-165 identifier for IERC721Enumerable is 0x780e9d63.
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return (interfaceId == 0x80ac58cd ||
            interfaceId == 0x5b5e139f||
            interfaceId == 0x780e9d63
        );
    }

    modifier managerOnly() {
        require(msg.sender == manager, "ERC721: Contract manager restricted call");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

interface IERC721Metadata {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function tokenURI(uint256 tokenId) external view returns(string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

interface IERC721Enumerable {
    function totalSupply() external view returns(uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns(address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function approve(address to, uint256 tokenId) external ;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}