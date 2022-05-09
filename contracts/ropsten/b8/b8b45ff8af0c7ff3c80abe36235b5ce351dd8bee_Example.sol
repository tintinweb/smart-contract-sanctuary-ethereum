/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.9.0;



contract Example{
    address public owner;
    uint256 public balance;
    address SellerAddress;
    address payable manager;

    struct ProductInfo{
        uint256 ProductPrice;
        string ProductName;
    }
    constructor(address  _SellerAddress){
        SellerAddress = _SellerAddress;
        owner = msg.sender; // store information who deployed contract
    }

    modifier CheckAddress {
      require(msg.sender != SellerAddress, "Address Error");
      _;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this!");
        _;
    }


    ProductInfo[] public productInfo;
    
    function addProductInfo(uint256 _ProductPrice, string memory _ProductName) public {
        productInfo.push(ProductInfo(_ProductPrice, _ProductName));
    }
    
    function getProductInfo() public view returns(uint256, string memory) {
        return (productInfo[0].ProductPrice, productInfo[0].ProductName);  
    }

    function getSellerAddressInfo() public view returns(address) {
        return SellerAddress;
    }

    function withdraw(address payable destAddr) public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(productInfo[0].ProductPrice <= balance, "Insufficient funds");
        
        destAddr.transfer(productInfo[0].ProductPrice); // send funds to given address
        balance -= productInfo[0].ProductPrice;
    }

    receive() payable external {
        balance += msg.value; // keep track of balance (in WEI)
    }

}