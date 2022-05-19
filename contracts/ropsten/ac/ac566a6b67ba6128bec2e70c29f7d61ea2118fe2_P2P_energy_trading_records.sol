/**
 *Submitted for verification at Etherscan.io on 2022-05-19
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
    //   column 8: FiTs(c/kWh)
    //   column 9: Win or not
    //   column 10: Average biding price (c/kWh)
    //   column 11: Average real price (c/kWh)
    //   column 12: Biding round
    //   column 13: Savings account (cent)
    //   column 14: Transaction (cent)
    ////////////////////////////////////////////
    string[14][] private trading_win_records;


    ////////////////////////////////////////////
    //
    //    Constructor
    //         set up house owner (who will buy energy from other households
    //         house owner == energy buyer == contract creator
    //
    ////////////////////////////////////////////
    constructor() {
        houseOwner = payable(msg.sender);
        //trading_win_records.push();   
    }


    ////////////////////////////////////////////
    //
    //   add new record to the system (by house owner ONLY)
    //
    ////////////////////////////////////////////
    function add_new_record(string[14] memory record) public onlyHouseOwner{
        trading_win_records.push(record);
    }

    ////////////////////////////////////////////
    //
    //   get specific record from the system
    //
    ////////////////////////////////////////////
    function get_record(uint256 index) public view returns (string[14] memory) {
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
        
        require( get_eth_balance(houseOwner) >= price_in_ETH);

        _to.transfer(price_in_ETH);
    }

    function get_eth_balance(address eth_address) internal view returns (uint256 length) {
        return address(eth_address).balance;
    }
}