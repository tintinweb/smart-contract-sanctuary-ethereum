// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

//pragma solidity 0.6.0;

contract sellingContract {
    address payable public seller;
    address payable public buyer;

    struct asset {
        address owner;
        string description;
        uint256 price;
        bool sold;
    }

    event purchaseOp(address seller, address buyer, string bought);

    asset public newAsset;

    asset[] public assetList;
    mapping(address => address) public parties;

    // o.6.0 require to set the constructor to public , 0.8.0 doesnt need
    constructor() {
        seller = payable(msg.sender);
    }

    function comparison(string memory string1, string memory string2)
        private
        pure
        returns (bool)
    {
        bool isEqual = keccak256(abi.encodePacked(string1)) ==
            keccak256(abi.encodePacked(string2));
        return isEqual;
    }

    function checkAvalability(string memory _string)
        internal
        view
        returns (bool)
    {
        bool isAvalable = false;
        for (uint256 i = 0; i < assetList.length; i++) {
            if (comparison(_string, assetList[i].description)) {
                isAvalable = assetList[i].sold;
            }
        }
        return isAvalable;
    }

    function setItem(string memory _description, uint256 _price)
        public
        onlySeller
        returns (bool)
    {
        newAsset.description = _description;
        newAsset.price = _price;
        newAsset.sold = false;
        newAsset.owner = seller;
        assetList.push(newAsset);
        return newAsset.sold;
    }

    function purchase(address _buyer, string memory _item)
        public
        payable
        onlyBuyer
        returns (bool)
    {
        buyer = payable(_buyer);
        require(
            (buyer.balance >= 0.1 ether) && (checkAvalability(_item) == false)
        );
        for (uint256 i = 0; i < assetList.length; i++) {
            if (comparison(_item, assetList[i].description)) {
                seller.transfer(assetList[i].price);
                assetList[i].owner = buyer;
                assetList[i].sold = true;
                parties[seller] = buyer;
            }
        }
        emit purchaseOp(seller, buyer, _item);

        return true;
    }

    modifier onlySeller() {
        require(msg.sender == seller);
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender != seller);
        _;
    }
}