/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract AirSweetContent {
 // Define variable content of type Content
    struct Content{
        string id;
        string text;
        string[] imgs;
    }
    mapping(string => Content) contentMap;
    mapping(address => uint) countMap;
    mapping(address=>mapping(uint =>string)) contentIdMap;
    address _owner;
    constructor(){
        _owner  = msg.sender;
     }

     function getContentLength(address  owner) public view returns(uint ){
        return countMap[owner];
     }

     function geContentId(address owner,uint index)public view returns(string memory ){
         return contentIdMap[owner][index];
     }

     // Write function to insert the value of variable content
     function postContent(string memory _id,string memory _text,string[] memory _imgs) public  returns (Content memory) {
         if(bytes(contentMap[_id].text).length >0){
            revert('content_id is existed');
         }
         countMap[msg.sender] +=1;
         contentIdMap[msg.sender][ countMap[msg.sender]] = _id;
         contentMap[_id] = Content({id:_id,text:_text,imgs:_imgs});
         return   contentMap[_id] ;
     }
    
     // Read function to fetch variable content
     function getContent(string memory _id ) public view returns (Content memory ){
        return contentMap[_id];
     }
    
     function getOwener() public view returns (address ){
         return msg.sender;
     }    
}