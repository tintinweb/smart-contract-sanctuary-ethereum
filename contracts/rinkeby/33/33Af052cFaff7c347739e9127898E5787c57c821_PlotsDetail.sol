/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.7;

contract TaxCalculator {    
    
    function calculatePrice(uint _rpm, uint _regFee, uint _size) external pure returns (uint) {
        uint plotPrice;
        uint regPlotPrice;
        uint price; 

        plotPrice = _size * _rpm;
        regPlotPrice = plotPrice * _regFee/100;
        price = plotPrice + regPlotPrice;

        return price;
    }    
}

contract HashirToken {
    uint _totalSupply;
    string _tokenName;
    string _tokenSymbol;
    uint _decimals;

    mapping(address => uint) _balanceOf;

    constructor(uint totalSupply_, string memory tokenName_, string memory tokenSymbol_, uint decimals_) {
        _totalSupply = totalSupply_;
        _tokenName = tokenName_;
        _tokenSymbol = tokenSymbol_;
        _decimals = decimals_;
        _balanceOf[msg.sender] = totalSupply_;

    }
    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }
    function tokenName() public view returns(string memory) {
        return _tokenName;
    }
     function tokenSymbol() public view returns(string memory) {
        return _tokenSymbol;
    }
     function decimals() public view returns(uint) {
        return _decimals;
    }
     function balanceOf(address _address) public view returns(uint) {
        return _balanceOf[_address];
    }
    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _balanceOf[owner] = _balanceOf[owner] - amount;
        _balanceOf[to] = _balanceOf[to] + amount;
        _totalSupply = _totalSupply - amount;
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        _balanceOf[_from] -= _value;
        _balanceOf[_to] += _value;
        return true;
   }

}

contract PlotsDetail {
    TaxCalculator taxC;
    HashirToken HashirT;

    string public townName;
    uint private ratePerMarla;
    uint private size;
    uint private price;
    address public owner; 

    constructor(address tc, address HT) {
        owner = msg.sender;
        taxC = TaxCalculator(tc);
        HashirT = HashirToken(HT);
    }

    function plotDetails(string memory _townName, uint _size) public returns (uint _price) {
        uint regFee;
        townName = _townName;
        size = _size;

        if (keccak256(abi.encodePacked((townName))) == keccak256(abi.encodePacked(("bahriaTown"))))  {
            ratePerMarla = 400000;
            regFee = 2;
            price = taxC.calculatePrice(ratePerMarla, regFee, size);
            return price;
        }else if (keccak256(abi.encodePacked((townName))) == keccak256(abi.encodePacked(("modelTown"))))  {
            ratePerMarla = 450000;
            regFee = 3;
            price = taxC.calculatePrice(ratePerMarla, regFee, size);
            return price;
        }else if (keccak256(abi.encodePacked((townName))) == keccak256(abi.encodePacked(("blueCity"))))  {
            ratePerMarla = 300000;
            regFee = 1;
            price = taxC.calculatePrice(ratePerMarla, regFee, size);
            return price;
        }else if (keccak256(abi.encodePacked((townName))) == keccak256(abi.encodePacked(("makkahTown")))) {
            ratePerMarla = 800000;
            regFee = 8;
            price = taxC.calculatePrice(ratePerMarla, regFee, size);
            return price;
        }else {
            ratePerMarla = 0;
            return 0;
        }
    }
    function bookPlot(string memory _townName, uint _size) public {
        address buyerAddrees = msg.sender;
        uint _price = plotDetails(_townName, _size);
        HashirT.transferFrom(buyerAddrees, address(this), _price); 
    }

    function getRPM() public view returns (uint) {
         return ratePerMarla;
    }

    function getPrice() public view returns(uint) {
        return price;
    }
}