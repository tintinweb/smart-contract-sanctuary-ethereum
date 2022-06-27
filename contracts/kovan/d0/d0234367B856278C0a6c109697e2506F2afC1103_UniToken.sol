// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
// import "./Ownable.sol";

contract UniToken is ERC20("Uni Token", "UNI") {

    function mint(address _to, uint256 _amount) public { // onlyOwner is required in product version
        _mint(_to, _amount);
    }
}