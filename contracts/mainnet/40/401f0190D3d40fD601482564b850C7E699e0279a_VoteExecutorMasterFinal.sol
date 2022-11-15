// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../interfaces/ILiquidityHandler.sol";
import "../interfaces/IAlluoToken.sol";
import "../interfaces/ILocker.sol";
import "../interfaces/IGnosis.sol";
import "../interfaces/IAlluoStrategyV2.sol";
import "../interfaces/IExchange.sol";                                                                 
import "../interfaces/IWrappedEther.sol";                               
import "../interfaces/IIbAlluo.sol";
import "../Farming/priceFeedsV2/PriceFeedRouterV2.sol";
import "./strategies/StrategyHandler.sol";

contract VoteExecutorMasterFinal is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable {

    using ECDSAUpgradeable for bytes32;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    address public constant ALLUO = 0x1E5193ccC53f25638Aa22a940af899B692e10B09;
    address public gnosis;
    address public locker;
    address public exchangeAddress;
    address public priceFeed;
    address public liquidityHandler;
    address public strategyHandler;
    IWrappedEther public constant wETH = IWrappedEther(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    uint256 public timeLock;
    uint256 public minSigns;
    bool public upgradeStatus;

    mapping(string => address) public ibAlluoSymbolToAddress;

    SubmittedData[] public submittedData;
    mapping(bytes32 => uint256) public hashExecutionTime;

    CrossChainInfo public crossChainInfo;
    mapping(uint => AssetBridging) public assetIdToAssetBridging;

    mapping(uint256 => Deposit[]) public assetIdToDepositList;

    uint slippage;

    struct Deposit{
        uint256 directionId;
        uint256 amount;
    }
    
    struct CrossChainInfo{
        address anyCallAddress;
        address anyCallExecutor;
        address nextChainExecutor;
        address previousChainExecutor;
        uint256 currentChain;
        uint256 nextChain;
        uint256 previousChain;
    }

    struct AssetBridging{
        address token;
        address anyToken;
        bytes4 functionSignature;
        address multichainRouter;
        uint256 minimumAmount;
    }
    
    struct Message {
        uint256 commandIndex;
        bytes commandData;
    }

    struct SubmittedData {
        bytes data;
        uint256 time;
        bytes[] signs;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _multiSigWallet
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        require(_multiSigWallet.isContract(), "Executor: Not contract");
        gnosis = _multiSigWallet;
        minSigns = 1;
        exchangeAddress = 0x29c66CF57a03d41Cfe6d9ecB6883aa0E2AbA21Ec;

        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _grantRole(UPGRADER_ROLE, _multiSigWallet);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    receive() external payable {
        if(msg.sender != address(wETH)){
            wETH.deposit{value : msg.value}();
        }
    }

    /// @notice Allows anyone to submit data for execution of votes
    /// @dev Attempts to parse at high level and then confirm hash before submitting to queue
    /// @param data Payload fully encoded as required (see formatting using encoding functions below)

    function submitData(bytes memory data) external {

        (bytes32 hashed, Message[] memory _messages, uint256 timestamp) = abi.decode(data, (bytes32, Message[], uint256));

        require(hashed == keccak256(abi.encode(_messages, timestamp)), "Hash doesn't match");

        SubmittedData memory newSubmittedData;
        newSubmittedData.data = data;
        newSubmittedData.time = block.timestamp;
        submittedData.push(newSubmittedData);
    }

    /// @notice Allow anyone to approve data for execution given off-chain signatures
    /// @dev Checks against existing sigs submitted and only allow non-duplicate multisig owner signatures to approve the payload
    /// @param _dataId Id of data payload to be approved
    /// @param _signs Array of off-chain EOA signatures to approve the payload.

    function approveSubmittedData(uint256 _dataId, bytes[] memory _signs) external {
        // SubmittedData storage fullSubmittedData = submittedData[_dataId];
        (bytes32 dataHash,,) = abi.decode(submittedData[_dataId].data, (bytes32, Message[], uint256));
        address[] memory owners = IGnosis(gnosis).getOwners();
        bytes[] memory submittedSigns = submittedData[_dataId].signs;
        address[] memory uniqueSigners = new address[](owners.length);
        uint256 numberOfSigns;

        for (uint256 i; i< submittedSigns.length; i++) {
            numberOfSigns++;
            uniqueSigners[i]= _getSignerAddress(dataHash, submittedSigns[i]);
        }

        for (uint256 i; i < _signs.length; i++) {
            for (uint256 j; j < owners.length; j++) {
                if(_verify(dataHash, _signs[i], owners[j]) && _checkUniqueSignature(uniqueSigners, owners[j])){
                    submittedData[_dataId].signs.push(_signs[i]);
                    uniqueSigners[numberOfSigns] = owners[j];
                    numberOfSigns++;
                    break;
                }
            }
        }
    }


    function executeSpecificData(uint256 index) external {
            SubmittedData memory exactData = submittedData[index];
            (bytes32 hashed, Message[] memory messages,) = abi.decode(exactData.data, (bytes32, Message[], uint256));
            require(exactData.time + timeLock < block.timestamp, "Under timelock");
            require(hashExecutionTime[hashed] == 0, "Duplicate Hash");

            StrategyHandler handler = StrategyHandler(strategyHandler);

            if(exactData.signs.length >= minSigns){
                uint256 currentChain = crossChainInfo.currentChain;

                handler.calculateAll();

                bool needToWithdrawTreasury;
                uint amountToWithdrawTreasury;
                Message memory lastMessage = messages[messages.length-1];
                if(lastMessage.commandIndex == 3){
                    (int256 treasuryDelta) = abi.decode(lastMessage.commandData, (int256));
                    handler.adjustTreasury(treasuryDelta);
                    if(treasuryDelta < 0){
                        needToWithdrawTreasury = true;
                        amountToWithdrawTreasury = uint(-treasuryDelta);
                    }
                }
               
                uint[] memory amountsDeployed = handler.getLatestDeployed();
                
                for (uint256 j; j < messages.length; j++) {
                    uint256 commandIndex = messages[j].commandIndex;
                    if(commandIndex == 0){
                        (string memory ibAlluoSymbol, uint256 newAnnualInterest, uint256 newInterestPerSecond) = abi.decode(messages[j].commandData, (string, uint256, uint256));
                        IIbAlluo ibAlluo = IIbAlluo(ibAlluoSymbolToAddress[ibAlluoSymbol]);
                        if(ibAlluo.annualInterest() != newAnnualInterest){
                           ibAlluo.setInterest(newAnnualInterest, newInterestPerSecond);
                        }
                    }
                    else if(commandIndex == 1){
                        (uint256 mintAmount, uint256 period) = abi.decode(messages[j].commandData, (uint256, uint256));
                        IAlluoToken(ALLUO).mint(locker, mintAmount);
                        ILocker(locker).setReward(mintAmount / (period));
                    }

                    else if(commandIndex == 2) {
                        // Handle all withdrawals first and then add all deposit actions to an array to be executed afterwards
                        (uint256 directionId, uint256 percent) = abi.decode(messages[j].commandData, (uint256, uint256));
                        (address strategyPrimaryToken, StrategyHandler.LiquidityDirection memory direction) = handler.getDirectionFullInfoById(directionId);
                        if (direction.chainId == currentChain) {

                            if(percent == 0){
                                IAlluoStrategyV2(direction.strategyAddress).exitAll(direction.exitData, 10000, strategyPrimaryToken, address(this), false, false);
                                handler.removeFromActiveDirections(directionId);
                            }
                            else{
                                uint newAmount = percent * amountsDeployed[direction.assetId] / 10000;
                                if(newAmount < direction.latestAmount){
                                    uint exitPercent = 10000 - newAmount * 10000 / direction.latestAmount;
                                    IAlluoStrategyV2(direction.strategyAddress).exitAll(direction.exitData, exitPercent, strategyPrimaryToken, address(this), false, false);
                                }
                                else if(newAmount != direction.latestAmount){
                                    uint depositAmount = newAmount - direction.latestAmount;
                                    assetIdToDepositList[direction.assetId].push(Deposit(directionId, depositAmount));
                                }
                            }
                        }
                    }
                    else if(commandIndex == 3 && j != messages.length - 1) {
                        revert("3 command !last");
                    }

                }
                if(needToWithdrawTreasury){
                    assetIdToDepositList[0].push(Deposit(type(uint).max, amountToWithdrawTreasury));
                }
                hashExecutionTime[hashed] = block.timestamp;
                bytes memory finalData = abi.encode(exactData.data, exactData.signs);
                IAnyCall(crossChainInfo.anyCallAddress).anyCall(crossChainInfo.nextChainExecutor, finalData, address(0), crossChainInfo.nextChain, 0);
            }     
    }

    // Execute deposits. Only executes if we have sufficient balances.
    function _executeDeposits() internal {
        PriceFeedRouterV2 feed = PriceFeedRouterV2(priceFeed);
        StrategyHandler handler = StrategyHandler(strategyHandler);
        address exchange = exchangeAddress;
        uint8 numberOfAssets = handler.numberOfAssets();
        for (uint256 i; i < numberOfAssets; i++) {
            Deposit[] storage depositList = assetIdToDepositList[i];
            uint depositListLength = depositList.length;
            address strategyPrimaryToken = handler.getPrimaryTokenByAssetId(i,1);
            uint primaryDecimalsMultiplier = 10**(18 - IERC20MetadataUpgradeable(strategyPrimaryToken).decimals()) ;
            while(depositListLength > 0){
                Deposit memory depositInfo = depositList[depositListLength - 1];
                if(depositInfo.directionId != type(uint).max){

                    StrategyHandler.LiquidityDirection memory direction = handler.getLiquidityDirectionById(depositInfo.directionId);
                    (uint256 fiatPrice, uint8 fiatDecimals) = feed.getPrice(strategyPrimaryToken, i);
                    uint exactAmount = (depositInfo.amount * 10**fiatDecimals) / fiatPrice;
                    uint256 tokenAmount = exactAmount / primaryDecimalsMultiplier;
                    uint256 actualBalance = IERC20MetadataUpgradeable(strategyPrimaryToken).balanceOf(address(this));
                    if(depositListLength == 1 && actualBalance < tokenAmount){
                        uint assetAmount = handler.getAssetAmount(i);
                        uint assetMaxSlippageAmount = assetAmount - (assetAmount * (10000 - slippage) / 10000);
                        if(tokenAmount - actualBalance < assetMaxSlippageAmount/ primaryDecimalsMultiplier){
                            tokenAmount = actualBalance;
                        }
                        else{
                            revert("VEMaster: Slippage screwed you");
                        }
                    }
                    if (direction.entryToken != strategyPrimaryToken) {
                        IERC20MetadataUpgradeable(strategyPrimaryToken).safeApprove(exchange, tokenAmount);
                        tokenAmount = IExchange(exchange).exchange(strategyPrimaryToken, direction.entryToken, tokenAmount, 0);
                    }
                    IERC20MetadataUpgradeable(direction.entryToken).safeTransfer(direction.strategyAddress, tokenAmount);
                    IAlluoStrategyV2(direction.strategyAddress).invest(direction.entryData, tokenAmount);
                    handler.addToActiveDirections(depositInfo.directionId);
                }
                else{
                    (uint256 fiatPrice, uint8 fiatDecimals) = feed.getPrice(strategyPrimaryToken, i);
                    uint exactAmount = (depositInfo.amount * 10**fiatDecimals) / fiatPrice;
                    uint256 tokenAmount = exactAmount / primaryDecimalsMultiplier;
                    
                    IERC20MetadataUpgradeable(strategyPrimaryToken).safeTransfer(gnosis, tokenAmount);
                }
                depositList.pop();
                depositListLength--;
            }
        }
        handler.calculateOnlyLp();
    }
    
    function executeDeposits() public onlyRole(DEFAULT_ADMIN_ROLE){
        _executeDeposits();
    }


    function getSubmittedData(uint256 _dataId) external view returns(bytes memory, uint256, bytes[] memory){
        SubmittedData memory submittedDataExact = submittedData[_dataId];
        return(submittedDataExact.data, submittedDataExact.time, submittedDataExact.signs);
    }

    function encodeApyCommand(
        string memory _ibAlluoName, 
        uint256 _newAnnualInterest, 
        uint256 _newInterestPerSecond
    ) public pure  returns (uint256, bytes memory) {
        bytes memory encodedCommand = abi.encode(_ibAlluoName, _newAnnualInterest, _newInterestPerSecond);
        return (0, encodedCommand);
    }

    function encodeMintCommand(
        uint256 _newMintAmount,
        uint256 _period
    ) public pure  returns (uint256, bytes memory) {
        bytes memory encodedCommand = abi.encode(_newMintAmount, _period);
        return (1, encodedCommand);
    }

   function encodeLiquidityCommand(
        string memory _codeName,
        uint256 _percent
    ) public view  returns (uint256, bytes memory) {
        uint256 directionId = StrategyHandler(strategyHandler).getDirectionIdByName(_codeName);
        return (2, abi.encode(directionId, _percent));
    }

    function encodeTreasuryAllocationChangeCommand(
        int256 _delta
    ) public pure  returns (uint256, bytes memory) {
        bytes memory encodedCommand = abi.encode(_delta);
        return (3, encodedCommand);
    }
    
    function encodeAllMessages(uint256[] memory _commandIndexes, bytes[] memory _messages) public view  returns (bytes32 messagesHash, Message[] memory messages, bytes memory inputData) {
        uint256 timestamp = block.timestamp;
        uint length = _commandIndexes.length;
        require(length == _messages.length, "Array length mismatch");

        for (uint256 i; i < length; i++) {
            if(_commandIndexes[i] == 3){
                uint temporaryIndex = _commandIndexes[length-1];
                bytes memory temporaryMessage = _messages[length-1];
                _commandIndexes[length-1] = _commandIndexes[i];
                _messages[length-1] = _messages[i];
                _commandIndexes[i] = temporaryIndex;
                _messages[i] = temporaryMessage;
            }
        }

        messages = new Message[](length);
        for (uint256 i; i < length; i++) {
            messages[i] = Message(_commandIndexes[i], _messages[i]);
        }
        messagesHash = keccak256(abi.encode(messages, timestamp));
        inputData = abi.encode(
                messagesHash,
                messages,
                timestamp
        );
    }

    /// @notice Updates all the ibAlluo addresses used when setting APY
    function updateAllIbAlluoAddresses() public {
        address[] memory ibAlluoAddressList = ILiquidityHandler(liquidityHandler).getListOfIbAlluos();
        for (uint256 i; i< ibAlluoAddressList.length; i++) {
            ibAlluoSymbolToAddress[IIbAlluo(ibAlluoAddressList[i]).symbol()] = ibAlluoAddressList[i];
        }
    }

    function cleanDepositList(uint256 _assetId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        delete assetIdToDepositList[_assetId];
    }

    function removeTokenByAddress(address _address, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_address != address(0), "Wrong address");
        IERC20MetadataUpgradeable(_address).safeTransfer(msg.sender, _amount);
    }

    function _verify(bytes32 data, bytes memory signature, address account) internal pure returns (bool) {
        return data
            .toEthSignedMessageHash()
            .recover(signature) == account;
    }
    function _getSignerAddress(bytes32 data, bytes memory signature) internal pure returns (address) {
        return data
            .toEthSignedMessageHash()
            .recover(signature);
    }
    
    function _checkUniqueSignature(address[] memory _uniqueSigners, address _signer) internal pure returns (bool) {
        for (uint256 k; k< _uniqueSigners.length; k++) {
            if (_uniqueSigners[k] ==_signer) {
                return false;
            }
        }
        return true;
    }

    function setCrossChainInfo(
        address _anyCallAddress,
        address _anyCallExecutor,
        address _nextChainExecutor,
        address _previousChainExecutor,
        uint256 _currentChain,
        uint256 _nextChain,
        uint256 _previousChain
        ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        crossChainInfo = CrossChainInfo(_anyCallAddress, _anyCallExecutor, _nextChainExecutor, _previousChainExecutor, _currentChain, _nextChain, _previousChain);
    }

    /// @notice Sets the minimum required signatures before data is accepted on L2.
    /// @param _minSigns New value
    function setMinSigns(uint256 _minSigns) public onlyRole(DEFAULT_ADMIN_ROLE) {
        minSigns = _minSigns;
    }

    /**
    * @notice Set the address of the multisig.
    * @param _gnosisAddress  
    **/
    function setGnosis(address _gnosisAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        gnosis = _gnosisAddress;
    }

    function setLocker(address _lockerAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        locker = _lockerAddress;
    }

    function setHandler(address _newHandler)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_newHandler.isContract(), "Executor: Not contract");
        liquidityHandler = _newHandler;
    }

    function setExchangeAddress(address _newExchange) public onlyRole(DEFAULT_ADMIN_ROLE) {
        exchangeAddress = _newExchange;
    }

    function setSlippage(uint _slippage) public onlyRole(DEFAULT_ADMIN_ROLE) {
        slippage = _slippage;
    }

    function setStrategyHandler(address _newHandler) public onlyRole(DEFAULT_ADMIN_ROLE) {
        strategyHandler = _newHandler;
    }

    function setPriceFeed(address _newFeed) public onlyRole(DEFAULT_ADMIN_ROLE) {
        priceFeed = _newFeed;
    }

    function grantRole(bytes32 role, address account)
    public
    override
    onlyRole(getRoleAdmin(role)) {
        if (role == DEFAULT_ADMIN_ROLE) {
            require(account.isContract(), "Handler: Not contract");
        }
        _grantRole(role, account);
    }

    function changeUpgradeStatus(bool _status)
    external
    onlyRole(DEFAULT_ADMIN_ROLE) {
        upgradeStatus = _status;
    }

    function changeTimeLock(uint256 _newTimeLock)
    external
    onlyRole(DEFAULT_ADMIN_ROLE) {
        timeLock = _newTimeLock;
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(UPGRADER_ROLE)
    override {
        require(upgradeStatus, "Executor: Upgrade not allowed");
        upgradeStatus = false;
    }

    function multicall(
        address[] calldata destinations,
        bytes[] calldata calldatas
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = destinations.length;
        for (uint256 i = 0; i < length; i++) {
            destinations[i].functionCall(calldatas[i]);
        }
    }
}


interface IAnyCall {
    function anyCall(address _to, bytes calldata _data, address _fallback, uint256 _toChainID, uint256 _flags) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface ILiquidityHandler is IAccessControl{

    function adapterIdsToAdapterInfo(uint256)
        external
        view
        returns (
            string memory name,
            uint256 percentage,
            address adapterAddress,
            bool status
        );

    function changeAdapterStatus(uint256 _id, bool _status) external;

    function changeUpgradeStatus(bool _status) external;

    function deposit(address _token, uint256 _amount) external;
    function deposit ( address _token, uint256 _amount, address _targetToken) external;

    function getActiveAdapters()
        external
        view
        returns (ILiquidityHandlerStructs.AdapterInfo[] memory, address[] memory);

    function getAdapterAmount(address _ibAlluo) external view returns (uint256);

    function getAdapterId(address _ibAlluo) external view returns (uint256);

    function getAllAdapters()
        external
        view
        returns (ILiquidityHandlerStructs.AdapterInfo[] memory, address[] memory);

    function getExpectedAdapterAmount(address _ibAlluo, uint256 _newAmount)
        external
        view
        returns (uint256);

    function getIbAlluoByAdapterId(uint256 _adapterId)
        external
        view
        returns (address);

    function getLastAdapterIndex() external view returns (uint256);

    function getListOfIbAlluos() external view returns (address[] memory);

    function getWithdrawal(address _ibAlluo, uint256 _id)
        external
        view
        returns (ILiquidityHandlerStructs.Withdrawal memory);


    function ibAlluoToWithdrawalSystems(address)
        external
        view
        returns (
            uint256 lastWithdrawalRequest,
            uint256 lastSatisfiedWithdrawal,
            uint256 totalWithdrawalAmount,
            bool resolverTrigger
        );

    function isUserWaiting(address _ibAlluo, address _user)
        external
        view
        returns (bool);

    function pause() external;

    function paused() external view returns (bool);

    function removeTokenByAddress(
        address _address,
        address _to,
        uint256 _amount
    ) external;


    function satisfyAdapterWithdrawals(address _ibAlluo) external;

    function satisfyAllWithdrawals() external;

    function setAdapter(
        uint256 _id,
        string memory _name,
        uint256 _percentage,
        address _adapterAddress,
        bool _status
    ) external;

    function setIbAlluoToAdapterId(address _ibAlluo, uint256 _adapterId)
        external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function upgradeStatus() external view returns (bool);

    function withdraw(
        address _user,
        address _token,
        uint256 _amount
    ) external;
    function withdraw ( address _user, address _token, uint256 _amount, address _outputToken ) external;

    function getAdapterCoreTokensFromIbAlluo(address _ibAlluo) external view returns (address,address);

}

interface ILiquidityHandlerStructs {
    struct AdapterInfo {
        string name;
        uint256 percentage;
        address adapterAddress;
        bool status;
    }

    struct Withdrawal {
        address user;
        address token;
        uint256 amount;
        uint256 time;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";


interface IAlluoToken is IAccessControl{
  function ADMIN_ROLE (  ) external view returns ( bytes32 );
  function BURNER_ROLE (  ) external view returns ( bytes32 );
  function CAP_CHANGER_ROLE (  ) external view returns ( bytes32 );
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function DOMAIN_SEPARATOR (  ) external view returns ( bytes32 );
  function MINTER_ROLE (  ) external view returns ( bytes32 );
  function PAUSER_ROLE (  ) external view returns ( bytes32 );
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address account ) external view returns ( uint256 );
  function blocklist ( address ) external view returns ( bool );
  function burn ( address account, uint256 amount ) external;
  function changeCap ( uint256 _newCap ) external;
  function decimals (  ) external view returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function delegate ( address delegatee ) external;
  function delegateBySig ( address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s ) external;
  function delegates ( address account ) external view returns ( address );
  function getPastTotalSupply ( uint256 blockNumber ) external view returns ( uint256 );
  function getPastVotes ( address account, uint256 blockNumber ) external view returns ( uint256 );
  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function maxTotalSupply (  ) external view returns ( uint256 );
  function mint ( address to, uint256 amount ) external;
  function name (  ) external view returns ( string memory);
  function nonces ( address owner ) external view returns ( uint256 );
  function numCheckpoints ( address account ) external view returns ( uint32 );
  function paused (  ) external view returns ( bool );
  function permit ( address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s ) external;
  function setBlockStatus ( address _user, bool _state ) external;
  function setPause ( bool _state ) external;
  function setWhiteStatus ( address _user, bool _state ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory);
  function totalSupply (  ) external view returns ( uint256 );
  function transfer ( address recipient, uint256 amount ) external returns ( bool );
  function transferFrom ( address sender, address recipient, uint256 amount ) external returns ( bool );
  function unlockERC20 ( address _token, address _to, uint256 _amount ) external;
  function whitelist ( address ) external view returns ( bool );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ILocker {
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function UPGRADER_ROLE (  ) external view returns ( bytes32 );
  function _lockers ( address ) external view returns ( uint256 amount, uint256 rewardAllowed, uint256 rewardDebt, uint256 distributed, uint256 unlockAmount, uint256 depositUnlockTime, uint256 withdrawUnlockTime );
  function addReward ( uint256 _amount ) external;
  function alluoBalancerLp (  ) external view returns ( address );
  function alluoToken (  ) external view returns ( address );
  function balanceOf ( address _address ) external view returns ( uint256 amount );
  function balancer (  ) external view returns ( address );
  function changeUpgradeStatus ( bool _status ) external;
  function claim (  ) external;
  function convertAlluoToLp ( uint256 _amount ) external view returns ( uint256 );
  function convertLpToAlluo ( uint256 _amount ) external view returns ( uint256 );
  function decimals (  ) external view returns ( uint8 );
  function depositLockDuration (  ) external view returns ( uint256 );
  function distributionTime (  ) external view returns ( uint256 );
  function exchange (  ) external view returns ( address );
  function getClaim ( address _locker ) external view returns ( uint256 reward );
  function getInfoByAddress ( address _address ) external view returns ( uint256 locked_, uint256 unlockAmount_, uint256 claim_, uint256 depositUnlockTime_, uint256 withdrawUnlockTime_ );
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function initialize ( address _multiSigWallet, uint256 _rewardPerDistribution ) external;
  function lock ( uint256 _amount ) external;
  function lockWETH ( uint256 _amount ) external;
  function migrationLock ( address[] memory _users, uint256[] memory _amounts ) external;
  function name (  ) external view returns ( string memory);
  function pause (  ) external;
  function paused (  ) external view returns ( bool );
  function poolId (  ) external view returns ( bytes32 );
  function proxiableUUID (  ) external view returns ( bytes32 );
  function renounceRole ( bytes32 role, address account ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function rewardPerDistribution (  ) external view returns ( uint256 );
  function setReward ( uint256 _amount ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory);
  function totalDistributed (  ) external view returns ( uint256 );
  function totalLocked (  ) external view returns ( uint256 );
  function totalSupply (  ) external view returns ( uint256 amount );
  function unlock ( uint256 _amount ) external;
  function unlockAll (  ) external;
  function unlockedBalanceOf ( address _address ) external view returns ( uint256 amount );
  function unpause (  ) external;
  function update (  ) external;
  function updateDepositLockDuration ( uint256 _depositLockDuration ) external;
  function updateWithdrawLockDuration ( uint256 _withdrawLockDuration ) external;
  function upgradeStatus (  ) external view returns ( bool );
  function upgradeTo ( address newImplementation ) external;
  function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
  function waitingForWithdrawal (  ) external view returns ( uint256 );
  function weth (  ) external view returns ( address );
  function withdraw (  ) external;
  function withdrawLockDuration (  ) external view returns ( uint256 );
  function withdrawTokens ( address withdrawToken, address to, uint256 amount ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IGnosis {
  function addOwnerWithThreshold ( address owner, uint256 _threshold ) external;
  function approveHash ( bytes32 hashToApprove ) external;
  function approvedHashes ( address, bytes32 ) external view returns ( uint256 );
  function changeThreshold ( uint256 _threshold ) external;
  function checkNSignatures ( bytes32 dataHash, bytes memory data, bytes memory signatures, uint256 requiredSignatures ) external view;
  function checkSignatures ( bytes32 dataHash, bytes memory data, bytes memory signatures ) external view;
  function disableModule ( address prevModule, address module ) external;
  function domainSeparator (  ) external view returns ( bytes32 );
  function enableModule ( address module ) external;
  function encodeTransactionData ( address to, uint256 value, bytes memory data, uint8 operation, uint256 safeTxGas, uint256 baseGas, uint256 gasPrice, address gasToken, address refundReceiver, uint256 _nonce ) external view returns ( bytes memory);
  function execTransaction ( address to, uint256 value, bytes memory data, uint8 operation, uint256 safeTxGas, uint256 baseGas, uint256 gasPrice, address gasToken, address refundReceiver, bytes memory signatures ) external returns ( bool success );
  function execTransactionFromModule ( address to, uint256 value, bytes memory data, uint8 operation ) external returns ( bool success );
  function execTransactionFromModuleReturnData ( address to, uint256 value, bytes memory data, uint8 operation ) external returns ( bool success, bytes memory returnData );
  function getChainId (  ) external view returns ( uint256 );
  function getModulesPaginated ( address start, uint256 pageSize ) external view returns ( address[] memory array, address next );
  function getOwners (  ) external view returns ( address[] memory );
  function getStorageAt ( uint256 offset, uint256 length ) external view returns ( bytes memory );
  function getThreshold (  ) external view returns ( uint256 );
  function getTransactionHash ( address to, uint256 value, bytes memory data, uint8 operation, uint256 safeTxGas, uint256 baseGas, uint256 gasPrice, address gasToken, address refundReceiver, uint256 _nonce ) external view returns ( bytes32 );
  function isModuleEnabled ( address module ) external view returns ( bool );
  function isOwner ( address owner ) external view returns ( bool );
  function nonce (  ) external view returns ( uint256 );
  function removeOwner ( address prevOwner, address owner, uint256 _threshold ) external;
  function requiredTxGas ( address to, uint256 value, bytes memory data, uint8 operation ) external returns ( uint256 );
  function setFallbackHandler ( address handler ) external;
  function setGuard ( address guard ) external;
  function setup ( address[]memory  _owners, uint256 _threshold, address to, bytes memory data, address fallbackHandler, address paymentToken, uint256 payment, address paymentReceiver ) external;
  function signedMessages ( bytes32 ) external view returns ( uint256 );
  function simulateAndRevert ( address targetContract, bytes memory calldataPayload ) external;
  function swapOwner ( address prevOwner, address oldOwner, address newOwner ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IAlluoStrategyV2 {
    /// @notice Invest tokens transferred to this contract.
    /// @dev Amount of tokens specified in `amount` is guranteed to be
    /// transferred to strategy by vote executor.
    /// @param data whatever data you want to pass to strategy from vote extry.
    /// @param amount amount of your tokens that will be invested.
    function invest(bytes calldata data, uint256 amount)
        external;

    /// @notice Uninvest value and tranfer exchanged value to receiver.
    /// @param data whatever data you want to pass to strategy from vote extry.
    /// @param unwindPercent percentage of available assets to be released with 2 decimal points.
    /// @param outputCoin address of token that strategy MUST return.
    /// @param receiver address where tokens should go.
    /// @param swapRewards true if rewards are needed to swap to `outputCoin`, false otherwise.
    function exitAll(
        bytes calldata data,
        uint256 unwindPercent,
        address outputCoin,
        address receiver,
        bool _withdrawRewards,
        bool swapRewards
    ) external;

    function getDeployedAmountAndRewards(
        bytes calldata data
    ) external returns(uint256);

    /// @notice Claim available rewards.
    /// @param data whatever data you want to pass to strategy from vote extry.
    /// @param outputCoin address of token that strategy MUST return (if swapRewards is true).
    /// @param receiver address where tokens should go.
    /// @param swapRewards true if rewards are needed to swap to `outputCoin`, false otherwise.
    function exitOnlyRewards(
        bytes calldata data,
        address outputCoin,
        address receiver,
        bool swapRewards
    ) external;

    function getDeployedAmount(
        bytes calldata data
    ) external view returns(uint256);

    function withdrawRewards(address _token) external;


    /// @notice Execute any action on behalf of strategy.
    /// @dev Regular call is executed. If any of extcall fails, transaction should revert.
    /// @param destinations addresses to call
    /// @param calldatas calldatas to execute
    function multicall(
        address[] calldata destinations,
        bytes[] calldata calldatas
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IExchange{
    struct RouteEdge {
        uint32 swapProtocol; // 0 - unknown edge, 1 - UniswapV2, 2 - Curve...
        address pool; // address of pool to call
        address fromCoin; // address of coin to deposit to pool
        address toCoin; // address of coin to get from pool
    }

    function exchange(
        address from,
        address to,
        uint256 amountIn,
        uint256 minAmountOut
    ) external payable returns (uint256);

     function buildRoute(address from, address to)
        external
        view
        returns (RouteEdge[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IWrappedEther {
    function name() external view returns (string memory);

    function approve(address guy, uint256 wad) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function transfer(address dst, uint256 wad) external returns (bool);

    function deposit() external payable;

    function allowance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IIbAlluo is IERC20, IAccessControl{
  function annualInterest (  ) external view returns ( uint256 );
  function approveAssetValue ( address spender, uint256 amount ) external returns ( bool );
  function burn ( address account, uint256 amount ) external;
  function changeTokenStatus ( address _token, bool _status ) external;
  function changeUpgradeStatus ( bool _status ) external;
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function deposit ( address _token, uint256 _amount ) external;
  function getBalance ( address _address ) external view returns ( uint256 );
  function getBalanceForTransfer ( address _address ) external view returns ( uint256 );
  function getListSupportedTokens (  ) external view returns ( address[] memory );
  function growingRatio (  ) external view returns ( uint256 );
  function interestPerSecond (  ) external view returns ( uint256 );
  function lastInterestCompound (  ) external view returns ( uint256 );
  function liquidityBuffer (  ) external view returns ( address );
  function mint ( address account, uint256 amount ) external;
  function pause (  ) external;
  function unpause (  ) external;
  function paused (  ) external view returns ( bool );
  function setInterest ( uint256 _newAnnualInterest, uint256 _newInterestPerSecond ) external;
  function setLiquidityBuffer ( address newBuffer ) external;
  function setUpdateTimeLimit ( uint256 _newLimit ) external;
  function totalAssetSupply (  ) external view returns ( uint256 );
  function transferAssetValue ( address to, uint256 amount ) external returns ( bool );
  function transferFromAssetValue ( address from, address to, uint256 amount ) external returns ( bool );
  function updateRatio (  ) external;
  function updateTimeLimit (  ) external view returns ( uint256 );
  function upgradeStatus (  ) external view returns ( bool );
  function withdraw ( address _targetToken, uint256 _amount ) external; 
  function withdrawTo ( address _recipient, address _targetToken, uint256 _amount ) external;
  function stopFlowWhenCritical(address sender, address receiver) external;
  function forceWrap(address sender) external;
  function superToken() external view returns (address);
  function symbol (  ) external view returns ( string memory symbol );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "./IFeedStrategy.sol";
import "./../../interfaces/IChainlinkPriceFeed.sol";

contract PriceFeedRouterV2 is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable {

    using AddressUpgradeable for address;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    bool public upgradeStatus;
    mapping(string => uint256) public fiatNameToFiatId;
    mapping(uint256 => IFeedStrategy) public fiatIdToUsdStrategies;

    mapping(address => IFeedStrategy) public cryptoToUsdStrategies;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _multiSigWallet
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        fiatNameToFiatId["USD"] = 0;

        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _grantRole(UPGRADER_ROLE, _multiSigWallet);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function getPrice(address token, string calldata fiatName)
        external
        view
        returns (uint256 value, uint8 decimals)
    {
        return _getPrice(token, fiatNameToFiatId[fiatName]);
    }

    function getPrice(address token, uint256 fiatId)
        external
        view
        returns (uint256 value, uint8 decimals)
    {
        return _getPrice(token, fiatId);
    }

    function getPriceOfAmount(address token, uint256 amount, string calldata fiatName)
        external
        view
        returns (uint256 value, uint8 decimals)
    {
        return _getPriceOfAmount(token, amount, fiatNameToFiatId[fiatName]);
    }

    function getPriceOfAmount(address token, uint256 amount, uint256 fiatId)
        external
        view
        returns (uint256 value, uint8 decimals)
    {
        return _getPriceOfAmount(token, amount, fiatId);
    }

    function setCryptoStrategy(address strategy, address coin)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        cryptoToUsdStrategies[coin] = IFeedStrategy(strategy);
    }

    function setFiatStrategy(
        string calldata fiatSymbol,
        uint256 fiatId,
        address fiatFeed
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(fiatId != 0, "PriceFeed: id 0 reserved for USD");
        fiatNameToFiatId[fiatSymbol] = fiatId;
        fiatIdToUsdStrategies[fiatId] = IFeedStrategy(fiatFeed);
    }

    // 1.0 `token` costs `value` of [fiatId] (in decimals of `token`)
    function _getPrice(address token, uint256 fiatId)
        private
        view
        returns (uint256 value, uint8 decimals)
    {
        IFeedStrategy priceFeed = cryptoToUsdStrategies[token];
        require(
            address(priceFeed) != address(0),
            "PriceFeedRouter: 1no priceFeed"
        );

        (int256 usdPrice, uint8 usdDecimals) = priceFeed.getPrice();
        require(usdPrice > 0, "PriceFeedRouter: 1feed lte 0");

        if (fiatId == 0) {
            return (uint256(usdPrice), usdDecimals);
        } else {
            IFeedStrategy fiatPriceFeed = fiatIdToUsdStrategies[fiatId];
            require(
                address(fiatPriceFeed) != address(0),
                "PriceFeedRouter: 2no priceFeed"
            );

            (int256 fiatPrice, uint8 fiatDecimals) = fiatPriceFeed.getPrice();
            require(fiatPrice > 0, "PriceFeedRouter: 2feed lte 0");

            return (
                (uint256(usdPrice) * 10**fiatDecimals) / uint256(fiatPrice),
                usdDecimals
            );
        }
    }

    function _getPriceOfAmount(address token, uint256 amount, uint256 fiatId)
        private
        view
        returns (uint256 value, uint8 decimals)
    {
        IFeedStrategy priceFeed = cryptoToUsdStrategies[token];
        require(
            address(priceFeed) != address(0),
            "PriceFeedRouter: 1no priceFeed"
        );

        (int256 usdPrice, uint8 usdDecimals) = priceFeed.getPriceOfAmount(amount);
        require(usdPrice > 0, "PriceFeedRouter: 1feed lte 0");

        if (fiatId == 0) {
            return (uint256(usdPrice), usdDecimals);
        } else {
            IFeedStrategy fiatPriceFeed = fiatIdToUsdStrategies[fiatId];
            require(
                address(fiatPriceFeed) != address(0),
                "PriceFeedRouter: 2no priceFeed"
            );

            (int256 fiatPrice, uint8 fiatDecimals) = fiatPriceFeed.getPrice();
            require(fiatPrice > 0, "PriceFeedRouter: 2feed lte 0");

            return (
                (uint256(usdPrice) * 10**fiatDecimals) / uint256(fiatPrice),
                usdDecimals
            );
        }
    }

    function decimalsConverter(uint256 _amount, uint8 _decimalsIn, uint8 _decimalsOut) public pure returns(uint256){
        if(_decimalsIn > _decimalsOut){
            return _amount / 10 ** (_decimalsIn - _decimalsOut);
        }
        else if(_decimalsIn < _decimalsOut){
            return _amount * 10 ** (_decimalsOut - _decimalsIn);
        }
        else{
            return _amount;
        }
    }

    function grantRole(bytes32 role, address account)
    public
    override
    onlyRole(getRoleAdmin(role)) {
        if (role == DEFAULT_ADMIN_ROLE) {
            require(account.isContract(), "Handler: Not contract");
        }
        _grantRole(role, account);
    }

    function changeUpgradeStatus(bool _status)
    external
    onlyRole(DEFAULT_ADMIN_ROLE) {
        upgradeStatus = _status;
    }


    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(UPGRADER_ROLE)
    override {
        require(upgradeStatus, "Executor: Upgrade not allowed");
        upgradeStatus = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../../interfaces/IIbAlluo.sol";
import "../../Farming/priceFeedsV2/PriceFeedRouterV2.sol";
import "../../interfaces/IAlluoStrategyV2.sol";

contract StrategyHandler is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable {

    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    address public gnosis;
    address public booster;
    address public executor;
    address public exchangeAddress;
    address public priceFeed;

    bool public upgradeStatus;
    uint256 public lastTimeCalculated;

    mapping(string => uint256) public directionNameToId;
    mapping(uint256 => LiquidityDirection) public liquidityDirection;

    // asset id: usd = 0, eur = 1, eth = 2, btc = 3 
    mapping(uint256 => AssetInfo) private assetIdToAssetInfo;

    uint8 public numberOfAssets;

    struct LiquidityDirection {
        address strategyAddress; 
        address entryToken; 
        uint256 assetId;
        uint256 chainId;
        bytes entryData;
        bytes exitData;
        bytes rewardsData;
        uint256 latestAmount;
    }

    struct AssetInfo {
        mapping(uint256 => address) chainIdToPrimaryToken; 
        address ibAlluo;
        EnumerableSetUpgradeable.UintSet activeDirections;
        EnumerableSetUpgradeable.AddressSet needToTransferFrom;
        uint256 amountDeployed; 
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _multiSigWallet,
        address _priceFeed,
        address _executor
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        require(_multiSigWallet.isContract(), "Executor: Not contract");
        gnosis = _multiSigWallet;
        exchangeAddress = 0x29c66CF57a03d41Cfe6d9ecB6883aa0E2AbA21Ec;
        priceFeed = _priceFeed;
        executor = _executor;

        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _grantRole(UPGRADER_ROLE, _multiSigWallet);

        // For tests only
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    function calculateAll() external onlyRole(DEFAULT_ADMIN_ROLE){

        uint256 timePass = block.timestamp - lastTimeCalculated;
        for (uint256 i; i < numberOfAssets; i++) {
            uint256 newAmountDeployed;
            AssetInfo storage info = assetIdToAssetInfo[i];
            for (uint256 j; j < info.activeDirections.length(); j++) {
                LiquidityDirection memory direction = liquidityDirection[info.activeDirections.at(j)];
                uint latestAmount = IAlluoStrategyV2(direction.strategyAddress).getDeployedAmountAndRewards(direction.rewardsData);
                liquidityDirection[info.activeDirections.at(j)].latestAmount = latestAmount;
                newAmountDeployed += latestAmount;
                if(!info.needToTransferFrom.contains(direction.strategyAddress)){
                    info.needToTransferFrom.add(direction.strategyAddress);
                }
            }
            address primaryToken = info.chainIdToPrimaryToken[1];
            for (uint256 j = info.needToTransferFrom.length(); j > 0 ; j--) {
                address strategyAddress = info.needToTransferFrom.at(j-1);
                IAlluoStrategyV2(strategyAddress).withdrawRewards(primaryToken);
                info.needToTransferFrom.remove(strategyAddress);
            }
            (uint256 fiatPrice, uint8 fiatDecimals) = PriceFeedRouterV2(priceFeed).getPrice(primaryToken, i);
            uint256 totalRewardsBalance = IERC20Upgradeable(primaryToken).balanceOf(address(this));
            uint8 primaryDecimals = IERC20MetadataUpgradeable(primaryToken).decimals();
            uint256 totalRewards = PriceFeedRouterV2(priceFeed).decimalsConverter(
                fiatPrice * totalRewardsBalance, 
                fiatDecimals + primaryDecimals, 
                18
            );
            
            uint256 interest = IIbAlluo(info.ibAlluo).annualInterest();
            uint256 expectedAddition = info.amountDeployed * interest * timePass / 31536000  / 10000;
            uint256 expectedFullAmount = info.amountDeployed + expectedAddition;
            uint256 actualAmount = newAmountDeployed + totalRewards;


            if(actualAmount > expectedFullAmount){
            uint256 surplus = actualAmount - expectedFullAmount;

                if(surplus < totalRewards){
                    
                    IERC20Upgradeable(primaryToken).transfer(booster, totalRewardsBalance * surplus  / totalRewards);

                    uint rewardsLeft = IERC20Upgradeable(primaryToken).balanceOf(address(this)); 
                    IERC20Upgradeable(primaryToken).transfer(executor, rewardsLeft);

                    rewardsLeft = PriceFeedRouterV2(priceFeed).decimalsConverter(
                        rewardsLeft, 
                        primaryDecimals, 
                        18
                    );  
                    info.amountDeployed = newAmountDeployed + rewardsLeft;

                }
                else{

                    info.amountDeployed = actualAmount - totalRewards;
                    IERC20Upgradeable(primaryToken).transfer(booster, totalRewardsBalance);

                    //in the future here we will also exit some existing strategy to send to booster
                }

            }
            else{
                IERC20Upgradeable(primaryToken).transfer(executor, totalRewardsBalance);
                info.amountDeployed = actualAmount;

            }
        }
        lastTimeCalculated = block.timestamp;
    }

    function calculateOnlyLp() external onlyRole(DEFAULT_ADMIN_ROLE){

        for (uint256 i; i < numberOfAssets; i++) {
            uint256 newAmountDeployed;
            AssetInfo storage info = assetIdToAssetInfo[i];
            for (uint256 j; j < info.activeDirections.length(); j++) {
                LiquidityDirection memory direction = liquidityDirection[info.activeDirections.at(j)];
                newAmountDeployed += IAlluoStrategyV2(direction.strategyAddress).getDeployedAmount(direction.rewardsData);
            }
            info.amountDeployed = newAmountDeployed;
        }
        lastTimeCalculated = block.timestamp;
    }


    function getCurrentDeployed() external view returns(uint[] memory amounts){
        amounts = new uint[](numberOfAssets);

        for (uint256 i; i < numberOfAssets; i++) {
            uint256 newAmountDeployed;
            AssetInfo storage info = assetIdToAssetInfo[i];
            for (uint256 j; j < info.activeDirections.length(); j++) {
                LiquidityDirection memory direction = liquidityDirection[info.activeDirections.at(j)];
                uint latestAmount = IAlluoStrategyV2(direction.strategyAddress).getDeployedAmount(direction.rewardsData);
                newAmountDeployed += latestAmount;
            }
            address primaryToken = info.chainIdToPrimaryToken[1];
 
            (uint256 fiatPrice, uint8 fiatDecimals) = PriceFeedRouterV2(priceFeed).getPrice(primaryToken, i);
            uint256 totalRewardsBalance = IERC20Upgradeable(primaryToken).balanceOf(address(this));
            uint8 primaryDecimals = IERC20MetadataUpgradeable(primaryToken).decimals();
            uint256 totalRewards = PriceFeedRouterV2(priceFeed).decimalsConverter(
                fiatPrice * totalRewardsBalance, 
                fiatDecimals + primaryDecimals, 
                18
            );
            
            amounts[i] = newAmountDeployed + totalRewards;
        }
    }

    function getLatestDeployed()external view returns(uint[] memory amounts){
        amounts = new uint[](numberOfAssets);
        for (uint256 i; i < numberOfAssets; i++) {
            amounts[i] = assetIdToAssetInfo[i].amountDeployed;
        }
    }

    function adjustTreasury(int256 _delta) public onlyRole(DEFAULT_ADMIN_ROLE) {
        assetIdToAssetInfo[0].amountDeployed = uint(int(assetIdToAssetInfo[0].amountDeployed) + _delta);
        if(_delta > 0){
            address primaryToken = assetIdToAssetInfo[0].chainIdToPrimaryToken[1];
            (uint256 fiatPrice, uint8 fiatDecimals) = PriceFeedRouterV2(priceFeed).getPrice(primaryToken, 0);
            uint exactAmount = (uint(_delta) * 10**fiatDecimals) / fiatPrice;
            uint256 tokenAmount = exactAmount / 10**(18 - IERC20MetadataUpgradeable(primaryToken).decimals());
            IERC20MetadataUpgradeable(primaryToken).safeTransferFrom(gnosis, executor, tokenAmount);
        }
    }

    function getDirectionIdByName(string memory _codeName) external view returns(uint256){
        return directionNameToId[_codeName];
    }

    function getDirectionLatestAmount(uint256 _id) external view returns(uint){
        return liquidityDirection[_id].latestAmount;
    }

    function getLiquidityDirectionByName(string memory _codeName) external view returns(uint256, address, LiquidityDirection memory){
        uint256 directionId = directionNameToId[_codeName];
        LiquidityDirection memory direction = liquidityDirection[directionId];
        address primaryToken = assetIdToAssetInfo[direction.assetId].chainIdToPrimaryToken[direction.chainId];
        return (directionId, primaryToken, direction);
    }

    function getAssetIdByDirectionId(uint256 _id)external view returns(uint){
        return liquidityDirection[_id].assetId;
    }

    function getDirectionFullInfoById(uint256 _id) external view returns(address, LiquidityDirection memory){
        LiquidityDirection memory direction = liquidityDirection[_id];
        address primaryToken = assetIdToAssetInfo[direction.assetId].chainIdToPrimaryToken[direction.chainId];
        return (primaryToken, direction);
    }

    function getLiquidityDirectionById(uint256 _id) external view returns(LiquidityDirection memory){
        return (liquidityDirection[_id]);
    }

    function getPrimaryTokenByAssetId(uint256 _id, uint256 _chainId) external view returns(address){
        return (assetIdToAssetInfo[_id].chainIdToPrimaryToken[_chainId]);
    }


    function setAssetAmount(uint _id,uint amount) public onlyRole(DEFAULT_ADMIN_ROLE){
        assetIdToAssetInfo[_id].amountDeployed = amount;
    }

    function getAssetAmount(uint _id) view public returns(uint){
        return (assetIdToAssetInfo[_id].amountDeployed);
    }

    function addToActiveDirections(uint256 _directionId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if(!assetIdToAssetInfo[liquidityDirection[_directionId].assetId].activeDirections.contains(_directionId)){
            assetIdToAssetInfo[liquidityDirection[_directionId].assetId].activeDirections.add(_directionId);
        }
    }

    function removeFromActiveDirections(uint256 _directionId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        assetIdToAssetInfo[liquidityDirection[_directionId].assetId].activeDirections.remove(_directionId);
        liquidityDirection[_directionId].latestAmount = 0;
    }   

    function setGnosis(address _gnosisAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        gnosis = _gnosisAddress;
    }

    function updateLastTime() public onlyRole(DEFAULT_ADMIN_ROLE) {
        lastTimeCalculated = block.timestamp;
    }

    function setExchangeAddress(address _newExchange) public onlyRole(DEFAULT_ADMIN_ROLE) {
        exchangeAddress = _newExchange;
    }

    function setBoosterAddress(address _newBooster) public onlyRole(DEFAULT_ADMIN_ROLE) {
        booster = _newBooster;
    }

    function setExecutorAddress(address _newExecutor) public onlyRole(DEFAULT_ADMIN_ROLE) {
        executor = _newExecutor;
        _grantRole(DEFAULT_ADMIN_ROLE, _newExecutor);
    }

    function setLiquidityDirection(
        string memory _codeName,
        uint256 _directionId,
        address _strategyAddress, 
        address _entryToken, 
        uint256 _assetId, 
        uint256 _chainId, 
        bytes memory _entryData, 
        bytes memory _exitData,
        bytes memory _rewardsData
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        directionNameToId[_codeName] = _directionId;
        liquidityDirection[_directionId] = LiquidityDirection(
            _strategyAddress, 
            _entryToken, 
            _assetId, 
            _chainId, 
            _entryData, 
            _exitData, 
            _rewardsData,
            0
        );
    }

    function changeNumberOfAssets(uint8 _newNumber) public onlyRole(DEFAULT_ADMIN_ROLE) {
        numberOfAssets = _newNumber;
    }

    function changeAssetInfo(
        uint256 _assetId,
        uint256[] calldata  _chainIds, 
        address[] calldata _chainIdToPrimaryToken,
        address _ibAlluo
    )external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_chainIds.length == _chainIdToPrimaryToken.length);
        assetIdToAssetInfo[_assetId].ibAlluo = _ibAlluo;
        for (uint256 i; i < _chainIds.length; i++) {
            assetIdToAssetInfo[_assetId].chainIdToPrimaryToken[_chainIds[i]] = _chainIdToPrimaryToken[i];
        }
    }

    function grantRole(bytes32 role, address account)
    public
    override
    onlyRole(getRoleAdmin(role)) {
        // if (role == DEFAULT_ADMIN_ROLE) {
        //     require(account.isContract(), "Handler: Not contract");
        // }
        _grantRole(role, account);
    }

    function changeUpgradeStatus(bool _status)
    external
    onlyRole(DEFAULT_ADMIN_ROLE) {
        upgradeStatus = _status;
    }


    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(UPGRADER_ROLE)
    override {
        require(upgradeStatus, "Executor: Upgrade not allowed");
        upgradeStatus = false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFeedStrategy {
    function getPrice() external view returns (int256 value, uint8 decimals);
    function getPriceOfAmount(uint256 amount) external view returns (int256 value, uint8 decimals);
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.4. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface IChainlinkPriceFeed {
    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );
    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );
    event OwnershipTransferRequested(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);

    function acceptOwnership() external;

    function accessController() external view returns (address);

    function aggregator() external view returns (address);

    function confirmAggregator(address _aggregator) external;

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function getAnswer(uint256 _roundId) external view returns (int256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function getTimestamp(uint256 _roundId) external view returns (uint256);

    function latestAnswer() external view returns (int256);

    function latestRound() external view returns (uint256);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestTimestamp() external view returns (uint256);

    function owner() external view returns (address);

    function phaseAggregators(uint16) external view returns (address);

    function phaseId() external view returns (uint16);

    function proposeAggregator(address _aggregator) external;

    function proposedAggregator() external view returns (address);

    function proposedGetRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function proposedLatestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function setController(address _accessController) external;

    function transferOwnership(address _to) external;

    function version() external view returns (uint256);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"address","name":"_aggregator","type":"address"},{"internalType":"address","name":"_accessController","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"int256","name":"current","type":"int256"},{"indexed":true,"internalType":"uint256","name":"roundId","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"updatedAt","type":"uint256"}],"name":"AnswerUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"roundId","type":"uint256"},{"indexed":true,"internalType":"address","name":"startedBy","type":"address"},{"indexed":false,"internalType":"uint256","name":"startedAt","type":"uint256"}],"name":"NewRound","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"OwnershipTransferRequested","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"inputs":[],"name":"acceptOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"accessController","outputs":[{"internalType":"contract AccessControllerInterface","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"aggregator","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_aggregator","type":"address"}],"name":"confirmAggregator","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"description","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_roundId","type":"uint256"}],"name":"getAnswer","outputs":[{"internalType":"int256","name":"","type":"int256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint80","name":"_roundId","type":"uint80"}],"name":"getRoundData","outputs":[{"internalType":"uint80","name":"roundId","type":"uint80"},{"internalType":"int256","name":"answer","type":"int256"},{"internalType":"uint256","name":"startedAt","type":"uint256"},{"internalType":"uint256","name":"updatedAt","type":"uint256"},{"internalType":"uint80","name":"answeredInRound","type":"uint80"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_roundId","type":"uint256"}],"name":"getTimestamp","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"latestAnswer","outputs":[{"internalType":"int256","name":"","type":"int256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"latestRound","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"latestRoundData","outputs":[{"internalType":"uint80","name":"roundId","type":"uint80"},{"internalType":"int256","name":"answer","type":"int256"},{"internalType":"uint256","name":"startedAt","type":"uint256"},{"internalType":"uint256","name":"updatedAt","type":"uint256"},{"internalType":"uint80","name":"answeredInRound","type":"uint80"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"latestTimestamp","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint16","name":"","type":"uint16"}],"name":"phaseAggregators","outputs":[{"internalType":"contract AggregatorV2V3Interface","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"phaseId","outputs":[{"internalType":"uint16","name":"","type":"uint16"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_aggregator","type":"address"}],"name":"proposeAggregator","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"proposedAggregator","outputs":[{"internalType":"contract AggregatorV2V3Interface","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint80","name":"_roundId","type":"uint80"}],"name":"proposedGetRoundData","outputs":[{"internalType":"uint80","name":"roundId","type":"uint80"},{"internalType":"int256","name":"answer","type":"int256"},{"internalType":"uint256","name":"startedAt","type":"uint256"},{"internalType":"uint256","name":"updatedAt","type":"uint256"},{"internalType":"uint80","name":"answeredInRound","type":"uint80"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"proposedLatestRoundData","outputs":[{"internalType":"uint80","name":"roundId","type":"uint80"},{"internalType":"int256","name":"answer","type":"int256"},{"internalType":"uint256","name":"startedAt","type":"uint256"},{"internalType":"uint256","name":"updatedAt","type":"uint256"},{"internalType":"uint80","name":"answeredInRound","type":"uint80"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_accessController","type":"address"}],"name":"setController","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_to","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"version","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]
*/