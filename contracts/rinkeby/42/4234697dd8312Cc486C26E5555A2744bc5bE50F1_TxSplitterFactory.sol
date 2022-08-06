// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface TokenInterface {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract TxSplitter {
    string public name;
    address[] private shareOwners;
    uint256[] private percentages;
    uint256 public totalPercentage;

    constructor(
        string memory _name,
        address[] memory _shareOwners,
        uint256[] memory _percentages
    ) {
        name = _name;
        shareOwners = _shareOwners;
        percentages = _percentages;
        for (uint256 i = 0; i < _shareOwners.length; i++) {
            totalPercentage += _percentages[i];
        }
    }

    function getOwners() external view returns (address[] memory) {
        return shareOwners;
    }

    function getPercentages() external view returns (uint256[] memory) {
        return percentages;
    }

    /// @dev Allows contract to receive ETH
    receive() external payable {
        uint256 total = msg.value;
        for (uint256 i = 0; i < shareOwners.length; i++) {
            uint256 amount = (total * percentages[i]) / totalPercentage;
            payable(shareOwners[i]).transfer(amount);
        }
    }

    function withdrawTokens(address tokenAddress) external {
        uint256 total = TokenInterface(tokenAddress).balanceOf(address(this));
        for (uint256 i = 0; i < shareOwners.length; i++) {
            uint256 amount = (total * percentages[i]) / totalPercentage;
            TokenInterface(tokenAddress).transfer(shareOwners[i], amount);
        }
    }
}

contract TxSplitterFactory {
    mapping(address => address[]) private splitters;
    mapping(address => address[]) private splitterCreators;

    uint256 public totalSpitters = 0;

    constructor() {}

    function createSplitter(
        string calldata _name,
        address[] calldata _shareOwners,
        uint256[] calldata _sharePoints
    ) public returns (address) {
        address newSplitter = address(
            new TxSplitter(_name, _shareOwners, _sharePoints)
        );
        for (uint256 i = 0; i < _shareOwners.length; i++) {
            require(_sharePoints[i] > 0, "Cannot withdraw 0%");
            splitters[_shareOwners[i]].push(newSplitter);
        }
        splitterCreators[msg.sender].push(newSplitter);
        ++totalSpitters;
        return newSplitter;
    }

    function getSplittersByMemberAddress(address userAddress)
        external
        view
        returns (address[] memory)
    {
        return splitters[userAddress];
    }

    function getSplittersDeployedByAddress(address userAddress)
        external
        view
        returns (address[] memory)
    {
        return splitterCreators[userAddress];
    }

    function splitTokens(address tokenAddress, address txSplitterAddress)
        external
    {
        TxSplitter(payable(txSplitterAddress)).withdrawTokens(tokenAddress);
    }
}