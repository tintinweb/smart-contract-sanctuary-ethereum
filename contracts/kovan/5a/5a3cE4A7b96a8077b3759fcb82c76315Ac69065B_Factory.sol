//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IERC20Seed.sol";
import "./interfaces/IAdminTools.sol";
import "./interfaces/IATDeployer.sol";
import "./interfaces/IFundingSinglePanel.sol";
import "./interfaces/ITDeployer.sol";
import "./interfaces/IFSPDeployer.sol";
import "./interfaces/IWDeployer.sol";
import "./interfaces/ICommunityVault.sol";
import "./interfaces/IToken.sol";

/**
 * @notice This smart contract manages the creation of every campaign in the platform
 */
contract Factory is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address[] public deployerList;
    uint public deployerLength;
    address[] public ATContractsList;
    address[] public TContractsList;
    address[] public FSPContractsList;
    address[] public WContractsList;

    mapping(address => bool) public deployers;
    mapping(address => bool) public ATContracts;
    mapping(address => bool) public TContracts;
    mapping(address => bool) public FSPContracts;
    mapping(address => bool) public WContracts;

    IERC20Seed private seedContract;
    address private seedAddress;
    IATDeployer private deployerAT;
    address private ATDAddress;
    ITDeployer private deployerT;
    address private TDAddress;
    IFSPDeployer private deployerFSP;
    address private FSPDAddress;
    IWDeployer private deployerW;
    address private WDAddress;

    address private internalDEXAddress;

    uint private factoryDeployBlock;

    uint nextFPIndex = 0;
    mapping(address => uint) private FSPAddressToIndexMap;

    address public communityVaultAddress;
    address public cashbackAddress;

    event NewPanelCreated(address creator, address admintTools, address fundToken, address wrapper, address fsp, uint deployedFSPs);
    event ATFactoryAddressChanged();
    event TFactoryAddressChanged();
    event FSPFactoryAddressChanged();
    event WFactoryAddressChanged();
    event InternalDEXAddressChanged();
    event CommunityVaultAddressChanged();
    event CashbackAddressChanged();

    /**
     * @notice Initialise the factory
     * @param _seedAddress The address of SEED
     * @param _ATDAddress The address of the Admin Tools deployer 
     * @param _TDAddress The addres of the Fund Token deployer
     * @param _FSPDAddress The address of the FSP deployer
     * @param _WDAddress The address of the Wrapper deployer
     */
    constructor (address _seedAddress, 
            address _ATDAddress, 
            address _TDAddress, 
            address _FSPDAddress,
            address _WDAddress) {
        seedAddress = _seedAddress;
        seedContract = IERC20Seed(seedAddress);
        ATDAddress = _ATDAddress;
        deployerAT = IATDeployer(ATDAddress);
        TDAddress = _TDAddress;
        deployerT = ITDeployer(_TDAddress);
        FSPDAddress = _FSPDAddress;
        deployerFSP = IFSPDeployer(_FSPDAddress);
        WDAddress = _WDAddress;
        deployerW = IWDeployer(_WDAddress);
        factoryDeployBlock = block.number;
    }

    /**
     * @notice Changes AdminTools deployer address
     * @param _newATD The new Admin Tools deployer address
     * @dev On success emits the event ATFactoryAddressChanged
     */
    function changeATDeployerAddress(address _newATD) external onlyOwner {
        //require(block.number < 8850000, "Time expired!");
        require(_newATD != address(0), "/zero-address");
        require(_newATD != ATDAddress, "/address-not-changed");
        ATDAddress = _newATD;
        deployerAT = IATDeployer(ATDAddress);
        emit ATFactoryAddressChanged();
    }

    /**
     * @dev Changes Fund Token deployer address
     * @param _newTD The new Fund Token deployer address
     * @dev On success emits the event TFactoryAddressChanged
     */
    function changeTDeployerAddress(address _newTD) external onlyOwner {
        //require(block.number < 8850000, "Time expired!");
        require(_newTD != address(0), "/zero-address");
        require(_newTD != TDAddress, "/address-not-changed");
        TDAddress = _newTD;
        deployerT = ITDeployer(TDAddress);
        emit TFactoryAddressChanged();
    }

    /**
     * @dev change Funding Panel deployer address
     * @param _newFPD new FP deployer address
     */
    // function changeFPDeployerAddress(address _newFPD) external onlyOwner {
    //     //require(block.number < 8850000, "Time expired!");
    //     require(_newFPD != address(0), "Address not suitable!");
    //     require(_newFPD != ATDAddress, "FPD factory address not changed!");
    //     FPDAddress = _newFPD;
    //     deployerFP = IFPDeployer(FPDAddress);
    //     emit FPFactoryAddressChanged();
    // }

    /**
     * @dev Changes Funding Single Panel deployer address
     * @param _newFSPD The new FSP deployer address
     * @dev On success emits the event FSPFactoryAddressChanged
     */
    function changeFSPDeployerAddress(address _newFSPD) external onlyOwner {
        //require(block.number < 8850000, "Time expired!");
        require(_newFSPD != address(0), "/zero-address");
        require(_newFSPD != FSPDAddress, "/address-not-changed");
        FSPDAddress = _newFSPD;
        deployerFSP = IFSPDeployer(FSPDAddress);
        emit FSPFactoryAddressChanged();
    }

    /**
     * @dev Changes Wrapper deployer address
     * @param _newWD The new Wrapper deployer address
     * @dev On success emits the event WFactoryAddressChanged
     */
    function changeWDeployerAddress(address _newWD) external onlyOwner {
        //require(block.number < 8850000, "Time expired!");
        require(_newWD != address(0), "/zero-address");
        require(_newWD != WDAddress, "/address-not-changed");
        WDAddress = _newWD;
        deployerW = IWDeployer(_newWD);
        emit WFactoryAddressChanged();
    }

    /**
     * @dev set internal DEX address
     * @param _dexAddress internal DEX address
     */
    // function setInternalDEXAddress(address _dexAddress) external onlyOwner {
    //     //require(block.number < 8850000, "Time expired!");
    //     require(_dexAddress != address(0), "Address not suitable!");
    //     require(_dexAddress != internalDEXAddress, "DEX factory address not changed!");
    //     internalDEXAddress = _dexAddress;
    //     emit InternalDEXAddressChanged();
    // }

    /**
     * @dev Changes Community Vault address
     * @param _cvAddress The new Community Vault address
     * @dev On success emits the event CommunityVaultAddressChanged
     */
    function changeCommunityVaultAddress(address _cvAddress) external onlyOwner {
        require(_cvAddress != address(0), "/zero-address");

        communityVaultAddress = _cvAddress;

        emit CommunityVaultAddressChanged();
    }

    /**
     * @dev Changes the Cashback Vault address
     * @param _cashbackAddress The new Cashback Vault address
     * @dev On success emits the event CashbackAddressChanged
     */
    function changeCashbackAddress(address _cashbackAddress) external onlyOwner {
        require(_cashbackAddress != address(0), "/zero-address");

        cashbackAddress = _cashbackAddress;

        emit CashbackAddressChanged();
    }

    /**
     * @notice Deploys a new set of contracts for the campaign
     * @param _name The name of the token to be deployed
     * @param _symbol The symbol of the token to be deployed
     * @param _setDocURL The URL of the document describing the campaign
     * @param _setDocHash The hash of the document describing the campaign
     * @param _exchRateOnTop The exchange rate between Payment Tokens and Fund Tokens for the Community Vault, including 18 decimals.
     * @param _paymentTokenMaxSupply The maximum supply of Payment Tokens accepted during the campaign
     * @param _WLEmissionAnonymThr Emission threshold for an anonymous crowd investor
     * @param _WLTransferAnonymThr Transfer threshold for an anonymous crowd investor
     * @return The campaign id
     * @dev Sets the minter address for the Fund Token contract,
     *      The campaign owner is set as a manager in whitelisting, funding and fund unlocker.
     *      Community Vault and Wrapper will also be whitelisted
     */
    function deployCampaign(string memory _name, 
            string memory _symbol, 
            string memory _setDocURL, 
            bytes32 _setDocHash,
            // uint256 _exchRateToken, 
            uint256 _exchRateOnTop, 
            uint256 _paymentTokenMaxSupply, 
            //uint256 _seedMinSupply,
            //address _paymentTokenAddress, 
            uint256 _WLEmissionAnonymThr, 
            uint256 _WLTransferAnonymThr) external nonReentrant returns (uint) {
        require(msg.sender != address(0), "/sender-is-zero");
        require(communityVaultAddress != address(0), "/cv-address-not-set");
        //require(internalDEXAddress != address(0), "Internal DEX Address is zero");

        deployers[msg.sender] = true;
        deployerList.push(msg.sender);
        deployerLength = deployerList.length;

        // Admin Tools
        address newAT = deployerAT.newAdminTools(_WLEmissionAnonymThr, _WLTransferAnonymThr);
        ATContracts[newAT] = true;
        ATContractsList.push(newAT);

        // Fund Token
        address newT = deployerT.newToken(msg.sender, _name, _symbol, newAT);
        TContracts[newT] = true;
        TContractsList.push(newT);

        // Wrapper
        address newW = deployerW.newWrapper(msg.sender, 
            string(abi.encodePacked("Wrapped ",_name)), 
            string(abi.encodePacked("W", _symbol)), newT);
        WContracts[newW] = true;
        WContractsList.push(newW);

        // Funding Single Panel
        address newFSP = deployerFSP.newFundingSinglePanel(cashbackAddress, newT, newAT, (deployerLength-1), seedAddress);
        IFundingSinglePanel(newFSP).setOwnerData(_setDocURL, _setDocHash);
        //IFundingSinglePanel(newFSP).setEconomicData(_exchRateToken, _exchRateOnTop, _paymentTokenAddress, _seedMinSupply, _paymentTokenMaxSupply);
        FSPContracts[newFSP] = true;
        FSPContractsList.push(newFSP);

        // Update FSP index
        uint newFSPIndex = nextFPIndex;
        FSPAddressToIndexMap[newFSP] = newFSPIndex;
        nextFPIndex = nextFPIndex.add(1);

        // Set the FSP address in the Fund Token contract
        IToken(newT).setFSPAddress(newFSP);

        // Transfer FSP ownership
        Ownable customOwnable = Ownable(newFSP);
        customOwnable.transferOwnership(msg.sender);

        // Updates the community vault
        ICommunityVault(communityVaultAddress).setFundTokenWrapper(newFSPIndex, newW, newT);

        // Admin tools setup
        IAdminTools ATBrandNew = IAdminTools(newAT);
        ATBrandNew.setFFSPAddresses(address(this), newFSP);
        ATBrandNew.setMinterAddress(newFSP);
        ATBrandNew.addWLManagers(address(this));
        ATBrandNew.addWLManagers(msg.sender);
        ATBrandNew.addFundingManagers(msg.sender);
        ATBrandNew.addFundsUnlockerManagers(msg.sender);
        ATBrandNew.setWalletOnTopAddress(communityVaultAddress);

        //uint256 dexMaxAmnt = _exchRateToken.mul(300000000);  //Seed total supply
        //ATBrandNew.addToWhitelist(internalDEXAddress, dexMaxAmnt, dexMaxAmnt);

        uint256 onTopMaxAmnt = _paymentTokenMaxSupply.mul(_exchRateOnTop).div(1e18);
        ATBrandNew.addToWhitelist(msg.sender, onTopMaxAmnt, onTopMaxAmnt);
        ATBrandNew.addToWhitelist(communityVaultAddress, onTopMaxAmnt, onTopMaxAmnt);
        ATBrandNew.addToWhitelist(newW, onTopMaxAmnt, onTopMaxAmnt);
        ATBrandNew.removeWLManagers(address(this));

        customOwnable = Ownable(newAT);
        customOwnable.transferOwnership(msg.sender);

        // Should we change deployerLength with deployerLength - 1 (the actual index of the FSP)?
        emit NewPanelCreated(msg.sender, newAT, newT, newW, newFSP, deployerLength);

        return newFSPIndex;
    }


    /**
     * @notice Returns the number of campaign deployers
     * @return deployers uint256 The number of campaign deployers
     */
    function getTotalDeployers() external view returns(uint256) {
        return deployerList.length;
    }

    /**
     * @notice Returns the number of Admin Tools contracts
     * @return contracts uint256 The number of Admin Tools contracts
     */
    function getTotalATContracts() external view returns(uint256) {
        return ATContractsList.length;
    }

    /**
     * @notice Returns the number of Fund Tokens contracts
     * @return contracts uint256 The number of Fund Tokens contracts
     */
    function getTotalTContracts() external view returns(uint256) {
        return TContractsList.length;
    }

    /**
     * @notice Returns the number of Wrapper contracts
     * @return contracts uint256 The number of Wrapper contracts
     */
    function getTotalWContracts() external view returns(uint256) {
        return WContractsList.length;
    }

    /**
     * @notice Returns the number of FSP contracts
     * @return contracts uint256 The number of FSP contracts
     */
    function getTotalFSPContracts() external view returns(uint256) {
        return FSPContractsList.length;
    }

    /**
     * @notice Tells if an adress is a campaign deployer
     * @param _addr The address to check
     * @return isDeployer bool True if the address is a campaign deployer, false otherwise
     */
    function isFactoryDeployer(address _addr) external view returns(bool) {
        return deployers[_addr];
    }

    /**
     * @notice Tells if an address is an Admin Tools contract generated by the factory
     * @param _addr The address to check
     * @return isFactoryGenerated bool True if the address is an Admin Tools contract generated by the factory
     */
    function isFactoryATGenerated(address _addr) external view returns(bool) {
        return ATContracts[_addr];
    }

    /**
     * @notice Tells if an address is a Fund Token contract generated by the factory
     * @param _addr The address to check
     * @return isFactoryGenerated bool True if the address is a Fund Token contract generated by the factory
     */
    function isFactoryTGenerated(address _addr) external view returns(bool) {
        return TContracts[_addr];
    }

    /**
     * @notice Tells if an address is a Wrapper contract generated by the factory
     * @param _addr The address to check
     * @return isFactoryGenerated bool True if the address is a Wrapper contract generated by the factory
     */
    function isFactoryWGenerated(address _addr) external view returns(bool) {
        return WContracts[_addr];
    }

    /**
     * @notice Tells if an address is a Funding Single Panel contract generated by the factory
     * @param _addr The address to check
     * @return isFactoryGenerated bool True if the address is a Funding Single Panel contract generated by the factory
     */
    function isFactoryFSPGenerated(address _addr) external view returns(bool) {
        return FSPContracts[_addr];
    }

    /**
     * @notice Returns the context of a campaign
     * @param _index The campaign id
     * @return context A tuple containing the address of the deployer, the Admin Tools, the Fund Token, the Wrapper and the Funding Single Panel
     */
    function getContractsByIndex(uint256 _index) external view returns (address, address, address, address, address) {
        return (deployerList[_index], ATContractsList[_index], TContractsList[_index], WContractsList[_index], FSPContractsList[_index]);
    }

    /**
     * @notice Returns the address of the FSP related to the specified campaign
     * @param _index The campaign id
     * @return fspAddress address The address of the Funding Single Panel
     */
    function getFSPAddressByIndex(uint256 _index) external view returns (address) {
        return FSPContractsList[_index];
    }

    /**
     * @notice Returns the index of the FSP related to the specified address
     * @param _address The address of the FSP
     * @return campaignId uint256 The campaign id related to the FSP address
     */
    function getFSPIndexByAddress(address _address) external view returns (uint) {
        return FSPAddressToIndexMap[_address];
    }

    /**
     * @notice Returns the index of the Wrapper related to the specified campaign id
     * @param _index The campaign id
     * @return wrapper address The address of the Wrapper
     */
    function getWrapperByIndex(uint _index) external view returns (address) {
        return WContractsList[_index];
    }

    /**
     * @notice Returns the context of the factory
     * @return context A tuple containing the address of SEED, the Community Vault, the Cashback Vault and the block number in which the factory has been deployed
     */
    function getFactoryContext() external view returns (address, address, address, uint) {
        return (seedAddress, communityVaultAddress, cashbackAddress, factoryDeployBlock);
    }

}

//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

interface IWDeployer {
    function newWrapper(address, string calldata, string calldata, address) external returns(address);
    function setFactoryAddress(address) external;
    function getFactoryAddress() external view returns(address);
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

interface ITDeployer {
    function newToken(address, string calldata, string calldata, address/*, uint8*/) external returns(address);
    function setFactoryAddress(address) external;
    function getFactoryAddress() external view returns(address);
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

interface IFSPDeployer {
    function newFundingSinglePanel(address, address, address, uint256, address) external returns(address);
    function setFactoryAddress(address) external;
    function getFactoryAddress() external view returns(address);
}

//SPDX-License-Identifier:  GNU 3.0
pragma solidity ^0.7.6;

interface IERC20Seed {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

interface IATDeployer {
    function newAdminTools(uint256, uint256) external returns(address);
    function setFactoryAddress(address) external;
    function getFactoryAddress() external view returns(address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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