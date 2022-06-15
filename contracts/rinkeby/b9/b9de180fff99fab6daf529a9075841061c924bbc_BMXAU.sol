// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./BXAU.sol";
import "./Math.sol";
import "./ERC20.sol";

contract BMXAU is ERC20("Bone Marrow Gold", "BMXAU", 18), Math {
    BXAU   public immutable bxau;
    ERC20  public immutable dai;
    uint   public constant  priceFloor = 1e18;
    uint   public constant  fee        = 0.01 * 1e18;

    error Cratio();
    
    constructor(address _xauusd, address _daiusd, address _dai) {
	bxau    = new BXAU(address(this), _xauusd, _daiusd, _dai);
	dai     = ERC20(_dai);
    }

    function equityPerRC()
        public
	view
	returns (uint)
    {
    	return totalSupply == 0 ? 0 : wdiv(bxau.daiBalance() - bxau.liabilities(), totalSupply);
    }

    function mint(uint _wad)
        public
	returns (bool)
    {
        uint price            = max(priceFloor, equityPerRC());
	uint preFee           = wmul(_wad, price);
        uint total            = wmul(preFee, WAD + fee);
	uint allowance        = dai.allowance(msg.sender, address(this));
	if (allowance < total)  revert NSF();
	dai.transferFrom(msg.sender, address(bxau), total);
	balanceOf[msg.sender] = balanceOf[msg.sender] + _wad;
        totalSupply           = totalSupply           + _wad;
	emit                    Mint(_wad, msg.sender);
	return                  true;
    }

    function redeem(uint _wad)
    	public
	returns (bool)
    {
        if (balanceOf[msg.sender] < _wad) revert NSF();
	if (bxau.breachedCratio())        revert Cratio();
	uint preFee                       = wmul(_wad, equityPerRC());
	uint total                        = wmul(preFee, WAD - fee);
	balanceOf[msg.sender]             = balanceOf[msg.sender] - _wad;
        totalSupply                       = totalSupply           - _wad;	
	dai.transferFrom(address(bxau), msg.sender, total);
	if (bxau.breachedCratio())        revert Cratio();
	emit                              Redemption(_wad, msg.sender);
	return                            true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Math.sol";
import "./BMXAU.sol";
import "./ERC20.sol";
import "../lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract BXAU is ERC20("Bone Gold", "BXAU", 18), Math {
    AggregatorV3Interface public           xauusd;
    AggregatorV3Interface public           daiusd;
    ERC20                 public           dai;
    address               public           owner;
    uint                  public constant  fee          = 0.01 * 1e18;
    uint                  public constant  cratioFloor  = 1.1  * 1e18;
    
    error XAUUSD();
    error DAIUSD();
    error Cratio();
    
    constructor(address _owner, address _xauusd, address _daiusd, address _dai) {
	xauusd     = AggregatorV3Interface(_xauusd);
	daiusd     = AggregatorV3Interface(_daiusd);
	dai        = ERC20(_dai);
	dai.approve(_owner, type(uint).max);
	owner      = _owner;
    }

    function price()
        public
	view
	returns (uint)
    {
        (, int256 _iXAUUSD, , , ) = xauusd.latestRoundData();
	if (_iXAUUSD <= 0)          revert XAUUSD();
	uint _XAUUSD              = uint(_iXAUUSD) * 1e8;
	
        (, int256 _iDAIUSD, , , ) = daiusd.latestRoundData();
	if (_iDAIUSD <= 0)          revert DAIUSD();
	uint _DAIUSD              = uint(_iDAIUSD) * 1e8;

        uint _XAUDAI              = wmul(_XAUUSD, wdiv(WAD, _DAIUSD));
	if (totalSupply == 0)       return _XAUDAI;
	uint _reservePerSC        = wdiv(daiBalance(), totalSupply);
        return                      min(_XAUDAI, _reservePerSC);
    }

    function liabilities()
        public
	view
	returns (uint)
    {
        return wmul(totalSupply, price());   
    }

    function breachedCratio()
        public
	view
	returns (bool)
    {
	uint b             =  daiBalance();
        return b == 0 ? true : b <  wmul(cratioFloor, liabilities());
    }

    function daiBalance()
    	public
	view
	returns (uint)
    {
        return dai.balanceOf(address(this));
    }
    
    function mint(uint _wad)
        public
	returns (bool)
    {
        if (breachedCratio())   revert Cratio();
	uint preFee           = wmul(_wad, price());
	uint total            = wmul(preFee, WAD + fee);
	uint allowance        = dai.allowance(msg.sender, address(this));
	if (allowance < total)  revert NSF();
	dai.transferFrom(msg.sender, address(this), total);
	balanceOf[msg.sender] = balanceOf[msg.sender] + _wad;
        totalSupply           = totalSupply           + _wad;
	if (breachedCratio())   revert Cratio();
	emit Mint(_wad, msg.sender);
	return true;
    }
    
    function redeem(uint _wad)
        public
	returns (bool)
    {
        if (balanceOf[msg.sender] < _wad)  revert NSF();
	uint preFee                      = wmul(_wad, price());
	uint total                       = wmul(preFee, WAD - fee);
	dai.transfer(msg.sender, total);
	balanceOf[msg.sender]            = balanceOf[msg.sender] - _wad;
        totalSupply                      = totalSupply           - _wad;
	emit Redemption(_wad, msg.sender);
	return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract Math {
    uint constant WAD = 1e18;

    function min(uint x, uint y)
        internal
        pure
	returns (uint z)
    {
        z = x <= y ? x : y;
    }

    function max(uint x, uint y)
        internal
	pure
	returns (uint z)
    {
        return x >= y ? x : y;
    }

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y)
        internal
        pure
	returns (uint z)
    {
        z = (x * y + WAD / 2) / WAD;
    }
    
    //rounds to zero if x/y < y / 2
    function wdiv(uint x, uint y)
        internal
        pure
	returns (uint z)
    {
        z = (x * WAD + y / 2) / y;
    }
}

// Credit: https://github.com/dapphub/ds-math/blob/master/src/math.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract ERC20 {
    uint256                                           public totalSupply;
    mapping (address => uint256)                      public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    string                                            public name;
    string                                            public symbol;
    uint8                                             public decimals;

    event Approval  (address indexed src, address indexed guy, uint wad);
    event Transfer  (address indexed src, address indexed dst, uint wad);
    event Mint      (uint wad, address indexed dst);
    event Redemption(uint wad, address indexed dst);

    error NSF();

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name     = _name;
	symbol   = _symbol;
	decimals = _decimals;
    }
    
    function transfer(address _dst, uint _wad)
        external
        returns (bool)
    {
        return transferFrom(msg.sender, _dst, _wad);
    }
    
    function transferFrom(address _src, address _dst, uint _wad)
        public
        returns (bool)
    {
        if (_src != msg.sender  && allowance[_src][msg.sender] != type(uint).max) {
            if (allowance[_src][msg.sender] < _wad) revert NSF();
            allowance[_src][msg.sender] = allowance[_src][msg.sender] - _wad;
        }
        if (balanceOf[_src] < _wad) revert NSF();
        
        balanceOf[_src] = balanceOf[_src] - _wad;
        balanceOf[_dst] = balanceOf[_dst] - _wad;
        emit Transfer(_src, _dst, _wad);
        return true;
    }
    
    function approve(address _guy, uint _wad)
        public
        returns (bool)
    {
        allowance[msg.sender][_guy] = _wad;
        emit Approval(msg.sender, _guy, _wad);
        return true;
    }
}
// Credit
// - https://github.com/dapphub/ds-token/blob/master/src/token.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}