// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";
// interfaces compile down to ABI - Application Binary Interfaces, which tells solidity how it can
// interact with another contract
// Anytime you need to interact with a smart contract you will need adn ABI

// interfaces minimalisttic view into another contract


contract receiveRinkeby {

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;

    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    //accept payment
    // when we send or fund , now the contract is the owner of the funds
    // will fund a smartcontract whereever is deployed

    function fund() public payable {
        // $50
        uint256 minimumUSD = 50 * 10 ** 18;
        require(getConversionRate(msg.value) >= minimumUSD, "You need more eth");

        // 1 wei is the smallert denomination of ether
        // red button payable function

        //msg.sender and msg.value are key words in a contract
        addressToAmountFunded[msg.sender] += msg.value;

        funders.push(msg.sender);

        // ETH to USD conversion

    }

    function getVersion() public view returns (uint256) {
        // using constructor now... AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
       // using constructor  AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);

        (uint80 roundId,
         int256 answer,
         uint256 startedAt,
         uint256 updateAt,
         uint80 answeredInRound) = priceFeed.latestRoundData();
         return uint256(answer * 10000000000) ; // multiply to change from wei to gwei
        // 197749555185 is 1,977.49555185
    }

    // 1000000000 one wei
    function getConversionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
        // 1985980000000
    }

//     function withdraw() payable public {
//         require(msg.sender == owner);
//         payable(msg.sender).transfer(address(this).balance);
//    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price + 1;
    }

    // modifier us used to change behavior of a function in a declarative way
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function withdraw() payable onlyOwner public {

        payable(msg.sender).transfer(address(this).balance);

        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
   }
// acct 1   0xf6C0DBd210394ddFfDDBC4eac66E58c63a05A2bC
// acct 2   0xb96A132DB696eFBE7dd678239c14617486776Ce8

    //////////////////////////////////////
//    string name_of_person;
//    uint total_balance;

    struct Invoices {
        uint id;
        string name_of_person;
        uint total_balance;
    }
// string payed_date; uint payed_amount;
    mapping(uint => Invoices) public invoiceMap;
    //Invoices [] public sander_invoices;

    uint public cnt;

    function addInvoice(uint _id, string memory _name_of_person, uint _total_balance) public {
        invoiceMap[cnt] = Invoices(_id,_name_of_person, _total_balance);
        cnt++;
    }

    //return Single structure
    function get(uint _candidateId) public view returns(Invoices memory) {
        return invoiceMap[_candidateId];
    }

    function updateBal(uint _candidateId) public returns(Invoices memory) {
        Invoices storage invoice = invoiceMap[_candidateId];
        invoice.total_balance = 1222;
        return invoiceMap[_candidateId];
    }

    //return Array of structure
    function getInvoices() public view returns (Invoices[] memory){
        Invoices[] memory id = new Invoices[](cnt);
        for (uint i = 0; i < cnt; i++) {
            Invoices storage invoices = invoiceMap[i];
            id[i] = invoices;
        }
        return id;
    }

    //return Array of structure Value
    function getAllInvoices() public view returns (uint[] memory, string[] memory, uint[] memory){
        uint[]    memory id = new uint[](cnt);
        string[]  memory name = new string[](cnt);
        uint[]    memory amount = new uint[](cnt);
        for (uint i = 0; i < cnt; i++) {
            Invoices storage invoice = invoiceMap[i];
            id[i] = invoice.id;
            name[i] = invoice.name_of_person;
            amount[i] = invoice.total_balance;
        }
        return (id, name,amount);
    }
//    function storeName(string memory _name_of_person) public returns (string memory) {
//        name_of_person = _name_of_person;
//        return name_of_person;
//    }
//
//    function storeBal(uint _total_balance) public returns (uint) {
//        total_balance = _total_balance;
//        return total_balance;
//    }
//
//    function retrieveName() public view returns (string memory){
//         return name_of_person;
//    }
//
//    function retrieveBalance() public view returns (uint){
//        return total_balance;
//    }

//    function addInvoice(string memory _name_of_person, uint256 _total_balance) public view returns (array){
//        sander_invoices.push(Invoices(_name_of_person, _total_balance));
//   //     return sander_invoices;
//        //name_to_balance[_name_of_person] = _total_balance;
//    }

//    //return Array of structure Value
//    function getInvoices() public view returns (uint[] memory, string[] memory){
//      string[]  memory name = new string[](sander_invoicesConut);
//      uint[]    memory amount = new uint[](sander_invoicesConut);
//      for (uint i = 0; i < candidateConut; i++) {
//          People storage people = peoples[i];
//          id[i] = people.id;
//          name[i] = people.name;
//          amount[i] = people.amount;
//      }
//
//      return (id, name,amount);
//
//  }



//    function addInvoice() public {
//        sander_invoices.push(Invoices(1300, "Jemy den", 16000, "02/02/2022"));
//    }
//
//    function showInvoices() public {
//        return Invoices();
//    }
//    function addInvoice(address _address, uint _payed_amount, string memory _name_of_person, uint _total_balance, string memory _payed_date)
//        public {
//        //creating the object of the structure in solidity
//        Invoices storage sander_invoice=invoicesMap[_address];
//
//        sander_invoices.payed_amount=_payed_amount;
//        sander_invoices.name_of_person=_name_of_person;
//        sander_invoices.total_balance=_total_balance;
//        sander_invoices.payed_date=_payed_date;
//
//        sander_invoices.push(payable(_address)) -1;
//
//    }

//    function getInvoices(address _address) public view returns(uint,string memory,uint, string memory ) {
//            return(invoicesMap[_address].payed_amount,
//            invoicesMap[_address].name_of_person,
//            invoicesMap[_address].total_balance,
//            invoicesMap[_address].payed_date);
//    }

    //function showInvoice() public view returns (uint, bytes32, uint, bytes32) {
    //function showInvoice() public view returns (address [] memory) {

    //    return (3, "gr", 56, "33");
    //    return sander_invoices;
    //}


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