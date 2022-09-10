/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract GoerliBridge {

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

    // MockOptimismBridge public optimismBridgeInstance;

    mapping(uint => address) public queue; //Modified from //https://programtheblockchain.com/posts/2018/03/23/storage-patterns-stacks-queues-and-deques/

    uint256 public last; //Do not declare 0 directly, will waste gas.
    uint256 public first = 1;

    function enqueue() private { //Should not be called outside of contract or by anyone else, private.
        last += 1;
        queue[last] = msg.sender;
    }

    function dequeue() public { 
        // if (address(optimismBridgeInstance) == address(0) || msg.sender != address(optimismBridgeInstance) || last < first) { revert notExternalBridge(); } //Protect function external with owner call
        if (msg.sender != Owner) { revert notOwnerAddress(); }
        if (last < first) { revert queueIsEmpty(); } //Removed require for this since it costs less gas.
        delete queue[first];
        first += 1;
    }

    function lockTokensForOptimism(uint bridgeAmount) public payable {
        if (bridgeAmount < 1000) { revert msgValueLessThan1000(); }
        if (msg.value != (1003*bridgeAmount)/1000 ) { revert msgValueDoesNotCoverFee(); }
        // if (address(optimismBridgeInstance) == address(0) || address(optimismBridgeInstance).balance < bridgeAmount ) { revert bridgeOnOtherSideNeedsLiqudity(); }
        lockedForOptimismETH[msg.sender] += (1000*msg.value)/1003;
        enqueue();
        payable(Owner).transfer(msg.value);
    }

    function ownerUnlockGoerliETH(address userToBridge, uint lockedForGoerliETH) public {
        if (msg.sender != Owner) { revert notOwnerAddress(); }
        // if (address(optimismBridgeInstance) == address(0) || optimismBridgeInstance.last() < optimismBridgeInstance.first()) { revert queueIsEmpty(); } //Removed require for this since it costs less gas.
        // address userToBridge = optimismBridgeInstance.queue(optimismBridgeInstance.last());
        // optimismBridgeInstance.dequeue(); //Only this contract address set from the other contract from owner can call this function.
        uint sendETH = lockedForGoerliETH- goerliBridgedETH[userToBridge];
        goerliBridgedETH[userToBridge] += sendETH;
        payable(userToBridge).transfer(sendETH);
    }

    function ownerAddBridgeLiqudity() public payable {
        if (msg.sender != Owner) { revert notOwnerAddress(); }
        if (msg.value == 0) { revert msgValueZero(); }
    }

    function ownerRemoveBridgeLiqudity() public  {
        if (msg.sender != Owner) { revert notOwnerAddress(); }
        if (address(this).balance == 0) { revert bridgeEmpty(); }
        // if (address(optimismBridgeInstance) == address(0) || optimismBridgeInstance.last() >= optimismBridgeInstance.first()) { revert queueNotEmpty(); } //Removed require for this since it costs less gas.
        payable(Owner).transfer(address(this).balance);
    }

}