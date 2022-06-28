/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Receiver {

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC721 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is IERC721, IERC721Metadata, ERC165{
    uint256 tokenId;
    string _name;
    string _symbol;
    string  baseUri;
    address owner;

    mapping(uint256 => address) owners;
    mapping(address => uint256) balances;
    mapping(uint256 => address) tokenAprovals;
    mapping(address => mapping(address => bool)) operatorAprovals;

    constructor(string memory name_, string memory symbol_, string memory baseUri_) {
        owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        baseUri = baseUri_;
    }

    function mint(address to) public returns(uint256) {
        require(owner == msg.sender, "ERC721: You are not owner");
        require(to != address(0), "ERC721: mint to the zero address");
        tokenId += 1;
        balances[to] += 1;
        owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        return tokenId;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(owners[tokenId] != address(0), "ERC721: URI query for nonexistent token");
        return string(abi.encodePacked(baseUri, toString(_tokenId)));
    }

    function balanceOf(address _owner) external view override returns (uint256) {
        return balances[_owner];
    }

    function ownerOf(uint256 _tokenId) external view override returns (address) {
        return owners[_tokenId];
    }

    function approve(address _spender, uint256 _tokenId) public override {
        require(owners[_tokenId] != _spender, "ERC721: approval to current owner");
        require(msg.sender == owners[_tokenId] || operatorAprovals[owners[_tokenId]][msg.sender] == true, "ERC721: approve caller is not owner nor approved for all" );
        tokenAprovals[_tokenId] = _spender;
        emit Approval(msg.sender, _spender, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public override {
        require(msg.sender != _operator, "ERC721: approve to caller");
        operatorAprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view override returns (address) {
        return tokenAprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        return operatorAprovals[_owner][_operator];
    }

    function transferFrom( address _from, address _to, uint256 _tokenId) external override {
        require (msg.sender == owners[_tokenId] || operatorAprovals[owners[_tokenId]][msg.sender] == true || msg.sender == tokenAprovals[_tokenId], "ERC721: transfer caller is not owner nor approved");
        approve(address(0), _tokenId);
        owners[_tokenId] = _to;
        balances[_from] -= 1;
        balances[_to] += 1;
        emit Transfer(_from, _to, _tokenId);
    }

    
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external  override {
        require (msg.sender == owners[_tokenId] || operatorAprovals[owners[_tokenId]][msg.sender] == true || msg.sender == tokenAprovals[_tokenId], "ERC721: transfer caller is not owner nor approved");
        approve(address(0), _tokenId);
        owners[_tokenId] = _to;
        balances[_from] -= 1;
        balances[_to] += 1;
        require(_checkOnERC721Received(_from, _to, _tokenId, ""), "ERC721: transfer to non ERC721Receiver implementer");
        emit Transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override {
        require (msg.sender == owners[_tokenId] || operatorAprovals[owners[_tokenId]][msg.sender] == true  || msg.sender == tokenAprovals[_tokenId], "ERC721: transfer caller is not owner nor approved");
        approve(address(0), _tokenId);
        owners[_tokenId] = _to;
        balances[_from] -= 1;
        balances[_to] += 1;
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
        emit Transfer(_from, _to, _tokenId);
    }


    // эта функция нужна для проверки поддерживаемых интерфейсов
    function supportsInterface(bytes4 interfaceId) public view override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _checkOnERC721Received(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory data
    ) private returns (bool) {
    // если на целевом аккаунт длина кода больше 0 - то это контракт
    if (_to.code.length > 0) {
        // пробуем вызвать на целевом контракте функцию
        try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, data) returns (bytes4 response) {
            // если функция вернула значение, равное селектору функции onERC721Received - то всё ок
            return response == IERC721Receiver.onERC721Received.selector;
        } catch {
            return false;
        }
    } else {
        return true;
    }
    }

    function toString(uint256 value) internal pure returns(string memory) {
    uint256 temp = value;
    uint256 digits;
    do {
        digits++;
        temp /= 10;
    } while (temp != 0);
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
        value /= 10;
    }
    return string(buffer);
    }
}