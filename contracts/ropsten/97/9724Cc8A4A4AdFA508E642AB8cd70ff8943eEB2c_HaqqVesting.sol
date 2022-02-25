// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

/*
* @title HaqqVesting
* This smart contract allows making deposits with 'westing', i.e. each deposit can be repaid to beneficiary in
* fixed amount of portions (defined in 'numberOfPayments' variable), each payment will be unblocked after fixed period
* of time (defined in 'timeBetweenPayments' variable).
* Payments can be cumulative. That is, if the time has passed for which the beneficiary could have already received
* three payments, then the current transfer will pay the amount of three payments.
* Any address can make a deposit, and any address can trigger next payment to beneficiary.
* There can be many deposits for the same beneficiary address.
*/
contract HaqqVesting {

    /// @dev number of payments to be made to repay a deposit to beneficiary
    uint256 public constant NUMBER_OF_PAYMENTS = 5; // TODO: '24' in production <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    /// @dev Time period (in seconds) to unblock next payment.
    uint256 public constant TIME_BETWEEN_PAYMENTS = 3 minutes; // TODO: '30 days' in production <<<<<<<<<<<<<<<<<<<<<<<<

    /// @dev  Mapping: deposit id => beneficiary address
    mapping(uint256 => address) public beneficiary;

    /// @dev Mapping: deposit id => time when deposit was made
    mapping(uint256 => uint256) public timestamp;

    /// @dev Mapping: deposit id => sum deposited in smallest amount of native blockchain currency (wei on Ethereum)
    mapping(uint256 => uint256) public sumInWeiDeposited;

    /// @dev Mapping: deposit id => number of payments already made to beneficiary address
    mapping(uint256 => uint256) public portionsPaidAlready;

    /// @dev Event to be emitted, when deposit was made.
    event DepositMade (
        uint256 indexed depositId,
        address indexed beneficiaryAddress,
        uint256 indexed timestamp,
        uint256 sumInWeiDeposited
    );

    /// @dev Function to make a new deposit.
    /// @param _depositId id for the new deposit, must be new (not used already for existing deposit) or tx fails.
    /// @param _beneficiaryAddress address that will receive payments from this deposit
    function deposit(uint256 _depositId, address _beneficiaryAddress) external payable returns (bool success){

        require(timestamp[_depositId] == 0, "Deposit with this id already exists");

        beneficiary[_depositId] = _beneficiaryAddress;
        timestamp[_depositId] = block.timestamp;
        sumInWeiDeposited[_depositId] = msg.value;

        emit DepositMade(
            _depositId,
            beneficiary[_depositId],
            timestamp[_depositId],
            sumInWeiDeposited[_depositId]
        );

        return true;
    }

    /// @dev Calculates number of portions of the deposit, that are available for payment at this moment
    /// @param _depositId deposit id
    function portionsAvailableToWithdraw(uint256 _depositId) public view returns (uint256){

        /// Time in seconds elapsed after the deposit was placed
        uint256 depositAge = block.timestamp - timestamp[_depositId];

        /// Total payouts unlocked in the elapsed time
        uint256 totalPayouts = depositAge / TIME_BETWEEN_PAYMENTS;

        if (totalPayouts > NUMBER_OF_PAYMENTS) {
            totalPayouts = NUMBER_OF_PAYMENTS;
        }

        /// Number of unblocked but not yet made withdrawals
        uint256 availablePayments = totalPayouts - portionsPaidAlready[_depositId];

        return availablePayments;
    }

    /// @dev Returns amount (in wei on Ethereum) that should be unlocked in one time period for the given deposit
    /// @param _depositId deposit id
    function amountForOneWithdrawal(uint256 _depositId) public view returns (uint256){
        return sumInWeiDeposited[_depositId] / NUMBER_OF_PAYMENTS;
    }

    /// @dev Returns amount available for withdrawal for given deposit at this time
    /// @param _depositId deposit id
    function amountToWithdrawNow(uint256 _depositId) public view returns (uint256){
        return portionsAvailableToWithdraw(_depositId) * amountForOneWithdrawal(_depositId);
    }

    /// @dev Event that will be emitted, when withdrawal was made
    event WithdrawalMade(
        uint256 indexed depositId,
        address indexed beneficiary,
        uint256 sumInWei,
        address indexed triggeredByAddress
    );

    /// @dev Function that transfers the amount currently due to the beneficiary address
    /// @param _depositId deposit id
    function withdraw(uint256 _depositId) external returns (bool success) {

        uint256 sumToWithdraw = amountToWithdrawNow(_depositId);

        require(sumToWithdraw > 0, "Sum to withdraw should be not zero");

        // mark portions of deposit as received already by the beneficiary
        portionsPaidAlready[_depositId] = portionsPaidAlready[_depositId] + portionsAvailableToWithdraw(_depositId);

        emit WithdrawalMade(
            _depositId,
            beneficiary[_depositId],
            sumToWithdraw,
            msg.sender
        );

        payable(beneficiary[_depositId]).transfer(sumToWithdraw);

        return true;
    }

}