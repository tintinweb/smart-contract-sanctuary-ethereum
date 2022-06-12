/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
interface Isettings {

    function networkFee(uint256 chainId) external view returns (uint256);
    function minValidations() external  view returns (uint256);
    function isNetworkSupportedChain(uint256 chainID) external returns (bool);
    function feeRemitance() external view returns (address);
    function railRegistrationFee() external view returns (uint256);
    function railOwnerFeeShare() external view returns (uint256);
    function onlyOwnableRail() external view returns (bool);
    function minWithdrawableFee() external view returns (uint256);
    function brgToken() external view returns (address);
    function getNetworkSupportedChains() external view returns(uint256[] memory);
    function approvedToAdd(address token , address user) external view returns(bool);
}
interface IController {
    function isAdmin(address account) external view returns (bool);
    function isRegistrar(address account) external view returns (bool);
    function isOracle(address account) external view returns (bool);
    function isValidator(address account) external view returns (bool);
    function owner() external view returns (address);
    function validatorsCount()   external view returns (uint256);
    
}
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  
    function balanceOf(address account) external view returns (uint256);


}

contract FeeController  {
IController public controller;
Isettings public settings;
mapping (address => bool) public isExempted;
uint256 public brgHoldingThreshold ;
uint256 public brgHoldingIncentive = 20;

mapping(address => uint256) public assetIncentive;

bool public useExemption;
bool public usebrgHoldingIncentive;
bool public useAssetIncentive;
uint256 public minUpdateDelay;

event BrgHoldingIncentiveStatusChanged( bool status );
event AssetIncentiveStatusChanged( bool status );
event AddressExemptionStatusChanged( bool status );
event AssetIncentiveUpdated(address indexed asset ,uint256  oldIncentive , uint256 newIncentive);
event userExemptStatusChanged(address indexed user , bool exemptionStatus);
event BrgHoldingThresholdUpdated(uint256 prevBrgHoldingThreshold , uint256 newBrgHoldingThreshold);
event BrgHoldingIncentiveUpdated(uint256 prevBrgHoldingIncentive , uint256 newBrgHoldingIncentive);
modifier onlyOwner {
    require(controller.owner() == msg.sender, " caller is not the owner");
        _;

}

modifier Admin {
    require(controller.owner() == msg.sender || controller.isAdmin(msg.sender), " caller is not the admin");
        _;
    
}


constructor(IController _controller ,  Isettings _settings ) {
    controller = _controller;
    settings = _settings;
}


function activateBrgHoldingIncentive(bool status) public Admin {
    require(usebrgHoldingIncentive != status , "already set");
    emit BrgHoldingIncentiveStatusChanged(status);
    usebrgHoldingIncentive = status;
 }


function activateAssetIncentive(bool status) public Admin {
    require(useAssetIncentive != status , "already set");
    emit AssetIncentiveStatusChanged(status);
    useAssetIncentive = status;
}


function activateAddressExemption(bool status) public Admin {
    require(useExemption != status , "already set");
    AddressExemptionStatusChanged(status);
    useExemption = status;
 }


 function exemptAddress(address user , bool status) external  onlyOwner {
     require(isExempted[user] != status ,"already set");
     emit userExemptStatusChanged(user , status);
     isExempted[user] = status;
 }


 function setAssetIncentivization(address asset , uint256 incentive) external  onlyOwner{
     require(assetIncentive[asset] != incentive ,"already set");
     require(incentive + brgHoldingIncentive < 100 ,"above limit");
     emit AssetIncentiveUpdated(asset , assetIncentive[asset] , incentive);
     assetIncentive[asset] = incentive;
 }


function setBrgHoldingThreshold( uint256 threshold) external  onlyOwner{
     require(brgHoldingThreshold != threshold ,"already set");
     emit BrgHoldingThresholdUpdated(brgHoldingThreshold , threshold);
     brgHoldingThreshold = threshold;
}


function setBrgHoldingIncentive ( uint256 incentive) external  onlyOwner{
     require(brgHoldingIncentive!= incentive ,"already set");
     require(incentive  < 100 ,"above limit");
     emit BrgHoldingIncentiveUpdated(brgHoldingIncentive , incentive );
     brgHoldingIncentive = incentive;
 }


function getBridgeFee(address sender, address asset, uint256 chainTo ) external view returns(uint256){
     uint256 fees = settings.networkFee(chainTo);
     uint256 totalIncentive;
     if (useExemption && isExempted[sender]) {
         return 0;
      }
     if (usebrgHoldingIncentive) {
         if (IERC20(settings.brgToken()).balanceOf(sender) >= brgHoldingThreshold) {
             totalIncentive += brgHoldingIncentive;
         }
     }
     if (useAssetIncentive && assetIncentive[asset] > 0) {
         totalIncentive +=  assetIncentive[asset];
     }

     if (totalIncentive >= 100) {
         return 0;
     } else if (totalIncentive == 0) {
         return fees;
     } else {
         return fees -  getIncentive(fees , totalIncentive) ;
     }
}


function getIncentive(uint256 fee , uint256 incentive) public pure returns (uint256){
    if (incentive > 100 || incentive == 0) {
        return 0;
     } else {
      return incentive * fee / 100;
     }
 }

}