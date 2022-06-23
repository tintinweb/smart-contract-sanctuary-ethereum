/**
 *Submitted for verification at Etherscan.io on 2022-06-23
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

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is IERC721, IERC721Metadata, ERC165{
    uint public tokenId;
    string public _name;
    string public _symbol;
    string public baseURI;
    address public owner;
    mapping(uint => address) owners;
    mapping(address => uint) balances;
    mapping(uint => address) tokenAprovals;
    mapping(address => mapping(address => bool)) operatorAprovals;


    constructor(string memory _name_, string memory _symbol_, string memory _baseUrl) {
        _name = _name_;
        _symbol = _symbol_;
        baseURI = _baseUrl;
        owner = msg.sender;
    }

    function mint(address to) external returns (uint) {
        require(msg.sender == owner, "ERC721: You are not owner");
        require(to != address(0), "ERC721: mint to the zero address");
        
        tokenId += 1;
        balances[to] += 1;
        owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        return tokenId;
    }

    // функция получения имени токена
    function name() external view override returns (string memory) { return _name; }

    // функция получения символа токена
    function symbol() external view override returns (string memory) { return _symbol; }

    // функция получения URI токена
    function tokenURI(uint256 _tokenId) external view override returns (string memory) {
        require(tokenId >= _tokenId, "ERC721: URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, toString(_tokenId)));
    }

    // функция получения баланса аккаунта по его адресу
    function balanceOf(address _owner) external view override returns (uint) { return balances[_owner]; }

    // функция получения адреса владельца токена по его id
    function ownerOf(uint256 _tokenId) external view override returns (address) { return owners[_tokenId]; }

    // функция для установки прав оператора для одного конкретного токена
    function approve(address _spender, uint256 _tokenId) external override {
        require(_spender != owners[_tokenId], "ERC721: Approval to current owner");
        require(msg.sender == owners[_tokenId] || msg.sender == tokenAprovals[_tokenId], "ERC721: approve caller is not owner nor approved for all");

        tokenAprovals[_tokenId] = _spender;

        emit Approval(msg.sender, _spender, tokenId);
    }

    // функция для установки прав оператора на все токены
    function setApprovalForAll(address _operator, bool _approved) external override {
        require(_operator != msg.sender, "ERC721: Approve to caller");

        operatorAprovals[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    // проверка прав оператора на конкретный токен
    function getApproved(uint256 _tokenId) external view override returns (address) {
        return tokenAprovals[_tokenId];
    }

    // проверка прав оператора на все токены
    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        return operatorAprovals[_owner][_operator];
    }

    // функция трансфера
    function transferFrom( address _from, address _to, uint256 _tokenId) public override {
        require(msg.sender == owners[_tokenId] || msg.sender == tokenAprovals[_tokenId], "ERC721: Transfer caller is not owner nor approved");

        tokenAprovals[_tokenId] = address(0);
        owners[_tokenId] = _to;
        balances[_from] -= 1;
        balances[_to] += 1;

        emit Transfer(_from, _to, _tokenId);
    }

    // ещё функция трансфера
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        bytes memory empty;
        require(_checkOnERC721Received(_from, _to, _tokenId, empty), "ERC721: Transfer to non ERC721Receiver implementer");
        transferFrom(_from, _to, _tokenId);
    }

    // и ещё функция трансфера
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) external override {
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "ERC721: Transfer to non ERC721Receiver implementer");
        transferFrom(_from, _to, _tokenId);
    }

    // функция проверки наличия необходимого интерфейса на целевом аккаунте
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

    // Функция для перевода числа в строку
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

    // эта функция нужна для проверки поддерживаемых интерфейсов
    function supportsInterface(bytes4 interfaceId) public view override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}