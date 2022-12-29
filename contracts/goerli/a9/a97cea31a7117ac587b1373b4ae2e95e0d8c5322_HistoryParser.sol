// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {
    VaultAction,
    LoanResolved,
    IncompleteLoan,
    HistoryHolder,
    Contribution,
    ActionType
} from "./lib/GoblinVaultLib.sol";

import { SafeDecimalMath } from "synthetix/SafeDecimalMath.sol";

contract HistoryParser {
    using SafeDecimalMath for uint;

    /**
     * @notice iterates through history of vault to cacluate the balance of an account
     *
     * @param data                          encoded account id, history, and resolved history
     *
     * @return balance                      balance of account
     * @return vault_balance                balance of vault
     * @return Contribution                 array of active loan contributions
     * @return c_counter                    number of active loan contributions
    */
    function calculateBalance(bytes calldata data) external pure returns (
        uint balance, 
        uint vault_balance,
        Contribution[] memory,
        uint c_counter
    ) {
        // note: HistoryHolder used to avoid stack too deep errors, for too many local vars
        HistoryHolder memory history;

        // account id
        uint account;

        // initialize account and all vault history
        (account, history.v_history, history.r_history) = abi.decode(data, (
            uint256,
            VaultAction[],
            LoanResolved[]
        ));

        // note: storing lengths before a loop saves noticable gas
        history.v_length = history.v_history.length;

        // get time of first repayment or a large number if no repayments
        history.next_repayment = history.r_history.length > 0 ? history.r_history[0].time : type(uint256).max;

        // holder of account contributions to loan (used when calculating repayments)
        // note: the size of memory arrays must be defined — this sets the size to the total loans from vault
        //       we will often be using a subset of this array, the length of which is 'c_counter'
        history.contributions = new Contribution[](history.v_length);

        // iterate through despoit / withdraw / loans history
        for(uint i; i < history.v_length; ++i ) {
            if (history.v_history[i].action == ActionType.deposit) {
                vault_balance += history.v_history[i].amount;

                if (history.v_history[i].account == account) balance += history.v_history[i].amount;

            } else if (history.v_history[i].action == ActionType.withdraw) {

                // if next repayment occured before or at time of withdraw
                if (history.v_history[i].time >= history.next_repayment) {
                    (
                        history, 
                        balance, 
                        vault_balance
                    ) = _calculateRepayments(
                        history,
                        vault_balance,
                        history.v_history[i].treasury,
                        balance, 
                        history.v_history[i].time
                    );
                }

                vault_balance -= history.v_history[i].amount;

                if (history.v_history[i].account == account) balance -= history.v_history[i].amount;

            } else if (history.v_history[i].action == ActionType.loan) {
                // calculate repayments before or at time of new loan
                // note: repayments change an account balance (meaning their contribution to a new loan) 
                //       and change the vault balance (which is how we calculate an account's contribution to a new loan) 
                //       so it's necessary to calculate relevant resolved loans before any new loan
                if (history.v_history[i].time >= history.next_repayment) {
                    (
                        history, 
                        balance, 
                        vault_balance
                    ) = _calculateRepayments(
                        history,
                        vault_balance,
                        history.v_history[i].treasury,
                        balance, 
                        history.v_history[i].time
                    );
                }

                // calculate account contribution to new loan
                history.contribution = balance.divideDecimalRoundPrecise(
                    vault_balance.divideDecimalRoundPrecise(history.v_history[i].principal)
                );

                if (history.contribution > 0) {
                    balance -= history.contribution;

                    // add to 'contributions' at index of c_counter
                    history.contributions[history.c_counter] = Contribution({
                        loan_id : history.v_history[i].loan_id,
                        contribution : history.contribution,
                        platform : history.v_history[i].platform
                    });

                    unchecked { ++history.c_counter; }
                }

                // reduce principal from balance
                vault_balance -= history.v_history[i].principal;
            }
        }
        
        // calculate remaining repayments
        ( history , balance, vault_balance ) = _calculateRepayments(
            history, 
            vault_balance, 
            type(uint256).max, // is typically used to order resolved action on the same timestamp as history
                               // setting this at max will allow the function to count all repayments while keeping
                               // the if statements minimal
            balance, 
            type(uint256).max // represents time to calculate repayments to 
        );

        return (balance, vault_balance, history.contributions, history.c_counter);
    }


    function _calculateRepayments(
        HistoryHolder memory history,
        uint vault_balance,
        uint treasury_before_action,
        uint account_balance,
        uint max_time
    ) internal pure returns(
        HistoryHolder memory,  // updated history
        uint,                  // updated account balance 
        uint                   // updated vault balance
    ) {
        LoanResolved memory resolved;

        uint r_length = history.r_history.length;

        // iterate through repayments
        // todo: go over how calculating repayments before/after (>=/> respectively) this affects same-timestamp bug
        //       in the event the repayment was really made after/before, respectively
        while (history.r_idx < r_length) {
            resolved = history.r_history[history.r_idx];

            // if resolved loan is before or the same time as 'max_time'
            if (max_time >= resolved.time) {
                // if treasury_before_action is higher than what we calculated, it happened first
                // so we'll process the repayment
                if (treasury_before_action > vault_balance) {
                    vault_balance += resolved.amount;

                    // go through an account's contribution to see if loan resolution adds to their balance
                    for (uint c; c < history.c_counter; ) {
                        // note: repayments don't necessarily happen in the same order as loans and since, we're
                        //       limited with how we can store data in memory, we have to loop through 'contributions' to find
                        //       data on loan 
                        if (resolved.loan_id == history.contributions[c].loan_id && history.contributions[c].platform == resolved.platform) {
                            account_balance += history.contributions[c].contribution.multiplyDecimalRoundPrecise(
                                resolved.amount.divideDecimalRoundPrecise(resolved.principal)
                            );

                            // remove loan from 'contributions'
                            // note: c_counter can never be zero here, so unchecked is safe
                            // note: this moves the item at the end of our array subset to the current index 
                            //       (leaving us w/ 2 copys of loan) and reduces the length of the array subset
                            //       the next contribution will be stored at the second copy, overwriting it
                            unchecked { history.contributions[c] = history.contributions[--history.c_counter]; }

                            break;
                        }

                        unchecked { ++c; }
                    }

                    unchecked { ++history.r_idx; }
                // if the repayment happened after on a different
                } else {
                    break;
                }
            // if next resolved loan is after 'max_time'
            } else {
                break;
            }
        }
        
        // set 'next_repayment' to the time of next repayment if any
        if (history.r_idx < r_length) {
            history.next_repayment = history.r_history[history.r_idx].time;

            // else set next_repayment to a very high number
        } else {
            history.next_repayment = type(uint256).max;
        }

        return (history, account_balance, vault_balance);
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

pragma solidity ^0.8.13;

// Libraries
import "openzeppelin/utils/math/SafeMath.sol";

// https://docs.synthetix.io/contracts/source/libraries/safedecimalmath
library SafeDecimalMath {
    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10**uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10**uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10**uint(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint x, uint y) internal pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint x, uint y) internal pure returns (uint) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint x,
        uint y,
        uint precisionUnit
    ) private pure returns (uint) {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint x, uint y) internal pure returns (uint) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i) internal pure returns (uint) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i) internal pure returns (uint) {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    // Computes `a - b`, setting the value to 0 if b > a.
    function floorsub(uint a, uint b) internal pure returns (uint) {
        return b >= a ? 0 : a - b;
    }

    /* ---------- Utilities ---------- */
    /*
     * Absolute value of the input, returned as a signed number.
     */
    function signedAbs(int x) internal pure returns (int) {
        return x < 0 ? -x : x;
    }

    /*
     * Absolute value of the input, returned as an unsigned number.
     */
    function abs(int x) internal pure returns (uint) {
        return uint(signedAbs(x));
    }
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