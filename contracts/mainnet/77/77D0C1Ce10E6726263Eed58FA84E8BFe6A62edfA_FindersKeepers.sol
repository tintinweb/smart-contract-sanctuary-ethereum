/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: cc0
// deployed by Dr. Slurp
//
/**
                                                  
          ..     ..                    ..         
         .::.   .,'..   ...   ..    .. .,.        
        .cdo'  'lc,co;'.:do:;:oc..':oc''cl.       
         ,ol. .;::c::;;,cxx0N0xkd:;;::cc:'        
          .'  ',.     ..cxdONd:kk'                
           .'...    .cx0XNNWWX00c.                
            .''.    .cddddkKXX0kc.                
             .,..        .;k00Oko,.               
             .''.       ..;x0Oxdc'..     .,::,.   
              .,;:;.   ...,okxo:'....    ...,:'   
              .,:oc,......,dOOo:'......   .,;,.   
              .,'.........,dOOd:'......  .;,...   
               ..     ....,oxxo:'....'.  .,..'.   
                        ..,d00d:..,:cc.           
           .'..         ..,oxxo;...,;.            
          .,,'.        ....:oo:'....              
         .',;'         .....;,......              
          ':::;,.       ......  ....              
          .,;:::;'      .....    ...              
           .',,,::.    ';;;,.   ';,'.             
               ...     .....    ....              
**/


pragma solidity >=0.7.0 <0.9.0;

contract FindersKeepers
{

    address creator;
    address public winnerAddress;
    string public winnerDiscord;  // data

    enum State {Init, Waiting, Done}
    State public state = State.Init;

        constructor() 
        {
            creator = msg.sender;
        }

        //start contenst
        function startContest() public onlyOwner
        {
            state = State.Waiting;
        }

        function submitWinnerInfo(string memory discord) public waitingState
        {
            winnerDiscord = discord;
            winnerAddress = msg.sender;
            state = State.Done;
        }

        modifier onlyOwner 
        {
            require(msg.sender == creator);
            _;
        }

        modifier waitingState
        {
            require(state == State.Waiting);
            _;
        }
}