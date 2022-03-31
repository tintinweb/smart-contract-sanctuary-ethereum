/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


contract AMN1155 {

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    
    // constructor(string memory uri_) {
    //     _setURI(uri_);
    // }

    function _msgSender() internal view returns (address) {
    return msg.sender;
}
    function uri(uint256) public view returns (string memory) {
        return _uri;
    }

   
    function balanceOf(address account, uint256 id) public view returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    
    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 id,
    //     uint256 amount,
    //     bytes memory data
    // ) public {
    //     require(
    //         from == _msgSender() || isApprovedForAll(from, _msgSender()),
    //         "ERC1155: caller is not owner nor approved"
    //     );
    // }

    
    // function safeBatchTransferFrom(
    //     address from,
    //     address to,
    //     uint256[] memory ids,
    //     uint256[] memory amounts,
    //     bytes memory data
    // ) public {
    //     require(
    //         from == _msgSender() || isApprovedForAll(from, _msgSender()),
    //         "ERC1155: transfer caller is not owner nor approved"
    //     );
    // }

    
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) public{
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

    }

  
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public{
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

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


    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }


    function _mint(
        address to,
        uint256 id,
        uint256 amount
    ) public {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

    }
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) public {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }


    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();


        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) public {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }


    

    
}