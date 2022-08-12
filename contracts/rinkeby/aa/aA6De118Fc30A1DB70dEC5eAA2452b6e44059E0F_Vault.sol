// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

    /// @title A Vault Contract
    /// @author Glory Praise Emmanuel
    /* A contract with the following features:
        - owner can create grant for a beneficiary
        - allows beneficiary only when the time elapses
        - allows owner to withdraw before time elapses
        - get information of a beneficiary
        - amount of ethers in the smart contract
    */

contract Vault{
    
    //********* STATE VARIABLES***********/

    uint ID = 1;

    uint[] id;

    address public owner;
    
    BeneficiaryProperties[] bp;

    struct BeneficiaryProperties{
        uint ammountAllocated;
        address beneficiary;
        uint time;
        bool status;
    }

    mapping(uint => BeneficiaryProperties) public _beneficiaryProperties;


    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");

        _;
    }

    modifier hasTimeElapsed(uint _id){
        BeneficiaryProperties memory BP = _beneficiaryProperties[_id];
        require(block.timestamp >= BP.time, "Not time to withraw yet ogbeni");

        _;
    }

    function createGrant(address _beneficiary, uint _time) external payable onlyOwner returns(uint){
        BeneficiaryProperties storage BP = _beneficiaryProperties[ID];
        require(msg.value > 0, "Zero ether not allowed");
        BP.ammountAllocated = msg.value;
        BP.beneficiary = _beneficiary;
        BP.time = _time;
        uint _id = ID;
        id.push(_id);
        ID++;

        return _id;
    }

    function withdraw(uint _id) external hasTimeElapsed(_id){
        BeneficiaryProperties storage BP = _beneficiaryProperties[_id];
        address user = BP.beneficiary;
        uint _amount = BP.ammountAllocated;
        require(user == msg.sender, "You are not a beneficiary for a grant");
        require(_amount > 0, "This beneficiary has no money");
        uint getBal = getBalance();
        require(getBal >= _amount, "Insufficient funds");
        BP.ammountAllocated = 0;
        payable(user).transfer(_amount);
    }

    function withdrawFromSingleAddr(uint _id, uint _amount) external hasTimeElapsed(_id){
        BeneficiaryProperties storage BP = _beneficiaryProperties[_id];
        address user = BP.beneficiary;
        require(user == msg.sender, "You are not a beneficiary for a grant");

        require(_amount <= BP.ammountAllocated, "You are not a thief, the money no reach");
        uint amountToWithdraw = _amount;
        BP.ammountAllocated -= amountToWithdraw;

        // To prevent reentrancy
        require(BP.ammountAllocated > 0, "No more money to withdraw");

        payable(user).transfer(amountToWithdraw);
        
    }

    function revertGrant(uint _id) external onlyOwner{
        BeneficiaryProperties storage BP = _beneficiaryProperties[_id];
        uint _amount = BP.ammountAllocated;
        BP.ammountAllocated = 0;
        payable(owner).transfer(_amount);

    }

    function returnBeneficiaryInfo(uint _id) external view returns(BeneficiaryProperties memory BP){
        BP = _beneficiaryProperties[_id];
    }

    function getBalance() public view returns(uint256 bal){
        return bal = address(this).balance;
    }

    function getAllBeneficiary() external view returns(BeneficiaryProperties[] memory _bp){
        uint[] memory all = id;
        _bp =  new BeneficiaryProperties[](all.length);

        for(uint i; i < all.length; i++){
            _bp[i] = _beneficiaryProperties[all[i]];
        }
    }

    function checkBlockTimeStamp() external view returns(uint){
        return block.timestamp;
    }

    function checkBTimeLeft(uint _id) external view returns(uint){
        BeneficiaryProperties storage BP = _beneficiaryProperties[_id];
        uint time = BP.time - block.timestamp;
        return time;
    }

}