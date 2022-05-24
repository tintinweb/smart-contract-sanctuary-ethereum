/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface KeeperCompatibleInterface {
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
  function performUpkeep(bytes calldata performData) external;
}

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

interface Mil {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Distribution is KeeperCompatible{
    
    Mil public mil;
    address public owner;
    uint public immutable interval;
    uint public lastTimeStamp;

    //Wallet addresses
    address payable contractAddress = payable(0xd1bA9694d01b1d19F6b4023320421db7d7Cc48cf);
    address payable operationsWallet = payable(0xd1e38535538038b68B9D594A0FcF46966AC720E7);
    address donationWallet = 0x52E17379bF49632a60ae17f7002Aa71a5328E1e5;
    address stakingWallet = 0xc2aF019bed9224A0b6f09f3a39F6af34aE62aa59;
    address burnMilEthWallet = 0x379de924C311Bf8d0C210e92cbF3d94116FF9274;

    constructor(uint updateInterval, Mil _mil) {
        mil = _mil;
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
        owner = msg.sender;
    }

    fallback() external payable{}

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;
            uint256 ethBalance = address(this).balance;
            uint256 milBalance = mil.balanceOf(address(this));
            uint256 onePointFive = (milBalance * 375)/1000;
            uint256 burnFund = milBalance - onePointFive*2;
            uint256 contractFund = (ethBalance*75)/100;
            uint256 oprFund = ethBalance - contractFund;
            contractAddress.transfer(contractFund);
            operationsWallet.transfer(oprFund);
            mil.transfer(donationWallet, onePointFive*10**18);
            mil.transfer(stakingWallet, onePointFive*10**18);
            mil.transfer(burnMilEthWallet, burnFund*10**18);
        }
    }

    function getEthBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMilBalance() public view returns(uint256){
        return mil.balanceOf(address(this));
    }

    function retrieve() public{
        payable(owner).transfer(address(this).balance);
    }
}