/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


contract EthCart{

    address private Owner;

    struct BuyersPanDetails{
        string name;
        uint invoiceAmount;
        uint invoiceDate;
        address transactionFrom;
        string ProductDescription;
    }

    struct SellersPanDetails{
        string name;
        uint invoiceAmount;
        uint invoiceDate;
        string ProductDescription;
    }
     struct Product_Details{ 
        address Product_Owner;
        string Product_Name;
        string Product_Description;
        uint256 Product_Price;
        string product_id;
    }
    struct Product_Status{
        address Buyer_Owner; 
        status Status;
        uint Time_Lock;
    }

    constructor(){

        Owner=msg.sender;

    }

    event Product_register(address indexed Product_Owner,string Product_Id, uint Product_Price);
    event Product_Buy(address indexed Product_Buyer,string Product_Id, uint Product_Price );
    event LogDelievered(string productId, bool sold);

    error InsufficientBalance(uint256 available, uint256 required);
    error Unauthorized(string reason); 

    Product_Details[] private p;

    address[] private buyers;
    address[] private sellers;
    BuyersPanDetails[] private b;
    SellersPanDetails[] private s;

    
    enum status {available,ordered,cancelled, paid,sold}

    mapping(address=>bool) private deliveryAgent;
    mapping (string=>BuyersPanDetails[]) private BuyersPanMapping;
    mapping (string=>SellersPanDetails[]) private SellersPanMapping;
    mapping(address=>mapping (string=>Product_Details)) private ProductDetails;
    mapping(string=>Product_Status) private ProductStatus;
    mapping(string=>address) private product_Owner;
    mapping(string=>uint ) private PriceOfProduct;
    mapping (string=>string) private ProductDescription;
    mapping(string=>bool) private ProductID;
    mapping(address=>bool) private unique;
    mapping(string=>address) private sellersPAN;
    mapping(string=>address) private buyersPAN;


    modifier OnlyOwner(){
        require(msg.sender==Owner,"only owner can access function");
        _;
    }

    modifier OnlyDeliveryAgent(){
        require(deliveryAgent[msg.sender]==true,"only DeleveryAgent can access function");
        _;
    }

    function DetailsFromPan(string memory _s) public view returns(BuyersPanDetails[] memory){
         return BuyersPanMapping[_s];
    }

    function SellersDetails(string memory _s) public view returns(SellersPanDetails[] memory){
        return SellersPanMapping[_s];
    }

    function TotalProducts() public view returns(uint){
        return p.length;
    }

    function TotalBuyers() public view returns(uint){
        return buyers.length;
    }

    function TotalSellers() public view returns(uint){
        return sellers.length;
    }

    function AvailableProducts() public view returns(Product_Details[] memory){
        return p;
    }

    function ProductsDetails(string memory _productid) public  view returns(Product_Details memory){
       return ProductDetails[product_Owner[_productid]][_productid];
    }

    function Submit(string memory _name,string memory _sellersPAN,string memory Product_Name,string memory Product_Description,uint256 Product_Price,string memory ProductId) public {
        require(sellersPAN[_sellersPAN]==msg.sender || sellersPAN[_sellersPAN]==address(0) );
        require(ProductID[ProductId]==false,"Product Id already taken");
        require(bytes(_sellersPAN).length==12,"The pan length should be 12 digit");
        ProductID[ProductId]=true;
        SellersPanMapping[_sellersPAN].push(SellersPanDetails({
            name:_name,
            invoiceAmount: Product_Price,
            invoiceDate: block.timestamp,
            ProductDescription:Product_Description
        }));
        p.push(Product_Details({
             Product_Owner:msg.sender,
             Product_Name:Product_Name,
             Product_Description:Product_Description,
              Product_Price:Product_Price,
              product_id:ProductId
        }));
        
        ProductDetails[msg.sender][ProductId]=Product_Details(msg.sender,Product_Name,Product_Description,Product_Price,ProductId);
        product_Owner[ProductId]=msg.sender;
        PriceOfProduct[ProductId]=Product_Price;
        ProductDescription[ProductId]=Product_Description;

        ProductStatus[ProductId]=Product_Status(msg.sender,status.available,block.timestamp);
        
        emit Product_register(msg.sender, ProductId, Product_Price);
        if(unique[msg.sender]!=true){
            sellers.push(msg.sender);
            unique[msg.sender]=true;
        }
        sellersPAN[_sellersPAN]=msg.sender;
    }

    function Buy(string memory _ProductId,string memory _buyersPAN,string memory _name) public  {
        require(buyersPAN[_buyersPAN]==msg.sender || buyersPAN[_buyersPAN]==address(0));
        require(ProductStatus[_ProductId].Status==status.available,"product is not available");
        require(bytes(_buyersPAN).length==12,"The pan length should be 12 digit");
        
        BuyersPanMapping[_buyersPAN].push(BuyersPanDetails({
            name:_name,
            invoiceAmount: PriceOfProduct[_ProductId],
            invoiceDate: block.timestamp,
            transactionFrom:product_Owner[_ProductId],
            ProductDescription:ProductDescription[_ProductId]
        }));

        buyers.push(msg.sender);

        ProductStatus[_ProductId]=Product_Status(msg.sender,status.ordered,block.timestamp);
        buyersPAN[_buyersPAN]=msg.sender;
        emit Product_Buy(msg.sender, _ProductId, PriceOfProduct[_ProductId]);
    }

    function track_Status(string memory _ProductId) public  view returns(Product_Status memory) {
        require(ProductID[_ProductId]==true);
        return  ProductStatus[_ProductId];

    }

    function cancel(string memory _ProductId) public {
        require(msg.sender==ProductStatus[_ProductId].Buyer_Owner,"Owner UnAthorised:");
        require(ProductStatus[_ProductId].Status==status.ordered,"product is not available");
        ProductStatus[_ProductId]=Product_Status(address(0x0),status.available,0);
    }

    function AmountPaid(string memory _ProductId)public OnlyDeliveryAgent{
        require(ProductStatus[_ProductId].Status==status.ordered,"product is not available");
        ProductStatus[_ProductId].Status=status.paid;
    }

    function delivered(string memory _ProductId) public OnlyDeliveryAgent{
        require(ProductStatus[_ProductId].Status==status.paid,"product is not paid yet");
        ProductStatus[_ProductId].Status=status.sold;
        emit LogDelievered(_ProductId,true);
        deliveryAgent[msg.sender]=false;
    }

    function AddDeleveryAgent(address _deliveryagent)public OnlyOwner{
        deliveryAgent[_deliveryagent]=true;
    }
    address[] private subscribers;
    uint total_subsribers=subscribers.length;
    mapping(address=>bool) subscibed;

    modifier alreadySubscibed(){
        require(subscibed[msg.sender]!=true,"You are already subscribed to our website");
        _;
    }

    function subscibe()public alreadySubscibed{
       subscribers.push(msg.sender);
       subscibed[msg.sender]=true;
    }

    function showSubscribers()public view returns(address[] memory){
        return subscribers;
    }
}