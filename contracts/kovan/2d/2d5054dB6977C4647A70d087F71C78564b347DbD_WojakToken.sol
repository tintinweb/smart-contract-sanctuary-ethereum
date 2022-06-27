// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
// import "./Ownable.sol";

contract WojakToken is ERC20("Wojak Token", "WJK") {

    function mint(address _to, uint256 _amount) public { // onlyOwner is required in product version
        _mint(_to, _amount);
    }
}