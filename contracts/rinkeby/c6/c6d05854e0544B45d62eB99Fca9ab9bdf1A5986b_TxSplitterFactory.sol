// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface TokenInterface {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract TxSplitter {
    address[] public owners;
    uint256[] public percentages;

    constructor(address[] memory _owners, uint256[] memory _percentages) {
        owners = _owners;
        percentages = _percentages;
    }

    /// @dev Allows contract to receive ETH
    receive() external payable {
        uint256 total = msg.value;
        for (uint256 i = 0; i < owners.length; i++) {
            uint256 amount = (total * percentages[i]) / 100;
            payable(owners[i]).transfer(amount);
        }
    }

    function withdrawTokens(address tokenAddress) public {
        uint256 total = TokenInterface(tokenAddress).balanceOf(address(this));
        for (uint256 i = 0; i < owners.length; i++) {
            uint256 amount = (total * percentages[i]) / 100;
            TokenInterface(tokenAddress).transfer(owners[i], amount);
        }
    }
}

contract TxSplitterFactory {
    mapping(address => address[]) public splitters;

    constructor() {}

    function createSplitter(
        address[] calldata _owners,
        uint256[] calldata _percentages
    ) public returns (address) {
        address newSplitter = address(new TxSplitter(_owners, _percentages));
        for (uint256 i = 0; i < _owners.length; i++) {
            splitters[_owners[i]].push(newSplitter);
        }
        return newSplitter;
    }

    function splitTokens(address tokenAddress, address txSplitterAddress)
        public
    {
        TxSplitter(payable(txSplitterAddress)).withdrawTokens(tokenAddress);
    }
}