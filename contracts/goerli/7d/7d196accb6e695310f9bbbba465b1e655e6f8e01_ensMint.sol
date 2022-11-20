/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface braands{
    function mint(address _to,uint _amount,string memory _uri,uint _intial_price, uint buyVail) external payable;
}
interface ens {
    function makeCommitment(string memory name, address owner, bytes32 secret) external view  returns(bytes32);
    function register(string calldata name, address owner, uint duration, bytes32 secret) external payable ;
    function commit(bytes32 commitment) external; 
     function available(string memory name) external view returns(bool);
}
contract ensMint{
    receive() external payable {}
    fallback() external payable {}
    address public owner;
    braands erc1155token;
    ens ensName;
    constructor( address payable  _braands, address payable _ensName){
       erc1155token =  braands(_braands);
       ensName = ens(_ensName);
       owner = msg.sender;
       

    }
    function Mint (address _to,uint _amount,string memory _uri,uint _intial_price, uint buyVail)external payable{
        uint _duration = buyVail*31536000;
       // address _resolver = 0x42D63ae25990889E35F215bC95884039Ba354115;
        bytes32 _secret = 0x0;
        ens (ensName).register{value : 0.04 ether}(_uri,_to,_duration,_secret);
        braands(erc1155token).mint{value : _intial_price}(_to,_amount,_uri,_intial_price,buyVail);

    }
    function Commit (bytes32 commitment) public {
        ens (ensName).commit(commitment);
    }
    function Mint_fees (uint _intial_price) pure public returns(uint fee){
        fee = _intial_price+ 0.04 ether;}
        
    function withdraw (uint amount) public {
        require (msg.sender == owner);
        payable (owner).transfer(amount);
    }
    
}