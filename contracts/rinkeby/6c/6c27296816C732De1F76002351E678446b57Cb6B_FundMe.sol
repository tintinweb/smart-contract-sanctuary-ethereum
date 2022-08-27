// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error FundMe__NotEnoughETHSent();
error FundMe__YouAreNotThei_Owner();
error FundMe__TransferFailed();

contract FundMe {
    /**
     * Contract that allows people to fund a contract an an i_Owner to withdraw the funds
     */
    // Variables & Modifiers

    uint256 private Fee;
    address private immutable i_Owner;

    event addressFunded(address funder, uint256 amount);

    //Constructor
    constructor(uint256 newFee) {
        i_Owner = msg.sender;
        Fee = newFee;
        //DECLARE THE FEE!!
    }

    // Store the s_funders Somehow
    address[] private s_funders;
    mapping(address => uint256) private addressToAmountFunded;

    modifier minFee() {
        if (msg.value < Fee) {
            revert FundMe__NotEnoughETHSent();
        }
        _;
    }

    modifier Only_Owner() {
        if (msg.sender != i_Owner) {
            revert FundMe__YouAreNotThei_Owner();
        }
        _;
    }

    // Functions
    function fund() public payable minFee {
        addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);

        emit addressFunded(msg.sender, msg.value);
    }

    function withdraw() public Only_Owner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            addressToAmountFunded[s_funders[funderIndex]] = 0;
        }

        s_funders = new address[](0);
        (bool success, ) = i_Owner.call{value: address(this).balance}("");
        if (!success) {
            revert FundMe__TransferFailed();
        }
    }

    // Getters

    function getFee() public view returns (uint256) {
        return Fee;
    }

    function addressToFunding(address desiredAddress)
        public
        view
        returns (uint256)
    {
        return addressToAmountFunded[desiredAddress];
    }

    function getFunderFromArray(uint256 index) public view returns (address) {
        return s_funders[index];
    }
}