/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
contract Logistics {
    ////////Declaration////////
    address Owner ;
    struct package {
        bool isuidgenerated;
        uint itemid;
        string itemname;
        uint orderstatus; // 1=ordered; 2=in-transit ; 3 = delivered; 4=canceled
        address customer ;
        uint ordertime;
        string transitstatus;
        uint price;
        
    }
    struct station{
        address station1;
        uint station1_time;
        address station2;
        uint station2_time;
        address station3;
        uint station3_time;
    }

    struct products{
        string  name ;
        uint price;
        bool isInStore;
       
    }

    mapping (bytes20 => package ) public packageDetails;
    mapping (bytes20 => station ) public stationReport;
    mapping (address => bool ) public stations;
    mapping(uint=>products) public allProcducts;
    event Code(bytes20 uniqueId);
   
   
   
   constructor()  {
        Owner = msg.sender;
        allProcducts[1].name = "ipad";
        allProcducts[1].price = 5;
        allProcducts[1].isInStore=true;

        allProcducts[2].name="iphone";
        allProcducts[2].price=10;
        allProcducts[2].isInStore=true;

        allProcducts[3].name="shoes";
        allProcducts[3].price=15;
        allProcducts[3].isInStore=true;

        allProcducts[4].name="dress";
        allProcducts[4].price=20;
        allProcducts[4].isInStore=true;

        allProcducts[5].name="sock";
        allProcducts[5].price=25;
        allProcducts[5].isInStore=true;
   }
    modifier onlyOwner(){
        require(Owner == msg.sender);
        _;
    }


    
  
    function ManageStation(address _stationAddress) onlyOwner public returns (string memory) {
        if(!stations[_stationAddress]){
            stations[_stationAddress] = true ;
        } else{
            stations[_stationAddress] = false ;
        }
        return "Station is updated";
    }
    function OrderItem(uint _itemid) public payable returns (bytes20){
        require(allProcducts[_itemid].isInStore);
        require(allProcducts[_itemid].price==msg.value);
        bytes20 uniqueId = bytes20(sha256(abi.encodePacked(msg.sender,block.timestamp)));
        emit Code(uniqueId);
        packageDetails[uniqueId].isuidgenerated = true ;
        packageDetails[uniqueId].itemid = _itemid ; 
        packageDetails[uniqueId].itemname = allProcducts[_itemid].name;
        packageDetails[uniqueId].transitstatus = "Your package is ordered and is under processing";
        packageDetails[uniqueId].orderstatus = 1;
        packageDetails[uniqueId].customer = msg.sender ;
        packageDetails[uniqueId].ordertime = block.timestamp ;
        packageDetails[uniqueId].price = msg.value ;
        return uniqueId;
    }

    function CancelOrder(bytes20 _uniqueId) public returns (string memory){
        require(packageDetails[_uniqueId].orderstatus == 1);
        require(packageDetails[_uniqueId].isuidgenerated);
        require(packageDetails[_uniqueId].customer == msg.sender );
        packageDetails[_uniqueId].orderstatus = 4;
        packageDetails[_uniqueId].transitstatus = "Your order has been canceled";
        payable(msg.sender).transfer(packageDetails[_uniqueId].price);
        packageDetails[_uniqueId].price=0;

        return "Your order has been canceled successfully!";
    }

    function Station1Report(bytes20 _uniqueId, string memory _transitStatus) public {
        require(packageDetails[_uniqueId].isuidgenerated);
        require(stations[msg.sender]);
        require(packageDetails[_uniqueId].orderstatus == 1);
       packageDetails[_uniqueId].orderstatus = 2;
       packageDetails[_uniqueId].transitstatus = _transitStatus;

        
        stationReport[_uniqueId].station1 = msg.sender;
        stationReport[_uniqueId].station1_time = block.timestamp;
       
    }
    function Station2Report(bytes20 _uniqueId, string memory _transitStatus) public {
        require(packageDetails[_uniqueId].isuidgenerated);
        require(stations[msg.sender]);
        require(packageDetails[_uniqueId].orderstatus == 2);
       packageDetails[_uniqueId].orderstatus = 2;
       packageDetails[_uniqueId].transitstatus = _transitStatus;


        stationReport[_uniqueId].station2 = msg.sender;
        stationReport[_uniqueId].station2_time = block.timestamp;

    }

    function Station3Report(bytes20 _uniqueId, string memory _transitStatus) public returns(string memory ) {
        require(packageDetails[_uniqueId].isuidgenerated);
        require(stations[msg.sender]);
        require(packageDetails[_uniqueId].orderstatus == 2);
       packageDetails[_uniqueId].orderstatus = 3;
       packageDetails[_uniqueId].transitstatus = _transitStatus;


        stationReport[_uniqueId].station3 = msg.sender;
        stationReport[_uniqueId].station3_time = block.timestamp;

        return "Your package is deliverd";
    }

    function confirmOrder(bytes20 _uniqueId)public returns (string memory){
        require(packageDetails[_uniqueId].isuidgenerated);
        require(packageDetails[_uniqueId].orderstatus == 3);
        require(packageDetails[_uniqueId].customer == msg.sender );
        payable(Owner).transfer(packageDetails[_uniqueId].price);
        packageDetails[_uniqueId].price=0;
        packageDetails[_uniqueId].isuidgenerated = false;
        packageDetails[_uniqueId].customer =address(0);
        return "Your order is confirmed";
    }
}