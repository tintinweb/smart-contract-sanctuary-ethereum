// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

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

// SPDX-License-Identifier: MIT LICENSED
pragma solidity ^0.8.8;

/* This contract is about sending your ETH to the BANK(contract) and retieve when you need or 
   you can send to someone
   function:
   payment
   withdraw
   send_to
   View_deposited amount
   loan:
*/
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./PriceConverter.sol";


error NoBalance();
error InsufficientBalance();
error  NotProvdingLoan();
error  YouHavePayedLoan();
error Blocked();

contract BankingAmount is AutomationCompatibleInterface {
    using PriceConverter for uint256;
    address private immutable i_OwnerAddress;
    uint256 public BankTotalMoney;
    address public contractOwner;
    uint256 public immutable i_interval;
    uint256 public lastTimeStamp;
    uint256 public loanIndex;
    
    struct Custmers {
        address CustmerAddress;
        uint256 amount;
    }
    
    struct peopleLoanDetails{
        address CustmerAddress;
        uint256 loanAmount;
        uint256 timestampLoan;
        bool loanStatus;
        bool blockStatus;  //true==blocked false ==not blocked
    }
    struct BlockedListPeople {
        address blockedAddress;
        uint256 remainingAmount;
    }
    enum loan {ON,OFF}
    
    loan public status;
    AggregatorV3Interface public PriceFeed;
    
    constructor(address PriceFeedAddress,uint256 interval) {
        contractOwner = msg.sender;
        PriceFeed = AggregatorV3Interface(PriceFeedAddress);
        i_interval=interval;
        status=loan.OFF;
        i_OwnerAddress=msg.sender;
    }

    Custmers[] public people;
    peopleLoanDetails[] public peopleLoan;
    BlockedListPeople[] public blockedpeople;

    mapping(address => uint256) public Balance;
    mapping(address => bool) public loanMapping;
    mapping(address => uint256) public loanAmountMapping;
    mapping(address => uint256) public blockedPeople;


    function payment() public payable {
        people.push(
            Custmers(msg.sender, msg.value.getConversionRate(PriceFeed))
        );
        Balance[msg.sender] =
            Balance[msg.sender] +
            msg.value.getConversionRate(PriceFeed);
        BankTotalMoney = Balance[msg.sender];
    }

    function ViewAmount() public view returns (uint256) {
        return Balance[msg.sender];
    }
    function BankTotalAmount() public view returns(uint256){
        return address(this).balance;
    }

    function send_from_BankAccount(address payable to_receiever,uint256 value) public {
        address from_user = msg.sender;
        // (bool sent, ) = payable(to_receiever).call{
        //     value: msg.value
        // }("");
        // require(sent, "Failed to send Ether");
        to_receiever.transfer(value);
        // Balance[to_receiever] = Balance[to_receiever] + Balance[from_user];
        Balance[from_user] = Balance[from_user] - value;
    }

    function withDraw(uint256 value) public {
        address withdraw = msg.sender;
        if (Balance[withdraw] == 0) revert NoBalance();
        if(blockedPeople[msg.sender]!=0) revert Blocked();
        // (bool sent, ) = payable(withdraw).call{value: msg.value}("");
        // require(sent, "Failed to withdraw Ether");
        payable(withdraw).transfer(value);
        Balance[withdraw] = Balance[withdraw] - value;
    }

    function LOAN(uint256 RequestedLoanValue) public {
        // if (BankTotalMoney > RequestedLoanValue.getConversionRate(PriceFeed))
        //     revert InsufficientBalance();
        // if(address(this).balance<)
        if(blockedPeople[msg.sender]!=0) revert Blocked();
        address withdraw = msg.sender;
        payable(withdraw).transfer(RequestedLoanValue);
        BankTotalMoney = BankTotalMoney - RequestedLoanValue;
        lastTimeStamp=block.timestamp;
        peopleLoan.push(peopleLoanDetails(msg.sender,RequestedLoanValue,lastTimeStamp,false,false));
        loanMapping[msg.sender]=false;
        loanAmountMapping[msg.sender]=RequestedLoanValue;
        status=loan.ON;
        checkUpkeep("");
    }

    function PayLoan() public payable{
        if(loanMapping[msg.sender]!=false) revert YouHavePayedLoan();  
        payable(i_OwnerAddress).transfer(loanAmountMapping[msg.sender]);
        loanMapping[msg.sender]=true;
        peopleLoan[peopleLoan.length-1].loanStatus=true;
        }

    function checkUpkeep(
        bytes memory /*checkData*/
    ) public override returns (bool upkeepNeeded, bytes memory /*performData*/) {
        if(status == loan.OFF) revert NotProvdingLoan();
        for(uint256 i=0;i<=peopleLoan.length-1;i++){
            loanIndex=i;
            upkeepNeeded = (
                ((block.timestamp - peopleLoan[i].timestampLoan) > i_interval)
                && !peopleLoan[i].loanStatus 
                && !peopleLoan[i].blockStatus
                );
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        //  (((block.timestamp - lastTimeStamp) > i_interval) && !peopleLoan[peopleLoan.length-1].loanStatus);
        blockedpeople.push(BlockedListPeople(
            peopleLoan[loanIndex].CustmerAddress,
            peopleLoan[loanIndex].loanAmount)
        );
        peopleLoan[loanIndex].blockStatus=true;
        blockedPeople[peopleLoan[loanIndex].CustmerAddress]=peopleLoan[loanIndex].loanAmount;
        status=loan.OFF;
        // if(Balance[peopleLoan[peopleLoan.length-1].CustmerAddress]!=0){
            
        // }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    (, int256 answer, , , ) = priceFeed.latestRoundData();
    // ETH/USD rate in 18 digit
    return uint256(answer * 10000000000);
  }

  // 1000000000
  // call it get fiatConversionRate, since it assumes something about decimals
  // It wouldn't work for every aggregator
  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    uint256 ethPrice = getPrice(priceFeed);
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
    // the actual ETH/USD conversation rate, after adjusting the extra 0s.
    return ethAmountInUsd;
  }
}