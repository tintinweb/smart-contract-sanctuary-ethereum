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

interface AutomationCompatibleInterface {
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
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Currency} from "./PriceConventer.sol";

interface IJobOfferFactory {
    enum OfferType {
        HOURLY,
        SALARY
    }

    function fundJobOffer(uint256 amount, address employerAddress, bool keeperCompatible) external;

    function createJobOffer(
        OfferType contractType,
        uint256 paymentAmount,
        address employeeAddress,
        uint256 paymentRate,
        Currency currency
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./PriceConventer.sol";
import {IJobOfferFactory} from "./IJobOfferFactoryInterface.sol";

error JobOffer_not_enough_amount(uint256 requiredAmount, Currency currency);
error JobOffer_not_employee();
error JobOffer_not_employer();
error JobOffer_invalid_sender();
error JobOffer_transaction_not_successful();
error JobOffer_payment_not_needed();
error JobOffer_wrong_offer_type();
error JobOffer_is_not_keeper_compatible();
error JobOffer_not_closed();
error JobOffer_wrong_state();

enum OfferType {
    HOURLY,
    SALARY
}

struct OfferBetween {
    address employeeAddress;
    address employerAddress;
}

struct PriceFeeds {
    AggregatorV3Interface priceFeedUSDtoETH;
    AggregatorV3Interface priceFeedUSDtoEUR;
}

struct Settings {
    uint256 paymentAmount;
    uint256 paymentRate;
    Currency currency;
    uint256 requiredSalariesFunded;
    OfferType offerType;
    bool keeperCompatible;
}
enum JobOfferState {
    UNSIGNED,
    ACTIVE,
    CLOSED
}

contract JobOffer {
    using PriceConventer for uint256;

    event ContractSigned(address indexed employee, uint256 timestamp);
    event SalaryPaid(address indexed employee, uint256 ethAmount, uint256 timestamp);
    event ContractClosed(JobOfferState indexed state, address indexed closedBy, uint256 timestamp);
    event ContractNeedsToBeFunded(address indexed contractAddress, uint256 ethAmount);

    uint256 private immutable i_paymentAmount;
    address private immutable i_companyAddress;
    address private immutable i_employeeAddress;
    IJobOfferFactory private immutable i_jobOfferFactory;
    Currency private immutable i_currency;
    uint256 private immutable i_paymentRate;
    OfferType private immutable i_offerType;
    bool private immutable i_keeperCompatible;

    uint256 private s_nonPaidWorkedHours;
    AggregatorV3Interface private s_priceFeedUSDtoETH;
    AggregatorV3Interface private s_priceFeedUSDtoEUR;
    uint256 private s_lastPaymentTimestamp;
    JobOfferState private s_state;

    modifier onlyEmployer() {
        if (msg.sender != i_companyAddress) {
            revert JobOffer_not_employer();
        }
        _;
    }

    modifier onlyEmployee() {
        if (msg.sender != i_employeeAddress) {
            revert JobOffer_not_employee();
        }
        _;
    }

    modifier payment() {
        if (s_lastPaymentTimestamp + i_paymentRate > block.timestamp) {
            revert JobOffer_payment_not_needed();
        }
        _;
    }

    modifier active() {
        if (s_state != JobOfferState.ACTIVE) {
            revert JobOffer_wrong_state();
        }
        _;
    }

    modifier hourly() {
        if (i_offerType == OfferType.SALARY) {
            revert JobOffer_wrong_offer_type();
        }
        _;
    }

    modifier salary() {
        if (i_offerType == OfferType.HOURLY) {
            revert JobOffer_wrong_offer_type();
        }
        _;
    }

    constructor(
        OfferBetween memory offerBetween,
        PriceFeeds memory priceFeeds,
        Settings memory settings
    ) payable {
        i_currency = settings.currency;
        s_priceFeedUSDtoETH = priceFeeds.priceFeedUSDtoETH;
        s_priceFeedUSDtoEUR = priceFeeds.priceFeedUSDtoEUR;
        uint256 requiredAmountFunded = (settings.paymentAmount *
            settings.requiredSalariesFunded *
            95) / 100;
        if (i_currency != Currency.ETH) {
            if (
                msg.value.getCurrencyAmount(s_priceFeedUSDtoETH, s_priceFeedUSDtoEUR, i_currency) <
                requiredAmountFunded
            ) {
                revert JobOffer_not_enough_amount(requiredAmountFunded, settings.currency);
            }
        } else if (msg.value < requiredAmountFunded) {
            revert JobOffer_not_enough_amount(requiredAmountFunded, settings.currency);
        }
        i_keeperCompatible = settings.keeperCompatible;
        i_offerType = settings.offerType;
        i_paymentAmount = settings.paymentAmount;
        i_paymentRate = settings.paymentRate;
        i_employeeAddress = offerBetween.employeeAddress;
        i_companyAddress = offerBetween.employerAddress;
        s_state = JobOfferState.UNSIGNED;
        s_lastPaymentTimestamp = 0;
        i_jobOfferFactory = IJobOfferFactory(msg.sender);
    }

    function sign() public onlyEmployee returns (JobOfferState) {
        if (s_state != JobOfferState.UNSIGNED) {
            revert JobOffer_wrong_state();
        }
        s_state = JobOfferState.ACTIVE;
        emit ContractSigned(i_employeeAddress, block.timestamp);
        return s_state;
    }

    function close() public returns (JobOfferState) {
        if (msg.sender == i_companyAddress || msg.sender == i_employeeAddress) {
            s_state = JobOfferState.CLOSED;
            emit ContractClosed(s_state, msg.sender, block.timestamp);
            return s_state;
        }
        revert JobOffer_invalid_sender();
    }

    function pay() internal returns (uint256) {
        uint256 paymentAmount = i_paymentAmount;
        if (i_currency != Currency.ETH) {
            paymentAmount = paymentAmount.getEthAmount(
                s_priceFeedUSDtoETH,
                s_priceFeedUSDtoEUR,
                i_currency
            );
        }
        if (i_offerType == OfferType.HOURLY) {
            paymentAmount *= s_nonPaidWorkedHours;
        }
        (bool success, ) = i_employeeAddress.call{value: paymentAmount}("");
        if (!success) {
            revert JobOffer_transaction_not_successful();
        }
        try
            i_jobOfferFactory.fundJobOffer(paymentAmount, i_companyAddress, i_keeperCompatible)
        {} catch {
            emit ContractNeedsToBeFunded(address(this), paymentAmount);
        }
        s_lastPaymentTimestamp = block.timestamp;
        emit SalaryPaid(i_employeeAddress, paymentAmount, block.timestamp);
        s_nonPaidWorkedHours = 0;
        return paymentAmount;
    }

    function setWorkedHours(
        uint256 workedHours
    ) public onlyEmployee active hourly returns (uint256) {
        s_nonPaidWorkedHours += workedHours;
        return s_nonPaidWorkedHours;
    }

    function payWorkedHours() public onlyEmployee payment hourly returns (uint256) {
        return pay();
    }

    function payMonthly() public onlyEmployer payment salary active returns (uint256) {
        return pay();
    }

    function performUpkeep() public payment active returns (uint256) {
        if (!i_keeperCompatible) {
            revert JobOffer_is_not_keeper_compatible();
        }
        return pay();
    }

    function withdraw() public onlyEmployer {
        if (s_state != JobOfferState.CLOSED) {
            revert JobOffer_not_closed();
        }
        uint256 balance = address(this).balance;
        if (i_offerType == OfferType.HOURLY) {
            balance -=
                i_paymentAmount.getEthAmount(s_priceFeedUSDtoETH, s_priceFeedUSDtoEUR, i_currency) *
                s_nonPaidWorkedHours;
        }
        (bool success, ) = payable(i_companyAddress).call{value: balance}("");
        if (!success) {
            revert JobOffer_transaction_not_successful();
        }
    }

    fallback() external payable {}

    receive() external payable {}

    function getWorkedHours() public view returns (uint256) {
        return s_nonPaidWorkedHours;
    }

    function getLastPaymentTimestamp() external view returns (uint256) {
        return s_lastPaymentTimestamp;
    }

    function getPaymentRate() external view returns (uint256) {
        return i_paymentRate;
    }

    function getPaymentAmount() external view returns (uint256) {
        return i_paymentAmount;
    }

    function getState() external view returns (JobOfferState) {
        return s_state;
    }

    function getCurrency() external view returns (Currency) {
        return i_currency;
    }

    function getEthAmount() external view returns (uint256) {
        return i_paymentAmount.getEthAmount(s_priceFeedUSDtoETH, s_priceFeedUSDtoEUR, i_currency);
    }

    function getEmployeeAddress() external view returns (address) {
        return i_employeeAddress;
    }

    function getEmployerAddress() external view returns (address) {
        return i_companyAddress;
    }

    function isKeeperCompatible() external view returns (bool) {
        return i_keeperCompatible;
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

import {PriceConventer, Currency} from "./PriceConventer.sol";
import {JobOffer, OfferType, Settings, OfferBetween, PriceFeeds, JobOfferState} from "./JobOffer.sol";

error JobOfferFactory_transaction_not_successful();
error JobOfferFactory_not_enough_eth_funded(uint256 requiredEthAmount, uint256 balance);
error JobOfferFactory_not_valid_offer(address offerAddress);
error JobOfferFactory_employer_does_not_have_enough_balance();
error JobOfferFactory_not_all_offers_closed();
error JobOfferFactory_zero_balance();

contract JobOfferFactory is KeeperCompatibleInterface {
    using PriceConventer for uint256;

    struct Employer {
        uint256 balance;
        Offer[] offers;
    }

    struct Employee {
        Offer[] offers;
    }

    struct Offer {
        address offerAddress;
        OfferType offerType;
    }

    event OfferCreated(
        address indexed offerAddress,
        OfferType offerType,
        address employer,
        address employee
    );

    uint256 private constant REQUIRED_HOURS_FUNDED = 72 * 8;
    uint256 private constant REQUIRED_SALARIES_FUNDED = 3;
    uint256 public constant KEEPER_COMPATIBLE_FEE = 5000000000000000;

    AggregatorV3Interface private priceFeedUSDtoETH;
    AggregatorV3Interface private priceFeedUSDtoEUR;
    address private immutable owner;

    mapping(address => Employer) private employerData;
    mapping(address => Employee) private employeeData;

    address[] private validOffers;

    constructor(address priceFeedUSDtoETHAddress, address priceFeedEURtoUSDAddress) {
        priceFeedUSDtoETH = AggregatorV3Interface(priceFeedUSDtoETHAddress);
        priceFeedUSDtoEUR = AggregatorV3Interface(priceFeedEURtoUSDAddress);
        owner = msg.sender;
    }

    function fund() public payable {
        employerData[msg.sender].balance += msg.value;
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    function createJobOffer(
        OfferType contractType,
        uint256 paymentAmount,
        address employeeAddress,
        uint256 paymentRate,
        Currency currency,
        bool keeperCompatible
    ) external returns (address) {
        uint256 requiredSalariesFunded = REQUIRED_SALARIES_FUNDED;
        if (contractType == OfferType.HOURLY) {
            requiredSalariesFunded = REQUIRED_HOURS_FUNDED;
        }
        uint256 fee = 0;
        if (keeperCompatible) {
            fee = KEEPER_COMPATIBLE_FEE;
        }
        uint256 requiredEthAmount = paymentAmount.getEthAmount(
            priceFeedUSDtoETH,
            priceFeedUSDtoEUR,
            currency
        ) *
            requiredSalariesFunded +
            fee;
        if (requiredEthAmount > employerData[msg.sender].balance) {
            revert JobOfferFactory_not_enough_eth_funded(
                requiredEthAmount,
                employerData[msg.sender].balance
            );
        }
        JobOffer offer = new JobOffer{value: requiredEthAmount - fee}(
            OfferBetween(employeeAddress, msg.sender),
            PriceFeeds(priceFeedUSDtoETH, priceFeedUSDtoEUR),
            Settings(
                paymentAmount,
                paymentRate,
                currency,
                requiredSalariesFunded,
                contractType,
                keeperCompatible
            )
        );
        employerData[msg.sender].balance -= requiredEthAmount;
        if (keeperCompatible) {
            payKeeperCompatibleFee();
        }
        employerData[msg.sender].offers.push(Offer((address(offer)), contractType));
        employeeData[employeeAddress].offers.push(Offer((address(offer)), contractType));
        validOffers.push(address(offer));
        emit OfferCreated(address(offer), contractType, msg.sender, employeeAddress);
        return address(offer);
    }

    function fundJobOffer(uint256 amount, address employerAddress, bool keeperCompatible) external {
        if (!isValidOffer(msg.sender)) {
            revert JobOfferFactory_not_valid_offer(msg.sender);
        }
        uint256 fee = 0;
        if (keeperCompatible) {
            fee = KEEPER_COMPATIBLE_FEE;
            payKeeperCompatibleFee();
        }
        if (employerData[employerAddress].balance < amount + fee) {
            revert JobOfferFactory_employer_does_not_have_enough_balance();
        }
        employerData[employerAddress].balance -= amount + fee;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert JobOfferFactory_transaction_not_successful();
        }
    }

    function isValidOffer(address offerAddress) internal view returns (bool) {
        for (uint8 i = 0; i < validOffers.length; i++) {
            if (validOffers[i] == offerAddress) {
                return true;
            }
        }
        return false;
    }

    function countRequiredFund(
        uint256 amount,
        Currency currency,
        OfferType offerType,
        bool keeperCompatible
    ) external view returns (uint256) {
        uint256 requiredSalariesFunded = REQUIRED_SALARIES_FUNDED;
        if (offerType == OfferType.HOURLY) {
            requiredSalariesFunded = REQUIRED_HOURS_FUNDED;
        }
        uint256 fee = 0;
        if (keeperCompatible) {
            fee = KEEPER_COMPATIBLE_FEE;
        }
        return
            amount.getEthAmount(priceFeedUSDtoETH, priceFeedUSDtoEUR, currency) *
            requiredSalariesFunded +
            fee;
    }

    function parseEthToCurrency(uint256 amount, Currency currency) external view returns (uint256) {
        return amount.getCurrencyAmount(priceFeedUSDtoETH, priceFeedUSDtoEUR, currency);
    }

    function checkUpkeep(
        bytes memory /*checkData*/
    ) public pure override returns (bool upkeepNeeded, bytes memory /*performData*/) {
        upkeepNeeded = true;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        for (uint8 i = 0; i < validOffers.length; i++) {
            JobOffer offer = JobOffer(payable(validOffers[i]));
            if (!offer.isKeeperCompatible()) {
                continue;
            }
            offer.performUpkeep();
        }
    }

    function payKeeperCompatibleFee() internal {
        (bool success, ) = payable(owner).call{value: KEEPER_COMPATIBLE_FEE}("");
        if (!success) {
            revert JobOfferFactory_transaction_not_successful();
        }
    }

    function isAllOffersClosed(address employer) internal view returns (bool) {
        for (uint8 i = 0; i < employerData[employer].offers.length; i++) {
            if (
                JobOffer(payable(employerData[employer].offers[i].offerAddress)).getState() !=
                JobOfferState.CLOSED
            ) {
                return false;
            }
        }
        return true;
    }

    function withdraw() public {
        if (employerData[msg.sender].balance == 0) {
            revert JobOfferFactory_zero_balance();
        }
        if (!isAllOffersClosed(msg.sender)) {
            revert JobOfferFactory_not_all_offers_closed();
        }
        (bool success, ) = payable(msg.sender).call{value: employerData[msg.sender].balance}("");
        if (!success) {
            revert JobOfferFactory_transaction_not_successful();
        }
    }

    function getEmployerData() external view returns (Employer memory) {
        return employerData[msg.sender];
    }

    function getEmployeeData() external view returns (Employee memory) {
        return employeeData[msg.sender];
    }

    function getKeeperCompatibleFee() external pure returns (uint256) {
        return KEEPER_COMPATIBLE_FEE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

enum Currency {
    ETH,
    USD,
    EUR
}

library PriceConventer {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256, uint8) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        return (uint256(price), decimals);
    }

    function getCurrencyAmount(
        uint256 ethAmount,
        AggregatorV3Interface priceFeedUSDtoETH,
        AggregatorV3Interface priceFeedUSDtoEUR,
        Currency currency
    ) internal view returns (uint256) {
        if (currency == Currency.ETH) {
            return ethAmount;
        } else if (currency == Currency.USD) {
            (uint256 ethPrice, uint8 priceDecimals) = getPrice(priceFeedUSDtoETH);
            uint256 amountInCurrency = (ethPrice * ethAmount) / (10 ** priceDecimals);
            return amountInCurrency;
        } else {
            (uint256 ethPrice, uint8 priceDecimals) = getPrice(priceFeedUSDtoETH);
            (uint256 eurPrice, ) = getPrice(priceFeedUSDtoEUR);
            uint256 rate = (ethPrice * (10 ** priceDecimals)) / eurPrice;
            uint256 amountInCurrency = (ethAmount / (10 ** priceDecimals)) * rate;
            return amountInCurrency;
        }
    }

    function getEthAmount(
        uint256 amountInCurrency,
        AggregatorV3Interface priceFeedUSDtoETH,
        AggregatorV3Interface priceFeedUSDtoEUR,
        Currency currency
    ) internal view returns (uint256) {
        if (currency == Currency.ETH) {
            return amountInCurrency;
        } else if (currency == Currency.USD) {
            (uint256 ethPrice, uint8 priceDecimals) = getPrice(priceFeedUSDtoETH);
            uint256 ethAmount = amountInCurrency / ethPrice;
            return ethAmount * (10 ** priceDecimals);
        } else {
            (uint256 ethPrice, uint8 priceDecimals) = getPrice(priceFeedUSDtoETH);
            (uint256 eurPrice, ) = getPrice(priceFeedUSDtoEUR);
            uint256 rate = (ethPrice * (10 ** priceDecimals)) / eurPrice;
            uint256 ethAmount = amountInCurrency / rate;
            return ethAmount * (10 ** priceDecimals);
        }
    }
}