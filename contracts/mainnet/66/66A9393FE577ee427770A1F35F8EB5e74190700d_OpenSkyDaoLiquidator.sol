// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/Context.sol';

import '../interfaces/IOpenSkySettings.sol';
import '../interfaces/IOpenSkyLoan.sol';
import '../interfaces/IOpenSkyPool.sol';
import '../interfaces/IACLManager.sol';
import '../interfaces/IOpenSkyDaoLiquidator.sol';
import '../libraries/types/DataTypes.sol';

contract OpenSkyDaoLiquidator is Context, ERC721Holder, IOpenSkyDaoLiquidator {
    using SafeERC20 for IERC20;
    IOpenSkySettings public immutable SETTINGS;

    modifier onlyLiquidationOperator() {
        IACLManager ACLManager = IACLManager(SETTINGS.ACLManagerAddress());
        require(ACLManager.isLiquidationOperator(_msgSender()), 'LIQUIDATION_ONLY_OPERATOR_CAN_CALL');
        _;
    }

    constructor(address settings) {
        SETTINGS = IOpenSkySettings(settings);
    }

    function startLiquidate(uint256 loanId) external override onlyLiquidationOperator {
        IOpenSkyLoan loanNFT = IOpenSkyLoan(SETTINGS.loanAddress());
        DataTypes.LoanData memory loanData = loanNFT.getLoanData(loanId);

        IOpenSkyPool pool = IOpenSkyPool(SETTINGS.poolAddress());
        pool.startLiquidation(loanId);

        uint256 borrowBalance = loanNFT.getBorrowBalance(loanId);

        // withdraw erc20 token from dao vault
        IERC20 token = IERC20(pool.getReserveData(loanData.reserveId).underlyingAsset);
        token.safeTransferFrom(SETTINGS.daoVaultAddress(), address(this), borrowBalance);
        token.safeApprove(address(pool), borrowBalance);

        pool.endLiquidation(loanId, borrowBalance);

        // transfer NFT to dao vault
        IERC721(loanData.nftAddress).safeTransferFrom(address(this), SETTINGS.daoVaultAddress(), loanData.tokenId);

        emit Liquidate(loanId, loanData.nftAddress, loanData.tokenId, _msgSender());
    }

    function withdrawERC721ToDaoVault(address token, uint256 tokenId) external onlyLiquidationOperator {
        IERC721(token).safeTransferFrom(address(this), SETTINGS.daoVaultAddress(), tokenId);
        emit WithdrawERC721(token, tokenId, SETTINGS.daoVaultAddress());
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

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
pragma solidity 0.8.10;
import '../libraries/types/DataTypes.sol';

interface IOpenSkySettings {
    event InitPoolAddress(address operator, address address_);
    event InitLoanAddress(address operator, address address_);
    event InitVaultFactoryAddress(address operator, address address_);
    event InitIncentiveControllerAddress(address operator, address address_);
    event InitWETHGatewayAddress(address operator, address address_);
    event InitPunkGatewayAddress(address operator, address address_);
    event InitDaoVaultAddress(address operator, address address_);

    event AddToWhitelist(address operator, uint256 reserveId, address nft);
    event RemoveFromWhitelist(address operator, uint256 reserveId, address nft);
    event SetReserveFactor(address operator, uint256 factor);
    event SetPrepaymentFeeFactor(address operator, uint256 factor);
    event SetOverdueLoanFeeFactor(address operator, uint256 factor);
    event SetMoneyMarketAddress(address operator, address address_);
    event SetTreasuryAddress(address operator, address address_);
    event SetACLManagerAddress(address operator, address address_);
    event SetLoanDescriptorAddress(address operator, address address_);
    event SetNftPriceOracleAddress(address operator, address address_);
    event SetInterestRateStrategyAddress(address operator, address address_);
    event AddLiquidator(address operator, address address_);
    event RemoveLiquidator(address operator, address address_);

    function poolAddress() external view returns (address);

    function loanAddress() external view returns (address);

    function vaultFactoryAddress() external view returns (address);

    function incentiveControllerAddress() external view returns (address);

    function wethGatewayAddress() external view returns (address);

    function punkGatewayAddress() external view returns (address);

    function inWhitelist(uint256 reserveId, address nft) external view returns (bool);

    function getWhitelistDetail(uint256 reserveId, address nft) external view returns (DataTypes.WhitelistInfo memory);

    function reserveFactor() external view returns (uint256); // treasury ratio

    function MAX_RESERVE_FACTOR() external view returns (uint256);

    function prepaymentFeeFactor() external view returns (uint256);

    function overdueLoanFeeFactor() external view returns (uint256);

    function moneyMarketAddress() external view returns (address);

    function treasuryAddress() external view returns (address);

    function daoVaultAddress() external view returns (address);

    function ACLManagerAddress() external view returns (address);

    function loanDescriptorAddress() external view returns (address);

    function nftPriceOracleAddress() external view returns (address);

    function interestRateStrategyAddress() external view returns (address);
    
    function isLiquidator(address liquidator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '../libraries/types/DataTypes.sol';

/**
 * @title IOpenSkyLoan
 * @author OpenSky Labs
 * @notice Defines the basic interface for OpenSkyLoan.  This loan NFT is composable and can be used in other DeFi protocols 
 **/
interface IOpenSkyLoan is IERC721 {

    /**
     * @dev Emitted on mint()
     * @param tokenId The ID of the loan
     * @param recipient The address that will receive the loan NFT
     **/
    event Mint(uint256 indexed tokenId, address indexed recipient);

    /**
     * @dev Emitted on end()
     * @param tokenId The ID of the loan
     * @param onBehalfOf The address the repayer is repaying for
     * @param repayer The address of the user initiating the repayment()
     **/
    event End(uint256 indexed tokenId, address indexed onBehalfOf, address indexed repayer);

    /**
     * @dev Emitted on startLiquidation()
     * @param tokenId The ID of the loan
     * @param liquidator The address of the liquidator
     **/
    event StartLiquidation(uint256 indexed tokenId, address indexed liquidator);

    /**
     * @dev Emitted on endLiquidation()
     * @param tokenId The ID of the loan
     * @param liquidator The address of the liquidator
     **/
    event EndLiquidation(uint256 indexed tokenId, address indexed liquidator);

    /**
     * @dev Emitted on updateStatus()
     * @param tokenId The ID of the loan
     * @param status The status of loan
     **/
    event UpdateStatus(uint256 indexed tokenId, DataTypes.LoanStatus indexed status);

    /**
     * @dev Emitted on flashClaim()
     * @param receiver The address of the flash loan receiver contract
     * @param sender The address that will receive tokens
     * @param nftAddress The address of the collateralized NFT
     * @param tokenId The ID of collateralized NFT
     **/
    event FlashClaim(address indexed receiver, address sender, address indexed nftAddress, uint256 indexed tokenId);

    /**
     * @dev Emitted on claimERC20Airdrop()
     * @param token The address of the ERC20 token
     * @param to The address that will receive the ERC20 tokens
     * @param amount The amount of the tokens
     **/
    event ClaimERC20Airdrop(address indexed token, address indexed to, uint256 amount);

    /**
     * @dev Emitted on claimERC721Airdrop()
     * @param token The address of ERC721 token
     * @param to The address that will receive the eRC721 tokens
     * @param ids The ID of the token
     **/
    event ClaimERC721Airdrop(address indexed token, address indexed to, uint256[] ids);

    /**
     * @dev Emitted on claimERC1155Airdrop()
     * @param token The address of the ERC1155 token
     * @param to The address that will receive the ERC1155 tokens
     * @param ids The ID of the token
     * @param amounts The amount of the tokens
     * @param data packed params to pass to the receiver as extra information
     **/
    event ClaimERC1155Airdrop(address indexed token, address indexed to, uint256[] ids, uint256[] amounts, bytes data);

    /**
     * @notice Mints a loan NFT to user
     * @param reserveId The ID of the reserve
     * @param borrower The address of the borrower
     * @param nftAddress The contract address of the collateralized NFT 
     * @param nftTokenId The ID of the collateralized NFT
     * @param amount The amount of the loan
     * @param duration The duration of the loan
     * @param borrowRate The borrow rate of the loan
     * @return loanId and loan data
     **/
    function mint(
        uint256 reserveId,
        address borrower,
        address nftAddress,
        uint256 nftTokenId,
        uint256 amount,
        uint256 duration,
        uint256 borrowRate
    ) external returns (uint256 loanId, DataTypes.LoanData memory loan);

    /**
     * @notice Starts liquidation of the loan in default
     * @param tokenId The ID of the defaulted loan
     **/
    function startLiquidation(uint256 tokenId) external;

    /**
     * @notice Ends liquidation of a loan that is fully settled
     * @param tokenId The ID of the loan
     **/
    function endLiquidation(uint256 tokenId) external;

    /**
     * @notice Terminates the loan
     * @param tokenId The ID of the loan
     * @param onBehalfOf The address the repayer is repaying for
     * @param repayer The address of the repayer
     **/
    function end(uint256 tokenId, address onBehalfOf, address repayer) external;
    
    /**
     * @notice Returns the loan data
     * @param tokenId The ID of the loan
     * @return The details of the loan
     **/
    function getLoanData(uint256 tokenId) external view returns (DataTypes.LoanData calldata);

    /**
     * @notice Returns the status of a loan
     * @param tokenId The ID of the loan
     * @return The status of the loan
     **/
    function getStatus(uint256 tokenId) external view returns (DataTypes.LoanStatus);

    /**
     * @notice Returns the borrow interest of the loan
     * @param tokenId The ID of the loan
     * @return The borrow interest of the loan
     **/
    function getBorrowInterest(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the borrow balance of a loan, including borrow interest
     * @param tokenId The ID of the loan
     * @return The borrow balance of the loan
     **/
    function getBorrowBalance(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the penalty fee of the loan
     * @param tokenId The ID of the loan
     * @return The penalty fee of the loan
     **/
    function getPenalty(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the ID of the loan
     * @param nftAddress The address of the collateralized NFT
     * @param tokenId The ID of the collateralized NFT
     * @return The ID of the loan
     **/
    function getLoanId(address nftAddress, uint256 tokenId) external view returns (uint256);

    /**
     * @notice Allows smart contracts to access the collateralized NFT within one transaction,
     * as long as the amount taken plus a fee is returned
     * @dev IMPORTANT There are security concerns for developers of flash loan receiver contracts that must be carefully considered
     * @param receiverAddress The address of the contract receiving the funds, implementing IOpenSkyFlashClaimReceiver interface
     * @param loanIds The ID of loan being flash-borrowed
     * @param params packed params to pass to the receiver as extra information
     **/
    function flashClaim(
        address receiverAddress,
        uint256[] calldata loanIds,
        bytes calldata params
    ) external;

    /**
     * @notice Claim the ERC20 token which has been airdropped to the loan contract
     * @param token The address of the airdropped token
     * @param to The address which will receive ERC20 token
     * @param amount The amount of the ERC20 token
     **/
    function claimERC20Airdrop(
        address token,
        address to,
        uint256 amount
    ) external;

    /**
     * @notice Claim the ERC721 token which has been airdropped to the loan contract
     * @param token The address of the airdropped token
     * @param to The address which will receive the ERC721 token
     * @param ids The ID of the ERC721 token
     **/
    function claimERC721Airdrop(
        address token,
        address to,
        uint256[] calldata ids
    ) external;

    /**
     * @notice Claim the ERC1155 token which has been airdropped to the loan contract
     * @param token The address of the airdropped token
     * @param to The address which will receive the ERC1155 tokens
     * @param ids The ID of the ERC1155 token
     * @param amounts The amount of the ERC1155 tokens
     * @param data packed params to pass to the receiver as extra information
     **/
    function claimERC1155Airdrop(
        address token,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '../libraries/types/DataTypes.sol';

/**
 * @title IOpenSkyPool
 * @author OpenSky Labs
 * @notice Defines the basic interface for an OpenSky Pool.
 **/

interface IOpenSkyPool {
    /*
     * @dev Emitted on create()
     * @param reserveId The ID of the reserve
     * @param underlyingAsset The address of the underlying asset
     * @param oTokenAddress The address of the oToken
     * @param name The name to use for oToken
     * @param symbol The symbol to use for oToken
     * @param decimals The decimals of the oToken
     */
    event Create(
        uint256 indexed reserveId,
        address indexed underlyingAsset,
        address indexed oTokenAddress,
        string name,
        string symbol,
        uint8 decimals
    );

    /*
     * @dev Emitted on setTreasuryFactor()
     * @param reserveId The ID of the reserve
     * @param factor The new treasury factor of the reserve
     */
    event SetTreasuryFactor(uint256 indexed reserveId, uint256 factor);

    /*
     * @dev Emitted on setInterestModelAddress()
     * @param reserveId The ID of the reserve
     * @param interestModelAddress The address of the interest model contract
     */
    event SetInterestModelAddress(uint256 indexed reserveId, address interestModelAddress);

    /*
     * @dev Emitted on openMoneyMarket()
     * @param reserveId The ID of the reserve
     */
    event OpenMoneyMarket(uint256 reserveId);

    /*
     * @dev Emitted on closeMoneyMarket()
     * @param reserveId The ID of the reserve
     */
    event CloseMoneyMarket(uint256 reserveId);

    /*
     * @dev Emitted on deposit()
     * @param reserveId The ID of the reserve
     * @param onBehalfOf The address that will receive the oTokens
     * @param amount The amount of ETH to be deposited
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards
     * 0 if the action is executed directly by the user, without any intermediaries
     */
    event Deposit(uint256 indexed reserveId, address indexed onBehalfOf, uint256 amount, uint256 referralCode);

    /*
     * @dev Emitted on withdraw()
     * @param reserveId The ID of the reserve
     * @param onBehalfOf The address that will receive assets withdrawed
     * @param amount The amount to be withdrawn
     */
    event Withdraw(uint256 indexed reserveId, address indexed onBehalfOf, uint256 amount);

    /*
     * @dev Emitted on borrow()
     * @param reserveId The ID of the reserve
     * @param user The address initiating the withdrawal(), owner of oTokens
     * @param onBehalfOf The address that will receive the ETH and the loan NFT
     * @param loanId The loan ID
     */
    event Borrow(
        uint256 indexed reserveId,
        address user,
        address indexed onBehalfOf,
        uint256 indexed loanId
    );

    /*
     * @dev Emitted on repay()
     * @param reserveId The ID of the reserve
     * @param repayer The address initiating the repayment()
     * @param onBehalfOf The address that will receive the pledged NFT
     * @param loanId The ID of the loan
     * @param repayAmount The borrow balance of the loan when it was repaid
     * @param penalty The penalty of the loan for either early or overdue repayment
     */
    event Repay(
        uint256 indexed reserveId,
        address repayer,
        address indexed onBehalfOf,
        uint256 indexed loanId,
        uint256 repayAmount,
        uint256 penalty
    );

    /*
     * @dev Emitted on extend()
     * @param reserveId The ID of the reserve
     * @param onBehalfOf The owner address of loan NFT
     * @param oldLoanId The ID of the old loan
     * @param newLoanId The ID of the new loan
     */
    event Extend(uint256 indexed reserveId, address indexed onBehalfOf, uint256 oldLoanId, uint256 newLoanId);

    /*
     * @dev Emitted on startLiquidation()
     * @param reserveId The ID of the reserve
     * @param loanId The ID of the loan
     * @param nftAddress The address of the NFT used as collateral
     * @param tokenId The ID of the NFT used as collateral
     * @param operator The address initiating startLiquidation()
     */
    event StartLiquidation(
        uint256 indexed reserveId,
        uint256 indexed loanId,
        address indexed nftAddress,
        uint256 tokenId,
        address operator
    );

    /*
     * @dev Emitted on endLiquidation()
     * @param reserveId The ID of the reserve
     * @param loanId The ID of the loan
     * @param nftAddress The address of the NFT used as collateral
     * @param tokenId The ID of the NFT used as collateral
     * @param operator
     * @param repayAmount The amount used to repay, must be equal to or greater than the borrowBalance, excess part will be shared by all the lenders
     * @param borrowBalance The borrow balance of the loan
     */
    event EndLiquidation(
        uint256 indexed reserveId,
        uint256 indexed loanId,
        address indexed nftAddress,
        uint256 tokenId,
        address operator,
        uint256 repayAmount,
        uint256 borrowBalance
    );

    /**
     * @notice Creates a reserve
     * @dev Only callable by the pool admin role
     * @param underlyingAsset The address of the underlying asset
     * @param name The name of the oToken
     * @param symbol The symbol for the oToken
     * @param decimals The decimals of the oToken
     **/
    function create(
        address underlyingAsset,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external;

    /**
     * @notice Updates the treasury factor of a reserve
     * @dev Only callable by the pool admin role
     * @param reserveId The ID of the reserve
     * @param factor The new treasury factor of the reserve
     **/
    function setTreasuryFactor(uint256 reserveId, uint256 factor) external;

    /**
     * @notice Updates the interest model address of a reserve
     * @dev Only callable by the pool admin role
     * @param reserveId The ID of the reserve
     * @param interestModelAddress The new address of the interest model contract
     **/
    function setInterestModelAddress(uint256 reserveId, address interestModelAddress) external;

    /**
     * @notice Open the money market
     * @dev Only callable by the emergency admin role
     * @param reserveId The ID of the reserve
     **/
    function openMoneyMarket(uint256 reserveId) external;

    /**
     * @notice Close the money market
     * @dev Only callable by the emergency admin role
     * @param reserveId The ID of the reserve
     **/
    function closeMoneyMarket(uint256 reserveId) external;

    /**
     * @dev Deposits ETH into the reserve.
     * @param reserveId The ID of the reserve
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards
     **/
    function deposit(uint256 reserveId, uint256 amount, address onBehalfOf, uint256 referralCode) external;

    /**
     * @dev withdraws the ETH from reserve.
     * @param reserveId The ID of the reserve
     * @param amount amount of oETH to withdraw and receive native ETH
     **/
    function withdraw(uint256 reserveId, uint256 amount, address onBehalfOf) external;

    /**
     * @dev Borrows ETH from reserve using an NFT as collateral and will receive a loan NFT as receipt.
     * @param reserveId The ID of the reserve
     * @param amount amount of ETH user will borrow
     * @param duration The desired duration of the loan
     * @param nftAddress The collateral NFT address
     * @param tokenId The ID of the NFT
     * @param onBehalfOf address of the user who will receive ETH and loan NFT.
     **/
    function borrow(
        uint256 reserveId,
        uint256 amount,
        uint256 duration,
        address nftAddress,
        uint256 tokenId,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Repays a loan, as a result the corresponding loan NFT owner will receive the collateralized NFT.
     * @param loanId The ID of the loan the user will repay
     */
    function repay(uint256 loanId) external returns (uint256);

    /**
     * @dev Extends creates a new loan and terminates the old loan.
     * @param loanId The loan ID to extend
     * @param amount The amount of ERC20 token the user will borrow in the new loan
     * @param duration The selected duration the user will borrow in the new loan
     * @param onBehalfOf The address will borrow in the new loan
     **/
    function extend(
        uint256 loanId,
        uint256 amount,
        uint256 duration,
        address onBehalfOf
    ) external returns (uint256, uint256);

    /**
     * @dev Starts liquidation for a loan when it's in LIQUIDATABLE status
     * @param loanId The ID of the loan which will be liquidated
     */
    function startLiquidation(uint256 loanId) external;

    /**
     * @dev Completes liquidation for a loan which will be repaid.
     * @param loanId The ID of the liquidated loan that will be repaid.
     * @param amount The amount of the token that will be repaid.
     */
    function endLiquidation(uint256 loanId, uint256 amount) external;

    /**
     * @dev Returns the state of the reserve
     * @param reserveId The ID of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(uint256 reserveId) external view returns (DataTypes.ReserveData memory);

    /**
     * @dev Returns the normalized income of the reserve
     * @param reserveId The ID of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(uint256 reserveId) external view returns (uint256);

    /**
     * @dev Returns the remaining liquidity of the reserve
     * @param reserveId The ID of the reserve
     * @return The reserve's withdrawable balance
     */
    function getAvailableLiquidity(uint256 reserveId) external view returns (uint256);

    /**
     * @dev Returns the instantaneous borrow limit value of a special NFT
     * @param nftAddress The address of the NFT
     * @param tokenId The ID of the NFT
     * @return The NFT's borrow limit
     */
    function getBorrowLimitByOracle(
        uint256 reserveId,
        address nftAddress,
        uint256 tokenId
    ) external view returns (uint256);

    /**
     * @dev Returns the sum of all users borrow balances include borrow interest accrued
     * @param reserveId The ID of the reserve
     * @return The total borrow balance of the reserve
     */
    function getTotalBorrowBalance(uint256 reserveId) external view returns (uint256);

    /**
     * @dev Returns TVL (total value locked) of the reserve.
     * @param reserveId The ID of the reserve
     * @return The reserve's TVL
     */
    function getTVL(uint256 reserveId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IACLManager {
    function addEmergencyAdmin(address admin) external;
    
    function isEmergencyAdmin(address admin) external view returns (bool);
    
    function removeEmergencyAdmin(address admin) external;
    
    function addGovernance(address admin) external;
    
    function isGovernance(address admin) external view returns (bool);

    function removeGovernance(address admin) external;

    function addPoolAdmin(address admin) external;

    function isPoolAdmin(address admin) external view returns (bool);

    function removePoolAdmin(address admin) external;

    function addLiquidationOperator(address address_) external;

    function isLiquidationOperator(address address_) external view returns (bool);

    function removeLiquidationOperator(address address_) external;

    function addAirdropOperator(address address_) external;

    function isAirdropOperator(address address_) external view returns (bool);

    function removeAirdropOperator(address address_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IOpenSkyDaoLiquidator {
    event Liquidate(uint256 indexed loanId, address indexed nftAddress, uint256 tokenId, address operator);
    event WithdrawERC721(address indexed token, uint256 tokenId, address indexed to);

    function startLiquidate(uint256 loanId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library DataTypes {
    struct ReserveData {
        uint256 reserveId;
        address underlyingAsset;
        address oTokenAddress;
        address moneyMarketAddress;
        uint128 lastSupplyIndex;
        uint256 borrowingInterestPerSecond;
        uint256 lastMoneyMarketBalance;
        uint40 lastUpdateTimestamp;
        uint256 totalBorrows;
        address interestModelAddress;
        uint256 treasuryFactor;
        bool isMoneyMarketOn;
    }

    struct LoanData {
        uint256 reserveId;
        address nftAddress;
        uint256 tokenId;
        address borrower;
        uint256 amount;
        uint128 borrowRate;
        uint128 interestPerSecond;
        uint40 borrowBegin;
        uint40 borrowDuration;
        uint40 borrowOverdueTime;
        uint40 liquidatableTime;
        uint40 extendableTime;
        uint40 borrowEnd;
        LoanStatus status;
    }

    enum LoanStatus {
        NONE,
        BORROWING,
        EXTENDABLE,
        OVERDUE,
        LIQUIDATABLE,
        LIQUIDATING
    }

    struct WhitelistInfo {
        bool enabled;
        string name;
        string symbol;
        uint256 LTV;
        uint256 minBorrowDuration;
        uint256 maxBorrowDuration;
        uint256 extendableDuration;
        uint256 overdueDuration;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

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