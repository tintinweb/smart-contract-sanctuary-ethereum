// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


   /*$     /$$$$$$$   /$$$$$$   /$$        /$$         /$$$$$$ 
  /$$$$$$  | $$__  $$ |_  $$_/ | $$       | $$        /$$__  $$
 /$$__  $$ | $$  \ $$   | $$   | $$       | $$       | $$  \__/
| $$  \__/ | $$$$$$$    | $$   | $$       | $$       |  $$$$$$ 
|  $$$$$$  | $$__  $$   | $$   | $$       | $$        \____  $$
 \____  $$ | $$  \ $$   | $$   | $$       | $$        /$$  \ $$
 /$$  \ $$ | $$$$$$$/  /$$$$$$ | $$$$$$$$ | $$$$$$$$ |  $$$$$$/
|  $$$$$$/ |_______/  |______/ |________/ |________/  \______/ 
 \_  $$_/                                                 
   \_*/                                                   


import "./ERC20.sol";
import "./Ownable.sol";

/**
 * @dev ERC20 Contract Implementation
 */
contract Bills is ERC20("BILLS", "BILLS"), Ownable {
    mapping(address => bool) public managers;

    /**
    * @dev Function adds manager allowing interaction with contract.
    */
    function addManager(address _address) external onlyOwner {
        managers[_address] = true;
    }

    /**
    * @dev Function removes manager, removing accessibility to contract.
    */
    function removeManager(address _address) external onlyOwner {
        managers[_address] = false;
    }

    /**
    * @dev Function mints tokens to specified address.
    */
    function mint(address _to, uint _amount) external {
        require(managers[msg.sender], "This address is not allowed to interact with the contract");
        _mint(_to, _amount);
    }
    
    /**
    * @dev Function burns tokens from specified address.
    */
    function burn(address _from, uint _amount) external {
        require(managers[msg.sender], "This address is not allowed to interact with the contract");
        _burn(_from, _amount);
    }
}