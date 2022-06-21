// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

contract PayableFirst {
    //Rinkeby : 0xECe365B379E1dD183B20fc5f022230C044d51404
    //Kovan : 0x9326BFA02ADD2366b30bacB125260Af641031331
    AggregatorV3Interface usdInterface =
        AggregatorV3Interface(0xECe365B379E1dD183B20fc5f022230C044d51404);
    uint8 public decimals;

    mapping(address => uint256) public addressToId;
    uint256[] public contributions; // in gwei
    address public owner;

    uint256 public minAmountToContribute = 5;

    uint256 public lastMsgValue;

    constructor() {
        owner = msg.sender;
        decimals = usdInterface.decimals();
    }

    function compareStrings(string memory a, string memory b)
        private
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function fromDollarToWei(uint256 toConvert) public view returns (uint256) {
        return ((toConvert * 10**27) / getPrice());
    }

    function fromEthToDollar(uint256 toConvert) public view returns (uint256) {
        return (toConvert * getPrice()) / 10**9;
    }

    function getPrice() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = usdInterface.latestRoundData();
        return uint256(price);
    }

    function contribute() public payable {
        lastMsgValue = msg.value;
        require(
            lastMsgValue > fromDollarToWei(minAmountToContribute),
            "You need to send more, you damn poor!"
        );
        if (addressToId[msg.sender] != 0) {
            contributions[addressToId[msg.sender]] += msg.value;
        } else {
            contributions.push(msg.value);
            addressToId[msg.sender] = contributions.length - 1;
        }
    }

    function myContribution() public view returns (uint256) {
        return contributions[addressToId[msg.sender]];
    }

    function minAmountInWei() public view returns (uint256) {
        return fromDollarToWei(minAmountToContribute);
    }

    function setMinAmountToContribute(uint256 newAmount) public {
        require(msg.sender == owner, "Nice try, hacker !");
        minAmountToContribute = newAmount;
    }

    function transferFunds(address payable receiver) public payable {
        require(receiver != address(0), "Can't send all the funds to no one !");
        require(msg.sender == owner, "Nice try, hacker!");
        uint256 funds;
        for (uint256 i; i < contributions.length; i++) {
            funds += contributions[i];
        }
        require(funds != 0, "You can't transfer 0 ...");
        //This throws an exception if it fails, so it won't delete the contributions
        // and it even warns the sender if it will fail;
        receiver.transfer(funds);
        delete (contributions);
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