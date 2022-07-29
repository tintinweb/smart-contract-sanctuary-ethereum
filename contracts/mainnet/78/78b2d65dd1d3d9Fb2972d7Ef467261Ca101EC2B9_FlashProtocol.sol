// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IFlashStrategy.sol";
import "./interfaces/IFlashFToken.sol";
import "./interfaces/IFlashNFT.sol";
import "./interfaces/IFlashFTokenFactory.sol";

contract FlashProtocol is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable flashNFTAddress;
    address immutable flashFTokenFactoryAddress;

    // Define the structure for each strategy
    struct StrategyInformation {
        address fTokenAddress;
        address principalTokenAddress;
    }
    mapping(address => StrategyInformation) strategies;

    // This will store the NFT ID to StakeID mapping
    mapping(uint256 => uint256) nftIdMappingsToStakeIds;

    // This will store how many stakes we have
    uint256 stakeCount = 0;

    // The global fToken mint fee
    uint96 globalMintFee = 0;
    address globalMintFeeRecipient = 0x5089722613C2cCEe071C39C59e9889641f435F15;

    // This defines the structure of the Stake information we store
    struct StakeStruct {
        address stakerAddress; // Address of staker
        address strategyAddress; // Address of strategy being used
        uint256 stakeStartTs; // Unix timestamp of when stake started
        uint256 stakeDuration; // Time in seconds from start time until stake ends
        uint256 stakedAmount; // The amount of tokens staked
        bool active; // Stake has been removed/unstaked
        uint256 nftId; // NFT id if set
        uint256 fTokensToUser; // How many fERC20 tokens were minted
        uint256 fTokensFee; // How many fERC20 tokens were taken as fee
        uint256 totalFTokenBurned;
        uint256 totalStakedWithdrawn;
    }
    mapping(uint256 => StakeStruct) stakes;

    // Define events
    event StrategyRegistered(
        address indexed _strategyAddress,
        address indexed _principalTokenAddress,
        address indexed _fTokenAddress
    );
    event Staked(uint256 _stakeId);
    event Unstaked(uint256 _stakeId, uint256 _tokensReturned, uint256 _fTokensBurned, bool _stakeFinished);
    event NFTIssued(uint256 _stakeId, uint256 nftId);

    constructor(address _flashNFTAddress, address _flashFTokenFactoryAddress) public {
        flashNFTAddress = _flashNFTAddress;
        flashFTokenFactoryAddress = _flashFTokenFactoryAddress;
    }

    function registerStrategy(
        address _strategyAddress,
        address _principalTokenAddress,
        string calldata _fTokenName,
        string calldata _fTokenSymbol
    ) external {
        require(
            strategies[_strategyAddress].principalTokenAddress == address(0) &&
                _strategyAddress != address(0) &&
                _principalTokenAddress != address(0)
        );

        address flashFToken = IFlashFTokenFactory(flashFTokenFactoryAddress).createFToken(_fTokenName, _fTokenSymbol);

        // Store the appropriate information
        strategies[_strategyAddress].fTokenAddress = flashFToken;
        strategies[_strategyAddress].principalTokenAddress = _principalTokenAddress;

        IFlashStrategy(_strategyAddress).setFTokenAddress(flashFToken);

        emit StrategyRegistered(_strategyAddress, _principalTokenAddress, flashFToken);
    }

    function stake(
        address _strategyAddress,
        uint256 _tokenAmount,
        uint256 _stakeDuration,
        address _fTokensTo,
        bool _issueNFT
    ) public nonReentrant returns (StakeStruct memory _stake) {
        require(strategies[_strategyAddress].principalTokenAddress != address(0));
        require(
            _stakeDuration >= 60 && _stakeDuration <= IFlashStrategy(_strategyAddress).getMaxStakeDuration(),
            "ISD"
        );

        // Transfer the tokens from caller to the strategy contract
        IERC20(strategies[_strategyAddress].principalTokenAddress).safeTransferFrom(
            msg.sender,
            address(_strategyAddress),
            _tokenAmount
        );

        // Determine how many fERC20 tokens to mint (ask strategy)
        uint256 tokensToMint = IFlashStrategy(_strategyAddress).quoteMintFToken(_tokenAmount, _stakeDuration);

        // Deposit into the strategy
        uint256 principalAfterDeductions = IFlashStrategy(_strategyAddress).depositPrincipal(_tokenAmount);

        // Calculate fee and if this is more than 0, transfer fee
        uint256 fee = (tokensToMint * globalMintFee) / 10000;
        if (fee > 0) {
            IFlashFToken(strategies[_strategyAddress].fTokenAddress).mint(globalMintFeeRecipient, fee);
        }

        // Mint fERC20 tokens to the user
        IFlashFToken(strategies[_strategyAddress].fTokenAddress).mint(_fTokensTo, (tokensToMint - fee));

        // Save the stake details
        stakeCount = stakeCount + 1;
        stakes[stakeCount] = StakeStruct(
            msg.sender,
            _strategyAddress,
            block.timestamp,
            _stakeDuration,
            principalAfterDeductions,
            true,
            0,
            (tokensToMint - fee),
            fee,
            0,
            0
        );

        // Mint NFT if requested
        if (_issueNFT) {
            issueNFT(stakeCount);
        }

        emit Staked(stakeCount);

        return stakes[stakeCount];
    }

    function unstake(
        uint256 _id,
        bool _isNFT,
        uint256 _fTokenToBurn
    ) external nonReentrant returns (uint256 _principalReturned, uint256 _fTokensBurned) {
        StakeStruct memory p;
        uint256 stakeId;
        address returnAddress;
        if (_isNFT) {
            stakeId = nftIdMappingsToStakeIds[_id];
            p = stakes[stakeId];
            returnAddress = msg.sender;
            require(p.nftId == _id, "SNM");
            require(IFlashNFT(flashNFTAddress).ownerOf(_id) == msg.sender, "NNO");
        } else {
            stakeId = _id;
            p = stakes[stakeId];
            returnAddress = p.stakerAddress;

            require(p.nftId == 0, "NTR");
            require(p.stakerAddress == msg.sender, "NSO");
        }
        require(p.active == true, "SNE");

        bool stakeFinished;
        uint256 principalToReturn;
        uint256 percentageIntoStake = (((block.timestamp - p.stakeStartTs) * (10**18)) / p.stakeDuration);

        if (percentageIntoStake >= (10**18)) {
            // Stake has ended, simply return principal
            principalToReturn = p.stakedAmount - p.totalStakedWithdrawn;
            _fTokenToBurn = 0;

            stakeFinished = true;
        } else {
            require(block.timestamp >= (p.stakeStartTs + 3600), "MIN DUR 1HR");

            // Stake has not ended yet, user is trying to withdraw early
            uint256 fTokenBurnForFullUnstake = ((((10**18) - percentageIntoStake) * (p.fTokensToUser + p.fTokensFee)) /
                (10**18));

            if (p.totalFTokenBurned > fTokenBurnForFullUnstake) {
                // The total number of fTokens burned is greater than the amount required, no burn required
                fTokenBurnForFullUnstake = 0;
            } else {
                fTokenBurnForFullUnstake = fTokenBurnForFullUnstake - p.totalFTokenBurned;
            }

            // Ensure the user cannot burn more fTokens than required
            if (_fTokenToBurn > fTokenBurnForFullUnstake) {
                _fTokenToBurn = fTokenBurnForFullUnstake;
            }

            // Is the user trying to withdraw everything early?
            if (_fTokenToBurn == fTokenBurnForFullUnstake) {
                // Yes, return all principal
                principalToReturn = p.stakedAmount - p.totalStakedWithdrawn;
                stakeFinished = true;
            } else {
                // No - only a partial withdraw
                principalToReturn =
                    (((_fTokenToBurn * (10**18)) / (p.fTokensToUser + p.fTokensFee)) * p.stakedAmount) /
                    (10**18);
            }

            // Burn these fTokens
            IFlashFToken(strategies[p.strategyAddress].fTokenAddress).burnFrom(msg.sender, _fTokenToBurn);

            // Update stake information
            stakes[stakeId].totalFTokenBurned = p.totalFTokenBurned + _fTokenToBurn;
            stakes[stakeId].totalStakedWithdrawn = p.totalStakedWithdrawn + principalToReturn;
        }
        require(principalToReturn > 0);
        require(p.stakedAmount >= stakes[stakeId].totalStakedWithdrawn);

        // if the stake is finished, delete all data related to it (nice to have)
        if (stakeFinished) {
            delete stakes[stakeId];
        }
        // if the stake finished and it was NFT based, remove the mapping (nice to have)
        if (stakeFinished && _isNFT) {
            delete nftIdMappingsToStakeIds[_id];
        }
        emit Unstaked(stakeId, principalToReturn, _fTokenToBurn, stakeFinished);

        // Remove tokens from Strategy and transfer to user
        IFlashStrategy(p.strategyAddress).withdrawPrincipal(principalToReturn);
        IERC20(strategies[p.strategyAddress].principalTokenAddress).safeTransfer(returnAddress, principalToReturn);

        return (principalToReturn, _fTokenToBurn);
    }

    function issueNFT(uint256 _stakeId) public returns (uint256 _nftId) {
        StakeStruct memory p = stakes[_stakeId];
        require(p.active == true && p.nftId == 0 && p.stakerAddress == msg.sender);

        // Mint the NFT
        uint256 nftId = IFlashNFT(flashNFTAddress).mint(msg.sender);

        // Store the NFT ID
        stakes[_stakeId].nftId = nftId;

        // Update the NFT Mapping so we can look it up later
        nftIdMappingsToStakeIds[nftId] = _stakeId;

        emit NFTIssued(_stakeId, nftId);

        return nftId;
    }

    function setMintFeeInfo(address _feeRecipient, uint96 _feePercentageBasis) external onlyOwner {
        require(_feePercentageBasis <= 2000);
        globalMintFeeRecipient = _feeRecipient;
        globalMintFee = _feePercentageBasis;
    }

    function getStakeInfo(uint256 _id, bool _isNFT) external view returns (StakeStruct memory _stake) {
        uint256 stakeId;
        if (_isNFT) {
            stakeId = nftIdMappingsToStakeIds[_id];
            require(stakes[stakeId].nftId == _id);
        } else {
            stakeId = _id;
        }

        return stakes[stakeId];
    }

    function flashStake(
        address _strategyAddress,
        uint256 _tokenAmount,
        uint256 _stakeDuration,
        uint256 _minimumReceived,
        address _yieldTo,
        bool _mintNFT
    ) external {
        // Stake (re-direct fTokens to this contract)
        uint256 fTokensToUser = stake(_strategyAddress, _tokenAmount, _stakeDuration, address(this), _mintNFT)
            .fTokensToUser;

        IERC20 fToken = IERC20(strategies[_strategyAddress].fTokenAddress);

        // Approve, burn and send yield to specified address
        fToken.approve(_strategyAddress, fTokensToUser);
        IFlashStrategy(_strategyAddress).burnFToken(fTokensToUser, _minimumReceived, _yieldTo);
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
pragma solidity ^0.8.4;

interface IFlashStrategy {
    event BurnedFToken(address indexed _address, uint256 _tokenAmount, uint256 _yieldReturned);

    // This is how principal will be deposited into the contract
    // The Flash protocol allows the strategy to specify how much
    // should be registered. This allows the strategy to manipulate (eg take fee)
    // on the principal if the strategy requires
    function depositPrincipal(uint256 _tokenAmount) external returns (uint256);

    // This is how principal will be returned from the contract
    function withdrawPrincipal(uint256 _tokenAmount) external;

    // Responsible for instant upfront yield. Takes fERC20 tokens specific to this
    // strategy. The strategy is responsible for returning some amount of principal tokens
    function burnFToken(
        uint256 _tokenAmount,
        uint256 _minimumReturned,
        address _yieldTo
    ) external returns (uint256);

    // This should return the current total of all principal within the contract
    function getPrincipalBalance() external view returns (uint256);

    // This should return the current total of all yield generated to date (including bootstrapped tokens)
    function getYieldBalance() external view returns (uint256);

    // This should return the principal token address (eg DAI)
    function getPrincipalAddress() external view returns (address);

    // View function which quotes how many principal tokens would be returned if x
    // fERC20 tokens are burned
    function quoteMintFToken(uint256 _tokenAmount, uint256 duration) external view returns (uint256);

    // View function which quotes how many principal tokens would be returned if x
    // fERC20 tokens are burned
    // IMPORTANT NOTE: This should utilise bootstrap tokens if they exist
    // bootstrapped tokens are any principal tokens that exist within the smart contract
    function quoteBurnFToken(uint256 _tokenAmount) external view returns (uint256);

    // The function to set the fERC20 address within the strategy
    function setFTokenAddress(address _fTokenAddress) external;

    // This should return what the maximum stake duration is
    function getMaxStakeDuration() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFlashFToken {
    function mint(address account, uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function decimals() external returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFlashNFT {
    function mint(address _recipientAddress) external returns (uint256);

    function burn(uint256 _tokenId) external returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFlashFTokenFactory {
    function createFToken(string calldata _fTokenName, string calldata _fTokenSymbol) external returns (address);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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