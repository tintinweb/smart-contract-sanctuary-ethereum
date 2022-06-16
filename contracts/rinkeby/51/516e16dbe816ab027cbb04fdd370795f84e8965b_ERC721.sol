/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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

    // функция получения имени токена
    function name() public view override returns (string memory){
        return _name;
    }

    // функция получения символа токена
    function symbol() public view override returns (string memory){
        return _symbol;
    }

    // функция получения URI токена
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(owners[_tokenId] != address(0), "ERC721: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, toString(_tokenId)));
    }

    // функция эмиссии токенов
    function mint(address to) external returns (uint256) {
        require(msg.sender == owner, "ERC721: you are not owner");
        require(to != address(0), "ERC721: mint to the zero address");

        uint256 newTokenId = ++(tokenId);
        balances[to] += 1;
        owners[newTokenId] = to;

        emit Transfer(address(0), to, newTokenId);
        return newTokenId;
    }

    // функция получения баланса аккаунта по его адресу
    function balanceOf(address _owner) external view override returns (uint256) {
        return balances[_owner];
    }

    // функция получения адреса владельца токена по его id
    function ownerOf(uint256 _tokenId) external view override returns (address) {
        return owners[_tokenId];
    }

    // функция для установки прав оператора для одного конкретного токена
    function approve(address _spender, uint256 _tokenId) public override {
        address tokenOwner = owners[_tokenId];

        require(_spender != tokenOwner, "ERC721: approval to current owner");
        require(msg.sender == tokenOwner || operatorApprovals[tokenOwner][msg.sender],
            "ERC721: approve caller is not owner nor approved for all");

        tokenApprovals[_tokenId] = _spender;

        emit Approval(owner, _spender, _tokenId);
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
    function transferFrom(address _from, address _to, uint256 _tokenId) external override checkOwner(_tokenId){
        _transfer(_from, _to, _tokenId);
    }

    // функция трансфера
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override checkOwner(_tokenId){
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    // функция трансфера
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override checkOwner(_tokenId){
        _safeTransfer(_from, _to, _tokenId, _data);
    }

    // функция трансфера
    function _safeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    // функция трансфера
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        approve(address(0), _tokenId);

        balances[_from] -= 1;
        balances[_to] += 1;
        owners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    // функция для проверки прав на токены
    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address tokenOwner = owners[_tokenId];
        return (_spender == tokenOwner || isApprovedForAll(tokenOwner, _spender) || getApproved(_tokenId) == _spender);
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

    function _checkOnERC721Received(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) private returns (bool) {
        if (_to.code.length > 0) {
            try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, data) returns (bytes4 response) {
                return response == IERC721Receiver.onERC721Received.selector;
            } catch {
                return false;
            }
        } else {
            return true;
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}