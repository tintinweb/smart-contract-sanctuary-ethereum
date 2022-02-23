//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ETHBankContract {
    struct userInfo {
        address userAddress;
        string firstName;
        string lastName;
        //to test if the account actually exists
        bool exists;
        uint256 balance;
    }
    mapping(address => userInfo) addressToUserInfo;
    address mSender;

    // constructor() {
    //     address mSender = msg.sender;
    // }

    //Make a part of the contracts that states that users can't enter twice

    function addUser(string memory _firstName, string memory _lastName) public {
        addressToUserInfo[msg.sender] = userInfo(
            msg.sender,
            _firstName,
            _lastName,
            true,
            0
        );
    }

    function deposit(address _address) public payable {
        // require(addressToUserInfo[_address].exists == true, "Account doesn't exist");
        addressToUserInfo[msg.sender].balance += msg.value;
    }

    function returnUserData(address _address)
        public
        view
        returns (
            address,
            string memory,
            string memory,
            bool,
            uint256
        )
    {
        return (
            addressToUserInfo[_address].userAddress,
            addressToUserInfo[_address].firstName,
            addressToUserInfo[_address].lastName,
            addressToUserInfo[_address].exists,
            addressToUserInfo[_address].balance
        );
    }

    function returnAddress(address _address) public view returns (address) {
        return addressToUserInfo[_address].userAddress;
    }

    function withdraw(uint256 _amount) external payable {
        // address payable Withdraw;
        require(
            addressToUserInfo[msg.sender].balance >= _amount,
            "Not enough ETH in bank to withdraw this amount of ETH"
        );
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Failed to withdraw ETH");
        // uint256 amount = address(this).balance;
        // Withdraw.transfer(amount);
    }
}