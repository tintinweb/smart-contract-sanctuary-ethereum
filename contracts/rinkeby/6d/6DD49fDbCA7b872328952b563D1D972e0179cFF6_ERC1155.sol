/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// пример реализации библиотеки
library Strings {

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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

library Address {

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

interface IERC1155Receiver is IERC165 {

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC1155MetadataURI is IERC1155 {

    function uri(uint256 id) external view returns (string memory);
}

contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC1155 is  ERC165, IERC1155, IERC1155MetadataURI {
    // пример применения библиотеки
    using Address for address;
    using Strings for uint256;

    string public name;
    string public symbol;
    string  baseURI;
    address owner;

    mapping(uint256 => bool) tokenIds;
    mapping(uint256 => mapping(address => uint256)) balances;
    mapping(address => mapping(address => bool)) operatorAprovals;

    constructor(string memory _name, string memory _symbol, string memory _baseURI) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
    }

    // функция эмиссии одного токена
    function mint(address to, uint256 _tokenId, uint256 amount) public {
        require(msg.sender == owner, "ERC1155: You are not owner");

        balances[_tokenId][to] += amount;
        tokenIds[_tokenId] = true;

        emit TransferSingle(owner, address(0), to, _tokenId, amount);
    }

    // функция эмиссии нескольких токенов на несколько адресов
    function mintBatch(address to, uint256[] memory _tokenIds, uint256[] memory amounts) public {
        require(msg.sender == owner, "ERC1155: You are not owner");
        require(_tokenIds.length == amounts.length, "ERC1155: ids and amounts lenght mismatch");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            balances[_tokenIds[i]][to] += amounts[i];
            if (!tokenIds[_tokenIds[i]]) {
                 tokenIds[_tokenIds[i]] = true;
            }
        }

        emit TransferBatch(owner, address(0), to, _tokenIds, amounts);
    }

    // функция получения URI токена
    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
        require(tokenIds[_tokenId], "ERC1155: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    // функция получения баланса аккаунта
    function balanceOf(address account, uint256 _tokenId) public view virtual override returns (uint256) {
        return balances[_tokenId][account];
    }

    // Функция получения баланса нескольких аккаунтов
    function balanceOfBatch(address[] memory accounts, uint256[] memory _tokenIds) public view virtual override returns (uint256[] memory) {
        require(accounts.length == _tokenIds.length, "ERC1155: ids and amounts lenght mismatch");

        uint256[] memory Balances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            Balances[i] = balanceOf(accounts[i], _tokenIds[i]);
        }

        return Balances;
    }

    // функция назначения оператора
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(msg.sender != operator, "ERC1155: setting approval status for self");

        operatorAprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // функия проверки прав оператора
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return operatorAprovals[account][operator];
    }

    // функция отправки токена
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(msg.sender == from || operatorAprovals[from][msg.sender], "ERC1155: caller is not owner or not approved");
        require (to != address(0), "ERC1155 transfer to the zero address");
        address operator = msg.sender;
        require (_doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data), "ERC1155: transfer to non ERC1155 receiver implementer");
        uint256 fromBalance = balances[id][from];
        require (fromBalance >= amount, "ERC1155: insufficient balance for transfer");

        balances[id][from] = fromBalance - amount;
        balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);
    }

    // функция отправки нескольких токенов
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(ids.length == amounts.length, "ERC1155: ids and amounts lenght mismatch");
        require (to != address(0), "ERC1155 transfer to the zero address");
        address operator = msg.sender;
        require (_doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data), "ERC1155: transfer to non ERC1155 receiver implementer");
       
       for (uint256 i = 0; i < ids.length; i++) {
           uint256 id = ids[i];
           uint256 amount = amounts[i];
           uint256 fromBalance = balances[id][from];
           require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
           balances[id][from] = fromBalance - amount;
           balances[id][to] += amount;

           emit TransferBatch(operator, from, to, ids, amounts);
       }


    }

    // проверка аккаунта, на который отправляется токен
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private returns(bool){
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                return response == IERC1155Receiver.onERC1155Received.selector;
            } catch {
                return false;
            }
        } else {
            return true;
        }
    }

    // проверка аккаунта, на который отправляются токены
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private returns(bool){
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                return response == IERC1155Receiver.onERC1155BatchReceived.selector;
            } catch {
                return false;
            }
        } else {
            return true;
        }
    }
    // эта функция нужна для проверки поддерживаемых интерфейсов
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}