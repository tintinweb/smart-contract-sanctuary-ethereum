// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IERC20.sol";
import "./ERC20.sol";

contract Usdt is ERC20 {
    IERC20 private control;

    constructor() ERC20("DemoTether", "USDT") {
        control = IERC20(address(this));
    }

    function faucetUSDT(address to, uint256 amount) public {
        require(to != address(0x0));
        _mint(to, amount * 1e6);
    }


    function faucet(address to, uint256 amount) public {
        require(to != address(0x0));
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
      return 6;
    }
}