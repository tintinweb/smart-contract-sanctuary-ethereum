// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Escrow {
    uint256 public money;
    address public isEscrowedAddress;
    address public personAddress;
    address public emptyAddress;
    bool public isAssetTransfered;

    function payment(address _personAddress) public payable {
        isEscrowedAddress = msg.sender;
        money = msg.value;
        personAddress = _personAddress;
    }

    function delivered() public {
        require(isEscrowedAddress == msg.sender, "Wrong Person");
        require(money != 0, "Dont have money");
        isAssetTransfered = true;
        (bool callSuccess, ) = payable(personAddress).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
    }

    function canceled() public {
        (bool callSuccess, ) = payable(isEscrowedAddress).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
        personAddress = emptyAddress;
        money = 0;
        isEscrowedAddress = emptyAddress;
    }
}