// SPDX-License-Identifier: MIT
pragma solidity>=0.7.0<0.9.0;
contract Vworld{
    struct Lands{
        uint land_id;
        uint price;
        address owner;
        address seller;
        uint256 x_coordinate;
        uint y_coordinate;
        uint area;
        bool forSale;
    }
    Lands[5]  public lands;
    constructor() {
        lands[0]=Lands(0,1 ether,msg.sender,address(0),10,20,200,false);
        lands[1]=Lands(1,1 ether,msg.sender,address(0),10,20,200,false);
        lands[2]=Lands(2,1 ether,msg.sender,address(0),10,20,200,false);
        lands[3]=Lands(3,1 ether,msg.sender,address(0),10,20,200,false);
        lands[4]=Lands(4,1 ether,msg.sender,address(0),10,20,200,false); 
    }

    modifier onlyowner(uint land_id){
        require(msg.sender==lands[land_id].owner,"You are not the owner");
        _;
    }
    event LandOwnersHistory(uint indexed land_Id,address previousowner,address currentowner);
    event ChangedPrice(uint indexed land_Id,uint old_price,uint current_price);
    function SetLandForSale(uint land_id) onlyowner(land_id) public {
        lands[land_id].forSale=true;
    }
    function setLandPrice(uint land_Id,uint _price) public onlyowner(land_Id) {
        uint old_price=lands[land_Id].price;
        lands[land_Id].price=_price;
        emit ChangedPrice(land_Id,old_price,_price);
    }
    function buy(uint _landid) public payable{
        address payable previousowner=payable(lands[_landid].owner);
        require(_landid<=lands.length,"Please Enter Valid Land Id");
        require(lands[_landid].forSale==true,"This land is not available for forSale");
        require(msg.value==lands[_landid].price,"Land Price Must be Paid");
         lands[_landid].seller=previousowner;
         previousowner.transfer(msg.value);
        lands[_landid].owner=msg.sender;
        lands[_landid].forSale=false;
        emit LandOwnersHistory(_landid,previousowner,msg.sender);
    }
}