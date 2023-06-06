// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

import {IsContract} from "./libraries/isContract.sol";

import "./interfaces/univ2.sol";

error NotStartedYet();
error Blocked();

contract PPAPToken is ERC20("PPAP Token", "$PPAP", 18), Owned(msg.sender) {
    using IsContract for address;

    mapping(address => bool) public whitelisted;
    mapping(address => bool) public blocked;

    IUniswapV2Pair public pair;
    IUniswapV2Router02 public router;
    uint256 public startedIn = 0;
    uint256 public startedAt = 0;

    address public treasury;

    uint256 public feeCollected = 0;
    uint256 public feeSwapBps = 100; // 1.00% liquidity increase
    uint256 public feeSwapTrigger = 10e18;

    uint256 maxBps = 10000; // 10000 is 100.00%
    // 0-1 blocks
    uint256 public initialBuyBPS = 9000; // 90.00%
    uint256 public initialSellBPS = 9000; // 90.00%
    // 24 hours
    uint256 public earlyBuyBPS = 200; // 2.00%
    uint256 public earlySellBPS = 2000; // 20.00%
    // after
    uint256 public buyBPS = 200; // 2.00%
    uint256 public sellBPS = 400; // 4.00%

    constructor() {
        treasury = address(0xC5cAd10E496D0F3dBd3b73742B8b3a9A92cA4DcA);
        uint256 expectedTotalSupply = 369_000_000_000 ether;
        whitelisted[treasury] = true;
        whitelisted[address(this)] = true;
        _mint(treasury, expectedTotalSupply);
    }

    // getters
    function isLiqudityPool(address account) public view returns (bool) {
        if (!account.isContract()) return false;
        (bool success0, bytes memory result0) = account.staticcall(
            abi.encodeWithSignature("token0()")
        );
        if (!success0) return false;
        (bool success1, bytes memory result1) = account.staticcall(
            abi.encodeWithSignature("token1()")
        );
        if (!success1) return false;
        address token0 = abi.decode(result0, (address));
        address token1 = abi.decode(result1, (address));
        if (token0 == address(this) || token1 == address(this)) return true;
        return false;
    }

    // public functions

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    // transfer functions
    function _onTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (blocked[to] || blocked[from]) {
            revert Blocked();
        }
        if(whitelisted[from] || whitelisted[to]) {
            return amount;
        }

        if (startedIn == 0) {
            revert NotStartedYet();
        }

        if (isLiqudityPool(to) || isLiqudityPool(from)) {
            return _transferFee(from, to, amount);
        }

        if (feeCollected > feeSwapTrigger) {
            _swapFee();
        }

        return amount;
    }

    function _swapFee() internal {
        uint256 feeAmount = feeCollected;
        feeCollected = 0;
        if(address(pair) == address(0)) return;


        (address token0, address token1) = (pair.token0(), pair.token1());
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        if (token1 == address(this)) {
            (token0, token1) = (token1, token0);
            (reserve0, reserve1) = (reserve1, reserve0);
        }

        uint256 maxFee = reserve0 * feeSwapBps / maxBps;
        if (maxFee < feeAmount) {
            feeCollected = feeAmount - maxFee;
            feeAmount = maxFee;
        }

        if(feeAmount == 0) return;

        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;

        this.approve(address(router), feeAmount);
        router.swapExactTokensForTokens(
            feeAmount,
            0,
            path,
            treasury,
            block.timestamp + 1000
        );
    }

    function _transferFee(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        uint256 taxBps = 0;

        if (isLiqudityPool(from)) {
            if (block.number <= startedIn + 1) {
                taxBps = initialBuyBPS;
            } else if (block.timestamp <= startedAt + 24 hours) {
                taxBps = earlyBuyBPS;
            } else {
                taxBps = buyBPS;
            }
        } else if (isLiqudityPool(to)) {
            if (block.number <= startedIn + 1) {
                taxBps = initialSellBPS;
            } else if (block.timestamp <= startedAt + 24 hours) {
                taxBps = earlySellBPS;
            } else {
                taxBps = sellBPS;
            }
        }

        uint256 feeAmount = (amount * taxBps) / maxBps;
        if (feeAmount == 0) return amount;

        feeCollected += feeAmount;
        amount -= feeAmount;

        _transfer(from, address(this), feeAmount);

        return amount;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (from != address(this) && to != address(this)) {
            amount = _onTransfer(from, to, amount);
        }

        return super.transferFrom(from, to, amount);
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        if (msg.sender != address(this) && to != address(this)) {
            amount = _onTransfer(msg.sender, to, amount);
        }
        return super.transfer(to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        balanceOf[from] -= amount;
        unchecked {
            balanceOf[to] += amount;
        }
        emit Transfer(from, to, amount);
        return true;
    }

    // Only owner functions
    function start() public onlyOwner {
        require(startedIn == 0, "PPAP: already started");
        startedIn = block.number;
        startedAt = block.timestamp;
    }

    function setUni(address _router, address _pair) public onlyOwner {
        router = IUniswapV2Router02(_router);
        pair = IUniswapV2Pair(_pair);
        (address token0, address token1) = (pair.token0(), pair.token1());
        require(token0 == address(this) || token1 == address(this), "PPAP: wrong pair");
        require(pair.factory() == router.factory(), "PPAP: wrong pair");
    }

    function setFeeSwapConfig(uint256 _feeSwapTrigger, uint256 _feeSwapBps) public onlyOwner {
        feeSwapTrigger = _feeSwapTrigger;
        feeSwapBps = _feeSwapBps;
    }

    function setBps(uint256 _buyBPS, uint256 _sellBPS) public onlyOwner {
        require(_buyBPS <= 200, "PPAP: wrong buyBPS");
        require(_sellBPS <= 400, "PPAP: wrong sellBPS");
        buyBPS = _buyBPS;
        sellBPS = _sellBPS;
    }

    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function whitelist(address account, bool _whitelisted) public onlyOwner {
        whitelisted[account] = _whitelisted;
    }

    function blocklist(address account, bool _blocked) public onlyOwner {
        require(startedAt > 0, "PPAP: too early");
        require(startedAt + 7 days > block.timestamp, "PPAP: too late");
        blocked[account] = _blocked;
    }

    // meme
    function penPineappleApplePen() public pure returns (string memory) {
        return meme("pen", "apple");
    }

    function meme(string memory _what, string memory _with)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "I have a ",
                    _what,
                    ", I have a ",
                    _with,
                    ", UH, ",
                    _what,
                    "-",
                    _with,
                    "!"
                )
            );
    }

    function link() public pure returns (string memory) {
        return "https://www.youtube.com/watch?v=0E00Zuayv9Q";
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// Taken from Address.sol from OpenZeppelin.
pragma solidity ^0.8.0;


library IsContract {
  /// @dev Returns true if `account` is a contract.
  function isContract(address account) internal view returns (bool) {
      // This method relies on extcodesize, which returns 0 for contracts in
      // construction, since the code is only stored at the end of the
      // constructor execution.

      uint256 size;
      assembly { size := extcodesize(account) }
      return size > 0;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.5.16;


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

interface IUniswapV2ERC20 {
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