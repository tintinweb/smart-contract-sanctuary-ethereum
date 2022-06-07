// File: contracts/BulkRenewal.sol
// Deployed: 0xfF252725f6122A92551A5FA9a6b6bf10eb0Be035
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import { IETHRegistrarController } from "../ENSBulkController/interfaces/IETHRegistrarController.sol";

contract BulkRenewal {

    function getController() internal pure returns(IETHRegistrarController) {
        return IETHRegistrarController(0x283Af0B28c62C092C9727F1Ee09c02CA627EB7F5);
    }

    function rentPrice(string[] calldata names, uint duration) external view returns(uint total) {
        IETHRegistrarController controller = getController();
        for(uint i = 0; i < names.length; i++) {
            total += controller.rentPrice(names[i], duration);
        }
    }

    function renewAll(string[] calldata names, uint duration) external payable {
        IETHRegistrarController controller = getController();
        for(uint i = 0; i < names.length; i++) {
            uint cost = controller.rentPrice(names[i], duration);
            controller.renew{value: cost}(names[i], duration);
        }
        // Send any excess funds back
        payable(msg.sender).transfer(address(this).balance);
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

// SPDX-License-Identifier: MIT
// https://0xinside.xyz
// Twitter: @0xinside

pragma solidity ^0.8.13;

import { IETHRegistrarController } from "./interfaces/IETHRegistrarController.sol";

contract ENSBulkController {
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

// SPDX-License-Identifier: o0o0o0o0o00o
// lcfr.eth
// birdapp/github: @lcfr_eth
// deployed: 0x22256a2812f7a771b8b224e4fb34c6f245f3e330
// http://ens.vision

pragma solidity ^0.8.7;

import { IETHRegistrarController } from "../ENSBulkController/interfaces/IETHRegistrarController.sol";

contract ENSVisionBulk {

  address public ENS = 0x283Af0B28c62C092C9727F1Ee09c02CA627EB7F5;

  IETHRegistrarController controller = IETHRegistrarController(ENS);

  address owner;
  address multisig;

  constructor(address _multisig) {
    owner = msg.sender;
    multisig = _multisig;
  }

  modifier onlyOwner {
    require(msg.sender == owner, "not owner.");
    _;
  }

  function _updateOwner(address _newOwner) external onlyOwner {
    owner = _newOwner;
  }

  function _adminWithdraw() external onlyOwner {
    (bool sent,) = multisig.call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
  }

  function commitAll(bytes32[] calldata _commitments) external {
    for ( uint i = 0; i < _commitments.length; ++i ) {
      controller.commit(_commitments[i]);
    }
  }

  function registerAll(string[] calldata _names, bytes32[] calldata _secrets, uint256 _duration) external payable { 
    require(_names.length == _secrets.length, "names/secrets length mismatch");

    for( uint i = 0; i < _names.length; ++i ) {
      uint price = controller.rentPrice(_names[i], _duration);
      controller.register{value: price}(_names[i], msg.sender, _duration, _secrets[i]);
    }

  }

  function priceAll(string[] calldata _names, uint256 _duration) external view returns(uint total) {
    for (uint i = 0; i < _names.length; ++i) {
      total += controller.rentPrice(_names[i], _duration);
    }
  }

  function multicall(address _who, bytes[] calldata _what) external returns(bytes[] memory results) {
    results = new bytes[](_what.length);
    for(uint i = 0; i < _what.length; ++i) {
        (bool success, bytes memory result) = _who.delegatecall(_what[i]);
        require(success);
        results[i] = result;
    }
    return results;
  }

}