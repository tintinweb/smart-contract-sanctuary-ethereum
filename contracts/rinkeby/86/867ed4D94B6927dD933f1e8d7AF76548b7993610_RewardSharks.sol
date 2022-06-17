// File: contracts/SmartChefInitializable.sol
// SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract RewardSharks is Ownable, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant STAKE_ROLE = keccak256("STAKE_ROLE");
    bytes32 public constant CLAIM_ROLE = keccak256("CLAIM_ROLE");
    bytes32 public constant BOOST_ROLE = keccak256("BOOST_ROLE");

    // The Alpha Shark Token
    IERC20 public rewardTokenAddress;

    address raffleAddress;
    address dutchRaffle;

    // The address of the smart chef factory
    address public ALPHA_SHARK_FACTORY;

    // Whether it is initialized
    bool public isInitialized;

    // Token Decimals
    uint256 public tokenDecimals = 18;

    // Rewards Claims
    bool public claimAllowed = true;

    mapping(address => uint256[]) public ownerTokenList;

    mapping(address => uint256) public totalTokens; // Address => Total Tokens
    
    mapping(address => uint256) public tokenSpent;

    mapping(address => uint256) public lockedTokens; // Address => Locked Tokens

    // Reward Token Mapping (Token Id => Reward ) Rewards --> Tokens/Day
    mapping(uint256 => uint256) public tokenIdReward;

    bool public firstTwelveMonth = true;
    bool public firstSixMonth = true;
    bool public firstStakeTimestamp = true;
    uint256 public stakingCounter = 0;

    struct Boosts {
        uint256 boost_type;
        uint boostAmountPercentage; 
        uint256 expireTimeStamp;
    }

    struct Sharks {
        uint256 sharkId;
        uint256 stakingTimeStamp;
        uint256 lastClaimTimeStamp;
        address ownerAddress;
        bool tokenStaked; 
        uint256[] activeBoost;
        bool shiver;
        uint shiverId;
    }

    Boosts[] public listOfBoosters;
    // Boost_type => Boosts
    mapping(uint256 => Boosts) public getBooster;

    // sharkId => Sharks
    mapping(uint256 => Sharks) public getSharks;

    // Active Shiver Counter Missing ?
    uint256 public shiverCounter = 0;
    // ShiverID => Shiver Token List
    mapping(uint256 => uint256[]) public getShiver;

    // List of alloted boost for addresses
    mapping(address => uint256[]) public availableBoosts;

    

    // Event Stake
    // Event Shiver
    // Event Unstake
    // Event Shiver Break
    // Claim rewards
    // Toggle Claim Status
    // event Stake(address indexed user, uint256 amount);
    // event RewardsStop(uint256 blockNumber);
    // event Withdraw(address indexed user, uint256 amount);

    constructor() ReentrancyGuard() {
        ALPHA_SHARK_FACTORY = msg.sender;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /*
     * @notice Initialize the contract
     * @param _rewardToken: reward token address
     * @param _admin: admin address with ownership
     */
    function initialize(
        IERC20 _rewardTokenAddress,
        address _raffleAddress,
        address _dutchRaffle,
        address _admin
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == ALPHA_SHARK_FACTORY, "Not factory");

        // Make this contract initialized
        isInitialized = true;
        rewardTokenAddress = _rewardTokenAddress;
        raffleAddress = _raffleAddress;
        dutchRaffle = _dutchRaffle;
        transferOwnership(_admin);
    }

    function updateRewardAddress(IERC20 _rewardTokenAddress) external onlyOwner {
        rewardTokenAddress = _rewardTokenAddress;
    }

    function toggleClaimReward() external onlyOwner {
        claimAllowed = !claimAllowed;
    }

    function ifBoostTypeAvailable(uint256 _boostType) public view returns (bool) {
        for(uint256 i=0; i<listOfBoosters.length; i++)
        {
            if(listOfBoosters[i].boost_type == _boostType)
            {
                return false;
            }
        }
        return true;
    }

    function addBooster(uint256 _boostType, uint _boostPercentage, uint256 _expireTimeStamp) external {
        require(hasRole(BOOST_ROLE, msg.sender), "Caller is not a booster");
        require(ifBoostTypeAvailable(_boostType), "Boost Type Not Available");
        Boosts memory b1;
        b1.boost_type = _boostType;
        b1.boostAmountPercentage = _boostPercentage;
        b1.expireTimeStamp = _expireTimeStamp;
        listOfBoosters.push(b1);
        getBooster[_boostType] = b1;
    }

    function assignBooster(address _address, uint256 _boostType) external {
        require(hasRole(BOOST_ROLE, msg.sender), "Caller is not a booster");
        require(!ifBoostTypeAvailable(_boostType), "Boost Type Not Available");
        availableBoosts[_address].push(_boostType);
    }

    function userBoostAvailabitiy(uint256 _boostType, address _address) internal returns (bool) {
        uint256[] storage listOfBoosts = availableBoosts[_address];
        uint256 index = 0;
        bool flag = false;
        for(uint256 i=0; i<listOfBoosts.length; i++)
        {
            if(listOfBoosts[i] == _boostType){
                index = i;
                flag = true;
            }
        }
        if(flag)
        {
            listOfBoosts[index] = listOfBoosts[listOfBoosts.length -1 ];
            listOfBoosts.pop();
            return true;
        }
        else{
            return false;
        }
    }

    function returnSingleSharkData(uint256 _tokenID) external view returns (Sharks memory) {
        return getSharks[_tokenID];
    }

    function returnOwnerAllSharkData(address _address) external view returns (Sharks[] memory,Boosts[] memory, uint256[] memory, Boosts[] memory) {
        // require(ownerTokenList[_address].length > 0, "No Tokens Staked");

        //Sharks
        Sharks[] memory _shark = new Sharks[](ownerTokenList[_address].length);
        uint256 _boostCounter = 0;
        for(uint256 i=0; i<ownerTokenList[_address].length; i++){
            _shark[i] = getSharks[ownerTokenList[_address][i]];
            _boostCounter += getSharks[ownerTokenList[_address][i]].activeBoost.length;
        }
        
        // Boosts
        Boosts[] memory _boosts = new Boosts[](_boostCounter);
        uint256 currentBoostCounter = 0;
        for(uint256 i=0; i<ownerTokenList[_address].length; i++){
            Sharks memory _sharkTemp = getSharks[ownerTokenList[_address][i]];
            for(uint256 j=0; j<_sharkTemp.activeBoost.length; j++){
                _boosts[currentBoostCounter] = getBooster[_sharkTemp.activeBoost[j]];
                currentBoostCounter +=1;
            }
        }

        // Available Tokens
        uint256[] memory _tokenDetails = new uint256[](4);
        _tokenDetails[0] = totalTokens[_address];
        _tokenDetails[1] = lockedTokens[_address];
        _tokenDetails[2] = availableTokens(_address);
        _tokenDetails[3] = tokenSpent[_address];

        // Available Boosts
        uint256[] memory _tempAvailableBoosts = availableBoosts[_address];
        Boosts[] memory _boostsAvailable = new Boosts[](_tempAvailableBoosts.length);
        uint256 counter2 = 0;
        for(uint256 i=0; i<_tempAvailableBoosts.length; i++){
            _boostsAvailable[counter2] = getBooster[_tempAvailableBoosts[i]];
            counter2 += 1;
        }
        return (_shark, _boosts, _tokenDetails, _boostsAvailable);
    }

    function getOwnerList(address _address) external view returns (uint256[] memory) {
        return ownerTokenList[_address];
    }

    function getActiveBoost(uint256 _tokenId, uint256 activeBoostNumber) external view returns (uint256) {
        Sharks memory _shark = getSharks[_tokenId];
        return _shark.activeBoost[activeBoostNumber];
    }
 
    function activateBooster(uint256 _boostType, uint256 _tokenId, address _address) external {
        require(hasRole(BOOST_ROLE, msg.sender), "Caller is not a booster");
        require(userBoostAvailabitiy(_boostType, _address), "Boost is not available");
        Sharks storage _shark = getSharks[_tokenId];
        require(_shark.tokenStaked , "Token is not staked");
        _shark.activeBoost.push(_boostType);
        getSharks[_tokenId] = _shark;
    }

    function checkFixedBooster(uint256 _tokenId) public view returns (uint256) {
        // Add require staked statement 
        // S1 Booster
        Sharks memory _shark = getSharks[_tokenId];
        if(!_shark.tokenStaked){
            return 0;
        }
        uint256 rewardAdder = 0;
        if(_tokenId<1000 && firstTwelveMonth)
        {
            rewardAdder = rewardAdder + 30;
        }
        else if(_tokenId%2==1 && firstSixMonth)
        {
            rewardAdder = rewardAdder + 10;
        }
        uint256 timeDiffMonth = (block.timestamp -  _shark.stakingTimeStamp) / 30 days;
        rewardAdder = rewardAdder + timeDiffMonth.mul(5);
        return (rewardAdder > 100 ? 100: rewardAdder); 
    }

    function calculateTotalRewards(uint256 _tokenId) public view returns (uint) {
        Sharks memory _shark = getSharks[_tokenId];
        if(!_shark.tokenStaked){
            return 0;
        }
        uint rewardPercent = checkFixedBooster(_tokenId);
        // S2 Booster
        if(_shark.shiver)
        {
            rewardPercent = rewardPercent + 100;
        }
        uint256[] memory activeBoosters = _shark.activeBoost;
        // S3 Booster
        uint rewardPercentS3 = 0;
        for(uint256 i=0;i<activeBoosters.length;i++)
        {
            Boosts memory _boost = getBooster[activeBoosters[i]];
            if(_boost.expireTimeStamp > block.timestamp)
            {
                rewardPercentS3 = rewardPercentS3 + _boost.boostAmountPercentage;
            }
        }
        rewardPercent = rewardPercent + (rewardPercentS3 > 100 ? 100: rewardPercentS3);
        return rewardPercent;
    }

    function claimRewards(uint256 _tokenId) public {
        require(hasRole(CLAIM_ROLE, msg.sender), "Caller is not a claimer");
        require(claimAllowed, "Rewards Stopped");
        Sharks storage _shark = getSharks[_tokenId];
        if(!_shark.tokenStaked){
            return ;
        }
        uint256 rewardPercent = calculateTotalRewards(_tokenId);

        // Calculate Reward Amount
        uint256 rewardPerMinute = tokenIdReward[_tokenId].mul(10 ** 18).div(24).div(60);
        uint256 timeElapsed = (block.timestamp - _shark.lastClaimTimeStamp) / 1 minutes; 
        uint256 amountReward = timeElapsed.mul(rewardPerMinute).mul(100 + rewardPercent).div(100);

        _shark.lastClaimTimeStamp = block.timestamp;
        totalTokens[_shark.ownerAddress] += amountReward;
    }

    function claimAll(uint256 startIndex, uint256 endIndex) external {
        require(hasRole(CLAIM_ROLE, msg.sender), "Caller is not a claimer");
        for(uint256 i=startIndex; i <= endIndex; i++) {
            claimRewards(i);
        }
    }

    modifier onlyNFT {
        require(msg.sender == raffleAddress, "Can be only accessed by Raffle Contract");
        _;
    }

    modifier onlyDutchRaffle {
        require(msg.sender == dutchRaffle, "Can be only accessed by Dutch Raffle Contract");
        _;
    }

    // True ==> Add
    // False ==> Subtract
    function updateAddLockTokens(uint256 _amount, address _address,bool _add) external onlyNFT {
        if(_add){
            lockedTokens[_address] += _amount;
        }
        else{
            lockedTokens[_address] -= _amount;
        }
    }

    function updateTotalLockTokens(uint256 _amount, address _address) external onlyDutchRaffle {
        require(totalTokens[_address] >= _amount, "Insufficient Balance");
        totalTokens[_address] -= _amount;
        tokenSpent[_address] += _amount;
    }

    function availableTokens(address _address) public view returns (uint256) {
        return (totalTokens[_address] - lockedTokens[_address]);
    }

    function withdawTokens(uint256 _amount) external nonReentrant {
        require(availableTokens(msg.sender) >= _amount, "Insufficient Tokens");
        rewardTokenAddress.safeTransfer(msg.sender, _amount);
        totalTokens[msg.sender] -= _amount;
    }

    function depositTokens(uint256 _amount) external {
        rewardTokenAddress.transferFrom(msg.sender,address(this), _amount);
        totalTokens[msg.sender] += _amount;
    }

    function stakeNFT(uint256 _tokenId, address _address) external {
        require(hasRole(STAKE_ROLE, msg.sender), "Caller is not a staker");
        Sharks memory _shark = getSharks[_tokenId];
        require(!_shark.tokenStaked, "Token is Already Staked");
        if(_shark.stakingTimeStamp==0 && firstStakeTimestamp){
            _shark.lastClaimTimeStamp = 1648166400;
            _shark.stakingTimeStamp = 1648166400;
        }
        else{
            _shark.lastClaimTimeStamp = block.timestamp;
            _shark.stakingTimeStamp = block.timestamp;
        }
        _shark.sharkId = _tokenId;
        _shark.tokenStaked = true;
        _shark.ownerAddress = _address;
        _shark.activeBoost;
        
        getSharks[_tokenId] = _shark;
        ownerTokenList[_address].push(_tokenId);

        stakingCounter +=1;
        // Emit Event Stake
    }

    function checkShiverBreak(uint256 _tokenId) internal {
        Sharks memory _shark = getSharks[_tokenId];
        if(_shark.shiver==true)
        {
            uint256 ShiverID = _shark.shiverId;
            uint256[] memory shiverTokenList = getShiver[ShiverID];
            for(uint256 i=0;i<shiverTokenList.length;i++)
            {
                getSharks[shiverTokenList[i]].shiver = false;
                getSharks[shiverTokenList[i]].shiverId = 0;
            }
        }
    }

    function removeTokenFromOwnerList(uint256 _tokenId) internal {
        uint256[] storage listOfTokens = ownerTokenList[getSharks[_tokenId].ownerAddress];
        uint256 index = 0;
        bool flag = false;
        for(uint256 i=0; i<listOfTokens.length; i++)
        {
            if(listOfTokens[i] == _tokenId){
                index = i;
                flag = true;
            }
        }
        if(flag)
        {
            listOfTokens[index] = listOfTokens[listOfTokens.length -1];
            listOfTokens.pop();
        }
        ownerTokenList[getSharks[_tokenId].ownerAddress] = listOfTokens;
    }

    function unStakeNFT(uint256 _tokenId) external {
        require(hasRole(STAKE_ROLE, msg.sender), "Caller is not a staker");
        require(getSharks[_tokenId].tokenStaked, "Token is not Staked");
        getSharks[_tokenId].tokenStaked = false;
        
        checkShiverBreak(_tokenId);
        removeTokenFromOwnerList(_tokenId);
        stakingCounter -=1;
        // Emit Event Unstake
    }
    
    function makeShiver(uint256[] memory listOfTokens, address _address) external {
        require(hasRole(BOOST_ROLE, msg.sender), "Caller is not a booster");
        require(listOfTokens.length==5, "Shiver can be only made with 5 Tokens");
        for(uint256 i=0;i<5;i++){
            Sharks memory _shark = getSharks[listOfTokens[i]];
            require(_shark.shiver==false, "Shiver already activated for this token");
            require(_shark.ownerAddress==_address, "The address passed is not owner");
            require(_shark.tokenStaked, "Token not staked");
        }
        shiverCounter = shiverCounter + 1;
        for(uint256 i=0;i<5;i++){
            Sharks memory _shark = getSharks[listOfTokens[i]];
            _shark.shiverId = shiverCounter;
            _shark.shiver = true;
            getSharks[listOfTokens[i]] = _shark;
        }
        getShiver[shiverCounter] = listOfTokens;
    }

    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        rewardTokenAddress.safeTransfer(address(msg.sender), _amount);
    }

    function stopBooster(uint256 _boostType) external {
        require(hasRole(BOOST_ROLE, msg.sender), "Caller is not a booster");
        Boosts storage _boost = getBooster[_boostType];
        _boost.expireTimeStamp = block.timestamp;
    }

    function updateAllRewards(uint256[] memory _rewards, uint256[] memory _tokenIds) external {
        require(hasRole(BOOST_ROLE, msg.sender), "Caller is not a booster");
        require(_rewards.length==_tokenIds.length,"Length of Arrays Should be Equal");
        for(uint256 i=0;i<_rewards.length;i++)
        {
            tokenIdReward[_tokenIds[i]] = _rewards[i];
        }
    }

    function clearUpActiveBoost(uint256 startIndex, uint256 endIndex) external {
        require(hasRole(BOOST_ROLE, msg.sender), "Caller is not a booster");
        for(uint256 i=startIndex; i<=endIndex;i++)
        {
            Sharks storage _shark = getSharks[i];
            for(uint256 j=0; j < _shark.activeBoost.length;j++){
                Boosts memory _boost = getBooster[_shark.activeBoost[j]];
                if(_boost.expireTimeStamp < block.timestamp)
                {
                    _shark.activeBoost[j] = _shark.activeBoost[_shark.activeBoost.length -1];
                    _shark.activeBoost.pop();
                    if(j!=0){
                        j-=1;
                    }
                }
            }
        }
    }

    function updateSingleReward(uint256 _reward, uint256 _tokenId) external {
        require(hasRole(BOOST_ROLE, msg.sender), "Caller is not a booster");
        tokenIdReward[_tokenId] = _reward;
    }

    function toggleFirstTwelveMonth() external onlyOwner {
        firstTwelveMonth = !firstTwelveMonth;
    }

    function toggleFirstSixMonth() external onlyOwner {
        firstSixMonth = !firstSixMonth;
    }

    function toggleFirstStakeTimestamp() external onlyOwner {
        firstStakeTimestamp = !firstStakeTimestamp;
    }

    function updateRaffleAddress(address _address) external onlyOwner {
        raffleAddress = _address;
    }

    function updateDutchRaffleAddress(address _address) external onlyOwner {
        dutchRaffle = _address;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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