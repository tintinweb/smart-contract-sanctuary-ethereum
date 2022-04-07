//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract sSpellRatio  {

    IERC20 public constant SSPELL = IERC20(0x26FA3fFFB6EfE8c1E69103aCb4044C26B9A106a9);
    IERC20 public constant SPELL = IERC20(0x090185f2135308BaD17527004364eBcC2D37e5F6);

    function toSSpell(uint256 amount) public view returns (uint256) {
        return amount * SPELL.balanceOf(address(SSPELL)) / SSPELL.totalSupply();
    }
}