// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IMediaManagerAccess.sol";

contract OwnerAccess is IMediaMediaManagerAccess {
   address public owner;

   constructor() {
      owner = msg.sender;
   }

   function hasMediaManagerAccess(address _addr) external view override returns(bool) {
      return _addr == owner;
   }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMediaMediaManagerAccess {
   function hasMediaManagerAccess(address) external view returns(bool);
}