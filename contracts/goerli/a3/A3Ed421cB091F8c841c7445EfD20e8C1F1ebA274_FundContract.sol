//SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

error FundMe__NotOwner();

contract FundContract {
  uint256 private constant MIN_WEI = 1e16;

  address private immutable i_owner;

  address[] private s_funders;
  mapping(address => uint256) private s_address2Amt;
  uint256 private totalAmount;

  constructor() {
    i_owner = msg.sender;
    totalAmount = 0;
  }

  modifier isOwner() {
    if (msg.sender != i_owner) revert FundMe__NotOwner();
    _;
  }

  receive() external payable {
    fund();
  }

  fallback() external payable {
    fund();
  }

  function fund() public payable {
    require(msg.value >= MIN_WEI, "Not Enough ETH");
    if (s_address2Amt[msg.sender] == 0) {
      s_funders.push(msg.sender);
    }
    s_address2Amt[msg.sender] += msg.value;
    totalAmount += msg.value;
  }

  function withdraw() public isOwner {
    (bool isSuccess, ) = payable(msg.sender).call{value: address(this).balance}(
      ""
    );
    require(isSuccess, "Call failed");
  }

  function getOwner() public view returns (address) {
    return i_owner;
  }

  function getAddress2Amt(address funder) public view returns (uint256) {
    return s_address2Amt[funder];
  }

  function getFunder(uint256 index) public view returns (address) {
    return s_funders[index];
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function getTotalAmount() public view returns (uint256) {
    return totalAmount;
  }
}