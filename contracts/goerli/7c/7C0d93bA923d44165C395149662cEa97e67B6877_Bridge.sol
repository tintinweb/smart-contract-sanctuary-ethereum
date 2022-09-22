/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//Interface for interacting with erc20
interface ERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address owner) external returns (uint256);

    function decimals() external returns (uint256);
}
contract Bridge{
    //addresses owners
    address[6] private owners = [0x49939aeD5D127C2d9a056CA1aB9aDe9F79fa8E81,0xA3656dc1EC5eF6779ba920B6d20157f4A169A30B,0xdC498209DeeCb868ACe2D47e137AfA52D6E1256e,0x603C3524C018F22fC7EdB1e8a64219659C4b1794,0x7F385879d165448046d3967121f7c56AE9794252];//[0x4cB57ffC74460772C84e07B684cF59b730802810,0x2C87D8F4EBcd05bE72EFbbd2fc6C6A000C8af854,0x122a2121A99a0CFC7104CD5EeAbE7FFfEd7F4da1];//add 3 owners;
    address[] private bridgeNode = [0x49939aeD5D127C2d9a056CA1aB9aDe9F79fa8E81,0xBe87EF5F4faA1F22B33d16196AF277c6a098E658,0xA3656dc1EC5eF6779ba920B6d20157f4A169A30B,0xdC498209DeeCb868ACe2D47e137AfA52D6E1256e,0x603C3524C018F22fC7EdB1e8a64219659C4b1794,0x7F385879d165448046d3967121f7c56AE9794252];
    uint nextToVote; //consensus number
    uint del;//consensus number for delet rootNode
    uint add;//consensus number for addNode
    uint nextToVoteUnl;
    address owner;
    uint startBlock;
    uint networkId ; // chain network id
    bool pause;
    
    
    //this mapping is necessary so that the owner cannot vote 2 or more times
    mapping(address => uint) acceptance;
    mapping(address => bool) public unlockConfirm;
    

   
    constructor(uint network){
        startBlock = block.number;
        networkId = network;
    }

   
    //looking for the owner in the owner array
    modifier Owners() {
        bool confirmation;
        for (uint8 i = 0; i < owners.length; i++){
            if(owners[i] == msg.sender){
                confirmation = true;
                break;
            }
        }
        require(confirmation ,"You are not on the list of owners");
        _;
    }

    modifier bridgeNodes() {
        bool success;
        for (uint8 i = 0; i < bridgeNode.length; i++){
            if(bridgeNode[i] == msg.sender){
                success = true;
                break;
            }
        }
        require(success,"you are not bridge nodes");
        _;
        
    }

    event Locked(uint time,
        address sender,
        uint value,
        string walletCN,
        address tokenAddress,
        string token_symbol,
        uint networkId,
        uint _block
        );

    event Consensus(address sender,
        uint answer,
        uint countVote
    );

    event proposeNode(
        address owner,
        address propose,
        uint timestamp
    );

    event Unlock(
        address sender,
        address tokenAdress,
        uint value,
        uint networkId
    );

    
    function chekUnlCons() external view returns(uint){
        return nextToVoteUnl;
    }



    function Time() view public returns(uint){
        return block.timestamp;
        

    }
    function seeNode ()view external returns(address[]memory){
        return bridgeNode;
    }
    function checkDel() view external  returns(uint){
        return del;
    }

    function checkAdd()view external returns(uint){
        return add;
    }

    function pauseLock(bool answer) external Owners returns(bool){
        pause = answer;
        return pause;
    }
        
    //shows how many votes there are already in the consensus
    function numberVote() view external Owners returns (uint){
        return nextToVote;
    }

    //the function adds root nodes to the array(funcID == 0 )
    function addRootNode(address newBridgeNode) external Owners{
        require(newBridgeNode != address(0),"Address must not be null");
        require(add >= 2,"Consensus not reached");
        bridgeNode.push(newBridgeNode);

        //after adding, the consensus counter is reset to zero
        for (uint i = 0; i < owners.length; i++){
            acceptance[owners[i]] = 0;
        }
        nextToVote = 0;
        add = 0; 

        emit proposeNode(msg.sender,newBridgeNode,block.timestamp);    
        
    }

    //@dev blocks user tokens, considers sum arguments, network index, token address
    function lockToken(uint amount,string memory walletCN,address token_address,string memory token_symbol) external returns (bool) {
        require(amount > 0,"The amount must be greater than zero");
        require(token_address != address(0),"Address must not be null");
        require(pause == false,"Bridge paused");
        //sending a token to a smart contract (approve must be done before sending)
        ERC20(token_address).transferFrom(msg.sender,address(this),amount);      
        emit Locked(block.timestamp,msg.sender,amount,walletCN,token_address,token_symbol,networkId,block.number);
        return true;
    }

    function agreeUnlock(uint _answer) external bridgeNodes{
        require(_answer <= 1,"Enter 0 or false 1 or yes");
        require(!unlockConfirm[msg.sender],"You voted");
        
        nextToVoteUnl ++;
        unlockConfirm[msg.sender] = true;
        if(_answer == 0) {
            nextToVoteUnl = 0;
            unlockConfirm[msg.sender] = false;
        }
        emit Consensus(msg.sender,_answer,nextToVoteUnl);
    } 

    //@dev consensus acceptance, takes 2 arguments first uint where 1 is agree, 0 disagree, 2 is the argument you choose the feature you vote for
    function agree(uint _answer,uint _funcID) external Owners{
        require(_answer <= 1,"Enter 0 or false 1 or yes");
        require(_funcID <= 1,"Enter 0 or addNode 1 or delNode");
        require(acceptance[msg.sender] == 0,"You voted");
        require(nextToVote < 3,"Consensus already reached");

        if(_answer == 1){
            nextToVote ++;
            acceptance[msg.sender] = nextToVote; 
            }
            if(_funcID == 0 ){
                add ++;
            }
            else if(_funcID == 1){
                del ++;
            }
            
        else {
            nextToVote = 0;   
        }
    
    }

    
    function unlockToken(address sender,address token_address,uint amount) external bridgeNodes {
        require(sender != address(0) && token_address != address(0),"Address must not be null");
        require(nextToVoteUnl >=2,"No consensus reached between nodes");
        
        ERC20(token_address).transfer(    
            sender,
            amount);

         for (uint i = 0; i < bridgeNode.length; i++){
            acceptance[bridgeNode[i]] = 0;
            unlockConfirm[bridgeNode[i]] = false;
         }
         nextToVoteUnl = 0;
         
         emit Unlock(sender,token_address,amount,networkId);
    }


    //function to remove address from array node by its index (funcID == 1)
    function delRootNode (uint index) external Owners returns(address[]memory) {
        require(del >= 2,"Consensus not reached for deletion");
        require(index <= bridgeNode.length,"Node index cannot be higher than their number"); // index must be less than or equal to array length

        for (uint i = index; i < bridgeNode.length-1; i++){
            bridgeNode[i] = bridgeNode[i+1];
        }

        delete bridgeNode[bridgeNode.length-1];
        bridgeNode.pop();
        
        for (uint i = 0; i < owners.length; i++){
            acceptance[owners[i]] = 0;
        }
        nextToVote = 0;
        del = 0;
        return bridgeNode;
    }


    //dropping all if you did not come to unanimous votes or voted for different functions, you can cancel the voting completely
    function droppingAllVoute() external Owners {
        nextToVote = 0;
        add = 0;
        del = 0;
        nextToVoteUnl = 0;
        for (uint i = 0; i < owners.length; i++){
            acceptance[owners[i]] = 0;
        }
        for (uint i = 0; i < bridgeNode.length; i++){
            acceptance[bridgeNode[i]] = 0;
            unlockConfirm[bridgeNode[i]] = false;
        }
        
    } 
    
}