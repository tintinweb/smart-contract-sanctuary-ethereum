// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./blockBuy.sol";

contract BlockBuyManager {
    uint256 _blockBuyIDCounter; // auction Id counter
    mapping(uint256 => BlockBuy) public blockBuys; // auctions

    // create an auction
    function createBlockbuy(
        uint256 _endTime,
        uint256 _price,
        string calldata _productName,
        string calldata _productDescription
    ) external returns (bool) {
        require(_price > 0); // direct buy price must be greater than 0
        require(_endTime > 5 minutes); // end time must be greater than 5 minutes (setting it to 5 minutes for testing you can set it to 1 days or anything you would like)

        uint256 blockBuyID = _blockBuyIDCounter; // get the current value of the counter
        _blockBuyIDCounter++; // increment the counter
        BlockBuy blockBuy = new BlockBuy(
            msg.sender,
            _endTime,
            _price,
            _productName,
            _productDescription
        ); // create the auction

        blockBuys[blockBuyID] = blockBuy; // add the auction to the map
        return true;
    }

    // Return a list of all auctions
    function getBlockbuys()
        external
        view
        returns (address[] memory _blockBuys)
    {
        _blockBuys = new address[](_blockBuyIDCounter); // create an array of size equal to the current value of the counter
        for (uint256 i = 0; i < _blockBuyIDCounter; i++) {
            // for each auction
            _blockBuys[i] = address(blockBuys[i]); // add the address of the auction to the array
        }
        return _blockBuys; // return the array
    }

    // Need to edit the this for blockbuy
    // Return the information of each auction address
    function getBlockBuyInfo(address[] calldata _blockbuyList)
        external
        view
        returns (
            string[] memory productName,
            string[] memory productDescription,
            uint256[] memory price,
            address[] memory seller,
            uint256[] memory endTime,
            uint256[] memory blockbuyState
        )
    {
        endTime = new uint256[](_blockbuyList.length); // create an array of size equal to the length of the passed array
        price = new uint256[](_blockbuyList.length); // create an array of size equal to the length of the passed array
        seller = new address[](_blockbuyList.length);
        productName = new string[](_blockbuyList.length);
        productDescription = new string[](_blockbuyList.length);
        blockbuyState = new uint256[](_blockbuyList.length);

        for (uint256 i = 0; i < _blockbuyList.length; i++) {
            // for each auction
            productName[i] = BlockBuy(blockBuys[i]).productName(); // get the direct buy price
            productDescription[i] = BlockBuy(blockBuys[i]).productDescription(); // get the owner of the auction
            price[i] = BlockBuy(blockBuys[i]).price(); // get the highest bid
            seller[i] = BlockBuy(blockBuys[i]).seller(); // get the token id
            endTime[i] = BlockBuy(blockBuys[i]).endTime(); // get the end time
            blockbuyState[i] = uint256(
                BlockBuy(blockBuys[i]).getAuctionState()
            ); // get the auction state
        }

        return (
            // return the arrays
            productName,
            productDescription,
            price,
            seller,
            endTime,
            blockbuyState
        );
    }
}