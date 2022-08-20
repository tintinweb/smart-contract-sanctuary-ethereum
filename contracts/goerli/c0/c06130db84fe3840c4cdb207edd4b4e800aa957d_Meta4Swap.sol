/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
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

// File: Meta4Swap.sol


pragma solidity ^0.8.7;


interface Meta4SwapToken {
    function mintReward(address _receiver, uint256 _rewardRate)
        external
        returns (bool);

    function balanceOf(address _address) external returns (uint256);
}

//deploy this third

contract Meta4Swap {
    //business logic
    uint256 public orderCount;
    uint256 public itemCount;
    uint256 public marketplaceFee; //2.5 == 250
    
    //admin
    address public admin;
    address public dao;
    address public m4sToken;
    address public priceFeed;

    //rewards
    uint256 public buyerReward; // amount
    uint256 public sellerReward; // amount
    uint256 public daoReward; // dao
    uint256 public minFee; // the minimum order size to earn rewards
    bool public rewardsLive;

    struct Item {
        uint256 id;
        string metadata;
        bool isLive;
        uint256 price;
        address owner;
        uint256 serviceType;
    }

    struct Order {
        uint256 id;
        uint256 itemId;

        uint256 orderTotal;
        uint256 created;
        uint256 fee;
   
        uint256 itemPrice;
        uint256 chainLinkPrice;

        uint8 buyerState;
        uint8 sellerState;

        bool isLive;
        address buyer;
        address seller;
     }

    struct Dispute {
        string buyerResponse;
        string sellerResponse;
        uint256 created;
        bool isLive;
    }

    struct Profile {
        uint256 cancelled;
        uint256 completed;
        uint256 disputes;
    }
    
    mapping(uint256 => Item) public itemInfo; // itemId to Item struct mapping
    mapping(uint256 => Order) public orderInfo; // orderId to Order struct mapping
    mapping(address => mapping(uint256 => bool)) public offerInfo; //offers per item
    
    mapping(uint256 => Dispute) public disputeInfo; //orderId to Dispute struct mapping

    mapping(address => Profile) public userProfile; //user profile mapping
    
    mapping(address => mapping(uint256 => bool)) public ratingCheck; //check to prevent duplicate ratings

    constructor(address _dao, address _m4sToken, address _priceFeed) {
        marketplaceFee = 250;
        minFee = 0;
        buyerReward = 1 ether;
        sellerReward = 1 ether;
        daoReward = 1 ether;
        admin = msg.sender;
        rewardsLive = true;
        dao = _dao;
        m4sToken = _m4sToken;
        priceFeed = _priceFeed;
    }

    event ItemCreated(
        uint256 itemId,
        address creator,
        string metadata,
        uint256 itemType
    );
    event ItemUpdated(
        uint256 itemId
    );

    event OrderCreated(
        uint256 orderId,
        uint256 itemId,
        uint256 price,
        uint256 serviceType,
        address buyer,
        address seller
    );

    event OrderUpdated(
        uint256 orderId
    );

    event OfferCreated(
        uint256 itemId,
        address worker
    );

    event DisputeCreated(uint256 orderId);
    event DisputeUpdated(uint256 orderId);

    modifier onlyCounterpart(uint256 _orderId) {
        require(
            orderInfo[_orderId].buyer == msg.sender ||
                orderInfo[_orderId].seller == msg.sender,
            "Not authorized. Buyer or Seller only."
        );
        _;
    }

    function create(
        string memory _metadata,
        bool _state,
        uint256 _price,
        uint256 _serviceType
    ) public returns (uint256) {
        itemCount++;
        Item memory _item;
        _item.id = itemCount;
        _item.metadata = _metadata;
        _item.isLive = _state;
        _item.price = _price;
        _item.owner = msg.sender;
        _item.serviceType = _serviceType;

        itemInfo[_item.id] = _item;

        emit ItemCreated(
            _item.id,
            _item.owner,
            _item.metadata,
            _item.serviceType
        );

        return _item.id;
    }

    function buy(uint256 _itemId)
        public
        payable
        returns (uint256)
    {
        require(
            itemInfo[_itemId].isLive == true,
            "Item not for sale or doesn't exist."
        );

        orderCount++;
        Order memory _order;

        _order.chainLinkPrice = uint256(getLatestPrice());
        uint256 orderTotal = ((itemInfo[_itemId].price / _order.chainLinkPrice) *
            10**8);
        uint256 orderFee = (marketplaceFee * orderTotal) / 10000;
        require(msg.value >= orderTotal, "Amount paid is less than total");

        _order.id = orderCount;
        _order.itemId = _itemId;
        _order.itemPrice = itemInfo[_itemId].price;
        _order.orderTotal = orderTotal;
        _order.fee = orderFee;
        _order.isLive = true;
        _order.created = block.number;
        _order.buyer = msg.sender;
        _order.seller = itemInfo[_itemId].owner;
        
        orderInfo[_order.id] = _order;

        if (msg.value > orderTotal) {
            //send refund back to the user
            (bool sent, bytes memory data) = msg.sender.call{
                value: (msg.value - orderTotal)
            }("");
            data;
            require(sent, "Failed to Send Ether");
        }

        emit OrderCreated(
            _order.id,
            _order.itemId,
            _order.orderTotal,
            itemInfo[_itemId].serviceType,
            _order.buyer,
            _order.seller
        );
        return _order.id;
    }

    function offer(uint256 _itemId) public {
        require(itemInfo[_itemId].isLive==true, "Not available");
        require(offerInfo[msg.sender][_itemId]==false, "User already made offer");

        offerInfo[msg.sender][_itemId]=true;

        emit OfferCreated(
            _itemId,
            msg.sender
        );

    }

    function acceptOffer(uint _itemId, address _worker) public payable returns (uint256) {
        require(msg.sender == itemInfo[_itemId].owner, "Only item owner can accept offer");
        require(offerInfo[_worker][_itemId]==true, "Can only accept offers from workers who offered");

        orderCount++;
        Order memory _order;

        _order.chainLinkPrice = uint256(getLatestPrice());
        uint256 orderTotal = ((itemInfo[_itemId].price / _order.chainLinkPrice) *
            10**8);
        uint256 orderFee = (marketplaceFee * orderTotal) / 10000;
        require(msg.value >= orderTotal, "Amount paid is less than total");

        _order.id = orderCount;
        _order.itemId = _itemId;
        _order.itemPrice = itemInfo[_itemId].price;
        _order.orderTotal = orderTotal;
        _order.fee = orderFee;
        _order.isLive = true;
        _order.created = block.number;
        _order.buyer = msg.sender;
        _order.seller = _worker;
        
        orderInfo[_order.id] = _order;

        if (msg.value > orderTotal) {
            //send refund back to the user
            (bool sent, bytes memory data) = msg.sender.call{
                value: (msg.value - orderTotal)
            }("");
            data;
            require(sent, "Failed to Send Ether");
        }

        emit OrderCreated(
            _order.id,
            _order.itemId,
            _order.orderTotal,
            itemInfo[_itemId].serviceType,
            _order.buyer,
            _order.seller
        );
        return _order.id;

    }

    function complete(uint256 _orderId) public onlyCounterpart(_orderId) {
        require(orderInfo[_orderId].isLive == true, "Order isn't active");

        if (
            msg.sender == orderInfo[_orderId].buyer &&
            msg.sender == orderInfo[_orderId].seller
        ) {
            orderInfo[_orderId].buyerState = 1;
            orderInfo[_orderId].sellerState = 1;
        } else if (msg.sender == orderInfo[_orderId].buyer) {
            orderInfo[_orderId].buyerState = 1;
        } else if (msg.sender == orderInfo[_orderId].seller) {
            orderInfo[_orderId].sellerState = 1;
        }

        if (
            orderInfo[_orderId].buyerState == 1 &&
            orderInfo[_orderId].sellerState == 1
        ) {
            orderInfo[_orderId].isLive = false;
            //pay seller
            (bool sent, bytes memory data) = orderInfo[_orderId].seller.call{
                value: (orderInfo[_orderId].orderTotal - orderInfo[_orderId].fee)
            }("");
            data;
            require(sent, "Failed to Send Ether");
            //collect fee
            _transferEarnings(orderInfo[_orderId].fee);
            //update buyer
            userProfile[orderInfo[_orderId].buyer].completed += 1;
            //update seller
            userProfile[orderInfo[_orderId].seller].completed += 1;
            //pay rewards
            if (rewardsLive && orderInfo[_orderId].fee >= minFee) {
                Meta4SwapToken(m4sToken).mintReward(
                    orderInfo[_orderId].buyer,
                    buyerReward
                );
                Meta4SwapToken(m4sToken).mintReward(
                    orderInfo[_orderId].seller,
                    sellerReward
                );
                Meta4SwapToken(m4sToken).mintReward(admin, daoReward);
            }
        }

        emit OrderUpdated(_orderId);
    }

    function cancel(uint256 _orderId) public {
        require(
            msg.sender == orderInfo[_orderId].seller,
            "Only seller can cancel"
        );
        require(orderInfo[_orderId].isLive == true, "Order isn't active");
        orderInfo[_orderId].sellerState = 2;
        orderInfo[_orderId].buyerState = 2;
        orderInfo[_orderId].isLive = false;

        userProfile[orderInfo[_orderId].seller].cancelled += 1;

        (bool sent, bytes memory data) = orderInfo[_orderId].buyer.call{
            value: (orderInfo[_orderId].orderTotal)
        }("");
        data;
        require(sent, "Failed to Send Ether");

        orderInfo[_orderId].fee = 0;

        emit OrderUpdated(_orderId);
    }

    //disputes

    function dispute(uint256 _orderId) public onlyCounterpart(_orderId) {
        require(orderInfo[_orderId].isLive == true, "Order isn't active");
        orderInfo[_orderId].sellerState = 3;
        orderInfo[_orderId].buyerState = 3;
        orderInfo[_orderId].isLive = false;

        Dispute memory _dispute;
        _dispute.created = block.number;
        _dispute.isLive = true;

        disputeInfo[_orderId] = _dispute;

        emit DisputeCreated(_orderId);
    }

    function updateDispute(uint256 _orderId, string memory _ipfsHash)
        public
        onlyCounterpart(_orderId)
    {
        require(disputeInfo[_orderId].isLive == true, "Dispute isn't live");
        if (msg.sender == orderInfo[_orderId].buyer) {
            disputeInfo[_orderId].buyerResponse = _ipfsHash;
        } else if (msg.sender == orderInfo[_orderId].seller) {
            disputeInfo[_orderId].sellerResponse = _ipfsHash;
        }

        emit DisputeUpdated(_orderId);
    }


    function resolve(uint256 _orderId, address _winner) public {
        require(
            disputeInfo[_orderId].isLive == true,
            "Dispute isn't live or is already resolved."
        );
        require(msg.sender==admin, "Only DAO address can resolve disputes");

        if (_winner==orderInfo[_orderId].buyer) {
            //transfer money back to buyer
            (bool sent, bytes memory data) = orderInfo[_orderId].buyer.call{
                value: orderInfo[_orderId].orderTotal
            }("");
            data;
            require(sent, "Failed to Send Ether");
            orderInfo[_orderId].fee = 0;
        } else if (_winner==orderInfo[_orderId].seller) {
            //transfer money to selller
            (bool sent, bytes memory data) = orderInfo[_orderId].seller.call{
                value: (orderInfo[_orderId].orderTotal - orderInfo[_orderId].fee)
            }("");
            data;
            require(sent, "Failed to Send Ether");
            _transferEarnings(orderInfo[_orderId].fee);

        }

        orderInfo[_orderId].sellerState = 4;
        orderInfo[_orderId].buyerState = 4;

        userProfile[orderInfo[_orderId].buyer].disputes +=1;
        userProfile[orderInfo[_orderId].seller].disputes +=1;

        disputeInfo[_orderId].isLive = false;

        emit DisputeUpdated(_orderId);
    }

    //DAO controls
    function updateRules(uint256 _variable, uint256 _value)
        public
        returns (bool)
    {
        require(dao == msg.sender);
        if (_variable == 0) {
            //edit fee
            marketplaceFee = _value;
        } 
         else if (_variable == 1) {
            //edit minFee
            minFee = _value;
        } 

        return true;
    }

    //Admin controls
    function updateAddress(uint256 _value, address _newAddress) public {
        require(msg.sender == admin, "Only company can change address");
        if (_value == 0) {
            //DAO Address
            dao = _newAddress;
        } else if (_value == 1) {
            //Token Address
            admin = _newAddress;
        }else if (_value == 2) {
            //Token Address
            m4sToken = _newAddress;
        } else if (_value == 3) {
            //Price Feed Address
            priceFeed = _newAddress;
        }
    }

    function updateRewardsisLive(bool _state) public {
        require(
            msg.sender == admin,
            "Only company can update rewards status"
        );
        rewardsLive = _state;
    }

    //edit Item
    function editPrice(uint256 _itemId, uint256 _value) public {
        require(
            msg.sender == itemInfo[_itemId].owner,
            "Only item owner can edit"
        );

        itemInfo[_itemId].price = _value;

        emit ItemUpdated(_itemId);
    }

    function editMetadata(uint256 _itemId, string memory _metadata) public {
        require(
            msg.sender == itemInfo[_itemId].owner,
            "Only item owner can edit"
        );

        itemInfo[_itemId].metadata = _metadata;

        emit ItemUpdated(_itemId);
    }

    function editState(uint256 _itemId, bool _isLive) public {
        require(
            msg.sender == itemInfo[_itemId].owner,
            "Only item owner can edit"
        );

        itemInfo[_itemId].isLive = _isLive;

        emit ItemUpdated(_itemId);
    }

    //internal
    function _transferEarnings(uint256 _amount) internal {
        (bool sent, bytes memory data) = dao.call{value: _amount}("");
        data;
        require(sent, "Failed to Send Ether");
    }

    //get Chain Link Price
    function getLatestPrice() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = AggregatorV3Interface(priceFeed).latestRoundData();
        // avax main net 0x0A77230d17318075983913bC2145DB16C7366156
        //avax test net 0x5498BB86BC934c8D34FDA08E81D444153d0D06aD
        return price;
    }
}