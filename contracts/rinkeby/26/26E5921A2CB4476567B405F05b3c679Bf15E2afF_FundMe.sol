/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

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

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded; //creating a mapping variable that links the senders address to the value of coins or money sent
    address[] public funders;
    address public owner;

    constructor() public {
        owner = msg.sender; // the constructor function makes it possible to declare the owner of the contract as he who deloys the contract immediately the contract is deployed
    }

    function fund() public payable {
        uint256 minUSD = 40 * 10**18;
        require(
            getConversionRate(msg.value) >= minUSD,
            "the minimum value you can deposit is 40 dollars"
        ); // the require keyword is like an if statement that is used to check conditionsand if those conditions aren't met the transaction doesn't go through and it reverts and sends back an error message
        addressToAmountFunded[msg.sender] += msg.value; // the msg,value gets the value of eth or cash in general the user is trying to pay, while the msg.sender gets the address to the user sending the cash
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        return priceFeed.version(); // the version is a function of the AggregatorV3Interface contract
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData(); // the latestRoundData is a function of the Aggregator contract
        return uint256(answer * 10000000000); // here we are trying to convert the answer parameter which returns the current etherum price to uint256 because thats what we set the funtion getPrice to return
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethprice = getPrice(); //using the getprice function to get the current eth price
        uint256 ethAmountinUsd = (ethprice * ethAmount); // coverting the price to usd
        return ethAmountinUsd;
    }

    modifier onlyowner() {
        //modifier is used to make restrictions set by the owner of the contract more flexible
        require(msg.sender == owner); // the require function ensures that its only the owner that has the ability to withdraw funds from the contract
        _; // this marks where the code execution begins i.e after checking the require function, notee if the underscore is above the require function it runs the code first before checking the requirement
    }

    function withdraw() public payable onlyowner {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 funderindex = 0;
            funderindex < funders.length;
            funderindex++
        ) {
            address funder = funders[funderindex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}