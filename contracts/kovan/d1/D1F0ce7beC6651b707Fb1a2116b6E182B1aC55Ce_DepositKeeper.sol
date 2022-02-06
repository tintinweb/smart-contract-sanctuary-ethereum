// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  function performUpkeep(bytes calldata performData) external;
}

pragma solidity ^0.8.0;

interface ISuperDeposit {

    function depositToAave(
        address token,
        address recepient        
    ) external;

    function _getFlow(
        address acceptedToken,
        address sender,
        address recepient
    ) external view returns(uint256, int96);

    function removeAddress(address token, uint toRemove) external;

    function getTokenUserAddress(
        address token,
        uint256 index
    ) view external returns(address);

    function getTotalAddresses(address token) external view returns(uint);

    function getTokens(uint256 index) external view returns(address);
    
    function getTotalTokens() external view returns(uint256);

    function addKeeperContractAddress(address _keeperCon) external;

    function _updateCurentInfo(
        address acceptedToken,
        address owner,
        uint startTime,
        int96 flowRate
    ) external;

    function getAddressTokenInfo(
        address token,
        address user
    ) external view returns(
        uint256 startTime,
        int96 flowRate,
        uint256 amountAccumunated,
        uint256 freequency
    );
}

pragma solidity ^0.8.0;

contract DepositKeeper is KeeperCompatibleInterface {

    ISuperDeposit superDeposit;

    mapping(address => uint) private tokenAddresses;
    constructor(ISuperDeposit _superDeposit) {
        superDeposit = _superDeposit;
        superDeposit.addKeeperContractAddress(address(this));
    }

    function _getAddressFreequency(address superToken, address user) private view returns(uint, uint) {
        (uint start,,,uint frequency) = superDeposit.getAddressTokenInfo(superToken, user);
        return (start, frequency);
    }

    function checkUpkeep(
        bytes calldata checkData
    ) external view override returns (
        bool upkeepNeeded, bytes memory performData
    ) { 
        for (uint i = 0; i < superDeposit.getTotalTokens(); i++) {
            address token = superDeposit.getTokens(i);
            for (uint p = 0; p < superDeposit.getTotalAddresses(token); p++) {
                address user = superDeposit.getTokenUserAddress(token, p);
                (,int96 flowRate) = superDeposit._getFlow(token, user, address(superDeposit));
                (uint begining, uint freq) = _getAddressFreequency(token, user);
                if (((begining + freq) >= block.timestamp) && flowRate != 0) {
                    upkeepNeeded = true;
                    uint purpose = 1;
                    return (true, abi.encodePacked(token, p, purpose));
                }
                if (flowRate == 0) {
                    upkeepNeeded = true;
                    uint purpose = 2;
                    return (true, abi.encodePacked(token, p, purpose));
                }
            }
        }
        
        performData = checkData;
        
    }
    
    function performUpkeep(bytes calldata performData) external override {
        (address token, uint256 index, uint purpose) = abi.decode(performData, (address, uint256, uint256));
        address user = superDeposit.getTokenUserAddress(token, index);
        if (purpose == 1) {
            superDeposit.depositToAave(token, user);
        } 
        if (purpose == 2) {
            superDeposit.depositToAave(token, user);
            superDeposit.removeAddress(token, index);
        }
    }
    

}