// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./IUniswapV3.sol";
import "./Include.sol";

contract Constants {
    uint internal constant _ChipsN_             = 10000e18;
    uint24 internal constant _fee_              = 10000;     // 1.00%
    address internal constant _UniswapV3Factory_= 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address internal constant _SwapRouter02_    = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address internal constant _PositionManager_ = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address internal constant _ChipFactory_     = 0xd37e53C5871b36cf99f8C7c75E91A26f4c261539;
    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    bytes32 internal constant _feeSelf_         = "feeSelf";
    bytes32 internal constant _feeRandom_       = "feeRandom";
    bytes32 internal constant _feeSpecified_    = "feeSpecified";
    bytes32 internal constant _rebSpan_         = "rebSpan";
    bytes32 internal constant _rebRate_         = "rebRate";

    address internal immutable _WETH_           = _WETH();
    function _WETH() internal pure returns (address addr) {
        assembly {
            switch chainid() 
                case  1  { addr := 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 }      // Ethereum Mainnet
                case  3  { addr := 0xc778417E063141139Fce010982780140Aa0cD5Ab }      // Ethereum Testnet Ropsten
                case  4  { addr := 0xc778417E063141139Fce010982780140Aa0cD5Ab }      // Ethereum Testnet Rinkeby
                case  5  { addr := 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6 }      // Ethereum Testnet Gorli
                case 42  { addr := 0xd0A1E359811322d97991E03f863a0C30C2cF029C }      // Ethereum Testnet Kovan
                case 56  { addr := 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c }      // BSC Mainnet
                case 65  { addr := 0x2219845942d28716c0f7c605765fabdca1a7d9e0 }      // OKExChain Testnet
                case 66  { addr := 0x8f8526dbfd6e38e3d8307702ca8469bae6c56c15 }      // OKExChain Main
                case 128 { addr := 0x5545153ccfca01fbd7dd11c0b23ba694d9509a6f }      // HECO Mainnet 
                case 256 { addr := 0xB49f19289857f4499781AaB9afd4A428C4BE9CA8 }      // HECO Testnet 
                default  { addr := 0x0                                        }      // unknown 
        }
    }
}

contract Chip is ERC20Permit, Constants {      // NFT Chip
    using EnumerableSet for EnumerableSet.UintSet;
    
    address payable public beacon;
    address public nft;
    mapping (uint => address) public sellers;
    mapping (uint => uint) public askAmounts;
    EnumerableSet.UintSet internal _randomTokens;
    uint internal _supply0;
    uint internal _lasttime;
    uint32 internal _rebSpan;           // uses single storage slot
    uint24 internal _rebRate;           // uses single storage slot

    function __Chip_init(address nft_, uint price, uint supply0) external initializer returns (address pool) {
        __Context_init_unchained();
        (string memory name, string memory symbol) = _spellNameAndSymbol(nft_);
        __ERC20_init_unchained(name, symbol);
        __ERC20Permit_init_unchained();
        pool = __Chip_init_unchained(nft_, price, supply0);
    }

    function __Chip_init_unchained(address nft_, uint price, uint supply0) internal initializer returns (address pool) {
        beacon = _msgSender();
        nft = nft_;
        _supply0 = supply0;
        _lasttime = block.timestamp;
        pool = _createPool(price, supply0);
    }

    function _spellNameAndSymbol(address nft_) internal view returns (string memory name, string memory symbol) {
        name = string(abi.encodePacked("NPics.xyz NFT Chip ", IERC721Metadata(nft_).symbol()));
        symbol = string(abi.encodePacked("c", IERC721Metadata(nft_).symbol()));
    }

    //function setNameAndSymbol_(string memory name, string memory symbol) external governance{
    //    _name = name;
    //    _symbol = symbol;
    //}

    //function setSupply0_(uint supply0) external governance {
    //    _supply0 = supply0;
    //}

    function setRebalance_(uint32 span, uint24 rate) external governance {
        _rebSpan = span;
        _rebRate = rate;
    }

    modifier governance() virtual {
        require(_msgSender() == ChipFactory(beacon).governor() || _msgSender() == __AdminUpgradeabilityProxy__(beacon).__admin__());
        _;
    }

    function _createPool(uint price, uint supply0) internal returns (address pool) {
        price = price.mul(2**96).div(1e18);
        (address token0, address token1) = address(this) < _WETH_ ? (address(this), _WETH_) : (_WETH_, address(this));
        pool = IPoolInitializer(_PositionManager_).createAndInitializePoolIfNecessary(token0, token1, _fee_, _priceToSqrt(price));

        _mint(address(this), supply0);
        _approve(address(this), _PositionManager_, uint(-1));
        IERC20(_WETH_).approve(_PositionManager_, uint(-1));
        
        _nfpMint(0, supply0, price);
    }

    function _nfpMint(uint e, uint b1, uint p1) internal returns(uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        int24 tickSpacing = IUniswapV3Factory(_UniswapV3Factory_).feeAmountTickSpacing(_fee_);
        int24 tick = TickMath.getTickAtSqrtRatio(_priceToSqrt(p1));
        tick = tick / tickSpacing * tickSpacing - (tick < 0 ? tickSpacing : 0);

        //(uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = 
        return INonfungiblePositionManager(_PositionManager_).mint(
            INonfungiblePositionManager.MintParams({
                token0          : address(this) <= _WETH_ ? address(this) : _WETH_,
                token1          : address(this) <= _WETH_ ? _WETH_ : address(this),
                fee             : _fee_,
                tickLower       : address(this) <= _WETH_ ? (e == 0 ? tick + tickSpacing : tick) : TickMath.MIN_TICK / tickSpacing * tickSpacing,
                tickUpper       : address(this) <= _WETH_ ? TickMath.MAX_TICK / tickSpacing * tickSpacing : (e == 0 ? tick : tick + tickSpacing),
                amount0Desired  : address(this) <= _WETH_ ? b1 : e,
                amount1Desired  : address(this) <= _WETH_ ? e : b1,
                amount0Min      : 0,
                amount1Min      : 0,
                recipient       : address(this),
                deadline        : now
            })
        );
    }

    function _nfpBurn() internal returns(uint256 amount0, uint256 amount1) {
        uint tokenId = IERC721Enumerable(_PositionManager_).tokenOfOwnerByIndex(address(this), 0);
        INonfungiblePositionManager(_PositionManager_).collect(
            INonfungiblePositionManager.CollectParams({
                tokenId     : tokenId,
                recipient   : beacon,
                amount0Max  : type(uint128).max,
                amount1Max  : type(uint128).max
            })
        );
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
                recipient   : address(this),
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
            _randomTokens.add(tokenId);
        amt = _ChipsN_.mul(_ChipsN_).div(amount);

        //(uint b0, uint e) = _nfpBurn();
        _nfpBurn();
        uint b1; uint price;
        (uint b0, uint e) = (_balances[address(this)], IERC20(_WETH_).balanceOf(address(this)));
        {
        address pool = _pool();
        price = _sqrtToPrice(_sqrtPriceX96(pool));
        uint temp = price * 2**96 / e;
        uint tmp  = uint(2**192) / (_totalSupply.sub(b0).add(amt));
        b1 = temp <= tmp.add(uint(2**192) / _supply0) ? _supply0 : uint(2**192) / (temp - tmp);
        b1 = Math.min(b1, _rebDelta(pool, price).add(b0));
        //uint b1 = b0.mul(2**96).div(b0.mul(price).div(e).sub(b0.mul(2**96).div(_totalSupply.sub(b0).add(amt))));
        //uint b1 = b0.mul(2**96).div(_totalSupply.mul(2**96).div(_totalSupply.sub(b0)).sub(b0.mul(2**96).div(_totalSupply.sub(b0).add(amt))));
        }
        if(b0 > b1)
            _burn(address(this), b0-b1);
        else if(b0 < b1)
            _mint(address(this), b1-b0);
        _mint(_msgSender(), amt);

        uint p1 = price.mul(b1).sub(e.mul(2**96)).div(_totalSupply);
        //uint p1 = e.mul(b1).div(_totalSupply.sub(b1)).mul(2**96).div(_totalSupply);
        _nfpMint(e, b1, p1);
    }

    function remint(uint tokenId, uint amount) external returns(uint inc, uint dec) {

    }

    function burn(uint tokenId) public returns (uint amount, uint amt) {     // -1 for random
        bytes32 feeBurn;
        if(tokenId == uint(-1)) {
            require(_randomTokens.length() > 0, "_randomTokens.length() == 0");
            tokenId = _randomTokens.at(uint(keccak256(abi.encode(block.timestamp))) % _randomTokens.length());
            _randomTokens.remove(tokenId);
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
        
        //(uint b0, uint e) = _nfpBurn();
        _nfpBurn();
        uint b1; uint price;
        (uint b0, uint e) = (_balances[address(this)], IERC20(_WETH_).balanceOf(address(this)));
        {
        address pool = _pool();
        price = _sqrtToPrice(_sqrtPriceX96(pool));
        uint temp = price * 2**96 / e;
        uint tmp  = uint(2**192) / (_totalSupply.sub(b0).add(amt).sub(amount));
        b1 = temp <= tmp.add(uint(2**192) / _supply0) ? _supply0 : uint(2**192) / (temp - tmp);
        b1 = Math.min(b1, _rebDelta(pool, price).add(b0));
        //uint b1 = b0.mul(2**96).div(b0.mul(price).div(e).sub(b0.mul(2**96).div(_totalSupply.sub(b0).add(amt).sub(amount))));
        //uint b1 = b0.mul(2**96).div(_totalSupply.mul(2**96).div(_totalSupply.sub(b0)).sub(b0.mul(2**96).div(_totalSupply.sub(b0).add(amt).sub(amount))));
        }
        if(amt.add(b1) > b0.add(amount))
            _mint(address(this), amt.add(b1).sub(b0).sub(amount));
        else if(amt.add(b1) < b0.add(amount))
            _burn(address(this), amount.add(b0).sub(b1).sub(amt));

        _transfer(_msgSender(), address(this), amount.add(fee));
        if(fee > 0)
            _transfer(address(this), beacon, fee);
        if(amt > 0)
            _transfer(address(this), sellers[tokenId], amt);

        uint p1 = price.mul(b1).sub(e.mul(2**96)).div(_totalSupply);
        //uint p1 = e.mul(b1).div(_totalSupply.sub(b1)).mul(2**96).div(_totalSupply);
        _nfpMint(e, b1, p1);

        IERC721(nft).transferFrom(address(this), _msgSender(), tokenId);
    }

    
    function _pool() internal view returns (address) {
        return IUniswapV3Factory(_UniswapV3Factory_).getPool(address(this), _WETH_, _fee_);
    }

    function _sqrtPriceX96(address pool) internal view returns (uint160 sqrtPriceX96) {
        (sqrtPriceX96,,,,,,) = IUniswapV3Pool(pool).slot0();
    }

    function _sqrtToPrice(uint160 sqrtPriceX96) internal view returns (uint price) {
        price = uint(sqrtPriceX96)**2 / 2**96;
        if(address(this) > _WETH_)
            price = uint(2**192) / price;
    }

    function _priceToSqrt(uint price) internal view returns (uint160 sqrtPriceX96) {
        if(address(this) > _WETH_)
            price = uint(2**192) / price;
        sqrtPriceX96 = SafeCast.toUint160(Math.sqrt(price.mul(2**96)));
    }
    
    function _rebDelta(address pool, uint price) public returns (uint delta) {
        (uint rebSpan, uint rebRate) = (_rebSpan, _rebRate);
        if(rebSpan == 0)
            rebSpan = ChipFactory(beacon).getConfig(_rebSpan_);
        if(rebRate == 0)
            rebRate = ChipFactory(beacon).getConfig(_rebRate_);
        (,,uint16 oi,,uint16 on,,) = IUniswapV3Pool(pool).slot0();
        if(oi+1 == on && on < uint16(rebSpan.add(11).div(12)))
            IUniswapV3Pool(pool).increaseObservationCardinalityNext(on+1);
        (int24 tick, ) = OracleLibrary.consult(pool, uint32(rebSpan));
        uint twap = OracleLibrary.getQuoteAtTick(tick, 2**96, address(this), _WETH_);
        uint dp = price > twap ? price - twap : twap - price;
        uint rp = dp.mul(1e6).div(twap).add(1);
        delta = _supply0.mul(Math.min(rebRate, rp)).div(rp).mul(Math.min(block.timestamp.sub(_lasttime), rebSpan)).div(rebSpan);
        _lasttime = block.timestamp;
    }

    //modifier onlyBeacon {
    //    require(_msgSender() == beacon, 'Only Beacon');
    //    _;
    //}
    //
    //function transfer_(address sender, address recipient, uint amount) external onlyBeacon {
    //    _transfer(sender, recipient, amount);
    //}
    //
    //function mint_(address account, uint amount) external onlyBeacon {
    //    _mint(account, amount);
    //}
    //
    //function burn_(address account, uint amount) external onlyBeacon {
    //    _burn(account, amount);
    //}

    // Reserved storage space to allow for layout changes in the future.
    uint[42] private ______gap;
}

contract ChipFactory is Configurable, ReentrancyGuardUpgradeSafe, ContextUpgradeSafe, Constants {
    using Address for address;

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
        config[_rebSpan_]       = 1800;     // 30min
        config[_rebRate_]       = 20;       // can inc liqudity 20/1000000*supply0 when TWAP changed 100% in rebSpan
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