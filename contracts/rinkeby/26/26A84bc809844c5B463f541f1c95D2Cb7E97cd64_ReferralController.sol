/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// File: contracts/IReferral.sol


pragma solidity ^0.8.3;

abstract contract IReferral{

   struct Code{
      address owner;
      address user;
   }

   function canJoin(address account) external view virtual returns(bool);
   function useReferral(address account,string memory _code) external virtual;
   function wasUsed(address account,string memory _code) public view virtual returns (bool result);
}

// File: contracts/IActivation.sol


pragma solidity ^0.8.3;

abstract contract IActivation{

   struct Code{
      address owner;
      address user;
      uint256 lifespan;
   }

   function canJoin(address account) external view virtual returns(bool);
   function useReferral(address account,string memory _code) external virtual;
   function wasUsed(address account,string memory _code) public view virtual returns (bool result);
}

// File: contracts/ReferralController.sol


// solhint-disable not-rely-on-time
pragma solidity ^0.8.3;



contract ReferralController  {

    IReferral public referral;
    IActivation public activation;

    constructor(address _referral,address _activation){
        referral = IReferral(_referral);
        activation = IActivation(_activation);
    }

    function canJoin(address account) external view returns(bool result){
        result = false;
        if(referral.canJoin(account) || activation.canJoin(account))
        {
                result = true;
        }
    }

    function useReferral(string memory _code) external{
        if(referral.wasUsed(msg.sender,_code))
        {
            activation.useReferral(msg.sender,_code);
        }else{
            referral.useReferral(msg.sender,_code);
        }
    }

    function wasUsed(string memory _code) public view returns (bool result) {
        result = true;
        if(!referral.wasUsed(msg.sender,_code) || !activation.wasUsed(msg.sender,_code))
        {
            result = false;
        }

        return result;
    }

    
}