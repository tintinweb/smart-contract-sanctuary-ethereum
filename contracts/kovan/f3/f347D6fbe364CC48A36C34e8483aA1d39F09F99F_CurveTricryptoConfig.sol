// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/curve/tricrypto/ITricryptoStrategyConfig.sol";

import "../../libraries/FeeOperations.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title A config contract for Curve Tricrypto strategy
/// @author Cosmin Grigore (@gcosmintech)
contract CurveTricryptoConfig is
    ITricryptoStrategyConfig,
    Ownable,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;
    /// @notice main reward token
    address public override crvToken;

    /// @notice the LP token address
    address public override tricryptoToken;

    /// @notice the LP Vault address; L1 0x3993d34e7e99abf6b6f367309975d1360222d446
    ITricryptoLPVault public override tricryptoLPVault;

    /// @notice the Gauge address; L1 0xDeFd8FdD20e0f34115C7018CCfb655796F6B2168
    ITricryptoLPGauge public override tricryptoGauge;

    /// @notice the Minter address; L1 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0
    IMinter public override minter;

    /// @notice the Swap address; L1 0xd51a44d3fae010294c616388b506acda1bfaae46
    ITricryptoSwap public override tricryptoSwap;

    /// @notice the keeper's address
    address public override keeper;

    /// @notice the bridge manager's address
    address public override bridgeManager;

    /// @notice the mapping for whitelisted underlying addresses
    mapping(address => bool) public override underlyingAssets;

    /// @notice array of reward tokens
    address[] private _rewardTokensArray;

    /// @notice the mapping for whitelisted reward tokens
    mapping(address => bool) public override whitelistedRewardTokens;

    /// @notice the fee address
    address public override feeAddress;

    /// @notice min fee per withdrawal
    uint256 public override minFee;

    /// @notice max fee per withdrawal
    uint256 public override maxFee;

    /// @notice current fee per withdrawal
    uint256 public override currentFee;

    /// @notice the number of underlying assets tricrypto has
    uint256 public override underlyingAssetsNo;

    /// @notice weth token
    address public override wethToken;

    /// @notice Constructor
    /// @param _lpVault The LP Vault contract from Curve where underlying assets are deposited in exchange of an LP
    /// @param _gauge The gauge contract from Curve where LPs are staked for rewards
    /// @param _minter The minter contract from Curve, used to claim rewards in CRV Token
    /// @param _i The numnber of underlying assets the LP vault has
    /// @param _weth WETH address
    constructor(
        address _lpVault,
        address _gauge,
        address _minter,
        uint256 _i,
        address _weth
    ) {
        require(_lpVault != address(0), "ERR: INVALID LP VAULT ADDRESS");
        require(_gauge != address(0), "ERR: INVALID GAUGE ADDRESS");
        require(_minter != address(0), "ERR: INVALID MINTER ADDRESS");
        require(_weth != address(0), "ERR: INVALID WETH ADDRESS");
        require(_i > 0, "ERR: INVALID NO OF UNDERLYING ASSETS");

        // tricryptoLPVault = ITricryptoLPVault(_lpVault);
        // tricryptoGauge = ITricryptoLPGauge(_gauge);
        // minter = IMinter(_minter);
        // tricryptoSwap = ITricryptoSwap(tricryptoLPVault.pool());
        // address _crvToken = tricryptoGauge.crv_token();
        // whitelistedRewardTokens[_crvToken] = true;
        // _rewardTokensArray.push(_crvToken);
        // crvToken = _crvToken;
        // _whitelisteUnderlyingAssetsAuto(_i);
        // tricryptoToken = tricryptoLPVault.token();

        minFee = 0;
        maxFee = 500; //5%
        currentFee = minFee;
        wethToken = _weth;
    }

    //View methods
    function getRewardTokensArray()
        external
        view
        override
        returns (address[] memory)
    {
        return _rewardTokensArray;
    }

    //Owner methods
    /// @notice Updates the WETH token's address
    /// @param _weth new address
    function setWethToken(address _weth)
        external
        validAddress(_weth)
        onlyOwner
    {
        emit WethTokenSet(msg.sender, _weth, wethToken);
        wethToken = _weth;
    }

    /// @notice Updates the Tricrypto token's address
    /// @param _token new address
    function setTricryptoToken(address _token)
        external
        validAddress(_token)
        onlyOwner
    {
        emit TricryptoTokenSet(msg.sender, _token, tricryptoToken);
        tricryptoToken = _token;
    }

    function setCrvToken(address _crv) external validAddress(_crv) onlyOwner {
        emit CrvTokenSet(msg.sender, _crv, crvToken);
        crvToken = _crv;
    }

    function setUnderlyingAssetsNumber(uint256 i) external onlyOwner {
        require(i > 0, "ERR: INVALID NUMBER");
        emit UnderlyingAssetNoChange(msg.sender, i, underlyingAssetsNo);
        underlyingAssetsNo = i;
    }

    /// @notice Updates the current fee
    /// @param _fee new fee value
    function setCurrentFee(uint256 _fee) external onlyOwner {
        currentFee = _fee;
        require(_fee >= minFee && _fee <= maxFee, "ERR: INVALID FEE");
        emit CurrentFeeChanged(_fee);
    }

    /// @notice Updates the minimum fee
    /// @param _newMinFee new minimum fee value
    function setMinFee(uint256 _newMinFee) external onlyOwner {
        require(_newMinFee < FeeOperations.FEE_FACTOR, "ERR: MIN > FACTOR");
        require(_newMinFee < maxFee, "ERR: MIN > MAX");

        minFee = _newMinFee;
        emit MinFeeChanged(_newMinFee);
    }

    /// @notice Updates the maximum fee
    /// @param _newMaxFee new maximum fee value
    function setMaxFee(uint256 _newMaxFee) external onlyOwner {
        require(_newMaxFee < FeeOperations.FEE_FACTOR, "ERR: MAX > FACTOR");
        require(_newMaxFee > minFee, "ERR: MIN > MAX");

        maxFee = _newMaxFee;
        emit MaxFeeChanged(_newMaxFee);
    }

    /// @notice Used to set the fee address
    /// @param _addr Wallet address
    function setFeeAddress(address _addr)
        external
        onlyOwner
        validAddress(_addr)
    {
        feeAddress = _addr;
        emit FeeAddressSet(msg.sender, _addr, feeAddress);
    }

    /// @notice Used to whitelist a new reward token and to add it to the array
    /// @dev When interacting over the array, we use the mapping to check if a reward is still valid
    /// @param _addr Token address
    function addRewardToken(address _addr)
        external
        onlyOwner
        validAddress(_addr)
    {
        _rewardTokensArray.push(_addr);
        whitelistedRewardTokens[_addr] = true;
        emit RewardTokenStatusChange(msg.sender, _addr, true);
    }

    /// @notice Used to remove a reward token fromt he whitelist
    /// @dev We don't remove it from the array; we have the mapping to check if a reward is still valid
    /// @param _addr Token address
    function removeRewardToken(address _addr)
        external
        onlyOwner
        validAddress(_addr)
    {
        whitelistedRewardTokens[_addr] = false;
        emit RewardTokenStatusChange(msg.sender, _addr, false);
    }

    /// @notice Used to set the LP Vault
    /// @param _addr LP Vault address
    function setGaugeVault(address _addr)
        external
        onlyOwner
        validAddress(_addr)
    {
        emit GaugeSet(msg.sender, _addr, address(tricryptoGauge));
        tricryptoGauge = ITricryptoLPGauge(_addr);
    }

    /// @notice Used to set the LP Vault
    /// @param _addr LP Vault address
    function setLPVault(address _addr) external onlyOwner validAddress(_addr) {
        emit LPVaultSet(msg.sender, _addr, address(tricryptoLPVault));
        tricryptoLPVault = ITricryptoLPVault(_addr);
        emit SwapVaultSet(
            msg.sender,
            tricryptoLPVault.pool(),
            address(tricryptoSwap)
        );
        tricryptoSwap = ITricryptoSwap(tricryptoLPVault.pool());
    }

    /// @notice Used to set the minter
    /// @param _addr Minter address
    function setMinter(address _addr) external onlyOwner validAddress(_addr) {
        emit MinterSet(msg.sender, _addr, address(minter));
        minter = IMinter(_addr);
    }

    /// @notice Used to set the LP Vault
    /// @param _addr LP Vault address
    function setSwapVault(address _addr)
        external
        onlyOwner
        validAddress(_addr)
    {
        emit SwapVaultSet(msg.sender, _addr, address(tricryptoLPVault));
        tricryptoSwap = ITricryptoSwap(_addr);
    }

    /// @notice Used to set the keeper
    /// @param _addr Keeper address
    function setKeeper(address _addr) external onlyOwner validAddress(_addr) {
        emit KeeperSet(msg.sender, _addr, keeper);
        keeper = _addr;
    }

    /// @notice Used to set the bridgeManager
    /// @param _addr bridgeManager address
    function setBridgeManager(address _addr)
        external
        onlyOwner
        validAddress(_addr)
    {
        emit BridgeManagerSet(msg.sender, _addr, bridgeManager);
        bridgeManager = _addr;
    }

    /// @notice Used to whitelist an underlying token
    /// @param _underlying Token address
    function whitelistUnderlying(address _underlying) external onlyOwner {
        require(!underlyingAssets[_underlying], "ERR: ALREADY WHITELISTED");
        underlyingAssets[_underlying] = true;
        emit UnderlyingWhitelistStatusChange(_underlying, msg.sender, true);
    }

    /// @notice Used to remove an underlying token from the whitelist
    /// @param _underlying Token address
    function removeUnderlyingFromWhitelist(address _underlying)
        external
        onlyOwner
    {
        require(underlyingAssets[_underlying], "ERR: NOT WHITELISTED");
        underlyingAssets[_underlying] = false;
        emit UnderlyingWhitelistStatusChange(_underlying, msg.sender, false);
    }

    /// @notice Automatically whitelist tokens available in the Curve Tricrypto LP Vault
    /// @param _i The numnber of underlying assets the LP vault has
    function _whitelisteUnderlyingAssetsAuto(uint256 _i) private {
        for (uint256 i = 0; i < _i; i++) {
            address underlying = tricryptoLPVault.coins(i);

            underlyingAssets[underlying] = true;
        }
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "ERR: INVALID ADDRESS");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITricryptoLPVault.sol";
import "./ITricryptoLPGauge.sol";
import "./ITricryptoSwap.sol";
import "./IMinter.sol";

/// @title Interface for Curve Tricrypto strategy config
/// @author Cosmin Grigore (@gcosmintech)
interface ITricryptoStrategyConfig {
    event CurrentFeeChanged(uint256 newMinFee);
    event MinFeeChanged(uint256 newMinFee);
    event MaxFeeChanged(uint256 newMaxFee);
    event FeeAddressSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event TricryptoTokenSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event CrvTokenSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event LPVaultSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event SwapVaultSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event GaugeSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event MinterSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event KeeperSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event BridgeManagerSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );

    event RewardTokenSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );
    event UnderlyingWhitelistStatusChange(
        address indexed underlying,
        address indexed owner,
        bool whitelisted
    );
    event RewardTokenStatusChange(
        address indexed owner,
        address indexed token,
        bool whitelisted
    );
    event UnderlyingAssetNoChange(
        address indexed owner,
        uint256 newNo,
        uint256 previousNo
    );

    event WethTokenSet(
        address indexed owner,
        address indexed newAddr,
        address indexed oldAddr
    );

    function wethToken() external view returns (address);

    function crvToken() external view returns (address);

    function tricryptoToken() external view returns (address);

    function tricryptoLPVault() external view returns (ITricryptoLPVault);

    function tricryptoSwap() external view returns (ITricryptoSwap);

    function tricryptoGauge() external view returns (ITricryptoLPGauge);

    function minter() external view returns (IMinter);

    function keeper() external view returns (address);

    function bridgeManager() external view returns (address);

    function underlyingAssets(address asset) external view returns (bool);

    function whitelistedRewardTokens(address asset)
        external
        view
        returns (bool);

    function getRewardTokensArray() external view returns (address[] memory);

    function feeAddress() external view returns (address);

    function minFee() external view returns (uint256);

    function maxFee() external view returns (uint256);

    function currentFee() external view returns (uint256);

    function underlyingAssetsNo() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/**
 * Created on 2021-06-07 08:50
 * @author: Pepe Blasco
 */
pragma solidity ^0.8.0;

library FeeOperations {
    uint256 internal constant FEE_FACTOR = 10000;

    function getFeeAbsolute(uint256 amount, uint256 fee)
        internal
        pure
        returns (uint256)
    {
        return (amount * fee) / FEE_FACTOR;
    }

    function getRatio(
        uint256 numerator,
        uint256 denominator,
        uint256 precision
    ) internal pure returns (uint256) {
        if (numerator == 0 || denominator == 0) {
            return 0;
        }
        uint256 _numerator = numerator * 10**(precision + 1);
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    /// @notice Save approve token for spending on contract
    /// @param token Token's address
    /// @param to Contract's address
    /// @param value Amount
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ERR::safeApprove: approve failed"
        );
    }

    /// @notice Safe transfer ETH to address
    /// @param to Contract's address
    /// @param value Contract's address
    /// @param value Amount
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ERR::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

/// @title Interface for Curve Tricrypto swaps & liquidity
/// @author Cosmin Grigore (@gcosmintech)
interface ITricryptoLPVault {
    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount,
        address _receiver
    ) external;

    function remove_liquidity(
        uint256 _amount,
        uint256[3] calldata min_amounts,
        address _receiver
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 _min_amount
    ) external;

    function token() external view returns (address);

    function coins(uint256 i) external view returns (address);

    function pool() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for Curve Tricrypto LP staking gauge
/// @author Cosmin Grigore (@gcosmintech)
interface ITricryptoLPGauge {
    function crv_token() external view returns (address);

    function deposit(
        uint256 _value,
        address _addr,
        bool _claim_rewards
    ) external;

    function withdraw(uint256 value, bool _claim_rewards) external;

    function claim_rewards(address _addr, address _receiver) external;

    function balanceOf(address _addr) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for Curve Tricrypto remove liquidity operation
/// @author Cosmin Grigore (@gcosmintech)
interface ITricryptoSwap {
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 _min_amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for Curve Minter
interface IMinter {
    function mint(address _gauge_addr) external;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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