//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;
contract DynamicDiscount {

  function getPercentage (uint _amount, uint _discountRate) internal pure returns (uint)
  {
    return (_amount * _discountRate) / 10000;
  }

  function getDiscount(int _invoiceAmount, int _invoiceCreationDate, int _defaultNetTerm, int _maxDiscontRate, int _paymentDay) public pure returns(int, int) {
    require (_defaultNetTerm >= 86400, "The net term has to be more than one day");
    require (_invoiceAmount > 0, "The invoice must be greater than 0");
    require (_maxDiscontRate > 0, "The discount rate must be greater or equal than 0.01");
    int discount;
    int defaultNetTermInDays = _defaultNetTerm / 86400;
    int invoiceDueDate = ( _invoiceCreationDate + _defaultNetTerm );
    int daysReminding = (invoiceDueDate - _paymentDay) / 86400;
    if ( (daysReminding) >= defaultNetTermInDays) {
      discount = _maxDiscontRate;
    } else if ( ( daysReminding < defaultNetTermInDays && daysReminding > 0) ) {
      discount = daysReminding * _maxDiscontRate / defaultNetTermInDays;
    }
    else  {
      return (_invoiceAmount, 0);
    }
    uint amountDiscounted = getPercentage(uint(_invoiceAmount), uint(discount));
    return ( _invoiceAmount - int(amountDiscounted) , discount);
  }

  function getNonLinearDiscount(uint256 _invoiceAmount, uint256 _defaultNetTerm,  uint256[] memory _discounts, uint256[] memory _duration, uint256 _invoiceCreationDate, uint256 _discountDate)
  public pure returns(uint, uint) {
    require (_defaultNetTerm >= 86400, "The net term has to be more than one day");
    require (_invoiceAmount > 0, "The invoice must be greater than 0");
    uint invoiceDueDate = ( _invoiceCreationDate + _defaultNetTerm );
    uint discount = 0;
    if (_discountDate > invoiceDueDate) {
      return (_invoiceAmount, discount);
    }
    int diff = int(invoiceDueDate - _discountDate);
    int daysElapsed = int(_defaultNetTerm) - diff;
    if (daysElapsed <= 0) {
      uint fullDiscountValue = getPercentage(_invoiceAmount, _discounts[0]);
      return (_invoiceAmount - fullDiscountValue , _discounts[0]);
    }

    uint256 daysCounter = 0;
    for (uint i = 0; i < _duration.length; i++) { //Check that the sum of the steps durations is equal or less than the defaultNetTerm
              if (daysElapsed >= int(daysCounter + 1) && daysElapsed <= int(daysCounter + _duration[i]) ) {
                discount = (_discounts[i]);
              }
              daysCounter = daysCounter + _duration[i];
      }
      require (int(_defaultNetTerm) >= daysElapsed, "Sum of steps duration has to be more than Default Net Term");
      uint amountDiscounted = getPercentage(_invoiceAmount, uint(discount));

      return ( _invoiceAmount - amountDiscounted , discount);
    }
}