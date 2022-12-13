/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


// 
// ERC20 methods stub required by this contract
interface TOKEN {
  function balanceOf(address) external view returns (uint256);
  function transfer(address, uint256) external returns (bool);
}

contract StaffTokensScheme {
  mapping(address => string) private AccountsByToken;
  mapping(bytes32 => uint256) private NextPaymentDue;
  mapping(bytes32 => uint256) private NumPaymentsRemaining;
  mapping(bytes32 => uint256) private FirstPaymentAmount;
  mapping(bytes32 => uint256) private RegularPaymentAmount;
  address public owner;

  error OnlyOwner();
  error InsufficientFunds();
  error InvalidDate();

  modifier onlyOwner {
    if (msg.sender != owner) revert OnlyOwner();
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  function changeOwner(address newOwner) external onlyOwner {
    // not zero
    owner = newOwner;
  }

  function drain(address token) external onlyOwner {
    TOKEN Token = TOKEN(token);
    Token.transfer(msg.sender, Token.balanceOf(address(this)));
  }

  function dateToTimestamp(uint256 day, uint256 month, uint256 year) public pure returns (uint256 timestamp) {
    if (day == 0 || day > 31 || month == 0 || month > 12 || year < 1970) revert InvalidDate();
    int256 d = int256(day);
    int256 y = int256(year);
    int256 m = int256(month);
    int256 _days = d-32075+(1461*(y+4800+(m-14)/12))/4+(367*(m-2-((m-14)/12)*12))/12-(3*((y+4900+(m-14)/12)/100))/4-2440588;
    timestamp = uint256(_days) * 1 days;
  }

  function timestampToDate(uint256 timestamp) private pure returns (uint256 year, uint256 month, uint256 day) {
    unchecked {
      int256 L = int256(timestamp / 1 days) + 2509157;
      int256 N = (4 * L) / 146097;
      L = L - (146097 * N + 3) / 4;
      int256 y = (4000 * (L + 1)) / 1461001;
      L = L - (1461 * y) / 4 + 31;
      int256 m = (80 * L) / 2447;
      int256 d = L - (2447 * m) / 80;
      L = m / 11;
      m = m + 2 - 12 * L;
      y = 100 * (N - 49) + y + L;
      year = uint256(y);
      month = uint256(m);
      day = uint256(d);
    }
  }

  function addOneMonth(uint256 timestamp) public pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = timestampToDate(timestamp);
    month += 1;
    year += (month - 1) / 12;
    month = ((month - 1) % 12) + 1;
    uint256 daysInMonth = getDaysInMonth(year, month);
    if (day > daysInMonth) day = daysInMonth;
    newTimestamp = dateToTimestamp(day, month, year);
  }

  function getDaysInMonth(uint256 year, uint256 month) private pure returns (uint256 daysInMonth) {
    if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
      daysInMonth = 31;
    } else if (month != 2) {
      daysInMonth = 30;
    } else {
      daysInMonth = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0) ? 29 : 28;
    }
  }

  function addBeneficiary(address token, address account, uint256 award, uint256 numPayments, uint256 startDay, uint256 startMonth, uint256 startYear) external onlyOwner {
    // do checks
    updateBeneficiary(token, account, award, numPayments, dateToTimestamp(startDay, startMonth, startYear));
  }

  function removeBeneficiary(address token, address account) external onlyOwner {
    updateBeneficiary(token, account, 0, 0, 0);
  }

  function claim(address token) external {
    payout(token, msg.sender);
  }

  function payoutAll(address token) external {

  }

  function payout(address token, address account) private {
    bytes32 schemeEntry = keccak256(abi.encode(token, account));
    uint256 numPaymentsRemaining = NumPaymentsRemaining[schemeEntry];

    /* if (numPaymentsRemaining > 0) {
      uint256 nextPaymentDue = NextPaymentDue[schemeEntry];
      if (nextPaymentDue > block.timestamp) return;

      uint256 numPaymentsToMake = 1 + (block.timestamp - nextPaymentDue) / ONE_MONTH;
      numPaymentsToMake = (numPaymentsToMake > numPaymentsRemaining) ? numPaymentsRemaining : numPaymentsToMake;
      NumPaymentsRemaining[schemeEntry] = numPaymentsRemaining - numPaymentsToMake;
      NextPaymentDue[schemeEntry] = addOneMonth(nextPaymentDue);
      uint256 paymentDue = calculatePayment(schemeEntry, numPaymentsToMake);
      if (!TOKEN(token).transfer(account, paymentDue)) revert InsufficientFunds();
    } */
  }

  function calculateAmounts(uint256 numPayments, uint256 award) public pure returns (uint256 first, uint256 regular) {
    if (numPayments == 1) first = award;
    else if (numPayments != 0){
      regular = award / numPayments;
      first = award - (regular * (numPayments - 1));
    }
    return (first, regular);
  }

  function updateBeneficiary(address token, address account, uint256 award, uint256 numPayments, uint256 start) private {
    bytes32 schemeEntry = keccak256(abi.encode(token, account));
    NextPaymentDue[schemeEntry] = start;
    NumPaymentsRemaining[schemeEntry] = numPayments;
    (FirstPaymentAmount[schemeEntry], RegularPaymentAmount[schemeEntry]) = calculateAmounts(numPayments, award);
  }

  function calculatePayment(bytes32 schemeEntry, uint256 numPaymentsToMake) private returns (uint256) {
    uint256 firstPaymentAmount = (FirstPaymentAmount[schemeEntry]);
    if (firstPaymentAmount == 0) {
      return RegularPaymentAmount[schemeEntry] * numPaymentsToMake;
    } else {
      FirstPaymentAmount[schemeEntry] = 0;
      if (numPaymentsToMake == 1 ) return firstPaymentAmount;
      else return firstPaymentAmount + (RegularPaymentAmount[schemeEntry] * (numPaymentsToMake - 1));
    }
  }
}