// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "../interfaces/IAPContract.sol";

contract Whitelist {
    uint256 groupId; // Id of the latest whitelist group created.
    address public whiteListManager; // Address of the WhiteList Manager.
    address public apContract;
    address public yieldsterDAO;

    struct WhitelistGroup {
        mapping(address => bool) members;
        mapping(address => bool) whitelistGroupAdmin;
        bool created;
    }
    mapping(uint256 => WhitelistGroup) private whitelistGroups; // Mapping of groupId to Whitelist group.
    event GroupCreated(address, uint256);

    constructor(address _apContract){
        apContract = _apContract;
    }

    /// @dev Function to change the aps contract of Yieldster.
    /// @param _apContract Address of the aps.
    function changeAPContract(address _apContract) public {
        require(
            msg.sender == IAPContract(apContract).yieldsterGOD(),
            "unauthorized"
        );
        apContract = _apContract;
    }

    /// @dev Function that returns if a whitelist group is exist.
    /// @param _groupId Group Id of the whitelist group.
    function _isGroup(uint256 _groupId) private view returns (bool) {
        return whitelistGroups[_groupId].created;
    }

    /// @dev Function that returns if the msg.sender is the whitelist group admin.
    /// @param _groupId Group Id of the whitelist group.
    function _isGroupAdmin(uint256 _groupId) public view returns (bool) {
        return whitelistGroups[_groupId].whitelistGroupAdmin[msg.sender];
    }

    /// @dev Function to create a new whitelist group.
    /// @param _whitelistGroupAdmin Address of the whitelist group admin.
    function createGroup(address _whitelistGroupAdmin)
        public
        returns (uint256)
    {
        require(IAPContract(apContract).vaultsCount(msg.sender)>0,"Not a vault admin");
        groupId += 1;
        require(!whitelistGroups[groupId].created, "Group already exists");
        WhitelistGroup storage newGroup = whitelistGroups[groupId];
        whitelistGroups[groupId].members[_whitelistGroupAdmin] = true;
        whitelistGroups[groupId].whitelistGroupAdmin[
            _whitelistGroupAdmin
        ] = true;
        newGroup.created = true;

        whitelistGroups[groupId].members[msg.sender] = true;
        emit GroupCreated(msg.sender, groupId);
        return groupId;
    }

    /// @dev Function to delete a whitelist group.
    /// @param _groupId Group Id of the whitelist group.
    function deleteGroup(uint256 _groupId) public {
        require(_isGroup(_groupId), "Group doesn't exist!");
        require(
            _isGroupAdmin(_groupId),
            "Only Whitelist Group admin is permitted for this operation"
        );
        delete whitelistGroups[_groupId];
    }

    /// @dev Function to add members to a whitelist group.
    /// @param _groupId Group Id of the whitelist group.
    /// @param _memberAddress List of address to be added to the whitelist group.
    function addMembersToGroup(
        uint256 _groupId,
        address[] memory _memberAddress
    ) public {
        require(_isGroup(_groupId), "Group doesn't exist!");
        require(
            _isGroupAdmin(_groupId),
            "Only goup admin is permitted for this operation"
        );

        for (uint256 i = 0; i < _memberAddress.length; i++) {
            whitelistGroups[_groupId].members[_memberAddress[i]] = true;
        }
    }

    /// @dev Function to remove members from a whitelist group.
    /// @param _groupId Group Id of the whitelist group.
    /// @param _memberAddress List of address to be removed from the whitelist group.
    function removeMembersFromGroup(
        uint256 _groupId,
        address[] memory _memberAddress
    ) public {
        require(_isGroup(_groupId), "Group doesn't exist!");
        require(
            _isGroupAdmin(_groupId),
            "Only Whitelist Group admin is permitted for this operation"
        );

        for (uint256 i = 0; i < _memberAddress.length; i++) {
            whitelistGroups[_groupId].members[_memberAddress[i]] = false;
        }
    }

    /// @dev Function to check if an address is a whitelisted address.
    /// @param _groupId Group Id of the whitelist group.
    /// @param _memberAddress Address to check.
    function isMember(uint256 _groupId, address _memberAddress)
        public
        view
        returns (bool)
    {
        require(_isGroup(_groupId), "Group doesn't exist!");
        return whitelistGroups[_groupId].members[_memberAddress];
    }

    /// @dev Function to add the whitelist admin of a group.
    /// @param _groupId Group Id of the whitelist group.
    /// @param _whitelistGroupAdmin Address of the new whitelist admin.
    function addWhitelistAdmin(uint256 _groupId, address _whitelistGroupAdmin)
        public
    {
        require(_isGroup(_groupId), "Group doesn't exist!");
        require(
            _isGroupAdmin(_groupId),
            "Only existing whitelist admin can perform this operation"
        );
        whitelistGroups[_groupId].whitelistGroupAdmin[
            _whitelistGroupAdmin
        ] = true;
    }

    /// @dev Function to remove the whitelist admin of a group.
    /// @param _groupId Group Id of the whitelist group.
    /// @param _whitelistGroupAdmin Address of the whitelist admin.
    function removeWhitelistAdmin(
        uint256 _groupId,
        address _whitelistGroupAdmin
    ) public {
        require(_isGroup(_groupId), "Group doesn't exist!");
        require(_whitelistGroupAdmin != msg.sender, "Cannot remove yourself");
        require(
            _isGroupAdmin(_groupId),
            "Only existing whitelist admin can perform this operation"
        );
        delete whitelistGroups[_groupId].whitelistGroupAdmin[
            _whitelistGroupAdmin
        ];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IAPContract {
    

    function getUSDPrice(address) external view returns (uint256);
    function stringUtils() external view returns (address);
    function yieldsterGOD() external view returns (address);
    function emergencyVault() external view returns (address);
    function whitelistModule() external view returns (address);
    function addVault(address,uint256[] calldata) external;
    function setVaultSlippage(uint256) external;
    function setVaultAssets(address[] calldata,address[] calldata,address[] calldata,address[] calldata) external;
    function changeVaultAdmin(address _vaultAdmin) external;
    function yieldsterDAO() external view returns (address);
    function exchangeRegistry() external view returns (address);
    function getVaultSlippage() external view returns (uint256);
    function _isVaultAsset(address) external view returns (bool);
    function yieldsterTreasury() external view returns (address);
    function setVaultStatus(address) external;
    function setVaultSmartStrategy(address, uint256) external;
    function getWithdrawStrategy() external returns (address);
    function getDepositStrategy() external returns (address);
    function isDepositAsset(address) external view returns (bool);
    function isWithdrawalAsset(address) external view returns (bool);
    function getVaultManagementFee() external returns (address[] memory);
    function safeMinter() external returns (address);
    function safeUtils() external returns (address);
    function getStrategyFromMinter(address) external view returns (address);
    function sdkContract() external returns (address);
    function getWETH()external view returns(address);
    function calculateSlippage(address ,address, uint256, uint256)external view returns(uint256);
    function vaultsCount(address) external view returns(uint256);
    function getPlatformFeeStorage() external view returns(address);
    function checkWalletAddress(address _walletAddress) external view returns(bool);
}