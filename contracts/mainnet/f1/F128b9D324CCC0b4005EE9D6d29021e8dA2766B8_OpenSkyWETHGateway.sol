// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../dependencies/weth/IWETH.sol';
import '../interfaces/IOpenSkyWETHGateway.sol';
import '../interfaces/IOpenSkySettings.sol';
import '../interfaces/IOpenSkyPool.sol';
import '../interfaces/IOpenSkyOToken.sol';
import '../libraries/helpers/Errors.sol';

contract OpenSkyWETHGateway is IOpenSkyWETHGateway, Ownable, ERC721Holder {
    using SafeERC20 for IERC20;

    IWETH public immutable WETH;
    IOpenSkySettings public immutable SETTINGS;

    /**
     * @dev Sets the WETH address and the OpenSkySettings address.
     * @param weth Address of the Wrapped Ether contract
     **/
    constructor(IWETH weth, IOpenSkySettings settings) {
        WETH = weth;
        SETTINGS = settings;
    }

    /**
     * @notice Infinite weth approves OpenSkyPool contract.
     * @dev Only callable by the owner
     **/
    function authorizeLendingPoolWETH() external override onlyOwner {
        address lendingPool = SETTINGS.poolAddress();
        require(WETH.approve(lendingPool, type(uint256).max),Errors.APPROVAL_FAILED);
        emit AuthorizeLendingPoolWETH(_msgSender());
    }

    /**
     * @notice Infinite NFT approves OpenSkyPool contract.
     * @dev Only callable by the owner
     * @param nftAssets addresses of nft assets
     **/
    function authorizeLendingPoolNFT(address[] calldata nftAssets) external override onlyOwner {
        address lendingPool = SETTINGS.poolAddress();
        for (uint256 i = 0; i < nftAssets.length; i++) {
            IERC721(nftAssets[i]).setApprovalForAll(lendingPool, true);
        }
        emit AuthorizeLendingPoolNFT(_msgSender(), nftAssets);
    }

    /**
     * @dev deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying asset (aTokens)
     * is minted.
     * @param reserveId address of the targeted underlying lending pool
     * @param onBehalfOf address of the user who will receive the aTokens representing the deposit
     * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
     **/
    function deposit(
        uint256 reserveId,
        address onBehalfOf,
        uint16 referralCode
    ) external payable override {
        WETH.deposit{value: msg.value}();
        IOpenSkyPool(SETTINGS.poolAddress()).deposit(reserveId, msg.value, onBehalfOf, referralCode);

        emit Deposit(reserveId, onBehalfOf, msg.value);
    }

    /**
     * @dev withdraws the WETH _reserves of msg.sender.
     * @param reserveId address of the targeted underlying lending pool
     * @param amount amount of aWETH to withdraw and receive native ETH
     * @param onBehalfOf address of the user who will receive native ETH
     */
    function withdraw(
        uint256 reserveId,
        uint256 amount,
        address onBehalfOf
    ) external override {
        IOpenSkyPool lendingPool = IOpenSkyPool(SETTINGS.poolAddress());
        IERC20 oWETH = IERC20(lendingPool.getReserveData(reserveId).oTokenAddress);
        uint256 userBalance = oWETH.balanceOf(msg.sender);
        uint256 amountToWithdraw = amount;

        // if amount is equal to uint256 max, the user wants to redeem everything
        if (amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }
        oWETH.safeTransferFrom(msg.sender, address(this), amountToWithdraw);
        lendingPool.withdraw(reserveId, amountToWithdraw, address(this));
        WETH.withdraw(amountToWithdraw);
        _safeTransferETH(onBehalfOf, amountToWithdraw);

        emit Withdraw(reserveId, onBehalfOf, amountToWithdraw);
    }

    /**
     * @dev Borrows ETH from reserve using an NFT as collateral and will receive a loan NFT as receipt.
     * @param reserveId The ID of the reserve
     * @param amount amount of ETH user will borrow
     * @param duration The desired duration of the loan
     * @param nftAddress The collateral NFT address
     * @param tokenId The ID of the NFT
     * @param onBehalfOf address of the user who will receive ETH and loan NFT.
     */
    function borrow(
        uint256 reserveId,
        uint256 amount,
        uint256 duration,
        address nftAddress,
        uint256 tokenId,
        address onBehalfOf
    ) external override {
        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        IOpenSkyPool lendingPool = IOpenSkyPool(SETTINGS.poolAddress());
        uint256 loanId = lendingPool.borrow(reserveId, amount, duration, nftAddress, tokenId, onBehalfOf);
        WETH.withdraw(amount);
        _safeTransferETH(onBehalfOf, amount);

        emit Borrow(reserveId, onBehalfOf, loanId);
    }

    /**
     * @dev repays a borrow on the WETH reserve, for the specified amount (or for the whole amount, if uint256(-1) is specified).
     * @param loanId the id of reserve
     */
    function repay(uint256 loanId) external payable override {
        WETH.deposit{value: msg.value}();

        IOpenSkyPool lendingPool = IOpenSkyPool(SETTINGS.poolAddress());
        uint256 repayAmount = lendingPool.repay(loanId);

        require(msg.value >= repayAmount, Errors.REPAY_MSG_VALUE_ERROR);

        // refund remaining dust eth
        if (msg.value > repayAmount) {
            uint256 refundAmount = msg.value - repayAmount;
            WETH.withdraw(refundAmount);
            _safeTransferETH(msg.sender, refundAmount);
        }
        emit Repay(loanId);
    }

    function extend(
        uint256 loanId,
        uint256 amount,
        uint256 duration
    ) external payable {
        WETH.deposit{value: msg.value}();

        IOpenSkyPool lendingPool = IOpenSkyPool(SETTINGS.poolAddress());
        (uint256 inAmount, uint256 outAmount) = lendingPool.extend(loanId, amount, duration, _msgSender());

        require(msg.value >= inAmount, Errors.EXTEND_MSG_VALUE_ERROR);

        // refund eth
        uint256 refundAmount;
        if (msg.value > inAmount) {
            refundAmount += msg.value - inAmount;
        }
        if (outAmount > 0) {
            refundAmount += outAmount;
        }
        if (refundAmount > 0) {
            WETH.withdraw(refundAmount);
            _safeTransferETH(msg.sender, refundAmount);
        }

        emit Extend(loanId);
    }

    /**
     * @dev transfer ETH to an address, revert if it fails.
     * @param to recipient of the transfer
     * @param value the amount to send
     */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, Errors.ETH_TRANSFER_FAILED);
    }

    /**
     * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
     * direct transfers to the contract address.
     * @param token token to transfer
     * @param to recipient of the transfer
     * @param amount amount to send
     */
    function emergencyTokenTransfer(
        address token,
        address to,
        uint256 amount
    ) external override onlyOwner {
        IERC20(token).safeTransfer(to, amount);
        emit EmergencyTokenTransfer(_msgSender(), token, to, amount);
    }

    /**
     * @dev transfer native Ether from the utility contract, for native Ether recovery in case of stuck Ether
     * due selfdestructs or transfer ether to pre-computed contract address before deployment.
     * @param to recipient of the transfer
     * @param amount amount to send
     */
    function emergencyEtherTransfer(address to, uint256 amount) external override onlyOwner {
        _safeTransferETH(to, amount);
        emit EmergencyEtherTransfer(_msgSender(), to, amount);
    }

    /**
     * @dev Only WETH contract is allowed to transfer ETH here. Prevent other addresses to send Ether to this contract.
     */
    receive() external payable {
        require(msg.sender == address(WETH), Errors.RECEIVE_NOT_ALLOWED);
        emit Received(msg.sender, msg.value);
    }

    /**
     * @dev Revert fallback calls
     */
    fallback() external payable {
        revert(Errors.FALLBACK_NOT_ALLOWED);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

pragma solidity 0.8.10;

interface IWETH {
    function balanceOf(address) external view returns (uint256);

    function deposit() external payable;

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IOpenSkyWETHGateway {
    event AuthorizeLendingPoolWETH(address indexed operator);
    event AuthorizeLendingPoolNFT(address indexed operator, address[] nftAssets);
    event EmergencyTokenTransfer(address indexed operator, address indexed token, address indexed to, uint256 amount);
    event EmergencyEtherTransfer(address indexed operator, address indexed to, uint256 amount);

    event Deposit(uint256 indexed reserveId, address indexed onBehalfOf, uint256 amount);
    event Withdraw(uint256 indexed reserveId, address indexed onBehalfOf, uint256 amount);
    event Borrow(uint256 indexed reserveId, address indexed onBehalfOf, uint256 indexed loanId);
    event Repay(uint256 indexed loanId);
    event Extend(uint256 indexed loanId);

    event Received(address, uint256);

    function authorizeLendingPoolWETH() external;

    function authorizeLendingPoolNFT(address[] calldata nftAssets) external;

    function deposit(
        uint256 reserveId,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdraw(
        uint256 reserveId,
        uint256 amount,
        address onBehalfOf
    ) external;

    function borrow(
        uint256 reserveId,
        uint256 amount,
        uint256 duration,
        address nftAddress,
        uint256 tokenId,
        address onBehalfOf
    ) external;

    function repay(uint256 loanId) external payable;

    function extend(
        uint256 loanId,
        uint256 amount,
        uint256 duration
    ) external payable;

    function emergencyTokenTransfer(
        address token,
        address to,
        uint256 amount
    ) external;

    function emergencyEtherTransfer(address to, uint256 amount) external;
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

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IOpenSkyOToken is IERC20 {
    event Mint(address indexed account, uint256 amount, uint256 index);
    event Burn(address indexed account, uint256 amount, uint256 index);
    event MintToTreasury(address treasury, uint256 amount, uint256 index);
    event Deposit(uint256 amount);
    event Withdraw(uint256 amount);

    function mint(
        address account,
        uint256 amount,
        uint256 index
    ) external;

    function burn(
        address account,
        uint256 amount,
        uint256 index
    ) external;

    function mintToTreasury(uint256 amount, uint256 index) external;

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount, address to) external;

    function scaledBalanceOf(address account) external view returns (uint256);

    function principleBalanceOf(address account) external view returns (uint256);

    function scaledTotalSupply() external view returns (uint256);

    function principleTotalSupply() external view returns (uint256);

    function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

    function claimERC20Rewards(address token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Errors {
    // common
    string public constant MATH_MULTIPLICATION_OVERFLOW = '100';
    string public constant MATH_ADDITION_OVERFLOW = '101';
    string public constant MATH_DIVISION_BY_ZERO = '102';

    string public constant ETH_TRANSFER_FAILED = '110';
    string public constant RECEIVE_NOT_ALLOWED = '111';
    string public constant FALLBACK_NOT_ALLOWED = '112';
    string public constant APPROVAL_FAILED = '113';

    // setting/factor
    string public constant SETTING_ZERO_ADDRESS_NOT_ALLOWED = '115';
    string public constant SETTING_RESERVE_FACTOR_NOT_ALLOWED = '116';
    string public constant SETTING_WHITELIST_INVALID_RESERVE_ID = '117';
    string public constant SETTING_WHITELIST_NFT_ADDRESS_IS_ZERO = '118';
    string public constant SETTING_WHITELIST_NFT_DURATION_OUT_OF_ORDER = '119';
    string public constant SETTING_WHITELIST_NFT_NAME_EMPTY = '120';
    string public constant SETTING_WHITELIST_NFT_SYMBOL_EMPTY = '121';
    string public constant SETTING_WHITELIST_NFT_LTV_NOT_ALLOWED = '122';

    // settings/acl
    string public constant ACL_ONLY_GOVERNANCE_CAN_CALL = '200';
    string public constant ACL_ONLY_EMERGENCY_ADMIN_CAN_CALL = '201';
    string public constant ACL_ONLY_POOL_ADMIN_CAN_CALL = '202';
    string public constant ACL_ONLY_LIQUIDATOR_CAN_CALL = '203';
    string public constant ACL_ONLY_AIRDROP_OPERATOR_CAN_CALL = '204';
    string public constant ACL_ONLY_POOL_CAN_CALL = '205';

    // lending & borrowing
    // reserve
    string public constant RESERVE_DOES_NOT_EXIST = '300';
    string public constant RESERVE_LIQUIDITY_INSUFFICIENT = '301';
    string public constant RESERVE_INDEX_OVERFLOW = '302';
    string public constant RESERVE_SWITCH_MONEY_MARKET_STATE_ERROR = '303';
    string public constant RESERVE_TREASURY_FACTOR_NOT_ALLOWED = '304';
    string public constant RESERVE_TOKEN_CAN_NOT_BE_CLAIMED = '305';

    // token
    string public constant AMOUNT_SCALED_IS_ZERO = '310';
    string public constant AMOUNT_TRANSFER_OVERFLOW = '311';

    //deposit
    string public constant DEPOSIT_AMOUNT_SHOULD_BE_BIGGER_THAN_ZERO = '320';

    // withdraw
    string public constant WITHDRAW_AMOUNT_NOT_ALLOWED = '321';
    string public constant WITHDRAW_LIQUIDITY_NOT_SUFFICIENT = '322';

    // borrow
    string public constant BORROW_DURATION_NOT_ALLOWED = '330';
    string public constant BORROW_AMOUNT_EXCEED_BORROW_LIMIT = '331';
    string public constant NFT_ADDRESS_IS_NOT_IN_WHITELIST = '332';

    // repay
    string public constant REPAY_STATUS_ERROR = '333';
    string public constant REPAY_MSG_VALUE_ERROR = '334';

    // extend
    string public constant EXTEND_STATUS_ERROR = '335';
    string public constant EXTEND_MSG_VALUE_ERROR = '336';

    // liquidate
    string public constant START_LIQUIDATION_STATUS_ERROR = '360';
    string public constant END_LIQUIDATION_STATUS_ERROR = '361';
    string public constant END_LIQUIDATION_AMOUNT_ERROR = '362';

    // loan
    string public constant LOAN_DOES_NOT_EXIST = '400';
    string public constant LOAN_SET_STATUS_ERROR = '401';
    string public constant LOAN_REPAYER_IS_NOT_OWNER = '402';
    string public constant LOAN_LIQUIDATING_STATUS_CAN_NOT_BE_UPDATED = '403';
    string public constant LOAN_CALLER_IS_NOT_OWNER = '404';
    string public constant LOAN_COLLATERAL_NFT_CAN_NOT_BE_CLAIMED = '405';

    string public constant FLASHCLAIM_EXECUTOR_ERROR = '410';
    string public constant FLASHCLAIM_STATUS_ERROR = '411';

    // money market
    string public constant MONEY_MARKET_DEPOSIT_AMOUNT_NOT_ALLOWED = '500';
    string public constant MONEY_MARKET_WITHDRAW_AMOUNT_NOT_ALLOWED = '501';
    string public constant MONEY_MARKET_APPROVAL_FAILED = '502';
    string public constant MONEY_MARKET_DELEGATE_CALL_ERROR = '503';
    string public constant MONEY_MARKET_REQUIRE_DELEGATE_CALL = '504';
    string public constant MONEY_MARKET_WITHDRAW_AMOUNT_NOT_MATCH = '505';

    // price oracle
    string public constant PRICE_ORACLE_HAS_NO_PRICE_FEED = '600';
    string public constant PRICE_ORACLE_INCORRECT_TIMESTAMP = '601';
    string public constant PRICE_ORACLE_PARAMS_ERROR = '602';
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