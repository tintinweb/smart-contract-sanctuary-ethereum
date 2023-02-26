//  SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;
 
contract Store {

    struct Product {
        string name;
        string description;
        
        uint init_amt;
        uint amt;
        uint price;
        uint value_escrow;

        uint deposit_fund;
        uint in_delivery;

        bool cancelled;

        address seller;

        uint total_ratings;
        string[] reviews;
        uint[] ratings;
    }

    enum PurchaseState {Default, Started, Confirmed, Rejected, Cancelled, Finalized, Reviewed}

    uint public numProducts;
    Product[] public products;

    mapping(uint => address[]) internal buyers;
    mapping(uint => mapping(address => string)) internal buyers_ads;
    mapping(uint => mapping(address => PurchaseState)) internal buyerStatus;

    // Seller: Create a new product for sale
    function createProduct (
        address _seller,
        string calldata name,
        string calldata description,
        uint price,
        uint amt
    ) public payable {
        // Ensure that the seller has enough balance to sell
        require(address(msg.sender).balance > price, "Not enough balance to sell");
        // Ensure that the value sent is equal to the price
        require(msg.value == price, "Value must be equal to price");
        // Ensure that the price is bigger than 0
        require(price > 0, "Price must be bigger than 0");
        // Ensure that the amount is bigger than 0
        require(amt > 0, "Amount must be bigger than 0");
        
        // Create a new product
        Product memory newProduct;
        
        // Add information about the new product
        newProduct.name = name;
        newProduct.description = description;
        newProduct.price = price;
        newProduct.value_escrow = price * 2;   
        newProduct.amt = amt;
        newProduct.init_amt = amt;
        // newProduct.seller = address(msg.sender);
        newProduct.seller = _seller;
        newProduct.cancelled = false;
        newProduct.deposit_fund = price;
        newProduct.in_delivery = 0;

        products.push(newProduct);
        numProducts++;
    }

    // Buyer: Buy a product
    function buyProduct(
        uint product_id,
        string calldata delivery_address
    ) public payable {
        // Select a product to buy
        Product storage curProd = products[product_id];

        // Ensure that the buyer has enough balance to buy the product
        require(address(msg.sender).balance > curProd.value_escrow, "Not enough balance to buy");
        // Ensure that the value sent is equal to the value of the escrow
        require(msg.value == curProd.value_escrow, "Value must be equal to the value of the escrow");
        // Ensure that the product is still available
        require(curProd.amt > 0, "Product is out of stock");
        
        // Ensure that the buyer has not already been a buyer of the product
        require(buyerStatus[product_id][address(msg.sender)] == PurchaseState.Default);

        // Increase the deposit fund
        curProd.deposit_fund += msg.value;

        // Set the buyer's start transaction to true
        buyerStatus[product_id][address(msg.sender)] = PurchaseState.Started;
        
        // Decrease the amount of the product available
        curProd.amt --;

        // Add the buyer's address to the buyer_ids array
        buyers[product_id].push(address(msg.sender));
        buyers_ads[product_id][address(msg.sender)] = delivery_address;

    }

    // Seller: Approve purchase for the specified buyer
    function approvePurchase(
        uint product_id,
        address payable buyer
    ) public {
        // Retrieve the specified product from storage
        Product storage curProd = products[product_id];

        // Ensure that only the seller can approve the purchase
        require(curProd.seller == address(msg.sender), "Only the seller can approve the purchase.");
        require(buyerStatus[product_id][buyer] == PurchaseState.Started);
        
        // Increase the amount of products in delivery;
        curProd.in_delivery ++;

        buyerStatus[product_id][buyer] = PurchaseState.Confirmed;
    }

    // Seller: Reject a purchase from the specified buyer
    function rejectPurchase(
        uint product_id,
        address payable buyer
    ) public {
        // Retrieve the specified product from storage
        Product storage curProd = products[product_id];

        // Ensure that only the seller can reject the purchase
        require(curProd.seller == address(msg.sender), "Only the seller can reject the purchase.");
        // Ensure that the buyer has not already been rejected or already purchased the product
        require(buyerStatus[product_id][buyer]  == PurchaseState.Started);

        // Transfer the escrowed funds back to the buyer
        payable(address(buyer)).transfer(curProd.value_escrow);
        
        // Increment the number of avaiable products
        curProd.amt ++;
        // Decrement the deposit fund for the product
        curProd.deposit_fund -= curProd.value_escrow;
        
        buyerStatus[product_id][buyer] = PurchaseState.Rejected; 
    }

    // Buyer: Approve receipt of the specified product
    function approveReceipt(
        uint product_id
    ) public {
        // Retrieve the specified product from storage
        Product storage curProd = products[product_id];

        // Ensure that the buyer has already started the transaction
        require(buyerStatus[product_id][address(msg.sender)] == PurchaseState.Confirmed);
        
        // Transfer the price of the product to the buyer
        payable(address(msg.sender)).transfer(curProd.price);
        // Transfer the price of the product to the seller
        payable(curProd.seller).transfer(curProd.price);

        // Reduce the deposit fund by the escrow value
        curProd.deposit_fund -= curProd.value_escrow;
        
        // Decrease the amount of products in delivery;
        curProd.in_delivery --;

        buyerStatus[product_id][address(msg.sender)] = PurchaseState.Finalized; 

        // If the amount of available products is 0, transfer the price to the seller
        if (curProd.amt == 0 && !curProd.cancelled) {
            payable(curProd.seller).transfer(curProd.price);
            curProd.deposit_fund -= curProd.price;
            curProd.cancelled = true;
        }
    }

    // Buyer: Cancel purchase of the specified product
    function cancelBuy(
        uint product_id
    ) public {
        require(buyerStatus[product_id][address(msg.sender)] == PurchaseState.Started);

        // Retrieve the specified product from storage
        Product storage curProd = products[product_id];

        // Transfer the escrow value back to the buyer
        payable(address(msg.sender)).transfer(curProd.value_escrow);

        // Decrement the deposit fund by the escrow value
        curProd.deposit_fund -= curProd.value_escrow;

        buyerStatus[product_id][address(msg.sender)] = PurchaseState.Cancelled; 

        curProd.amt ++;
    }

    // Seller: stop selling Product
    function stopProduct(
        uint product_id
    ) public {
        // Retrieve the specified product from storage
        Product storage curProd = products[product_id];

        // Ensure that only the seller can delete the product
        require(curProd.seller == address(msg.sender), "Only the seller can stop selling the product.");
        // Ensure that no products are currently in delivery
        require(curProd.in_delivery == 0, "The seller can only stop selling the product when there are no products in delivery");
        // Ensure that the product is not already cancelled
        require(!curProd.cancelled, "The product is already cancelled");
        
        // Mark the product as cancelled
        curProd.cancelled = true;
        // Reset the product's amount
        curProd.amt = 0;

        for (uint i = 0; i < buyers[product_id].length; i++) {
            // Check if the buyer's confirmation is true
            if (buyerStatus[product_id][buyers[product_id][i]] == PurchaseState.Confirmed ||
                buyerStatus[product_id][buyers[product_id][i]] == PurchaseState.Started) {
                // Transfer the buyer's escrow value back to them
                payable(buyers[product_id][i]).transfer(curProd.value_escrow);
                // Decrement the deposit fund by the escrow value
                curProd.deposit_fund -= curProd.value_escrow;
                // Record the rejection of the buyer
                buyerStatus[product_id][buyers[product_id][i]] = PurchaseState.Rejected; 
            }
        }
        // Transfer the sellers's escrow price back to them
        payable(curProd.seller).transfer(curProd.price);
        // Decrement the deposit fund by the product price
        curProd.deposit_fund -= curProd.price;
    }

    // Seller: observe Buyers
    function observeBuyers(
        uint product_id
    ) public view returns (address[] memory) {
        // Return the list of buyers for the specified product
        return buyers[product_id];
    }  

    function getDeliveryAddress(
        uint product_id,
        address buyer
    ) public view returns (string memory) {
        return buyers_ads[product_id][buyer];
    } 

    function getStatus(
        uint product_id,
        address buyer
    ) public view returns (PurchaseState) {
        // Return the list of buyers for the specified product
        return buyerStatus[product_id][buyer];
    }  

    function getAllProducts(
    ) public view returns (Product[] memory) {
        // Retrieve the specified product from storage
        return products;
    }  

    // Buyer: Add rating to product
    function addRating(
        uint product_id, 
        uint rating, 
        string calldata review
    ) public {
        // Retrieve the specified product from storage
        Product storage curProd = products[product_id];
        
        // Ensure that the message sender is not the seller of the product
        require(curProd.seller != address(msg.sender), "The seller cannot add a rating.");
        // Ensure that the message sender has confirmed the receipt for the product
        require(buyerStatus[product_id][address(msg.sender)] == PurchaseState.Finalized);
        // Ensure that the rating provided is between 0 and 5
        require(rating <= 5, "The rating should be between 0 and 5");
        
        // Add the review and rating to the product's storage
        curProd.total_ratings ++;
        curProd.reviews.push(review);
        curProd.ratings.push(rating);

        buyerStatus[product_id][address(msg.sender)] = PurchaseState.Reviewed;
    }
}