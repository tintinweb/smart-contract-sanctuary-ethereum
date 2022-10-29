/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

//SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.7;
     contract IMBUE_GymProfileSetUp
     {
          struct GymDetailsStruct{
               address GymOwner;
               string  GymImageURLs; 
               string  GymName;
               string  Genre;
               string  Description;
               string  Addresses;
               string  SocialMediaLinks;
               uint    MemberShipPrice;
               uint128 MobileNumber;  }
     mapping(address=>GymDetailsStruct)  viewDescription;
     GymDetailsStruct[] private GymArr;
     mapping(address=>bool) public IsMember;
     mapping(address=>uint) private MemberShipEnd;
     string[] private AddArr;
     address public Owner=msg.sender;

     function SetGymDetails(string memory _GymImageURLs, string memory _GymName,string memory _Genre,string memory  _Description, string memory _Addresses,
                              string memory _SocialMediaLinks,uint _MemberShipPrice,uint128 _MobileNumber) public
     {         if(viewDescription[msg.sender].GymOwner==0x0000000000000000000000000000000000000000){
                    viewDescription[msg.sender]=GymDetailsStruct(msg.sender,_GymImageURLs,_GymName,_Genre,_Description,_Addresses,_SocialMediaLinks,_MemberShipPrice,_MobileNumber);
               GymArr.push(viewDescription[msg.sender]);
               AddArr.push(_Addresses);
               }else{
                    for(uint i=0;i<GymArr.length;i++){
                         viewDescription[msg.sender]=GymDetailsStruct(msg.sender,_GymImageURLs,_GymName,_Genre,_Description,_Addresses,_SocialMediaLinks,_MemberShipPrice,_MobileNumber);
                         if(GymArr[i].GymOwner==msg.sender){
                         GymArr[i]=viewDescription[msg.sender];
                         }}    }   }
     function ViewDescription(address _user) public view returns(GymDetailsStruct memory)
     {
               return viewDescription[_user];
     }
     function GetGymLocations(address _user) public view returns(string memory){
               return viewDescription[_user].Addresses;
     }
     function viewLocations(address _user,uint _Id) public view returns(string memory) {
          if(IsCreated[_user][_Id]==true){
               return _ClassDetails[_Id][_user].Location;
          }
          else{
               return viewDescription[_user].Addresses;
          }
     }
     function RegisteredGyms() public view returns(GymDetailsStruct[] memory){
          return GymArr;
     }
     function GetAddress() public view returns(string[]memory){
          return AddArr;
     }
     function purchaseMemberShip() public payable{
          require(MemberShipEnd[msg.sender]>block.timestamp,"You are already a member");
          payable(Owner).transfer(msg.value);
          IsMember[msg.sender]=true;
          MemberShipEnd[msg.sender]=block.timestamp+2592000;
     }     struct ClassStruct  {
               address studioWalletAddress;
               string  ImageUrl;
               string  ClassName;
               string  Category;
               string  SubCategory;
               string  ClassLevel;
               string  Description;
               string  Location;
               string[]  classModeAndEventKey;
               string  DateAndTime;
               string  Duration;
               string  ClassType;// class is one time or repeating
               address WhoBooked;
               uint    ClassId;
               bool    IsBooked;

     }        
          uint ClassID=1;
          uint ClassCount;
          mapping(address=>ClassStruct) ClassDetails;
          mapping(address=>uint) private Count;
          mapping(address=>uint) private BookedClassCount;
          mapping(uint=>mapping(address=>ClassStruct)) private _ClassDetails;
          mapping(address=>mapping(uint=>bool)) private IsCreated;
          mapping(uint=>mapping(address=>ClassStruct))  private BookedClasses;
          ClassStruct[] arr;
     function CreateAndScheduleClasses(string memory _ImageUrl,string memory _ClassName,string[] memory _Categories,
          string memory _ClassLevel, string memory _Description,string memory _Location,string[] memory _classModeAndEventKey,string memory _DateAndTime,string memory _Duration,
          string memory _ClassType) public{
          ClassDetails[msg.sender]=ClassStruct(msg.sender,_ImageUrl,_ClassName,_Categories[0],_Categories[1],_ClassLevel,_Description,
          _Location,_classModeAndEventKey,_DateAndTime,_Duration,_ClassType,0x0000000000000000000000000000000000000000,ClassID,false);
          arr.push(ClassDetails[msg.sender]);
          _ClassDetails[ClassID][msg.sender]=ClassDetails[msg.sender];
                    ClassID+=1;
          Count[msg.sender]+=1;
          IsCreated[msg.sender][ClassID]=true;
     }
     function editClass(address _user,uint _ClassID,string memory _ImageUrl,string[] memory _ClassNameAnd_Categories,
          string memory _ClassLevel, string memory _Description,string memory _Location,string[] memory _classModeAndEventKey,string memory _DateAndTime,string memory _Duration,
          string memory _ClassType) public {
               _ClassDetails[_ClassID][_user]=ClassStruct(_user,_ImageUrl,_ClassNameAnd_Categories[0],_ClassNameAnd_Categories[1],_ClassNameAnd_Categories[2],_ClassLevel,
                    _Description,_Location,_classModeAndEventKey,_DateAndTime,_Duration,_ClassType,0x0000000000000000000000000000000000000000,_ClassID,false);
                    ClassDetails[_user]=_ClassDetails[_ClassID][_user];
                    for(uint i=0;i<arr.length;i++){
                    if(arr[i].ClassId==_ClassID){
                         arr[i]=ClassDetails[_user];
                    }      }        }
     function getClasses(address _user) public view returns(ClassStruct[] memory)
     {
          uint8 _index=0;
          uint count=Count[_user];
          ClassStruct[] memory arr1=new ClassStruct[](count);
     for(uint i=0;i<arr.length;i++)
     { if(arr[i].studioWalletAddress==_user)
     { arr1[_index]=arr[i];
               _index+=1;
     }}    return arr1;
     }
     function BookClass(address _Owner,uint _ClassId) public {
          require(MemberShipEnd[msg.sender]>=block.timestamp,"Purchase subscription");
          require(_ClassDetails[_ClassId][msg.sender].IsBooked=false,"You already booked this class");
          BookedClasses[_ClassId][msg.sender]=_ClassDetails[_ClassId][_Owner];
         // _ClassDetails[_ClassId][msg.sender].IsBooked=true;
          _ClassDetails[_ClassId][msg.sender].WhoBooked=msg.sender;
          BookedClassCount[msg.sender]+=1;  
          ClassCount+=1;
               } 
     function getBookedClasses(address _user) public view returns(ClassStruct[] memory)
          {
          uint _Count= BookedClassCount[_user];
          uint _index=0;
          ClassStruct[] memory arR=new ClassStruct[](_Count);
          for(uint  i=0;i<ClassCount;i++){
               arR[_index]=BookedClasses[i][_user];
               _index+=1;
          }  return arR;}
     }