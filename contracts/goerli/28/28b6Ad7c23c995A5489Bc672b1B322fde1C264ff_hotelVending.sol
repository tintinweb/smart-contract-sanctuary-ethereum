// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Strings.sol";

contract hotelVending{
    address admin;
    //state of room
    enum state{vacant,occupied}
    //room details
    struct room{
        state status;
        string key;
        uint256 price;
        address owner;
    }
    //room list
    mapping(uint256 => room) roomlist;

    constructor(){
        //set admin to further checks
        admin = msg.sender;
    }

    function checkroom(uint256 _roomno) public view returns(string memory r){
        require(keccak256(abi.encodePacked(roomlist[_roomno].key)) != keccak256(abi.encodePacked("")),"Room does not exist");
        if(roomlist[_roomno].status  == state.occupied){
            return "occupied";
        }
        else if(roomlist[_roomno].status  == state.vacant){
            return string(abi.encodePacked("The room is vacant and price is: ",(roomlist[_roomno].price)," ether"));
        }
    }

    function allocate_room(uint256 _roomno) public payable{
        require(keccak256(abi.encodePacked(roomlist[_roomno].key)) != keccak256(abi.encodePacked("")),"Room does not exist");
        require(msg.value<=(roomlist[_roomno].price*1e18),"Not sufficient funds provided");
        require(msg.value>=(roomlist[_roomno].price*1e18),"Not sufficient funds provided");
        require(roomlist[_roomno].status!=state.occupied,"Room is already occupied");
        roomlist[_roomno].owner = msg.sender;
        roomlist[_roomno].status = state.occupied;

    }
    function createroom(uint256 _roomno,string memory _key,uint256 _price)  public{
        require(keccak256(abi.encodePacked(_key)) != keccak256(abi.encodePacked("")),"Empty key not allowed!");
        require(msg.sender==admin);
        roomlist[_roomno] = room({status:state.vacant,key:_key,price:_price,owner:admin});
    }
}