// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IUniswapV2Factory } from "../core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "../core/interfaces/IUniswapV2Pair.sol";
import { IERC721 } from "../core/interfaces/IERC721.sol";
import { IWERC721 } from "../core/interfaces/IWERC721.sol";
import { TransferHelper } from "../lib/libraries/TransferHelper.sol";

import { IUniswapV2Router01Collection } from "./interfaces/IUniswapV2Router01Collection.sol";
import { UniswapV2Router01 } from "./UniswapV2Router01.sol";
import { UniswapV2Library } from "./libraries/UniswapV2Library.sol";
import { RoyaltyHelper } from "./libraries/RoyaltyHelper.sol";
import { IWETH } from "./interfaces/IWETH.sol";

contract UniswapV2Router01Collection is IUniswapV2Router01Collection, UniswapV2Router01 {
    address public override marketplaceAdmin;
    address public override marketplaceWallet;
    uint public override marketplaceFee;
    mapping(address => uint) public override royaltyFeeCap;

    constructor(address _factory, address _WETH, address _marketplaceAdmin, address _marketplaceWallet, uint _marketplaceFee) UniswapV2Router01(_factory, _WETH) {
        marketplaceAdmin = _marketplaceAdmin;
        marketplaceWallet = _marketplaceWallet;
        marketplaceFee = _marketplaceFee;
    }

    function updateAdmin(address _marketplaceAdmin) external
    {
        require(msg.sender == marketplaceAdmin, "SweepnFlipRouter: FORBIDDEN");
        marketplaceAdmin = _marketplaceAdmin;
        emit UpdateAdmin(_marketplaceAdmin);
    }

    function updateFeeConfig(address _marketplaceWallet, uint _marketplaceFee) external
    {
        require(msg.sender == marketplaceAdmin, "SweepnFlipRouter: FORBIDDEN");
        require(_marketplaceFee <= 100e16, "SweepnFlipRouter: INVALID_FEE");
        marketplaceWallet = _marketplaceWallet;
        marketplaceFee = _marketplaceFee;
        emit UpdateFeeConfig(_marketplaceWallet, _marketplaceFee);
    }

    function updateRoyaltyFeeCap(address collection, uint _royaltyFeeCap) external
    {
        require(msg.sender == marketplaceAdmin || msg.sender == collection, "SweepnFlipRouter: FORBIDDEN");
        require(_royaltyFeeCap <= 100e16, "SweepnFlipRouter: INVALID_FEE");
        royaltyFeeCap[collection] = _royaltyFeeCap;
        emit UpdateRoyaltyFeeCap(collection, _royaltyFeeCap);
    }

    function _getWrapper(address collection) internal returns (address wrapper) {
        wrapper = IUniswapV2Factory(factory).getWrapper(collection);
        if (wrapper == address(0)) {
            wrapper = IUniswapV2Factory(factory).createWrapper(collection);
        }
        if (!IERC721(collection).isApprovedForAll(address(this), wrapper)) {
            IERC721(collection).setApprovalForAll(wrapper, true);
        }
    }

    function _mint(address wrapper, address to, uint[] memory tokenIds) internal {
        address collection = IWERC721(wrapper).collection();
        for (uint i = 0; i < tokenIds.length; i++) {
            IERC721(collection).transferFrom(msg.sender, address(this), tokenIds[i]);
        }
        IWERC721(wrapper).mint(to, tokenIds);
    }

    // **** ADD LIQUIDITY ****
    function addLiquidityCollection(
        address tokenA,
        address collectionB,
        uint amountADesired,
        uint[] memory tokenIdsB,
        uint amountAMin,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        address wrapperB = _getWrapper(collectionB);
        uint amountBMin = tokenIdsB.length * 1e18;
        (amountA, amountB) = _addLiquidity(
            tokenA,
            wrapperB,
            amountADesired,
            amountBMin,
            amountAMin,
            amountBMin
        );
        address pair = UniswapV2Library.pairFor(factory, tokenA, wrapperB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        _mint(wrapperB, pair, tokenIdsB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }
    function addLiquidityETHCollection(
        address collection,
        uint[] memory tokenIds,
        uint amountETHMin,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        address wrapper = _getWrapper(collection);
        uint amountTokenMin = tokenIds.length * 1e18;
        (amountToken, amountETH) = _addLiquidity(
            wrapper,
            WETH,
            amountTokenMin,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, wrapper, WETH);
        _mint(wrapper, pair, tokenIds);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(to);
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH); // refund dust eth, if any
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidityCollection(
        address tokenA,
        address collectionB,
        uint liquidity,
        uint[] memory tokenIdsB,
        uint amountAMin,
        address to,
        uint deadline
    ) public override ensure(deadline) returns (uint amountA, uint amountB) {
        address wrapperB = _getWrapper(collectionB);
        uint amountBMin = tokenIdsB.length * 1e18;
        (amountA, amountB) = removeLiquidity(
            tokenA,
            wrapperB,
            liquidity,
            amountAMin,
            amountBMin,
            address(this),
            deadline
        );
        require(amountB == amountBMin, "SweepnFlipRouter: EXCESSIVE_B_AMOUNT");
        TransferHelper.safeTransfer(tokenA, to, amountA);
        IWERC721(wrapperB).burn(to, tokenIdsB);
    }
    function removeLiquidityETHCollection(
        address collection,
        uint liquidity,
        uint[] memory tokenIds,
        uint amountETHMin,
        address to,
        uint deadline
    ) public override ensure(deadline) returns (uint amountToken, uint amountETH) {
        address wrapper = _getWrapper(collection);
        uint amountTokenMin = tokenIds.length * 1e18;
        (amountToken, amountETH) = removeLiquidity(
            wrapper,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        require(amountToken == amountTokenMin, "SweepnFlipRouter: EXCESSIVE_A_AMOUNT");
        IWERC721(wrapper).burn(to, tokenIds);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
/*
    function removeLiquidityWithPermitCollection(
        address tokenA,
        address collectionB,
        uint liquidity,
        uint[] memory tokenIdsB,
        uint amountAMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountA, uint amountB) {
        address wrapperB = _getWrapper(collectionB);
        address pair = UniswapV2Library.pairFor(factory, tokenA, wrapperB);
        uint value = approveMax ? type(uint).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidityCollection(tokenA, collectionB, liquidity, tokenIdsB, amountAMin, to, deadline);
    }
    function removeLiquidityETHWithPermitCollection(
        address collection,
        uint liquidity,
        uint[] memory tokenIds,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountToken, uint amountETH) {
        address wrapper = _getWrapper(collection);
        address pair = UniswapV2Library.pairFor(factory, wrapper, WETH);
        uint value = approveMax ? type(uint).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETHCollection(collection, liquidity, tokenIds, amountETHMin, to, deadline);
    }
*/
    // **** SWAP ****
    function swapExactTokensForTokensCollection(
        uint[] memory tokenIdsIn,
        uint amountOutMin,
        address[] memory path,
        bool capRoyaltyFee,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        address collection = path[0];
        path[0] = _getWrapper(collection);
        amounts = UniswapV2Library.getAmountsOut(factory, tokenIdsIn.length * 1e18, path);
        uint amountOut = amounts[amounts.length - 1];
        (address[] memory royaltyReceivers, uint[] memory royaltyAmounts, uint totalRoyaltyAmount) = RoyaltyHelper.getRoyaltyInfo(collection, tokenIdsIn, amountOut, marketplaceWallet, marketplaceFee, capRoyaltyFee ? royaltyFeeCap[collection] : 100e16);
        _mint(path[0], UniswapV2Library.pairFor(factory, path[0], path[1]), tokenIdsIn);
        uint netAmountOut = amountOut - totalRoyaltyAmount;
        require(netAmountOut >= amountOutMin, "SweepnFlipRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        if (totalRoyaltyAmount == 0) {
            _swap(amounts, path, to);
        } else {
            _swap(amounts, path, address(this));
            address tokenOut = path[path.length - 1];
            TransferHelper.safeTransfer(tokenOut, to, netAmountOut);
            TransferHelper.safeTransferBatch(tokenOut, royaltyReceivers, royaltyAmounts);
        }
    }
    function swapTokensForExactTokensCollection(
        uint[] memory tokenIdsOut,
        uint amountInMax,
        address[] memory path,
        bool capRoyaltyFee,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        address collection = path[path.length - 1];
        path[path.length - 1] = _getWrapper(collection);
        amounts = UniswapV2Library.getAmountsIn(factory, tokenIdsOut.length * 1e18, path);
        uint amountIn = amounts[0];
        (address[] memory royaltyReceivers, uint[] memory royaltyAmounts, uint totalRoyaltyAmount) = RoyaltyHelper.getRoyaltyInfo(collection, tokenIdsOut, amountIn, marketplaceWallet, marketplaceFee, capRoyaltyFee ? royaltyFeeCap[collection] : 100e16);
        require(amountIn + totalRoyaltyAmount <= amountInMax, "SweepnFlipRouter: EXCESSIVE_INPUT_AMOUNT");
        {
        address pair = UniswapV2Library.pairFor(factory, path[0], path[1]);
        TransferHelper.safeTransferFrom(path[0], msg.sender, pair, amountIn);
        }
        _swap(amounts, path, address(this));
        IWERC721(path[path.length - 1]).burn(to, tokenIdsOut);
        if (totalRoyaltyAmount > 0) {
            TransferHelper.safeTransferFromBatch(path[0], msg.sender, royaltyReceivers, royaltyAmounts);
        }
    }
    function swapExactTokensForETHCollection(uint[] memory tokenIdsIn, uint amountOutMin, address[] memory path, bool capRoyaltyFee, address to, uint deadline)
        external
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, "SweepnFlipRouter: INVALID_PATH");
        address collection = path[0];
        path[0] = _getWrapper(collection);
        amounts = UniswapV2Library.getAmountsOut(factory, tokenIdsIn.length * 1e18, path);
        uint amountOut = amounts[amounts.length - 1];
        (address[] memory royaltyReceivers, uint[] memory royaltyAmounts, uint totalRoyaltyAmount) = RoyaltyHelper.getRoyaltyInfo(collection, tokenIdsIn, amountOut, marketplaceWallet, marketplaceFee, capRoyaltyFee ? royaltyFeeCap[collection] : 100e16);
        _mint(path[0], UniswapV2Library.pairFor(factory, path[0], path[1]), tokenIdsIn);
        uint netAmountOut = amountOut - totalRoyaltyAmount;
        require(netAmountOut >= amountOutMin, "SweepnFlipRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, netAmountOut);
        if (totalRoyaltyAmount > 0) {
            TransferHelper.safeTransferETHBatch(royaltyReceivers, royaltyAmounts);
        }
    }
    function swapETHForExactTokensCollection(uint[] memory tokenIdsOut, address[] memory path, bool capRoyaltyFee, address to, uint deadline)
        external
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, "SweepnFlipRouter: INVALID_PATH");
        address collection = path[path.length - 1];
        path[path.length - 1] = _getWrapper(collection);
        amounts = UniswapV2Library.getAmountsIn(factory, tokenIdsOut.length * 1e18, path);
        uint amountIn = amounts[0];
        (address[] memory royaltyReceivers, uint[] memory royaltyAmounts, uint totalRoyaltyAmount) = RoyaltyHelper.getRoyaltyInfo(collection, tokenIdsOut, amountIn, marketplaceWallet, marketplaceFee, capRoyaltyFee ? royaltyFeeCap[collection] : 100e16);
        uint grossAmountIn = amountIn + totalRoyaltyAmount;
        require(grossAmountIn <= msg.value, "SweepnFlipRouter: EXCESSIVE_INPUT_AMOUNT");
        IWETH(WETH).deposit{value: amountIn}();
        {
        address pair = UniswapV2Library.pairFor(factory, path[0], path[1]);
        assert(IWETH(WETH).transfer(pair, amountIn));
        }
        _swap(amounts, path, address(this));
        IWERC721(path[path.length - 1]).burn(to, tokenIdsOut);
        if (totalRoyaltyAmount > 0) {
            TransferHelper.safeTransferETHBatch(royaltyReceivers, royaltyAmounts);
        }
        if (msg.value > grossAmountIn) TransferHelper.safeTransferETH(msg.sender, msg.value - grossAmountIn); // refund dust eth, if any
    }

    function getAmountsOutCollection(uint[] memory tokenIdsIn, address[] memory path, bool capRoyaltyFee) external view override returns (uint[] memory amounts)
    {
        address collection = path[0];
        path[0] = IUniswapV2Factory(factory).getWrapper(collection);
        amounts = UniswapV2Library.getAmountsOut(factory, tokenIdsIn.length * 1e18, path);
        uint amountOut = amounts[amounts.length - 1];
        (,,uint totalRoyaltyAmount) = RoyaltyHelper.getRoyaltyInfo(collection, tokenIdsIn, amountOut, marketplaceWallet, marketplaceFee, capRoyaltyFee ? royaltyFeeCap[collection] : 100e16);
        amounts[amounts.length - 1] = amountOut - totalRoyaltyAmount;
        return amounts;
    }

    function getAmountsInCollection(uint[] memory tokenIdsOut, address[] memory path, bool capRoyaltyFee) external view override returns (uint[] memory amounts)
    {
        address collection = path[path.length - 1];
        path[path.length - 1] = IUniswapV2Factory(factory).getWrapper(collection);
        amounts = UniswapV2Library.getAmountsIn(factory, tokenIdsOut.length * 1e18, path);
        uint amountIn = amounts[0];
        (,,uint totalRoyaltyAmount) = RoyaltyHelper.getRoyaltyInfo(collection, tokenIdsOut, amountIn, marketplaceWallet, marketplaceFee, capRoyaltyFee ? royaltyFeeCap[collection] : 100e16);
        amounts[0] = amountIn + totalRoyaltyAmount;
        return amounts;
    }

    event UpdateAdmin(address marketplaceAdmin);
    event UpdateFeeConfig(address marketplaceWallet, uint marketplaceFee);
    event UpdateRoyaltyFeeCap(address indexed collection, uint royaltyFeeCap);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

//address constant DELEGATE_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac; // SushiSwap (Ethereum mainnet)
address constant DELEGATE_FACTORY = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4; // SushiSwap (most but Ethereum mainnet)
bytes constant DELEGATE_INIT_CODE_HASH = hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303";
uint256 constant DELEGATE_NET_FEE = 9970;

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IERC721 {
    event Approval(address indexed owner, address indexed spender, uint indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed spender, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function approve(address spender, uint256 tokenId) external;
    function setApprovalForAll(address spender, bool approved) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IERC20 } from "./IERC20.sol";

interface IUniswapV2ERC20 is IERC20 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event WrapperCreated(address indexed collection, address wrapper, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function getCollection(address wrapper) external view returns (address collection);
    function getWrapper(address collection) external view returns (address wrapper);
    function allWrappers(uint) external view returns (address wrapper);
    function allWrappersLength() external view returns (uint);

    function delegates(address token0, address token1) external view returns (bool);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function createWrapper(address collection) external returns (address wrapper);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IUniswapV2ERC20 } from "./IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {
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

    function initialize(address, address, bool, bool) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IERC20 } from "./IERC20.sol";

interface IWERC721 is IERC20 {
    event Mint(address indexed from, address indexed to, uint[] tokenIds);
    event Burn(address indexed from, address indexed to, uint[] tokenIds);

    function factory() external view returns (address);
    function collection() external view returns (address);

    function mint(address to, uint[] memory tokenIds) external;
    function burn(address to, uint[] memory tokenIds) external;

    function initialize(address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }

    function safeTransferBatch(address token, address[] memory receivers, uint256[] memory amounts) internal {
        for (uint i = 0; i < receivers.length; i++) {
            uint amount = amounts[i];
            if (amount > 0) {
                safeTransfer(token, receivers[i], amount);
            }
        }
    }

    function safeTransferFromBatch(address token, address from, address[] memory receivers, uint256[] memory amounts) internal {
        for (uint i = 0; i < receivers.length; i++) {
            uint amount = amounts[i];
            if (amount > 0) {
                safeTransferFrom(token, from, receivers[i], amount);
            }
        }
    }

    function safeTransferETHBatch(address[] memory receivers, uint256[] memory amounts) internal {
        for (uint i = 0; i < receivers.length; i++) {
            uint amount = amounts[i];
            if (amount > 0) {
                safeTransferETH(receivers[i], amount);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IERC165 } from "./IERC165.sol";

interface IERC2981 is IERC165 {
    function royaltyInfo(uint tokenId, uint salePrice) external view returns (address receiver, uint royaltyAmount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IUniswapV2Router01 {
    function factory() external view returns (address);
    function WETH() external view returns (address);

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IUniswapV2Router01 } from "./IUniswapV2Router01.sol";

interface IUniswapV2Router01Collection is IUniswapV2Router01 {
    function marketplaceAdmin() external view returns (address _marketplaceAdmin);
    function marketplaceWallet() external view returns (address _marketplaceWallet);
    function marketplaceFee() external view returns (uint _marketplaceFee);
    function royaltyFeeCap(address collection) external view returns (uint _royaltyFeeCap);

    function addLiquidityCollection(
        address tokenA,
        address collectionB,
        uint amountADesired,
        uint[] memory tokenIdsB,
        uint amountAMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETHCollection(
        address collection,
        uint[] memory tokenIds,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidityCollection(
        address tokenA,
        address collectionB,
        uint liquidity,
        uint[] memory tokenIdsB,
        uint amountAMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHCollection(
        address collection,
        uint liquidity,
        uint[] memory tokenIds,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
/*
    function removeLiquidityWithPermitCollection(
        address tokenA,
        address collectionB,
        uint liquidity,
        uint[] memory tokenIdsB,
        uint amountAMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermitCollection(
        address collection,
        uint liquidity,
        uint[] memory tokenIds,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
*/
    function swapExactTokensForTokensCollection(
        uint[] memory tokenIdsIn,
        uint amountOutMin,
        address[] calldata path,
        bool capRoyaltyFee,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokensCollection(
        uint[] memory tokenIdsOut,
        uint amountInMax,
        address[] memory path,
        bool capRoyaltyFee,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForETHCollection(uint[] memory tokenIdsIn, uint amountOutMin, address[] calldata path, bool capRoyaltyFee, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokensCollection(uint[] memory tokenIdsOut, address[] memory path, bool capRoyaltyFee, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function getAmountsOutCollection(uint[] memory tokenIdsIn, address[] memory path, bool capRoyaltyFee) external view returns (uint[] memory amounts);
    function getAmountsInCollection(uint[] memory tokenIdsOut, address[] memory path, bool capRoyaltyFee) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IERC165 } from "../interfaces/IERC165.sol";
import { IERC2981 } from "../interfaces/IERC2981.sol";

library RoyaltyHelper {
    bytes4 constant IERC2981_INTERFACE_ID = 0x2a55205a;

    function getRoyaltyInfo(address collection, uint[] memory tokenIds, uint totalAmount, address marketplaceWallet, uint marketplaceFee, uint256 royaltyFeeCap) internal view returns (address[] memory royaltyReceivers, uint[] memory royaltyAmounts, uint totalRoyaltyAmount) {
        bool implementsIERC2981;
        try IERC165(collection).supportsInterface(IERC2981_INTERFACE_ID) returns (bool result) { implementsIERC2981 = result; } catch { implementsIERC2981 = false; }
        totalRoyaltyAmount = 0;
        if (!implementsIERC2981) {
            if (marketplaceFee > 0) {
                royaltyReceivers = new address[](1);
                royaltyAmounts = new uint[](1);
                (royaltyReceivers[0], royaltyAmounts[0]) = (marketplaceWallet, totalAmount * marketplaceFee / 100e16);
                totalRoyaltyAmount += royaltyAmounts[0];
            } else {
                royaltyReceivers = new address[](0);
                royaltyAmounts = new uint[](0);
            }
        } else {
            if (marketplaceFee > 0) {
                royaltyReceivers = new address[](tokenIds.length + 1);
                royaltyAmounts = new uint[](tokenIds.length + 1);
            } else {
                royaltyReceivers = new address[](tokenIds.length);
                royaltyAmounts = new uint[](tokenIds.length);
            }
            {
                uint salePrice = totalAmount / tokenIds.length;
                for (uint i = 0; i < tokenIds.length; i++) {
                    (royaltyReceivers[i], royaltyAmounts[i]) = IERC2981(collection).royaltyInfo(tokenIds[i], salePrice);
                    totalRoyaltyAmount += royaltyAmounts[i];
                }
            }
            {
                uint maxRoyaltyAmount = totalAmount * royaltyFeeCap / 100e16;
                if (totalRoyaltyAmount > maxRoyaltyAmount) {
                    uint256 _scale = 100e16 * maxRoyaltyAmount / totalRoyaltyAmount;
                    totalRoyaltyAmount = 0;
                    for (uint i = 0; i < tokenIds.length; i++) {
                        royaltyAmounts[i] = royaltyAmounts[i] * _scale / 100e16;
                        totalRoyaltyAmount += royaltyAmounts[i];
                    }
                }
            }
            if (marketplaceFee > 0) {
                (royaltyReceivers[tokenIds.length], royaltyAmounts[tokenIds.length]) = (marketplaceWallet, totalAmount * marketplaceFee / 100e16);
                totalRoyaltyAmount += royaltyAmounts[tokenIds.length];
            }
        }
        return (royaltyReceivers, royaltyAmounts, totalRoyaltyAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IUniswapV2Pair } from "../../core/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Factory } from "../../core/interfaces/IUniswapV2Factory.sol";
import { DELEGATE_FACTORY, DELEGATE_INIT_CODE_HASH, DELEGATE_NET_FEE } from "../../core/Delegation.sol";

library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "SweepnFlipLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "SweepnFlipLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal view returns (address pair) {
        (pair,) = pairForWithDelegates(factory, tokenA, tokenB);
    }
    function pairForWithDelegates(address factory, address tokenA, address tokenB) internal view returns (address pair, bool delegates) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        delegates = IUniswapV2Factory(factory).delegates(token0, token1);
        if (delegates) {
            pair = address(uint160(uint(keccak256(abi.encodePacked(
                    hex"ff",
                    DELEGATE_FACTORY,
                    keccak256(abi.encodePacked(token0, token1)),
                    DELEGATE_INIT_CODE_HASH
                )))));
        } else {
            pair = address(uint160(uint(keccak256(abi.encodePacked(
                    hex"ff",
                    factory,
                    keccak256(abi.encodePacked(token0, token1)),
                    hex"b85412b2be79318964695a23f77fc5af7b4e50bd7df8f21fb8fef9724a92a042" // init code hash
                )))));
        }
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (reserveA, reserveB,) = getReservesWithDelegates(factory, tokenA, tokenB);
    }
    function getReservesWithDelegates(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB, bool delegates) {
        (address token0,) = sortTokens(tokenA, tokenB);
        address pair;
        (pair, delegates) = pairForWithDelegates(factory, tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, "SweepnFlipLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "SweepnFlipLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = amountA * reserveB / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        return getAmountOut(amountIn, reserveIn, reserveOut, DELEGATE_NET_FEE);
    }
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint netFee) internal pure returns (uint amountOut) {
        require(amountIn > 0, "SweepnFlipLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SweepnFlipLibrary: INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn * netFee;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 10000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        return getAmountIn(amountOut, reserveIn, reserveOut, DELEGATE_NET_FEE);
    }
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint netFee) internal pure returns (uint amountIn) {
        require(amountOut > 0, "SweepnFlipLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SweepnFlipLibrary: INSUFFICIENT_LIQUIDITY");
        uint numerator = reserveIn * amountOut * 10000;
        uint denominator = (reserveOut - amountOut) * netFee;
        amountIn = numerator / denominator + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "SweepnFlipLibrary: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut, bool delegates) = getReservesWithDelegates(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, delegates ? DELEGATE_NET_FEE : 9900);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "SweepnFlipLibrary: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut, bool delegates) = getReservesWithDelegates(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, delegates ? DELEGATE_NET_FEE : 9900);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IUniswapV2Factory } from "../core/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "../core/interfaces/IUniswapV2Pair.sol";
import { IERC20 } from "../core/interfaces/IERC20.sol";
import { TransferHelper } from "../lib/libraries/TransferHelper.sol";

import { IUniswapV2Router01 } from "./interfaces/IUniswapV2Router01.sol";
import { UniswapV2Library } from "./libraries/UniswapV2Library.sol";
import { IWETH } from "./interfaces/IWETH.sol";

contract UniswapV2Router01 is IUniswapV2Router01 {
    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "SweepnFlipRouter: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "SweepnFlipRouter: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "SweepnFlipRouter: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(to);
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH); // refund dust eth, if any
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "SweepnFlipRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "SweepnFlipRouter: INSUFFICIENT_B_AMOUNT");
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        uint value = approveMax ? type(uint).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external override returns (uint amountToken, uint amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint value = approveMax ? type(uint).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "SweepnFlipRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "SweepnFlipRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, "SweepnFlipRouter: INVALID_PATH");
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "SweepnFlipRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, "SweepnFlipRouter: INVALID_PATH");
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "SweepnFlipRouter: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, "SweepnFlipRouter: INVALID_PATH");
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "SweepnFlipRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]);
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, "SweepnFlipRouter: INVALID_PATH");
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, "SweepnFlipRouter: EXCESSIVE_INPUT_AMOUNT");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]); // refund dust eth, if any
    }

    function quote(uint amountA, uint reserveA, uint reserveB) public pure override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure override returns (uint amountOut) {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure override returns (uint amountIn) {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path) public view override returns (uint[] memory amounts) {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path) public view override returns (uint[] memory amounts) {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }
}