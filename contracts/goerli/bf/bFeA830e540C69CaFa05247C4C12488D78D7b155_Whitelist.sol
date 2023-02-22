//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Whitelist {
    address private owner;
    uint16 public numAddressesWhitelisted;
    mapping(address => bool) public whiteListPeople;

    event allPeople(address newPerson);

    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }

    constructor(uint16 _whitelistAllowed) {
        numAddressesWhitelisted = _whitelistAllowed;
        owner = msg.sender;
    }

    function addWhiteListPublic() public {
        require(
            whiteListPeople[msg.sender] != true,
            "you are in the whitelist"
        );
        whiteListPeople[msg.sender] = true;
        emit allPeople(msg.sender);
    }

    function addWhiteListPrivate(address _addPerson) public onlyOwner {
        require(whiteListPeople[_addPerson] != true, " in the whitelist");
        whiteListPeople[_addPerson] = true;
        emit allPeople(_addPerson);
    }

    function viewPeople() public view returns (bool) {
        return whiteListPeople[msg.sender];
    }

    function whitelistedAddresses(
        address _address
    ) external view returns (bool) {
        return whiteListPeople[_address];
    }
}