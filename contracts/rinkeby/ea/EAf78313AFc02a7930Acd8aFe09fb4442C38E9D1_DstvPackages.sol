// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.8;


 contract DstvPackages {

   //error

   error Dstv_tryanotherpackage();  

//declaration of Variables

uint256 public PremiumCost = 0.03 ether;
uint256 public CompactPlusCost = 0.02 ether;
uint256 public CompactCost = 0.01 ether;
uint256 public ConFamCost = 0.007 ether;
uint256 public yangaCost =  0.004 ether;
uint256 public PadiCost =  0.003 ether;

//Creat Event

event PackagesDstv(address indexed _from, uint256 Cost);

//modifier
modifier trackall(uint _Cost){
    if(msg.value< _Cost)
    revert Dstv_tryanotherpackage();

    _;
}

// function Buy
//just add modifier to buy function

function BuyPremiumCost() payable public trackall( PremiumCost) {

 emit  PackagesDstv(msg.sender, PremiumCost);
}


function BuyCompactPlusCost () payable public trackall(CompactPlusCost) {

    emit  PackagesDstv(msg.sender, CompactPlusCost);

    
}

function BuyCompactCost () payable public trackall(CompactCost) {

    
emit  PackagesDstv(msg.sender, CompactCost);
    
}


function BuyConFamCost () payable public trackall(ConFamCost){
    emit  PackagesDstv(msg.sender,ConFamCost);

    
}

function BuyyangaCost () payable public trackall(yangaCost) {
    emit  PackagesDstv(msg.sender,yangaCost);


    
}


function BuyPadiCost() payable public trackall(PadiCost) {

    emit  PackagesDstv(msg.sender,PadiCost);
}


//Refund function

function Refund(address) payable public {
payable(msg.sender).transfer(address(this).balance);


}

//Balance

function getBalance() public view returns(uint){

    return address(this).balance;
}


 }