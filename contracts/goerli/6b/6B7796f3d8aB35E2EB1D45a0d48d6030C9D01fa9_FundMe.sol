// SPDX-License-Identifier: MIT

// Contract which does these things:
// 1) Users send ether into this contract to store their ether
// 2) Owner can withdraw the amount
// 3) Users can take their ether back from this contract

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FundMe {

    address public immutable Owner;
    address[] public Users;
    mapping (address => uint) public AddressToValue;
    int256 public minimumWei;
    AggregatorV3Interface contractInstance;

    // Constructor which acts when the contract is being deployed and stores the address of the Owner in a variable
    constructor(address contractAddress) {
        Owner = payable(msg.sender);
        contractInstance = AggregatorV3Interface(contractAddress);
    }

    // 1) Users send ether into this contract
    function sendEth () public payable returns (string memory) {

        // We are setting the minimum amount that a user need to send to this contract
        require(msg.value >= uint(minimumWei), "Eth amount too low!");
        
        // Storing the users addresses in an array
        Users.push(msg.sender);

        return "Eth sent successfully!";
    } 

    // 2) Owner can withdraw the amount
    function OwnerWithdraw () public payable {

        // Only the Owner can withdraw the amount
        require(msg.sender == Owner, "You cannot withdraw all the funds only Owner can withdraw all the funds");

        // To send Eth from contract to the Owner use call method
        // convert address of the Owner to payable
        (bool success, bytes memory data) = Owner.call{value: address(this).balance}("");

        // We then update the balances of all the users in the contract
        for (uint i = 0; i < Users.length; i++) {
            AddressToValue[Users[i]] = 0;
        }

    }

    // 3) Users can take their money back from this contract
    function userWithdraw () public {

        // Convert the user address to payable address
        address UserAddress = msg.sender;
        (bool success, bytes memory data) = UserAddress.call{value: AddressToValue[UserAddress]}("");

    }

    // function which gets data about value of ETH for 10$
    function getValueOfEth() public payable {
        (
            ,
            int256 _answer,
            ,
            ,
            
        ) = contractInstance.latestRoundData();
        minimumWei = _answer / (10 ** 8);
        minimumWei = (10**18) * 10/minimumWei;
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