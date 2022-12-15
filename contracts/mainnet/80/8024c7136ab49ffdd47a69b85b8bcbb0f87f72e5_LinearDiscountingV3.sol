/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

contract LinearDiscountingV3 {

  struct Token {
    uint discount;
    uint duration;
  }

  function getDiscount(uint _invoiceAmount, uint _invoiceDueDate, uint _defaultNetTerm, uint _maxDiscontRate, int _paymentDay) public pure returns(uint, uint) {
    require (_defaultNetTerm >= 86400, "The net term has to be more than one day");
    require (_invoiceAmount > 0, "The invoice must be greater than 0");
    require (_maxDiscontRate > 0, "The discount rate must be greater or equal than 0.01");
    int disscount;
    int defaultNetTermInDays = int((_defaultNetTerm / 86400));
    int daysReminding = int(( int (_invoiceDueDate) - _paymentDay) / 86400);
    if ( (daysReminding) >= defaultNetTermInDays) {
      disscount = int(_maxDiscontRate);
    } else if ( ( (daysReminding) < defaultNetTermInDays && daysReminding > 0) ) {
      disscount = daysReminding * int(_maxDiscontRate) / defaultNetTermInDays;
    }
    else  {
      return (_invoiceAmount, 0);
    }
    uint amountDiscounted = getPercentage(_invoiceAmount, uint(disscount));
    return ( _invoiceAmount - amountDiscounted , uint(disscount));
  }

  function getPercentage (uint _amount, uint _discountRate)
  internal pure returns (uint)
  {
    return (_amount * _discountRate) / 10000;
  }

  function getNonLinearDiscount(uint256 _invoiceAmount, uint256 _defaultNetTerm,  uint256[] memory _discounts, uint256[] memory _duration, uint256 _invoiceDueDate, uint256 _discountDate)
  public pure returns(uint, uint) {
    require (_defaultNetTerm >= 86400, "The net term has to be more than one day");
    require (_invoiceAmount > 0, "The invoice must be greater than 0");
    uint discount = 0;
    if (_discountDate > _invoiceDueDate) {
      return (_invoiceAmount, discount);
    }
    int diff = int(_invoiceDueDate) - int(_discountDate);
    int daysElapsed = int(_defaultNetTerm) - diff;
    if (daysElapsed <= 0) {
      uint fullDiscountValue = getPercentage(_invoiceAmount, _discounts[0]);
      return (_invoiceAmount - fullDiscountValue , _discounts[0]);
    }

    uint256 daysCounter = 0;
    for (uint i = 0; i < _duration.length; i++) { //Check that the sum of the steps durations is equal or less than the defaultNetTerm
              if (daysElapsed >= int(daysCounter + 1 days) && daysElapsed <= int(daysCounter + _duration[i]) ) {
                discount = _discounts[i];
              }
              daysCounter = daysCounter + _duration[i];
      }
      require (int(_defaultNetTerm) >= daysElapsed, "Sum of steps duration has to be more than Default Net Term");
      uint amountDiscounted = getPercentage(_invoiceAmount, uint(discount));

      return ( _invoiceAmount - amountDiscounted , uint(discount));
    }
}