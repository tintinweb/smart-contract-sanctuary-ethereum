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
 

    address private owner;
    uint256 private tokenId;
    string private baseURI;
    string private _name;
    string private _symbol;

    mapping(uint256 => address) private owners; // - адрес владельца токена по его id
    mapping(address => uint256) private balances; // - количество токенов, принадлежащих аккаунту по его адресу
    mapping(uint256 => address) private tokenAprovals; // - словарь разрешения для одного токена по его id может быть определён один spender по его адресу
    mapping(address => mapping(address => bool)) private  operatorAprovals; // - словарь разрешения для оператора. Оператор может выполнять лю

    constructor (string memory name_, string memory symbol_ ,string memory _baseURI) {
        owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        baseURI = _baseURI;
    }


    // функция эмиссии токенов
    function mint (address to) external returns (uint256) {
        require(msg.sender == owner, "ERC721: You are not owner");
        require(to !=address(0), "ERC721: zero address");
        uint256 newTokenId = ++(tokenId);
        balances[to] += 1;
        owners[newTokenId] = to;

        emit Transfer(address(0), to, newTokenId);
        return newTokenId;

    }



 
    // функция для установки прав оператора для одного конкретного токена
    function approve(address _spender, uint256 _tokenId) public {
///
        
      //  require(_spender !=tokenOwner || operatorAprovals[tokenOwner][msg.sender] || msg.sender == tokenAprovals[_tokenId], "" );



///

    }
 
    // функция для установки прав оператора на все токены
    function setApprovalForAll(address _operator, bool _approved) public {}
 
    // функция трансфера без проверки адреса _to
    function transferFrom(address _from, address _to, uint256 _tokenId) external {}
 
    // функция трансфера с проверкой, что адрес _to поддерживает интерфейс IERC721Receiver
    function safeTransferFrom( address _from, address _to, uint256 _tokenId) external {}
 
    // функция трансфера с проверкой, что адрес _to поддерживает интерфейс IERC721Receiver
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public {}
 
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
    function tokenURI(uint256 _tokenId) public view returns (string memory) {}
 
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
        return tokenAprovals[_tokenId];
    }
 
    // проверка прав оператора на все токены
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorAprovals[_owner][_operator];
    }
}