// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "IPaxReputableApplication.sol";
import "IERC20.sol";

contract PaxSimpleReputationMarket is IPaxReputableApplication {
    uint8 version;

    function getVersion() public view returns(uint8) {
        return version;
    }

    function getAppData() public view returns(string memory) {}

    // Requires no buyer approval to finalize
    struct ItemData {
        uint id;
        address payable seller;
        string itemURI;
        string title;
        address tokenContract; // address(0) = ETH
        uint256 price;
        bool active;
    }

    struct Review {
        uint8 rating; // 0-5
        string text;
    }

    struct TransactionData {
        uint item_id;
        address seller;
        address buyer;
        bool finalized;
        Review buyerReview;
        Review sellerReview;
    }

    // Should I have a global store or should each seller launch their own Market contract?
    ItemData[
        
    ] items;
    TransactionData[] transactions;

    event NewItem(uint indexed temId);
    event Transaction(uint indexed transactionId);

    function listItem(address payable seller, string memory itemURI, string memory title, address tokenContract, uint256 price) public {
        assert(seller != address(0));
        emit NewItem(items.length);
        items.push();
        uint _id = items.length-1;
        items[_id].id = _id;
        items[_id].seller = seller;
        items[_id].itemURI = itemURI;
        items[_id].title = title;
        items[_id].tokenContract = tokenContract;
        items[_id].price = price;
        items[_id].active = true;
    }

    function getItem(uint itemId) public view returns(ItemData memory) {
        return items[itemId];
    }

    function purchaseItem(uint itemId, address buyer) public payable {
        ItemData memory item = items[itemId];
        if (item.tokenContract == address(0)) {
            require(msg.value >= item.price);
            //require() // send ETH to user without reentrancy attk
            require(item.seller.send(msg.value)); 
        } else {
            require(IERC20(item.tokenContract).transferFrom(buyer, item.seller, item.price), "Must pay!"); 
        }
        emit Transaction(transactions.length);
        transactions.push();
        uint _id = transactions.length;
        transactions[_id].seller = item.seller;
        transactions[_id].item_id = itemId;
        transactions[_id].buyer = buyer;
        transactions[_id].finalized = true;
    }

    function reviewSeller(uint _id, uint8 rating, string memory text) public {
        TransactionData storage transaction = transactions[_id];
        require(msg.sender == transaction.buyer);
        require(transaction.buyerReview.rating == 0 && bytes(transaction.buyerReview.text).length == 0); // hasn't been submitted already
        require(rating < 6 && rating > 0);
        transaction.buyerReview.rating = rating;
        transaction.buyerReview.text = text;
    }

    function reviewBuyer(uint _id, uint8 rating, string memory text) public {
        TransactionData storage transaction = transactions[_id];
        require(msg.sender == transaction.seller);
        require(transaction.sellerReview.rating == 0 && bytes(transaction.sellerReview.text).length == 0); // hasn't been submitted already
        require(rating < 6 && rating > 0);
        transaction.sellerReview.rating = rating;
        transaction.sellerReview.text = text;
    }

    function finalizePurchase() public {
        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IPaxReputableApplication {
    function getVersion() external returns(uint8);
    function getAppData() external returns(string memory);
    // function getUserHistory(address _pk) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
	function transfer(address _to, uint256 _amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}