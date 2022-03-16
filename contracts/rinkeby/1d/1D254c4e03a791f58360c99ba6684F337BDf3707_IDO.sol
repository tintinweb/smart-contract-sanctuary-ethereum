// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./Token.sol";

contract IDO is Token {
    uint256 public dllrForBnb = 1000000;                
    uint256 public bnb = 1 ether;                       
    uint256 public idoStatus;
    uint256 public jagerForDllr = bnb / dllrForBnb;    
    uint256 public idoPool;                             
    uint256 private startTime;

    Token public token;

    event HashTeg(string hashTeg);

    constructor(address payable _token) {
        token = Token(_token);
        uint256 totalSupply = totalSupply();
        idoPool = (totalSupply * 10) / 100;
        token.mint(address(this), idoPool);
        token.burn(_token, idoPool);
        startTime = block.timestamp;
    }

    modifier idoStatusModifier() {
        require(idoStatus == 1, "IDO isn't active");
        _;
    }

    function startIDO() public {
        require(idoStatus == 0, "IDO started or is over");
        idoStatus = 1;
    }

    function buy(uint256 _amount)
        public
        payable
        idoStatusModifier
        returns (string memory)
    {
        uint256 requireBnb = _amount * jagerForDllr;

        address buyer = msg.sender;
        
        require(buyer.balance > requireBnb, "balance is not enought");
        
        require(requireBnb <= msg.value, "Type right amount of BNB");
        
        require(_amount < idoPool, "tokens in the pool isn't enough");
        
        
        token.transfer(address(this), buyer, _amount);
        

        idoPool -= _amount;
        emit HashTeg("#from_ido");

        return "#from_ido";
    }

    function withdraw() external override onlyOwner {
        // require(
        //     (block.timestamp - startTime) > 24 hours,
        //     "you can withdraw only after 24 hour"
        // );
        payable(msg.sender).transfer(address(this).balance);
        startTime = block.timestamp;
    }

    function endIDO() public {
        require(idoStatus == 1, "IDO isn't started or it's over");
        idoStatus = 2;
        token.burn(address(this), idoPool);
    }
}