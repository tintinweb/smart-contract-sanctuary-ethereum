// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

error Validators__NotEnoughValidators();
error Validators__InvalidRequiredNumberOfApproval();
error Validators__InvalidValidator();
error Validators__NotUniqueValidator();
error Validators__NotValidator();
error Validators__TransactionDoesNotExists();
error Validators__TransactionAlreadyApproved();
error Validators__TransactionAlreadyValidated();
error Validators__NotEnoughValidation();
error Validators__TransactionNotApproved();
error Validators__TransactionAlreadyStakeValidated();
error Validators__NotEnoughStake();
error Validators__TransactionNotStaked();

contract Validators {
    // to store the address of validators
    address[] private validators;

    // validators will be calling most of the function
    // so we want a way to check if the msg.sender is validator or not
    mapping(address => bool) public isValidator;

    // for the required approval
    uint256 public requiredApproval;

    // to store the validation
    struct Validation {
        uint256 totalInsuredAmount; // for how much amount client has done insurance
        bool claimValidates; // once majority validator claimValidates, we'll set this to true
        bool stakeValidates;
    }

    // storing all the validation in a struct
    Validation[] public validations;

    // storing the approval of each validators in a mapping
    // transaction index is mapped to the address of the validators which is mapped
    // with the approval bool
    mapping(uint256 => mapping(address => bool)) public approved;
    mapping(uint256 => mapping(address => bool)) public staked;

    // event DepositAmount(address indexed sender, uint amount);
    event SubmitTransaction(uint256 indexed txn);
    event ApproveTransaction(address indexed validator, uint256 indexed txnId);
    event StakedTransaction(address indexed validator, uint256 indexed txnId);
    event RevokedTransaction(address indexed validator, uint256 indexed txnId);
    event RevokedStaked(address indexed validator, uint256 indexed txnId);
    event ExecuteTransaction(uint256 indexed txnId);
    event ExecuteStakeTransaction(uint256 indexed txnId);

    modifier onlyValidator() {
        if (isValidator[msg.sender]) {
            revert Validators__NotValidator();
        }
        _;
    }

    modifier txnExists(uint256 _txnId) {
        if (_txnId >= validations.length) {
            revert Validators__TransactionDoesNotExists();
        }
        _;
    }

    modifier notApproved(uint256 _txnId) {
        if (approved[_txnId][msg.sender]) {
            revert Validators__TransactionAlreadyApproved();
        }
        _;
    }

    modifier notValidated(uint256 _txnId) {
        if (validations[_txnId].claimValidates) {
            revert Validators__TransactionAlreadyValidated();
        }
        _;
    }

    modifier notStakeValidated(uint256 _txnId) {
        if (validations[_txnId].stakeValidates) {
            revert Validators__TransactionAlreadyStakeValidated();
        }
        _;
    }

    constructor(address[] memory _validators, uint256 _requiredApproval) {
        if (_validators.length <= 3) {
            revert Validators__NotEnoughValidators();
        }
        if (_requiredApproval < 0 && _requiredApproval > _validators.length) {
            revert Validators__InvalidRequiredNumberOfApproval();
        }

        // looping through _owner to save into state variables
        for (uint256 i; i < _validators.length; i++) {
            address validator = _validators[i];
            if (validator == address(0)) {
                revert Validators__InvalidValidator();
            }
            if (isValidator[validator]) {
                revert Validators__NotUniqueValidator();
            }
            // setting that address is a validator
            isValidator[validator] = true;
            // push that address in a validators array
            validators.push(validator);
        }

        requiredApproval = _requiredApproval;
    }

    // fallback() external {

    // }

    // only the validators will be able to approve the transaction.
    // once the transaction is submitted and it has enough approval,
    // client will be able to get the amount

    function appealForclaim(uint256 _totalInsuredAmount) external onlyValidator {
        validations.push(
            Validation({
                totalInsuredAmount: _totalInsuredAmount,
                claimValidates: false,
                stakeValidates: false
            })
        );
        emit SubmitTransaction(validations.length - 1);
    }

    // once the claim is submitted, validators will be able to approve the claim
    function approveClaim(uint256 _txnId)
        external
        onlyValidator
        txnExists(_txnId)
        notApproved(_txnId)
        notValidated(_txnId)
    {
        approved[_txnId][msg.sender] = true;
        emit ApproveTransaction(msg.sender, _txnId);
    }

    function approveStake(uint256 _txnId)
        external
        onlyValidator
        txnExists(_txnId)
        notApproved(_txnId)
        notStakeValidated(_txnId)
    {
        staked[_txnId][msg.sender] = true;
        emit StakedTransaction(msg.sender, _txnId);
    }

    // to execute the claim there needs to more than requiredValidations
    function _getValidationCount(uint256 _txnId) public view returns (uint256 count) {
        // for each validator we go check whether they approve is true or not
        // if true incerement the count
        for (uint256 i; i < validators.length; i++) {
            if (approved[_txnId][validators[i]]) {
                count += 1;
            }
        }
    }

    function _getStakeCount(uint256 _txnId) public view returns (uint256 count) {
        // for each validator we go check whether they approve is true or not
        // if true incerement the count
        for (uint256 i; i < validators.length; i++) {
            if (staked[_txnId][validators[i]]) {
                count += 1;
            }
        }
    }

    // function to execute the claim
    function executeClaim(uint256 _txnId) external txnExists(_txnId) notValidated(_txnId) {
        if (_getValidationCount(_txnId) < requiredApproval) {
            revert Validators__NotEnoughValidation();
        }
        Validation storage validation = validations[_txnId];

        validation.claimValidates = true;
        // low level call

        emit ExecuteTransaction(_txnId);
    }

    function executeStake(uint256 _txnId) external txnExists(_txnId) notStakeValidated(_txnId) {
        if (_getStakeCount(_txnId) < requiredApproval) {
            revert Validators__NotEnoughStake();
        }
        Validation storage validation = validations[_txnId];

        validation.stakeValidates = true;
        // low level call

        emit ExecuteStakeTransaction(_txnId);
    }

    // for the revoke
    // if validators approve the transaction and before it's executed, he changes mind
    // wants to undo the approval
    function revoke(uint256 _txnId) external onlyValidator txnExists(_txnId) notValidated(_txnId) {
        if (!approved[_txnId][msg.sender]) {
            revert Validators__TransactionNotApproved();
        }
        approved[_txnId][msg.sender] = false;
        emit RevokedTransaction(msg.sender, _txnId);
    }

    function revokeValidation(uint256 _txnId)
        external
        onlyValidator
        txnExists(_txnId)
        notStakeValidated(_txnId)
    {
        if (!staked[_txnId][msg.sender]) {
            revert Validators__TransactionNotStaked();
        }
        staked[_txnId][msg.sender] = false;
        emit RevokedStaked(msg.sender, _txnId);
    }
}