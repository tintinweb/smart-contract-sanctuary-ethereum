// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { SafeERC20, IERC20 } from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/token/ERC721/IERC721.sol";
import "openzeppelin/token/ERC721/IERC721Receiver.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";
import "openzeppelin/interfaces/IERC1271.sol";

import { IHistoryParser } from "./interfaces/IHistoryParser.sol";
import { IFactory } from "./interfaces/IFactory.sol";
import { IVaultManager } from "./interfaces/IVaultManager.sol";
import "./interfaces/IGoblinVaultNFT.sol";

import "./interfaces/IDirectLoanCoordinator.sol";
import "./interfaces/IDirectLoanFixedOffer.sol";

import {
    VaultParams,
    VaultAction,
    LoanResolved,
    IncompleteLoan,
    ActionType,
    LoanType,
    InternalBalances,
    Contribution,
    NFTfi
} from "./lib/GoblinVaultLib.sol";

// review: safe transfer? (not needed as we're only dealing with WETH & DAI)
contract Vault is IERC1271, IERC721Receiver {

    /*//////////////////////////////////////////////////////////////
                             INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    
    /// TODO: add strategist address & fee params to loan history
    /// TODO: nft liquidation and renegotation
    /// TODO: swaps names LoanResolved ResolvedLoan
    /// TODO: deposit lock (e.g. depcrecated vaults) review do we want this?
    /// TODO: non-param functions to update lendng platform addresses from VaultManager
    ///       and see what else can be directly sourced from VaultManager rather than stored here

    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    bytes4 constant internal MAGICVALUE = 0x1626ba7e;
    bytes4 constant internal INVALID_SIGNATURE = 0xffffffff;
    
    IHistoryParser private  Parser;

    IGoblinVaultNFT public  nft;

    /// @notice underlying asset
    IERC20 public asset;

    /// @notice vault manager
    IVaultManager public manager;
    
    /// @notice address of admin
    address public goblinsax;

    /// @notice address of strategist
    address public strategist;

    /// @notice whether vault is private
    bool public private_vault;

    constructor(bytes memory _params) {
        VaultParams memory params = abi.decode(_params,(VaultParams));

        // store state variables
        asset = IERC20(params.asset);
        strategistFee = params.strategistFee;
        Parser = IHistoryParser(params.parser);
        manager = IVaultManager(params.manager);
        goblinsax = params.goblinsax;
        strategist = params.strategist;
        nftfi = params.nftfi;
        arcade = params.arcade;
        
        bool _private = params.whitelist.length > 0;

        // if relevant, store whitelist to state & set vault to private
        if (_private) {
            private_vault = true;

            whitelist = params.whitelist;
        }

        // create and store lp nft
        nft = params.nft_factory.createGoblinVaultNFT(
            _private, 
            params.name, 
            params.symbol,
            address(this), 
            params.goblinsax, 
            params.baseURI
        );

        // review: is this how approval should be handled?
        // give NFTfi's DirectLoanLoanFixedOffer.sol unlimited approval
        asset.approve(address(params.nftfi.loan), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                               VAULT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice holder of whitelist
    address[] internal whitelist;

    /// @notice lending platform => loan id => whether it was resolved
    mapping(LoanType => mapping(uint => bool)) internal resolvedLoan;

    /// @notice account id => whether it exists
    /// note: created exists here, and not in the NFT contract for cheaper gas
    mapping(uint => bool) internal exists;

    /// @notice undistributed fees in vault and internal vault counter
    /// note: internal vault counter is used to singal unprocessed repayments —
    ///       both at withdraw & to remove protocol fees from vault_balance in loan history
    InternalBalances internal internalBalances;

    /// @notice strategist fee in BPS
    uint public strategistFee;

    /// @notice index in 'resolved_history' to calculate fees from
    uint internal feeNonce;

    /// @notice history of all deposits, withdraws, and loans
    VaultAction[] internal history; 

    /// @notice history resolved loans
    /// note: must be chonological or bug
    LoanResolved[] internal resolved_history;

    /// @notice NFTfi loan ids w/ incomplete loan data
    uint[] internal incomplete_loans;

    NFTfi internal nftfi;

    address internal arcade;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Deposit(uint indexed _id, address indexed sender, uint amount);

    event Withdraw(uint indexed _id, address indexed to, address indexed sender, uint amount);

    event NewLoan(uint indexed loan_id);

    event ResolvedLoan(uint indexed loan_id, uint repayment, uint admin_fee, uint strategist_fee);

    event CompletedLoanInfo();

    event FailedCompleteLoanInfo();

    event NewAdmin(address indexed _goblinsax);

    event NewStrategist(address indexed _strategist);

    event NewFee(uint fee);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice assert caller of admin-permissioned functions is GoblinSax
    error Vault_NotAdmin();

    /// @notice assert caller of strategist-permissioned functions is current strategist
    error Vault_NotStrategist();

    /// @notice assert strategist fee is within protocol params
    error Vault_InvalidFee();

    /// @notice assert withdraw / balance check cannot be processed with incomplete loan history
    error Vault_IncompleteLoanInfo();

    /// @notice assert withdraw cannot be initiated with unprocessed resolved loans
    error Vault_UnprocessedResolvedLoans();

    /// @notice assert inputted loan data matches incomplete loan data when forceCompleteLoanInfo is called
    error Vault_UnmatchingLoanData();

    /// @notice assert loan resolution cannot be processed for an active loan
    error Vault_LoanActive();

    /// @notice assert loan is valid
    error Vault_LoanDoesntExist();

    /// @notice assert incomplete loan info is still stored on NFTfi
    error Vault_FailedCompleteLoanInfo();

    /// @notice assert loan resolution cannot be processed twice for the same loan
    error Vault_LoanAlreadyResolved();

    /// @notice assert withdraw from an account is initiated by account owner
    error Vault_NotAccountOwner();

    /// @notice assert withdraw from an account doesn't exceed account's balance
    error Vault_BalanceTooLow();

    /// @notice assert withdraws cannot be initiated if SHTF (i.e. contract needs an upgrade)
    error Vault_WithdrawsLocked();

    /// @notice assert deposits cannot be initiated if vault is deprecated 
    error Vault_DepositsLocked();

    /// @notice assert withdraw cannot be initiated from nonexistant account
    error Vault_NonexistentAccount();

    /// @notice assert address is whitelisted if vault is private
    error Vault_NotWhitelisted();

    /*//////////////////////////////////////////////////////////////
                               LOAN UPDATES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice saves NFTfi loan repayment information to 'resolved' in storage
     *
     * @dev caller must be GoblinSax to ensure time is accurate and
     *      to ensure that this isn't called during a collateral liquidation
     *
     * @param _id                           id of loan
     * @param time                          time of loan repayment 
    */
    function loanRepayed(
        uint _id, 
        uint time
    ) external {
        // todo: ensure a collateral liquidation isn't in progress..
        // todo: confirm loan resolved with NFTfi

        LoanType platform = LoanType.nftfi;

        // ensure loan info is complete — will revert if unable
        completeLoanInfo();

        // assert caller is GoblinSax
        if (msg.sender != goblinsax) revert Vault_NotAdmin();

        // assert resolution hasn't already been processed 
        if (resolvedLoan[platform][_id]) revert Vault_LoanAlreadyResolved();

        resolvedLoan[platform][_id] = true;

        // save history to memory
        VaultAction[] memory _history = history;

        VaultAction memory loan;

        uint interest;
        uint _adminFee;
        uint _strategistFee;
        uint repayment;

        uint length = _history.length;

        // loop through history
        for (uint i; i < length; ++i) {
            // if index is loan
            if (_history[i].platform == platform && _history[i].loan_id == _id) {
                // save loan data and calculate GoblinSax fees + repayment
                loan = _history[i];
                
                // review: is accounting for negative ROI necessary?
                // get interest amount, accounting for negative ROI
                interest = loan.repaymentAmount > loan.principal ? loan.repaymentAmount - loan.principal : 0;

                _adminFee = interest * loan.adminFee / 10000;

                _strategistFee = interest * loan.strategistFee / 10000;

                repayment = loan.repaymentAmount - (_adminFee + _strategistFee);

                // add fees to accumulatedFees
                internalBalances.accumulatedFees += _adminFee + _strategistFee;
            
            // if new loan happened after repayment reduce treasury by fees to avoid ghost contributor
            } else if ( _history[i].time >= time && _history[i].action == ActionType.loan ) {
                // if resolution happened on the same timestamnp && treasury is larger than virtualTreasury
                // meaning resolution happned first in the same block
                if (_history[i].time == time && _history[i].treasury > _history[i].virtualTreasury) {
                    // remove from fees from history's treasury in storage
                    history[i].treasury -= _adminFee + _strategistFee;
                    history[i].virtualTreasury -= _adminFee + _strategistFee;
                
                // else if loan happened on a later block
                } else if (_history[i].time > time){
                    history[i].treasury -= _adminFee + _strategistFee;
                    history[i].virtualTreasury -= _adminFee + _strategistFee;
                }
            }
        }

        // update virtual treasury
        internalBalances.virtualTreasury += repayment;

        // add resolved loan to history
        resolved_history.push( LoanResolved({
            loan_id : _id, 
            amount : repayment, 
            principal : loan.principal, 
            time : time,
            adminFee : _adminFee,
            strategistFee : _strategistFee,
            strategist : loan.strategist,
            platform : platform
        }) );

        emit ResolvedLoan(_id, repayment, _adminFee, _strategistFee);
    }

    /**
     * @notice fills incomplete loan info to 'history' in storage
     * @notice returns false and emits log if loan info is deleted from NFTfi's contract
     *
     * @dev caller must be GoblinSax to ensure time is accurate
     * @dev successfully completeing loan info unlocks withdraws & allows for a resolution to process
     * @dev unsuccessfully completing loan data requires completing via forceCompleteLoanInfo
     *
     * @return success                      whether or not loan data was completed             
    */
    function completeLoanInfo() public returns (bool success) {
        uint[] memory _incomplete = incomplete_loans;

        if (_incomplete.length == 0) return true;

        VaultAction[] memory _history = history;

        uint h_length = _history.length;

        IDirectLoanFixedOffer.LoanTerms memory terms;

        bool afterFirstIncomplete;
        uint principalSum;
        uint i_idx;
        
        uint interest;
        uint platformFee;
        uint repaymentAmount;

        // iterate through to edit incorrect data from incomplete NFTfi loans
        for (uint h_idx; h_idx < h_length; ++h_idx) {
            if (_history[h_idx].action == ActionType.loan) {
                // reduce the virtual treasury for the loan by the sum of principal amounts of all incomplete loans
                // note: after an incomplete NFTfi loan, all loans after will have an incorrect virtual treasury
                //       since the virtual treasury hasn't subtracted the principal amount(s) of incomplete NFTfi loan(s)
                if (afterFirstIncomplete) history[h_idx].virtualTreasury -= principalSum;

                // if h_idx is incomplete loan then fill in loan the data
                if (_history[h_idx].platform == LoanType.nftfi && _history[h_idx].loan_id == _incomplete[i_idx]) {
                    // get terms
                    terms = nftfi.loan.loanIdToLoan(uint32(_incomplete[i_idx]));

                    // if terms have been deleted from NFTfi contracts (i.e. loan resolved)
                    // note: we know terms are deleted by an item having a default value
                    if (terms.borrower == address(0)) {
                        revert Vault_FailedCompleteLoanInfo();
                    }

                    // calculate repayment after NFTfi fee
                    interest = terms.maximumRepaymentAmount - terms.loanPrincipalAmount;
                    platformFee = (interest * terms.loanAdminFeeInBasisPoints) / 10000;
                    repaymentAmount = terms.maximumRepaymentAmount - platformFee;

                    // fill loan data
                    history[h_idx].nft = terms.nftCollateralContract;
                    history[h_idx].nft_id = terms.nftCollateralId;
                    history[h_idx].principal = terms.loanPrincipalAmount;
                    history[h_idx].repaymentAmount = repaymentAmount;

                    // increase treasury by principal amount to get treasury before loan which is used to 
                    // calculate an account's share of the vault, and then their contributoon to the loan
                    history[h_idx].treasury += terms.loanPrincipalAmount; 

                    // add principal sum
                    principalSum += terms.loanPrincipalAmount;

                    afterFirstIncomplete = true;

                    // iterate i_idx
                    unchecked { ++i_idx; }
                }
            }  
        }

        // decrease virtual treasury by sum of loan principal amounts
        internalBalances.virtualTreasury -= principalSum;
        
        // delete incomplete_loans from storage
        delete incomplete_loans;

        success = true;

        emit CompletedLoanInfo();
    }

    /**
     * @notice manual input to complete loan info
     *
     * @dev emergency function in the event that loan data is deleted from NFTfi before 
     *      the vault can write the data to storage
     * @dev only callable by GoblinSax
     * @dev repaymentAmount must be repayment after NFTfi fees
     * @dev loans input must be ordered the same as loans as 'incomplete' — chronologically
     * @dev requires loan data for all loans in 'incomplete' — not just data deleted from NFTfi
     *
     * @param loans                         array of missing loan data 
    */
    // function forceCompleteLoanInfo(Loan[] memory loans) external {
    //     if (msg.sender != goblinsax) revert Vault_NotAdmin();

    //     IncompleteLoan[] memory _incomplete = incomplete_loans;
    //     uint length = _incomplete.length;

    //     if (loans.length != length) revert Vault_UnmatchingLoanData();

    //     uint principalSum;

    //     Loan memory loan;

    //     //input complete loan info to history
    //     for (uint i; i < length; ) {
    //         loan = loans[i];

    //         if (loan.loan_id != _incomplete[i].loan_id) {
    //             revert Vault_UnmatchingLoanData();
    //         }

    //         principalSum += loan.principal;

    //         loan_history.push(loan);

    //         unchecked { ++i; }
    //     }

    //     internalBalances.virtualTreasury += principalSum;

    //     delete incomplete_loans;

    //     emit CompletedLoanInfo();
    // }
    
    /*//////////////////////////////////////////////////////////////
                          DEPOSIT / WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice deposits into vault from an account id
     *
     * @dev if 
     * @dev account id is the id of the vault's LP NFT
     * @dev if id is zero, the vault mints a new LP NFT to sender
     * @dev if vault is private, sender must be whitelisted to mint a new LP NFT
     *
     * @param account                       id of account
     * @param amount                        amount to deposit
    */
    function deposit(uint account, uint256 amount) external {
        // transfer deposit into vault
        asset.safeTransferFrom(msg.sender, address(this), amount);

        // if account id is 0
        if (account == 0) {
            // if private vault, require sender to be whitelisted before minting LP token
            if (private_vault) _assertWhitelist(msg.sender);

            // mint vault nft
            account = nft.mint(msg.sender);

            // set account exists to true
            exists[account] = true;

        // else if not account owner revert
        } else if (nft.ownerOf(account) != msg.sender) {
            revert Vault_NotAccountOwner();
        } 

        // initialize VaultAction with relevant info 
        VaultAction memory _deposit;
        _deposit.account = account;
        _deposit.amount = amount;
        _deposit.time = block.timestamp;
        _deposit.action = ActionType.deposit;

        // save to storage
        history.push(_deposit);

        // increase virtual treasury
        internalBalances.virtualTreasury += amount;

        emit Deposit(account, msg.sender, amount);
    }

    /**
     * @notice withdraws from an account id
     *
     * @dev requires 'incomplete_loans' storage variable being empty
     *      i.e. requires all loan data be complete 
     * @dev caulculates account balance with HistoryParser.calculateBalance
     * @dev if withdrawal is the full balance of the account, this burns their LP NFT
     *
     * @param account                       id of account
     * @param amount                        amount to withdraw
    */
    function withdraw(uint account, uint256 amount, address to) external {
        InternalBalances memory _internalBalances = internalBalances;

        uint actualVaultBalance = asset.balanceOf(address(this)) - _internalBalances.accumulatedFees;
        
        if (actualVaultBalance != _internalBalances.virtualTreasury) revert Vault_UnprocessedResolvedLoans();
        
        // require loan info be completed
        if (incomplete_loans.length > 0) revert Vault_IncompleteLoanInfo();

        // require account exists
        if (!exists[account]) revert Vault_NonexistentAccount();

        address account_owner = nft.ownerOf(account);

        if (msg.sender != account_owner) revert Vault_NotAccountOwner();

        bytes memory data = abi.encode(account, history, resolved_history);

        (
            uint balance, , ,
            uint num_contributions 
        ) = Parser.calculateBalance(data);
        
        // allow for full withdraw if amount to withdraw exceeds balance
        if (balance < amount) amount = balance;

        // initialize VaultAction with relevant info
        VaultAction memory withdrawal;
        withdrawal.account = account;
        withdrawal.amount = amount;
        withdrawal.treasury = actualVaultBalance; 
        withdrawal.time = block.timestamp;
        withdrawal.action = ActionType.withdraw;

        // save to history
        history.push(withdrawal);

        // subtract withdrawal from virtual treasury
        internalBalances.virtualTreasury -= amount;

        // if withdrawal is full balance w/ no outstanding loans, burn LP nft
        if(balance == amount && num_contributions == 0) {
            nft.burn(account);

            exists[account] = false;
        } 

        // distribute withdrawal
        asset.safeTransfer(to, amount);

        emit Withdraw(account, to, msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            BALANCE CHECK
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice returns balance of account without initiating a withdraw
     *
     * @dev used to show an account's balance on the front end
     *
     * @param account                       id of account
     *
     * @return balance                      balance of account
     * @return vault_balance                balance of vault
     * @return contributions                active loan contributions 
    */
    function calculateBalance(uint account) external view returns (uint, uint, Contribution[] memory) {
        // note: if there are loan w/ incomplete info, we can't accurately calculate an account's balance
        if (incomplete_loans.length > 0) revert Vault_IncompleteLoanInfo();

        bytes memory data = abi.encode(account, history, resolved_history);

        ( 
            uint balance, 
            uint vault_balance, 
            Contribution[] memory contributions, 
            uint num_contributions 
        ) = Parser.calculateBalance(data);

        // margin of empty contributions 
        // note: local arrays must have a static size, which can't be made larger
        //       in calculateBalance this array is initialized with a length of the total loans
        //       from the vault, which is the max contributions a user can have,
        //       however LP's will often have contributed to less, so there will be a margin in this array
        //       with empty indexes
        uint margin = contributions.length - num_contributions;

        // remove empty indexes from 'contributions'
        // note: while you can't safely make a local array larger, you can make it smaller
        assembly { mstore(contributions, sub(mload(contributions), margin)) }

        return (balance, vault_balance, contributions);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC721 RECEIVER
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice called on receiving an ERC-721
     * @notice if ERC-721 is PromissoryNote, adds the incomplete loan data to storage
     *
     * @dev at the time of this call, NFTfi's loan data isn't saved to their contract
     *      so we save the loan id to history + push an IncompleteLoan struct to 'incomplete'
     *
     * @param _id                           id of nft
     * @param data                          loan terms or id if sent from prmissoryNote
    */
    function onERC721Received(
        address, 
        address, 
        uint _id, 
        bytes calldata data
    ) external returns (bytes4) {
        // if sender is NFTfi
        if (msg.sender == address(nftfi.promissoryNote)) {
            /// review: not necessary with trusted NFTfi addresses (needless gas)
            if(nftfi.promissoryNote.ownerOf(_id) != address(this)) revert Vault_LoanDoesntExist();

            // decode NFTfi loan id
            uint32 loan_id = abi.decode(data, (uint32));
    
            InternalBalances memory _internalBalances = internalBalances;

            // save incomplete loan data
            incomplete_loans.push(loan_id);

            VaultAction memory loan;

            loan.loan_id = loan_id;
            loan.promissory_id = _id;
            loan.adminFee = manager.lendingParams().adminFee;
            loan.strategistFee = strategistFee;
            loan.strategist = strategist;
            loan.time = block.timestamp;
            loan.action = ActionType.loan;
            loan.platform = LoanType.nftfi;

            // note: treasuries are after loan and will be subtracted by principal (once we know it)
            //       to be before loan, so we can accurately calculate contributions
            // note: virtual vs treasury will be compared to determine if there are any unprocessed loan
            //       at this time, so that we can also subtract fees from treasury — or else we'd get a ghost contributor
            loan.treasury = asset.balanceOf(address(this)) - internalBalances.accumulatedFees;
            loan.virtualTreasury = _internalBalances.virtualTreasury;

            history.push(loan);
            
            emit NewLoan(loan_id);
        }

        return IERC721Receiver.onERC721Received.selector;
    }

    /*//////////////////////////////////////////////////////////////
                                GOBLINSAX
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice calculates & distributes fees from the interest of loan repayments
     *
     * @dev only callable by GoblinSax
    */
    function distributeFees() public {
        if (msg.sender != goblinsax) revert Vault_NotAdmin();

        LoanResolved[] memory _resolved = resolved_history;
        uint length = _resolved.length;

        uint i = feeNonce;

        LoanResolved memory resolved_loan;

        uint _adminFee;
        uint _strategistFee;

        // add fees from resolved loans
        while (i < length) {
            resolved_loan = _resolved[i];

            _adminFee += resolved_loan.adminFee;
            _strategistFee += resolved_loan.strategistFee;

            unchecked { ++i; }
        }  

        feeNonce = i;

        assert(_adminFee + _strategistFee == internalBalances.accumulatedFees);

        internalBalances.accumulatedFees = 0;

        // distribute fees
        asset.transfer(goblinsax, _adminFee);
        asset.transfer(strategist, _strategistFee);
    }

    /**
     * @notice opens private vault
     *
     * @dev only callable by GoblinSax
     * @dev removes soulbound from LP token
    */
    function openVault() external {
        if (msg.sender != goblinsax) revert Vault_NotAdmin();

        private_vault = false;

        nft.openVault();

        delete whitelist;
    }

    /**
     * @notice adds an address to whitelist
     *
     * @dev only callable by GoblinSax
     *
     * @param lp                           the address to whitelist
    */
    function addToWhitelist(address lp) external {
        if (msg.sender != goblinsax) revert Vault_NotAdmin();

        whitelist.push(lp);
    }

    /**
     * @notice sets a new fee structure
     *
     * @dev only callable by current strategist
     * @dev asserts new fee is within protocol params via VaultManger call
     * @dev changes the 'strategistFee' storage variable
     *
     * @param fee                           new strategist fee in BPS
    */
    function setFee(uint fee) external {
        if (msg.sender != strategist) revert Vault_NotStrategist();

        if (fee > manager.lendingParams().maxStrategistFee) revert Vault_InvalidFee();

        emit NewFee(fee);
    }

    /**
     * @notice sets a new admin
     *
     * @dev only callable by GoblinSax
     * @dev changes the 'goblinsax' storage variable
     *
     * @param _goblinsax                    address of new admin
    */
    function setAdmin(address _goblinsax) public {
        if (msg.sender != goblinsax) revert Vault_NotAdmin();

        goblinsax = _goblinsax;

        emit NewAdmin(_goblinsax);
    }

    /**
     * @notice sets a new strategist
     *
     * @dev only callable by GoblinSax and current strategist
     * @dev changes the 'strategist' storage variable
     *
     * @param _strategist                   address of new strategist
    */
    function setStrategist(address _strategist) external { 
        if (msg.sender != goblinsax) {
            revert Vault_NotAdmin();
        } else if (msg.sender != strategist) {
            revert Vault_NotStrategist();
        }

        strategist = _strategist;

        emit NewStrategist(_strategist);
    }


    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice iterates through whitelist and reverts if address isn't found
     *
     * @dev an array is used instead of a mapping to save gas on deployment
     *
     * @param user                          address of user
    */
    function _assertWhitelist(address user) internal view {
        address[] memory _whitelist = whitelist;
        uint length = _whitelist.length;


        for (uint i; i < length; ) {
            if (_whitelist[i] == user) {
                break;
            }

            unchecked { ++i; }
        
            if (i == length) revert Vault_NotWhitelisted();
        }

    }

    /**
     * @notice view ids owned by a user
     *
     * @param user                          address of user
     *
     * @return ids                          array of id's owned by sender          
    */
    function idsOwned(address user) external view returns (uint[] memory ids) {
        return nft.idsOwned(user);
    }

    function viewHistory() external view returns (VaultAction[] memory) {
        return history;
    }

    function viewResolvedLoans() external view returns (LoanResolved[] memory) {
        return resolved_history;
    }

    function viewIncompleteLoans() external view returns (uint[] memory incomplete) {
        return incomplete_loans;
    }

    function viewWhitelist() external view returns (address[] memory _whitelist) {
        return whitelist;
    }

    /*//////////////////////////////////////////////////////////////
                            VAULT SIGNATURE
    //////////////////////////////////////////////////////////////*/

    function isValidSignature(bytes32, bytes memory) public override pure returns (bytes4 magicValue) {

        // if (_hash.recover(_signature) == goblinsax) {
        //     return MAGICVALUE;
        // } else {
        //     return INVALID_SIGNATURE;
        // }

        // temp:
        return MAGICVALUE;

    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { Vault } from "../Vault.sol";

contract VaultFactory {


    function createVault(bytes calldata params) external returns(address) {
        Vault vault = new Vault(params);

        return address(vault);
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
pragma solidity ^0.8.4;

import { Contribution } from "../lib/GoblinVaultLib.sol";

interface IHistoryParser {
    function calculateBalance(bytes calldata data) external pure returns (
        uint balance, 
        uint vault_balance,
        Contribution[] memory,
        uint c_counter
    );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

interface IPromissoryNote {
    function ownerOf(uint id) external returns (address);

    function exists(uint id) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import { LendingParams } from "../lib/GoblinVaultLib.sol";

interface IVaultManager {
    function lendingParams() external view returns (LendingParams memory);

    function validateLoanTerms(
        address collection, 
        uint principal,
        uint duration
    ) external view returns (bool valid);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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