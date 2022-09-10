/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MockGoerliBridge {

    address public immutable Owner;    

    mapping(address => uint) public lockedForOptimismETH;
    mapping(address => uint) public goerliBridgedETH;

    error msgValueZero(); //Using custom errors with revert saves gas compared to using require. 
    error msgValueLessThan1000(); 
    error msgValueDoesNotCoverFee(); 
    error notOwnerAddress();
    error bridgedAlready();
    error bridgeOnOtherSideNeedsLiqudity();
    error bridgeEmpty();
    error ownerBridgeUsersBeforeWithdraw();
    error queueIsEmpty();
    error queueNotEmpty();
    error notExternalBridge();

    constructor() {
        Owner = msg.sender;
    }

    MockOptimismBridge public optimismBridgeInstance;    

    // struct addressBridgeBalance{
    //     address userToBridge;
    //     uint bridgeAmount;
    // }

    // mapping(uint => addressBridgeBalance) public queue; 
    mapping(uint => address) public queue; //Modified from //https://programtheblockchain.com/posts/2018/03/23/storage-patterns-stacks-queues-and-deques/

    uint256 public last; //Do not declare 0 directly, will waste gas.
    uint256 public first = 1; 

    function enqueue() private { //Should not be called outside of contract or by anyone else, private.
        last += 1;
        // queue[last].userToBridge = msg.sender;
        // queue[last].bridgeAmount = bridgeAmount;
        queue[last] = msg.sender;
    }

    function dequeue() external { //Gets called by the other bridge contract, external.
        if (msg.sender != address(optimismBridgeInstance) && address(optimismBridgeInstance) != address(0)) { revert notExternalBridge(); } //Protect function external with owner call
        if (last < first) { revert queueIsEmpty(); } //Removed require for this since it costs less gas. 
        delete queue[first];
        first += 1;
    }

    function lockTokensForOptimism(uint bridgeAmount) public payable {
        if (bridgeAmount < 1000) { revert msgValueLessThan1000(); } 
        if (msg.value != (1003*bridgeAmount)/1000 ) { revert msgValueDoesNotCoverFee(); } 
        if (address(optimismBridgeInstance).balance < bridgeAmount) { revert bridgeOnOtherSideNeedsLiqudity(); } 
        lockedForOptimismETH[msg.sender] += (1000*msg.value)/1003;
        enqueue();
        payable(Owner).transfer(msg.value);
    }

    function ownerUnlockOptimismETH() public {
        
        //MAYBE WE DON'T NEED THE STRUCT AND JUST LOOK AT QUEUE FOR LOCKED AMOUNT????
        // (address userToBridge, uint bridgeAmount) = goerliBridgeInstance.queue(goerliBridgeInstance.last());
        if (msg.sender != Owner) { revert notOwnerAddress(); } 
        if (optimismBridgeInstance.last() < optimismBridgeInstance.first()) { revert queueIsEmpty(); } //Removed require for this since it costs less gas. 
        address userToBridge = optimismBridgeInstance.queue(optimismBridgeInstance.last());
        optimismBridgeInstance.dequeue(); //Only this contract address set from the other contract from owner can call this function.
        uint sendETH = optimismBridgeInstance.lockedForGoerliETH(userToBridge)- goerliBridgedETH[userToBridge];
        goerliBridgedETH[userToBridge] += sendETH;
        payable(userToBridge).transfer(sendETH);
    }

    function ownerAddBridgeLiqudity() public payable {
        if (msg.sender != Owner) { revert notOwnerAddress(); } 
        if (msg.value == 0) { revert msgValueZero(); } 
    }

    function ownerRemoveBridgeLiqudity() public  {
        if (address(this).balance == 0) { revert bridgeEmpty(); } 
        if (optimismBridgeInstance.last() >= optimismBridgeInstance.first()) { revert queueNotEmpty(); } //Removed require for this since it costs less gas. 
        payable(Owner).transfer(address(this).balance);
    }

    function mockOwnerOptimismBridgeAddress(address _token) public{
        if (msg.sender != Owner) { revert notOwnerAddress(); } 
        optimismBridgeInstance = MockOptimismBridge(_token); 
    }

}

contract MockOptimismBridge {

    address public immutable Owner;    

    mapping(address => uint) public lockedForGoerliETH;
    mapping(address => uint) public optimismBridgedETH;
    
    error msgValueZero(); //Using custom errors with revert saves gas compared to using require. 
    error msgValueLessThan1000(); 
    error msgValueDoesNotCoverFee(); 
    error notOwnerAddress();
    error bridgeEmpty();
    error queueIsEmpty();
    error queueNotEmpty();
    error notExternalBridge();
    
    MockGoerliBridge public goerliBridgeInstance;

    mapping(uint => address) public queue; 

    uint256 public last; //Do not declare 0 directly, will waste gas.
    uint256 public first = 1; 

    function enqueue() private { //Should not be called outside of contract or by anyone else, private.
        last += 1;
        queue[last] = msg.sender;
    }

    function dequeue() external { //Removed return value, not needed.
        if (msg.sender != address(goerliBridgeInstance) && address(goerliBridgeInstance) != address(0)) { revert notExternalBridge(); } //Protect function external with owner call
        if (last < first) { revert queueIsEmpty(); } //Removed require for this since it costs less gas. 
        delete queue[first];
        first += 1;
    }

    constructor() {
        Owner = msg.sender;
    }

    function lockTokensForGoerli(uint bridgeAmount) public payable {
        if (bridgeAmount < 1000) { revert msgValueLessThan1000(); } 
        if (msg.value != (1003*bridgeAmount)/1000 ) { revert msgValueDoesNotCoverFee(); } 
        lockedForGoerliETH[msg.sender] += (1000*msg.value)/1003;
        enqueue();
        payable(Owner).transfer(msg.value);
    }

    function ownerUnlockOptimismETH() public {
        if (msg.sender != Owner) { revert notOwnerAddress(); } 
        if (goerliBridgeInstance.last() < goerliBridgeInstance.first()) { revert queueIsEmpty(); } //Removed require for this since it costs less gas. 
        address userToBridge = goerliBridgeInstance.queue(goerliBridgeInstance.last());
        goerliBridgeInstance.dequeue(); //Only this contract address set from the other contract from owner can call this function.
        uint sendETH = goerliBridgeInstance.lockedForOptimismETH(userToBridge)- optimismBridgedETH[userToBridge];
        optimismBridgedETH[userToBridge] += sendETH;
        payable(userToBridge).transfer(sendETH);
    }

    function ownerAddBridgeLiqudity() public payable {
        if (msg.sender != Owner) { revert notOwnerAddress(); } 
        if (msg.value == 0) { revert msgValueZero(); } 
    }

    function ownerRemoveBridgeLiqudity() public  {
        if (address(this).balance == 0) { revert bridgeEmpty(); } 
        if (goerliBridgeInstance.last() >= goerliBridgeInstance.first()) { revert queueNotEmpty(); } //Removed require for this since it costs less gas. 
        payable(Owner).transfer(address(this).balance);
    }

    function mockOwnerOptimismBridgeAddress(address _token) public{
        if (msg.sender != Owner) { revert notOwnerAddress(); } 
        goerliBridgeInstance = MockGoerliBridge(_token); 
    }

}