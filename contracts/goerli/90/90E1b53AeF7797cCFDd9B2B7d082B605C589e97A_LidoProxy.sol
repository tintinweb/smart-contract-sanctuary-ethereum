// SPDX-License-Identifier: MIT
pragma solidity ^0.4.24;

import "./ILido.sol";

contract LidoProxy {
    ILido public lido;

    constructor(address _lido) {
        lido = ILido(_lido);
    }

   function deposit(address _referral) external payable returns (uint256 StETH) {
       require(msg.gas < 3000000, "Gas limit exceeded");
       return lido.submit(_referral);
   }

}