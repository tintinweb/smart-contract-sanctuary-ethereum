// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IUniswapV3.sol";
import "./Include.sol";

contract Constants {
    uint internal constant _ChipsN_             = 10000e18;
    uint24 internal constant _fee_              = 10000;     // 1.00%
    address internal constant _WETH_            = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant _WETH_Rinkeby_    = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address internal constant _UniswapV3Factory_= 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address internal constant _SwapRouter02_    = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address internal constant _PositionManager_ = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address internal constant _ChipFactory_     = 0xd37e53C5871b36cf99f8C7c75E91A26f4c261539;
    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    bytes32 internal constant _feeSelf_         = "feeSelf";
    bytes32 internal constant _feeRandom_       = "feeRandom";
    bytes32 internal constant _feeSpecified_    = "feeSpecified";
}

contract Chip is ERC20Permit, Constants {      // NFT Chip
    //using SafeERC20 for IERC20;
    //using SafeMath for uint;
    using EnumerableSet for EnumerableSet.UintSet;
    
    address payable public beacon;
    address public nft;
    mapping (uint => address) public sellers;
    mapping (uint => uint) public askAmounts;
    EnumerableSet.UintSet internal randomTokens;

    function __Chip_init(address nft_, uint price, uint supply0) external initializer returns (address pool) {
        __Context_init_unchained();
        (string memory name, string memory symbol) = spellNameAndSymbol(nft_);
        __ERC20_init_unchained(name, symbol);
        __ERC20Permit_init_unchained();
        pool = __Chip_init_unchained(nft_, price, supply0);
    }

    function __Chip_init_unchained(address nft_, uint price, uint supply0) internal initializer returns (address pool) {
        beacon = _msgSender();
        nft = nft_;
        pool = _createPool(price, supply0);
    }

    function spellNameAndSymbol(address nft_) public view returns (string memory name, string memory symbol) {
        name = string(abi.encodePacked("NPics.xyz NFT Chip ", IERC721Metadata(nft_).symbol()));
        symbol = string(abi.encodePacked("chip", IERC721Metadata(nft_).symbol()));
    }

    function setNameAndSymbol(string memory name, string memory symbol) external {
        require(_msgSender() == ChipFactory(beacon).governor() || _msgSender() == __AdminUpgradeabilityProxy__(beacon).__admin__());
        _name = name;
        _symbol = symbol;
    }

    function _createPool(uint price, uint supply0) internal returns (address pool) {
        address WETH = _WETH();
        (address token0, address token1) = address(this) <= WETH ? (address(this), WETH) : (WETH, address(this));
        uint p1 = price.mul(2**96).div(1e18);
        price = address(this) <= WETH ? p1 : uint(2**192).div(p1);
        uint160 sqrtPriceX96 = SafeCast.toUint160(Math.sqrt(price.mul(2**96)));
        pool = IPoolInitializer(_PositionManager_).createAndInitializePoolIfNecessary(token0, token1, _fee_, sqrtPriceX96);

        _mint(address(this), supply0);
        _approve(address(this), _PositionManager_, uint(-1));
        IERC20(WETH).approve(_PositionManager_, uint(-1));
        
        _nfpMint(0, supply0, p1);
    }

    function _nfpMint(uint e, uint b1, uint p1) internal returns(uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        address WETH = _WETH();
        if(address(this) > WETH)
            p1 = uint(2**192).div(p1);
        uint160 sqrtPriceX96 = SafeCast.toUint160(Math.sqrt(p1.mul(2**96)));

        int24 tickSpacing = IUniswapV3Factory(_UniswapV3Factory_).feeAmountTickSpacing(_fee_);
        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96) / tickSpacing * tickSpacing;

        //(uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = 
        return INonfungiblePositionManager(_PositionManager_).mint(
            INonfungiblePositionManager.MintParams({
                token0          : address(this) <= WETH ? address(this) : WETH,
                token1          : address(this) <= WETH ? WETH : address(this),
                fee             : _fee_,
                tickLower       : address(this) <= WETH ? tick + tickSpacing : TickMath.MIN_TICK / tickSpacing * tickSpacing,
                tickUpper       : address(this) <= WETH ? TickMath.MAX_TICK / tickSpacing * tickSpacing : tick,
                amount0Desired  : address(this) <= WETH ? b1 : e,
                amount1Desired  : address(this) <= WETH ? e : b1,
                amount0Min      : 0,
                amount1Min      : 0,
                recipient       : address(this),
                deadline        : now
            })
        );
    }

    function _nfpBurn() internal returns(uint256 amount0, uint256 amount1) {
        uint tokenId = IERC721Enumerable(_PositionManager_).tokenOfOwnerByIndex(address(this), 0);
        (,,,,,,, uint128 liquidity,,,,) = INonfungiblePositionManager(_PositionManager_).positions(tokenId);
        (amount0, amount1) = INonfungiblePositionManager(_PositionManager_).decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId     : tokenId,
                liquidity   : liquidity,
                amount0Min  : 0,
                amount1Min  : 0,
                deadline    : now
            })
        );
        INonfungiblePositionManager(_PositionManager_).collect(
            INonfungiblePositionManager.CollectParams({
                tokenId     : tokenId,
                recipient   : beacon,
                amount0Max  : type(uint128).max,
                amount1Max  : type(uint128).max
            })
        );
        INonfungiblePositionManager(_PositionManager_).burn(tokenId);
    }

    function mint(uint tokenId, uint amount) public returns (uint amt) {
        IERC721(nft).transferFrom(_msgSender(), address(this), tokenId);
        sellers[tokenId] = _msgSender();
        askAmounts[tokenId] = amount;
        require(amount >= _ChipsN_, "ChipsN");
        if(amount == _ChipsN_)
            randomTokens.add(tokenId);
        amt = _ChipsN_.mul(_ChipsN_).div(amount);

        (uint b0, uint e) = _nfpBurn();
        if(address(this) > _WETH())
            (b0, e) = (e, b0);
        (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(IUniswapV3Factory(_UniswapV3Factory_).getPool(address(this), _WETH(), _fee_)).slot0();
        uint b1 = b0.mul(2**96).div(b0.mul(uint(sqrtPriceX96) **2 / 2**96).div(e).sub(b0.mul(2**96).div(_totalSupply.sub(b0).add(amt))));
        //uint b1 = b0.mul(2**96).div(_totalSupply.mul(2**96).div(_totalSupply.sub(b0)).sub(b0.mul(2**96).div(_totalSupply.sub(b0).add(amt))));
        _burn(address(this), b0.sub(b1));
        _mint(_msgSender(), amt);

        uint p1 = e.mul(b1).div(_totalSupply.sub(b1)).mul(2**96).div(_totalSupply);
        _nfpMint(e, b1, p1);
    }

    function remint(uint tokenId, uint amount) external returns(uint inc, uint dec) {

    }

    function burn(uint tokenId) public returns (uint amount, uint amt) {     // -1 for random
        bytes32 feeBurn;
        if(tokenId == uint(-1)) {
            tokenId = randomTokens.at(uint(keccak256(abi.encode(block.timestamp))) % randomTokens.length());
            randomTokens.remove(tokenId);
            amount = _ChipsN_;
            feeBurn = _feeRandom_;
        } else if(sellers[tokenId] == _msgSender()) {
            amount = _ChipsN_.mul(_ChipsN_).div(askAmounts[tokenId]);
            feeBurn = _feeSelf_;
        } else {
            amount = askAmounts[tokenId];
            amt = amount.sub(_ChipsN_.mul(_ChipsN_).div(amount));
            feeBurn = _feeSpecified_;
        }
        uint fee = ChipFactory(beacon).getConfig(feeBurn).mul(askAmounts[tokenId]).div(1000000);
        
        _transfer(_msgSender(), address(this), amount.add(fee));
        if(fee > 0)
            _transfer(address(this), beacon, fee);
        if(amt > 0)
            _transfer(address(this), sellers[tokenId], amt);

        (uint b0, uint e) = _nfpBurn();
        if(address(this) > _WETH())
            (b0, e) = (e, b0);
        (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(IUniswapV3Factory(_UniswapV3Factory_).getPool(address(this), _WETH(), _fee_)).slot0();
        uint b1 = b0.mul(2**96).div(b0.mul(uint(sqrtPriceX96) **2 / 2**96).div(e).sub(b0.mul(2**96).div(_totalSupply.sub(b0).add(amt).sub(amount))));
        //uint b1 = b0.mul(2**96).div(_totalSupply.mul(2**96).div(_totalSupply.sub(b0)).sub(b0.mul(2**96).div(_totalSupply.sub(b0).add(amt).sub(amount))));
        _burn(address(this), amount.add(b0).sub(b1).sub(amt));

        uint p1 = e.mul(b1).div(_totalSupply.sub(b1)).mul(2**96).div(_totalSupply);
        _nfpMint(e, b1, p1);

        IERC721(nft).transferFrom(address(this), _msgSender(), tokenId);
    }

    function _WETH() internal pure returns (address) {
        if(_chainId() == 1)
            return _WETH_;
        else
            return _WETH_Rinkeby_;
    }

    modifier onlyBeacon {
        require(_msgSender() == beacon, 'Only Beacon');
        _;
    }
    
    function transfer_(address sender, address recipient, uint amount) external onlyBeacon {
        _transfer(sender, recipient, amount);
    }
    
    function mint_(address account, uint amount) external onlyBeacon {
        _mint(account, amount);
    }
    
    function burn_(address account, uint amount) external onlyBeacon {
        _burn(account, amount);
    }

    // Reserved storage space to allow for layout changes in the future.
    uint[45] private ______gap;
}

contract ChipFactory is Configurable, ReentrancyGuardUpgradeSafe, ContextUpgradeSafe, Constants {
    //using SafeERC20 for IERC20;
    //using SafeMath for uint;
    using Address for address;
    //using Address for address payable;

    address public implementation;
    //function implementation() public view returns(address) {  return implementations[0];  }
    //mapping (bytes32 => address) public implementations;

    mapping (address => address) public chips;     // nft => chip
    address[] public chipA;
    function chipN() external view returns (uint) {  return chipA.length;  }
    
    function __ChipFactory_init(address governor, address implChip) public initializer {
        __Governable_init_unchained(governor);
        __ReentrancyGuard_init_unchained();
        __Context_init_unchained();
        __ChipFactory_init_unchained(implChip);
    }

    function __ChipFactory_init_unchained(address implChip) internal initializer {
        config[_feeSelf_]       = 10000;    // 1%
        config[_feeRandom_]     = 20000;    // 2%
        config[_feeSpecified_]  = 30000;    // 3%
        upgradeImplementationTo(implChip);
    }
    
    function upgradeImplementationTo(address implChip) public governance {
        require(implChip.isContract(), "implChip non-contract");
        implementation = implChip;
    }
    
    function createChip(address nft, uint price, uint supply0) external governance returns (address chip, address pool) {
        require(nft.isContract(), "nft non-contract");
        require(IERC165(nft).supportsInterface(_INTERFACE_ID_ERC721), "nft should supportsInterface(_INTERFACE_ID_ERC721)");

        require(chips[nft] == address(0), "the chip exist already");

        bytes memory bytecode = type(BeaconProxyChip).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(nft));
        assembly {
            chip := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        pool = Chip(chip).__Chip_init(nft, price, supply0);

        chips[nft] = chip;
        chipA.push(chip);

        emit CreateChip(nft, chip, chipA.length, pool);
    }
    event CreateChip(address indexed nft, address indexed chip, uint count, address indexed pool);

    // calculates the CREATE2 address for a chip without making any external calls
    function chipFor(address nft) public view returns (address chip) {
        chip = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                keccak256(abi.encodePacked(nft)),
                keccak256(abi.encodePacked(type(BeaconProxyChip).creationCode))
            ))));
    }

    // return chips if chip exist, or else return chipFor
    function getChipFor(address nft) public view returns (address chip) {
        chip = chips[nft];
        if(chip == address(0))
            chip = chipFor(nft);
    }
    
    //receive () external payable {
    //}

    // Reserved storage space to allow for layout changes in the future.
    uint[47] private ______gap;
}

contract BeaconProxyChip is Proxy, Constants {
    function _implementation() virtual override internal view returns (address) {
        return IBeacon(_ChipFactory_).implementation();
  }
}