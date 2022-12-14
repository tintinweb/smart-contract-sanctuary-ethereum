/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


// 
// ERC20 transfer method required by this contract
interface TOKEN {
  function transfer(address, uint256) external returns (bool);
  function balanceOf(address) external view returns (uint256);
}

struct Date {
  uint256 day;
  uint256 month;
  uint256 year;
}

contract StaffTokensScheme {
  string[] private TokenSymbols;
  uint256 constant private TIME_BETWEEN_PAYMENTS = 30 days;
  mapping(bytes32 => address) private SchemeTokens;
  mapping(address => uint256) private Obligation;
  mapping(address => address[]) private TokenSubscribers;
  mapping(bytes32 => uint256) private NextPaymentDue;
  mapping(bytes32 => uint256) private NumPaymentsRemaining;
  mapping(bytes32 => uint256) private FirstPaymentAmount;
  mapping(bytes32 => uint256) private RegularPaymentAmount;
  mapping(address => bool) public isAdmin;
  address public owner;

  event BeneficiaryAdded(address indexed token, address indexed account, uint256 award, uint256 numPayments, uint256 startTimestamp);
  event BeneficiaryRemoved(address indexed token, address indexed account, uint256 recoupedAward, uint256 numPaymentsUnpaid);

  error OnlyOwner();
  error OnlyOwnerOrAdmin();
  error InsufficientFunds();
  error InvalidDate();
  error UnrecognisedToken();
  error AddressIsZero();
  error AmountIsZero();
  error NumPaymentsIsZero();
  error TokenAlreadyAdded();

  modifier onlyOwner {
    if (msg.sender != owner) revert OnlyOwner();
    _;
  }

  modifier onlyOwnerOrAdmin {
    if (msg.sender != owner && !isAdmin[msg.sender]) revert OnlyOwnerOrAdmin();
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  /// @notice Adds a new token to the scheme
  /// @param tokenSymbol 3 or 4 letter 'ticker' reference for the token being added
  /// @param token Ethereum address of the token contract
  /// @dev This is required before any payments of the token can be made.
  function owner_registerToken(string calldata tokenSymbol, address token) external onlyOwner {
    bytes32 symbolHash = keccak256(abi.encode(tokenSymbol));
    if (SchemeTokens[symbolHash] != address(0)) revert TokenAlreadyAdded();
    SchemeTokens[symbolHash] = token;
    TokenSymbols.push(tokenSymbol);
  }

  /// @notice Removes an existing token from the scheme
  /// @param tokenSymbol 3 or 4 letter 'ticker' reference for the token being removed
  /// @dev Prevents further payments for this token. Does not remove existing beneficiaries. Does not withdraw any token funds.
  function owner_revokeToken(string calldata tokenSymbol) external onlyOwner {
    bytes32 symbolHash = keccak256(abi.encode(tokenSymbol));

    if (SchemeTokens[symbolHash] == address(0)) {
      return;
    } else {
      SchemeTokens[symbolHash] = address(0);
      uint256 lastTokenIndex = TokenSymbols.length - 1;
      uint256 i;
      for (i; i < lastTokenIndex;) {
        if (keccak256(abi.encode(TokenSymbols[i])) == keccak256(abi.encode(tokenSymbol))) {
          TokenSymbols[i] = TokenSymbols[lastTokenIndex];
          break;
        }
        unchecked { i++; }
      }
      TokenSymbols.pop();
    }
  }

  /// @notice Set the admin status of an address
  /// @param account Ethereum address of account being added or removed as admin
  /// @param status true = grant admin rights, false = revoke admin rights
  /// @dev Accounts with admin status are permitted to call any admin_ functions.
  function owner_setAdmin(address account, bool status) external onlyOwner {
    if (account == address(0)) revert AddressIsZero();
    if (isAdmin[account] == status) return;
    else isAdmin[account] = status;
  }

  /// @notice Change contract owner
  /// @param account Ethereum address of account being set as the new owner of this contract
  /// @dev The owner may call any owner_ or admin_ functions.
  function owner_setOwner(address account) external onlyOwner {
    if (account == address(0)) revert AddressIsZero();
    owner = account;
  }

  /// @notice Withdraw an amount of a token from the contract
  /// @param token Ethereum contract address of the token to withdraw
  /// @param destination Recipient of withdrawn funds
  /// @param amount Amount of funds to withdraw (in full decimals)
  /// @dev Withdrawal does not depend on the token being registered with the contract at the time.
  function owner_withdrawFunds(address token, address destination, uint256 amount) external onlyOwner {
    if (destination == address(0)) revert AddressIsZero();
    TOKEN Token = TOKEN(token);
    assert(Token.transfer(destination, amount));
  }

  /// @notice Set up a new beneficiary in the scheme
  /// @param tokenSymbol 3 or 4 letter 'ticker' token reference (token must be currently registered)
  /// @param account Ethereum address of the beneficiary being added
  /// @param award Total award amount (in full decimals)
  /// @param numPayments Number of monthly payments to split the total award into (excess from division is added to the first payment)
  /// @param startDate Date for the initial payment input as a comma separated array, eg: 23rd July 2023 would be [23,7,2023]
  /// @dev Logs the provided inputs with the initial payment converted to its UNIX timestamp representation.
  function admin_addBeneficiary(string calldata tokenSymbol, address account, uint256 award, uint256 numPayments, Date calldata startDate) external onlyOwnerOrAdmin {
    if (account == address(0)) revert AddressIsZero();
    if (award == 0) revert AmountIsZero();
    if (numPayments == 0) revert NumPaymentsIsZero();

    address token = getTokenAddress(tokenSymbol);
    tokenSubscribe(token, account);

    bytes32 key = keccak256(abi.encode(token, account));
    uint256 startTimestamp = dateToTimestamp(startDate);

    NextPaymentDue[key] = startTimestamp;
    NumPaymentsRemaining[key] = numPayments;
    (FirstPaymentAmount[key], RegularPaymentAmount[key]) = calcPaymentAmounts(numPayments, award);
    Obligation[token] += award;
    emit BeneficiaryAdded(token, account, award, numPayments, startTimestamp);
  }

  /// @notice Remove an existing beneficiary from the scheme
  /// @param tokenSymbol 3 or 4 letter 'ticker' token reference
  /// @param account Ethereum address of the beneficiary being removed
  /// @dev Prevents any future payments of this token unless beneficiary is re-added. Logs the number of payments and total amount they had been due.
  function admin_removeBeneficiary(string calldata tokenSymbol, address account) external onlyOwnerOrAdmin {
    address token = getTokenAddress(tokenSymbol);
    tokenUnsubscribe(token, account);

    bytes32 key = keccak256(abi.encode(token, account));
    uint256 numPaymentsUnpaid = NumPaymentsRemaining[key];
    uint256 recoupedAward = calcAmountDue(key, numPaymentsUnpaid);
    NextPaymentDue[key] = 0;
    NumPaymentsRemaining[key] = 0;
    FirstPaymentAmount[key] = 0;
    RegularPaymentAmount[key] = 0;
    Obligation[token] -= recoupedAward;
    emit BeneficiaryRemoved(token, account, recoupedAward, numPaymentsUnpaid);
  }

  /// @notice Runs all outstanding payments across all tokens and beneficiaries
  /// @dev There must be enough funds available to make ALL the payments or the method will fail and no payments will be made.
  function admin_runPayments() external onlyOwnerOrAdmin {
    uint256 tokensLength = TokenSymbols.length;
    uint256 accountsLength;
    uint256 paid;
    uint256 i;
    uint256 j;
    address token;
    address[] memory accounts;

    for (i; i < tokensLength;) {
      paid = 0;
      token = getTokenAddress(TokenSymbols[i]);
      accounts = TokenSubscribers[token];
      accountsLength = accounts.length;

      for (j; j < accountsLength;) {
        paid += makePayment(token, accounts[j]);
        unchecked { j++; }
      }

      Obligation[token] -= paid;
      unchecked { i++; }
    }
  }

  /// @notice Allows the caller to claim any funds due
  /// @dev Pays out across all tokens the claimant is registered for.
  function user_claim() external {
    uint256 tokenSymbolsLength = TokenSymbols.length;
    uint256 i;
    address token;

    for (i; i < tokenSymbolsLength;) {
      token = getTokenAddress(TokenSymbols[i]);
      Obligation[token] -= makePayment(token, msg.sender);
      unchecked { i++; }
    }
  }

  /// @notice Get the next payment date of a token for a beneficiary
  /// @param tokenSymbol 3 or 4 letter 'ticker' token reference
  /// @param account Ethereum address of the beneficiary
  /// @dev Returns a calender date in comma separated array form, eg: 23rd July 2023 would be [23,7,2023].
  function nextPaymentDate(string calldata tokenSymbol, address account) external view returns (Date memory) {
    bytes32 key = keccak256(abi.encode(getTokenAddress(tokenSymbol), account));
    return timestampToDate(NextPaymentDue[key]);
  }

  /// @notice Get the number of outstanding payments of a token for a beneficiary
  /// @param tokenSymbol 3 or 4 letter 'ticker' token reference
  /// @param account Ethereum address of the beneficiary
  /// @dev Returns the number of monthly payments outstanding.
  function paymentsRemaining(string calldata tokenSymbol, address account) external view returns (uint256) {
    bytes32 key = keccak256(abi.encode(getTokenAddress(tokenSymbol), account));
    return NumPaymentsRemaining[key];
  }

  /// @notice Get the monthly payment amount of a token for a beneficiary
  /// @param tokenSymbol 3 or 4 letter 'ticker' token reference
  /// @param account Ethereum address of the beneficiary
  /// @dev Returns the monthly payment amount (in full decimals).
  function amountPerPayment(string calldata tokenSymbol, address account) external view returns (uint256) {
    bytes32 key = keccak256(abi.encode(getTokenAddress(tokenSymbol), account));
    if (RegularPaymentAmount[key] > 0) return RegularPaymentAmount[key];
    else return FirstPaymentAmount[key];
  }

  /// @notice Get the current suplus/deficit for a token in the scheme
  /// @param tokenSymbol 3 or 4 letter 'ticker' token reference
  /// @dev Returns the suplus (positive) or deficit (negative) in full decimals accounting for all future payments.
  function schemeFundingStatus(string calldata tokenSymbol) external view returns (int256){
    address token = getTokenAddress(tokenSymbol);
    uint256 balance = TOKEN(token).balanceOf(address(this));
    uint256 obligation = Obligation[token];
    if (balance > obligation) return int256(balance - obligation);
    else if (obligation > balance) return int256(obligation - balance) * - 1;
    else return 0;
  }

  /// @notice Returns a list of all beneficiary addresses for a token
  /// @param tokenSymbol 3 or 4 letter 'ticker' token reference
  function activeBeneficiaries(string calldata tokenSymbol) external view returns (address[] memory) {
    address token = getTokenAddress(tokenSymbol);
    return TokenSubscribers[token];
  }

  /// @notice Returns the list of all registered tokens
  function registeredTokens() external view returns (string[] memory) {
    return TokenSymbols;
  }

  function tokenUnsubscribe(address token, address account) private {
    address[] memory accounts = TokenSubscribers[token];
    uint256 accountsLength = accounts.length;
    bool found;
    uint256 i;

    for (i; i < accountsLength; i++) {
      if (accounts[i] == account) {
        found = true;
        break;
      }
    }

    if (found) {
      if (i < accountsLength - 1) TokenSubscribers[token][i] = TokenSubscribers[token][accountsLength - 1];
      TokenSubscribers[token].pop();
    }
  }

  function tokenSubscribe(address token, address account) private {
    address[] memory accounts = TokenSubscribers[token];
    uint256 accountsLength = accounts.length;
    uint256 i;

    for (i; i < accountsLength;) {
      if (accounts[i] == account) return;
      unchecked { i++; }
    }

    TokenSubscribers[token].push(account);
  }

  function makePayment(address token, address account) private returns (uint256 payment) {
    bytes32 key = keccak256(abi.encode(token, account));
    uint256 numPaymentsRemaining = NumPaymentsRemaining[key];
    uint256 numPaymentsToMake;

    if (numPaymentsRemaining > 0) {
      uint256 nextPaymentDue = NextPaymentDue[key];
      if (nextPaymentDue > block.timestamp) return payment;
      numPaymentsToMake = 1 + (block.timestamp - nextPaymentDue) / TIME_BETWEEN_PAYMENTS;
      numPaymentsToMake = (numPaymentsToMake > numPaymentsRemaining) ? numPaymentsRemaining : numPaymentsToMake;
      numPaymentsRemaining -= numPaymentsToMake;
      NumPaymentsRemaining[key] = numPaymentsRemaining;
      NextPaymentDue[key] = nextPaymentDue + TIME_BETWEEN_PAYMENTS;
      payment = calcAmountDue(key, numPaymentsToMake);
      if (!TOKEN(token).transfer(account, payment)) revert InsufficientFunds();
    }

    if (numPaymentsRemaining == 0) {
      tokenUnsubscribe(token, account);
      NextPaymentDue[key] = 0;
      RegularPaymentAmount[key] = 0;
    }
  }

  function getTokenAddress(string memory tokenSymbol) private view returns (address token) {
    token = SchemeTokens[keccak256(abi.encode(tokenSymbol))];
    if (token == address(0)) revert UnrecognisedToken();
  }

  function calcPaymentAmounts(uint256 numPayments, uint256 award) private pure returns (uint256 first, uint256 regular) {
    if (numPayments == 1) first = award;
    else if (numPayments != 0) {
      unchecked {
        regular = award / numPayments;
        first = award - (regular * (numPayments - 1));
      }
    }
    return (first, regular);
  }

  function calcAmountDue(bytes32 key, uint256 numPayments) private returns (uint256) {
    uint256 firstPaymentAmount = (FirstPaymentAmount[key]);

    unchecked {
      if (firstPaymentAmount == 0) {
        return RegularPaymentAmount[key] * numPayments;
      } else {
        FirstPaymentAmount[key] = 0;
        if (numPayments == 1 ) return firstPaymentAmount;
        else return firstPaymentAmount + (RegularPaymentAmount[key] * (numPayments - 1));
      }
    }
  }

  function dateToTimestamp(Date calldata date) private pure returns (uint256 timestamp) {
    if (date.day == 0 || date.day > 31 || date.month == 0 || date.month > 12 || date.year < 1970) revert InvalidDate();
    int256 d = int256(date.day);
    int256 y = int256(date.year);
    int256 m = int256(date.month);
    int256 _days = d-32075+(1461*(y+4800+(m-14)/12))/4+(367*(m-2-((m-14)/12)*12))/12-(3*((y+4900+(m-14)/12)/100))/4-2440588;
    timestamp = uint256(_days) * 1 days;
  }

  function timestampToDate(uint256 timestamp) private pure returns (Date memory date) {
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