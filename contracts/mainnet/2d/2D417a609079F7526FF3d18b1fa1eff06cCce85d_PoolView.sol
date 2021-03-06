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

pragma solidity 0.7.6;
pragma abicoder v2;

import "./IPool.sol";
import "./libs/complifi/tokens/IERC20Metadata.sol";

contract PoolView {
    struct TokenRecord {
        address self;
        uint256 balance;
        uint256 leverage;
        uint8 decimals;
        uint256 userBalance;
    }

    struct Token {
        address self;
        uint256 totalSupply;
        uint8 decimals;
        uint256 userBalance;
    }

    struct Config {
        address derivativeVault;
        address dynamicFee;
        address repricer;
        uint exposureLimit;
        uint volatility;
        uint pMin;
        uint qMin;
        uint8 qMinDecimals;
        uint baseFee;
        uint maxFee;
        uint feeAmp;
        uint8 decimals;
    }

    function getPoolInfo(address _pool)
    external view
    returns (
        TokenRecord memory primary,
        TokenRecord memory complement,
        Token memory poolToken,
        Config memory config
    )
    {
        IPool pool = IPool(_pool);

        address _primaryAddress = address(pool.derivativeVault().primaryToken());
        primary = TokenRecord(
            _primaryAddress,
            pool.getBalance(_primaryAddress),
            pool.getLeverage(_primaryAddress),
            IERC20Metadata(_primaryAddress).decimals(),
            IERC20(_primaryAddress).balanceOf(msg.sender)
        );

        address _complementAddress = address(pool.derivativeVault().complementToken());
        complement = TokenRecord(
            _complementAddress,
            pool.getBalance(_complementAddress),
            pool.getLeverage(_complementAddress),
            IERC20Metadata(_complementAddress).decimals(),
            IERC20(_complementAddress).balanceOf(msg.sender)
        );

        poolToken = Token(
            _pool,
            pool.totalSupply(),
            IERC20Metadata(_pool).decimals(),
            IERC20(_pool).balanceOf(msg.sender)
        );

        config = Config(
            address(pool.derivativeVault()),
            address(pool.dynamicFee()),
            address(pool.repricer()),
            pool.exposureLimit(),
            pool.volatility(),
            pool.pMin(),
            pool.qMin(),
            IERC20Metadata(_primaryAddress).decimals(),
            pool.baseFee(),
            pool.maxFee(),
            pool.feeAmp(),
            IERC20Metadata(_pool).decimals()
        );
    }

    function getPoolTokenData(address _pool)
    external view
    returns (
        address primary,
        uint primaryBalance,
        uint primaryLeverage,
        uint8 primaryDecimals,
        address complement,
        uint complementBalance,
        uint complementLeverage,
        uint8 complementDecimals,
        uint lpTotalSupply,
        uint8 lpDecimals
    )
    {
        IPool pool = IPool(_pool);

        primary = address(pool.derivativeVault().primaryToken());
        complement = address(pool.derivativeVault().complementToken());

        primaryBalance = pool.getBalance(primary);
        primaryLeverage = pool.getLeverage(primary);
        primaryDecimals = IERC20Metadata(primary).decimals();

        complementBalance = pool.getBalance(complement);
        complementLeverage = pool.getLeverage(complement);
        complementDecimals = IERC20Metadata(complement).decimals();

        lpTotalSupply  = pool.totalSupply();
        lpDecimals = IERC20Metadata(_pool).decimals();
    }

    function getPoolConfig(address _pool)
    external view
    returns (
        address derivativeVault,
        address dynamicFee,
        address repricer,
        uint exposureLimit,
        uint volatility,
        uint pMin,
        uint qMin,
        uint baseFee,
        uint maxFee,
        uint feeAmp
    )
    {
        IPool pool = IPool(_pool);
        derivativeVault = address(pool.derivativeVault());
        dynamicFee = address(pool.dynamicFee());
        repricer = address(pool.repricer());
        pMin = pool.pMin();
        qMin = pool.qMin();
        exposureLimit = pool.exposureLimit();
        baseFee = pool.baseFee();
        feeAmp = pool.feeAmp();
        maxFee = pool.maxFee();
        volatility = pool.volatility();
    }
}

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

pragma solidity 0.7.6;

import "./Token.sol";
import "./IVault.sol";

interface IPool is IERC20 {

    function repricingBlock() external view returns(uint);

    function baseFee() external view returns(uint);
    function feeAmp() external view returns(uint);
    function maxFee() external view returns(uint);

    function pMin() external view returns(uint);
    function qMin() external view returns(uint);
    function exposureLimit() external view returns(uint);
    function volatility() external view returns(uint);

    function derivativeVault() external view returns(IVault);
    function dynamicFee() external view returns(address);
    function repricer() external view returns(address);

    function isFinalized()
    external view
    returns (bool);

    function getNumTokens()
    external view
    returns (uint);

    function getTokens()
    external view
    returns (address[] memory tokens);

    function getLeverage(address token)
    external view
    returns (uint);

    function getBalance(address token)
    external view
    returns (uint);

    function getController()
    external view
    returns (address);

    function setController(address manager)
    external;


    function joinPool(uint poolAmountOut, uint[2] calldata maxAmountsIn)
    external;

    function exitPool(uint poolAmountIn, uint[2] calldata minAmountsOut)
    external;

    function swapExactAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        address tokenOut,
        uint minAmountOut
    )
    external
    returns (uint tokenAmountOut, uint spotPriceAfter);
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

interface IERC20Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

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

pragma solidity 0.7.6;

import "./Num.sol";

// Highly opinionated token implementation

interface IERC20 {

    function totalSupply() external view returns (uint);
    function balanceOf(address whom) external view returns (uint);
    function allowance(address src, address dst) external view returns (uint);

    function approve(address dst, uint amt) external returns (bool);
    function transfer(address dst, uint amt) external returns (bool);
    function transferFrom(
        address src, address dst, uint amt
    ) external returns (bool);
}

contract TokenBase is Num {

    mapping(address => uint)                   internal _balance;
    mapping(address => mapping(address=>uint)) internal _allowance;
    uint internal _totalSupply;

    event Approval(address indexed src, address indexed dst, uint amt);
    event Transfer(address indexed src, address indexed dst, uint amt);

    function _mint(uint amt) internal {
        _balance[address(this)] = add(_balance[address(this)], amt);
        _totalSupply = add(_totalSupply, amt);
        emit Transfer(address(0), address(this), amt);
    }

    function _burn(uint amt) internal {
        require(_balance[address(this)] >= amt, "INSUFFICIENT_BAL");
        _balance[address(this)] = sub(_balance[address(this)], amt);
        _totalSupply = sub(_totalSupply, amt);
        emit Transfer(address(this), address(0), amt);
    }

    function _move(address src, address dst, uint amt) internal {
        require(_balance[src] >= amt, "INSUFFICIENT_BAL");
        _balance[src] = sub(_balance[src], amt);
        _balance[dst] = add(_balance[dst], amt);
        emit Transfer(src, dst, amt);
    }

    function _push(address to, uint amt) internal {
        _move(address(this), to, amt);
    }

    function _pull(address from, uint amt) internal {
        _move(from, address(this), amt);
    }
}

contract Token is TokenBase, IERC20 {

    string  private _name;
    string  private _symbol;
    uint8   private constant _decimals = 18;

    function setName(string memory name) internal {
        _name = name;
    }

    function setSymbol(string memory symbol) internal {
        _symbol = symbol;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }

    function allowance(address src, address dst) external view override returns (uint) {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external view override returns (uint) {
        return _balance[whom];
    }

    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }

    function approve(address dst, uint amt) external override returns (bool) {
        _allowance[msg.sender][dst] = amt;
        emit Approval(msg.sender, dst, amt);
        return true;
    }

    function increaseApproval(address dst, uint amt) external returns (bool) {
        _allowance[msg.sender][dst] = add(_allowance[msg.sender][dst], amt);
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function decreaseApproval(address dst, uint amt) external returns (bool) {
        uint oldValue = _allowance[msg.sender][dst];
        if (amt > oldValue) {
            _allowance[msg.sender][dst] = 0;
        } else {
            _allowance[msg.sender][dst] = sub(oldValue, amt);
        }
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function transfer(address dst, uint amt) external override returns (bool) {
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(address src, address dst, uint amt) external override returns (bool) {
        uint oldValue = _allowance[src][msg.sender];
        require(msg.sender == src || amt <= oldValue, "TOKEN_BAD_CALLER");
        _move(src, dst, amt);
        if (msg.sender != src && oldValue != uint256(-1)) {
            _allowance[src][msg.sender] = sub(oldValue, amt);
            emit Approval(msg.sender, dst, _allowance[src][msg.sender]);
        }
        return true;
    }
}

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

pragma solidity 0.7.6;

import "./Token.sol";
import "./libs/complifi/IDerivativeSpecification.sol";

interface IVault {
    /// @notice vault initialization time
    function initializationTime() external view returns(uint256);
    /// @notice start of live period
    function liveTime() external view returns(uint256);
    /// @notice end of live period
    function settleTime() external view returns(uint256);

    /// @notice underlying value at the start of live period
    function underlyingStarts(uint index) external view returns(int256);
    /// @notice underlying value at the end of live period
    function underlyingEnds(uint index) external view returns(int256);

    /// @notice primary token conversion rate multiplied by 10 ^ 12
    function primaryConversion() external view returns(uint256);
    /// @notice complement token conversion rate multiplied by 10 ^ 12
    function complementConversion() external view returns(uint256);

    // @notice derivative specification address
    function derivativeSpecification() external view returns(IDerivativeSpecification);
    // @notice collateral token address
    function collateralToken() external view returns(IERC20);
    // @notice oracle address
    function oracles(uint index) external view returns(address);
    function oracleIterators(uint index) external view returns(address);

    // @notice primary token address
    function primaryToken() external view returns(IERC20);
    // @notice complement token address
    function complementToken() external view returns(IERC20);
}

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

pragma solidity 0.7.6;

import "./Const.sol";

contract Num is Const {

    function toi(uint a)
        internal pure
        returns (uint)
    {
        return a / BONE;
    }

    function floor(uint a)
        internal pure
        returns (uint)
    {
        return toi(a) * BONE;
    }

    function add(uint a, uint b)
        internal pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }

    function sub(uint a, uint b)
        internal pure
        returns (uint c)
    {
        bool flag;
        (c, flag) = subSign(a, b);
        require(!flag, "SUB_UNDERFLOW");
    }

    function subSign(uint a, uint b)
        internal pure
        returns (uint, bool)
    {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function mul(uint a, uint b)
        internal pure
        returns (uint c)
    {
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "MUL_OVERFLOW");
        uint c1 = c0 + (BONE / 2);
        require(c1 >= c0, "MUL_OVERFLOW");
        c = c1 / BONE;
    }

    function div(uint a, uint b)
        internal pure
        returns (uint c)
    {
        require(b != 0, "DIV_ZERO");
        uint c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "DIV_INTERNAL"); // mul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "DIV_INTERNAL"); //  add require
        c = c1 / b;
    }

    // DSMath.wpow
    function powi(uint a, uint n)
        internal pure
        returns (uint z)
    {
        z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = mul(a, a);

            if (n % 2 != 0) {
                z = mul(z, a);
            }
        }
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `powi` for `b^e` and `powK` for k iterations
    // of approximation of b^0.w
    function pow(uint base, uint exp)
        internal pure
        returns (uint)
    {
        require(base >= MIN_POW_BASE, "POW_BASE_TOO_LOW");
        require(base <= MAX_POW_BASE, "POW_BASE_TOO_HIGH");

        uint whole  = floor(exp);
        uint remain = sub(exp, whole);

        uint wholePow = powi(base, toi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint partialResult = powApprox(base, remain, POW_PRECISION);
        return mul(wholePow, partialResult);
    }

    function powApprox(uint base, uint exp, uint precision)
        internal pure
        returns (uint sum)
    {
        // term 0:
        uint a     = exp;
        (uint x, bool xneg)  = subSign(base, BONE);
        uint term = BONE;
        sum   = term;
        bool negative = false;


        // term(k) = numer / denom
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint i = 1; term >= precision; i++) {
            uint bigK = i * BONE;
            (uint c, bool cneg) = subSign(a, sub(bigK, BONE));
            term = mul(term, mul(c, x));
            term = div(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = sub(sum, term);
            } else {
                sum = add(sum, term);
            }
        }
    }

    function min(uint first, uint second)
        internal pure
        returns (uint)
    {
        if(first < second) {
            return first;
        }
        return second;
    }
}

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

pragma solidity 0.7.6;

import "./Color.sol";

contract Const is Bronze {
    uint public constant BONE              = 10**18;
    int public constant  iBONE             = int(BONE);

    uint public constant MIN_POW_BASE      = 1 wei;
    uint public constant MAX_POW_BASE      = (2 * BONE) - 1 wei;
    uint public constant POW_PRECISION     = BONE / 10**10;

    uint public constant MAX_IN_RATIO      = BONE / 2;
    uint public constant MAX_OUT_RATIO     = (BONE / 3) + 1 wei;
}

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

pragma solidity 0.7.6;

abstract contract Color {
    function getColor()
        external view virtual
        returns (bytes32);
}

contract Bronze is Color {
    function getColor()
        external view override
        returns (bytes32) {
            return bytes32("BRONZE");
        }
}

// "SPDX-License-Identifier: GPL-3.0-or-later"

pragma solidity 0.7.6;

/// @title Derivative Specification interface
/// @notice Immutable collection of derivative attributes
/// @dev Created by the derivative's author and published to the DerivativeSpecificationRegistry
interface IDerivativeSpecification {
    /// @notice Proof of a derivative specification
    /// @dev Verifies that contract is a derivative specification
    /// @return true if contract is a derivative specification
    function isDerivativeSpecification() external pure returns (bool);

    /// @notice Set of oracles that are relied upon to measure changes in the state of the world
    /// between the start and the end of the Live period
    /// @dev Should be resolved through OracleRegistry contract
    /// @return oracle symbols
    function oracleSymbols() external view returns (bytes32[] memory);

    /// @notice Algorithm that, for the type of oracle used by the derivative,
    /// finds the value closest to a given timestamp
    /// @dev Should be resolved through OracleIteratorRegistry contract
    /// @return oracle iterator symbols
    function oracleIteratorSymbols() external view returns (bytes32[] memory);

    /// @notice Type of collateral that users submit to mint the derivative
    /// @dev Should be resolved through CollateralTokenRegistry contract
    /// @return collateral token symbol
    function collateralTokenSymbol() external view returns (bytes32);

    /// @notice Mapping from the change in the underlying variable (as defined by the oracle)
    /// and the initial collateral split to the final collateral split
    /// @dev Should be resolved through CollateralSplitRegistry contract
    /// @return collateral split symbol
    function collateralSplitSymbol() external view returns (bytes32);

    /// @notice Lifecycle parameter that define the length of the derivative's Live period.
    /// @dev Set in seconds
    /// @return live period value
    function livePeriod() external view returns (uint256);

    /// @notice Parameter that determines starting nominal value of primary asset
    /// @dev Units of collateral theoretically swappable for 1 unit of primary asset
    /// @return primary nominal value
    function primaryNominalValue() external view returns (uint256);

    /// @notice Parameter that determines starting nominal value of complement asset
    /// @dev Units of collateral theoretically swappable for 1 unit of complement asset
    /// @return complement nominal value
    function complementNominalValue() external view returns (uint256);

    /// @notice Minting fee rate due to the author of the derivative specification.
    /// @dev Percentage fee multiplied by 10 ^ 12
    /// @return author fee
    function authorFee() external view returns (uint256);

    /// @notice Symbol of the derivative
    /// @dev Should be resolved through DerivativeSpecificationRegistry contract
    /// @return derivative specification symbol
    function symbol() external view returns (string memory);

    /// @notice Return optional long name of the derivative
    /// @dev Isn't used directly in the protocol
    /// @return long name
    function name() external view returns (string memory);

    /// @notice Optional URI to the derivative specs
    /// @dev Isn't used directly in the protocol
    /// @return URI to the derivative specs
    function baseURI() external view returns (string memory);

    /// @notice Derivative spec author
    /// @dev Used to set and receive author's fee
    /// @return address of the author
    function author() external view returns (address);
}

