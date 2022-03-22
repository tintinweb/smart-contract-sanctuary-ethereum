/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

pragma solidity ^0.8.4;

contract Array {

    // create a table with 13 columns and undefiend rows
    //
    // column 1: Household ID
    // column 2: PV energy generated (kWh)
    // column 3: PV energy used (kWh)
    // column 4: PV energy sale to the Coliban Water (kWh)
    // column 5: Biding price (c/kWh)
    // column 6: Real price (c/kWh)
    // column 7: Whole sale price (c/kWh)
    // column 8: Win or not
    // column 9: Average biding price (c/kWh)
    // column 10: Average real price (c/kWh)
    // column 11: Biding round
    // column 12: Savings account (cent)
    // column 13: Transaction (cent)
    //
    string[13][] private household_biding_win_records;

    constructor() {
        household_biding_win_records.push(["1", "8.061908185", "2.037500024", "6.024408161", "2.517944145", "2.626345108", "3.9803", "TRUE", "2.577653882", "2.631530737", "17/01/2021 6:00", "19041.04948", "15.8221749"]);   
    }

  function push(string[13] memory item) public {
    household_biding_win_records.push(item);
  }

  function get(uint256 index) public view returns (string[13] memory) {
    return household_biding_win_records[index];
  }


  function remove(uint256 index) public returns (bool) {
    if (index >= 0 && index < household_biding_win_records.length) {
      household_biding_win_records[index] = household_biding_win_records[household_biding_win_records.length - 1];
      household_biding_win_records.pop();
      return true;
    }
    revert("index out of bounds");
  }

    function getLength() public view returns (uint256 length){
        return household_biding_win_records.length;
    }

    // function getAll() public view returns (string[] memory) {
    //     string[2] memory test = ["1","terry"];
    //     // string[2] storage result;
    //     // result.push(test[0]);
    //     // result.push(test[1]);
    //     return test;
    // }
}