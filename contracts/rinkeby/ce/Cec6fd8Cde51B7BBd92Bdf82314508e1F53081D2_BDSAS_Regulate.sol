/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title BDSAS_Regulate
 * @dev Implements the G-Chain Regulatory Contract for a number (=20) of L-Chains in BD-SAS. Experimental version 0.2.0
 */
contract BDSAS_Regulate {

    struct Server { // SAS server
        string desc; // Description, e.g., name, IP address, other credentials.
        uint8 status; // 0: invalid, 1: valid candidate, 2: currently in service
        uint lid; // L-Chain index that the server currently serves (i.e., status==2) or lastly served
        uint sequence; // Server sequence for the lid-th L-Chain if status == 2
    }

    struct Witness { // SAS server
        string desc; // Description, e.g., name, IP address, other credentials.
        uint8 status; // 0: invalid, 1: valid
        uint lid; // L-Chain index
        uint sequence; // Witness sequence for the lid-th L-Chain if status == 1
        bool reshuffle_vote; // For confirming a reshuffle proposal
    }

    struct Regulation { // Short-term regulation, e.g., "order to vacate" due to incumbent arrival
        string desc; // Description of regulation content
        uint start_time;
        uint end_time;
        uint8 status; // 0: valid, 1: invalid
    }

    struct Proposal { // Verifiable random function (VRF) proposal (based on ed25519)
        bytes32 pubkey; // Public key - 32 bytes
        bytes32 hash_1; // Hash - first 32 bytes
        bytes32 hash_2; // Hash - second 32 bytes
        bytes32 proof_1;  // Proof - first 32 bytes
        bytes32 proof_2;  // Proof - second 32 bytes
        bytes32 proof_3;  // Proof - last 16 bytes
        uint shift_num;
    }

    address public regulator; // There could be multiple regulators, we assume one for convenience

    /* L-Chain variables */
    string public DESC; // Description on the associated spectrum regions, e.g., state-county names
    string public INTF; // Interference model parameters for the associated spectrum regions
    uint public T_SHIFT; // The L-Chain's shift length in G-Chain block cycles
    uint public T_EPOCH; // The L-Chain's epoch length in G-Chain block cycles 
    mapping(address => Server) public Servers; // Candidate servers
    mapping(address => Witness) public Witnesses; // For access control on witnesses
    address[20][5] public Witnesses_Addr; // We fix 20 L-Chains, 5 witnesses to an L-Chain, with Witnesses[0] being the anchor
    address[20][5] public CurrServers_Addr; // We require 5 servers to serve an L-Chain
    uint public shift; // Shift count (shared by all 20 L-Chains)
    uint[20] public epoch; // Epoch count (for each L-Chain)
    Regulation[] public Regulations; // List of short-term regulations
    bytes32[20][5] public LocalStates; // Service states of each L-Chain, provided by all serving servers

    /* Variables for SAS server reshuffling */
    mapping(address => Proposal) public ReshuffleProposals; // Candidate server' VRF info
    uint8[20] public reshuffle_status; // 0: accepting confirmation, 1: confirmation success, 2: confirmation failure (more than half are no-votes)
    uint public reshuffle_vote_count;
    uint public reshuffle_yesvote_count;
    address[20][5] public ProposedServers_Addr; // For the next shift

    /** 
     * @dev Create a new regulatory contract.
       @param t_sh: shift length, t_ep: epoch length
     */
    constructor(uint t_sh, uint t_ep){
        regulator = msg.sender; // Regulator creates the contract
        DESC = "This is a test G-Chain contract for 20 regions.";
        INTF = "TO FILL: interference model parameters.";
        T_SHIFT = t_sh;
        T_EPOCH = t_ep;
    }
 
    /**
     * @dev Add an eligible server. Callable by regulator.
     * @param addr: participant address, de: description, li: L-Chain index (0,1,2,...), st: status (0: invalidate, 1: valid, 2: serving as default), seq: valid witness sequence number (0,1,..)
     */
    function RegisterServer(address addr, string memory de, uint li, uint8 st, uint8 seq) public {
        require(msg.sender == regulator, "Only regulator can manage participating servers.");
        require(st == 0 || st == 1 || st == 2, "Illegal status assignment.");
        Servers[addr].status = st;
        Servers[addr].desc = de;
        Servers[addr].lid = li;
        if(st == 2){ // Default server
            Servers[addr].sequence = seq;
            CurrServers_Addr[li][seq] = addr;
        }
    }

      /**
     * @dev Add a witness. Callable by regulator.
     * @param addr: participant address, de: description, li: L-Chain index (0,1,2,...), sta: status (0: invalidate, 1: valid), seq: valid witness sequence number (0,1,..)
     */
    function RegisterWitness(address addr, string memory de, uint li, uint8 st, uint8 seq) public {
        require(msg.sender == regulator, "Only regulator can manage participating witnesses.");
        require(st == 0 || st == 1, "Illegal status assignment.");
        Witnesses[addr].status = st;
        Witnesses[addr].desc = de;
        Witnesses[addr].lid = li;
        Witnesses[addr].reshuffle_vote = false;
        if(st == 1){
            Witnesses[addr].sequence = seq;
            Witnesses_Addr[li][seq] = addr;
        }
    }

    /** 
     * @dev Publish/update new spectum access rules. Callable by regulator.
     * @param de: description, st: start time, et: end time, s: status 
     */
    function Publish(string memory de, uint st, uint et, uint8 s) public {
        require(msg.sender == regulator, "Only regulator can publish regulations.");
        Regulations.push(Regulation({desc: de, start_time: st, end_time: et, status: s}));
    }

    /** 
     * @dev Collect server reshuffle information. Callable by a server.
     * @param pubkey: VRF public key, h1: hash part1, h2: hash part2, p1: proof part1, p2: proof part2, p3: proof part3, 
     */
    function ReshufflePropose(bytes32 pubkey, bytes32 h1, bytes32 h2, bytes32 p1, bytes32 p2, bytes32 p3) public {
        // By our original design, we would need to have all VRF proposals submitted within the second last epoch of the current shift. 
        // However, such time constraints are not implemented in this version for easier testing
        require(Servers[msg.sender].status == 1 || Servers[msg.sender].status == 2, "The SAS server does not exist or is no longer valid."); // Valid server
        ReshuffleProposals[msg.sender].pubkey = pubkey;
        ReshuffleProposals[msg.sender].hash_1 = h1;
        ReshuffleProposals[msg.sender].hash_2 = h2;
        ReshuffleProposals[msg.sender].proof_1 = p1;
        ReshuffleProposals[msg.sender].proof_2 = p2;
        ReshuffleProposals[msg.sender].proof_3 = p3;
        ReshuffleProposals[msg.sender].shift_num = block.number / T_SHIFT;
    }

    /** 
     * @dev Collect SAS server group nomination. Callable by the anchor witness. The VRF verification and SG selection are done off-chain.
     * @param l: L-Chain index, sg: server group nomination by an anchor
     */
    function ReshuffleNominate(uint l, address[] memory sg) public {
        require(msg.sender == Witnesses_Addr[l][0], "The sender is not the anchor witness."); // Valid anchor witness
        for(uint i = 0; i < 5; i++) {
            ProposedServers_Addr[l][i] = sg[i];
        }
        Witnesses[msg.sender].reshuffle_vote = true; // The anchor's own vote
        for(uint i = 1; i < 5; i++) {
            Witnesses[Witnesses_Addr[l][i]].reshuffle_vote = false; // Restart the votes
        }
        reshuffle_vote_count = 1;
        reshuffle_yesvote_count = 1;
        reshuffle_status[l] = 0;
    }

    /** 
     * @dev Collect SAS server group confirmations. Callable by a normal witness. The VRF verification and nominee verification are done off-chain
     * @param l: L-Chain index, y: yes vote if true
     */
    function ReshuffleConfirm(uint l, bool y) public returns(uint8){
        require(reshuffle_status[l] == 0, "The confirmation procedure ended.");
        require(msg.sender != Witnesses_Addr[l][0], "Only callable by a normal witness.");
        require(Witnesses[msg.sender].status == 1, "Invalid witness.");
        require(Witnesses[msg.sender].reshuffle_vote == false, "You have already voted for this shift.");
        reshuffle_vote_count++;
        if(y){
            reshuffle_yesvote_count++;
        }
        Witnesses[msg.sender].reshuffle_vote = true;
        if(reshuffle_yesvote_count >= 3) { // 3 out of 5 witnesses vote yes
            for(uint i = 0; i < 5; i++) {
                Servers[CurrServers_Addr[l][i]].status = 1; // Switch the incumbent servers' status from "current" to "valid"
                CurrServers_Addr[l][i] = ProposedServers_Addr[l][i];
                Servers[CurrServers_Addr[l][i]].status = 2;
                Servers[CurrServers_Addr[l][i]].sequence = i;
            }
            reshuffle_status[l] = 1; // Success
        }
        else if(reshuffle_vote_count == 5) {
            reshuffle_status[l] = 2; // Reshuffle failure; do nothing; it is up to the regulator to add/delete candidate servers
        }
        return(reshuffle_status[l]);
    }

    /** 
     * @dev Allow a server to update its local service. Callable by a current server. Later audits (if needed) will check if all servers for an L-Chain provide the same updates
     * @param l: L-Chain index, st: local service state (can be digest of L-Chain contract state)
     */
    function LocalUpdate(uint l, bytes32 st) public {
        // By our original design, we would need to have all servers submit the update within one epoch time from the current epoch ends. 
        // However, such time constraints are not implemented in this version for easier testing
        require(Servers[msg.sender].status == 2, "Not a current server."); 
        require(Servers[msg.sender].lid == l, "Not currently serving the said L-Chain."); 
        LocalStates[l][Servers[msg.sender].sequence] = st;
        // TO DO in Future: Compensation scheme (needed in commercial deployment), which may need interaction from witnesses    
    }

    /**
     * @dev Destroy the contract. Callable by the contract creator, i.e., the regulator
     */
    function DestroyContract() public {
        require(msg.sender == regulator, "Only regulator can destroy the contract.");
        selfdestruct(payable(regulator));
    }
}