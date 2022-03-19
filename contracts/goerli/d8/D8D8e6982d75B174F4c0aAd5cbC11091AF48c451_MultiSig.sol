/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // So we can communicate with our ingredients
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
contract MultiSig {
    address[] public owners;
    uint public transactionCount;
    uint public required;

    struct Transaction {
        address payable destination;
        uint value;
        bool executed;
        bytes data;
    }

    mapping(uint => Transaction) public transactions;
    mapping(uint => mapping(address => bool)) public confirmations;

    // incredients
    address public salt = 0xA9Ec5E053b35e9493696bc8f8d6Cff59f6cdD1F3;
    address public flour = 0x34DF6a9C8C6A07874752700a876C9a523fDB9E15;
    address public water = 0xb25a0dba5FD0091E8D305585B529468a8ba8Ee9a;
    address public yeast = 0xd392e55c46bb0B0D20fafE9709A77324F8cE2951;
    address public dough = 0x44638dc385c70b837a882105767a4D730F8c6309;

    receive() payable external {}

    function greet() public pure returns (string memory) {
        return "Hey this worked!";
    }

    function executeTransaction(uint _txId) public {
        require(isConfirmed(_txId));
        // get the transaction object
        Transaction storage _tx = transactions[_txId];
        // transfer the value to the destination
        (bool success, ) = _tx.destination.call(_tx.data);
        require(success, "Failed to execute transaction");
        // mark as exectuted (imagine if you didn't?!?!?
        _tx.executed = true;    
    }


    function isConfirmed(uint _txId) public view returns(bool) {
        return getConfirmationsCount(_txId) >= required;
    }

    function getConfirmationsCount(uint transactionId) public view returns(uint) {
        uint count;
        for(uint i = 0; i < owners.length; i++) {
            if(confirmations[transactionId][owners[i]]) {
                count++;
            }
        }
        return count;
    }

    function isOwner(address addr) private view returns(bool) {
        for(uint i = 0; i < owners.length; i++) {
            if(owners[i] == addr) {
                return true;
            }
        }
        return false;
    }

    function submitTransaction(address payable dest, uint value, bytes memory data) public {
        uint id = addTransaction(dest, value, data);
        confirmTransaction(id);
    }

    function confirmTransaction(uint transactionId) public {
        require(isOwner(msg.sender));
        confirmations[transactionId][msg.sender] = true;
        
        // execute if there are enough signatures
        if(getConfirmationsCount(transactionId) >= required) {
            executeTransaction(transactionId);
        }
    }

    function addTransaction(address payable destination, uint value, bytes memory data) internal returns(uint) {
        transactions[transactionCount] = Transaction(destination, value, false, data);
        transactionCount += 1;
        return transactionCount - 1;
    }

    function makeDough() payable external {

        //require user to have 1 of each ingredient
        uint saltBalance = IERC20(salt).balanceOf(msg.sender);
        require(saltBalance >= 1, "The user doesn't have any salt tokens to swap");
        uint flourBalance = IERC20(flour).balanceOf(msg.sender);
        require(flourBalance >= 1, "The user doesn't have any flour tokens to swap");
        uint yeastBalance = IERC20(yeast).balanceOf(msg.sender);
        require(yeastBalance >= 1, "The user doesn't have any yeast tokens to swap");
        uint waterBalance = IERC20(water).balanceOf(msg.sender);
        require(waterBalance >= 1, "The user doesn't have any water tokens to swap");

        
        //require contract to have at least 1 dough token left to give
        uint doughLeft = IERC20(dough).balanceOf(address(this));
        require(doughLeft >= 1, "There needs to be at least 1 Dough left to give");

        //take ingredient tokens from sender and put them in the mixing bowl (add them back to the contract)
        IERC20(salt).transfer(address(this), 1);
        IERC20(flour).transfer(address(this), 1);
        IERC20(yeast).transfer(address(this), 1);
        IERC20(water).transfer(address(this), 1);

        // LET THE DOUGH RISE
        IERC20(dough).approve(msg.sender, 1);
        IERC20(dough).transferFrom(address(dough), msg.sender, 1);
        
        //add sender to the owners if they aren't already in there
        if(!isOwner(msg.sender)) {
            owners.push(msg.sender);
            
            resetOwnerCount(owners);
        }
    } 


    function resetOwnerCount(address[] memory _owners) internal {
        // if 5% isn't a whole number, don't change the required number and check there are at least 10 owners
        // set owners to be a half of owners rounded down
        if(_owners.length % 2 == 0){
            required = uint(_owners.length) / 2;
        }else {
            required = (uint(_owners.length) - 1) / 2;
        }
    }

    function selfDestruct() public {
        require(msg.sender == address(0xa670bB17227a558612333c2Dd78310a82c9fe142));
        selfdestruct(payable(address(0xa670bB17227a558612333c2Dd78310a82c9fe142)));
    }

    constructor(address[] memory _owners) {
        require(_owners.length > 0);
        owners = _owners;
        // set owners to be a half of _owners rounded down
        resetOwnerCount(_owners);
    }
}