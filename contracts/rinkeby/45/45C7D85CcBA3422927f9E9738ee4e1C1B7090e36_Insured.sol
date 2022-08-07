// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./Types.sol";
import "./Insurance.sol";

error Insured__NotEnoughInsuranceAmount();
error Insured__HasAlreadyInsured();
error Insured__NoNeedToPayFine();
error Insured__UpKeepNotNeeded();
error Insured__PhaseNumberNotCorrect();
error Insured__InsuredAountPaymentFailed();
error Insured__AmountNotPerSession();

contract Insured {
    uint256 public constant FINE_PERCENT = 10; // fine percentage if insured person doesn't pay in time

    Insurance private immutable i_insurance;

    enum InsuranceState {
        NotInsured, // still no insurance done
        InProcess, // insurance is done for certain time period
        Closed // insurance time period is done
    }

    enum PaymentPhase {
        firstPhase, // full payment done at once before the payment time
        secondPhase, // can pay twice to pay the total amount before the payment time
        thirdPhase // can pay thrice to pay the total amount before the payment time
    }

    PaymentPhase private paymentPhaseState;

    InsuranceState private insuranceState;

    Types.Details private insuredDetail;

    event SuccessfulWithdraw(address indexed insured, uint256 indexed amount);

    constructor(
        uint256 _insuredAmount,
        uint256 _interval,
        uint256 _timeToPay,
        address payable _insuranceContractAddress,
        uint256 _insuredAmountPerSession
    ) {
        insuredDetail.insuredAmount = _insuredAmount;
        insuredDetail.startingBlockTime = block.timestamp;
        insuredDetail.interval = _interval;
        insuredDetail.timeToPay = _timeToPay;
        insuranceState = InsuranceState.InProcess;
        i_insurance = Insurance(_insuranceContractAddress);
        insuredDetail.insuredAmountPerSession = _insuredAmountPerSession;
    }

    function payInsuranceAmount(uint256 phaseNumber) external payable {
        if (insuranceState != InsuranceState.InProcess) {
            revert Insured__HasAlreadyInsured();
        }
        // if (msg.value < insuredDetail.insuredAmountPerSession) {
        //     revert Insured__NotEnoughInsuranceAmount();
        // }
        if (phaseNumber < 0 || phaseNumber > 3) {
            revert Insured__PhaseNumberNotCorrect();
        }
        insuredDetail.payedTime = block.timestamp;
        // payes the insured Amount

        insuredDetail.paymentPhase = phaseNumber;

        if (insuredDetail.insuredAmountPerSession != msg.value * phaseNumber) {
            revert Insured__AmountNotPerSession();
        }

        insuredDetail.payedAmount += msg.value;

        (bool success, ) = address(i_insurance).call{value: address(this).balance}("");
        if (!success) {
            revert Insured__InsuredAountPaymentFailed();
        }
    }

    function setInsuredDetail(
        address x,
        uint256 _insuredAmount,
        uint256 _startingBlockTime,
        uint256 _interval,
        uint256 _timeToPay,
        uint256 _payedAmount,
        uint256 _payedTime,
        uint256 _insuredAmountPerSession,
        uint256 _paymentPhase
    ) public {
        i_insurance.setInsuranceDetail(
            x,
            _insuredAmount,
            _startingBlockTime,
            _interval,
            _timeToPay,
            _payedAmount,
            _payedTime,
            _insuredAmountPerSession,
            _paymentPhase
        );
    }

    // returns whether the insurance time period has finished or not
    function timeFinished() public {
        if (block.timestamp >= insuredDetail.startingBlockTime + insuredDetail.interval) {
            insuredDetail.readyToPay = true;
        }
    }

    // returns whether or not insured person has the right to claim
    function rightToClaim() public {
        if (
            insuredDetail.readyToPay == true &&
            insuredDetail.payedAmount == insuredDetail.insuredAmount
        ) {
            insuredDetail.rightToClaim = true;
        }
    }

    // returns whether insured person has paying the insurance in time or not
    // otherwise 10% fine will be charged
    function timePassed() public {
        if (insuredDetail.timeToPay < insuredDetail.payedTime) {
            insuredDetail.timePassed = true;
        }
    }

    // fine is charged if the insured person exceeds the payment day i.e s_payedTime
    function payInsuredAmountWithFine() public {
        if (insuredDetail.timePassed == false) {
            revert Insured__NoNeedToPayFine();
        }
        insuredDetail.insuredAmountPerSession =
            insuredDetail.insuredAmountPerSession +
            (insuredDetail.insuredAmountPerSession * FINE_PERCENT) /
            100;
    }

    function getInsuredDetail()
        public
        view
        returns (
            uint256 insuredAmount,
            uint256 startingBlockTime,
            uint256 interval,
            uint256 timeToPay,
            uint256 payedAmount,
            uint256 payedTime,
            uint256 insuredAmountPerSession,
            uint256 paymentPhase,
            bool,
            bool readyToPay,
            bool,
            bool twoConsutiveFail,
            bool claimReturnedByValidator
        )
    // bool stakeReturnedByValidator
    {
        return (
            insuredDetail.insuredAmount,
            insuredDetail.startingBlockTime,
            insuredDetail.interval,
            insuredDetail.timeToPay,
            insuredDetail.payedAmount,
            insuredDetail.payedTime,
            insuredDetail.insuredAmountPerSession,
            insuredDetail.paymentPhase,
            insuredDetail.timePassed,
            insuredDetail.readyToPay,
            insuredDetail.rightToClaim,
            insuredDetail.threeDelayed,
            insuredDetail.claimReturnedByValidator
            // insuredDetail.stakeReturnedByValidator
        );
    }

    function getFinePercent() public pure returns (uint256) {
        return FINE_PERCENT;
    }
}

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

    function appeal(uint256 _totalInsuredAmount) external onlyValidator {
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

//["0xdD870fA1b7C4700F2BD7f44238821C26f7392148", "0x583031D1113aD414F02576BD6afaBfb302140225", "0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB", "0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C"]

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

library Types {
    struct Details {
        uint256 insuredAmount; //  amount person is insuring for
        uint256 startingBlockTime; // starting time the person has insured
        uint256 interval; // for how long he's insuring
        uint256 timeToPay; // yearly or monthy payment time by the insured person
        uint256 payedAmount; // amount payed during insurance
        uint256 payedTime; // time when insured person has payed
        uint256 insuredAmountPerSession; // amount paid at certain time period
        uint256 paymentPhase; // times when one can pay the insured amount
        bool timePassed; // does that payment time passed?
        bool readyToPay; // is the whole time period finished?
        bool rightToClaim; // is the insured person has right to claim?
        bool threeDelayed; // does the insured person failed to give the insured amount times
        bool claimReturnedByValidator;
        // bool stakeReturnedByValidator;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./Types.sol";
import "./Validators.sol";

error Insurance__PhaseNumberNotCorrect();
error Insurance__UpKeepNotNeeded();
error Insurance__NotOwner();
error Insurance__AdminWithdrawFailed();
error Insurance__NotEnoughBalance();
error Insurance__NotValidateForStake();
error Insurance__DepositedAmountNotEqualToWithdrawnAmount();

contract Insurance is KeeperCompatibleInterface {
    address public s_insuredAddress;
    uint256 private s_contractBalance = 0;
    address private immutable i_owner;
    Validators private immutable i_validators;
    uint256 constant REQUIREDVALIDATORS = 3;
    uint256 public txnId = 0;
    uint256 private withdrawBalance = 0;
    bool private staked = false;
    uint256 public count = 0;

    event SuccessfulClaim(address indexed insuredAddress, uint256 indexed amount);

    event InsuredAmount(address indexed insuredAddress, uint256 indexed insuredAmount);

    // for tracking the insured details
    mapping(address => Types.Details) private trackingDetail;

    constructor(address _owner, address _validatorsContractAddress) {
        i_owner = _owner;
        i_validators = Validators(_validatorsContractAddress);
    }

    modifier onlyOwner() {
        if (i_owner != msg.sender) {
            revert Insurance__NotOwner();
        }
        _;
    }

    function getAppeal(uint256 insuredAmount) public {
        i_validators.appeal(insuredAmount);
    }

    // sets the stake of the Insurance owner to true
    // only validators are allowed to do it
    function setStake() public {
        i_validators.approveStake(txnId);
        // if (i_validators._getStakeCount(txnId) >= REQUIREDVALIDATORS){
        //     approved[txnId][msg.sender] = true;
        count++;
        if (count > 2) {
            staked = true;
            txnId += 1;
            count = 0;
        }

        // }
    }

    function getStakeCount() public view returns (uint256) {
        return i_validators._getStakeCount(txnId);
    }

    // sets the claim of the client to true
    // only validators are allowed to do it
    function setClaim(address x) public {
        i_validators.approveClaim(txnId);
        if (i_validators._getValidationCount(txnId) >= REQUIREDVALIDATORS) {
            trackingDetail[x].claimReturnedByValidator = true;
            txnId += 1;
        }
    }

    function recieveInsuredAmount() external {}

    // ownly owner could withdraw form the balance
    // but needs to stake the property
    // staking is still needs to maintain
    function withdraw() public payable onlyOwner {
        if (!staked) {
            revert Insurance__NotValidateForStake();
        }
        if (s_contractBalance <= 0) {
            revert Insurance__NotEnoughBalance();
        }
        s_contractBalance = s_contractBalance - msg.value;
        withdrawBalance += msg.value;
        (bool success, ) = payable(i_owner).call{value: address(this).balance}("");
        if (!success) {
            revert Insurance__AdminWithdrawFailed();
        }
    }

    // only owner could deposit the amount that he/she has withdrawn
    function deposit() public payable onlyOwner {
        if (msg.value != withdrawBalance) {
            revert Insurance__DepositedAmountNotEqualToWithdrawnAmount();
        }
        s_contractBalance += msg.value;
    }

    // checks is the particular address
    function timeFinished(address x) public {
        if (block.timestamp >= trackingDetail[x].startingBlockTime + trackingDetail[x].interval) {
            trackingDetail[x].readyToPay = true;
        }
    }

    // does particular address has the right to claim
    function rightToClaim(address x) public {
        if (
            trackingDetail[x].readyToPay == true &&
            trackingDetail[x].payedAmount == trackingDetail[x].insuredAmount &&
            trackingDetail[x].claimReturnedByValidator
        ) {
            trackingDetail[x].rightToClaim = true;
        }
    }

    // does the payed time exceeds the payment time
    function timePassed(address x) public {
        if (trackingDetail[x].timeToPay < trackingDetail[x].payedTime) {
            trackingDetail[x].timePassed = true;
        }
    }

    function isThreeFail(address x) public {
        uint256 failCount = 0;
        if (trackingDetail[x].timePassed) {
            failCount += 1;
        }

        if (failCount == 3) {
            trackingDetail[x].threeDelayed = true;
            transferFailedAmountToInsurance(x);
        }
    }

    function transferFailedAmountToInsurance(address x) internal {
        s_contractBalance += trackingDetail[x].payedAmount;
        delete (trackingDetail[x]);
    }

    function transferFineToInsurance(address x) public {
        uint256 amount;
        if (isTimePasses(x)) {
            amount = trackingDetail[x].payedAmount;
            amount = (amount * 10) / 100;
            s_contractBalance += amount;
            isThreeFail(x);
        }
    }

    // returns the condition for the contract to automatically run
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = (!(isTimeFinished(s_insuredAddress)) &&
            isTimePasses(s_insuredAddress) &&
            isRightToClaim(s_insuredAddress) &&
            isFullPaymentDone(s_insuredAddress) &&
            trackingDetail[s_insuredAddress].claimReturnedByValidator);
        return (upkeepNeeded, "0x0");
    }

    // automatically runs after the insurance time period has finished
    // so that insured gets payed
    function performUpkeep(
        bytes calldata /* callData */
    ) external override {
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Insurance__UpKeepNotNeeded();
        }
        trackingDetail[s_insuredAddress].payedAmount += trackingDetail[s_insuredAddress]
            .insuredAmount;
        emit SuccessfulClaim(s_insuredAddress, trackingDetail[s_insuredAddress].insuredAmount);
        trackingDetail[s_insuredAddress].insuredAmount = 0;
        trackingDetail[s_insuredAddress].readyToPay = false;
        trackingDetail[s_insuredAddress].rightToClaim = false;
        trackingDetail[s_insuredAddress].claimReturnedByValidator = false;
    }

    function setInsuranceDetail(
        address x,
        uint256 _insuredAmount,
        uint256 _startingBlockTime,
        uint256 _interval,
        uint256 _timeToPay,
        uint256 _payedAmount,
        uint256 _payedTime,
        uint256 _insuredAmountPerSession,
        uint256 _paymentPhase
    ) external {
        trackingDetail[x].insuredAmount = _insuredAmount;
        trackingDetail[x].startingBlockTime = _startingBlockTime;
        trackingDetail[x].interval = _interval;
        trackingDetail[x].timeToPay = _timeToPay;
        trackingDetail[x].payedAmount = _payedAmount;
        trackingDetail[x].payedTime = _payedTime;
        trackingDetail[x].insuredAmountPerSession = _insuredAmountPerSession;
        trackingDetail[x].paymentPhase = _paymentPhase;
    }

    function isTimeFinished(address x) public view returns (bool) {
        return trackingDetail[x].readyToPay;
    }

    function isRightToClaim(address x) public view returns (bool) {
        return trackingDetail[x].rightToClaim;
    }

    function isTimePasses(address x) public view returns (bool) {
        return trackingDetail[x].timePassed;
    }

    function isFullPaymentDone(address x) public view returns (bool) {
        return trackingDetail[x].insuredAmount == trackingDetail[x].payedAmount;
    }

    function _getContractBalance() private view onlyOwner returns (uint256) {
        return s_contractBalance;
    }

    function getRemainingDetail(address x) public view returns (Types.Details memory) {
        return trackingDetail[x];
    }

    receive() external payable {
        trackingDetail[msg.sender].payedAmount = msg.value;
        s_insuredAddress = msg.sender;
        s_contractBalance += trackingDetail[msg.sender].payedAmount;
        emit InsuredAmount(msg.sender, msg.value);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getInsuredDetail(address x)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            trackingDetail[x].insuredAmount,
            trackingDetail[x].startingBlockTime,
            trackingDetail[x].interval,
            trackingDetail[x].timeToPay,
            trackingDetail[x].payedAmount,
            trackingDetail[x].payedTime,
            trackingDetail[x].insuredAmountPerSession
        );
        // trackingDetail[x].timePassed;
        // trackingDetail[x].readyToPay;
        // trackingDetail[x].rightToClaim;
        // trackingDetail[x].threeDelayed;
        // trackingDetail[x].claimReturnedByValidator;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}