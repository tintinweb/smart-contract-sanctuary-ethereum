// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Asset {
    // Current owner of the slot.
    address payable public Owner;
    // Previous Owner of the slot.
    address payable public PreviousOwner; 
    // User-settable price.
    uint256 public P;
    // Content.
    string public V;
    // Current ownership remaining time.
    uint256 public currentOwnershipRemainingTime;
    
    // Contract owner.
    address payable immutable public Issuer;
    // Ownership duration
    // Owner controls the slot only for this period.
    uint256 immutable public Q;
    // Harberger Hike
    // Additional tax for the Purchaser when he buys the slot. 
    // Paid to the Issuer.
    uint256 immutable public HH;
    // Harberger Tax
    // Additional tax for the Purchaser when he buys the slot. 
    // Paid to the previous Owner.
    uint256 immutable public HT;
    // Initial Price
    // The price of the first purchase should be greater than this value.
    uint256 immutable public IP;

    uint256 public constant PCT_BASE = 100;

    event OwnershipTimeExtended(address owner, uint256 currentTime, uint256 ownershipRemainingTime);
    event SlotPurchaised(address owner, address previousOwner, uint256 ownershipRemainingTime);
    event TimeOfOwnershipIsUp(address owner, uint256 currentTime);
    event ContentChanged(address owner, string content);

    /**
     * Check if caller is Owner of the slot.
     */
    modifier onlyOwner() {
        require(msg.sender == Owner, "Only current owner of the asset can do it.");
        _;
    }
    
    /**
     * Check if there are enough funds.
     */
    modifier enoughFunds() {
        if (Owner == Issuer) {
            require(msg.value >= (IP + (IP * HT / PCT_BASE)), "The purchase price cannot be lower than the initial price + tax paid to the issuer.");
            _;
        } else {
            require(msg.value >= (P + (P * HT / PCT_BASE) + (P * HH / PCT_BASE)), "The purchase price cannot be lower than the last price (P) + tax paid to the last buyer (P * HT) + tax paid to the issuer of the contract (P * HH).");
            _;
        }
    }

    constructor(uint256 q, uint256 hh, uint256 ht, uint256 ip, string memory v) {
        Q = q;
        V = v;
        IP = ip;
        P = ip;
        HH = hh;
        HT = ht;
        Issuer = payable(msg.sender);
        Owner = payable(msg.sender);
    }

    /**
     * Buy the slot.
     */
    function buy() external payable enoughFunds() {
        if (Owner == Issuer) {
            Owner = payable(msg.sender);
            P = PCT_BASE * msg.value / (PCT_BASE + HT);
            Issuer.transfer(msg.value);
            currentOwnershipRemainingTime = block.timestamp + Q;
            emit SlotPurchaised(Owner, Issuer, currentOwnershipRemainingTime);
        } else {
            PreviousOwner = Owner;
            Owner = payable(msg.sender);
            P = PCT_BASE * msg.value / (PCT_BASE + HT + HH);
            Issuer.transfer(P * HT / PCT_BASE);
            PreviousOwner.transfer(P + (P * HT / PCT_BASE));
            currentOwnershipRemainingTime = block.timestamp + Q;
            emit SlotPurchaised(Owner, Issuer, currentOwnershipRemainingTime);
        }
    }

    /**
     * Prolong ownership time.
     */
    function prolongdOwnershipTime() external payable onlyOwner {
        require(Issuer != Owner);
        require(block.timestamp <= currentOwnershipRemainingTime, "Time is up");
        require(((currentOwnershipRemainingTime - block.timestamp) / Q) <= 1, "Owner can prolong his ownership for only one period Q in advance");
        require(msg.value ==  (P * HT / PCT_BASE), "Owner can prolong his ownership for only one period Q in advance.");
        currentOwnershipRemainingTime += Q;
        emit OwnershipTimeExtended(Owner, block.timestamp, currentOwnershipRemainingTime);
    }

    /**
     * Check if time of ownership is up.
     */
    function checkTime() external returns(uint256) {
        uint256 leftTime = currentOwnershipRemainingTime - block.timestamp;
        if (leftTime <= 0) {
            PreviousOwner = Owner;
            Owner = Issuer;
            P = 0;
            currentOwnershipRemainingTime = 0;
            emit TimeOfOwnershipIsUp(PreviousOwner, block.timestamp);
            return 0;
        }
        return leftTime;
    }

    /** 
     * Set content of the slot.
     */
    function setContent(string calldata content) external onlyOwner {
        V = content;
        emit ContentChanged(Owner, content);
    }
}