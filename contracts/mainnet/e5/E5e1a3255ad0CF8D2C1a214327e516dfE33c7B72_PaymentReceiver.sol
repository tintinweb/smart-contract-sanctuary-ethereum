/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
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
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

contract PaymentReceiver is Ownable {

    // Address -> Allocation
    mapping ( address => uint256 ) public allocations;

    // All Payees With An Allocation
    address[] public payees;

    // Total Allocation
    uint256 public totalAllocation;

    function withdraw() external onlyOwner {
        (bool s,) = payable(msg.sender).call{value: address(this).balance}("");
        require(s, 'Failure to withdraw');
    }

    function registerPayee(address payee, uint256 allocation) external onlyOwner {
        require(
            allocations[payee] == 0,
            'Already Registered'
        );
        payees.push(payee);
        totalAllocation += allocation;
        allocations[payee] = allocation;
    }

    function removePayee(address payee) external onlyOwner {
        uint index = payees.length + 1;
        for (uint i = 0; i < payees.length; i++) {
            if (payees[i] == payee) {
                index = i;
                break;
            }
        }
        require(
            index < payees.length,
            'Index Not Found'
        );

        payees[index] = payees[payees.length - 1];
        payees.pop();

        totalAllocation -= allocations[payee];
        delete allocations[payee];
    }

    function distribute() external onlyOwner {
        _distribute();
    }

    function _distribute() internal {

        uint bal = address(this).balance;
        if (bal == 0) {
            return;
        }

        for (uint i = 0; i < payees.length; i++) {
            uint amt = bal * allocations[payees[i]] / totalAllocation;
            if (amt > address(this).balance) {
                amt = address(this).balance;
            }
            if (amt > 0) {
                (bool s,) = payable(payees[i]).call{value: amt}("");
                require(s, 'Failure On ETH Transfer');
            }
        }
    }

    receive() external payable {}
}