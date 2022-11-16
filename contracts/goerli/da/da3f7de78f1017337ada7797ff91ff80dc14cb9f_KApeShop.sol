/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

error NotOwner();
error OutOfStock(uint256 icedAmericano, uint256 pandesal, uint256 hotEspresso, uint256 hotChoco);
error shopStillClosed(uint end);
error shopIsClosed(uint closingTime);

contract KApeShop{
    uint256 icedAmericano = 100;
    uint256 pandesal = 70;
    uint256 hotEspresso = 50;
    uint256 hotChoco = 50;
    address public owner;
    uint end;
    uint closingTime;
    
    mapping (address => uint256) public icedAmericanoBought;
    mapping (address => uint256) public pandesalBought;
    mapping (address => uint256) public hotEspressoBought;
    mapping (address => uint256) public hotChocoBought;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if(msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    modifier icedAmericanoEmpty {
        if(icedAmericano == 0) {
            revert OutOfStock(icedAmericano, pandesal, hotEspresso, hotChoco);
        }
        _;
    }

    modifier hotChocoEmpty {
        if(hotChoco == 0) {
            revert OutOfStock(icedAmericano, pandesal, hotEspresso, hotChoco);
        }
        _;
    }

    modifier pandesalEmpty {
        if(pandesal == 0) {
            revert OutOfStock(icedAmericano, pandesal, hotEspresso, hotChoco);
        }
        _;
    }

    modifier hotEspressoEmpty {
        if(hotEspresso == 0) {
            revert OutOfStock(icedAmericano, pandesal, hotEspresso, hotChoco);
        }
        _;
    }     

    modifier setTimeLock {
        if( block.timestamp > end) {
            revert shopStillClosed(end);
        }
        _;
    }

    modifier shopKey {
        if(block.timestamp > closingTime) {
            revert shopIsClosed(closingTime);
        }
        _;
    }

    // ALL ITEMS ARE PAYABLE
    function buyIcedAmericano(uint256 _icedAmericano) public payable icedAmericanoEmpty {
        require(msg.value >= 1 ether, "Not enough balance");
        icedAmericano = icedAmericano - _icedAmericano;
        icedAmericanoBought[msg.sender] += _icedAmericano;
    }

    function buyHotChoco(uint256 _hotChoco) public payable hotChocoEmpty {
        require(msg.value >= 1 ether, "Not enough balance");
        hotChoco = hotChoco - _hotChoco;
        hotChocoBought[msg.sender] += _hotChoco;
    }

    // BUY 1 TAKE 1
    function B1T1Pandesal() public payable pandesalEmpty {
        require(msg.value >= 1 ether, "Not enough balance");
        pandesal = pandesal - 2;
        pandesalBought[msg.sender] += 2;
    }

    // WITH TIME LOCK
    function buyHotEspresso(uint256 _hotEspresso) public payable hotEspressoEmpty shopKey  {
        require(msg.value >= 1 ether, "Not enough balance");
        hotEspresso = hotEspresso - _hotEspresso;
        hotEspressoBought[msg.sender] += _hotEspresso;
    }

    function IcedAmericano () public view returns(uint256) {
        return icedAmericano;
    }

    function HotChoco () public view returns(uint256) {
        return hotChoco;
    }

    function Pandesal () public view returns(uint256) {
        return pandesal;
    }

    function HotEspresso () public view returns(uint256) {
        return hotEspresso;
    }

    function balanceOf() external view returns(uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {
        require(msg.sender == owner, "Sender is not owner!");
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }

    // RESTOCK ITEMS
    function restockIcedAmericano(uint256 quantity) public {
        if(icedAmericano == 0) {
            icedAmericano = quantity;
        }
        require(quantity <= 100, "Iced Americano maximum quantity: 100");
    }

    function restockHotChoco(uint256 quantity) public {
        if(hotChoco == 0) {
            hotChoco = quantity;
        }
        require(quantity <= 50, "Hot Choco maximum quantity: 50");
    }

    function restockPandesal(uint256 quantity) public {
        if(pandesal == 0) {
            pandesal = quantity;
        }
        require(quantity <= 70, "Pandesal maximum quantity: 70");
    }

    function restockHotEspresso(uint256 quantity) public {
        if(hotEspresso == 0) {
            hotEspresso = quantity;
        }
        require(quantity <= 50, "Hot Espresso maximum quantity: 50");
    }

    // TIME LOCK
    function timeLock(uint256 time) public onlyOwner {
        end = block.timestamp + time;
    }

    function getTimeLeft() public view returns(uint256 time) {
        require(end >= block.timestamp,
            "Hot Espresso is not available at this time. Please come back tomorrow.");
        return end - block.timestamp;
    }

    function getTimeStamp()public view returns(uint256) {
        return block.timestamp;
    }

    function openShop(uint256 time) public {
        closingTime = block.timestamp + time;
        require(msg.sender == owner, "Not owner");
    }

    function getOpenTimeLeft() public view returns(uint256) {
        require(closingTime >= block.timestamp , "KApe Shop is closed.");
        return closingTime - block.timestamp;
    }

    // WHITELIST
  
}