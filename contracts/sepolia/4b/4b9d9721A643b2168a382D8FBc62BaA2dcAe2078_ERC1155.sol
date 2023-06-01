// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155TokenReceiver.sol";
import "./ERC1155TokenReciver.sol";
import "./IERC165.sol";

contract ERC1155 is IERC1155, IERC165, ERC1155TokenReciver {
    address private _owner;
    //  tokenId => account balance;
    mapping(uint256 => mapping(address => uint256)) private _balances;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor() {
        _owner = msg.sender;
    }

    function supportInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC1155).interfaceId;
    }

    function _addressCheck(address adrs) private pure {
        require(adrs != address(0), "ERC1155: Invalid address");
    }

    function _mint(address to, uint256 id, uint256 amount) private {
        // if (_balances[id][to] == 0) {
        //     // setURI(id, string(abi.encodePacked(Strings.toString(id), ".json")));
        //     // emit URI(uri(id), id);
        // }
        _balances[id][to] += amount;
    }

    function _transfer(
        address from,
        address to,
        uint256 id,
        uint256 value
    ) private {
        _balances[id][from] -= value;
        _balances[id][to] += value;
    }

    function mint(address to, uint256 id, uint256 amount) external {
        _addressCheck(to);
        // require(to != _owner, "ERC1155: owner not allowed");
        require(amount > 0, "ERC1155: invalid amount");
        _mint(to, id, amount);
        emit TransferSingle(msg.sender, address(0), to, id, amount);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amount
    ) external {
        _addressCheck(to);
        require(to != _owner, "ERC1155: owner not allowed");
        require(ids.length == amount.length, "ERC1155: missing values");

        for (uint256 i = 0; i < ids.length; i++) {
            _mint(to, ids[i], amount[i]);
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amount);
    }

    // function tokenURI(uint256 tokenId) external view returns (string memory) {
    //     // return uri(tokenId);
    // }

    function burn(address from, uint256 id, uint256 amount) external {
        _addressCheck(from);
        require(
            msg.sender == from || msg.sender == _owner,
            "ERC1155: burn not allowed"
        );
        require(
            _balances[id][from] >= amount || amount > 0,
            "ERC1155: insufficent balance"
        );
        _balances[id][from] -= amount;
        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }

    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external {
        _addressCheck(from);
        require(
            msg.sender == from || msg.sender == _owner,
            "ERC1155: burn not allowed"
        );
        require(ids.length == amounts.length, "ERC1155: missing values");

        for (uint256 i = 0; i < ids.length; i++) {
            require(
                _balances[ids[i]][from] >= amounts[i] || amounts[i] > 0,
                "ERC1155: insufficent balance"
            );
            _balances[ids[i]][from] -= amounts[i];
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external {
        _addressCheck(to);
        require(value > 0, "ERC1155: invalid value");
        require(from != to, "ERC1155: same address");
        require(
            msg.sender == from || isApprovedForAll(from, msg.sender),
            "ERC1155: unauthorized"
        );
        require(_balances[id][from] >= value, "ERC1155: insufficient balance");
        _transfer(from, to, id, value);
        require(
            to.code.length == 0 ||
                IERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    value,
                    data
                ) ==
                IERC1155TokenReceiver.onERC1155Received.selector,
            "ERC1155: unsafe transactions"
        );
        emit TransferSingle(msg.sender, from, to, id, value);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external {
        _addressCheck(to);
        require(from != to, "ERC1155: same address");
        require(
            msg.sender == from || isApprovedForAll(from, msg.sender),
            "ERC1155: unauthorized"
        );
        require(from != to, "ERC1155: same address");
        require(ids.length == values.length, "ERC1155: length mismatch");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 value = values[i];
            require(
                _balances[id][from] >= value || value > 0,
                "ERC1155: insufficent balance"
            );

            _transfer(from, to, id, value);
        }

        require(
            to.code.length == 0 ||
                IERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    values,
                    data
                ) ==
                IERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "ERC1155: unsafe transactions"
        );
        emit TransferBatch(msg.sender, from, to, ids, values);
    }

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256) {
        return _balances[id][account];
    }

    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) external view returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: length mismatch");
        uint256[] memory balanceBatch = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; i++) {
            balanceBatch[i] = _balances[ids[i]][accounts[i]];
        }

        return balanceBatch;
    }

    function setApprovalForAll(address operator, bool approved) external {
        _addressCheck(operator);
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155TokenReceiver.sol";

contract ERC1155TokenReciver is IERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155 {
    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _value
    );

    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _values
    );

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    event URI(string _value, uint256 indexed _id);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    function balanceOf(
        address _owner,
        uint256 _id
    ) external view returns (uint256);

    function balanceOfBatch(
        address[] calldata _owners,
        uint256[] calldata _ids
    ) external view returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(
        address _owner,
        address _operator
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1155TokenReceiver {
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportInterface(bytes4 interfaceId) external view returns (bool);
}