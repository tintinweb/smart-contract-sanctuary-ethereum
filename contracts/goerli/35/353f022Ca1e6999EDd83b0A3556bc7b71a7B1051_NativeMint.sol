//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INativeMinter.sol";
import "./IAllowList.sol";

contract NativeMint is INativeMinter {
  event HeyLookItWorks(bytes4 _function, address _address, uint256 _amount);

  function mintNativeCoin(address addr, uint256 amount) external override {
    emit HeyLookItWorks(INativeMinter.mintNativeCoin.selector, addr, amount);
  }

  function setAdmin(address addr) external override {
    emit HeyLookItWorks(IAllowList.setAdmin.selector, addr, uint256(0));
  }

  // Set [addr] to be enabled on the minter list
  function setEnabled(address addr) external override {
    emit HeyLookItWorks(IAllowList.setEnabled.selector, addr, uint256(0));
  }

  // Set [addr] to have no role over the minter list
  function setNone(address addr) external override {
    emit HeyLookItWorks(IAllowList.setNone.selector, addr, uint256(0));
  }

  // Read the status of [addr]
  function readAllowList(address addr)
    external
    view
    override
    returns (uint256)
  {
    return uint256(420);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IAllowList.sol";

interface INativeMinter is IAllowList {
  // Mint [amount] number of native coins and send to [addr]
  function mintNativeCoin(address addr, uint256 amount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAllowList {
  // Set [addr] to have the admin role over the minter list
  function setAdmin(address addr) external;

  // Set [addr] to be enabled on the minter list
  function setEnabled(address addr) external;

  // Set [addr] to have no role over the minter list
  function setNone(address addr) external;

  // Read the status of [addr]
  function readAllowList(address addr) external view returns (uint256);
}