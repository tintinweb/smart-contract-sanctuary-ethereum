// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { 
    VaultParams,
    Whitelist, 
    LendingParams,
    NFTfi
} from "./lib/GoblinVaultLib.sol";

import { IFactory } from "./interfaces/IFactory.sol";

contract VaultManager {

    /*///////////////////////////////////////////////////////////////
                              INITIALIZATION
    ///////////////////////////////////////////////////////////////*/

    /// @notice admin address
    address internal GoblinSax;

    /// @notice vault factory contract
    IFactory internal Vault_Factory;

    /// @notice LP token factory contract
    IFactory internal NFT_Factory;

    constructor(
        LendingParams memory _lendingParams,
        NFTfi memory  _nftfi,
        address _astaria,
        address _arcade,
        address _goblinsax,
        address v_factory,
        address n_factory,
        address _parser,
        string memory uri
    ) {
        // lending params
        lendingParams = _lendingParams;

        // lending platforms
        nftfi = _nftfi;
        astaria = _astaria;
        arcade = _arcade;

        // admin
        GoblinSax = _goblinsax;

        // contracts
        Vault_Factory = IFactory(v_factory);
        NFT_Factory = IFactory(n_factory);
        parser = _parser;

        // LP token uri
        LPTokenURI = uri;
    }

    modifier onlyGoblin {
        if (msg.sender != GoblinSax) revert Manager_NotAdmin();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                  STATE
    ///////////////////////////////////////////////////////////////*/

    /// @notice address => whether it's a whitelisted strategist
    mapping(address => bool) public strategists;

    /// @notice token address => whether it's supported
    /// note: a placeholder address can be used to represent ETH / Native
    mapping(address => bool) public supportedTokens;

    /// @notice encoded vault name => whether in use
    mapping(bytes => bool) public nameInUse;

    /// @notice encoded vault symbol => whether in use
    mapping(bytes => bool) public symbolInUse;

    /// @notice all vault addresses
    address[] public allVaults;

    /// @notice address of HistoryParser
    /// review: should HistoryParser be a library
    address public parser;

    /// @notice URI of LP Token
    string public LPTokenURI;

    /// @notice abi encoded Whitelist[]
    bytes internal whitelist;

    /// @notice protocol-level lending params
    LendingParams public lendingParams;

    /// @notice NFTfi contracts
    NFTfi internal nftfi;

    /// @notice arcade multisig address
    address public arcade;

    /// @notice astaria vault address
    address public astaria;

    /// note: can add others below w/ contract upgrade

    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    ///////////////////////////////////////////////////////////////*/

    /// @notice when a new vault is created
    event VaultCreated(address indexed vault);

    /// @notice when 'whitelist' is updated
    event WhitelistUpdated(Whitelist[] _whitelist);
    
    /// @notice when 'lendingParams' are updated
    event LendingParamsUpdated(uint indexed adminFee, uint indexed maxStrategistFee);

    /// @notice when 'GoblinSax' is updated
    event NewAdmin(address indexed goblinsax);

    /// @notice when a new strategist is whitelisted in 'strategists'
    event NewStrategist(address indexed strategist);

    /// @notice when a strategist is removed from whitelist in 'strategists'
    event RemovedStrategist(address indexed strategist);

    /// @notice when the 'parser' is updated
    event ParserUpdated(address indexed _parser);

    /// @notice when 'nftfi' is updated
    event NFTfiUpdated(NFTfi indexed _nftfi);

    /// @notice when 'arcade' is updated
    event ArcadeUpdated(address indexed _arcade);

    /// @notice when the 'LPTokenURI' changes
    event URIUpdated(string uri);

    /*///////////////////////////////////////////////////////////////
                                  ERRORS
    ///////////////////////////////////////////////////////////////*/

    /// @notice assert called by GoblinSax
    error Manager_NotAdmin();

    /// @notice assert vault being created is private if unwhitelisted strategist
    error Manager_VaultMustBePrivate();

    /// @notice asssert strategist fee is within protocol params
    error Manager_InvalidFee();

    /// @notice assert asset is supported
    error Manager_UnsupportedAsset();

    /// @notice assert unique vault names
    error Manager_NameTaken();

    /// @notice assert unique vault symbols
    error Manager_SymbolTaken();

    /*///////////////////////////////////////////////////////////////
                              VAULT CREATION
    ///////////////////////////////////////////////////////////////*/

    function createVault(
        string calldata name,
        string calldata symbol,
        address asset, 
        address[] memory _whitelist, 
        uint strategistFee
    ) external returns (address vault) {
        address strategist = msg.sender;

        // assert name and symbol are not taken
        if (nameInUse[abi.encodePacked(name)]) revert Manager_NameTaken();
        if(symbolInUse[abi.encodePacked(symbol)]) revert Manager_SymbolTaken();

        // set name and symbol as taken
        nameInUse[abi.encodePacked(name)] = true;
        symbolInUse[abi.encodePacked(symbol)] = true;

        if (strategist != GoblinSax && !strategists[strategist]) {
            if (whitelist.length == 0) revert Manager_VaultMustBePrivate();
        }

        if (strategistFee > lendingParams.maxStrategistFee) revert Manager_InvalidFee();

        if (!supportedTokens[asset]) revert Manager_UnsupportedAsset();

        VaultParams memory params = VaultParams({
            name : name,
            symbol : symbol,
            asset : asset,
            manager : address(this),
            parser : parser,
            goblinsax : GoblinSax,
            strategist : strategist,
            strategistFee : strategistFee,
            nft_factory : NFT_Factory,
            whitelist : _whitelist,
            nftfi : nftfi,
            arcade : arcade,
            astaria : astaria,
            baseURI : LPTokenURI
        });

        vault = Vault_Factory.createVault(abi.encode(params));

        allVaults.push(vault);

        emit VaultCreated(vault);
    }

    /*///////////////////////////////////////////////////////////////
                                GOBLINSAX
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice updates 'lendingParams'
     *
     * @dev only callable by GoblinSax
     *
     * @param params                         new LendingParams 
    */
    function updateLendingParams(LendingParams calldata params) external onlyGoblin {
        lendingParams = params;

        emit LendingParamsUpdated(params.adminFee, params.maxStrategistFee);
    }

    /**
     * @notice adds support or ERC20 asset
     *
     * @dev only callable by GoblinSax
     *
     * @param asset                          ERC20 token
    */
    function supportAsset(address asset) external onlyGoblin {
        supportedTokens[asset] = true;
    }

    /**
     * @notice deprecates support for ERC20 asset
     *
     * @dev only callable by GoblinSax
     * @dev any vault using this asset must be deprecated individually (i.e. pausing deposits)
     *
     * @param asset                          ERC20 token
    */
    function deprecateAsset(address asset) external onlyGoblin {
        supportedTokens[asset] = false;
    }

    /**
     * @notice updates 'parser to a new HistoryParser contract
     *
     * @dev only callable by GoblinSax
     * @dev parser is upgradeable without an on-chain call, this is
     *      just an optional function
     *
     * @param _parser                        new HistoryParser address
    */
    function updateParser(address _parser) external onlyGoblin {
        parser = _parser;

        emit ParserUpdated(_parser);
    }

    /**
     * @notice updates 'nftfi'
     *
     * @dev only callable by GoblinSax
     *
     * @param _nftfi                         new NFTfi struct 
    */
    function updateNFTfi(NFTfi calldata _nftfi) external onlyGoblin {
        nftfi = _nftfi;

        emit NFTfiUpdated(_nftfi);
    }

    /**
     * @notice updates 'arcade'
     *
     * @dev only callable by GoblinSax
     *
     * @param _arcade                        new Arcade struct
    */
    function updateArcade(address _arcade) external onlyGoblin {
        arcade = _arcade;

        emit ArcadeUpdated(_arcade);
    }

    /**
     * @notice removes stategist from whitelist in 'strategists'
     *
     * @dev only callable by GoblinSax
     * @dev uri should be updatable without an on-chain call, this is
     *      just an emergency function
     *
     * @param uri                            new URI for LP token
    */
    function updateURI(string calldata uri) external onlyGoblin {
        LPTokenURI = uri;

        emit URIUpdated(uri);
    }

    /**
     * @notice updates 'GoblinSax'
     *
     * @dev only callable by GoblinSax
     *
     * @param goblinsax                      new admin
    */
    function updateAdmin(address goblinsax) external onlyGoblin {
        GoblinSax = goblinsax;

        emit NewAdmin(goblinsax);
    }

    /**
     * @notice whitelists new stategist in 'strategists'
     *
     * @dev only callable by GoblinSax
     *
     * @param strategist                     address to whitelist as strategist
    */
    function validateStrategist(address strategist) external onlyGoblin {
        strategists[strategist] = true;

        emit NewStrategist(strategist);
    }

    /**
     * @notice removes stategist from whitelist in 'strategists'
     *
     * @dev only callable by GoblinSax
     * @dev this function must be called along with 'setStrategist' in vaults where
     *      that strategist is active to completely remove a strategist from the protocol
     *
     * @param strategist                     address to de-whitelist as strategist
    */
    function invalidateStrategist(address strategist) external onlyGoblin {
        strategists[strategist] = false;

        emit RemovedStrategist(strategist);
    }


    /*///////////////////////////////////////////////////////////////
                               PARAM QUERIES 
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice verifies a loan is valid for protocol
     *
     * @dev called from isValidSignature in vault, and that function will 
     *      will revert if this function returns false
     *
     * @param collection                     NFT collateral address
     * @param principal                      loan principal amount
     * @param duration                       duration of loan
     *
     * @return valid                         whether loan terms are valid
    */
    // function validateLoanTerms(
    //     address collection, 
    //     uint principal,
    //     uint duration
    // ) external view returns (bool valid) {
    //     Whitelist[] memory _whitelist = abi.decode(whitelist,(Whitelist[]));

    //     LendingParams memory params = lendingParams;

    //     // todo: integrate fixed point math lib..
    //     uint RAY = 10 ** 27;

    //     // assert duration is within params
    //     if (duration > params.maxLoanDuration) return false;

    //     uint length = _whitelist.length;

    //     uint collateral;

    //     // get price for collection — return false if collection not whitelisted
    //     for (uint i; i < length; ) {
    //         if (_whitelist[i].collection == collection) {
    //             collateral = _whitelist[i].price;

    //             break;
    //         }

    //         unchecked { ++i; }

    //         if (i == length) return false;
    //     }

    //     // calculate LTV for loan
    //     uint ltv = principal * RAY / collateral * 10000 / RAY;

    //     if (ltv <= params.maxLTV) return true;
    // }

    /// review: remove this?
    /**
     * @notice getter function for whitelist
     *
     * @dev the whitelist can also be retreived by calling .whitelist() from this contract
     *      and decoding in ethers. this is an optional function
     *
     * @return _whitelist                    Whitelist[] of whitelisted collection address + accepted price
    */
    function displayWhitelist() external view returns (Whitelist[] memory _whitelist) {
        return abi.decode(whitelist,(Whitelist[]));
    }

    function displayAllVaults() external view returns (address[] memory) {
        return allVaults;
    }

    
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.4;

/// @notice IDirectLoanCoordinator clone
/// @dev exposed totalNumLoans getter to retrieve NFTfi loan id 
interface IDirectLoanCoordinator {
    enum StatusType {
        NOT_EXISTS,
        NEW,
        RESOLVED
    }

    /**
     * @notice This struct contains data related to a loan
     *
     * @param smartNftId - The id of both the promissory note and obligation receipt.
     * @param status - The status in which the loan currently is.
     * @param loanContract - Address of the LoanType contract that created the loan.
     */
    struct Loan {
        address loanContract;
        uint64 smartNftId;
        StatusType status;
    }

    function registerLoan(address _lender, bytes32 _loanType) external returns (uint32);

    function mintObligationReceipt(uint32 _loanId, address _borrower) external;

    function resolveLoan(uint32 _loanId) external;

    function promissoryNoteToken() external view returns (address);

    function obligationReceiptToken() external view returns (address);

    function getLoanData(uint32 _loanId) external view returns (Loan memory);

    function isValidLoanId(uint32 _loanId, address _loanContract) external view returns (bool);

    function totalNumLoans() external view returns (uint32);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice interface for https://github.com/NFTfi-Genesis/nftfi.eth/blob/main/V2/contracts/loans/direct/loanTypes/DirectLoanFixedOffer.sol
interface IDirectLoanFixedOffer {

    /// @notice NFTfi loan terms
    struct LoanTerms {
        uint256 loanPrincipalAmount;
        uint256 maximumRepaymentAmount;
        uint256 nftCollateralId;
        address loanERC20Denomination;
        uint32 loanDuration;
        uint16 loanInterestRateForDurationInBasisPoints;
        uint16 loanAdminFeeInBasisPoints;
        address nftCollateralWrapper;
        uint64 loanStartTime;
        address nftCollateralContract;
        address borrower;
    }

    /// @notice NFTfi offer struct
    struct Offer {
        uint256 loanPrincipalAmount;
        uint256 maximumRepaymentAmount;
        uint256 nftCollateralId;
        address nftCollateralContract;
        uint32 loanDuration;
        uint16 loanAdminFeeInBasisPoints;
        address loanERC20Denomination;
        address referrer;
    }

    /// @notice NFTfi signature
    struct Signature {
        uint256 nonce;
        uint256 expiry;
        address signer;
        bytes signature;
    }

    /// @notice borrower settings
    struct BorrowerSettings {
        address revenueSharePartner;
        uint16 referralFeeInBasisPoints;
    }

    /// @notice accepts Offer
    function acceptOffer(
        Offer memory _offer,
        Signature memory _signature,
        BorrowerSettings memory _borrowerSettings
    ) external;

    /// @notice pays back loan in full
    function payBackLoan(uint32 _loanId) external;

    function adminFeeInBasisPoints() external view returns(uint16);


    /// @notice getter for loan id => LoanTerms mapping
    function loanIdToLoan(uint32 _id) external view returns(LoanTerms memory _loan);

    /// @notice mins obligation receipt of loan
    function mintObligationReceipt(uint32 _loanId) external;

    function unpause() external;

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { VaultParams } from "../lib/GoblinVaultLib.sol";

import "./IGoblinVaultNFT.sol";

interface IFactory {

    function createVault(bytes memory _params) external returns(address);

    function createGoblinVaultNFT(
        bool _private,
        string calldata name,
        string calldata symbol,
        address vault,
        address goblinsax,
        string calldata baseURI
    ) external returns(IGoblinVaultNFT);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

interface IGoblinVaultNFT {
    function openVault() external;

    function mint(address to) external returns(uint _id);

    function burn(uint account) external;

    function ownerOf(uint account) external view returns(address);

    function idsOwned(address user) external view returns(uint[] memory);

    function balanceOf(address user) external view returns(uint);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

interface IPromissoryNote {
    function ownerOf(uint id) external returns (address);

    function exists(uint id) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import  { IFactory } from "../interfaces/IFactory.sol";

import { IPromissoryNote } from "../interfaces/IPromissoryNote.sol";

import { IDirectLoanCoordinator } from  "../interfaces/IDirectLoanCoordinator.sol";

import { IDirectLoanFixedOffer } from  "../interfaces/IDirectLoanFixedOffer.sol";

/*//////////////////////////////////////////////////////////////
                             HISTORY
//////////////////////////////////////////////////////////////*/

/// todo: ensure all params are commented

/**
 * @notice data for deposits, withdraws, and loans — first of two units of history
 *
 * @dev 'treasury' is the treasury of the underlying asset minus accumulatedFees. 
 *      it's assigned here on withdraws and on new loans. it's used in HistoryParser to both
 *      calculate an account's contribution to a new loan & to determine whether the withdraw / new loan
 *      happened before or after a resolved loan that occured on the same block (i.e. timestamp)
 * @dev 'virtualTreasury' is used when processing a resolved loan that occured on the same block
 *      as a new loan, to determine if fees need to be subtracted from 'treasury' — otherwise those
 *      fees become would become a 'ghost contributor' to the new loan
 *
 * @param account                       id of account LP token (if d/w)
 * @param amount                        amount of deposit / withdraw (if d/w)
 * @param nft                           collection address (if loan)
 * @param loan_id                       if of loan (if loan)
 * @param nft_id                        id of nft (if loan)
 * @param promissory_id                 id of promissoryNote (if loan)
 * @param principal                     loan principal amount
 * @param repaymentAmount               loan repayment after platform (e.g. NFTfi) fees (if loan)
 * @param adminFee                      admin fee for loan (if loan)
 * @param strategistFee                 strategist fee for loan (if loan)
 * @param strategist                    strategist for loan (if loan)
 * @param treasury                      treasury before withdraw / loan (withdraw / loan)
 * @param virtualTreasury               virtual treasury before loan (if loan)
 * @param time                          time of action (start time if loan)
 * @param action                        action type (deposit / withdraw / loan)
 * @param platform                      lending platform (if loan)
*/
struct VaultAction {
    uint account; 
    uint amount;
    address nft;
    uint loan_id;
    uint nft_id;
    uint promissory_id;
    uint principal;
    uint repaymentAmount;
    uint adminFee;
    uint strategistFee;
    address strategist;
    uint treasury;
    uint virtualTreasury;
    uint time;
    ActionType action;
    LoanType platform;
}

/**
 * @notice data for resolved loans — second of two units of history
 *
 * @param loan_id                       id of loan
 * @param amount                        amount repayed after all fees
 * @param principal                     principal of loan  
 * @param time                          time of loan repayment 
 * @param admin_fee                     admin fee from loan interest
 * @param strategist                    strategist for loan
 * @param strategist_fee                strategist fee from loan interest
*/
struct LoanResolved {
    uint loan_id;
    uint amount;
    uint principal;
    uint time;
    uint adminFee;
    uint strategistFee;
    address strategist;
    LoanType platform;
}

/// @notice enum of action types
enum ActionType {
    deposit,
    withdraw,
    loan
}

/// @notice enum of lending platforms
enum LoanType {
    empty,
    nftfi,
    arcade,
    astoria,
    nftlp
}

/*//////////////////////////////////////////////////////////////
                          HISTORY HELPERS
//////////////////////////////////////////////////////////////*/

/**
 * @notice temporary data store for NFTfi loans w/ incomplete loan info
 *
 * @param loan_id                       id of loan
 * @param promissory_id                 id of PromissoryNote
 * @param treasuryAtLoan                treasury after offer was accepted
 * @param virtualTreasuryAtLoan         virtual treasury after offer was accepted
*/
struct IncompleteLoan {
    uint loan_id;
    uint promissory_id;
    uint treasuryAtLoan;
    uint virtualTreasuryAtLoan;
}

/**
 * @notice internal balances of fees and a treasury counter
 *
 * @dev when attributing contributions to a loan, we need to know: 
 *      vault balance, an account's balance, and loan principal amount
 *      if any of these 3 are wrong, we can't calculate the true balance of an account
 *      this struct is used to ensure an accurate vault balance so that fees don't get included in the vault balance
 *      if there is a repayed loan we don't know about at the time of a new loan, the true
 *      vault balance would include the rapayment (good) and the fees we 
 *      haven't yet added to 'accumulatedFees' (bad) — we need virtualTreasury so that we
 *      know whether or not to subtract fees from 'VaultAction.treasury' if the loan happened
 *      on the same timestamp as the resolved loan
 * @dev stored as a struct for cheaper calls vs calling both
 *
 * @param accumulatedFees               total fee amount stored in vault
 * @param virtualTreasury               internal treasury counter
*/
struct InternalBalances {
    uint accumulatedFees;
    uint virtualTreasury;
}

/*//////////////////////////////////////////////////////////////
                        VAULT CREATION
//////////////////////////////////////////////////////////////*/

/**
 * @notice parameter for vault creation
 *
 * @dev used to avoid a stack too deep error
 * 
 * @param vault_id                       id of vault
 * @param asset                          address of underlying token for vault
 * @param manager                        address of VaultManager.sol
 * @param parser                         address of HistoryParser
 * @param goblinsax                      address of GoblinSax (admin)
 * @param strategist                     address of vault strategist
 * @param strategistFee                  strategist fee in BPS
 * @param nft_factory                    LP token factory contract
 * @param whitelist                      vault whitelist if private
 * @param nftfi                          addresses of NFTfi contracts
 * @param arcade                         address for Arcade contracts
 * @param baseURI                        uri for LP token
*/
struct VaultParams {
    string name;
    string symbol;
    address asset;
    address manager;
    address parser;
    address goblinsax;
    address strategist;
    uint strategistFee;
    IFactory nft_factory;
    address[]  whitelist;
    NFTfi nftfi;
    address arcade;
    address astaria;
    string baseURI;
}


/*//////////////////////////////////////////////////////////////
                        LENDING PLATFORMS
//////////////////////////////////////////////////////////////*/

struct NFTfi {
    IDirectLoanFixedOffer loan;
    IDirectLoanCoordinator coordinator;
    IPromissoryNote promissoryNote;
}

/*//////////////////////////////////////////////////////////////
                        PROTOCOL PARAMS
//////////////////////////////////////////////////////////////*/

/**
 * @notice protocol-level collection whitelist and prices
 *
 * @dev stored as an encoded array in VaultManager
 *
 * @param collection                    address of NFT collection
 * @param price                         accepted price for an item in collection
*/
struct Whitelist {
    address collection;
    uint256 price;
}

/**
 * @notice protocol-level loan params
 *
 * @dev stored as a variable in VaultManager
 *
 * @param maxLTV                        maximum LTV for a loan
 * @param maxStrategistFee              maximum strategist fee in BPS
 * @param maxLoanDuration               maximum loan duration
 * @param adminFee                      admin fee in BPS
*/
struct LendingParams {
    uint256 maxStrategistFee;
    uint256 adminFee;
}

/*//////////////////////////////////////////////////////////////
                        PARSING HELPERS
//////////////////////////////////////////////////////////////*/

/**
 * @notice struct for account's contributions to loan
 *
 * @dev used in _calculateBalance
 *
 * @param loan_id                       id of loan
 * @param contribution                  amount contributed to loan
*/
struct Contribution {
    uint loan_id;
    uint contribution;
    LoanType platform;
}

/**
 * @notice holds variables used in HistoryParser's calculateBalance
 *
 * @dev used to avoid a stack too deep error
 * 
 * @param v_history                      history of deposits, withdraws, and loans
 * @param r_history                      resolved loans history
 * @param contributions                  temporary holder of account's loan contributions
 * @param next_repayment                 time of next repayment
 * @param contribution                   an account's contribution to the principal of current loan
 * @param c_counter                      num of active loans that an account contributed to at any time in history
 * @param v_length                       length of v_history
 * @param r_idx                          current index of resolved loans history
*/
struct HistoryHolder {
    VaultAction[] v_history;
    LoanResolved[] r_history;
    Contribution[] contributions;
    uint next_repayment;
    uint contribution;
    uint c_counter;
    uint v_length;
    uint r_idx;
}