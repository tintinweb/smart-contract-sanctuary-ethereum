// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * Website: https://yilongma-erc.com
 * Telegram: https://t.me/yilongmaercportal
 * Twitter: https://twitter.com/YiLongMaERC
 */

import {Owned} from "solmate/src/auth/Owned.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {IUniswapV2Factory, IUniswapV2Router} from "./interfaces/Uniswap.sol";

contract YiLongMa is Owned, ERC20 {
    uint8 internal _decimals = 9;
    uint256 internal _totalSupply = 1000000 * 10 ** _decimals;

    uint256 public _maxTxAmount = (_totalSupply * 2) / 100;
    uint256 public _maxWalletAmount = _maxTxAmount;
    uint256 public _buyTax = 30;
    uint256 public _sellTax = 30;

    uint256 internal swapThreshold = _maxWalletAmount;
    IUniswapV2Router internal uniswapV2Router;
    address internal WETH;
    address internal uniswapV2Pair;
    address internal marketingWallet;
    mapping(address => bool) internal excludedFromLimits;
    uint256 internal launchedBlock;
    bool internal tradingEnabled;
    bool internal internalSwap;

    modifier lockInternalSwap() {
        internalSwap = true;
        _;
        internalSwap = false;
    }

    constructor() Owned(msg.sender) ERC20(unicode"YiLongMa", unicode"一龙马", _decimals) {
        super._mint(address(this), _totalSupply);
        uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        marketingWallet = msg.sender;
        excludedFromLimits[msg.sender] = true;
        excludedFromLimits[address(this)] = true;
    }

    function removeLimits() external onlyOwner {
        uint256 maxAmount = _totalSupply;
        _maxTxAmount = maxAmount;
        _maxWalletAmount = maxAmount;
    }

    function removeTaxes() external onlyOwner {
        _buyTax = 0;
        _sellTax = 0;
    }

    function enableTrading(uint256 db) external payable onlyOwner {
        require(!tradingEnabled, "Trading Already Enabled");
        WETH = uniswapV2Router.WETH();
        IUniswapV2Factory uniswapV2Factory = IUniswapV2Factory(uniswapV2Router.factory());
        address currentPair = uniswapV2Factory.getPair(address(this), WETH);
        if (currentPair == address(0)) currentPair = uniswapV2Factory.createPair(address(this), WETH);
        uniswapV2Pair = currentPair;
        uint256 initialDb = _buyTax;
        _buyTax = db;
        allowance[address(this)][address(uniswapV2Router)] = type(uint256).max;
        uniswapV2Router.addLiquidityETH{value: msg.value}(address(this), balanceOf[address(this)], 0, 0, owner, block.timestamp);
        launchedBlock = block.number;
        tradingEnabled = true;
        _buyTax = initialDb;
    }

    function renounceOwnership() external onlyOwner {
        uint256 maxAmount = _totalSupply;
        require(_maxTxAmount == maxAmount && _maxWalletAmount == maxAmount, "Limits Not Yet Removed");
        require(_buyTax == 0 && _sellTax == 0, "Taxes Not Yet Removed");
        require(tradingEnabled, "Trading Not Yet Enabled");
        Owned.transferOwnership(address(0));
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        return _tokenTransfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;
        return _tokenTransfer(from, to, amount);
    }

    function _tokenTransfer(address from, address to, uint256 amount) internal returns (bool) {
        if (!excludedFromLimits[from]) require(tradingEnabled, "Trading Not Yet Enabled");
        require(from != address(0) && to != address(0), "Transfer From/To Zero Address");
        require(amount > 0, "Transfer Amount Zero");

        uint256 taxAmount = 0;
        if (from != owner && to != owner) {
            taxAmount = !internalSwap ? (amount * (block.number <= launchedBlock ? 99 : _buyTax)) / 100 : 0;
            if (from == uniswapV2Pair && !excludedFromLimits[to]) {
                require(amount <= _maxTxAmount, "Exceeds Max TX");
                require(balanceOf[to] + amount <= _maxWalletAmount, "Exceeds Max Wallet");
            } else if (to == uniswapV2Pair && from != address(this)) {
                taxAmount = (amount * _sellTax) / 100;
                if (!internalSwap) _internalSwap(amount);
            }
        }

        balanceOf[from] -= amount;

        if (taxAmount > 0) {
            balanceOf[address(this)] += taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }

        uint256 finalAmount = amount - taxAmount;
        balanceOf[to] += finalAmount;
        emit Transfer(from, to, finalAmount);

        return true;
    }

    function _internalSwap(uint256 amount) internal lockInternalSwap {
        uint256 swapAmount = _min(amount, _min(balanceOf[address(this)], swapThreshold));
        if (swapAmount > 0) {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = WETH;
            uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(swapAmount, 0, path, marketingWallet, block.timestamp);
        }
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = (a > b) ? b : a;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
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