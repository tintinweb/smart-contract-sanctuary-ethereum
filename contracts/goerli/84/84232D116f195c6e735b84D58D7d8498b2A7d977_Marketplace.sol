/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

/**
Created by Bob Lin

Blockchain Reputation Management System in E-commerce 
-- 6 sections of code:
1. Create contract structure
2. Initialize seller store
3. Product upload
4. Product purchase
5. Buyer reviews
6. Rewards

This marketplace currently is set up for only 1 seller store with multiple products, and multiple possible buyers.
Things to add:
- Reputation score storage
- Reputation score calculations and updates

*/


// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Marketplace {

    // ------------------------------------------------- Variables -------------------------------------------------
    uint256 public countOfSellers;     

    // ------------------------------------------------- Constructor -------------------------------------------------
    // initialising the marketplace
    constructor() {
        countOfSellers = 0; 
    }

    // ------------------------------------------------- Structs -------------------------------------------------
    struct Seller {
        // Attributes
        address sellerAddress;
        uint256 sellerID;
        uint256 sellerRepScore;
        uint256 rewardAmount;
        uint256 sellerRevenue;
        bool valid;

        // Mappings and arrays
        Product[] sellerProducts;

    }

    struct Buyer {
        // Attributes
        address buyerAddress;
        uint256 buyerRepScore;
        uint256 buyerRewardAmount;
        bool valid;

    }

    struct Product { 
        // Attributes
        uint256 productID;
        string productName;
        address sellerAddress; 
        uint256 price; 
        bool valid;
        uint256 countReviews;

        // Mappings and arrays
        mapping(address => bool) buyers; 
        mapping(address => Review) buyerReviews; 
    } 

    // Product[] public allProducts;
    // mapping()

    
    // struct Reviews {
    //     mapping()
    // }

    struct Review {
        // Attributes
        uint256 reviewID;
        uint256 productID;
        address sellerAddress;
        address buyerAddress;
        //string reviewText;
        uint256 rating;
        bool valid;
    }

    struct Sale {
        // Attributes
        address saleAddress;
        address productID;
        address sellerAddress;
        address buyerAddress;
        uint256 price;
        uint256 timestamp;
        bool valid;
    }

    // ------------------------------------------------- Mappings -------------------------------------------------
    mapping(address => Seller) public allSellers;
    mapping(address => Buyer) allBuyers;

    // Tracks seller's number of sales
    mapping(address => uint256) public numOfSales;

    // // Mapping productID to Product 
    // mapping(address => Product) allProducts; 



    // ------------------------------------------------- Arrays -------------------------------------------------
    // Unused so far... review!
    Review[] public allReviews;
    Sale[] public allSales;
    Seller[] public allSellersArr;

    // ------------------------------------------------- Events -------------------------------------------------
    event Upload( 
        uint256 productID,
        string productName, 
        address indexed sellerAddress
    ); 
    event ProductSale( 
        address indexed buyerAddress, 
        address indexed sellerAddress, 
        uint256 price, 
        uint256 timestamp 
    ); 
    event Reward( 
        address indexed buyerAddress, 
        address indexed sellerAddress, 
        uint256 reviewID, 
        uint256 price,
        uint256 timestamp
    ); 
    event BuyerReview(
        uint256 productID,
        uint256 reviewID,
        address indexed buyerAddress,
        uint256 rating,
        uint256 timestamp
    );
    event CreateSeller( 
        address sellerAddress, 
        uint256 sellerID,
        uint256 sellerRepScore,
        uint256 rewardAmount
    ); 
    event CreateBuyer( 
        address buyerAddress, 
        uint256 buyerRepScore
    ); 


    // ------------------------------------------------- Functions -------------------------------------------------
    // Create seller - called by seller
    function createSeller(uint256 sellerID, uint256 sellerRepScore, uint256 rewardAmount, uint256 sellerRevenue) 
    public 
    returns (bool success)
    {
        // Check for duplicates
        require(!allSellers[msg.sender].valid, "Seller with this sellerAddress already exists!");

        allSellers[msg.sender];
        Seller storage newSeller = allSellers[msg.sender];

        newSeller.sellerAddress = msg.sender;
        newSeller.sellerID = sellerID;
        newSeller.sellerRepScore = sellerRepScore;
        newSeller.rewardAmount = rewardAmount;
        newSeller.sellerRevenue = sellerRevenue;

        // NEW
        uint256 idx = allSellersArr.length;
        allSellersArr.push();
        newSeller = allSellersArr[idx];
        //NEW

        emit CreateSeller(msg.sender, sellerID, sellerRepScore, rewardAmount);
        return true;
    }

    // Create buyer - called by buyer
    function createBuyer(address buyerAddress, uint256 buyerRepScore) 
    public 
    returns (bool success)
    {
        // Check for duplicates
        require(!allBuyers[msg.sender].valid, "Buyer with this buyerAddress already exists!");

        allBuyers[msg.sender];
        Buyer storage newBuyer = allBuyers[msg.sender];

        newBuyer.buyerAddress = buyerAddress;
        newBuyer.buyerRepScore = buyerRepScore;

        emit CreateBuyer(buyerAddress, buyerRepScore);
        return true;
    }


    // Upload Product - called by seller
    function uploadProduct(uint256 productID, string memory productName, uint256 price) 
    public 
    returns (bool success) 
    {
        // Verify whether the product information has been uploaded or not. (Pass if productID not valid)
        require(!allSellers[msg.sender].sellerProducts[productID].valid, "Product with this productID already uploaded before!"); 
// TODO
        // Initialize product instance 
        // cur numProducts will also be the productID of the next newProduct (zero indexed)
        uint256 numProducts = allSellers[msg.sender].sellerProducts.length;
        // adds one ele to array allProducts
        allSellers[msg.sender].sellerProducts.push(); 
        // Create a newProduct in storage, note that numProducts is the new productID
        // This way of initialisation is necessary to avoid (nested) mapping error in Solidity
        Product storage newProduct = allSellers[msg.sender].sellerProducts[numProducts];

        // numProducts++;
        newProduct.productID = numProducts; 
        newProduct.productName = productName;
        newProduct.sellerAddress = msg.sender;
        newProduct.price = price;
        newProduct.valid = true;
        newProduct.countReviews = 0;

        // Mappings (None during initialisation)

        // If success, publish to UI 
        emit Upload(numProducts, productName, msg.sender);
        return true;
    }

    // Purchase of product - called by buyer 
    function purchaseProduct(uint256 productID, address sellerAddress) 
    public 
    payable 
    returns (bool success) 
    { 
        // Verify whether product is in the system 
        require(allSellers[sellerAddress].sellerProducts[productID].valid, "Product does not exist!"); 

        // Check if buyer's balance is not 0 (the value provided in this function call msg)
        require(msg.value > 0, "Ethers cannot be zero!"); 

        // Identify product instance 
        Product storage productToBuy = allSellers[sellerAddress].sellerProducts[productID]; 

        // Checks if buyer's payment is equal to product price
        require(msg.value == productToBuy.price, "Please send exact amount!"); 

        // Perform the sale 
        // Give seller the credits 
        allSellers[sellerAddress].sellerRevenue += msg.value;
        // Update allSales
        // allSales

        // Update mapping 
        productToBuy.buyers[msg.sender] = true; // mapping buyer address to true or false depending on whether the buyer has bought this product before

        // Publish Purchase event to UI 
        emit ProductSale(msg.sender, sellerAddress, productToBuy.price, block.timestamp); 
        return true; 
    }
    
    // Review of product - called by buyer
    function buyerReview(uint256 buyerRating, uint256 productID, address sellerAddress) 
    public 
    returns (bool success) 
    { 
        // Verify whether product is in the system 
        require(allSellers[sellerAddress].sellerProducts[productID].valid, "Product does not exist!");  

        // Identify product instance 
        Product storage productToReview = allSellers[sellerAddress].sellerProducts[productID]; 

        // Check if buyer actually bought the product 
        require(productToReview.buyers[msg.sender] == true, "No records of buyer buying this product or leaving review."); 

        // Create the Reviewww named productReview
        productToReview.countReviews++;
        uint256 reviewID = productToReview.countReviews;
        Review memory productReview = Review(reviewID, productID, productToReview.sellerAddress, msg.sender, buyerRating, true);

        // Update mappings 
        productToReview.buyerReviews[msg.sender] = productReview;

        // Publish Review event to UI 
        emit BuyerReview(productID, reviewID, msg.sender, buyerRating, block.timestamp);
        return true;

    }

    // Seller rewards buyers for leaving review - called by seller
    function reward(uint256 productID, address buyerAddress, uint256 reviewID) 
    public 
    payable 
    returns (bool success) 
    { 
        // Verify whether product is in the system 
        require(allSellers[msg.sender].sellerProducts[productID].valid, "Product does not exist!"); 

        // Identify product instance 
        Product storage product = allSellers[msg.sender].sellerProducts[productID]; 

        // Identify product instance via its product ID, via its IPFS address p = allProducts[productID] 
        // Check if buyer has actually bought the product 
        require(product.buyers[buyerAddress] == true, "No records of buyer buying this product."); 

        // TODO START FROM HERE!
        // Check if buyer left a review 
        require(product.buyerReviews[buyerAddress].valid, "No records of buyer leaving review."); 

        // Future TODO - Seller gives review 
        //Update mapping for this seller review to the buyer 

        // Ensure seller has sent the correct amount
        require(msg.value == allSellers[msg.sender].rewardAmount, "Please send exact amount of reward!");

        // Reward buyer 
        allBuyers[buyerAddress].buyerRewardAmount += allSellers[msg.sender].rewardAmount;

        // Publish Reward event to UI 
        emit Reward(buyerAddress, msg.sender, reviewID, allSellers[msg.sender].rewardAmount, block.timestamp);
        return true; 
    }

    // Payable functions - called by seller
    // Sellers withdraw amount they are entitled to
    function sellerWithdraw()
    public
    payable
    returns (bool sucess)
    {
        uint256 amountToWithdraw = allSellers[msg.sender].sellerRevenue;
        payable(msg.sender).transfer(amountToWithdraw);
        allSellers[msg.sender].sellerRevenue = 0;
        return true;
    }

    // Buyers withdraw amount they are entitled to - called by buyer
    function buyerWithdraw()
    public
    payable
    returns (bool sucess)
    {
        uint256 amountToWithdraw = allBuyers[msg.sender].buyerRewardAmount;
        payable(msg.sender).transfer(amountToWithdraw);
        allBuyers[msg.sender].buyerRewardAmount = 0;
        return true;
    }

    // Getter functions to interact and test the contract on Goerli testnet
    function getSellers()
    public
    returns (uint256)
    {
        return allSellersArr[0].sellerID;
    }

}


// contract ERC20Basic{
//     uint256 public constant tokenPrice = 5; // 1 token for 5 wei
    
//     function buy(uint256 _amount) external payable {
//         // e.g. the buyer wants 100 tokens, needs to send 500 wei
//         require(msg.value == _amount * tokenPrice, 'Need to send exact amount of wei');
        
//         /*
//          * sends the requested amount of tokens
//          * from this contract address
//          * to the buyer
//          */
//         transfer(msg.sender, _amount);
//     }
    
//     function sell(uint256 _amount) external {
//         // decrement the token balance of the seller
//         balances[msg.sender] -= _amount;
//         increment the token balance of this contract
//         balances[address(this)] += _amount;

//         /*
//          * don't forget to emit the transfer event
//          * so that external apps can reflect the transfer
//          */
//         emit Transfer(msg.sender, address(this), _amount);
        
//         // e.g. the user is selling 100 tokens, send them 500 wei
//         payable(msg.sender).transfer(amount * tokenPrice);
//     }
// }