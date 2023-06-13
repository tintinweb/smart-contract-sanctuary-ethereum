/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


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







library PriceGetterOracle {
        //get price of eth in usd and convert it into 18 decimals.
        function getPrice(AggregatorV3Interface oracle) internal view returns(uint256) {
                (,int256 price, , , ) = oracle.latestRoundData();
                return uint256(price * 10 ** (18 - 8));
        }

}

contract FundMe {

        using PriceGetterOracle for AggregatorV3Interface;

        address payable immutable private s_owner;
        mapping(address => uint256) private userBal;
        address[] private userList;
        uint256 constant MIN_USD_DEPOSIT = 50 ether;  //with decimals 18.
        AggregatorV3Interface public s_oracle;

        constructor(address oracle) {
                s_owner = payable(msg.sender);
                s_oracle = AggregatorV3Interface(oracle);
        }

        function fundContract() payable public returns(uint256) {
                require(msg.value > 0, "msg.value cannot be zero");
                uint256 amountInDollars = s_oracle.getPrice() * msg.value;
                require(amountInDollars >= MIN_USD_DEPOSIT, "Not enough deposit amount");
                if(userBal[msg.sender] == 0) {
                        userList.push(msg.sender);
                }
                userBal[msg.sender] += amountInDollars;
                return amountInDollars;
        }

        function withdraw() external returns(uint256) {
                require(msg.sender == s_owner, "Only owner can withdraw");
                require(address(this).balance > 0, "No funds to withdraw");
                //clear balances
                uint256 len = userList.length;
                for(uint256 i; i < len; ) {
                        userBal[userList[i]] = 0;
                        unchecked{
                                ++len;
                        }
                }
                userList = new address[](0);
                uint256 availableFunds = address(this).balance;
                (bool success, ) = msg.sender.call{value: availableFunds}("");
                require(success, "Unable to withdraw");
                return availableFunds;
        }
         
        receive() payable external {
                fundContract();
        }

        fallback() payable external {
                fundContract();
        }

        //View functions.
        function getOwner() external view returns(address) {
                return s_owner;
        }

        function getuserBalance(address user) external view returns(uint256) {
                return userBal[user];
        }

        function getUserList() external view returns(address[] memory) {
                return userList;
        }

}