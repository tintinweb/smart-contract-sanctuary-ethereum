// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Price Feed
import "./UsdEthPairConverter.sol";

// VRF
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";

// Self-Automation
import "./SelfAutomation.sol";

// Open Zeppelin
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 1- Data Feeds (Done)
// 2- VRF --> Only need to store LINK on the deployed contract (Done)
// 3- Add Self Automation --> Need to Send LINK to the deployed contract and register it to Automation (Done)

// 1000000, 3, 1, 0x779877A7B0D9E8603169DdbD7836e478b4624789, 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46
//  0x779877A7B0D9E8603169DdbD7836e478b4624789,  0x9a811502d843E5a03913d5A2cfb646c11463467A, 0xE16Df59B887e3Caa439E0b29B42bA2e7976FD8b2
// 600
// ["0xC5B7EAd4Ee09352B9B51219BCDcf185E010e730B","0xd7c16863FfD9e15f2c7d488738E02Ffd48dceD4F","0xbD1FcB3965120490FF20Ed448f8A455f9e984413","0x41e9934529175645c3aEF33A6f77889be8c770a1","0x5ca9A3Cfbd5B927Fb3F76e37Ca939ca65d9fd89C"]
// ["1","2","3","4","5"]

// Deployed and working contract -->

error TimeInterval__NotFulfilled();
error SalaryPayment__UpkeepCannotBeFulfilled();
error Cannot__ExtendMaxEmployeeCount();
error Must__BeEqualLength();
error Employee__AddressesMustBeUnique();
error Cannot__SendMoney();
error Not__EnoughMoneyProvided();
error Must__BeContractOwner();
error SalaryPayment__ManualPaymentCannotBeDone();

contract SalaryPayments is
    VRFV2WrapperConsumerBase,
    ConfirmedOwner,
    UsdEthPairConverter,
    SelfAutomation,
    ReentrancyGuard
{
    // VRF
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );
    event AnnounceRaffleWinnerEmployee(address indexed _winnerEmployee);

    struct RequestStatus {
        uint256 paid; // amount paid in link
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    struct winnerEmployeeCredentials {
        address _winnerEmployeeAddress;
        uint _winDate;
    }

    mapping(uint256 => winnerEmployeeCredentials) public WinnerEmployeesMapping;
    uint256 public shuffleCount;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    uint32 callbackGasLimit;
    uint16 requestConfirmations;
    uint32 numWords;
    address linkAddress;
    address wrapperAddress;
    address public s_recentWinnerEmployee;

    // Salary Payment Automation

    event AnnounceAutomatedSalaryPayment(
        uint _paymentCount,
        uint _totalAmountPaidToEmployees,
        uint _timeOfPay
    );
    event AnnounceManualSalaryPayment(
        uint _paymentCount,
        uint _totalAmountPaidToEmployees,
        uint _timeOfPay
    );

    uint constant MAX_EMPLOYEES_COUNT = 20;
    uint public paymentCount;

    struct Employees {
        address employeeAddress;
        uint usdAmount;
    }

    mapping(uint => Employees) public EmployersMapping;
    uint public EmployersMappingLength;

    address[] public employeeAddressList;
    uint[] public usdAmountArray;

    enum salaryPaymentStatus {
        OPEN,
        SENDING,
        CLOSED
    }

    salaryPaymentStatus public statusSalaryPayment;

    constructor(
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords,
        address _linkAddress,
        address _wrapperAddress,
        // Self-Automation
        LinkTokenInterface _link,
        address _registrar,
        AutomationRegistryInterface _registry,
        uint _timeInterval,
        address[] memory _employeeAddressList,
        uint[] memory _usdAmountArray
    )
        payable
        /* VRF */
        ConfirmedOwner(msg.sender)
        VRFV2WrapperConsumerBase(_linkAddress, _wrapperAddress)
        /* Self Automation */
        SelfAutomation(_link, _registrar, _registry, _timeInterval)
        /* Modifiers */
        checkIfListsHaveSameLength(_employeeAddressList, _usdAmountArray)
        checkEmployeeAddressListLength(_employeeAddressList)
        checkEmployeePaymentListLength(_usdAmountArray)
    {
        checkIfThereIsEnoughBalanceToMakeAtLeastOnePayment(_usdAmountArray);

        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
        linkAddress = _linkAddress;
        wrapperAddress = _wrapperAddress;

        statusSalaryPayment = salaryPaymentStatus.OPEN;

        for (uint i = 0; i < _usdAmountArray.length; i++) {
            employeeAddressesMustBeUnique(
                _employeeAddressList[i],
                _employeeAddressList
            ); // To check the uniqueness of the addresses
            EmployersMappingLength++;
            EmployersMapping[i] = Employees(
                _employeeAddressList[i],
                _usdAmountArray[i]
            );
            employeeAddressList.push(_employeeAddressList[i]);
            usdAmountArray.push(_usdAmountArray[i]);
        }
    }

    modifier checkIfListsHaveSameLength(
        address[] memory _employeeAddressList,
        uint[] memory _usdAmountArray
    ) {
        if (_employeeAddressList.length != _usdAmountArray.length) {
            revert Must__BeEqualLength();
        }
        _;
    }

    modifier checkEmployeeAddressListLength(
        address[] memory _employeeAddressList
    ) {
        if (_employeeAddressList.length > MAX_EMPLOYEES_COUNT) {
            revert Cannot__ExtendMaxEmployeeCount();
        }
        _;
    }

    modifier checkEmployeePaymentListLength(uint[] memory _usdAmountArray) {
        if (_usdAmountArray.length > MAX_EMPLOYEES_COUNT) {
            revert Cannot__ExtendMaxEmployeeCount();
        }
        _;
    }

    modifier MustBeOwnerOfContract() {
        if (msg.sender == owner()) {
            revert Must__BeContractOwner();
        }
        _;
    }

    receive() external payable {}

    function checkIfThereIsEnoughBalanceToMakeAtLeastOnePayment(
        uint[] memory _usdAmountArray
    ) public payable {
        if (calculateTotalEthRequiredEachPayment(_usdAmountArray) > msg.value) {
            revert Not__EnoughMoneyProvided();
        }
    }

    function employeeAddressesMustBeUnique(
        address _employeeAddress,
        address[] memory _employeeAddressList
    ) private view {
        for (uint i = 0; i < EmployersMappingLength; i++) {
            if (_employeeAddress == _employeeAddressList[i]) {
                revert Employee__AddressesMustBeUnique();
            }
        }
    }

    function changeContractStatus() public MustBeOwnerOfContract {
        statusSalaryPayment == salaryPaymentStatus.OPEN
            ? statusSalaryPayment = salaryPaymentStatus.CLOSED
            : statusSalaryPayment = salaryPaymentStatus.OPEN;
    }

    function addAnEmployee(
        address _newEmployeeAddress,
        uint _amountToBePaid
    ) public MustBeOwnerOfContract {
        employeeAddressesMustBeUnique(_newEmployeeAddress, employeeAddressList);
        EmployersMapping[EmployersMappingLength] = Employees(
            _newEmployeeAddress,
            _amountToBePaid
        );
        employeeAddressList.push(_newEmployeeAddress);
        usdAmountArray.push(_amountToBePaid);
        EmployersMappingLength++;
    }

    function deleteAnEmployee(
        address _deletedEmployeeAddress
    ) public MustBeOwnerOfContract {
        for (uint i = 0; i < EmployersMappingLength; i++) {
            if (
                EmployersMapping[i].employeeAddress == _deletedEmployeeAddress
            ) {
                delete EmployersMapping[i];
                delete employeeAddressList[i];
                delete usdAmountArray[i];
            }
        }
        EmployersMappingLength--;
    }

    function calculateTotalEthRequiredEachPayment(
        uint[] memory _usdAmountArray
    ) public view returns (uint) {
        // make it only seeble by owner
        uint totalUsdRequiredEachPayment;

        for (uint i = 0; i < EmployersMappingLength; i++) {
            totalUsdRequiredEachPayment += _usdAmountArray[i];
        }

        return (totalUsdRequiredEachPayment * getAnUsdPriceInTermsOfEther());
    }

    function balanceInContract() public view returns (uint) {
        return address(this).balance;
    }

    // Implement withdraw off money
    function withdrawBalance(uint _balance) public MustBeOwnerOfContract {
        (bool success, ) = owner().call{value: _balance}("");
        if (!success) {
            revert Cannot__SendMoney();
        }
    }

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timePassed = ((block.timestamp - last_timestamp) > timeInterval);
        bool isOpen = (statusSalaryPayment == salaryPaymentStatus.OPEN);
        bool hasEmployees = EmployersMappingLength > 0;
        uint totalEthRequiredForThePayment = calculateTotalEthRequiredEachPayment(
                usdAmountArray
            );
        bool hasEnoughBalance = (address(this).balance >=
            totalEthRequiredForThePayment);

        upkeepNeeded = (timePassed &&
            hasEmployees &&
            isOpen &&
            hasEnoughBalance);

        return (upkeepNeeded, "");
    }

    function manualPayment() public onlyOwner {
        bool isOpen = (statusSalaryPayment == salaryPaymentStatus.OPEN);
        bool hasEmployees = EmployersMappingLength > 0;
        uint totalEthRequiredForThePayment = calculateTotalEthRequiredEachPayment(
                usdAmountArray
            );
        bool hasEnoughBalance = (address(this).balance >=
            totalEthRequiredForThePayment);

        bool paymentCheck = (hasEmployees && isOpen && hasEnoughBalance);

        if (!paymentCheck) {
            revert SalaryPayment__ManualPaymentCannotBeDone();
        }

        statusSalaryPayment = salaryPaymentStatus.SENDING;
        uint totalEthRequiredEachPayment;

        for (uint i = 0; i < EmployersMappingLength; i++) {
            uint salaryInEth = EmployersMapping[i].usdAmount *
                getAnUsdPriceInTermsOfEther();

            address addressToGetPaid = EmployersMapping[i].employeeAddress;

            totalEthRequiredEachPayment += salaryInEth;

            (bool success, ) = addressToGetPaid.call{value: salaryInEth}("");
            if (!success) {
                revert Cannot__SendMoney();
            }
        }

        emit AnnounceManualSalaryPayment(
            paymentCount,
            totalEthRequiredEachPayment,
            block.timestamp
        );

        paymentCount++;
        statusSalaryPayment = salaryPaymentStatus.OPEN;
    }

    function performUpkeep(bytes calldata) external nonReentrant {
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert SalaryPayment__UpkeepCannotBeFulfilled();
        }

        statusSalaryPayment = salaryPaymentStatus.SENDING;
        uint totalEthRequiredEachPayment;

        for (uint i = 0; i < EmployersMappingLength; i++) {
            uint salaryInEth = EmployersMapping[i].usdAmount *
                getAnUsdPriceInTermsOfEther();

            address addressToGetPaid = EmployersMapping[i].employeeAddress;

            totalEthRequiredEachPayment += salaryInEth;

            (bool success, ) = addressToGetPaid.call{value: salaryInEth}("");
            if (!success) {
                revert Cannot__SendMoney();
            }
        }

        emit AnnounceAutomatedSalaryPayment(
            paymentCount,
            totalEthRequiredEachPayment,
            block.timestamp
        );

        paymentCount++;
        statusSalaryPayment = salaryPaymentStatus.OPEN;
        last_timestamp = block.timestamp;
    }

    function requestRandomWords()
        external
        onlyOwner
        returns (uint256 requestId)
    {
        requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomWords: new uint256[](0),
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);

        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;

        uint256 indexOfWinner = _randomWords[0] % employeeAddressList.length;
        address recentWinnerEmployee = employeeAddressList[indexOfWinner];
        s_recentWinnerEmployee = recentWinnerEmployee;
        WinnerEmployeesMapping[shuffleCount]._winDate = block.timestamp;
        WinnerEmployeesMapping[shuffleCount]
            ._winnerEmployeeAddress = recentWinnerEmployee;
        shuffleCount++;
        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
        emit AnnounceRaffleWinnerEmployee(recentWinnerEmployee);
    }

    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (uint256 paid, bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].paid > 0, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    function getEmployees() external view returns (address[] memory) {
        return employeeAddressList;
    }

    function getEmployeeSalaries() external view returns (uint[] memory) {
        return usdAmountArray;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice OnchainConfig of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct OnchainConfig {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint32 maxCheckDataSize;
  uint32 maxPerformDataSize;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice state of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @member ownerLinkBalance withdrawable balance of LINK by contract owner
 * @member expectedLinkBalance the expected balance of LINK of the registry
 * @member totalPremium the total premium collected on registry so far
 * @member numUpkeeps total number of upkeeps on the registry
 * @member configCount ordinal number of current config, out of all configs applied to this contract so far
 * @member latestConfigBlockNumber last block at which this config was set
 * @member latestConfigDigest domain-separation tag for current config
 * @member latestEpoch for which a report was transmitted
 * @member paused freeze on execution scoped to the entire registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint96 totalPremium;
  uint256 numUpkeeps;
  uint32 configCount;
  uint32 latestConfigBlockNumber;
  bytes32 latestConfigDigest;
  uint32 latestEpoch;
  bool paused;
}

/**
 * @notice all information about an upkeep
 * @dev only used in return values
 * @member target the contract which needs to be serviced
 * @member executeGas the gas limit of upkeep execution
 * @member checkData the checkData bytes for this upkeep
 * @member balance the balance of this upkeep
 * @member admin for this upkeep
 * @member maxValidBlocknumber until which block this upkeep is valid
 * @member lastPerformBlockNumber the last block number when this upkeep was performed
 * @member amountSpent the amount this upkeep has spent
 * @member paused if this upkeep has been paused
 * @member skipSigVerification skip signature verification in transmit for a low security low cost model
 */
struct UpkeepInfo {
  address target;
  uint32 executeGas;
  bytes checkData;
  uint96 balance;
  address admin;
  uint64 maxValidBlocknumber;
  uint32 lastPerformBlockNumber;
  uint96 amountSpent;
  bool paused;
  bytes offchainConfig;
}

enum UpkeepFailureReason {
  NONE,
  UPKEEP_CANCELLED,
  UPKEEP_PAUSED,
  TARGET_CHECK_REVERTED,
  UPKEEP_NOT_NEEDED,
  PERFORM_DATA_EXCEEDS_LIMIT,
  INSUFFICIENT_BALANCE
}

interface AutomationRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData,
    bytes calldata offchainConfig
  ) external returns (uint256 id);

  function cancelUpkeep(uint256 id) external;

  function pauseUpkeep(uint256 id) external;

  function unpauseUpkeep(uint256 id) external;

  function transferUpkeepAdmin(uint256 id, address proposed) external;

  function acceptUpkeepAdmin(uint256 id) external;

  function updateCheckData(uint256 id, bytes calldata newCheckData) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function setUpkeepOffchainConfig(uint256 id, bytes calldata config) external;

  function getUpkeep(uint256 id) external view returns (UpkeepInfo memory upkeepInfo);

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getTransmitterInfo(address query)
    external
    view
    returns (
      bool active,
      uint8 index,
      uint96 balance,
      uint96 lastCollected,
      address payee
    );

  function getState()
    external
    view
    returns (
      State memory state,
      OnchainConfig memory config,
      address[] memory signers,
      address[] memory transmitters,
      uint8 f
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface AutomationRegistryInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId)
    external
    view
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 fastGasWei,
      uint256 linkNative
    );
}

interface AutomationRegistryExecutableInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId)
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 fastGasWei,
      uint256 linkNative
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/VRFV2WrapperInterface.sol";

/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface KeeperRegistrarInterface {
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        bytes calldata offchainConfig,
        uint96 amount,
        address sender
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Self Automation
import {AutomationRegistryInterface, State, OnchainConfig} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface2_0.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "./KeeperRegistrarInterface.sol";

error Escrow__NotReady();

//  0x779877A7B0D9E8603169DdbD7836e478b4624789,  0x9a811502d843E5a03913d5A2cfb646c11463467A, 0xE16Df59B887e3Caa439E0b29B42bA2e7976FD8b2

contract SelfAutomation {
    // Time Variables
    uint public last_timestamp;
    uint public timeInterval;

    // Automation State Variables
    uint public myUpkeepID;

    // Set Self-Automated Credentials
    LinkTokenInterface public immutable i_link;
    address public immutable registrar;
    AutomationRegistryInterface public immutable i_registry;
    bytes4 registerSig = KeeperRegistrarInterface.register.selector;

    constructor(
        // Self-Automation
        LinkTokenInterface _link,
        address _registrar,
        AutomationRegistryInterface _registry,
        uint _timeInterval
    ) {
        // Self-Automation
        i_link = _link;
        registrar = _registrar;
        i_registry = _registry;
        last_timestamp = block.timestamp;
        timeInterval = _timeInterval;
    }

    // Self-Automation Functions

    function registerAndPredictID(
        string memory name,
        uint32 gasLimit,
        uint96 amount
    ) public {
        (State memory state, , , , ) = i_registry.getState();
        uint256 oldNonce = state.nonce;
        // Encode the data to send to the registrar
        bytes memory payload = abi.encode(
            name,
            "0x",
            address(this),
            // 999999, Max = 2500000
            gasLimit,
            address(msg.sender),
            "0x",
            "0x",
            // 2000000000000000000
            amount,
            address(this)
        );

        // Transfer LINK and call the registrar
        i_link.transferAndCall(
            registrar,
            amount,
            bytes.concat(registerSig, payload)
        );
        (state, , , , ) = i_registry.getState();
        uint256 newNonce = state.nonce;
        if (newNonce == oldNonce + 1) {
            uint256 upkeepID = uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        address(i_registry),
                        uint32(oldNonce)
                    )
                )
            );
            myUpkeepID = upkeepID;
        } else {
            revert("auto-approve disabled");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract UsdEthPairConverter {
    AggregatorV3Interface internal priceFeed;

    constructor() {
        priceFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306 // ETH/USD pair
        );
    }

    function getLatestPrice() private view returns (int) {
        (, /* uint80 roundID */ int price, , , ) = /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
        priceFeed.latestRoundData();
        return (price * 1e10);
    }

    function getAnUsdPriceInTermsOfEther() internal view returns (uint) {
        int EthUsdPair = getLatestPrice();
        return uint(1e36 / EthUsdPair);
    }
}