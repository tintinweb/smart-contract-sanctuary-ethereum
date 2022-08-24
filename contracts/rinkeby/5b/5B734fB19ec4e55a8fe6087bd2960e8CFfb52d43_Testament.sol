/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

contract Testament{

    event SetHeirs(address _HeirsAddress,uint _amount);//To show the event when the heirs are set
    event Distribute_Assets(address Distributed_address, uint Distributed_Assets);//To show the event when the asset was distributed

    mapping (address => uint) BalanceOfHeirs;

    modifier OnlyOwner{
        require (msg.sender == OwnerAddress,"OnlyOwner can do it");
        _;
    }
    //ErfanPa

    modifier OnlyLawer{
       require(msg.sender == lawyer, "OnlyLawer can do it");
       _;
    }

    //If you want to appoint a lawyer from the beginning, uncomments the following two options
    constructor (/*address _address*/){
        OwnerAddress = msg.sender;
        //lawyer = _address;
    }

    address payable []  HeirsAddress;
    address OwnerAddress;
    address payable lawyer;

    uint Asset;
    uint AssetCheck;//To check that the remaining assets to define the heirs. 
    uint counts; //Used in the last function

    bool status; //true = The owner is dead - false = The owner is alive
    bool Assets_distributed;

    //uint public count ;

    function SetLawyer(address payable _address)public OnlyOwner {
        //If you want to choose a lawyer only once,, uncomments the following two options
        //require (count == 0, "the lawyer can be chosen once.");
        //count += 1 ;
        lawyer = _address;
    }

    function GetLawyer()public view returns(address){
        return (lawyer);
    }  

    function SetAsset()public payable OnlyOwner{
        Asset = msg.value;
        AssetCheck = Asset;
    }

    function GetAsset()public view returns(uint){
        return (Asset);
    }
    
    function setHeirs(address payable _address, uint amount)public OnlyOwner{
        require(status == false,"Sorry Owner died...");//You can not add heirs if the owner is dead
        require(AssetCheck >= amount,"There is no asset for this heir");
        BalanceOfHeirs[_address] = amount;
        HeirsAddress.push(_address);
        AssetCheck -= amount;
        emit SetHeirs(_address,amount);
    }

    function CheckAsset()public view returns(uint){
        return (AssetCheck);
    }

    function GetBalanceOfHeirs(address _address)public view returns(uint){
        return (BalanceOfHeirs[_address]);
    }

    function OwnerDie()public OnlyLawer{
        //The lawyer confirms that the owner is dead and the assets are distributed
        status = true;
        AssetDistribution();
    }
    
    function GetStatus()public view returns(bool){
        return (status);
    }

    function AssetDistribution()public payable OnlyLawer {
        require(status == true);//The owner must be dead
        require (counts == 0, "Can only be used once..");
        for(uint i=0;i<HeirsAddress.length;i++){
        HeirsAddress[i].transfer(BalanceOfHeirs[HeirsAddress[i]]);
        counts += 1; //To distribute assets only once
        emit Distribute_Assets(HeirsAddress[i],BalanceOfHeirs[HeirsAddress[i]]);
        }
        Assets_distributed = true;
    }
    //ErfanPa

    function distributed_Check()public view returns(bool){
        return Assets_distributed;
    }
}