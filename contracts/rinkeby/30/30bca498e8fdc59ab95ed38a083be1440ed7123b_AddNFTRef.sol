/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

pragma solidity ^0.4.11;

 contract NFTRef {
  mapping (address => uint) balances;
  mapping (address => uint) totalNoofJobs;
  address owner;
  uint public reward;
  uint[] public volumeThreshold;
  uint[] public volumeAffiliatePercentage;

  function NFTRef(address _affiliateAddress) {
        owner=msg.sender;
        balances[owner]=150000;
        volumeThreshold = [1,5,100,1000];
        volumeAffiliatePercentage = [1, 2, 3, 5];
        balances[_affiliateAddress]=0;
        totalNoofJobs[_affiliateAddress]=0;
    }

  function addJobs(address _affiliateAddress,uint _jobs) {
    totalNoofJobs[_affiliateAddress]+=_jobs;
  }

  function changeBudget(uint _newBudget){
    if(msg.sender==owner)
    balances[owner]=_newBudget;
  }

  function getBalance(address _affiliateAddress) constant returns(uint) {
    return balances[_affiliateAddress];
}

  function returnBalance(address _affiliateAddress) external returns(uint) {
    return balances[_affiliateAddress];
}

function getAffiliatePercentage(address _affiliateAddress) constant returns (uint) {
        for (uint i = 0; i < volumeThreshold.length; i++) {
            if (totalNoofJobs[_affiliateAddress] < volumeThreshold[i]) return volumeAffiliatePercentage[i];
        }

        return volumeAffiliatePercentage[volumeThreshold.length - 1];
    }

   function commissionAgreement(address _affiliateAddress,uint _reward) returns (bool) {
     uint payment = _reward* getAffiliatePercentage(_affiliateAddress) / 100;
      if(balances[owner]>payment){
        balances[_affiliateAddress] += payment;
        balances[owner] -=payment;
        return true;
      }
      else
       return false;
    }

function payPerProductAgreement(address _affiliateAddress,uint _rewardperSale) returns (bool) {
   if(balances[owner]>_rewardperSale){
     balances[_affiliateAddress] += _rewardperSale;
     balances[owner] -=_rewardperSale;
     return true;
   }
   else
    return false;
 }
}

contract AddNFTRef{
address _add;
Affiliate[] public Affiliates;
struct Affiliate
{
  address public_address;
  uint balance;
}

function returnAdd(address _pubaddress) returns (address){
    _add = new NFTRef(_pubaddress);
    return _add;
}

function addAffiliate(address _public_address) returns(bool success) {
  Affiliate memory newAffiliate;
  newAffiliate.public_address= _public_address;
  NFTRef nftref= new NFTRef(_public_address);
  newAffiliate.balance= nftref.getBalance(_public_address);
  Affiliates.push(newAffiliate);
  return true;
}

function getAffiliate() constant returns (address[], uint[]) {

uint length = Affiliates.length;
address[] memory _publicAddress = new address[](length);
uint[] memory _balance = new uint[](length);

for (uint i = 0; i < Affiliates.length; i++) {
Affiliate memory currentAffiliate;
currentAffiliate = Affiliates[i];
_publicAddress[i] = currentAffiliate.public_address;
_balance[i] = currentAffiliate.balance;
}
return (_publicAddress, _balance);

}

}