//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ILendingPoolAddressesProvider.sol";

contract Bank {
    
    ILendingPoolAddressesProvider provider;
    address pool;

    constructor() {
        provider = ILendingPoolAddressesProvider(0x88757f2f99175387aB4C6a4b3067c77A695b0349);
        pool = provider.getLendingPool();
    }

    function myBalance() public view returns(uint){
        return msg.sender.balance;
    }

}