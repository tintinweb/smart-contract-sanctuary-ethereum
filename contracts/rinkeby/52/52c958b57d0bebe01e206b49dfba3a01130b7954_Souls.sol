// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Souls is ERC20, Ownable {
    
    mapping(address => bool) public allowedAddresses;

    constructor() ERC20("Gold", "GLD") {}
    
    function burn(address user, uint256 amount) external {
        require(allowedAddresses[msg.sender], "Address cannot burn tokens");
        require(msg.sender == user, "Only your own tokens can be burnt");
        _burn(user, amount);
    }

    function mint(address to, uint256 value) external {
        require(allowedAddresses[msg.sender], "Address cannot mint tokens");
        _mint(to, value);
    }

    function setAllowedAddresses(address _address, bool _access) public onlyOwner {
        allowedAddresses[_address] = _access;
    }
}