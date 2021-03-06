pragma solidity ^0.4.13;

contract PriceFeeder{
    address public owner;
    bytes32 name;

    struct FeederState {
        uint32 previousDate;
        uint64 previousPrice;
        uint32 date;
        uint64 price;
    }

    event newPrice(uint32 indexed date, bytes32 indexed underlying, uint64 price);

    mapping(bytes32 => FeederState) public priceData;

    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }

    constructor(bytes15 _name) public{
        owner = msg.sender;
        name = _name;
    }

    function updatePrice(bytes32 underlying, uint32 date, uint64 price, uint32 previousDate) onlyOwner public{
        FeederState storage state = priceData[underlying];
        state.previousDate = state.date;
        state.previousPrice = state.price;
        if (state.date != 0){
          // just a check that the update does not skip quotes
          require(previousDate == state.previousDate);
        }
        state.date = date;
        state.price = price;
        priceData[underlying] = state;
        emit newPrice(date, underlying, price);
    }


    function getState(bytes32 underlying) public constant returns (uint32 date, uint64 price, uint32 previousDate, uint64 previousPrice){
      FeederState storage record = priceData[underlying];
      return (record.date, record.price, record.previousDate, record.previousPrice);
    }

    function getDate(bytes32 underlying) public constant returns (uint32){
      FeederState storage record = priceData[underlying];
      return record.date;
    }

    function getPrice(bytes32 underlying) public constant returns (uint64){
      FeederState storage record = priceData[underlying];
      return record.price;
    }

    function getPreviousDate(bytes32 underlying) public constant returns (uint32){
      FeederState storage record = priceData[underlying];
      return record.previousDate;
    }

    function getPreviousPrice(bytes32 underlying) public constant returns (uint64){
      FeederState storage record = priceData[underlying];
      return record.previousPrice;
    }
}