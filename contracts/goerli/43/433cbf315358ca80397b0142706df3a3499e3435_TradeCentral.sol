// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TradeCentral is ReentrancyGuard {
    //@dev global variables
    uint256 tradeIds;
    address public owner;
    uint256 public totalTrades;
    uint256 public totalUsers;

    //@dev structs
    struct Trade {
        uint256 id;
        address buyer;
        address seller;
        uint256 price;
        string name;
        string description;
        string image;
        bool isSold;
    }

    struct userData {
        string email;
        string name;
        string image;
    }

    mapping(address => userData) public users;
    mapping(uint256 => Trade) public trades;

    //@dev constructor
    constructor() {
        owner = msg.sender;
    }

    function getTotalTrades() public view returns (uint256) {
        return totalTrades;
    }

    function getTotalUsers() public view returns (uint256) {
        return totalUsers;
    }

    //@dev function  create one userr
    function createUser(
        string memory _email,
        string memory _name,
        string memory image
    ) external nonReentrant {
        require(msg.sender != address(0), "Invalid address");
        require(bytes(_email).length > 0, "Invalid email");
        require(bytes(_name).length > 0, "Invalid name");
        require(bytes(image).length > 0, "Invalid image");
        users[msg.sender] = userData(_email, _name, image);
        totalUsers++;
    }

    //@dev function create one trade

    function createTrade(
        uint256 _price,
        string memory _name,
        string memory _description,
        string memory _image
    ) external nonReentrant {
        // require(
        //     bytes(users[msg.sender].email).length == 0,
        //     "User already exist"
        // );
        require(msg.sender != address(0), "Invalid address");
        require(_price > 0, "Invalid price");
        require(bytes(_name).length > 0, "Invalid name");
        require(bytes(_description).length > 0, "Invalid description");
        require(bytes(_image).length > 0, "Invalid image");
        tradeIds++;
        trades[tradeIds] = Trade(
            tradeIds,
            address(0),
            msg.sender,
            _price,
            _name,
            _description,
            _image,
            false
        );
        totalTrades++;
    }

    //@dev function for update profile user

    function updateProfile(
        string memory _email,
        string memory _name,
        string memory _image
    ) external nonReentrant {
        require(
            bytes(users[msg.sender].email).length > 0,
            "User does not exist"
        );
        require(msg.sender != address(0), "Invalid address");
        require(bytes(_email).length > 0, "Invalid email");
        require(bytes(_name).length > 0, "Invalid name");
        require(bytes(_image).length > 0, "Invalid image");
        users[msg.sender].email = _email;
        users[msg.sender].name = _name;
        users[msg.sender].image = _image;
    }

    //@dev function for look trades in the market
    function lookTrades(uint256 _itemId) public view returns (Trade memory) {
      // validate that trade exists
        require(trades[_itemId].id > 0, "Trade does not exist");
        Trade storage _trade = trades[_itemId];
        return _trade;
    }

    // @dev function for look all open trades in the market
    function lookAllTrades() public view returns (Trade[] memory) {
        Trade[] memory _trades = new Trade[](totalTrades);
        uint256 index = 0;
        for (uint256 i = 1; i <= tradeIds; i++) {
            if (trades[i].isSold == false) {
                _trades[index] = trades[i];
                index++;
            }
        }
        return _trades;
    }

    //@dev function for look users in the market
    function lookUsers(address _userAddress) public view returns (userData memory) {
        // validate that user exists
        require(bytes(users[_userAddress].email).length > 0, "User does not exist");
        userData storage _user = users[_userAddress];
        return _user;
    }

    //@dev function for buy one trade
    function buyTrade(uint256 _itemId) public payable nonReentrant {
        require(msg.value == trades[_itemId].price, "Invalid value");
        require(trades[_itemId].isSold == false, "Invalid trade, item sold");
        require(trades[_itemId].seller != address(0), "Invalid seller");
        require(trades[_itemId].seller != msg.sender, "Invalid seller");
        trades[_itemId].buyer = msg.sender;
        trades[_itemId].isSold = true;
        payable(trades[_itemId].seller).transfer(msg.value);
        delete trades[_itemId];
        totalTrades--;
    }

    //@dev function for cancel one trade
    function cancelTrade(uint256 _itemId) public nonReentrant {
        require(msg.sender != address(0), "Invalid address");
        require(trades[_itemId].isSold == false, "Invalid trade, item sold");
        require(trades[_itemId].seller != address(0), "Invalid seller");
        require(trades[_itemId].seller == msg.sender, "Invalid seller");
        delete trades[_itemId];
        totalTrades--;
    }

    //@dev function for withdraw one trade
    function cancelAllTrades() public nonReentrant {
        require(msg.sender != address(0), "Invalid address");
        for (uint256 i = 1; i <= tradeIds; i++) {
            if (trades[i].seller == msg.sender) {
                delete trades[i];
                totalTrades--;
            }
        }
    }
}