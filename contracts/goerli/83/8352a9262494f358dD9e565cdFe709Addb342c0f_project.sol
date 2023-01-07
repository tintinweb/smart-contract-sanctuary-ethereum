/**
 *Submitted for verification at Etherscan.io on 2023-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.4;
contract project {
    
   address payable public owner;
   
   constructor() public {
     owner=msg.sender;
    }

     uint id;
     uint purchaseId;

   struct seller {
     string name;
     address addr;
     uint bankGuaraantee;
     bool bgPaid;
     }

     struct product{
        string productId;
        string productName;
        string Category;
        uint price;
        string description;
        address payable seller;
        bool isActive;
        
           }

    struct ordersPlaced {
        string productId;
        uint purchaseId;
        address orderedBy;
           }

    struct sellerShipment {
        string productId;
        uint purchaseId;
        string shipmentStatus;
        string deliveryAddress;
        address  payable orderedBy;
        bool isActive;
        bool isCanceled;
            }

    struct user{
        string name;
        string email;
        string deliveryAddress;
        bool isCreated;
           }

    struct orders{
        string productId;
        string orderStatus;
        uint purchaseId;
        string shipmentStatus;
            }

  mapping(address=> seller) public sellers;
  mapping (string => product) products;
  product[] public allProducts;
  mapping (address=> ordersPlaced[]) sellerOrders;
  mapping (address=> mapping(uint=>sellerShipment))sellerShipments;
  mapping (address=> user) users;
  mapping (address=>orders[]) userOrders;

 
 //ลงทะเบียนเป็นผู้ขายและชำระหลักประกันธนาคารคงที่ 5 ETH
function sellerSignUp(string memory _name) public payable{
        require(!sellers[msg.sender].bgPaid, "You are Already Registered"); //ตรวจสอบว่าผู้ขายลงทะเบียนแล้วหรือไม่ หากลงทะเบียนแล้ว เงื่อนไขจะเป็นเท็จและกลับสู่สถานะเริ่มต้น
        require(msg.value==3 ether, "Bank Guarantee of 3 ETH Required"); //ตรวจสอบว่า msg.value พร้อมกับฟังก์ชันมีค่าเท่ากับ 5ETH หรือไม่ ถ้าไม่ มันจะเปลี่ยนกลับไปสู่สถานะเริ่มต้น
        owner.transfer(msg.value);
        sellers[msg.sender].name= _name;
        sellers[msg.sender].addr= msg.sender;
        sellers[msg.sender].bankGuaraantee = msg.value;
        sellers[msg.sender].bgPaid=true;
             }

//สร้างบัญชี         
function createAccount(string memory _name, string memory _email, string memory _deliveryAddress) public {
        
       users[msg.sender].name= _name;
       users[msg.sender].email= _email;
       users[msg.sender].deliveryAddress= _deliveryAddress;
       users[msg.sender].isCreated= true;
             }

//ซื้อสินค้า
function buyProduct(string memory _productId)  public payable {
        
       require(msg.value == products[_productId].price, "Value Must be Equal to Price of Product");//เพื่อตรวจสอบว่าผู้ขายชำระหนังสือค้ำประกันจากธนาคารหรือไม่
       require( users[msg.sender].isCreated, "You Must Be Registered to Buy");
        
       products[_productId].seller.transfer(msg.value);
        
       purchaseId = id++;
       orders memory order = orders(_productId,  "Order Placed With Seller",purchaseId, sellerShipments[products[_productId].seller][purchaseId].shipmentStatus);
       userOrders[msg.sender].push(order);
       ordersPlaced memory ord = ordersPlaced(_productId, purchaseId,msg.sender);
       sellerOrders[products[_productId].seller].push(ord);
        
       sellerShipments[products[_productId].seller][purchaseId].productId=_productId;
       sellerShipments[products[_productId].seller][purchaseId].orderedBy=   msg.sender;
       sellerShipments[products[_productId].seller][purchaseId].purchaseId= purchaseId;
       sellerShipments[products[_productId].seller][purchaseId].deliveryAddress = users[msg.sender].deliveryAddress;
       sellerShipments[products[_productId].seller][purchaseId].isActive= true;
              }

//ลงรายการสินค้าพร้อมรายละเอียดที่จำเป็นทั้งหมด
function addProduct(string memory _productId, string memory _productName, string memory _category, uint _price, string memory _description) public {
       require(sellers[msg.sender].bgPaid,"You are not Registered as Seller");//เพื่อตรวจสอบว่าผู้ขายชำระหนังสือค้ำประกันจากธนาคารหรือไม่   
       require(!products[_productId].isActive, "Product With this Id is already Active. Use other UniqueId");//เพื่อตรวจสอบว่าสินค้าที่มี productId เดียวกันทำงานอยู่หรือไม่
       
       
       product memory product = product(_productId, _productName, _category, _price, _description, msg.sender, true);  
       products[_productId].productId= _productId;
       products[_productId].productName= _productName;   
       products[_productId].Category= _category;   
       products[_productId].description= _description;   
       products[_productId].price= _price;   
       products[_productId].seller= msg.sender; 
       products[_productId].isActive = true;
       allProducts.push(product);
          
                     }
//ยกเลิกออเดอร์
function cancelOrder(string memory _productId, uint _purchaseId)  public payable {
      require(sellerShipments[products[_productId].seller][_purchaseId].orderedBy==msg.sender, "Aww Crap.. You are not Authorized to This Product PurchaseId");
      require (sellerShipments[products[_productId].seller][purchaseId].isActive, "Aww crap..You Already Canceled This order"); 
    
      sellerShipments[products[_productId].seller][_purchaseId].shipmentStatus= "Order Canceled By Buyer, Payment will Be  Refunded";
      sellerShipments[products[_productId].seller][_purchaseId].isCanceled= true; 
      sellerShipments[products[_productId].seller][_purchaseId].isActive= false;
             }

//จัดส่งสินค้าและอัพเดทรายละเอียดการจัดส่ง
function updateShipment(uint _purchaseId, string memory _shipmentDetails) public {
      require(sellerShipments[msg.sender][_purchaseId].isActive, "Order is either inActive or cancelled");
        
      sellerShipments[msg.sender][_purchaseId].shipmentStatus= _shipmentDetails;
         }

//คืนเงินคำสั่งซื้อที่ถูกยกเลิก
function refund(string memory _productId, uint _purchaseId)public payable {
      require (sellerShipments[msg.sender][_purchaseId].isCanceled, "Order is not Yet Cancelled"); 
      require (!sellerShipments[products[_productId].seller][purchaseId].isActive,"Order is Active and not yet Cancelled");        
      require(msg.value==products[_productId].price,"Value Must be Equal to Product Price");
      sellerShipments[msg.sender][_purchaseId].orderedBy.transfer(msg.value);
      sellerShipments[products[_productId].seller][_purchaseId].shipmentStatus= "Order Canceled By Buyer, Payment Refunded";
                    
             }

//ดูรายการที่สั่งสินค้า
function myOrders (uint _index) public view returns(string memory, string memory, uint, string memory) {                
      return(userOrders[msg.sender][_index].productId, userOrders[msg.sender][_index].orderStatus, userOrders[msg.sender][_index].purchaseId, sellerShipments[products[userOrders[msg.sender][_index].productId].seller][userOrders[msg.sender][_index].purchaseId].shipmentStatus);                 
              }


//ติดตามคำสั่งซื้อที่ผู้ซื้อวางไว้
function getOrdersPlaced(uint _index) public view returns(string memory, uint, address, string memory) {
      return(sellerOrders[msg.sender][_index].productId, sellerOrders[msg.sender][_index].purchaseId, sellerOrders[msg.sender][_index].orderedBy, sellerShipments[msg.sender][sellerOrders[msg.sender][_index].purchaseId].shipmentStatus);
              }

//รายละเอียดการจัดส่ง
function getShipmentDetails(uint _purchaseId) public view returns(string memory,string memory,address,string memory) {
        
      return(sellerShipments[msg.sender][_purchaseId].productId, sellerShipments[msg.sender][_purchaseId].shipmentStatus, sellerShipments[msg.sender][_purchaseId].orderedBy,sellerShipments[msg.sender][_purchaseId].deliveryAddress);
             }
    

}