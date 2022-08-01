/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

pragma solidity >=0.7.0 <0.9.0;



contract setPurpose{

address private owner;
string public purpose;

event PurposeSet(address msgSetter, string newMessage);
event OwnerSet(address indexed oldOwner, address indexed newOwner);

constructor() {
        
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        purpose = "default";
        emit OwnerSet(address(0), owner);
        emit PurposeSet(owner, purpose);
    }

function setNewPurpose(string memory newMessage) public {
    purpose = newMessage;
    emit PurposeSet(msg.sender, newMessage);
}

}