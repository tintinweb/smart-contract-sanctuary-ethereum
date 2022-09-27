/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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
    address[] private owners = [0x4cB57ffC74460772C84e07B684cF59b730802810,0x2C87D8F4EBcd05bE72EFbbd2fc6C6A000C8af854,0x122a2121A99a0CFC7104CD5EeAbE7FFfEd7F4da1];//add 3 owners;
    address[] private bridgeNode;
    uint8 private nextToVote; //consensus number
    uint8 private del;//consensus number for delet rootNode
    uint8 private add;//consensus number for addNode
    uint8 private nextToVoteUnl;
    address owner;
    uint startBlock;
    uint networkId ; // chain network id
    bool pause;
    uint8 private minVouteToNode = 2;
    uint8 private minVouteToOwners = 2;

    uint8 private votesMinVouteNode;
    uint8 private votesMinVouteOwners;


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

    function seeMinVoteToOwners() view public returns(uint){
        return minVouteToOwners;
    }
    function setMinVoteToOwners(uint8 minVote) external Owners{
        require(votesMinVouteOwners >= minVouteToOwners);
        minVouteToOwners = minVote;
        for (uint i = 0; i < owners.length; i++){
            acceptance[owners[i]] = 0;
        }
        votesMinVouteOwners = 0;
    }

    function seeMinVoteToNode() view public returns(uint){
        return minVouteToNode;
    }

    function setMinVoteToNode(uint8 minVote) external Owners{
        require(votesMinVouteNode >= minVouteToOwners);
        minVouteToNode = minVote;
        for (uint i = 0; i < owners.length; i++){
            acceptance[owners[i]] = 0;
        }
        votesMinVouteNode = 0;
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
    function addNode(address newBridgeNode) external Owners{
        require(newBridgeNode != address(0),"Address must not be null");
        require(add >= minVouteToOwners,"Consensus not reached");
        bridgeNode.push(newBridgeNode);

        //after adding, the consensus counter is reset to zero
        for (uint i = 0; i < owners.length; i++){
            acceptance[owners[i]] = 0;
        }
        nextToVote = 0;
        add = 0;

        emit proposeNode(msg.sender,newBridgeNode,block.timestamp);

    }

    function addOwners(address newowner) external Owners{
        require(newowner != address(0),"Address must not be null");
        require(add >= minVouteToOwners,"Consensus not reached");
        owners.push(newowner);

        //after adding, the consensus counter is reset to zero
        for (uint i = 0; i < owners.length; i++){
            acceptance[owners[i]] = 0;
        }
        nextToVote = 0;
        add = 0;

        emit proposeNode(msg.sender,newowner,block.timestamp);

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
        }
        emit Consensus(msg.sender,_answer,nextToVoteUnl);
    }

    //@dev consensus acceptance, takes 2 arguments first uint where 1 is agree, 0 disagree, 2 is the argument you choose the feature you vote for
    function agree(uint _answer,uint _funcID) external Owners{
        require(_answer <= 1,"Enter 0 or false 1 or yes");
        require(acceptance[msg.sender] == 0,"You voted");
        

        if(_answer == 1){
            nextToVote ++;
            acceptance[msg.sender] = nextToVote;
            
            if(_funcID == 0 ){
                add ++;
            }
            else if(_funcID == 1){
                del ++;
            }
            else if(_funcID ==2){
                votesMinVouteNode ++;
            }
            else if(_funcID ==3){
                votesMinVouteOwners ++;
            }
           
        }
        else{
            for (uint i = 0; i < owners.length; i++){
            acceptance[owners[i]] = 0;
        }
            nextToVote = 0;
            add = 0;
            nextToVoteUnl = 0;
            votesMinVouteNode = 0;
            votesMinVouteOwners = 0;
        }

    }


    function unlockToken(address sender,address token_address,uint amount) external bridgeNodes {
        require(sender != address(0) && token_address != address(0),"Address must not be null");
        require(nextToVoteUnl >= minVouteToNode,"No consensus reached between nodes");

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
        require(del >= minVouteToOwners,"Consensus not reached for deletion");
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

    function delOwners(uint index) external Owners  {
        require(del >= minVouteToOwners,"Consensus not reached for deletion");
        require(index <= owners.length,"Node index cannot be higher than their number"); // index must be less than or equal to array length

        for (uint i = index; i < owners.length-1; i++){
            owners[i] = owners[i+1];
        }

        delete owners[owners.length-1];
        owners.pop();

        for (uint i = 0; i < owners.length; i++){
            acceptance[owners[i]] = 0;
        }
        nextToVote = 0;
        del = 0;
        
    }


    //dropping all if you did not come to unanimous votes or voted for different functions, you can cancel the voting completely
    function droppingAllVoute() external Owners {
        nextToVote = 0;
        add = 0;
        del = 0;
        nextToVoteUnl = 0;
        votesMinVouteNode = 0;
        votesMinVouteOwners = 0;
        for (uint i = 0; i < owners.length; i++){
            acceptance[owners[i]] = 0;
        }
        for (uint i = 0; i < bridgeNode.length; i++){
            acceptance[bridgeNode[i]] = 0;
            unlockConfirm[bridgeNode[i]] = false;
        }

    }

}