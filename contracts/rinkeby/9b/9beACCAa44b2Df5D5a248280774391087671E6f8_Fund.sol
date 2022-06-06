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

contract Fund{

    mapping(address => uint256) public Transaction;

    address[] public Funders;

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function fund_me() public payable {
        uint256 minWei = 50;
        require(msg.value >= minWei , "You need more ETH!!!");
        Transaction[msg.sender] += msg.value;
        Funders.push(msg.sender);
    }
    function memoryAddress() public view returns(address , uint256){
        return (address(this) , address(this).balance);
    }
    function GetVersion() public view returns(uint256){
        AggregatorV3Interface PriceFee = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        return PriceFee.version();
    }
    function GetPrice() public view returns(uint256){
        AggregatorV3Interface PriceFee = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        (uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound)
        = PriceFee.latestRoundData();
        return uint256(answer/100000000) ;
    }
    function ETHinDoller(uint256 value) public view returns(uint256){
        uint256 ETH_USD = GetPrice() * value ;
        return ETH_USD;
    }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
      // yani aval sharte require ro check kon , baad baghi line ha ro anjam bede , bara hamin _; ro baadesh mizarim
    }

    function Withdraw() public onlyOwner payable {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 FunderIndex=0 ; FunderIndex < Funders.length ; FunderIndex++){
            address funder = Funders[FunderIndex];
            Transaction[funder] = 0;
        }
        Funders = new address[](0); //funders ro reset kardim
    }
    uint functionCallTime;
    function FunTime() public returns(uint){
        functionCallTime=block.timestamp;
        return functionCallTime;
    }
}