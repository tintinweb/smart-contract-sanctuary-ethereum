// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

//import "hardhat/console.sol";

/*
* @title HaqqVesting
* This smart contract allows making deposits with 'vesting', i.e. each deposit can be repaid to beneficiary in
* fixed amount of portions (defined in 'numberOfPayments' variable), each payment will be unblocked after fixed period
* of time (defined in 'timeBetweenPayments' variable).
* Payments can be cumulative. That is, if the time has passed for which the beneficiary could have already received
* three payments, then the current transfer will pay the amount of three payments.
* Any address can make a deposit, and any address can trigger next payment to beneficiary.
* There can be many deposits for the same beneficiary address.
*/
contract HaqqVesting {

    /// @dev number of payments to be made to repay a deposit to beneficiary
    uint256 public constant NUMBER_OF_PAYMENTS = 5; // TEST
    //    uint256 public constant NUMBER_OF_PAYMENTS = 24; // TODO: Production <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    /// @dev Time period (in seconds) to unblock next payment.
    //    uint256 public constant TIME_BETWEEN_PAYMENTS = 1 seconds; // TEST
    uint256 public constant TIME_BETWEEN_PAYMENTS = 2 minutes; // TEST
    // uint256 public constant TIME_BETWEEN_PAYMENTS = 30 days; // TODO: Production <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

    uint256 public constant MAX_DEPOSITS = 5;

    mapping(address => uint256) public depositsCounter;

    struct Deposit {
        uint256 timestamp;
        uint256 sumInWeiDeposited;
        uint256 sumPaidAlready;
    }

    /// @dev beneficiary address => deposit
    mapping(address => mapping(uint256 => Deposit)) public deposits;

    /// @dev Event to be emitted, when deposit was made.
    event DepositMade (
        address indexed beneficiaryAddress,
        uint256 indexed depositId,
        uint256 indexed timestamp,
        uint256 sumInWeiDeposited,
        address depositedBy
    );

    /// @dev Function to make a new deposit.
    /// @param _beneficiaryAddress address that will receive payments from this deposit
    function deposit(address _beneficiaryAddress) external payable returns (bool success){

        require(msg.value > 0, "deposited amount must be greater than 0 ");

        depositsCounter[_beneficiaryAddress] = depositsCounter[_beneficiaryAddress] + 1;

        require(depositsCounter[_beneficiaryAddress] <= MAX_DEPOSITS, "Max deposit number for this address reached");

        deposits[_beneficiaryAddress][depositsCounter[_beneficiaryAddress]].timestamp = block.timestamp;

        deposits[_beneficiaryAddress][depositsCounter[_beneficiaryAddress]].sumInWeiDeposited = msg.value;

        emit DepositMade(
            _beneficiaryAddress,
            depositsCounter[_beneficiaryAddress],
            deposits[_beneficiaryAddress][depositsCounter[_beneficiaryAddress]].timestamp,
            deposits[_beneficiaryAddress][depositsCounter[_beneficiaryAddress]].sumInWeiDeposited,
            msg.sender
        );

        /// make the first withdrawal
        uint256 depositId = depositsCounter[_beneficiaryAddress];
        uint256 amountToWithdrawNow_ = amountToWithdrawNow(_beneficiaryAddress, depositId);
        deposits[_beneficiaryAddress][depositId].sumPaidAlready = deposits[_beneficiaryAddress][depositId].sumPaidAlready + amountToWithdrawNow_;
        payable(_beneficiaryAddress).transfer(amountToWithdrawNow_);

        return true;
    }

    /// @dev Total payouts unlocked in the elapsed time.
    /// @dev One payment is unlocked immediately
    function totalPayoutsUnblocked(address _beneficiaryAddress, uint256 _depositId) public view returns (uint256){

        require(deposits[_beneficiaryAddress][_depositId].timestamp > 0, "No deposit with this ID for this address");

        /// Time in seconds elapsed after the deposit was placed
        uint256 depositAge = block.timestamp - deposits[_beneficiaryAddress][_depositId].timestamp;

        uint256 totalPayoutsUnblocked_ = (depositAge / TIME_BETWEEN_PAYMENTS) + 1;
        if (totalPayoutsUnblocked_ > NUMBER_OF_PAYMENTS) {
            totalPayoutsUnblocked_ = NUMBER_OF_PAYMENTS;
        }

        return totalPayoutsUnblocked_;
    }

    /// @dev Returns amount (in wei on Ethereum) that should be unlocked in one time period for the given deposit
    /// @param _depositId deposit id
    function amountForOneWithdrawal(address _beneficiaryAddress, uint256 _depositId) public view returns (uint256){
        return deposits[_beneficiaryAddress][_depositId].sumInWeiDeposited / NUMBER_OF_PAYMENTS;
    }

    /// @dev Returns amount available for withdrawal for given deposit at this time
    /// @param _depositId deposit id
    function amountToWithdrawNow(address _beneficiaryAddress, uint256 _depositId) public view returns (uint256){

        /// the total amount of the withdrawal at the current moment, excluding the previously withdrawn,
        uint256 totalAmount = totalPayoutsUnblocked(_beneficiaryAddress, _depositId) * amountForOneWithdrawal(_beneficiaryAddress, _depositId);

        return totalAmount - deposits[_beneficiaryAddress][_depositId].sumPaidAlready;

    }

    /// @dev Event that will be emitted, when withdrawal was made
    event WithdrawalMade(
        address indexed beneficiary,
        uint256 sumInWei,
        address indexed triggeredByAddress
    );

    /// @dev Returns sum currently available for withdrawal from all deposits for a given address
    function calculateAvailableSumForAllDeposits(address _beneficiaryAddress) external view returns (uint256){

        uint256 sum;

        if (depositsCounter[_beneficiaryAddress] > 0) {

            for (uint256 depositId = 1; depositId <= depositsCounter[_beneficiaryAddress]; depositId ++) {

                sum = sum + amountToWithdrawNow(_beneficiaryAddress, depositId);

            }
        }

        return sum;
    }

    /// @dev Function that transfers the amount currently due to the beneficiary address
    /// @param _beneficiaryAddress beneficiary address
    function withdraw(address _beneficiaryAddress) external returns (bool success) {

        uint256 sumToWithdraw;

        if (depositsCounter[_beneficiaryAddress] > 0) {
            for (uint256 depositId = 1; depositId <= depositsCounter[_beneficiaryAddress]; depositId ++) {

                uint256 amountToWithdrawNow_ = amountToWithdrawNow(_beneficiaryAddress, depositId);

                sumToWithdraw = sumToWithdraw + amountToWithdrawNow_;

                deposits[_beneficiaryAddress][depositId].sumPaidAlready = deposits[_beneficiaryAddress][depositId].sumPaidAlready + amountToWithdrawNow_;

            }
        }

        emit WithdrawalMade(
            _beneficiaryAddress,
            sumToWithdraw,
            msg.sender
        );

        require(
            sumToWithdraw > 0,
            "Sum to withdraw should be > 0"
        );

        payable(_beneficiaryAddress).transfer(sumToWithdraw);

        return true;
    }

}