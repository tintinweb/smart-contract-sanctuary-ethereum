/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity>=0.7.0<0.9.0;
contract LandRecord{
    // contractaddress 0x19c3cafdff6dbe7d75fdf82ff2e601126311f680
    struct Lands{
        uint land_id;
        uint price;
        address buyer;
        address owner;
        address seller;
        bool forSale;
    }
    Lands[5]  public lands;
    constructor() public {
        lands[0]=Lands(0,1 ether,address(0),msg.sender,msg.sender,false);
        lands[1]=Lands(1,1 ether,address(0),msg.sender,msg.sender,false);
        lands[2]=Lands(2,1 ether,address(0),msg.sender,msg.sender,false);
        lands[3]=Lands(3,1 ether,address(0),msg.sender,msg.sender,false);
        lands[4]=Lands(4,1 ether,address(0),msg.sender,msg.sender,false); 
    }

    modifier onlyowner(uint land_id){
        require(msg.sender==lands[land_id].owner,"You are not the owner");
        _;
    }
    event LandOwnersHistory(uint indexed land_Id,address seller,address currentowner);
    event ChangedPrice(uint indexed land_Id,uint old_price,uint current_price);


    function SetLandForSale(uint land_id) onlyowner(land_id) public {
        lands[land_id].forSale=true;
        lands[land_id].seller=msg.sender;
        lands[land_id].buyer=address(0);
    }
    function setLandPrice(uint land_Id,uint _price) public onlyowner(land_Id) {
        uint old_price=lands[land_Id].price;
        lands[land_Id].price=_price;
        emit ChangedPrice(land_Id,old_price,_price);
    }
    function buy(uint _landid) public payable{
        address payable seller=payable(lands[_landid].seller);
        require(_landid<=lands.length,"Please Enter Valid Land Id");
        require(lands[_landid].forSale==true,"This land is not available for Sale");
        require(msg.value==lands[_landid].price,"Land Price Must be Paid");
        seller.transfer(msg.value);
        lands[_landid].buyer=msg.sender;
        lands[_landid].seller=address(0);
        lands[_landid].owner=msg.sender;
        lands[_landid].forSale=false;
        emit LandOwnersHistory(_landid,seller,msg.sender);
    }
    function FetchAvailableLands() public view returns(Lands[] memory ){
        uint currentIndex=0;
        uint unsoldLands=0;
        for(uint i=0;i<lands.length;i++){
            if(lands[i].forSale==true){
                unsoldLands++;

            }
        }
        Lands[] memory items= new Lands[](unsoldLands);
        for(uint i=0;i<lands.length;i++){
            if(lands[i].forSale==true){
                uint currentId=i+1;
                Lands storage currentItem = lands[currentId-1];
                items[currentIndex]=currentItem;
                currentIndex++;
            }
        }
        return items;
    }
    

}