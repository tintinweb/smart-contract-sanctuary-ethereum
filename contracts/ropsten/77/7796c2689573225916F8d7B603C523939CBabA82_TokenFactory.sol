//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.4;
import "./NewToken.sol";
contract TokenFactory{
    mapping(address=>address[]) public ownerToTokens; 
    mapping(address=>uint256) public ownerToDeployedContracts;
    uint256 public totalDeployedContracts;

    event TokenCreated(address _minter,address _token,uint256 _idToken);

    function createNewToken(uint256 _initialSupply, string memory _name,string memory _initials) public returns(address){
        NewToken newToken=new NewToken(_initialSupply,_name,_initials);
        totalDeployedContracts++;
        ownerToTokens[msg.sender].push(address(newToken));
        ownerToDeployedContracts[msg.sender]++;

        emit TokenCreated(msg.sender,address(newToken), totalDeployedContracts);

        return address(newToken);
    } 

}