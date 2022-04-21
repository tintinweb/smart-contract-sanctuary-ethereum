pragma solidity >=0.5.0;

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

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >0.4.13;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    //rounds to zero if x*y < WAD / 2
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    //rounds to zero if x*y < RAY / 2
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: GNU-3
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.4.23;

interface DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) external view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(address(0))) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

/// token.sol -- ERC20 implementation with minting and burning

// Copyright (C) 2015, 2016, 2017  DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.4.23 <0.7.0;

import "ds-math/math.sol";
import "ds-auth/auth.sol";


contract DSToken is DSMath, DSAuth {
    bool                                              public  stopped;
    uint256                                           public  totalSupply;
    mapping (address => uint256)                      public  balanceOf;
    mapping (address => mapping (address => uint256)) public  allowance;
    string                                            public  symbol;
    uint8                                             public  decimals = 18; // standard token precision. override to customize
    string                                            public  name = "";     // Optional token name


    constructor(string memory symbol_) public {
        symbol = symbol_;
    }

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Mint(address indexed guy, uint wad);
    event Burn(address indexed guy, uint wad);
    event Stop();
    event Start();

    modifier stoppable {
        require(!stopped, "ds-stop-is-stopped");
        _;
    }

    function approve(address guy) external returns (bool) {
        return approve(guy, uint(-1));
    }

    function approve(address guy, uint wad) public stoppable returns (bool) {
        allowance[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);

        return true;
    }

    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        stoppable
        returns (bool)
    {
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "ds-token-insufficient-approval");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }

        require(balanceOf[src] >= wad, "ds-token-insufficient-balance");
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function push(address dst, uint wad) external {
        transferFrom(msg.sender, dst, wad);
    }

    function pull(address src, uint wad) external {
        transferFrom(src, msg.sender, wad);
    }

    function move(address src, address dst, uint wad) external {
        transferFrom(src, dst, wad);
    }


    function mint(uint wad) external {
        mint(msg.sender, wad);
    }

    function burn(uint wad) external {
        burn(msg.sender, wad);
    }

    function mint(address guy, uint wad) public auth stoppable {
        balanceOf[guy] = add(balanceOf[guy], wad);
        totalSupply = add(totalSupply, wad);
        emit Mint(guy, wad);
    }

    function burn(address guy, uint wad) public auth stoppable {
        if (guy != msg.sender && allowance[guy][msg.sender] != uint(-1)) {
            require(allowance[guy][msg.sender] >= wad, "ds-token-insufficient-approval");
            allowance[guy][msg.sender] = sub(allowance[guy][msg.sender], wad);
        }

        require(balanceOf[guy] >= wad, "ds-token-insufficient-balance");
        balanceOf[guy] = sub(balanceOf[guy], wad);
        totalSupply = sub(totalSupply, wad);
        emit Burn(guy, wad);
    }

    function stop() public auth {
        stopped = true;
        emit Stop();
    }

    function start() public auth {
        stopped = false;
        emit Start();
    }


    function setName(string memory name_) public auth {
        name = name_;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "ds-token/token.sol";
import "./Math.sol";
import "./Token.sol";
import "../lib/chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol";

// Issues and manage stabecoins.
contract DaiPool is DSToken, Math {
    uint public constant RESERVE_MULTIPLE_MIN = 1.5 * 10 * WAD / 10;
    uint public constant FEE_MULTIPLE = 0.0025 * 10000 * WAD / 10000;
 
    Token public dai;
    AggregatorV3Interface public agg;

    event Buy(address indexed guy, uint wad);
    event Sell(address indexed guy, uint wad);
    event GiveDai(address indexed guy, uint wad);
    event TakeDai(address indexed guy, uint wad);

    constructor (address _pip, address _dai, string memory _name, string memory _symbol) DSToken(_symbol) public {
        agg = AggregatorV3Interface(_pip);
        dai = Token(_dai);
        name = _name;
    }
    // --- view ---
    function reserveBalance() public view returns (uint) {
        // TODO: Can enforce this function to be view?
        return dai.balanceOf(address(this));
    }
    function price() public view returns (uint) {
        // TODO: Can enforce this function to be view?
        (, int256 _price, , , )  = agg.latestRoundData();
        if (_price <= 0 ) { revert("Non-positive price."); }
        return uint(_price) * 10 ** sub(decimals, uint(agg.decimals()));
    }
    function liability() public view returns (uint) {
        return wmul(price(), totalSupply);
    }
    function equity() public view returns (uint) {
        return sub(reserveBalance(), liability());
    }
    function aboveMinReserveReq(uint _added) public view returns (bool) {
        return add(reserveBalance(), _added) >= wmul(RESERVE_MULTIPLE_MIN, liability());
    }
    // --- side effects ---
    function takeDai(address _usr, uint _wad) private {
        require(dai.allowance(_usr, address(this)) >= _wad, "DaiPool/too-little-dai-allowance");
        dai.transferFrom(_usr, address(this), _wad);
        emit TakeDai(_usr, _wad);
    }
    function giveDai(address _usr, uint _wad) public auth {
        require(dai.balanceOf(address(this)) >= _wad, "DaiPool/too-little-dai-balance");
        dai.transfer(_usr, _wad);
        emit GiveDai(_usr, _wad);
    }
    function buy(uint _wad, uint _dai) external {
        require(aboveMinReserveReq(0), "DaiPool/breached-minimum-reserve-requirement-before");
        uint _afterFee = afterFeeAdded(FEE_MULTIPLE, price(), _wad);
        require(_dai == _afterFee, "DaiPool/unexpected-dai-provision-amount");
        require(aboveMinReserveReq(_afterFee), "DaiPool/breached-minimum-reserve-requirement-after");
        takeDai(msg.sender, _afterFee);
        balanceOf[msg.sender] = add(balanceOf[msg.sender], _wad);
        totalSupply = add(totalSupply, _wad);
        emit Buy(msg.sender, _wad);
    }
    function sell(uint _wad, uint _dai) external {
        require(balanceOf[msg.sender] >= _wad, "DaiPool/insufficient-balance");
        require(_dai == afterFeeSubtracted(FEE_MULTIPLE, price(), _wad), "DaiPool/unexpected-dai-request-amount");
        balanceOf[msg.sender] = sub(balanceOf[msg.sender], _wad);
        totalSupply = sub(totalSupply, _wad);
        giveDai(msg.sender, _dai);
        emit Sell(msg.sender, _wad);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

import "ds-math/math.sol";

contract Math is DSMath {
    function beforeFeeAndFee(uint _feeMultiple, uint _price, uint _qty) internal pure returns (uint, uint) {
        uint _beforeFee = wmul(_price, _qty);
        return (_beforeFee, wmul(_feeMultiple, _beforeFee));
    }
    function afterFeeAdded(uint _feeMultiple, uint _price, uint _qty) internal pure returns (uint) {
        (uint _beforeFee, uint _fee) = beforeFeeAndFee(_feeMultiple, _price, _qty);
        return add(_beforeFee, _fee);
    }
    function afterFeeSubtracted(uint _feeMultiple, uint _price, uint _qty) internal pure returns (uint) {
        (uint _beforeFee, uint _fee) = beforeFeeAndFee(_feeMultiple, _price, _qty);
        return sub(_beforeFee, _fee);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

interface Token {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value)  external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender  , uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}