// SPDX-License-Identifier: MIT
// https://0xinside.xyz
// Twitter: @0xinside

pragma solidity ^0.8.13;

import { IETHRegistrarController } from "./interfaces/IETHRegistrarController.sol";

contract ENSBulkTool {
  IETHRegistrarController public immutable controller = IETHRegistrarController(0x283Af0B28c62C092C9727F1Ee09c02CA627EB7F5);

  function commitAll(bytes32[] calldata commitments) external {
    for (uint256 i = 0; i < commitments.length; i++) {
      controller.commit(commitments[i]);
    }
  }

  function registerAll(string[] calldata names, uint256 duration, bytes32 secret) external payable {
    for (uint256 i = 0; i < names.length; i++) {
      uint256 cost = controller.rentPrice(names[i], duration);
      controller.register{ value: cost }(names[i], msg.sender, duration, secret);
    }
    payable(msg.sender).transfer(address(this).balance);
  }

  function renewAll(string[] calldata names, uint256 duration) external payable {
    for (uint256 i = 0; i < names.length; i++) {
      uint256 cost = controller.rentPrice(names[i], duration);
      controller.renew{ value: cost }(names[i], duration);
    }
    payable(msg.sender).transfer(address(this).balance);
  }

  function priceAll(string[] calldata names, uint256 duration) external view returns (uint256 total) {
    for (uint256 i = 0; i < names.length; i++) {
      total += controller.rentPrice(names[i], duration);
    }
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IETHRegistrarController {
    function commit(bytes32 commitment) external;

    function register(string calldata name, address owner, uint256 duration, bytes32 secret) external payable;

    function renew(string calldata name, uint256 duration) external payable;

    function rentPrice(string memory name, uint256 duration) external view returns (uint256);
}