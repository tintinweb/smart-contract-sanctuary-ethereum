/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

pragma solidity ^0.8.7;
contract FlightInsurance{

    enum ClaimState { Active, Processed }
    mapping (address => ClaimState) insurance;
   
       address constant val = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
       constructor() payable {}
            
    function payPremium()payable public {
            insurance[msg.sender] = ClaimState.Active;
            payable(msg.sender).transfer(msg.value);
        }
    function claimPremium(address _customerAddress)public payable{
            require(msg.sender == val);
            require(insurance[_customerAddress] == ClaimState.Active);
            insurance[_customerAddress] = ClaimState.Processed;
            uint claimAmount = msg.value;
           payable( _customerAddress).transfer(claimAmount);
        
}
       
}