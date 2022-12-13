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
  string[] public schemeTokens;
  uint256 constant private ONE_MONTH = 2629743;
  mapping(bytes32 => address) private validTokens;
  mapping(address => string) private AccountsByToken;
  mapping(bytes32 => uint256) private NextPaymentDue;
  mapping(bytes32 => uint256) private NumPaymentsRemaining;
  mapping(bytes32 => uint256) private FirstPaymentAmount;
  mapping(bytes32 => uint256) private RegularPaymentAmount;
  address public owner;
  struct Date {
    uint256 day;
    uint256 month;
    uint256 year;
  }

  error OnlyOwner();
  error InsufficientFunds();
  error InvalidDate();
  error UnrecognisedToken();
  error AddressIsZero();
  error AmountIsZero();
  error NumPaymentsIsZero();

  modifier onlyOwner {
    if (msg.sender != owner) revert OnlyOwner();
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  function changeOwner(address newOwner) external onlyOwner {
    if (newOwner == address(0)) revert AddressIsZero();
    owner = newOwner;
  }

  function drain(address token) external onlyOwner {
    TOKEN Token = TOKEN(token);
    Token.transfer(msg.sender, Token.balanceOf(address(this)));
  }

  function addToken(string calldata tokenSymbol, address token) external onlyOwner {
    require (validTokens[keccak256(abi.encode(tokenSymbol))] == address(0));
    validTokens[keccak256(abi.encode(tokenSymbol))] = token;
    schemeTokens.push(tokenSymbol);
  }

  function getTokens() external view returns (string[] memory) {
    return schemeTokens;
  }

  // ADMIN
  function addBeneficiary(string calldata tokenSymbol, address account, uint256 award, uint256 numPayments, Date calldata start) external onlyOwner {
    address token = getToken(tokenSymbol);
    if (account == address(0)) revert AddressIsZero();
    if (award == 0) revert AmountIsZero();
    if (numPayments == 0) revert NumPaymentsIsZero();
    updateBeneficiary(token, account, award, numPayments, dateToTimestamp(start));
    // log added
  }

  // ADMIN
  function removeBeneficiary(string calldata tokenSymbol, address account) external onlyOwner {
    address token = getToken(tokenSymbol);
    updateBeneficiary(token, account, 0, 0, 0);
    // log removed
  }

  function claim(string calldata tokenSymbol) external {
    payout(tokenSymbol, msg.sender);
  }

  /* function payoutAll(string calldata tokenSymbol) external {

  } */

  function getNextPaymentDue(string calldata tokenSymbol, address account) external view returns (Date memory) {
    address token = getToken(tokenSymbol);
    bytes32 entry = getEntry(token, account);
    uint256 nextPaymentTimestamp = NextPaymentDue[entry];
    return timestampToDate(nextPaymentTimestamp);
  }

  function payout(string calldata tokenSymbol, address account) private {
    address token = getToken(tokenSymbol);
    bytes32 entry = getEntry(token, account);
    uint256 numPaymentsRemaining = NumPaymentsRemaining[entry];

    if (numPaymentsRemaining > 0) {
      uint256 nextPaymentDue = NextPaymentDue[entry];
      if (nextPaymentDue > block.timestamp) return;
      uint256 numPaymentsToMake = 1 + (block.timestamp - nextPaymentDue) / ONE_MONTH;
      numPaymentsToMake = (numPaymentsToMake > numPaymentsRemaining) ? numPaymentsRemaining : numPaymentsToMake;
      NumPaymentsRemaining[entry] = numPaymentsRemaining - numPaymentsToMake;
      NextPaymentDue[entry] = nextPaymentDue + ONE_MONTH;
      uint256 paymentDue = calcAmountDue(entry, numPaymentsToMake);
      if (!TOKEN(token).transfer(account, paymentDue)) revert InsufficientFunds();
    }
  }

  function getToken(string memory tokenSymbol) private view returns (address token) {
    token = validTokens[keccak256(abi.encode(tokenSymbol))];
    if (token == address(0)) revert UnrecognisedToken();
  }

  function getEntry(address token, address account) private pure returns (bytes32) {
    return keccak256(abi.encode(token, account));
  }

  function updateBeneficiary(address token, address account, uint256 award, uint256 numPayments, uint256 start) private {
    bytes32 entry = getEntry(token, account);
    NextPaymentDue[entry] = start;
    NumPaymentsRemaining[entry] = numPayments;
    (FirstPaymentAmount[entry], RegularPaymentAmount[entry]) = calcPaymentAmounts(numPayments, award);
  }

  function calcPaymentAmounts(uint256 numPayments, uint256 award) private pure returns (uint256 first, uint256 regular) {
    if (numPayments == 1) first = award;
    else if (numPayments != 0){
      regular = award / numPayments;
      first = award - (regular * (numPayments - 1));
    }
    return (first, regular);
  }

  function calcAmountDue(bytes32 entry, uint256 numPaymentsToMake) private returns (uint256) {
    uint256 firstPaymentAmount = (FirstPaymentAmount[entry]);
    if (firstPaymentAmount == 0) {
      return RegularPaymentAmount[entry] * numPaymentsToMake;
    } else {
      FirstPaymentAmount[entry] = 0;
      if (numPaymentsToMake == 1 ) return firstPaymentAmount;
      else return firstPaymentAmount + (RegularPaymentAmount[entry] * (numPaymentsToMake - 1));
    }
  }

  function dateToTimestamp(Date calldata date) public pure returns (uint256 timestamp) {
    if (date.day == 0 || date.day > 31 || date.month == 0 || date.month > 12 || date.year < 1970) revert InvalidDate();
    int256 d = int256(date.day);
    int256 y = int256(date.year);
    int256 m = int256(date.month);
    int256 _days = d-32075+(1461*(y+4800+(m-14)/12))/4+(367*(m-2-((m-14)/12)*12))/12-(3*((y+4900+(m-14)/12)/100))/4-2440588;
    timestamp = uint256(_days) * 1 days;
  }

  function timestampToDate(uint256 timestamp) public pure returns (Date memory date) {
    if (timestamp != 0) {
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
        date.year = uint256(y);
        date.month = uint256(m);
        date.day = uint256(d);
      }
    }
  }
}