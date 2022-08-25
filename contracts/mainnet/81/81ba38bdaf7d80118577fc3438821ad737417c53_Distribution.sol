/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
 
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  function performUpkeep(bytes calldata performData) external;
}

contract KeeperBase {
  error OnlySimulatedBackend();

  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

interface Mil {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Distribution is KeeperCompatibleInterface{
    
    Mil public mil;
    address public owner;
    uint public immutable interval;
    uint public lastTimeStamp;

    modifier onlyOwner(){
      require(msg.sender == owner, "You're not owner!");
      _;
    }
    uint8 public contractPercent;
    uint8 public operationPercent;
    uint8 public donationPercent;
    uint8 public stakingPercent;
    uint8 public milEthBurnPercent;

    function setContractPercent(uint8 _newPercent) external onlyOwner{
      contractPercent = _newPercent;
    }
    function setOperationPercent(uint8 _newPercent) external onlyOwner{
      operationPercent = _newPercent;
    }
    function setDonationPercent(uint8 _newPercent) external onlyOwner{
      donationPercent = _newPercent;
    }
    function setStakingPercent(uint8 _newPercent) external onlyOwner{
      stakingPercent = _newPercent;
    }
    function setMilEthPercent(uint8 _newPercent) external onlyOwner{
      milEthBurnPercent = _newPercent;
    }


    //Wallet addresses
    address contractAddress = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    function setContractWallet(address _address) public onlyOwner{
        contractAddress = _address;
    }
    address operationsWallet =0x583031D1113aD414F02576BD6afaBfb302140225;
    function setOperationsWallet(address _address) public onlyOwner{
        operationsWallet = _address;
    }
    address donationWallet = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
    function setDonationWallet(address _address) public onlyOwner{
      donationWallet = _address;
    }
    address stakingWallet = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;
    function setstakingWallet(address _address) public onlyOwner{
      stakingWallet = _address;
    }
    address burnMilEthWallet = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
    function setburnMilEthWallet(address _address) public onlyOwner{
      burnMilEthWallet = _address;
    }

    constructor(uint updateInterval, Mil _mil) {
        mil = _mil;
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
        owner = msg.sender;
    }

    //receive () external payable{}

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function distribute() public {
      uint256 milBalance = getMilBalance();
      mil.transfer(contractAddress, (contractPercent*milBalance)/100);
      mil.transfer(operationsWallet, (operationPercent*milBalance)/100);
      mil.transfer(donationWallet, (donationPercent*milBalance)/100);
      mil.transfer(stakingWallet, (stakingPercent*milBalance)/100);
      mil.transfer(burnMilEthWallet, (milEthBurnPercent*milBalance)/100);
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;
            distribute();
        }
    }

    function getMilBalance() public view returns(uint256){
        return mil.balanceOf(address(this));
    }
}