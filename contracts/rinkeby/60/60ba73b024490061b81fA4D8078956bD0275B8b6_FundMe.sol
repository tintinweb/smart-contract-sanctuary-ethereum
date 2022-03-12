// fund, withdraw, getUSDValue, minUSDVal, getVersionAggregator
// SDPX-License-Identifier: MIT

pragma solidity >0.6;

contract FundMe {
    address owner;
    address[] fundAddressList;

    constructor() {
        owner = msg.sender;
    }

    mapping(address => uint256) public fundAddressToAmount;

    function fund() public payable {
        bool addAddress = true;
        for (uint256 i = 0; i < fundAddressList.length; i++) {
            if (fundAddressList[i] == msg.sender) addAddress = false;
        }
        if (addAddress) fundAddressList.push(msg.sender);
        fundAddressToAmount[msg.sender] += msg.value;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You don't have the permissions to execute this call."
        );
        _;
    }

    function totalFunds() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < fundAddressList.length; i++) {
            total += fundAddressToAmount[fundAddressList[i]];
        }
        return total;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 i = 0; i < fundAddressList.length; i++) {
            fundAddressToAmount[fundAddressList[i]] = 0;
        }
        fundAddressList = new address[](0);
    }
}