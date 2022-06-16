/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

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

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract MyERC1155 is  ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;
    using Strings for uint256;

    // Contract owner
    address private _tokenOwner;
    // Base token URI
    string private _baseURI;
    // Token name
    string public name;
    // Token symbol
    string public symbol;

    // Existing tokens ids
    mapping(uint256 => bool) _tokenIds; 
    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;
    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;


    constructor(string memory _name, string memory _symbol, string memory baseURI_) {
        _tokenOwner = msg.sender;
        name = _name;
        symbol = _symbol;
        _baseURI = baseURI_;
    }

    // функция эмиссии одного токена
    function mint(address to, uint256 tokenId, uint256 amount) public {
        require(msg.sender == _tokenOwner, "ERC1155: You are not owner");
        require(to != address(0), "ERC1155: mint to the zero address");

        _balances[tokenId][to] += amount;
        _tokenIds[tokenId] = true;

        emit TransferSingle(_tokenOwner, address(0), to, tokenId, amount);
    }

    // функция эмиссии нескольких токенов на несколько адресов
    function mintBatch(address to, uint256[] memory tokenIds, uint256[] memory amounts) public {
        require(msg.sender == _tokenOwner, "ERC1155: You are not owner");
        require(to != address(0), "ERC1155: mint to the zero address");
        require(tokenIds.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _balances[tokenIds[i]][to] += amounts[i];
            if(!_tokenIds[tokenIds[i]]){
                _tokenIds[tokenIds[i]] = true;
            }
        }

        emit TransferBatch(_tokenOwner, address(0), to, tokenIds, amounts);
    }

    // функция получения URI токена
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(_tokenIds[tokenId], "ERC1155Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    // функция получения баланса аккаунта
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        
        return _balances[id][account];
    }

    // Функция получения баланса нескольких аккаунтов
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    // функция назначения оператора
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(msg.sender != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // функия проверки прав оператора
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    // функция отправки токена
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            msg.sender == from || _operatorApprovals[from][msg.sender],
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    // функция отправки нескольких токенов
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            msg.sender == from || _operatorApprovals[from][msg.sender],
            "ERC1155: caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    //
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");
        address operator = msg.sender;
        require(_doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data), 
                "ERC1155: transfer to non ERC1155Receiver implementer");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        address operator = msg.sender;
        require(_doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data), 
                "ERC1155: transfer to non ERC1155Receiver implementer");
            
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);
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