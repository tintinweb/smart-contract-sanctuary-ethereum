// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol"; // Keepers import
import "./PriceConverter.sol";

error Sub_NotQuantity();
error Already_SUB();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 PlayersNum);

contract Code is KeeperCompatibleInterface { //Keeper interface
    using PriceConverter for uint256; //library

    AggregatorV3Interface public priceFeed;

    //Variables

    enum access {
            DENIED,
            GRANTED
        }

    struct Dades {
        uint256 timer;
        access s_access;
    }

    address payable [] private s_Wallets;
    mapping (address => Dades) s_Registre;
    address public immutable i_owner;
    uint256 private s_SubPrice; //USD
    uint256 private s_Interval; //Temps que dura subscripcio 
    uint256 private EthPrice;

    /*Events */
    event subscription(address indexed NewWallet);
    event NewPrice(uint256 indexed PricePlaced);

    constructor (uint256 startPrice /*,uint256 Interval*/, address priceFeedAddress) {
        i_owner = msg.sender;
        s_SubPrice = startPrice;
        s_Interval = 50; //Interval;
        priceFeed = AggregatorV3Interface(priceFeedAddress);//0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    }

    modifier onlyOwner{
        require(msg.sender == i_owner);  
        _;     
    }
    //Functions

    function PriceConversion() public { //Function where I call the conversion
       
        EthPrice = PriceConverter.ConversionToEth(s_SubPrice, priceFeed);
    }


    function checkUpkeep(bytes memory /* checkData */) public view override returns (
        bool upkeepNeeded, 
        bytes memory walletOut
        ){
        
        bool hasPlayers = s_Wallets.length > 0;
        address[] memory id = new address[](s_Wallets.length);
        //address walletOut;

        for (uint i = 0; i < s_Wallets.length; i++) {           //Loop looks for the wallet with a subs > 30 days
          id[i] = s_Wallets[i];
          Dades memory checkTime = s_Registre[id[i]];
          uint256 TimeOut = checkTime.timer;
          bool timePassed = ((block.timestamp - TimeOut) > s_Interval);
            if (timePassed && checkTime.s_access==access.GRANTED) {
                walletOut = abi.encodePacked(i);            //coded to bytes
            }
          upkeepNeeded = (timePassed && hasPlayers && checkTime.s_access==access.GRANTED); //All conditions must be True
        }  
        return (upkeepNeeded, walletOut); // can we comment this out?
    }

    function performUpkeep(bytes calldata walletOut) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_Wallets.length
            );
        }
        //Byte conversion to uint
        uint256 number;
        for(uint i=0;i<walletOut.length;i++){
            number = number + uint(uint8(walletOut[i]))*(2**(8*(walletOut.length-(i+1))));
        }
        //Resets the timer and Denies access
        s_Registre[s_Wallets[number]].timer = 999999999999999999999;
        s_Registre[s_Wallets[number]].s_access = access.DENIED;
        // Dades memory RST = s_Registre[s_Wallets[0]];
        // RST.timer = 1971;
        // RST.s_access = access.DENIED;
    }

    function Subscription() public payable {//uint256 tmr
        
        //Pay subscription
        Dades memory find = s_Registre[msg.sender];
        if (find.s_access == access.GRANTED){
            revert Already_SUB();
        }
        if (msg.value != s_SubPrice){
            revert Sub_NotQuantity();
        }
        //Add wallet to the s_Wallets
        s_Wallets.push(payable(msg.sender));
            //emit RaffleEnter(msg.sender);
        //Start subscription time
        Dades storage dades = s_Registre[msg.sender];
        dades.timer = block.timestamp;

        dades.s_access = access.GRANTED;// Give acces to the wallet
        //s_Registre[msg.sender] += Dades.push(30, access = access.GRANTED);
        emit subscription(msg.sender);
    }

    function changePrice(uint256 newPrice) public onlyOwner {
        s_SubPrice = newPrice;
        emit NewPrice(newPrice);
    }

    function Withdraw () public onlyOwner {
        // (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        // require(callSuccess, "Call failed");
        (bool Success, ) = i_owner.call{value: address(this).balance}("");
        require(Success);
    }

    //Getter functions
    function getOwner() public view returns(address){
        return i_owner;
    }
    function getPrice() public view returns(uint256, uint256) {
        return (s_SubPrice, EthPrice);
    }
    function getBalance() public view onlyOwner returns(uint256) {
        return (address(this).balance);
    }
    function getSubscribers() public view returns (uint256) {
        return s_Wallets.length;
    }
    function callTimer(address add) public view onlyOwner returns (uint256, access){
        Dades memory timer = s_Registre[add];
        return (timer.timer, timer.s_access);
    }
    // function callState(address add) public view onlyOwner returns (access){
    //     Dades memory acc = s_Registre[add];
    //     return acc.s_access;
    // }
    // function callList() public view onlyOwner returns (bytes32[]){
    //     return s_Wallets;
    // }

    function getMembers() public view returns (address[] memory){
      address[] memory id = new address[](s_Wallets.length);
      for (uint i = 0; i < s_Wallets.length; i++) {
          id[i] = s_Wallets[i];
      }
      return id;
    }
    function EthValue() public view returns (uint256) {
        return EthPrice;
    }
    function getPriceFeed () public view returns(AggregatorV3Interface) {
        return priceFeed;
    }
    function getInterval () public view returns(uint256) {
        return s_Interval;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // PriceFeed contract imported from chainlink github

library PriceConverter {
    /**
     * Network: Rinkeby
     * Aggregator: ETH/USD
     * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     */
    function getLatestPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (
            /*uint80 roundID*/,
            int256 price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint256(price);// Retorna 8 decimals
    }

    function ConversionToEth(uint256 DollaAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        uint256 Price = getLatestPrice(priceFeed);
        uint256 EthAmount = (DollaAmount * 100000000000)/Price;
        return EthAmount;
    }
}