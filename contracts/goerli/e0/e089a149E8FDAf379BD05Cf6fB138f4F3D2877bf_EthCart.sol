/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// File: hacknovate.sol/project.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;


contract EthCart{

    uint256 public  ProductId;

    // company Owner
    address Owner;

    // we can add more delevery agent if need
    address deleveryAgent;

    constructor(){
        Owner=msg.sender;
    }


    event Product_register(address indexed Product_Owner,uint Product_Id, uint Product_Price);
    event Product_Buy(address indexed Product_Buyer,uint Product_Id, uint Product_Price );
    event LogCancel(address indexed Buyer, uint projectId);
    event LogDelevered(uint productId, bool sold);


    error InsufficientBalance(uint256 available, uint256 required);
    error Unauthorized(string reason); 

    struct Product_Details{ 
        address Product_Owner;
        string Product_Name;
        string Product_Description;
        uint256 Product_Price;
    }

     struct Product_Status{
        address Buyer_Owner; 
        status Status;
        uint Time_Lock;
    }

    enum status {avilable,ordered,cancled, sold}

    // store (key,UniqueId, value)=(projectOwneraddress , UniqueId,Product_details)
    //productId is given by contract at time of product submit by product owner
    // each product has a specific productID 
    mapping(address=>mapping (uint=>Product_Details)) public ProductDetails;

        // track project Status by ProjectId
    mapping(uint=>Product_Status) public ProductStatus;

    // track buyer balance for specific product
    mapping(address=>mapping (uint =>uint)) public Balance;

    // approved : buyer can withdraw their after succesfull cancelation
    mapping(address=>mapping (uint=>bool)) public Approved;

    // track owner address by projectId
    mapping(uint=>address) public product_Owner;


    modifier OnlyOwner(){
        require(msg.sender==Owner,"only owner can access function");
        _;
    }

    
    modifier OnlyDeleveryAgent(){
        require(msg.sender==deleveryAgent,"only DeleveryAgent can access function");
        _;
    }

    

    // product owner can submit thier product on network
    function Submit(
        string memory Product_Name,
        string memory Product_Description,
        uint256 Product_Price
    ) public returns(uint){
        ProductId++;
        ProductDetails[msg.sender][ProductId]=Product_Details(msg.sender,Product_Name,Product_Description,Product_Price);
        Balance[msg.sender][ProductId]=Product_Price;
        product_Owner[ProductId]=msg.sender;
        emit Product_register(msg.sender, ProductId, Product_Price);
        return ProductId;

    }


    // any buyer can buy this project by productId
    function Buy(uint _ProductId, uint timeStamp) public payable  {
        require(_ProductId<=ProductId,"Unlicensed Product");
        require(ProductStatus[_ProductId].Status==status.avilable,"product is not avilable");
        Product_Details memory Product_details = ProductDetails[product_Owner[_ProductId]][_ProductId];
        uint amount=Product_details.Product_Price;
        if (msg.sender==Product_details.Product_Owner){
            revert Unauthorized({reason:"Owner can't buy own product"});
        }
        else {
            if (amount>msg.value){
                revert InsufficientBalance({
                    available: msg.value,
                    required: amount}

                );
            }
            else {
                require(msg.value==amount,"please entered correct product price");
                ProductStatus[_ProductId]=Product_Status(msg.sender,status.ordered,timeStamp);
                Balance[msg.sender][_ProductId]=msg.value;
                emit Product_Buy(msg.sender, _ProductId, amount);


            }
        }
    }


    // buyer can track their own product status by _ProductId 
    function track_Status(uint _ProductId) public  view returns(Product_Status memory) {
        require(msg.sender==ProductStatus[_ProductId].Buyer_Owner,"Owner UnAthorised:");
        return  ProductStatus[_ProductId];

    }


    // buyer can withdraw money after cancalation of product(in case of cancel)
    function withdrawBuyer(uint _ProductId) public {
        Product_Status memory product_Status= ProductStatus[_ProductId];
        address Buyer_owner=product_Status.Buyer_Owner;
        require(msg.sender!=Owner,"you're not buyer of this product");
        require(Approved[msg.sender][_ProductId],"hasn't approved");
        uint amount=Balance[msg.sender][_ProductId];
        Balance[msg.sender][_ProductId]=0;
        payable(Buyer_owner).transfer(amount);

    
    }

        // buyer can cancel their product within 7 day 
    function cancel(uint _ProductId , uint timeStamp ) public {
        require(msg.sender==ProductStatus[_ProductId].Buyer_Owner,"Owner UnAthorised:");
        Product_Status storage productStatus=ProductStatus[_ProductId];
        uint initialtime=productStatus.Time_Lock;
        uint timeperiod=timeStamp-initialtime;
        require(timeperiod<604800,"you're 7 days time limit exceeded for cancelation");
        Approved[msg.sender][_ProductId]=true;
        ProductStatus[_ProductId]=Product_Status(msg.sender,status.avilable,timeStamp);

    }

        //  buyer update this function after delever this project
        // after succesfull delever product owner can withdraw their money 
    function delevered(uint _ProductId) public {
        Product_Status storage product_Status= ProductStatus[_ProductId];
        address product_owner=product_Status.Buyer_Owner;
        require(product_Status.Status==status.ordered,"product not ordered yet");
        require(msg.sender==product_owner,"you're not buyer of this product");
        product_Status.Status=status.sold;
        Approved[product_Owner[_ProductId]][_ProductId]=true;
    }


    // product owner can withraw their money after approve (or delever to buyer)
    function WithdrawOwner(uint _productId) public {
        address Product_owner=product_Owner[_productId];
        require(msg.sender==Product_owner,"Owner UnAthorised:");
        require(Approved[msg.sender][_productId],"product hasn't delevered");
        uint amount=Balance[msg.sender][_productId];
        Balance[msg.sender][_productId]=0;
        payable(Product_owner).transfer(amount);
    }

    //only  owner can add delevery agent in copany
    function AddDeleveryAgent(address deleveryagent) internal OnlyOwner{
        deleveryAgent=deleveryagent;

    }

}