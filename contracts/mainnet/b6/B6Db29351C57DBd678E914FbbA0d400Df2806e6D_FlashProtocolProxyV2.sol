// SPDX-License-Identifier: BUSL-1.1
// Licensor: Flashstake DAO
// Licensed Works: (this contract, source below)
// Change Date: The earlier of 2026-12-01 or a date specified by Flashstake DAO publicly
// Change License: GNU General Public License v2.0 or later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IFlashProtocol.sol";
import "./interfaces/IFlashStrategy.sol";
import "./interfaces/IFlashNFT.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IWETH.sol";

contract FlashProtocolProxyV2 is Ownable {
    using SafeERC20 for IERC20;

    struct PermitInfo {
        uint8 _v;
        bytes32 _r;
        bytes32 _s;
        uint256 _deadline;
    }

    address public immutable flashProtocolAddress;
    address payable public immutable nativeWrappedTokenAddress;
    address payable public immutable routerContractAddress;
    address immutable flashNFTAddress;

    constructor(
        address _flashProtocolAddress,
        address payable _routerContractAddress,
        address payable _nativeWrappedTokenAddress
    ) {
        flashProtocolAddress = _flashProtocolAddress;
        routerContractAddress = _routerContractAddress;
        nativeWrappedTokenAddress = _nativeWrappedTokenAddress;

        flashNFTAddress = IFlashProtocol(flashProtocolAddress).flashNFTAddress();
    }

    /// @notice Wrapper to allow users to stake ETH (as opposed to WETH)
    /// @dev Not permissioned: callable by anyone
    function stakeETH(
        address _strategyAddress,
        uint256 _stakeDuration,
        address _fTokensTo
    ) external payable returns (IFlashProtocol.StakeStruct memory) {
        IWETH(nativeWrappedTokenAddress).deposit{ value: msg.value }();

        IWETH(nativeWrappedTokenAddress).approve(flashProtocolAddress, msg.value);
        IFlashProtocol.StakeStruct memory stakeInfo = IFlashProtocol(flashProtocolAddress).stake(
            _strategyAddress,
            msg.value,
            _stakeDuration,
            _fTokensTo,
            true
        );

        IFlashNFT(flashNFTAddress).safeTransferFrom(address(this), msg.sender, stakeInfo.nftId);

        return stakeInfo;
    }

    /// @notice Wrapper to allow users to Flashstake ETH (as opposed to WETH)
    /// @dev Not permissioned. Beware: DO NOT pass 0 into _burnFTokenAmount unless you know exactly what you are doing
    function flashStakeETH(
        address _strategyAddress,
        uint256 _stakeDuration,
        uint256 _burnFTokenAmount,
        uint256 _swapFTokenAmount,
        uint256 _minimumReturnedBurn,
        uint256 _minimumReturnedSwap,
        bytes calldata _swapRoute,
        address _yieldTo
    ) external payable {
        IWETH(nativeWrappedTokenAddress).deposit{ value: msg.value }();

        flashStakeInternal(
            _strategyAddress,
            msg.value,
            _stakeDuration,
            _burnFTokenAmount,
            _swapFTokenAmount,
            _minimumReturnedBurn,
            _minimumReturnedSwap,
            _swapRoute,
            _yieldTo
        );
    }

    /// @notice Wrapper to allow users to stake ERC20 tokens with Permit
    /// @dev Not permissioned: callable by anyone
    function stakeWithPermit(
        address _strategyAddress,
        uint256 _tokenAmount,
        uint256 _stakeDuration,
        address _fTokensTo,
        PermitInfo calldata _permitInfo
    ) external returns (IFlashProtocol.StakeStruct memory) {
        IERC20 pToken = IERC20(IFlashStrategy(_strategyAddress).getPrincipalAddress());

        consumePermit(_permitInfo, address(pToken), _tokenAmount);
        pToken.safeTransferFrom(msg.sender, address(this), _tokenAmount);

        pToken.approve(flashProtocolAddress, _tokenAmount);
        IFlashProtocol.StakeStruct memory stakeInfo = IFlashProtocol(flashProtocolAddress).stake(
            _strategyAddress,
            _tokenAmount,
            _stakeDuration,
            _fTokensTo,
            true
        );

        IFlashNFT(flashNFTAddress).safeTransferFrom(address(this), msg.sender, stakeInfo.nftId);

        return stakeInfo;
    }

    /// @notice Wrapper to allow users to Flashstake then burn and/or swap their fTokens in one tx with Permit
    /// @dev Not permissioned. Beware: DO NOT pass 0 into _burnFTokenAmount unless you know exactly what you are doing
    function flashStakeWithPermit(
        address _strategyAddress,
        uint256 _tokenAmount,
        uint256 _stakeDuration,
        uint256 _burnFTokenAmount,
        uint256 _swapFTokenAmount,
        uint256 _minimumReturnedBurn,
        uint256 _minimumReturnedSwap,
        bytes calldata _swapRoute,
        address _yieldTo,
        PermitInfo calldata _permitInfo
    ) external {
        IERC20 pToken = IERC20(IFlashStrategy(_strategyAddress).getPrincipalAddress());

        consumePermit(_permitInfo, address(pToken), _tokenAmount);
        pToken.safeTransferFrom(msg.sender, address(this), _tokenAmount);

        flashStakeInternal(
            _strategyAddress,
            _tokenAmount,
            _stakeDuration,
            _burnFTokenAmount,
            _swapFTokenAmount,
            _minimumReturnedBurn,
            _minimumReturnedSwap,
            _swapRoute,
            _yieldTo
        );
    }

    /// @notice Wrapper to allow users to Flashstake then burn and/or swap their fTokens in one tx
    /// @dev Not permissioned. Beware: DO NOT pass 0 into _burnFTokenAmount unless you know exactly what you are doing
    function flashStake(
        address _strategyAddress,
        uint256 _tokenAmount,
        uint256 _stakeDuration,
        uint256 _burnFTokenAmount,
        uint256 _swapFTokenAmount,
        uint256 _minimumReturnedBurn,
        uint256 _minimumReturnedSwap,
        bytes calldata _swapRoute,
        address _yieldTo
    ) external {
        IERC20 pToken = IERC20(IFlashStrategy(_strategyAddress).getPrincipalAddress());

        pToken.safeTransferFrom(msg.sender, address(this), _tokenAmount);

        flashStakeInternal(
            _strategyAddress,
            _tokenAmount,
            _stakeDuration,
            _burnFTokenAmount,
            _swapFTokenAmount,
            _minimumReturnedBurn,
            _minimumReturnedSwap,
            _swapRoute,
            _yieldTo
        );
    }

    /// @notice Wrapper to allow users to burn and/or swap their fTokens in one tx
    /// @dev Not permissioned. Beware: DO NOT pass 0 into _burnFTokenAmount unless you know exactly what you are doing
    function burnAndSwapFToken(
        address _strategyAddress,
        uint256 _burnFTokenAmount,
        uint256 _swapFTokenAmount,
        uint256 _minimumReturnedBurn,
        uint256 _minimumReturnedSwap,
        bytes calldata _swapRoute,
        address _yieldTo
    ) external {
        IERC20 fToken = IERC20(IFlashStrategy(_strategyAddress).getFTokenAddress());

        fToken.safeTransferFrom(msg.sender, address(this), _burnFTokenAmount + _swapFTokenAmount);

        burnAndSwapFTokenInternal(
            _strategyAddress,
            _burnFTokenAmount,
            _swapFTokenAmount,
            _minimumReturnedBurn,
            _minimumReturnedSwap,
            _swapRoute,
            _yieldTo
        );
    }

    /// @notice Wrapper to allow users to burn and/or swap their fTokens in one tx using Permit
    /// @dev Not permissioned. Beware: DO NOT pass 0 into _burnFTokenAmount unless you know exactly what you are doing
    function burnAndSwapFTokenWithPermit(
        address _strategyAddress,
        uint256 _burnFTokenAmount,
        uint256 _swapFTokenAmount,
        uint256 _minimumReturnedBurn,
        uint256 _minimumReturnedSwap,
        bytes calldata _swapRoute,
        address _yieldTo,
        PermitInfo calldata _permitInfo
    ) external {
        IERC20 fToken = IERC20(IFlashStrategy(_strategyAddress).getFTokenAddress());

        uint256 _totalAmount = _burnFTokenAmount + _swapFTokenAmount;

        consumePermit(_permitInfo, address(fToken), _totalAmount);
        fToken.safeTransferFrom(msg.sender, address(this), _totalAmount);

        burnAndSwapFTokenInternal(
            _strategyAddress,
            _burnFTokenAmount,
            _swapFTokenAmount,
            _minimumReturnedBurn,
            _minimumReturnedSwap,
            _swapRoute,
            _yieldTo
        );
    }

    /// @notice Wrapper to allow users to burn their fTokens in one tx with permit
    /// @dev Not permissioned: callable by anyone
    function burnFTokenWithPermit(
        address _strategyAddress,
        uint256 _burnFTokenAmount,
        uint256 _minimumReturnedBurn,
        address _yieldTo,
        PermitInfo calldata _permitInfo
    ) external {
        IERC20 fToken = IERC20(IFlashStrategy(_strategyAddress).getFTokenAddress());

        consumePermit(_permitInfo, address(fToken), _burnFTokenAmount);
        fToken.safeTransferFrom(msg.sender, address(this), _burnFTokenAmount);

        fToken.approve(_strategyAddress, _burnFTokenAmount);
        IFlashStrategy(_strategyAddress).burnFToken(_burnFTokenAmount, _minimumReturnedBurn, _yieldTo);
    }

    /// @notice Internal function wrapper for flashstaking
    /// @dev This can only be called internally
    function flashStakeInternal(
        address _strategyAddress,
        uint256 _tokenAmount,
        uint256 _stakeDuration,
        uint256 _burnFTokenAmount,
        uint256 _swapFTokenAmount,
        uint256 _minimumReturnedBurn,
        uint256 _minimumReturnedSwap,
        bytes calldata _swapRoute,
        address _yieldTo
    ) private {
        IERC20 principalContract = IERC20(IFlashStrategy(_strategyAddress).getPrincipalAddress());

        principalContract.approve(flashProtocolAddress, _tokenAmount);
        IFlashProtocol.StakeStruct memory stakeInfo = IFlashProtocol(flashProtocolAddress).stake(
            _strategyAddress,
            _tokenAmount,
            _stakeDuration,
            address(this),
            true
        );

        require(_burnFTokenAmount + _swapFTokenAmount == stakeInfo.fTokensToUser, "SWAP AND/OR BURN AMOUNT INVALID");

        burnAndSwapFTokenInternal(
            _strategyAddress,
            _burnFTokenAmount,
            _swapFTokenAmount,
            _minimumReturnedBurn,
            _minimumReturnedSwap,
            _swapRoute,
            _yieldTo
        );

        IFlashNFT(flashNFTAddress).safeTransferFrom(address(this), msg.sender, stakeInfo.nftId);
    }

    /// @notice Internal wrapper, burns/swaps fTokens as per user inputs
    /// @dev This can only be called internally
    function burnAndSwapFTokenInternal(
        address _strategyAddress,
        uint256 _burnFTokenAmount,
        uint256 _swapFTokenAmount,
        uint256 _minimumReturnedBurn,
        uint256 _minimumReturnedSwap,
        bytes calldata _swapRoute,
        address _yieldTo
    ) private {
        IERC20 fToken = IERC20(IFlashStrategy(_strategyAddress).getFTokenAddress());

        // @note Relying on FlashStrategy handling ensuring minimum is returned
        // @note V2:  Only burn fTokens if the user is expecting back (_minimumReturnedBurn) more than 0 tokens
        // @note      otherwise trap fTokens within this contract and avoid burning
        if (_burnFTokenAmount > 0 && _minimumReturnedBurn > 0) {
            fToken.approve(_strategyAddress, _burnFTokenAmount);
            IFlashStrategy(_strategyAddress).burnFToken(_burnFTokenAmount, _minimumReturnedBurn, _yieldTo);
        }

        // @note Relying on Uniswap handling ensuring minimum is returned
        if (_swapFTokenAmount > 0) {
            fToken.approve(routerContractAddress, _swapFTokenAmount);
            ISwapRouter(routerContractAddress).exactInput{ value: 0 }(
                ISwapRouter.ExactInputParams({
                    path: _swapRoute,
                    recipient: _yieldTo,
                    amountIn: _swapFTokenAmount,
                    amountOutMinimum: _minimumReturnedSwap
                })
            );
        }
    }

    /// @notice Internal function to consume Permit
    /// @dev This can only be called internally
    function consumePermit(
        PermitInfo calldata _permitInfo,
        address _tokenAddress,
        uint256 _tokenAmount
    ) private {
        IERC20Permit permitToken = IERC20Permit(_tokenAddress);
        permitToken.permit(
            msg.sender,
            address(this),
            _tokenAmount,
            _permitInfo._deadline,
            _permitInfo._v,
            _permitInfo._r,
            _permitInfo._s
        );
    }

    /// @notice Allows owner to withdraw any ERC20 token to a _recipient address - used for fToken rescue
    /// @dev This can be called by the Owner only
    function withdrawERC20(address[] calldata _tokenAddresses, address _recipient) external onlyOwner {
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            // Transfer all the tokens to the caller
            uint256 totalBalance = IERC20(_tokenAddresses[i]).balanceOf(address(this));
            IERC20(_tokenAddresses[i]).safeTransfer(_recipient, totalBalance);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFlashStrategy {
    event BurnedFToken(address indexed _address, uint256 _tokenAmount, uint256 _yieldReturned);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function burnFToken(
        uint256 _tokenAmount,
        uint256 _minimumReturned,
        address _yieldTo
    ) external returns (uint256);

    function claimAAVEv2Rewards(address[] memory _assets, uint256 _amount) external;

    function depositPrincipal(uint256 _tokenAmount) external returns (uint256);

    function getFTokenAddress() external view returns (address);

    function getMaxStakeDuration() external pure returns (uint256);

    function getPrincipalAddress() external view returns (address);

    function getPrincipalBalance() external view returns (uint256);

    function getYieldBalance() external view returns (uint256);

    function increaseAllowance() external;

    function lockSetUserIncentiveAddress() external;

    function owner() external view returns (address);

    function quoteBurnFToken(uint256 _tokenAmount) external view returns (uint256);

    function quoteMintFToken(uint256 _tokenAmount, uint256 _duration) external view returns (uint256);

    function renounceOwnership() external;

    function setFTokenAddress(address _fTokenAddress) external;

    function setUserIncentiveAddress(address _userIncentiveAddress) external;

    function transferOwnership(address newOwner) external;

    function userIncentiveAddress() external view returns (address);

    function userIncentiveAddressLocked() external view returns (bool);

    function withdrawERC20(address[] memory _tokenAddresses, uint256[] memory _tokenAmounts) external;

    function withdrawPrincipal(uint256 _tokenAmount) external;
}

pragma solidity ^0.8.4;

interface IFlashProtocol {
    event NFTIssued(uint256 _stakeId, uint256 nftId);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Staked(uint256 _stakeId);
    event StrategyRegistered(
        address indexed _strategyAddress,
        address indexed _principalTokenAddress,
        address indexed _fTokenAddress
    );
    event Unstaked(uint256 _stakeId, uint256 _tokensReturned, uint256 _fTokensBurned, bool _stakeFinished);

    function flashNFTAddress() external view returns (address);

    function flashStake(
        address _strategyAddress,
        uint256 _tokenAmount,
        uint256 _stakeDuration,
        uint256 _minimumReceived,
        address _yieldTo,
        bool _mintNFT
    ) external;

    function getStakeInfo(uint256 _id, bool _isNFT) external view returns (StakeStruct memory _stake);

    function issueNFT(uint256 _stakeId) external returns (uint256 _nftId);

    function owner() external view returns (address);

    function registerStrategy(
        address _strategyAddress,
        address _principalTokenAddress,
        string memory _fTokenName,
        string memory _fTokenSymbol
    ) external;

    function renounceOwnership() external;

    function setMintFeeInfo(address _feeRecipient, uint96 _feePercentageBasis) external;

    function stake(
        address _strategyAddress,
        uint256 _tokenAmount,
        uint256 _stakeDuration,
        address _fTokensTo,
        bool _issueNFT
    ) external returns (StakeStruct memory _stake);

    function transferOwnership(address newOwner) external;

    function unstake(
        uint256 _id,
        bool _isNFT,
        uint256 _fTokenToBurn
    ) external returns (uint256 _principalReturned, uint256 _fTokensBurned);

    struct StakeStruct {
        address stakerAddress;
        address strategyAddress;
        uint256 stakeStartTs;
        uint256 stakeDuration;
        uint256 stakedAmount;
        bool active;
        uint256 nftId;
        uint256 fTokensToUser;
        uint256 fTokensFee;
        uint256 totalFTokenBurned;
        uint256 totalStakedWithdrawn;
    }
}

pragma solidity ^0.8.4;

interface IFlashNFT {
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function burn(uint256 _tokenId) external returns (bool);

    function contractURI() external pure returns (string memory);

    function exists(uint256 _tokenId) external view returns (bool);

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function mint(address _recipientAddress) external returns (uint256);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function renounceOwnership() external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferOwnership(address newOwner) external;
}

pragma solidity ^0.8.4;

interface ISwapRouter {
    function WETH9() external view returns (address);

    function exactInput(ISwapRouter.ExactInputParams memory params) external payable returns (uint256 amountOut);

    function exactInputSingle(ISwapRouter.ExactOutputSingleParams memory params)
        external
        payable
        returns (uint256 amountOut);

    function exactOutput(ISwapRouter.ExactOutputParams memory params) external payable returns (uint256 amountIn);

    function exactOutputSingle(ISwapRouter.ExactOutputSingleParams memory params)
        external
        payable
        returns (uint256 amountIn);

    function factory() external view returns (address);

    function multicall(bytes[] memory data) external payable returns (bytes[] memory results);

    function refundETH() external payable;

    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;

    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external payable;

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes memory _data
    ) external;

    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    function unwrapWETH9WithFee(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external payable;

    receive() external payable;

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IWETH {
    function name() external view returns (string memory);

    function approve(address guy, uint256 wad) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function transfer(address dst, uint256 wad) external returns (bool);

    function deposit() external payable;

    function allowance(address, address) external view returns (uint256);

    fallback() external payable;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
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