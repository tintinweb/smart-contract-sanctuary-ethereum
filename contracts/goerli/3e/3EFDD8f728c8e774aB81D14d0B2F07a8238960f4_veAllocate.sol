pragma solidity ^0.8.12;
// Copyright BigchainDB GmbH and Ocean Protocol contributors
// SPDX-License-Identifier: (Apache-2.0 AND CC-BY-4.0)
// Code is Apache-2.0 and docs are CC-BY-4.0

contract veAllocate {
    mapping(address => mapping(address => mapping(uint256 => uint256)))
        private veAllocation;
    mapping(address => uint256) private _totalAllocation;

    event AllocationSet(
        address indexed sender,
        address indexed nft,
        uint256 indexed chainId,
        uint256 amount
    );

    event AllocationSetMultiple(
        address indexed sender,
        address[] nft,
        uint256[] chainId,
        uint256[] amount
    );

    function getveAllocation(
        address user,
        address nft,
        uint256 chainid
    ) external view returns (uint256) {
        return veAllocation[user][nft][chainid];
    }

    function getTotalAllocation(address user)
        public
        view
        returns (uint256)
    {
        return _totalAllocation[user];
    }

    function setAllocation(
        uint256 amount,
        address nft,
        uint256 chainId
    ) external {
        _totalAllocation[msg.sender] =
            _totalAllocation[msg.sender] +
            amount -
            veAllocation[msg.sender][nft][chainId];

        require(_totalAllocation[msg.sender] <= 10000, "Max Allocation");
        veAllocation[msg.sender][nft][chainId] = amount;
        emit AllocationSet(msg.sender, nft, chainId, amount);
    }

    function setBatchAllocation(
        uint256[] calldata amount,
        address[] calldata nft,
        uint256[] calldata chainId
    ) external {
        require(amount.length <= 150, 'Too Many Operations');
        require(amount.length == nft.length, 'Nft array size missmatch');
        require(amount.length == chainId.length, 'Chain array size missmatch');
        for (uint256 i = 0; i < amount.length; i++) {
            _totalAllocation[msg.sender] =
                _totalAllocation[msg.sender] +
                amount[i] -
                veAllocation[msg.sender][nft[i]][chainId[i]];
            veAllocation[msg.sender][nft[i]][chainId[i]] = amount[i];
        }
        require(_totalAllocation[msg.sender] <= 10000, "Max Allocation");
        emit AllocationSetMultiple(msg.sender, nft, chainId, amount);
    }
}