// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;
/*
Market Data Oracle

It is a kind of oracle to bring market data to the Ethereum blockchain.

The prices renewed once a day. A list of current instruments available at a website or
through the contract dictionary with the last time and block the price was renewed.
New requests for price updates are checked every second.

If you need the prlllllllllllllllllllice to be renewed more often, you can do the following:*
- send transaction to the contract just before you need it to be updated using
function requestPriceUpdate (see the contract code or use it on our website)
- top up the balance of smart contract to pay before for the transactions to renew the price with the frequency
you need, or on a significant price change using payForSubscription function (find more info on the website)
- if you top up your previous subscription, you get an additional 5% discount each time till you pay only half of contract's comission.

Note: topping up the contract balance by just sending ether directly will be considered as a donation.
By the way, donations are always appreciated and mentioned on the website.
Beneficiary address is public and can be viewed in the contract.
If 'finalized' flag is up, there is no possibility to change it even for the author.
All profits are shared amoung tokenHolders of this service.
If you want to earn profits of this service, check beneficiary address contract or our website.

Examples:

exchangeRate er = exchangeRate(contractAdress);

uint eth = er.getPrice('eth');        // returns price of Ether in USD cents.
uint btc = er.getPrice('btc')         // returns price of Bitcoin in USD cents.
uint brent = er.getPrice('brent')     // returns price of Brent in USD cents.

Please, visit https://exchangeRate.io for more information.

@author Nagornykh Dmitry
*My cat helped to type this line (the word "prlllllllllllllllllllice"). It's name is Liquid.
*/

    struct subscription{
        uint256 index;
        uint256 id;
        string email;
        string[] symbols;     // symbols to update
        uint256[] frequencies;  // how often proceed updates
        uint256[] priceDifferences; // update price, if it changed significantly (in percent)
        address payer;
        uint256 remainingBalance;
        uint256 txSpeed;
        uint256 timeStamp; // time of creation
    }

    struct Instrument {
        string name;    // full name of an instrument or pair
        uint256 price;     // price of an instrument in US dollars
        uint256 decimals;  // to use the price in your smart contracts or elsewhere, you need to divide it by 10^decimals
        uint256 timeStamp; // block.timeStamp
        uint256 time;     // time from updater
    }

import "./INTDAO.sol";

contract exchangeRateContract {

    constructor(address _INTDAOaddress) payable{
        INTDAO dao = INTDAO(_INTDAOaddress);
        dao.setAddressOnce("oracle", payable(this));
        author = payable(msg.sender);
        updater = payable(msg.sender);
    }

    subscription[] subscriptions;

    uint256 public subscriptionsCount;
    uint256 public instrumentsCount;

    //================== discounts =====================
    mapping(address => uint) public discounts;

    //================== discounts =====================
    uint256 constant public updOnePriceGasCost = 84928;
    uint256 constant public updSeveralPricesCost = 87742;
    uint256 constant public updAdditionalPrice = 22700;

    uint256 public minSubscrTxNum = 100;

    uint256[3] public gasPrices;

    address payable public author;
    address payable public beneficiary;
    address payable public updater;

    bool public finalized;

    mapping(string => Instrument) public instruments;
    mapping(uint => string) public dictionary;

    modifier onlyAuthor{
        require(msg.sender == author, "This function is for author only");
        _;
    }

    modifier onlyUpdater{
        require(msg.sender == updater, "This function is for updater only");
        _;
    }

    event priceUpdateRequest (uint256 block, string symbol, uint256 gasPrice);
    event updateSeveralPricesRequest (uint256 block, string[] symbols, uint256 gasPrice);
    event priceUpdated (address payer, string symbol, uint256 newPrice, uint256 timeStamp, uint256 time);
    event Donation (address donator, uint256 value, uint256 blockNumber);
    event SubscriptionPayed (address subscirber, uint256 subscriptionID);
    event ProfitEvent (uint256 profit);

    function changeBeneficiaryAddress(address payable newAddress) public onlyAuthor returns (bool){
        if (!finalized){
            beneficiary = newAddress;
            return true;
        }
        return false;
    }

    function finalize() public onlyAuthor returns (bool){
        if (!finalized){
            finalized = true;
            return true;
        }
        return false;
    }

    function setDiscount(address payer, uint value) public onlyAuthor {
        require (value>0 && value<100, "Invalid discount value");
        discounts[payer] = value;
    }

    function changeUpdaterAddress (address payable newAddress) public onlyAuthor{
        updater = newAddress;
    }

    function changeMinSubscrTxNum (uint value) public onlyAuthor{
        minSubscrTxNum = value;
    }

    function topUpSubscription (uint subscriptionId) public payable {
        require (subscriptionId <subscriptionsCount, "There is no subscription with such ID");
        subscription storage s = subscriptions[subscriptionId];
        require (msg.value > 2 * minSubscrTxNum * (updSeveralPricesCost + updAdditionalPrice * s.symbols.length) * tx.gasprice, "Too little transactions ordered");
        if (discounts[s.payer] == 0)
            discounts[s.payer] = 100;
        if (discounts[s.payer] > 50)
            discounts[s.payer] -=5;
        s.remainingBalance += msg.value;
    }

    function payForSubscription(string memory email, uint[] memory frequencies, uint[] memory priceDifferences, string[] memory symbols, uint txSpeed) public payable {
        require(frequencies.length == priceDifferences.length && frequencies.length == symbols.length, "Arrays should have similar length, for more informatiion visit website");
        require(symbols.length>0 && instrumentsCount >= symbols.length, "Invalid array size. For more information visit webSite");
        require (txSpeed>0 && txSpeed<4, "Wrong txSpeed. Use only 1/2/3" );
        require (msg.value > 2 * minSubscrTxNum * (updSeveralPricesCost + updAdditionalPrice * symbols.length) * tx.gasprice, "Too little transactions ordered");
        uint256 id = subscriptionsCount++;

        subscription storage s = subscriptions[id];

        for (uint i = 0; i<priceDifferences.length; i++)
            require (priceDifferences[i]<100, "priceDifferences should be less then 100");

        s.id = id;
        s.email = email;
        s.symbols = symbols;
        s.frequencies = frequencies;
        s.priceDifferences = priceDifferences;
        s.txSpeed = txSpeed;
        s.remainingBalance = msg.value;
        s.payer = msg.sender;
        s.timeStamp = block.timestamp;
        s.index = subscriptions.length;

        emit SubscriptionPayed (msg.sender,s.id);
    }

    function requestPriceUpdate(string memory symbol) public payable {
        uint cost = 2*updOnePriceGasCost*tx.gasprice;
        require (msg.value>=cost, "You need to pass more ether to request new price. For more information visit webSite");
        if (msg.value>cost)
            author.transfer(msg.value - cost);
        emit priceUpdateRequest (block.number, symbol, tx.gasprice);
    }

    function requestMultiplePricesUpdate(string[] memory symbols) public payable {
        require (symbols.length>=1, "Symbols array must contain at least 1 element. For more information visit webSite");
        uint256 cost = 2 * (symbols.length * updAdditionalPrice + updSeveralPricesCost) * tx.gasprice;
        require (msg.value>= cost, "You need to pass more ether to request new price. For more information visit webSite");
        if (msg.value> cost)
            author.transfer(msg.value - cost);
    }

    function removeSubscription (uint index) internal {
        require(index < subscriptions.length,"Index is out of range");
        subscriptions[index] = subscriptions[subscriptions.length-1];
        subscriptions[index].index = index;
        delete subscriptions[subscriptions.length-1];
    }

    function updateSeveralPrices(address payer, uint256[] memory timeStamps, string[] memory symbols, uint256[] memory prices, uint256[3] memory currentGasPrices, uint256 subscriptionID) public onlyUpdater{
        uint256 cost = (updSeveralPricesCost + symbols.length * updAdditionalPrice) * tx.gasprice;
        require (timeStamps.length == symbols.length &&  symbols.length == prices.length, "Symbols, timeStamps and prices arrays have different size. For more information visit webSite");
        require (address(this).balance > 2 * cost,"Contract has insufficient balance. For more information visit webSite");

        subscription memory s;

        if (subscriptionID != 0 && payer == address(0x0)) {
            s = subscriptions[subscriptionID];
            uint profit = transferProfit (s.payer, cost);
            updater.transfer(cost);
            if (s.remainingBalance >= profit+cost)
                s.remainingBalance -= (profit + cost);
            else {
                revert();
            }
        }

        gasPrices = currentGasPrices;

        for (uint i=0; i<symbols.length; i++)
            updPrice (payer, symbols[i], prices[i], timeStamps[i]);
    }

    function transferProfit (address payer, uint cost) internal returns (uint profit){
        uint prof = cost;
        if (discounts[payer]>0)
            prof = cost * discounts[payer] / 100;
        if (prof>0) {
            beneficiary.transfer(prof);
            emit ProfitEvent(prof);
            return prof;
        }
    }

    function updateSinglePrice(address payer, string memory symbol, uint256 tickTimeStamp, uint256 newPrice) public onlyUpdater returns (bool success){
        uint256 cost = updOnePriceGasCost*tx.gasprice;
        require(address(this).balance > 2 * cost ,"Contract has insufficient balance. For more information visit webSite");
        updPrice (payer, symbol, newPrice, tickTimeStamp);
        transferProfit (payer, cost);
        updater.transfer(cost);
        return true;
    }

    function updPrice(address payer, string memory symbol, uint256 newPrice, uint256 tickTimeStamp) internal {
        require (instruments[symbol].timeStamp > 0, "Symbol not found in the dictinary. For more information visit webSite");
        instruments[symbol].time = tickTimeStamp;
        instruments[symbol].timeStamp = block.timestamp;
        instruments[symbol].price = newPrice;
        emit priceUpdated (payer, symbol, newPrice, block.timestamp, tickTimeStamp);
    }

    function addInstrument(string memory symbol, string memory name, uint256 decimals) public onlyUpdater{
        require (instruments[symbol].timeStamp == 0, "Symbol already exist, use updateInstrument");
        dictionary[instrumentsCount] = symbol;
        instruments[symbol].name = name;
        instruments[symbol].timeStamp = block.timestamp;
        instruments[symbol].decimals = decimals;
        instrumentsCount++;
    }

    function updateInstrument(string memory symbol, string memory name, uint decimals) public onlyUpdater{
        instruments[symbol].name = name;
        instruments[symbol].decimals = decimals;
    }

    function getPrice(string memory symbol) public view returns (uint256) {
        return instruments[symbol].price;
    }

    function timeStamp(string memory symbol) public view returns (uint256) {
        return instruments[symbol].timeStamp;
    }

    function getDecimals(string memory symbol) public view returns (uint256 decimals) {
        return instruments[symbol].decimals;
    }

    receive() external payable {
        if (msg.sender != author) {
            beneficiary.transfer(msg.value);
            emit Donation (msg.sender, msg.value, block.number);
        }
    }
}