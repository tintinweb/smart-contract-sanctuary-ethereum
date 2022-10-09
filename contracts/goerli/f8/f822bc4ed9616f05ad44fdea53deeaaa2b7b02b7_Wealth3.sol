/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Wealth3 {
      address payable owner;
      uint256 totalVaults;
      constructor() {
        owner = payable(msg.sender);
      totalVaults = 0;
      }

    

    struct Vault {
      uint256 contractTime;
      uint256 proofOfLifeFreq;
      uint256 amount;
      uint256 lastProofOfLife;
      address[] beneficiaries;
      uint[] distribution;
    }


    mapping(address => Vault) public Vaults;
    function getVault(address _userId) public view returns (Vault memory){
      return Vaults[_userId];
    }
    function createVault(uint256 _contractTime, uint256 _proofOfLifeFreq, address[] memory _beneficiaries, uint[] memory _distributions)
        public
        payable
        returns (Vault memory)
    {
      Vault storage vault = Vaults[msg.sender];
      require(vault.amount == 0, "User already has a vault");
      require(msg.value > 0, "deposit must be greater than 0");
      require(_distributions.length <= 3 && _beneficiaries.length <=3, "Only three beneficiaries can be set");
      require(_distributions.length>0 && _beneficiaries.length > 0, "At least one beneficiary must be set");
      require(_distributions.length == _beneficiaries.length, "Beneficiaries and distributions have to be the same length");
      //require(_distributions[0] + _distributions[1]+ _distributions[2] == 100, "Sum of distribution percentages must be equal to 100%");
      totalVaults++;
      // proceda 
      Vaults[msg.sender] = Vault(_contractTime, _proofOfLifeFreq, msg.value, block.timestamp, _beneficiaries, _distributions);
      emit newVault(Vaults[msg.sender]);
      return Vaults[msg.sender];
    }
    function deposit() 
      public 
      payable
      returns (Vault memory)
    {
      Vault storage vault = Vaults[msg.sender];
      require(vault.amount != 0, "User doesn't have a vault");
      require(msg.value > 0, "Can't deposit 0 eth");
      Vaults[msg.sender].amount += msg.value;
      Vaults[msg.sender].lastProofOfLife = block.timestamp;
      emit newDeposit(msg.sender, msg.value);
      return Vaults[msg.sender];
    }
    function withdrawAllFundsAdmin () public {
      require(msg.sender == owner, "Function must be called by the contract owner");
      owner.transfer(address(this).balance);
    }
    function updateProofOfLife() public {
      Vaults[msg.sender].lastProofOfLife = block.timestamp;
      emit newProofOfLife(msg.sender, block.timestamp);
    }
    function changeOwner (address _newOwner) public {
      require(owner == msg.sender, "Ownership can only be changed by the owner");
      owner = payable(_newOwner);
    }
    function getOwner() public view returns (address){
      return owner;
    }
    
    event newVault (Vault vault);
    event newDeposit(address userId, uint256 amount);
    event newProofOfLife(address userId, uint256 _newProofOfLife);

    
}