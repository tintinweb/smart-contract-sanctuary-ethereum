/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

pragma solidity 0.8.4;
// eip-1014 sample, deployment contract using CREATE2 opcode, taken from Miguel Mota, https://github.com/miguelmota/solidity-create2-example

contract DeploymentFactory {
  event Deployed(address addr, uint256 salt);

  function deploy(bytes memory code, uint256 salt) public {
    address addr;
    assembly {
      addr := create2(0, add(code, 0x20), mload(code), salt)
      if iszero(extcodesize(addr)) {
        revert(0, 0)
      }
    }

    emit Deployed(addr, salt);
  }
}