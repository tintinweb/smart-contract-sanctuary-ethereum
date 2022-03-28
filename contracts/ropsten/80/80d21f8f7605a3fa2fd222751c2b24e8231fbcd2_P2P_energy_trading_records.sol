/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract P2P_energy_trading_records {

    ////////////////////////////////////////////
    //
    //  PV energy buyer == house owner == contract creator
    //  house owner cannot be changed after deployed
    //
    ////////////////////////////////////////////
    address payable public houseOwner;

    modifier onlyHouseOwner() { // for the function(s) that can only be performed by house owner
        require(msg.sender == houseOwner);
        _;
    }

    ////////////////////////////////////////////
    //   create a table with 13 columns and undefiend rows
    //
    //   column 1: Household ID
    //   column 2: PV energy generated (kWh)
    //   column 3: PV energy used (kWh)
    //   column 4: PV energy sale to the Coliban Water (kWh)
    //   column 5: Biding price (c/kWh)
    //   column 6: Real price (c/kWh)
    //   column 7: Whole sale price (c/kWh)
    //   column 8: Win or not
    //   column 9: Average biding price (c/kWh)
    //   column 10: Average real price (c/kWh)
    //   column 11: Biding round
    //   column 12: Savings account (cent)
    //   column 13: Transaction (cent)
    ////////////////////////////////////////////
    string[13][] private trading_win_records;

    ////////////////////////////////////////////
    //
    //    Constructor
    //         set up house owner (who will buy energy from other households
    //         house owner == energy buyer == contract creator
    //
    ////////////////////////////////////////////
    constructor() {
        houseOwner = payable(msg.sender);
    }

    ////////////////////////////////////////////
    //
    //   add (or delete new record to the system (by house owner ONLY)
    //
    ////////////////////////////////////////////
    function add_new_record(string[13] memory record) public onlyHouseOwner{
        trading_win_records.push(record);
    }

    ////////////////////////////////////////////
    //
    //   get specific record from the system
    //
    ////////////////////////////////////////////
    function get_record(uint256 index) public view returns (string[13] memory) {
        return trading_win_records[index];
    }

    ////////////////////////////////////////////
    //
    //   get length of all records in the system
    //
    ////////////////////////////////////////////
    function get_length_of_records() public view returns (uint256 length) {
        return trading_win_records.length;
    }

    ////////////////////////////////////////////
    //
    //   house owner can pay specific house hold id (house owner only)
    //
    //   transfer ether coin between accounts
    //   from:   msg.sender
    //   amount: price_in_ETH
    //   to:     _to
    //
    ////////////////////////////////////////////
    function pay_household_ETH(address payable _to, uint256 price_in_ETH) payable public onlyHouseOwner{
        require( address(houseOwner).balance >= price_in_ETH);
        _to.transfer(price_in_ETH);
    }
}