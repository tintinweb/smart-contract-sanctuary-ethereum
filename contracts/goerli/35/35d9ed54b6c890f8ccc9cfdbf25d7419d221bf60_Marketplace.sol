/**
 *Submitted for verification at Etherscan.io on 2023-01-17
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

    // CONSTANTS
    uint public VERIFIEDSCORE = 50;
    uint PADDING = 1000;    // This allows us to have 3 decimal places

    uint FORGET = 1;
    uint TOLERANCE = 1; 
    uint NMAX = 10;
    uint NMIN = 1;
    

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
        uint numOfReviewsGiven;
        uint countOfRepScores;
    }

    struct Product { 
        // Attributes
        uint productID;
        string productName;
        address sellerAddress; 
        uint price; 
        bool valid;
        uint countReviews;
        uint latestReviewTimestamp;
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

    // struct Sale {
    //     // Attributes
    //     address saleAddress;
    //     address productID;
    //     address sellerAddress;
    //     address buyerAddress;
    //     uint price;
    //     uint timestamp;
    //     bool valid;
    // }

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
    mapping(address => Buyer) public allBuyers;

    // Maps seller or buyer address to seller or buyer ID, which is the index position in allSellersArr or allBuyersArr
    mapping(address => uint) public sellerID;
    mapping(address => uint) public buyerID;

    // Tracks seller's number of sales
    mapping(address => uint) public numOfSales;

    // Mapping sellerAddress to array of Products
    mapping(address => Product[]) public productsOfSeller; 

    // Mapping buyerAddress to array of Products that they bought
    mapping(address => Product[]) public purchasedProductsOfBuyer;
    

    // ------------------------------------------------- Arrays -------------------------------------------------
    // Arrays in Solidity are a reference type, meaning that they reference existing data. This contrasts with a value type, which passes an independent copy of that value to be used.
    // For e.g. z and y both reference x and therefore either can alter (the third element in) x when f() is called.
    
    // Dynamic memory arrays can be initialized using the new operator. 
    // However, although dynamic, memory arrays can not be resized — required sizes must be determined in advance, or completely copied into new memory arrays to make updates.
    // push() and push(x) and pop(): both only available to storage arrays. Note pop() does not return removed element

    Review[] public allReviewsArr;
    // Sale[] public allSalesArr;
    Seller[] public allSellersArr;
    Buyer[] public allBuyersArr;

    // ------------------------------------------------- Events -------------------------------------------------
    event Upload( 
        uint productID,
        string productName, 
        address sellerAddress
    ); 
    event ProductSale( 
        address buyerAddress, 
        address sellerAddress, 
        string productName,
        uint productID,
        uint price, 
        uint timestamp,
        uint buyerProductIdx
    ); 
    event Reward( 
        address buyerAddress, 
        address sellerAddress, 
        uint price,
        uint timestamp
    ); 
    event BuyerReview(
        uint productID,
        address sellerAddress,
        address buyerAddress,
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
    event Verified(
        string sellerOrBuyer,
        address userAddress
    );


    // ------------------------------------------------- Functions -------------------------------------------------
    // Create a new seller - called by seller
    function createSeller(string memory sellerName, uint sellerRepScore, uint rewardAmount) 
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
        newSeller.sellerRevenue = 0;
        newSeller.valid = true;

        allSellers[msg.sender] = newSeller;

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
        newBuyer.numOfReviewsGiven = 0;
        newBuyer.countOfRepScores = 1;

        allBuyers[msg.sender] = newBuyer;

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
        newProduct.price = price;///(10^9);    //convert to gwei
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
        // require(msg.value * 10^9 == productToBuy.price, "Please send exact amount!"); 

        // Perform the sale 
        // Transfer eth to seller
        (bool sent, ) = sellerAddress.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        // Update curBuyerProducts array
        Product[] storage curBuyerProducts = purchasedProductsOfBuyer[msg.sender];
        uint buyerProductIdx = curBuyerProducts.length;
        curBuyerProducts.push();
        curBuyerProducts[buyerProductIdx] = productToBuy;

        // Update numOfSales
        numOfSales[sellerAddress]++;

        // Publish Purchase event to UI 
        emit ProductSale(msg.sender, sellerAddress, productToBuy.productName, productToBuy.productID, productToBuy.price, block.timestamp, buyerProductIdx); 
    }

    // function getBuyerProducts()
    // public
    // view
    // returns (Product[] memory)
    // {
    //     // Verify buyer exists
    //     require(allBuyers[msg.sender].valid, "Buyer does not exist!");

    //     return purchasedProductsOfBuyer[msg.sender];
    // }

    // Register ID and verify authenticity of account
    function verifyID()
    public
    {   
        require(allSellers[msg.sender].valid == true || allBuyers[msg.sender].valid == true, "Address is not a seller or a buyer");
        require((allSellers[msg.sender].valid == true && allSellers[msg.sender].verified == false) || (allBuyers[msg.sender].valid == true && allBuyers[msg.sender].verified == false), "This account is already verified.");

        string memory sellerOrBuyer;
        if (allSellers[msg.sender].valid == true && allSellers[msg.sender].verified == false) {
            allSellers[msg.sender].verified = true;
            sellerOrBuyer = 'Seller';

            // Update rep score to VERIFIEDSCORE if current score is under VERIFIEDSCORE
            if (allSellers[msg.sender].sellerRepScore < VERIFIEDSCORE) {
                allSellers[msg.sender].sellerRepScore = VERIFIEDSCORE;
            }
            
        } 
        else if (allBuyers[msg.sender].valid == true && allBuyers[msg.sender].verified == false) {
            allBuyers[msg.sender].verified = true;
            sellerOrBuyer = 'Buyer';

            // Update rep score to VERIFIEDSCORE if current score is under VERIFIEDSCORE
            if (allBuyers[msg.sender].buyerRepScore < VERIFIEDSCORE) {
                allBuyers[msg.sender].buyerRepScore = VERIFIEDSCORE;
            }
        }

        emit Verified(sellerOrBuyer, msg.sender);
    }
    
    
    // Review of product - called by buyer
    function buyerReview(uint buyerRating, uint productID, uint buyerProductIdx, address sellerAddress) 
    public 
    { 
        // Verify whether seller product is in the system ››
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

// TODO
        // CALL REP SCORE CALCULATION HERE, then update the product's countReviews and rating
        uint newRepScore = calculateRepScore(msg.sender, buyerRating, productID, sellerAddress);

        // Calculate new product rating
        uint oldRating = productsOfSeller[sellerAddress][productID].rating;
        uint numOfRatings = productsOfSeller[sellerAddress][productID].countReviews;
        uint newRating = ( (oldRating * numOfRatings) + (buyerRating * newRepScore) ) / (numOfRatings + newRepScore);

        // Update seller product rating
        productsOfSeller[sellerAddress][productID].rating = newRating;
        // uint oldRating = productsOfSeller[sellerAddress][productID].rating;
        // uint oldCountReviews = productsOfSeller[sellerAddress][productID].countReviews;
        // productsOfSeller[sellerAddress][productID].rating = ( (oldRating * oldCountReviews) + (buyerRating * allBuyers[msg.sender].buyerRepScore/100) ) / oldCountReviews+1 ; 
        
        // Update buyer rep score 
        allBuyers[msg.sender].buyerRepScore = newRepScore; 
        allBuyers[msg.sender].countOfRepScores++;
        
        // Increment countReviews and reviewed to true 
        // and update timestamp of lastest review of this product by this buyer
        productsOfSeller[sellerAddress][productID].countReviews++;
        purchasedProductsOfBuyer[msg.sender][buyerProductIdx].reviewed = true;
        // purchasedProductsOfBuyer[msg.sender][buyerProductIdx].timestamp = block.timestamp; // current time
        productsOfSeller[sellerAddress][productID].latestReviewTimestamp = block.timestamp;

        // Note that the only things to update for seller's Product is rating and countReviews
        // Note that the only things to update for buyer's version of the Product is reviewed bool
        // This is to save gas fees and avoid unnecessary updates to blockchain

        // TODO - CALL REWARD FUNCTION TO REWARD UPON SUCCESSFUL REVIEW (Cannot do since internal function cannot be payable)


        // Publish Review event to UI 
        emit BuyerReview(productID, sellerAddress, msg.sender, buyerRating, block.timestamp, productsOfSeller[sellerAddress][productID].rating, productsOfSeller[sellerAddress][productID].countReviews);
    }

    // function updateProductRating(uint oldProductRating, uint countReviews, uint buyerRating, uint buyerRepScore) 
    // private
    // pure
    // returns (uint)
    // {
    //     return ((oldProductRating * countReviews) + (buyerRating * buyerRepScore / 100)) / 100 ; 

    // }

    // Seller rewards buyers for leaving review - called by seller
    function reward(address sellerAddress, uint productID, address buyerAddress, uint buyerProductIdx) 
    public 
    payable 
    { 
        // Verify whether product is in the system 
        require(productsOfSeller[sellerAddress][productID].valid, "Product does not exist!"); 

        // Identify product instance 
        // Product storage product = productsOfSeller[sellerAddress][productID]; 

        // Identify product instance via its product ID, via its IPFS address p = productsOfSeller[productID] 
        // Check if buyer has actually bought the product 
        require(purchasedProductsOfBuyer[buyerAddress][buyerProductIdx].valid, "No records of buyer buying this product."); 

        // Check if buyer left a review 
        require(purchasedProductsOfBuyer[buyerAddress][buyerProductIdx].reviewed, "No records of buyer leaving review."); 

        // Future TODO - Seller gives review 
        //Update mapping for this seller review to the buyer 

        // Calculate how much to reward
        uint finalReward = allSellers[sellerAddress].rewardAmount * (allBuyers[buyerAddress].buyerRepScore / 100);

        // Check if msg.value is enough to pay Buyer
        require(msg.value * 10^9 >= finalReward, "msg.value not enough."); 
        
        // Transfer reward amount to buyer 
        (bool sentBuyer, ) = buyerAddress.call{value: finalReward}("");
        require(sentBuyer, "Failed to send Ether to Buyer");

        // Change return to seller
        (bool sentSeller, ) = sellerAddress.call{value: msg.value}("");
        require(sentSeller, "Failed to send remaining Ether to Seller");


        // Future TODO
        // Update buyer's rep score

        // Publish Reward event to UI 
        emit Reward(buyerAddress, msg.sender, finalReward, block.timestamp);
    }

    function minimum(uint256 a, uint256 b) 
    public 
    pure 
    returns (uint) 
    {
        return a <= b ? a : b;
    }

    // TODO
    function calculateRepScore(address buyerAddress, uint buyerRating, uint productID, address sellerAddress)
    public
    view
    returns (uint)
    {
        Buyer storage buyer = allBuyers[buyerAddress];
        uint oldRepScore = buyer.buyerRepScore;
        uint n = buyer.countOfRepScores;

        // frequency factor 
        uint timePrev = productsOfSeller[sellerAddress][productID].latestReviewTimestamp;
        uint timeNow = block.timestamp;
        uint frequencyFactor = FORGET ^ (timePrev - timeNow);
        
        // deviation factor
        uint deviationFactor = TOLERANCE ^ (productsOfSeller[sellerAddress][productID].rating - buyerRating);

        // active factor
        uint N = allBuyers[msg.sender].numOfReviewsGiven;
        uint activeFactor = minimum((N - NMAX)/(NMAX - NMIN), 1);

        // Rep score
        uint incomingRepScore = frequencyFactor * deviationFactor * activeFactor;

        uint newRepScore = (incomingRepScore + (oldRepScore * n)) / (n+1);

        return newRepScore;
    }



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