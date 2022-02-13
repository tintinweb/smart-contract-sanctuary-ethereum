// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC20Burnable.sol";

contract SevToken is ERC20Burnable {
    constructor() ERC20("SeveraDAO", "SEV") {
        _mint(0x085Bad3Ed8154a90cedC3D14cf53ea70C1CC4284, 100_000_000 * (10 ** decimals()));
    }
}