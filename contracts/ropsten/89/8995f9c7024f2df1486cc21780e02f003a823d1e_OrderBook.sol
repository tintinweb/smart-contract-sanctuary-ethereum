// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./SafeMath.sol";

/// @author Ramin Rakhshani
/// @title A simple order book
contract OrderBook {
    using SafeMath for uint256;

    struct Order {
        address maker;
        address makeAsset;
        uint256 makeAmount;
        address taker;
        address takeAsset;
        uint256 takeAmount;
        uint256 salt;
        uint256 startBlock;
        uint256 endBlock;
    }

    address public owner;
    mapping(uint256 => Order) public orders;
    uint256 public lastOrderId;

    event LogMake(
        bytes32 indexed id,
        bytes32 indexed pair,
        address indexed maker,
        address makeAsset,
        address takeAsset,
        uint256 makeAmount,
        uint256 takeAmount,
        uint64 timestamp
    );

    event LogTake(
        bytes32 id,
        bytes32 indexed pair,
        address indexed maker,
        address makeAsset,
        address takeAsset,
        address indexed taker,
        uint256 take_amt,
        uint256 give_amt,
        uint64 timestamp
    );

    event LogCancel(
        bytes32 indexed id,
        bytes32 indexed pair,
        address indexed maker,
        address makeAsset,
        address takeAsset,
        uint256 makeAmount,
        uint256 takeAmount,
        uint64 timestamp
    );

    constructor() {
        owner = msg.sender;
    }

    modifier canCancel(uint256 id) {
        require(isOrderExists(id), "invalid id");
        require(getMaker(id) == msg.sender, "no access");
        _;
    }

    /// @param makeAsset the address of ERC20 assets that want to be sent
    /// @param makeAmount the value of ERC20 asset of `makeAsset`
    /// @param takeAsset the address of ERC20 assets that want to be received
    /// @param takeAmount the value of ERC20 asset of `takeAsset`
    /// @dev create new order and store it in the state variable `orders` and emit 'LogMake' event.
    /// @return id the stored order id.
    function makeOrder(
        address makeAsset,
        uint256 makeAmount,
        address takeAsset,
        uint256 takeAmount
    ) public returns (uint256 id) {
        require(makeAmount > 0, "makeAmount must be greatar than zero");
        require(takeAmount > 0, "takeAmount must be greatar than zero");
        // require(
        //     isContract(makeAsset),
        //     "makeAsset must be contract asset address"
        // );
        // require(
        //     isContract(takeAsset),
        //     "takeAsset must be contract asset address"
        // );

        Order memory order;
        order.makeAsset = makeAsset;
        order.makeAmount = makeAmount;
        order.takeAsset = takeAsset;
        order.takeAmount = takeAmount;

        order.maker = msg.sender;
        order.startBlock = block.number;

        order.salt;
        order.endBlock;
        order.taker;

        //generate last order id
        id = nextId();
        orders[id] = order;
        //set last order Id
        lastOrderId = id;
        return id;
    }

    /// @param id the the address to retrieve data and delete order from `orders`
    /// @dev retrieves the value of the state variable `orders` for event and delete the order from `orders'
    /// @return success the operation is succes or not.
    function cancelOrder(uint256 id)
        public
        canCancel(id)
        returns (bool success)
    {
        Order memory order = orders[id];
        delete orders[id];

        emit LogCancel(
            bytes32(id),
            keccak256(abi.encodePacked(order.makeAsset, order.takeAsset)),
            order.maker,
            order.makeAsset,
            order.takeAsset,
            order.makeAmount,
            order.takeAmount,
            uint64(block.timestamp)
        );

        success = true;
    }

    /// @param maker the address of order maker
    /// @dev retrieves the values of the state variable `orders` for maker
    /// @return openOrders the array of openOrders.
    function getOrders(address maker)
        public
        view
        returns (Order[] memory openOrders)
    {
        // Order[] memory openOrders = new Order[](lastOrderId);
        for (uint256 i = 1; i <= lastOrderId; i++) {
            Order storage order = orders[i];
            if (order.maker == maker) {
                uint256 length = openOrders.length;
                openOrders[length] = order;
            }
        }
        return openOrders;
    }

    /// @param id the value to retrieve data and delete order from `orders`
    /// @dev retrieves the value of the state variable `orders` for getting maker property
    /// @return maker the maker address of order.
    function getMaker(uint256 id) public view returns (address maker) {
        return orders[id].maker;
    }

    /// @param id the value to retrieve data and delete order from `orders`
    /// @dev retrieves the value of the state variable `orders` if exit or not
    /// Return true or false.
    function isOrderExists(uint256 id) public view returns (bool) {
        if (orders[id].startBlock > 0) {
            return true;
        }
        return false;
    }

    /// @dev increment the value of the state variable `lastOrderId`
    /// Return uint256 of next order id
    function nextId() internal returns (uint256) {
        uint256 id = lastOrderId++;
        return id;
    }

    /// @param account the address
    /// @dev This method relies on extcodesize/address.code.length, which returns 0
    /// for contracts in construction, since the code is only stored at the end
    /// of the constructor execution.
    /// Return true or false.
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}