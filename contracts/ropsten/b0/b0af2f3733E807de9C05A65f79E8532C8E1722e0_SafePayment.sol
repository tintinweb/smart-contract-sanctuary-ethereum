// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/IERCValidableEvent.sol";

// SafePayment main contract for a safe payment platform.
// A safe payment event is a payment that can be validated by another party.
contract SafePayment is ValidableEvent {

    // Payment struct represents a validable payment event.
    struct Payment {
        // Involved Parties
        address issuer; // issuer address of the payment issuer.
        address receiver; // Original Receiver

        // Validators are the possible transaction validators.
        mapping(address => bool) isValidator; // mapping for quick check of validators.
        address[] validators; // list of possible validators.

        // Flags
        bool isValidated; // has not received any reject or approve
        bool isApproved; // final approval status.
        bool isPaid; // if the payment was already made.
        
        // Values
        uint256 paymentValue; // represents the value that must be paid to receiver.
        uint256 validationFee; // represents the value that will be paid for the validator.
    }

    // Mapping from paymentID to transaction.
    mapping(uint256 => Payment) public payments;
    uint256 nextPaymentID = 1;

    // Contract ethereum balance
    uint256 private contractBalance;

    // Indexes
    mapping(address => uint256[]) private issuerIndex;
    mapping(address => uint256[]) private validatorIndex;
    mapping(address => uint256[]) private receiverIndex;


    /// @notice is the payment event constructor.
    /// @param paymentValue is the value that must be paid to payable to. It must be sent in the tx value.
    /// @param validationFee is the fee for the validator. It must be sent in the tx value.
    /// @param receiver the address that this payment is addressed to.
    /// @param validators an array of addresses that can validate this payment.
    function createPayment(
        uint256 paymentValue,
        uint256 validationFee,
        address receiver,
        address[] calldata validators
    ) public payable returns (uint256) {
        require(paymentValue + validationFee == msg.value, "Value must be equal paymentValue and validationFee");
        contractBalance += msg.value;
        
        uint256 paymentID = nextPaymentID;
        nextPaymentID++;

        Payment storage p = payments[paymentID];
        p.issuer = msg.sender;
        p.paymentValue = paymentValue;
        p.receiver = receiver;
        p.validationFee = validationFee;
        p.validators = validators;
        for(uint256 i=0; i < validators.length; i++) {
            p.isValidator[validators[i]] = true;
            // validator index
            validatorIndex[validators[i]].push(paymentID);
        }
        issuerIndex[msg.sender].push(paymentID);
        receiverIndex[receiver].push(paymentID);

        address[] memory parties = new address[](1);
        parties[0] = receiver;
        emit EventCreated(paymentID, msg.sender, parties, validators);

        return paymentID;
    }

    /// @notice returns the total locked value on the contract
    function getContractLockedValue() external view returns(uint256) {
        return contractBalance;
    }

    /// @notice returns the number of payments created on the contract.
    function getTotalPayments() external view returns (uint256) {
        return nextPaymentID - 1;
    }

    /// @notice is the getter for all ids of payments where address passed is a validator
    /// @param validator address of the validator.
    function getValidatorIndex(address validator) external view returns(uint256[] memory paymentIDs ) {
        return validatorIndex[validator];
    }

    /// @notice is the getter for all ids of payments where address passed is an issuer
    /// @param issuer address of the issuer.
    function getIssuerIndex(address issuer) external view returns(uint256[] memory paymentIDs ) {
        return issuerIndex[issuer];
    }

    /// @notice is the getter for all ids of payments where address passed is a receiver
    /// @param receiver address of the receiver.
    function getReceiverIndex(address receiver) external view returns(uint256[] memory paymentIDs ) {
        return receiverIndex[receiver];
    }

     // Event emmited when a transfer is made.
    event EthTransfer(
        address  to,
        uint256  ammount
    );

    function _transfer(address payable _to, uint256 _ammount) internal {
        _to.transfer(_ammount);
        contractBalance -= _ammount;
        emit EthTransfer(_to, _ammount);
    }

    /// @notice claimPayment allows the payment target to withdraw the value from the contract after the payment was validated.
    /// It also allows issuer to retrieve the money is payment was not approved.
    /// @param paymentID is the payment ID.
    function claimPayment(uint256 paymentID) external {
        Payment storage p = payments[paymentID];
        require(p.issuer != address(0), "payment id doesn't exist.");
        require(p.isValidated, "payment wasn't validated.");
        if (p.isApproved) {
            require(p.receiver == msg.sender,"msg.sender is not the receiver of the payment.");
        } else {
            require(p.issuer == msg.sender, "msg.sender is not the issuer of this payment.");
        }
        require(!p.isPaid, "payment was already made.");

        _transfer(payable(msg.sender), p.paymentValue);
        p.isPaid = true;
    }

    // IERCValidatable implementation

    /// @notice Get the status of an event. Status is represented by two boleans, isApproved and isFinal.
    /// @param paymentID Identifier of the payment event.
    /// @return isApproved bool representing if event was approved.
    /// @return isFinal bool representing if event was validated and isApproved is a final approval status.
    function getEventStatus(uint256 paymentID) external view override returns(bool isApproved, bool isFinal){
        Payment storage p = payments[paymentID];
        require(p.issuer != address(0), "payment id doesn't exist.");
        return (p.isApproved, p.isValidated);
    }

    /// @notice Get the approval and reject rates of the event.
    /// For the payment contract, rates are not used.
    /// @param paymentID Identifier of the event.
    /// @return approvalRate uint256 representing the rate of approval.
    /// @return rejectRate uint256 representing the rate of rejection.
    function getEventRates(uint256 paymentID) external view override returns(uint256 approvalRate, uint256 rejectRate) {
        Payment storage p = payments[paymentID];
        require(p.issuer != address(0), "payment id doesn't exist.");
        if (p.isValidated && p.isApproved) {
            return (1, 0);
        }
        return (0,0);
    }

    /// @notice Returns possible addresses that can validate the event with paymentID.
    /// @param paymentID Identifier of the event.
    /// @return address of validator.
    function getEventValidators(uint256 paymentID) external view override returns(address[] memory){ 
        Payment storage p = payments[paymentID];
        require(p.issuer != address(0), "payment id doesn't exist.");
        return p.validators;
    }

    /// @notice Returns a boolean if the address is a possible event validator. 
    /// @param paymentID Identifier of the event.
    /// @param validator Address of the possible validator.
    /// @return bool representing if validator can approve or reject the event with paymentID.
    function isEventValidator(uint256 paymentID, address validator) external view override returns(bool){ 
        Payment storage p = payments[paymentID];
        require(p.issuer != address(0), "payment id doesn't exist.");
        return p.isValidator[validator];
    }


    /// @notice allows sender to reject an event. Should raise error if event was already validated.
    /// For this contract, rates are ignored.
    /// @param paymentID Identifier of the event.
    /// @param rejectRate A rate that can be used by contracts to measure approval when needed.
    function rejectEvent(uint256 paymentID, uint256 rejectRate) external override {
        Payment storage p = payments[paymentID];
        require(p.issuer != address(0), "payment id doesn't exist.");
        require(!p.isValidated, "payment was already validated");
        require(p.isValidator[msg.sender], "msg.sender is not a valid validator for the payment");

        p.isApproved = false;
        p.isValidated = true;
        _transfer(payable(msg.sender), p.validationFee);
        emit EventRejected(paymentID, msg.sender, rejectRate);
    }

    /// @notice allows sender to approve an event. Should raise error if event was already validated.
    /// @param paymentID Identifier of the event.
    /// @param approvalRate A rate that can be used by contracts to measure approval when needed.
    function approveEvent(uint256 paymentID, uint256 approvalRate) external override {
        Payment storage p = payments[paymentID];
        require(p.issuer != address(0), "payment id doesn't exist.");
        require(!p.isValidated, "payment was already validated");
        require(p.isValidator[msg.sender], "msg.sender is not a valid validator for the payment");

        p.isApproved = true;
        p.isValidated = true;
        _transfer(payable(msg.sender), p.validationFee);
        emit EventApproved(paymentID, msg.sender, approvalRate);
    }

    /// @notice should return the issuer of the event.
    /// @param paymentID Identifier of the event.
    /// @return address of the issuer.
    function issuerOf(uint256 paymentID) external view override returns (address) {
        Payment storage p = payments[paymentID];
        require(p.issuer != address(0), "payment id doesn't exist.");
        return p.issuer;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// ValidableEvent is an interface to represent a validatable event.
// An event can represent anything. It must have an unique ID which identifies it.
// The contract that implements should have it's own policy of event validation. 
// The event might have a approvalRate and any logic can be associated with it, since approve and reject functions both accept a rate.
interface ValidableEvent {

  /// @notice Get the status of an event. Status is represented by two boleans, isApproved and isFinal.
  /// @param eventID Identifier of the event.
  /// @return isApproved bool representing if event was approved.
  /// @return isFinal bool representing if event was validated and isApproved is a final approval status.
  function getEventStatus(uint256 eventID) external view returns(bool isApproved, bool isFinal);

  /// @notice Get the approval and reject rates of the event.
  /// @param eventID Identifier of the event.
  /// @return approvalRate uint256 representing the rate of approval.
  /// @return rejectRate uint256 representing the rate of rejection.
  function getEventRates(uint256 eventID) external view returns(uint256 approvalRate, uint256 rejectRate);

  /// @notice Returns possible addresses that can validate the event with eventID.
  /// @param eventID Identifier of the event.
  /// @return address of validator.
  function getEventValidators(uint256 eventID) external view returns(address[] memory);

  /// @notice Returns a boolean if the address is a possible event validator. 
  /// @param eventID Identifier of the event.
  /// @param validator Address of the possible validator.
  /// @return bool representing if validator can approve or reject the event with eventID.
  function isEventValidator(uint256 eventID, address validator) external view returns(bool);

  /// @notice allows sender to reject an event. Should raise error if event was already validated.
  /// @param eventID Identifier of the event.
  /// @param rejectRate A rate that can be used by contracts to measure approval when needed.
  function rejectEvent(uint256 eventID, uint256 rejectRate) external;
  
  /// @notice allows sender to approve an event. Should raise error if event was already validated.
  /// @param eventID Identifier of the event.
  /// @param approvalRate A rate that can be used by contracts to measure approval when needed.
  function approveEvent(uint256 eventID, uint256 approvalRate) external;

  /// @notice should return the issuer of the event.
  /// @param eventID Identifier of the event.
  /// @return address of the issuer.
  function issuerOf(uint256 eventID) external view returns (address);

  // Event emmited when an event is created.
  event EventCreated(
    uint256 indexed eventID,
    address indexed issuer,
    address[] parties,
    address[] validators
  );

  // Event emmited when an event is approved.
  event EventApproved(
    uint256 indexed eventID,
    address indexed validator,
    uint256 approvalRate
  );

  // Event emmited when an event is revoked.
  event EventRejected(
    uint256 indexed eventID,
    address indexed validator,
    uint256 rejectionRate
  );
}