/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// SPDX-License-Identifier: MIT
 
pragma solidity 0.8.15;
 
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
 
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
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
 
    // адрес владельца контракта
    address private owner;
    // текущий id токена
    uint256 private tokenId;
    // базовый URI токенов
    string private baseURI;
    // имя токена
    string private _name;
    // символ токена
    string private _symbol;
 
    // словарь владельцев токена (id токена => адрес владельца)
    mapping(uint256 => address) private owners;
    // словарь балансов (адрес аккаунта => количество токенов)
    mapping(address => uint256) private balances;
    // словарь разрешений (id токена => адрес аккаунта, которому разрешено тратить токен)
    mapping(uint256 => address) private tokenApprovals;
    // словарь операторов (адреса владельца токена => (адрес оператора => разрешение))
    mapping(address => mapping(address => bool)) private operatorApprovals;
 
    modifier checkOwner(uint _tokenId){
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        _;
    }
 
    constructor(string memory name_, string memory symbol_, string memory _baseURI) {
        owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        baseURI = _baseURI;
    }
 
    // функция эмиссии токенов
    function mint(address to) external returns (uint256) {
        // проверка, что функцию вызывает владелец и эмиссия не на нулевой адрес
        require(msg.sender == owner, "ERC721: you are not owner");
        require(to != address(0), "ERC721: mint to the zero address");
        // увеличиваем количество токенов, получаем id нового токена
        uint256 newTokenId = ++(tokenId);
        // увеличиваем баланс to и сохраняем владельца нового токена
        balances[to] += 1;
        owners[newTokenId] = to;
        // делаем событие
        emit Transfer(address(0), to, newTokenId);
        // возвращаем id нового токена
        return newTokenId;
    }
 
    // функция для установки прав оператора для одного конкретного токена
    function approve(address _spender, uint256 _tokenId) public {
        // получаем адрес вледельца токена _tokenId
        address tokenOwner = owners[_tokenId];
        // проверяем, что _tokenId не tokenOwner
        require(_spender != tokenOwner, "ERC721: approval to current owner");
        // проверяем, что msg.sender - владелец или оператор токена _tokenId
        require(msg.sender == tokenOwner || operatorApprovals[tokenOwner][msg.sender] || msg.sender == tokenApprovals[_tokenId],
            "ERC721: approve caller is not owner nor approved for all");
        // назначаем _spender оператором токена _tokenId
        tokenApprovals[_tokenId] = _spender;
        // делаем событие
        emit Approval(owner, _spender, _tokenId);
    }
 
    // функция для установки прав оператора на все токены
    function setApprovalForAll(address _operator, bool _approved) public {
        // проверяем, что msg.sender не является сам адресом _operator
        require(msg.sender != _operator, "ERC721: approve to caller");
        // устанавливаем разрешине/запрет для _operator оперировать токенами msg.sender
        operatorApprovals[msg.sender][_operator] = _approved;
        // делаем событие
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
 
    // функция трансфера без проверки адреса _to
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external checkOwner(_tokenId){
        _transfer(_from, _to, _tokenId);
    }
 
    // функция трансфера с проверкой, что адрес _to поддерживает интерфейс IERC721Receiver
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external checkOwner(_tokenId){
        safeTransferFrom(_from, _to, _tokenId, "");
    }
 
    // функция трансфера с проверкой, что адрес _to поддерживает интерфейс IERC721Receiver
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId, 
        bytes memory _data
    ) public checkOwner(_tokenId){
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
        _transfer(_from, _to, _tokenId);
    }
 
    // Собственно именно здесь происходит настоящий трансфер
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // поскольку владелец токена меняется, обнуляем ранее выданные права оператора на этот токен
        approve(address(0), _tokenId);
        // уменьшаем/увеличиваем баланс _from и _to
        balances[_from] -= 1;
        balances[_to] += 1;
        // назначаем нового владельца для _tokenId
        owners[_tokenId] = _to;
        // делаем событие
        emit Transfer(_from, _to, _tokenId);
    }
 
    // функция проверки наличия интерфейса IERC721Receiver на целевом аккаунте
    function _checkOnERC721Received(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) internal returns (bool) {
        // если на целевом аккаунт длина кода больше 0 - то это контракт
        if (_to.code.length > 0) {
            // если контракт - пробуем вызвать на целевом контракте функцию onERC721Received
            try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, data) returns (bytes4 response) {
                // если функция вернула значение, равное селектору функции onERC721Received - то всё ок
                return response == IERC721Receiver.onERC721Received.selector;
            // если на целевом контракте не удалось вызвать функцию onERC721Received - возвращаем false
            } catch {
                return false;
            }
        // если не контракт - возвращаем сразу true
        } else {
            return true;
        }
    }
    
    // функция для проверки прав на токен
    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address tokenOwner = owners[_tokenId];
        return (_spender == tokenOwner || operatorApprovals[tokenOwner][_spender] || tokenApprovals[_tokenId] == _spender);
    }
 
    // функция преобразования числа в строку
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
 
   // функция проверки поддерживаемых интерфейсов
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
 
    // возвращает название токена
    function name() public view returns (string memory){
        return _name;
    }
 
    // возвращает символа токена
    function symbol() public view returns (string memory){
        return _symbol;
    }
 
    // возвращает URI токена по его id
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(owners[_tokenId] != address(0), "ERC721: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, toString(_tokenId)));
    }
 
    // возвращает баланса аккаунта по его адресу
    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }
 
    // возвращает адрес владельца токена по его id
    function ownerOf(uint256 _tokenId) external view returns (address) {
        return owners[_tokenId];
    }
 
    // проверка прав оператора на конкретный токен
    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }
 
    // проверка прав оператора на все токены
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }
}