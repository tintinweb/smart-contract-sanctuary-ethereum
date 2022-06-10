/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

pragma solidity ^0.5.10;

contract ERC20Contract  {
    event MemberAdded(address member);
    event MemberRemoved(address member);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    mapping (address => bool) members;

    address _member1;
  
    //Fucntion is to verify the member is in the blocked list or not
    function isMember(address _member) public view returns(bool)
    {
        return members[_member];
    }

 //Fucntion is to add memmber in the blockc list and to verify whether the member already in the blocked list or not
    function addMember(address _member) public 
    {
        require(!isMember(_member),"Address is member already.");
        members[_member] = true;
        emit MemberAdded(_member);
    }
    
//Fucntion is to remove memmber in the blockc list and to verify whether the member already removed from blocked list or not
    function removeMember(address _member) public 
    {
        require(isMember(_member),"Not member of Blocklist." );
        delete members[_member];
        emit MemberRemoved(_member);
    }

    //Function to transfer the ethers from members who are not part of the list
    function special_transfer(address receiver) public payable returns (int)
    {
          if(isMember(msg.sender)==true)
          {
              revert();
          }
              else
              {
                receiver.call.value(msg.value).gas(60000)("");
                emit Transfer(receiver,msg.sender, msg.value);
                 return 0;
              }
               
             
    }
}