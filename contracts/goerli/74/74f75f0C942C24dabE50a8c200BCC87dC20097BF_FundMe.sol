// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract FundMe {
    /* state variable */
    uint256 private constant MINIMUM_AMOUNT = 10000000000000000;
    address private immutable i_owner;

    mapping(address => uint256) private addressToAmount;
    address[] private funders;

    constructor() {
        i_owner = msg.sender;
    }

    //receive eth from funders
    function fund() external payable {
        require(msg.value > MINIMUM_AMOUNT, "You need to send more ETH");
        addressToAmount[msg.sender] = msg.value;
        funders.push(msg.sender);
    }

    receive() external payable {}

    fallback() external payable {}

    // reset the funder data
    // send every ETH to the owner
    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmount[funder] = 0;
        }

        funders = new address[](0);

        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    // get state variables
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMinimumFundAmount() public pure returns (uint256) {
        return MINIMUM_AMOUNT;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner);
        _;
    }
}