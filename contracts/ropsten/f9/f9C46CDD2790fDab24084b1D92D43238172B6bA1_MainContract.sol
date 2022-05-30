/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity <= 0.8.14;

contract MainContract {

    uint constant MAX_BENEFICIARIES = 64;
    address owner;

    struct BeneficiaryInformation {
        address addr;
        uint portion;
    }

    struct Information {
        bool created;
        uint balance; // recorded in wei
        BeneficiaryInformation[MAX_BENEFICIARIES] beneficiaries;
        uint numBeneficiaries;
        uint total;
    }

    Information info;

    event Deposit  (address user, uint amount);
    event Withdraw (address user, uint amount);
    event Receive  (address from, uint amount);
    
    // Check whether requests are from owner address
    modifier fromOwner {
        require(msg.sender == owner, "Only owner can use this function.");
        _;
    }

    modifier fromBeneficiary {
        bool valid = false;
        for (uint i = 0; i < info.numBeneficiaries; i++) {
            if (msg.sender == info.beneficiaries[i].addr) {
                valid = true;
                break;
            }
        }
        require(valid, "Only beneficiaries can use this function.");
        _;
    }

    modifier fromOwnerOrBeneficiary {
        bool valid = false;
        valid = (msg.sender == owner);
        for (uint i = 0; i < info.numBeneficiaries && !valid; i++) {
            if (msg.sender == info.beneficiaries[i].addr) {
                valid = true;
                break;
            }
        }
        require(valid, "Only owner and beneficiaries can use this function.");
        _;
    }

    // Just for deploying contract with ethers.
    constructor(address addr) payable {
        owner = addr;
    }
    
    function deposit () public payable fromOwner {
        emit Deposit(msg.sender, msg.value);
        info.balance += msg.value;
    }
    
    function withdraw (uint amount) external fromOwner {
        require(amount <= info.balance, "Inadequate balance.");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to send Ether.");
        info.balance -= amount;
        emit Withdraw(msg.sender, amount);
    }
    
    function addBeneficiary (address addr, uint portion) public fromOwner {
        require(info.numBeneficiaries < MAX_BENEFICIARIES, "Too many beneficiaries, Max: 64.");
        require(info.total + portion <= 100, "Invalid portion(> 100%), please adjust other beneficiaries' portion.");
        for (uint i = 0; i < info.numBeneficiaries; i++) {
            require(info.beneficiaries[i].addr != addr, "This address is already a beneficiary.");
        }
        info.beneficiaries[info.numBeneficiaries++] = BeneficiaryInformation({
            addr: addr,
            portion: portion
        });
        info.total += portion;
    }

    function removeBeneficiary (address addr) public fromOwner {
        uint idx = 0;
        bool found = false;
        for (uint i = 0; i < info.numBeneficiaries; i++) {
            if (info.beneficiaries[i].addr == addr) {
                idx = i;
                found = true;
                break;
            }
        }
        require(found, "Cannot find this beneficiary.");
        info.total -= info.beneficiaries[idx].portion;
        info.beneficiaries[idx] = BeneficiaryInformation({
            addr: info.beneficiaries[info.numBeneficiaries - 1].addr,
            portion: info.beneficiaries[info.numBeneficiaries - 1].portion
        });
        delete info.beneficiaries[info.numBeneficiaries--];
    }

    function adjustPortion (uint idx, uint _portion) public fromOwner {
        require(
            info.total - info.beneficiaries[idx].portion + _portion <= 100, 
            "Invalid portion(> 100%), please adjust other beneficiaries' portion"
        );
        info.total = info.total - info.beneficiaries[idx].portion + _portion;
        info.beneficiaries[idx].portion = _portion;
    }

    function destroy (address payable addr) public fromOwner {
        selfdestruct(addr);
    }

    function execute () public {
        require(info.total == 100, "Invalid portion(!= 100%), please adjust beneficiaries' portions");
        for (uint i = 0; i < info.numBeneficiaries; i++) {
            uint value = info.balance * info.beneficiaries[i].portion / 100;
            (bool success, ) = info.beneficiaries[i].addr.call{value: value}("");
            require(success, "Failed to distribute Ethers to beneficiaries.");
        }
    }

    // Functions below are for information query
    function getNumBeneficiaries () public view fromOwner returns(uint) {
        return info.numBeneficiaries;
    }

    function getBeneficiary (uint idx) public view fromOwner returns(address, uint) {
        return (info.beneficiaries[idx].addr, info.beneficiaries[idx].portion);
    }

    function getInformation () public view fromOwner returns(uint, uint) {
        return (info.balance, info.numBeneficiaries);
    }

    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }
}