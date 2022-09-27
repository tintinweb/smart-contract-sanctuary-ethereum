// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './BEP20.sol';

contract USDCToken is BEP20('USD Coin', 'USDC') {
    constructor() public {
        uint256 _initialSupply = 1000000000e18;
        _mint(owner(), _initialSupply);
    }

    function burn(uint256 amount) external returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function burnFrom(address spender, uint256 amount) external returns (bool) {
        _burnFrom(spender, amount);
        return true;
    }

    /* ========== OWNER FUNCTIONS ========== */

    function mint(uint256 amount) external onlyOwner returns (bool) {
        require(amount > 0, "Cannot mint 0");
        _mint(owner(), amount);
        return true;
    }

    function recoverToken(address tokenAddress, uint256 amount) external onlyOwner returns (bool) {
        return IBEP20(tokenAddress).transfer(owner(), amount);
    }
}