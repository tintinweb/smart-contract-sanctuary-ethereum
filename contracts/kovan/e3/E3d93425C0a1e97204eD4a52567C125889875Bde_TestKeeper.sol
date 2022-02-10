// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface KeeperCompatibleInterface {

  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  function performUpkeep(bytes calldata performData) external;
}
pragma solidity ^0.8.10;

interface ISuperDeposit {


    function depositToAave(
        address recepient        
    ) external;

    function _getFlow(
        address sender
    ) external view returns(uint256, int96);

    function removeAddress(uint toRemove) external;

    function getUserAddress(
        uint256 index
    ) view external returns(address);

    function getTotalAddresses() external view returns(uint);

    function addKeeperContractAddress(address _keeperCon) external;

    function getAddressTokenInfo(
        address user
    ) external view returns(
        uint256 startTime,
        int96 flowRate,
        uint256 amountAccumunated,
        uint256 freequency
    );
}

pragma solidity ^0.8.10;

contract TestKeeper is KeeperCompatibleInterface {

    ISuperDeposit superDeposit;

    mapping(address => uint) private tokenAddresses;
    constructor(ISuperDeposit _superDeposit) {
        superDeposit = _superDeposit;
        superDeposit.addKeeperContractAddress(address(this));
    }

    function _getAddressFreequency(address user) public view returns(uint, uint) {
        (uint start,,,uint frequency) = superDeposit.getAddressTokenInfo(user);
        return (start, frequency);
    }

    function _depositToAave(
        address recepient        
    ) public {
        superDeposit.depositToAave(recepient);
    }

    function getFlow(
        address sender
    ) public view returns(uint256, int96) {
        return superDeposit._getFlow(sender);
    }

    function _removeAddress(uint toRemove) public {
        superDeposit.removeAddress(toRemove);
    }

    function _getUserAddress(
        uint256 index
    ) view public returns(address) {
        return superDeposit.getUserAddress(index);
    }

    function _getTotalAddresses() public view returns(uint) {
        return superDeposit.getTotalAddresses();
    }
    

    function checkUpkeep(
        bytes calldata /*checkData*/
    ) external view override returns (
        bool upkeepNeeded, bytes memory performData
    ) { 
        //for (uint i = 0; i < superDeposit.getTotalTokens(); i++) {
            //address token = superDeposit.getTokens(i);
        //address token = 0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD;
        for (uint p = 0; p < _getTotalAddresses(); p++) {
            address user = _getUserAddress(p);
            (,int96 flowRate) = getFlow(user);
            (uint begining, uint freq) = _getAddressFreequency(user);
            if ((begining + freq) >= block.timestamp) {
                upkeepNeeded = true;
                uint purpose = 1;
                performData = abi.encodePacked(p, purpose);
                return (true, performData);
            }
            if (flowRate == 0) {
                upkeepNeeded = true;
                uint purpose = 2;
                performData = abi.encodePacked(p, purpose);
                return (true, performData);
            }
        }
        //}        
    }
    
    function performUpkeep(bytes calldata performData) external override {
        (uint256 index, uint purpose) = abi.decode(performData, (uint256, uint256));
        address user = superDeposit.getUserAddress(index);
        if (purpose == 1) {
            superDeposit.depositToAave( user);
        } 
        if (purpose == 2) {
            superDeposit.depositToAave(user);
            superDeposit.removeAddress(index);
        }
    }
    

}