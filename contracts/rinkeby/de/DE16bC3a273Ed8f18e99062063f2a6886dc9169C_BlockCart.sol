/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.14;
contract BlockCart {
    address  public owner;
    string public contractName='BlockCart';
    constructor(){
        owner =msg.sender;
    }

    struct restaurant{
        string name;
        string description;
        bool isOpen;
        bool isRegister;
        uint successWork;
        address restaurantOwner;
    }
    uint restaurantCount=0;
    uint foodCount=0;
    uint orderCount=0;

    struct food{
        uint foot_id;
        string name;
        string description;
        uint price;
        bool isActive;
    }
   
    struct order{
        address  courrierAddress;
        uint ordersAmount;
        uint orderId;
        uint foodId;
        uint restaurantId;
        address restaurantAddress;
        address customer;
        uint courrierFee;
        string orderDetail;
        bool isCompleted;
        bool isCancelled;
        uint time;
    }

    struct customer{
        address customerName;
        string defaultAddress;
        string mail;
        bool isRegister;
    }
    struct courrier{
        address  name ;
        uint totalEarning;
        bool isRegister;
        uint successPercentage;
    }
    
    modifier onlyCustomerOwner{
        require(customers[msg.sender].isRegister,'you are not customer');
        _;
    }

    modifier onlyCourrierOwner{
        require(courriers[msg.sender].isRegister, 'you are not courrier');
        _;
    }

    mapping(uint => restaurant) public restaurants;
    mapping(uint=>mapping(uint=>food)) public foodsOfRestaurant;
    mapping(uint=>order) public orders;
    mapping(address=>customer)public customers;
    mapping(address=>courrier)public courriers;
    
    event CreateRestaurant(address indexed _from, string _name);
    event DestroyRestaurant(address indexed _from);
    event AddFood(address indexed _from, uint _id);
    event CreateCustomer(address indexed _from);
    event CreateOrder(address indexed _from,address indexed _to, uint _orderId,uint _foodId);
    event CancelOrder(address indexed _from,uint _orderId);
    event Refund(address indexed _from, address indexed _to, uint _orderId);
    event CompleteOrder(address indexed _from,  uint _orderId);
    event GetPackage(address indexed _from, uint _orderId);
    event ChangeActiveFood(uint indexed _id,uint _foodId);
    event PayToCourrier(uint indexed _id);
    event UpdateOrderForCourrier(uint indexed _id,uint _fee);
    event ChangeAddress(address indexed _address,string _localAddress);
    

    function createRestaurant(string memory _name, string memory _description)public {
        restaurants[restaurantCount].name=_name;
        restaurants[restaurantCount].description=_description;
        restaurants[restaurantCount].isOpen=true;
        restaurants[restaurantCount].isRegister=true;
        restaurants[restaurantCount].restaurantOwner=msg.sender;
        emit CreateRestaurant(msg.sender,_name);
    }

    function destroyRestaurant(uint _id) public {
        require(msg.sender==restaurants[_id].restaurantOwner);
        delete restaurants[restaurantCount];
        emit DestroyRestaurant(msg.sender);
    }

    function addFood(uint _id,string memory _name,string memory _description,uint _price)public {
        require(msg.sender==restaurants[_id].restaurantOwner);
        foodsOfRestaurant[_id][foodCount].name=_name;
        foodsOfRestaurant[_id][foodCount].description=_description;
        foodsOfRestaurant[_id][foodCount].price=_price;
        foodsOfRestaurant[_id][foodCount].isActive=true;
        foodCount++;
        emit AddFood(msg.sender,foodCount);
    } 

    function changeActiveFood(uint _id,uint _foodId)public {
        require(msg.sender==restaurants[_id].restaurantOwner);
        foodsOfRestaurant[_id][_foodId].isActive=!foodsOfRestaurant[restaurantCount][_foodId].isActive;
        emit ChangeActiveFood(_id,_foodId);
    }
    function payToCourrier(uint _orderId)public payable {
        require(msg.sender==orders[_orderId].restaurantAddress ,'you are not owner');
        require(msg.value >= orders[_orderId].courrierFee);
        payable(orders[_orderId].courrierAddress).transfer(msg.value);
        emit PayToCourrier(_orderId);
    }
    function updateOrderForCourrier(uint _orderId,uint _courrierFee)public{
        require(msg.sender==orders[_orderId].restaurantAddress);
        require(orders[_orderId].isCompleted==false,'order is completed');
        orders[_orderId].isCancelled=true;
        orders[_orderId].courrierFee=_courrierFee;
        emit UpdateOrderForCourrier(_orderId,_courrierFee);
    }

    function createCustomer(string memory _defaultAddress,string memory _mail) public {
        customers[msg.sender].customerName=msg.sender;
        customers[msg.sender].defaultAddress=_defaultAddress;
        customers[msg.sender].mail=_mail;
        customers[msg.sender].isRegister=true;
        emit CreateCustomer(msg.sender);
    }

    function changeAddress(string memory _defaultAddress)public onlyCustomerOwner{
        customers[msg.sender].defaultAddress=_defaultAddress;
        emit ChangeAddress(msg.sender,_defaultAddress);
    }

    function createOrder(uint _restaurantId,uint _foodId,string memory _orderDetail)public payable onlyCustomerOwner {
        require(msg.value==foodsOfRestaurant[_restaurantId][_foodId].price,'value must be equal to price of food');
        require(!foodsOfRestaurant[_restaurantId][_foodId].isActive);
        payable(restaurants[_restaurantId].restaurantOwner).transfer(msg.value);
        orders[orderCount].orderId=orderCount;
        orders[orderCount].foodId=_foodId;
        orders[orderCount].orderDetail=_orderDetail;
        orders[orderCount].customer=msg.sender;
        orders[orderCount].restaurantAddress=restaurants[_restaurantId].restaurantOwner;
        orders[orderCount].isCompleted=false;
        orders[orderCount].isCancelled=false;
        orders[orderCount].time=block.timestamp;
        orders[orderCount].time=msg.value;
        orders[orderCount].restaurantId=_restaurantId;
        orderCount++;
        emit CreateOrder(msg.sender,restaurants[_restaurantId].restaurantOwner,orderCount,_foodId);
    }
    function cancelOrder(uint _orderId)public{
        require(orders[_orderId].customer==msg.sender,'order is not yours');
        require(orders[_orderId].isCompleted==false,'order is completed');
        orders[_orderId].isCancelled=true;
        orders[_orderId].isCompleted=true;
        emit CancelOrder(msg.sender,_orderId);
    }

    function refund(uint _orderId)public payable {  
        require(orders[_orderId].ordersAmount==msg.value);
        require(orders[_orderId].isCancelled==false,'order is not cancelled');
        require(orders[_orderId].restaurantAddress==msg.sender,'order is not yours');
        payable(orders[_orderId].customer).transfer(msg.value);
        emit Refund(msg.sender,orders[_orderId].customer,_orderId);
    }
    function completeOrder(uint _orderId)public{
        require(msg.sender==orders[_orderId].customer);
        require(orders[_orderId].isCompleted,'order is completed');
        orders[_orderId].isCancelled=true;
        restaurants[orders[_orderId].restaurantId].successWork ++;
        emit CompleteOrder(msg.sender,_orderId);
    }
    
    function getpackage(uint _orderId)public{
        require(msg.sender==orders[_orderId].customer);
        require(orders[_orderId].isCompleted==false,'order is completed');
        orders[_orderId].isCancelled=true;
        orders[_orderId].courrierAddress=msg.sender;
        emit GetPackage(msg.sender,_orderId);
    }
}