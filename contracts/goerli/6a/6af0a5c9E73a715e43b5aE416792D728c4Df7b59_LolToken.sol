/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// SPDX-License-Identifier: GPL-3.0
// (c) quswadress 2022

pragma solidity 0.8.15;

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
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract LolToken is IERC721, IERC721Metadata, ERC165 {
    uint256 tokenId;
    string constant baseUri =
        "https://gateway.pinata.cloud/ipfs/QmbjxbDMWDyaBxw7byhWev51d38yCFP2sswkVb1obMqXso/";
    address owner;
    mapping(uint256 => address) owners;
    mapping(address => uint256) balances;
    mapping(uint256 => address) tokenAprovals;
    mapping(address => mapping(address => bool)) operatorAprovals;

    string public constant name = "Token for blockchain education";
    string public constant symbol = "LOLKEK";

    constructor() {
        owner = msg.sender;
    }

    // функция эмиссии токенов
    function mint(address to) external returns (uint256) {
        require(msg.sender == owner, "ERC721: You are not owner");
        tokenId += 1;
        balances[to] += 1;
        owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        return tokenId;
    }

    // функция для установки прав оператора для одного конкретного токена
    function approve(address _spender, uint256 _tokenId) public {
        require(
            _spender != owners[_tokenId],
            "ERC721: approval to current owner"
        );
        require(
            msg.sender == owners[_tokenId] ||
                isApprovedForAll(msg.sender, _spender) ||
                msg.sender == tokenAprovals[_tokenId],
            "ERC721: approve caller is not owner nor approved for all"
        );
        tokenAprovals[_tokenId] = _spender;
        emit Approval(msg.sender, _spender, _tokenId);
    }

    // функция для установки прав оператора на все токены
    function setApprovalForAll(address _operator, bool _approved) public {
        require(_operator != msg.sender, "ERC721: approve to caller");
        operatorAprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    // функция трансфера без проверки адреса _to
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        require(
            _from == owners[_tokenId],
            "ERC721: from is not the owner of the tokenId"
        );
        require(
            msg.sender == owners[_tokenId] || operatorAprovals[msg.sender][_from] ||
                tokenAprovals[_tokenId] == msg.sender,
            "ERC721: approve caller is not owner nor approved for all"
        );
        require(balances[_from] > 0, "Your balance is empty");
        delete tokenAprovals[_tokenId];
        tokenAprovals[_tokenId] = _to;
        balances[_from] -= 1;
        balances[_to] += 1;
        emit Transfer(_from, _to, _tokenId);
    }

    // функция трансфера с проверкой, что адрес _to поддерживает интерфейс IERC721Receiver
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        // TODO: Remove copy-paste
        require(
            _checkOnERC721Received(_from, _to, _tokenId, bytes("")),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
        require(
            _from == owners[_tokenId],
            "ERC721: from is not the owner of the tokenId"
        );
        require(
            msg.sender == owners[_tokenId] ||
                tokenAprovals[_tokenId] == msg.sender,
            "ERC721: approve caller is not owner nor approved for all"
        );
        require(balances[_from] > 0, "Your balance is empty");
        tokenAprovals[_tokenId] = _to;
        balances[_from] -= 1;
        balances[_to] += 1;
        emit Transfer(_from, _to, _tokenId);
    }

    // функция трансфера с проверкой, что адрес _to поддерживает интерфейс IERC721Receiver
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public {
        // TODO: Remove copy-paste
        require(
            _checkOnERC721Received(_from, _to, _tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
        require(
            _from == owners[_tokenId],
            "ERC721: from is not the owner of the tokenId"
        );
        require(
            msg.sender == owners[_tokenId] ||
                tokenAprovals[_tokenId] == msg.sender,
            "ERC721: approve caller is not owner nor approved for all"
        );
        require(balances[_from] > 0, "Your balance is empty");
        tokenAprovals[_tokenId] = _to;
        balances[_from] -= 1;
        balances[_to] += 1;
        emit Transfer(_from, _to, _tokenId);
    }

    // функция проверки поддерживаемых интерфейсов
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // возвращает URI токена по его id
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_tokenId < tokenId, "ERC721: URI query for nonexistent token");
        return string(abi.encodePacked(baseUri, toString(_tokenId)));
    }

    // возвращает баланса аккаунта по его адресу
    function balanceOf(address to) external view returns (uint256) {
        return balances[to];
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
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        return operatorAprovals[_owner][_operator];
    }

    function _checkOnERC721Received(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) private returns (bool) {
        // если на целевом аккаунт длина кода больше 0 - то это контракт
        if (_to.code.length > 0) {
            // если контракт - пробуем вызвать на целевом контракте функцию onERC721Received
            try
                IERC721Receiver(_to).onERC721Received(
                    msg.sender,
                    _from,
                    _tokenId,
                    data
                )
            returns (bytes4 response) {
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