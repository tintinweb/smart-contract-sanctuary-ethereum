/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract ERC721{

    // адрес владельца контракта
    address private owner;
    // текущий id токена
    uint256 private tokenId;
    // базовый URI токенов
    string private baseURI;
    // имя токена
    string public name;
    // символ токена
    string public symbol;

    // словарь владельцев токена (id токена => адрес владельца)
    mapping(uint256 => address) private owners;
    // словарь балансов (адрес аккаунта => количество токенов)
    mapping(address => uint256) private balances;
    // словарь разрешений (id токена => адрес аккаунта, которому разрешено тратить токен)
    mapping(uint256 => address) private tokenApprovals;
    // словарь операторов (адреса владельца токена => (адрес оператора => разрешение))
    mapping(address => mapping(address => bool)) private operatorApprovals;

    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address spender, uint256 tokenId);
    event ApprovalForAll(address owner, address operator, bool approved);

    constructor(string memory _name, string memory _symbol, string memory _baseURI) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
    }

    // функция эмиссии токенов
    function mint(address to) external returns (uint256) {
        require(msg.sender == owner, "ERC721: you are not owner");
        require(to != address(0), "ERC721: mint to the zero address");

        uint256 newTokenId = ++(tokenId);
        balances[to] += 1;
        owners[newTokenId] = to;

        //emit Transfer(address(0), to, newTokenId);
        return newTokenId;
    }

    // функция получения баланса аккаунта по его адресу
    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    // функция получения адреса владельца токена по его id
    function ownerOf(uint256 _tokenId) external view returns (address) {
        return owners[_tokenId];
    }


    function approve(address _spender, uint256 _tokenId) public {
        address tokenOwner = owners[_tokenId];

        require(_spender != tokenOwner, "ERC721: approval to current owner");
        require(msg.sender == tokenOwner || operatorApprovals[tokenOwner][msg.sender],
            "ERC721: approve caller is not owner nor approved for all");

        tokenApprovals[_tokenId] = _spender;

        emit Approval(owner, _spender, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        require(msg.sender != _operator, "ERC721: approve to caller");
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        approve(address(0), _tokenId);

        balances[_from] -= 1;
        balances[_to] += 1;
        owners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }


    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        transferFrom(_from, _to, _tokenId);
    }


    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) external {
        _data;
        transferFrom(_from, _to, _tokenId);
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address tokenOwner = owners[_tokenId];
        return (_spender == tokenOwner || isApprovedForAll(tokenOwner, _spender) || getApproved(_tokenId) == _spender);
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

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(owners[_tokenId] != address(0), "ERC721: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, toString(_tokenId)));
    }
}