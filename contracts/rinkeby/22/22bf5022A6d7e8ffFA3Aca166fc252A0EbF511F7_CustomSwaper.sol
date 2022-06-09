// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;


import "./interfaces/IERC20.sol";
import "./interfaces/IAugustusSwapper.sol";
import "./interfaces/ITokenTransferProxy.sol";

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CustomSwaper /* is Ownable */ {
    
    address public owner;
    address constant public PSAugustus = 0x1bD435F3C054b6e901B7b108a0ab7617C808677b;
    address constant public PSTokenTransferProxy = 0xb70Bc06D2c9Bf03b3373799606dc7d39346c06B3;

    constructor() {
        owner = msg.sender;
    }

    /** 
    * @param swapMethodName Use to determine which function of PSAugustus is called
    */

    function swapViaPS(string memory swapMethodName, uint256 amountIn, uint256 amountOutMin, address[] memory path) public {
        require(path.length >= 2, 'swapViaPS : path.length >= 2');
        require(keccak256(bytes(swapMethodName)) == keccak256(bytes("UniswapV2")), "swapViaPS: unknow/unhandled swapMethod");
        require(IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn), "swapViaPS : transferFrom");
        require(IERC20(path[0]).approve(PSTokenTransferProxy, amountIn), "swapViaPS: approve");
        IAugustusSwapper(PSAugustus).swapOnUniswap(amountIn, amountOutMin, path, 1);
        uint256 received = IERC20(path[path.length - 1]).balanceOf(address(this));
        IERC20(path[path.length - 1]).transfer(msg.sender, received);
    }

    function dispatchPSBuildTx(address _tokenFrom, uint256 _amountIn, bytes memory _data) public returns (bool) {
        require(IERC20(_tokenFrom).transferFrom(msg.sender, address(this), _amountIn), "dispatchPSBuildTx : transferFrom");
        require(IERC20(_tokenFrom).approve(PSTokenTransferProxy, _amountIn), "dispatchPSBuildTx: approve");
        (bool success,) = PSAugustus.call(_data);
        // (bool success,) = address(PSAugustus).call(_data);
        return success;
    }
    
}

/**
 * https://www.reddit.com/r/ethdev/comments/74yepn/is_this_possible_using_solidity/
 * https://ethereum.stackexchange.com/questions/80106/function-to-execute-raw-bytecode-in-evm  --> This is the solution I guess
 * https://github.com/ColonelJ/aave-protocol-v2/blob/14e2ab47d95f42ec5ee486f367067e78a7588878/contracts/adapters/BaseParaSwapSellAdapter.sol
 */

/*
 * simpleSwap : 0xcfc0afeb
 * megaSwap : ec1d21dd
 * 
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.8.4;

interface ITokenTransferProxy {
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;

    function freeReduxTokens(address user, uint256 tokensToFree) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.8.4;
pragma experimental ABIEncoderV2;

interface IAugustusSwapper {
    /**
   * @param fromToken Address of the source token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param expectedAmount Expected amount of destination tokens without slippage
   * @param beneficiary Beneficiary address
   * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
   * @param referrer referral id
   * @param useReduxToken whether to use redux token or not
   * @param path Route to be taken for this swap to take place

   */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        string referrer;
        bool useReduxToken;
        Path[] path;
    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        string referrer;
        bool useReduxToken;
        MegaSwapPath[] path;
    }

    struct BuyData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        address payable beneficiary;
        string referrer;
        bool useReduxToken;
        BuyRoute[] route;
    }

    struct Route {
        address payable exchange;
        address targetExchange;
        uint256 percent;
        bytes payload;
        uint256 networkFee; //Network fee is associated with 0xv3 trades
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee; //Network fee is associated with 0xv3 trades
        Route[] routes;
    }

    struct BuyRoute {
        address payable exchange;
        address targetExchange;
        uint256 fromAmount;
        uint256 toAmount;
        bytes payload;
        uint256 networkFee; //Network fee is associated with 0xv3 trades
    }

    function getPartnerRegistry() external view returns (address);

    function getWhitelistAddress() external view returns (address);

    function getFeeWallet() external view returns (address);

    function getTokenTransferProxy() external view returns (address);

    function getUniswapProxy() external view returns (address);

    function getVersion() external view returns (string memory);

    /**
     * @dev The function which performs the multi path swap.
     */
    function multiSwap(SellData calldata data)
        external
        payable
        returns (uint256);

    /**
     * @dev The function which performs the single path buy.
     */
    function buy(BuyData calldata data) external payable returns (uint256);

    function swapOnUniswap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint8 referrer
    ) external payable;

    function buyOnUniswap(
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path,
        uint8 referrer
    ) external payable;

    function buyOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path,
        uint8 referrer
    ) external payable;

    function swapOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint8 referrer
    ) external payable;

    function simplBuy(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address[] memory callees,
        bytes memory exchangeData,
        uint256[] memory startIndexes,
        uint256[] memory values,
        address payable beneficiary,
        string memory referrer,
        bool useReduxToken
    ) external payable;

    function simpleSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 expectedAmount,
        address[] memory callees,
        bytes memory exchangeData,
        uint256[] memory startIndexes,
        uint256[] memory values,
        address payable beneficiary,
        string memory referrer,
        bool useReduxToken
    ) external payable returns (uint256 receivedAmount);

    /**
     * @dev The function which performs the mega path swap.
     * @param data Data required to perform swap.
     */
    function megaSwap(MegaSwapSellData memory data)
        external
        payable
        returns (uint256);
}