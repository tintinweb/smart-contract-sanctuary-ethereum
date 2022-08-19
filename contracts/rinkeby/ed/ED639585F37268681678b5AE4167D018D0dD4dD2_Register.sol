/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Register  {  
    

    struct  Property {
    uint256 assetId;  
    uint256 listedValue; 
    bool Callable;
    uint256 assetClassId;
    uint256 interestRate;
    uint256 couponFrequency; 
    uint256 Issue_date;
    uint Maturity_Date;
    uint256 Owner_Id;
    uint[] Subscriberlist;
   }

    mapping(uint256=>Property)Property_Id;   //Add values to Property stuct

    struct Owner{
    uint[] propertiesHeld;
    
    }

    mapping(uint256=>Owner) DSAOwners; //Add values toUser struct mapping


    struct Subscriber{
    uint[] propertiesInvestedIn;
    
    }

    mapping(uint256=>Subscriber) Subscribers; //Add values toUser struct mapping

    struct Sub_Detail{
        uint256 subID;
        uint256 propID;
        uint256 Amount;
        uint256 DebtTokensIssued;
        uint256 subDate;
    }
    mapping(uint256=>Sub_Detail) SubDetails;
    uint public subCount;
    Sub_Detail[] subs;

  
  
    //Events
    event AddProperty(uint256 assetId,uint256 listedValue,bool Callable,uint256 assetclassId,uint256 interestRate,uint256 couponFrequency,uint256 Issue_date,uint256 Maturity_Date,uint256 Owner_Id);

    event InvesterSubscription(uint256 User_Id,uint256 property_id,uint256 amount,uint256 DebtTokensIssued,uint256 subDate);
         
  
 // Function for Creating properties
    function Add_Property(uint256 assetId,
                          uint256 _value,
                          bool callable,
                          uint256 _assetclass,
                          uint256 interestRate,
                          uint256 couponFrequency,
                          uint256 Issue_Date, // future
                          uint256 Maturity_Date,
                          uint256 Owner_Id)  public {
                          
                          Property_Id[assetId].assetId=assetId;
                          Property_Id[assetId].listedValue=_value;
                          Property_Id[assetId].Callable=callable;
                          Property_Id[assetId].assetClassId=_assetclass;
                          Property_Id[assetId].Issue_date=Issue_Date;
                          Property_Id[assetId].Maturity_Date=Maturity_Date;
                          Property_Id[assetId].Owner_Id=Owner_Id;
                          DSAOwners[Owner_Id].propertiesHeld.push(assetId);
                          
                          
    emit AddProperty(assetId,_value,callable,_assetclass,interestRate,couponFrequency,Issue_Date,Maturity_Date,Owner_Id);
    }
   
function InvesterSub(uint256 User_Id,uint256 property_id,uint256 amount,uint256 tokensIssued, uint256 subDate) public {
       
        SubDetails[subCount].propID = property_id;
        SubDetails[subCount].subID = User_Id;
        SubDetails[subCount].Amount=amount;  
          
       SubDetails[subCount].DebtTokensIssued=tokensIssued;

       SubDetails[subCount].subDate=subDate;

       Subscribers[User_Id].propertiesInvestedIn.push(property_id);

       Property_Id[property_id].Subscriberlist.push(User_Id);
       subCount++;
      
    emit InvesterSubscription(User_Id,property_id,amount,tokensIssued,subDate);
    }

    function ReturnSubscriber(uint256 User_Id) view public returns(Sub_Detail[] memory filteredSubs){
       Sub_Detail[] memory subsTemp = new Sub_Detail[](subCount);
       uint count;
       for (uint i=0; i<subCount; i++) {
           if(SubDetails[i].subID == User_Id) {
               subsTemp[count] = SubDetails[i];
               count+=1;
           }
 }
 filteredSubs = new Sub_Detail[](count);
 for(uint i=0;i<count; i++){
     filteredSubs[i]=subsTemp[i];
 }
    }

    function ReturnProperty(uint256 assetid) view public returns(Sub_Detail[] memory filteredProps){
       Sub_Detail[] memory propsTemp = new Sub_Detail[](subCount);
       uint count;
       for (uint i=0; i<subCount; i++) {
           if(SubDetails[i].propID == assetid) {
               propsTemp[count] = SubDetails[i];
               count+=1;
           }
 }
 filteredProps = new Sub_Detail[](count);
 for(uint i=0;i<count; i++){
     filteredProps[i]=propsTemp[i];
 }
    }
}