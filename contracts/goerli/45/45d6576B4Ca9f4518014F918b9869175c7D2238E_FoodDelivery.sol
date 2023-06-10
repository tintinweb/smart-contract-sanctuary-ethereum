// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "AggregatorV3Interface.sol";

contract FoodDelivery {
    struct Item{
        uint256 id;
        string name;
        string description;
        uint256 price;          // price in USD
        bool available;
    }

    struct Restaurant{
        address addr;
        string name;
        string description;
        string physicalAddress;
        Item[] items;
    }

    struct Client {
        address addr;
        string name;
    }

    enum OrderStatus {
        PENDING,                // order submitted by client, but before the restaurant accepts the order
        WAITING_COURIER,        // order ready for courier (after being accepted by restaurant)
        ASSIGNED_COURIER,       // order accepted by a courier
        READY_TO_DELIVER,       // order finished by restaurant, ready to deliver
        DELIVERING,             // order being delivered by the courier
        DELIVERED,              // order delivered, confirmed by client
        CANCELLED               // order was cancelled
    }

    struct Order {
        uint256 id;
        address restaurantAddr;
        string restaurantName;
        string restaurantPhysicalAddress;
        address clientAddr;
        address courierAddr;
        uint256[] itemIndices;
        uint256[] quantities;
        uint256 deliveryFee;        // delivery fee is in GWei
        uint256 totalPrice;         // total price is in GWei
        string deliveryAddress;
        OrderStatus status;
        uint256 maxPreparationTime;     // in seconds
        uint256 maxDeliveryTime;        // in seconds
        uint256 preparationStartTime;   // timestamp
        uint256 deliveryStartTime;      // timestamp
    }

    struct Review {
        uint256 orderId;
        uint256 rating;
        string comment;
    }

    mapping(address => Restaurant) public restaurants;
    mapping(address => Client) public clients;
    mapping(address => uint256[]) public clientsToOrdersMapping;
    mapping(uint256 => Review) public reviews;
    mapping(address => uint256[]) public restaurantToOrdersIds;
    mapping(address => uint256[]) public couriersToOrdersMapping;
    uint256[] public ordersWaitingForCourier;
    Order[] public orders;
    address[] public restaurantsAddr;
    address[] public clientsAddr;
    uint256 numberOfOrders = 0;
    AggregatorV3Interface public ethUsdPriceFeed;

    constructor (address priceFeedAddress) {
        ethUsdPriceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function getAllRestaurants() public view returns (Restaurant[] memory, uint256[] memory) {
        Restaurant[] memory allRestaurants = new Restaurant[](restaurantsAddr.length);
        uint256[] memory reviewsForRestaurants = new uint256[](restaurantsAddr.length);

        for (uint256 i = 0; i < restaurantsAddr.length; i++) {
            address restaurantAddress = restaurantsAddr[i];
            Restaurant storage restaurant = restaurants[restaurantAddress];
            allRestaurants[i] = restaurant;

            reviewsForRestaurants[i] = getAverageRatingForRestaurant(restaurantAddress);
        }

        return (allRestaurants, reviewsForRestaurants);
    }

    function getAllOrdersForClient(address clientAddr) public view returns (Order[] memory) {
        uint256[] memory clientOrderIds = clientsToOrdersMapping[clientAddr];
        Order[] memory clientOrders = new Order[](clientOrderIds.length);

        for (uint256 i = 0; i < clientOrderIds.length; i++) {
            uint256 orderId = clientOrderIds[i];
            clientOrders[i] = orders[orderId];
        }

        return clientOrders;
    }

    function getAllOrdersForRestaurant(address restaurantAddr) public view returns (Order[] memory) {
        uint256[] memory restaurantOrderIds = restaurantToOrdersIds[restaurantAddr];
        Order[] memory restaurantOrders = new Order[](restaurantOrderIds.length);

        for (uint256 i = 0; i < restaurantOrderIds.length; i++) {
            uint256 orderId = restaurantOrderIds[i];
            restaurantOrders[i] = orders[orderId];
        }

        return restaurantOrders;
    }

    function getOrdersForCouriers(address courierAddr) public view returns (Order[] memory) {
        uint256[] memory courierOrderIds = couriersToOrdersMapping[courierAddr];
        Order[] memory courierOrders = new Order[](courierOrderIds.length);

        for (uint256 i = 0; i < courierOrderIds.length; i++) {
            uint256 orderId = courierOrderIds[i];
            courierOrders[i] = orders[orderId];
        }

        return courierOrders;
    }

    function getItemsForRestaurant(address restaurantAddr) public view returns (Item[] memory) {
        Item[] memory items = new Item[](restaurants[restaurantAddr].items.length);

        for (uint256 i = 0; i < items.length; ++i) {
            items[i] = restaurants[restaurantAddr].items[i];
        }

        return items;
    }

    function getNumberOfItemsInMenu(address restaurant) public view returns(uint) {
        return restaurants[restaurant].items.length;
    }

    function getMenuEntryAtIndex(address restaurant, uint index) public view returns(Item memory) {
        return restaurants[restaurant].items[index];
    }

    function getNumberOfRestaurants() public view returns(uint) {
        return restaurantsAddr.length;
    }

    function getNumberOfClients() public view returns(uint) {
        return clientsAddr.length;
    }

    function getNumberOfOrderForClient(address client) public view returns(uint) {
        return clientsToOrdersMapping[client].length;
    }

    function getNumberOfOrderForRestaurant(address restaurant) public view returns(uint) {
        return restaurantToOrdersIds[restaurant].length;
    }

    function getNumberOfOrdersForCourier(address courier) public view returns(uint) {
        return couriersToOrdersMapping[courier].length;
    }

    function getOrdersByStatus(OrderStatus status) public view returns (Order[] memory) {
        uint256 numberOfOrdersWithStatus = 0;
        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].status == status) {
                numberOfOrdersWithStatus++;
            }
        }
        Order[] memory ordersWithStatus = new Order[](numberOfOrdersWithStatus);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].status == status) {
                ordersWithStatus[currentIndex] = orders[i];
                currentIndex++;
            }
        }
        return ordersWithStatus;
    }

    function getNumberOfOrdersWaitingForCourier() public view returns (uint256) {
        return ordersWaitingForCourier.length;
    }

    // Gets the price in GWei
    function getPriceInEth(uint256 usdPrice) public view returns (uint256) {
        (,int256 price,,, ) = ethUsdPriceFeed.latestRoundData();
        uint8 decimals = ethUsdPriceFeed.decimals();
        uint256 cost = (usdPrice * 10 ** (decimals + 18)) / (uint256(price));
        return cost;
    }

    function getOrderItemsAndQuantities(uint256 orderId) public view returns (Item[] memory, uint256[] memory) {
        Order storage order = orders[orderId];
        require(order.id == orderId, "Order with given id does not exist");

        // Get the restaurant for this order
        Restaurant storage restaurant = restaurants[order.restaurantAddr];

        // Initialize an array to store the ordered items
        Item[] memory orderedItems = new Item[](order.itemIndices.length);

        // Loop through the itemIndices array in the order and populate the orderedItems array
        for (uint256 i = 0; i < order.itemIndices.length; i++) {
            uint256 itemIndex = order.itemIndices[i];
            orderedItems[i] = restaurant.items[itemIndex];
        }

        // Return both ordered items and their corresponding quantities
        return (orderedItems, order.quantities);
    }

    function registerRestaurant(string calldata name, string calldata description, string calldata physicalAddress) public {
        Restaurant storage restaurant = restaurants[msg.sender];
        restaurant.addr = msg.sender;
        restaurant.name = name;
        restaurant.description = description;
        restaurant.physicalAddress = physicalAddress;
        restaurantsAddr.push(msg.sender);
    }

    function registerClient(string calldata name) public {
        Client storage client = clients[msg.sender];
        client.addr = msg.sender;
        client.name = name;
        clientsAddr.push(msg.sender);
    }

    function addItem(string calldata name, string calldata description, uint256 price) public returns(uint256) {
        Restaurant storage restaurant = restaurants[msg.sender];
        uint256 id = restaurant.items.length;
        restaurant.items.push(Item({
            id: id,
            name: name,
            description: description,
            price: price,
            available: true
        }));

        return id;
    }

    function updateItem(uint256 id, string calldata name, string calldata description, uint256 price) public returns(uint256) {
        Restaurant storage restaurant = restaurants[msg.sender];
        restaurant.items[id] = Item({
            id: id,
            name: name,
            description: description,
            price: price,
            available: true
        });

        return id;
    }

    function enableItem(uint256 itemId) public {
        Restaurant storage restaurant = restaurants[msg.sender];
        restaurant.items[itemId].available = true;
    }

    function disableItem(uint256 itemId) public {
        Restaurant storage restaurant = restaurants[msg.sender];
        restaurant.items[itemId].available = false;
    }

    function getWeiPriceForOrder(address restaurantAddr, uint256[] calldata itemIds, uint256[] calldata quantities, uint256 deliveryFee) public view returns(uint256, uint256) {
        Restaurant storage restaurant = restaurants[restaurantAddr];

        uint256 totalPrice = 0;
        for (uint256 i = 0; i < itemIds.length; i++) {
            require(itemIds[i] < restaurant.items.length, "Invalid item ID");
            Item storage item = restaurant.items[itemIds[i]];
            totalPrice += getPriceInEth(item.price) * quantities[i];
        }

        uint256 ethDeliveryFee = getPriceInEth(deliveryFee);
        return (totalPrice, ethDeliveryFee);
    }

    function placeOrder(address restaurantAddr, uint256[] calldata itemIds, uint256[] calldata quantities, uint256 deliveryFee, string calldata deliveryAddress) public payable {
        Restaurant storage restaurant = restaurants[restaurantAddr];
        require(restaurant.addr != address(0), "Invalid restaurant address");

        for (uint i = 0; i < itemIds.length; ++i) {
            require(restaurant.items[itemIds[i]].available == true, "Order contains unavailable items...");
        }

        (uint256 totalPrice, uint256 ethDeliveryFee) = getWeiPriceForOrder(restaurantAddr, itemIds, quantities, deliveryFee);
        require(msg.value >= totalPrice + ethDeliveryFee, "Incorrect amount paid");

        Order memory order = Order({
            id: orders.length,
            restaurantAddr: restaurantAddr,
            restaurantName: restaurant.name,
            restaurantPhysicalAddress: restaurant.physicalAddress,
            clientAddr: msg.sender,
            courierAddr: address(0),
            itemIndices: itemIds,
            quantities: quantities,
            deliveryFee: ethDeliveryFee,
            totalPrice: totalPrice,
            deliveryAddress: deliveryAddress,
            status: OrderStatus.PENDING,
            maxPreparationTime: 0,
            maxDeliveryTime: 0,
            preparationStartTime: 0,
            deliveryStartTime: 0
        });

        orders.push(order);
        clientsToOrdersMapping[msg.sender].push(order.id);
        restaurantToOrdersIds[restaurantAddr].push(order.id);
    }

    function acceptOrder(uint256 orderId, uint256 maxPreparationTime) public {
        Order storage order = orders[orderId];
        require(order.id == orderId, "Order with given id does not exist");
        require(order.restaurantAddr == msg.sender, "Only the restaurant for which the order was made can accept it");
        require(order.status == OrderStatus.PENDING, "Can only accept orders for which the status is PENDING");

        order.maxPreparationTime = maxPreparationTime;
        order.preparationStartTime = block.timestamp;
        order.status = OrderStatus.WAITING_COURIER;
        ordersWaitingForCourier.push(orderId);
    }

    function declineOrder(uint256 orderId) public {
        Order storage order = orders[orderId];
        require(order.id == orderId, "Order with given id does not exist");
        require(order.restaurantAddr == msg.sender, "Only the restaurant can decline the order");
        require(order.status == OrderStatus.PENDING, "Order must be pending");

        // refund the client
        address payable clientAddr = payable(order.clientAddr);
        require(clientAddr.send(order.totalPrice + order.deliveryFee), "Failed to refund client");

        order.status = OrderStatus.CANCELLED;
    }

    function increaseDeliveryFee(uint256 orderId) public payable {
        Order storage order = orders[orderId];
        require(order.id == orderId, "Order with given id does not exist");
        require(order.status == OrderStatus.WAITING_COURIER);
        require(order.clientAddr == msg.sender, "Order delivery fee must be increased by the client");

        order.deliveryFee = order.deliveryFee + msg.value;
    }

    function takeOrder(uint256 orderId, uint256 maxDeliveryTime) public {
        Order storage order = orders[orderId];
        require(order.id == orderId, "Order with given id does not exist");
        require(order.status == OrderStatus.WAITING_COURIER, "Order must be in the processing state");
        order.courierAddr = msg.sender;
        order.maxDeliveryTime = maxDeliveryTime;
        order.deliveryStartTime = block.timestamp;
        order.status = OrderStatus.ASSIGNED_COURIER;
        couriersToOrdersMapping[msg.sender].push(order.id);
        removeOrderFromWaitingList(orderId);
    }

    function orderReadyToDeliver(uint256 orderId) public {
        Order storage order = orders[orderId];
        require(order.id == orderId, "Order with given id does not exist");
        require(order.status == OrderStatus.ASSIGNED_COURIER);
        require(order.restaurantAddr == msg.sender, "Order must be marked ready to deliver by the restaurant of the order");

        order.status = OrderStatus.READY_TO_DELIVER;
    }

    function orderDelivering(uint256 orderId) public {
        Order storage order = orders[orderId];
        require(order.id == orderId, "Order with given id does not exist");
        require(order.status == OrderStatus.READY_TO_DELIVER);
        require(order.courierAddr == msg.sender, "Order must be delivered by courier that accepted it");

        order.status = OrderStatus.DELIVERING;
    }

    function orderDelivered(uint256 orderId) public {
        Order storage order = orders[orderId];
        require(order.id == orderId, "Order with given id does not exist");
        require(order.status == OrderStatus.DELIVERING);
        require(order.clientAddr == msg.sender, "Order delivery must be confirmed by client");

        uint256 preparationTime = order.deliveryStartTime - order.preparationStartTime;
        uint256 deliveryTime = block.timestamp - order.deliveryStartTime;
        uint256 totalPayment = order.totalPrice + order.deliveryFee;
        uint256 refundAmount = 0;

        uint256 restaurantRefund = 0;
        uint256 courierRefund = 0;

        uint256 fixedLateFeePercentage = 10; // Fixed late fee percentage (e.g., 10%)

        // Calculate the refund amounts based on delays
        if (preparationTime > order.maxPreparationTime) {
            restaurantRefund = (fixedLateFeePercentage * order.totalPrice) / 100;
        }

        if (deliveryTime > order.maxDeliveryTime) {
            courierRefund = (fixedLateFeePercentage * order.deliveryFee) / 100;
        }

        // Proportional payments to restaurant and courier
        address payable restaurantAddr = payable(order.restaurantAddr);
        address payable courierAddr = payable(order.courierAddr);
        address payable clientAddr = payable(order.clientAddr);
        uint256 restaurantPayment = order.totalPrice - restaurantRefund;
        uint256 courierPayment = order.deliveryFee - courierRefund;
        
        require(restaurantAddr.send(restaurantPayment), "Failed to send payment to restaurant");
        require(courierAddr.send(courierPayment), "Failed to send payment to courier");
        require(clientAddr.send(restaurantRefund + courierRefund), "Failed to send payment to client");

        order.status = OrderStatus.DELIVERED;
    }

    function cancelOrder(uint256 orderId) public {
        Order storage order = orders[orderId];
        require(order.id == orderId, "Order with given id does not exist");
        require(order.clientAddr == msg.sender, "Order must be cancelled by client");
        require(order.status != OrderStatus.DELIVERED && order.status != OrderStatus.CANCELLED, "Order cannot be in DELIVERED or CANCELLED status already");
        
        // refund the client
        address payable clientAddr = payable(order.clientAddr);
        address payable restaurantAddr = payable(order.restaurantAddr);
        if (order.status == OrderStatus.PENDING || order.status == OrderStatus.WAITING_COURIER
            || order.status == OrderStatus.ASSIGNED_COURIER) {      // full refund
            require(clientAddr.send(order.totalPrice + order.deliveryFee), "Failed to refund client");
        } else if (order.status == OrderStatus.READY_TO_DELIVER) {  // partial refund, as the restaurant did finish the order
            require(restaurantAddr.send(order.totalPrice), "Failed to refund restaurant");
            require(clientAddr.send(order.deliveryFee), "Failed to refund client");
        } else {        // no refund for client, order was just being delivered
            address payable courierAddr = payable(order.clientAddr);
            require(restaurantAddr.send(order.totalPrice), "Failed to refund restaurant");
            require(courierAddr.send(order.deliveryFee), "Failed to refund courier");
        }

        order.status = OrderStatus.CANCELLED;
    }

    function placeReview(uint256 orderId, uint256 rating, string calldata comment) public {
        Order storage order = orders[orderId];
        require(order.id == orderId, "Order with given id does not exist");
        require(order.clientAddr == msg.sender, "Only the client who placed the order can leave a review");
        require(order.status == OrderStatus.DELIVERED, "Only delivered orders can be reviewed");

        reviews[orderId] = Review({
            orderId: orderId,
            rating: rating,
            comment: comment
        });
    }

    function getReview(uint256 orderId) public view returns (Review memory) {
        return reviews[orderId];
    }

    function getAverageRatingForRestaurant(address restaurantAddr) public view returns (uint256) {
        uint256 totalRating = 0;
        uint256 numberOfRatings = 0;

        for (uint256 i = 0; i < restaurantToOrdersIds[restaurantAddr].length; i++) {
            uint256 orderId = restaurantToOrdersIds[restaurantAddr][i];
            if (reviews[orderId].orderId == orderId) {
                totalRating += reviews[orderId].rating;
                numberOfRatings++;
            }
        }

        if (numberOfRatings == 0) {
            return 5;
        } else {
            return totalRating / numberOfRatings;
        }
    }

    function removeOrderFromWaitingList(uint256 orderId) internal {
        for (uint256 i = 0; i < ordersWaitingForCourier.length; i++) {
            if (ordersWaitingForCourier[i] == orderId) {
                // Swap the order to remove with the last order in the array, then remove the last order
                ordersWaitingForCourier[i] = ordersWaitingForCourier[ordersWaitingForCourier.length - 1];
                ordersWaitingForCourier.pop();
                break;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}