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
    uint256 constant interval = 3600 seconds;
    uint256 public lastCheck;

    mapping(address => uint) private tokenAddresses;
    constructor(ISuperDeposit _superDeposit) {
        superDeposit = _superDeposit;
        superDeposit.addKeeperContractAddress(address(this));
        lastCheck = block.timestamp;
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
        bool upkeepNeeded, bytes memory /*performData*/
    ) { 
        upkeepNeeded = (lastCheck + interval) > block.timestamp;
    }


    function depositWithLoop() public {
        for (uint p = 0; p < _getTotalAddresses(); p++) {
            address user = _getUserAddress(p);
            (,int96 flowRate) = getFlow(user);
            (uint begining, uint freq) = _getAddressFreequency(user);
            if ((begining + freq) >= block.timestamp) {
                _depositToAave(user);
            }
            if (flowRate == 0) {
                _depositToAave(user);
                _removeAddress(p);
            }
        }
    }

    
    function performUpkeep(bytes calldata /* performData*/) external override {
        lastCheck = block.timestamp;
        depositWithLoop();
    }
    

}