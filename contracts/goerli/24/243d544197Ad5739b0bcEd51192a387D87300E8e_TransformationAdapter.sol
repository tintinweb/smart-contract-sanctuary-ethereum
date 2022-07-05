// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.11;

import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "../../../sushiswap/IBentoBoxMinimal.sol";

/// @title BentoAdapter
/// @notice Adapter which provides all functions of BentoBox require by this contract.
/// @dev These are generic functions, make sure, only msg.sender, address(this) and address(bentoBox)
/// are passed in the from param, or else the attacker can sifu user's funds in bentobox.
abstract contract BentoAdapter {
    IBentoBoxMinimal public immutable bentoBox;

    constructor(address _bentoBox) {
        bentoBox = IBentoBoxMinimal(_bentoBox);
    }

    // deposits funds from address(this) into bentobox
    function depositToBentoBox(
        bool approve,
        address token,
        address to,
        uint256 amount,
        uint256 share,
        uint256 value
    ) public {
        if (approve) {
            ERC20(token).approve(address(bentoBox), type(uint256).max);
        }

        bentoBox.deposit{value: value}(token, address(this), to, amount, share);
    }

    /// @notice Deposits the token from users wallet into the BentoBox.
    /// @dev Make sure, only msg.sender, address(this) and address(bentoBox)
    /// are passed in the from param, or else the attacker can sifu user's funds in bentobox.
    /// Pass either amount or share.
    /// @param token token to deposit. Use token as address(0) when depositing native token
    /// @param from sender
    /// @param to receiver
    /// @param amount amount to be deposited
    /// @param share share to be deposited
    /// @param value native token value to be deposited. Only use when token address is address(0)
    function _depositToBentoBox(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 share,
        uint256 value
    ) internal {
        bentoBox.deposit{value: value}(token, from, to, amount, share);
    }

    /// @notice Transfers the token from bentobox user to another or withdraw it to another address.
    /// @dev Make sure, only msg.sender, address(this) and address(bentoBox)
    /// are passed in the from param, or else the attacker can sifu user's funds in bentobox.
    /// Pass either amount or share.
    /// @param token token to transfer. For native tokens, use wnative token address
    /// @param from sender
    /// @param to receiver
    /// @param amount amount to transfer
    /// @param share share to transfer
    /// @param unwrapBento use true for withdraw and false for transfer
    function _transferFromBentoBox(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 share,
        bool unwrapBento
    ) internal {
        if (unwrapBento) {
            bentoBox.withdraw(token, from, to, amount, share);
        } else {
            if (amount > 0) {
                share = bentoBox.toShare(token, amount, false);
            }
            bentoBox.transfer(token, from, to, share);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import { ConduitControllerInterface } from "seaport/contracts/interfaces/ConduitControllerInterface.sol";
import { ConduitInterface } from "seaport/contracts/interfaces/ConduitInterface.sol";
import { ConduitTransfer } from "seaport/contracts/conduit/lib/ConduitStructs.sol";
import { ConduitItemType } from "seaport/contracts/conduit/lib/ConduitEnums.sol";

contract ConduitAdapter {
    // Allow for interaction with the conduit controller.
    ConduitControllerInterface private immutable _CONDUIT_CONTROLLER;
    // Cache the conduit creation hash used by the conduit controller.
    bytes32 private immutable _CONDUIT_CREATION_CODE_HASH;

    constructor(address _conduitController) {
        // Get the conduit creation code hash from the supplied conduit
        // controller and set it as an immutable.
        ConduitControllerInterface conduitController = ConduitControllerInterface(
            _conduitController
        );
        (_CONDUIT_CREATION_CODE_HASH, ) = conduitController.getConduitCodeHashes();

        // Set the supplied conduit controller as an immutable.
        _CONDUIT_CONTROLLER = conduitController;
    }

    function _performERC20TransferWithConduit(
        address token,
        address from,
        address to,
        uint256 amount,
        bytes32 conduitKey
    ) internal {
        // Derive the conduit address from the deployer, conduit key
        // and creation code hash.
        address conduit = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(_CONDUIT_CONTROLLER),
                            conduitKey,
                            _CONDUIT_CREATION_CODE_HASH
                        )
                    )
                )
            )
        );

        ConduitTransfer[] memory conduitTransfers = new ConduitTransfer[](1);
        conduitTransfers[0] = ConduitTransfer(
            ConduitItemType.ERC20,
            token,
            from,
            to,
            0,
            amount
        );

        // Call the conduit and execute transfer.
        ConduitInterface(conduit).execute(conduitTransfers);
    }

    function _performERC721TransferWithConduit(
        address token,
        address from,
        address to,
        uint256 tokenId,
        bytes32 conduitKey
    ) internal {
        // Derive the conduit address from the deployer, conduit key
        // and creation code hash.
        address conduit = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(_CONDUIT_CONTROLLER),
                            conduitKey,
                            _CONDUIT_CREATION_CODE_HASH
                        )
                    )
                )
            )
        );

        ConduitTransfer[] memory conduitTransfers = new ConduitTransfer[](1);
        conduitTransfers[0] = ConduitTransfer(
            ConduitItemType.ERC721,
            token,
            from,
            to,
            tokenId,
            1
        );

        // Call the conduit and execute transfer.
        ConduitInterface(conduit).execute(conduitTransfers);
    }

    function _performERC1155TransferWithConduit(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes32 conduitKey
    ) internal {
        // Derive the conduit address from the deployer, conduit key
        // and creation code hash.
        address conduit = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(_CONDUIT_CONTROLLER),
                            conduitKey,
                            _CONDUIT_CREATION_CODE_HASH
                        )
                    )
                )
            )
        );

        ConduitTransfer[] memory conduitTransfers = new ConduitTransfer[](1);
        conduitTransfers[0] = ConduitTransfer(
            ConduitItemType.ERC1155,
            token,
            from,
            to,
            tokenId,
            amount
        );

        // Call the conduit and execute transfer.
        ConduitInterface(conduit).execute(conduitTransfers);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "seaport/contracts/lib/TokenTransferrer.sol";
import "./ConduitAdapter.sol";
import "./BentoAdapter.sol";
import { TokenSource } from "../../lib/ShoyuEnums.sol";

// TODO: Consider notice in TokenTransferrer.sol, maybe it shouldn't be used here
contract TransferAdapter is TokenTransferrer, ConduitAdapter, BentoAdapter {
    constructor(
        address _conduitController,
        address _bentoBox
    )
        ConduitAdapter(_conduitController)
        BentoAdapter(_bentoBox)
    {}

    function transferERC20From(
        address token,
        address to,
        uint256 amount,
        TokenSource source,
        bytes memory data
    ) public {
        if (source == TokenSource.WALLET) {
            _performERC20Transfer(
                token,
                msg.sender,
                to,
                amount
            );
        } else if (source == TokenSource.CONDUIT) {
            bytes32 conduitKey = abi.decode(data, (bytes32));

            _performERC20TransferWithConduit(
                token,
                msg.sender,
                to,
                amount,
                conduitKey
            );
        } else if (source == TokenSource.BENTO) {
            bool unwrapBento = abi.decode(data, (bool));

            _transferFromBentoBox(
                token,
                msg.sender,
                to,
                amount,
                0,
                unwrapBento
            );
        } else {
            revert("transferERC20From/INVALID_TOKEN_SOURCE");
        }
    }

    function transferERC721From(
        address token,
        address to,
        uint256 tokenId,
        TokenSource source,
        bytes memory data
    ) public {
        if (source == TokenSource.WALLET) {
            _performERC721Transfer(
                token,
                msg.sender,
                to,
                tokenId
            );
        } else if (source == TokenSource.CONDUIT) {
            bytes32 conduitKey = abi.decode(data, (bytes32));

            _performERC721TransferWithConduit(
                token,
                msg.sender,
                to,
                tokenId,
                conduitKey
            );
        } else {
            revert("transferERC721From/INVALID_TOKEN_SOURCE");
        }
    }

    function transferERC1155From(
        address token,
        address to,
        uint256 tokenId,
        uint256 amount,
        TokenSource source,
        bytes memory data
    ) public {
        if (source == TokenSource.WALLET) {
            _performERC1155Transfer(
                token,
                msg.sender,
                to,
                tokenId,
                amount
            );
        } else if (source == TokenSource.CONDUIT) {
           bytes32 conduitKey = abi.decode(data, (bytes32));

           _performERC1155TransferWithConduit(
                token,
                msg.sender,
                to,
                tokenId,
                amount,
                conduitKey
            );
        } else {
            revert("transferERC1155From/INVALID_TOKEN_SOURCE");
        }
    }

    /// @dev Transfers some amount of ETH to the given recipient and
    ///      reverts if the transfer fails.
    /// @param to The recipient of the ETH.
    /// @param amount The amount of ETH to transfer.
    function _transferEth(address payable to, uint256 amount)
        internal
    {
        assembly {
            let success := call(gas(), to, amount, 0, 0, 0, 0)
            if eq(success, 0) { revert(0, 0) }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "@rari-capital/solmate/src/tokens/ERC20.sol";

import "../Transfer/ConduitAdapter.sol";
import "../Transfer/TransferAdapter.sol";
import { SwapExactOutDetails } from "../../lib/ShoyuStructs.sol";
import { pairFor, sortTokens, getAmountsIn, getAmountsOut } from "../../lib/LibSushi.sol";
import { TokenSource } from "../../lib/ShoyuEnums.sol";

contract LegacySwapAdapter is TransferAdapter {
    /// @dev The UniswapV2Factory address.
    address private immutable factory;
    /// @dev The UniswapV2 pair init code.
    bytes32 private immutable pairCodeHash;

    constructor(
        address _factory,
        bytes32 _pairCodeHash,
        address _conduitController,
        address _bentobox
    ) TransferAdapter (_conduitController, _bentobox) {
        factory = _factory;
        pairCodeHash = _pairCodeHash;
    }

    // transfers funds from msg.sender and performs swap
    function _legacySwapExactOut(
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        address to,
        TokenSource tokenSource,
        bytes memory transferData
    ) internal returns (uint256 amountIn) {
        uint256[] memory amounts = getAmountsIn(
            factory,
            amountOut,
            path,
            pairCodeHash
        );
        amountIn = amounts[0];

        require(amountIn <= amountInMax, '_legacySwapExactOut/EXCESSIVE_AMOUNT_IN');

        transferERC20From(
            path[0],
            pairFor(
                factory,
                path[0],
                path[1],
                pairCodeHash
            ),
            amountIn,
            tokenSource,
            transferData
        );

        _swap(amounts, path, to);
    }

    // requires path[0] to have already been sent to address(this)
    function _legacySwapExactIn(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to
    ) internal returns (uint256 amountOut) {
        uint256[] memory amounts = getAmountsOut(
            factory,
            amountIn,
            path,
            pairCodeHash
        );
        amountOut = amounts[amounts.length - 1];

        require(amountOut >= amountOutMin, "_legacySwapExactIn/EXCESSIVE_AMOUNT_OUT");

        ERC20(path[0]).transfer(
            pairFor(
                factory,
                path[0],
                path[1],
                pairCodeHash
            ),
            amountIn
        );

        _swap(amounts, path, to);
    }

    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);

            (address token0, ) = sortTokens(input, output);

            uint256 amountOut = amounts[i + 1];

            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2 ? pairFor(factory, output, path[i + 2], pairCodeHash) : _to;

            IUniswapV2Pair(pairFor(factory, input, output, pairCodeHash)).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    
}

pragma solidity >=0.8.11;

import "@sushiswap/core/contracts/uniswapv2/interfaces/IWETH.sol";
import "./LegacySwapAdapter.sol";

contract TransformationAdapter is LegacySwapAdapter {
    address private immutable WETH;

    constructor(
        address _weth,
        address _factory,
        bytes32 _pairCodeHash,
        address _conduitController,
        address _bentobox
    ) LegacySwapAdapter(_factory, _pairCodeHash, _conduitController, _bentobox) {
        WETH = _weth;
    }

    // transfers funds from msg.sender & performs swaps
    function swapExactOut(
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        address payable to,
        TokenSource tokenSource,
        bytes memory transferData,
        bool unwrapNative
    ) public payable {
        _legacySwapExactOut(
            amountOut,
            amountInMax,
            path,
            unwrapNative ? address(this) : to,
            tokenSource,
            transferData
        );

        if (unwrapNative) {
            IWETH(WETH).withdraw(amountOut);
            if (to != address(this)) {
                _transferEth(to, amountOut);
            }
        }
    }

    // requires path[0] to have been sent to address(this)
    function swapExactIn(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address payable to,
        bool unwrapNative
    ) public payable {
        uint256 amountOut = _legacySwapExactIn(
            amountIn,
            amountOutMin,
            path,
            unwrapNative ? address(this) : to
        );

        if (unwrapNative) {
            IWETH(WETH).withdraw(amountOut);
            if (to != address(this)) {
                _transferEth(to, amountOut);
            }
        }

    }

    // requires WETH to have been sent to address(this)
    function unwrapNativeToken(
        uint256 amount,
        address payable to
    ) public payable {
        IWETH(WETH).withdraw(amount);
        if (to != address(this)) {
            _transferEth(to, amount);
        }
    }

    // requires ETH to have been sent to address(this)
    function wrapNativeToken(uint256 amount) public payable {
        IWETH(WETH).deposit{value: amount}();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";

// returns sorted token addresses, used to handle return values from pairs sorted in this order
function sortTokens(
    address tokenA,
    address tokenB
) pure returns (address token0, address token1) {
    require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
}

// calculates the CREATE2 address for a pair without making any external calls
function pairFor(
    address factory,
    address tokenA,
    address tokenB,
    bytes32 pairCodeHash
) pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            pairCodeHash // init code hash
        )))));
}

// fetches and sorts the reserves for a pair
function getReserves(
    address factory,
    address tokenA,
    address tokenB,
    bytes32 pairCodeHash
) view returns (uint reserveA, uint reserveB) {
    (address token0,) = sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB, pairCodeHash)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
}

// given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
function quote(
    uint amountA,
    uint reserveA,
    uint reserveB
) pure returns (uint amountB) {
    require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
    require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
    amountB = amountA * reserveB / reserveA;
}

// given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
) pure returns (uint amountOut) {
    require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
    uint amountInWithFee = amountIn* 997;
    uint numerator = amountInWithFee * reserveOut;
    uint denominator = reserveIn * 1000 + amountInWithFee;
    amountOut = numerator / denominator;
}

// given an output amount of an asset and pair reserves, returns a required input amount of the other asset
function getAmountIn(
    uint amountOut,
    uint reserveIn,
    uint reserveOut
) pure returns (uint amountIn) {
    require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
    uint numerator = reserveIn * amountOut * 1000;
    uint denominator = (reserveOut - amountOut) * 997;
    amountIn = numerator / denominator + 1;
}

// performs chained getAmountOut calculations on any number of pairs
function getAmountsOut(
    address factory,
    uint amountIn,
    address[] memory path,
    bytes32 pairCodeHash
) view returns (uint[] memory amounts) {
    require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
    amounts = new uint[](path.length);
    amounts[0] = amountIn;
    for (uint i; i < path.length - 1; i++) {
        (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1], pairCodeHash);
        amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
}

// performs chained getAmountIn calculations on any number of pairs
function getAmountsIn(
    address factory,
    uint amountOut,
    address[] memory path,
    bytes32 pairCodeHash
) view returns (uint[] memory amounts) {
    require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
    amounts = new uint[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint i = path.length - 1; i > 0; i--) {
        (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i], pairCodeHash);
        amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

enum TokenSource {
    WALLET,
    CONDUIT,
    BENTO
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

struct OrderDetails {
    uint256 value;
    bytes data;
}

struct SwapExactOutDetails {
    address[] path;
    uint256 amountInMax;
    uint256 amountOut;
}

struct SwapExactInDetails {
    address[] path;
    uint256 amountIn;
    uint256 amountOutMin;
}

struct Adapter {
    address adapterAddress;
    bool isLibrary;
    bool isActive;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.11;

/// @notice Minimal BentoBox vault interface.
/// @dev `token` is aliased as `address` from `IERC20` for simplicity.
interface IBentoBoxMinimal {
    /// @notice Balance per ERC-20 token per account in shares.
    function balanceOf(address, address) external view returns (uint256);

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param token The ERC-20 token.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    /// @dev Helper function to represent shares back into the `token` amount.
    /// @param token The ERC-20 token.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(
        address token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    /// @notice Registers this contract so that users can approve it for BentoBox.
    function registerProtocol() external;

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param token_ The ERC-20 token to deposit.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount represented in shares.
    function deposit(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param token_ The ERC-20 token to withdraw.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    /// @notice Transfer shares from a user account to another one.
    /// @param token The ERC-20 token to transfer.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param share The amount of `token` in shares.
    function transfer(
        address token,
        address from,
        address to,
        uint256 share
    ) external;

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

enum ConduitItemType {
    NATIVE, // unused
    ERC20,
    ERC721,
    ERC1155
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import { ConduitItemType } from "./ConduitEnums.sol";

struct ConduitTransfer {
    ConduitItemType itemType;
    address token;
    address from;
    address to;
    uint256 identifier;
    uint256 amount;
}

struct ConduitBatch1155Transfer {
    address token;
    address from;
    address to;
    uint256[] ids;
    uint256[] amounts;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

/**
 * @title ConduitControllerInterface
 * @author 0age
 * @notice ConduitControllerInterface contains all external function interfaces,
 *         structs, events, and errors for the conduit controller.
 */
interface ConduitControllerInterface {
    /**
     * @dev Track the conduit key, current owner, new potential owner, and open
     *      channels for each deployed conduit.
     */
    struct ConduitProperties {
        bytes32 key;
        address owner;
        address potentialOwner;
        address[] channels;
        mapping(address => uint256) channelIndexesPlusOne;
    }

    /**
     * @dev Emit an event whenever a new conduit is created.
     *
     * @param conduit    The newly created conduit.
     * @param conduitKey The conduit key used to create the new conduit.
     */
    event NewConduit(address conduit, bytes32 conduitKey);

    /**
     * @dev Emit an event whenever conduit ownership is transferred.
     *
     * @param conduit       The conduit for which ownership has been
     *                      transferred.
     * @param previousOwner The previous owner of the conduit.
     * @param newOwner      The new owner of the conduit.
     */
    event OwnershipTransferred(
        address indexed conduit,
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Emit an event whenever a conduit owner registers a new potential
     *      owner for that conduit.
     *
     * @param newPotentialOwner The new potential owner of the conduit.
     */
    event PotentialOwnerUpdated(address indexed newPotentialOwner);

    /**
     * @dev Revert with an error when attempting to create a new conduit using a
     *      conduit key where the first twenty bytes of the key do not match the
     *      address of the caller.
     */
    error InvalidCreator();

    /**
     * @dev Revert with an error when attempting to create a new conduit when no
     *      initial owner address is supplied.
     */
    error InvalidInitialOwner();

    /**
     * @dev Revert with an error when attempting to set a new potential owner
     *      that is already set.
     */
    error NewPotentialOwnerAlreadySet(
        address conduit,
        address newPotentialOwner
    );

    /**
     * @dev Revert with an error when attempting to cancel ownership transfer
     *      when no new potential owner is currently set.
     */
    error NoPotentialOwnerCurrentlySet(address conduit);

    /**
     * @dev Revert with an error when attempting to interact with a conduit that
     *      does not yet exist.
     */
    error NoConduit();

    /**
     * @dev Revert with an error when attempting to create a conduit that
     *      already exists.
     */
    error ConduitAlreadyExists(address conduit);

    /**
     * @dev Revert with an error when attempting to update channels or transfer
     *      ownership of a conduit when the caller is not the owner of the
     *      conduit in question.
     */
    error CallerIsNotOwner(address conduit);

    /**
     * @dev Revert with an error when attempting to register a new potential
     *      owner and supplying the null address.
     */
    error NewPotentialOwnerIsZeroAddress(address conduit);

    /**
     * @dev Revert with an error when attempting to claim ownership of a conduit
     *      with a caller that is not the current potential owner for the
     *      conduit in question.
     */
    error CallerIsNotNewPotentialOwner(address conduit);

    /**
     * @dev Revert with an error when attempting to retrieve a channel using an
     *      index that is out of range.
     */
    error ChannelOutOfRange(address conduit);

    /**
     * @notice Deploy a new conduit using a supplied conduit key and assigning
     *         an initial owner for the deployed conduit. Note that the first
     *         twenty bytes of the supplied conduit key must match the caller
     *         and that a new conduit cannot be created if one has already been
     *         deployed using the same conduit key.
     *
     * @param conduitKey   The conduit key used to deploy the conduit. Note that
     *                     the first twenty bytes of the conduit key must match
     *                     the caller of this contract.
     * @param initialOwner The initial owner to set for the new conduit.
     *
     * @return conduit The address of the newly deployed conduit.
     */
    function createConduit(bytes32 conduitKey, address initialOwner)
        external
        returns (address conduit);

    /**
     * @notice Open or close a channel on a given conduit, thereby allowing the
     *         specified account to execute transfers against that conduit.
     *         Extreme care must be taken when updating channels, as malicious
     *         or vulnerable channels can transfer any ERC20, ERC721 and ERC1155
     *         tokens where the token holder has granted the conduit approval.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to open or close the channel.
     * @param channel The channel to open or close on the conduit.
     * @param isOpen  A boolean indicating whether to open or close the channel.
     */
    function updateChannel(
        address conduit,
        address channel,
        bool isOpen
    ) external;

    /**
     * @notice Initiate conduit ownership transfer by assigning a new potential
     *         owner for the given conduit. Once set, the new potential owner
     *         may call `acceptOwnership` to claim ownership of the conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to initiate ownership transfer.
     * @param newPotentialOwner The new potential owner of the conduit.
     */
    function transferOwnership(address conduit, address newPotentialOwner)
        external;

    /**
     * @notice Clear the currently set potential owner, if any, from a conduit.
     *         Only the owner of the conduit in question may call this function.
     *
     * @param conduit The conduit for which to cancel ownership transfer.
     */
    function cancelOwnershipTransfer(address conduit) external;

    /**
     * @notice Accept ownership of a supplied conduit. Only accounts that the
     *         current owner has set as the new potential owner may call this
     *         function.
     *
     * @param conduit The conduit for which to accept ownership.
     */
    function acceptOwnership(address conduit) external;

    /**
     * @notice Retrieve the current owner of a deployed conduit.
     *
     * @param conduit The conduit for which to retrieve the associated owner.
     *
     * @return owner The owner of the supplied conduit.
     */
    function ownerOf(address conduit) external view returns (address owner);

    /**
     * @notice Retrieve the conduit key for a deployed conduit via reverse
     *         lookup.
     *
     * @param conduit The conduit for which to retrieve the associated conduit
     *                key.
     *
     * @return conduitKey The conduit key used to deploy the supplied conduit.
     */
    function getKey(address conduit) external view returns (bytes32 conduitKey);

    /**
     * @notice Derive the conduit associated with a given conduit key and
     *         determine whether that conduit exists (i.e. whether it has been
     *         deployed).
     *
     * @param conduitKey The conduit key used to derive the conduit.
     *
     * @return conduit The derived address of the conduit.
     * @return exists  A boolean indicating whether the derived conduit has been
     *                 deployed or not.
     */
    function getConduit(bytes32 conduitKey)
        external
        view
        returns (address conduit, bool exists);

    /**
     * @notice Retrieve the potential owner, if any, for a given conduit. The
     *         current owner may set a new potential owner via
     *         `transferOwnership` and that owner may then accept ownership of
     *         the conduit in question via `acceptOwnership`.
     *
     * @param conduit The conduit for which to retrieve the potential owner.
     *
     * @return potentialOwner The potential owner, if any, for the conduit.
     */
    function getPotentialOwner(address conduit)
        external
        view
        returns (address potentialOwner);

    /**
     * @notice Retrieve the status (either open or closed) of a given channel on
     *         a conduit.
     *
     * @param conduit The conduit for which to retrieve the channel status.
     * @param channel The channel for which to retrieve the status.
     *
     * @return isOpen The status of the channel on the given conduit.
     */
    function getChannelStatus(address conduit, address channel)
        external
        view
        returns (bool isOpen);

    /**
     * @notice Retrieve the total number of open channels for a given conduit.
     *
     * @param conduit The conduit for which to retrieve the total channel count.
     *
     * @return totalChannels The total number of open channels for the conduit.
     */
    function getTotalChannels(address conduit)
        external
        view
        returns (uint256 totalChannels);

    /**
     * @notice Retrieve an open channel at a specific index for a given conduit.
     *         Note that the index of a channel can change as a result of other
     *         channels being closed on the conduit.
     *
     * @param conduit      The conduit for which to retrieve the open channel.
     * @param channelIndex The index of the channel in question.
     *
     * @return channel The open channel, if any, at the specified channel index.
     */
    function getChannel(address conduit, uint256 channelIndex)
        external
        view
        returns (address channel);

    /**
     * @notice Retrieve all open channels for a given conduit. Note that calling
     *         this function for a conduit with many channels will revert with
     *         an out-of-gas error.
     *
     * @param conduit The conduit for which to retrieve open channels.
     *
     * @return channels An array of open channels on the given conduit.
     */
    function getChannels(address conduit)
        external
        view
        returns (address[] memory channels);

    /**
     * @dev Retrieve the conduit creation code and runtime code hashes.
     */
    function getConduitCodeHashes()
        external
        view
        returns (bytes32 creationCodeHash, bytes32 runtimeCodeHash);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

// prettier-ignore
import {
    ConduitTransfer,
    ConduitBatch1155Transfer
} from "../conduit/lib/ConduitStructs.sol";

/**
 * @title ConduitInterface
 * @author 0age
 * @notice ConduitInterface contains all external function interfaces, events,
 *         and errors for conduit contracts.
 */
interface ConduitInterface {
    /**
     * @dev Revert with an error when attempting to execute transfers using a
     *      caller that does not have an open channel.
     */
    error ChannelClosed(address channel);

    /**
     * @dev Revert with an error when attempting to update a channel to the
     *      current status of that channel.
     */
    error ChannelStatusAlreadySet(address channel, bool isOpen);

    /**
     * @dev Revert with an error when attempting to execute a transfer for an
     *      item that does not have an ERC20/721/1155 item type.
     */
    error InvalidItemType();

    /**
     * @dev Revert with an error when attempting to update the status of a
     *      channel from a caller that is not the conduit controller.
     */
    error InvalidController();

    /**
     * @dev Emit an event whenever a channel is opened or closed.
     *
     * @param channel The channel that has been updated.
     * @param open    A boolean indicating whether the conduit is open or not.
     */
    event ChannelUpdated(address indexed channel, bool open);

    /**
     * @notice Execute a sequence of ERC20/721/1155 transfers. Only a caller
     *         with an open channel can call this function.
     *
     * @param transfers The ERC20/721/1155 transfers to perform.
     *
     * @return magicValue A magic value indicating that the transfers were
     *                    performed successfully.
     */
    function execute(ConduitTransfer[] calldata transfers)
        external
        returns (bytes4 magicValue);

    /**
     * @notice Execute a sequence of batch 1155 transfers. Only a caller with an
     *         open channel can call this function.
     *
     * @param batch1155Transfers The 1155 batch transfers to perform.
     *
     * @return magicValue A magic value indicating that the transfers were
     *                    performed successfully.
     */
    function executeBatch1155(
        ConduitBatch1155Transfer[] calldata batch1155Transfers
    ) external returns (bytes4 magicValue);

    /**
     * @notice Execute a sequence of transfers, both single and batch 1155. Only
     *         a caller with an open channel can call this function.
     *
     * @param standardTransfers  The ERC20/721/1155 transfers to perform.
     * @param batch1155Transfers The 1155 batch transfers to perform.
     *
     * @return magicValue A magic value indicating that the transfers were
     *                    performed successfully.
     */
    function executeWithBatch1155(
        ConduitTransfer[] calldata standardTransfers,
        ConduitBatch1155Transfer[] calldata batch1155Transfers
    ) external returns (bytes4 magicValue);

    /**
     * @notice Open or close a given channel. Only callable by the controller.
     *
     * @param channel The channel to open or close.
     * @param isOpen  The status of the channel (either open or closed).
     */
    function updateChannel(address channel, bool isOpen) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

/**
 * @title TokenTransferrerErrors
 */
interface TokenTransferrerErrors {
    /**
     * @dev Revert with an error when an ERC721 transfer with amount other than
     *      one is attempted.
     */
    error InvalidERC721TransferAmount();

    /**
     * @dev Revert with an error when attempting to fulfill an order where an
     *      item has an amount of zero.
     */
    error MissingItemAmount();

    /**
     * @dev Revert with an error when attempting to fulfill an order where an
     *      item has unused parameters. This includes both the token and the
     *      identifier parameters for native transfers as well as the identifier
     *      parameter for ERC20 transfers. Note that the conduit does not
     *      perform this check, leaving it up to the calling channel to enforce
     *      when desired.
     */
    error UnusedItemParameters();

    /**
     * @dev Revert with an error when an ERC20, ERC721, or ERC1155 token
     *      transfer reverts.
     *
     * @param token      The token for which the transfer was attempted.
     * @param from       The source of the attempted transfer.
     * @param to         The recipient of the attempted transfer.
     * @param identifier The identifier for the attempted transfer.
     * @param amount     The amount for the attempted transfer.
     */
    error TokenTransferGenericFailure(
        address token,
        address from,
        address to,
        uint256 identifier,
        uint256 amount
    );

    /**
     * @dev Revert with an error when a batch ERC1155 token transfer reverts.
     *
     * @param token       The token for which the transfer was attempted.
     * @param from        The source of the attempted transfer.
     * @param to          The recipient of the attempted transfer.
     * @param identifiers The identifiers for the attempted transfer.
     * @param amounts     The amounts for the attempted transfer.
     */
    error ERC1155BatchTransferGenericFailure(
        address token,
        address from,
        address to,
        uint256[] identifiers,
        uint256[] amounts
    );

    /**
     * @dev Revert with an error when an ERC20 token transfer returns a falsey
     *      value.
     *
     * @param token      The token for which the ERC20 transfer was attempted.
     * @param from       The source of the attempted ERC20 transfer.
     * @param to         The recipient of the attempted ERC20 transfer.
     * @param amount     The amount for the attempted ERC20 transfer.
     */
    error BadReturnValueFromERC20OnTransfer(
        address token,
        address from,
        address to,
        uint256 amount
    );

    /**
     * @dev Revert with an error when an account being called as an assumed
     *      contract does not have code and returns no data.
     *
     * @param account The account that should contain code.
     */
    error NoContract(address account);

    /**
     * @dev Revert with an error when attempting to execute an 1155 batch
     *      transfer using calldata not produced by default ABI encoding or with
     *      different lengths for ids and amounts arrays.
     */
    error Invalid1155BatchTransferEncoding();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "./TokenTransferrerConstants.sol";

// prettier-ignore
import {
    TokenTransferrerErrors
} from "../interfaces/TokenTransferrerErrors.sol";

import { ConduitBatch1155Transfer } from "../conduit/lib/ConduitStructs.sol";

/**
 * @title TokenTransferrer
 * @author 0age
 * @custom:coauthor d1ll0n
 * @custom:coauthor transmissions11
 * @notice TokenTransferrer is a library for performing optimized ERC20, ERC721,
 *         ERC1155, and batch ERC1155 transfers, used by both Seaport as well as
 *         by conduits deployed by the ConduitController. Use great caution when
 *         considering these functions for use in other codebases, as there are
 *         significant side effects and edge cases that need to be thoroughly
 *         understood and carefully addressed.
 */
contract TokenTransferrer is TokenTransferrerErrors {
    /**
     * @dev Internal function to transfer ERC20 tokens from a given originator
     *      to a given recipient. Sufficient approvals must be set on the
     *      contract performing the transfer.
     *
     * @param token      The ERC20 token to transfer.
     * @param from       The originator of the transfer.
     * @param to         The recipient of the transfer.
     * @param amount     The amount to transfer.
     */
    function _performERC20Transfer(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        // Utilize assembly to perform an optimized ERC20 token transfer.
        assembly {
            // The free memory pointer memory slot will be used when populating
            // call data for the transfer; read the value and restore it later.
            let memPointer := mload(FreeMemoryPointerSlot)

            // Write call data into memory, starting with function selector.
            mstore(ERC20_transferFrom_sig_ptr, ERC20_transferFrom_signature)
            mstore(ERC20_transferFrom_from_ptr, from)
            mstore(ERC20_transferFrom_to_ptr, to)
            mstore(ERC20_transferFrom_amount_ptr, amount)

            // Make call & copy up to 32 bytes of return data to scratch space.
            // Scratch space does not need to be cleared ahead of time, as the
            // subsequent check will ensure that either at least a full word of
            // return data is received (in which case it will be overwritten) or
            // that no data is received (in which case scratch space will be
            // ignored) on a successful call to the given token.
            let callStatus := call(
                gas(),
                token,
                0,
                ERC20_transferFrom_sig_ptr,
                ERC20_transferFrom_length,
                0,
                OneWord
            )

            // Determine whether transfer was successful using status & result.
            let success := and(
                // Set success to whether the call reverted, if not check it
                // either returned exactly 1 (can't just be non-zero data), or
                // had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                callStatus
            )

            // Handle cases where either the transfer failed or no data was
            // returned. Group these, as most transfers will succeed with data.
            // Equivalent to `or(iszero(success), iszero(returndatasize()))`
            // but after it's inverted for JUMPI this expression is cheaper.
            if iszero(and(success, iszero(iszero(returndatasize())))) {
                // If the token has no code or the transfer failed: Equivalent
                // to `or(iszero(success), iszero(extcodesize(token)))` but
                // after it's inverted for JUMPI this expression is cheaper.
                if iszero(and(iszero(iszero(extcodesize(token))), success)) {
                    // If the transfer failed:
                    if iszero(success) {
                        // If it was due to a revert:
                        if iszero(callStatus) {
                            // If it returned a message, bubble it up as long as
                            // sufficient gas remains to do so:
                            if returndatasize() {
                                // Ensure that sufficient gas is available to
                                // copy returndata while expanding memory where
                                // necessary. Start by computing the word size
                                // of returndata and allocated memory. Round up
                                // to the nearest full word.
                                let returnDataWords := div(
                                    add(returndatasize(), AlmostOneWord),
                                    OneWord
                                )

                                // Note: use the free memory pointer in place of
                                // msize() to work around a Yul warning that
                                // prevents accessing msize directly when the IR
                                // pipeline is activated.
                                let msizeWords := div(memPointer, OneWord)

                                // Next, compute the cost of the returndatacopy.
                                let cost := mul(CostPerWord, returnDataWords)

                                // Then, compute cost of new memory allocation.
                                if gt(returnDataWords, msizeWords) {
                                    cost := add(
                                        cost,
                                        add(
                                            mul(
                                                sub(
                                                    returnDataWords,
                                                    msizeWords
                                                ),
                                                CostPerWord
                                            ),
                                            div(
                                                sub(
                                                    mul(
                                                        returnDataWords,
                                                        returnDataWords
                                                    ),
                                                    mul(msizeWords, msizeWords)
                                                ),
                                                MemoryExpansionCoefficient
                                            )
                                        )
                                    )
                                }

                                // Finally, add a small constant and compare to
                                // gas remaining; bubble up the revert data if
                                // enough gas is still available.
                                if lt(add(cost, ExtraGasBuffer), gas()) {
                                    // Copy returndata to memory; overwrite
                                    // existing memory.
                                    returndatacopy(0, 0, returndatasize())

                                    // Revert, specifying memory region with
                                    // copied returndata.
                                    revert(0, returndatasize())
                                }
                            }

                            // Otherwise revert with a generic error message.
                            mstore(
                                TokenTransferGenericFailure_error_sig_ptr,
                                TokenTransferGenericFailure_error_signature
                            )
                            mstore(
                                TokenTransferGenericFailure_error_token_ptr,
                                token
                            )
                            mstore(
                                TokenTransferGenericFailure_error_from_ptr,
                                from
                            )
                            mstore(TokenTransferGenericFailure_error_to_ptr, to)
                            mstore(TokenTransferGenericFailure_error_id_ptr, 0)
                            mstore(
                                TokenTransferGenericFailure_error_amount_ptr,
                                amount
                            )
                            revert(
                                TokenTransferGenericFailure_error_sig_ptr,
                                TokenTransferGenericFailure_error_length
                            )
                        }

                        // Otherwise revert with a message about the token
                        // returning false or non-compliant return values.
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_sig_ptr,
                            BadReturnValueFromERC20OnTransfer_error_signature
                        )
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_token_ptr,
                            token
                        )
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_from_ptr,
                            from
                        )
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_to_ptr,
                            to
                        )
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_amount_ptr,
                            amount
                        )
                        revert(
                            BadReturnValueFromERC20OnTransfer_error_sig_ptr,
                            BadReturnValueFromERC20OnTransfer_error_length
                        )
                    }

                    // Otherwise, revert with error about token not having code:
                    mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                    mstore(NoContract_error_token_ptr, token)
                    revert(NoContract_error_sig_ptr, NoContract_error_length)
                }

                // Otherwise, the token just returned no data despite the call
                // having succeeded; no need to optimize for this as it's not
                // technically ERC20 compliant.
            }

            // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

            // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)
        }
    }

    /**
     * @dev Internal function to transfer an ERC721 token from a given
     *      originator to a given recipient. Sufficient approvals must be set on
     *      the contract performing the transfer. Note that this function does
     *      not check whether the receiver can accept the ERC721 token (i.e. it
     *      does not use `safeTransferFrom`).
     *
     * @param token      The ERC721 token to transfer.
     * @param from       The originator of the transfer.
     * @param to         The recipient of the transfer.
     * @param identifier The tokenId to transfer.
     */
    function _performERC721Transfer(
        address token,
        address from,
        address to,
        uint256 identifier
    ) internal {
        // Utilize assembly to perform an optimized ERC721 token transfer.
        assembly {
            // If the token has no code, revert.
            if iszero(extcodesize(token)) {
                mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                mstore(NoContract_error_token_ptr, token)
                revert(NoContract_error_sig_ptr, NoContract_error_length)
            }

            // The free memory pointer memory slot will be used when populating
            // call data for the transfer; read the value and restore it later.
            let memPointer := mload(FreeMemoryPointerSlot)

            // Write call data to memory starting with function selector.
            mstore(ERC721_transferFrom_sig_ptr, ERC721_transferFrom_signature)
            mstore(ERC721_transferFrom_from_ptr, from)
            mstore(ERC721_transferFrom_to_ptr, to)
            mstore(ERC721_transferFrom_id_ptr, identifier)

            // Perform the call, ignoring return data.
            let success := call(
                gas(),
                token,
                0,
                ERC721_transferFrom_sig_ptr,
                ERC721_transferFrom_length,
                0,
                0
            )

            // If the transfer reverted:
            if iszero(success) {
                // If it returned a message, bubble it up as long as sufficient
                // gas remains to do so:
                if returndatasize() {
                    // Ensure that sufficient gas is available to copy
                    // returndata while expanding memory where necessary. Start
                    // by computing word size of returndata & allocated memory.
                    // Round up to the nearest full word.
                    let returnDataWords := div(
                        add(returndatasize(), AlmostOneWord),
                        OneWord
                    )

                    // Note: use the free memory pointer in place of msize() to
                    // work around a Yul warning that prevents accessing msize
                    // directly when the IR pipeline is activated.
                    let msizeWords := div(memPointer, OneWord)

                    // Next, compute the cost of the returndatacopy.
                    let cost := mul(CostPerWord, returnDataWords)

                    // Then, compute cost of new memory allocation.
                    if gt(returnDataWords, msizeWords) {
                        cost := add(
                            cost,
                            add(
                                mul(
                                    sub(returnDataWords, msizeWords),
                                    CostPerWord
                                ),
                                div(
                                    sub(
                                        mul(returnDataWords, returnDataWords),
                                        mul(msizeWords, msizeWords)
                                    ),
                                    MemoryExpansionCoefficient
                                )
                            )
                        )
                    }

                    // Finally, add a small constant and compare to gas
                    // remaining; bubble up the revert data if enough gas is
                    // still available.
                    if lt(add(cost, ExtraGasBuffer), gas()) {
                        // Copy returndata to memory; overwrite existing memory.
                        returndatacopy(0, 0, returndatasize())

                        // Revert, giving memory region with copied returndata.
                        revert(0, returndatasize())
                    }
                }

                // Otherwise revert with a generic error message.
                mstore(
                    TokenTransferGenericFailure_error_sig_ptr,
                    TokenTransferGenericFailure_error_signature
                )
                mstore(TokenTransferGenericFailure_error_token_ptr, token)
                mstore(TokenTransferGenericFailure_error_from_ptr, from)
                mstore(TokenTransferGenericFailure_error_to_ptr, to)
                mstore(TokenTransferGenericFailure_error_id_ptr, identifier)
                mstore(TokenTransferGenericFailure_error_amount_ptr, 1)
                revert(
                    TokenTransferGenericFailure_error_sig_ptr,
                    TokenTransferGenericFailure_error_length
                )
            }

            // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

            // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)
        }
    }

    /**
     * @dev Internal function to transfer ERC1155 tokens from a given
     *      originator to a given recipient. Sufficient approvals must be set on
     *      the contract performing the transfer and contract recipients must
     *      implement the ERC1155TokenReceiver interface to indicate that they
     *      are willing to accept the transfer.
     *
     * @param token      The ERC1155 token to transfer.
     * @param from       The originator of the transfer.
     * @param to         The recipient of the transfer.
     * @param identifier The id to transfer.
     * @param amount     The amount to transfer.
     */
    function _performERC1155Transfer(
        address token,
        address from,
        address to,
        uint256 identifier,
        uint256 amount
    ) internal {
        // Utilize assembly to perform an optimized ERC1155 token transfer.
        assembly {
            // If the token has no code, revert.
            if iszero(extcodesize(token)) {
                mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                mstore(NoContract_error_token_ptr, token)
                revert(NoContract_error_sig_ptr, NoContract_error_length)
            }

            // The following memory slots will be used when populating call data
            // for the transfer; read the values and restore them later.
            let memPointer := mload(FreeMemoryPointerSlot)
            let slot0x80 := mload(Slot0x80)
            let slot0xA0 := mload(Slot0xA0)
            let slot0xC0 := mload(Slot0xC0)

            // Write call data into memory, beginning with function selector.
            mstore(
                ERC1155_safeTransferFrom_sig_ptr,
                ERC1155_safeTransferFrom_signature
            )
            mstore(ERC1155_safeTransferFrom_from_ptr, from)
            mstore(ERC1155_safeTransferFrom_to_ptr, to)
            mstore(ERC1155_safeTransferFrom_id_ptr, identifier)
            mstore(ERC1155_safeTransferFrom_amount_ptr, amount)
            mstore(
                ERC1155_safeTransferFrom_data_offset_ptr,
                ERC1155_safeTransferFrom_data_length_offset
            )
            mstore(ERC1155_safeTransferFrom_data_length_ptr, 0)

            // Perform the call, ignoring return data.
            let success := call(
                gas(),
                token,
                0,
                ERC1155_safeTransferFrom_sig_ptr,
                ERC1155_safeTransferFrom_length,
                0,
                0
            )

            // If the transfer reverted:
            if iszero(success) {
                // If it returned a message, bubble it up as long as sufficient
                // gas remains to do so:
                if returndatasize() {
                    // Ensure that sufficient gas is available to copy
                    // returndata while expanding memory where necessary. Start
                    // by computing word size of returndata & allocated memory.
                    // Round up to the nearest full word.
                    let returnDataWords := div(
                        add(returndatasize(), AlmostOneWord),
                        OneWord
                    )

                    // Note: use the free memory pointer in place of msize() to
                    // work around a Yul warning that prevents accessing msize
                    // directly when the IR pipeline is activated.
                    let msizeWords := div(memPointer, OneWord)

                    // Next, compute the cost of the returndatacopy.
                    let cost := mul(CostPerWord, returnDataWords)

                    // Then, compute cost of new memory allocation.
                    if gt(returnDataWords, msizeWords) {
                        cost := add(
                            cost,
                            add(
                                mul(
                                    sub(returnDataWords, msizeWords),
                                    CostPerWord
                                ),
                                div(
                                    sub(
                                        mul(returnDataWords, returnDataWords),
                                        mul(msizeWords, msizeWords)
                                    ),
                                    MemoryExpansionCoefficient
                                )
                            )
                        )
                    }

                    // Finally, add a small constant and compare to gas
                    // remaining; bubble up the revert data if enough gas is
                    // still available.
                    if lt(add(cost, ExtraGasBuffer), gas()) {
                        // Copy returndata to memory; overwrite existing memory.
                        returndatacopy(0, 0, returndatasize())

                        // Revert, giving memory region with copied returndata.
                        revert(0, returndatasize())
                    }
                }

                // Otherwise revert with a generic error message.
                mstore(
                    TokenTransferGenericFailure_error_sig_ptr,
                    TokenTransferGenericFailure_error_signature
                )
                mstore(TokenTransferGenericFailure_error_token_ptr, token)
                mstore(TokenTransferGenericFailure_error_from_ptr, from)
                mstore(TokenTransferGenericFailure_error_to_ptr, to)
                mstore(TokenTransferGenericFailure_error_id_ptr, identifier)
                mstore(TokenTransferGenericFailure_error_amount_ptr, amount)
                revert(
                    TokenTransferGenericFailure_error_sig_ptr,
                    TokenTransferGenericFailure_error_length
                )
            }

            mstore(Slot0x80, slot0x80) // Restore slot 0x80.
            mstore(Slot0xA0, slot0xA0) // Restore slot 0xA0.
            mstore(Slot0xC0, slot0xC0) // Restore slot 0xC0.

            // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

            // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)
        }
    }

    /**
     * @dev Internal function to transfer ERC1155 tokens from a given
     *      originator to a given recipient. Sufficient approvals must be set on
     *      the contract performing the transfer and contract recipients must
     *      implement the ERC1155TokenReceiver interface to indicate that they
     *      are willing to accept the transfer. NOTE: this function is not
     *      memory-safe; it will overwrite existing memory, restore the free
     *      memory pointer to the default value, and overwrite the zero slot.
     *      This function should only be called once memory is no longer
     *      required and when uninitialized arrays are not utilized, and memory
     *      should be considered fully corrupted (aside from the existence of a
     *      default-value free memory pointer) after calling this function.
     *
     * @param batchTransfers The group of 1155 batch transfers to perform.
     */
    function _performERC1155BatchTransfers(
        ConduitBatch1155Transfer[] calldata batchTransfers
    ) internal {
        // Utilize assembly to perform optimized batch 1155 transfers.
        assembly {
            let len := batchTransfers.length
            // Pointer to first head in the array, which is offset to the struct
            // at each index. This gets incremented after each loop to avoid
            // multiplying by 32 to get the offset for each element.
            let nextElementHeadPtr := batchTransfers.offset

            // Pointer to beginning of the head of the array. This is the
            // reference position each offset references. It's held static to
            // let each loop calculate the data position for an element.
            let arrayHeadPtr := nextElementHeadPtr

            // Write the function selector, which will be reused for each call:
            // safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)
            mstore(
                ConduitBatch1155Transfer_from_offset,
                ERC1155_safeBatchTransferFrom_signature
            )

            // Iterate over each batch transfer.
            for {
                let i := 0
            } lt(i, len) {
                i := add(i, 1)
            } {
                // Read the offset to the beginning of the element and add
                // it to pointer to the beginning of the array head to get
                // the absolute position of the element in calldata.
                let elementPtr := add(
                    arrayHeadPtr,
                    calldataload(nextElementHeadPtr)
                )

                // Retrieve the token from calldata.
                let token := calldataload(elementPtr)

                // If the token has no code, revert.
                if iszero(extcodesize(token)) {
                    mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                    mstore(NoContract_error_token_ptr, token)
                    revert(NoContract_error_sig_ptr, NoContract_error_length)
                }

                // Get the total number of supplied ids.
                let idsLength := calldataload(
                    add(elementPtr, ConduitBatch1155Transfer_ids_length_offset)
                )

                // Determine the expected offset for the amounts array.
                let expectedAmountsOffset := add(
                    ConduitBatch1155Transfer_amounts_length_baseOffset,
                    mul(idsLength, OneWord)
                )

                // Validate struct encoding.
                let invalidEncoding := iszero(
                    and(
                        // ids.length == amounts.length
                        eq(
                            idsLength,
                            calldataload(add(elementPtr, expectedAmountsOffset))
                        ),
                        and(
                            // ids_offset == 0xa0
                            eq(
                                calldataload(
                                    add(
                                        elementPtr,
                                        ConduitBatch1155Transfer_ids_head_offset
                                    )
                                ),
                                ConduitBatch1155Transfer_ids_length_offset
                            ),
                            // amounts_offset == 0xc0 + ids.length*32
                            eq(
                                calldataload(
                                    add(
                                        elementPtr,
                                        ConduitBatchTransfer_amounts_head_offset
                                    )
                                ),
                                expectedAmountsOffset
                            )
                        )
                    )
                )

                // Revert with an error if the encoding is not valid.
                if invalidEncoding {
                    mstore(
                        Invalid1155BatchTransferEncoding_ptr,
                        Invalid1155BatchTransferEncoding_selector
                    )
                    revert(
                        Invalid1155BatchTransferEncoding_ptr,
                        Invalid1155BatchTransferEncoding_length
                    )
                }

                // Update the offset position for the next loop
                nextElementHeadPtr := add(nextElementHeadPtr, OneWord)

                // Copy the first section of calldata (before dynamic values).
                calldatacopy(
                    BatchTransfer1155Params_ptr,
                    add(elementPtr, ConduitBatch1155Transfer_from_offset),
                    ConduitBatch1155Transfer_usable_head_size
                )

                // Determine size of calldata required for ids and amounts. Note
                // that the size includes both lengths as well as the data.
                let idsAndAmountsSize := add(TwoWords, mul(idsLength, TwoWords))

                // Update the offset for the data array in memory.
                mstore(
                    BatchTransfer1155Params_data_head_ptr,
                    add(
                        BatchTransfer1155Params_ids_length_offset,
                        idsAndAmountsSize
                    )
                )

                // Set the length of the data array in memory to zero.
                mstore(
                    add(
                        BatchTransfer1155Params_data_length_basePtr,
                        idsAndAmountsSize
                    ),
                    0
                )

                // Determine the total calldata size for the call to transfer.
                let transferDataSize := add(
                    BatchTransfer1155Params_calldata_baseSize,
                    idsAndAmountsSize
                )

                // Copy second section of calldata (including dynamic values).
                calldatacopy(
                    BatchTransfer1155Params_ids_length_ptr,
                    add(elementPtr, ConduitBatch1155Transfer_ids_length_offset),
                    idsAndAmountsSize
                )

                // Perform the call to transfer 1155 tokens.
                let success := call(
                    gas(),
                    token,
                    0,
                    ConduitBatch1155Transfer_from_offset, // Data portion start.
                    transferDataSize, // Location of the length of callData.
                    0,
                    0
                )

                // If the transfer reverted:
                if iszero(success) {
                    // If it returned a message, bubble it up as long as
                    // sufficient gas remains to do so:
                    if returndatasize() {
                        // Ensure that sufficient gas is available to copy
                        // returndata while expanding memory where necessary.
                        // Start by computing word size of returndata and
                        // allocated memory. Round up to the nearest full word.
                        let returnDataWords := div(
                            add(returndatasize(), AlmostOneWord),
                            OneWord
                        )

                        // Note: use transferDataSize in place of msize() to
                        // work around a Yul warning that prevents accessing
                        // msize directly when the IR pipeline is activated.
                        // The free memory pointer is not used here because
                        // this function does almost all memory management
                        // manually and does not update it, and transferDataSize
                        // should be the largest memory value used (unless a
                        // previous batch was larger).
                        let msizeWords := div(transferDataSize, OneWord)

                        // Next, compute the cost of the returndatacopy.
                        let cost := mul(CostPerWord, returnDataWords)

                        // Then, compute cost of new memory allocation.
                        if gt(returnDataWords, msizeWords) {
                            cost := add(
                                cost,
                                add(
                                    mul(
                                        sub(returnDataWords, msizeWords),
                                        CostPerWord
                                    ),
                                    div(
                                        sub(
                                            mul(
                                                returnDataWords,
                                                returnDataWords
                                            ),
                                            mul(msizeWords, msizeWords)
                                        ),
                                        MemoryExpansionCoefficient
                                    )
                                )
                            )
                        }

                        // Finally, add a small constant and compare to gas
                        // remaining; bubble up the revert data if enough gas is
                        // still available.
                        if lt(add(cost, ExtraGasBuffer), gas()) {
                            // Copy returndata to memory; overwrite existing.
                            returndatacopy(0, 0, returndatasize())

                            // Revert with memory region containing returndata.
                            revert(0, returndatasize())
                        }
                    }

                    // Set the error signature.
                    mstore(
                        0,
                        ERC1155BatchTransferGenericFailure_error_signature
                    )

                    // Write the token.
                    mstore(ERC1155BatchTransferGenericFailure_token_ptr, token)

                    // Increase the offset to ids by 32.
                    mstore(
                        BatchTransfer1155Params_ids_head_ptr,
                        ERC1155BatchTransferGenericFailure_ids_offset
                    )

                    // Increase the offset to amounts by 32.
                    mstore(
                        BatchTransfer1155Params_amounts_head_ptr,
                        add(
                            OneWord,
                            mload(BatchTransfer1155Params_amounts_head_ptr)
                        )
                    )

                    // Return modified region. The total size stays the same as
                    // `token` uses the same number of bytes as `data.length`.
                    revert(0, transferDataSize)
                }
            }

            // Reset the free memory pointer to the default value; memory must
            // be assumed to be dirtied and not reused from this point forward.
            // Also note that the zero slot is not reset to zero, meaning empty
            // arrays cannot be safely created or utilized until it is restored.
            mstore(FreeMemoryPointerSlot, DefaultFreeMemoryPointer)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

/*
 * -------------------------- Disambiguation & Other Notes ---------------------
 *    - The term "head" is used as it is in the documentation for ABI encoding,
 *      but only in reference to dynamic types, i.e. it always refers to the
 *      offset or pointer to the body of a dynamic type. In calldata, the head
 *      is always an offset (relative to the parent object), while in memory,
 *      the head is always the pointer to the body. More information found here:
 *      https://docs.soliditylang.org/en/v0.8.14/abi-spec.html#argument-encoding
 *        - Note that the length of an array is separate from and precedes the
 *          head of the array.
 *
 *    - The term "body" is used in place of the term "head" used in the ABI
 *      documentation. It refers to the start of the data for a dynamic type,
 *      e.g. the first word of a struct or the first word of the first element
 *      in an array.
 *
 *    - The term "pointer" is used to describe the absolute position of a value
 *      and never an offset relative to another value.
 *        - The suffix "_ptr" refers to a memory pointer.
 *        - The suffix "_cdPtr" refers to a calldata pointer.
 *
 *    - The term "offset" is used to describe the position of a value relative
 *      to some parent value. For example, OrderParameters_conduit_offset is the
 *      offset to the "conduit" value in the OrderParameters struct relative to
 *      the start of the body.
 *        - Note: Offsets are used to derive pointers.
 *
 *    - Some structs have pointers defined for all of their fields in this file.
 *      Lines which are commented out are fields that are not used in the
 *      codebase but have been left in for readability.
 */

uint256 constant AlmostOneWord = 0x1f;
uint256 constant OneWord = 0x20;
uint256 constant TwoWords = 0x40;
uint256 constant ThreeWords = 0x60;

uint256 constant FreeMemoryPointerSlot = 0x40;
uint256 constant ZeroSlot = 0x60;
uint256 constant DefaultFreeMemoryPointer = 0x80;

uint256 constant Slot0x80 = 0x80;
uint256 constant Slot0xA0 = 0xa0;
uint256 constant Slot0xC0 = 0xc0;

// abi.encodeWithSignature("transferFrom(address,address,uint256)")
uint256 constant ERC20_transferFrom_signature = (
    0x23b872dd00000000000000000000000000000000000000000000000000000000
);
uint256 constant ERC20_transferFrom_sig_ptr = 0x0;
uint256 constant ERC20_transferFrom_from_ptr = 0x04;
uint256 constant ERC20_transferFrom_to_ptr = 0x24;
uint256 constant ERC20_transferFrom_amount_ptr = 0x44;
uint256 constant ERC20_transferFrom_length = 0x64; // 4 + 32 * 3 == 100

// abi.encodeWithSignature(
//     "safeTransferFrom(address,address,uint256,uint256,bytes)"
// )
uint256 constant ERC1155_safeTransferFrom_signature = (
    0xf242432a00000000000000000000000000000000000000000000000000000000
);
uint256 constant ERC1155_safeTransferFrom_sig_ptr = 0x0;
uint256 constant ERC1155_safeTransferFrom_from_ptr = 0x04;
uint256 constant ERC1155_safeTransferFrom_to_ptr = 0x24;
uint256 constant ERC1155_safeTransferFrom_id_ptr = 0x44;
uint256 constant ERC1155_safeTransferFrom_amount_ptr = 0x64;
uint256 constant ERC1155_safeTransferFrom_data_offset_ptr = 0x84;
uint256 constant ERC1155_safeTransferFrom_data_length_ptr = 0xa4;
uint256 constant ERC1155_safeTransferFrom_length = 0xc4; // 4 + 32 * 6 == 196
uint256 constant ERC1155_safeTransferFrom_data_length_offset = 0xa0;

// abi.encodeWithSignature(
//     "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)"
// )
uint256 constant ERC1155_safeBatchTransferFrom_signature = (
    0x2eb2c2d600000000000000000000000000000000000000000000000000000000
);

bytes4 constant ERC1155_safeBatchTransferFrom_selector = bytes4(
    bytes32(ERC1155_safeBatchTransferFrom_signature)
);

uint256 constant ERC721_transferFrom_signature = ERC20_transferFrom_signature;
uint256 constant ERC721_transferFrom_sig_ptr = 0x0;
uint256 constant ERC721_transferFrom_from_ptr = 0x04;
uint256 constant ERC721_transferFrom_to_ptr = 0x24;
uint256 constant ERC721_transferFrom_id_ptr = 0x44;
uint256 constant ERC721_transferFrom_length = 0x64; // 4 + 32 * 3 == 100

// abi.encodeWithSignature("NoContract(address)")
uint256 constant NoContract_error_signature = (
    0x5f15d67200000000000000000000000000000000000000000000000000000000
);
uint256 constant NoContract_error_sig_ptr = 0x0;
uint256 constant NoContract_error_token_ptr = 0x4;
uint256 constant NoContract_error_length = 0x24; // 4 + 32 == 36

// abi.encodeWithSignature(
//     "TokenTransferGenericFailure(address,address,address,uint256,uint256)"
// )
uint256 constant TokenTransferGenericFailure_error_signature = (
    0xf486bc8700000000000000000000000000000000000000000000000000000000
);
uint256 constant TokenTransferGenericFailure_error_sig_ptr = 0x0;
uint256 constant TokenTransferGenericFailure_error_token_ptr = 0x4;
uint256 constant TokenTransferGenericFailure_error_from_ptr = 0x24;
uint256 constant TokenTransferGenericFailure_error_to_ptr = 0x44;
uint256 constant TokenTransferGenericFailure_error_id_ptr = 0x64;
uint256 constant TokenTransferGenericFailure_error_amount_ptr = 0x84;

// 4 + 32 * 5 == 164
uint256 constant TokenTransferGenericFailure_error_length = 0xa4;

// abi.encodeWithSignature(
//     "BadReturnValueFromERC20OnTransfer(address,address,address,uint256)"
// )
uint256 constant BadReturnValueFromERC20OnTransfer_error_signature = (
    0x9889192300000000000000000000000000000000000000000000000000000000
);
uint256 constant BadReturnValueFromERC20OnTransfer_error_sig_ptr = 0x0;
uint256 constant BadReturnValueFromERC20OnTransfer_error_token_ptr = 0x4;
uint256 constant BadReturnValueFromERC20OnTransfer_error_from_ptr = 0x24;
uint256 constant BadReturnValueFromERC20OnTransfer_error_to_ptr = 0x44;
uint256 constant BadReturnValueFromERC20OnTransfer_error_amount_ptr = 0x64;

// 4 + 32 * 4 == 132
uint256 constant BadReturnValueFromERC20OnTransfer_error_length = 0x84;

uint256 constant ExtraGasBuffer = 0x20;
uint256 constant CostPerWord = 3;
uint256 constant MemoryExpansionCoefficient = 0x200;

// Values are offset by 32 bytes in order to write the token to the beginning
// in the event of a revert
uint256 constant BatchTransfer1155Params_ptr = 0x24;
uint256 constant BatchTransfer1155Params_ids_head_ptr = 0x64;
uint256 constant BatchTransfer1155Params_amounts_head_ptr = 0x84;
uint256 constant BatchTransfer1155Params_data_head_ptr = 0xa4;
uint256 constant BatchTransfer1155Params_data_length_basePtr = 0xc4;
uint256 constant BatchTransfer1155Params_calldata_baseSize = 0xc4;

uint256 constant BatchTransfer1155Params_ids_length_ptr = 0xc4;

uint256 constant BatchTransfer1155Params_ids_length_offset = 0xa0;
uint256 constant BatchTransfer1155Params_amounts_length_baseOffset = 0xc0;
uint256 constant BatchTransfer1155Params_data_length_baseOffset = 0xe0;

uint256 constant ConduitBatch1155Transfer_usable_head_size = 0x80;

uint256 constant ConduitBatch1155Transfer_from_offset = 0x20;
uint256 constant ConduitBatch1155Transfer_ids_head_offset = 0x60;
uint256 constant ConduitBatch1155Transfer_amounts_head_offset = 0x80;
uint256 constant ConduitBatch1155Transfer_ids_length_offset = 0xa0;
uint256 constant ConduitBatch1155Transfer_amounts_length_baseOffset = 0xc0;
uint256 constant ConduitBatch1155Transfer_calldata_baseSize = 0xc0;

// Note: abbreviated version of above constant to adhere to line length limit.
uint256 constant ConduitBatchTransfer_amounts_head_offset = 0x80;

uint256 constant Invalid1155BatchTransferEncoding_ptr = 0x00;
uint256 constant Invalid1155BatchTransferEncoding_length = 0x04;
uint256 constant Invalid1155BatchTransferEncoding_selector = (
    0xeba2084c00000000000000000000000000000000000000000000000000000000
);

uint256 constant ERC1155BatchTransferGenericFailure_error_signature = (
    0xafc445e200000000000000000000000000000000000000000000000000000000
);
uint256 constant ERC1155BatchTransferGenericFailure_token_ptr = 0x04;
uint256 constant ERC1155BatchTransferGenericFailure_ids_offset = 0xc0;