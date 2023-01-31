/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

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

    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] memory accounts, uint256[] memory _tokenIds) external view returns (uint256[] memory);
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

contract ERC1155 is  ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;
    using Strings for uint256;

    string name;
    string symbol;
    string baseUri;
    address owner;

    mapping(uint256 => bool) tokenIds;
    mapping(uint256 => mapping(address => uint256)) balances;
    mapping(address => mapping(address => bool)) operatorAprovals;

    constructor(string memory _name, string memory _symbol, string memory _baseUri){
        name = _name;
        symbol = _symbol;
        baseUri = _baseUri;
        owner = msg.sender;
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "ERC1155: You are not owner");
        require(!tokenIds[_tokenId], "ERC1155: A token with this id already exists");
        tokenIds[_tokenId] = true;
    }

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

    function mint(address to, uint256 _tokenId, uint256 amount) external {
        require(msg.sender == owner, "ERC1155: You are not owner");
        require(tokenIds[_tokenId], "ERC1155: There is no token with such an id");

        balances[_tokenId][to] += amount;
        emit TransferSingle(msg.sender, address(0), to, _tokenId, amount);
    }

    function mintBatch(address to, uint256[] memory _tokenIds, uint256[] memory amounts) external {
        require(msg.sender == owner, "ERC1155: You are not owner");
        require(_tokenIds.length != amounts.length, "ERC1155: The length of the tokenIds array is not equal to the length of the amounts array");
        for(uint256 i = 0; i < _tokenIds.length; i++)
            require(tokenIds[_tokenIds[i]], "ERC1155: There is no token with such an id");

        for(uint256 i = 0; i < _tokenIds.length; i++)
            balances[_tokenIds[i]][to] += amounts[i];

        emit TransferBatch(msg.sender, address(0), to, _tokenIds, amounts);
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "ERC1155: Operator is you");
        require(approved != operatorAprovals[msg.sender][operator], "ERC1155: Approval is already there");

        operatorAprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 _tokenId,
        uint256 amount,
        bytes memory data
    ) external {
        require(from == msg.sender || operatorAprovals[from][msg.sender], "ERC1155: You don't have enough rights");
        require(tokenIds[_tokenId], "ERC1155: There is no token with such an id");
        require(balances[_tokenId][from] >= amount, "ERC1155: Not enough tokens");
        require(_doSafeTransferAcceptanceCheck(msg.sender, from, to, _tokenId, amount, data), "ERC1155: The recipient's address is not secure");

        balances[_tokenId][from] -= amount;
        balances[_tokenId][to] += amount;
        emit TransferSingle(msg.sender, from, to, _tokenId, amount);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory _tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        require(from == msg.sender || operatorAprovals[from][msg.sender], "ERC1155: You don't have enough rights");
        require(_tokenIds.length != amounts.length, "ERC1155: The length of the tokenIds array is not equal to the length of the amounts array");
        for(uint256 i = 0; i < _tokenIds.length; i++){
            require(tokenIds[_tokenIds[i]], "ERC1155: There is no token with such an id");
            require(balances[_tokenIds[i]][from] >= amounts[i], "ERC1155: Not enough tokens");
        }
        require(_doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, _tokenIds, amounts, data), "ERC1155: The recipient's address is not secure");

        for(uint256 i = 0; i < _tokenIds.length; i++){
            balances[_tokenIds[i]][from] -= amounts[i];
            balances[_tokenIds[i]][to] += amounts[i];
        }
        emit TransferBatch(msg.sender, from, to, _tokenIds, amounts);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function isApprovedForAll(address account, address operator) external view returns (bool) {
        return operatorAprovals[account][operator];
    }

    function uri(uint256 _tokenId) external view returns (string memory) {
        require(tokenIds[_tokenId], "ERC1155: There is no token with such an id");

        return string(abi.encodePacked(baseUri, Strings.toString(_tokenId)));
    }

    function balanceOf(address account, uint256 _tokenId) external view returns (uint256) {
        require(tokenIds[_tokenId], "ERC1155: There is no token with such an id");
        return balances[_tokenId][account];

    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory _tokenIds)
        external
        view
        returns (uint256[] memory)
    {
        require(_tokenIds.length != accounts.length, "ERC1155: The length of the tokenIds array is not equal to the length of the account array");
        uint256[] memory amounts = new uint256[](accounts.length);
        for(uint256 i = 0; i < _tokenIds.length; i++){
            amounts[i] = balances[_tokenIds[i]][accounts[i]];
        }
        return amounts;
    }
}