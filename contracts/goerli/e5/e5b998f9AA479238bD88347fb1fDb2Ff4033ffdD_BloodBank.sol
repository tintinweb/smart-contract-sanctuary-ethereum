/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: MIT
/* 
Problem statement - Medical record of patients not safe (can be accessed publically).
    There is a need to track blood being donated to a blood bank , right upto the point of it being used
    for some patient. This will help in making sure that the blood administered has not expired or is in
    the negative list.

*/
pragma solidity 0.8.0;

contract BloodBank{
    
    uint256 id;// bar code
    uint256 regId;
    enum BloodGroups{ABp,ABn,Ap,An,Bp,Bn,Op,On}
    struct Blood{    
        address donater;
        uint256 timeOfDonation;
        uint BloodGroup;
        bool isSafe;
        bool isAvailable;
    } 
    struct Users{
        address user;
        uint8 age;
        string name;
        uint8 group;    
    }

    mapping (uint256 => Blood) collection;
    mapping(address => uint256[]) donations;
    mapping(uint256 => address) patient;
    mapping (uint256 => Users) registrations;   //regId with User data
    address[] registered;

    event Donate(address indexed User, address indexed Donator, uint256 Id);
    
    function register(address _addr, uint8 _age, string memory _name, uint8 _group) public returns(uint256){
        // Check if already registered.
        require(_checkIfIncluded(_addr), "Error: Already registerd");
        regId++;
        registrations [regId]=Users(_addr, _age, _name, _group);
        registered.push(_addr);
        return regId;
    }
    function _checkIfIncluded(address _addr) internal view returns(bool){
        for(uint i=0; i<registered.length; i++){
            if(registered[i]==_addr){
                return false;
            }
        }
        return true;
    }
    
    function addDonation(uint256 _regId ) public returns (uint256){
        require(_regId<=regId, "Not yet registered");
        id++;
        address donor = registrations [_regId].user;
        uint8 bgroup = registrations [_regId].group;
        collection[id] = Blood(donor, block.timestamp,bgroup,true,true);
        donations[donor].push(id);
        emit Donate(msg.sender,donor,id);
        return block.timestamp;

    }
    function viewDonations(address _addr) public view returns(uint256[] memory){
        return donations[_addr];
    }
    // Can be made for input as an array too.
    function useCollection(uint256 _id, uint256 _regId) public {
        address users = registrations[_regId].user;
        collection[_id].isAvailable = false;
        patient[_id] = users;
    }
    function trackUsage(uint256 _id)public view returns(uint256 REGID){
        for (uint256 i=0;i<registered.length;i++){
            if(registrations[i].user==patient[_id]){
                return i;
            }
        }
        
    }

    function markUnsafe(uint256 _id) public{
        collection[_id].isSafe = false;        
    }
    
    function inventory() public view returns(uint256 ABp ,uint256 ABn,uint256 Ap,uint256 An,uint256 Bp,uint256 Bn,uint256 Op,uint256 On){
        uint256 abp;uint256 abn; uint256 ap; uint256 an; uint256 bp; uint256 bn; uint256 op;uint256 on;
        for(uint i=1; i<=id;i++){
            if(collection[i].isAvailable && collection[i].isSafe ) {
                if(collection[i].BloodGroup == 0){
                     abp += 1;
                }else if (collection[i].BloodGroup == 1){
                     abn ++;
                }else if (collection[i].BloodGroup == 2){
                     ap ++;
                }else if (collection[i].BloodGroup == 3){
                     an ++;
                }else if (collection[i].BloodGroup == 4){
                     bp ++;
                }else if (collection[i].BloodGroup == 5){
                     bn ++;
                }else if (collection[i].BloodGroup == 6){
                     op ++;
                }else {
                     on ++ ;
                }                
            }
        }
        return (abp,abn,ap,an,bp,bn,op,on);
    }    

    function searchBloodGroup(uint8 _bloodgroup) public view returns(uint256){
        uint256 result;
        for(uint i=1; i<=id;i++){
            if(collection[i].isAvailable && collection[i].isSafe){
                if(collection[i].BloodGroup == _bloodgroup){
                    result++;
                }
            }
        }
        return result;        
    }
    function count(uint256 _start, uint256 _stop) external view returns(uint) {
        uint k;
        for (uint i=1;i<=id;i++){
            if(collection[i].timeOfDonation>_start && collection[i].timeOfDonation<_stop) {
                k++;
            }
        }
        return k;    
        
    }

    function viewDonationData(uint256 _start, uint256 _stop, uint8 z) public view 
        returns(address[] memory Donators, uint256[] memory Time_Of_Donation, 
        uint[] memory Blood_Group, bool[]memory SAFE) {
        
            uint256[] memory viewId  = new uint256[] (z);
            address[] memory donators = new address[](z);
            uint256[] memory times = new uint256[](z);
            uint[] memory groups = new uint[](z);
            bool[] memory safe = new bool[](z);
        
            Blood memory blood;
            uint j=0;

            for (uint i=1;i<=id;i++){
                if(collection[i].timeOfDonation>_start && collection[i].timeOfDonation<_stop) {
        
                    viewId[j] = i;
                    blood = collection[i];
                    donators[j] = blood.donater;
                    times[j] = blood.timeOfDonation;
                    groups[j] = blood.BloodGroup;
                    safe[j] = blood.isSafe;

                    j++;
                }
            }        
        return (donators,times,groups,safe);
    }

}