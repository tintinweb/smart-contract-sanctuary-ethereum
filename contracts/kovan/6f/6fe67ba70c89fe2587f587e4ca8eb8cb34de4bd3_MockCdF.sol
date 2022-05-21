// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


// contract tryIt{
//     constructor() payable {
//         require(msg.value > 0, "initial funding rqred");
//     } 

//     function fundIt() public payable {
//     }

//     function refundViaTransfer() public {
//         address payable senderp = payable(msg.sender);
//         senderp.transfer(address(this).balance);
//     }

//     function refundViaSend() public {
//         address payable senderp = payable(msg.sender);
//         bool sent = senderp.send(address(this).balance);
//         require(sent, "Failed to send Ether");
//     }

//     function sendViaCall() public {
//         // Call returns a boolean value indicating success or failure.
//         // This is the current recommended method to use.
//         address payable senderp = payable(msg.sender);
//         // (bool sent, bytes memory data) = senderp.call{value: msg.value}("");
//         (bool sent, bytes memory data) = senderp.call{value: address(this).balance}("");
//         require(sent, "Failed to CALL Ether");
//     }

// }

contract MockCdF {
    address payable buyer;
    address payable seller;
    AggregatorV3Interface private priceFeed; // price oracle
    int private initialPrice;
    bool private activeContract;
    uint private initialFundingRequirement;

    /**
     * Aggregator: Kovan, Chainlink, ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */
    constructor() {
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        activeContract = false;
        initialFundingRequirement = 1e14;
        buyer = payable(address(0));
        seller = payable(address(0));
    }

    // modifier to check if there is already a buyer
    modifier buyerDNE() {
        require(buyer == address(0), "There is already a Buyer for this contract instance");
        _;
    }

    // modifier to check if there is already a buyer
    modifier sellerDNE() {
        require(seller == address(0), "There is already a Seller for this contract instance");
        _;
    }

    /**
     * @dev Return Buyer address 
     * @return address of Buyer
     */
    function getBuyer() external view returns (address) {
        return buyer;
    }

    /**
     * @dev Return Seller address 
     * @return address of Seller
     */
    function getSeller() external view returns (address) {
        return seller;
    }
 
     /**
     * @dev Return initialPrice
     * @return initialPrice
     */
    function getInitialPrice() external view returns (int) {
        return initialPrice;
    }

    /**
     * @dev Return activeContract
     * @return activeContract
     */
    function getContractState() external view returns (bool) {
        return activeContract;
    }

    // liquidate contract
    function liquidateContract() external {
        require(activeContract, "Contract is inactive.");
        int currentPrice = getLatestPrice();
        int currentMinusInitial = currentPrice - initialPrice;
        require(currentMinusInitial != 0, "Price is same as when contract was signed.");
        if (currentMinusInitial < 0) { // price went down; good for the seller
            (bool sent, bytes memory data) = seller.call{value: address(this).balance}("");
            require(sent, "Failed to send Ether to seller.");
        } else { // price went up; good for the buyer
            (bool sent, bytes memory data) = buyer.call{value: address(this).balance}("");
            require(sent, "Failed to send Ether to buyer.");
        }
        buyer = payable(address(0));
        seller = payable(address(0));
        activeContract = false;
    }

     // withdraw from contract
    function withdrawFromContract() external {
        require(!activeContract, "Contract is already active. You cannot withdraw.");
        if (msg.sender == buyer){
            (bool sent, bytes memory data) = buyer.call{value: address(this).balance}("");
            require(sent, "Failed to send Ether to buyer.");
            buyer = payable(address(0));
        }
        if (msg.sender == seller){
            (bool sent, bytes memory data) = seller.call{value: address(this).balance}("");
            require(sent, "Failed to send Ether to seller.");
            seller = payable(address(0));
        }
    }    

    /**
     * Returns the latest price  
     */
    function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    function activateContract() private {
        require(!activeContract, "Contract is already active.");
        activeContract = true;
        initialPrice = getLatestPrice();
    }

    // enter contract / set buyer/seller, if counterparty exists, this is equivalent to starting the contract
    function enterContractAsBuyer() payable external {
        require(!activeContract, "Contract is already active. You cannot enter.");
        require(buyer == address(0), "There is already a buyer for this CfD contract." );
        require(msg.value == initialFundingRequirement, "You need to provide a funding buffer / margin.");
        buyer = payable(msg.sender);
        if (seller != address(0)){
            activateContract();
        }
    }    

    // enter contract / set buyer/seller, if counterparty exists, this is equivalent to starting the contract
    function enterContractAsSeller() payable external {
        require(!activeContract, "Contract is already active. You cannot enter.");
        require(seller == address(0), "There is already a seller for this CfD contract." );
        require(msg.value == initialFundingRequirement, "You need to provide a funding buffer / margin.");
        seller = payable(msg.sender);
        if (buyer != address(0)){
            activateContract();
        }
    }    

// event LogDepositMade(address indexed accountAddress, uint amount);
// emit LogDepositMade(msg.sender, msg.value);
   
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