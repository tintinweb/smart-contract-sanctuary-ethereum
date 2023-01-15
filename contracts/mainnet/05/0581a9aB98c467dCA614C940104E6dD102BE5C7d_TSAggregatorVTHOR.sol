// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SafeTransferLib} from "../lib/SafeTransferLib.sol";
import {TSAggregator} from "./TSAggregator.sol";
import {IThorchainRouter} from "./interfaces/IThorchainRouter.sol";
import {IUniswapRouterV2} from "./interfaces/IUniswapRouterV2.sol";

import {IERC20} from "./interfaces/IERC20.sol";
import {IERC4626} from "./interfaces/IERC4626.sol";

contract TSAggregatorVTHOR is TSAggregator {
    using SafeTransferLib for address;

    IERC20 public thor;
    IERC4626 public vthor;

    address public weth;
    IUniswapRouterV2 public swapRouter;

    constructor(
        address _thor,
        address _vthor,
        address _ttp,
        address _weth,
        address _swapRouter // sushiswap
    ) TSAggregator(_ttp) {
        thor = IERC20(_thor);
        vthor = IERC4626(_vthor);

        weth = _weth;
        swapRouter = IUniswapRouterV2(_swapRouter);
    }

    function sendFeesToStakers() public nonReentrant {
        address(thor).safeApprove(address(vthor), thor.balanceOf(address(this)));
        thor.transfer(address(vthor), thor.balanceOf(address(this)));
    }

    function redeemDeposit(
        address tcRouter,
        address tcVault,
        string calldata memo,
        uint256 shares,
        uint256 deadline
    ) public nonReentrant {
        uint256 thorAmount = vthor.redeem(shares, address(this), msg.sender);
        uint256 amountOut = skimFee(thorAmount);

        address(thor).safeApprove(address(tcRouter), amountOut);

        IThorchainRouter(tcRouter).depositWithExpiry{value: 0}(
            payable(tcVault),
            address(thor),
            amountOut,
            memo,
            deadline
        );
    }

    function redeemSwapEthDeposit(
        address tcRouter,
        address tcVault,
        string calldata memo,
        uint256 shares,
        uint256 amountOutMin,
        uint256 deadline
    ) public nonReentrant {
        uint256 thorAmount = vthor.redeem(shares, address(this), msg.sender);
        uint256 amountOut = skimFee(thorAmount);

        thor.approve(address(swapRouter), amountOut);

        address[] memory path = new address[](2);
        path[0] = address(thor);
        path[1] = weth;
        swapRouter.swapExactTokensForETH(
            amountOut,
            amountOutMin,
            path,
            address(this),
            deadline
        );

        IThorchainRouter(tcRouter).depositWithExpiry{value: address(this).balance}(
            payable(tcVault),
            address(0),
            amountOut,
            memo,
            deadline
        );
    }

    // swapOut from tcRouter and (swap)deposit for vTHOR
    function swapOut(
        address token, // not used now, could allow for more token staking in the future
        address to,
        uint256 amountOutMin
    ) public payable nonReentrant {
        // B. We receive ETH from the router: swap it for thor and stake
        // Can't get ERC20 transferOut from tcRouter...
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = address(thor);
        swapRouter.swapExactETHForTokens{value: msg.value}(
            _parseAmountOutMin(amountOutMin),
            path,
            to,
            type(uint256).max
        );

        address(thor).safeApprove(address(vthor), thor.balanceOf(address(this)));
        vthor.deposit(address(this).balance, to);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SafeTransferLib} from "../lib/SafeTransferLib.sol";
import {ReentrancyGuard} from "../lib/ReentrancyGuard.sol";
import {Owners} from "./Owners.sol";
import {TSAggregatorTokenTransferProxy} from "./TSAggregatorTokenTransferProxy.sol";

abstract contract TSAggregator is Owners, ReentrancyGuard {
    using SafeTransferLib for address;

    event FeeSet(uint256 fee, address feeRecipient);

    uint256 public fee;
    address public feeRecipient;
    TSAggregatorTokenTransferProxy public tokenTransferProxy;

    constructor(address _tokenTransferProxy) {
        _setOwner(msg.sender, true);
        tokenTransferProxy = TSAggregatorTokenTransferProxy(
            _tokenTransferProxy
        );
    }

    // Needed for the swap router to be able to send back ETH
    receive() external payable {}

    function setFee(uint256 _fee, address _feeRecipient) external isOwner {
        require(_fee <= 1000, "fee can not be more than 10%");
        fee = _fee;
        feeRecipient = _feeRecipient;
        emit FeeSet(_fee, _feeRecipient);
    }

    function skimFee(uint256 amount) internal returns (uint256) {
        if (fee != 0 && feeRecipient != address(0)) {
            uint256 feeAmount = (amount * fee) / 10000;
            feeRecipient.safeTransferETH(feeAmount);
            amount -= feeAmount;
        }
        return amount;
    }

    // Parse amountOutMin treating the last 2 digits as an exponent
    // So 15e4 = 150000. This allows for compressed memos on chains
    // with limited space like Bitcoin
    function _parseAmountOutMin(uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return (amount / 100) * (10**(amount % 100));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IThorchainRouter {
    function depositWithExpiry(
        address payable vault,
        address asset,
        uint256 amount,
        string memory memo,
        uint256 expiration
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUniswapRouterV2 {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC4626 {
    function asset() external view returns (address assetTokenAddress);
    function totalAssets() external view returns (uint256 totalManagedAssets);
    function convertToShares(uint256 assets) external view returns (uint256 shares);
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);
    function previewDeposit(uint256 assets) external view returns (uint256 shares);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function maxMint(address receiver) external view returns (uint256 maxShares);
    function previewMint(uint256 shares) external view returns (uint256 assets);
    function mint(uint256 shares, address receiver) external returns (uint256 assets);
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
    function maxRedeem(address owner) external view returns (uint256 maxShares);
    function previewRedeem(uint256 shares) external view returns (uint256 assets);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Owners {
    event OwnerSet(address indexed owner, bool active);

    mapping(address => bool) public owners;

    modifier isOwner() {
        require(owners[msg.sender], "Unauthorized");
        _;
    }

    function _setOwner(address owner, bool active) internal virtual {
        owners[owner] = active;
        emit OwnerSet(owner, active);
    }

    function setOwner(address owner, bool active) external virtual isOwner {
        _setOwner(owner, active);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SafeTransferLib} from "../lib/SafeTransferLib.sol";
import {Owners} from "./Owners.sol";

contract TSAggregatorTokenTransferProxy is Owners {
    using SafeTransferLib for address;

    constructor() {
        _setOwner(msg.sender, true);
    }

    function transferTokens(
        address token,
        address from,
        address to,
        uint256 amount
    ) external isOwner {
        require(from == tx.origin || _isContract(from), "Invalid from address");
        token.safeTransferFrom(from, to, amount);
    }

    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}