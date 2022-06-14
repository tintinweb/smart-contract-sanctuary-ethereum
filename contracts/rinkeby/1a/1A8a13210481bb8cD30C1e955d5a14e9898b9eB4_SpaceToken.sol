pragma solidity ^0.8.0;

import "./ERC777.sol";

contract SpaceToken is ERC777 {
    constructor(uint256 initialSupply, address[] memory defaultOperators)
    ERC777("SpaceToken", "Space", defaultOperators)
    {

        _mint(msg.sender, initialSupply*(10 ** 18), "", "");
        uint256 supply=(initialSupply*5)*(10 ** 16);
//        transfer(defaultOperators[0],supply);
        _mint(defaultOperators[0],supply, "", "");
    }
}