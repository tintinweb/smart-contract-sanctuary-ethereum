/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

contract Leasing {
    // Define a structure for Rental property Lease Agreement
    struct Lease {
        address payable landlord; // The landlord
        address payable tenant; // The tenant
        string location; // Property location
        uint term; // Lease term
        uint rent; // Monthly rent
        uint securityDeposit; // Security deposit
        uint earlyPenalty; // Early termination penalty
        uint creationTimestamp; // Creation timestamp
        uint signedTimestamp; // Contract retification timestamp
        uint moveinTimestamp; // The tenant occupation timestamp
    }

    // Keep a record of all payments and account balance
    struct Deposit {
        uint sequence;
        uint amount;
    }

    // Define the state machine for leasing
    enum LeaseState { Created, Signed, Occupied, Terminated }

    // Lease as the state variable
    Lease public lease;

    // Keep track of state transition of leasing application
    LeaseState public state;

    Deposit[] public deposits;
    uint public balance = 0;
    uint public totalReceived = 0;

    // Keep track of security deposit received
    uint public securityDeposited;

    // Start the lease
    constructor(uint _rent, uint _term, uint _securityDeposit, uint _earlyPenalty, string memory _location) payable {
        lease.landlord = payable(msg.sender);
        lease.location = _location;
        lease.rent = _rent;
        lease.term = _term;
        lease.securityDeposit = _securityDeposit;
        lease.earlyPenalty = _earlyPenalty;
        lease.creationTimestamp = block.timestamp;
        state = LeaseState.Created;
    }

    // Define function modifier restricting actions per state
    modifier inState(LeaseState _state) {
        if (state != _state) {
            revert();
        }
        _;
    }

    // Define function modifier restricting to landlord only
    modifier onlyLandlord() {
        if (msg.sender != lease.landlord) {
            revert();
        }
        _;
    }

    // Define function modifier excluding the landlord
    modifier notLandLord() {
        if (msg.sender == lease.landlord) {
            revert();
        }
        _;
    }

    // Define function modifier restricting to tenant only
    modifier onlyTenant() {
        if (msg.sender != lease.tenant) {
            revert();
        }
        _;
    }

    // Define function modifier requiring pay in full
    modifier payInFull(uint _rent) {
        if (_rent < lease.rent) {
            revert();
        }
        _;
    }

    event securityDepositPaid(address indexed _tenant, uint _amount, uint _timestamp);

    event leaseSigned(address indexed _tenant, uint _signedTimestamp);

    event rentPaid(address indexed _tenant, uint _timestamp);

    event leaseTerminated(address indexed _by, string _reason, uint _timestamp);

    // Lease signed by the tenant
    function signLease() public payable inState(LeaseState.Created) notLandLord {
        lease.tenant = payable(msg.sender);
        securityDeposited = msg.value;

        require(securityDeposited >= lease.securityDeposit);

        lease.signedTimestamp = block.timestamp;
        state = LeaseState.Signed;

        emit leaseSigned(lease.tenant, lease.signedTimestamp);
    }

    // Tenant move in
    function moveIn() public inState(LeaseState.Signed) onlyTenant {
        lease.moveinTimestamp = block.timestamp;
        state = LeaseState.Occupied;
    }

    // Pay the monthly rent, and keep a record
    function payRent() public payable onlyTenant inState(LeaseState.Occupied) payInFull(msg.value + balance) {
        emit rentPaid(lease.tenant, block.timestamp);

        totalReceived++;
        balance += msg.value - lease.rent; // keep track of balance
        deposits.push(Deposit({sequence: totalReceived, amount: msg.value}));
        lease.landlord.transfer(msg.value);
    }

    // Terminate the lease when it is mature
    function leaseDue() public inState(LeaseState.Occupied) onlyLandlord {
        emit leaseTerminated(lease.landlord, "lease due", block.timestamp);

        // If lease term is due, return security deposit to the tenant, and the rest to landlord
        require(totalReceived >= lease.term);

        state = LeaseState.Terminated;
        lease.tenant.transfer(securityDeposited);
        lease.landlord.transfer(address(this).balance);
    }

    // Evict the tenant for missing pay
    function evict() public inState(LeaseState.Occupied) onlyLandlord {
        emit leaseTerminated(lease.landlord, "eviction", block.timestamp);

        // If missing rent pay, start the eviction; return the balance to the landlord
        require(totalReceived < lease.term && balance < lease.rent);

        state = LeaseState.Terminated;
        lease.landlord.transfer(address(this).balance);
    }

    // Terminate the lease early by the tenant
    function terminateEarly() public payable inState(LeaseState.Occupied) onlyTenant {
        emit leaseTerminated(lease.tenant, "early termination", block.timestamp);

        // Tenant terminates the lease early, pay penalty; return the balance to landlord
        require(totalReceived < lease.term && msg.value >= lease.earlyPenalty);

        state = LeaseState.Terminated;
        lease.landlord.transfer(address(this).balance);
    }
}