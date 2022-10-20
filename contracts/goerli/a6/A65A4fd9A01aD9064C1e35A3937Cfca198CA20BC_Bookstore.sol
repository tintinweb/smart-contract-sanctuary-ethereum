// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/*
Bookstore owner
1. Upload e-books

Buyer
1. Purchase e-books
2. View e-books

1. 
*/
error UploadBookOnlyForStoreOwner();
error ReadBookOnlyForBookOwner();
error DuplicatePurchaseNotAllowed();

contract Bookstore {
    address payable public immutable storeOwner;
    uint256 public storeBalance;
    uint256[] public bookIds;
    string[] public couponIds;
    string public letters = "abcdefghijklmnopqrstuvwxyz";
    uint randomCounter = 1;
    uint bookIdCounter = 1;
    mapping(uint256 => string) public bookIdsToTitle;
    mapping(uint256 => uint256) public bookIdsToPrice;
    mapping(uint256 => string) public bookIdsToDescription;
    mapping(uint256 => string) public bookIdsToCover;
    mapping(uint256 => string) private bookIdsToBookURI;
    mapping(uint256 => address[]) public bookIdsToOwners;
    mapping(string => uint256) public couponIdsToDiscount;
    mapping(string => uint256) public couponIdsToQuantity;

    modifier onlyStoreOwner() {
        if (msg.sender != storeOwner) {
            revert UploadBookOnlyForStoreOwner();
        }
        _;
    }

    modifier onlyBookOwnerOrAdmin(uint256 _bookIds) {
        if(msg.sender != storeOwner) {
            address[] memory ownerList = bookIdsToOwners[_bookIds];
            bool found = false;
            for (uint i = 0; i < ownerList.length; i++) {
                if (ownerList[i] == msg.sender) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                revert ReadBookOnlyForBookOwner();
            }
        }
        _;
    }

    modifier onlyNotBookOwner(uint256 _bookIds) {
        address[] memory ownerList = bookIdsToOwners[_bookIds];
        bool found = false;
        for (uint i = 0; i < ownerList.length; i++) {
            if (ownerList[i] == msg.sender) {
                found = true;
                break;
            }
        }
        if (found) {
            revert DuplicatePurchaseNotAllowed();
        }
        _;
    }

    event BookPurchased(
        uint256 indexed bookIds,
        address indexed buyer,
        uint256 transactionValue
    );

    event BookUploaded(
        uint256 indexed bookId
    );

    event CouponUploaded(
        string couponId,
        uint256 indexed couponValue,
        uint256 indexed couponQuantity
    );

    event CouponUsed(
        string couponId
    );

    constructor() {
        storeOwner = payable(msg.sender);
    }

    function getAllBooks() public view returns (uint256[] memory) {
        return bookIds;
    }

    function getAllCoupons() public view returns (string[] memory) {
        return couponIds;
    }

    function addCoupon(uint256 _discountAmount, uint256 _couponQuantity) external onlyStoreOwner {
        string memory id = randomString(10);
        couponIds.push(id);
        couponIdsToDiscount[id] = _discountAmount;
        couponIdsToQuantity[id] = _couponQuantity;
        emit CouponUploaded(id, _discountAmount, _couponQuantity);
    }

    function randomString(uint size) private returns(string memory){
        bytes memory randomWord= new bytes(size);
        bytes memory chars = new bytes(26); // 26 possible alphabets, abcde....
        chars="abcdefghijklmnopqrstuvwxyz";
        for (uint i=0;i<size;i++){
            uint randomNumber = random(26);
            randomWord[i]=chars[randomNumber];
        }
        return string(randomWord);
    }

    function random(uint number) private returns(uint){
        randomCounter++;
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender,randomCounter))) % number;
    }

    function uploadBook(string memory _title, uint256 _price, string memory _description, string memory _bookCover, string memory _bookURI) external onlyStoreOwner() {
        uint256 currBookId = bookIdCounter;
        bookIdsToTitle[currBookId] = _title;
        bookIdsToPrice[currBookId] = _price;
        bookIdsToDescription[currBookId] = _description; 
        bookIdsToCover[currBookId] = _bookCover;
        bookIdsToBookURI[currBookId] = _bookURI;
        bookIds.push(currBookId);
        // emit event
        emit BookUploaded(currBookId);
        bookIdCounter++;
    }

    function purchaseBook(uint256 _bookIds, bool _hasCoupon, string memory _couponId) external payable onlyNotBookOwner(_bookIds) {
        // check if early bird discount eligible
        uint256 couponDiscount = 0;
        if (_hasCoupon) {
            uint256 couponQuantity = couponIdsToQuantity[_couponId];
            if(couponQuantity >= 0) {
                couponDiscount = couponIdsToDiscount[_couponId];
                couponIdsToQuantity[_couponId] = couponQuantity - 1;
            }
        }
        uint256 priceAfterDiscount = bookIdsToPrice[_bookIds] - couponDiscount;

        // check payment
        require(msg.value == priceAfterDiscount, "Incorrect payment value");
        bookIdsToOwners[_bookIds].push(msg.sender);
        
        // emit event
        emit BookPurchased(_bookIds, msg.sender, msg.value);
        if (couponDiscount > 0) {
            emit CouponUsed(_couponId);
        }
        storeBalance += msg.value;
    }

    function readBook(uint256 _bookIds) public view onlyBookOwnerOrAdmin(_bookIds) returns (string memory) {
        return (bookIdsToBookURI[_bookIds]);
    }

    function retrieveEarning() external payable onlyStoreOwner {
        (bool sent, ) = payable(storeOwner).call{value: storeBalance}(""); // deposit eth to storeOwner's address
        require(sent, "Earnings withdrawal failed");
        storeBalance = 0;
    }
}