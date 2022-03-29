// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

contract FundMe {
    mapping(address => uint256) public amountFundedByAddress;

    /*
    msg is a solidity keyword
    msg.sender is the address who called the contract
    msg.amount is the amount
    */
    function fund()public payable {
        amountFundedByAddress[msg.sender] += msg.value;
    }

    /*
    require is a solidity keyword

    require(condition boolean, errMessage string)

    check is condition is true
    If false, it'll revert (i.e. return user their eth
    */
    function fundWithMinimum() public payable {  
        uint256 MIN_WEI = 20;
        require(msg.value > MIN_WEI, "Insufficient wei");
    }

    /*
    address(this) gets the current contract

    This function transfers current contract's balance to msg.sender
    */
    function withdraw() payable public {
        uint256 currentBalanceOfContract = address(this).balance;
        payable(msg.sender).transfer(currentBalanceOfContract);
    }

    function getCurrentContractBalance() public view returns (uint256){
        return address(this).balance;
    }
}