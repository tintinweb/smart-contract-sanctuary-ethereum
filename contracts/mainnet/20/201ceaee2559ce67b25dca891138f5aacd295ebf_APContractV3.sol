// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IPriceModule.sol";
import "../interfaces/IHexUtils.sol";

contract APContractV3 is Initializable {
    address public yieldsterDAO;

    address public yieldsterTreasury;

    address public yieldsterGOD;

    address public emergencyVault;

    address public yieldsterExchange;

    address public stringUtils;

    address public whitelistModule;

    address public proxyFactory;

    address public priceModule;

    address public safeMinter;

    address public safeUtils;

    address public exchangeRegistry;

    address public stockDeposit;

    address public stockWithdraw;

    address public platFormManagementFee; //Platform fee

    address public profitManagementFee; //Management fee

    address public wEth;

    address public sdkContract;

    address public mStorage; //Platform fee storage

    struct Vault {
        mapping(address => bool) vaultAssets;
        mapping(address => bool) vaultDepositAssets;
        mapping(address => bool) vaultWithdrawalAssets;
        address depositStrategy;
        address withdrawStrategy;
        uint256[] whitelistGroup;
        address vaultAdmin;
        bool created;
        uint256 slippage;
    }

    mapping(address => bool) assets;

    mapping(address => Vault) vaults;

    mapping(address => bool) vaultCreated;

    mapping(address => bool) APSManagers;

    mapping(address => uint256) vaultsOwnedByAdmin;

    struct SmartStrategy {
        address minter;
        address executor;
        bool created;
    }

    mapping(address => SmartStrategy) smartStrategies;

    mapping(address => address) minterStrategyMap;

    struct vaultActiveManagemetFee {
        mapping(address => bool) isActiveManagementFee;
        mapping(address => uint256) activeManagementFeeIndex;
        address[] activeManagementFeeList;
    }

    mapping(address => vaultActiveManagemetFee) managementFeeStrategies;

    mapping(address => bool) permittedWalletAddresses;

    address public performanceManagementFee; //Performance fee

    address public navCalculator;

    /// @dev Function to initialize addresses.
    /// @param _yieldsterDAO Address of yieldsterDAO.
    /// @param _yieldsterTreasury Address of yieldsterTreasury.
    /// @param _yieldsterGOD Address of yieldsterGOD.
    /// @param _emergencyVault Address of emergencyVault.
    /// @param _apsAdmin Address of apsAdmin.
    function initialize(
        address _yieldsterDAO,
        address _yieldsterTreasury,
        address _yieldsterGOD,
        address _emergencyVault,
        address _apsAdmin
    ) public initializer {
        yieldsterDAO = _yieldsterDAO;
        yieldsterTreasury = _yieldsterTreasury;
        yieldsterGOD = _yieldsterGOD;
        emergencyVault = _emergencyVault;
        APSManagers[_apsAdmin] = true;
    }

    /// @dev Function to set initial values.
    /// @param _whitelistModule Address of whitelistModule.
    /// @param _platformManagementFee Address of platformManagementFee.
    /// @param _profitManagementFee Address of profitManagementFee.
    /// @param _stringUtils Address of stringUtils.
    /// @param _yieldsterExchange Address of yieldsterExchange.
    /// @param _exchangeRegistry Address of exchangeRegistry.
    /// @param _priceModule Address of priceModule.
    /// @param _safeUtils Address of safeUtils.
    function setInitialValues(
        address _whitelistModule,
        address _platformManagementFee,
        address _profitManagementFee,
        address _stringUtils,
        address _yieldsterExchange,
        address _exchangeRegistry,
        address _priceModule,
        address _safeUtils,
        address _mStorage
    ) public onlyYieldsterDAO {
        whitelistModule = _whitelistModule;
        platFormManagementFee = _platformManagementFee;
        stringUtils = _stringUtils;
        yieldsterExchange = _yieldsterExchange;
        exchangeRegistry = _exchangeRegistry;
        priceModule = _priceModule;
        safeUtils = _safeUtils;
        profitManagementFee = _profitManagementFee;
        mStorage = _mStorage;
    }

    /// @dev Function to add proxy Factory address to Yieldster.
    /// @param _proxyFactory Address of proxy factory.
    function addProxyFactory(address _proxyFactory) public onlyManager {
        proxyFactory = _proxyFactory;
    }

    /// @dev Function to add vault Admin to Yieldster.
    /// @param _manager Address of the manager.
    function addManager(address _manager) public onlyYieldsterDAO {
        APSManagers[_manager] = true;
    }

    /// @dev Function to remove vault Admin from Yieldster.
    /// @param _manager Address of the manager.
    function removeManager(address _manager) public onlyYieldsterDAO {
        APSManagers[_manager] = false;
    }

    /// @dev Function to set Yieldster GOD.
    /// @param _yieldsterGOD Address of the Yieldster GOD.
    function setYieldsterGOD(address _yieldsterGOD) public {
        require(
            msg.sender == yieldsterGOD,
            "Only Yieldster GOD can perform this operation"
        );
        yieldsterGOD = _yieldsterGOD;
    }

    /// @dev Function to set Yieldster DAO.
    /// @param _yieldsterDAO Address of the Yieldster DAO.
    function setYieldsterDAO(address _yieldsterDAO) public {
        require(
            msg.sender == yieldsterDAO,
            "Only Yieldster DAO can perform this operation"
        );
        yieldsterDAO = _yieldsterDAO;
    }

    /// @dev Function to set Yieldster Treasury.
    /// @param _yieldsterTreasury Address of the Yieldster Treasury.
    function setYieldsterTreasury(address _yieldsterTreasury) public {
        require(
            msg.sender == yieldsterDAO,
            "Only Yieldster DAO can perform this operation"
        );
        yieldsterTreasury = _yieldsterTreasury;
    }

    /// @dev Function to disable Yieldster GOD.
    function disableYieldsterGOD() public {
        require(
            msg.sender == yieldsterGOD,
            "Only Yieldster GOD can perform this operation"
        );
        yieldsterGOD = address(0);
    }

    /// @dev Function to set Emergency vault.
    /// @param _emergencyVault Address of the Yieldster Emergency vault.
    function setEmergencyVault(address _emergencyVault)
        public
        onlyYieldsterDAO
    {
        emergencyVault = _emergencyVault;
    }

    /// @dev Function to set Safe Minter.
    /// @param _safeMinter Address of the Safe Minter.
    function setSafeMinter(address _safeMinter) public onlyYieldsterDAO {
        safeMinter = _safeMinter;
    }

    /// @dev Function to set safeUtils contract.
    /// @param _safeUtils Address of the safeUtils contract.
    function setSafeUtils(address _safeUtils) public onlyYieldsterDAO {
        safeUtils = _safeUtils;
    }

    /// @dev Function to set stringUtils contract.
    /// @param _stringUtils Address of the stringUtils contract.
    function setStringUtils(address _stringUtils) public onlyYieldsterDAO {
        stringUtils = _stringUtils;
    }

    /// @dev Function to set whitelistModule contract.
    /// @param _whitelistModule Address of the whitelistModule contract.
    function setWhitelistModule(address _whitelistModule)
        public
        onlyYieldsterDAO
    {
        whitelistModule = _whitelistModule;
    }

    /// @dev Function to set exchangeRegistry address.
    /// @param _exchangeRegistry Address of the exchangeRegistry.
    function setExchangeRegistry(address _exchangeRegistry)
        public
        onlyYieldsterDAO
    {
        exchangeRegistry = _exchangeRegistry;
    }

    /// @dev Function to set Yieldster Exchange.
    /// @param _yieldsterExchange Address of the Yieldster exchange.
    function setYieldsterExchange(address _yieldsterExchange)
        public
        onlyYieldsterDAO
    {
        yieldsterExchange = _yieldsterExchange;
    }

    /// @dev Function to change the vault Admin for a vault.
    /// @param _vaultAdmin Address of the new APS Manager.
    function changeVaultAdmin(address _vaultAdmin) external {
        require(vaults[msg.sender].created, "Vault is not present");
        vaultsOwnedByAdmin[vaults[msg.sender].vaultAdmin] =
            vaultsOwnedByAdmin[vaults[msg.sender].vaultAdmin] -
            1;
        vaultsOwnedByAdmin[_vaultAdmin] = vaultsOwnedByAdmin[_vaultAdmin] + 1;
        vaults[msg.sender].vaultAdmin = _vaultAdmin;
    }

    /// @dev Function to change the Slippage Settings for a vault.
    /// @param _slippage value of slippage.
    function setVaultSlippage(uint256 _slippage) external {
        require(vaults[msg.sender].created, "Vault is not present");
        vaults[msg.sender].slippage = _slippage;
    }

    /// @dev Function to get the Slippage Settings for a vault.
    function getVaultSlippage() external view returns (uint256) {
        require(vaults[msg.sender].created, "Vault is not present");
        return vaults[msg.sender].slippage;
    }

    //Price Module
    /// @dev Function to set Yieldster price module.
    /// @param _priceModule Address of the price module.
    function setPriceModule(address _priceModule) public onlyManager {
        priceModule = _priceModule;
    }

    /// @dev Function to get the USD price for a token.
    /// @param _tokenAddress Address of the token.
    function getUSDPrice(address _tokenAddress) public view returns (uint256) {
        return IPriceModule(priceModule).getUSDPrice(_tokenAddress);
    }

    /// @dev Function to set Management Fee Strategies.
    /// @param _platformManagement Address of the Platform Management Fee Strategy
    /// @param _profitManagement Address of the Profit Management Fee Strategy
    /// @param _performanceManagement Address of the performance Management Fee Strategy
    function setProfitAndPlatformAndPerformanceManagementFeeStrategies(
        address _platformManagement, //platformManagement
        address _profitManagement, //management
        address _performanceManagement //Performance
    ) public onlyYieldsterDAO {
        if (_profitManagement != address(0))
            profitManagementFee = _profitManagement;
        if (_platformManagement != address(0))
            platFormManagementFee = _platformManagement;
        if (_performanceManagement != address(0))
            performanceManagementFee = _performanceManagement;
    }

    /// @dev Function to get the list of management fee strategies applied to the vault.
    function getVaultManagementFee() public view returns (address[] memory) {
        require(vaults[msg.sender].created, "Vault not present");
        return managementFeeStrategies[msg.sender].activeManagementFeeList;
    }

    /// @dev Function to add the management fee strategies applied to a vault.
    /// @param _vaultAddress Address of the vault.
    /// @param _managementFeeAddress Address of the management fee strategy.
    function addManagementFeeStrategies(
        address _vaultAddress,
        address _managementFeeAddress
    ) public {
        require(vaults[_vaultAddress].created, "Vault not present");
        require(
            vaults[_vaultAddress].vaultAdmin == msg.sender,
            "Sender not Authorized"
        );
        managementFeeStrategies[_vaultAddress].isActiveManagementFee[
            _managementFeeAddress
        ] = true;
        managementFeeStrategies[_vaultAddress].activeManagementFeeIndex[
                _managementFeeAddress
            ] = managementFeeStrategies[_vaultAddress]
            .activeManagementFeeList
            .length;
        managementFeeStrategies[_vaultAddress].activeManagementFeeList.push(
            _managementFeeAddress
        );
    }

    /// @dev Function to deactivate a vault strategy.
    /// @param _vaultAddress Address of the Vault.
    /// @param _managementFeeAddress Address of the Management Fee Strategy.
    function removeManagementFeeStrategies(
        address _vaultAddress,
        address _managementFeeAddress
    ) public {
        require(vaults[_vaultAddress].created, "Vault not present");
        require(
            managementFeeStrategies[_vaultAddress].isActiveManagementFee[
                _managementFeeAddress
            ],
            "Provided ManagementFee is not active"
        );
        require(
            vaults[_vaultAddress].vaultAdmin == msg.sender ||
                yieldsterDAO == msg.sender,
            "Sender not Authorized"
        );
        require(
            platFormManagementFee != _managementFeeAddress ||
                yieldsterDAO == msg.sender,
            "Platfrom Management only changable by dao!"
        );
        managementFeeStrategies[_vaultAddress].isActiveManagementFee[
            _managementFeeAddress
        ] = false;

        if (
            managementFeeStrategies[_vaultAddress]
                .activeManagementFeeList
                .length == 1
        ) {
            managementFeeStrategies[_vaultAddress].activeManagementFeeList.pop();
        } else {
            uint256 index = managementFeeStrategies[_vaultAddress]
                .activeManagementFeeIndex[_managementFeeAddress];
            uint256 lastIndex = managementFeeStrategies[_vaultAddress]
                .activeManagementFeeList
                .length - 1;
            delete managementFeeStrategies[_vaultAddress]
                .activeManagementFeeList[index];
            managementFeeStrategies[_vaultAddress].activeManagementFeeIndex[
                    managementFeeStrategies[_vaultAddress]
                        .activeManagementFeeList[lastIndex]
                ] = index;
            managementFeeStrategies[_vaultAddress].activeManagementFeeList[
                    index
                ] = managementFeeStrategies[_vaultAddress]
                .activeManagementFeeList[lastIndex];
            managementFeeStrategies[_vaultAddress].activeManagementFeeList.pop();
        }
    }

    /// @dev Function to create a vault.
    /// @param _vaultAddress Address of the new vault.
    function setVaultStatus(address _vaultAddress) public {
        require(
            msg.sender == proxyFactory,
            "Only Proxy Factory can perform this operation"
        );
        vaultCreated[_vaultAddress] = true;
    }

    /// @dev Function to add a vault in the APS.
    /// @param _vaultAdmin Address of the vaults APS Manager.
    /// @param _whitelistGroup List of whitelist groups applied to the vault.
    function addVault(address _vaultAdmin, uint256[] memory _whitelistGroup)
        public
    {
        require(vaultCreated[msg.sender], "Vault not created");
        Vault storage newVault = vaults[msg.sender];
        newVault.vaultAdmin = _vaultAdmin;
        newVault.depositStrategy = stockDeposit;
        newVault.withdrawStrategy = stockWithdraw;
        newVault.whitelistGroup = _whitelistGroup;
        newVault.created = true;
        newVault.slippage = 50;
        vaultsOwnedByAdmin[_vaultAdmin] = vaultsOwnedByAdmin[_vaultAdmin] + 1;

        // applying Platform management fee
        managementFeeStrategies[msg.sender].isActiveManagementFee[
            platFormManagementFee
        ] = true;
        managementFeeStrategies[msg.sender].activeManagementFeeIndex[
                platFormManagementFee
            ] = managementFeeStrategies[msg.sender]
            .activeManagementFeeList
            .length;
        managementFeeStrategies[msg.sender].activeManagementFeeList.push(
            platFormManagementFee
        );

        //applying Profit management fee
        managementFeeStrategies[msg.sender].isActiveManagementFee[
            profitManagementFee
        ] = true;
        managementFeeStrategies[msg.sender].activeManagementFeeIndex[
                profitManagementFee
            ] = managementFeeStrategies[msg.sender]
            .activeManagementFeeList
            .length;
        managementFeeStrategies[msg.sender].activeManagementFeeList.push(
            profitManagementFee
        );

        //applying performance management fee
        managementFeeStrategies[msg.sender].isActiveManagementFee[
            performanceManagementFee
        ] = true;
        managementFeeStrategies[msg.sender].activeManagementFeeIndex[
                performanceManagementFee
            ] = managementFeeStrategies[msg.sender]
            .activeManagementFeeList
            .length;
        managementFeeStrategies[msg.sender].activeManagementFeeList.push(
            performanceManagementFee
        );
    }

    /// @dev Function to Manage the vault assets.
    /// @param _enabledDepositAsset List of deposit assets to be enabled in the vault.
    /// @param _enabledWithdrawalAsset List of withdrawal assets to be enabled in the vault.
    /// @param _disabledDepositAsset List of deposit assets to be disabled in the vault.
    /// @param _disabledWithdrawalAsset List of withdrawal assets to be disabled in the vault.
    function setVaultAssets(
        address[] memory _enabledDepositAsset,
        address[] memory _enabledWithdrawalAsset,
        address[] memory _disabledDepositAsset,
        address[] memory _disabledWithdrawalAsset
    ) public {
        require(vaults[msg.sender].created, "Vault not present");

        for (uint256 i = 0; i < _enabledDepositAsset.length; i++) {
            address asset = _enabledDepositAsset[i];
            require(_isAssetPresent(asset), "Asset not supported by Yieldster");
            vaults[msg.sender].vaultAssets[asset] = true;
            vaults[msg.sender].vaultDepositAssets[asset] = true;
        }

        for (uint256 i = 0; i < _enabledWithdrawalAsset.length; i++) {
            address asset = _enabledWithdrawalAsset[i];
            require(_isAssetPresent(asset), "Asset not supported by Yieldster");
            vaults[msg.sender].vaultAssets[asset] = true;
            vaults[msg.sender].vaultWithdrawalAssets[asset] = true;
        }

        for (uint256 i = 0; i < _disabledDepositAsset.length; i++) {
            address asset = _disabledDepositAsset[i];
            require(_isAssetPresent(asset), "Asset not supported by Yieldster");
            vaults[msg.sender].vaultAssets[asset] = false;
            vaults[msg.sender].vaultDepositAssets[asset] = false;
        }

        for (uint256 i = 0; i < _disabledWithdrawalAsset.length; i++) {
            address asset = _disabledWithdrawalAsset[i];
            require(_isAssetPresent(asset), "Asset not supported by Yieldster");
            vaults[msg.sender].vaultAssets[asset] = false;
            vaults[msg.sender].vaultWithdrawalAssets[asset] = false;
        }
    }

    /// @dev Function to check if the asset is supported by the vault.
    /// @param cleanUpAsset Address of the asset.
    function _isVaultAsset(address cleanUpAsset) public view returns (bool) {
        require(vaults[msg.sender].created, "Vault is not present");
        return vaults[msg.sender].vaultAssets[cleanUpAsset];
    }

    /// @dev Function to check if an asset is supported by Yieldster.
    /// @param _address Address of the asset.
    function _isAssetPresent(address _address) private view returns (bool) {
        return assets[_address];
    }

    /// @dev Function to add an asset to the Yieldster.
    /// @param _tokenAddress Address of the asset.
    function addAsset(address _tokenAddress) public onlyManager {
        require(!_isAssetPresent(_tokenAddress), "Asset already present!");
        assets[_tokenAddress] = true;
    }

    /// @dev Function to remove an asset from the Yieldster.
    /// @param _tokenAddress Address of the asset.
    function removeAsset(address _tokenAddress) public onlyManager {
        require(_isAssetPresent(_tokenAddress), "Asset not present!");
        delete assets[_tokenAddress];
    }

    /// @dev Function to check if an asset is supported deposit asset in the vault.
    /// @param _assetAddress Address of the asset.
    function isDepositAsset(address _assetAddress) public view returns (bool) {
        require(vaults[msg.sender].created, "Vault not present");
        return vaults[msg.sender].vaultDepositAssets[_assetAddress];
    }

    /// @dev Function to check if an asset is supported withdrawal asset in the vault.
    /// @param _assetAddress Address of the asset.
    function isWithdrawalAsset(address _assetAddress)
        public
        view
        returns (bool)
    {
        require(vaults[msg.sender].created, "Vault not present");
        return vaults[msg.sender].vaultWithdrawalAssets[_assetAddress];
    }

    /// @dev Function to set stock Deposit and Withdraw.
    /// @param _stockDeposit Address of the stock deposit contract.
    /// @param _stockWithdraw Address of the stock withdraw contract.
    function setStockDepositWithdraw(
        address _stockDeposit,
        address _stockWithdraw
    ) public onlyYieldsterDAO {
        stockDeposit = _stockDeposit;
        stockWithdraw = _stockWithdraw;
    }

    /// @dev Function to set smart strategy applied to the vault.
    /// @param _smartStrategyAddress Address of the smart strategy.
    /// @param _type type of smart strategy(deposit or withdraw).
    function setVaultSmartStrategy(address _smartStrategyAddress, uint256 _type)
        external
    {
        require(vaults[msg.sender].created, "Vault not present");
        require(
            _isSmartStrategyPresent(_smartStrategyAddress),
            "Smart Strategy not Supported by Yieldster"
        );
        if (_type == 1) {
            vaults[msg.sender].depositStrategy = _smartStrategyAddress;
        } else if (_type == 2) {
            vaults[msg.sender].withdrawStrategy = _smartStrategyAddress;
        } else {
            revert("Invalid type provided");
        }
    }

    /// @dev Function to check if a smart strategy is supported by Yieldster.
    /// @param _address Address of the smart strategy.
    function _isSmartStrategyPresent(address _address)
        private
        view
        returns (bool)
    {
        return smartStrategies[_address].created;
    }

    /// @dev Function to add a smart strategy to Yieldster.
    /// @param _smartStrategyAddress Address of the smart strategy.
    /// @param _minter Address of the strategy minter.
    /// @param _executor Address of the strategy executor.
    function addSmartStrategy(
        address _smartStrategyAddress,
        address _minter,
        address _executor
    ) public onlyManager {
        require(
            !_isSmartStrategyPresent(_smartStrategyAddress),
            "Smart Strategy already present!"
        );
        // SmartStrategy memory newSmartStrategy = SmartStrategy({
        //     minter: _minter,
        //     executor: _executor,
        //     created: true
        // });
        SmartStrategy storage newSmartStrategy = smartStrategies[
            _smartStrategyAddress
        ];
        newSmartStrategy.minter = _minter;
        newSmartStrategy.executor = _executor;
        newSmartStrategy.created = true;

        minterStrategyMap[_minter] = _smartStrategyAddress;
    }

    /// @dev Function to remove a smart strategy from Yieldster.
    /// @param _smartStrategyAddress Address of the smart strategy.
    function removeSmartStrategy(address _smartStrategyAddress)
        public
        onlyManager
    {
        require(
            !_isSmartStrategyPresent(_smartStrategyAddress),
            "Smart Strategy not present"
        );
        delete smartStrategies[_smartStrategyAddress];
    }

    /// @dev Function to get ssmart strategy executor address.
    /// @param _smartStrategy Address of the strategy.
    function smartStrategyExecutor(address _smartStrategy)
        external
        view
        returns (address)
    {
        return smartStrategies[_smartStrategy].executor;
    }

    /// @dev Function to change executor of smart strategy.
    /// @param _smartStrategy Address of the smart strategy.
    /// @param _executor Address of the executor.
    function changeSmartStrategyExecutor(
        address _smartStrategy,
        address _executor
    ) public onlyManager {
        require(
            _isSmartStrategyPresent(_smartStrategy),
            "Smart Strategy not present!"
        );
        smartStrategies[_smartStrategy].executor = _executor;
    }

    /// @dev Function to get the deposit strategy applied to the vault.
    function getDepositStrategy() public view returns (address) {
        require(vaults[msg.sender].created, "Vault not present");
        return vaults[msg.sender].depositStrategy;
    }

    /// @dev Function to get the withdrawal strategy applied to the vault.
    function getWithdrawStrategy() public view returns (address) {
        require(vaults[msg.sender].created, "Vault not present");
        return vaults[msg.sender].withdrawStrategy;
    }

    /// @dev Function to get strategy address from minter.
    /// @param _minter Address of the minter.
    function getStrategyFromMinter(address _minter)
        external
        view
        returns (address)
    {
        return minterStrategyMap[_minter];
    }

    modifier onlyYieldsterDAO() {
        require(
            yieldsterDAO == msg.sender,
            "Only Yieldster DAO is allowed to perform this operation"
        );
        _;
    }

    modifier onlyManager() {
        require(
            APSManagers[msg.sender],
            "Only APS managers allowed to perform this operation!"
        );
        _;
    }

    /// @dev Function to check if an address is an Yieldster Vault.
    /// @param _address Address to check.
    function isVault(address _address) public view returns (bool) {
        return vaults[_address].created;
    }

    /// @dev Function to get wEth Address.
    function getWETH() external view returns (address) {
        return wEth;
    }

    /// @dev Function to set wEth Address.
    /// @param _wEth Address of wEth.
    function setWETH(address _wEth) external onlyYieldsterDAO {
        wEth = _wEth;
    }

    /// @dev function to calculate the slippage value accounted min return for an exchange operation.
    /// @param fromToken Address of From token
    /// @param toToken Address of To token
    /// @param amount amount of From token
    /// @param slippagePercent slippage Percentage
    function calculateSlippage(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 slippagePercent
    ) public view returns (uint256) {
        uint256 fromTokenUSD = getUSDPrice(fromToken);
        uint256 toTokenUSD = getUSDPrice(toToken);
        uint256 fromTokenAmountDecimals = IHexUtils(stringUtils).toDecimals(
            fromToken,
            amount
        );

        uint256 expectedToTokenDecimal = (fromTokenAmountDecimals *
            fromTokenUSD) / toTokenUSD;

        uint256 expectedToToken = IHexUtils(stringUtils).fromDecimals(
            toToken,
            expectedToTokenDecimal
        );

        uint256 minReturn = expectedToToken -
            ((expectedToToken * slippagePercent) / (10000));
        return minReturn;
    }

    /// @dev Function to check number of vaults owned by an admin
    /// @param _vaultAdmin address of vaultAdmin
    function vaultsCount(address _vaultAdmin) public view returns (uint256) {
        return vaultsOwnedByAdmin[_vaultAdmin];
    }

    /// @dev Function to retrieve the storage of platform managementFee
    function getPlatformFeeStorage() public view returns (address) {
        return mStorage;
    }

    /// @dev Function to set the storage of platform managementFee
    /// @param _mStorage address of platform storage
    function setPlatformManagementFeeStorage(address _mStorage)
        external
        onlyYieldsterDAO
    {
        mStorage = _mStorage;
    }


    /// @dev Function to set the address of setSDKContract
    /// @param _sdkContract address of sdkContract
    function setSDKContract(address _sdkContract) external onlyYieldsterDAO {
        sdkContract = _sdkContract;
    }

    /// @dev Function to set the approved wallets
    /// @param _walletAddresses address of wallet
    /// @param _permission status of permission
    function setWalletAddress(
        address[] memory _walletAddresses,
        bool[] memory _permission
    ) external onlyYieldsterDAO {
        for (uint256 i = 0; i < _walletAddresses.length; i++) {
            if (_walletAddresses[i] != address(0))
                if (
                    permittedWalletAddresses[_walletAddresses[i]] !=
                    _permission[i]
                )
                    permittedWalletAddresses[_walletAddresses[i]] = _permission[
                        i
                    ];
        }
    }

    /// @dev Function to check if  approved wallet
    /// @param _walletAddress address of wallet

    function checkWalletAddress(address _walletAddress)
        public
        view
        returns (bool)
    {
        return permittedWalletAddresses[_walletAddress];
    }

    /// @dev Function to add assets to  Yieldster.
    /// @param _tokenAddresses Address of the assets.
    function addAssets(address[] calldata _tokenAddresses) public onlyManager {
        for (uint256 index = 0; index < _tokenAddresses.length; index++) {
            address _tokenAddress = _tokenAddresses[index];
            assets[_tokenAddress] = true;
        }
    }

    /// @dev Function to get the vault NAV Calculator contract
    function getNavCalculator() external view returns (address) {
        return navCalculator;
    }

    /// @dev Function to set the vault NAV Calculator contract
    /// @param _navCalculator Address of NAV Calculator
    function setNavCalculator(address _navCalculator) external onlyManager {
        navCalculator = _navCalculator;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IPriceModule
{
    function getUSDPrice(address ) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IHexUtils {
    function fromHex(bytes calldata) external pure returns (bytes memory);

    function toDecimals(address, uint256) external view returns (uint256);

    function fromDecimals(address, uint256) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}