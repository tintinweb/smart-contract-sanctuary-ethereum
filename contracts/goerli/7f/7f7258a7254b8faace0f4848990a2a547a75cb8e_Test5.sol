// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.4;

struct Attributes {
    bool Exists;
    uint256 BlockNumber;
    string Message;
}

contract Test5
{
    mapping(address => Attributes) public addressMapping;

    function AddAddress(string memory message_) external
    {
        addressMapping[msg.sender] = Attributes(true, block.number, message_);
    }


    function GetAttributes(address addr_) external view returns(Attributes memory)
    {
        return addressMapping[addr_];
    }

}