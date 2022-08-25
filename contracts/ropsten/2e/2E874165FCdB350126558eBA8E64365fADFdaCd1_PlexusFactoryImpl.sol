pragma solidity 0.6.12;

import "../interfaces/IPlexusPair.sol";
import "../interfaces/IERC20.sol";
import "./PlexusPair.sol";

import "./PlexusFactory.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

contract PlexusFactoryImpl is PlexusFactory {
    event PairCreated(address token0, address token1, address pair, uint256);

    // PlexusFactory(address(0), address(0), address(0), address(0))
    constructor() public PlexusFactory(address(0), address(0), address(0), address(0), address(0)) {}

    function createPool(
        address tokenA,
        address tokenB,
        uint256 _fee,
        uint256 _pairOwnerFee
    ) private returns (address pair) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESS");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "PAIR_EXISTS");
        require(_fee == 30 || _fee == 100 || _fee == 1 || _fee == 5, "Not a normal pair");
        bytes memory bytecode = type(PlexusPair).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        IPlexusPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        pairOwner[pair] = msg.sender;

        // if (msg.sender != owner || msg.sender != feeToSetter) {
        //     // TransferHelper.safeTransferFrom(plexus, msg.sender, address(0), pairCreateFee);
        //     IERC20(plexus).transferFrom(msg.sender, address(0), pairCreateFee);
        pairOwnerFee[pair] = _pairOwnerFee;
        // }

        fee[pair] = _fee;
        allPairs.push(pair);

        // TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, tokenAamount);
        // TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, tokenBamount);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(PlexusPair).creationCode);
    }

    function createETHPool(
        address token,
        uint256 amount,
        uint256 fee,
        uint256 _pairOwnerFee
    ) public payable {
        uint256 amountWETH = msg.value;
        address pair = createPool(WETH, token, fee, _pairOwnerFee);

        IWETH(WETH).deposit.value(msg.value)();

        IERC20(WETH).transferFrom(address(this), pair, amountWETH);

        IERC20(token).transferFrom(msg.sender, pair, amount);

        IPlexusPair(pair).mint(msg.sender);
        // IERC20(WETH).transfer(address(this), msg.sender, amountWETH);
    }

    function createTokenPool(
        address token0,
        uint256 amount0,
        address token1,
        uint256 amount1,
        uint256 fee,
        uint256 _pairOwnerFee
    ) public {
        require(token0 != token1);
        require(token1 != WETH);
        address pair = createPool(token0, token1, fee, _pairOwnerFee);
        IERC20(token0).transferFrom(msg.sender, pair, amount0);
        IERC20(token1).transferFrom(msg.sender, pair, amount1);
        IPlexusPair(pair).mint(msg.sender);
    }
}

pragma solidity 0.6.12;

interface IPlexusPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

pragma solidity 0.6.12;

interface IPlexusFactoryImpl {
    function getExchangeImplementation() external view returns (address);

    function WETH() external view returns (address payable);

    function plexus() external view returns (address);
}

contract PlexusPair {
    // ======== ERC20 =========
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public name;
    string public constant symbol = "PLP";
    uint8 public decimals = 18;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public factory;
    address public plexus;
    address payable public WETH;
    address public token0;
    address public token1;

    uint112 public reserve0;
    uint112 public reserve1;
    uint32 public blockTimestampLast;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 balance0;
    uint256 balance1;

    uint256 public fee;

    uint256 public mining;

    uint256 public lastMined;
    uint256 public miningIndex;

    mapping(address => uint256) public userLastIndex;
    mapping(address => uint256) public userRewardSum;

    // ======== Uniswap V2 Compatible ========
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;

    bytes4 internal constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    uint256 internal unlocked = 1;

    constructor(address _token0, address _token1) public {
        factory = msg.sender;

        plexus = IPlexusFactoryImpl(msg.sender).plexus();

        require(_token0 != _token1);

        token0 = _token0;
        token1 = _token1;
    }

    fallback() external payable {
        address impl = IPlexusFactoryImpl(factory).getExchangeImplementation();
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.6.12;

contract PlexusFactory {
    // ======== Construction & Init ========
    address public feeToSetter;
    address payable public implementation;
    address payable public exchangeImplementation;
    address payable public WETH;
    address public plexus;
    address public feeDistributor;
    address public buyback;
    address[] public allPairs;
    address public airdrop;
    uint256 public pairCreateFee = 1e18 * 100;
    address public owner;
    mapping(address => mapping(address => address)) public getPair;
    mapping(address => address) public pairOwner;
    mapping(address => uint256) public fee;
    mapping(address => uint256) public pairOwnerFee;

    // ======== Pool Info ========
    address[] public pools;
    mapping(address => bool) public poolExist;

    // ======== Administration ========

    uint256 public createFee;

    constructor(
        address payable _implementation,
        address payable _exchangeImplementation,
        address payable _WETH,
        address payable _plexus,
        address payable _buyback
    ) public {
        implementation = _implementation;
        plexus = _plexus;
        WETH = _WETH;
        feeToSetter = msg.sender;
        buyback = _buyback;
        owner = msg.sender;
    }

    function setImplementation(address payable _newImp) public {
        require(msg.sender == feeToSetter);
        require(implementation != _newImp);
        implementation = _newImp;
    }

    function getPairFee(address _pair) external view returns (uint256) {
        return fee[_pair];
    }

    function getPairOwner(address _pair) external view returns (address) {
        return pairOwner[_pair];
    }

    function getPairOwnerFee(address _pair) external view returns (uint256) {
        return pairOwnerFee[_pair];
    }

    function setPairCreateFee(uint256 _fee) public {
        require(msg.sender == feeToSetter);
        {
            pairCreateFee = _fee * 1e18;
        }
    }

    function setPairOwnerFee(address _pair, uint256 _ownerFee) public {
        require(msg.sender == feeToSetter || msg.sender == pairOwner[_pair]);
        pairOwnerFee[_pair] = _ownerFee;
    }

    function setPairOwner(address _pair, address newOwner) public {
        require(msg.sender == feeToSetter || msg.sender == pairOwner[_pair]);
        pairOwner[_pair] = newOwner;
    }

    function setFeeToSetter(address _feeToSetter) public {
        require(msg.sender == feeToSetter);
        feeToSetter = _feeToSetter;
    }

    function setBuyBack(address _buyback) public {
        require(msg.sender == feeToSetter);
        buyback = _buyback;
    }

    function setFeeDistributor(address _feeDistributor) public {
        require(msg.sender == feeToSetter);
        feeDistributor = _feeDistributor;
    }

    function setAirdrop(address _airdrop) public {
        require(msg.sender == feeToSetter);
        airdrop = _airdrop;
    }

    fallback() external payable {
        address impl = implementation;
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}