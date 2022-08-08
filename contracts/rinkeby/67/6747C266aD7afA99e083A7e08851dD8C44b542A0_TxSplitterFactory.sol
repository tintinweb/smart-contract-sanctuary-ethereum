// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ERC20TokenInterface {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract TxSplitter {
    string public name;
    uint256 public totalSharePoints;

    address[] private _shareOwners;
    uint256[] private _sharePoints;

    constructor(
        string memory _name,
        address[] memory __shareOwners,
        uint256[] memory __sharePoints
    ) {
        require(
            __shareOwners.length == __sharePoints.length,
            "TxSplitter: share owners and shares points length mismatch"
        );
        require(
            __shareOwners.length > 1,
            "TxSplitter: must indicate at least 2 addresses to split the transactions"
        );

        // we won't require the total share points to be 100,
        // because we want to let people divide in thirds.
        // What matters is the total, then we'll split proportionally.

        name = _name;
        _shareOwners = __shareOwners;
        _sharePoints = __sharePoints;
        for (uint256 i = 0; i < _shareOwners.length; i++) {
            require(
                _sharePoints[i] > 0,
                "TxSplitter: share owner must have at least 1 share point"
            );
            totalSharePoints += _sharePoints[i];
        }
    }

    function getOwners() external view returns (address[] memory) {
        return _shareOwners;
    }

    function getSharePoints() external view returns (uint256[] memory) {
        return _sharePoints;
    }

    /// @dev Allows contract to receive ETH
    receive() external payable {
        uint256 total = msg.value;
        for (uint256 i = 0; i < _shareOwners.length; i++) {
            uint256 amount = (total * _sharePoints[i]) / totalSharePoints;
            payable(_shareOwners[i]).transfer(amount);
        }
    }

    function withdrawERC20Tokens(address tokenAddress) external {
        uint256 total = ERC20TokenInterface(tokenAddress).balanceOf(
            address(this)
        );
        for (uint256 i = 0; i < _shareOwners.length; i++) {
            uint256 amount = (total * _sharePoints[i]) / totalSharePoints;
            ERC20TokenInterface(tokenAddress).transfer(_shareOwners[i], amount);
        }
    }
}

contract TxSplitterFactory {
    mapping(address => address[]) private _splitters;
    mapping(address => address[]) private _splitterCreators;

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
            _splitters[_shareOwners[i]].push(newSplitter);
        }
        _splitterCreators[msg.sender].push(newSplitter);
        ++totalSpitters;
        return newSplitter;
    }

    function getSplittersByMemberAddress(address userAddress)
        external
        view
        returns (address[] memory)
    {
        return _splitters[userAddress];
    }

    function getDeployedSplittersByAddress(address userAddress)
        external
        view
        returns (address[] memory)
    {
        return _splitterCreators[userAddress];
    }

    function withdrawERC20fromSplitter(
        address tokenAddress,
        address txSplitterAddress
    ) external {
        TxSplitter(payable(txSplitterAddress)).withdrawERC20Tokens(
            tokenAddress
        );
    }
}