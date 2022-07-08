pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Mintable.sol";
import "./ERC20Burnable.sol";
import "./ERC20Detailed.sol";


contract KWHContract is ERC20,ERC20Detailed,ERC20Mintable,ERC20Burnable {

uint256 public initialSupply = 1000000;

constructor() ERC20Detailed("KiloWattHour","KWH",3) public {
  _mint(msg.sender, initialSupply);
    }

}