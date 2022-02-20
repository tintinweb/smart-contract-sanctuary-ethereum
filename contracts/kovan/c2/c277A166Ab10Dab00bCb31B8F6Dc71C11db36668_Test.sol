/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8;
pragma experimental ABIEncoderV2;

contract Test {
    function uniswapWeth(uint256 _amountToFirstMarket, bytes memory _params, uint256 additionalDebt) public payable {
      (uint256 _ethAmountToCoinbase, address[] memory _targets, bytes[] memory _payloads) = abi.decode(_params, (uint256, address[], bytes[]));
      require(_targets.length == _payloads.length, "Targets and payloads discrepancy");

      for (uint256 i = 0; i < _targets.length; i++) {
          (bool _success, bytes memory _response) = _targets[i].call(_payloads[i]);
          require(_success, "Failed target call"); _response;
      }
    }
}