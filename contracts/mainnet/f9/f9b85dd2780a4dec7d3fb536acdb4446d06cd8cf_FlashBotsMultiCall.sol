//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "./Interfaces.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// This contract simply calls multiple targets sequentially, ensuring WETH balance before and after

contract FlashBotsMultiCall {
    address private immutable owner;
    address private immutable executor1;
    address private immutable executor2;
    IWETH private constant WETH =
        IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address private constant ETH_address =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    modifier onlyExecutor() {
        require(msg.sender == executor1 || msg.sender == executor2);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _executor1, address _executor2) payable {
        owner = msg.sender;
        executor1 = _executor1;
        executor2 = _executor2;
        if (msg.value > 0) {
            WETH.deposit{value: msg.value}();
        }
    }

    receive() external payable {}

    function uniswapWeth(
        uint256 _wethAmountToFirstMarket,
        address[] memory _targets,
        bytes[] memory _payloads
    ) external payable onlyExecutor {
        require(_targets.length == _payloads.length);
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
        WETH.transfer(_targets[0], _wethAmountToFirstMarket);
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool _success, bytes memory _response) = _targets[i].call(
                _payloads[i]
            );
            require(_success);
            _response;
        }

        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        require(_wethBalanceAfter > _wethBalanceBefore);
    }

    function call(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) external payable onlyOwner returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success);
        return _result;
    }

    function withdraw(address token) external onlyOwner {
        if (token == ETH_address) {
            uint256 bal = address(this).balance;
            payable(msg.sender).transfer(bal);
        } else if (token != ETH_address) {
            uint256 bal = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(address(msg.sender), bal);
        }
    }
}