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

// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IMintGateway} from "../../Gateways/interfaces/IMintGateway.sol";
import {ILockGateway} from "../../Gateways/interfaces/ILockGateway.sol";

abstract contract IGatewayRegistry {
    function signatureVerifier() external view virtual returns (address);

    function chainId() external view virtual returns (uint256);

    function chainName() external view virtual returns (string memory);

    function getMintGatewaySymbols(uint256 from, uint256 count) external view virtual returns (string[] memory);

    function getLockGatewaySymbols(uint256 from, uint256 count) external view virtual returns (string[] memory);

    function getMintGatewayByToken(address token) external view virtual returns (IMintGateway);

    function getMintGatewayBySymbol(string calldata tokenSymbol) external view virtual returns (IMintGateway);

    function getRenAssetBySymbol(string calldata tokenSymbol) external view virtual returns (IERC20);

    function getLockGatewayByToken(address token) external view virtual returns (ILockGateway);

    function getLockGatewayBySymbol(string calldata tokenSymbol) external view virtual returns (ILockGateway);

    function getLockAssetBySymbol(string calldata tokenSymbol) external view virtual returns (IERC20);
}

// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

abstract contract ILockGateway {
    event LogRelease(address indexed recipient, uint256 amount, bytes32 indexed sigHash, bytes32 indexed nHash);
    event LogLockToChain(
        string recipientAddress,
        string recipientChain,
        bytes recipientPayload,
        uint256 amount,
        uint256 indexed lockNonce,
        // Indexed versions of previous parameters.
        string indexed recipientAddressIndexed,
        string indexed recipientChainIndexed
    );

    function lock(
        string calldata recipientAddress,
        string calldata recipientChain,
        bytes calldata recipientPayload,
        uint256 amount
    ) external virtual returns (uint256);

    function release(
        bytes32 pHash,
        uint256 amount,
        bytes32 nHash,
        bytes calldata sig
    ) external virtual returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

abstract contract IMintGateway {
    /// @dev For backwards compatiblity reasons, the sigHash is cast to a
    /// uint256.
    event LogMint(address indexed to, uint256 amount, uint256 indexed sigHash, bytes32 indexed nHash);

    /// @dev Once `LogBurnToChain` is enabled on mainnet, LogBurn may be
    /// replaced by LogBurnToChain with empty payload and chain fields.
    /// @dev For backwards compatibility, `to` is bytes instead of a string.
    event LogBurn(
        bytes to,
        uint256 amount,
        uint256 indexed burnNonce,
        // Indexed versions of previous parameters.
        bytes indexed indexedTo
    );
    event LogBurnToChain(
        string recipientAddress,
        string recipientChain,
        bytes recipientPayload,
        uint256 amount,
        uint256 indexed burnNonce,
        // Indexed versions of previous parameters.
        string indexed recipientAddressIndexed,
        string indexed recipientChainIndexed
    );

    function mint(
        bytes32 pHash,
        uint256 amount,
        bytes32 nHash,
        bytes calldata sig
    ) external virtual returns (uint256);

    function burnWithPayload(
        string calldata recipientAddress,
        string calldata recipientChain,
        bytes calldata recipientPayload,
        uint256 amount
    ) external virtual returns (uint256);

    function burn(string calldata recipient, uint256 amount) external virtual returns (uint256);

    function burn(bytes calldata recipient, uint256 amount) external virtual returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IGatewayRegistry} from "@renproject/gateway-sol/src/GatewayRegistry/interfaces/IGatewayRegistry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Payment, FEE_CURRENCY} from "./libraries/Payment.sol";

struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
}

interface OneInch {
    function swap(
        address caller,
        SwapDescription calldata desc,
        bytes calldata data
    ) external payable returns (uint256);

    function unoswap(
        IERC20 srcToken,
        uint256 _amount,
        uint256 minReturn,
        bytes32[] calldata pools
    ) external payable returns (uint256 returnAmount);

    function uniswapV3Swap(
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns (uint256 returnAmount);

    function uniswapV3SwapTo(
        address payable recipient,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns (uint256 returnAmount);

    function clipperSwap(
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 amount,
        uint256 minReturn
    ) external payable returns (uint256 returnAmount);

    function clipperSwapTo(
        address payable recipient,
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 amount,
        uint256 minReturn
    ) external payable returns (uint256 returnAmount);
}

contract OneInchAdapter is Context, Payment {
    OneInch public oneInch;

    constructor(OneInch oneInch_) {
        oneInch = oneInch_;
    }

    function swap(
        address caller,
        SwapDescription calldata desc,
        bytes calldata data
    ) public payable returns (uint256) {
        uint256 amount;
        if (address(desc.srcToken) == FEE_CURRENCY) {
            amount = msg.value;
        } else {
            amount = desc.srcToken.allowance(_msgSender(), address(this));
            desc.srcToken.approve(address(oneInch), amount);
        }
        acceptPayment(address(desc.srcToken), amount);

        return
            oneInch.swap{value: msg.value}(
                caller,
                SwapDescription({
                    srcToken: desc.srcToken,
                    dstToken: desc.dstToken,
                    srcReceiver: desc.srcReceiver,
                    dstReceiver: desc.dstReceiver == address(0x0)
                        ? payable(_msgSender())
                        : desc.dstReceiver,
                    amount: amount,
                    minReturnAmount: desc.minReturnAmount,
                    flags: desc.flags,
                    permit: desc.permit
                }),
                data
            );
    }

    function unoswap(
        IERC20 srcToken,
        uint256 _amount,
        uint256 minReturn,
        bytes32[] calldata pools
    ) public payable returns (uint256 returnAmount) {
        uint256 approvedAmount;
        if (
            address(srcToken) == FEE_CURRENCY ||
            address(srcToken) == address(0x0)
        ) {
            approvedAmount = msg.value;
        } else {
            approvedAmount = srcToken.allowance(_msgSender(), address(this));
            srcToken.approve(address(oneInch), approvedAmount);
        }
        acceptPayment(address(srcToken), approvedAmount);

        return oneInch.unoswap(srcToken, approvedAmount, minReturn, pools);
    }

    function uniswapV3Swap(
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns (uint256 returnAmount) {
        return uniswapV3SwapTo(payable(_msgSender()), amount, minReturn, pools);
    }

    function uniswapV3SwapTo(
        address payable recipient,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) public payable returns (uint256 returnAmount) {}

    function clipperSwap(
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 amount,
        uint256 minReturn
    ) external payable returns (uint256 returnAmount) {
        return
            clipperSwapTo(
                payable(_msgSender()),
                srcToken,
                dstToken,
                amount,
                minReturn
            );
    }

    function clipperSwapTo(
        address payable recipient,
        IERC20 srcToken,
        IERC20 dstToken,
        uint256 amount,
        uint256 minReturn
    ) public payable returns (uint256 returnAmount) {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

address constant FEE_CURRENCY = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

abstract contract Payment is Context {
    function acceptPayment(address token, uint256 amount) internal {
        if (token == FEE_CURRENCY || token == address(0x0)) {
            require(msg.value == amount, "Payment: insufficient msg.value");
        } else {
            IERC20(token).transferFrom(_msgSender(), address(this), amount);
        }
    }

    function payToken(
        address to,
        address token,
        uint256 amount
    ) internal {
        if (token == FEE_CURRENCY || token == address(0x0)) {
            payable(to).transfer(amount);
        } else {
            IERC20(token).transfer(to, amount);
        }
    }
}