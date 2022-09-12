/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MockGoerliBridge {

    address public immutable Owner;

    error msgValueZero(); //Using custom errors with revert saves gas compared to using require.
    error msgValueNot1003();
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

    mapping(uint => address) public queue; //Modified from //https://programtheblockchain.com/posts/2018/03/23/storage-patterns-stacks-queues-and-deques/

    uint256 public last; //Do not declare 0 directly, will waste gas.
    uint256 public first = 1;

    function enqueue() private { //Should not be called outside of contract or by anyone else, private.
        last += 1;
        queue[last] = msg.sender;
    }

    function dequeue() external { //Gets called by the other bridge contract, external.
        // if (address(optimismBridgeInstance) == address(0) || msg.sender != address(optimismBridgeInstance) || last < first) { revert notExternalBridge(); } //Protect function external with owner call
        if (msg.sender != Owner) { revert notOwnerAddress(); }
        if (last < first) { revert queueIsEmpty(); } //Removed require for this since it costs less gas.
        delete queue[first];
        first += 1;
    }

    function lockTokensForOptimism() public payable {
        if (msg.value != 1003 ) { revert msgValueNot1003(); }
        // if (address(optimismBridgeInstance) == address(0) || (((last+2)-first)*1000) > address(optimismBridgeInstance).balance  ) { revert bridgeOnOtherSideNeedsLiqudity(); }
        enqueue();
        payable(Owner).transfer(msg.value);
    }

    function ownerUnlockGoerliETH(address userToBridge) public {
        if (msg.sender != Owner) { revert notOwnerAddress(); }
        // if (address(optimismBridgeInstance) == address(0) || optimismBridgeInstance.last() < optimismBridgeInstance.first()) { revert queueIsEmpty(); } //Removed require for this since it costs less gas.
        // address userToBridge = optimismBridgeInstance.queue(optimismBridgeInstance.last());
        // optimismBridgeInstance.dequeue(); //Only this contract address set from the other contract from owner can call this function.
        payable(userToBridge).transfer(1000);
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