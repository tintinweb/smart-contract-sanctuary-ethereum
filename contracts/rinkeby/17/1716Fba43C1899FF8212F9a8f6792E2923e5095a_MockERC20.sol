// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";

contract MockERC20 is ERC20 {

    address public admin;
    
    modifier onlyOwner() {
        require(msg.sender == admin, "WRONG");
        _;
    }
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) 
    {
        admin = msg.sender;
    }

    function mint(address to, uint256 value) public onlyOwner {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public {
        _burn(from, value);
    }
}