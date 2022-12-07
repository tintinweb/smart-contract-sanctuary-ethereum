// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC20.sol";
import {ERC20} from "./ERC20.sol";

contract TestERC20 is ERC20 {

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function mint(address _account, uint256 _quantity) external {
        _mint(_account, _quantity);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}