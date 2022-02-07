// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract RCC is ERC20("Royal Ceramic Club ERC20 Token", "$RCC"), Ownable {
    mapping(address => bool) public managers;

    function addManager(address _address) external onlyOwner {
        managers[_address] = true;
    }

    function removeManager(address _address) external onlyOwner {
        managers[_address] = false;
    }

    function mint(address _to, uint256 _amount) external {
        require(
            managers[msg.sender] == true,
            "This address is not allowed to interact with the contract"
        );
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        require(
            managers[msg.sender] == true || msg.sender == _from,
            "This address is not allowed to interact with the contract"
        );
        _burn(_from, _amount);
    }
}