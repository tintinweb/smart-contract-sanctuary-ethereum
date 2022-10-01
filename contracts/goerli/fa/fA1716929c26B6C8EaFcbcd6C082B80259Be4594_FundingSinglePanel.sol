//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IAdminTools.sol";
import "./interfaces/IFactory.sol";
import "./Token.sol";
import "./interfaces/IFundingSinglePanel.sol";
import "./interfaces/ICommunityVault.sol";

/**
 * @notice This smart contract manages a campaign from its beginning
            to its exit, if happens.
 */
contract FundingSinglePanel is Ownable, IFundingSinglePanel {
    using SafeMath for uint256;

    string private setDocURL;
    bytes32 private setDocHash;

    address public paymentTokenAddress;
    IERC20 private paymentToken;
    Token private token;
    address public tokenAddress;
    IAdminTools private ATContract;
    address public ATAddress;
    address public cashbackAddress;

    uint8 public exchRateDecimals;
    uint256 public exchangeRateOnTop;
    uint256 public exchangeRate;
    uint256 public exitExchangeRate;

    address public factoryAddress;
    uint public factoryDeployIndex;

    uint256 public paymentTokenMaxSupply;
    uint256 public paymentTokenMinSupply;
    uint256 public totalSentPaymentTokens;
    uint256 public totalNumberOfInvestors;
    uint256 public totalDepositedPaymentTokensOnExit;

    address public seedTokenAddress;
    uint256 public minimumSeedToHold;

    bool public changeTokenExchangeRateAllowed;
    bool public changeTokenExchangeOnTopRateAllowed; 
    bool public setNewSeedMaxSupplyAllowed;
    bool public isFundFinanceable;
    bool public ownerDataSet;
    bool public economicDataSet;
    bool public campaignDurationSet;
    bool public override campaignExitFlag;

    mapping (address => uint256) public investedTokens;

    uint256 public campaignStartingBlock;
    uint256 public campaignEndingBlock;
    uint256 public campaignDurationBlocks;

    bool public shouldDepositSeedAsGuarantee;

    event TokenExchangeRateChanged();
    event TokenExchangeOnTopRateChanged();
    event TokenExchangeDecimalsChanged();
    event OwnerDataChanged();
    event PaymentTokenMaxSupplyChanged();
    event MintedToken(uint256 amount, uint256 amountOnTop);
    event FundsUnlocked();
    event MintedImportedToken(uint256 newTokenAmount);
    event CashbackChanged();
    event PaymentTokenWithdrawn(address startupAddress, uint amount);
    event DepositedExitAmount(address leadInvestor, uint amount);

    /**
     * @notice Initialise the FSP
     * @param _cashbackAddress The address of the Cashback Vault
     * @param _tokenAddress The address of the Fund Token of the campaign
     * @param _ATAddress The addres of the Admin Tools smart contract of this campaign
     * @param _deployIndex The campaign id
     * @dev _deployIndex is used to identify the FSP and is an incremental number managed by the factory
     */
    constructor (address _cashbackAddress,
            address _tokenAddress, 
            address _ATAddress,
            address _factory,
            uint256 _deployIndex, 
            address _seedToken) {
        factoryDeployIndex = _deployIndex;

        cashbackAddress = _cashbackAddress;
        tokenAddress = _tokenAddress;
        ATAddress = _ATAddress;
        factoryAddress = _factory;
        token = Token(tokenAddress);
        ATContract = IAdminTools(ATAddress);
        changeTokenExchangeRateAllowed = true;
        changeTokenExchangeOnTopRateAllowed = true; 
        setNewSeedMaxSupplyAllowed = true; 

        shouldDepositSeedAsGuarantee = true;

        seedTokenAddress = _seedToken;
    }

    /**
     * @notice Set the startup documentation URL and hash
     * @param _dataURL The URL of the document
     * @param _dataHash The hash of the document
     * @dev This method can only be called by the campaign owner
     */
    function setOwnerData(string calldata _dataURL, bytes32 _dataHash) external override onlyOwner {
        require(!ownerDataSet, "/cant-change-campaign-owner-data");
        setDocURL = _dataURL;
        setDocHash = _dataHash;
        ownerDataSet = true;
        emit OwnerDataChanged();
    }

    /**
     * @notice Set the campaign economic data
     * @param _exchRate Pay-T / Fund-T exchange rate for the a generic crowd investor
     * @param _exchRateOnTop Pay-T / Fund-T exchange rate for the Community Vault
     * @param _paymentTokenAddress The address of the Payment Token
     * @param _paymentTokenMinSupply Minimum amount of Payment Token required to consider the campaign successful
     * @param _paymentTokenMaxSupply Maximum amount of Payment Token that can be invested in this campaign
     * @param _minSeedToHold Minimum number of SEED an investor has to hold in order to invest in the campaign. Has to be at least one SEED
     * @param _shouldDepositSeedGuarantee True if the campaign needs SEED as a guarantee before starting the fundraise, false otherwise.
     * @dev This method can only be called by the campaign owner
     */
    function setEconomicData(uint256 _exchRate, 
            uint256 _exchRateOnTop,
            address _paymentTokenAddress, 
            uint256 _paymentTokenMinSupply, 
            uint256 _paymentTokenMaxSupply,
            uint256 _minSeedToHold,
            bool _shouldDepositSeedGuarantee) external override onlyOwner {
        require(!economicDataSet, "/cant-change-campaign-economy");
        require(!IFactory(factoryAddress).isFactoryTGenerated(_paymentTokenAddress), "/invalid-payment-token");
        require(!IFactory(factoryAddress).isFactoryWGenerated(_paymentTokenAddress), "/invalid-payment-token");
        require(_minSeedToHold >= 1 ether, "/min-seed-low"); // at least one SEED has to be deposited

        exchangeRate = _exchRate;
        exchangeRateOnTop = _exchRateOnTop;
        exchRateDecimals = 18;
        paymentToken = IERC20(_paymentTokenAddress);
        paymentTokenAddress = _paymentTokenAddress;
        paymentTokenMaxSupply = _paymentTokenMaxSupply;
        paymentTokenMinSupply = _paymentTokenMinSupply;
        minimumSeedToHold = _minSeedToHold;
        shouldDepositSeedAsGuarantee = _shouldDepositSeedGuarantee;

        economicDataSet = true;
    }

    /**
     * @notice Set the duration of the campaign in blocks
     * @param _campaignDurationBlocks The duration of the campaign in blocks
     * @dev This method can only be called by the campaign owner
     */
    function setCampaignDuration(uint _campaignDurationBlocks) external override onlyOwner {
        require(!campaignDurationSet, "/cant-change-campaign-duration");
        campaignDurationBlocks = _campaignDurationBlocks;
        campaignDurationSet = true;
    }

/**************** Modifiers ***********/

    modifier holderEnabledInSeeds(address _holder, uint256 _seedAmountToAdd) {
        uint256 amountInTokens = getTokenExchangeAmount(_seedAmountToAdd);
        uint256 holderBalanceToBe = token.balanceOf(_holder).add(amountInTokens);
        bool okToInvest = ATContract.isWhitelisted(_holder) && holderBalanceToBe <= ATContract.getMaxTransferAmount(_holder) ? true :
                          holderBalanceToBe <= ATContract.getWLThresholdTransferAmount() ? true : false;
        require(okToInvest, "/not-whitelisted");
        _;
    }

    modifier onlyFundingOperators() {
        require(ATContract.isFundingOperator(msg.sender), "/not-funding-operator");
        _;
    }

    modifier onlyFundsUnlockerOperators() {
        require(ATContract.isFundsUnlockerOperator(msg.sender), "/not-unlocker-operator");
        _;
    }

    modifier onlyCashbackOrNoSeedGuarantee() {
        bool caseSeedGuaranteeNotNeeded = msg.sender == owner() && !shouldDepositSeedAsGuarantee;
        bool caseSeedGuaranteeNeeded = msg.sender == cashbackAddress && shouldDepositSeedAsGuarantee;
        require(caseSeedGuaranteeNotNeeded || caseSeedGuaranteeNeeded, "/not-cashback-or-owner");
        _;
    }

/**************************************/

    /**
     * @notice Get the campaign id
     * @return campaignId uint256 The campaing id
     */
    function getFactoryDeployIndex() public view override returns(uint) {
        return factoryDeployIndex;
    }

    /**
     * @notice Returns the amount of tokens the user will receive for the specified amount of Payment Token
     * @param _amount The amount of Payment Token to exchange
     * @return exchangeRate uint256 The amount of Fund Token received after the exchange
     */
    function getTokenExchangeAmount(uint256 _amount) internal view returns(uint256) {
        require(_amount > 0);
        return _amount.mul(exchangeRate).div(10 ** uint256(exchRateDecimals));
    }

    /**
     * @notice Returns the amount of tokens the Community Vault will receive for the specified amount of Payment Token
     * @param _amount The amount of Payment Token to exchange
     * @return exchangeRate uint256 The amount of Fund Token received after the exchange
     */
    function getTokenExchangeAmountOnTop(uint256 _amount) internal view returns(uint256) {
        require(_amount > 0);
        return _amount.mul(exchangeRateOnTop).div(100).div(10 ** uint256(exchRateDecimals));
    }

    /**
     * @notice Returns the address of the Fund Token of this campaign
     * @return fundToken address The address of the Fund Token
     */
    function getTokenAddress() external view returns (address) {
        return tokenAddress;
    }

    /**
     * @notice Returns the campaign documentation URL and the document hash
     * @return data The campaign documentation URL and hash
     */
    function getOwnerData() external view override returns (string memory, bytes32) {
        return (setDocURL, setDocHash);
    }

    /**
     * @notice Returns the amount of invested Payment Token by the specified address
     * @param _investor The address of the investor
     * @return amount uint256 The amount of Payment Token invested by the investor
     */
    function getSentTokens(address _investor) external view override returns (uint256) {
        return investedTokens[_investor];
    }

    /**
     * @notice Returns the amount of invested Payment Token in this campaign
     * @return amount uint256 The total amount of Payment Tokens invested
     */
    function getTotalSentTokens() external view override  returns (uint256) {
        // if the total supply can change after the campaign ends we should create a more 
        // sophisticated method to store the totalSupply when the campaign ends
        return totalSentPaymentTokens;
    }

    /**
     * @notice Returns the block numbers that marks the beginning and the ending of the campaign
     * @return blocks tuple The block number of the beginning and the ending of the campaign
     * @dev The first block number marks the beginning of the campaign, the second one marks the ending
     */
    function getCampaignPeriod() external view override returns (uint256, uint256) {
        return (campaignStartingBlock, campaignEndingBlock);
    }

    /**
     * @notice Set if an investor can now invest in this campaign
     * @dev This method can only be called by the Cashback Vault
     */
    function setFSPFinanceable() external override onlyCashbackOrNoSeedGuarantee {
        require(ownerDataSet && economicDataSet && campaignDurationSet, "/campaign-data-not-set");
        
        campaignStartingBlock = block.number;
        campaignEndingBlock = campaignStartingBlock.add(campaignDurationBlocks);
        isFundFinanceable = true;
    }

    /**
     * @notice Returns if the campaign is over
     * @return isOver bool True if the campaign is over, false otherwise
     */
    function isCampaignOver() public view override returns (bool) {
        return (block.number > campaignEndingBlock && campaignEndingBlock != 0);
    }

    /**
     * @notice Returns if the campaign is successful
     * @return isSuccessful bool True if the campaign is successful, false otherwise
     */
    function isCampaignSuccessful() public view override returns (bool) {
        require(isCampaignOver(), "/campaign-not-terminated");

        return (totalSentPaymentTokens >= paymentTokenMinSupply);
    }

    /**
     * @notice Let a crowd investor invest Payment Tokens in the campaign
     * @param _amount The amount of payment tokens to invest
     * @param _receiver receiver address of minted tokens, if set to 0 token will be sent to msg.sender
     * @dev msg.sender has to approve transfer the seed tokens BEFORE calling this function. This method takes 
            the _amount Payment Token from the caller and mints back _amount * exchangeRate Fund Tokens. It also 
            mints _amount * exchangeRateOnTop Fund-Token to the Community Vault
            On success, emits the event MintedToken(_amount, amountOnTop). 
            This method can only be called if the crowd investor is whitelisted or is investing less than the 
            whitelist threshold
     */
    function holderSendPaymentToken(uint256 _amount, address _receiver) external override holderEnabledInSeeds(msg.sender, _amount) {
        require(isFundFinanceable, "/not-financeable");
        require(paymentToken.balanceOf(msg.sender) >= _amount, "/insufficient-funds");
        require(_amount > 0, "/invalid-amount");
        require(block.number <= campaignEndingBlock, "/campaign-ended");
        SafeERC20.safeTransferFrom(paymentToken, msg.sender, address(this), _amount);
        totalSentPaymentTokens = totalSentPaymentTokens.add(_amount);
        require(totalSentPaymentTokens <= paymentTokenMaxSupply, "/fund-exceeds-max-supply");
        
        address walletOnTop = ATContract.getWalletOnTopAddress();
        require(ATContract.isWhitelisted(walletOnTop), "/ontop-not-whitelisted");

        // Check if investor has at least the minimum amount of SEED
        uint balance = IERC20(seedTokenAddress).balanceOf(msg.sender);
        require (balance >= minimumSeedToHold, "/insufficient-seed"); 
        
        // Update investors counter
        if (investedTokens[msg.sender] == 0) {
            totalNumberOfInvestors = totalNumberOfInvestors.add(1);
        }

        investedTokens[msg.sender] = investedTokens[msg.sender].add(_amount);

        //apply conversion seed/set token
        uint256 amount = getTokenExchangeAmount(_amount);
        if (_receiver == address(0))
            _receiver = msg.sender;
        token.mint(_receiver, amount);

        // Mint for the Community Vault
        uint256 amountOnTop = getTokenExchangeAmountOnTop(_amount);
        if (amountOnTop > 0)
            token.mint(walletOnTop, amountOnTop);

        emit MintedToken(amount, amountOnTop);
    }

    /**
     * @notice Returns the invested Payment Tokens to the caller if a campaign fails
     * @dev The caller has to approve the transfer of all its Fund Tokens
     */
    function returnPaymentTokensIfCampaignUnsuccessful() external {
        require(!isCampaignSuccessful(), "/campaign-successful");

        uint amount = token.balanceOf(msg.sender);
        require(amount > 0, "/nothing-to-return");

        // Takes the fund token from msg.sender, then burns them
        // token.transferFrom(msg.sender, address(this), amount);
        token.burn(msg.sender, amount);

        // Sends amount * exchangeRate payment tokens to msg.sender
        uint payAmount = amount.mul(1e18).div(exchangeRate);
        IERC20(paymentTokenAddress).transfer(msg.sender, payAmount);
    }

    /**
     * @notice Withdraws 99% of the payment tokens to the startup, 1% to the Commnity Vault.
     * @param _startupAddress the address of the startup 
     * @dev After transferring the Payment Tokens it wraps the Fund-T in the Community Vault, then
            creates a liquidity pool with 1% of the Payment Tokens raised during the campaign and 
            all the Fund Tokens in the Community Vault. 
            This method can only be called by a funds unlocker operator
     */
    function withdrawPaymentTokens(address _startupAddress) external onlyFundsUnlockerOperators {
        require(isCampaignSuccessful(), "/campaign-not-successful");

        uint startupAmount = totalSentPaymentTokens.mul(99).div(100);
        uint communityVaultAmount = totalSentPaymentTokens.sub(startupAmount); // 1% = 100% - 99%

        SafeERC20.safeTransfer(paymentToken, _startupAddress, startupAmount);
        
        address communityVaultAddress = ATContract.getWalletOnTopAddress();
        SafeERC20.safeApprove(paymentToken, communityVaultAddress, communityVaultAmount);
        ICommunityVault(communityVaultAddress).depoistCampaignPaymentTokens(factoryDeployIndex, paymentTokenAddress, communityVaultAmount);

        emit PaymentTokenWithdrawn(_startupAddress, startupAmount);
    }

    /**
    * @notice Set the campaign in the exit state
    * @dev This method can only be called by the campaign owner
    */
    function setCampaignExit() public onlyOwner {
        require(exitExchangeRate != 0, "/must-deposit-exit-tokens-first");
        campaignExitFlag = true;
    }

    /**
     * @notice Let a lead investor deposit Payment Tokens raised during the exit
     * @param _leadInvestor The address of the lead investor
     * @param _amount The amount of Paymnet Tokens that will be deposited
     * @dev _leadInvestor must approve the transfer before calling this method. This method can only be
            called by a funding operator
     */
    function depositExitPaymentTokens(address _leadInvestor, uint256 _amount) external onlyFundingOperators {
        require(!campaignExitFlag, "/exit-completed");
        require(paymentToken.allowance(_leadInvestor, address(this)) >= _amount, "/must-approve-transfer");

        // Transfer _amount Pay-T from _leadInvestor
        SafeERC20.safeTransferFrom(paymentToken, _leadInvestor, address(this), _amount);

        // Compute the new exchane rate
        uint fundTokenTotalSupply = token.totalSupply();
        totalDepositedPaymentTokensOnExit = totalDepositedPaymentTokensOnExit.add(_amount);
        exitExchangeRate = totalDepositedPaymentTokensOnExit.mul(1e18).div(fundTokenTotalSupply);

        emit DepositedExitAmount(_leadInvestor, _amount);
    }


    /**
    * @notice Let a crowd investor claim Payment Tokens after an exit has been done
    * @param _amount The amount of Fund Token used for the claim
    * @return paytAmount uint The amount of Payment Tokens claimed
    */
    function claimExitPaymentTokens(uint256 _amount) public override returns (uint) {
        require(campaignExitFlag, "/not-exit");
        require(token.balanceOf(msg.sender) >= _amount, "/invalid-amount");

        // Take _amount Fund-T from the sender
        token.burn(msg.sender, _amount);

        // Compute the amount of Pay-Ts and transfer them to sender
        uint256 payTokenAmount = _amount.mul(exitExchangeRate).div(1e18);
        SafeERC20.safeTransfer(paymentToken, msg.sender, payTokenAmount);

        return payTokenAmount;
    }

    /**
     * @notice Burn Fund tokens 
     * @param _amount The amount of Fund Tokens to burn
     * @dev This method can only be called by a funding operator
     */
    function burnFundTokens(uint256 _amount) external override onlyFundingOperators {
        require(token.balanceOf(msg.sender) >= _amount);
        token.burn(msg.sender, _amount);
    }

    /**
     * @notice Import unknown tokens and mints Fund Tokens
     * @param _tokenAddress Token address to convert in this tokens
     * @param _tokenAmount Amount of old tokens to convert
     * @dev This method can only be called by a funding operator
     */
    function importOtherTokens(address _tokenAddress, uint256 _tokenAmount) external override onlyFundingOperators {
        require(token.isImportedContract(_tokenAddress));
        require(token.getImportedContractRate(_tokenAddress) >= 0);
        require(ATContract.isWhitelisted(msg.sender));
        uint256 newTokenAmount = _tokenAmount.mul(token.getImportedContractRate(_tokenAddress));
        uint256 holderBalanceToBe = token.balanceOf(msg.sender).add(newTokenAmount);
        bool okToInvest = ATContract.isWhitelisted(msg.sender) && holderBalanceToBe <= ATContract.getMaxTransferAmount(msg.sender) ? true :
                          holderBalanceToBe <= ATContract.getWLThresholdTransferAmount() ? true : false;
        require(okToInvest);
        token.mint(msg.sender, newTokenAmount);
        emit MintedImportedToken(newTokenAmount);
    }
}

//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

interface IToken {
    function getPaused() external view returns (bool);
    function pause() external;
    function unpause() external;
    function isImportedContract(address) external view returns (bool);
    function getImportedContractRate(address) external view returns (uint256);
    function setImportedContract(address, uint256) external;
    function checkTransferAllowed (address, address, uint256) external view returns (bytes1);
    function checkTransferFromAllowed (address, address, uint256) external view returns (bytes1);
    // function checkMintAllowed (address, uint256) external pure returns (bytes1);
    // function checkBurnAllowed (address, uint256) external pure returns (bytes1);
    function setFSPAddress (address) external;
    function okToReceiveTokens(address _recipient, uint256 _amountToAdd) external view returns (bool);
    function okToTransferTokens(address _holder, uint256 _amountToAdd) external view returns (bool);
}

//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

interface IFundingSinglePanel {
    function getFactoryDeployIndex() external view returns(uint _deployIndex);
    // function changeTokenExchangeRate(uint256 _newExchRate) external;
    // function changeTokenExchangeOnTopRate(uint256 _newExchRateOnTop) external;
    function getOwnerData() external view returns (string memory _docURL, bytes32 _docHash);
    function setOwnerData(string calldata _docURL, bytes32 _docHash) external;
    function setEconomicData(uint256 _exchRate, 
            uint256 _exchRateOnTop,
            address _paymentTokenAddress, 
            uint256 _paymentTokenMinSupply, 
            uint256 _paymentTokenMaxSupply,
            uint256 _minSeedToHold,
            bool _shouldDepositSeedGuarantee) external;
    function setCampaignDuration(uint _campaignDurationBlocks) external;
    function getCampaignPeriod() external returns (uint256 _campStartingBlock, uint256 _campEndingBlock);
    // function setCashbackAddress(address _cashback) external returns (address _newCashbackAddr);
    // function setNewPaymentTokenMaxSupply(uint256 _newMaxPTSupply) external returns (uint256 _ptMaxSupply);
    function holderSendPaymentToken(uint256 _amount, address _receiver) external;
    function burnFundTokens(uint256 _amount) external;
    function importOtherTokens(address _tokenAddress, uint256 _tokenAmount) external;
    function getSentTokens(address _investor) external returns (uint256);
    function getTotalSentTokens() external returns (uint256 _amount);
    function setFSPFinanceable() external;
    // function isFSPFinanceable() external returns (bool _isFinanceable);
    function isCampaignOver() external returns (bool _isOver);
    function isCampaignSuccessful() external returns (bool _isSuccessful);
    function claimExitPaymentTokens(uint256 _amount) external returns (uint);
    function campaignExitFlag() external view returns (bool);
}

//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

interface IFactory {
    function changeATFactoryAddress(address) external;
    function changeTDeployerAddress(address) external;
    function changeFPDeployerAddress(address) external;
    function deployPanelContracts(string calldata, string calldata, string calldata, bytes32, uint8, uint8, uint256, uint256) external;
    function isFactoryDeployer(address) external view returns(bool);
    function isFactoryATGenerated(address) external view returns(bool);
    function isFactoryTGenerated(address) external view returns(bool);
    function isFactoryWGenerated(address) external view returns(bool);
    function isFactoryFPGenerated(address) external view returns(bool);
    function getTotalDeployer() external view returns(uint256);
    function getTotalATContracts() external view returns(uint256);
    function getTotalTContracts() external view returns(uint256);
    function getTotalFPContracts() external view returns(uint256);
    function getContractsByIndex(uint256) external view returns (address, address, address, address);
    function getFSPAddressByIndex(uint256) external view returns (address);
    function getFactoryContext() external view returns (address, address, uint);
}

//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

interface ICommunityVault {
    function depoistCampaignPaymentTokens(uint _fspNumber, address _paymentTokenAddress, uint _amount) external;
    function setFundTokenWrapper(uint _fspNumber, address _wrapper, address _fundToken) external;
    function getPayTokenToSeedPrice(address _payToken) external view returns (uint);
}

//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

interface IAdminTools {
    function setFFSPAddresses(address, address) external;
    function setMinterAddress(address) external returns(address);
    function getMinterAddress() external view returns(address);
    function getWalletOnTopAddress() external view returns (address);
    function setWalletOnTopAddress(address) external returns(address);

    function addWLManagers(address) external;
    function removeWLManagers(address) external;
    function isWLManager(address) external view returns (bool);
    function addWLOperators(address) external;
    function removeWLOperators(address) external;
    function renounceWLManager() external;
    function isWLOperator(address) external view returns (bool);
    function renounceWLOperators() external;

    function addFundingManagers(address) external;
    function removeFundingManagers(address) external;
    function isFundingManager(address) external view returns (bool);
    function addFundingOperators(address) external;
    function removeFundingOperators(address) external;
    function renounceFundingManager() external;
    function isFundingOperator(address) external view returns (bool);
    function renounceFundingOperators() external;

    function addFundsUnlockerManagers(address) external;
    function removeFundsUnlockerManagers(address) external;
    function isFundsUnlockerManager(address) external view returns (bool);
    function addFundsUnlockerOperators(address) external;
    function removeFundsUnlockerOperators(address) external;
    function renounceFundsUnlockerManager() external;
    function isFundsUnlockerOperator(address) external view returns (bool);
    function renounceFundsUnlockerOperators() external;

    function isWhitelisted(address) external view returns(bool);
    function getWLThresholdEmissionAmount() external view returns (uint256);
    function getWLThresholdTransferAmount() external view returns (uint256);
    function getMaxEmissionAmount(address) external view returns(uint256);
    function getMaxTransferAmount(address) external view returns(uint256);
    function getWLLength() external view returns(uint256);
    function setNewEmissionThreshold(uint256) external;
    function setNewTransferThreshold(uint256) external;
    function changeMaxWLAmount(address, uint256, uint256) external;
    function addToWhitelist(address, uint256, uint256) external;
    function addToWhitelistMassive(address[] calldata, uint256[] calldata,  uint256[] calldata) external returns (bool);
    function removeFromWhitelist(address, uint256) external;
}

//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAdminTools.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IFundingSinglePanel.sol";

/**
 * @notice This smart contract represents a Fund Token in the platform. It's an ERC20 with whitelisting capabilities.
 */
contract Token is IToken, ERC20, Ownable {
    using SafeMath for uint256;

    IAdminTools private ATContract;
    address private ATAddress;

    bytes1 private constant STATUS_ALLOWED = 0x11;
    bytes1 private constant STATUS_DISALLOWED = 0x10;

    address public fspAddress;
    address public factoryAddress;

    bool private _paused;

    struct contractsFeatures {
        bool permission;
        uint256 tokenRateExchange;
    }

    mapping(address => contractsFeatures) private contractsToImport;

    event Paused(address account);
    event Unpaused(address account);

    /**
     * @notice Initialise the Fund Token
     * @param tokname The name of the token
     * @param toksymbol The symbol of the token
     * @param _ATAddress The address of the Admin Tools related to this Fund Token
     * @param _factoryAddress The address of the factory
     */
    constructor(string memory tokname, string memory toksymbol, address _ATAddress, address _factoryAddress /*, uint8 _tokenDecimals*/) ERC20(tokname, toksymbol) {
        //_setupDecimals(_tokenDecimals);

        factoryAddress = _factoryAddress;

        ATAddress = _ATAddress;
        ATContract = IAdminTools(ATAddress);
        _paused = false;
    }

    modifier onlyMinterAddress() {
        require(ATContract.getMinterAddress() == msg.sender, "Address can not mint!");
        _;
    }

    /**
     * @notice Ensures that the function can only be called if the campaign is over
     */
    modifier onlyWhenCampaignFinished() {
        bool isCampaignOver = IFundingSinglePanel(fspAddress).isCampaignOver();
        require(isCampaignOver, "/campaign-not-finished");
        _;
    }

    /**
     * @notice Ensures that the function can only be called by the factory
     */
    modifier onlyFactory() {
        require(msg.sender == factoryAddress, "/not-factory");
        _;
    }

    /**
     * @notice Ensures that the function can only be called when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Token Contract paused...");
        _;
    }

    /**
     * @notice Ensures that the function can only be called when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Token Contract not paused");
        _;
    }

    /**
     * @notice Returns if the token is paused or not
     * @return isPaused bool True if the token is paused, false otherwise.
     */
    function getPaused() external view override returns (bool) {
        return _paused;
    }

    /**
     * @notice Pauses the token
     * @dev This method can only be called by the owner of the token
     */
    function pause() external override onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses the token
     * @dev This method can only be called by the owner of the token
     */
    function unpause() external override onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Check if the contract can be imported to change with this token
     * @param _contract The address of token to be imported
     * @return isImported bool True if the can be used to change with this token
     */
    function isImportedContract(address _contract) external override view returns (bool) {
        return contractsToImport[_contract].permission;
    }

    /**
     * @notice Get the exchange rate between token to be imported and this token
     * @param _contract The address of token to be exchange
     * @return exchangeRate uint256 The exchange rate with 18 decimals
     */
    function getImportedContractRate(address _contract) external override view returns (uint256) {
        return contractsToImport[_contract].tokenRateExchange;
    }

    /**
     * @notice Set the address of the token to be imported and its exchange rate
     * @param _contract The address of token to be imported
     * @param _exchRate The exchange rate between token to be imported and this token
     * @dev This method can only be called by the owner
     */
    function setImportedContract(address _contract, uint256 _exchRate) external override onlyOwner {
        require(_contract != address(0), "Address not allowed!");
        require(_exchRate >= 0, "Rate exchange not allowed!");
        contractsToImport[_contract].permission = true;
        contractsToImport[_contract].tokenRateExchange = _exchRate;
    }

    /**
     * @notice Transfer tokens from the caller to another account
     * @param _to The address of the receiver
     * @param _value The quantity of tokens to transfer
     * @dev Checks if the transfer can be done via the Admin Tools
     */
    function transfer(address _to, uint256 _value) public override whenNotPaused onlyWhenCampaignFinished returns (bool) {
        require(checkTransferAllowed(msg.sender, _to, _value) == STATUS_ALLOWED, "transfer must be allowed");
        return ERC20.transfer(_to, _value);
    }

    /**
     * @notice Transfer tokens between two accounts
     * @param _from The address of the sender
     * @param _to The address of the receiver
     * @param _value The quantity of tokens to transfer
     * @dev Checks if the transfer can be done via the Admin Tools
     */
    function transferFrom(address _from, address _to, uint256 _value) public override whenNotPaused onlyWhenCampaignFinished returns (bool) {
        require(checkTransferFromAllowed(_from, _to, _value) == STATUS_ALLOWED, "transfer must be allowed");
        return ERC20.transferFrom(_from, _to,_value);
    }

    /**
     * @notice Mints new token to a specified address
     * @param _account The address of the receiver
     * @param _amount The quantity of tokens to mint
     * @dev Checks if the mint is allowed and if the receiver can receive the tokens via the Admin Tools
     */
    function mint(address _account, uint256 _amount) public whenNotPaused onlyMinterAddress {
        // require(checkMintAllowed(_account, _amount) == STATUS_ALLOWED, "mint must be allowed");
        require(okToReceiveTokens(_account, _amount), "Receiver not allowed to receive tokens!");
        ERC20._mint(_account, _amount);
    }

    /**
     * @notice Burns token from a specified address
     * @param _account The address from which tokens will be burned
     * @param _amount The quantity of tokens to burn
     * @dev Checks if the burn is allowed via the Admin Tools
     */
    function burn(address _account, uint256 _amount) public whenNotPaused onlyMinterAddress {
        // require(checkBurnAllowed(_account, _amount) == STATUS_ALLOWED, "burn must be allowed");
        ERC20._burn(_account, _amount);
    }

    /**
     * @notice Check if the sender address could receive new tokens on emission
     * @param _recipient The address of the receiver
     * @param _amountToAdd The amount of tokens to be added to sender balance on emission
     * @return canReceive bool True if the recipient can receive the specified amount of tokens
     */
    function okToReceiveTokens(address _recipient, uint256 _amountToAdd) public view override returns (bool){
        uint256 holderBalanceToBe = balanceOf(_recipient).add(_amountToAdd);
        bool okToTransfer = ATContract.isWhitelisted(_recipient) && holderBalanceToBe <= ATContract.getMaxEmissionAmount(_recipient) ? true :
                          holderBalanceToBe <= ATContract.getWLThresholdEmissionAmount() ? true : false;
        return okToTransfer;
    }

    /**
     * @notice Check if the sender address could receive new tokens on transfer
     * @param _holder The address of the sender
     * @param _amountToAdd The amount of tokens to be added to sender balance on transfer
     * @return canTransfer bool True if the holder can transfer the specified amount of tokens
     */
    function okToTransferTokens(address _holder, uint256 _amountToAdd) public view override returns (bool){
        uint256 holderBalanceToBe = balanceOf(_holder).add(_amountToAdd);
        bool okToTransfer = ATContract.isWhitelisted(_holder) && holderBalanceToBe <= ATContract.getMaxTransferAmount(_holder) ? true :
                          holderBalanceToBe <= ATContract.getWLThresholdTransferAmount() ? true : false;
        return okToTransfer;
    }

    /**
     * @notice Check if a transfer can be done
     * @param _sender The address that will transfer the tokens
     * @param _receiver The address that will receive the tokens
     * @param _amount The amount of tokens that will be transferred
     * @return status bytes1 Returns STATUS_ALLOWED if the receiver can receiver the specified amount of tokens
     */
    function checkTransferAllowed (address _sender, address _receiver, uint256 _amount) public view override returns (bytes1) {
        require(_sender != address(0), "Sender can not be 0!");
        require(_receiver != address(0), "Receiver can not be 0!");
        require(balanceOf(_sender) >= _amount, "Sender does not have enough tokens!");
        require(okToTransferTokens(_receiver, _amount), "Receiver not allowed to perform transfer!");
        return STATUS_ALLOWED;
    }

    /**
     * @notice Check if a transferFrom can be done
     * @param _sender The address that will transfer the tokens
     * @param _receiver The address that will receive the tokens
     * @param _amount The amount of tokens that will be transferred
     * @return status bytes1 Returns STATUS_ALLOWED if the receiver can receiver the specified amount of tokens
     */
    function checkTransferFromAllowed (address _sender, address _receiver, uint256 _amount) public view override returns (bytes1) {
        require(_sender != address(0), "Sender can not be 0!");
        require(_receiver != address(0), "Receiver can not be 0!");
        require(balanceOf(_sender) >= _amount, "Sender does not have enough tokens!");
        require(okToTransferTokens(_receiver, _amount), "Receiver not allowed to perform transfer!");
        return STATUS_ALLOWED;
    }

    /**
     * @notice Set the address of the FSP related to this Fund Token
     * @param _fspAddress The address of the FSP
     * @dev This method can only be called by the factory
     */
    function setFSPAddress(address _fspAddress) external onlyFactory override {
        require(fspAddress == address(0), "/fsp-address-already-set");
        fspAddress = _fspAddress;
    }


    // function checkMintAllowed (address, uint256) public pure override returns (bytes1) {
    //     // require(ATContract.isOperator(_minter), "Not Minter!");
    //     return STATUS_ALLOWED;
    // }

    // function checkBurnAllowed (address, uint256) public pure override returns (bytes1) {
    //     // default
    //     return STATUS_ALLOWED;
    // }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}