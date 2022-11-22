// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ERC20 {
    function transferFrom(
        address from,
        address to,
        uint tokens
    ) external returns (bool success);
}

error PaymentContract__TransferFailed();
error PaymentContract__InsufficientAmount();
error PaymentContract__SenderNotOwner();
error PaymentContract__InvalidPaymentSubscriptionId();
error PaymentContract__PaymentSubscriptionClosed();

contract PaymentContract {
    address public immutable owner;

    uint256 public constant fee = 5;
    address public immutable feeReceiver;

    struct PaymentSubscription {
        address payer;
        uint256 fundsAmount;
        uint256 timeInterval;
        address[] receivers;
        uint256[] values;
        uint256 valuesSum;
        bool closed;
    }

    event NewPaymentSubscription(uint256 index, uint256 startTime);
    event PaymentSubscriptionEnded(uint256 index);

    PaymentSubscription[] public payments;

    constructor(address _feeReceiver) {
        owner = msg.sender;
        feeReceiver = _feeReceiver;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function CreatePaymentSubscriptionEth(
        uint256 _startTime,
        uint256 _timeInterval,
        address[] calldata _receivers,
        uint256[] calldata _values
    ) public payable {
        uint256 sum = 0;

        for (uint256 i = 0; i < _receivers.length; i++) {
            sum += _values[i];
        }

        payments.push(
            PaymentSubscription(
                msg.sender,
                msg.value,
                _timeInterval,
                _receivers,
                _values,
                sum,
                false
            )
        );

        emit NewPaymentSubscription(payments.length - 1, _startTime);
    }

    function CancelPaymentSubscription(uint256 index) private {
        uint256 amountToPay = payments[index].fundsAmount;

        payments[index].fundsAmount = 0;
        payments[index].closed = true;

        (bool success, ) = payable(payments[index].payer).call{
            value: amountToPay
        }("");
        if (!success) revert PaymentContract__TransferFailed();

        emit PaymentSubscriptionEnded(index);
    }

    function PayPaymentEth(uint256 index) public onlyOwner {
        if (index >= payments.length)
            revert PaymentContract__InvalidPaymentSubscriptionId();

        PaymentSubscription memory payment = payments[index];

        if (payment.closed) revert PaymentContract__PaymentSubscriptionClosed();

        uint256 amountToTake = payment.valuesSum +
            (payment.valuesSum * fee) /
            100;

        if (amountToTake > payment.fundsAmount) {
            CancelPaymentSubscription(index);
            return;
        }

        payments[index].fundsAmount -= amountToTake;

        for (uint256 i = 0; i < payment.receivers.length; i++) {
            (bool success, ) = payable(payment.receivers[i]).call{
                value: payment.values[i]
            }("");
            if (!success) revert PaymentContract__TransferFailed();
        }

        (bool feePaymentsuccess, ) = payable(feeReceiver).call{
            value: (payment.valuesSum * fee) / 100
        }("");
        if (!feePaymentsuccess) revert PaymentContract__TransferFailed();
    }

    // function PayAllErc20(
    //     address erc20Contract,
    //     address[] calldata _addresses,
    //     uint256[] calldata _values
    // ) public {
    //     for (uint256 i = 0; i < _addresses.length; i++) {
    //         bool success = ERC20(erc20Contract).transferFrom(
    //             msg.sender,
    //             _addresses[i],
    //             _values[i]
    //         );
    //         if (!success) revert PaymentContract__TransferFailed();
    //     }
    // }
}