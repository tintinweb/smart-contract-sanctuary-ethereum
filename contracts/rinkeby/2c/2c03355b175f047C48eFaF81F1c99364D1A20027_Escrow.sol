/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
contract Escrow {
    constructor (uint8 _FEE) {
        owner=msg.sender;
        FEE=_FEE;
        }
    address owner;
    uint8 public FEE;
    uint public withdrawFunds;
    uint private valueseller;
    uint amountOwner;
    struct  Deal  {
        address seller;
        uint valueSeller;
        address buyer;
        uint valueBuyer;
        string messageSeller;
        string messageBuyer;
        }

    mapping (uint=>Deal) public deals;

    uint public dealNumber;

    error ValueNotEven();

    modifier condition (bool condition_) {
        require(condition_);
        _;
        }

    function placement (string memory _message) external payable returns (uint) {
        require (msg.value>=1000000000000000, "Wrong value, minimum 0.001ETH");
        valueseller = msg.value / 2;
        if ((2 * valueseller) != msg.value)
            revert ValueNotEven();
        dealNumber++;
        deals[dealNumber].valueSeller = msg.value;
        deals[dealNumber].seller = msg.sender;
        deals[dealNumber].messageSeller = _message;
        return dealNumber;
        }

    function abort (uint _dealNumber) external  {
        require (deals[_dealNumber].valueSeller*2 >  deals[_dealNumber].valueBuyer, "Locked from buyer!");
        require (deals[_dealNumber].seller==msg.sender, "No have right to abort!");
        uint amount = deals[_dealNumber].valueSeller;
        deals[_dealNumber].valueSeller -= amount;
        payable(msg.sender).transfer(amount);
        }

    function confirmPurchase (uint _dealNumber, string memory _message) external condition(msg.value == (2 * deals[_dealNumber].valueSeller)) payable {
        require (deals[_dealNumber].valueBuyer==0, "don't do it twice!");
        require (msg.value!=0, "Wrong value!");
        deals[_dealNumber].valueBuyer = msg.value;
        deals[_dealNumber].buyer = msg.sender;
        deals[_dealNumber].messageBuyer = _message;
        }

    function confirmReceived (uint _dealNumber) external  {
        require(msg.sender == deals[_dealNumber].buyer, "You are not a buyer!");
        uint amountB = deals[_dealNumber].valueBuyer;
        uint amountS = deals[_dealNumber].valueSeller;
        if (amountS>=10000000000000000000) { // >10ETH Fee - 0.5%
            amountOwner = amountS*FEE/2000;
        }
        if (amountS<10000000000000000000) { // <10ETH Fee - 1%
            amountOwner = amountS*FEE/1000;
        }     
        deals[_dealNumber].valueBuyer -= amountB;
        deals[_dealNumber].valueSeller -= amountS;
        payable(deals[_dealNumber].seller).transfer(amountB -(amountOwner/2));
        payable(msg.sender).transfer(amountS-(amountOwner/2));
        withdrawFunds += amountOwner;
        }

    function withdraw () external  {
        require (msg.sender==owner, "You are not an owner!");
        uint _amount = withdrawFunds;
        withdrawFunds -= _amount;
        payable(msg.sender).transfer(_amount);
        }

    function getBalance () public view returns (uint) {
        return address(this).balance;
        }

    function selector () external pure returns (bytes memory Placement, bytes memory Abort,
    bytes memory ConfirmPurchase, bytes memory ConfirmReceived) {
    return (
        abi.encodeWithSignature("placement(string)"),
        abi.encodeWithSignature("abort(uint256)"),
        abi.encodeWithSignature("confirmPurchase(uint256,string)"),
        abi.encodeWithSignature("confirmReceived(uint256)"));
        }  
}