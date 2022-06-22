// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Synth.sol";
import "./BMW.sol";

contract BXAU is Synth {
    constructor(BMW _bmw, address _xauusd, address _daiusd, address _dai)
        // TODO: the floor must be enforced to have higher floor than redemption cratio floor in reserve.
        Synth(_bmw, _xauusd, _daiusd, _dai, 0.01 * 1e18, 2 * 1e18, "Bone Gold", "BXAU")
    {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./BMW.sol";
import "./Math.sol";
import "./ERC20.sol";
import "./IERC20Synth.sol";
import "../lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Synth is ERC20, IERC20Synth, Math {
    AggregatorV3Interface public           refusd;
    AggregatorV3Interface public           daiusd;
    BMW                   public           bmw;
    ERC20                 public           dai;
    uint                  public immutable fee;
    uint                  public immutable cratioFloor;

    event                 Mint(address indexed guy, uint wad);
    event                 Redemption(address indexed guy, uint wad);

    error REFUSD();
    error DAIUSD();
    error Cratio();

    constructor(
        BMW           _bmw,
	address       _refusd,
	address       _daiusd,
	address       _dai,
	uint          _fee,
	uint          _cratioFloor,
	string memory _name,
	string memory _symbol
    ) ERC20(_name, _symbol, 18)
    {
        bmw         = _bmw;
	refusd      = AggregatorV3Interface(_refusd);
	daiusd      = AggregatorV3Interface(_daiusd);
	dai         = ERC20(_dai);
	fee         = _fee;
	cratioFloor = _cratioFloor;
    }

    function mintPrice()
        virtual
        public
	view
	returns (uint)
    {
        (, int256 _iREFUSD, , , ) = refusd.latestRoundData();
	if (_iREFUSD <= 0)          revert REFUSD();
	uint _REFUSD              = uint(_iREFUSD) * 1e8;

        (, int256 _iDAIUSD, , , ) = daiusd.latestRoundData();
	if (_iDAIUSD <= 0)          revert DAIUSD();
	uint _DAIUSD              = uint(_iDAIUSD) * 1e8;
        return                      wmul(_REFUSD, wdiv(WAD, _DAIUSD));
    }

    function redemptionPrice()
        virtual
        public
	view
	returns (uint)
    {
        return mintPrice();
    }

    function liability()
        virtual
        public
	view
	returns (uint)
    {
        return wmul(totalSupply, redemptionPrice());
    }

    function mint(uint _wad)
        virtual
        public
	returns (bool)
    {
        if (bmw.cratio() < cratioFloor)   revert Cratio();
	uint total             = wmul(wmul(_wad, mintPrice()), WAD + fee);
	dai.transferFrom(msg.sender, address(bmw), total);
	balanceOf[msg.sender]  = balanceOf[msg.sender] + _wad;
        totalSupply            = totalSupply           + _wad;
        if (bmw.cratio() < cratioFloor)   revert Cratio();
	emit Mint(msg.sender, _wad);
	return true;
    }

    function redeem(uint _wad)
        virtual
        public
	returns (bool)
    {
        if (balanceOf[msg.sender] < _wad)  revert NSF();
	uint _liability  = liability();
        uint _price;
	if (_liability == 0 || totalSupply == 0) {
	     _price                           = redemptionPrice();
	} else {
	     uint _liabilityFraction          = wdiv(_liability, bmw.liability());
	     uint _reserveShare               = wmul(_liabilityFraction, bmw.reserve());
	     uint _reservePerToken            = wdiv(_reserveShare, totalSupply);
	     _price                           = min(_reservePerToken, redemptionPrice());
	}
        uint _total                       = wmul(wmul(_wad, _price), WAD - fee);
	dai.transferFrom(address(bmw), msg.sender, _total);
	balanceOf[msg.sender]            = balanceOf[msg.sender] - _wad;
        totalSupply                      = totalSupply           - _wad;
	emit Redemption(msg.sender, _wad);
	return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Math.sol";
import "./ERC20.sol";
import "./IERC20Synth.sol";

contract BMW is ERC20("Bone Marrow", "BMW", 18), Math {
    ERC20         public immutable dai;
    IERC20Synth[] public           synths;
    address       public           ownerTestnet;
    uint          public constant  priceFloor   = 1e18;
    uint          public constant  fee          = 0.003 * 1e18;
    uint          public           cratioFloor  = 2 * 1e18;

    error Cratio();
    event         Mint(address indexed guy, uint wad);
    event         Redemption(address indexed guy, uint wad);

    constructor(address _dai)
    {
	dai            = ERC20(_dai);
	ownerTestnet   = msg.sender;
    }

    function equityPerToken()
        public
	view
	returns (uint)
    {
    	return wdiv(equity(), totalSupply);
    }

    function equity()
        public
	view
	returns (uint)
    {
        return reserve() - liability();
    }

    function reserve()
        public
	view
	returns (uint)
    {
        return dai.balanceOf(address(this));
    }


    function liability()
        public
	view
	returns (uint)
    {
        uint sum = 0;
        for (uint i = 0; i < synths.length; i++)
	    sum = sum + synths[i].liability();
        return sum;
    }

    function cratio()
        public
	view
	returns (uint)
    {
        uint _liability = liability();
	uint _reserve   = reserve();
	if (_reserve == 0) return 0;
	if (_liability == 0) return type(uint).max;
        return wdiv(_reserve, _liability);
    }

    function mintPrice()
        public
	view
	returns (uint)
    {
        return totalSupply == 0 ? priceFloor : max(priceFloor, equityPerToken());
    }

    function redemptionPrice()
        public
	view
	returns (uint)
    {
        return totalSupply == 0 ? 0 : equityPerToken();
    }

    // TODO: auth
    function pushSynth(address _synth)
        public
	returns (bool)
    {
        if (!(msg.sender == ownerTestnet)) revert("On testnet, only owner can approve new asset.");
        synths.push(IERC20Synth(_synth));
	dai.approve(_synth, type(uint).max);
	return true;
    }

    function mint(uint _wad)
        public
	returns (bool)
    {
        uint total            = wmul(wmul(_wad, mintPrice()), WAD + fee);
	dai.transferFrom(msg.sender, address(this), total);
	balanceOf[msg.sender] = balanceOf[msg.sender] + _wad;
        totalSupply           = totalSupply           + _wad;
	emit                    Mint(msg.sender, _wad);
	return                  true;
    }

    function redeem(uint _wad)
    	public
	returns (bool)
    {
        if (balanceOf[msg.sender] < _wad) revert NSF();
	if (cratio() < cratioFloor)       revert Cratio();
	uint total                        = wmul(wmul(_wad, redemptionPrice()), WAD - fee);
	balanceOf[msg.sender]             = balanceOf[msg.sender] - _wad;
        totalSupply                       = totalSupply           - _wad;
	dai.transfer(msg.sender, total);
	if (cratio() < cratioFloor)       revert Cratio();
	emit                              Redemption(msg.sender, _wad);
	return                            true;
    }
}

// SPDX-License-Identifier: UNLICENSED
// Credit: https://github.com/dapphub/ds-math/blob/master/src/math.sol
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

// SPDX-License-Identifier: UNLICENSED
// Credit: https://github.com/dapphub/ds-token/blob/master/src/token.sol
pragma solidity 0.8.13;

import "./IERC20.sol";

contract ERC20 is IERC20 {
    uint256                                           public totalSupply;
    mapping (address => uint256)                      public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    string                                            public name;
    string                                            public symbol;
    uint8                                             public decimals;

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
            if (allowance[_src][msg.sender] < _wad) revert NSA();
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

pragma solidity 0.8.13;

import "./IERC20.sol";

interface IERC20Synth is IERC20 {
    function mintPrice()       external view returns (uint256);
    function redemptionPrice() external view returns (uint256);
    function fee()             external view returns (uint256);
    function cratioFloor()     external view returns (uint256);
    function liability()       external view returns (uint256);
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
// Credit: https://github.com/OpenZeppelin/openzeppelin-contracts/blame/master/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    error NSF();

    error NSA();

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}