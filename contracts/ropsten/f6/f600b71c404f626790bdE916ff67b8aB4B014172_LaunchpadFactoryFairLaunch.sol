// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces.sol";
import "./LaunchpadPresaleFairLaunch.sol";

interface IApolloSafePlay {
    function setRaiseInAddress(address _raisein) external;
}

contract LaunchpadFactoryFairLaunch is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    address public router;
    address immutable tokenImplementation;
    address public feeAddress;
    address public signer;
    address private _burnAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public finalizeForOwner = 259200; // 72-hours
    uint256 public liquidityPercentLimit = 5000;
    uint256 public createFee;

    mapping(address => address) public CloneAddressOfPrivate;
    mapping(address => address) public CloneAddressOf;
    mapping(address => address) public CloneAddressOfFairLaunch;
    mapping(address => bool) public tokenSupported;

    event CreateLaunch(
        address indexed token,
        address indexed raiseIn,
        LaunchpadPresaleFairLaunch.Parameters par,
        LaunchpadPresaleFairLaunch.WhitelistParameters wpar,
        LaunchpadPresaleFairLaunch.VestingParameters vpar,
        uint256 tokens,
        uint256 raisedFee,
        uint256 influencerFee
    );

    constructor(
        address _router,
        address _feeAddress,
        address _signer,
        uint256 _createFee
    ) {
        require(
            _router != address(0) &&
                _feeAddress != address(0) &&
                _signer != address(0),
            "Invalid address"
        );

        router = _router;
        feeAddress = _feeAddress;
        tokenImplementation = address(new LaunchpadPresaleFairLaunch());
        createFee = _createFee;
        signer = _signer;

        tokenSupported[address(0)] = true;
    }

    /**
     * @dev Sets fee collector address
     */
    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0), "Invalid address");
        feeAddress = _feeAddress;
    }

    /**
     * @dev Sets signer collector address
     */
    function setSigner(address _signer) external onlyOwner {
        require(_signer != address(0), "Invalid address");
        signer = _signer;
    }

    /**
     * @dev Sets router address
     */
    function setRouterAddress(address _router) external onlyOwner {
        require(_router != address(0), "Invalid address");
        router = _router;
    }

    /**
     * @dev Sets finalize for owner duration
     */
    function setFinalizeForOwner(uint256 _finalizeForOwner) external onlyOwner {
        finalizeForOwner = _finalizeForOwner;
    }

    /**
     * @dev To set liquidity percent limit
     */
    function setLiquidityPercentLimit(uint256 _liquidityPercentLimit)
        external
        onlyOwner
    {
        liquidityPercentLimit = _liquidityPercentLimit;
    }

    /**
     * @dev To set create fee
     */
    function setCreateFee(uint256 _createFee) external onlyOwner {
        createFee = _createFee;
    }

    /**
     * @dev Add Token Support for Presale/Private Sale
     */
    function addTokenSupport(address _token) external onlyOwner {
        tokenSupported[_token] = true;
    }

    /**
     * @dev Remove Token Support for Presale/Private Sale
     */
    function removeTokenSupport(address _token) external onlyOwner {
        tokenSupported[_token] = false;
    }

    /**
     * @param saleType: 0 - private sale, 1 - presale, 2 - fair launch, 3 - safePlay
     * @param presaleRate: 1 raiseIn token = ? Tokens in WEI
     * @param hardcap: ? raisein in WEI
     * @param liquidityPercent: ? % multiplied with 100 e.g. Fir 50% pass 5000
     * @param listingRate: 1 raiseIn token = ? Tokens in WEI (At the time of adding liquiding in Router)
     */
    function requiredTokens(
        address raiseIn,
        uint8 saleType,
        uint256 presaleRate,
        uint256 hardcap,
        uint256 liquidityPercent,
        uint256 listingRate,
        uint256 totalSellingAmount
    ) public view returns (uint256 tokens) {
        if (saleType == 2) {
            tokens =
                ((liquidityPercent * totalSellingAmount) / 10000) +
                totalSellingAmount;
        } else {
            uint256 raiseInDecimals;

            if (raiseIn == address(0)) {
                raiseInDecimals = 18;
            } else {
                raiseInDecimals = IERC20Metadata(raiseIn).decimals();
            }

            tokens = (hardcap * presaleRate) / (10**raiseInDecimals);
            tokens =
                tokens +
                ((hardcap * liquidityPercent * listingRate) /
                    (10000 * (10**raiseInDecimals)));
        }
    }

    /**
     * @dev To create new launchpad presale contract
     * 0 - Private Sale
     * 1 - Presale
     * 2 - Fair Launch
     * 3 - safe play
     */
    function createLaunch(
        address token,
        address raiseIn,
        LaunchpadPresaleFairLaunch.Parameters memory par,
        LaunchpadPresaleFairLaunch.WhitelistParameters memory wpar,
        LaunchpadPresaleFairLaunch.VestingParameters memory vpar,
        uint256 raisedFee,
        uint256 influencerFee
    ) public payable nonReentrant whenNotPaused {
        require(msg.value >= createFee, "Fees are wrong");
        require(tokenSupported[raiseIn], "Token Not Supported");
        if (par.saleType != 0) {
            require(
                par.liquidityPercent >= liquidityPercentLimit,
                "Liquidity Percent Low"
            );
        }

        address clone = Clones.clone(tokenImplementation);
        LaunchpadPresaleFairLaunch(payable(clone)).initialize(
            owner(),
            signer,
            feeAddress,
            token,
            raiseIn,
            router,
            par,
            wpar,
            vpar,
            raisedFee,
            influencerFee,
            finalizeForOwner
        );

        LaunchpadPresaleFairLaunch(payable(clone)).transferOwnership(
            msg.sender
        );

        if (par.saleType == 0) {
            CloneAddressOfPrivate[token] = clone;
        } else if (par.saleType == 2) {
            CloneAddressOfFairLaunch[token] = clone;
        } else {
            CloneAddressOf[token] = clone;
        }

        uint256 tokens = requiredTokens(
            raiseIn,
            par.saleType,
            par.presaleRate,
            par.hardcap,
            par.liquidityPercent,
            par.listingRate,
            par.totalSellingAmount
        );

        if (par.saleType == 3) {
            uint256 totalTokens = IERC20(token).totalSupply();
            require(totalTokens >= tokens, "Insufficient token supply");
            uint256 extraToken = totalTokens - tokens;
            if (extraToken > 0) {
                require(
                    IERC20(token).transferFrom(
                        msg.sender,
                        _burnAddress,
                        extraToken
                    ),
                    "Transfer Failed"
                );
            }
            if (raiseIn != address(0)) {
                IApolloSafePlay(token).setRaiseInAddress(raiseIn);
            } else {
                IApolloSafePlay(token).setRaiseInAddress(
                    IUniswapV2Router02(router).WETH()
                );
            }
        }

        IERC20(token).safeTransferFrom(msg.sender, clone, tokens);
        require(
            IERC20(token).balanceOf(clone) >= tokens,
            "Received Amount Invalid"
        );

        emit CreateLaunch(
            token,
            raiseIn,
            par,
            wpar,
            vpar,
            tokens,
            raisedFee,
            influencerFee
        );
    }

    /**
     * @dev Withdraw BNB
     */
    function withdraw(uint256 weiAmount, address to) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(address(this).balance >= weiAmount, "insufficient BNB balance");
        (bool sent, ) = payable(to).call{value: weiAmount}("");
        require(sent, "Failed to withdraw");
    }

    /**
     * @dev To pause
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev To unpause
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

pragma solidity ^0.8.4;

// SPDX-License-Identifier: MIT

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


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces.sol";

contract LaunchpadPresaleFairLaunch is
    Initializable,
    ReentrancyGuard,
    Ownable,
    Pausable
{
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    address public feeAddress;
    address public signer;
    address public platformOwner;
    address private constant _burnAddress =
        0x000000000000000000000000000000000000dEaD;

    IERC20 public token;
    IERC20Metadata public raiseIn;
    IUniswapV2Router02 public router;
    address public pair;

    uint256 public decimals;
    uint256 public participants;
    uint256 public totalBought;
    uint256 public liqidityLockedTill;
    uint256 public influencerFee;
    uint256 public raisedFee;
    uint256 public finalizeForOwner;
    uint256 public finalizedAt;
    uint256 public mustRaise;
    uint256 public tokenRate;

    bool public fail;
    bool public isFinalized;
    bool public unlocked;

    struct Parameters {
        uint8 saleType;
        uint256 presaleRate;
        uint256 softcap;
        uint256 hardcap;
        uint256 minBuy;
        uint256 maxBuy;
        uint256 startTime;
        uint256 endTime;
        uint256 liquidityPercent;
        uint256 lockingPeriod;
        uint256 listingRate;
        uint256 totalSellingAmount;
        uint256 maxOwnerReceive;
    }

    struct VestingParameters {
        bool vesting;
        uint256 vestingCyclePeriod;
        uint256[] vestingRelease;
    }

    struct WhitelistParameters {
        bool whitelist;
        uint256 duration;
        uint256 minBuy;
        uint256 maxBuy;
    }

    Parameters public par;
    WhitelistParameters public wpar;
    VestingParameters public vpar;

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public wbought;
    mapping(address => uint256) public bought;
    mapping(address => uint256) public claimed;

    event Buy(address indexed account, uint256 amount);
    event Claim(address indexed account, uint256 tokens);
    event Withdraw(address indexed account, uint256 amount);
    event Success(
        address indexed token,
        uint256 amountToLiquidity,
        uint256 tokensToLiquidity,
        uint256 unsold
    );
    event SuccessFairLaunch(
        address indexed token,
        uint256 amountToLiquidity,
        uint256 tokensToLiquidity,
        uint256 amountToOwner
    );
    event Fail(address indexed token);

    /**
     * @dev Initializing contract with parameters
     */
    function initialize(
        address _platformOwner,
        address _signer,
        address _feeAddress,
        address _token,
        address _raiseIn,
        address _router,
        Parameters calldata _par,
        WhitelistParameters calldata _wpar,
        VestingParameters calldata _vpar,
        uint256 _raisedFee,
        uint256 _influencerFee,
        uint256 _finalizeForOwner
    ) public initializer {
        require(
            _platformOwner != address(0) &&
                _signer != address(0) &&
                _feeAddress != address(0),
            "Invalid address"
        );
        // In case of fair launch
        if (_par.saleType == 2) {
            require(
                _par.softcap >= percent(_par.maxOwnerReceive, 5100) &&
                    _par.hardcap == 0 &&
                    _par.listingRate == 0,
                "Invalid Parameters"
            );
            if (_par.maxOwnerReceive > 0) {
                mustRaise =
                    ((_par.liquidityPercent * _par.maxOwnerReceive) /
                        (10000 - _par.liquidityPercent)) +
                    _par.maxOwnerReceive;
                mustRaise +=
                    ((mustRaise * _raisedFee) / (10000 - _raisedFee)) +
                    _influencerFee;
            }
        } else {
            // In case of Normal sale
            require(
                _par.softcap >= (_par.hardcap / 2) &&
                    (_par.softcap <= _par.hardcap),
                "Invalid Softcap"
            );

            if (_vpar.vesting) {
                uint256 releasePercent;
                for (uint256 i = 0; i < _vpar.vestingRelease.length; i++) {
                    releasePercent += _vpar.vestingRelease[i];
                }
                require(releasePercent == 10000, "Release Sum Invalid");
            }
        }

        _transferOwnership(_msgSender());

        platformOwner = _platformOwner;
        signer = _signer;
        feeAddress = _feeAddress;
        token = IERC20(_token);
        raiseIn = IERC20Metadata(_raiseIn);
        router = IUniswapV2Router02(_router);
        par = _par;
        wpar = _wpar;
        vpar = _vpar;
        raisedFee = _raisedFee;
        influencerFee = _influencerFee;
        finalizeForOwner = _finalizeForOwner;
        if (_raiseIn != address(0)) {
            decimals = raiseIn.decimals();
        } else {
            decimals = 18;
        }
    }

    /**
     * @dev Adding accounts to whitelist if whitelist tier is active
     * @notice gas is propotional to array size
     * @param account: array of addresses to add
     */
    function addToWhitelist(address[] memory account) external onlyOwner {
        require(wpar.whitelist, "Whitelist is not active");

        for (uint256 i = 0; i < account.length; i++) {
            whitelist[account[i]] = true;
        }
    }

    /**
     * @dev Remove from whitelist
     * @param account: array of addresses to remove
     */
    function removeFromWhitelist(address[] memory account) external onlyOwner {
        require(wpar.whitelist, "Whitelist is not active");

        for (uint256 i = 0; i < account.length; i++) {
            whitelist[account[i]] = false;
        }
    }

    /**
     * @param status: Enable/Disable Whitelist Tier
     */
    function changeWhitelistStatus(bool status)
        external
        onlyOwner
        notForFairLaunch
    {
        wpar.whitelist = status;
    }

    /**
     * @dev To whitelist yourself through staking
     * @param signature: Signed Signature
     */
    function getWhitelisted(bytes memory signature) public notForFairLaunch {
        require(wpar.whitelist, "Whitelist is not active");
        require(recover(signature) == signer, "Wrong Signer");

        whitelist[msg.sender] = true;
    }

    /**
     * @dev To Get Message Hash in Frontend
     * @param user: address of user
     */
    function getMessageHash(address user) public view returns (bytes32) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return keccak256(abi.encodePacked(address(this), user, id));
    }

    /**
     * @dev To Get Ethereum Signed Message Hash
     */
    function getEthSignedMessageHash() public view returns (bytes32) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encodePacked(address(this), msg.sender, id))
                )
            );
    }

    /**
     * @dev To Get Signer of Signature
     * @param signature: Signed Signature
     */
    function recover(bytes memory signature) public view returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(getEthSignedMessageHash(), v, r, s);
        }
    }

    /**
     * @dev To buy tokens
     * @param amount: purchase amount
     */
    function buy(uint256 amount) external payable nonReentrant whenNotPaused {
        require(
            block.timestamp >= par.startTime && block.timestamp < par.endTime,
            "Sale Not Active"
        );
        require(!isFinalized, "Finalized");
        if (par.saleType != 2) {
            // In case of fair launch no hard cap
            require(totalBought + amount <= par.hardcap, "Sold out");
        }

        if (
            wpar.whitelist && block.timestamp < (par.startTime + wpar.duration)
        ) {
            require(whitelist[msg.sender], "You are not Whitelisted");

            require(
                bought[msg.sender] + amount >= wpar.minBuy &&
                    bought[msg.sender] + amount <= wpar.maxBuy,
                "Whitelist: Can't Buy"
            );

            if (wbought[msg.sender] + bought[msg.sender] == 0) {
                participants += 1;
            }

            wbought[msg.sender] += amount;
            totalBought += amount;
        } else {
            require(
                bought[msg.sender] + amount >= par.minBuy &&
                    bought[msg.sender] + amount <= par.maxBuy,
                "Can't Buy"
            );

            if (wbought[msg.sender] + bought[msg.sender] == 0) {
                participants += 1;
            }

            bought[msg.sender] += amount;
            totalBought += amount;
        }

        if (address(raiseIn) != address(0)) {
            raiseIn.safeTransferFrom(msg.sender, address(this), amount);
        } else {
            require(msg.value == amount, "Invalid Amount");
        }

        emit Buy(msg.sender, amount);
    }

    /**
     * @dev calculates amount of tokens as per presale rate
     * @param amount: purchase amount in WEI
     */
    function calculateTokens(uint256 amount)
        public
        view
        notForFairLaunch
        returns (uint256 tokens)
    {
        tokens = (par.presaleRate * amount) / (10**decimals);
    }

    /**
     * @dev transfer _amount to address
     * @param _amount to transfer
     */
    function transfer(uint256 _amount, address _to) private {
        if (_amount > 0 && address(raiseIn) != address(0)) {
            raiseIn.safeTransfer(_to, _amount);
        } else if (_amount > 0) {
            (bool sentFee, ) = payable(_to).call{value: _amount}("");
            require(sentFee, "Fees transfer failed");
        }
    }

    /**
     * @dev To add liquidity
     * @param _tokensToLiquidity: tokens to add in liquidity
     * @param _amountToLiquidity: BNB to add in liquidity
     */
    function addLiquidity(
        uint256 _amountToLiquidity,
        uint256 _tokensToLiquidity
    ) private {
        liqidityLockedTill = block.timestamp + par.lockingPeriod;
        token.safeApprove(address(router), _tokensToLiquidity);
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        if (address(raiseIn) != address(0)) {
            raiseIn.safeApprove(address(router), _amountToLiquidity);

            router.addLiquidity(
                address(token),
                address(raiseIn),
                _tokensToLiquidity,
                _amountToLiquidity,
                0,
                0,
                address(this),
                block.timestamp
            );
            pair = factory.getPair(address(token), address(raiseIn));
        } else {
            router.addLiquidityETH{value: _amountToLiquidity}(
                address(token),
                _tokensToLiquidity,
                0,
                0,
                address(this),
                block.timestamp
            );
            pair = factory.getPair(address(token), router.WETH());
        }
    }

    /**
     * @dev Finalizing/Ending the respective Launch
     * Adding liquidity as calculated
     * Returning remaining BNB/Tokens to owner in case of presale
     * Unsold tokens are returned to owner
     * If fails then return all tokens to owner
     */
    function finalize() external {
        require(!isFinalized, "Already Finalized");
        if (par.saleType == 2) {
            require(block.timestamp > par.endTime, "Sale is not ended");
        } else {
            require(
                totalBought >= percent(par.hardcap, 9900) ||
                    block.timestamp > par.endTime,
                "Sale is not ended"
            );
        }

        if (
            block.timestamp > par.endTime &&
            ((block.timestamp - par.endTime) < finalizeForOwner)
        ) {
            require(msg.sender == owner(), "Ownable: caller is not the owner");
        }

        isFinalized = true;
        finalizedAt = block.timestamp;

        if (totalBought >= par.softcap) {
            fail = false;

            uint256 remainingAmount = 0;
            uint256 amountToLiquidity = 0;
            uint256 tokensToLiquidity = 0;
            uint256 payToOwner = 0;
            uint256 raisedFeeAmount = percent(totalBought, raisedFee);
            uint256 feesToPay = raisedFeeAmount + influencerFee;

            // In case of Fair Launch
            if (par.saleType == 2) {
                remainingAmount = totalBought - feesToPay;

                tokensToLiquidity = percent(
                    par.totalSellingAmount,
                    par.liquidityPercent
                );

                // Calculating liquidity percentage
                if (par.maxOwnerReceive > 0 && totalBought >= mustRaise) {
                    payToOwner = par.maxOwnerReceive;
                    amountToLiquidity = totalBought - feesToPay - payToOwner;
                } else {
                    amountToLiquidity = percent(
                        remainingAmount,
                        par.liquidityPercent
                    );
                    payToOwner = totalBought - amountToLiquidity - feesToPay;
                }

                transfer(payToOwner, owner());

                addLiquidity(amountToLiquidity, tokensToLiquidity);

                tokenRate = priceForFairLaunch();

                emit SuccessFairLaunch(
                    address(token),
                    amountToLiquidity,
                    tokensToLiquidity,
                    payToOwner
                );
            } else {
                remainingAmount = totalBought - raisedFeeAmount;

                // Adding Liquidity
                if (par.saleType == 1 || par.saleType == 3) {
                    amountToLiquidity = (remainingAmount *
                        par.liquidityPercent);
                    tokensToLiquidity =
                        (par.listingRate * amountToLiquidity) /
                        ((10**decimals) * 10000);
                    amountToLiquidity = amountToLiquidity / 10000;
                    addLiquidity(amountToLiquidity, tokensToLiquidity);
                }

                // Tranfering to owner
                payToOwner = totalBought - amountToLiquidity - feesToPay;
                transfer(payToOwner, owner());

                // Transferring Unsold Tokens to Owner or Burning
                uint256 unsold = (token.balanceOf(address(this))) -
                    (calculateTokens(totalBought));

                if (unsold > 0) {
                    if (par.saleType == 3) {
                        token.safeTransfer(_burnAddress, unsold);
                    } else {
                        token.safeTransfer(owner(), unsold);
                    }
                }

                emit Success(
                    address(token),
                    amountToLiquidity,
                    tokensToLiquidity,
                    unsold
                );
            }

            transfer(feesToPay, feeAddress);
        } else {
            fail = true;

            // Transferring All Tokens to Owner
            token.safeTransfer(owner(), token.balanceOf(address(this)));

            emit Fail(address(token));
        }
    }

    /**
     * @dev Returns pending amount of tokens for an account
     * @param account: address of account
     */
    function pendingClaim(address account)
        public
        view
        returns (uint256 tokens)
    {
        if (isFinalized && !fail) {
            if (par.saleType == 2) {
                tokens =
                    ((tokenRate * bought[account]) / 1 ether) -
                    claimed[account];
                return tokens;
            }

            uint256 ubought = calculateTokens(
                wbought[account] + bought[account]
            );
            uint256 cycles = 0;

            if (vpar.vesting) {
                if (vpar.vestingCyclePeriod > 0) {
                    cycles =
                        (block.timestamp - finalizedAt) /
                        vpar.vestingCyclePeriod;
                }

                cycles = min(vpar.vestingRelease.length, cycles + 1);

                for (uint256 i = 0; i < cycles; i++) {
                    tokens += (ubought * vpar.vestingRelease[i]) / 10000;
                }
            } else {
                tokens = ubought;
            }

            tokens -= claimed[account];
        }
    }

    /**
     * @dev To claim tokens
     */
    function claim() public nonReentrant {
        uint256 tokens;

        tokens = pendingClaim(msg.sender);

        if (tokens > 0) {
            claimed[msg.sender] += tokens;

            token.safeTransfer(msg.sender, tokens);
        }

        emit Claim(msg.sender, tokens);
    }

    /**
     * @dev To unlock and claim locked LP
     */
    function unlockLiquidity() external onlyOwner {
        require(
            block.timestamp > liqidityLockedTill,
            "Liquidity Locking Period is not Over"
        );

        unlocked = true;

        uint256 LPBalance = LPTokenBalance(address(this));

        IERC20(pair).safeTransfer(owner(), LPBalance);
    }

    /// @dev Extends locking period of liquidity
    /// @param _liqidityLockedTill a unix time, must be greater than current locking period
    function extendLockingPeriod(uint256 _liqidityLockedTill)
        external
        onlyOwner
    {
        require(!unlocked, "Liquidity already unlocked");
        if (liqidityLockedTill >= block.timestamp) {
            liqidityLockedTill = liqidityLockedTill + _liqidityLockedTill;
        } else {
            liqidityLockedTill = block.timestamp + _liqidityLockedTill;
        }
    }

    /// @dev Relocking of liquidity with whatever LPToken owner has
    /// @param _liqidityLockedTill a unix time, must be greater than current block.timestamp
    function relockLiquidity(uint256 _liqidityLockedTill, uint256 _amount)
        external
        onlyOwner
    {
        require(unlocked, "Liquidity not unlocked");

        IERC20(pair).safeTransferFrom(owner(), address(this), _amount);

        unlocked = false;
        liqidityLockedTill = block.timestamp + _liqidityLockedTill;
    }

    /// @dev To know the balance of LPTOken
    /// @param _owner address of which balance will be returned
    /// @return balance - balance of _owner
    function LPTokenBalance(address _owner)
        public
        view
        returns (uint256 balance)
    {
        require(pair != address(0), "Pair hasn't been created yet");
        balance = IERC20(pair).balanceOf(_owner);
    }

    /**
     * @dev When Launch Fails
     * Users will be able to withdraw their BNB/Token back
     */
    function withdraw() external nonReentrant {
        require(fail, "Can't Withdraw");

        uint256 amount = wbought[msg.sender] + bought[msg.sender];

        if (amount > 0) {
            wbought[msg.sender] = 0;
            bought[msg.sender] = 0;

            if (address(raiseIn) != address(0)) {
                raiseIn.safeTransfer(msg.sender, amount);
            } else {
                (bool sent, ) = payable(msg.sender).call{value: amount}("");
                require(sent, "Failed to withdraw");
            }
        }

        emit Withdraw(msg.sender, amount);
    }

    /**
     * @dev Withdraw BNB
     */
    function withdrawBNB(uint256 weiAmount, address to) external {
        require(to != address(0), "Invalid address");
        require(msg.sender == platformOwner, "Invalid Account");
        require(address(this).balance >= weiAmount, "insufficient BNB balance");
        (bool sent, ) = payable(to).call{value: weiAmount}("");
        require(sent, "Failed to withdraw");
    }

    function withdrawToken(uint256 amount, address to) external {
        require(msg.sender == platformOwner, "Invalid Account");
        require(
            token.balanceOf(address(this)) >= amount,
            "insufficient token balance"
        );

        token.safeTransfer(to, amount);
    }

    function withdrawRaiseToken(uint256 amount, address to) external {
        require(msg.sender == platformOwner, "Invalid Account");
        require(
            raiseIn.balanceOf(address(this)) >= amount,
            "insufficient token balance"
        );

        raiseIn.safeTransfer(to, amount);
    }

    function withdrawERC20(
        address erc20,
        uint256 amount,
        address to
    ) external {
        require(msg.sender == platformOwner, "Invalid Account");

        IERC20(erc20).safeTransfer(to, amount);
    }

    function finalizeManual() external onlyOwnerAndPlatformOwner {
        require(!isFinalized, "Sale is finalized");

        isFinalized = true;
        finalizedAt = block.timestamp;
        fail = false;
    }

    /**
     * @dev Successfully fail
     */
    function safeFail() external onlyOwnerAndPlatformOwner {
        require(!isFinalized, "Sale is finalized");

        isFinalized = true;
        fail = true;

        // Transferring All Tokens to Owner
        token.safeTransfer(owner(), token.balanceOf(address(this)));

        emit Fail(address(token));
    }

    /**
     * @dev Calculates percentage with two decimal support.
     */
    function percent(uint256 amount, uint256 fraction)
        public
        pure
        virtual
        returns (uint256)
    {
        return ((amount * fraction) / 10000);
    }

    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev To pause
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev To unpause
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function setRouter(address _router) external onlyOwner {
        router = IUniswapV2Router02(_router);
    }

    modifier notForFairLaunch() {
        require(par.saleType != 2, "Not for fair launch");
        _;
    }

    modifier onlyForFairLaunch() {
        require(par.saleType == 2, "Only for fair launch");
        _;
    }

    modifier onlyOwnerAndPlatformOwner() {
        require(
            owner() == _msgSender() || platformOwner == _msgSender(),
            "Ownable: caller is not the owner"
        );
        _;
    }

    /**
     * @dev calculate tokens per raiseIn token
     */
    function priceForFairLaunch()
        public
        view
        onlyForFairLaunch
        returns (uint256 price)
    {
        price = (par.totalSellingAmount * 1 ether) / (totalBought);
    }

    /**
     * @dev to recieve BNB from uniswapV2Router when adding liquidity
     */
    receive() external payable {}
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}