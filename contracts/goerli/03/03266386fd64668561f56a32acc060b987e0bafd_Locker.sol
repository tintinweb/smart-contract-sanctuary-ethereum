/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.2; 



interface EAToken {
    
    function transfer(address to, uint256 amount) external returns(bool);
    

}

contract Locker { 
    address public owner;  
    mapping(address => uint) public lockingWallet;
    uint public unlockDate;
    address public tokenContract=address(0);
    address public contractaddress;
    
    
    
    constructor(address[4] memory _wallet,uint[4] memory  _tokenamount, address _tokenContract) {

        owner=msg.sender;
       
        contractaddress = address(this);
        tokenContract= _tokenContract; 
       

       for(uint i=0;i<4;i++){      
       
         lockingWallet[_wallet[i]]=_tokenamount[i]; 
         
        }

        unlockDate = block.timestamp + 600; //(30*9*(24*60*60));
    } 


    event withdraw(address _to, uint _amount);

    function withdrawTokens() public {
             require(block.timestamp > unlockDate);
             
             if (keccak256(abi.encodePacked(lockingWallet[msg.sender])) > 0) {

             EAToken(tokenContract).transfer(msg.sender, lockingWallet[msg.sender]);
             emit withdraw(msg.sender,lockingWallet[msg.sender]);

             }
           
    }

    
}

//[0x871796D7647Cb05a6d2A5B46464342dF552CdE3f,0x0Cc1BfceB8AF2ff479D288fB3d0B9B558632D6b9,0x15C226162949339Bf46008039423bF28021Ca8a2,0xfbf1dB935415dd9c293e0c6c27011Cbe69718f3C]
//[10000000000000000,20000000000000000,30000000000000000,40000000000000000]


//[0x871796D7647Cb05a6d2A5B46464342dF552CdE3f,0x0Cc1BfceB8AF2ff479D288fB3d0B9B558632D6b9,0x15C226162949339Bf46008039423bF28021Ca8a2,0xfbf1dB935415dd9c293e0c6c27011Cbe69718f3C],[10000,20000,30000,4000],'0x10a8063cEbbe762105317DAeb85026592FA65882'