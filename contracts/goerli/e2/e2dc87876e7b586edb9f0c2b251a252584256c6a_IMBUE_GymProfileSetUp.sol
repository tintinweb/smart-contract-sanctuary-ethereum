/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

//SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.7;
contract IMBUE_GymProfileSetUp
    {
    struct GymDetailsStruct
    {
          string  Genre;
          string  Discription;
          string  WebsiteLink;
          string  twitter;
          string  instagram;
          string  otherLink;
          uint    MemberShipPrice;
          uint128 MobileNumber;  
    }
    struct GymLocationStruct
    {
          string[] gymLocations;
    }
    struct GymImageURL_Struct
    {
          string[]  GymImageURL;
    }
    mapping(address=>string) private gym_Name;
    mapping(string=>GymDetailsStruct) public ViewDescription;
    mapping(string=>GymLocationStruct) GymLocation;
    mapping(string=>GymImageURL_Struct) GymImageUrl;
    event eSetGymDetails(string _GymName,string _Genre,string _Discription,string _WebsiteLink,string _twitter,
                         string _instagram,string _OtherLink,uint _MemberShipPrice,uint128 _MobileNumber);
    event eSetGymAddress(string _GymName,string[] _GymLocations);
    event eSetImageUrl(string _GymName,string[] _ImageUrl);
    modifier mGymName
    {
          string memory gymName=gym_Name[msg.sender];
          bytes memory EmptyString=bytes(gymName);
          require(EmptyString.length!=0,"Gym name is not provided");
          _;
    }
    function SetGymDetails(string memory _GymName,string memory _Genre,string memory  _Discription,string memory _WebsiteLink,string memory _twitter,
          string memory _instagram,string memory _OtherLink,uint _MemberShipPrice,uint128 _MobileNumber) public
    {
          ViewDescription[_GymName]=GymDetailsStruct(_Genre,_Discription,_WebsiteLink,_twitter,_instagram,
                                                     _OtherLink,_MemberShipPrice,_MobileNumber);
          gym_Name[msg.sender]=_GymName;
          emit eSetGymDetails(_GymName,_Genre,_Discription,_WebsiteLink,_twitter,_instagram,_OtherLink,_MemberShipPrice,_MobileNumber);
    }
    function SetGymAddress(string memory _GymAddress) public mGymName
    {
          string memory gymName=gym_Name[msg.sender];
          GymLocation[gymName].gymLocations.push(_GymAddress);
          emit eSetGymAddress(gymName,GymLocation[gymName].gymLocations);
    }
    function SetImageUrl(string memory _ImageUrl) public mGymName
    {
          string memory gymName=gym_Name[msg.sender];
          require(GymImageUrl[gymName].GymImageURL.length<5,"More than five images are not allowed");
          GymImageUrl[gymName].GymImageURL.push(_ImageUrl);
          emit eSetImageUrl(gymName,GymImageUrl[gymName].GymImageURL);
    }
    function ViewLocations(string memory _GymName) public view returns(string[] memory)
    {
          return GymLocation[_GymName].gymLocations;
    }
    function getImageUrl(string memory _GymName) public view returns(string[] memory)
    {
          return GymImageUrl[_GymName].GymImageURL;
    }
    }