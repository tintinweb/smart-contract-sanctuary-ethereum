// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
//import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol"; // Keepers import
import "./TokenPrice.sol";

error Quantity_zero();
error Wallet_error();

contract MarketOrder{//} is KeeperCompatibleInterface {
    using TokenPrice for uint256; //library

    AggregatorV3Interface public priceFeed;

    struct Dades {
        uint256 Quantity;
        uint256 Stop;
    }

    address payable [] private s_Wallets;
    mapping (address => Dades) s_Registre;
    address public immutable i_owner;
    address public s_AddressFeed;



    constructor ( address priceFeedAddress) {
        i_owner = msg.sender;
        s_AddressFeed = priceFeedAddress;
        priceFeed = AggregatorV3Interface(s_AddressFeed);//0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        
    }

    modifier onlyOwner{
        require(msg.sender == i_owner);  
        _;     
    }

    function Deposit(uint256 StopLoss ) public payable {//Deposita quantity i es registre  uint256 StopLoss 
        
        //Pay subscription
        if (msg.value == 0){
            revert Quantity_zero();
        }
        //Add wallet to the s_Wallets
        s_Wallets.push(payable(msg.sender));
        //Start subscription time
        Dades storage dades = s_Registre[msg.sender];
        dades.Quantity += msg.value;
        dades.Stop = StopLoss;
    } 

    function Withdraw () public {
        //Bloqueja si la wallet no esta
        bool listed;
        uint256 num;
        address[] memory id = new address[](s_Wallets.length);
        for (uint i = 0; i < s_Wallets.length; i++){
            id[i] = s_Wallets[i];
            if (listed = (msg.sender == id[i])) {
                num = i;
                break;
            }
        }
        //require(listed, 'Wallet not listed');
        if (!listed){
            revert Wallet_error();
        }
        //Agafa la quanittat que te per fer el W
        Dades memory Quantity = s_Registre[msg.sender];
        uint256 Value = Quantity.Quantity;
        (bool Success, ) = msg.sender.call{value: Value}("");
        require(Success);
        //Reseteja les dades
        Dades storage dades = s_Registre[msg.sender];
        dades.Quantity = 0;
        dades.Stop = 0;
        //Borrar wallet que ha fet W
        s_Wallets = Remove(num);

    }

    function Remove(uint num) internal returns(address payable [] memory) {// Borra la wallet del array borrant la posicio tmb

        for (uint i = num; i < s_Wallets.length - 1; i++){
            s_Wallets[i] = s_Wallets[i+1];
        }
        delete s_Wallets[s_Wallets.length-1];
        s_Wallets.pop();
        return s_Wallets;
    }

    function ModifyFeed(address NewFeed) external onlyOwner {
        s_AddressFeed = NewFeed;
        priceFeed = AggregatorV3Interface(s_AddressFeed);
    }

    //function getEThPrice() 


    // Public view functions
    function ActualFeed() public view returns(address) {
        return s_AddressFeed;
    }
    function CallQuantity(address add) public view returns (uint256){
        Dades memory data = s_Registre[add];
        return (data.Quantity);
    }
    function CallStop(address add) public view returns (uint256){
        Dades memory data = s_Registre[add];
        return (data.Stop);
    }
    function getMembers() public view returns (address[] memory){
      address[] memory id = new address[](s_Wallets.length);
      for (uint i = 0; i < s_Wallets.length; i++) {
          id[i] = s_Wallets[i];
      }
      return id;
    }
    function getBalance() public view returns (uint256){
        return (address(this).balance);
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
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // PriceFeed contract imported from chainlink github

library TokenPrice {
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