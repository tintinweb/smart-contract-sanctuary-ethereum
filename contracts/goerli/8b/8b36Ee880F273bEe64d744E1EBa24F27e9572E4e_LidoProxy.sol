// SPDX-License-Identifier: MIT
pragma solidity ^0.4.24;

import "./ILido.sol";

contract LidoProxy {
    ILido public lido;

    constructor(ILido _lido) {
        lido = _lido;
    }

   function deposit(address _referral) external payable returns (uint256 StETH) {
       uint256 stMount = lido.submit.value(msg.value)(_referral);
       require(stMount > 0, "deposit failed");
       return stMount;
   }

   function getFees() external view returns (uint16) {
        uint16 fee = lido.getFee();
        return fee;
   }

}