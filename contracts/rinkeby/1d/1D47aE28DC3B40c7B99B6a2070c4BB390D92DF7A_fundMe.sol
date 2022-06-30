//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "AggregatorV3Interface.sol";

contract fundMe {
    AggregatorV3Interface internal priceFeed;
    mapping(address => uint256) public naslovVVrednost;
    address[] public financerji;
    address public lastnik;

    constructor() {
        priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        lastnik = msg.sender;
    }

    modifier samoLastnik() {
        require(msg.sender == lastnik, "niste lastnik");
        _;
    }

    function fund() public payable {
        uint256 minUSD = 50 * 10**18;
        require(vrednostKonverzije(msg.value) >= minUSD, "premalo ETHja!");

        naslovVVrednost[msg.sender] += msg.value;
        financerji.push(msg.sender);
    }

    function defund() public payable samoLastnik {
        require(msg.sender == lastnik, "niste lastnik pogodbe!");
        payable(msg.sender).transfer(address(this).balance);

        for (uint256 i = 0; i < financerji.length; i++) {
            address financer = financerji[i];
            naslovVVrednost[financer] = 0;
        }
        financerji = new address[](0);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function vrniCeno() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        //gwei
        return uint256(answer * 10000000000);
    }

    //vnesi eth vrednost
    function vrednostKonverzije(uint256 kolicinaEth)
        public
        view
        returns (uint256)
    {
        uint256 ethCena = vrniCeno();
        uint256 ethVUSD = (ethCena * kolicinaEth) / 1000000000000000000;
        return ethVUSD;
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