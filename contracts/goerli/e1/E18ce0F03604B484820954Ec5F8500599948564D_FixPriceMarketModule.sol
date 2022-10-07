// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IMarketModule} from '../../interfaces/markets/IMarketModule.sol';
import {IBardsHub} from '../../interfaces/IBardsHub.sol';
import {IBardsCurationBase} from '../../interfaces/curations/IBardsCurationBase.sol';
import {IProgrammableMinter} from '../../interfaces/minters/IProgrammableMinter.sol';
import {MarketModuleBase} from '../trades/MarketModuleBase.sol';
import {DataTypes} from '../../utils/DataTypes.sol';
import {Errors} from '../../utils/Errors.sol';
import {Constants} from '../../utils/Constants.sol';


/**
 * @title FixPriceMarketModule
 * 
 * @author Thebards Protocol
 * 
 * @notice This module allows sellers to list an owned ERC-721 token for sale for a given price in a given currency, 
 * and allows buyers to purchase from those asks.
 */
contract FixPriceMarketModule is MarketModuleBase, IMarketModule {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
	// tokenContract address -> tokenId -> market data
	mapping(address => mapping(uint256 => DataTypes.FixPriceMarketData)) internal _marketMetaData;

    constructor(
        address _hub, 
        address _royaltyEngine,
        address _stakingAddress
    ) {
        MarketModuleBase._initialize(_hub, _royaltyEngine, _stakingAddress);
    }

    /**
     * @notice Get market meta data.
     */
    function getMarketData(
        address tokenContract,
        uint256 tokenId
    ) 
        external 
        view
        returns (DataTypes.FixPriceMarketData memory)
    {
        return _marketMetaData[tokenContract][tokenId];
    }

	/** 
     * @notice See {IMarketModule-initializeModule}
     */
	function initializeModule(
		address tokenContract,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes memory) {
		(   
            address seller,
            address currency,
            uint256 price,
            address treasury,
            address minter
        ) = abi.decode(
            data, 
            (address, address, uint256, address, address)
        );

        if (!isCurrencyWhitelisted(currency)) revert Errors.CurrencyNotWhitelisted();
        if (price == 0) revert Errors.ZeroPrice();
        if (minter != address(0) && !bardsHub().isMinterModuleWhitelisted(minter))
            revert Errors.MinterModuleNotWhitelisted();
		
        _marketMetaData[tokenContract][tokenId].seller = seller;
        _marketMetaData[tokenContract][tokenId].price = price;
        _marketMetaData[tokenContract][tokenId].currency = currency;
        _marketMetaData[tokenContract][tokenId].treasury = treasury;
        _marketMetaData[tokenContract][tokenId].minter = minter;

        return data;
	}

	/**
     * @notice See {IMarketModule-collect}
     */
	function collect(
        address collector,
        uint256 curationId,
		address tokenContract,
        uint256 tokenId,
        uint256[] memory curationIds,
        bytes memory collectMetaData
    ) 
        external 
        override 
        returns (address, uint256)
    {
        // Royalty Payout + Protocol Fee + Curation Fees + staking fees + seller fees
        address _collector = collector;
        uint256 _curationId = curationId;
        // The price and currency of NFT.
        DataTypes.FixPriceMarketData memory marketData = _marketMetaData[tokenContract][tokenId];

        // Before core logic of  collecting, collect fees to a specific address, 
        // and pay royalties and protocol fees
        uint256 remainingProfit = _beforeCollecting(
            _collector,
            marketData.price, 
            marketData.currency,
            tokenContract,
            tokenId
        );

        // Transfer remaining ETH/ERC-20 to stakeholders.
        uint256 curationFee;
        if (_curationId != 0) {
            // curation meta data
            DataTypes.CurationStruct memory curationStruct = bardsHub().getCuration(_curationId);
            require(curationStruct.tokenContractPointed == tokenContract && curationStruct.tokenIdPointed == tokenId, "When Collecting in fix price market, NFT and curation mismatch");

            // 1) tokenContract == HUB, deal curation.
            // 2) tokenContract != HUB, deal token curated, but using curationBps and stakingBps in curation.

            // The fee split setting of curation.
		    DataTypes.CurationData memory curationData = IBardsCurationBase(HUB).curationDataOf(_curationId);

            // collect curation
            curationFee = remainingProfit.mul(uint256(curationData.curationBps)).div(Constants.MAX_BPS);
            remainingProfit -= curationFee;
            _handleCurationsPayout(
                tokenContract, 
                tokenId,
                curationFee,
                marketData.currency,
                curationIds
            );
            // collect staking
            uint256 stakingFee = remainingProfit.mul(uint256(curationData.stakingBps)).div(Constants.MAX_BPS);
            remainingProfit -= stakingFee;
            _handleStakingPayout(
                _curationId,
                marketData.currency,
                stakingFee
            );

            // payout for sellers
            _handleSellersSplitPayout(
                tokenContract, 
                tokenId,
                remainingProfit,
                marketData.currency,
                _curationId
            );

        } else {
            // Just listed on the Decentralized Market, not curated.
            // using default curation and staking bps setting.

            require(tokenContract != HUB, "Collecting non-HUB NFTs");
            // payout curation
            curationFee = remainingProfit.mul(uint256(getDefaultCurationBps())).div(Constants.MAX_BPS);
            remainingProfit -= curationFee;
            _handleCurationsPayout(
                tokenContract, 
                tokenId,
                curationFee,
                marketData.currency,
                curationIds
            );

            _handlePayout(
                marketData.treasury, 
                remainingProfit, 
                marketData.currency, 
                Constants.USE_ALL_GAS_FLAG
            );
        }
        
        (
            address retTokenContract,
            uint256 retTokenId
        ) = IProgrammableMinter(marketData.minter).mint(
            collectMetaData
        );

        delete _marketMetaData[tokenContract][tokenId];

        return (retTokenContract, retTokenId);
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {DataTypes} from '../utils/DataTypes.sol';

/**
 * @title IBardsHub
 * @author TheBards Protocol
 * 
 * @notice This is the interface for the TheBards contract, the main entry point for the TheBards Protocol.
 */
interface IBardsHub {

	// -- Governance --

	/**
     * @notice Initializes the TheBards NFT, setting the initial governance address as well as the name and symbol in
     * the BardsNFTBase contract.
     *
     * @param name The name to set for the hub NFT.
     * @param symbol The symbol to set for the hub NFT.
     * @param newGovernance The governance address to set.
     * @param cooldownBlocks Number of blocks to set the curation parameters cooldown period
     */
    function initialize(
        string calldata name,
        string calldata symbol,
        address newGovernance,
        uint32 cooldownBlocks
    ) external;

    /**
     * @notice Sets the privileged governance role. This function can only be called by the current governance
     * address.
     *
     * @param newGovernance The new governance address to set.
     */
    function setGovernance(address newGovernance) 
		  external;

    /**
     * @notice Sets the emergency admin, which is a permissioned role able to set the protocol state. This function
     * can only be called by the governance address.
     *
     * @param newEmergencyAdmin The new emergency admin address to set.
     */
    function setEmergencyAdmin(address newEmergencyAdmin) 
		  external;

    /**
     * @notice Set the time in blocks an curator needs to wait to change curation parameters.
     * @param _blocks Number of blocks to set the curation parameters cooldown period
     */
    function setCooldownBlocks(uint32 _blocks) 
		  external;

	/**
     * @notice Sets the protocol state to either a global pause, a publishing pause or an unpaused state. This function
     * can only be called by the governance address or the emergency admin address.
     *
     * Note that this reverts if the emergency admin calls it if:
     *      1. The emergency admin is attempting to unpause.
     *      2. The emergency admin is calling while the protocol is already paused.
     *
     *   ########################################################
     *   ##                 Unpaused | Paused | CurationPaused ##
     *   ## governance     |   yes   |   yes  |      yes       ##
     *   ## emergency admin|   no    |   yes  |      yes       ##
     *   ## other          |   no    |   no   |      no        ##
     *   ########################################################
     *
     * @param newState The state to set, as a member of the ProtocolState enum.
     */
    function setState(DataTypes.ProtocolState newState) 
		external;

    /**
    * @notice Updates a curation with the specified parameters. 
    */
	  function updateCuration(DataTypes.InitializeCurationData memory _vars) external;

    // /**
    //  * @notice Sets the sellerFundsRecipients of the sellers for a NFT
    //  * 
    //  * @param tokenId The token Id of the NFT to set fee params.
    //  * @param sellerFundsRecipients The bpses of seller funds
    //  */
    // function setSellerFundsRecipientsParams(uint256 tokenId, address[] calldata sellerFundsRecipients) external;

    // /**
    //  * @notice Sets the curationFundsRecipients of the sellers for a NFT
    //  * 
    //  * @param tokenId The token Id of the NFT to set fee params.
    //  * @param curationFundsRecipients The bpses of curation funds
    //  */
    // function setCurationFundsRecipientsParams(uint256 tokenId, uint256[] calldata curationFundsRecipients) external;


  //   /**
  //    * @notice Sets the fee that is sent to the sellers for a NFT
  //    * 
  //    * @param tokenId The token Id of the NFT to set fee params.
  //    * @param sellerFundsBpses The fee that is sent to the sellers.
  //    */
  //   function setSellerFundsBpsesParams(uint256 tokenId, uint32[] calldata sellerFundsBpses) external;

  //   /**
  //    * @notice Sets the fee that is sent to the curation for a NFT
  //    * 
  //    * @param tokenId The token Id of the NFT to set fee params.
  //    * @param curationFundsBpses The fee that is sent to the curations.
  //    */
  //   function setCurationFundsBpsesParams(uint256 tokenId, uint32[] calldata curationFundsBpses) external;

	// /**
  //    * @notice Sets fee parameters for a NFT
	//  *
  //    * @param tokenId The token Id of the NFT to set fee params.
  //    * @param curationBps The bps of curation
  //    * @param stakingBps The bps of staking
  //    */
  //   function setBpsParams(uint256 tokenId, uint32 curationBps, uint32 stakingBps) external;

	/**
     * @notice Adds or removes a market module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param marketModule The market module contract address to add or remove from the whitelist.
     * @param whitelist Whether or not the market module should be whitelisted.
     */
    function whitelistMarketModule(address marketModule, bool whitelist) 
		external;

  	/**
     * @notice Adds or removes a mint module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param minterModule The mint module contract address to add or remove from the whitelist.
     * @param whitelist Whether or not the mint module should be whitelisted.
     */
    function whitelistMinterModule(address minterModule, bool whitelist) 
		external;

	/**
     * @notice Adds or removes a profile creator from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param profileCreator The profile creator address to add or remove from the whitelist.
     * @param whitelist Whether or not the profile creator should be whitelisted.
     */
    function whitelistProfileCreator(address profileCreator, bool whitelist) 
		external;

	// -- Registry --

    /**
     * @notice Register contract id and mapped address
     * @param _id Contract id (keccak256 hash of contract name)
     * @param _contractAddress Contract address
     */
    function registerContract(bytes32 _id, address _contractAddress) external;

    /**
     * @notice Unregister a contract address
     * @param _id Contract id (keccak256 hash of contract name)
     */
    function unsetContract(bytes32 _id) external;

    /**
     * @notice Get contract registered address by its id
     * @param _id Contract id
     */
    function getContractAddressRegistered(bytes32 _id) external view returns (address);

	// -- Pausing --

	// -- Epoch Manage --

	// -- Reward Manage --

	// -- cruation funtions --
	/**
     * @notice Creates a profile with the specified parameters, minting a self curation as NFT to the given recipient.
     *
     * @param vars A CreateCurationData struct containing the needed parameters.
     *
     * @return uint256 An integer representing the profile's token ID.
     */
    function createProfile(DataTypes.CreateCurationData calldata vars) 
		external 
		returns (uint256);

    // /**
    //  * @notice Creates a profile with the specified parameterse via signature with the specified parameters.
    //  *
    //  * @param vars A CreateCurationWithSigData struct containing the regular parameters and an EIP712Signature struct.
    //  *
    //  * @return uint256 An integer representing the profile's token ID.
    //  */
    // function createProfileWithSig(DataTypes.CreateCurationWithSigData calldata vars) 
    // external 
    // returns (uint256);

    /**
     * @notice Sets the mapping between wallet and its main profile identity.
     *
     * @param profileId The token ID of the profile to set as the main profile identity.
     */
    function setDefaultProfile(uint256 profileId) 
		external;

    /**
     * @notice Sets the mapping between curation Id and its allocation ID.
     *
     * @param vars A SetAllocationIdData struct, including the regular parameters
     */
    function setAllocationId(DataTypes.SetAllocationIdData calldata vars) 
		external;

    /**
     * @notice Sets the mapping between curation Id and its allocation ID via signature with the specified parameters.
     *
     * @param vars A SetAllocationIdWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setAllocationIdWithSig(DataTypes.SetAllocationIdWithSigData calldata vars) 
		external;

    /**
     * @notice Sets the mapping between wallet and its main profile identity via signature with the specified parameters.
     *
     * @param vars A SetDefaultProfileWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setDefaultProfileWithSig(DataTypes.SetDefaultProfileWithSigData calldata vars)
        external;

    /**
     * @notice Sets a curation's content URI.
     *
     * @param curationId The token ID of the curation to set the URI for.
     * @param contentURI The URI to set for the given curation.
     */
    function setCurationContentURI(uint256 curationId, string calldata contentURI) external;

    /**
     * @notice Sets a curation's content URI via signature with the specified parameters.
     *
     * @param vars A SetCurationContentURIWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setCurationContentURIWithSig(DataTypes.SetCurationContentURIWithSigData calldata vars)
        external;

	    /**
     * @notice Sets a curation's market module, must be called by the curator.
     *
     * @param vars The SetMarketModuleData struct containing the following parameters:
     *   curationId The token ID of the profile to set the market module for.
     *   tokenContract The address of NFT token to curate.
     *   tokenId The NFT token ID to curate.
     *   marketModule The market module to set for the given curation, must be whitelisted.
     *   marketModuleInitData The data to be passed to the market module for initialization.
     */
    function setMarketModule( 
        DataTypes.SetMarketModuleData calldata vars
    ) external;

    /**
     * @notice Sets a curation's market module via signature with the specified parameters.
     *
     * @param vars A SetMarketModuleWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setMarketModuleWithSig(DataTypes.SetMarketModuleWithSigData calldata vars) 
		external;

	    /**
     * @notice Sets a curation's mint module, must be called by the curator.
     *
     * @param vars The SetMarketModuleData struct containing the following parameters:
     *   curationId The token ID of the profile to set the mint module for.
     *   tokenContract The address of NFT token to curate.
     *   tokenId The NFT token ID to curate.
     *   marketModule The mint module to set for the given curation, must be whitelisted.
     *   marketModuleInitData The data to be passed to the mint module for initialization.
     */
    function setMinterMarketModule( 
        DataTypes.SetMarketModuleData calldata vars
    ) external;

    /**
     * @notice Sets a curation's mint module via signature with the specified parameters.
     *
     * @param vars A SetMarketModuleWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setMinterMarketModuleWithSig(DataTypes.SetMarketModuleWithSigData calldata vars) 
		external;

    /**
     * @notice Creates a curation to a given profile, must be called by the profile owner.
     *
     * @param vars A CreateCurationData struct containing the needed parameters.
     *
     * @return uint256 An integer representing the curation's token ID.
     */
    function createCuration(DataTypes.CreateCurationData calldata vars) external returns (uint256);

    /**
     * @notice Adds or removes a currency from the whitelist. This function can only be called by governance.
     *
     * @param currency The currency to add or remove from the whitelist.
     * @param toWhitelist Whether to add or remove the currency from the whitelist.
     */
    function whitelistCurrency(address currency, bool toWhitelist) external;

    /**
     * @notice Creates a curation via signature with the specified parameters.
     *
     * @param vars A CreateCurationWithSigData struct containing the regular parameters and an EIP712Signature struct.
     *
     * @return uint256 An integer representing the curation's token ID.
     */
    function createCurationWithSig(
      DataTypes.CreateCurationWithSigData calldata vars
    ) external returns (uint256);

    /**
     * @notice Collects a given curation, executing market module logic and transfering curation to the caller.
     *
     * @param vars A SimpleDoCollectData struct containing the regular parameters as well as the collector's address and
     * an EIP712Signature struct.
     *
     * @return (addresss, uint256) An  address and integer pair representing the minted token ID.
     */
    function collect(
      DataTypes.SimpleDoCollectData calldata vars
    ) external returns (address, uint256);

    /**
     * @notice Collects a given curation via signature with the specified parameters.
     *
     * @param vars A CollectWithSigData struct containing the regular parameters as well as the collector's address and
     * an EIP712Signature struct.
     *
     * @return (addresss, uint256) An  address and integer pair representing the minted token ID.
     */
    function collectWithSig(
      DataTypes.DoCollectWithSigData calldata vars
    ) external returns (address, uint256);

    /// ************************
    /// *****VIEW FUNCTIONS*****
    /// ************************

    /**
     * @notice Returns whether `spender` is allowed to manage things for `curator`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * 
     * @param operator The address of operator
     * @param curator The address of curation.
     */
    function isAuthForCurator(address operator, address curator)
      external
      view
      returns (bool);

    /**
     * @notice Returns whether or not a profile creator is whitelisted.
     *
     * @param profileCreator The address of the profile creator to check.
     *
     * @return bool True if the profile creator is whitelisted, false otherwise.
     */
    function isProfileCreatorWhitelisted(address profileCreator) 
		external 
		view 
		returns (bool);

    /**
     * @notice Returns default profile for a given wallet address
     *
     * @param wallet The address to find the default mapping
     *
     * @return uint256 The default profile id, which will be 0 if not mapped.
     */
    function defaultProfile(address wallet) 
		external 
		view 
		returns (uint256);

    /**
     * @notice Returns whether or not a market module is whitelisted.
     *
     * @param marketModule The address of the market module to check.
     *
     * @return bool True if the the market module is whitelisted, false otherwise.
     */
    function isMarketModuleWhitelisted(address marketModule) 
		external 
		view 
		returns (bool);

    /**
     * @notice Returns whether or not a mint module is whitelisted.
     *
     * @param minterModule The address of the mint module to check.
     *
     * @return bool True if the the mint module is whitelisted, false otherwise.
     */
    function isMinterModuleWhitelisted(address minterModule) 
		external 
		view 
		returns (bool);

    /**
     * @notice Returns whether a currency is whitelisted.
     *
     * @param currency The currency to query the whitelist for.
     *
     * @return bool True if the queried currency is whitelisted, false otherwise.
     */
    function isCurrencyWhitelisted(address currency) external view returns (bool);

    /**
     * @notice Returns the currently configured governance address.
     *
     * @return address The address of the currently configured governance.
     */
    function getGovernance() 
		external 
		view 
		returns (address);
    
	/**
     * @notice Returns the market module associated with a given curation.
     *
     * @param curationId The token ID of the profile that published the curation to query.
     *
     * @return address The address of the market module associated with the queried curation.
     */
    function getMarketModule(uint256 curationId) 
		external 
		view 
		returns (address);

	/**
     * @notice Returns the minter market module associated with a given curation.
     *
     * @param curationId The token ID of the profile that published the curation to query.
     *
     * @return address The address of the mint module associated with the queried curation.
     */
    function getMinterMarketModule(uint256 curationId) 
		external 
		view 
		returns (address);

	/**
     * @notice Returns the handle associated with a profile.
     *
     * @param profileId The token ID of the profile to query the handle for.
     *
     * @return string The handle associated with the profile.
     */
    function getHandle(uint256 profileId) 
		external 
		view 
		returns (string memory);

	    /**
     * @notice Returns the URI associated with a given curation.
     *
     * @param curationId The token ID of the curation to query.
     *
     * @return string The URI associated with a given publication.
     */
    function getContentURI(uint256 curationId) 
		external 
		view 
		returns (string memory);

    /**
     * @notice Returns the profile token ID according to a given handle.
     *
     * @param handle The handle to resolve the profile token ID with.
     *
     * @return uint256 The profile ID the passed handle points to.
     */
    function getProfileIdByHandle(string calldata handle) 
		external 
		view 
		returns (uint256);

    /**
     * @notice Returns the full profile struct associated with a given profile token ID.
     *
     * @param profileId The token ID of the profile to query.
     *
     * @return ProfileStruct The profile struct of the given profile.
     */
    function getProfile(uint256 profileId) 
		external 
		view 
		returns (DataTypes.CurationStruct memory);

    /**
     * @notice Returns the full curationId struct.
     *
     * @param curationId The token ID of the curation to query.
     *
     * @return CurationStruct The curation struct associated with the queried curation.
     */
    function getCuration(uint256 curationId)
        external
        view
        returns (DataTypes.CurationStruct memory);

    /**
     * @notice Returns the allocation Id.
     *
     * @param curationId The token ID of the curation to query.
     *
     * @return allocationId The allocation ID associated with the queried curation.
     */
    function getAllocationIdById(uint256 curationId)
        external
        view
        returns (uint256);

    /**
     * @notice remove allocations in _isToBeClaimedByAllocByCurator.
     */
    function removeAllocation(
        address curator, 
        uint256 allocationId
    ) external;

}

// SPDX-License-Identifier: MIT

import {IBardsStaking} from '../interfaces/tokens/IBardsStaking.sol';

pragma solidity ^0.8.12;

/**
 * @title DataTypes
 * @author TheBards Protocol
 *
 * @notice A standard library of data types used throughout the bards Protocol.
 */
library DataTypes {

	enum ContentType {
		Microblog,
        Article,
        Audio,
        Video
	}

	enum CurationType {
		Profile,
        Content,
        Combined,
        Protfolio,
        Feed,
        Dapp
	}

    /**
     * @notice An enum containing the different states the protocol can be in, limiting certain actions.
     *
     * @param Unpaused The fully unpaused state.
     * @param CurationPaused The state where only curation creation functions are paused.
     * @param Paused The fully paused state.
     */
    enum ProtocolState {
        Unpaused,
        CurationPaused,
        Paused
    }

    /**
     * @notice A struct containing the necessary information to reconstruct an EIP-712 typed data signature.
     *
     * @param v The signature's recovery parameter.
     * @param r The signature's r parameter.
     * @param s The signature's s parameter
     * @param deadline The signature's deadline
     */
    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    /**
     * @notice Contains the owner address and the mint timestamp for every NFT.
     *
     * Note: Instead of the owner address in the _tokenOwners private mapping, we now store it in the
     * _tokenData mapping, alongside the unchanging mintTimestamp.
     *
     * @param owner The token owner.
     * @param mintTimestamp The mint timestamp.
     */
    struct TokenData {
        address owner;
        uint96 mintTimestamp;
    }

    /**
     * A struct containing the parameters required for the `permit` function of bardsCurationToken.
     * @param owner The address of the owner of token.
     * @param spender The address of the spender who will be approved.
     * @param value The token amount.
     */
    struct BCTPermitData{
        address owner;
        address spender;
        uint256 value;
    }

    /**
     * A struct containing the parameters required for the `permitWithSig` function of bardsCurationToken.
     * @param owner The address of the owner of token.
     * @param spender The address of the spender who will be approved.
     * @param value The token amount.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct BCTPermitWithSigData{
        address owner;
        address spender;
        uint256 value;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `SetAllocationIdData()` function. 
     *
     * @param curationId The token ID of the curation.
     * @param allocationId The allocation id.
     * @param curationMetaData The encoding of curation Data.
     * @param stakeToCuration The curation Id restake to
     */
    struct SetAllocationIdData {
        uint256 curationId;
        uint256 allocationId;
        bytes curationMetaData;
        uint256 stakeToCuration; 
    }

    /**
     * @notice A struct containing the parameters required for the `setAllocationIdWithSig()` function. Parameters are
     * the same as the regular `setAllocationId()` function, with an added EIP712Signature.
     *
     * @param curationId The token ID of the curation.
     * @param allocationId The address of the allocation.
     * @param curationMetaData The encoding of curation Data.
     * @param stakeToCuration The curation Id restake to
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetAllocationIdWithSigData {
        uint256 curationId;
        uint256 allocationId;
        bytes curationMetaData;
        uint256 stakeToCuration;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setDefaultProfileWithSig()` function. Parameters are
     * the same as the regular `setDefaultProfile()` function, with an added EIP712Signature.
     *
     * @param wallet The address of the wallet setting the default profile.
     * @param profileId The token ID of the profile which will be set as default, or zero.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetDefaultProfileWithSigData {
        address wallet;
        uint256 profileId;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setMarketModule()` function.
     *
     * @param curationId The token ID of the curation to change the marketModule for.
	 * @param tokenContract The address of NFT token to curate.
     * @param tokenId The NFT token ID to curate.
     * @param marketModule The marketModule to set for the given curation, must be whitelisted.
     * @param marketModuleInitData The data to be passed to the marketModule for initialization.
     */
    struct SetMarketModuleData {
        uint256 curationId;
        address tokenContract;
        uint256 tokenId;
        address marketModule;
        bytes marketModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `setMarketModuleWithSig()` function. Parameters are
     * the same as the regular `setMarketModule()` function, with an added EIP712Signature.
     *
     * @param curationId The token ID of the curation to change the marketModule for.
	 * @param tokenContract The address of NFT token to curate.
     * @param tokenId The NFT token ID to curate.
     * @param marketModule The marketModule to set for the given curation, must be whitelisted.
     * @param marketModuleInitData The data to be passed to the marketModule for initialization.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetMarketModuleWithSigData {
        uint256 curationId;
        address tokenContract;
        uint256 tokenId;
        address marketModule;
        bytes marketModuleInitData;
        EIP712Signature sig;
    }

    /**
     * @notice Contains the curation BPS and staking BPS for every Curation.
     *
	 * @param sellerFundsRecipients The addresses where funds are sent after the trade.
	 * @param curationFundsRecipients The curation Id where funds are sent after the trade.
	 * @param sellerFundsBpses The fee percents that is sent to the sellers.
	 * @param curationFundsBpses The fee percents that is sent to the curation.
	 * @param curationBps The points fee of willing to share of the NFT income to curators.
	 * @param stakingBps The points fee of willing to share of the NFT income to delegators who staking tokens.
     * @param updatedAtBlock Period that need to pass to update curation data parameters
     */
    struct CurationData {
        address[] sellerFundsRecipients;
        uint256[] curationFundsRecipients;
		uint32[] sellerFundsBpses;
        uint32[] curationFundsBpses;
		uint32 curationBps;
		uint32 stakingBps;
        uint256 updatedAtBlock;
    }

    /**
     * @notice A struct containing the parameters required for the `createCuration()` function.
     *
     * @param tokenId The token id.
     * @param curationData The data of CurationData curation.
     */
    struct InitializeCurationData {
        uint256 tokenId;
        bytes curationData;
    }

    /**
     * @notice The metadata for a free market.
     * @param seller The seller of nft
     * @param minter The programmable minter module.
     */
    struct FreeMarketData {
        address seller;
        address minter;
    }

    /**
     * @notice The metadata for a fix price market.
     * @param seller The seller of nft
     * @param currency The currency to ask.
     * @param price The fix price of nft.
     * @param treasury The recipient of the fee
     * @param minter The programmable minter module.
     */
    struct FixPriceMarketData {
        address seller;
        address currency;
        uint256 price;
        address treasury;
        address minter;
    }

    /**
     * @notice The metadata of a protocol fee setting
     * @param feeBps The basis points fee
     * @param treasury The recipient of the fee
     * @param curationBps The default points fee of willing to share of the NFT income to curators.
	 * @param stakingBps The default points fee of willing to share of the NFT income to delegators who staking tokens.
     */
    struct ProtocolFeeSetting {
        uint32 feeBps;
        address treasury;
        uint32 defaultCurationBps;
		uint32 defaultStakingBps;
    }

    /**
     * @notice A struct containing data associated with each new Content Curation.
     *
     * @param curationType The Type of curation.
     * @param handle The profile's associated handle.
       @param tokenContractPointed The token contract address this curation points to, default is the bards hub.
     * @param tokenIdPointed The token ID this curation points to.
     * @param contentURI The URI associated with this publication.
     * @param marketModule The address of the current market module in use by this curation to trade itself, can be empty.
     * @param minterMarketModule The address of the current mint market module in use by this curation. 
     * @param curationFrom The curation Id that this curation minted from.
     * Make sure each curation can mint its own NFTs. minterMarketModule is marketModule, but the initialization parameters are different.
     */
    struct CurationStruct {
        CurationType curationType;
        string handle;
        address tokenContractPointed;
        uint256 tokenIdPointed;
        string contentURI;
        address marketModule;
        address minterMarketModule;
        uint256 allocationId;
        uint256 curationFrom;
    }

    /**
     * @notice A struct containing the parameters required for the `setCurationContentURIWithSig()` function. Parameters are the same
     * as the regular `setCurationContentURI()` function, with an added EIP712Signature.
     *
     * @param curationId The token ID of the curation to set the URI for.
     * @param contentURI The URI to set for the given curation.
     * @param sig The EIP712Signature struct containing the curation owner's signature.
     */
    struct SetCurationContentURIWithSigData {
        uint256 curationId;
        string contentURI;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the paramters required for the `collect` function.
     * 
     * @param curationId The token ID of the curation being collected's parent profile.
     * @param curationIds A array of curation IDs sharing trade fees.
     * @param collectMetaData The meta data for collecting.
     * @param fromCuration Whether to mint from scratch in curation.
     * 
     */
    struct SimpleDoCollectData {
        uint256 curationId;
        uint256[] curationIds;
        bytes collectMetaData;
        bool fromCuration;
    }

    /**
     * @notice A struct containing the paramters required for the `_collect` function.
     * 
     * @param collector The address executing the collect.
     * @param curationId The token ID of the curation being collected's parent profile.
     * @param curationIds A array of curation IDs sharing trade fees.
     * @param collectMetaData The meta data for collecting.
     * @param fromCuration Whether to mint from scratch in curation.
     * 
     */
    struct DoCollectData {
        address collector;
        uint256 curationId;
        uint256[] curationIds;
        bytes collectMetaData;
        bool fromCuration;
    }

    /**
     * @notice A struct containing the paramters required for the `collectWithSig` function.
     * 
     * @param collector The address executing the collect.
     * @param curationId The token ID of the curation being collected's parent profile.
     * @param curationIds A array of curation IDs sharing trade fees.
     * @param collectMetaData The meta data for collecting.
     * @param fromCuration Whether to mint from scratch in curation.
     * @param sig
     */
    struct DoCollectWithSigData {
        address collector;
        uint256 curationId;
        uint256[] curationIds;
        bytes collectMetaData;
        bool fromCuration;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the paramters required for the `collect` function.
     * 
     * @param collector The address executing the collect.
     * @param curationId The token ID of the curation being collected's parent profile.
     * @param tokenContract The address of token.
     * @param tokenId The token id.
     * @param curationIds A array of curation IDs sharing trade fees.
     * @param collectMetaData The meta data for collecting.
     * 
     */
    struct MarketCollectData {
        address collector;
        uint256 curationId;
        address tokenContract;
        uint256 tokenId;
        uint256[] curationIds;
        bytes collectMetaData;
    }

    /**
     * @notice A struct containing the parameters required for the `createProfile()` and `creationCuration` function.
     *
     * @param to The address receiving the curation.
     * @param curationType The Type of curation.
     * @param profileId the profile id creating the curation.
     * @param curationId the curation ID.
     * @param tokenContractPointed The token contract address this curation points to, default is the bards hub.
     * @param tokenIdPointed The token ID this curation points to.
     * @param handle The handle to set for the profile, must be unique and non-empty.
     * @param contentURI The URI to set for the profile metadata.
     * @param marketModule The market module to use, can be the zero address to trade itself.
     * @param marketModuleInitData The market module initialization data, if any.
     * @param minterMarketModule The minter market module to use, can be the zero address. Make sure each curation can mint its own NFTs.
     * minterMarketModule is marketModule, but the initialization parameters are different.
     * @param minterMarketModuleInitData The minter market module initialization data, if any.
     * @param curationMetaData The data of CurationData struct.
     * @param curationFrom The curation Id that this curation minted from.
     */
    struct CreateCurationData {
        address to;
        CurationType curationType;
        uint256 profileId;
        uint256 curationId;
        address tokenContractPointed;
        uint256 tokenIdPointed;
        string handle;
        string contentURI;
        address marketModule;
        bytes marketModuleInitData;
        address minterMarketModule;
        bytes minterMarketModuleInitData;
        bytes curationMetaData;
        uint256 curationFrom;
    }

    /**
     * @notice A struct containing the parameters required for the `createProfile()` and `creationCuration` function.
     *
     * @param curationType The Type of curation.
     * @param profileId the profile id creating the curation
     * @param curationId the curation ID.
     * @param tokenContractPointed The token contract address this curation points to, default is the bards hub.
     * @param tokenIdPointed The token ID this curation points to.
     * @param handle The handle to set for the profile, must be unique and non-empty.
     * @param contentURI The URI to set for the profile metadata.
     * @param marketModule The market module to use, can be the zero address to trade itself.
     * @param marketModuleInitData The market module initialization data, if any.
     * @param minterMarketModule The minter market module to use, can be the zero address. Make sure each curation can mint its own NFTs.
     * minterMarketModule is marketModule, but the initialization parameters are different.
     * @param minterMarketModuleInitData The minter market module initialization data, if any.
     * @param curationMetaData The data of CurationData struct.
     * @param curationFrom The curation Id that this curation minted from.
     * @param sig
     */
    struct CreateCurationWithSigData {
        CurationType curationType;
        uint256 profileId;
        uint256 curationId;
        address tokenContractPointed;
        uint256 tokenIdPointed;
        string handle;
        string contentURI;
        address marketModule;
        bytes marketModuleInitData;
        address minterMarketModule;
        bytes minterMarketModuleInitData;
        bytes curationMetaData;
        uint256 curationFrom;
        EIP712Signature sig;
    }

    /**
     * @notice Possible states an allocation can be
     * States:
     * - Null = indexer == address(0)
     * - Active = not Null && tokens > 0
     * - Closed = Active && closedAtEpoch != 0
     * - Finalized = Closed && closedAtEpoch + channelDisputeEpochs > now()
     * - Claimed = not Null && tokens == 0
     */
    enum AllocationState {
        Null,
        Active,
        Closed,
        Finalized,
        Claimed
    }

    /**
     * @notice A struct containing the parameters required for the multi-currency fees earned.
     * 
     * @param totalShare Total share during the fees pool's epoch
     * @param currencies The currencies of tokens.
     * @param fees Fees earned, currency -> amount.
     */
    struct MultiCurrencyFees{
        uint256 totalShare;
        address[] currencies;
        mapping (address => uint256) fees;
    }

    /**
     * @notice A struct containing the parameters required for the staking module.
     * 
     * @param tokens BCT Tokens stored as reserves for the curation.
     * @param fees fees earned excluding BCT, which can be withdrawn without thawing period, epoch -> MultiCurrencyFees.
     * @param reserveRatio Ratio for the bonding curve.
     * @param bst Curation token contract for this curation staking pool.
     * @param shares Shares minted totally.
     * @param delegators All delegators.
     */
    struct CurationStakingPool {
        uint256 tokens;
        uint32 reserveRatio;
        address bst;
        uint256 shares;
        mapping(uint256 => MultiCurrencyFees) fees;
        mapping(address => Delegation) delegators;
    }

    /**
     * @notice Individual delegation data of a delegator in a pool. 
     * Will auto-withdraw before updating shares.
     * 
     * @param tokens tokens be staked in curation by delegator.
     * @param shares Shares owned by a delegator in the pool
     * @param tokensLocked Tokens locked for undelegation
     * @param tokensLockedUntil Block when locked tokens can be withdrawn
     * @param lastWithdrawFeesEpoch The last withdraw fees Epoch.
     */
    struct Delegation {
        uint256 shares;
        uint256 tokensLocked;
        uint256 tokensLockedUntil;
        uint256 lastWithdrawFeesEpoch;
    }

    /**
     * @notice Stores accumulated rewards and snapshots related to a particular Curation.
     * 
     * @param accRewardsForCuration Accumulated rewards for curation 
     * @param accRewardsForCurationSnapshot Accumulated rewards for curation snapshot
     * @param accRewardsPerStakingSnapshot Accumulated rewards per staking for curation snapshot
     * @param accRewardsPerAllocatedToken Accumulated rewards per allocated token.
     */
    struct CurationReward {
        uint256 accRewardsForCuration;
        uint256 accRewardsForCurationSnapshot;
        uint256 accRewardsPerStakingSnapshot;
        uint256 accRewardsPerAllocatedToken;
    }

    /**
     * @notice Allocate tokens for the purpose of curation fees and rewards.
     * An allocation is created in the allocate() function and consumed in claim()
     * 
     * @param curator The address of curator.
     * @param curationId curation Id
     * @param recipientsMeta The snapshot of recipients from curationData.
     * @param createdAtEpoch Epoch when it was created
     * @param closedAtEpoch Epoch when it was closed
     * @param collectedFees Collected fees for the allocation
     * @param effectiveAllocationStake Effective allocation when closed
     * @param accRewardsPerAllocatedToken Snapshot used for reward calc
     */
    struct Allocation {
        address curator;
        uint256 curationId;
        bytes recipientsMeta;
        // uint256 tokens;
        uint256 createdAtEpoch;
        uint256 closedAtEpoch;
        MultiCurrencyFees collectedFees;
        uint256 effectiveAllocationStake;
        uint256 accRewardsPerAllocatedToken;
    }

    /**
     * @notice Allocate tokens for the purpose of curation fees and rewards.
     * An allocation is created in the allocate() function and consumed in claim()
     * 
     * @param curator The address of curator.
     * @param curationId curation Id
     * @param recipientsMeta The snapshot of recipients from curationData.
     * @param tokens Tokens allocated to a curation, currency => tokens
     * @param createdAtEpoch Epoch when it was created
     * @param closedAtEpoch Epoch when it was closed
     * @param effectiveAllocationStake Effective allocation when closed
     * @param accRewardsPerAllocatedToken Snapshot used for reward calc
     */
    struct SimpleAllocation {
        address curator;
        uint256 curationId;
        bytes recipientsMeta;
        uint256 tokens;
        uint256 createdAtEpoch;
        uint256 closedAtEpoch;
        uint256 effectiveAllocationStake;
        uint256 accRewardsPerAllocatedToken;
    }

    /**
     * @notice Tracks stats for allocations closed on a particular epoch for claiming.
     * The pool also keeps tracks of total fees collected and stake used.
     * Only one rebate pool exists per epoch
     * 
     * @param fees total trade fees in the rebate pool
     * @param effectiveAllocationStake total effective allocation of stake
     * @param claimedRewards total claimed rewards from the rebate pool
     * @param unclaimedAllocationsCount amount of unclaimed allocations
     * @param alphaNumerator numerator of `alpha` in the cobb-douglas function
     * @param alphaDenominator denominator of `alpha` in the cobb-douglas function
     */
    struct RebatePool {
        MultiCurrencyFees fees;
        mapping (address => uint256) effectiveAllocationStake;
        MultiCurrencyFees claimedRewards;
        uint32 unclaimedAllocationsCount;
        uint32 alphaNumerator;
        uint32 alphaDenominator;
    }

    /**
     * @notice The struct for creating allocate
     * 
     * @param allocationId The allocation Id.
     * @param curator The address of curator.
     * @param curationId Curation Id.
     * @param recipientsMeta The snapshot of recipients from curationData.
     * 
     */
    struct CreateAllocateData {
        uint256 allocationId;
        address curator;
        uint256 curationId;
        bytes recipientsMeta;
    }

    struct UpdateCurationDataParamsData {
        address owner;
        uint256 tokenId;
        uint256 newAllocationId;
        uint32 minimalCooldownBlocks;
        IBardsStaking bardsStaking;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library Errors {
	error CannotInitImplementation();
    error Initialized();
    error SignatureExpired();
    error ZeroSpender();
    error ZeroPrice();
    error ZeroAddress();
    error SignatureInvalid();
    error NotOwnerOrApproved();
    error NotHub();
    error TokenDoesNotExist();
    error NotGovernance();
    error NotGovernanceOrEmergencyAdmin();
    error EmergencyAdminCannotUnpause();
    error CallerNotWhitelistedModule();
    error MarketModuleNotWhitelisted();
    error MinterModuleNotWhitelisted();
    error CurrencyNotWhitelisted();
    error ProfileCreatorNotWhitelisted();
    error NotOwner();
    error CurationDoesNotExist();
    error HandleToken();
    error HandleLengthInvalid();
    error HandleContainsInvalidCharacters();
    error HandleFirstCharInvalid();
    error BlockNumberInvalid();
    error ArrayMismatch();
    error NotWhitelisted();
    error CurationContentURILengthInvalid();
    error NoAllowance();
    error AllocationExists();
    error ZeroAllocationId();

    // Market Errors
    error InitParamsInvalid();
    error MarketZeroAddress();
    error CollectExpired();
    error ModuleDataMismatch();
    error MintLimitExceeded();
    error TradeNotAllowed();

    // Pausable Errors
    error Paused();
    error CurationPaused();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library Constants{
	uint32 constant MAX_BPS = 1000000;
	uint8 constant MAX_HANDLE_LENGTH = 31;
	// The indicator to pass all remaining gas when paying out royalties
    uint256 constant USE_ALL_GAS_FLAG = 0;
	// Amount of share you get with your minimum token deposit
    uint256 constant SHARE_PER_MINIMUM_DEPOSIT = 1e18; // 1 signal as 18 decimal number
	uint256 constant MIN_ISSUANCE_RATE = 1e18;
	uint256 constant TOKEN_DECIMALS = 1e18;
	uint256 constant MAX_CURATION_CONTENT_URI_LENGTH = 6000;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {DataTypes} from '../../utils/DataTypes.sol';

/**
 * @title IBardsCurationBase
 * @author TheBards Protocol
 *
 * @notice This is the interface for the BardsCurationBase contract. 
 * The proportion of relevant benefit-sharing involved in the curation is specified.
 */
interface IBardsCurationBase {
				/* GETTERs */

	/**
     * @notice Returns the sellerFundsRecipients associated with a given NFT, stored only once upon initial mint.
     *
     * @param tokenId The token ID of the NFT to query the curation BPS for.
     *
     * @return address[] The addresses of the sellers
     */
    function sellerFundsRecipientsOf(uint256 tokenId) external view returns (address[] memory);

	/**
     * @notice Returns the curationFundsRecipients associated with a given NFT, stored only once upon initial mint.
     *
     * @param tokenId The token ID of the NFT to query the curation BPS for.
     *
     * @return uint256[] The addresses of the sellers
     */
    function curationFundsRecipientsOf(uint256 tokenId) external view returns (uint256[] memory);

	/**
     * @notice Returns the sellerFundsBpses associated with a given NFT, stored only once upon initial mint.
     *
     * @param tokenId The token ID of the NFT to query the curation BPS for.
     *
     * @return uint32[] The fee that is sent to the sellers.
     */
    function sellerFundsBpsesOf(uint256 tokenId) external view returns (uint32[] memory);

	/**
     * @notice Returns the curationFundsBpses associated with a given NFT, stored only once upon initial mint.
     *
     * @param tokenId The token ID of the NFT to query the curation BPS for.
     *
     * @return uint32[] The fee that is sent to the sellers.
     */
    function curationFundsBpsesOf(uint256 tokenId) external view returns (uint32[] memory);


	/**
     * @notice Returns the curation BPS associated with a given NFT, stored only once upon initial mint.
     *
     * @param tokenId The token ID of the NFT to query the curation BPS for.
     *
     * @return uint32 curation BPS
     */
    function curationBpsOf(uint256 tokenId) external view returns (uint32);

	/**
     * @notice Returns the staking BPS associated with a given NFT, stored only once upon initial mint.
     *
     * @param tokenId The token ID of the NFT to query thestaking BPS for.
     *
     * @return uint32 staking BPS
     */
    function stakingBpsOf(uint256 tokenId) external view returns (uint32);

	/**
     * @notice Returns the curation data associated with a given NFT. This allows fetching the curation BPS and 
	 * staking BPS in a single call.
     * @param tokenId The token ID of the NFT to query the token data for.
     *
     * @return CurationData curation data struct containing the curation BPS and staking BPS.
     */
    function curationDataOf(uint256 tokenId) external view returns (DataTypes.CurationData memory);

    /**
     * @notice Computes the curation fee for a given uint256 amount
	 *
     * @param tokenId The token Id of a NFT to compute the fee for.
     * @param amount The amount to compute the fee for.
     * @return feeAmount The amount to be paid out to the fee recipient.
     */
    function getCurationFeeAmount(uint256 tokenId, uint256 amount) external view returns (uint256 feeAmount);

    /**
     * @notice Computes the staking fee for a given uint256 amount
	 *
     * @param tokenId The token Id of a NFT to compute the fee for.
     * @param amount The amount to compute the fee for.
     * @return feeAmount The amount to be paid out to the fee recipient.
     */
    function getStakingFeeAmount(uint256 tokenId, uint256 amount) external view returns (uint256 feeAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * @title IMinter
 * @author TheBards Protocol
 *
 * @notice This is the standard interface for all TheBards-compatible NFT minting modules.
 * Support any programmable NFT minting needs.
 */
interface IProgrammableMinter {

	/**
	 * @notice Mint programmable NFT.
	 * 
	 * @param metaData Meta data.
	 */
	function mint(
		bytes memory metaData
	) external returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IRoyaltyEngineV1} from "@manifoldxyz/royalty-registry-solidity/contracts/IRoyaltyEngineV1.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IWETH} from "./IWETH.sol";
import {Events} from '../../utils/Events.sol';
import {Errors} from '../../utils/Errors.sol';
import {TokenUtils} from '../../utils/TokenUtils.sol';
import {DataTypes} from '../../utils/DataTypes.sol';
import {Constants} from '../../utils/Constants.sol';
import {BardsHub} from '../BardsHub.sol';
import {ContractRegistrar} from '../govs/ContractRegistrar.sol';
import {IBardsStaking} from '../../interfaces/tokens/IBardsStaking.sol';
import {IBardsCurationBase} from '../../interfaces/curations/IBardsCurationBase.sol';


/**
 * @title MarketModuleBase
 * @author TheBards Protocol
 * @notice This contract extension supports paying out funds to an external recipient
 */
abstract contract MarketModuleBase is ContractRegistrar {
    using SafeERC20 for IERC20;

    IWETH internal weth;
    // The Manifold Royalty Engine
    IRoyaltyEngineV1 internal royaltyEngine;
    // The address of staking tokens.
    address internal stakingAddress;

    function _initialize(
        address _hub, 
        address _royaltyEngine,
        address _stakingAddress
    ) internal {
        if (_hub == address(0) || _royaltyEngine == address(0)) revert Errors.InitParamsInvalid();
        ContractRegistrar._initialize(_hub);

        weth = iWETH();
        royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);
        stakingAddress = _stakingAddress;
        
        emit Events.MarketModuleBaseInitialized(
            stakingAddress,
			_royaltyEngine,
			block.timestamp
		);
    }

    /**
     * @notice Update the address of the Royalty Engine, in case of unexpected update on Manifold's Proxy
     * emergency use only – requires a frozen RoyaltyEngineV1 at commit 4ae77a73a8a73a79d628352d206fadae7f8e0f74
     * to be deployed elsewhere, or a contract matching that ABI
     * @param _royaltyEngine The address for the new royalty engine
     */
    function setRoyaltyEngineAddress(
        address _royaltyEngine
    ) 
        public 
        onlyGov 
    {
        require(
            ERC165Checker.supportsInterface(_royaltyEngine, type(IRoyaltyEngineV1).interfaceId),
            "setRoyaltyEngineAddress must match IRoyaltyEngineV1 interface"
        );
        royaltyEngine = IRoyaltyEngineV1(_royaltyEngine);
    }

    function isCurrencyWhitelisted(address currency)
		internal 
		view 
		returns (bool) {
        	return bardsHub().isCurrencyWhitelisted(currency);
    }

    function getProtocolFeeSetting()
		internal 
		view 
		returns (DataTypes.ProtocolFeeSetting memory) {
        	return bardsDataDao().getProtocolFeeSetting();
    }

	function getProtocolFee()
		internal
		view
		returns (uint32) {
			return bardsDataDao().getProtocolFee();
	}

	function getDefaultCurationBps()
		internal
		view
		returns (uint32) {
			return bardsDataDao().getDefaultCurationBps();
	}

	function getDefaultStakingBps()
		internal
		view
		returns (uint32) {
			return bardsDataDao().getDefaultStakingBps();
	}

	function getTreasury()
		internal
		view
		returns (address){
			return bardsDataDao().getTreasury();
		}

	function getFeeAmount(uint256 _amount)
		internal
		view
		returns (uint256) {
			return bardsDataDao().getFeeAmount(_amount);
		}

    /**
     * @notice Before core logic of  collecting, collect fees to a specific address, 
     * and pay royalties and protocol fees
     * 
     * @param collector The colloctor of NFT.
     * @param price The price of NFT.
     * @param currency The currency
     * @param tokenContract The address of token contract.
     * @param tokenId The token Id of NFT.
     */
    function _beforeCollecting(
        address collector,
        uint256 price,
        address currency,
        address tokenContract,
        uint256 tokenId
    ) 
        internal
        returns (uint256)
    {
        // Ensure ETH/ERC-20 payment from collector is valid and take custody
        _handleIncomingTransfer(
            collector, 
            price, 
            currency, 
            stakingAddress
        );

        // Payout respective parties, ensuring royalties are honored
        (uint256 remainingProfit, ) = _handleRoyaltyPayout(
            tokenContract, 
            tokenId, 
            price, 
            currency, 
            Constants.USE_ALL_GAS_FLAG
        );

        // Payout protocol fee
        uint256 protocolFee = getFeeAmount(remainingProfit);
        address protocolTreasury = getTreasury();
        remainingProfit = _handleProtocolFeePayout(
            remainingProfit,
            currency, 
            protocolFee, 
            protocolTreasury
        );

        return remainingProfit;
    }

    /**
     * 
     * @notice Pays out the protocol fee to its protocol treasury
     * @param _amount The sale amount
     * @param _payoutCurrency The currency to pay the fee
     * @param _protocolFee The protocol fee
     * @param _protocolTreasury The protocol fee recipient
     * @return The remaining funds after paying the protocol fee
     */
    function _handleProtocolFeePayout(
        uint256 _amount, 
        address _payoutCurrency,
        uint256 _protocolFee,
        address _protocolTreasury
    ) internal returns (uint256) {
        // If no fee, return initial amount
        if (_protocolFee == 0) return _amount;

        // Payout protocol fee
        _handlePayout(_protocolTreasury, _protocolFee, _payoutCurrency, 50000);

        // Return remaining amount
        return _amount - _protocolFee;
    }

    /**
     * 
     * @notice Handle an incoming funds transfer, ensuring the sent amount is valid and the sender is solvent
     * @param _buyer The address of buyer.
     * @param _amount The amount to be received
     * @param _currency The currency to receive funds in, or address(0) for ETH
     * @param _to The address of sending tokens to.
     */
    function _handleIncomingTransfer(
        address _buyer, 
        uint256 _amount, 
        address _currency,
        address _to
    ) 
    internal {
        if (_buyer == _to){
            return;
        }
        require(_buyer != _to, "Buyer is same with seller.");

        if (_currency == address(0)) {
            require(msg.value >= _amount, "_handleIncomingTransfer msg value less than expected amount");
        } else {
            // We must check the balance that was actually transferred to this contract,
            // as some tokens impose a transfer fee and would not actually transfer the
            // full amount to the market, resulting in potentally locked funds
            IERC20 token = IERC20(_currency);
            uint256 beforeBalance = token.balanceOf(_to);
            TokenUtils.transfer(token, _buyer, _amount, _to);
            // IERC20(_currency).safeTransferFrom(_buyer, _to, _amount);
            uint256 afterBalance = token.balanceOf(_to);
            require(beforeBalance + _amount == afterBalance, "_handleIncomingTransfer token transfer call did not transfer expected amount");
        }
    }

    /**
     * @notice Pays out the amount to all curators proportionally.
     * @param _tokenContract The NFT contract address to get curation information from
     * @param _tokenId, The Token ID to get curation information from
     * @param _amount The sale amount to pay out.
     * @param _payoutCurrency The currency to pay out
     * @param _curationIds the list of curation id, who act curators.
     */
    function _handleCurationsPayout(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _amount,
        address _payoutCurrency,
        uint256[] memory _curationIds
    ) internal returns (uint256){
        if (_amount == 0) return _amount;

        // Store the number of recipients
        uint256 numCurations = _curationIds.length;

        // Store the initial amount
        uint256 amountRemaining = _amount;

        // Store the variables that cache each amount, and curationBps.
        uint256 amount;
        uint32 curationBps;

        // Payout each royalty
        for (uint256 i = 0; i < numCurations; ) {
            // Cache the recipient and amount
            // recipient = BardsHub(HUB).curationDataOf(_curationIds[i]).treasury;
            curationBps = BardsHub(HUB).curationDataOf(_curationIds[i]).curationBps;

            amount = (amountRemaining * (1 - curationBps)) / Constants.MAX_BPS;

            // Ensure that we aren't somehow paying out more than we have
            require(amountRemaining >= amount, "insolvent");

            // Transfer to the recipient
            // _handlePayout(recipient, amount, _payoutCurrency, 50000);
            bardsStaking().collect(
                _payoutCurrency, 
                amount, 
                bardsHub().getAllocationIdById(_curationIds[i])
            );

            emit Events.CurationFeePayout(
                _tokenContract, 
                _tokenId, 
                amount, 
                block.timestamp
            );

            // Cannot underflow as remaining amount is ensured to be greater than or equal to _amount
            unchecked {
                amountRemaining -= amount;
                ++i;
            }
            if (amountRemaining == 0) break;
        }

        return _amount - amountRemaining;
    }

    /**
     * @notice Collect the delegation rewards.
     * This function will assign the collected fees to the delegation pool.
     * @param _curationId Curation to which the tokens to distribute are related
     * @param _currency The currency of token.
     * @param _tokens Total tokens received used to calculate the amount of fees to collect
     */
    function _handleStakingPayout(
        uint256 _curationId, 
        address _currency, 
        uint256 _tokens
    ) internal {
        bardsStaking().collectStakingFees(
            _curationId,
            _currency,
            _tokens
        );
    }

    /**
     * @notice Pays out the amount to all sellers proportionally.
     * @param _tokenContract The NFT contract address to get royalty information from
     * @param _tokenId, The Token ID to get royalty information from
     * @param _amount The sale amount to pay out.
     * @param _payoutCurrency The currency to pay out
     * @param curationId The curattion ID where funds are split after the trade.
     */
    function _handleSellersSplitPayout(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _amount,
        address _payoutCurrency,
        uint256 curationId
    ) internal returns (uint256){
        if (_amount == 0) return _amount;

        DataTypes.CurationData memory curationData = IBardsCurationBase(_tokenContract).curationDataOf(curationId);

        // Store the number of recipients
        uint256 numRecipients = curationData.sellerFundsRecipients.length;

        // Store the initial amount
        uint256 amountRemaining = _amount;

        // Store the variables that cache each recipient and amount
        address recipient;
        uint256 amount;

        // Payout each royalty
        for (uint256 i = 0; i < numRecipients; ) {
            // Cache the recipient and amount
            recipient = curationData.sellerFundsRecipients[i];
            amount = (_amount * curationData.sellerFundsBpses[i]) / Constants.MAX_BPS;

            // Ensure that we aren't somehow paying out more than we have
            require(amountRemaining >= amount, "insolvent");

            // Transfer to the recipient
            _handlePayout(recipient, amount, _payoutCurrency, 50000);

            emit Events.SellFeePayout(
                _tokenContract, 
                _tokenId, 
                recipient, 
                amount, 
                block.timestamp
            );

            // Cannot underflow as remaining amount is ensured to be greater than or equal to _amount
            unchecked {
                amountRemaining -= amount;
                ++i;
            }
        }

        numRecipients = curationData.curationFundsRecipients.length;
        uint256 curationRecipient;
        for (uint256 i = 0; i < numRecipients; ) {
            // Cache the recipient and amount
            curationRecipient = curationData.curationFundsRecipients[i];
            amount = (_amount * curationData.curationFundsBpses[i]) / Constants.MAX_BPS;

            // Ensure that we aren't somehow paying out more than we have
            require(amountRemaining >= amount, "insolvent");

            // Transfer to the recipient
            bardsStaking().collect(
                _payoutCurrency,
                amount,
                bardsHub().getAllocationIdById(curationId)
            );

            emit Events.CurationFeePayout(
                _tokenContract, 
                _tokenId, 
                amount, 
                block.timestamp
            );

            // Cannot underflow as remaining amount is ensured to be greater than or equal to _amount
            unchecked {
                amountRemaining -= amount;
                ++i;
            }
        }

        return amountRemaining;
    }

    /**
     * 
     * @notice Pays out royalties for given NFTs
     * @param _tokenContract The NFT contract address to get royalty information from
     * @param _tokenId, The Token ID to get royalty information from
     * @param _amount The total sale amount
     * @param _payoutCurrency The ERC-20 token address to payout royalties in, or address(0) for ETH
     * @param _gasLimit The gas limit to use when attempting to payout royalties. Uses gasleft() if not provided.
     * @return The remaining funds after paying out royalties
     */
    function _handleRoyaltyPayout(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _amount,
        address _payoutCurrency,
        uint256 _gasLimit
    ) internal returns (uint256, bool) {
        // If no gas limit was provided or provided gas limit greater than gas left, just pass the remaining gas.
        uint256 gas = (_gasLimit == 0 || _gasLimit > gasleft()) ? gasleft() : _gasLimit;

        // External call ensuring contract doesn't run out of gas paying royalties
        try this._handleRoyaltyEnginePayout{gas: gas}(_tokenContract, _tokenId, _amount, _payoutCurrency) returns (uint256 remainingFunds) {
            // Return remaining amount if royalties payout succeeded
            return (remainingFunds, true);
        } catch {
            // Return initial amount if royalties payout failed
            return (_amount, false);
        }
    }

    /**
     * @notice Pays out royalties for NFTs based on the information returned by the royalty engine
     * @dev This method is external to enable setting a gas limit when called - see `_handleRoyaltyPayout`.
     * @param _tokenContract The NFT Contract to get royalty information from
     * @param _tokenId, The Token ID to get royalty information from
     * @param _amount The total sale amount
     * @param _payoutCurrency The ERC-20 token address to payout royalties in, or address(0) for ETH
     * @return The remaining funds after paying out royalties
     */
    function _handleRoyaltyEnginePayout(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _amount,
        address _payoutCurrency
    ) external payable returns (uint256) {
        // Ensure the caller is the contract
        require(msg.sender == address(this), "_handleRoyaltyEnginePayout only self callable");

        // Get the royalty recipients and their associated amounts
        (
            address payable[] memory recipients, 
            uint256[] memory amounts
        ) = royaltyEngine.getRoyalty(_tokenContract, _tokenId, _amount);

        // Store the number of recipients
        uint256 numRecipients = recipients.length;

        // If there are no royalties, return the initial amount
        if (numRecipients == 0) return _amount;

        // Store the initial amount
        uint256 amountRemaining = _amount;

        // Store the variables that cache each recipient and amount
        address recipient;
        uint256 amount;

        // Payout each royalty
        for (uint256 i = 0; i < numRecipients; ) {
            // Cache the recipient and amount
            recipient = recipients[i];
            amount = amounts[i];

            // Ensure that we aren't somehow paying out more than we have
            require(amountRemaining >= amount, "insolvent");

            // Transfer to the recipient
            _handlePayout(recipient, amount, _payoutCurrency, 50000);

            emit Events.RoyaltyPayout(_tokenContract, _tokenId, recipient, amount, block.timestamp);

            // Cannot underflow as remaining amount is ensured to be greater than or equal to royalty amount
            unchecked {
                amountRemaining -= amount;
                ++i;
            }
        }

        return amountRemaining;
    }

    /**
     * @notice Handle an outgoing funds transfer
     * @dev Wraps ETH in WETH if the receiver cannot receive ETH, noop if the funds to be sent are 0 or recipient is invalid
     * @param _dest The destination for the funds
     * @param _amount The amount to be sent
     * @param _currency The currency to send funds in, or address(0) for ETH
     * @param _gasLimit The gas limit to use when attempting a payment (if 0, gasleft() is used)
     */
    function _handlePayout(
        address _dest,
        uint256 _amount,
        address _currency,
        uint256 _gasLimit
    ) internal {
        if (_amount == 0 || _dest == address(0)) {
            return;
        }

        // Handle ETH payment
        if (_currency == address(0)) {
            require(address(this).balance >= _amount, "_handlePayout insolvent");

            // If no gas limit was provided or provided gas limit greater than gas left, just use the remaining gas.
            uint256 gas = (_gasLimit == 0 || _gasLimit > gasleft()) ? gasleft() : _gasLimit;
            (bool success, ) = _dest.call{value: _amount, gas: gas}("");
            // If the ETH transfer fails (sigh), wrap the ETH and try send it as WETH.
            if (!success) {
                weth.deposit{value: _amount}();
                // IERC20(address(weth)).safeTransferFrom(stakingAddress, _dest, _amount);
                TokenUtils.transfer(IERC20(address(weth)), stakingAddress, _amount, _dest);
            }
        } else {
            // IERC20(_currency).safeTransferFrom(stakingAddress, _dest, _amount);
            TokenUtils.transfer(IERC20(_currency), stakingAddress, _amount, _dest);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * @title IMarketModule
 * @author TheBards Protocol
 *
 * @notice This is the standard interface for all TheBards-compatible NFT market modules.
 */
interface IMarketModule {
	/**
     * @notice Initializes data for a given publication being published. This can only be called by the hub.
     *
     * @param tokenContract The address of content NFT contract
     * @param tokenId The token ID of content NFT contract.
     * @param data Arbitrary data __passed from the user!__ to be decoded, such as price.
     *
     * @return bytes An abi encoded byte array encapsulating the execution's state changes. This will be emitted by the
     * hub alongside the collect module's address and should be consumed by front ends.
     */
    function initializeModule(
        address tokenContract,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes memory);

	/**
     * @notice Processes a collect action for a given NFT.
     *
     * @param collector The buyer address.
     * @param curationId The curation ID.
     * @param tokenContract The address of content NFT contract.
     * @param tokenId The token ID of content NFT contract.
     * @param curationIds the list of curation id, who act curators.
     * @param collectMetaData The meta data of collect.
     */
    function collect(
        address collector,
        uint256 curationId,
        address tokenContract,
        uint256 tokenId,
        uint256[] memory curationIds,
        bytes memory collectMetaData
    ) external returns (address, uint256);
	
}

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

pragma solidity ^0.8.12;

import {DataTypes} from '../../utils/DataTypes.sol';

/**
 * @title IBardsStaking
 * 
 * @author TheBards Protocol
 * 
 * @notice The interface of BardsStaking
 * 
 */
interface IBardsStaking {

    /**
     * @notice initialize the contract.
     * 
     * @param _HUB The address of HUB;
     * @param _bondingCurve The address of bonding curve;
     * @param _bardsShareTokenImpl The address of bards share token;
     * @param _defaultStakingReserveRatio The default staking reserve ratio;
     * @param _stakingTaxPercentage The percentage of staking tax;
     * @param _minimumStaking The minimum staking;
     * @param _stakingAddress The fund address of staking;
     * @param _rebateAlphaNumerator The alphaNumerator of rebating;
     * @param _rebateAlphaDenominator The alphaDenominator of rebating;
     * @param _thawingPeriod The thawing period;
     * @param _channelDisputeEpochs _channelDisputeEpochs
     * @param _maxAllocationEpochs _maxAllocationEpochs
     */
    function initialize(
        address _HUB,
        address _bondingCurve,
        address _bardsShareTokenImpl,
        uint32 _defaultStakingReserveRatio,
        uint32 _stakingTaxPercentage,
        uint256 _minimumStaking,
        address _stakingAddress,
        uint32 _rebateAlphaNumerator,
        uint32 _rebateAlphaDenominator,
        uint32 _thawingPeriod,
        uint32 _channelDisputeEpochs,
        uint32 _maxAllocationEpochs
    ) external;

    /**
     * @notice Set the address of tokens.
     * 
     * @param _stakingAddress The address of staking tokens;
     */
    function setStakingAddress(address _stakingAddress) external;

    /**
     * @notice Set the default reserve ratio percentage for a curation pool.
     * 
     * Update the default reserver ratio to `_defaultReserveRatio`
     * @param _defaultReserveRatio Reserve ratio (in PPM)
     */
    function setDefaultReserveRatio(uint32 _defaultReserveRatio) external;

    /**
     * @notice Set the minimum stake required to.
     * 
     * @param _minimumStaking Minimum stake
     */
    function setMinimumStaking(uint256 _minimumStaking) external;

    /**
     * @notice Set the thawing period for unstaking.
     * 
     * @param _thawingPeriod Period in blocks to wait for token withdrawals after unstaking
     */
    function setThawingPeriod(uint32 _thawingPeriod) external;

    /**
     * @notice Set the period in epochs that need to pass before fees in rebate pool can be claimed.
     * 
     * @param _channelDisputeEpochs Period in epochs
     */
    function setChannelDisputeEpochs(uint32 _channelDisputeEpochs) external;

    /**
     * @notice Set the max time allowed for stake on allocations.
     * 
     * @param _maxAllocationEpochs Allocation duration limit in epochs
     */
    function setMaxAllocationEpochs(uint32 _maxAllocationEpochs) external;

    /**
     * @notice Set the rebate ratio (fees to allocated stake).
     * 
     * @param _alphaNumerator Numerator of `alpha` in the cobb-douglas function
     * @param _alphaDenominator Denominator of `alpha` in the cobb-douglas function
     */
    function setRebateRatio(uint32 _alphaNumerator, uint32 _alphaDenominator) external;

    /**
     * @notice Set a staking tax percentage to burn when staked funds are deposited.
     * @param _percentage Percentage of staked tokens to burn as staking tax
     */
    function setStakingTaxPercentage(uint32 _percentage) external;

    /**
     * @notice Set the master copy to use as clones for the Bards Share Tokens.
     * @param _bardsShareTokenImpl Address of implementation contract to use for Bards Share Tokens.
     */
    function setBardsShareTokenImpl(address _bardsShareTokenImpl) external;

    /**
     * @notice Returns whether `_curationId` is staked.
     * 
     * @param _curationId The curation ID.
     */
    function isStaked(uint256 _curationId) external view returns (bool);

    // -- Staking --

    /**
     * @notice Deposit tokens on the curation.
     * 
     * @param _curationId curation Id
     * @param _tokens Amount of tokens to stake
     */
    function stake(uint256 _curationId, uint256 _tokens) external returns (uint256 shareOut, uint256 stakingTax) ;

    /**
     * @notice Unstake shares from the curation stake, lock them until thawing period expires.
     * 
     * @param _curationId Curation Id to unstake
     * @param _shares Amount of shares to unstake
     */
    function unstake(uint256 _curationId, uint256 _shares) external returns(uint256);

    /**
     * @notice Withdraw staked tokens once the thawing period has passed.
     * 
     * @param _curationId curation Id
     * @param _stakeToCuration Re-delegate to new curation if non-zero, withdraw if zero address
     */ 
    function withdrawStaked(uint256 _curationId, uint256 _stakeToCuration) external returns (uint256);

    // -- Channel management and allocations --

    /**
     * @notice Allocate available tokens to a curation.
     * 
     * @param _createAllocationData Data of struct CreateAllocationData
     */
    function allocate(
        DataTypes.CreateAllocateData calldata _createAllocationData
    ) external;

    /**
     * @notice Close an allocation and free the staked tokens.
     * 
     * @param _allocationId The allocation identifier.
     * @param _stakeToCuration Restake to curation.
     */
    function closeAllocation(uint256 _allocationId, uint256 _stakeToCuration) external;

    /**
     * @notice Close multiple allocations and free the staked tokens.
     * 
     * @param _allocationIds An array of allocationId
     * @param _stakeToCurations An array of curations for restaking.
     */
    function closeAllocationMany(uint256[] calldata _allocationIds, uint256[] calldata _stakeToCurations) external;

    /**
     * @notice Close and allocate. This will perform a close and then create a new Allocation
     * atomically on the same transaction.
     * 
     * @param _closingAllocationID The identifier of the allocation to be closed
     * @param _stakeToCuration The curation of restaking.
     * @param _createAllocationData Data of struct CreateAllocationData
     */
    function closeAndAllocate(
        uint256 _closingAllocationID,
        uint256 _stakeToCuration,
        DataTypes.CreateAllocateData calldata _createAllocationData
    ) external;

    /**
     * @notice Collect fees from market and assign them to an allocation.
     * Funds received are only accepted from a valid sender.
     * To avoid reverting on the withdrawal from channel flow this function will:
     * 1) Accept calls with zero tokens.
     * 2) Accept calls after an allocation passed the dispute period, in that case, all
     *    the received tokens are burned.
     * @param _currency Currency of token to collect.
     * @param _tokens Amount of tokens to collect
     * @param _allocationId Allocation where the tokens will be assigned
     */
    function collect(address _currency, uint256 _tokens, uint256 _allocationId) external;

    /**
     * @notice Collect the delegation rewards.
     * This function will assign the collected fees to the delegation pool.
     * @param _curationId Curation to which the tokens to distribute are related
     * @param _currency The currency of token.
     * @param _tokens Total tokens received used to calculate the amount of fees to collect
     */
    function collectStakingFees(
        uint256 _curationId, 
        address _currency, 
        uint256 _tokens
    ) external;

    /**
     * @notice Claim tokens from the rebate pool.
     * 
     * @param _allocationId Allocation from where we are claiming tokens
     * @param _stakeToCuration Restake to new curation
     */
    function claim(uint256 _allocationId, uint256 _stakeToCuration) external;

    /**
     * @notice Claim tokens from the rebate pool for many allocations.
     * 
     * @param _allocationIds Array of allocations from where we are claiming tokens
     * @param _stakeToCuration Restake to new curation
     */
    function claimMany(uint256[] calldata _allocationIds, uint256 _stakeToCuration) external;

    // -- Getters and calculations --

    /**
     * @notice Return the current state of an allocation.
     * @param _allocationId Address used as the allocation identifier
     * @return AllocationState
     */
    function getAllocationState(uint256 _allocationId) external view returns (DataTypes.AllocationState);

    /**
     * @notice Return if allocationId is used.
     * 
     * @param _allocationId Address used as signer for an allocation
     * @return True if allocationId already used
     */
    function isAllocation(uint256 _allocationId) external view returns (bool);

    /**
     * @notice Return the total amount of tokens allocated to curation.
     * 
     * @param _allocationId allocation Id
     * @param _currency The address of currency
     * @return Total tokens allocated to curation
     */
    function getFeesCollectedInAllocation(
        uint256 _allocationId, 
        address _currency
    )
        external
        view
        returns (uint256);

    /**
     * @notice Return the total amount of tokens allocated to curation.
     * 
     * @param _curationId _curationId
     * @return Total tokens allocated to curation
     */
    function getCurationAllocatedTokens(uint256 _curationId)
        external
        view
        returns (uint256);

    /**
     * @notice Get the address of staking tokens.
     * 
     * @return The address of Staking tokens.
     */
    function getStakingAddress() 
        external
        view
        returns (address);

    /**
     * @notice Get the total staking tokens.
     * 
     * @return The total Staking tokens.
     */
    function getTotalStakingToken() 
        external
        view
        returns (uint256);

    function getSimpleAllocation(
        uint256 _allocationId
    ) 
        external 
        view 
        returns (DataTypes.SimpleAllocation memory);

    /**
     * @notice Get the reserveRatio of curation.
     *
     * @param _curationId The curation ID
     * 
     * @return reserveRatio The reserveRatio of curation.
     */
    function getReserveRatioOfCuration(uint256 _curationId) 
        external
        view
        returns (uint32 reserveRatio);

    /**
     * @notice Returns amount of staked BCT tokens ready to be withdrawn after thawing period.
     * @param _curationId curation Id.
     * @param _delegator Delegator owning the share tokens
     * @return Are there any withdrawable tokens.
     */
    function getWithdrawableBCTTokens(uint256 _curationId, address _delegator)
        external
        view
        returns (uint256);

    /**
     * @notice Get the amount of share a delegator has in a curation staking pool.
     * 
     * @param _delegator Delegator owning the share tokens
     * @param _curationId curation Id.
     * 
     * @return Amount of share owned by a delegator for the curation
     */
    function getDelegatorShare(
        address _delegator, 
        uint256 _curationId
    )
        external
        view
        returns (uint256);

    /**
     * @notice Get the amount of share in a curation staking pool.
     * 
     * @param _curationId curation Id.
     * 
     * @return Amount of share minted for the curation
     */
    function getStakingPoolShare(uint256 _curationId) 
        external 
        view 
        returns (uint256);

    /**
     * @notice Get the amount of share in a curation staking pool.
     * 
     * @param _curationId curation Id.
     * 
     * @return Amount of share minted for the curation
     */
    function getStakingPoolToken(uint256 _curationId) 
        external 
        view 
        returns (uint256);

    /**
     * @notice Return whether the delegator has staked to the curation.
     * 
     * @param _curationId  Curation Id where funds have been staked
     * @param _delegator Address of the delegator
     * @return True if delegator of curation
     */
    function isDelegator(uint256 _curationId, address _delegator) external view returns (bool);

    /**
     * @notice Return whether the seller is one of the stakeholders of curation.
     * 
     * @param _allocationId _allocationId
     * @param _seller Address of the seller of curation NFT
     * @return True if delegator of curation
     */
    function isSeller(uint256 _allocationId, address _seller) external view returns (bool);

    /**
     * @notice Calculate amount of share that can be bought with tokens in a staking pool.
     * 
     * @param _curationId Curation to mint share
     * @param _tokens Amount of tokens used to mint share
     * @return Amount of share that can be bought with tokens
     */
    function tokensToShare(uint256 _curationId, uint256 _tokens)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Calculate number of tokens to get when burning shares from a staking pool.
     * 
     * @param _curationId Curation to burn share
     * @param _shares Amount of share to burn
     * 
     * @return Amount of tokens to get for an amount of shares
     */
    function shareToTokens(uint256 _curationId, uint256 _shares)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.12;

import {IBardsCurationToken} from "../interfaces/tokens/IBardsCurationToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library TokenUtils {
    using SafeERC20 for IERC20;
    /**
     * @dev Transfer tokens from an address to anther.
     * @param _ierc20 Token to transfer
     * @param _from Address sending the tokens
     * @param _amount Amount of tokens to transfer
     * @param _to Address sending to
     */
    function transfer(
        IERC20 _ierc20,
        address _from,
        uint256 _amount,
        address _to
    ) 
        internal 
    {
        if (_amount > 0) {
            address fromAddress = (_from == address(0))? address(this): _from;
            address toAddress = (_to == address(0))? address(this): _to;
            // require(_ierc20.transferFrom(fromAddress, toAddress, _amount), "!transfer");
            _ierc20.safeTransferFrom(fromAddress, toAddress, _amount);
        }
    }

    /**
     * @dev Pull tokens from an address to this contract.
     * @param _ierc20 Token to transfer
     * @param _from Address sending the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pullTokens(
        IERC20 _ierc20,
        address _from,
        uint256 _amount
    ) 
        internal 
    {
        if (_amount > 0) {
            require(_ierc20.transferFrom(_from, address(this), _amount), "!transfer");
        }
    }

    /**
     * @dev Push tokens from this contract to a receiving address.
     * @param _ierc20 Token to transfer
     * @param _to Address receiving the tokens
     * @param _amount Amount of tokens to transfer
     */
    function pushTokens(
        IBardsCurationToken _ierc20,
        address _to,
        uint256 _amount
    ) 
        internal 
    {
        if (_amount > 0) {
            require(_ierc20.transfer(_to, _amount), "!transfer");
        }
    }

    /**
     * @dev Burn tokens held by this contract.
     * @param _bardsCurationToken Token to burn
     * @param _amount Amount of tokens to burn
     */
    function burnTokens(
        IBardsCurationToken _bardsCurationToken, 
        address _from,
        uint256 _amount
    ) 
        internal 
    {
        if (_amount > 0) {
            _bardsCurationToken.burnFrom(_from, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {DataTypes} from './DataTypes.sol';

library Events {
    /**
     * @notice Emitted when the NFT contract's name and symbol are set at initialization.
     *
     * @param name The NFT name set.
     * @param symbol The NFT symbol set.
     * @param timestamp The current block timestamp.
     */
    event BaseInitialized(string name, string symbol, uint256 timestamp);

     /**
     * @notice Emitted when the hub state is set.
     *
     * @param caller The caller who set the state.
     * @param prevState The previous protocol state, an enum of either `Paused`, `PublishingPaused` or `Unpaused`.
     * @param newState The newly set state, an enum of either `Paused`, `PublishingPaused` or `Unpaused`.
     * @param timestamp The current block timestamp.
     */
    event StateSet(
        address indexed caller,
        DataTypes.ProtocolState indexed prevState,
        DataTypes.ProtocolState indexed newState,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the governance address is changed. We emit the caller even though it should be the previous
     * governance address, as we cannot guarantee this will always be the case due to upgradeability.
     *
     * @param caller The caller who set the governance address.
     * @param prevGovernance The previous governance address.
     * @param newGovernance The new governance address set.
     * @param timestamp The current block timestamp.
     */
    event GovernanceSet(
        address indexed caller,
        address indexed prevGovernance,
        address indexed newGovernance,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a dispatcher is set for a specific profile.
     *
     * @param curationId The token ID of the curation for which the dispatcher is set.
     * @param dispatcher The dispatcher set for the given profile.
     * @param timestamp The current block timestamp.
     */
    event DispatcherSet(
        uint256 indexed curationId, 
        address indexed dispatcher, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when `theBards` set `operator` access.
     */
    event OperatorSet(
        address indexed theBards, 
        address indexed operator, 
        bool allowed, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when `curationId` set `allocationId` access.
     */
    event AllocationIdSet(
        uint256 curationId,
        uint256 allocationId,
        bytes curationMetaData,
        uint256 stakeToCuration,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the emergency admin is changed. We emit the caller even though it should be the previous
     * governance address, as we cannot guarantee this will always be the case due to upgradeability.
     *
     * @param caller The caller who set the emergency admin address.
     * @param oldEmergencyAdmin The previous emergency admin address.
     * @param newEmergencyAdmin The new emergency admin address set.
     * @param timestamp The current block timestamp.
     */
    event EmergencyAdminSet(
        address indexed caller,
        address indexed oldEmergencyAdmin,
        address indexed newEmergencyAdmin,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the cooldown blocks is updated.
     * @param oldCooldownBlocks The previous emergency admin address.
     * @param newCooldownBlocks The new emergency admin address set.
     * @param timestamp The current block timestamp.
     */
    event CooldownBlocksUpdated(
        uint32 indexed oldCooldownBlocks, 
        uint32 indexed newCooldownBlocks, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param curationBps The bps of curation.
     * @param timestamp The current block timestamp.
     */
    event CurationBpsUpdated(
        uint256 indexed tokenId, 
        uint32 curationBps, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param sellers The addressers of the sellers.
     * @param timestamp The current block timestamp.
     */
    event CurationSellersUpdated(
        uint256 indexed tokenId, 
        address[] sellers, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param sellerFundsRecipients The addresses where funds are sent after the trade.
     * @param timestamp The current block timestamp.
     */
    event CurationSellerFundsRecipientsUpdated(
        uint256 indexed tokenId, 
        address[] sellerFundsRecipients, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param curationFundsRecipients The curation Ids where funds are sent after the trade.
     * @param timestamp The current block timestamp.
     */
    event CurationFundsRecipientsUpdated(
        uint256 indexed tokenId, 
        uint256[] curationFundsRecipients, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param sellerFundsBpses The fee that is sent to the sellers.
     * @param timestamp The current block timestamp.
     */
    event CurationSellerFundsBpsesUpdated(
        uint256 indexed tokenId, 
        uint32[] sellerFundsBpses, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param curationFundsBpses The fee that is sent to the curations.
     * @param timestamp The current block timestamp.
     */
    event CurationFundsBpsesUpdated(
        uint256 indexed tokenId, 
        uint32[] curationFundsBpses, 
        uint256 timestamp
    );
   
    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param stakingBps The bps of staking.
     * @param timestamp The current block timestamp.
     */
    event StakingBpsUpdated(
        uint256 indexed tokenId, 
        uint32 stakingBps, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when an curation is created.
     * @param tokenId The token Id of a NFT.
     * @param curationData The curation data.
     * @param timestamp The current block timestamp.
     */
    event CurationUpdated(
        uint256 indexed tokenId,
        bytes curationData,
        uint256 timestamp
    );

     /**
     * @notice Emitted when the Bards protocol treasury address is set.
     *
     * @param prevTreasury The previous treasury address.
     * @param newTreasury The new treasury address set.
     * @param timestamp The current block timestamp.
     */
    event ProtocolTreasurySet(
        address indexed prevTreasury,
        address indexed newTreasury,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the Bards protocol fee is set.
     *
     * @param prevProtocolFee The previous treasury fee in BPS.
     * @param newProtocolFee The new treasury fee in BPS.
     * @param timestamp The current block timestamp.
     */
    event ProtocolFeeSet(
        uint32 indexed prevProtocolFee,
        uint32 indexed newProtocolFee,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the Bards protocol default curation fee is set.
     *
     * @param prevDefaultCurationBps The previous default curation fee in BPS.
     * @param newDefaultCurationBps The new default curation fee in BPS.
     * @param timestamp The current block timestamp.
     */
    event DefaultCurationFeeSet(
        uint32 indexed prevDefaultCurationBps,
        uint32 indexed newDefaultCurationBps,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the Bards protocol default staking fee is set.
     *
     * @param prevDefaultStakingBps The previous default staking fee in BPS.
     * @param newDefaultStakingBps The new default staking fee in BPS.
     * @param timestamp The current block timestamp.
     */
    event DefaultStakingFeeSet(
        uint32 indexed prevDefaultStakingBps,
        uint32 indexed newDefaultStakingBps,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a currency is added to or removed from the Protocol fee whitelist.
     *
     * @param currency The currency address.
     * @param prevWhitelisted Whether or not the currency was previously whitelisted.
     * @param whitelisted Whether or not the currency is whitelisted.
     * @param timestamp The current block timestamp.
     */
    event ProtocolCurrencyWhitelisted(
        address indexed currency,
        bool indexed prevWhitelisted,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the Bards protocol governance address is set.
     *
     * @param prevGovernance The previous governance address.
     * @param newGovernance The new governance address set.
     * @param timestamp The current block timestamp.
     */
    event ProtocolGovernanceSet(
        address indexed prevGovernance,
        address indexed newGovernance,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a market module inheriting from the `MarketModuleBase` is constructed.
     *
     * @param stakingAddress The address of staking.
     * @param royaltyEngine The address of royaltyEngine.
     * @param timestamp The current block timestamp.
     */
    event MarketModuleBaseInitialized(
        address indexed stakingAddress,
        address indexed royaltyEngine,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a mint module is added to or removed from the whitelist.
     *
     * @param minterModule The address of the mint module.
     * @param whitelisted Whether or not the follow module is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event MinterModuleWhitelisted(
        address indexed minterModule,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a market module is added to or removed from the whitelist.
     *
     * @param marketModule The address of the market module.
     * @param whitelisted Whether or not the follow module is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event MarketModuleWhitelisted(
        address indexed marketModule,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a a default profile is set for a wallet as its main identity
     *
     * @param wallet The wallet which set or unset its default profile.
     * @param profileId The token ID of the profile being set as default, or zero.
     * @param timestamp The current block timestamp.
     */
    event DefaultProfileSet(
        address indexed wallet, 
        uint256 indexed profileId, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when a profile is created.
     *
     * @param profileId The newly created profile's token ID.
     * @param creator The profile creator, who created the token with the given profile ID.
     * @param to The address receiving the profile with the given profile ID.
     * @param handle The handle set for the profile.
     * @param contentURI The content uri set for the profile.
     * @param marketModule The profile's newly set market module. This CAN be the zero address.
     * @param marketModuleReturnData The data returned from the market module's initialization. This is abi encoded
     * and totally depends on the market module chosen.
     * @param minterMarketModule The profile's newly set mint module. This CAN be the zero address.
     * @param minterMarketModuleReturnData The data returned from the mint module's initialization. This is abi encoded
     * and totally depends on the mint module chosen.
     * @param timestamp The current block timestamp.
     */
    event ProfileCreated(
        uint256 indexed profileId,
        address indexed creator,
        address indexed to,
        string handle,
        string contentURI,
        address marketModule,
        bytes marketModuleReturnData,
        address minterMarketModule,
        bytes minterMarketModuleReturnData,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a curation is created.
     *
     * @param profileId The newly created profile's token ID.
     * @param curationId The newly created curation's token ID.
     * @param contentURI The content uri set for the profile.
     * @param marketModule The profile's newly set market module. This CAN be the zero address.
     * @param marketModuleReturnData The data returned from the market module's initialization. This is abi encoded
     * and totally depends on the market module chosen.
     * @param minterMarketModule The profile's newly set mint module. This CAN be the zero address.
     * @param minterMarketModuleReturnData The data returned from the mint module's initialization. This is abi encoded
     * and totally depends on the mint module chosen.
     * @param timestamp The current block timestamp.
     */
    event CurationCreated(
        uint256 indexed profileId,
        uint256 indexed curationId,
        string contentURI,
        address marketModule,
        bytes marketModuleReturnData,
        address minterMarketModule,
        bytes minterMarketModuleReturnData,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a curation's market module is set.
     *
     * @param curationId The profile's token ID.
     * @param marketModule The profile's newly set follow module. This CAN be the zero address.
     * @param marketModuleReturnData The data returned from the follow module's initialization. This is abi encoded
     * and totally depends on the follow module chosen.
     * @param timestamp The current block timestamp.
     */
    event MarketModuleSet(
        uint256 indexed curationId,
        address marketModule,
        bytes marketModuleReturnData,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a curation's minter market module is set.
     *
     * @param curationId The profile's token ID.
     * @param minterMarketModule The profile's newly set follow module. This CAN be the zero address.
     * @param minterMarketModuleReturnData The data returned from the follow module's initialization. This is abi encoded
     * and totally depends on the follow module chosen.
     * @param timestamp The current block timestamp.
     */
    event MinterMarketModuleSet(
        uint256 indexed curationId,
        address minterMarketModule,
        bytes minterMarketModuleReturnData,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a profile creator is added to or removed from the whitelist.
     *
     * @param profileCreator The address of the profile creator.
     * @param whitelisted Whether or not the profile creator is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event ProfileCreatorWhitelisted(
        address indexed profileCreator,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @notice Emitted when royalties are paid
     * 
     * @param tokenContract The ERC-721 token address of the royalty payout
     * @param tokenId The ERC-721 token ID of the royalty payout
     * @param recipient The recipient address of the royalty
     * @param amount The amount paid to the recipient
     * @param timestamp The current block timestamp.
     */
    event RoyaltyPayout(
        address indexed tokenContract, 
        uint256 indexed tokenId, 
        address recipient, 
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @notice Emitted when sell fee are paid
     * 
     * @param tokenContract The ERC-721 token address of the sell fee payout
     * @param tokenId The ERC-721 token ID of the sell fee payout
     * @param recipient The recipient address of the sell fee
     * @param amount The amount paid to the recipient
     * @param timestamp The current block timestamp.
     */
    event SellFeePayout(
        address indexed tokenContract, 
        uint256 indexed tokenId, 
        address recipient, 
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @notice Emitted when curation fees are paid
     * 
     * @param tokenContract The ERC-721 token address of the curation fee payout
     * @param tokenId The ERC-721 token ID of the curation fee payout
     * @param amount The amount paid to the recipient
     * @param timestamp The current block timestamp.
     */
    event CurationFeePayout(
        address indexed tokenContract, 
        uint256 indexed tokenId,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @notice Emitted when minters are added. 
     * 
     * @param account A minter address
     * @param timestamp The current block timestamp.
     */
    event MinterAdded(
        address indexed account, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when minters are removed.
     * 
     * @param account A minter address
     * @param timestamp The current block timestamp.
     */
    event MinterRemoved(
        address indexed account,
        uint256 timestamp
    );

    /**
     * @notice Emitted when defaultReserveRatio is setted.
     * 
     * @param prevDefaultReserveRatio The previous defaultReserveRatio.
     * @param newDefaultReserveRatio The new defaultReserveRatio.
     * @param timestamp The current block timestamp.
     */
    event DefaultReserveRatioSet(
        uint32 indexed prevDefaultReserveRatio,
        uint32 indexed newDefaultReserveRatio,
        uint256 timestamp
    );

    /**
     * @notice Emitted when newMinimumStaking is setted.
     * 
     * @param prevMinimumStaking The previous newMinimumStaking.
     * @param newMinimumStaking The new newMinimumStaking.
     * @param timestamp The current block timestamp.
     */
    event MinimumStakingSet(
        uint256 indexed prevMinimumStaking,
        uint256 indexed newMinimumStaking,
        uint256 timestamp
    );

    /**
     * @notice Emitted when stakingTaxPercentage is setted.
     * 
     * @param prevStakingTaxPercentage The previous stakingTaxPercentage.
     * @param newStakingTaxPercentage The new stakingTaxPercentage.
     * @param timestamp The current block timestamp.
     */
    event StakingTaxPercentageSet(
        uint32 indexed prevStakingTaxPercentage,
        uint32 indexed newStakingTaxPercentage,
        uint256 timestamp
    );

    /**
     * @notice Emitted when bardsShareTokenImpl is setted.
     * 
     * @param prevBardsShareTokenImpl The previous bardsShareTokenImpl.
     * @param newBardsShareTokenImpl The new bardsShareTokenImpl.
     * @param timestamp The current block timestamp.
     */
    event BardsShareTokenImplSet(
        address indexed prevBardsShareTokenImpl,
        address indexed newBardsShareTokenImpl,
        uint256 timestamp
    );

    /**
     * @notice Emitted when bardsCurationTokenImpl is setted.
     * 
     * @param prevBardsCurationTokenImpl The previous bardsCurationTokenImpl.
     * @param newBardsCurationTokenImpl The new bardsCurationTokenImpl.
     * @param timestamp The current block timestamp.
     */
    event BardsCurationTokenImplSet(
        address indexed prevBardsCurationTokenImpl,
        address indexed newBardsCurationTokenImpl,
        uint256 timestamp
    );

    /**
     * @notice Emitted when contract address update
     * 
     * @param id contract id
     * @param contractAddress contract Address
     * @param timestamp The current block timestamp.
     */
    event ContractRegistered(
        bytes32 indexed id, 
        address contractAddress,
        uint256 timestamp
    );

    /**
     * @notice Emitted when contract with `nameHash` is synced to `contractAddress`.
     * 
     * @param nameHash name Hash
     * @param contractAddress contract Address
     * @param timestamp The current block timestamp.
     */
    event ContractSynced(
        bytes32 indexed nameHash, 
        address contractAddress,
        uint256 timestamp
    );

    /**
     * @notice Emitted when hub setted
     * 
     * @param hub the hub address.
     * @param timestamp The current block timestamp.
     */
    event HUBSet(
        address indexed hub,
        uint256 timestamp
    );

    /**
     * @notice Emitted when BardsDaoData setted
     * 
     * @param bardsDaoData the hub address.
     * @param timestamp The current block timestamp.
     */
    event BardsDaoDataSet(
        address indexed bardsDaoData,
        uint256 timestamp
    );

    /**
     * @notice Emitted when epoch run
     * 
     * @param epoch epoch 
     * @param caller epoch
     * @param timestamp The current block timestamp.
     */
    event EpochRun(
        uint256 indexed epoch, 
        address caller,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a curation's URI is set.
     *
     * @param curationId The token ID of the curation for which the URI is set.
     * @param contentURI The URI set for the given profile.
     * @param timestamp The current block timestamp.
     */
    event CurationContentURISet(
        uint256 indexed curationId, 
        string contentURI, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when epoch length updated
     * 
     * @param epoch epoch
     * @param epochLength epoch length
     * @param timestamp The current block timestamp.
     */
    event EpochLengthUpdate(
        uint256 indexed epoch, 
        uint256 epochLength,
        uint256 timestamp
    );

    /**
     * @notice Emitted when rewards are assigned to a curation.
     */
    event RewardsAssigned(
        uint256 indexed curationId,
        uint256 indexed allocationId,
        uint256 epoch,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @notice Emitted when rewards are denied to a curation.
     */
    event RewardsDenied(
        uint256 indexed curationId, 
        uint256 indexed allocationId, 
        uint256 epoch,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a curation is denied for claiming rewards.
     */
    event RewardsDenylistUpdated(
        uint256 indexed curationId, 
        uint256 sinceBlock,
        uint256 timestamp
    );

    /**
     * @notice Emitted when IssuanceRate update
     * 
     * @param prevIssuanceRate The preivous issuance rate of BCT token.
     * @param newIssuanceRate The new issuance rate of BCT token.
     * @param timestamp The current block timestamp.
     */
    event IssuanceRateSet(
        uint256 prevIssuanceRate,
        uint256 newIssuanceRate,
        uint256 timestamp
    );

    /**
     * @notice Emitted when TargetBondingRate update
     * 
     * @param prevTargetBondingRate The preivous target bonding rate of BCT token.
     * @param newTargetBondingRate The new target bonding rate of BCT token.
     * @param timestamp The current block timestamp.
     */
    event TargetBondingRateSet(
        uint256 prevTargetBondingRate,
        uint256 newTargetBondingRate,
        uint256 timestamp
    );

    /**
     * @notice Emitted when InflationChange update
     * 
     * @param prevInflationChange The preivous inflation Change of BCT token.
     * @param newInflationChange The new inflation Change of BCT token.
     * @param timestamp The current block timestamp.
     */
    event InflationChangeSet(
        uint256 prevInflationChange,
        uint256 newInflationChange,
        uint256 timestamp
    );

    /**
     * @notice Emitted when MinimumStakeingToken update
     * 
     * @param prevMinimumStakeingToken The previous Minimum amount of tokens on a curation required to accrue rewards.
     * @param newMinimumStakeingToken The New minimum amount of tokens on a curation required to accrue rewards.
     * @param timestamp The current block timestamp.
     */
    event MinimumStakeingTokenSet(
        uint256 prevMinimumStakeingToken,
        uint256 newMinimumStakeingToken,
        uint256 timestamp
    );

    /**
     * @notice Emitted when ThawingPeriod update
     * 
     * @param prevThawingPeriod The previous Period in blocks to wait for token withdrawals after unstaking
     * @param newThawingPeriod The new Period in blocks to wait for token withdrawals after unstaking
     * @param timestamp The current block timestamp.
     */
    event ThawingPeriodSet(
        uint32 prevThawingPeriod,
        uint32 newThawingPeriod,
        uint256 timestamp
    );

    /**
     * @notice Emitted when ThawingPeriod update
     * 
     * @param prevChannelDisputeEpochs The previous Period in blocks to wait for token withdrawals after unstaking
     * @param newChannelDisputeEpochs The new Period in blocks to wait for token withdrawals after unstaking
     * @param timestamp The current block timestamp.
     */
    event ChannelDisputeEpochsSet(
        uint32 prevChannelDisputeEpochs,
        uint32 newChannelDisputeEpochs,
        uint256 timestamp
    );

    /**
     * @notice Emitted when stakingAddress update
     * 
     * @param prevStakingAddress The previous stakingAddress
     * @param newStakingAddress The new stakingAddress
     * @param timestamp The current block timestamp.
     */
    event StakingAddressSet(
        address prevStakingAddress,
        address newStakingAddress,
        uint256 timestamp
    );

    /**
     * @notice Emitted when ReserveRatio update
     * 
     * @param prevStakingReserveRatio The previous prevStakingReserveRatio.
     * @param newStakingReserveRatio The new newStakingReserveRatio.
     * @param timestamp The current block timestamp.
     */
    event DefaultStakingReserveRatioSet(
        uint32 prevStakingReserveRatio,
        uint32 newStakingReserveRatio,
        uint256 timestamp
    );

    /**
     * @notice Emitted when RebateRatio update
     * 
     * @param alphaNumerator Numerator of `alpha` in the cobb-douglas function
     * @param alphaDenominator Denominator of `alpha` in the cobb-douglas function
     * @param timestamp The current block timestamp.
     */
    event RebateRatioSet(
        uint32 alphaNumerator,
        uint32 alphaDenominator,
        uint256 timestamp
    );

    /**
     * @notice Emitted when `delegator` deposited `tokens` on `curationId` as share.
     * The `delegator` receives `share` amount according to the pool bonding curve.
     * An amount of `stakingTax` will be collected and burned.
     */
    event CurationPoolStaked(
        address indexed delegator,
        uint256 indexed curationId,
        uint256 tokens,
        uint256 shares,
        uint256 stakingTax,
        uint256 timestamp
    );

    /**
     * @notice Emitted when `delegator` undelegated `tokens` from `curationId`.
     * Tokens get locked for withdrawal after a period of time.
     * 
     * @param delegator delegator
     * @param curationId Curation Id
     * @param shares shares to be burnt
     * @param tokens tokens to be locked
     * @param until A time tokens unlock for withdrawal.
     * @param timestamp The current block timestamp.
     */
    event StakeDelegatedLocked(
        address indexed delegator,
        uint256 indexed curationId,
        uint256 shares,
        uint256 tokens,
        uint256 until,
        uint256 timestamp
    );

    /**
     * @notice Emitted when `delegator` withdrew delegated `tokens` from `curationId`.
     * 
     * @param curationId Curation Id
     * @param delegator delegator
     * @param tokens Amount of tokens withdrawn.
     * @param timestamp The current block timestamp.
     */
    event StakeDelegatedWithdrawn(
        uint256 indexed curationId,
        address indexed delegator,
        uint256 tokens,
        uint256 timestamp
    );

    /**
     * @notice Emitted when hub allocated `tokens` amount to `curationId`
     * during `epoch`.
     * `allocationId` indexer derived address used to identify the allocation.
     */
    event AllocationCreated(
        uint256 indexed curationId,
        uint256 indexed allocationId,
        uint256 epoch,
        uint256 timestamp
    );

    /**
     * @notice Emitted when hub close an allocation in `epoch` for `curationId`.
     * An amount of `tokens` get unallocated from `curationId`.
     * The `effectiveAllocation` are the tokens allocated from creation to closing.
     */
    event AllocationClosed(
        uint256 indexed curationId,
        uint256 epoch,
        uint256 tokens,
        uint256 indexed allocationId,
        uint256 effectiveAllocationStake,
        address sender,
        uint256 stakeToCuration,
        bool isCurator,
        uint256 timestamp
    );

    /**
     * @notice Emitted when `curator` claimed a rebate on `curationId` during `epoch`
     * related to the `forEpoch` rebate pool.
     * The rebate is for `tokens` amount and `unclaimedAllocationsCount` are left for claim
     * in the rebate pool. `delegationFees` collected and sent to delegation pool.
     */
    event RebateClaimed(
        uint256 indexed curationId,
        uint256 indexed allocationId,
        address currency,
        uint256 epoch,
        uint256 forEpoch,
        uint256 tokens,
        uint256 unclaimedAllocationsCount,
        uint256 delegationFees,
        uint256 timestamp
    );

    /**
     * @notice Emitted when `indexer` collected `tokens` amount in `epoch` for `allocationId`.
     * These funds are related to `curationId`.
     * The `from` value is the sender of the collected funds.
     */
    event AllocationCollected(
        uint256 indexed curationId,
        uint256 epoch,
        uint256 tokens,
        uint256 indexed allocationId,
        address from,
        address currency,
        uint256 timestamp
    );

    /**
     * @notice Emitted upon a successful collect action.
     *
     * @param collector The address collecting the NFT.
     * @param curationId The token ID of the curation.
     * @param tokenContractPointed The address of the NFT contract whose NFT is being collected.
     * @param tokenIdPointed The token ID of NFT being collected.
     * @param collectModuleData The data passed to the collect module.
     * @param timestamp The current block timestamp.
     */
    event Collected(
        address indexed collector,
        uint256 indexed curationId,
        address tokenContractPointed,
        uint256 tokenIdPointed,
        bytes collectModuleData,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {BardsCurationBase} from './curations/BardsCurationBase.sol';
import {BardsHubStorage} from './storages/BardsHubStorage.sol';
import {IBardsHub} from '../interfaces/IBardsHub.sol';
import {DataTypes} from '../utils/DataTypes.sol';
import {IBardsStaking} from '../interfaces/tokens/IBardsStaking.sol';
import {VersionedInitializable} from '../upgradeablity/VersionedInitializable.sol';
import {CurationHelpers} from '../utils/CurationHelpers.sol';
import {CodeUtils} from '../utils/CodeUtils.sol';
import {Errors} from '../utils/Errors.sol';
import {Events} from '../utils/Events.sol';
import {Constants} from '../utils/Constants.sol';
import {BardsPausable} from './govs/BardsPausable.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/**
 * @title BardsHub
 * @author TheBards Protocol
 *
 * @notice This is the main entrypoint of the Bards Protocol.
 */
contract BardsHub is
    BardsCurationBase,
    VersionedInitializable,
    BardsPausable,
    BardsHubStorage,
    IBardsHub
{
    using CurationHelpers for DataTypes.CreateCurationData;
    using CurationHelpers for DataTypes.UpdateCurationDataParamsData;
    using CodeUtils for DataTypes.SetCurationContentURIWithSigData;
    using CodeUtils for DataTypes.SetAllocationIdWithSigData;
    using CodeUtils for DataTypes.SetMarketModuleWithSigData;
    using CodeUtils for DataTypes.CreateCurationWithSigData;
    using CodeUtils for DataTypes.DoCollectWithSigData;
    using CodeUtils for DataTypes.SetDefaultProfileWithSigData;

    uint256 internal constant REVISION = 1;
    
    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyGov() {
        _validateCallerIsGovernance();
        _;
    }

    /// @inheritdoc IBardsHub
    function initialize(
        string calldata name,
        string calldata symbol,
        address newGovernance,
        uint32 cooldownBlocks
    ) 
        external 
        override 
        initializer
    {
        BardsCurationBase._initialize(name, symbol, cooldownBlocks);
        _setState(DataTypes.ProtocolState.Paused);
        _setGovernance(newGovernance);
    }

    /// ***********************
    /// *****GOV FUNCTIONS*****
    /// ***********************

    /// @inheritdoc IBardsHub
    function setGovernance(address newGovernance) 
        external 
        override 
        onlyGov {
            _setGovernance(newGovernance);
    }

    /// @inheritdoc IBardsHub
    function setEmergencyAdmin(address newEmergencyAdmin)
        external
        override
        onlyGov{
        address prevEmergencyAdmin = _emergencyAdmin;
        _emergencyAdmin = newEmergencyAdmin;
        emit Events.EmergencyAdminSet(
            msg.sender,
            prevEmergencyAdmin,
            newEmergencyAdmin,
            block.timestamp
        );
    }

    /// @inheritdoc IBardsHub
    function setState(DataTypes.ProtocolState newState) external override {
        if (msg.sender == _emergencyAdmin) {
            if (newState == DataTypes.ProtocolState.Unpaused)
                revert Errors.EmergencyAdminCannotUnpause();
            _validateNotPaused();
        } else if (msg.sender != _governance) {
            revert Errors.NotGovernanceOrEmergencyAdmin();
        }
        _setState(newState);
    }

    /// @inheritdoc IBardsHub
    function setCooldownBlocks(
        uint32 _blocks
    ) 
        external 
        override 
        onlyGov 
    {

        _setCooldownBlocks(_blocks);
    }

    ///@inheritdoc IBardsHub
    function whitelistProfileCreator(address profileCreator, bool whitelist)
        external
        override
        onlyGov
    {
        _profileCreatorWhitelisted[profileCreator] = whitelist;
        emit Events.ProfileCreatorWhitelisted(
            profileCreator,
            whitelist,
            block.timestamp
        );
    }

    /// @inheritdoc IBardsHub
    function whitelistMarketModule(address marketModule, bool whitelist)
        external
        override
        onlyGov
    {
        _marketModuleWhitelisted[marketModule] = whitelist;
        emit Events.MarketModuleWhitelisted(
            marketModule,
            whitelist,
            block.timestamp
        );
    }

    /// @inheritdoc IBardsHub
    function whitelistMinterModule(address minterModule, bool whitelist)
        external
        override
        onlyGov
    {
        _minterModuleWhitelisted[minterModule] = whitelist;
        emit Events.MinterModuleWhitelisted(
            minterModule,
            whitelist,
            block.timestamp
        );
    }

    /// @inheritdoc IBardsHub
    function registerContract(
        bytes32 _id, 
        address _contractAddress
    )
        external
        override
        onlyGov
    {
        require(_contractAddress != address(0), "Contract address must be set");
        _registry[_id] = _contractAddress;
        _isRegisteredAddress[_contractAddress] = true;
        emit Events.ContractRegistered(
            _id, 
            _contractAddress, 
            block.timestamp
        );
    }

    /// @inheritdoc IBardsHub
    function unsetContract(bytes32 _id) 
        external 
        override 
        onlyGov 
    {
        _registry[_id] = address(0);
        emit Events.ContractRegistered(_id, address(0), block.timestamp);
    }

    /// @inheritdoc IBardsHub
    function getContractAddressRegistered(bytes32 _id) 
        public 
        view 
        override 
        returns (address) 
    {
        return _registry[_id];
    }

    /// *********************************
    /// *****PROFILE OWNER FUNCTIONS*****
    /// *********************************

    /// @inheritdoc IBardsHub
    function createProfile(DataTypes.CreateCurationData memory vars)
        external
        override
        whenNotPaused
        returns (uint256)
    {
        if (!_profileCreatorWhitelisted[msg.sender])
            revert Errors.ProfileCreatorNotWhitelisted();

        unchecked {
            uint256 profileId = ++_curationCounter;
            uint256 allocationId = ++_allocationCounter;
            _mint(vars.to, profileId);
            vars.profileId = profileId;
            vars.tokenContractPointed = address(this);
            vars.tokenIdPointed = profileId;
            
            vars.createProfile(
                allocationId,
                _cooldownBlocks,
                _getBardsStaking(),
                _curationData,
                _profileIdByHandleHash,
                _curationById,
                _marketModuleWhitelisted,
                _isToBeClaimedByAllocByCurator
            );

            return profileId;
        }
    }

    /// @inheritdoc IBardsHub
    function setDefaultProfile(uint256 profileId)
        external
        override
        whenNotPaused
    {
        _setDefaultProfile(msg.sender, profileId);
    }

    /// @inheritdoc IBardsHub
    function setDefaultProfileWithSig(
        DataTypes.SetDefaultProfileWithSigData calldata vars
    ) 
        external 
        override 
        whenNotPaused 
    {
        unchecked {
            _validateRecoveredAddress(
                vars.encodeDefaultProfileWithSigMessage(
                    sigNonces[vars.wallet]++
                ),
                name(),
                vars.wallet,
                vars.sig
            );
            _setDefaultProfile(vars.wallet, vars.profileId);
        }
    }

    /// @inheritdoc IBardsHub
    function setCurationContentURI(
        uint256 curationId, 
        string calldata contentURI
    )
        external
        override
        whenNotPaused
    {
        _validateCallerIsCurationOwnerOrApproved(curationId);
        _setCurationContentURI(curationId, contentURI);
    }

    /// @inheritdoc IBardsHub
    function setCurationContentURIWithSig(
        DataTypes.SetCurationContentURIWithSigData calldata vars
    )
        external
        override
        whenNotPaused 
    {
        address owner = ownerOf(vars.curationId);
        unchecked {
            _validateRecoveredAddress(
                vars.encodeCurationContentURIWithSigMessage(
                    sigNonces[owner]++
                ),
                name(),
                owner,
                vars.sig
            );
        }
        _setCurationContentURI(vars.curationId, vars.contentURI);
    }

    /// @inheritdoc IBardsHub
    function setAllocationId(
        DataTypes.SetAllocationIdData calldata vars
    )
        external
        override
        whenNotPaused
    {
        _validateCallerIsCurationOwnerOrApproved(vars.curationId);
        if (vars.allocationId == 0)
            revert Errors.ZeroAllocationId();
        if (_existsAllocationId(vars.allocationId))
            revert Errors.AllocationExists();

        address owner = ownerOf(vars.curationId);
        // reset allocation
        _getBardsStaking().closeAndAllocate(
            _curationById[vars.curationId].allocationId,
            vars.stakeToCuration,
            DataTypes.CreateAllocateData({
                curator: owner,
                curationId: vars.curationId,
                recipientsMeta: vars.curationMetaData,
                allocationId: vars.allocationId
            })
        );
        _curationById[vars.curationId].allocationId = vars.allocationId;
        _isToBeClaimedByAllocByCurator[owner][vars.allocationId] = true;
        
        emit Events.AllocationIdSet(
            vars.curationId,
            vars.allocationId,
            vars.curationMetaData,
            vars.stakeToCuration,
            block.timestamp
        );
    }

    /// @inheritdoc IBardsHub
    function setAllocationIdWithSig(
        DataTypes.SetAllocationIdWithSigData calldata vars
    )
        external
        override
        whenNotPaused
    {
        if (vars.allocationId == 0)
            revert Errors.ZeroAllocationId();
        if (_existsAllocationId(vars.allocationId))
            revert Errors.AllocationExists();
        address owner = ownerOf(vars.curationId);

        unchecked {
            _validateRecoveredAddress(
                vars.encodeAllocationIdWithSigMessage(
                    sigNonces[owner]++
                ),
                name(),
                owner,
                vars.sig
            );
        }

        // init allocation
        _getBardsStaking().closeAndAllocate(
            _curationById[vars.curationId].allocationId,
            vars.stakeToCuration,
            DataTypes.CreateAllocateData({
                curator: owner,
                curationId: vars.curationId,
                recipientsMeta: vars.curationMetaData,
                allocationId: vars.allocationId
            })
        );
        _curationById[vars.curationId].allocationId = vars.allocationId;
        _isToBeClaimedByAllocByCurator[owner][vars.allocationId] = true;

        emit Events.AllocationIdSet(
            vars.curationId,
            vars.allocationId,
            vars.curationMetaData,
            vars.stakeToCuration,
            block.timestamp
        );
    }

    /// @inheritdoc IBardsHub
    function setMarketModule(DataTypes.SetMarketModuleData calldata vars)
        external
        override
        whenNotPaused
    {
        _validateCallerIsCurationOwnerOrApproved(vars.curationId);
        CurationHelpers.setMarketModule(
            vars.curationId,
            vars.tokenContract,
            vars.tokenId,
            vars.marketModule,
            vars.marketModuleInitData,
            _curationById[vars.curationId],
            _marketModuleWhitelisted
        );
    }

    /// @inheritdoc IBardsHub
    function setMarketModuleWithSig(
        DataTypes.SetMarketModuleWithSigData calldata vars
    ) external override whenNotPaused {
        address owner = ownerOf(vars.curationId);
        unchecked {
            _validateRecoveredAddress(
                vars.encodeMarketModuleWithSigMessage(
                    sigNonces[owner]++
                ),
                name(),
                owner,
                vars.sig
            );
        }
        CurationHelpers.setMarketModule(
            vars.curationId,
            vars.tokenContract,
            vars.tokenId,
            vars.marketModule,
            vars.marketModuleInitData,
            _curationById[vars.curationId],
            _marketModuleWhitelisted
        );
    }

    /// @inheritdoc IBardsHub
    function setMinterMarketModule(DataTypes.SetMarketModuleData calldata vars)
        external
        override
        whenNotPaused
    {
        _validateCallerIsCurationOwnerOrApproved(vars.curationId);
        CurationHelpers.setMinterMarketModule(
            vars.curationId,
            vars.tokenContract,
            vars.tokenId,
            vars.marketModule,
            vars.marketModuleInitData,
            _curationById[vars.curationId],
            _marketModuleWhitelisted
        );
    }

    /// @inheritdoc IBardsHub
    function setMinterMarketModuleWithSig(
        DataTypes.SetMarketModuleWithSigData calldata vars
    ) 
        external 
        override 
        whenNotPaused 
    {
        address owner = ownerOf(vars.curationId);
        unchecked {
            _validateRecoveredAddress(
                vars.encodeMarketModuleWithSigMessage(
                    sigNonces[owner]++
                ),
                name(),
                owner,
                vars.sig
            );
        }
        CurationHelpers.setMinterMarketModule(
            vars.curationId,
            vars.tokenContract,
            vars.tokenId,
            vars.marketModule,
            vars.marketModuleInitData,
            _curationById[vars.curationId],
            _marketModuleWhitelisted
        );
    }

    /// @inheritdoc IBardsHub
    function createCuration(DataTypes.CreateCurationData calldata vars)
        external
        override
        whenCurationEnabled
        returns (uint256)
    {
        _validateCallerIsCurationOwnerOrApproved(vars.profileId);
        return _createCuration(vars);
    }

    /// @inheritdoc IBardsHub
    function createCurationWithSig(
        DataTypes.CreateCurationWithSigData calldata vars
    )
        external
        override
        whenCurationEnabled
        returns (uint256)
    { 
        address owner = ownerOf(vars.profileId);
        unchecked {
            _validateRecoveredAddress(
                vars.encodeCreateCurationWithSigMessage(
                    sigNonces[owner]++
                ),
                name(),
                owner,
                vars.sig
            );
        }
        return _createCuration(
            DataTypes.CreateCurationData({
                to: owner,
                curationType: vars.curationType,
                profileId: vars.profileId,
                curationId: vars.curationId,
                tokenContractPointed: vars.tokenContractPointed,
                tokenIdPointed: vars.tokenIdPointed,
                handle: vars.handle,
                contentURI: vars.contentURI,
                marketModule: vars.marketModule,
                marketModuleInitData: vars.marketModuleInitData,
                minterMarketModule: vars.minterMarketModule,
                minterMarketModuleInitData: vars.minterMarketModuleInitData,
                curationMetaData: vars.curationMetaData,
                curationFrom: vars.curationFrom
            }
        ));
    }

    /// @inheritdoc IBardsHub
	function updateCuration(
        DataTypes.InitializeCurationData memory _vars
    )
		external
		override
	{

        _validateCallerIsCurationOwnerOrApproved(_vars.tokenId);
        
        // reset allocation for curation
        address owner = ownerOf(_vars.tokenId);
        uint256 newAllocationId = ++_allocationCounter;
        
		CurationHelpers.setCurationRecipientsParams(
            _vars, 
            owner,
            newAllocationId,
            _cooldownBlocks, 
            _getBardsStaking(),
            _curationData,
            _curationById,
            _isToBeClaimedByAllocByCurator
        );
	}

    // /// @inheritdoc IBardsHub
	// function setSellerFundsRecipientsParams(
	// 	uint256 tokenId, 
	// 	address[] calldata sellerFundsRecipients
	// ) 
	// 	external 
	// 	override 
	// {
    //     _validateCallerIsCurationOwnerOrApproved(tokenId);

    //     // reset allocation for curation
    //     address owner = ownerOf(tokenId);
    //     uint256 newAllocationId = ++_allocationCounter;

    //     CurationHelpers.setSellerFundsRecipientsParams(
    //         sellerFundsRecipients, 
    //         DataTypes.UpdateCurationDataParamsData({
    //             owner: owner,
    //             tokenId: tokenId,
    //             newAllocationId: newAllocationId,
    //             minimalCooldownBlocks: _cooldownBlocks,
    //             bardsStaking: _getBardsStaking()
    //         }),
    //         _curationData,
    //         _curationById,
    //         _isToBeClaimedByAllocByCurator
    //     );
	// }

    // /// @inheritdoc IBardsHub
	// function setCurationFundsRecipientsParams(uint256 tokenId, uint256[] calldata curationFundsRecipients) 
	// 	external 
	// 	virtual 
	// 	override 
	// {
    //     _validateCallerIsCurationOwnerOrApproved(tokenId);
    //     // reset allocation for curation
    //     address owner = ownerOf(tokenId);
    //     uint256 newAllocationId = ++_allocationCounter;

    //     CurationHelpers.setCurationFundsRecipientsParams(
    //         curationFundsRecipients, 
    //         DataTypes.UpdateCurationDataParamsData({
    //             owner: owner,
    //             tokenId: tokenId,
    //             newAllocationId: newAllocationId,
    //             minimalCooldownBlocks: _cooldownBlocks,
    //             bardsStaking: _getBardsStaking()
    //         }),
    //         _curationData,
    //         _curationById,
    //         _isToBeClaimedByAllocByCurator
    //     );
	// }

    // /// @inheritdoc IBardsHub
	// function setSellerFundsBpsesParams(uint256 tokenId, uint32[] calldata sellerFundsBpses) 
	// 	external 
	// 	override 
	// {
    //     _validateCallerIsCurationOwnerOrApproved(tokenId);
    //     // reset allocation for curation
    //     address owner = ownerOf(tokenId);
    //     uint256 newAllocationId = ++_allocationCounter;

    //     CurationHelpers.setSellerFundsBpsesParams(
    //         sellerFundsBpses, 
    //         DataTypes.UpdateCurationDataParamsData({
    //             owner: owner,
    //             tokenId: tokenId,
    //             newAllocationId: newAllocationId,
    //             minimalCooldownBlocks: _cooldownBlocks,
    //             bardsStaking: _getBardsStaking()
    //         }),
    //         _curationData,
    //         _curationById,
    //         _isToBeClaimedByAllocByCurator
    //     );
	// }

    // /// @inheritdoc IBardsHub
	// function setCurationFundsBpsesParams(
    //     uint256 tokenId, 
    //     uint32[] calldata curationFundsBpses
    // ) 
	// 	external 
	// 	override 
	// {
    //     _validateCallerIsCurationOwnerOrApproved(tokenId);

    //     // reset allocation for curation
    //     address owner = ownerOf(tokenId);
    //     uint256 newAllocationId = ++_allocationCounter;

    //     CurationHelpers.setCurationFundsBpsesParams(
    //         curationFundsBpses,  
    //         DataTypes.UpdateCurationDataParamsData({
    //             owner: owner,
    //             tokenId: tokenId,
    //             newAllocationId: newAllocationId,
    //             minimalCooldownBlocks: _cooldownBlocks,
    //             bardsStaking: _getBardsStaking()
    //         }),
    //         _curationData,
    //         _curationById,
    //         _isToBeClaimedByAllocByCurator
    //     );
	// }

    // /// @inheritdoc IBardsHub
	// function setBpsParams(
    //     uint256 tokenId, 
    //     uint32 curationBps, 
    //     uint32 stakingBps
    // ) 
	// 	external 
	// 	override 
	// {
    //     _validateCallerIsCurationOwnerOrApproved(tokenId);

    //     // reset allocation for curation
    //     address owner = ownerOf(tokenId);
    //     uint256 newAllocationId = ++_allocationCounter;
    
	// 	CurationHelpers.setBpsParams( 
    //         curationBps,
    //         stakingBps, 
    //         DataTypes.UpdateCurationDataParamsData({
    //             owner: owner,
    //             tokenId: tokenId,
    //             newAllocationId: newAllocationId,
    //             minimalCooldownBlocks: _cooldownBlocks,
    //             bardsStaking: _getBardsStaking()
    //         }), 
    //         _curationData,
    //         _curationById,
    //         _isToBeClaimedByAllocByCurator
    //     );
	// }

    /// @inheritdoc IBardsHub
    function removeAllocation(
        address curator, 
        uint256 allocationId
    ) 
        external {
        delete _isToBeClaimedByAllocByCurator[curator][allocationId];
    }

    /// @inheritdoc IBardsHub
    function collect(
        DataTypes.SimpleDoCollectData calldata vars
    ) 
        external 
        override 
        whenNotPaused 
        returns (address, uint256)
    {
        return CurationHelpers.collect(
            msg.sender,
            vars,
            _curationById
        );
    }

    /// @inheritdoc IBardsHub
    function collectWithSig(
        DataTypes.DoCollectWithSigData calldata vars
    )
        external
        override
        whenNotPaused
        returns (address, uint256)
    {
        unchecked {
            _validateRecoveredAddress(
                vars.encodecollectWithSigMessage(
                    sigNonces[vars.collector]++
                ),
                name(),
                vars.collector,
                vars.sig
            );
        }
        return CurationHelpers.collect(
            vars.collector,
            DataTypes.SimpleDoCollectData({
                curationId: vars.curationId,
                curationIds: vars.curationIds,
                collectMetaData: vars.collectMetaData,
                fromCuration: vars.fromCuration
            }),
            _curationById
        );
    }

    /// @inheritdoc IBardsHub
    function whitelistCurrency(
        address currency, 
        bool toWhitelist
    ) 
        external 
        override 
        onlyGov 
    {
        _whitelistCurrency(currency, toWhitelist);
    }

    /// *********************************
    /// *****EXTERNAL VIEW FUNCTIONS*****
    /// *********************************

    /// @inheritdoc IBardsHub
    function isAuthForCurator(address operator, address curator)
        external
        view
        override
        returns (bool)
    {
        return (operator == curator ||
            isApprovedForAll(curator, operator));
    }

    /// @inheritdoc IBardsHub
    function isCurrencyWhitelisted(address currency) 
        external 
        view 
        override 
        returns (bool) 
    {
        return _currencyWhitelisted[currency];
    }

    /// @inheritdoc IBardsHub
    function isProfileCreatorWhitelisted(address profileCreator)
        external
        view
        override
        returns (bool)
    {
        return _profileCreatorWhitelisted[profileCreator];
    }

    /// @inheritdoc IBardsHub
    function isMarketModuleWhitelisted(address marketModule)
        external
        view
        override
        returns (bool)
    {
        return _marketModuleWhitelisted[marketModule];
    }

    /// @inheritdoc IBardsHub
    function isMinterModuleWhitelisted(address minterModule)
        external
        view
        override
        returns (bool)
    {
        return _minterModuleWhitelisted[minterModule];
    }

    /// @inheritdoc IBardsHub
    function getGovernance() 
        external 
        view 
        override 
        returns (address) {
            return _governance;
    }

    /// @inheritdoc IBardsHub
    function defaultProfile(address wallet)
        external
        view
        override
        returns (uint256)
    {
        return _defaultProfileByAddress[wallet];
    }

    /// @inheritdoc IBardsHub
    function getAllocationIdById(uint256 curationId)
        external
        view
        override
        returns (uint256)
    {
        return _curationById[curationId].allocationId;
    }

    /// @inheritdoc IBardsHub
    function getHandle(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        return _curationById[profileId].handle;
    }

    /// @inheritdoc IBardsHub
    function getProfileIdByHandle(string calldata handle)
        external
        view
        override
        returns (uint256)
    {
        bytes32 handleHash = keccak256(bytes(handle));
        return _profileIdByHandleHash[handleHash];
    }

    /// @inheritdoc IBardsHub
    function getCuration(uint256 curationId)
        external
        view
        override
        returns (DataTypes.CurationStruct memory)
    {
        return _curationById[curationId];
    }

    /// @inheritdoc IBardsHub
    function getProfile(uint256 profileId)
        external
        view
        override
        returns (DataTypes.CurationStruct memory)
    {
        return _curationById[profileId];
    }

    /// @inheritdoc IBardsHub
    function getMarketModule(uint256 curationId)
        external
        view
        override
        returns (address)
    {
        return _curationById[curationId].marketModule;
    }

    /// @inheritdoc IBardsHub
    function getMinterMarketModule(uint256 curationId)
        external
        view
        override
        returns (address)
    {
        return _curationById[curationId].minterMarketModule;
    }

    /// @inheritdoc IBardsHub
    function getContentURI(uint256 curationId)
        external
        view
        override
        returns (string memory)
    {
        return _curationById[curationId].contentURI;
    }

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _createCuration(DataTypes.CreateCurationData memory _vars)
        internal
        returns (uint256)
    {
        unchecked {
            uint256 curationId = ++_curationCounter;
            uint256 allocationId = ++_allocationCounter;
            _mint(_vars.to, curationId);
            _vars.curationId = curationId;
            
            // Not refer to other NFT contract.
            if (_vars.tokenContractPointed == address(0)){
                _vars.tokenContractPointed = address(this);
                _vars.tokenIdPointed = curationId;
            } else {
                // Get the owner of the specified token
                address tokenOwner = IERC721(_vars.tokenContractPointed).ownerOf(_vars.tokenIdPointed);
                // Ensure the caller is the owner or an approved operator
                require(
                    _isRegisteredAddress[msg.sender] == true || 
                    msg.sender == tokenOwner || 
                    IERC721(_vars.tokenContractPointed).isApprovedForAll(tokenOwner, msg.sender), 
                    "ONLY_TOKEN_OWNER_OR_OPERATOR"
                );
            }
            _vars.createCuration(
                allocationId,
                _cooldownBlocks,
                _getBardsStaking(),
                _curationData,
                _curationById,
                _marketModuleWhitelisted,
                _isToBeClaimedByAllocByCurator
            );

            return curationId;
        }
    }

    function _setCurationContentURI(
        uint256 curationId, 
        string calldata contentURI
    ) 
        internal 
    {
        if (bytes(contentURI).length > Constants.MAX_CURATION_CONTENT_URI_LENGTH)
            revert Errors.CurationContentURILengthInvalid();

        _curationById[curationId].contentURI = contentURI;

        emit Events.CurationContentURISet(
            curationId, 
            contentURI, 
            block.timestamp
        );
    }

    function _setGovernance(address newGovernance) internal {
        address prevGovernance = _governance;
        _governance = newGovernance;
        emit Events.GovernanceSet(
            msg.sender,
            prevGovernance,
            newGovernance,
            block.timestamp
        );
    }

    function _whitelistCurrency(address currency, bool toWhitelist) internal {
        if (currency == address(0)) revert Errors.ZeroAddress();
        bool prevWhitelisted = _currencyWhitelisted[currency];
        _currencyWhitelisted[currency] = toWhitelist;
        emit Events.ProtocolCurrencyWhitelisted(
            currency,
            prevWhitelisted,
            toWhitelist,
            block.timestamp
        );
    }

    /*
     * If the profile ID is zero, this is the equivalent of "unsetting" a default profile.
     * Note that the wallet address should either be the message sender or validated via a signature
     * prior to this function call.
     */
    function _setDefaultProfile(address wallet, uint256 profileId) internal {
        if (profileId > 0 && wallet != ownerOf(profileId))
            revert Errors.NotOwner();

        _defaultProfileByAddress[wallet] = profileId;

        emit Events.DefaultProfileSet(
            wallet, 
            profileId, 
            block.timestamp
        );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) 
        internal 
        override 
        whenNotPaused 
    {
        if (_defaultProfileByAddress[from] == tokenId) {
            _defaultProfileByAddress[from] = 0;
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _validateCallerIsCurationOwnerOrApproved(
        uint256 curationId
    ) 
        internal 
        view 
    {
        if (_isRegisteredAddress[msg.sender] == true || _isApprovedOrOwner(msg.sender, curationId)) {
            return;
        }
        revert Errors.NotOwnerOrApproved();
    }

    function _validateCallerIsCurationOwner(
        uint256 curationId
    ) 
        internal 
        view 
    {
        if (msg.sender != ownerOf(curationId)) revert Errors.NotOwner();
    }

    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
        // require(msg.sender == _governance, 'not_gov');
    }

    function _existsAllocationId(uint256 allocationId) internal view returns (bool) {
        return _getBardsStaking().isAllocation(allocationId);
    }

    function _getBardsStaking() internal view returns (IBardsStaking) {
        return IBardsStaking(_registry[keccak256("BardsStaking")]);
    } 

    function getRevision() internal pure override returns (uint256) {
        return REVISION;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IContractRegistrar} from '../../interfaces/govs/IContractRegistrar.sol';
import {IBardsHub} from '../../interfaces/IBardsHub.sol';
import {Events} from '../../utils/Events.sol';
import {IBardsShareToken} from '../../interfaces/tokens/IBardsShareToken.sol';
import {IBardsCurationToken} from '../../interfaces/tokens/IBardsCurationToken.sol';
import {IBardsStaking} from '../../interfaces/tokens/IBardsStaking.sol';
import {IRewardsManager} from '../../interfaces/govs/IRewardsManager.sol';
import {IEpochManager} from '../../interfaces/govs/IEpochManager.sol';
import {IBardsDaoData} from '../../interfaces/govs/IBardsDaoData.sol';
import {IProgrammableMinter} from '../../interfaces/minters/IProgrammableMinter.sol';
import {IWETH} from '../trades/IWETH.sol';

/**
 * @title ContractRegistrar
 * 
 * @author TheBards Protocol
 * 
 * @notice This contract provides an interface to interact with the HUB.
 *
 * Inspired by Livepeer:
 * https://github.com/livepeer/protocol/blob/streamflow/contracts/Controller.sol
 */
abstract contract ContractRegistrar is IContractRegistrar {
	address internal HUB;
    mapping(bytes32 => address) private addressCache;

	modifier onlyHub() {
        require(msg.sender == HUB, "Only HUB can call");
        _;
    }

    modifier onlyGov(){
        require(msg.sender == bardsHub().getGovernance(), 'Only governance can call');
        _;
    }

    /**
     * @notice Initialize the controller.
     */
    function _initialize(address _HUB) internal {
        _setHub(_HUB);
    }

    /// @inheritdoc IContractRegistrar
    function setHub(address _HUB) external override onlyHub {
        _setHub(_HUB);
    }

    /**
     * @notice Set HUB.
     * @param _HUB Controller contract address
     */
    function _setHub(address _HUB) internal {
        require(_HUB != address(0), "HUB must be set");
        HUB = _HUB;
        emit Events.HUBSet(_HUB, block.timestamp);
    }

    /**
     * @notice Return IBardsHub interface.
     * @return IBardsHub contract registered with HUB
     */
    function bardsHub() internal view returns (IBardsHub) {
        return IBardsHub(HUB);
    }

    /**
     * @notice Return IWETH interface.
     * @return IWETH contract registered with HUB
     */
    function iWETH() internal view returns (IWETH) {
        return IWETH(_resolveContract(keccak256("WETH")));
    }

    /**
     * @notice Return BardsBardsDaoDataStaking interface.
     * @return BardsDaoData contract registered with HUB
     */
    function bardsDataDao() internal view returns (IBardsDaoData) {
        return IBardsDaoData(_resolveContract(keccak256("BardsDaoData")));
    } 

    /**
     * @notice Return BardsStaking interface.
     * @return BardsStaking contract registered with HUB
     */
    function bardsStaking() internal view returns (IBardsStaking) {
        return IBardsStaking(_resolveContract(keccak256("BardsStaking")));
    } 

    /**
     * @notice Return BardsCurationToken interface.
     * @return Bards Curation token contract registered with HUB
     */
    function bardsCurationToken() internal view returns (IBardsCurationToken) {
        return IBardsCurationToken(_resolveContract(keccak256("BardsCurationToken")));
    }

    /**
     * @notice Return RewardsManager interface.
     * 
     * @return Rewards manager contract registered with HUB
     */
    function rewardsManager() internal view returns (IRewardsManager) {
        return IRewardsManager(_resolveContract(keccak256("RewardsManager")));
    }

    /**
     * @notice Return EpochManager interface.
     * 
     * @return Epoch manager contract registered with HUB
     */
    function epochManager() internal view returns (IEpochManager) {
        return IEpochManager(_resolveContract(keccak256("EpochManager")));
    }

    /**
     * @notice Return transferMinter as default minter interface.
     * 
     * @return Transfer Minter contract registered with HUB
     */
    function defaultMinter() internal view returns (IProgrammableMinter) {
        return IProgrammableMinter(_resolveContract(keccak256("TransferMinter")));
    }

    /**
     * @notice Resolve a contract address from the cache or the HUB if not found.
     * @return Address of the contract
     */
    function _resolveContract(bytes32 _nameHash) internal view returns (address) {
        address contractAddress = addressCache[_nameHash];
        if (contractAddress == address(0)) {
            contractAddress = bardsHub().getContractAddressRegistered(_nameHash);
        }
        return contractAddress;
    }

    /**
     * @notice Cache a contract address from the HUB _registry.
     * @param _name Name of the contract to sync into the cache
     */
    function _syncContract(string memory _name) internal {
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        address contractAddress = bardsHub().getContractAddressRegistered(nameHash);
        if (addressCache[nameHash] != contractAddress) {
            addressCache[nameHash] = contractAddress;
            emit Events.ContractSynced(nameHash, contractAddress, block.timestamp);
        }
    }

    /**
     * @notice Sync protocol contract addresses from the HUB _registry.
     * This function will cache all the contracts using the latest addresses
     * Anyone can call the function whenever a contract change in the
     * HUB to ensure the protocol is using the latest version
     */
    function syncAllContracts() external {
        _syncContract("WETH");
        _syncContract("BardsDaoData");
        _syncContract("BardsStaking");
        _syncContract("BardsCurationToken");
        _syncContract("RewardsManager");
        _syncContract("EpochManager");
        _syncContract("TransferMinter");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Lookup engine interface
 */
interface IRoyaltyEngineV1 is IERC165 {

    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     * 
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(address tokenAddress, uint256 tokenId, uint256 value) external returns(address payable[] memory recipients, uint256[] memory amounts);

    /**
     * View only version of getRoyalty
     * 
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(address tokenAddress, uint256 tokenId, uint256 value) external view returns(address payable[] memory recipients, uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DataTypes} from '../../utils/DataTypes.sol';

/**
 * @title IBardsCurationToken
 * @author TheBards Protocol
 *
 * @notice This is the standard interface for the BardsCurationToken contract.
 */
interface IBardsCurationToken is IERC20 {
     // -- Mint and Burn --
    function burn(uint256 amount) external;

    /**
     * @notice burn tokens from.
     * @param _from Address to burn tokens
     * @param _amount Amount of tokens to mint
     */
    function burnFrom(address _from, uint256 _amount) external;

    /**
     * @notice Mint new tokens.
     * @param _to Address to send the newly minted tokens
     * @param _amount Amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external;

    /**
     * @notice Add a new minter.
     * @param _account Address of the minter
     */
    function addMinter(address _account) external;

    /**
     * @notice Remove a minter.
     * @param _account Address of the minter
     */
    function removeMinter(address _account) external;

    /**
     * @notice Renounce to be a minter.
     */
    function renounceMinter() external;

    /**
     * @notice Return if the `_account` is a minter or not.
     * @param _account Address to check
     * @return True if the `_account` is minter
     */
    function isMinter(address _account) external view returns (bool);

    /**
     * @notice Approve token allowance by validating a message signed by the holder.
     *
     * @param _owner The token owern.
     * @param _spender The token spender.
     * @param _value Amount of tokens to approve the spender.
     * @param _sig The EIP712 signature struct.
     */
    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        DataTypes.EIP712Signature calldata _sig
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {Errors} from '../utils/Errors.sol';


/**
 * @title VersionedInitializable
 *
 * @notice Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * This is slightly modified from [Aave's version.](https://github.com/aave/protocol-v2/blob/6a503eb0a897124d8b9d126c915ffdf3e88343a9/contracts/protocol/libraries/aave-upgradeability/VersionedInitializable.sol)
 *
 * @author TheBards Protocol, inspired by Aave's implementation, which is in turn inspired by OpenZeppelin's
 * Initializable contract
 */
abstract contract VersionedInitializable {
    address private immutable originalImpl;

    /**
     * @notice Indicates that the contract has been initialized.
     */
    uint256 private lastInitializedRevision = 0;

    /**
     * @notice Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        uint256 revision = getRevision();

        if (address(this) == originalImpl) revert Errors.CannotInitImplementation();
        if (revision <= lastInitializedRevision) revert Errors.Initialized();
        lastInitializedRevision = revision;
        _;
    }

    constructor() {
        originalImpl = address(this);
    }

    /**
     * @notice returns the revision number of the contract
     * Needs to be defined in the inherited class as a constant.
     **/
    function getRevision() internal pure virtual returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.12;

import {DataTypes} from "./DataTypes.sol";

library CodeUtils {
	bytes32 internal constant SET_DEFAULT_PROFILE_WITH_SIG_TYPEHASH =
        keccak256(
            'SetDefaultProfileWithSig(address wallet,uint256 profileId,uint256 nonce,uint256 deadline)'
        );
	bytes32 internal constant SET_CURATION_CONTENT_URI_WITH_SIG_TYPEHASH =
        keccak256(
            'SetCurationContentURIWithSig(uint256 curationId,string contentURI,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant SET_MARKET_MODULE_WITH_SIG_TYPEHASH =
        keccak256(
            'SetMarketModuleWithSig(uint256 curationId,address tokenContract,uint256 tokenId,address marketModule,bytes marketModuleInitData,uint256 nonce,uint256 deadline)'
        );
	bytes32 internal constant CREATE_CURATION_WITH_SIG_TYPEHASH =
        keccak256(
            'CreateCurationWithSig(uint256 profileId,address tokenContractPointed,uint256 tokenIdPointed,string contentURI,address marketModule,bytes marketModuleInitData,address minterMarketModule,bytes minterMarketModuleInitData,bytes curationMetaData,uint256 nonce,uint256 deadline)'
        );
	bytes32 internal constant COLLECT_WITH_SIG_TYPEHASH =
        keccak256(
            'CollectWithSig(uint256 curationId,bytes collectMetaData,uint256 nonce,uint256 deadline)'
        );
	bytes32 internal constant SET_DISPATCHER_WITH_SIG_TYPEHASH =
        keccak256(
            'SetDispatcherWithSig(uint256 profileId,address dispatcher,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant SET_ALLOCATION_ID_WITH_SIG_TYPEHASH =
        keccak256(
            'SetAllocationIdWithSig(uint256 curationId,uint256 allocationId,bytes curationMetaData,uint256 stakeToCuration,uint256 nonce,uint256 deadline)'
        );

	function decodeCurationMetaData(
		bytes memory curationMetaData
	)
		internal
		pure
		returns (DataTypes.CurationData memory)
	{
		(
            address[] memory sellerFundsRecipients,
            uint256[] memory curationFundsRecipients,
            uint32[] memory sellerFundsBpses,
            uint32[] memory curationFundsBpses,
            uint32 curationBps,
            uint32 stakingBps
        ) = abi.decode(
            curationMetaData, 
            (address[], uint256[], uint32[], uint32[], uint32, uint32)
        );

		return DataTypes.CurationData({
			sellerFundsRecipients: sellerFundsRecipients,
			curationFundsRecipients: curationFundsRecipients,
			sellerFundsBpses: sellerFundsBpses,
			curationFundsBpses: curationFundsBpses,
			curationBps: curationBps,
			stakingBps: stakingBps,
			updatedAtBlock: 0
		});
	}

	function encodeCurationMetaData(
		DataTypes.CurationData memory curationMetaData
	)
		internal
		pure
		returns (bytes memory)
	{
		bytes memory _metaData = abi.encode(
			curationMetaData.sellerFundsRecipients, 
			curationMetaData.curationFundsRecipients,
			curationMetaData.sellerFundsBpses,
			curationMetaData.curationFundsBpses,
			curationMetaData.curationBps,
			curationMetaData.stakingBps
        );

		return _metaData;
	}

	function encodeDefaultProfileWithSigMessage(
		DataTypes.SetDefaultProfileWithSigData calldata vars,
		uint256 nonce
	)
		internal
		pure
		returns (bytes32)
	{
		return keccak256(
			abi.encode(
				SET_DEFAULT_PROFILE_WITH_SIG_TYPEHASH,
				vars.wallet,
				vars.profileId,
				nonce,
				vars.sig.deadline
			)
		);
	}

	function encodeCurationContentURIWithSigMessage(
		DataTypes.SetCurationContentURIWithSigData calldata vars,
		uint256 nonce
	)
		internal
		pure
		returns (bytes32)
	{
		return keccak256(
			abi.encode(
				SET_CURATION_CONTENT_URI_WITH_SIG_TYPEHASH,
				vars.curationId,
				keccak256(bytes(vars.contentURI)),
				nonce,
				vars.sig.deadline
			)
		);
	}

	function encodeAllocationIdWithSigMessage(
		DataTypes.SetAllocationIdWithSigData calldata vars,
		uint256 nonce
	)
		internal
		pure
		returns (bytes32)
	{
		return keccak256(
			abi.encode(
				SET_ALLOCATION_ID_WITH_SIG_TYPEHASH,
				vars.curationId,
				vars.allocationId,
				keccak256(vars.curationMetaData),
				vars.stakeToCuration,
				nonce,
				vars.sig.deadline
			)
		);
	}

	function encodeMarketModuleWithSigMessage(
		DataTypes.SetMarketModuleWithSigData calldata vars,
		uint256 nonce
	)
		internal
		pure
		returns (bytes32)
	{
		return keccak256(
			abi.encode(
				SET_MARKET_MODULE_WITH_SIG_TYPEHASH,
				vars.curationId,
				vars.tokenContract,
				vars.tokenId,
				vars.marketModule,
				keccak256(vars.marketModuleInitData),
				nonce,
				vars.sig.deadline
			)
		);
	}

	function encodeCreateCurationWithSigMessage(
		DataTypes.CreateCurationWithSigData calldata vars,
		uint256 nonce
	)
		internal
		pure 
		returns (bytes32)
	{
		return keccak256(
			abi.encode(
				CREATE_CURATION_WITH_SIG_TYPEHASH,
				vars.profileId,
				vars.tokenContractPointed,
				vars.tokenIdPointed,
				keccak256(bytes(vars.contentURI)),
				vars.marketModule,
				keccak256(vars.marketModuleInitData),
				vars.minterMarketModule,
				keccak256(vars.minterMarketModuleInitData),
				keccak256(vars.curationMetaData),
				nonce,
				vars.sig.deadline
			)
		);
	}

	function encodecollectWithSigMessage(
		DataTypes.DoCollectWithSigData calldata vars,
		uint256 nonce
	)
		internal
		pure
		returns (bytes32)
	{
		return keccak256(
			abi.encode(
				COLLECT_WITH_SIG_TYPEHASH,
				vars.curationId,
				keccak256(vars.collectMetaData),
				nonce,
				vars.sig.deadline
			)
		);
	}


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {DataTypes} from './DataTypes.sol';
import {Errors} from './Errors.sol';
import {Events} from './Events.sol';
import {Constants} from './Constants.sol';
import {CodeUtils} from './CodeUtils.sol';
import {MathUtils} from './MathUtils.sol';
import {IMarketModule} from '../interfaces/markets/IMarketModule.sol';
import {IBardsStaking} from '../interfaces/tokens/IBardsStaking.sol';

/**
 * @title CurationHelpers
 * @author TheBards Protocol
 *
 * @notice This is the library that contains the logic for profile creation, publication, and Interaction.
 *
 * @dev The functions are external, so they are called from the hub via `delegateCall` under the hood. Furthermore,
 * expected events are emitted from this library instead of from the hub to alleviate code size concerns.
 */
library CurationHelpers {
    using SafeMath for uint256;
	using CurationHelpers for DataTypes.CurationStruct;
	using CurationHelpers for DataTypes.CreateCurationData;

	/**
     * @notice Executes the logic to create a profile with the given parameters to the given address.
     *
     * @param _vars The CreateProfileData struct.
     * @param _allocationId allocationg id
     * @param _minimalCooldownBlocks minimal cool down blocks
     * @param _bardsStaking The address of BardsStaking contract
     * @param _curationData The storage reference to the mapping of curation data.
     * @param _profileIdByHandleHash The storage reference to the mapping of profile IDs by handle hash.
     * @param _curationById The storage reference to the mapping of profile structs by IDs.
     * @param _marketModuleWhitelisted The storage reference to the mapping of whitelist status by market module address.
     * @param _isToBeClaimedByAllocByCurator The storage reference to the mapping of claim status of allocation.
     */
    function createProfile(
        DataTypes.CreateCurationData memory _vars,
        uint256 _allocationId,
        uint32 _minimalCooldownBlocks,
        IBardsStaking _bardsStaking,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(bytes32 => uint256) storage _profileIdByHandleHash,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => bool) storage _marketModuleWhitelisted,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
    ) external {
        _validateHandle(_vars.handle);
        bytes32 handleHash = keccak256(bytes(_vars.handle));
        if (_profileIdByHandleHash[handleHash] != 0) revert Errors.HandleToken();

        _profileIdByHandleHash[handleHash] = _vars.profileId;

        _curationById[_vars.profileId].curationType = _vars.curationType;
        _curationById[_vars.profileId].handle = _vars.handle;
        _curationById[_vars.profileId].contentURI = _vars.contentURI;
        _curationById[_vars.profileId].tokenContractPointed = _vars.tokenContractPointed;
		_curationById[_vars.profileId].tokenIdPointed = _vars.tokenIdPointed;
        _curationById[_vars.profileId].curationFrom = _vars.curationFrom;

        bytes memory marketModuleReturnData = _vars.marketModuleInitData;
        if (_vars.marketModule != address(0)) {
            _curationById[_vars.profileId].marketModule = _vars.marketModule;
            marketModuleReturnData = _initMarketModule(
				_vars.tokenContractPointed, 
                _vars.tokenIdPointed,
                _vars.marketModule,
                _vars.marketModuleInitData,
                _marketModuleWhitelisted
            );
        }

		bytes memory minterMarketModuleReturnData = _vars.minterMarketModuleInitData;
        if (_vars.minterMarketModule != address(0)) {
            _curationById[_vars.profileId].minterMarketModule = _vars.minterMarketModule;
            // mint module is also a market module, whose minter is different.
			minterMarketModuleReturnData = _initMarketModule(
				_vars.tokenContractPointed,
                _vars.tokenIdPointed,
				_vars.minterMarketModule,
				_vars.minterMarketModuleInitData,
                _marketModuleWhitelisted
            );
        }

        _initCurationRecipientsParams(
            DataTypes.InitializeCurationData({
                tokenId: _vars.profileId,
                curationData: _vars.curationMetaData
            }), 
            _vars.to,
            _allocationId,
            _minimalCooldownBlocks, 
            _bardsStaking,
            _curationData,
            _curationById,
            _isToBeClaimedByAllocByCurator
        );

        _emitProfileCreated(
            _vars.profileId, 
            _vars,
            marketModuleReturnData,
            minterMarketModuleReturnData
        );
    }

    /**
     * @notice Sets the market module for a given curation.
     *
     * @param curationId The curation token ID to set the market module for.
	 * @param tokenContract The address of NFT token to curate.
     * @param tokenId The NFT token ID to curate.
     * @param marketModule The market module to set for the given curation, if any.
     * @param marketModuleInitData The data to pass to the market module for curation initialization.
     * @param _curation The storage reference to the curation struct associated with the given curation token ID.
     * @param _marketModuleWhitelisted The storage reference to the mapping of whitelist status by market module address.
     */
    function setMarketModule(
		uint256 curationId,
		address tokenContract,
        uint256 tokenId,
        address marketModule,
        bytes memory marketModuleInitData,
        DataTypes.CurationStruct storage _curation,
        mapping(address => bool) storage _marketModuleWhitelisted
    ) external {
        if (marketModule != _curation.marketModule) {
            _curation.marketModule = marketModule;
        }

        bytes memory marketModuleReturnData;
        if (marketModule != address(0))
            marketModuleReturnData = _initMarketModule(
				tokenContract,
                tokenId,
                marketModule,
                marketModuleInitData,
                _marketModuleWhitelisted
            );

        emit Events.MarketModuleSet(
			curationId,
            marketModule,
            marketModuleInitData,
            block.timestamp
        );
    }

	/**
     * @notice Sets the mint module for a given curation.
     *
     * @param curationId The curation token ID to set the market module for.
	 * @param tokenContract The address of NFT token to curate.
     * @param tokenId The NFT token ID to curate.
     * @param marketModule The market module to set for the given curation, if any.
     * @param marketModuleInitData The data to pass to the market module for curation initialization.
     * @param _curation The storage reference to the curation struct associated with the given curation token ID.
     * @param _marketModuleWhitelisted The storage reference to the mapping of whitelist status by market module address.
     */
    function setMinterMarketModule(
		uint256 curationId,
		address tokenContract,
        uint256 tokenId,
        address marketModule,
        bytes memory marketModuleInitData,
        DataTypes.CurationStruct storage _curation,
        mapping(address => bool) storage _marketModuleWhitelisted
    ) external {
        if (marketModule != _curation.minterMarketModule) {
            _curation.minterMarketModule = marketModule;
        }

        bytes memory marketModuleReturnData;
        if (marketModule != address(0))
            marketModuleReturnData = _initMarketModule(
				tokenContract,
                tokenId,
                marketModule,
                marketModuleInitData,
                _marketModuleWhitelisted
            );
			 
        emit Events.MinterMarketModuleSet(
			curationId,
            marketModule,
            marketModuleInitData,
            block.timestamp
        );
    }

    /**
     * @notice Creates a curation mapped to the given profile.
     *
     * @dev To avoid a stack too deep error, reference parameters are passed in memory rather than calldata.
     *
     * @param _vars The CreateProfileData struct.
     * @param _allocationId allocationg id
     * @param _minimalCooldownBlocks minimal cool down blocks
     * @param _bardsStaking The address of BardsStaking contract
     * @param _curationData The storage reference to the mapping of curation data.
     * @param _curationById The storage reference to the mapping of curations by token ID.
     * @param _marketModuleWhitelisted The storage reference to the mapping of whitelist status by collect module address.
     * @param _isToBeClaimedByAllocByCurator The storage reference to the mapping of claim status of allocation.
     */
    function createCuration(
        DataTypes.CreateCurationData memory _vars,
        uint256 _allocationId,
        uint32 _minimalCooldownBlocks,
        IBardsStaking _bardsStaking,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => bool) storage _marketModuleWhitelisted,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
    ) external {
        _curationById[_vars.curationId].curationType = _vars.curationType;
        _curationById[_vars.curationId].contentURI = _vars.contentURI;
		_curationById[_vars.curationId].tokenContractPointed = _vars.tokenContractPointed;
		_curationById[_vars.curationId].tokenIdPointed = _vars.tokenIdPointed;
		_curationById[_vars.curationId].curationFrom = _vars.curationFrom;
        _curationById[_vars.curationId].allocationId = _allocationId;

        if (_vars.marketModule != address(0)) {
            _initMarketModule(
				_vars.tokenContractPointed, 
                _vars.tokenIdPointed,
                _vars.marketModule,
                _vars.marketModuleInitData,
                _marketModuleWhitelisted
            );
            _curationById[_vars.curationId].marketModule = _vars.marketModule;
        }
        if (_vars.minterMarketModule != address(0)) {
			_initMarketModule(
				_vars.tokenContractPointed,
                _vars.tokenIdPointed,
				_vars.minterMarketModule,
				_vars.minterMarketModuleInitData,
                _marketModuleWhitelisted
            );
            _curationById[_vars.curationId].minterMarketModule = _vars.minterMarketModule;
        }

        _initCurationRecipientsParams(
            DataTypes.InitializeCurationData({
                tokenId: _vars.curationId,
                curationData: _vars.curationMetaData
            }),
            _vars.to,
            _allocationId,
            _minimalCooldownBlocks, 
            _bardsStaking,
            _curationData,
            _curationById,
            _isToBeClaimedByAllocByCurator
        );

        emit Events.CurationCreated(
            _vars.profileId,
            _vars.curationId, 
            _vars.contentURI,
            _vars.marketModule,
            _vars.marketModuleInitData,
            _vars.minterMarketModule,
            _vars.minterMarketModuleInitData,
            block.timestamp
        );
    }

    /**
     * @notice Collects the given curation, executing the necessary logic and module call before minting the
     * collect NFT to the collector.
     *
     * @param _vars A struct of DoCollectData.
     *
     */
    function collect(
        address collector,
        DataTypes.SimpleDoCollectData memory _vars,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById
    ) 
        external
        returns (address, uint256)
    {
        // Avoids stack too deep
        DataTypes.CurationStruct storage curation = _curationById[_vars.curationId];
        address marketModule;
        if (_vars.fromCuration == true){
            marketModule = curation.minterMarketModule;
        } else{
            marketModule = curation.marketModule;
        }
        
        if (marketModule == address(0)) {
            revert Errors.MarketZeroAddress();
        }

        (
            address retTokenContract, 
            uint256 retTokenId
        ) = IMarketModule(marketModule).collect(
            collector,
            _vars.curationId,
            curation.tokenContractPointed,
            curation.tokenIdPointed,
            _vars.curationIds,
            _vars.collectMetaData
        );

        emit Events.Collected(
            collector,
            _vars.curationId,
            retTokenContract,
            retTokenId,
            _vars.collectMetaData,
            block.timestamp
        );

        return (retTokenContract, retTokenId);
    }

    function setCurationRecipientsParams(
        DataTypes.InitializeCurationData memory vars,
        address owner,
        uint256 newAllocationId,
        uint32 minimalCooldownBlocks,
        IBardsStaking bardsStaking,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
	) 
		external
        returns (bytes memory)
	{
        return _setCurationRecipientsParams(
            vars,
            owner,
            newAllocationId,
            minimalCooldownBlocks,
            bardsStaking,
            _curationData,
            _curationById,
            _isToBeClaimedByAllocByCurator
        );
    }

    function _initCurationRecipientsParams(
        DataTypes.InitializeCurationData memory vars,
        address owner,
        uint256 newAllocationId,
        uint32 minimalCooldownBlocks,
        IBardsStaking bardsStaking,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
	) 
		private
        returns (bytes memory)
	{
		require(
            _curationData[vars.tokenId].updatedAtBlock == 0 ||
                _curationData[vars.tokenId].updatedAtBlock.add(uint256(minimalCooldownBlocks)) <= block.number,
            "!cooldown"
        );

		DataTypes.CurationData memory curationData = CodeUtils.decodeCurationMetaData(vars.curationData);

		require(
			curationData.sellerFundsBpses.length == curationData.sellerFundsRecipients.length, 
			"sellerFundsRecipients and sellerFundsBpses must have same length."
		);
		require(
			curationData.curationFundsRecipients.length == curationData.curationFundsBpses.length, 
			"curationFundsRecipients and curationFundsBpses must have same length."
		);
		require(
			MathUtils.sum(MathUtils.uint32To256Array(curationData.sellerFundsBpses)) + 
			MathUtils.sum(MathUtils.uint32To256Array(curationData.curationFundsBpses)) == Constants.MAX_BPS, 
			"The sum of sellerFundsBpses and curationFundsBpses must be equal to 1000000."
		);
		require(
			curationData.curationBps + curationData.stakingBps <= Constants.MAX_BPS, 
			"curationBps + stakingBps <= 100%"
		);

		_curationData[vars.tokenId] = DataTypes.CurationData({
			sellerFundsRecipients: curationData.sellerFundsRecipients,
			curationFundsRecipients: curationData.curationFundsRecipients,
			sellerFundsBpses: curationData.sellerFundsBpses,
			curationFundsBpses: curationData.curationFundsBpses,
			curationBps: curationData.curationBps,
			stakingBps: curationData.stakingBps,
			updatedAtBlock: block.number
		});

        bardsStaking.allocate(
            DataTypes.CreateAllocateData({
                curator: owner,
                curationId: vars.tokenId,
                recipientsMeta: vars.curationData,
                allocationId: newAllocationId
            })
        );
        _curationById[vars.tokenId].allocationId = newAllocationId;
        _isToBeClaimedByAllocByCurator[owner][newAllocationId] = true;

        emit Events.CurationUpdated(
            vars.tokenId,
            vars.curationData,
            block.timestamp
        );

        return vars.curationData;
	}


    function _setCurationRecipientsParams(
        DataTypes.InitializeCurationData memory vars,
        address owner,
        uint256 newAllocationId,
        uint32 minimalCooldownBlocks,
        IBardsStaking bardsStaking,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
	) 
		private
        returns (bytes memory)
	{
		require(
            _curationData[vars.tokenId].updatedAtBlock == 0 ||
                _curationData[vars.tokenId].updatedAtBlock.add(uint256(minimalCooldownBlocks)) <= block.number,
            "!cooldown"
        );

		DataTypes.CurationData memory curationData = CodeUtils.decodeCurationMetaData(vars.curationData);

		require(
			curationData.sellerFundsBpses.length == curationData.sellerFundsRecipients.length, 
			"sellerFundsRecipients and sellerFundsBpses must have same length."
		);
		require(
			curationData.curationFundsRecipients.length == curationData.curationFundsBpses.length, 
			"curationFundsRecipients and curationFundsBpses must have same length."
		);
		require(
			MathUtils.sum(MathUtils.uint32To256Array(curationData.sellerFundsBpses)) + 
			MathUtils.sum(MathUtils.uint32To256Array(curationData.curationFundsBpses)) == Constants.MAX_BPS, 
			"The sum of sellerFundsBpses and curationFundsBpses must be equal to 1000000."
		);
		require(
			curationData.curationBps + curationData.stakingBps <= Constants.MAX_BPS, 
			"curationBps + stakingBps <= 100%"
		);

		_curationData[vars.tokenId] = DataTypes.CurationData({
			sellerFundsRecipients: curationData.sellerFundsRecipients,
			curationFundsRecipients: curationData.curationFundsRecipients,
			sellerFundsBpses: curationData.sellerFundsBpses,
			curationFundsBpses: curationData.curationFundsBpses,
			curationBps: curationData.curationBps,
			stakingBps: curationData.stakingBps,
			updatedAtBlock: block.number
		});

        bardsStaking.closeAndAllocate(
            _curationById[vars.tokenId].allocationId,
            vars.tokenId,
            DataTypes.CreateAllocateData({
                curator: owner,
                curationId: vars.tokenId,
                recipientsMeta: vars.curationData,
                allocationId: newAllocationId
            })
        );
        _curationById[vars.tokenId].allocationId = newAllocationId;
        _isToBeClaimedByAllocByCurator[owner][newAllocationId] = true;

        emit Events.CurationUpdated(
            vars.tokenId,
            vars.curationData,
            block.timestamp
        );

        return vars.curationData;
	}

	function setSellerFundsRecipientsParams(
		address[] calldata sellerFundsRecipients,
        DataTypes.UpdateCurationDataParamsData memory _vars,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
	) 
		external 
        returns (bytes memory)
	{
		require(
            _curationData[_vars.tokenId].updatedAtBlock == 0 ||
                _curationData[_vars.tokenId].updatedAtBlock.add(uint256(_vars.minimalCooldownBlocks)) <= block.number,
            "!cooldown"
        );

        require(
            _curationData[_vars.tokenId].sellerFundsBpses.length == sellerFundsRecipients.length, 
            "sellerFundsRecipients and sellerFundsBpses must have same length."
        );

		_curationData[_vars.tokenId].sellerFundsRecipients = sellerFundsRecipients;
		_curationData[_vars.tokenId].updatedAtBlock = block.number;

        bytes memory metaData = CodeUtils.encodeCurationMetaData(_curationData[_vars.tokenId]);
        _vars.bardsStaking.closeAndAllocate(
            _curationById[_vars.tokenId].allocationId,
            _vars.tokenId,
            DataTypes.CreateAllocateData({
                curator: _vars.owner,
                curationId: _vars.tokenId,
                recipientsMeta: metaData,
                allocationId: _vars.newAllocationId
            })
        );
        _curationById[_vars.tokenId].allocationId = _vars.newAllocationId;
        _isToBeClaimedByAllocByCurator[_vars.owner][_vars.newAllocationId] = true;

		emit Events.CurationSellerFundsRecipientsUpdated(
			_vars.tokenId, 
			sellerFundsRecipients, 
			block.timestamp
		);

        return metaData;
	}

	function setCurationFundsRecipientsParams(
        uint256[] calldata curationFundsRecipients,
        DataTypes.UpdateCurationDataParamsData memory _vars,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
    ) 
		external 
        returns (bytes memory)
	{
		require(
            _curationData[_vars.tokenId].updatedAtBlock == 0 ||
                _curationData[_vars.tokenId].updatedAtBlock.add(uint256(_vars.minimalCooldownBlocks)) <= block.number,
            "!cooldown"
        );

        require(
            curationFundsRecipients.length == _curationData[_vars.tokenId].curationFundsBpses.length, 
            "curationFundsRecipients and curationFundsBpses must have same length."
        );

		_curationData[_vars.tokenId].curationFundsRecipients = curationFundsRecipients;
		_curationData[_vars.tokenId].updatedAtBlock = block.number;

        bytes memory metaData = CodeUtils.encodeCurationMetaData(_curationData[_vars.tokenId]);

        _vars.bardsStaking.closeAndAllocate(
            _curationById[_vars.tokenId].allocationId,
            _vars.tokenId,
            DataTypes.CreateAllocateData({
                curator: _vars.owner,
                curationId: _vars.tokenId,
                recipientsMeta: metaData,
                allocationId: _vars.newAllocationId
            })
        );
        _curationById[_vars.tokenId].allocationId = _vars.newAllocationId;
        _isToBeClaimedByAllocByCurator[_vars.owner][_vars.newAllocationId] = true;

		emit Events.CurationFundsRecipientsUpdated(
			_vars.tokenId, 
			curationFundsRecipients, 
			block.timestamp
		);

        return metaData;
	}

	function setSellerFundsBpsesParams(
        uint32[] calldata sellerFundsBpses,
        DataTypes.UpdateCurationDataParamsData memory _vars,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
    ) 
		external 
        returns (bytes memory)
	{
		require(
            _curationData[_vars.tokenId].updatedAtBlock == 0 ||
                _curationData[_vars.tokenId].updatedAtBlock.add(uint256(_vars.minimalCooldownBlocks)) <= block.number,
            "!cooldown"
        );

        require(
            sellerFundsBpses.length == _curationData[_vars.tokenId].sellerFundsRecipients.length, 
            "sellerFundsRecipients and sellerFundsBpses must have same length."
        );

        require(
            MathUtils.sum(MathUtils.uint32To256Array(sellerFundsBpses)) + 
            MathUtils.sum(MathUtils.uint32To256Array(_curationData[_vars.tokenId].curationFundsBpses)) == Constants.MAX_BPS, 
            "The sum of sellerFundsBpses and curationFundsBpses must be equal to 100%."
        );

		_curationData[_vars.tokenId].sellerFundsBpses = sellerFundsBpses;
		_curationData[_vars.tokenId].updatedAtBlock = block.number;

        bytes memory metaData = CodeUtils.encodeCurationMetaData(_curationData[_vars.tokenId]);

        _vars.bardsStaking.closeAndAllocate(
            _curationById[_vars.tokenId].allocationId,
            _vars.tokenId,
            DataTypes.CreateAllocateData({
                curator: _vars.owner,
                curationId: _vars.tokenId,
                recipientsMeta: metaData,
                allocationId: _vars.newAllocationId
            })
        );
        _curationById[_vars.tokenId].allocationId = _vars.newAllocationId;
        _isToBeClaimedByAllocByCurator[_vars.owner][_vars.newAllocationId] = true;

		emit Events.CurationSellerFundsBpsesUpdated(
			_vars.tokenId, 
			sellerFundsBpses, 
			block.timestamp
		);

        return metaData;
	}

	function setCurationFundsBpsesParams( 
        uint32[] calldata curationFundsBpses,
        DataTypes.UpdateCurationDataParamsData memory _vars,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
    ) 
		external
        returns (bytes memory) 
	{
		require(
            _curationData[_vars.tokenId].updatedAtBlock == 0 ||
                _curationData[_vars.tokenId].updatedAtBlock.add(uint256(_vars.minimalCooldownBlocks)) <= block.number,
            "!cooldown"
        );

        require(
            MathUtils.sum(MathUtils.uint32To256Array(_curationData[_vars.tokenId].sellerFundsBpses)) + 
            MathUtils.sum(MathUtils.uint32To256Array(curationFundsBpses)) == Constants.MAX_BPS, 
            "The sum of sellerFundsBpses and curationFundsBpses must be equal to 100%."
        );

		_curationData[_vars.tokenId].curationFundsBpses = curationFundsBpses;
		_curationData[_vars.tokenId].updatedAtBlock = block.number;
        
        bytes memory metaData = CodeUtils.encodeCurationMetaData(_curationData[_vars.tokenId]);

        _vars.bardsStaking.closeAndAllocate(
            _curationById[_vars.tokenId].allocationId,
            _vars.tokenId,
            DataTypes.CreateAllocateData({
                curator: _vars.owner,
                curationId: _vars.tokenId,
                recipientsMeta: metaData,
                allocationId: _vars.newAllocationId
            })
        );
        _curationById[_vars.tokenId].allocationId = _vars.newAllocationId;
        _isToBeClaimedByAllocByCurator[_vars.owner][_vars.newAllocationId] = true;

		emit Events.CurationFundsBpsesUpdated(
			_vars.tokenId, 
			curationFundsBpses, 
			block.timestamp
		);

        return metaData;
	}

	function setCurationBpsParams(
        uint32 curationBps,
        DataTypes.UpdateCurationDataParamsData memory _vars,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
    ) 
		external
        returns (bytes memory)
	{
		require(
            _curationData[_vars.tokenId].updatedAtBlock == 0 ||
                _curationData[_vars.tokenId].updatedAtBlock.add(uint256(_vars.minimalCooldownBlocks)) <= block.number,
            "!cooldown"
        );

        require(curationBps <= Constants.MAX_BPS, "setCurationFeeParams must set fee <= 100%");

        require(
            curationBps + _curationData[_vars.tokenId].stakingBps <= Constants.MAX_BPS, 
            "curationBps + stakingBps <= 100%"
        );

		_curationData[_vars.tokenId].curationBps = curationBps;
		_curationData[_vars.tokenId].updatedAtBlock = block.number;

        bytes memory metaData = CodeUtils.encodeCurationMetaData(_curationData[_vars.tokenId]);

        _vars.bardsStaking.closeAndAllocate(
            _curationById[_vars.tokenId].allocationId,
            _vars.tokenId,
            DataTypes.CreateAllocateData({
                curator: _vars.owner,
                curationId: _vars.tokenId,
                recipientsMeta: metaData,
                allocationId: _vars.newAllocationId
            })
        );
        _curationById[_vars.tokenId].allocationId = _vars.newAllocationId;
        _isToBeClaimedByAllocByCurator[_vars.owner][_vars.newAllocationId] = true;

		emit Events.CurationBpsUpdated(
            _vars.tokenId, 
            curationBps, 
            block.timestamp
        );

        return metaData;
	}

	function setStakingBpsParams(
        uint32 stakingBps,
        DataTypes.UpdateCurationDataParamsData memory _vars,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
    ) 
		external
        returns (bytes memory)
	{
		require(
            _curationData[_vars.tokenId].updatedAtBlock == 0 ||
                _curationData[_vars.tokenId].updatedAtBlock.add(uint256(_vars.minimalCooldownBlocks)) <= block.number,
            "!cooldown"
        );
		require(stakingBps <= Constants.MAX_BPS, "setCurationFeeParams must set fee <= 100%");
        require(
            _curationData[_vars.tokenId].curationBps + stakingBps <= Constants.MAX_BPS, 
            "curationBps + stakingBps <= 100%"
        );

		_curationData[_vars.tokenId].stakingBps = stakingBps;
		_curationData[_vars.tokenId].updatedAtBlock = block.number;

        bytes memory metaData = CodeUtils.encodeCurationMetaData(_curationData[_vars.tokenId]);

        _vars.bardsStaking.closeAndAllocate(
            _curationById[_vars.tokenId].allocationId,
            _vars.tokenId,
            DataTypes.CreateAllocateData({
                curator: _vars.owner,
                curationId: _vars.tokenId,
                recipientsMeta: metaData,
                allocationId: _vars.newAllocationId
            })
        );
        _curationById[_vars.tokenId].allocationId = _vars.newAllocationId;
        _isToBeClaimedByAllocByCurator[_vars.owner][_vars.newAllocationId] = true;

		emit Events.StakingBpsUpdated(_vars.tokenId, stakingBps, block.timestamp);

        return metaData;
	}


	function setBpsParams(
        uint32 curationBps, 
        uint32 stakingBps,
        DataTypes.UpdateCurationDataParamsData memory _vars,
        mapping(uint256 => DataTypes.CurationData) storage _curationData,
        mapping(uint256 => DataTypes.CurationStruct) storage _curationById,
        mapping(address => mapping(uint256 => bool)) storage _isToBeClaimedByAllocByCurator
    ) 
		external
        returns (bytes memory) 
	{
		require(
            _curationData[_vars.tokenId].updatedAtBlock == 0 ||
                _curationData[_vars.tokenId].updatedAtBlock.add(uint256(_vars.minimalCooldownBlocks)) <= block.number,
            "!cooldown"
        );
		require(curationBps + stakingBps <= Constants.MAX_BPS, 'curationBps + stakingBps <= 100%');
		
		_curationData[_vars.tokenId].updatedAtBlock = block.number;
		_curationData[_vars.tokenId].curationBps = curationBps;
		emit Events.CurationBpsUpdated(_vars.tokenId, curationBps, block.timestamp);

		_curationData[_vars.tokenId].stakingBps = stakingBps;
		emit Events.StakingBpsUpdated(_vars.tokenId, stakingBps, block.timestamp);

        bytes memory metaData = CodeUtils.encodeCurationMetaData(_curationData[_vars.tokenId]);

        _vars.bardsStaking.closeAndAllocate(
            _curationById[_vars.tokenId].allocationId,
            _vars.tokenId,
            DataTypes.CreateAllocateData({
                curator: _vars.owner,
                curationId: _vars.tokenId,
                recipientsMeta: metaData,
                allocationId: _vars.newAllocationId
            })
        );
        _curationById[_vars.tokenId].allocationId = _vars.newAllocationId;
        _isToBeClaimedByAllocByCurator[_vars.owner][_vars.newAllocationId] = true;

        return metaData;
	}

	function _initMarketModule(
		address tokenContract,
        uint256 tokenId,
        address marketModule,
        bytes memory marketModuleInitData,
        mapping(address => bool) storage _marketModuleWhitelisted
    ) 
        private 
        returns (bytes memory) 
    {
        if (!_marketModuleWhitelisted[marketModule]) revert Errors.MarketModuleNotWhitelisted();
        return IMarketModule(marketModule).initializeModule(
            tokenContract, 
            tokenId, 
            marketModuleInitData
        );
    }

    function _emitProfileCreated(
        uint256 profileId,
        DataTypes.CreateCurationData memory vars,
        bytes memory marketModuleReturnData,
		bytes memory minterMarketModuleReturnData
    ) 
        private 
    {
        emit Events.ProfileCreated(
            profileId,
            msg.sender, // Creator is always the msg sender
            vars.to,
            vars.handle,
            vars.contentURI,
            vars.marketModule,
            marketModuleReturnData,
            vars.minterMarketModule,
            minterMarketModuleReturnData,
            block.timestamp
        );
    }

	function _validateHandle(
        string memory handle
    ) 
        private 
        pure 
    {
        bytes memory byteHandle = bytes(handle);
        if (byteHandle.length == 0 || byteHandle.length > Constants.MAX_HANDLE_LENGTH)
            revert Errors.HandleLengthInvalid();

        uint256 byteHandleLength = byteHandle.length;
        for (uint256 i = 0; i < byteHandleLength; ) {
            if (
                (byteHandle[i] < '0' ||
                    byteHandle[i] > 'z' ||
                    (byteHandle[i] > '9' && byteHandle[i] < 'a')) &&
                byteHandle[i] != '.' &&
                byteHandle[i] != '-' &&
                byteHandle[i] != '_'
            ) revert Errors.HandleContainsInvalidCharacters();
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {DataTypes} from '../../utils/DataTypes.sol';

/**
 * @title BardsHubStorage
 * @author TheBards Protocol
 *
 * @notice This is an abstract contract that *only* contains storage for the BardsHub contract. This
 * *must* be inherited last (bar interfaces) in order to preserve the BardsHub storage layout. Adding
 * storage variables should be done solely at the bottom of this contract.
 */
abstract contract BardsHubStorage {
	// Track contract ids to contract address
    mapping(bytes32 => address) internal _registry;
    mapping(address => bool) internal _isRegisteredAddress;

	// address -> profile id
	mapping(address => uint256) internal _defaultProfileByAddress;
	// whitelists
	mapping(address => bool) internal _marketModuleWhitelisted;
	mapping (address => bool) internal _minterModuleWhitelisted;
	mapping(address => bool) internal _profileCreatorWhitelisted;
    mapping(address => bool) internal _currencyWhitelisted;

	// hash -> profile id
	mapping(bytes32 => uint256) internal _profileIdByHandleHash;
	// self curation or profile
	mapping(uint256 => bool) internal _isProfileById;
    // curator => allocationId => bool
    mapping(address => mapping(uint256 => bool)) internal _isToBeClaimedByAllocByCurator;
	// curation
	mapping(uint256 => DataTypes.CurationStruct) internal _curationById;
	// curation id (or profile) -> curation id -> bool
	// mapping(uint256 => mapping(uint256 => bool)) internal _isMintedByIdById;

    uint256 internal _curationCounter;
    uint256 internal _allocationCounter;
    address internal _governance;
    address internal _emergencyAdmin;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IBardsCurationBase} from '../../interfaces/curations/IBardsCurationBase.sol';
import {BardsNFTBase} from '../NFTs/BardsNFTBase.sol';
import {Constants} from '../../utils/Constants.sol';
import {Events} from '../../utils/Events.sol';
import {MathUtils} from '../../utils/MathUtils.sol';
import {DataTypes} from '../../utils/DataTypes.sol';

/**
 * @title BardsCurationBase
 * @author TheBards Protocol
 *
 * @notice This is an abstract base contract to be inherited by other TheBards Protocol Curations, it includes
 * NFT module and curation fee setting module.
 */
abstract contract BardsCurationBase is 
	ReentrancyGuard, 
	IBardsCurationBase, 
	BardsNFTBase
{
	/**
     * @notice The curation for a given NFT, if one exists
     * @notice ERC-721 token id => Curation
	 */
    mapping(uint256 => DataTypes.CurationData) internal _curationData;

	// The time in blocks an curator needs to wait to change curation data parameters
	uint32 internal _cooldownBlocks;

	/**
     * @notice Initializer sets the name, symbol and the cached domain separator.
     *
     * NOTE: Inheritor contracts *must* call this function to initialize the name & symbol in the
     * inherited ERC721 contract.
     *
     * @param name The name to set in the ERC721 contract.
     * @param symbol The symbol to set in the ERC721 contract.
     */
    function _initialize(
		string calldata name, 
		string calldata symbol,
		uint32 cooldownBlocks
	) 
		internal 
	{
        BardsNFTBase._initialize(name, symbol);
		_setCooldownBlocks(cooldownBlocks);
    }

	/**
     * @notice See {IBardsCurationBase-sellerFundsRecipientsOf}
     */
	function sellerFundsRecipientsOf(uint256 tokenId)
		external
		view
		virtual
		override
		returns (address[] memory) 
	{
		address[] memory sellerFundsRecipients = _curationData[tokenId].sellerFundsRecipients;
		return sellerFundsRecipients;
	}

	/**
     * @notice See {IBardsCurationBase-sellerFundsRecipientsOf}
     */
	function curationFundsRecipientsOf(uint256 tokenId)
		external
		view
		virtual
		override
		returns (uint256[] memory) 
	{
		uint256[] memory curationFundsRecipients = _curationData[tokenId].curationFundsRecipients;
		return curationFundsRecipients;
	}

	/**
     * @notice See {IBardsCurationBase-sellerBpsesOf}
     */
	function sellerFundsBpsesOf(uint256 tokenId)
		external
		view
		virtual
		override
		returns (uint32[] memory) 
	{
		uint32[] memory sellerFundsBpses = _curationData[tokenId].sellerFundsBpses;
		return sellerFundsBpses;
	}

	/**
     * @notice See {IBardsCurationBase-curationFundsBpsesOf}
     */
	function curationFundsBpsesOf(uint256 tokenId)
		external
		view
		virtual
		override
		returns (uint32[] memory) 
	{
		uint32[] memory curationFundsBpses = _curationData[tokenId].curationFundsBpses;
		return curationFundsBpses;
	}

	/**
     * @notice See {IBardsCurationBase-curationBpsOf}
     */
    function curationBpsOf(uint256 tokenId) 
		external 
		view 
		virtual 
		override 
		returns (uint32) {
			uint32 curationBps = _curationData[tokenId].curationBps;
			require(curationBps <= Constants.MAX_BPS, 'curationBpsOf must set bps <= 100%');
			return curationBps;
    	}

	/**
     * @notice See {IBardsCurationBase-stakingBpsOf}
     */
    function stakingBpsOf(uint256 tokenId) 
		external 
		view 
		virtual 
		override 
		returns (uint32) {
			uint32 stakingBps = _curationData[tokenId].stakingBps;
			require(stakingBps <= Constants.MAX_BPS, 'stakingBps must set bps <= 100%');
			return stakingBps;
   	}

	    /**
     * @notice See {IBardsCurationBase-curationDataOf}
     */
    function curationDataOf(uint256 tokenId)
        external
        view
        virtual
        override
        returns (DataTypes.CurationData memory)
	{
		// if (tokenContract == address(this)){
		// 	require(_exists(tokenId), 'ERC721: token data query for nonexistent token');
		// }
		return _curationData[tokenId];
		}

    /**
     * @notice Internal: Set the time in blocks an curator needs to wait to change curation parameters.
     * @param _blocks Number of blocks to set the cuation parameters cooldown period
     */
    function _setCooldownBlocks(
        uint32 _blocks
    ) 
        internal 
    {
        uint32 prevCooldownBlocks = _cooldownBlocks;
        _cooldownBlocks = _blocks;
        emit Events.CooldownBlocksUpdated(
            prevCooldownBlocks,
            _blocks,
            block.timestamp
        );
    }

	/**
	 * @notice see {IBardsCurationBase-getCurationFeeAmount}
	 */
	function getCurationFeeAmount(uint256 tokenId, uint256 amount)
        external 
        view
        virtual
        override
        returns (uint256 feeAmount) {
			return (amount * _curationData[tokenId].curationBps) / Constants.MAX_BPS;
		}

	/**
	 * @notice see {IBardsCurationBase-getCurationFeeAmount}
	 */
	function getStakingFeeAmount(uint256 tokenId, uint256 amount) 
		external 
        view
        virtual
        override
        returns (uint256 feeAmount) {
			return (amount * _curationData[tokenId].curationBps) / Constants.MAX_BPS;
		}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {DataTypes} from '../../utils/DataTypes.sol';
import {Errors} from '../../utils/Errors.sol';
import {Events} from '../../utils/Events.sol';

/**
 * @title BardsPausable
 *
 * @notice This is an abstract contract that implements internal BardsHub state setting and validation.
 *
 * whenNotPaused: Either CurationPaused or Unpaused.
 * whenCurationEnabled: When Unpaused only.
 */
abstract contract BardsPausable {
	DataTypes.ProtocolState private _state;

	// Time last paused for both pauses
    uint256 public lastCurationPauseTime;
    uint256 public lastPauseTime;

    modifier whenNotPaused() {
        _validateNotPaused();
        _;
    }

    modifier whenCurationEnabled() {
        _validateCurationEnabled();
        _;
    }

    /**
     * @notice Returns the current protocol state.
     *
     * @return ProtocolState The Protocol state, an enum, where:
     *      0: Unpaused
     *      1: CurationPaused
     *      2: Paused
     */
    function getState() external view returns (DataTypes.ProtocolState) {
        return _state;
    }

    function _setState(DataTypes.ProtocolState newState) internal {
        DataTypes.ProtocolState prevState = _state;
        _state = newState;
		if (newState == DataTypes.ProtocolState.Paused){
			lastPauseTime = block.timestamp;
		}else if (newState == DataTypes.ProtocolState.CurationPaused){
			lastCurationPauseTime = block.timestamp;
		}
        emit Events.StateSet(msg.sender, prevState, newState, block.timestamp);
    }

    function _validateCurationEnabled() internal view {
        if (_state != DataTypes.ProtocolState.Unpaused) {
            revert Errors.CurationPaused();
        }
    }

    function _validateNotPaused() internal view {
        if (_state == DataTypes.ProtocolState.Paused) revert Errors.Paused();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title MathUtils Library
 * @notice A collection of functions to perform math operations
 */
library MathUtils {
    using SafeMath for uint256;

    /**
     * @dev Calculates the weighted average of two values pondering each of these
     * values based on configured weights. The contribution of each value N is
     * weightN/(weightA + weightB).
     * @param valueA The amount for value A
     * @param weightA The weight to use for value A
     * @param valueB The amount for value B
     * @param weightB The weight to use for value B
     */
    function weightedAverage(
        uint256 valueA,
        uint256 weightA,
        uint256 valueB,
        uint256 weightB
    ) internal pure returns (uint256) {
        return valueA.mul(weightA).add(valueB.mul(weightB)).div(weightA.add(weightB));
    }

    /**
     * @dev Returns the minimum of two numbers.
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? x : y;
    }

    /**
     * @dev Returns the difference between two numbers or zero if negative.
     */
    function diffOrZero(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x > y) ? x.sub(y) : 0;
    }

	/**
	 * @dev Returns the sum of a uint256 array.
	 */
	function sum(uint256[] memory arr) internal pure returns (uint256){
		if (arr.length == 0) return 0;
		
		uint256 i;
  		uint256 _sum = 0;
    
		for(i = 0; i < arr.length; i++)
			_sum = _sum.add(arr[i]);
		return _sum;
	}

    /**
     * @dev Casting uint32[] to uint256[]
     */
    function uint32To256Array(uint32[] memory arr) internal pure returns (uint256[] memory) {
        uint256[] memory res; 
        if (arr.length == 0)
            return res;
            
        res = new uint[](arr.length);
        for(uint256 i = 0; i < arr.length; i++){
            res[i] = uint256(arr[i]);
        }
        return res;
    }

    /**
     * @dev Raises x to the power of n with scaling factor of base.
     * Based on: https://github.com/makerdao/dss/blob/master/src/pot.sol#L81
     * @param x Base of the exponentiation
     * @param n Exponent
     * @param base Scaling factor
     * @return z Exponential of n with base x
     */
    function pow(
        uint256 x,
        uint256 n,
        uint256 base
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    z := base
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := base
                }
                default {
                    z := x
                }
                let half := div(base, 2) // for rounding.
                for {
                    n := div(n, 2)
                } n {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    x := div(xxRound, base)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IBardsNFTBase} from '../../interfaces/NFTs/IBardsNFTBase.sol';
import {Errors} from '../../utils/Errors.sol';
import {DataTypes} from '../../utils/DataTypes.sol';
import {Events} from '../../utils/Events.sol';
import './ERC721Enumerable.sol';
import {TokenStorage} from '../storages/TokenStorage.sol';


/**
 * @title BardsNFTBase
 * @author Lens Protocol
 *
 * @notice This is an abstract base contract to be inherited by other Lens Protocol NFTs, it includes
 * the slightly modified ERC721Enumerable-- which adds an
 * internal operator approval setter, stores the mint timestamp for each token, and replaces the
 * constructor with an initializer.
 */
abstract contract BardsNFTBase is ERC721Enumerable, IBardsNFTBase, TokenStorage {
    bytes32 private constant PERMIT_TYPEHASH = 
        keccak256('Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)');
    bytes32 private constant PERMIT_FOR_ALL_TYPEHASH =
        keccak256(
            'PermitForAll(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)'
        );
    bytes32 private constant BURN_WITH_SIG_TYPEHASH =
        keccak256('BurnWithSig(uint256 tokenId,uint256 nonce,uint256 deadline)');

    // uint256 internal _counter;

    /**
     * @notice Initializer sets the name, symbol and the cached domain separator.
     *
     * NOTE: Inheritor contracts *must* call this function to initialize the name & symbol in the
     * inherited ERC721 contract.
     *
     * @param name The name to set in the ERC721 contract.
     * @param symbol The symbol to set in the ERC721 contract.
     */
    function _initialize(string calldata name, string calldata symbol) internal {
        ERC721Time.__ERC721_Init(name, symbol);
        emit Events.BaseInitialized(name, symbol, block.timestamp);
    }

    /// @inheritdoc IBardsNFTBase
    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        if (spender == address(0)) revert Errors.ZeroSpender();
        address owner = ownerOf(tokenId);
        unchecked {
            _validateRecoveredAddress(
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        spender,
                        tokenId,
                        sigNonces[owner]++,
                        sig.deadline
                    )
                ),
                name(),
                owner,
                sig
            );
        }
        _approve(spender, tokenId);
    }

    /// @inheritdoc IBardsNFTBase
    function permitForAll(
        address owner,
        address operator,
        bool approved,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        if (operator == address(0)) revert Errors.ZeroSpender();
        unchecked {
            _validateRecoveredAddress(
                keccak256(
                    abi.encode(
                        PERMIT_FOR_ALL_TYPEHASH,
                        owner,
                        operator,
                        approved,
                        sigNonces[owner]++,
                        sig.deadline
                    )
                ),
                name(),
                owner,
                sig
            );
        }
        _setOperatorApproval(owner, operator, approved);
    }

    /// @inheritdoc IBardsNFTBase
    // function getDomainSeparator() external view override returns (bytes32) {
    //     return _calculateDomainSeparator(name());
    // }

    /// @inheritdoc IBardsNFTBase
    function burn(uint256 tokenId) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert Errors.NotOwnerOrApproved();
        _burn(tokenId);
    }

    /// @inheritdoc IBardsNFTBase
    function burnWithSig(uint256 tokenId, DataTypes.EIP712Signature calldata sig)
        public
        virtual
        override
    {
        address owner = ownerOf(tokenId);
        unchecked {
            _validateRecoveredAddress(
                keccak256(
                    abi.encode(
                        BURN_WITH_SIG_TYPEHASH,
                        tokenId,
                        sigNonces[owner]++,
                        sig.deadline
                    )
                ),
                name(),
                owner,
                sig
            );
        }
        _burn(tokenId);
    }


}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {DataTypes} from '../../utils/DataTypes.sol';

/**
 * @title IBardsNFTBase
 * @author TheBards Protocol
 *
 * @notice This is the interface for the BardsNFTBase contract, from which all Bards NFTs inherit.
 * It is an expansion of a very slightly modified ERC721Enumerable contract, which allows expanded
 * meta-transaction functionality.
 */
interface IBardsNFTBase {    
    /**
     * @notice Implementation of an EIP-712 permit function for an ERC-721 NFT. We don't need to check
     * if the tokenId exists, since the function calls ownerOf(tokenId), which reverts if the tokenId does
     * not exist.
     *
     * @param spender The NFT spender.
     * @param tokenId The NFT token ID to approve.
     * @param sig The EIP712 signature struct.
     */
    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Implementation of an EIP-712 permit-style function for ERC-721 operator approvals. Allows
     * an operator address to control all NFTs a given owner owns.
     *
     * @param owner The owner to set operator approvals for.
     * @param operator The operator to approve.
     * @param approved Whether to approve or revoke approval from the operator.
     * @param sig The EIP712 signature struct.
     */
    function permitForAll(
        address owner,
        address operator,
        bool approved,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Burns an NFT, removing it from circulation and essentially destroying it. This function can only
     * be called by the NFT to burn's owner.
     *
     * @param tokenId The token ID of the token to burn.
     */
    function burn(uint256 tokenId) external;

    /**
     * @notice Implementation of an EIP-712 permit-style function for token burning. Allows anyone to burn
     * a token on behalf of the owner with a signature.
     *
     * @param tokenId The token ID of the token to burn.
     * @param sig The EIP712 signature struct.
     */
    function burnWithSig(uint256 tokenId, DataTypes.EIP712Signature calldata sig) external;

    /**
     * @notice Returns the domain separator for this NFT contract.
     *
     * @return bytes32 The domain separator.
     */
    // function getDomainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import './ERC721Time.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 *
 * NOTE: Modified from Openzeppelin to inherit from a modified ERC721 contract.
 */
abstract contract ERC721Enumerable is ERC721Time, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721Time)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(index < ERC721Time.balanceOf(owner), 'ERC721Enumerable: owner index out of bounds');
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(
            index < ERC721Enumerable.totalSupply(),
            'ERC721Enumerable: global index out of bounds'
        );
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Time.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Time.balanceOf(from) - 1; 
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {DataTypes} from '../../utils/DataTypes.sol';
import {Errors} from '../../utils/Errors.sol';

/**
 * @title TokenStorage
 * 
 * @author TheBards Protocol
 * 
 * @notice Storages and functions for ERC20 and ERC721 token contract.
 */
abstract contract TokenStorage {
	bytes32 internal constant EIP712_REVISION_HASH = keccak256('1');
    bytes32 internal constant DOMAIN_SALT =
        0x51f3d585afe6dfeb2af01bba0889a36c1db03beec88c6a4d0c53817069026afa; // Randomly generated salt
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)'
        );

    mapping(address => uint256) public sigNonces;

	/**
     * @notice Wrapper for ecrecover to reduce code size, used in meta-tx specific functions.
     */
    function _validateRecoveredAddress(
        bytes32 hashedMessage,
        string memory name,
        address expectedAddress,
        DataTypes.EIP712Signature calldata sig
    ) 
        internal 
        view 
    {
        require(sig.deadline >= block.timestamp, 'SignatureExpired');
        bytes32 digest = _calculateDigest(hashedMessage, name);
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        require(recoveredAddress != address(0) && recoveredAddress == expectedAddress, 'SignatureInvalid');
    }

    /**
     * @notice Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _calculateDomainSeparator(
        string memory name
    ) 
        internal 
        view 
        returns (bytes32) 
    {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(name)),
                    EIP712_REVISION_HASH,
                    block.chainid,
                    address(this),
                    DOMAIN_SALT
                )
            );
    }

    /**
     * @notice Calculates EIP712 digest based on the current DOMAIN_SEPARATOR.
     *
     * @param hashedMessage The message hash from which the digest should be calculated.
	 * @param name The name of token.
     *
     * @return bytes32 A 32-byte output representing the EIP712 digest
     */
    function _calculateDigest(
        bytes32 hashedMessage, 
        string memory name
    ) 
        internal 
        view 
        returns (bytes32) 
    {
        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked('\x19\x01', _calculateDomainSeparator(name), hashedMessage)
            );
        }
        return digest;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IERC721Time, IERC721} from '../../interfaces/NFTs/IERC721Time.sol';
import {Events} from '../../utils/Events.sol';
import {DataTypes} from '../../utils/DataTypes.sol';
import {IERC721Receiver} from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {Context} from '@openzeppelin/contracts/utils/Context.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {ERC165, IERC165} from '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @notice Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 *
 * Modifications:
 * 1. Refactored _operatorApprovals setter into an internal function to allow meta-transactions.
 * 2. Constructor replaced with an initializer.
 * 3. Mint timestamp is now stored in a TokenData struct alongside the owner address.
 * 4. curationBps and stakingBps is now stored in a TokenData struct alongside the owner address.
 */
abstract contract ERC721Time is Context, ERC165, IERC721Time, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to token Data (owner address and mint timestamp uint96), this
    // replaces the original mapping(uint256 => address) private _owners;
    mapping(uint256 => DataTypes.TokenData) private _tokenData;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @notice Initializes the ERC721 name and symbol.
     *
     * @param __name The name to set.
     * @param __symbol The symbol to set.
     */
    function __ERC721_Init(string calldata __name, string calldata __symbol) internal {
        _name = __name;
        _symbol = __symbol;
    }

    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), 'ERC721: balance query for the zero address');
        return _balances[owner];
    }

    /**
     * @notice See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _tokenData[tokenId].owner;
        require(owner != address(0), 'ERC721: owner query for nonexistent token');
        return owner;
    }

    /**
     * @notice See {IERC721Time-mintTimestampOf}
     */
    function mintTimestampOf(uint256 tokenId) public view virtual override returns (uint256) {
        uint96 mintTimestamp = _tokenData[tokenId].mintTimestamp;
        require(mintTimestamp != 0, 'ERC721: mint timestamp query for nonexistent token');
        return mintTimestamp;
    }

    /**
     * @notice See {IERC721Time-tokenDataOf}
     */
    function tokenDataOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (DataTypes.TokenData memory)
    {
        require(_exists(tokenId), 'ERC721: token data query for nonexistent token');
        return _tokenData[tokenId];
    }

    /**
     * @notice See {IERC721Time-exists}
     */
    function exists(uint256 tokenId) public view virtual override returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @notice See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @notice See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @notice See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @notice Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @notice See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Time.ownerOf(tokenId);
        require(to != owner, 'ERC721: approval to current owner');

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            'ERC721: approve caller is not owner nor approved for all'
        );

        _approve(to, tokenId);
    }

    /**
     * @notice See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), 'ERC721: approved query for nonexistent token');

        return _tokenApprovals[tokenId];
    }

    /**
     * @notice See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), 'ERC721: approve to caller');

        _setOperatorApproval(_msgSender(), operator, approved);
    }

    /**
     * @notice See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @notice See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: transfer caller is not owner nor approved'
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @notice See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @notice See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: transfer caller is not owner nor approved'
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    /**
     * @notice Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenData[tokenId].owner != address(0);
    }

    /**
     * @notice Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(_exists(tokenId), 'ERC721: operator query for nonexistent token');
        address owner = ERC721Time.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @notice Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, '');
    }

    /**
     * @notice Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    /**
     * @notice Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), 'ERC721: mint to the zero address');
        require(!_exists(tokenId), 'ERC721: token already minted');

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _tokenData[tokenId].owner = to;
        _tokenData[tokenId].mintTimestamp = uint96(block.timestamp);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @notice Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Time.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _tokenData[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @notice Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Time.ownerOf(tokenId) == from, 'ERC721: transfer of token that is not own');
        require(to != address(0), 'ERC721: transfer to the zero address');

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _tokenData[tokenId].owner = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @notice Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Time.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @notice Refactored from the original OZ ERC721 implementation: approve or revoke approval from
     * `operator` to operate on all tokens owned by `owner`.
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setOperatorApproval(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @notice Private function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (
                bytes4 retval
            ) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert('ERC721: transfer to non ERC721Receiver implementer');
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @notice Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {DataTypes} from '../../utils/DataTypes.sol';

/**
 * @title IERC721Time
 * @author TheBards Protocol
 *
 * @notice This is an expansion of the IERC721 interface that includes a struct for token data,
 * which contains the token owner and the mint timestamp as well as associated getters.
 */
interface IERC721Time is IERC721 {

    /**
     * @notice Returns the mint timestamp associated with a given NFT, stored only once upon initial mint.
     *
     * @param tokenId The token ID of the NFT to query the mint timestamp for.
     *
     * @return uint256 mint timestamp, this is stored as a uint96 but returned as a uint256 to reduce unnecessary
     * padding.
     */
    function mintTimestampOf(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the token data associated with a given NFT. This allows fetching the token owner and
     * mint timestamp in a single call.
     *
     * @param tokenId The token ID of the NFT to query the token data for.
     *
     * @return TokenData token data struct containing the owner address, curation BPS, staking BPS and the mint timestamp.
     */
    function tokenDataOf(uint256 tokenId) external view returns (DataTypes.TokenData memory);

    /**
     * @notice Returns whether a token with the given token ID exists.
     *
     * @param tokenId The token ID of the NFT to check existence for.
     *
     * @return bool True if the token exists.
     */
    function exists(uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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

pragma solidity ^0.8.12;

interface IContractRegistrar {
	/**
     * @notice Set HUB
     * @param _HUB HUB contract address
     */
	function setHub(address _HUB) external;
	
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title IBardsShareToken
 * @author TheBards Protocol
 * 
 * @notice This is the interface for the BardsShareToken contract.
 */
interface IBardsShareToken is IERC20Upgradeable {

    /**
     * @notice Bards Share Token Contract initializer.
     */
    function initialize() external;

    /**
     * @dev Burn tokens from an address.
     * @param _account Address from where tokens will be burned
     * @param _amount Amount of tokens to burn
     */
	function burnFrom(address _account, uint256 _amount) external;

	/**
     * @dev Mint new tokens.
     * @param _to Address to send the newly minted tokens
     * @param _amount Amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external;
	
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * @title RewardManager Interface
 * 
 * @author Thebards Protocol
 * 
 * @notice The interface of RewardManager contract.
 */
interface IRewardsManager {

    /**
     * @notice Initializes the governance, treasury, treasury fee, default curation fee, and default staking fee amounts.
     *
     * @param _HUB The address of HUB
     * @param _issuanceRate The issuance rate
     * @param _inflationChange The issuance change
     * @param _targetBondingRate The target bonding rate
     */
    function initialize(
        address _HUB,
        uint256 _issuanceRate,
        uint256 _inflationChange,
        uint256 _targetBondingRate
    ) external;

	// -- Config --

	  /**
     * @notice Sets the issuance rate.
     * The issuance rate is defined as a percentage increase of the total supply per block.
     * This means that it needs to be greater than 1.0, any number under 1.0 is not
     * allowed and an issuance rate of 1.0 means no issuance.
     * To accommodate a high precision the issuance rate is expressed in wei.
     * @param _issuanceRate Issuance rate expressed in wei
     */
    function setIssuanceRate(
        uint256 _issuanceRate
    ) external;


    /**
     * @notice Set inflationChange. Only callable by gov
     * @param _inflationChange Inflation change as a percentage of total token supply
     */
    function setInflationChange(
        uint256 _inflationChange
    ) external;

    /**
     * @notice Set targetBondingRate. Only callable by gov
     * @param _targetBondingRate Target bonding rate as a percentage of total bonded tokens / total token supply
     */
    function setTargetBondingRate(
        uint256 _targetBondingRate
    ) external;

	  /**
     * @notice Sets the minimum staked tokens on a curation to start accruing rewards.
     * Can be set to zero which means that this feature is not being used.
     * @param _minimumStakeingToken Minimum signaled tokens
     */
    function setMinimumStakingToken(
        uint256 _minimumStakeingToken
    ) external;

    /**
     * @notice Denies to claim rewards for a curation.
     * @param _curationId curation ID
     * @param _deny Whether to set the curation as denied for claiming rewards or not
     */
    function setDenied(
        uint256 _curationId, 
        bool _deny
    ) external;

    /**
     * @notice Denies to claim rewards for multiple curations.
     * @param _curationIds Array of curation ID
     * @param _deny Array of denied status for claiming rewards for each curation
     */
    function setDeniedMany(
        uint256[] calldata _curationIds, 
        bool[] calldata _deny
    ) external;

    /**
     * @notice Tells if curation is in deny list
     * @param _curationId Curation ID to check
     * @return Whether the curation is denied for claiming rewards or not
     */
    function isDenied(
        uint256 _curationId
    ) 
      external 
      view 
      returns (bool);

	/**
     * @notice Gets the issuance of rewards per staking since last updated.
     *
     * Compound interest formula: `a = p(1 + r/n)^nt`
     * The formula is simplified with `n = 1` as we apply the interest once every time step.
     * The `r` is passed with +1 included. So for 10% instead of 0.1 it is 1.1
     * The simplified formula is `a = p * r^t`
     *
     * Notation:
     * t: time steps are in blocks since last updated
     * p: total supply of BCT tokens
     * a: inflated amount of total supply for the period `t` when interest `r` is applied
     * x: newly accrued rewards token for the period `t`
     *
     * @return newly accrued rewards per signal since last update
     */
    function getNewRewardsPerStaking() 
        external 
        view 
        returns (uint256);

    /**
     * @notice Gets the currently accumulated rewards per staking.
     * @return Currently accumulated rewards per staking
     */
    function getAccRewardsPerStaking() 
        external 
        view 
        returns (uint256);

    /**
     * @notice Gets the accumulated rewards for the curation.
     * @param _curationId Curation Id
     * @return Accumulated rewards for curation
     */
    function getAccRewardsForCuration(
        uint256 _curationId
    )
        external
        view
        returns (uint256);

    /**
     * @notice Gets the accumulated rewards per allocated token for the curation.
     * @param _curationId Curation Id
     * @return Accumulated rewards per allocated token for the curation
     * @return Accumulated rewards for curation
     */
    function getAccRewardsPerAllocatedToken(
        uint256 _curationId
    )
        external
        view
        returns (uint256, uint256);

    /**
     * @dev Calculate current rewards for a given allocation on demand.
     * @param _allocationId Allocation
     * @return Rewards amount for an allocation
     */
    function getRewards(
        uint256 _allocationId
    ) 
      external 
      view 
      returns (uint256);

    /**
     * @notice Updates the accumulated rewards per staking and save checkpoint block number.
     * Must be called before `issuanceRate` or `total staked BCT` changes
     * Called from the BardsStaking contract on mint() and burn()
     * @return Accumulated rewards per staking
     */
    function updateAccRewardsPerStaking() 
        external 
        returns (uint256);

    /**
     * Set IssuanceRate based upon the current bonding rate and target bonding rate
     */
    function onUpdateIssuanceRate() external;

    /**
     * @notice Pull rewards from the contract for a particular allocation.
     * This function can only be called by the BardsStaking contract.
     * This function will mint the necessary tokens to reward based on the inflation calculation.
     * @param _allocationId Allocation
     * @return Assigned rewards amount
     */
    function takeRewards(
        uint256 _allocationId
    ) 
      external 
      returns (uint256);

    // -- Hooks --

    /**
     * @notice Triggers an update of rewards for a curation.
     * Must be called before `staked BCT` on a curation changes.
     * Note: Hook called from the BardsStaking contract on mint() and burn()
     * @param _curationId Curation Id
     * @return Accumulated rewards for curation
     */
    function onCurationStakingUpdate(
        uint256 _curationId
    ) 
      external 
      returns (uint256);

    /**
     * @notice Triggers an update of rewards for a curation.
     * Must be called before allocation on a curation changes.
     * NOTE: Hook called from the BardStaking contract on allocate() and closeAllocation()
     *
     * @param _curationId Curation Id
     * @return Accumulated rewards per allocated token for a curation
     */
    function onCurationAllocationUpdate(
        uint256 _curationId
    ) 
      external 
      returns (uint256);
	
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IEpochManager {

    /**
     * @notice Initialize contract
     *
     * @param _HUB The address of HUB
     * @param _epochLength The epoch length
     */
    function initialize(
        address _HUB, 
        uint256 _epochLength
    ) external;

	// -- Configuration --

    function setEpochLength(uint256 _epochLength) external;

    // -- Epochs

    function runEpoch() external;

    // -- Getters --

    function isCurrentEpochRun() external view returns (bool);

    function blockNum() external view returns (uint256);

    function blockHash(uint256 _block) external view returns (bytes32);

    function currentEpoch() external view returns (uint256);

    function currentEpochBlock() external view returns (uint256);

    function currentEpochBlockSinceStart() external view returns (uint256);

    function epochsSince(uint256 _epoch) external view returns (uint256);

    function epochsSinceUpdate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {DataTypes} from '../../utils/DataTypes.sol';

/**
 * @title IBardsDaoData
 * @author TheBards Protocol
 *
 * @notice This is the interface for the BardsDaoData contract, 
 * which allows an optional fee percentage, recipient governancor to be set for TheBards protocol Dao.
 */
interface IBardsDaoData {

    /**
     * @notice Initializes the governance, treasury, treasury fee, default curation fee, and default staking fee amounts.
     *
     * @param governance The governance address which has additional control over setting certain parameters.
     * @param treasury The treasury address to direct fees to.
     * @param protocolFee The treasury fee in BPS to levy on collects.
     * @param defaultCurationBps The default curation fee in BPS to levy on collects.
     * @param defaultStakingBps The default staking fee in BPS to levy on collects.
     */
    function initialize(
        address governance,
        address treasury,
        uint32 protocolFee,
        uint32 defaultCurationBps,
        uint32 defaultStakingBps
    ) external;

    /**
     * @notice Sets the governance address. This function can only be called by governance.
     *
     * @param newGovernance The new governance address to set.
     */
    function setGovernance(address newGovernance) external;

    /**
     * @notice Sets the treasury address. This function can only be called by governance.
     *
     * @param newTreasury The new treasury address to set.
     */
    function setTreasury(address newTreasury) external;

    /**
     * @notice Sets the protocol fee. This function can only be called by governance.
     *
     * @param newProtocolFee The new treasury fee to set.
     */
    function setProtocolFee(uint32 newProtocolFee) external;

    /**
     * @notice Sets the Default Curation Bps. This function can only be called by governance.
     *
     * @param newDefaultCurationBps The new default curation Bps to set.
     */
    function setDefaultCurationBps(uint32 newDefaultCurationBps) external;

    /**
     * @notice Sets the default staking Bps. This function can only be called by governance.
     *
     * @param newDefaultStakingBps The new default staking Bps to set.
     */
    function setDefaultStakingBps(uint32 newDefaultStakingBps) external;

    /// ************************
    /// *****VIEW FUNCTIONS*****
    /// ************************

    /**
     * @notice Returns the governance address.
     *
     * @return address The governance address.
     */
    function getGovernance() external view returns (address);

    /**
     * @notice Returns the treasury address.
     *
     * @return address The treasury address.
     */
    function getTreasury() external view returns (address);

    /**
     * @notice Returns the protocol fee bps.
     *
     * @return uint32 The protocol fee bps.
     */
    function getProtocolFee() external view returns (uint32);

    /**
     * @notice Returns the default curation fee bps.
     *
     * @return uint32 The default curation fee bps.
     */
    function getDefaultCurationBps() external view returns (uint32);

    /**
     * @notice Returns the default staking fee bps.
     *
     * @return uint32 The default staking fee bps.
     */
    function getDefaultStakingBps() external view returns (uint32);

    /**
     * @notice Returns the protocol fee setting in a single call.
     *
     * @return ProtocolFeeSetting The DataType contains the treasury address and the protocol fee.
     */
    function getProtocolFeeSetting() external view returns (DataTypes.ProtocolFeeSetting memory);

    /**
     * @notice Returns the treasury address and protocol fee in a single call.
     *
     * @return tuple First, the treasury address, second, the protocol fee.
     */
    function getProtocolFeePair() external view returns (address, uint32);

    /**
     * @notice Computes the fee for a given uint256 amount
     * @param _amount The amount to compute the fee for
     * @return The amount to be paid out to the fee recipient
     */
    function getFeeAmount(uint256 _amount) external view returns (uint256);
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