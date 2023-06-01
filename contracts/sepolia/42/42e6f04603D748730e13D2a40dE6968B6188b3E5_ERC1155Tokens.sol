// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC1155Receiver.sol";

interface IERC1155Token {
    function balanceOf(address _owner, uint256 _tokenId)
        external
        view
        returns (uint256);
    
     function mint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    function balanceOfBatch(
        address[] memory _accounts,
        uint256[] memory _tokenIds
    ) external view returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _account, address _operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) external;

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
}

contract ERC1155Tokens is IERC1155Token, IERC1155Receiver {
    // token id => (address => balance)
    mapping(uint256 => mapping(address => uint256)) internal _balances;
    // owner => (operator => yes/no)
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    // token id => supply
    mapping(uint256 => uint256) public totalSupply;

    uint256 public nextTokenIdToMint;
    string public name;
    string public symbol;
    address public owner;

    constructor(string memory _name, string memory _symbol) {
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        nextTokenIdToMint = 0;
    }

    function balanceOf(address _owner, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        require(_owner != address(0), "ERC1155Token: invalid address");
        return _balances[_tokenId][_owner];
    }

    function balanceOfBatch(
        address[] memory _accounts,
        uint256[] memory _tokenIds
    ) public view returns (uint256[] memory) {
        require(
            _accounts.length == _tokenIds.length,
            "ERC1155Token: accounts id length mismatch"
        );
        // create an array dynamically
        uint256[] memory balances = new uint256[](_accounts.length);

        for (uint256 i = 0; i < _accounts.length; i++) {
            balances[i] = balanceOf(_accounts[i], _tokenIds[i]);
        }

        return balances;
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        _operatorApprovals[msg.sender][_operator] = _approved;
    }

    function isApprovedForAll(address _account, address _operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[_account][_operator];
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public {
        require(
            _from == msg.sender || isApprovedForAll(_from, msg.sender),
            "ERC1155Token: not authorized"
        );

        // transfer
        transfer(_from, _to, _id, _amount);
        // safe transfer checks

        _doSafeTransferAcceptanceCheck(
            msg.sender,
            _from,
            _to,
            _id,
            _amount,
            _data
        );
        emit TransferSingle(msg.sender, _from, _to, _id, _amount);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public {
        require(
            _from == msg.sender || isApprovedForAll(_from, msg.sender),
            "ERC1155Token: not authorized"
        );
        require(
            _ids.length == _amounts.length,
            "ERC1155Token: length mismatch"
        );

         
        
        for (uint256 i = 0; i < _ids.length; i++) {
            transfer(_from, _to, _ids[i], _amounts[i]);
            _doSafeTransferAcceptanceCheck(
                msg.sender,
                _from,
                _to,
                _ids[i],
                _amounts[i],
                _data
            );
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
    }

    function mint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) public {
        

        uint256 tokenIdToMint;

        if (_tokenId > nextTokenIdToMint) {
            require(
                _tokenId == nextTokenIdToMint+1,
                "ERC1155Token: invalid tokenId"
            );
            tokenIdToMint = nextTokenIdToMint;
            nextTokenIdToMint += 1;
        } else {
            tokenIdToMint = _tokenId;
        }

        _balances[tokenIdToMint][_to] += _amount;
        totalSupply[tokenIdToMint] += _amount;

        emit TransferSingle(msg.sender, address(0), _to, _tokenId, _amount);
    }

    // INTERNAL FUNCTIONS

    function transfer(
        address _from,
        address _to,
        uint256 _ids,
        uint256 _amounts
    ) internal {
        require(_to != address(0), "ERC1155Token: transfer to address 0");

        uint256 id = _ids;
        uint256 amount = _amounts;

        uint256 fromBalance = _balances[id][_from];
        require(
            fromBalance >= amount,
            "ERC1155Token: insufficient balance for transfer"
        );
        _balances[id][_from] -= amount;
        _balances[id][_to] += amount;

    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        require(
            to.code.length == 0 ||
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    to,
                    id,
                    amount,
                    data
                ) ==
                IERC1155Receiver.onERC1155Received.selector,
            "ERC1155Token: unsafe recepient"
        );
    }

    function onERC1155Received(
        address,
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address, address, address, uint256, uint256, bytes)"
                )
            );
    }
}