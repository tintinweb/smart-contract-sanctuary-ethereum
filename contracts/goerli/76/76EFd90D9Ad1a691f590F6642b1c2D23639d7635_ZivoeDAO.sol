// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "./OpenZeppelin/Ownable.sol";

import { SafeERC20 } from "./OpenZeppelin/SafeERC20.sol";
import { IERC20 } from "./OpenZeppelin/IERC20.sol";
import { IERC104, IERC721, IERC1155, IZivoeGlobals } from "./interfaces/InterfacesAggregated.sol";
import { ERC1155Holder } from "./OpenZeppelin/ERC1155Holder.sol";
import { ERC721Holder } from "./OpenZeppelin/ERC721Holder.sol";

/// @dev    This contract escrows unused or unallocated capital.
///         This contract has the following responsibilities:
///          - Deployment and redemption of capital:
///             (a) Pushing assets to a locker.
///             (b) Pulling assets from a locker.
///           - Enforces a whitelist of lockers through which pushing and pulling capital can occur.
///           - This whitelist is modifiable.
///         To be determined:
///          - How governance would be used to enforce actions.
contract ZivoeDAO is ERC1155Holder, ERC721Holder, Ownable {
    
    using SafeERC20 for IERC20;

    // ---------------------
    //    State Variables
    // ---------------------

    address public immutable GBL;                       /// The ZivoeGlobals contract.

    mapping(address => bool) public lockerWhitelist;    /// The whitelist for lockers.


    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the ZivoeDAO.sol contract.
    /// @param _GBL The ZivoeGlobals contract.
    constructor(address _GBL) {
        GBL = _GBL;
    }



    // ------------
    //    Events
    // ------------

    /// @notice Emitted during modifyLockerWhitelist().
    /// @param  locker  The locker whose status on lockerWhitelist() mapping is updated.
    /// @param  allowed The boolean value to assign.
    event ModifyLockerWhitelist(address locker, bool allowed);

    /// @notice Emitted during push().
    /// @param  locker The locker receiving "asset".
    /// @param  asset The asset being pushed.
    /// @param  amount The amount of "asset" being pushed.
    event Pushed(address indexed locker, address asset, uint256 amount);

    /// @notice Emitted during pull().
    /// @param  locker The locker "asset" is pulled from.
    /// @param  asset The asset being pulled.
    event Pulled(address indexed locker, address asset);

    /// @notice Emitted during pullPartial().
    /// @param  locker The locker "asset" is pulled from.
    /// @param  asset The asset being pulled.
    /// @param  amount The amount of "asset" being pulled.
    event PulledPartial(address indexed locker, address asset, uint256 amount);

    /// @notice Emitted during pushMulti().
    /// @param  locker The locker receiving "assets".
    /// @param  assets The assets being pushed, corresponds to "amounts" by position in array.
    /// @param  amounts The amounts of "assets" being pushed, corresponds to "assets" by position in array.
    event PushedMulti(address locker, address[] assets, uint256[] amounts);

    /// @notice Emitted during pullMulti().
    /// @param  locker The locker "assets" are pulled from.
    /// @param  assets The assets being pulled.
    event PulledMulti(address locker, address[] assets);

    /// @notice Emitted during pullMultiPartial().
    /// @param  locker The locker "assets" are pulled from.
    /// @param  assets The assets being pulled, corresponds to "amounts" by position in array.
    /// @param  amounts The amounts of "assets" being pulled, corresponds to "assets" by position in array.
    event PulledMultiPartial(address locker, address[] assets, uint256[] amounts);

    // ----------------
    //    Functions
    // ----------------

    /// @notice Modifies the lockerWhitelist.
    /// @dev    Only callable by ZVL.
    /// @param  locker  The locker to update.
    /// @param  allowed The value to assign (true = permitted, false = prohibited).
    function modifyLockerWhitelist(address locker, bool allowed) external {
        require(_msgSender() == IZivoeGlobals(GBL).ZVL(), "ZivoeDAO::modifyLockerWhitelist() _msgSender() != IZivoeGlobals(GBL).ZVL()");
        emit ModifyLockerWhitelist(locker, allowed);
        lockerWhitelist[locker] = allowed;
    }

    /// @notice Migrates capital from DAO to locker.
    /// @dev    Only callable by Admin.
    /// @param  locker  The locker to push capital to.
    /// @param  asset   The asset to push to locker.
    /// @param  amount  The amount of "asset" to push.
    function push(address locker, address asset, uint256 amount) external onlyOwner {
        require(lockerWhitelist[locker], "ZivoeDAO::push() !lockerWhitelist[locker]");
        require(IERC104(locker).canPush(), "ZivoeDAO::push() !IERC104(locker).canPush()");
        emit Pushed(locker, asset, amount);
        IERC20(asset).safeApprove(locker, amount);
        IERC104(locker).pushToLocker(asset, amount);
    }

    /// @notice Pulls capital from locker to DAO.
    /// @dev    Only callable by Admin.
    /// @param  locker The locker to pull from.
    /// @param  asset The asset to pull.
    function pull(address locker, address asset) external onlyOwner {
        require(IERC104(locker).canPull(), "ZivoeDAO::pull() !IERC104(locker).canPull()");
        emit Pulled(locker, asset);
        IERC104(locker).pullFromLocker(asset);
    }

    /// @notice Pulls capital from locker to DAO.
    /// @dev    Only callable by Admin.
    /// @dev    The input "amount" might represent a ratio, BIPS, or an absolute amount depending on OCY.
    /// @param  locker The locker to pull from.
    /// @param  asset The asset to pull.
    /// @param  amount The amount to pull (may not refer to "asset", but rather a different asset within the OCY).
    function pullPartial(address locker, address asset, uint256 amount) external onlyOwner {
        require(IERC104(locker).canPullPartial(), "ZivoeDAO::pullPartial() !IERC104(locker).canPullPartial()");
        emit PulledPartial(locker, asset, amount);
        IERC104(locker).pullFromLockerPartial(asset, amount);
    }

    /// @notice Migrates multiple types of capital from DAO to locker.
    /// @dev    Only callable by Admin.
    /// @param  locker  The locker to push capital to.
    /// @param  assets  The assets to push to locker.
    /// @param  amounts The amount of "asset" to push.
    function pushMulti(address locker, address[] calldata assets, uint256[] calldata amounts) external onlyOwner {
        require(lockerWhitelist[locker], "ZivoeDAO::pushMulti() !lockerWhitelist[locker]");
        require(assets.length == amounts.length, "ZivoeDAO::pushMulti() assets.length != amounts.length");
        require(IERC104(locker).canPushMulti(), "ZivoeDAO::pushMulti() !IERC104(locker).canPushMulti()");
        emit PushedMulti(locker, assets, amounts);
        for (uint i = 0; i < assets.length; i++) {
            IERC20(assets[i]).safeApprove(locker, amounts[i]);
        }
        IERC104(locker).pushToLockerMulti(assets, amounts);
    }

    /// @notice Pulls capital from locker to DAO.
    /// @dev    Only callable by Admin.
    /// @param  locker The locker to pull from.
    /// @param  assets The assets to pull.
    function pullMulti(address locker, address[] calldata assets) external onlyOwner {
        require(IERC104(locker).canPullMulti(), "ZivoeDAO::pullMulti() !IERC104(locker).canPullMulti()");
        emit PulledMulti(locker, assets);
        IERC104(locker).pullFromLockerMulti(assets);
    }

    /// @notice Pulls capital from locker to DAO.
    /// @dev    Only callable by Admin.
    /// @param  locker The locker to pull from.
    /// @param  assets The asset to pull.
    /// @param  amounts The amounts to pull (may not refer to "assets", but rather a different asset within the OCY).
    function pullMultiPartial(address locker, address[] calldata assets, uint256[] calldata amounts) external onlyOwner {
        require(IERC104(locker).canPullMultiPartial(), "ZivoeDAO::pullMultiPartial() !IERC104(locker).canPullMultiPartial()");
        emit PulledMultiPartial(locker, assets, amounts);
        IERC104(locker).pullFromLockerMultiPartial(assets, amounts);
    }

    /// @notice Migrates an NFT from the DAO to a locker.
    /// @dev    Only callable by Admin.
    /// @param  locker  The locker to push an NFT to.
    /// @param  asset The NFT contract.
    /// @param  tokenId The NFT ID to push.
    function pushERC721(address locker, address asset, uint tokenId, bytes calldata data) external onlyOwner {
        require(lockerWhitelist[locker], "ZivoeDAO::pushERC721() !lockerWhitelist[locker]");
        require(IERC104(locker).canPushERC721(), "ZivoeDAO::pushERC721() !IERC104(locker).canPushERC721()");
        IERC721(asset).approve(locker, tokenId);
        IERC104(locker).pushToLockerERC721(asset, tokenId, data);
    }

    /// @notice Pulls capital from locker to DAO.
    /// @dev    Only callable by Admin.
    /// @param  locker The locker to pull from.
    /// @param  asset The NFT contract.
    /// @param  tokenId The NFT ID to pull.
    function pullERC721(address locker, address asset, uint tokenId, bytes calldata data) external onlyOwner {
        require(IERC104(locker).canPullERC721(), "ZivoeDAO::pullERC721() !IERC104(locker).canPullERC721()");
        IERC104(locker).pullFromLockerERC721(asset, tokenId, data);
    }

    // TODO: Unit testing for ERC-721 push/pull + ERC-1155 push/pull + event logs + natSpec

    /// @notice Migrates capital from DAO to locker.
    /// @dev    Only callable by Admin.
    /// @param  locker  The locker to push capital to.
    /// @param  asset   The asset to push to locker.
    /// @param  ids  The ids of "assets" to push.
    /// @param  amounts  The amounts of "assets" to push.
    /// @param data Any misc. string data to pass through.
    function pushERC1155Batch(
            address locker,
            address asset,
            uint256[] calldata ids, 
            uint256[] calldata amounts,
            bytes calldata data
    ) external onlyOwner {
        require(lockerWhitelist[locker], "ZivoeDAO::pushERC1155Batch() !lockerWhitelist[locker]");
        require(IERC104(locker).canPushERC1155(), "ZivoeDAO::pushERC1155Batch() !IERC104(locker).canPushERC1155()");
        IERC1155(asset).setApprovalForAll(locker, true);
        IERC104(locker).pushToLockerERC1155(asset, ids, amounts, data);
    }

    /// @notice Pulls capital from locker to DAO.
    /// @dev    Only callable by Admin.
    /// @param  locker The locker to pull from.
    /// @param  asset The asset to pull.
    function pullERC1155Batch(
            address locker,
            address asset,
            uint256[] calldata ids, 
            uint256[] calldata amounts,
            bytes calldata data
    ) external onlyOwner {
        require(IERC104(locker).canPullERC1155(), "ZivoeDAO::pullERC1155Batch() !IERC104(locker).canPullERC1155()");
        IERC104(locker).pullFromLockerERC1155(asset, ids, amounts, data);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./draft-IERC20Permit.sol";
import "./Address.sol";

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import { IERC20 } from "../OpenZeppelin/IERC20.sol";
import { IERC20Metadata } from "../OpenZeppelin/IERC20Metadata.sol";

interface IERC20Mintable is IERC20, IERC20Metadata {
    function mint(address account, uint256 amount) external;
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;
    function approve(address to, uint256 tokenId) external;
}

interface IERC1155 {
    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

interface IZivoeRewards {
    function depositReward(address _rewardsToken, uint256 reward) external;
}

interface IZivoeYDL {
    function forwardAssets() external;
    function passThrough(address asset, uint256 amount, address location) external;
    function passToTranchies(address asset, uint256 _yield) external;
}

interface IZivoeRET {
    function linkYDL(address asset, address to) external;
    function decreaseAmplification(address account, uint256 amount) external;
}

interface IZivoeGlobals {
    function DAO() external view returns (address);
    function ITO() external view returns (address);
    function RET() external view returns (address);
    function stJTT() external view returns (address);
    function stSTT() external view returns (address);
    function stZVE() external view returns (address);
    function TLC() external view returns (address);
    function vestZVE() external view returns (address);
    function YDL() external view returns (address);
    function zJTT() external view returns (address);
    function zSTT() external view returns (address);
    function ZVE() external view returns (address);
    function ZVL() external view returns (address);
    function isKeeper(address) external view returns (bool);
    function maxTrancheRatioBPS() external view returns (uint256);
    function minZVEPerJTTMint() external view returns (uint256);
    function maxZVEPerJTTMint() external view returns (uint256);
    function lowerRatioIncentive() external view returns (uint256);
    function upperRatioIncentive() external view returns (uint256);
}

interface IWETH {
    function deposit() external payable;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

interface IZivoeITO {
    function amountWithdrawableSeniorBurn(address asset) external returns (uint256 amt);
    function claim() external returns (uint256 _zJTT, uint256 _zSTT, uint256 _ZVE);
    function end() external view returns (uint256);
}

interface ICRVDeployer {
    function deploy_metapool(
        address _bp, 
        string calldata _name, 
        string calldata _symbol, 
        address _coin, 
        uint256 _A, 
        uint256 _fee
    ) external returns (address);
}

struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface ISushiFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
     function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(
        uint amountIn, 
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IUniswapQuoterV3 {
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external view returns (uint256 amountOut);
}

interface IUniswapRouterV3 {
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

// https://etherscan.io/address/0x2F9EC37d6CcFFf1caB21733BdaDEdE11c823cCB0#code
interface IBancorNetwork {
     function conversionPath(
         IERC20 _sourceToken, 
         IERC20 _targetToken
    ) external view returns (address[] memory);
    function convert(
        address[] memory path,
        uint256 sourceAmount,
        uint256 minReturn
    ) external payable returns (uint256);
    function convertByPath(
        address[] memory path,
        uint256 sourceAmount,
        uint256 minReturn,
        address payable beneficiary,
        address affiliate,
        uint256 affiliateFee
    ) external payable returns (uint256);
    function rateByPath(
        address[] memory path, 
        uint256 sourceAmount
    ) external view returns (uint256);
}

// https://etherscan.io/address/0x8301ae4fc9c624d1d396cbdaa1ed877821d7c511#code (ETH/CRV)
// https://etherscan.io/address/0xDC24316b9AE028F1497c275EB9192a3Ea0f67022#code (ETH/stETH)
interface ICRVMetaPool {
    // i = token_from
    // j = token_to
    // dx = token_from_change
    // min_dy = token_to_min_receive
    function coins(uint256 i) external view returns (address);
    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256); 
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function add_liquidity(uint256[2] memory amounts_in, uint256 min_mint_amount) external payable returns (uint256);
    function remove_liquidity(uint256 amount, uint256[2] memory min_amounts_out) external returns (uint256[2] memory);
    function remove_liquidity_one_coin(uint256 token_amount, int128 index, uint min_amount) external;
    function lp_token() external view returns (address);
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
}

// https://etherscan.io/address/0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2#code (FRAX/USDC)
interface ICRVPlainPoolFBP {
    function coins(uint256 i) external view returns (address);
    function add_liquidity(uint256[2] memory amounts_in, uint256 min_mint_amount) external returns (uint256);
    function remove_liquidity(uint256 amount, uint256[2] memory min_amounts_out) external returns (uint256[2] memory);
    function remove_liquidity_one_coin(uint256 token_amount, int128 index, uint min_amount) external;
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
}

// https://etherscan.io/address/0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2#code (FRAX/USDC)
interface ICRVPlainPool3CRV {
    function coins(uint256 i) external view returns (address);
    function add_liquidity(uint256[3] memory amounts_in, uint256 min_mint_amount) external;
    function remove_liquidity(uint256 amount, uint256[3] memory min_amounts_out) external;
    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256); 
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external returns (uint256); 
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy, bool use_eth) external returns (uint256);
    function exchange_underlying(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
}

interface ICRV {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external payable; 
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy, bool use_eth) external payable;
}

interface ICRV_PP_128_NP {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
}
interface ICRV_PP_256_NP {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy, bool use_eth) external;
    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);
}
interface ICRV_PP_256_P {
    function exchange_underlying(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external payable returns (uint256);
    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);
}
interface ICRV_MP_256 {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable returns (uint256);
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable returns (uint256);
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
}

interface ICRVSBTC {
    // i = token_from
    // j = token_to
    // dx = token_from_change
    // min_dy = token_to_min_receive
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256); 
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256); 
    function add_liquidity(uint256[3] memory amounts_in, uint256 min_mint_amount) external;
    function remove_liquidity(uint256 amount, uint256[3] memory min_amounts_out) external;
    function remove_liquidity_one_coin(uint256 token_amount, int128 index, uint min_amount) external;
}

interface ICRVSBTC_CRV {
    // i = token_from
    // j = token_to
    // dx = token_from_change
    // min_dy = token_to_min_receive
    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256); 
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external; 
    function add_liquidity(uint256[3] memory amounts_in, uint256 min_mint_amount) external;
    function remove_liquidity(uint256 amount, uint256[3] memory min_amounts_out) external;
    function remove_liquidity_one_coin(uint256 token_amount, int128 index, uint min_amount) external;
}

// https://etherscan.io/address/0xd9e1ce17f2641f24ae83637ab66a2cca9c378b9f#code
interface ISushiRouter {
     function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(
        uint amountIn, 
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IERC104 {
    function pushToLocker(address asset, uint256 amount) external;
    function pullFromLocker(address asset) external;
    function pullFromLockerPartial(address asset, uint256 amount) external;
    function pushToLockerMulti(address[] calldata assets, uint256[] calldata amounts) external;
    function pullFromLockerMulti(address[] calldata assets) external;
    function pullFromLockerMultiPartial(address[] calldata assets, uint256[] calldata amounts) external;
    function pushToLockerERC721(address asset, uint256 tokenId, bytes calldata data) external;
    function pullFromLockerERC721(address asset, uint256 tokenId, bytes calldata data) external;
    function pushToLockerERC1155(
        address asset, 
        uint256[] calldata ids, 
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
    function pullFromLockerERC1155(
        address asset, 
        uint256[] calldata ids, 
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
    function canPush() external view returns (bool);
    function canPull() external view returns (bool);
    function canPullPartial() external view returns (bool);
    function canPushMulti() external view returns (bool);
    function canPullMulti() external view returns (bool);
    function canPullMultiPartial() external view returns (bool);
    function canPushERC721() external view returns (bool);
    function canPullERC721() external view returns (bool);
    function canPushERC1155() external view returns (bool);
    function canPullERC1155() external view returns (bool);
}

// AAVE v2 LendingPool Interface
// Docs:   https://docs.aave.com/developers/v/2.0/the-core-protocol/lendingpool
// Source: https://github.com/aave/protocol-v2/blob/master/contracts/interfaces/ILendingPool.sol

interface IAToken {
    function scaledBalanceOf(address user) external view returns (uint256);
    function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);
}

interface ILendingPool {

    /**
    * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
    * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
    * @param asset The address of the underlying asset to deposit
    * @param amount The amount to be deposited
    * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
    *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
    *   is a different wallet
    * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
    *   0 if the action is executed directly by the user, without any middle-man
    **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
  

    /**
    * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
    * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
    * @param asset The address of the underlying asset to withdraw
    * @param amount The underlying amount to be withdrawn
    *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
    * @param to Address that will receive the underlying, same as msg.sender if the user
    *   wants to receive it on his own wallet, or a different address if the beneficiary is a
    *   different wallet
    * @return The final amount withdrawn
    **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.6;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "./IERC1155Receiver.sol";
import "./ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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