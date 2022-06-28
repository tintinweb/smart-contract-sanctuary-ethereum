/**
 *Submitted for verification at Etherscan.io on 2022-06-28
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
        uint longtidude;
        uint latidude;
        uint serviceArea;
        uint successPercentage;
        address restaurantOwner;
    }

    uint foodCount=1;

    struct food{
        uint foot_id;
        string name;
        string description;
        uint price;
        bool isActive;
    }
    uint orderCount;
    struct order{
        address  courrierAddress;
        uint orderId;
        uint foodId; //birden fazla sipariş
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
    //fix
    modifier onlyRestaurantOwner{
        require(restaurants[msg.sender].isRegister,'you have not a restaurant');
        _;
    }
    modifier onlyCustomerOwner{
        require(customers[msg.sender].isRegister,'you are not customer');
        _;
    }

    modifier onlyCourrierOwner{
        require(courriers[msg.sender].isRegister, 'you are not courrier');
        _;
    }

    mapping(address => restaurant) public restaurants;
    mapping(address=>mapping(uint=>food)) public foodsOfRestaurant;
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
    event CompleteOrder(address indexed _from, address indexed _to, uint _orderId);
    event getPackage(address indexed _from, uint _orderId);
    

    function createRestaurant(string memory _name, string memory _description)public {
        restaurants[msg.sender].name=_name;
        restaurants[msg.sender].description=_description;
        restaurants[msg.sender].isOpen=true;
        restaurants[msg.sender].isRegister=true;
        restaurants[msg.sender].restaurantOwner=msg.sender;
        emit CreateRestaurant(msg.sender,_name);
    }

    function destroyRestaurant() public onlyRestaurantOwner{
        delete restaurants[msg.sender];
    }

    function addFood(string memory _name,string memory _description,uint _price)public onlyRestaurantOwner{
        foodsOfRestaurant[msg.sender][foodCount].name=_name;
        foodsOfRestaurant[msg.sender][foodCount].description=_description;
        foodsOfRestaurant[msg.sender][foodCount].price=_price*10**18;
        foodsOfRestaurant[msg.sender][foodCount].isActive=true;
        foodCount++;
    } 

    function changeActiveFood(uint _foodId)public onlyRestaurantOwner{
        foodsOfRestaurant[msg.sender][_foodId].isActive=!foodsOfRestaurant[msg.sender][_foodId].isActive;
    }
    function payToCourrier(uint _orderId)public payable{
        require(msg.sender==orders[_orderId].restaurantAddress ,'you are not owner');
        require(msg.value >= orders[_orderId].courrierFee);
        payable(orders[_orderId].courrierAddress).transfer(msg.value);
    }
    function updateOrderForCourrier(uint _orderId,uint _courrierFee)public{
        require(msg.sender==orders[_orderId].customer);
        require(orders[_orderId].isCompleted==true,'order is completed');
        orders[_orderId].isCancelled=true;
        orders[_orderId].courrierFee=_courrierFee;
    }

    function createCustomer(string memory _defaultAddress,string memory _mail) public {
        customers[msg.sender].customerName=msg.sender;
        customers[msg.sender].defaultAddress=_defaultAddress;
        customers[msg.sender].mail=_mail;
        customers[msg.sender].isRegister=true;
    }

    function changeAddress(string memory _defaultAddress)public onlyCustomerOwner{
        customers[msg.sender].defaultAddress=_defaultAddress;
    }

    function createOrder(address _restaurantOwner,uint _foodId,string memory _orderDetail)public payable onlyCustomerOwner {
        require(msg.value==foodsOfRestaurant[_restaurantOwner][_foodId].price,'value must be equal to price of food');
        payable(restaurants[_restaurantOwner].restaurantOwner).transfer(msg.value);
        orders[orderCount].orderId=orderCount;
        orders[orderCount].foodId=_foodId;
        orders[orderCount].orderDetail=_orderDetail;
        orders[orderCount].customer=msg.sender;
        orders[orderCount].restaurantAddress=_restaurantOwner;
        orders[orderCount].isCompleted=false;
        orders[orderCount].isCancelled=false;
        orders[orderCount].time=block.timestamp;
        orderCount++;
    }
    function cancelOrder(uint _orderId)public{
        require(orders[_orderId].customer==msg.sender,'order is not yours');
        require(orders[_orderId].isCompleted==false,'order is completed');
        orders[_orderId].isCancelled=true;
        orders[_orderId].isCompleted=true;
    }

    function refund(uint _orderId)public payable  onlyRestaurantOwner{
        require(foodsOfRestaurant[orders[_orderId].restaurantAddress][orders[_orderId].foodId].price==msg.value);
        require(orders[_orderId].isCancelled==false,'order is not cancelled');
        require(orders[_orderId].restaurantAddress==msg.sender,'order is not yours');
        payable(orders[_orderId].customer).transfer(msg.value);
    }
    function completeOrder(uint _orderId)public{
        require(msg.sender==orders[_orderId].customer);
        require(orders[_orderId].isCompleted==true,'order is completed');
        orders[_orderId].isCancelled=true;
    }
    
    function getpackage(uint _orderId)public{
        require(msg.sender==orders[_orderId].customer);
        require(orders[_orderId].isCompleted==true,'order is completed');
        orders[_orderId].isCancelled=true;
        orders[_orderId].courrierAddress=msg.sender;
    }
}