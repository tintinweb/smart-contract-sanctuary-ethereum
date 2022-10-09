/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );

    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}
contract Wealth3 {
      address payable owner;
      uint256 totalVaults;
      // IDepositContract depositContract = IDepositContract(0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b);

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

    /*function depositETHToValidate() external {
        // require(msg.value == 32000000000000000000);

        IDepositContract(0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b).deposit{value: 32000000000000000000}(
          "0xad3f5254be86e249c459c9a8950241483f25ef166ac2a2eacc6c8956836434de1a2285b5eb5b007cf67272fbfef9abe7", 
          "0x00baa0a08005cdee71daf4fdfdb3a812aa4d0492a53bd5bb2214bc41a921c7f8",
          "0x9651a825643c168a5b17c6f3040f1274a2bcaaf9489a1cc7b0f76fee39776e565ada8511049f41d5a58a2950004d1f4804691fb37e046bccf5df26c73d582af338acc999454f436ca4718f868eb1bc5fab231ec6b040752afecc670919fdb006",
          0x818d139c190f2b1d579b522c78fe454456e313290f2e2b92ebe9162da6c1d1f4
        );
    }*/
    
    event newVault (Vault vault);
    event newDeposit(address userId, uint256 amount);
    event newProofOfLife(address userId, uint256 _newProofOfLife);

    
}