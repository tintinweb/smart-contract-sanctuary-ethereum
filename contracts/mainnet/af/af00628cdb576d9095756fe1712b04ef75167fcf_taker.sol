/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

pragma solidity ^0.8.0;
//SPDX-License-Identifier: UNLICENSED
//import "hardhat/console.sol";

interface VatLike_8 {
    function hope(address) external;
    function dai(address) external view returns (uint256) ;
}

interface GemJoinLike_3 {
    function dec() external view returns (uint256);
    function gem() external view returns (LpTokenLike);
    function exit(address, uint256) external;
}

interface DaiJoinLike_3 {
    function dai() external view returns (TokenLike_3);
    function vat() external view returns (VatLike_8);
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

interface ClipperLike {
    function take(
        uint256 id,           // Auction id
        uint256 amt,          // Upper limit on amount of collateral to buy  [wad]
        uint256 max,          // Maximum acceptable price (DAI / collateral) [ray]
        address who,          // Receiver of collateral and external call address
        bytes calldata data   // Data to pass in external call; if length 0, no call is done
    ) external;
}

interface TokenLike_3 {
    function approve(address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
}

interface LpTokenLike is TokenLike_3 {
    function token0() external view returns (TokenLike_3);
    function token1() external view returns (TokenLike_3);
}

interface UniswapV2Router02Like_2 {
    function swapExactTokensForTokens(uint256, uint256, address[] calldata, address, uint256) external returns (uint[] memory);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
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
}

interface IWETH {
    function withdraw(uint) external;
    function deposit() external payable;
}

contract taker {

    //2022。7。19 0x9759A6Ac90977b93B58547b4A71c78317f391A28
    constructor(address _daiJoin, address[] memory clippers) {
        daiJoin = DaiJoinLike_3(_daiJoin);
        dai = daiJoin.dai();
        vat = daiJoin.vat();
        dai.approve(address(daiJoin), type(uint256).max);
        owner = msg.sender;

        batchHope(vat, clippers);
    }

    DaiJoinLike_3 public daiJoin;
    VatLike_8 public vat;
    uint256 public constant RAY = 10 ** 27;
    TokenLike_3 public dai;
    address owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    IUniswapV2Pair dai2eth = IUniswapV2Pair(0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11);
    function setDai2Eth(IUniswapV2Pair _new) onlyOwner external {
        dai2eth = _new;
    }

    IWETH weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    function setWETH(IWETH _new) onlyOwner external {
        weth = _new;
    }

    function _fromWad(address gemJoin, uint256 wad) internal view returns (uint256 amt) {
        amt = wad / 10 ** (18 - GemJoinLike_3(gemJoin).dec());
    }

    function _swap(address token1, address lp, address token2, address to, uint256 amount) internal returns (uint256 out) {
        (uint256 r0, uint256 r1, ) = IUniswapV2Pair(lp).getReserves();

        unchecked {
            if (token1 > token2) {
                out = amount * 997 * r0 / (1000 * r1 + 997 * amount);
                IUniswapV2Pair(lp).swap(out, 0, to, bytes(""));
            } else {
                out = amount * 997 * r1 / (1000 * r0 + 997 * amount);
                IUniswapV2Pair(lp).swap(0, out, to, bytes(""));
            }
        }
    }

    //if a => lp1 => B => lp2 => dai
    //paths[a, lp1, B, lp2]
    //if a => lp1 => dai
    //paths[a, lp1]
    function swapForDai(address[] memory paths) internal {
        //require(false, "not implemented");
        uint256 l = paths.length;
        if (l == 0) {
            return;
        }
        uint256 end = l / 2;
        uint256 amount = TokenLike_3(paths[0]).balanceOf(address(this));
        //TokenLike_3(paths[0]).transfer(paths[1], amount); //TODO: use safeErc20
        safeTransfer(paths[0], paths[1], amount);

        for(uint256 i = 0; i < end - 1; i += 2) {
            amount = _swap(paths[i], paths[i + 1], paths[i + 2], paths[i + 3], amount);
        }
        _swap(paths[l - 2], paths[l - 1], address(dai), address(this), amount);
    }

    function divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x) / y + 1;
    }

    //function swapForDai()
    function clipperCall(
        address sender,         // Clipper Caller and Dai deliveryaddress
        uint256 daiAmt,         // Dai amount to payback[rad]
        uint256 gemAmt,         // Gem amount received [wad]
        bytes calldata data     // Extra data needed (gemJoin)
    ) external {
        (
        address gemJoin,
        address gem,
        uint256 gemType,
        address[] memory pathA,
        address[] memory pathB
        ) = abi.decode(data, (address, address, uint256, address[], address[]));

        gemAmt = _fromWad(gemJoin, gemAmt);

        uint256 before = dai.balanceOf(address(this));
        GemJoinLike_3(gemJoin).exit(address(this), gemAmt);

        //now we get all the gem
        //do exist if we need to
        if (gemType == 1) {
            //lp type
            //TokenLike_3(gem).transfer(gem, gemAmt);
            safeTransfer(gem, gem, gemAmt);
            IUniswapV2Pair(gem).burn(address(this));
        }

        swapForDai(pathA);
        swapForDai(pathB);

        // Calculate amount of DAI to Join (as erc20 WAD value)
        uint256 daiToJoin = divup(daiAmt, RAY);
        daiJoin.join(sender, daiToJoin);

        uint256 earn = (dai.balanceOf(address(this)) - before);
        earn = swapDaiForEth(earn/2);
        block.coinbase.transfer(earn);
        // return dai to sender
    }

    //main entrance
    function go(ClipperLike clipper, uint256 id, uint256 amt, uint256 max, bytes calldata data) external {
        clipper.take(id, amt, max, address(this), data);
    }

    function batchHope(VatLike_8 _vat, address[] memory clippers) public {
        require(msg.sender == owner, "only owner");
        uint256 l = clippers.length;
        for(uint256 i = 0; i < l; i ++) {
            _vat.hope(clippers[i]);
        }
    }

    function withdrawlTokens(address[] calldata tokens) external {
        uint256 l = tokens.length;
        for(uint256 i = 0; i < l; i ++) {
            uint256 amount = TokenLike_3(tokens[i]).balanceOf(address(this));
            //TokenLike_3(tokens[i]).transfer(owner, amount);
            safeTransfer(tokens[i], owner, amount);
        }
    }

    function exit(uint wad) external {
        daiJoin.exit(owner, wad);
    }

    function swapDaiForEth(uint256 amount) internal returns (uint256) {
        //TOKEN0: dai
        //TOKEN1: ETH
        unchecked {
            (uint256 daiAmount, uint256 ethAmount, ) = dai2eth.getReserves();
            uint256 getBack = amount * 997 * ethAmount / (1000 * daiAmount + 997 * amount);
            safeTransfer(address(dai), address(dai2eth), amount);
            dai2eth.swap(0, getBack, address(this), "");
            weth.withdraw(getBack);
            return getBack;
        }
    }

    function safeTransfer(address token, address to, uint256 amount) internal {
        bool success;

        assembly {
        // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

        // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
            freeMemoryPointer,
            0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success :=
            and(
            // Set success to whether the call reverted, if not we check it either
            // returned exactly 1 (can't just be non-zero data), or had no return data.
            or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
            // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            // Counterintuitively, this call must be positioned second to the or() call in the
            // surrounding and() call or else returndatasize() will be zero during the computation.
            call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }
        require(success, "T");
    }

    receive() external payable{}
}