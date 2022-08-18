/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract DaxToken {
    address private _creator;
    bool private _locked;
    string private _name;
    string private _symbol;
    uint256 private _mintingFee;
    uint256[] private _allTokens;

    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(uint256 => address) private _tokenOwners;
    mapping(uint256 => address) private _tokenCreators;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) private _allTokensIndex;
    mapping(address => uint256) private _balances;
    mapping(uint256 => uint256) private _ownedTokensIndex;

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor() {
        _creator = _msgSender();
        _locked = true;
        _mintingFee = 1000000000000000;
        _name = "DaxToken";
        _symbol = "DAXT";
    }

    fallback() external payable {
        bulkMint();
    }

    receive() external payable {
        bulkMint();
    }

    function approve(address to, uint256 tokenId) public {
        address owner = DaxToken.ownerOf(tokenId);
        require(to != owner, "DaxToken: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "DaxToken: approve caller is not token owner or approved for all");
        _approve(to, tokenId);
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "DaxToken: zero address owner not valid");
        return _balances[owner];
    }

    function bulkMint() public payable returns (uint256[] memory) {
        return _bulkMint();
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function creator() public view returns (address) {
        return _creator;
    }

    function creatorOf(uint256 tokenId) public view returns (address) {
        address tokenCreator = _tokenCreators[tokenId];
        require(tokenCreator != address(0), "DaxToken: invalid token ID");
        return tokenCreator;
    }

    function getApproved(uint256 tokenId) public view tokenExists(tokenId) returns (address) {
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function locked() public view returns (bool) {
        return _locked;
    }

    function mint(string memory uri) public payable returns (uint256) {
        return _mint(uri);
    }

    function mintingFee() public view returns (uint256) {
        return _mintingFee;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address tokenOwner = _tokenOwners[tokenId];
        require(tokenOwner != address(0), "DaxToken: invalid token ID");
        return tokenOwner;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "DaxToken: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function setCreator(address contractCreator_) public onlyCreator isUnlocked {
        _creator = contractCreator_;
    }

    function setLocked(bool locked_) public onlyCreator {
        _locked = locked_;
    }

    function setMintingFee(uint256 mintingFee_) public onlyCreator isUnlocked {
        _mintingFee = mintingFee_;
    }

    function setName(string memory name_) public onlyCreator isUnlocked {
        _name = name_;
    }
    
    function setTokenURI(uint256 tokenId, string memory uri) public tokenExists(tokenId) onlyTokenCreator(tokenId) onlyTokenOwner(tokenId) {
        _tokenURIs[tokenId] = uri;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < DaxToken.totalSupply(), "DaxToken: global index out of bounds");
        return _allTokens[index];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < DaxToken.balanceOf(owner), "DaxToken: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function tokenURI(uint256 tokenId) public view tokenExists(tokenId) returns (string memory) {
        string memory _tokenURI = _tokenURIs[tokenId];
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }
        return "";
    }

    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "DaxToken: caller is not token owner or approved");
        _transfer(from, to, tokenId);
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = DaxToken.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(DaxToken.ownerOf(tokenId), to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) private {
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

    function _bulkMint() private requireMintingFee returns (uint256[] memory) {
        uint32 tokensToCreate = _tokensToCreate();
        uint256[] memory tokens = new uint256[](tokensToCreate);

        for (uint32 count = 0; count < tokensToCreate; count++) {
            tokens[count] = _createToken("");
        }

        _settleFees(tokensToCreate);

        return tokens;
    }

    function _burn(uint256 tokenId) private {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "DaxToken: caller is not token owner or approved");
        address owner = DaxToken.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        delete _tokenApprovals[tokenId];
        _balances[owner] -= 1;
        delete _tokenCreators[tokenId];
        delete _tokenOwners[tokenId];
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
        emit Transfer(owner, address(0), tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (_isContract(to)) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("DaxToken: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _createToken(string memory uri) private returns (uint256) {
        address sender = _msgSender();
        uint256 tokenId = totalSupply();
        _beforeTokenTransfer(address(0), sender, tokenId);
        _balances[sender] += 1;
        _tokenCreators[tokenId] = sender;
        _tokenOwners[tokenId] = sender;
        _tokenURIs[tokenId] = uri;
        emit Transfer(address(0), sender, tokenId);

        return tokenId;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) private view returns (bool) {
        address owner = DaxToken.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _isContract(address account) private view returns (bool) {
        return account.code.length > 0;
    }

    function _mint(string memory uri) private requireMintingFee returns (uint256) {
        uint256 tokenId = _createToken(uri);
        _settleFees(1);

        return tokenId;
    }

    function _msgSender() private view returns (address) {
        return msg.sender;
    }

    function _msgValue() private view returns (uint256) {
        return msg.value;
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = DaxToken.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) private {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "DaxToken: transfer to non ERC721Receiver implementer");
    }

    function _setApprovalForAll(address owner, address operator, bool approved) private {
        require(owner != operator, "DaxToken: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _settleFees(uint32 tokenCount) private {
        uint256 amount = _msgValue();
        uint256 fee = tokenCount * DaxToken.mintingFee();
        uint256 change = amount - fee;
        require(payable(_creator).send(fee), "DaxToken: failed to send fee to creator");
        require(payable(_msgSender()).send(change), "DaxToken: failed to send change to sender");
    }

    function _tokensToCreate() private view returns (uint32) {
        uint256 amount = _msgValue();
        if (amount == 0) {
            return 100;
        }
        uint32 count;
        do {
            amount = amount - _mintingFee;
            count ++;
        } while (amount >= _mintingFee);
        return count;
    }

    function _transfer(address from, address to, uint256 tokenId) private {
        require(DaxToken.ownerOf(tokenId) == from, "DaxToken: transfer from incorrect owner");
        require(to != address(0), "DaxToken: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        delete _tokenApprovals[tokenId];
        _balances[from] -= 1;
        _balances[to] += 1;
        _tokenOwners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    modifier isUnlocked {
        require(!_locked, "DaxToken: contract must be unlocked");
        _;
    }

    modifier onlyCreator {
        require(_creator == _msgSender(), "DaxToken: caller must be contract creator");
        _;
    }

    modifier onlyTokenCreator(uint256 tokenId) {
        require(DaxToken.creatorOf(tokenId) == _msgSender(), "DaxToken: caller must be token creator");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(DaxToken.ownerOf(tokenId) == _msgSender(), "DaxToken: caller must be token owner");
        _;
    }

    modifier requireMintingFee {
        require(_mintingFee <= _msgValue(), "DaxToken: mint fee required");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(_tokenOwners[tokenId] != address(0), "DaxToken: invalid token ID");
        _;
    }
}