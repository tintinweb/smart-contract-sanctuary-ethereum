// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./lib/Base1155NFT.sol";

contract Representative1155NFT is Base1155NFT {
    address public itemLocker;
    address public owner;

    modifier onlyItemLocker() {
        require(msg.sender == itemLocker, "rNFT: Only ItemLocker");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "rNFT: Only Owner");
        _;
    }

    constructor() Base1155NFT() {
        owner = msg.sender;
    }

    function setItemLocker(address _itemLocker) external onlyOwner {
        itemLocker = _itemLocker;
    }

    function mint(address _player, uint256 _id, uint256 _amount)
        external
        onlyItemLocker
    {
        _mint(_player, _id, _amount);
    }

    function burn(address _player, uint256 _id, uint256 _amount) external onlyItemLocker {
        _burn(_player, _id, _amount);
    }

    function setUri(uint256 _id, string memory newuri) external onlyItemLocker {
        _setURI(_id, newuri);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Base1155NFT {
  
    mapping(uint256 => mapping(address => uint256)) private _balances;

    mapping(uint256 => string) public uris;


    function uri(uint256 _id) public view returns (string memory) {
        return uris[_id];
    }

    function balanceOf(address account, uint256 id)
        public
        view
        returns (uint256)
    {
        require(
            account != address(0),
            "Base1155NFT: address zero is not a valid owner"
        );
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "Base1155NFT: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function _setURI(uint256 _id,string memory newuri) internal virtual {
        uris[_id] = newuri;
    }

    function _mint(
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(to != address(0), "Base1155NFT: mint to the zero address");

        _balances[id][to] += amount;
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(to != address(0), "Base1155NFT: mint to the zero address");
        require(
            ids.length == amounts.length,
            "Base1155NFT: ids and amounts length mismatch"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "Base1155NFT: burn from the zero address");
        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "Base1155NFT: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
    }

    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "Base1155NFT: burn from the zero address");
        require(
            ids.length == amounts.length,
            "Base1155NFT: ids and amounts length mismatch"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "Base1155NFT: burn amount exceeds balance"
            );
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }
    }
}