// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity >=0.6.0 <0.8.16;

import "./ERC20.sol";

contract verify3 is ERC20 {
    address public admin; 
    constructor() ERC20('Verify3', 'VED3') {
        _mint(msg.sender, 3333 * 10 ** 18);
        admin = msg.sender;
    }

    function mint(address to, uint amount) external {
         require(msg.sender == admin,'only admin');
         _mint(to, amount);   
    }
      function burn(uint amount) external {
          _burn(msg.sender, amount);
      }
}