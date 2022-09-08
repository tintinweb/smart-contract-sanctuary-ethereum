// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

abstract contract HCoinI {
    function transferFrom(address owner, address buyer, uint numTokens) public virtual returns (bool);
}

contract Dealer {

    error NotEnoughEthSent();
    error NotOwner();
    error ZeroAddress();

    address public hcoinAddress=0x6f2d6f4975754c05DCc30020e99f0Fc60cfE16e1;
    address public hcoinContractOwner=0x2F3999FaAC89c76Dbf9bd93D7367CbB5c17e484b;
    address public owner;
    HCoinI hcoin = HCoinI(hcoinAddress);

    uint256 public price = 2000000000000000 ; // 0.002 eth

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if(msg.sender !=owner) revert NotOwner();
        _;
    }

    function buyHcoin(uint256 amount_) external payable {
        if(msg.value < price*amount_) revert NotEnoughEthSent();
        hcoin.transferFrom(hcoinContractOwner, msg.sender,amount_);
    }

    function setHcoinAddress(address hcoinAddr_) external onlyOwner{
        if(hcoinAddr_==address(0)) revert ZeroAddress();
        hcoinAddress = hcoinAddr_;
        hcoin = HCoinI(hcoinAddress);
    }


}