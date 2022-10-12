// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.11;

import "../interfaces/IToken.sol";
import "../interfaces/IRouter.sol";

contract StarGate {
    IStargateRouter public immutable router;
    uint8 constant TYPE_SWAP_REMOTE = 1;
    uint16 public immutable chainId;

    event ReceivedOnDestination(address token, address to, uint256 amount, uint16 srcChainId, uint16 dstChainId);

    constructor(IStargateRouter _router, uint16 _chainId) {
        router = _router;
        chainId = _chainId;
    }

    function getSwapFee(
        uint16 dstChainId,
        bytes calldata toAddress,
        IStargateRouter.lzTxObj memory lzTxParams
    ) external view returns (uint256, uint256) {
        return
            router.quoteLayerZeroFee(
                dstChainId,
                TYPE_SWAP_REMOTE, /* for Swap */
                toAddress,
                "",
                lzTxParams
            );
    }

    function processSwap(
        uint256 qty,
        address bridgeToken,
        uint16 dstChainId,
        uint256 srcPoolId,
        uint256 dstPoolId,
        address to,
        address dstStargateComposed
    ) external payable {
        bytes memory data = abi.encode(to, chainId, dstChainId, srcPoolId, dstPoolId);

        IERC20(bridgeToken).transferFrom(msg.sender, address(this), qty);
        IERC20(bridgeToken).approve(address(router), qty);

        router.swap{ value: msg.value }(
            dstChainId,
            srcPoolId,
            dstPoolId,
            payable(msg.sender),
            qty,
            0,
            IStargateRouter.lzTxObj(200000, 0, "0x"),
            abi.encodePacked(dstStargateComposed),
            data
        );
    }

    function processReceive(
        address _token, // the token contract on the local chain
        uint256 amountLD, // the qty of local _token contract tokens
        bytes memory _payload
    ) external {
        require(msg.sender == address(router), "only stargate router can call sgReceive!");
        (address _toAddr, uint16 srcChainId, uint16 dstChainId, , ) = abi.decode(
            _payload,
            (address, uint16, uint16, uint256, uint256)
        );

        IERC20(_token).approve(_toAddr, amountLD);
        IERC20(_token).transfer(_toAddr, amountLD);

        emit ReceivedOnDestination(_token, _toAddr, amountLD, srcChainId, dstChainId);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.11;

interface IERC20 {
    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address _to, uint256 _amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.11;

interface ISwapRouter {
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

    /// @notice Swaps amountIn of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as ExactInputSingleParams in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps amountIn of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as ExactInputParams in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

interface IPancakeRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

interface IstargateReceiver {
    function sgReceive(
        uint16 _srcChainId, // the remote chainId sending the tokens
        bytes memory _srcAddress, // the remote Bridge address
        uint256 _nonce,
        address _token, // the token contract on the local chain
        uint256 amountLD, // the qty of local _token contract tokens
        bytes memory payload
    ) external;
}