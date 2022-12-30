/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract TradeSecure{
    // -- TradeStructure --
    struct Trade { 
        	 	   uint32 creatorSecurityFee; 
        		   uint32 acceptorSecurityFee; 
        		   address payable acceptorAddress; 
        		   address payable creatorAdress; 
        		   string description; 
        		   bool active; 
        		   bool creatorAccepted; 
        		   bool acceptorAccepted; 
        		   bool accepted; 
        		   bool concluded;
    }

    Trade[] public tradeArray;

    // -- ContractVariables --
    address payable constant owner = payable(0xEB3BC9d5C404e8DBA3239bbd0F6C590aACCfa404);
    uint8 public contractFee = 100; //make sure to cover deletion costs!
    uint8 profit = 0;
    error Unauthorized();
    error InsufficentFunding(uint256 sent, uint256 required);

    // -- Methods --
    // - public -
    function initiateSecuredTrade(uint32 creatorSecurityFee, uint32 acceptorSecurityFee, address payable acceptorAddress, string memory description) external payable returns(uint256 tradeID){
        Trade memory t;
        t.creatorAdress = payable(msg.sender);        
        if(msg.value >= creatorSecurityFee){
            t.creatorSecurityFee = creatorSecurityFee;
        }else{
            sendInsufficentFundingError(creatorSecurityFee);
        }
        t.acceptorSecurityFee = acceptorSecurityFee;
        t.acceptorAddress = acceptorAddress;
        t.description = description;
        t.active = true;
        t.creatorAccepted = false;
        t.acceptorAccepted = false;
        t.accepted = false;
        t.concluded = false;
        uint tradenumber = tradeArray.length + 1;
        tradeArray.push(t);
        profit += contractFee;
        return(tradenumber);
    }

    function cancelTrade(uint256 contractID) external {
        if(msg.sender == tradeArray[contractID].creatorAdress){
            tradeArray[contractID].active = false;
            tradeArray[contractID].concluded = true;
            address payable creator = payable(msg.sender);
            creator.transfer(tradeArray[contractID].creatorSecurityFee);
        }else{
            revert Unauthorized();
        }
    }

    function acceptTrade(uint256 contractID) external payable {
        if(msg.sender == tradeArray[contractID].acceptorAddress && tradeArray[contractID].accepted == false && tradeArray[contractID].active == true){
            if(msg.value >= tradeArray[contractID].acceptorSecurityFee){
                tradeArray[contractID].accepted = true;
            }else{
                sendInsufficentFundingError(tradeArray[contractID].acceptorSecurityFee);
            }
        }if(tradeArray[contractID].acceptorAddress == address(0) && tradeArray[contractID].accepted == false && tradeArray[contractID].active == true){
            if(msg.value >= tradeArray[contractID].acceptorSecurityFee){
                tradeArray[contractID].accepted = true;
            }else{
                sendInsufficentFundingError(tradeArray[contractID].acceptorSecurityFee);
            }
        }else{
            revert Unauthorized();
        }   
    }

    //concludeContract (can be called by contractCreator & contractAcceptor) 
    function concludeTrade(uint256 contractID) external {
        if (msg.sender == tradeArray[contractID].creatorAdress){
            tradeArray[contractID].creatorAccepted = true;
        }if(msg.sender == tradeArray[contractID].acceptorAddress){
            tradeArray[contractID].acceptorAccepted = true;
        }if(msg.sender == tradeArray[contractID].creatorAdress && tradeArray[contractID].acceptorAccepted == true && tradeArray[contractID].active == true){
            tradeArray[contractID].creatorAccepted = true;
            tradeArray[contractID].creatorAdress.transfer(tradeArray[contractID].creatorSecurityFee-contractFee);
            tradeArray[contractID].acceptorAddress.transfer(tradeArray[contractID].acceptorSecurityFee-contractFee);
            profit = profit + contractFee + contractFee;
            tradeArray[contractID].concluded = true;
        }if(msg.sender == tradeArray[contractID].acceptorAddress && tradeArray[contractID].creatorAccepted == true && tradeArray[contractID].active == true){
            tradeArray[contractID].acceptorAccepted = true;
            tradeArray[contractID].creatorAdress.transfer(tradeArray[contractID].creatorSecurityFee-contractFee);
            tradeArray[contractID].acceptorAddress.transfer(tradeArray[contractID].acceptorSecurityFee-contractFee);
            profit = profit + contractFee + contractFee;
            tradeArray[contractID].concluded = true;
        }else{
            revert Unauthorized();
        }
    }

    // - private (can only be called by owner) -
    function payoutProfits() external payable{
        if(msg.sender == owner && profit != 0){
            owner.transfer(profit);
        }else{
            revert Unauthorized();
        }
    }
    function changeFeeAmount(uint8 gweiAmount) external{
        if(msg.sender == owner){
            contractFee = gweiAmount;
        }else{
            revert Unauthorized();
        }
    }
    function cleanoutConcludedTrades() external{
        if(msg.sender == owner){
            for(uint i=0; i < tradeArray.length; i++){
                if(tradeArray[i].concluded == true){
                   delete tradeArray[i];
                }
            } 
        }else{
            revert Unauthorized();
        }
    }

    // -internal (only called by other functions) -
    function sendInsufficentFundingError(uint256 required) internal{
        revert InsufficentFunding(msg.value, required);
    }  
}