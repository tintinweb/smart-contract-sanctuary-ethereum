/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.9.0;


contract Example{
    //合約擁有者
    address public Owner;
    //合約餘額
    uint256 public Balance;
    //賣家Address
    address SellerAddress;
    //合約管理
    address payable Manager;
    //產品網址
    string ProductURL;
    //購買狀態
    uint Statu;

    //產品結構  產品價錢(ProductPrice) 產品名稱(ProductItem)
    struct ProductInfo{
        uint256 ProductPrice;
        string ProductItem;
    }

    //建構函數  傳入賣家Address 設定Owner
    constructor(address  _SellerAddress, string memory _ProductURL){
        SellerAddress = _SellerAddress;
        ProductURL = _ProductURL;
        Owner = msg.sender;
        Statu = 0;
        Manager = payable(msg.sender);
    }
    
    //檢查賣家和買家Address是否為不相同
    modifier CheckAddress {
      require(msg.sender != SellerAddress, "Address Error");
      _;
    }

    //檢查合約創建之買家Address是否為擁有者
    modifier onlyManager() {
        require(msg.sender == Manager, "Only manager can call this!");
        _;
    }

    //結構陣列宣告
    ProductInfo[] public productInfo;
    
    //將ProductInfo寫入合約，ProductPrice、ProductItem
    function addProductInfo(uint256 _ProductPrice, string memory _ProductItem) public CheckAddress{
        productInfo.push(ProductInfo(_ProductPrice, _ProductItem));
    }
    
    //取得產品名價錢和名稱
    function getProductInfo() public view returns(uint256, string memory) {
        return (productInfo[0].ProductPrice, productInfo[0].ProductItem);  
    }

    //取得賣家Address
    function getSellerAddressInfo() public view returns(address) {
        return SellerAddress;
    }

    //將產品價錢轉入合約當中
    receive() payable external {
        Balance += msg.value;
    }
    
    //將產品價錢轉至賣家Address
    function withdraw() public {
        require(msg.sender == Owner, "Only owner can withdraw");
        require(productInfo[0].ProductPrice <= Balance, "Insufficient funds");
        address payable destAddr = payable(SellerAddress);
        destAddr.transfer(productInfo[0].ProductPrice); // send funds to given address
        Balance -= productInfo[0].ProductPrice;
        Statu = 1;
    }

    //將合約剩餘價錢返回給買家
    function getBalance() public onlyManager{
        require(msg.sender == Owner, "Only owner can withdraw");
        payable(Owner).transfer(Balance); 
        Balance -= Balance;
    }

    //取得賣家Address
    function getURL() public view returns(string memory) {
        if(Statu == 1){
            return ProductURL;
        }
        return "Null";
    }

}