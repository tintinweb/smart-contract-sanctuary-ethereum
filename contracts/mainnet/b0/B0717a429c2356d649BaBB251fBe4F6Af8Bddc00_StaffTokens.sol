// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// ERC20 methods required by this contract
interface ERC20 {
  function transfer(address, uint256) external returns (bool);
  function balanceOf(address) external view returns (uint256);
}

struct Date {
  uint256 day;
  uint256 month;
  uint256 year;
}

contract StaffTokens {

  uint256 constant private TIME_BETWEEN_PAYMENTS = 30 days;

  mapping(bytes32 => address) private TokenAddress;
  mapping(address => uint256) private Obligation;
  mapping(address => address[]) private TokenSubscribers;
  mapping(bytes32 => uint256) private NextPaymentDue;
  mapping(bytes32 => uint256) private NumPaymentsRemaining;
  mapping(bytes32 => uint256) private FirstPaymentAmount;
  mapping(bytes32 => uint256) private RegularPaymentAmount;
  mapping(address => bool) public isAdmin;

  string[] private TokenSymbols;
  address public owner;

  error AccountAlreadyExists();
  error AddressIsZero();
  error AmountIsZero();
  error InvalidDate();
  error NumPaymentsIsZero();
  error OwnerOnly();
  error OwnerOrAdminOnly();
  error TokenAlreadyAdded();
  error UnrecognisedToken();

  event AdminStatusUpdated(address indexed account, bool isAdmin);
  event BeneficiaryAdded(address indexed token, address indexed account, uint256 award, uint256 numPayments, uint256 startTimestamp);
  event BeneficiaryRemoved(address indexed token, address indexed account, uint256 awardRemainder, uint256 numPaymentsOutstanding);

  modifier ownerOnly {
    if (msg.sender != owner) revert OwnerOnly();
    _;
  }

  modifier ownerOrAdminOnly {
    if (msg.sender != owner && !isAdmin[msg.sender]) revert OwnerOrAdminOnly();
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  /// @notice Add a new token
  /// @param token Ethereum address of the token contract
  /// @param symbol 3 or 4 letter token 'ticker'
  /// @dev Required before any payments of this token can be made.
  function owner_registerToken(address token, string calldata symbol) external ownerOnly {
    bytes32 symbolHash = keccak256(abi.encode(symbol));
    if (TokenAddress[symbolHash] != address(0)) revert TokenAlreadyAdded();
    TokenAddress[symbolHash] = token;
    TokenSymbols.push(symbol);
  }

  /// @notice Remove an existing token
  /// @param symbol 3 or 4 letter token 'ticker'
  /// @dev Prevents further payments for this token. Does not remove existing beneficiaries. Does not withdraw any token funds.
  function owner_revokeToken(string calldata symbol) external ownerOnly {
    bytes32 symbolHash = keccak256(abi.encode(symbol));

    if (TokenAddress[symbolHash] == address(0)) return;
    else {
      TokenAddress[symbolHash] = address(0);
      uint256 lastTokenIndex = TokenSymbols.length - 1;
      for (uint256 i; i < lastTokenIndex;) {
        if (keccak256(abi.encode(TokenSymbols[i])) == symbolHash) {
          TokenSymbols[i] = TokenSymbols[lastTokenIndex];
          break;
        }
        unchecked { i++; }
      }
      TokenSymbols.pop();
    }
  }

  /// @notice Set the admin status of an address
  /// @param account Ethereum address of the admin
  /// @param status true = grant admin rights, false = revoke admin rights
  /// @dev Accounts with admin status are permitted to call admin_ functions.
  function owner_setAdminStatus(address account, bool status) external ownerOnly {
    if (account == address(0)) revert AddressIsZero();
    emit AdminStatusUpdated(account, status);
    if (isAdmin[account] != status) isAdmin[account] = status;
  }

  /// @notice Change contract owner
  /// @param account Ethereum address of the new owner
  /// @dev The owner may call any owner_ or admin_ function.
  function owner_setOwner(address account) external ownerOnly {
    if (account == address(0)) revert AddressIsZero();
    owner = account;
  }

  /// @notice Withdraw an amount of the specified token from the contract
  /// @param token Ethereum address of the token contract
  /// @param destination Ethereum address of the withdrawal recipient
  /// @param amount Amount of funds to withdraw (in full decimals for the token)
  /// @dev Withdrawal does not depend on the token being registered with the contract at the time.
  function owner_withdrawFunds(address token, address destination, uint256 amount) external ownerOnly {
    if (destination == address(0)) revert AddressIsZero();
    assert(ERC20(token).transfer(destination, amount));
  }

  /// @notice Set up a new beneficiary for a token
  /// @param symbol 3 or 4 letter token 'ticker' (must be a registered token)
  /// @param account Ethereum address of the beneficiary
  /// @param totalAward Total amount being awarded (in full decimals for the token)
  /// @param numPayments Number of equal monthly payments to split the total award into (any excess from division is included in the first payment)
  /// @param startDate Date for the initial payment as a comma separated array, e.g.: 23rd July 2023 would be [23,7,2023]
  /// @dev Emits a BeneficiaryAdded log containing the input details for accounting.
  function admin_addBeneficiary(string calldata symbol, address account, uint256 totalAward, uint256 numPayments, Date calldata startDate) external ownerOrAdminOnly {
    if (account == address(0)) revert AddressIsZero();
    if (totalAward == 0) revert AmountIsZero();
    if (numPayments == 0) revert NumPaymentsIsZero();

    address token = getTokenAddress(symbol);
    bytes32 key = keccak256(abi.encode(token, account));

    if (NumPaymentsRemaining[key] != 0) revert AccountAlreadyExists();

    TokenSubscribers[token].push(account);
    uint256 startTimestamp = dateToTimestamp(startDate);

    NextPaymentDue[key] = startTimestamp;
    NumPaymentsRemaining[key] = numPayments;
    (FirstPaymentAmount[key], RegularPaymentAmount[key]) = calcPaymentAmounts(numPayments, totalAward);
    Obligation[token] += totalAward;
    emit BeneficiaryAdded(token, account, totalAward, numPayments, startTimestamp);
  }

  /// @notice Remove an existing beneficiary of a token
  /// @param symbol 3 or 4 letter token 'ticker'
  /// @param account Ethereum address of the beneficiary being removed
  /// @dev Ends payments of this token to the beneficiary. Emits a BeneficiaryRemoved log containing the closing state for accounting.
  function admin_removeBeneficiary(string calldata symbol, address account) external ownerOrAdminOnly {
    address token = getTokenAddress(symbol);
    tokenUnsubscribe(token, account);

    bytes32 key = keccak256(abi.encode(token, account));
    uint256 numPaymentsOutstanding = NumPaymentsRemaining[key];
    uint256 awardRemainder = calcAmountDue(key, numPaymentsOutstanding);
    NextPaymentDue[key] = 0;
    NumPaymentsRemaining[key] = 0;
    FirstPaymentAmount[key] = 0;
    RegularPaymentAmount[key] = 0;
    Obligation[token] -= awardRemainder;
    emit BeneficiaryRemoved(token, account, awardRemainder, numPaymentsOutstanding);
  }

  /// @notice Pays all outstanding amounts due, across all tokens and beneficiaries
  /// @dev The contract must hold enough funds to make ALL the payments or the method will fail and no payments will be made.
  function admin_runPayments() external ownerOrAdminOnly {
    uint256 numTokens = TokenSymbols.length;

    for (uint256 i; i < numTokens;) {
      uint256 paid;
      address token = getTokenAddress(TokenSymbols[i]);
      address[] memory accounts = TokenSubscribers[token];
      uint256 accountsLength = accounts.length;

      for (uint256 j; j < accountsLength;) {
        paid += makePaymentIfRequired(token, accounts[j]);
        unchecked { j++; }
      }

      Obligation[token] -= paid;
      unchecked { i++; }
    }
  }

  /// @notice Pays anything due to a single beneficiary for a specific token
  /// @param symbol 3 or 4 letter token 'ticker'
  /// @param account Ethereum address of the beneficiary
  function admin_runSinglePayment(string calldata symbol, address account) external ownerOrAdminOnly {
    address token = getTokenAddress(symbol);
    Obligation[token] -= makePaymentIfRequired(token, account);
  }

  /// @notice Allows a beneficiary to claim any unpaid funds due to date
  /// @dev Pays out for all tokens the beneficiary is entitled to.
  function claim() external {
    uint256 numTokens = TokenSymbols.length;

    for (uint256 i; i < numTokens;) {
      address token = getTokenAddress(TokenSymbols[i]);
      Obligation[token] -= makePaymentIfRequired(token, msg.sender);
      unchecked { i++; }
    }
  }

  /// @notice Query the next payment date of a token for a beneficiary
  /// @param symbol 3 or 4 letter token 'ticker'
  /// @param account Ethereum address of the beneficiary
  /// @dev Returns the date as a comma separated array, e.g.: 23rd July 2023 would be [23,7,2023].
  function nextPaymentDate(string calldata symbol, address account) external view returns (Date memory) {
    bytes32 key = keccak256(abi.encode(getTokenAddress(symbol), account));
    return timestampToDate(NextPaymentDue[key]);
  }

  /// @notice Query the number of outstanding payments of a token for a beneficiary
  /// @param symbol 3 or 4 letter token 'ticker'
  /// @param account Ethereum address of the beneficiary
  /// @dev Returns the number of monthly payments yet to be made.
  function paymentsRemaining(string calldata symbol, address account) external view returns (uint256) {
    bytes32 key = keccak256(abi.encode(getTokenAddress(symbol), account));
    return NumPaymentsRemaining[key];
  }

  /// @notice Query the monthly payment amount of a token for a beneficiary
  /// @param symbol 3 or 4 letter token 'ticker'
  /// @param account Ethereum address of the beneficiary
  /// @dev Returns the monthly payment amount (in full decimals for the token).
  function amountPerPayment(string calldata symbol, address account) external view returns (uint256) {
    bytes32 key = keccak256(abi.encode(getTokenAddress(symbol), account));
    if (RegularPaymentAmount[key] > 0) return RegularPaymentAmount[key];
    else return FirstPaymentAmount[key];
  }

  /// @notice Get the current surplus/deficit for a token
  /// @param symbol 3 or 4 letter token 'ticker'
  /// @dev Returns the surplus (+) or deficit (-) in full decimals, accounting for all future payments.
  function tokenFundingStatus(string calldata symbol) external view returns (int256){
    address token = getTokenAddress(symbol);
    uint256 balance = ERC20(token).balanceOf(address(this));
    uint256 obligation = Obligation[token];
    if (balance > obligation) return int256(balance - obligation);
    else if (obligation > balance) return int256(obligation - balance) * - 1;
    else return 0;
  }

  /// @notice Returns the list of current beneficiary addresses for a token
  /// @param symbol 3 or 4 letter token 'ticker'
  function activeBeneficiaries(string calldata symbol) external view returns (address[] memory) {
    address token = getTokenAddress(symbol);
    return TokenSubscribers[token];
  }

  /// @notice Displays a list of all currently registered tokens
  function registeredTokens() external view returns (string[] memory) {
    return TokenSymbols;
  }

  /// ******* PRIVATE METHODS ******* ///

  function tokenUnsubscribe(address token, address account) private {
    address[] memory accounts = TokenSubscribers[token];
    uint256 accountsLength = accounts.length;
    bool found;
    uint256 i;

    for (i; i < accountsLength;) {
      if (accounts[i] == account) {
        found = true;
        break;
      }
      unchecked { i++; }
    }

    if (found) {
      if (i < accountsLength - 1) TokenSubscribers[token][i] = TokenSubscribers[token][accountsLength - 1];
      TokenSubscribers[token].pop();
    }
  }

  function makePaymentIfRequired(address token, address account) private returns (uint256 payment) {
    bytes32 key = keccak256(abi.encode(token, account));
    uint256 numPaymentsRemaining = NumPaymentsRemaining[key];

    if (numPaymentsRemaining > 0) {
      uint256 nextPaymentDue = NextPaymentDue[key];
      if (nextPaymentDue > block.timestamp) return payment = 0;
      uint256 numPaymentsToMake = 1 + (block.timestamp - nextPaymentDue) / TIME_BETWEEN_PAYMENTS;
      numPaymentsToMake = (numPaymentsToMake > numPaymentsRemaining) ? numPaymentsRemaining : numPaymentsToMake;
      numPaymentsRemaining -= numPaymentsToMake;
      NumPaymentsRemaining[key] = numPaymentsRemaining;
      NextPaymentDue[key] = nextPaymentDue + (numPaymentsToMake * TIME_BETWEEN_PAYMENTS);
      payment = calcAmountDue(key, numPaymentsToMake);
      assert(ERC20(token).transfer(account, payment));
    }

    if (numPaymentsRemaining == 0) {
      tokenUnsubscribe(token, account);
      NextPaymentDue[key] = 0;
      RegularPaymentAmount[key] = 0;
    }
  }

  function getTokenAddress(string memory symbol) private view returns (address token) {
    token = TokenAddress[keccak256(abi.encode(symbol))];
    if (token == address(0)) revert UnrecognisedToken();
  }

  function calcPaymentAmounts(uint256 numPayments, uint256 award) private pure returns (uint256 first, uint256 regular) {
    if (numPayments == 1) first = award;
    else {
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