// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract ShipmentTracking {

        uint256 id;
        address sender;
        address reciver;
        string productContent;
        uint256 price;
        uint256 startTime;
        uint256 temperature;
        uint256 humidity;


        constructor() {
             sender = msg.sender;
             }


    enum packageState {notReady, ready, aborted, ShipmentReceived}
    packageState public state;
    enum violationType {none, tem, hum}
    violationType public Violation;
   

    function creatPackage(uint256 _id, address _reciver, string memory _productContent, uint256 _price, uint256 _temperature, uint256 _humidity) public {
        require(msg.sender ==sender,"the sender only can create package!");
        id = _id;
        reciver = _reciver;
        productContent = _productContent;
        price = _price;
        temperature = _temperature;
        humidity = _humidity;
        state = packageState.ready;
   
    }
   
   function violationOccure(uint _temperature, uint256 _humidity) public   {
       if (_temperature >= temperature) {
           Violation = violationType.tem;
           
       } else if (_humidity >= humidity) {
           Violation = violationType.hum;
         
       } else {
           Violation = violationType.none;
         
       }
   }

   function getViolation() public view returns (string memory) {
       if(Violation == violationType.tem) {
           return "temperature issue!";
       } else if (Violation == violationType.hum) {
           return "humidity issue!";
       } else {
           return "None violation occure.";
       }
       
   }

   function productInfo() public view returns (uint256, address, address, string memory, uint256, uint256, uint256) {
       return (id,msg.sender, reciver, productContent, price, temperature, humidity);
   }

 
}