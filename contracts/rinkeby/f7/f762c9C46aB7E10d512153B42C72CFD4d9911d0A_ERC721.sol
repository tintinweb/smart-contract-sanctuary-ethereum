/**
 *Submitted for verification at Etherscan.io on 2022-06-27
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
    //id последнего созданного токена, одновременно это и общее количество созданных токенов
    uint256 tokenId;
    //наименование токена
    string _name;
    //символ токена - 3-4 символа
    string _symbol;
    //базовый URI метаданных токена
    string  baseURI;
    //адрес владельца контракта токена
    address owner;
    //адрес владельца токена по его id
    mapping(uint256 => address) owners;
    //количество токенов, принадлежащих аккаунту по его адресу
    mapping(address => uint256) balances;
    //словарь разрешения для одного токена по его id может быть определён один spender по его адресу
    mapping(uint256 => address) tokenApprovals;
    //словарь разрешения для оператора. Оператор может выполнять любые операции со всеми токенами, принадлежащими определённому аккаунту.  (owner => (spender => true/false))
    mapping(address => mapping(address => bool)) operatorApprovals;

    constructor(string memory _baseURI) {
        owner = msg.sender;
        _name = "TesFacts";
        _symbol = "TFC";
        baseURI = _baseURI;
    }

    // функция выпуска новых токенов
    function mint(address _to) external returns(uint256) {
        require(msg.sender == owner, "ERC721: You are not owner");
        require(_to != address(0), "ERC721: mint to the zero address");

        tokenId += 1;
        balances[_to] += 1;
        owners[tokenId] = _to;

        emit Transfer(address(0), _to, tokenId);
        return tokenId;
    }

    // функция получения имени токена
    function name() public view override returns (string memory) {
        return _name;
    }

    // функция получения символа токена
    function symbol() public view override returns (string memory) {
        return _symbol;
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

    // функция получения URI токена
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require (_tokenId <= tokenId, "ERC721: URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, toString(_tokenId)));
    }

    // функция получения баланса аккаунта по его адресу
    function balanceOf(address _to) external view override returns (uint256) {
        return balances[_to];
    }

    // функция получения адреса владельца токена по его id
    function ownerOf(uint256 _tokenId) external view override returns (address) {
        return owners[_tokenId];
    }

    // функция для установки прав оператора для одного конкретного токена
    function approve(address _spender, uint256 _tokenId) public override {
        require(_spender != owners[_tokenId], "ERC721: approval to current owner");
        require((msg.sender == owners[_tokenId] || msg.sender == tokenApprovals[_tokenId] || operatorApprovals[owners[_tokenId]][msg.sender]), "ERC721: approve caller is not owner nor approved for all");
    
        tokenApprovals[_tokenId] = _spender;

        emit Approval(owners[_tokenId], tokenApprovals[_tokenId], _tokenId);
    }

    // функция для установки прав оператора на все токены
    function setApprovalForAll(address _operator, bool _approved) public override {
        require(msg.sender != _operator, "ERC721: approve to caller");

        operatorApprovals[msg.sender][_operator] = _approved;

        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    // проверка прав оператора на конкретный токен
    function getApproved(uint256 _tokenId) public view override returns (address) {
        return tokenApprovals[_tokenId];
    }

    // проверка прав оператора на все токены
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    // функция трансфера
    function transferFrom(address _from, address _to, uint256 _tokenId) external override {
        require((msg.sender == owners[_tokenId] || msg.sender == tokenApprovals[_tokenId] || operatorApprovals[owners[_tokenId]][msg.sender]), "ERC721: transfer caller is not owner nor approved");
    
        delete tokenApprovals[_tokenId];
        owners[_tokenId] = _to;
        balances[_from] -= 1;
        balances[_to] += 1;

        emit Transfer(_from, _to, tokenId);
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

    // ещё функция трансфера
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        require((msg.sender == owners[_tokenId] || msg.sender == tokenApprovals[_tokenId] || operatorApprovals[owners[_tokenId]][msg.sender]), "ERC721: transfer caller is not owner nor approved");
        require(_checkOnERC721Received(_from, _to, _tokenId, ''), "ERC721: transfer to non ERC721Receiver implementer");

        delete tokenApprovals[_tokenId];
        owners[_tokenId] = _to;
        balances[_from] -= 1;
        balances[_to] += 1;

        emit Transfer(_from, _to, tokenId);
    }

    // и ещё функция трансфера
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override {
        require((msg.sender == owners[_tokenId] || msg.sender == tokenApprovals[_tokenId] || operatorApprovals[owners[_tokenId]][msg.sender]), "ERC721: transfer caller is not owner nor approved");
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");

        delete tokenApprovals[_tokenId];
        owners[_tokenId] = _to;
        balances[_from] -= 1;
        balances[_to] += 1;

        emit Transfer(_from, _to, tokenId);
    }


    // эта функция нужна для проверки поддерживаемых интерфейсов
    function supportsInterface(bytes4 interfaceId) public view override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}