/**
 * 
 
  Watchtower

*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

contract Watchtower
{
    address private owner;
    uint256 private registerPrice;
    mapping (address => bool) private members;
    uint256 memberCount; 
    uint256 maxMembers; 
    
    constructor()
    {
        owner = msg.sender;   
        memberCount = 0; 
        maxMembers = 250; 
        registerPrice = 0.2 ether;
    }
    
    // Readers
    
    function getRegisterPrice() external view returns(uint256)
    {
        return(registerPrice);
    }

      function getMaxMembers() external view returns(uint256)
    {
        return(maxMembers);
    }


    function getMemberCount() external view returns(uint256)
    {
        return(memberCount);
    }

    function getOwner() external view returns(address)
    {
        return(owner);
    }
    
    function isMember(address _account) external view returns(bool)
    {
        return(members[_account]);
    }
    
    // Functions

    function setOwner(address _owner) external
    {
        require(msg.sender == owner, "Function only callable by owner!");
    
        owner = _owner;    
    }
    
    function setRegisterPrice(uint256 _registerPrice) external
    {
        require(msg.sender == owner, "Function only callable by owner!");
        
        registerPrice = _registerPrice;
    }

    function setMaxMembers(uint256 _maxMembers) external
    {
        require(msg.sender == owner, "Function only callable by owner!");
        
        maxMembers = _maxMembers;
    }
    
    
    // Register functions
    receive() external payable
    {
        register();
    }
    
    function register() public payable
    {
        require(!members[msg.sender], "Address already registered!");
        require(msg.value >= registerPrice, "Amount sent below register price!");
        require(memberCount < maxMembers, "We're currently at maximum members");
        
        memberCount += 1; 
        members[msg.sender] = true;
    }

    // Withdraw Ether
    function withdraw(uint256 _amount, address _receiver) external
    {   
        require(msg.sender == owner, "Function only callable by owner!");
        
        payable(_receiver).transfer(_amount);
    }
}