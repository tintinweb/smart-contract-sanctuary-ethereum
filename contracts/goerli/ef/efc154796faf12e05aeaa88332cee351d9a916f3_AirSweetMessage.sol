/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract AirSweetMessage {
 // Define variable message of type string
    struct Message{
        string id;
        string[] authors;
        string[] contents;
    }
    mapping(string => Message) messageMap;
    mapping(address => uint) countMap;
    mapping(address=>mapping(uint =>string)) messageIdMap;
    address _owner;
    constructor(){
        _owner  = msg.sender;
     }

     function getMessageLength(address  owner) public view returns(uint ){
        return countMap[owner];
     }

     function getMessageId(address owner,uint index)public view returns(string memory ){
         return messageIdMap[owner][index];
     }

     // Write function to change the value of variable message
     function postMessage(string[] memory _authors,string[] memory _contents) public  returns (Message memory) {
         require(_authors.length >0,"authors is null");
         require(_contents.length >0,"contents is null");
         require(_authors.length == _contents.length,"message length error");
         countMap[msg.sender] +=1;
         string memory  index = uintToStr( countMap[msg.sender] );
         string memory addressStr= addressToString(msg.sender);
         string memory _id = strConcat(addressStr,"_");
         _id = strConcat(_id,index);
         messageIdMap[msg.sender][ countMap[msg.sender]] = _id;

         messageMap[_id] = Message({id:_id,authors:_authors,contents:_contents});
         return   messageMap[_id] ;
     }
    
     // Read function to fetch variable message
     function getMessage(string memory id ) public view returns (Message memory ){
     return messageMap[id];
     }
    
     function getOwener() public view returns (address ){
         return msg.sender;
     }
 
   
    function uintToStr(uint  value) internal pure returns (string memory s) {
        if (value == 0) return "0";
        bytes memory  numbers = "0123456789";
        uint j = value;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }

        bytes memory bstr = new bytes(length);
        uint k = length ;

        while (value != 0){
           uint index = value % 10;
           bstr[--k] = numbers[index];
           value /= 10;
        }
        return string(bstr);
    }

    function strConcat(string memory  _a,string memory _b) internal pure returns(string memory){
        bytes memory bytes_a = bytes(_a);
        bytes memory bytes_b = bytes(_b);
        string memory res = new string(bytes_a.length+bytes_b.length);
        bytes memory bytes_res = bytes(res);
        uint k = 0;
        for(uint i =0;i < bytes_a.length;i++){ bytes_res[k++] = bytes_a[i];}
        for(uint i =0;i < bytes_b.length;i++){ bytes_res[k++] = bytes_b[i];}
        return string(bytes_res);
    }
    function addressToString(address x) internal pure  returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }


    
}