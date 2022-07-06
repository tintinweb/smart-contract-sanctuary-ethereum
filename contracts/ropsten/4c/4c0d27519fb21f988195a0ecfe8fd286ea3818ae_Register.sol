/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/math/SafeMath.sol";
contract Register {  

    uint256[] Admin;
    uint256[] Invester;
    uint256[] BSA;
    uint256 PropertyID=1;

    struct  Property {
    uint256 Value;
    uint256 Funds;
    uint256 Yield;
    uint256 Coupon_Rate;
    uint256 Coupon_Date;
    uint256 Issue_Date;
    bool Callable;
    bool status;
    uint256 ExpDate;   
    }
    mapping(uint256=>Property)Property_Id;   //Add values to Property stuct
    mapping(uint256=>mapping(uint256=>uint256[])) BSAProperty; //


    struct User{
    uint256 User_id;
    uint[] PropertiesHeld;
    }

    mapping(uint256=>User) BSAUsers; //Add values toUser struct mapping

    struct Invester_Detail{
        uint256 Amount;
        uint256 Percentage;
        bool FunRaising;
    }
    mapping(uint256=>mapping(uint256=>Invester_Detail)) SubDetails;

    struct PMP_Detail{
        uint256 Amount;    
        uint256 Tokens;
        uint256 Percentage;
    }

    // mapping(uint256=>Invester_Detail) InvetserMap;
    mapping(uint256=>mapping(uint256=>PMP_Detail)) PMPmapp;
  
    mapping(uint256=>bool) IsBSAproperty; // Mapp for Is BAS created property
    mapping(uint256=>bool) IsAdmin; // mapping for check the user as admin
    mapping(uint256=>bool) IsInvester; // mapping for check the user as invester
    mapping(uint256=>bool) IsBSA; // mapping for check the user as BSA


    // Admin Modifier
    modifier requireAdmin(uint256 _AdminID){
         require(IsAdmin[_AdminID]==true,"Selected User id Not a Admin");
         _;
    }
    modifier requireInvester(uint256 _InvesterID){
         require(IsInvester[_InvesterID]==true,"Selected User id Not a Invester");
         _;
    }
    modifier requireBSA(uint256 _BSAID){
         require(IsBSA[_BSAID]==true,"Selected User id Not a BSA");
         _;
    }

    //Events
    event AddProperty(uint256 _value,uint256 User_Id,uint256 _funds,uint256 _yield,uint256 _coupon_rate,uint256 _coupon_date,uint256 _Issue_Date,bool _Callable,bool _status,uint256 expDate);
    event InvesterSubscription(uint256 User_Id,uint256 property_id,uint256 amount,uint256 percent,bool funRaising);
    event PMPEvent ( uint256 From_Id,uint256 To_Id,uint256 property_id,uint256 amount,uint256 tokens,uint256 percentage);     
    event UserAsAdmiN(uint256 User_id);      
    event UserAsInvesteR(uint256 User_id); 
    event UserASBSa(uint256 _AdminId,uint256 User_id); 

     //Function for Add admin                      
    function UserAsAdmin(uint256 User_id)  public {
        require(IsAdmin[User_id]=true,"This user already Admin");
        Admin.push(User_id);
        IsAdmin[User_id]=true;
    emit UserAsAdmiN(User_id);
    }
    function CheckAdmin(uint256 User_id) view public returns(bool) {
        return(IsAdmin[User_id]);
    }
    // Function for Grant invester role for user
    function UserAsInvester(uint256 User_id) public  {
        Invester.push(User_id);
        IsInvester[User_id]=true;
    emit UserAsInvesteR(User_id);
    }
  
    function CheckInvester(uint256 User_id) view public returns(bool) {
        return(IsInvester[User_id]);
    }
     // Function for grant BSA role for user
    function UserAsBSA(uint256 _AdminId,uint256 User_id)  public requireAdmin(_AdminId)  {
        //only admin
        require(IsBSA[User_id]==false,"This user already  BSA");
        IsBSA[User_id]=true;
        emit UserASBSa(_AdminId, User_id);
    }
    function CheckAsBSA(uint256 User_id) view public returns(bool) {
        return(IsBSA[User_id]);
    }
    // Assign Project status
    function ProjectStatus(uint256 User_id,uint256 Property_ID,bool _status) public{
        require(IsBSA[User_id]==true,"User id not BSA");
        Property_Id[Property_ID].status=_status;
       // IsBSAproperty[Property_ID]=true; 
            }
    function projectstatusCheck(uint256 property_id) view public returns(bool){
        return Property_Id[property_id].status==true;
    }

    // Function for Creating properties
    function Add_Property(uint256 _value,
                          uint256 User_Id,
                          uint256 _funds,
                          uint256 _yield,
                          uint256 _coupon_rate,
                          uint256 _coupon_date,
                          uint256 _Issue_Date,bool _Callable,bool _status,uint256 expDate)  public requireBSA(User_Id){
                          require(expDate>block.timestamp,"Date experird");
                          Property_Id[PropertyID].Value=_value;
                          Property_Id[PropertyID].Funds=_funds;
                          Property_Id[PropertyID].Yield=_yield;
                          Property_Id[PropertyID].Coupon_Rate=_coupon_rate;
                          Property_Id[PropertyID].Coupon_Date=_coupon_date;
                          Property_Id[PropertyID].Issue_Date=_Issue_Date;
                          Property_Id[PropertyID].Callable=_Callable;
                          Property_Id[PropertyID].status=_status;
                          Property_Id[PropertyID].ExpDate=expDate;
                          BSAProperty[PropertyID][User_Id];    
                          //Add value to User struct
                          BSAUsers[User_Id].User_id=User_Id;
                          BSAUsers[User_Id].PropertiesHeld.push(PropertyID);
                          // Increamement for Property id 
                          PropertyID=PropertyID+1;
    emit AddProperty(_value,User_Id,_funds,_yield,_coupon_rate,_coupon_date,_Issue_Date,_Callable,_status,expDate);
    }
   
    function propertyReturn(uint Property_ID) view public returns( uint256 Value,
        uint256 Funds,
        uint256 Yield,
        uint256 Coupon_Rate,
        uint256 Coupon_Date,
        uint256 Issue_Date,
        bool Callable,
        bool status){
        Property storage p = Property_Id[Property_ID];
        return (p.Value,p.Funds,p.Yield,p.Coupon_Rate,p.Coupon_Date,p.Issue_Date,p.Callable,p.status);
    }

    function ReturnUser(uint256 User_Id) view public returns(uint256 User_id,uint256[] memory PropertiesHeld){
        User memory UserStruct = BSAUsers[User_Id];
        return(UserStruct.User_id,UserStruct.PropertiesHeld);
    }

    function InvesterSub(uint256 User_Id,uint256 property_id,uint256 amount,uint256 percent,bool funRaising) public requireInvester(User_Id){
        // only invester
        require(IsInvester[User_Id]==true,"Only Invester can Access");
        require(Property_Id[property_id].ExpDate>block.timestamp,"Time expired");
        require(Property_Id[property_id].status==false,"project status should be false");
        //project status should be false
        SubDetails[User_Id][property_id].Amount=amount;
        SubDetails[User_Id][property_id].Percentage=percent;
        SubDetails[User_Id][property_id].FunRaising=funRaising;
       // SubDetails[User_Id][property_id].Percentage=(amount/_value);
    emit InvesterSubscription(User_Id,property_id,amount,percent,funRaising);
    }

    function PMP( uint256 From_Id,
        uint256 To_Id,
        uint256 property_id,
        uint256 amount,
        uint256 tokens,
        uint256 percentage)  public requireInvester(To_Id){
        // only invester
        //we need user id and property id 
        require(Property_Id[property_id].status==true,"project status should be true"); //project status should be true
        require(Property_Id[property_id].ExpDate<block.timestamp,"Time not expired");
        PMPmapp[From_Id][To_Id].Amount=amount;
        PMPmapp[From_Id][To_Id].Tokens=tokens;
        PMPmapp[From_Id][To_Id].Percentage=percentage;
    emit PMPEvent( From_Id,To_Id,property_id,amount,tokens,percentage);
    }

    function GetInvesterSub(uint256 User_id,uint256 property_id) view public returns(uint256 Amount,uint256 Percentage,bool FunRaising){
        Invester_Detail memory  InvesterSUbscription =SubDetails[User_id][property_id];
        return (InvesterSUbscription.Amount,InvesterSUbscription.Percentage,InvesterSUbscription.FunRaising);
    }
    function GetPMP(uint256 User_id,uint256 property_id) view public returns(uint256 Amount,uint256 tokens,uint256 percentage){
        PMP_Detail memory PMPDetails= PMPmapp[User_id][property_id];
        return (PMPDetails.Amount,PMPDetails.Tokens,PMPDetails.Percentage);
    }
}