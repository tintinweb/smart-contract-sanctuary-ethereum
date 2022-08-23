/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {

    address private owner;

    uint256 public currentTicketId=0;

    mapping(uint256 => uint256) public test;


    mapping(uint256 => mapping(uint256=>address)) public tickets;
    //owner => roundId => Count
    mapping(address => mapping(uint256=>uint256)) public ticketCount;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
        test[1] = 1;
        test[2] = 2;
        test[3] = 3;
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function buyTickets(uint256 round,uint256 number) external {
        for(uint256 i=1;i<=number;i++){
            tickets[currentTicketId][round] = msg.sender;
            currentTicketId++;
            delete tickets[currentTicketId][round -1];
        }
        ticketCount[msg.sender][round] += number;
        delete ticketCount[msg.sender][round-1];
    }

    function buyTickets2(uint256 round,uint256 number) external {
        for(uint256 i=1;i<=number;i++){
            tickets[currentTicketId][round] = msg.sender;
            currentTicketId++;
            if(tickets[currentTicketId][round -1] != address(0)){
                delete tickets[currentTicketId][round -1];
            }
        }
        ticketCount[msg.sender][round] += number;
        if(ticketCount[msg.sender][round-1] !=0){
            delete ticketCount[msg.sender][round-1];
        }
    }

    function deleta(uint256[] memory t) external {
        for(uint i=0;i<t.length;i++){
            if(test[t[i]] !=0){
                delete test[t[i]];
            }else{
                continue;
            }
        }
    }
    //1-222265
    //2-203629

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}