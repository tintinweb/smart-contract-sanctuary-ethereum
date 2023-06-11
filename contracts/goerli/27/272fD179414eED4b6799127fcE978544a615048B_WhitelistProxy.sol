// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapRouter {
    function swapExactETHForTokens(uint256, address[] calldata, address, uint256) external payable returns (uint256[] memory);
    // Add more Uniswap functions here
}

contract WhitelistProxy {
    address public uniswapRouter;
    mapping(address => bool) public whitelist;

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Sender is not whitelisted");
        _;
    }

    constructor(address _uniswapRouter) {
        uniswapRouter = _uniswapRouter;
    }

    function addToWhitelist(address _address) public {
        whitelist[_address] = true;
    }

    function removeFromWhitelist(address _address) public {
        whitelist[_address] = false;
    }

    function swapExactETHForTokens(address[] calldata _path, address _to, uint256 _deadline)
        external
        payable
        onlyWhitelisted
        returns (uint256[] memory)
    {
        require(_path.length >= 2, "Invalid path");
        require(_path[0] == address(this), "First path element should be this contract");
        require(_path[_path.length - 1] == _to, "Last path element should be the destination address");

        IUniswapRouter router = IUniswapRouter(uniswapRouter);
        return router.swapExactETHForTokens{value: msg.value}(
            0,
            _path,
            address(this),
            _deadline
        );
    }

    // Add more functions to interact with Uniswap here
}