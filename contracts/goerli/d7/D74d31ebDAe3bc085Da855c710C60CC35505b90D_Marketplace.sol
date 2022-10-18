/**
 *Submitted for verification at Etherscan.io on 2022-10-18
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

/* ------- SOME INFO ---------------
In Solidity, reference types are comprised of structs, arrays, and mappings, and are more complicated to use than basic value types (ints, bools, etc) 
because the data location must also be explicitly declared: either memory, storage, or calldata. 
The only exception is state variables, which are automatically assumed and can only be storage. 

In general:
memory — has a lifetime limited to an external function call, is mutable, and scoped within a function (non-persistent, modifiable)
storage — has a lifetime limited to the lifetime of a contract it is contained in, is mutable, and is where all state variables are stored (persistent, mutable)
calldata — is similar to memory, is immutable, and is a special data location containing function arguments (non-persistent, non-modifiable)
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

// import "hardhat/console.sol";

contract Marketplace {

    // ------------------------------------------------- Variables -------------------------------------------------
    uint public countOfSellers = 0;     
    uint public countOfBuyers = 0;
    uint public countOfProducts = 0;     
    uint puchaseID;
    

    // ------------------------------------------------- Constructor -------------------------------------------------
    // initialising the marketplace
    // constructor() {
    //     countOfSellers = 0; 
    // }

    // ------------------------------------------------- Structs -------------------------------------------------
    struct Seller {
        // Attributes
        address sellerAddress;
        string name;
        uint sellerID;
        uint sellerRepScore;
        uint rewardAmount;
        uint sellerRevenue;
        bool valid;
        bool verified;
        // Mappings and arrays
        // Product[] sellerProducts;

    }

    struct Buyer {
        // Attributes
        address buyerAddress;
        uint buyerID;
        uint buyerRepScore;
        uint buyerRewardAmount;
        bool valid;
        bool verified;
    }

    struct Product { 
        // Attributes
        uint productID;
        string productName;
        address sellerAddress; 
        uint price; 
        bool valid;
        uint countReviews;
        uint rating;
        bool reviewed;

        // Mappings and arrays
        // mapping(address => bool) buyers; 
        // mapping(address => Review) buyerReviews; 
    } 

    // Product[] public productsOfSeller;
    // mapping()

    
    // struct Reviews {
    //     mapping()
    // }

    struct Review {
        // Attributes
        uint reviewID;
        uint productID;
        address sellerAddress;
        address buyerAddress;
        //string reviewText;
        uint rating;
        bool valid;
    }

    struct Sale {
        // Attributes
        address saleAddress;
        address productID;
        address sellerAddress;
        address buyerAddress;
        uint price;
        uint timestamp;
        bool valid;
    }

    // ------------------------------------------------- Mappings -------------------------------------------------
    // Mappings are like hash maps. They dont have virtually initialised such that every possible key exists and is mapped to a value 0. 
    // This means that mappings do not have a length
    // Mappings can only be used for state variables that act as storage reference types
    // It’s then possible to create a getter function call (like public) in which the _KeyType is the parameter used by the getter function in order to return the _ValueType.
    // Good for A->B type of relationship

    /* Note about mappings
    A note on Struct as a value type for mappings
    An important side note worth mentioning relates to mappings that have a struct as a value type.

    If the struct contains an array, it will not be returned via the getter function created by the “public” keyword. 
    You have to create your own function for that, that will return an array.
    */

    mapping(address => Seller) public allSellers;
    mapping(address => Buyer) allBuyers;

    // Maps seller or buyer address to seller or buyer ID, which is the index position in allSellersArr or allBuyersArr
    mapping(address => uint) public sellerID;
    mapping(address => uint) public buyerID;

    // Tracks seller's number of sales
    mapping(address => uint) public numOfSales;

    // Mapping sellerAddress to array of Products
    mapping(address => Product[]) productsOfSeller; 

    // Mapping buyerAddress to array of Products that they bought
    mapping(address => Product[]) purchasedProductsOfBuyer;
    

    // ------------------------------------------------- Arrays -------------------------------------------------
    // Arrays in Solidity are a reference type, meaning that they reference existing data. This contrasts with a value type, which passes an independent copy of that value to be used.
    // For e.g. z and y both reference x and therefore either can alter (the third element in) x when f() is called.
    
    // Dynamic memory arrays can be initialized using the new operator. 
    // However, although dynamic, memory arrays can not be resized — required sizes must be determined in advance, or completely copied into new memory arrays to make updates.
    // push() and push(x) and pop(): both only available to storage arrays. Note pop() does not return removed element

    Review[] public allReviewsArr;
    Sale[] public allSalesArr;
    Seller[] public allSellersArr;
    Buyer[] public allBuyersArr;

    // ------------------------------------------------- Events -------------------------------------------------
    event Upload( 
        uint productID,
        string productName, 
        address indexed sellerAddress
    ); 
    event ProductSale( 
        address indexed buyerAddress, 
        address indexed sellerAddress, 
        string productName,
        uint productID,
        uint price, 
        uint timestamp,
        uint buyerProductIdx
    ); 
    event Reward( 
        address indexed buyerAddress, 
        address indexed sellerAddress, 
        uint reviewID, 
        uint price,
        uint timestamp
    ); 
    event BuyerReview(
        uint productID,
        address sellerAddress,
        address indexed buyerAddress,
        uint rating,
        uint timestamp,
        uint newRating, 
        uint newCountOfReviews
    );
    event CreateSeller( 
        address sellerAddress, 
        string name,
        uint sellerID,
        uint sellerRepScore,
        uint rewardAmount
    ); 
    event CreateBuyer( 
        address buyerAddress, 
        uint buyerID,
        uint buyerRepScore
    ); 


    // ------------------------------------------------- Functions -------------------------------------------------
    // Create a new seller - called by seller
    function createSeller(string memory sellerName, uint sellerRepScore, uint rewardAmount, uint sellerRevenue) 
    public 
    {
        // Check for duplicates
        require(!allSellers[msg.sender].valid, "Seller with this sellerAddress already exists!");

        // Update mapping and creation of new Seller struct
        allSellers[msg.sender];
        Seller storage newSeller = allSellers[msg.sender];

        uint idx = allSellersArr.length;   
        sellerID[msg.sender] = idx;

        newSeller.sellerAddress = msg.sender;
        newSeller.name = sellerName;
        newSeller.sellerID = idx;
        newSeller.sellerRepScore = sellerRepScore;
        newSeller.rewardAmount = rewardAmount;
        newSeller.sellerRevenue = sellerRevenue;
        newSeller.valid = true;

        // Update of array allSellersArr
        allSellersArr.push();
        allSellersArr[idx] = newSeller;
        countOfSellers++;

        // console.log(
        //     "Seller created with address: %s, name: %s, sellerID: %s, sellerRepScore: %s, rewardAmount: %s.",
        //     msg.sender, 
        //     sellerName,
        //     idx,
        //     sellerRepScore,
        //     rewardAmount
        // );

        emit CreateSeller(msg.sender, sellerName, idx, sellerRepScore, rewardAmount);
    }

    // Create buyer - called by buyer
    function createBuyer(uint buyerRepScore) 
    public 
    {
        // Check for duplicates
        require(!allBuyers[msg.sender].valid, "Buyer with this buyerAddress already exists!");

        // Update mapping
        allBuyers[msg.sender];
        Buyer storage newBuyer = allBuyers[msg.sender];

        uint idx = allBuyersArr.length;
        buyerID[msg.sender] = idx;

        newBuyer.buyerAddress = msg.sender;
        newBuyer.buyerID = idx;
        newBuyer.buyerRepScore = buyerRepScore;
        newBuyer.valid = true;

        // Update array allBuyersArr
        allBuyersArr.push();
        allBuyersArr[idx] = newBuyer;
        countOfBuyers++;

        emit CreateBuyer(msg.sender, idx, buyerRepScore);
    }

    // Upload Product - called by seller
    function uploadProduct(string memory productName, uint price) 
    public 
    {
        // Verify whether the product information has been uploaded or not. (Pass if productID not valid)
        require(allSellers[msg.sender].valid, "This function is not called by a valid seller address!"); 

        // Get array of this seller's current products, via the mapping productsOfSeller
        Product[] storage curSellerProducts = productsOfSeller[msg.sender];
        // Product[] storage sellerProducts = allSellers[msg.sender];

        // Create a new slot in array for the next product
        uint productID = curSellerProducts.length;
        curSellerProducts.push();

        // Create Product struct (new product)
        Product storage newProduct = curSellerProducts[productID];
        //TODO
        newProduct.productID = productID; 
        newProduct.productName = productName;
        newProduct.sellerAddress = msg.sender;
        newProduct.price = price/(10^9);    //convert to gwei
        newProduct.valid = true;
        newProduct.countReviews = 0;
        newProduct.rating = 0;
        newProduct.reviewed = false;
        
        curSellerProducts[productID] = newProduct;
        countOfProducts++;

        // Update mapping productsOfSeller
        productsOfSeller[msg.sender] = curSellerProducts;

        // If success, publish to UI 
        emit Upload(productID, productName, msg.sender);
    }

    // Purchase of product - called by buyer 
    function purchaseProduct(uint productID, address payable sellerAddress) 
    public 
    payable 
    { 
        // Verify whether product is in the system 
        require(productsOfSeller[sellerAddress][productID].valid, "Product does not exist!"); 

        // Check if buyer's balance is not 0 (the value provided in this function call msg)
        require(msg.value > 0, "Ethers cannot be zero!"); 

        // Identify product instance 
        Product storage productToBuy = productsOfSeller[sellerAddress][productID]; 

        // Checks if buyer's payment is equal to product price
        // require(msg.value == productToBuy.price, "Please send exact amount!"); 

        // Perform the sale 
        // Transfer eth to seller
        (bool sent, bytes memory data) = sellerAddress.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        Product[] storage curBuyerProducts = purchasedProductsOfBuyer[msg.sender];
        uint buyerProductIdx = curBuyerProducts.length;
        curBuyerProducts.push();
        curBuyerProducts[buyerProductIdx] = productToBuy;



        // Publish Purchase event to UI 
        emit ProductSale(msg.sender, sellerAddress, productToBuy.productName, productToBuy.productID, productToBuy.price, block.timestamp, buyerProductIdx); 
    }

    function getBuyerProducts()
    public
    view
    returns (Product[] memory)
    {
        // Verify buyer exists
        require(allBuyers[msg.sender].valid, "Buyer does not exist!");

        return purchasedProductsOfBuyer[msg.sender];
    }

    // Register ID and verify authenticity of account
    function verifyID()
    public
    {
        if (allSellers[msg.sender].valid == true) {
            allSellers[msg.sender].verified = true;
        } 
        else if (allBuyers[msg.sender].valid == true) {
            allBuyers[msg.sender].verified = true;
        }
    }
    
    
    // Review of product - called by buyer
    function buyerReview(uint buyerRating, uint productID, uint buyerProductIdx, address sellerAddress) 
    internal 
    { 
        // Verify whether seller product is in the system 
        require(productsOfSeller[sellerAddress][productID].valid, "Product does not exist!");  

        // Identify product instance 
        // productsOfSeller[sellerAddress][productID]; 

        // Check if buyer has purchased this product before 
        // - conditions to fulfil: product in productsOfSeller has same productID and sellerAddress as the product in purchasedProductsOfBuyer
        require(
            purchasedProductsOfBuyer[msg.sender][buyerProductIdx].sellerAddress == sellerAddress &&
            purchasedProductsOfBuyer[msg.sender][buyerProductIdx].productID == productID,
            "No records of buyer buying this product from this seller."
        ); 


        // Check if buyer has left a review on this product before
        require(purchasedProductsOfBuyer[msg.sender][buyerProductIdx].reviewed == false, "Buyer has already left a review on this product before.");
        
        // IMPLEMENT REP SCORE CALCULATION HERE, then update the product's countReviews and rating
        // msg.sender is still buyer address from purchaseProduct() function!
        
        // Update seller product rating
// TODO!!! CANNOT HAVE DECIMALS OR NEGATIVE NUMBERS!
        productsOfSeller[sellerAddress][productID].rating = productsOfSeller[sellerAddress][productID].rating + 1; //* (allBuyers[msg.sender].buyerRepScore / 100);   // buyerRepScore is from 1 to 100
        // Update buyer rep score since number of reviews increased
        allBuyers[msg.sender].buyerRepScore = allBuyers[msg.sender].buyerRepScore + 1; 
        
        productsOfSeller[sellerAddress][productID].countReviews++;
        purchasedProductsOfBuyer[msg.sender][buyerProductIdx].reviewed == true;
        // Note that the only things necessary to update for seller's Product is rating and countReviews
        // Note that the only things necessary to update for buyer's version of the Product is reviewed bool
        // This is to save gas fees and avoid unnecessary updates to blockchain

        // TODO - CALL REWARD FUNCTION TO REWARD UPON SUCCESSFUL REVIEW

        // Publish Review event to UI 
        emit BuyerReview(productID, sellerAddress, msg.sender, buyerRating, block.timestamp, productsOfSeller[sellerAddress][productID].rating, productsOfSeller[sellerAddress][productID].countReviews);
    }

    // // Seller rewards buyers for leaving review - called by seller
    // function reward(uint productID, address buyerAddress, uint reviewID) 
    // public 
    // payable 
    // { 
    //     // Verify whether product is in the system 
    //     require(allSellers[msg.sender].sellerProducts[productID].valid, "Product does not exist!"); 

    //     // Identify product instance 
    //     Product storage product = allSellers[msg.sender].sellerProducts[productID]; 

    //     // Identify product instance via its product ID, via its IPFS address p = productsOfSeller[productID] 
    //     // Check if buyer has actually bought the product 
    //     require(product.buyers[buyerAddress] == true, "No records of buyer buying this product."); 

    //     // Check if buyer left a review 
    //     require(product.buyerReviews[buyerAddress].valid, "No records of buyer leaving review."); 

    //     // Future TODO - Seller gives review 
    //     //Update mapping for this seller review to the buyer 

    //     // Ensure seller has sent the correct amount
    //     uint finalRewardAmount = allSellers[msg.sender].rewardAmount * allBuyers[buyerAddress].buyerRepScore;   // rewardAmount * buyer's rep score
    //     require(msg.value >= finalRewardAmount, "msg.value not sufficient to pay reward!");

    //     // Reward buyer 
    //     allBuyers[buyerAddress].buyerRewardAmount += finalRewardAmount;

    //     // Future TODO
    //     // Give change back to seller

    //     // Future TODO
    //     // Update buyer's rep score

    //     // Publish Reward event to UI 
    //     emit Reward(buyerAddress, msg.sender, reviewID, allSellers[msg.sender].rewardAmount, block.timestamp);
    // }

    // // TODO
    // function updateRepScore(address buyerAddress)
    // private
    // {
    //     Buyer storage buyer = allBuyers[buyerAddress];
    //     uint oldScore = buyer.buyerRepScore;
    //     // buyer.buyerRepScore = oldScore * 
    // }

    // // Payable functions - called by seller
    // // Sellers withdraw amount they are entitled to
    // function sellerWithdraw()
    // public
    // payable
    // {
    //     uint amountToWithdraw = allSellers[msg.sender].sellerRevenue;
    //     payable(msg.sender).transfer(amountToWithdraw);
    //     allSellers[msg.sender].sellerRevenue = 0;
    // }

    // // Buyers withdraw amount they are entitled to - called by buyer
    // function buyerWithdraw()
    // public
    // payable
    // {
    //     uint amountToWithdraw = allBuyers[msg.sender].buyerRewardAmount;
    //     payable(msg.sender).transfer(amountToWithdraw);
    //     allBuyers[msg.sender].buyerRewardAmount = 0;
    // }

    // Getter functions to interact and test the contract on Goerli testnet
    // function getCountOfSellers()
    // public
    // view
    // returns (uint)
    // {
    //     return countOfSellers;
    // }

}


// contract ERC20Basic{
//     uint public constant tokenPrice = 5; // 1 token for 5 wei
    
//     function buy(uint _amount) external payable {
//         // e.g. the buyer wants 100 tokens, needs to send 500 wei
//         require(msg.value == _amount * tokenPrice, 'Need to send exact amount of wei');
        
//         /*
//          * sends the requested amount of tokens
//          * from this contract address
//          * to the buyer
//          */
//         transfer(msg.sender, _amount);
//     }
    
//     function sell(uint _amount) external {
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