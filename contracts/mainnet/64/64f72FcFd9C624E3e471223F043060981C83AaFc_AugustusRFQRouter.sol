// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "../AugustusStorage.sol";
import "./IRouter.sol";
import "../lib/weth/IWETH.sol";
import "../lib/Utils.sol";
import "../lib/augustus-rfq/IAugustusRFQ.sol";

contract AugustusRFQRouter is AugustusStorage, IRouter {
    using SafeMath for uint256;

    address public immutable weth;
    address public immutable exchange;

    constructor(address _weth, address _exchange) public {
        weth = _weth;
        exchange = _exchange;
    }

    function initialize(bytes calldata) external override {
        revert("METHOD NOT IMPLEMENTED");
    }

    function getKey() external pure override returns (bytes32) {
        return keccak256(abi.encodePacked("AUGUSTUS_RFQ_ROUTER", "1.0.0"));
    }

    function swapOnAugustusRFQ(
        IAugustusRFQ.Order calldata order,
        bytes calldata signature,
        uint8 wrapETH // set 0 bit to wrap src, and 1 bit to wrap dst
    ) external payable {
        address userAddress = address(uint160(order.nonceAndMeta));
        require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");

        uint256 fromAmount = order.takerAmount;
        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            tokenTransferProxy.transferFrom(order.takerAsset, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, order.takerAsset, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).fillOrder(order, signature);
            uint256 receivedAmount = Utils.tokenBalance(order.makerAsset, address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).fillOrderWithTarget(order, signature, msg.sender);
        }
    }

    function swapOnAugustusRFQWithPermit(
        IAugustusRFQ.Order calldata order,
        bytes calldata signature,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        bytes calldata permit
    ) external payable {
        address userAddress = address(uint160(order.nonceAndMeta));
        require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");

        uint256 fromAmount = order.takerAmount;
        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            Utils.permit(order.takerAsset, permit);
            tokenTransferProxy.transferFrom(order.takerAsset, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, order.takerAsset, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).fillOrder(order, signature);
            uint256 receivedAmount = Utils.tokenBalance(order.makerAsset, address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).fillOrderWithTarget(order, signature, msg.sender);
        }
    }

    function swapOnAugustusRFQNFT(
        IAugustusRFQ.OrderNFT calldata order,
        bytes calldata signature,
        uint8 wrapETH // set 0 bit to wrap src, and 1 bit to wrap dst
    ) external payable {
        address userAddress = address(uint160(order.nonceAndMeta));
        require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");

        uint256 fromAmount = order.takerAmount;
        address fromToken = address(uint160(order.takerAsset));
        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            tokenTransferProxy.transferFrom(fromToken, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, fromToken, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).fillOrderNFT(order, signature);
            uint256 receivedAmount = Utils.tokenBalance(address(uint160(order.makerAsset)), address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).fillOrderWithTargetNFT(order, signature, msg.sender);
        }
    }

    function swapOnAugustusRFQNFTWithPermit(
        IAugustusRFQ.OrderNFT calldata order,
        bytes calldata signature,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        bytes calldata permit
    ) external payable {
        address userAddress = address(uint160(order.nonceAndMeta));
        require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");

        uint256 fromAmount = order.takerAmount;
        address fromToken = address(uint160(order.takerAsset));
        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            Utils.permit(fromToken, permit);
            tokenTransferProxy.transferFrom(fromToken, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, fromToken, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).fillOrderNFT(order, signature);
            uint256 receivedAmount = Utils.tokenBalance(address(uint160(order.makerAsset)), address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).fillOrderWithTargetNFT(order, signature, msg.sender);
        }
    }

    function partialSwapOnAugustusRFQ(
        IAugustusRFQ.Order calldata order,
        bytes calldata signature,
        bytes calldata makerPermit,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        uint256 fromAmount
    ) external payable {
        address userAddress = address(uint160(order.nonceAndMeta));
        require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");

        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            tokenTransferProxy.transferFrom(order.takerAsset, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, order.takerAsset, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).partialFillOrderWithTargetPermit(
                order,
                signature,
                fromAmount,
                address(this),
                bytes(""),
                makerPermit
            );
            uint256 receivedAmount = Utils.tokenBalance(order.makerAsset, address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).partialFillOrderWithTargetPermit(
                order,
                signature,
                fromAmount,
                msg.sender,
                bytes(""),
                makerPermit
            );
        }
    }

    function partialSwapOnAugustusRFQWithPermit(
        IAugustusRFQ.Order calldata order,
        bytes calldata signature,
        bytes calldata makerPermit,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        uint256 fromAmount,
        bytes calldata permit
    ) external payable {
        address userAddress = address(uint160(order.nonceAndMeta));
        require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");

        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            Utils.permit(order.takerAsset, permit);
            tokenTransferProxy.transferFrom(order.takerAsset, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, order.takerAsset, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).partialFillOrderWithTargetPermit(
                order,
                signature,
                fromAmount,
                address(this),
                bytes(""),
                makerPermit
            );
            uint256 receivedAmount = Utils.tokenBalance(order.makerAsset, address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).partialFillOrderWithTargetPermit(
                order,
                signature,
                fromAmount,
                msg.sender,
                bytes(""),
                makerPermit
            );
        }
    }

    function partialSwapOnAugustusRFQNFT(
        IAugustusRFQ.OrderNFT calldata order,
        bytes calldata signature,
        bytes calldata makerPermit,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        uint256 fromAmount
    ) external payable {
        address userAddress = address(uint160(order.nonceAndMeta));
        require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");

        address fromToken = address(uint160(order.takerAsset));
        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            tokenTransferProxy.transferFrom(fromToken, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, fromToken, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).partialFillOrderWithTargetPermitNFT(
                order,
                signature,
                fromAmount,
                address(this),
                bytes(""),
                makerPermit
            );
            uint256 receivedAmount = Utils.tokenBalance(address(uint160(order.makerAsset)), address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).partialFillOrderWithTargetPermitNFT(
                order,
                signature,
                fromAmount,
                msg.sender,
                bytes(""),
                makerPermit
            );
        }
    }

    function partialSwapOnAugustusRFQNFTWithPermit(
        IAugustusRFQ.OrderNFT calldata order,
        bytes calldata signature,
        bytes calldata makerPermit,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        uint256 fromAmount,
        bytes calldata permit
    ) external payable {
        address userAddress = address(uint160(order.nonceAndMeta));
        require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");

        address fromToken = address(uint160(order.takerAsset));
        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            Utils.permit(fromToken, permit);
            tokenTransferProxy.transferFrom(fromToken, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, fromToken, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).partialFillOrderWithTargetPermitNFT(
                order,
                signature,
                fromAmount,
                address(this),
                bytes(""),
                makerPermit
            );
            uint256 receivedAmount = Utils.tokenBalance(address(uint160(order.makerAsset)), address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).partialFillOrderWithTargetPermitNFT(
                order,
                signature,
                fromAmount,
                msg.sender,
                bytes(""),
                makerPermit
            );
        }
    }

    function swapOnAugustusRFQTryBatchFill(
        IAugustusRFQ.OrderInfo[] calldata orderInfos,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        uint256 fromAmount,
        uint256 toAmountMin
    ) external payable {
        uint256 orderCount = orderInfos.length;
        require(orderCount > 0, "missing orderInfos");
        for (uint256 i = 0; i < orderCount; ++i) {
            address userAddress = address(uint160(orderInfos[i].order.nonceAndMeta));
            require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");
        }

        address fromToken = orderInfos[0].order.takerAsset;
        address toToken = orderInfos[0].order.makerAsset;

        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            tokenTransferProxy.transferFrom(fromToken, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, fromToken, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).tryBatchFillOrderTakerAmount(orderInfos, fromAmount, address(this));
            uint256 receivedAmount = Utils.tokenBalance(toToken, address(this));
            require(receivedAmount >= toAmountMin, "Received amount of tokens are less then expected");
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            uint256 startBalance = Utils.tokenBalance(toToken, msg.sender);
            IAugustusRFQ(exchange).tryBatchFillOrderTakerAmount(orderInfos, fromAmount, msg.sender);
            uint256 receivedAmount = Utils.tokenBalance(toToken, msg.sender).sub(startBalance);
            require(receivedAmount >= toAmountMin, "Received amount of tokens are less then expected");
        }
    }

    function swapOnAugustusRFQTryBatchFillWithPermit(
        IAugustusRFQ.OrderInfo[] calldata orderInfos,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        uint256 fromAmount,
        uint256 toAmountMin,
        bytes calldata permit
    ) external payable {
        uint256 orderCount = orderInfos.length;
        require(orderCount > 0, "missing orderInfos");
        for (uint256 i = 0; i < orderCount; ++i) {
            address userAddress = address(uint160(orderInfos[i].order.nonceAndMeta));
            require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");
        }

        address fromToken = orderInfos[0].order.takerAsset;
        address toToken = orderInfos[0].order.makerAsset;

        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmount, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            Utils.permit(fromToken, permit);
            tokenTransferProxy.transferFrom(fromToken, msg.sender, address(this), fromAmount);
        }
        Utils.approve(exchange, fromToken, fromAmount);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).tryBatchFillOrderTakerAmount(orderInfos, fromAmount, address(this));
            uint256 receivedAmount = Utils.tokenBalance(toToken, address(this));
            require(receivedAmount >= toAmountMin, "Received amount of tokens are less then expected");
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            uint256 startBalance = Utils.tokenBalance(toToken, msg.sender);
            IAugustusRFQ(exchange).tryBatchFillOrderTakerAmount(orderInfos, fromAmount, msg.sender);
            uint256 receivedAmount = Utils.tokenBalance(toToken, msg.sender).sub(startBalance);
            require(receivedAmount >= toAmountMin, "Received amount of tokens are less then expected");
        }
    }

    function buyOnAugustusRFQTryBatchFill(
        IAugustusRFQ.OrderInfo[] calldata orderInfos,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        uint256 fromAmountMax,
        uint256 toAmount
    ) external payable {
        uint256 orderCount = orderInfos.length;
        require(orderCount > 0, "missing orderInfos");
        for (uint256 i = 0; i < orderCount; ++i) {
            address userAddress = address(uint160(orderInfos[i].order.nonceAndMeta));
            require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");
        }

        address fromToken = orderInfos[0].order.takerAsset;

        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmountMax, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmountMax }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            tokenTransferProxy.transferFrom(fromToken, msg.sender, address(this), fromAmountMax);
        }
        Utils.approve(exchange, fromToken, fromAmountMax);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).tryBatchFillOrderMakerAmount(orderInfos, toAmount, address(this));
            uint256 receivedAmount = Utils.tokenBalance(orderInfos[0].order.makerAsset, address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).tryBatchFillOrderMakerAmount(orderInfos, toAmount, msg.sender);
        }

        if (wrapETH & 1 != 0) {
            uint256 remainingAmount = Utils.tokenBalance(weth, address(this));
            if (remainingAmount > 0) {
                IWETH(weth).withdraw(remainingAmount);
                Utils.transferETH(msg.sender, remainingAmount);
            }
        } else {
            uint256 remainingAmount = Utils.tokenBalance(fromToken, address(this));
            Utils.transferTokens(fromToken, msg.sender, remainingAmount);
        }
    }

    function buyOnAugustusRFQTryBatchFillWithPermit(
        IAugustusRFQ.OrderInfo[] calldata orderInfos,
        uint8 wrapETH, // set 0 bit to wrap src, and 1 bit to wrap dst
        uint256 fromAmountMax,
        uint256 toAmount,
        bytes calldata permit
    ) external payable {
        uint256 orderCount = orderInfos.length;
        require(orderCount > 0, "missing orderInfos");
        for (uint256 i = 0; i < orderCount; ++i) {
            address userAddress = address(uint160(orderInfos[i].order.nonceAndMeta));
            require(userAddress == address(0) || userAddress == msg.sender, "unauthorized user");
        }

        address fromToken = orderInfos[0].order.takerAsset;

        if (wrapETH & 1 != 0) {
            require(msg.value == fromAmountMax, "Incorrect msg.value");
            IWETH(weth).deposit{ value: fromAmountMax }();
        } else {
            require(msg.value == 0, "Incorrect msg.value");
            Utils.permit(fromToken, permit);
            tokenTransferProxy.transferFrom(fromToken, msg.sender, address(this), fromAmountMax);
        }
        Utils.approve(exchange, fromToken, fromAmountMax);

        if (wrapETH & 2 != 0) {
            IAugustusRFQ(exchange).tryBatchFillOrderMakerAmount(orderInfos, toAmount, address(this));
            uint256 receivedAmount = Utils.tokenBalance(orderInfos[0].order.makerAsset, address(this));
            IWETH(weth).withdraw(receivedAmount);
            Utils.transferETH(msg.sender, receivedAmount);
        } else {
            IAugustusRFQ(exchange).tryBatchFillOrderMakerAmount(orderInfos, toAmount, msg.sender);
        }

        if (wrapETH & 1 != 0) {
            uint256 remainingAmount = Utils.tokenBalance(weth, address(this));
            if (remainingAmount > 0) {
                IWETH(weth).withdraw(remainingAmount);
                Utils.transferETH(msg.sender, remainingAmount);
            }
        } else {
            uint256 remainingAmount = Utils.tokenBalance(fromToken, address(this));
            Utils.transferTokens(fromToken, msg.sender, remainingAmount);
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "./ITokenTransferProxy.sol";

contract AugustusStorage {
    struct FeeStructure {
        uint256 partnerShare;
        bool noPositiveSlippage;
        bool positiveSlippageToUser;
        uint16 feePercent;
        string partnerId;
        bytes data;
    }

    ITokenTransferProxy internal tokenTransferProxy;
    address payable internal feeWallet;

    mapping(address => FeeStructure) internal registeredPartners;

    mapping(bytes4 => address) internal selectorVsRouter;
    mapping(bytes32 => bool) internal adapterInitialized;
    mapping(bytes32 => bytes) internal adapterVsData;

    mapping(bytes32 => bytes) internal routerData;
    mapping(bytes32 => bool) internal routerInitialized;

    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");

    bytes32 public constant ROUTER_ROLE = keccak256("ROUTER_ROLE");
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IRouter {
    /**
     * @dev Certain routers/exchanges needs to be initialized.
     * This method will be called from Augustus
     */
    function initialize(bytes calldata data) external;

    /**
     * @dev Returns unique identifier for the router
     */
    function getKey() external pure returns (bytes32);

    event SwappedV3(
        bytes16 uuid,
        address partner,
        uint256 feePercent,
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount,
        uint256 expectedAmount
    );

    event BoughtV3(
        bytes16 uuid,
        address partner,
        uint256 feePercent,
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount,
        uint256 expectedAmount
    );
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IWETH is IERC20 {
    function deposit() external payable virtual;

    function withdraw(uint256 amount) external virtual;
}

/*solhint-disable avoid-low-level-calls */
// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../ITokenTransferProxy.sol";

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IERC20PermitLegacy {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

library Utils {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    uint256 private constant MAX_UINT = type(uint256).max;

    /**
   * @param fromToken Address of the source token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param expectedAmount Expected amount of destination tokens without slippage
   * @param beneficiary Beneficiary address
   * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
   * @param path Route to be taken for this swap to take place

   */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct BuyData {
        address adapter;
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Route[] route;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.MegaSwapPath[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct Adapter {
        address payable adapter;
        uint256 percent;
        uint256 networkFee; //NOT USED
        Route[] route;
    }

    struct Route {
        uint256 index; //Adapter at which index needs to be used
        address targetExchange;
        uint256 percent;
        bytes payload;
        uint256 networkFee; //NOT USED - Network fee is associated with 0xv3 trades
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee; //NOT USED - Network fee is associated with 0xv3 trades
        Adapter[] adapters;
    }

    function ethAddress() internal pure returns (address) {
        return ETH_ADDRESS;
    }

    function maxUint() internal pure returns (uint256) {
        return MAX_UINT;
    }

    function approve(
        address addressToApprove,
        address token,
        uint256 amount
    ) internal {
        if (token != ETH_ADDRESS) {
            IERC20 _token = IERC20(token);

            uint256 allowance = _token.allowance(address(this), addressToApprove);

            if (allowance < amount) {
                _token.safeApprove(addressToApprove, 0);
                _token.safeIncreaseAllowance(addressToApprove, MAX_UINT);
            }
        }
    }

    function transferTokens(
        address token,
        address payable destination,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (token == ETH_ADDRESS) {
                (bool result, ) = destination.call{ value: amount, gas: 10000 }("");
                require(result, "Failed to transfer Ether");
            } else {
                IERC20(token).safeTransfer(destination, amount);
            }
        }
    }

    function tokenBalance(address token, address account) internal view returns (uint256) {
        if (token == ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    function permit(address token, bytes memory permit) internal {
        if (permit.length == 32 * 7) {
            (bool success, ) = token.call(abi.encodePacked(IERC20Permit.permit.selector, permit));
            require(success, "Permit failed");
        }

        if (permit.length == 32 * 8) {
            (bool success, ) = token.call(abi.encodePacked(IERC20PermitLegacy.permit.selector, permit));
            require(success, "Permit failed");
        }
    }

    function transferETH(address payable destination, uint256 amount) internal {
        if (amount > 0) {
            (bool result, ) = destination.call{ value: amount, gas: 10000 }("");
            require(result, "Transfer ETH failed");
        }
    }
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

interface IAugustusRFQ {
    struct Order {
        uint256 nonceAndMeta; // first 160 bits is user address and then nonce
        uint128 expiry;
        address makerAsset;
        address takerAsset;
        address maker;
        address taker; // zero address on orders executable by anyone
        uint256 makerAmount;
        uint256 takerAmount;
    }

    // makerAsset and takerAsset are Packed structures
    // 0 - 159 bits are address
    // 160 - 161 bits are tokenType (0 ERC20, 1 ERC1155, 2 ERC721)
    struct OrderNFT {
        uint256 nonceAndMeta; // first 160 bits is user address and then nonce
        uint128 expiry;
        uint256 makerAsset;
        uint256 makerAssetId; // simply ignored in case of ERC20s
        uint256 takerAsset;
        uint256 takerAssetId; // simply ignored in case of ERC20s
        address maker;
        address taker; // zero address on orders executable by anyone
        uint256 makerAmount;
        uint256 takerAmount;
    }

    struct OrderInfo {
        Order order;
        bytes signature;
        uint256 takerTokenFillAmount;
        bytes permitTakerAsset;
        bytes permitMakerAsset;
    }

    struct OrderNFTInfo {
        OrderNFT order;
        bytes signature;
        uint256 takerTokenFillAmount;
        bytes permitTakerAsset;
        bytes permitMakerAsset;
    }

    /**
     @dev Allows taker to fill complete RFQ order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
    */
    function fillOrder(Order calldata order, bytes calldata signature) external;

    /**
     @dev Allows taker to fill Limit order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
    */
    function fillOrderNFT(OrderNFT calldata order, bytes calldata signature) external;

    /**
     @dev Same as fillOrder but allows sender to specify the target
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param target Address of the receiver
    */
    function fillOrderWithTarget(
        Order calldata order,
        bytes calldata signature,
        address target
    ) external;

    /**
     @dev Same as fillOrderNFT but allows sender to specify the target
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param target Address of the receiver
    */
    function fillOrderWithTargetNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        address target
    ) external;

    /**
     @dev Allows taker to partially fill an order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
    */
    function partialFillOrder(
        Order calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Allows taker to partially fill an NFT order
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
    */
    function partialFillOrderNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Same as `partialFillOrder` but it allows to specify the destination address
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
    */
    function partialFillOrderWithTarget(
        Order calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Same as `partialFillOrderWithTarget` but it allows to pass permit
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
     @param permitTakerAsset Permit calldata for taker
     @param permitMakerAsset Permit calldata for maker
    */
    function partialFillOrderWithTargetPermit(
        Order calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target,
        bytes calldata permitTakerAsset,
        bytes calldata permitMakerAsset
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Same as `partialFillOrderNFT` but it allows to specify the destination address
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
    */
    function partialFillOrderWithTargetNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Same as `partialFillOrderWithTargetNFT` but it allows to pass token permits
     @param order Order quote to fill
     @param signature Signature of the maker corresponding to the order
     @param takerTokenFillAmount Maximum taker token to fill this order with.
     @param target Address that will receive swap funds
     @param permitTakerAsset Permit calldata for taker
     @param permitMakerAsset Permit calldata for maker
    */
    function partialFillOrderWithTargetPermitNFT(
        OrderNFT calldata order,
        bytes calldata signature,
        uint256 takerTokenFillAmount,
        address target,
        bytes calldata permitTakerAsset,
        bytes calldata permitMakerAsset
    ) external returns (uint256 makerTokenFilledAmount);

    /**
     @dev Partial fill multiple orders
     @param orderInfos OrderInfo to fill
     @param target Address of receiver
    */
    function batchFillOrderWithTarget(OrderInfo[] calldata orderInfos, address target) external;

    /**
     @dev batch fills orders until the takerFillAmount is swapped
     @dev skip the order if it fails
     @param orderInfos OrderInfo to fill
     @param takerFillAmount total taker amount to fill
     @param target Address of receiver
    */
    function tryBatchFillOrderTakerAmount(
        OrderInfo[] calldata orderInfos,
        uint256 takerFillAmount,
        address target
    ) external;

    /**
     @dev batch fills orders until the makerFillAmount is swapped
     @dev skip the order if it fails
     @param orderInfos OrderInfo to fill
     @param makerFillAmount total maker amount to fill
     @param target Address of receiver
    */
    function tryBatchFillOrderMakerAmount(
        OrderInfo[] calldata orderInfos,
        uint256 makerFillAmount,
        address target
    ) external;

    /**
     @dev Partial fill multiple NFT orders
     @param orderInfos Info about each order to fill
     @param target Address of receiver
    */
    function batchFillOrderWithTargetNFT(OrderNFTInfo[] calldata orderInfos, address target) external;
}

// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface ITokenTransferProxy {
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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