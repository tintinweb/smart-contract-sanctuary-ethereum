/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface IERC20 {
    function name () external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals () external pure returns (uint);
    function totalSupply () external view returns (uint);
    function balanceOf (address account)  external view returns (uint);
    function transfer (address to, uint amount)  external;
    function allowance (address _owner, address spender)external view returns (uint);
    function approve (address spender, uint amount) external;
    function transferFrom (address sender, address recipient, uint amount) external;
    event Transfer (address indexed from, address indexed to, uint amount);
    event Approve (address indexed owner, address indexed to, uint amount);
}

contract Escrow {
    constructor (uint _FEE) {
        owner=msg.sender;
        FEE=_FEE;
        }
    address owner;
    uint public FEE;
    uint public withdrawFunds;
    uint private valueseller;
    uint amountOwner;
    uint public dealNumber;
    struct  Deal  {
        address seller;
        uint valueSeller;
        address buyer;
        uint valueBuyer;
        string messageSeller;
        string messageBuyer;
        }
    mapping (uint=>Deal) public deals;
    IERC20 USDT = IERC20 (address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
    
    error ValueNotEven();

    modifier condition (bool condition_) {
        require(condition_);
        _;
        }

    function createDeal (string memory _message, uint _amount) external {
        require (_amount>=1000000, "Wrong value, minimum 1 USDT");
        valueseller = _amount / 2;
        if ((2 * valueseller) != _amount)
            revert ValueNotEven();
        require (USDT.balanceOf(msg.sender)>=_amount, "Not enough funds!");
        uint balBefore = USDT.balanceOf(address(this));
        USDT.transferFrom(msg.sender, address(this), _amount);
        uint balAfter = USDT.balanceOf(address(this));
        require (balAfter-balBefore == _amount, "Dont Receive Your Money!");
        dealNumber++;
        deals[dealNumber].seller = msg.sender;
        deals[dealNumber].messageSeller = _message;
        deals[dealNumber].valueSeller = _amount;
    }

    function abort (uint _dealNumber) external  {
        require (deals[_dealNumber].valueSeller*2 >  deals[_dealNumber].valueBuyer, "Locked from buyer!");
        require (deals[_dealNumber].seller==msg.sender, "No have right to abort!");
        uint amount = deals[_dealNumber].valueSeller;
        deals[_dealNumber].valueSeller -= amount;
        USDT.transfer(msg.sender, amount);
        }

    function confirmPurchase (uint _dealNumber, string memory _message, uint _amount) external
     condition(_amount == (2 * deals[_dealNumber].valueSeller)) {
        require (deals[_dealNumber].valueBuyer==0, "don't do it twice!");
        require (_amount!=0, "Wrong value!");
        require (USDT.balanceOf(msg.sender)>=_amount, "Not enough funds!");
        uint balBef = USDT.balanceOf(address(this));
        USDT.transferFrom(msg.sender, address(this), _amount);
        uint balAf = USDT.balanceOf(address(this));
        require (balAf-balBef == _amount, "Dont Receive Your Money!");
        deals[_dealNumber].buyer = msg.sender;
        deals[_dealNumber].messageBuyer = _message;
        deals[_dealNumber].valueBuyer = _amount;
        }

    function confirmReceived (uint _dealNumber) external  {
        require(msg.sender == deals[_dealNumber].buyer, "You are not a buyer!");
        require(deals[_dealNumber].valueSeller>0, "Deal done!");
        uint amountB = deals[_dealNumber].valueBuyer;
        uint amountS = deals[_dealNumber].valueSeller;
        if (amountS>=10000000000) { // >10 000 USDT Fee - 0.5%
            amountOwner = amountS*FEE/2000;
        }
        if (amountS<10000000000) { // <10 000 USDT Fee - 1%
            amountOwner = amountS*FEE/1000;
        }
        deals[_dealNumber].valueBuyer -= amountB;
        deals[_dealNumber].valueSeller -= amountS;
        USDT.transfer(deals[_dealNumber].seller, amountB -(amountOwner/2));
        USDT.transfer(msg.sender, amountS-(amountOwner/2));
        withdrawFunds += amountOwner;
        }

    function withdraw () external  {
        require (msg.sender==owner, "You are not an owner!");
        uint _amount = withdrawFunds;
        withdrawFunds -= _amount;
        USDT.transfer(msg.sender, _amount);
        }

    function selector () external pure returns (bytes memory CreateDeal, bytes memory Abort,
    bytes memory ConfirmPurchase, bytes memory ConfirmReceived) {
    return (
        abi.encodeWithSignature("createDeal(string,uint256)"),
        abi.encodeWithSignature("abort(uint256)"),
        abi.encodeWithSignature("confirmPurchase(uint256,string,uint256)"),
        abi.encodeWithSignature("confirmReceived(uint256)"));
        }

    function addrSeller (uint _dealNumber) external view returns (address) {
        return deals[_dealNumber].seller;
        } 
    function valSeller (uint _dealNumber) external view returns (uint) {
        return deals[_dealNumber].valueSeller;
        } 
    function addrBuyer (uint _dealNumber) external view returns (address) {
        return deals[_dealNumber].buyer;
        }
    function valBuyer (uint _dealNumber) external view returns (uint) {
        return deals[_dealNumber].valueBuyer;
        }
    function msgSeller (uint _dealNumber) external view returns (string memory) {
        return deals[_dealNumber].messageSeller;
        }
    function msgBuyer (uint _dealNumber) external view returns (string memory) {
        return deals[_dealNumber].messageBuyer;
        }   
}