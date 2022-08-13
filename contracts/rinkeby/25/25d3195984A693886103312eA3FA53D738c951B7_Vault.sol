// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

contract Vault{
// a contract where the owner create grant for a beneficiary;
//allows beneficiary to withdraw only when time elapse
//allows owner to withdraw before time elapse
//get information of a beneficiary
//amount of ethers in the smart contract

//*********** state variables ********/

address public owner;
uint ID = 1; 



struct BeneficiaryProperties{
    uint amountAllocated;
    address beneficiary;
    uint time;
    bool status;
}
mapping(uint => BeneficiaryProperties)  public _beneficiaryProperties;


modifier onlyOwner(){

    require(msg.sender == owner, "not owner");
    _;

    
}
uint[] id;
BeneficiaryProperties[] public bp;

modifier hasTimeElapse(uint _id){
    BeneficiaryProperties memory BP = _beneficiaryProperties[_id];
    require(block.timestamp >= BP.time, "time never reach");
    //000000 setting time
    //111111 // value set to(BP.time)
    //222222 // coming to withdraw(Blocktime)

_;
}

constructor(){
    owner = msg.sender;
}

function createGrant(address _beneficiary, uint _time) external payable onlyOwner returns(uint ){
    require(msg.value > 0, "zero ether not allowed");
    BeneficiaryProperties storage BP = _beneficiaryProperties[ID];
    BP.time =_time;
    BP.amountAllocated= msg.value;
    BP.beneficiary = _beneficiary;
    uint _id = ID;
    id.push(_id);
    bp.push(BP);
    ID++;
    return _id;

}
function withdraw(uint _id) external {
    BeneficiaryProperties storage BP = _beneficiaryProperties[_id];
    address user = BP.beneficiary;
    require(user == msg.sender, "not a beneficiary for a grant");
    uint _amount = BP.amountAllocated;

    require(_amount > 0, "you  have no money!");
    uint getBal=getBalance();
    require(getBal >= _amount, "insufficient");
    BP.amountAllocated = 0;
    payable(user).transfer(_amount);

}

function RevertGrant(uint _id) external onlyOwner{
    BeneficiaryProperties storage BP = _beneficiaryProperties[_id];
    uint _amount = BP.amountAllocated;
    BP.amountAllocated = 0;
    payable(owner).transfer(_amount);
    
}
function returnBeneficiaryInfo(uint _id) external view returns(BeneficiaryProperties memory BP ){
    BP = _beneficiaryProperties[_id];
    
}
function getBalance() public view returns(uint256 bal){
    bal = address(this).balance;
}
function getAllBeneficiary() external view returns(BeneficiaryProperties[] memory _bp){
    uint[] memory all = id;
    _bp = new BeneficiaryProperties[](all.length);

    for(uint i = 0; i < all.length; i++){
        _bp[i]=_beneficiaryProperties[all[i]];

    }
}


function getPart(uint _id, uint _amount) external {
    BeneficiaryProperties storage BP = _beneficiaryProperties[_id];
    uint fundsInaccount = BP.amountAllocated;
    require(_amount <= fundsInaccount, "Insufficuent funds");
    uint balance = fundsInaccount - _amount;
    BP.amountAllocated = balance;
    payable(BP.beneficiary).transfer(_amount);

}
// function getBalance(uint _id) external view returns(uint){
//     BeneficiaryProperties storage BP = _beneficiaryProperties[_id];
//     return BP.amountAllocated;

// }



}