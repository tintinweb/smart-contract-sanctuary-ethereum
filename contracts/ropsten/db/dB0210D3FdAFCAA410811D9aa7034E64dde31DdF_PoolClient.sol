// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title PoolClient, Pool Client Contract,
/// @author liorabadi
/// @notice Contract to perform deposits, withdrawals and injections.
/// @notice No tokens are stored on this contract.
/// @notice The tokens are sent back and forth between this contract and the PoolVault.
/// @notice The tokens are sent back and forth between this contract and the PoolVault.

import "./PoolBase.sol";
import "./interfaces/rwETHTokenInterface.sol";
import "./interfaces/PoolClientInterface.sol";
import "./interfaces/TokenBalancesInterface.sol";
import "./interfaces/PoolVaultInterface.sol";

contract PoolClient is PoolBase {

    event UserStaked(address indexed _staker, uint _ethAmount, uint _time);
    event RewardsInjected(uint _lastRewardTime, uint _amountInjected);
    event UserUnstaked(address indexed _unstaker, uint _ethAmount, uint _time);

    constructor(DataStorageInterface _dataStorageAddress) PoolBase(_dataStorageAddress) {
        _setPoolClientAddress();
    }

    modifier depositCompliance() {
        PoolVaultInterface poolVault = PoolVaultInterface(getContractAddress("PoolVault"));
        bytes32 statusTag = keccak256(abi.encodePacked("isPoolLive"));
        bytes32 daysRewTag = keccak256(abi.encodePacked("daysToRewards"));
        bytes32 rewardsIntTag = keccak256(abi.encodePacked("rewardsInterestPerPeriod"));
        bytes32 contrLimitTag = keccak256(abi.encodePacked("contributionLimit"));
        bytes32 minContrTag = keccak256(abi.encodePacked("minContribution"));
        bytes32 poolMaxSizeTag = keccak256(abi.encodePacked("poolMaxSize"));
        
        require(dataStorage.getUintStorage(daysRewTag) != 0, "The team needs to set a reward interval.");
        require(dataStorage.getUintStorage(rewardsIntTag) != 0 , "The team needs to set a reward ratio.");
        require(dataStorage.getUintStorage(contrLimitTag) != 0, "The team needs to set a contribution limit.");
        require(msg.value <= dataStorage.getUintStorage(contrLimitTag), "Max. current contribution limit exceeded.");
        require(dataStorage.getUintStorage(minContrTag) <= msg.value, "Value to deposit needs to be higher than the current minimum contribution limit.");
        require(poolVault.poolEtherSize() + msg.value <= dataStorage.getUintStorage(poolMaxSizeTag), "Max. Pool size overflow with that amount of deposit.");
        _;
    }

    modifier withdrawCompliance(uint _rwEtherWithdrawal) {
        PoolVaultInterface poolVault = PoolVaultInterface(getContractAddress("PoolVault"));
        rwETHTokenInterface rwEthToken = rwETHTokenInterface(getContractAddress("rwETHToken"));
        bytes32 statusTag = keccak256(abi.encodePacked("isPoolLive"));

        require(rwEthToken.balanceOf(msg.sender) >= _rwEtherWithdrawal, "You don't have that amount of tokens on your account.");
        require(poolVault.poolEtherSize() - rwEthToken.calcEthValue(_rwEtherWithdrawal) >= 0, "Pool size cannot be smaller than zero.");
        require(dataStorage.getBoolStorage(statusTag), "The pool is currently paused");
        _;
    }

    modifier injectionComliance() {
        bytes32 statusTag = keccak256(abi.encodePacked("isPoolLive"));

        require(!dataStorage.getBoolStorage(statusTag), "The pool is currently live.");
      _;
    }
   
    /// @dev Store this contract address and existance on the main storage.
    /// @notice Called while deploying the contract. 
    function _setPoolClientAddress() private {
        dataStorage.setBoolStorage(keccak256(abi.encodePacked("contract_exists", address(this))), true);
        dataStorage.setAddressStorage(keccak256(abi.encodePacked("contract_address", "PoolClient")), address(this));
    }     

    /// @dev Main Staking function. Allows users to deposit ether in exchange of rwEther.
    /// @notice The exchange rate (ETH / rwETH) is calculated within the mint function.  
    /// @notice The minting function updates only the current rwEth supply.
    /// @notice The mint function comes with a built-in ether/rwEther converter.
    /// @notice Once the user deposits, the ether go to the vault contract.
    function deposit() external payable depositCompliance() nonReentrant() {
        rwETHTokenInterface rwEthToken = rwETHTokenInterface(getContractAddress("rwETHToken"));
        rwEthToken.mint(msg.sender, msg.value);

        bytes32 currentEthSupplyTag = keccak256(abi.encodePacked("totalSupply_Ether"));
        dataStorage.increaseUintStorage(currentEthSupplyTag, msg.value);

        emit UserStaked(msg.sender, msg.value , block.timestamp);
        _depositToVault();
    }

    /// @dev Transfers the staked ether to the vault.
    function _depositToVault() private {
        PoolVaultInterface poolVault = PoolVaultInterface(getContractAddress("PoolVault"));
        poolVault.storeEther{value: msg.value}();
    }
  

    /// @dev Helps the team calculate the rewards. Also, assigns the amount to inject into a variable.
    function calculateRewards() public onlyRole(POOL_MANAGER) injectionComliance() {
        TokenBalancesInterface poolTokenBalances = TokenBalancesInterface(getContractAddress("TokenBalances"));
        
        bytes32 rewardsToInjectTag = keccak256(abi.encodePacked("rewardsToInject"));
               
        uint rewardsInterest = getRewardsInterest();
        uint rewardsToInject = poolTokenBalances.getTotalEtherStaked() * rewardsInterest / (10**6);
        dataStorage.setUintStorage(rewardsToInjectTag, rewardsToInject);
    }

    /// @dev Gets the lastest amount of ether to inject.
    function getRewardsToInject() public view onlyRole(POOL_MANAGER) returns(uint){
        bytes32 rewardsToInjectTag = keccak256(abi.encodePacked("rewardsToInject"));
        return dataStorage.getUintStorage(rewardsToInjectTag);
    }
    
    /// @dev This function logic prevents the team to inject a wrong amount of ether as rewards.
    /// @notice With this function, both the team and the users will have the insuarance that the right amount will be injected.
    /// @notice the require reverts the process if a wrong amount is willed to be injected.
    /// @notice This function does not updates the poolEther size, it just updates the total amount of ether on the contract network.
    /// @notice Th

    function rewardsInjector() public payable onlyRole(POOL_MANAGER) injectionComliance() {
        bytes32 lastRewardTimeTag = keccak256(abi.encodePacked("lastRewardTime"));

        require(dataStorage.getUintStorage(lastRewardTimeTag) + (getRewardsInterval() * 1 days) < block.timestamp, "The team has already injected the rewards.");
        require(msg.value == getRewardsToInject(), "Invalid ether interest injected.");

        PoolVaultInterface poolVault = PoolVaultInterface(getContractAddress("PoolVault"));
        
        bytes32 totalRewardsInjectedTag = keccak256(abi.encodePacked("totalRewardsInjected"));   
        bytes32 currentEthSupplyTag = keccak256(abi.encodePacked("totalSupply_Ether"));             
     
        dataStorage.setUintStorage(lastRewardTimeTag, block.timestamp);
        dataStorage.increaseUintStorage(totalRewardsInjectedTag, msg.value);
        dataStorage.increaseUintStorage(currentEthSupplyTag, msg.value);        

        poolVault.processRewards{value: msg.value}();
        emit RewardsInjected(dataStorage.getUintStorage(lastRewardTimeTag), msg.value);
    }

    /// @dev Main Unstaking function. Allows users to deposit rwEther in exchange of Ether.
    /// @notice The withdrawEther function updates the total_ether_supply and its staked amount.
    /// @notice Once it is called, the rwEth amount is burned and the vault sends to this contract the ether counterpart.
    /// @notice User needs to provide allowance to the contract to make this call (performed on the frontend of the Dapp).
    function withdraw(uint _rwEthAmount) external withdrawCompliance(_rwEthAmount) nonReentrant(){
        rwETHTokenInterface rwEthToken = rwETHTokenInterface(getContractAddress("rwETHToken"));
        PoolVaultInterface poolVault = PoolVaultInterface(getContractAddress("PoolVault"));
        
        require(rwEthToken.allowance(msg.sender, address(this)) >= _rwEthAmount, "Reverted: Client lacks allowance to perform this action.");
       
        rwEthToken.transferFrom(msg.sender, address(this), _rwEthAmount);

        uint etherToUnstake = rwEthToken.calcEthValue(_rwEthAmount);
        rwEthToken.burn(_rwEthAmount);
        bytes32 burnedRwEtherTag = keccak256(abi.encodePacked("totalBurned_rewardEther"));
        dataStorage.increaseUintStorage(burnedRwEtherTag, _rwEthAmount);

        poolVault.withdrawEther(msg.sender, etherToUnstake);
        emit UserStaked(msg.sender, etherToUnstake, block.timestamp);
    }

    function getPoolClientAddress() public view returns(address){
        bytes32 addressTag = keccak256(abi.encodePacked("contract_address", "PoolClient"));
        address contractAddress = dataStorage.getAddressStorage(addressTag);
        return contractAddress;
    }    
    




}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title PoolBase, Base Pool Management Contract,
/// @author liorabadi
/// @notice Base control and management of the pool operation.

import "./interfaces/DataStorageInterface.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title This contract handles the modifiers and environmental parameters that control the pool. 

contract PoolBase is AccessControl, ReentrancyGuard{

    bytes32 public constant POOL_MANAGER = keccak256("POOL_MANAGER");

    // Events
    event NewManagerAdded(address indexed _newManager);
    event ManagerRemoved(address indexed _removedManager);

    /// @notice Getting access to the DataStorage Contract.
    DataStorageInterface dataStorage;
    
    /// @notice This contract will be deployed by the same address of the initial guardian. Afterwards Guardian may not be the same as the admin
    /// @notice if the guardian renounces to their guard.
    constructor(DataStorageInterface _dataStorageAddress){
        dataStorage = DataStorageInterface(_dataStorageAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(POOL_MANAGER, msg.sender);
        _setPoolBaseAddress();
    }


    // ====== Contract Modifiers ======
    /// @notice Besides the access control contract, the following modifiers will be used.
    modifier onlyCurrentGuardian() {
        require(msg.sender == dataStorage.getCurrentGuardian(), "Only callable by current guardian.");
        _;
    }

    modifier onlyPoolContract(){
        require(dataStorage.getBoolStorage(keccak256(abi.encodePacked("contract_exists", msg.sender))), "Invalid Contract Address.");
        _;
    }

    // ====== Pool Clearance  ======
    function addPoolManager (address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(POOL_MANAGER, _address);
        emit NewManagerAdded(_address);
    }

    function removePoolManager (address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(POOL_MANAGER, _address);
        emit ManagerRemoved(_address);
    }

    // ====== Pool Variables Setters  ======
    /// @dev Store this contract address and existance on the main storage.
    /// @notice Called while deploying the contract. 
    function _setPoolBaseAddress() private {
        dataStorage.setBoolStorage(keccak256(abi.encodePacked("contract_exists", address(this))), true);
        dataStorage.setAddressStorage(keccak256(abi.encodePacked("contract_address", "PoolBase")), address(this));
    }

    /// @dev Toggles the Pool Investing Switch. 
    /// @notice While live, anyone can invest but any state variable can be modified nor deleted.
    function setPoolLive(bool _live) public onlyRole(POOL_MANAGER) {
        bytes32 statusTag = keccak256(abi.encodePacked("isPoolLive"));
        dataStorage.setBoolStorage(statusTag, _live);
    }

    /// @dev Sets the Pool Maximium size expressed on ether.
    /// @param _maxSize is a WEI value (or BigInt / BigNumber).
    function setPoolMaxSize(uint _maxSize) public onlyRole(POOL_MANAGER) {
        require(!dataStorage.getBoolStorage(keccak256(abi.encodePacked("isPoolLive"))), "The pool is currently live.");
        bytes32 poolMaxSizeTag = keccak256(abi.encodePacked("poolMaxSize"));
        dataStorage.setUintStorage(poolMaxSizeTag, _maxSize);
    }    

    /// @dev Set the interval in days of the rewards period.
    function setRewardsInterval(uint _daysToRewards) public onlyRole(POOL_MANAGER) {
        require(_daysToRewards >= 1, "The minimum rewards interval is one day.");
        require(!dataStorage.getBoolStorage(keccak256(abi.encodePacked("isPoolLive"))), "The pool is currently live.");
        bytes32 daysRewTag = keccak256(abi.encodePacked("daysToRewards"));
        dataStorage.setUintStorage(daysRewTag, _daysToRewards);
    }

    /// @dev Set the interest per effective period.
    /// @param _rewardsInterest within the storage has 6 decimals.
    /// @notice E.G. If 0.001134 rate is desired, 0.001134 * (10**6) = 1134.
    function setRewardsInterest(uint _rewardsInterest) public onlyRole(POOL_MANAGER) {
        require(!dataStorage.getBoolStorage(keccak256(abi.encodePacked("isPoolLive"))), "The pool is currently live.");
        bytes32 rewardsIntTag = keccak256(abi.encodePacked("rewardsInterestPerPeriod"));
        dataStorage.setUintStorage(rewardsIntTag, _rewardsInterest);
    }

    /// @dev Set the max. contribution allowed for each user.
    /// @param _newContrLimit is a WEI value.
    function setContributionLimit(uint _newContrLimit) public onlyRole(POOL_MANAGER){
        require(!dataStorage.getBoolStorage(keccak256(abi.encodePacked("isPoolLive"))), "The pool is currently live.");
        bytes32 contrLimitTag = keccak256(abi.encodePacked("contributionLimit"));
        dataStorage.setUintStorage(contrLimitTag, _newContrLimit);
    }

    /// @dev Set the min. contribution allowed for each user.
    /// @param _newMinContr is a WEI value.
    function setMinContribution(uint _newMinContr) public onlyRole(POOL_MANAGER){
        bytes32 contrLimitTag = keccak256(abi.encodePacked("contributionLimit"));
        require(!dataStorage.getBoolStorage(keccak256(abi.encodePacked("isPoolLive"))), "The pool is currently live.");
        require(dataStorage.getUintStorage(contrLimitTag) > _newMinContr, "The min. contr. limit needs to be smaller than the max. limit.");
        
        bytes32 minContrTag = keccak256(abi.encodePacked("minContribution"));
        dataStorage.setUintStorage(minContrTag, _newMinContr);
    }
    

    // ====== Pool Data Getters  ======
    /// @dev Getters for each pool variable.

    function getContractAddress(string memory _contractName) internal view returns(address){
        bytes32 addressTag = keccak256(abi.encodePacked("contract_address", _contractName));
        address contractAddress = dataStorage.getAddressStorage(addressTag);
        require(contractAddress != address(0x0), "Contract address not found.");
        return contractAddress;
    }

    function getPoolBaseAddress() public view returns(address){
        bytes32 addressTag = keccak256(abi.encodePacked("contract_address", "PoolBase"));
        address contractAddress = dataStorage.getAddressStorage(addressTag);
        return contractAddress;
    }    

    function getPoolState() public view returns(bool){
        bytes32 statusTag = keccak256(abi.encodePacked("isPoolLive"));
        return dataStorage.getBoolStorage(statusTag);
    }

    function getPoolMaxSize() public view returns(uint){
        bytes32 poolMaxSizeTag = keccak256(abi.encodePacked("poolMaxSize"));
        return dataStorage.getUintStorage(poolMaxSizeTag);        
    }

    function getRewardsInterval() public view returns(uint){
        bytes32 daysRewTag = keccak256(abi.encodePacked("daysToRewards"));
        return dataStorage.getUintStorage(daysRewTag);
    }

    function getRewardsInterest() public view returns(uint){
        bytes32 rewardsIntTag = keccak256(abi.encodePacked("rewardsInterestPerPeriod"));
        return dataStorage.getUintStorage(rewardsIntTag);
    }

    function getContributionLimit() public view returns(uint){
        bytes32 contrLimitTag = keccak256(abi.encodePacked("contributionLimit"));
        return dataStorage.getUintStorage(contrLimitTag);
    }

    function getMinContribution() public view returns(uint){
        bytes32 minContrTag = keccak256(abi.encodePacked("minContribution"));
        return dataStorage.getUintStorage(minContrTag);
    }    






}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

interface rwETHTokenInterface is IERC20 {

    function setRwETHTokenAddress() external;    
    function calcEthValue(uint _rwEthAmount) external view returns(uint);
    function calcRwEthValue(uint _ethAmount) external view returns(uint);
    function getUnitPrice(uint _ethAmount) external view returns(uint);
    function mint(address _to, uint _ethAmount) external;
    function burn(uint _rwEthAmount) external;
    function getRwETHTokenAddress() external view returns(address);
             

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface PoolClientInterface {

    function deposit() external payable;
    function withdraw() external payable;
    function calculateRewards() external;
    function setAllowance(uint _amount) external returns(uint);
    function getPoolClientAddress() external view returns(address);
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


interface TokenBalancesInterface {
 
    function getTotalEthSupply() external view returns(uint);
    function getTotalrwEthSupply() external view returns(uint);
    function getRwEthBurned() external view returns(uint);   

    function getTotalEtherStaked() external view returns(uint);
    function getTotalRewardsInjected() external view returns(uint);
    function getRwEthMintedByUser(address _user) external view returns(uint);     
    function getTokenBalancesAddress() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface PoolVaultInterface {

    function poolEtherSize() external view returns(uint);
    function storeEther() external payable;
    function processRewards() external payable;
    function withdrawEther(address _to, uint _ethAmount) external;
    function getPoolVaultAddress() external view returns(address);
            

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface DataStorageInterface {

    // ====== Storage Contract Control ======
    function getStorageStatus() external view returns(bool);
    function getCurrentGuardian() external view returns(address);
    function setNewGuardian(address _newGuardian) external;
    function confirmGuard() external;
    function setStorageLive() external;

    // ====== Storage Mappings Getters ======
    function getUintStorage(bytes32 _id) external view returns(uint256);
    function getBoolStorage(bytes32 _id) external view returns(bool);
    function getAddressStorage(bytes32 _id) external view returns(address);
    function getDataStorageAddress() external view returns(address);

    // ====== Storage Mappings Setters ======
    function setUintStorage(bytes32 _id, uint256 _value) external;
    function setBoolStorage(bytes32 _id, bool _value) external;
    function setAddressStorage(bytes32 _id, address _value) external; 
    function increaseUintStorage(bytes32 _id, uint256 _increment) external;
    function decreaseUintStorage(bytes32 _id, uint256 _decrement) external;        

    // ====== Storage Mappings Deleters ======
    function deleteUintStorage(bytes32 _id) external;
    function deleteBoolStorage(bytes32 _id) external;
    function deleteAddressStorage(bytes32 _id) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}