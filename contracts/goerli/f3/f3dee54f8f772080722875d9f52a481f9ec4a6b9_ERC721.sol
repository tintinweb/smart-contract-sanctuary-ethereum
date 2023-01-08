//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./Strings.sol";
import "./IERC721Receiver.sol";


contract ERC721 is ERC165, IERC721, IERC721Metadata {
    using Strings for uint;

    string private _name;
    string private _symbol;

    mapping(address => uint) private _balances;
    // позволяет смотреть сколько токенов у определенного адреса
    mapping(uint => address) private _owners;
    // Кто владеет НФТ
    mapping(uint => address) private _tokenApprovals;
    // Дача разрешения НФТ распряжаться определенному адресу
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    // Определенный адрес може(или не может) управлять всеми токенами определенного адреса

    modifier _requireMinted(uint tokenId) {
        require(_exists(tokenId), "not minted!");
        _;
    }
//Проверка токена (был ли он введён в оборот)
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function transferFrom(address from, address to, uint tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not approved or owner!");

        _transfer(from, to, tokenId);
    }

//Права на взаимодействие и перевод NFT на другой адрес

    function safeTransferFrom( address from, address to, uint tokenId, bytes memory data ) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not owner!");
        _safeTransfer(from, to, tokenId, data);
    }
    // Безопасная передача токена
    function name() external view returns(string memory) {
        return _name;
    }

    function symbol() external view returns(string memory) {
        return _symbol;
    }

    function balanceOf(address owner) public view returns(uint) {
        require(owner != address(0), "owner cannot be zero");

        return _balances[owner];
    }
    // Сколько токенов на счету конкретного владельца
    function ownerOf(uint tokenId) public view _requireMinted(tokenId) returns(address) {
        return _owners[tokenId];
    }
// Устанавливает факт владения каким-либо токенном

    function approve(address to, uint tokenId) public {
        address _owner = ownerOf(tokenId);
// Выдача разрешений на передачу токена
        require(_owner == msg.sender || isApprovedForAll(_owner, msg.sender),
            "not an owner!"
        );

        require(to != _owner, "cannot approve to self");

        _tokenApprovals[tokenId] = to;

        emit Approval(_owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(msg.sender != operator, "cannot approve to self");

        _operatorApprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }
// Разрешение на взаимодействия  с токеном от создателя
    function getApproved(uint tokenId) public view _requireMinted(tokenId) returns(address) {
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view returns(bool) {
        return _operatorApprovals[owner][operator];
    }
// Может ли оператор распряжаться всеми токенами на определённом балансе
    function supportsInterface(bytes4 interfaceId) public view virtual override returns(bool) {
        return interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
// Подключение контрактов на 721 стандарте
   
    function _safeMint(address to, uint tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);

        require(_checkOnERC721Received(address(0), to, tokenId, data), "non-erc721 receiver");
    }
// Ввод нового токена в оборот на определенный адрес

    function _mint(address to, uint tokenId) internal virtual {
        require(to != address(0), "zero address to");
        require(!_exists(tokenId), "this token id is already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _owners[tokenId] = to;
        _balances[to]++;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not owner!");

        _burn(tokenId);
    }

    function _burn(uint tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        delete _tokenApprovals[tokenId];
        _balances[owner]--;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }
// Вывод токена из оборота с изменением данныхы и балансом владельца
    function _baseURI() internal pure virtual returns(string memory) {
        return "";
    }
// просто заглушка для ввода URI 

    function tokenURI(uint tokenId) public view virtual _requireMinted(tokenId) returns(string memory) {

        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0 ?
            string(abi.encodePacked(baseURI, tokenId.toString())) :
            "";
    }
    // Задаем URI к определенному токену
// Отображает где находиться токен
    function _exists(uint tokenId) internal view returns(bool) {
        return _owners[tokenId] != address(0);
    }
    // Проверка на наличие TokenID

    function _isApprovedOrOwner(address spender, uint tokenId) internal view returns(bool) {
        address owner = ownerOf(tokenId);
// Фунция по проверки кто может перевести токен 
        return(
            spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender
        );
    }
    
    function _safeTransfer( address from, address to, uint tokenId,bytes memory data ) internal {
        _transfer(from, to, tokenId);

        require( _checkOnERC721Received(from, to, tokenId, data),
            "transfer to non-erc721 receiver" );
    }
    // Может ли владелец владеть токеном или нет
    function _checkOnERC721Received(
        address from,
        address to,
        uint tokenId,
        bytes memory data
    ) private returns(bool) {
        if(to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns(bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch(bytes memory reason //*Переменная в которую упадёт переменная об ошибке 
            ) {
                if(reason.length == 0) {
                    revert("Transfer to non-erc721 receiver");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    // Защита от атакера, по средством проверки адреса(нельзя вызвать передачу токена через и в SC)
    function _transfer(address from, address to, uint tokenId) internal {
        require(ownerOf(tokenId) == from, "incorrect owner!");
        require(to != address(0), "to address is zero!");

        _beforeTokenTransfer(from, to, tokenId);

        delete _tokenApprovals[tokenId];

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }
// служебные функции для выполнения действий полсе передачи токена
    function _beforeTokenTransfer( address from, address to, uint tokenId) internal virtual {}

    function _afterTokenTransfer( address from, address to, uint tokenId) internal virtual {}
}