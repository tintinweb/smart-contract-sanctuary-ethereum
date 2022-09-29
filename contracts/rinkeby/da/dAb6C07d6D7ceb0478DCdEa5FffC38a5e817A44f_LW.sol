//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


contract LW {

    mapping(address=>string[])AddressToProofs;
    mapping(address=>bool) public UnlockProfile;
    function EnterNewProof(string memory url,address wallet)public {
      require(wallet==msg.sender,"Only owner of wallet can enter new proof");
     

     AddressToProofs[wallet].push(url);
     if(AddressToProofs[wallet].length==1){
        UnlockProfile[wallet]=true;
     }
    }

    function viewProofs(address wallet)public view returns(string[] memory){
        require(AddressToProofs[wallet].length>=1,"There is not any proof for this wallet");
       require(UnlockProfile[wallet]==true,"Profile locked");
   
        return AddressToProofs[wallet];
    }

    function profileState(bool state,address wallet)public{
        require(msg.sender==wallet,"Only owner can unlock or lock profile");
        UnlockProfile[wallet]=state;
        
    }

    
}