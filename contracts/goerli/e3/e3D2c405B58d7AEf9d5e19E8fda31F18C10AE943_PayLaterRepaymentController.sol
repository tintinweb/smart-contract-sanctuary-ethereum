// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// import "./libraries/PayLaterLoanLibrary.sol";
import "./interfaces/IPayLaterLoanCore.sol";
import "./interfaces/IPayLaterRepaymentController.sol";


contract PayLaterRepaymentController is IPayLaterRepaymentController {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IPayLaterLoanCore private loanCore;

    constructor(
        IPayLaterLoanCore _loanCore
    ) {
        loanCore = _loanCore;
    }

    /***
     * @inheritdoc IRepaymentController
     */
    function repay(uint256 loanId) external override {
        // get loan from borrower note

        require(loanId != 0, "PayLaterRepaymentController: repay could not dereference loan");

        PayLaterLoanLibrary.LoanTerms memory terms = loanCore.getLoan(loanId).terms;
        
        (uint256 installment,uint256 index) = loanCore.getInstallmentOfPayLaterPurchase(loanId);
        require(installment != 0, "PayLaterRepaymentController: No Pending Installments");

        IERC20(terms.payableCurrency).safeTransferFrom(msg.sender, address(this), installment);
        IERC20(terms.payableCurrency).approve(address(loanCore), installment);

        // call repay function in loan core
        loanCore.repay(loanId, installment, index);
    }

    /***
     * @inheritdoc IRepaymentController
     */
    function claim(uint256 loanId) external override {
        // make sure that caller owns lender note
        PayLaterLoanLibrary.LoanData memory data = loanCore.getLoan(loanId);

        
        require(data.lenderPrimaryWalletAddress == msg.sender, "PayLaterRepaymentController: not owner of lender note");

        // get loan from lender note
        require(loanId != 0, "PayLaterRepaymentController: claim could not dereference loan");

        // call claim function in loan core
        loanCore.claim(loanId);
    }

    function repayRental(uint256 loanId) external override {

        require(loanId != 0, "RentalRepaymentController: repay could not dereference loan");

        RentalLibrary.RentalTerms memory terms = loanCore.getRental(loanId).terms;

        (uint256 installment,uint256 index) = loanCore.getInstallmentOfRentalPurchase(loanId);
        require(installment != 0, "RentalRepaymentController: No Pending Installments");

        IERC20(terms.payableCurrency).safeTransferFrom(msg.sender, address(this), installment);
        IERC20(terms.payableCurrency).approve(address(loanCore), installment);

        // call repay function in loan core
        loanCore.repayRent(loanId, installment, index);

    }

    function claimRental(uint256 loanId) external override {
        // make sure that caller owns lender note
        RentalLibrary.RentalData memory data = loanCore.getRental(loanId);
        require(data.lenderPrimaryWalletAddress == msg.sender, "RentalRepaymentController: not owner");
        // get loan from lender note
        require(loanId != 0, "RentalRepaymentController: claim could not dereference loan");

        // call claim function in loan core
        loanCore.claimRentalAsset(loanId);
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

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity ^0.8.0;
import "../libraries/PayLaterLoanLibrary.sol";
import "../libraries/RentalLibrary.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPayLaterLoanCore {
    event FeesClaimed(address token, address to, uint256 amount);
    event LoanClaimed(uint256 loanId);
    event LoanRepaid(uint256 loanId);
    event LoanStarted(
        uint256 loanId,
        address lender,
        address borrower,
        address borrowerSecondary
    );
    // event Paused(address account);
    event RentRepaid(uint256 loanId);
    event RentalAssetClaimed(uint256 loanId);
    event RentalStarted(
        uint256 loanId,
        address lender,
        address borrower,
        address borrowerSecondary
    );
    // event RoleAdminChanged(
    //     bytes32 indexed role,
    //     bytes32 indexed previousAdminRole,
    //     bytes32 indexed newAdminRole
    // );
    // event RoleGranted(
    //     bytes32 indexed role,
    //     address indexed account,
    //     address indexed sender
    // );
    // event RoleRevoked(
    //     bytes32 indexed role,
    //     address indexed account,
    //     address indexed sender
    // );
    // event Unpaused(address account);
    event installmentRepaid(uint256 installment, uint256 loanId, uint256 index);
    event rentalInstallmentRepaid(
        uint256 installment,
        uint256 loanId,
        uint256 index
    );

    // function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    // function FEE_CLAIMER_ROLE() external view returns (bytes32);

    // function ORIGINATOR_ROLE() external view returns (bytes32);

    // function REPAYER_ROLE() external view returns (bytes32);

    function checkForNFTsPayLaterLoan(address assetAddress, uint256 token_id)
        external
        view
        returns (bool);

    function claim(uint256 loanId) external;

    function claimFees(IERC20 token) external;

    function claimRentalAsset(uint256 loanId) external;

    function createPayLaterPurchase(
        PayLaterLoanLibrary.LoanTerms memory loanTerms,
        address borrowerPrimaryAddress,
        address borrowerSecondaryAddress,
        address lenderPrimaryAddress,
        uint256 tokenType,
        address tokenAddress
    ) external returns (uint256 payLaterLoanId);

    function createRentalRequest(
        RentalLibrary.RentalTerms memory rentalTerms,
        address borrowerPrimaryAddress,
        address borrowerSecondaryAddress,
        address lenderPrimaryAddress,
        uint256 tokenType,
        address tokenAddress,
        uint256 rentalType
    ) external returns (uint256 rentalLoanId);

    // function feeController() external view returns (address);

    function getFirstInstallmentOfPayLaterPurchase(uint256 loanId)
        external
        view
        returns (uint256);

    function getFirstInstallmentOfRentalPurchase(uint256 loanId)
        external
        view
        returns (uint256);

    function getFirstInstallmentWithoutLoan(
        uint256 amount,
        uint256 parts,
        uint256 interest
    ) external view returns (uint256);

    function getFirstRentalInstallmentWithoutLoan(uint256 amount, uint256 parts)
        external
        view
        returns (uint256);

    function getInstallmentOfPayLaterPurchase(uint256 loanId)
        external
        view
        returns (uint256, uint256);

    function getInstallmentOfRentalPurchase(uint256 loanId)
        external
        view
        returns (uint256, uint256);

    function getLoan(uint256 loanId)
        external
        view
        returns (PayLaterLoanLibrary.LoanData memory loanData);

    function getRental(uint256 loanId)
        external
        view
        returns (RentalLibrary.RentalData memory loanData);

    // function getRoleAdmin(bytes32 role) external view returns (bytes32);

    // function grantRole(bytes32 role, address account) external;

    // function hasRole(bytes32 role, address account)
    //     external
    //     view
    //     returns (bool);

    // function pause() external;

    // function paused() external view returns (bool);

    // function renounceRole(bytes32 role, address account) external;

    function repay(
        uint256 loanId,
        uint256 installmentAmount,
        uint256 index
    ) external returns (bool);

    function repayRent(
        uint256 loanId,
        uint256 installmentAmount,
        uint256 index
    ) external returns (bool);

    // function revokeRole(bytes32 role, address account) external;

    function startPayLaterPurchase(uint256 loanId) external;

    function startRentalPurchase(uint256 loanId) external;

    function checkForNFTsUnderRental(address assetAddress, uint256 token_id) external view returns (bool);

    // function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // function unpause() external;
}

// interface PayLaterLoanLibrary {
//     struct LoanTerms {
//         uint256 durationSecs;
//         uint256 principal;
//         uint256 interest;
//         uint256 collateralTokenId;
//         address payableCurrency;
//         uint256 parts;
//         uint256 partduration;
//     }

//     struct LoanData {
//         address borrowerPrimaryWalletAddress;
//         address borrowerSecondaryWalletAddress;
//         address lenderPrimaryWalletAddress;
//         LoanTerms terms;
//         uint8 state;
//         uint256 dueDate;
//         address assetAddress;
//         uint256 tokenType;
//     }
// }

// interface RentalLibrary {
//     struct RentalTerms {
//         uint256 durationSecs;
//         uint256 principal;
//         uint256 collateralTokenId;
//         address payableCurrency;
//         uint256 parts;
//         uint256 partduration;
//     }

//     struct RentalData {
//         address borrowerPrimaryWalletAddress;
//         address borrowerSecondaryWalletAddress;
//         address lenderPrimaryWalletAddress;
//         RentalTerms terms;
//         uint8 state;
//         uint256 dueDate;
//         address assetAddress;
//         uint256 tokenType;
//         uint256 rentalType;
//     }
// }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPayLaterRepaymentController {
    /**
     * @dev used to repay a currently active loan.
     *
     * The loan must be in the Active state, and the
     * payableCurrency must be approved for withdrawal by the
     * repayment controller. This call will withdraw tokens
     * from the caller's wallet.
     *
     */
    function repay(uint256 loanId) external;

    /**
     * @dev used to repay a currently active loan that is past due.
     *
     * The loan must be in the Active state, and the caller must
     * be the holder of the lender note.
     */
    function claim(uint256 loanId) external;

    function repayRental(uint256 loanId) external;

    function claimRental(uint256 loanId) external;

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

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.7.0 <0.9.0;

library PayLaterLoanLibrary {
    /**
     * @dev Enum describing the current state of a loan
     * State change flow:
     *  Created -> Active -> Repaid
     *                    -> Defaulted
     */
    enum LoanState {
        // We need a default that is not 'Created' - this is the zero value
        DUMMY_DO_NOT_USE,
        // The loan data is stored, but not initiated yet.
        Created,
        // The loan has been initialized, NFT have been delivered to the borrower.
        Active,
        // The loan has been repaid, and the NFT has been returned to the borrower. This is a terminal state.
        Repaid,
        // The loan was delinquent and collateral claimed by the lender. This is a terminal state.
        Defaulted
    }

    /**
     * @dev The raw terms of a loan
     */
    struct LoanTerms {
        // The number of seconds representing relative due date of the loan
        uint256 durationSecs;
        // The amount of principal in terms of the payableCurrency
        uint256 principal;
        // The amount of interest in terms of the payableCurrency
        uint256 interest;
        // The tokenID of the collateral bundle
        uint256 collateralTokenId;
        // The payable currency for the loan principal and interest
        address payableCurrency;
        // The number parts in the payment cycle
        uint256 parts;
        // The part duration in seconds
        uint256 partduration;

    }

    /**
     * @dev The data of a loan. This is stored once the loan is Active
     */
    struct LoanData {
        // The primary wallet address of the borrower
        address borrowerPrimaryWalletAddress;
        // The Deefy wallet (secondary) address of the borrower
        address borrowerSecondaryWalletAddress;
        // The primary wallet address of the lender
        address lenderPrimaryWalletAddress;
        // The raw terms of the loan
        LoanTerms terms;
        // The current state of the loan
        LoanState state;
        // Timestamp representing absolute due date date of the loan
        uint256 dueDate;
        // The Asset address
        address assetAddress;
        // token type 0 - 721, 1 - 1155
        uint256 tokenType;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.7.0 <0.9.0;

library RentalLibrary {
    /**
     * @dev Enum describing the current state of a loan
     * State change flow:
     *  Created -> Active -> Repaid
     *                    -> Defaulted
     */
    enum LoanState {
        // We need a default that is not 'Created' - this is the zero value
        DUMMY_DO_NOT_USE,
        // The loan data is stored, but not initiated yet.
        Created,
        // The loan has been initialized, NFT have been delivered to the borrower.
        Active,
        // The loan has been repaid, and the NFT has been returned to the borrower. This is a terminal state.
        Repaid,
        // The loan was delinquent and collateral claimed by the lender. This is a terminal state.
        Defaulted
    }

    /**
     * @dev The raw terms of a loan
     */
    struct RentalTerms {
        // The number of seconds representing relative due date of the loan
        uint256 durationSecs;
        // The amount of principal in terms of the payableCurrency
        uint256 principal;
        // The tokenID of the collateral bundle
        uint256 collateralTokenId;
        // The payable currency for the loan principal and interest
        address payableCurrency;
        // The number parts in the payment cycle
        uint256 parts;
        // The part duration in seconds
        uint256 partduration;

    }

    /**
     * @dev The data of a loan. This is stored once the loan is Active
     */
    struct RentalData {
        // The primary wallet address of the borrower
        address borrowerPrimaryWalletAddress;
        // The Deefy wallet (secondary) address of the borrower
        address borrowerSecondaryWalletAddress;
        // The primary wallet address of the lender
        address lenderPrimaryWalletAddress;
        // The raw terms of the loan
        RentalTerms terms;
        // The current state of the loan
        LoanState state;
        // Timestamp representing absolute due date date of the loan
        uint256 dueDate;
        // The Asset address
        address assetAddress;
        // token type 0 - 721, 1 - 1155
        uint256 tokenType;
        // rental type 0 - direct payment 1 - part payment
        uint256 rentalType;
    }
}