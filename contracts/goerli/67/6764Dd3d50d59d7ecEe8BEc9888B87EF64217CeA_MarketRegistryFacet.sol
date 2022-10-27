// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./../../interfaces/IProtocolRegistry.sol";
import {AppStorage, Modifiers} from "./../../shared/libraries/LibAppStorage.sol";
import {LibMeta} from "./../../shared/libraries/LibMeta.sol";
import {LibMarketRegistryStorage} from "./../marketRegistry/LibMarketRegistryStorage.sol";
import {LibMarketStorage} from "./../market/libraries/LibMarketStorage.sol";

/// @title helper contract providing the data to the loan market contracts.
contract MarketRegistryFacet is Modifiers {
    event LoanActivateLimitUpdated(uint256 loansActivateLimit);
    event LTVPercentageUpdated(uint256 ltvPercentage);

    /// @dev function to set minimum loan amount allowed to create loan
    /// @param _minLoanAmount should be set in normal value, not in decimals, as decimals are handled in Token and NFT Market Loans
    function setMinLoanAmount(uint256 _minLoanAmount)
        external
        onlySuperAdmin(LibMeta.msgSender())
    {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();

        require(_minLoanAmount > 0, "minLoanAmount Invalid");
        ms.minLoanAmountAllowed = _minLoanAmount;
    }

    /// @dev set the loan activate limit for the token market contract
    /// @param _loansLimit limit allowed for loan activation
    function setloanActivateLimit(uint256 _loansLimit)
        external
        onlySuperAdmin(LibMeta.msgSender())
    {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();
        require(_loansLimit > 0, "GTM: loanlimit error");
        ms.allowedLoanActivateLimit = _loansLimit;
        emit LoanActivateLimitUpdated(_loansLimit);
    }

    /// @dev returns the loan activate limit
    /// @return uint256 returns the loan activation limit for the lender
    function getLoanActivateLimit() external view returns (uint256) {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();

        return ms.allowedLoanActivateLimit;
    }

    /// @dev set the LTV percentage limit
    /// @param _ltvPercentage percentage allowed for the liquidation
    function setLTVPercentage(uint256 _ltvPercentage)
        external
        onlySuperAdmin(LibMeta.msgSender())
    {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();

        require(_ltvPercentage > 0, "GTM: percentage amount error");
        ms.ltvPercentage = _ltvPercentage;
        emit LTVPercentageUpdated(_ltvPercentage);
    }

    /// @dev get the ltv percentage set by the super admin
    /// @return uint256 returns the ltv percentage amount
    function getLTVPercentage() external view returns (uint256) {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();

        return ms.ltvPercentage;
    }

    /// @dev set whitelist address for lending unlimited loans
    /// @param _lender add lender address for unlimited loan activation
    /// @param _value bool value true or false to remove unlimited loan feature for loan activation
    function setWhilelistAddress(address _lender, bool _value)
        external
        onlySuperAdmin(LibMeta.msgSender())
    {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();

        require(_lender != address(0x0), "GTM: null address error");
        require(
            !isWhitelisedLender(_lender),
            "GTM: lender already whitelisted"
        );
        ms.whitelistAddress[_lender] = _value;
        ms.allWhitelistAddresses.push(_lender);
    }

    /// @dev set whitelist address for lending unlimited loans
    /// @param _lender add lender address for unlimited loan activation
    /// @param _value bool value true or false to remove unlimited loan feature for loan activation
    function updateWhilelistAddress(address _lender, bool _value)
        external
        onlySuperAdmin(LibMeta.msgSender())
    {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();

        require(_lender != address(0x0), "GTM: null address error");
        require(isWhitelisedLender(_lender), "GTM: cannot update lender");
        require(ms.whitelistAddress[_lender] != _value, "already assigned");
        ms.whitelistAddress[_lender] = _value;
    }

    function setAllowedMultiCollateralLimit(uint256 _collateralLimit)
        external
        onlySuperAdmin(msg.sender)
    {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();

        require(_collateralLimit > 0, "GTM: zero value provided");
        ms.multiCollateralLimit = _collateralLimit;
    }

    /// @dev set address of 1inch aggregator v4
    function set1InchAggregator(address _1inchAggregatorV4)
        external
        onlySuperAdmin(msg.sender)
    {
        LibMarketStorage.MarketStorage storage ms = LibMarketStorage
            .marketStorage();
        require(_1inchAggregatorV4 != address(0), "aggregator address zero");
        ms.aggregator1Inch = _1inchAggregatorV4;
    }

    function isWhitelisedLender(address _lender) public view returns (bool) {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();

        uint256 lengthLenders = ms.allWhitelistAddresses.length;
        for (uint256 i = 0; i < lengthLenders; i++) {
            if (ms.allWhitelistAddresses[i] == _lender) {
                return true;
            }
        }
        return false;
    }

    function getAllWhitelisedLenders()
        external
        view
        returns (address[] memory)
    {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();

        return ms.allWhitelistAddresses;
    }

    function getMultiCollateralLimit() external view returns (uint256) {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();
        return ms.multiCollateralLimit;
    }

    /// @dev returns boolean flag is address is whitelisted for unlimited lending
    /// @param _lender address of the lender for checking if its whitelisted for activate unlimited loans
    /// @return bool value returns for whitelisted addresses
    function isWhitelistedForActivation(address _lender)
        external
        view
        returns (bool)
    {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();

        return ms.whitelistAddress[_lender];
    }

    function getMinLoanAmountAllowed() external view returns (uint256) {
        LibMarketRegistryStorage.MarketRegistryStorage
            storage ms = LibMarketRegistryStorage.marketRegistryStorage();
        return ms.minLoanAmountAllowed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./../facets/protocolRegistry/LibProtocolStorage.sol";

interface IProtocolRegistry {
    /// @dev check function if Token Contract address is already added
    /// @param _tokenAddress token address
    /// @return bool returns the true or false value
    function isTokenApproved(address _tokenAddress)
        external
        view
        returns (bool);

    /// @dev check fundtion token enable for staking as collateral
    /// @param _tokenAddress address of the collateral token address
    /// @return bool returns true or false value

    function isTokenEnabledForCreateLoan(address _tokenAddress)
        external
        view
        returns (bool);

    function getGovPlatformFee() external view returns (uint256);

    function getThresholdPercentage() external view returns (uint256);

    function getAutosellPercentage() external view returns (uint256);

    function getSingleApproveToken(address _tokenAddress)
        external
        view
        returns (LibProtocolStorage.Market memory);

    function getSingleApproveTokenData(address _tokenAddress)
        external
        view
        returns (
            address,
            bool,
            uint256
        );

    function isSyntheticMintOn(address _token) external view returns (bool);

    function getTokenMarket() external view returns (address[] memory);

    function getSingleTokenSps(address _tokenAddress)
        external
        view
        returns (address[] memory);

    function isAddedSPWallet(address _tokenAddress, address _walletAddress)
        external
        view
        returns (bool);

    function isStableApproved(address _stable) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {LibDiamond} from "./../../shared/libraries/LibDiamond.sol";
import {LibAdminStorage} from "./../../facets/admin/LibAdminStorage.sol";
import {LibLiquidatorStorage} from "./../../facets/liquidator/LibLiquidatorStorage.sol";
import {LibProtocolStorage} from "./../../facets/protocolRegistry/LibProtocolStorage.sol";
import {LibPausable} from "./../../shared/libraries/LibPausable.sol";

struct AppStorage {
    address govToken;
    address govGovToken;
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlySuperAdmin(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(es.approvedAdminRoles[admin].superAdmin, "not super admin");
        _;
    }

    /// @dev modifer only admin with edit admin access can call functions
    modifier onlyEditTierLevelRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(
            es.approvedAdminRoles[admin].editGovAdmin,
            "not edit tier role"
        );
        _;
    }

    modifier onlyLiquidator(address _admin) {
        LibLiquidatorStorage.LiquidatorStorage storage es = LibLiquidatorStorage
            .liquidatorStorage();
        require(es.whitelistLiquidators[_admin], "not liquidator");
        _;
    }

    //modifier: only admin with AddTokenRole can add Token(s) or NFT(s)
    modifier onlyAddTokenRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(es.approvedAdminRoles[admin].addToken, "not add token role");
        _;
    }

    //modifier: only admin with EditTokenRole can update or remove Token(s)/NFT(s)
    modifier onlyEditTokenRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();

        require(es.approvedAdminRoles[admin].editToken, "not edit token role");
        _;
    }

    //modifier: only admin with AddSpAccessRole can add SP Wallet
    modifier onlyAddSpRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();
        require(es.approvedAdminRoles[admin].addSp, "not add sp role");
        _;
    }

    //modifier: only admin with EditSpAccess can update or remove SP Wallet
    modifier onlyEditSpRole(address admin) {
        LibAdminStorage.AdminStorage storage es = LibAdminStorage
            .adminRegistryStorage();
        require(es.approvedAdminRoles[admin].editSp, "not edit sp role");
        _;
    }

    modifier whenNotPaused() {
        LibPausable.enforceNotPaused();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library LibMeta {
    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library LibMarketRegistryStorage {
    bytes32 constant MARKET_REGISTRY_STORAGE_POSITION =
        keccak256("diamond.standard.MARKETREGISTRY.storage");

    struct MarketRegistryStorage {
        uint256 allowedLoanActivateLimit;
        uint256 minLoanAmountAllowed;
        uint256 ltvPercentage;
        uint256 multiCollateralLimit;
        address[] allWhitelistAddresses;
        mapping(address => bool) whitelistAddress;
    }

    function marketRegistryStorage()
        internal
        pure
        returns (MarketRegistryStorage storage es)
    {
        bytes32 position = MARKET_REGISTRY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library LibMarketStorage {
    bytes32 constant MARKET_STORAGE_POSITION =
        keccak256("diamond.standard.MARKET.storage");

    enum TierType {
        GOV_TIER,
        NFT_TIER,
        NFT_SP_TIER,
        VC_TIER
    }

    enum LoanStatus {
        ACTIVE,
        INACTIVE,
        CLOSED,
        CANCELLED,
        LIQUIDATED
    }

    enum LoanTypeToken {
        SINGLE_TOKEN,
        MULTI_TOKEN
    }

    enum LoanTypeNFT {
        SINGLE_NFT,
        MULTI_NFT
    }

    struct LenderDetails {
        address lender;
        uint256 activationLoanTimeStamp;
        bool autoSell;
    }

    struct LenderDetailsNFT {
        address lender;
        uint256 activationLoanTimeStamp;
    }

    struct LoanDetailsToken {
        uint256 loanAmountInBorrowed; //total Loan Amount in Borrowed stable coin
        uint256 termsLengthInDays; //user choose terms length in days
        uint32 apyOffer; //borrower given apy percentage
        LoanTypeToken loanType; //Single-ERC20, Multiple staked ERC20,
        bool isPrivate; //private loans will not appear on loan market
        bool isInsured; //Future use flag to insure funds as they go to protocol.
        address[] stakedCollateralTokens; //single - or multi token collateral tokens wrt tokenAddress
        uint256[] stakedCollateralAmounts; // collateral amounts
        address borrowStableCoin; // address of the stable coin borrow wants
        LoanStatus loanStatus; //current status of the loan
        address borrower; //borrower's address
        uint256 paybackAmount; // track the record of payback amount
        bool[] isMintSp; // flag for the mint VIP token at the time of creating loan
        TierType tierType;
    }

    struct LoanDetailsNFT {
        address[] stakedCollateralNFTsAddress; //single nft or multi nft addresses
        uint256[] stakedCollateralNFTId; //single nft id or multinft id
        uint256[] stakedNFTPrice; //single nft price or multi nft price //price fetch from the opensea or rarible or maunal input price
        uint256 loanAmountInBorrowed; //total Loan Amount in USD
        uint32 apyOffer; //borrower given apy percentage
        LoanTypeNFT loanType; //Single NFT and multiple staked NFT
        LoanStatus loanStatus; //current status of the loan
        uint56 termsLengthInDays; //user choose terms length in days
        bool isPrivate; //private loans will not appear on loan market
        bool isInsured; //Future use flag to insure funds as they go to protocol.
        address borrower; //borrower's address
        address borrowStableCoin; //borrower stable coin,
        TierType tierType;
    }

    struct LoanDetailsNetwork {
        uint256 loanAmountInBorrowed; //total Loan Amount in Borrowed stable coin
        uint256 termsLengthInDays; //user choose terms length in days
        uint32 apyOffer; //borrower given apy percentage
        bool isPrivate; //private loans will not appear on loan market
        bool isInsured; //Future use flag to insure funds as they go to protocol.
        uint256 collateralAmount; // collateral amount in native coin
        address borrowStableCoin; // address of the borrower requested stable coin
        LoanStatus loanStatus; //current status of the loan
        address payable borrower; //borrower's address
        uint256 paybackAmount; // paybacked amount of the indiviual loan
    }

    struct MarketStorage {
        mapping(uint256 => LoanDetailsToken) borrowerLoanToken; //saves the loan details for each loanId
        mapping(uint256 => LenderDetails) activatedLoanToken; //saves the information of the lender for each loanId of the token loan
        mapping(address => uint256[]) borrowerLoanIdsToken; //erc20 tokens loan offer mapping
        mapping(address => uint256[]) activatedLoanIdsToken; //mapping address of lender => loan Ids
        mapping(uint256 => LoanDetailsNFT) borrowerLoanNFT; //Single NFT or Multi NFT loan offers mapping
        mapping(uint256 => LenderDetailsNFT) activatedLoanNFT; //mapping saves the information of the lender across the active NFT Loan Ids
        mapping(address => uint256[]) borrowerLoanIdsNFT; //mapping of borrower address to the loan Ids of the NFT.
        mapping(address => uint256[]) activatedLoanIdsNFTs; //mapping address of the lender to the activated loan offers of NFT
        mapping(uint256 => LoanDetailsNetwork) borrowerLoanNetwork; //saves information in loanOffers when createLoan function is called
        mapping(uint256 => LenderDetails) activatedLoanNetwork; // mapping saves the information of the lender across the active loanId
        mapping(address => uint256[]) borrowerLoanIdsNetwork; // users loan offers Ids
        mapping(address => uint256[]) activatedLoanIdsNetwork; // mapping address of lender to the loan Ids
        mapping(address => uint256) stableCoinWithdrawable; // mapping for storing the plaform Fee and unearned APY Fee at the time of payback or liquidation     // [token or nft or network MarketFacet][stableCoinAddress] += platformFee OR Unearned APY Fee
        mapping(address => uint256) collateralsWithdrawableToken; // mapping to add the extra collateral token amount when autosell off,   [TokenMarket][collateralToken] += exceedaltcoins;  // liquidated collateral on autsell off
        mapping(address => uint256) collateralsWithdrawableNetwork; // mapping to add the exceeding collateral amount after transferring the lender amount,  when liquidation occurs on autosell off
        mapping(address => uint256) loanActivateLimit; // loan lend limit of each market for each wallet address
        uint256[] loanOfferIdsToken; //array of all loan offer ids of the ERC20 tokens Single or Multiple.
        uint256[] loanOfferIdsNFTs; //array of all loan offer ids of the NFT tokens Single or Multiple
        uint256[] loanOfferIdsNetwork; //array of all loan offer ids of the native coin
        uint256 loanIdToken;
        uint256 loanIdNft;
        uint256 loanIdNetwork;
        address aggregator1Inch;
        mapping(address => mapping(address => uint256)) liquidatedSUNTokenbalances; //mapping of wallet address to track the approved claim token balances when loan is liquidated // wallet address lender => sunTokenAddress => balanceofSUNToken
    }

    function marketStorage() internal pure returns (MarketStorage storage es) {
        bytes32 position = MARKET_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library LibProtocolStorage {
    bytes32 constant PROTOCOLREGISTRY_STORAGE_POSITION =
        keccak256("diamond.standard.PROTOCOLREGISTRY.storage");

    enum TokenType {
        ISDEX,
        ISELITE,
        ISVIP
    }

    // Token Market Data
    struct Market {
        address dexRouter;
        address gToken;
        bool isMint;
        TokenType tokenType;
        bool isTokenEnabledAsCollateral;
    }

    struct ProtocolStorage {
        uint256 govPlatformFee;
        uint256 govAutosellFee;
        uint256 govThresholdFee;
        mapping(address => address[]) approvedSps; // tokenAddress => spWalletAddress
        mapping(address => Market) approvedTokens; // tokenContractAddress => Market struct
        mapping(address => bool) approveStable; // stable coin address enable or disable in protocol registry
        address[] allApprovedSps; // array of all approved SP Wallet Addresses
        address[] allapprovedTokenContracts; // array of all Approved ERC20 Token Contracts
    }

    function protocolRegistryStorage()
        internal
        pure
        returns (ProtocolStorage storage es)
    {
        bytes32 position = PROTOCOLREGISTRY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {IERC173} from "../interfaces/IERC173.sol";
import {LibMeta} from "./LibMeta.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferredDiamond(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferredDiamond(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            LibMeta.msgSender() == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    function addDiamondFunctions(
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _ownershipFacet
    ) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = IERC173.transferOwnership.selector;
        functionSelectors[1] = IERC173.owner.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: _ownershipFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        diamondCut(cut, address(0), "");
    }

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint16 selectorPosition = uint16(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                _facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
                selector
            );
            ds
                .selectorToFacetAndPosition[selector]
                .facetAddress = _facetAddress;
            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint16 selectorPosition = uint16(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(
                _facetAddress,
                "LibDiamondCut: New facet has no code"
            );
            ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(oldFacetAddress, selector);
            // add function
            ds
                .selectorToFacetAndPosition[selector]
                .functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
                selector
            );
            ds
                .selectorToFacetAndPosition[selector]
                .facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (success == false) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize != 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library LibLiquidatorStorage {
    bytes32 constant LIQUIDATOR_STORAGE =
        keccak256("diamond.standard.LIQUIDATOR.storage");
    struct LiquidatorStorage {
        mapping(address => bool) whitelistLiquidators; // list of already approved liquidators.
        mapping(address => mapping(address => uint256)) liquidatedSUNTokenbalances; //mapping of wallet address to track the approved claim token balances when loan is liquidated // wallet address lender => sunTokenAddress => balanceofSUNToken
        address[] whitelistedLiquidators; // list of all approved liquidator addresses. Stores the key for mapping approvedLiquidators
        address aggregator1Inch;
        bool isInitializedLiquidator;
    }

    function liquidatorStorage()
        internal
        pure
        returns (LiquidatorStorage storage ls)
    {
        bytes32 position = LIQUIDATOR_STORAGE;
        assembly {
            ls.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library LibAdminStorage {
    bytes32 constant ADMINREGISTRY_STORAGE_POSITION =
        keccak256("diamond.standard.ADMINREGISTRY.storage");

    struct AdminAccess {
        //access-modifier variables to add projects to gov-intel
        bool addGovIntel;
        bool editGovIntel;
        //access-modifier variables to add tokens to gov-world protocol
        bool addToken;
        bool editToken;
        //access-modifier variables to add strategic partners to gov-world protocol
        bool addSp;
        bool editSp;
        //access-modifier variables to add gov-world admins to gov-world protocol
        bool addGovAdmin;
        bool editGovAdmin;
        //access-modifier variables to add bridges to gov-world protocol
        bool addBridge;
        bool editBridge;
        //access-modifier variables to add pools to gov-world protocol
        bool addPool;
        bool editPool;
        //superAdmin role assigned only by the super admin
        bool superAdmin;
    }

    struct AdminStorage {
        mapping(address => AdminAccess) approvedAdminRoles; // approve admin roles for each address
        mapping(uint8 => mapping(address => AdminAccess)) pendingAdminRoles; // mapping of admin role keys to admin addresses to admin access roles
        mapping(uint8 => mapping(address => address[])) areByAdmins; // list of admins approved by other admins, for the specific key
        //admin role keys
        uint8 PENDING_ADD_ADMIN_KEY;
        uint8 PENDING_EDIT_ADMIN_KEY;
        uint8 PENDING_REMOVE_ADMIN_KEY;
        uint8[] PENDING_KEYS; // ADD: 0, EDIT: 1, REMOVE: 2
        address[] allApprovedAdmins; //list of all approved admin addresses
        address[][] pendingAdminKeys; //list of pending addresses for each key
        address superAdmin;
    }

    function adminRegistryStorage()
        internal
        pure
        returns (AdminStorage storage es)
    {
        bytes32 position = ADMINREGISTRY_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {LibMeta} from "./../../shared/libraries/LibMeta.sol";

/**
 * @dev Library version of the OpenZeppelin Pausable contract with Diamond storage.
 * See: https://docs.openzeppelin.com/contracts/4.x/api/security#Pausable
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol
 */
library LibPausable {
    struct Storage {
        bool paused;
    }

    bytes32 private constant STORAGE_SLOT =
        keccak256("diamond.standard.Pausable.storage");

    /**
     * @dev Returns the storage.
     */
    function _storage() private pure returns (Storage storage s) {
        bytes32 slot = STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Reverts when paused.
     */
    function enforceNotPaused() internal view {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Reverts when not paused.
     */
    function enforcePaused() internal view {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() internal view returns (bool) {
        return _storage().paused;
    }

    /**
     * @dev Triggers stopped state.
     */
    function _pause() internal {
        _storage().paused = true;
        emit Paused(LibMeta.msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function _unpause() internal {
        _storage().paused = false;
        emit Unpaused(LibMeta.msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}