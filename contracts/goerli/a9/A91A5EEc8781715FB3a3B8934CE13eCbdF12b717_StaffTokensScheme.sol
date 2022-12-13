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
  uint256 constant private ONE_YEAR = 31556952; // 60 secs * 60 mins * 24 hours * 365.2425 days
  uint256 constant private ONE_MONTH = ONE_YEAR / 12;

  mapping(address => string) private AccountsByToken;
  mapping(bytes32 => uint256) private NextPaymentDue;
  mapping(bytes32 => uint256) private NumPaymentsRemaining;
  mapping(bytes32 => uint256) private FirstPaymentAmount;
  mapping(bytes32 => uint256) private RegularPaymentAmount;
  address public owner;

  error OnlyOwner();
  error InsufficientFunds();
  error InvalidYear();

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
    require(year >= 1970);
    int256 d = int256(day);
    int256 y = int256(year);
    int256 m = int256(month);
    int256 _days = d-32075+(1461*(y+4800+(m-14)/12))/4+(367*(m-2-((m-14)/12)*12))/12-(3*((y+4900+(m-14)/12)/100))/4-2440588;
    timestamp = uint256(_days) * 60 * 60 * 24;
  }

  // start day month year
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

    if (numPaymentsRemaining > 0) {
      uint256 nextPaymentDue = NextPaymentDue[schemeEntry];
      if (nextPaymentDue > block.timestamp) return;

      uint256 numPaymentsToMake = 1 + (block.timestamp - nextPaymentDue) / ONE_MONTH;
      numPaymentsToMake = (numPaymentsToMake > numPaymentsRemaining) ? numPaymentsRemaining : numPaymentsToMake;
      NumPaymentsRemaining[schemeEntry] = numPaymentsRemaining - numPaymentsToMake;
      NextPaymentDue[schemeEntry] = nextPaymentDue + ONE_MONTH;
      uint256 paymentDue = calculatePayment(schemeEntry, numPaymentsToMake);
      if (!TOKEN(token).transfer(account, paymentDue)) revert InsufficientFunds();
    }
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