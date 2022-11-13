/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.16 <0.9.0;

contract SwapRespond {
    enum Status {
        Blank,
        Initiated,
        Locked, // initiatorAddress was locked by buyer
        Refunded, // ETH was refunded to buyer
        Performed // ETH was sucessfully claimed by order initiators
    }

    struct respondOrder {
        address initiatorEthAddress;
        address buyerOntAddress;
        address buyerEthAddress;
        bytes32 hashlock;
        uint mxbid;
        uint refundTimelock;
        uint bidTimelock;
        string secret;
        Status status;
    }

    mapping (bytes32 => respondOrder) public orderList; // hashlock => order data
    uint timelockDuration = 120; // set to 120 seconds for testing purposes
    uint bidtime = 120; //set to 120 seconds for testing

    // //Can we do it without this function
    // function initiateBid(bytes32 hashlock, uint bidtime) {
    //     orderList[hashlock].bidTimelock = block.timestamp + 120;
    // }

    function bid(bytes32 hashlock, uint bidprice, address buyerOntAddress) public {
        if((orderList[hashlock].bidTimelock!=0) && (block.timestamp>orderList[hashlock].bidTimelock) && (block.timestamp-orderList[hashlock].bidTimelock>610)){
            clear(hashlock);
        }
        require(orderList[hashlock].status == Status.Initiated || orderList[hashlock].status==Status.Blank, "Transaction Invalid");
        if (orderList[hashlock].status==Status.Blank){
            orderList[hashlock].bidTimelock = block.timestamp + bidtime;
        }
        require(block.timestamp<=orderList[hashlock].bidTimelock, "Bidding Period Ended");
        require(bidprice>orderList[hashlock].mxbid,"Bidding price should be greater than the highest bid");
        // If no one bid for the exchange control won't come here
        orderList[hashlock].mxbid = bidprice;
        orderList[hashlock].buyerEthAddress = msg.sender;   
        orderList[hashlock].buyerOntAddress = buyerOntAddress;     
        orderList[hashlock].status = Status.Initiated;
    }

    
    //respond to order by locking ether and setting initiator address
    function lockandset (bytes32 hashlock, address initiatorEthAddress) public payable{
        require(orderList[hashlock].bidTimelock+240>block.timestamp, "Locking time period finished");
        require(orderList[hashlock].status==Status.Initiated, "Wrong state");
        require(orderList[hashlock].buyerEthAddress==msg.sender, "Access Denied"); //Only max bidder can enter
        require(orderList[hashlock].mxbid==msg.value, "Value mismatch");
        orderList[hashlock].initiatorEthAddress = initiatorEthAddress;
        orderList[hashlock].refundTimelock = block.timestamp + timelockDuration;
        orderList[hashlock].status = Status.Locked;
    }

    function claimEth (bytes32 hashlock, string memory secret) public {
        require(orderList[hashlock].initiatorEthAddress == msg.sender, "Can only be perfomed by initiator");
        require(orderList[hashlock].status == Status.Locked, "Order status should be Locked");
        require(orderList[hashlock].refundTimelock>block.timestamp, "Claim Time Finished");
        require(sha256(abi.encodePacked(secret)) == hashlock, "Secret does not match the hashlock");
        
        orderList[hashlock].secret = secret;
        orderList[hashlock].status = Status.Performed;
        payable(msg.sender).transfer(orderList[hashlock].mxbid);

        //Transaction Finished. Make the hash ready for probable other txn
        clear(hashlock);
    }

    function refundEth (bytes32 hashlock) public payable {
        require(orderList[hashlock].buyerEthAddress == msg.sender, "Can only be perfomed by order initiator");
        require(orderList[hashlock].status == Status.Locked, "Order should be in locked state for refund");
        require(block.timestamp >= orderList[hashlock].refundTimelock, "Timelock is not over");

        orderList[hashlock].status = Status.Refunded;
        payable(msg.sender).transfer(orderList[hashlock].mxbid);

        //Transaction Finished. Make the hash ready for probable other txn
        clear(hashlock);
    }

    function clear(bytes32 hashlock) private {
        orderList[hashlock] = respondOrder({
            buyerOntAddress: address(0),
            buyerEthAddress: address(0),
            initiatorEthAddress: address(0),
            hashlock: bytes32(0),
            mxbid: 0,
            refundTimelock: 0,
            bidTimelock: 0,
            secret: "",
            status: Status.Blank
        });
    }
}