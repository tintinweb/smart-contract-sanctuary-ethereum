// SPDX-License-Identifier: MIT

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

pragma solidity ^0.7.3;

import "./IERC20.sol";
import "./SafeMath.sol";

import "./ABDKMath64x64.sol";
import "./IAssimilator.sol";
import "./IOracle.sol";

contract GyenToUsdAssimilator is IAssimilator {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    using SafeMath for uint256;

    IERC20 private constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    IOracle private constant oracle = IOracle(0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3);
    IERC20 private constant gyen = IERC20(0xC08512927D12348F6620a698105e1BAac6EcD911);

    // solhint-disable-next-line
    constructor() {}

    function getRate() public view override returns (uint256) {
        (, int256 price, , , ) = oracle.latestRoundData();
        return uint256(price);
    }

    // takes raw gyen amount, transfers it in, calculates corresponding numeraire amount and returns it
    function intakeRawAndGetBalance(uint256 _amount) external override returns (int128 amount_, int128 balance_) {
        bool _transferSuccess = gyen.transferFrom(msg.sender, address(this), _amount);

        require(_transferSuccess, "Curve/gyen-transfer-from-failed");

        uint256 _balance = gyen.balanceOf(address(this));

        uint256 _rate = getRate();

        balance_ = ((_balance * _rate) / 1e8).divu(1e6);

        amount_ = ((_amount * _rate) / 1e8).divu(1e6);
    }

    // takes raw gyen amount, transfers it in, calculates corresponding numeraire amount and returns it
    function intakeRaw(uint256 _amount) external override returns (int128 amount_) {
        bool _transferSuccess = gyen.transferFrom(msg.sender, address(this), _amount);

        require(_transferSuccess, "Curve/gyen-transfer-from-failed");

        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 1e8).divu(1e6);
    }

    // takes a numeraire amount, calculates the raw amount of gyen, transfers it in and returns the corresponding raw amount
    function intakeNumeraire(int128 _amount) external override returns (uint256 amount_) {
        uint256 _rate = getRate();

        amount_ = (_amount.mulu(1e6) * 1e8) / _rate;

        bool _transferSuccess = gyen.transferFrom(msg.sender, address(this), amount_);

        require(_transferSuccess, "Curve/gyen-transfer-from-failed");
    }

    // takes a numeraire amount, calculates the raw amount of gyen, transfers it in and returns the corresponding raw amount
    function intakeNumeraireLPRatio(
        uint256 _baseWeight,
        uint256 _quoteWeight,
        address _addr,
        int128 _amount
    ) external override returns (uint256 amount_) {
        uint256 _gyenBal = gyen.balanceOf(_addr);

        if (_gyenBal <= 0) return 0;

        // 1e6
        _gyenBal = _gyenBal.mul(1e18).div(_baseWeight);

        // 1e6
        uint256 _usdcBal = usdc.balanceOf(_addr).mul(1e18).div(_quoteWeight);

        // Rate is in 1e6
        uint256 _rate = _usdcBal.mul(1e6).div(_gyenBal);

        amount_ = (_amount.mulu(1e6) * 1e6) / _rate;

        bool _transferSuccess = gyen.transferFrom(msg.sender, address(this), amount_);

        require(_transferSuccess, "Curve/gyen-transfer-failed");
    }

    // takes a raw amount of gyen and transfers it out, returns numeraire value of the raw amount
    function outputRawAndGetBalance(address _dst, uint256 _amount)
        external
        override
        returns (int128 amount_, int128 balance_)
    {
        uint256 _rate = getRate();

        uint256 _gyenAmount = ((_amount) * _rate) / 1e8;

        bool _transferSuccess = gyen.transfer(_dst, _gyenAmount);

        require(_transferSuccess, "Curve/gyen-transfer-failed");

        uint256 _balance = gyen.balanceOf(address(this));

        amount_ = _gyenAmount.divu(1e6);

        balance_ = ((_balance * _rate) / 1e8).divu(1e6);
    }

    // takes a raw amount of gyen and transfers it out, returns numeraire value of the raw amount
    function outputRaw(address _dst, uint256 _amount) external override returns (int128 amount_) {
        uint256 _rate = getRate();

        uint256 _gyenAmount = (_amount * _rate) / 1e8;

        bool _transferSuccess = gyen.transfer(_dst, _gyenAmount);

        require(_transferSuccess, "Curve/gyen-transfer-failed");

        amount_ = _gyenAmount.divu(1e6);
    }

    // takes a numeraire value of gyen, figures out the raw amount, transfers raw amount out, and returns raw amount
    function outputNumeraire(address _dst, int128 _amount) external override returns (uint256 amount_) {
        uint256 _rate = getRate();

        amount_ = (_amount.mulu(1e6) * 1e8) / _rate;

        bool _transferSuccess = gyen.transfer(_dst, amount_);

        require(_transferSuccess, "Curve/gyen-transfer-failed");
    }

    // takes a numeraire amount and returns the raw amount
    function viewRawAmount(int128 _amount) external view override returns (uint256 amount_) {
        uint256 _rate = getRate();

        amount_ = (_amount.mulu(1e6) * 1e8) / _rate;
    }

    function viewRawAmountLPRatio(
        uint256 _baseWeight,
        uint256 _quoteWeight,
        address _addr,
        int128 _amount
    ) external view override returns (uint256 amount_) {
        uint256 _gyenBal = gyen.balanceOf(_addr);

        if (_gyenBal <= 0) return 0;

        // 1e6
        _gyenBal = _gyenBal.mul(1e18).div(_baseWeight);

        // 1e6
        uint256 _usdcBal = usdc.balanceOf(_addr).mul(1e18).div(_quoteWeight);

        // Rate is in 1e6
        uint256 _rate = _usdcBal.mul(1e6).div(_gyenBal);

        amount_ = (_amount.mulu(1e6) * 1e6) / _rate;
    }

    // takes a raw amount and returns the numeraire amount
    function viewNumeraireAmount(uint256 _amount) external view override returns (int128 amount_) {
        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 1e8).divu(1e6);
    }

    // views the numeraire value of the current balance of the reserve, in this case gyen
    function viewNumeraireBalance(address _addr) external view override returns (int128 balance_) {
        uint256 _rate = getRate();

        uint256 _balance = gyen.balanceOf(_addr);

        if (_balance <= 0) return ABDKMath64x64.fromUInt(0);

        balance_ = ((_balance * _rate) / 1e8).divu(1e6);
    }

    // views the numeraire value of the current balance of the reserve, in this case gyen
    function viewNumeraireAmountAndBalance(address _addr, uint256 _amount)
        external
        view
        override
        returns (int128 amount_, int128 balance_)
    {
        uint256 _rate = getRate();

        amount_ = ((_amount * _rate) / 1e8).divu(1e6);

        uint256 _balance = gyen.balanceOf(_addr);

        balance_ = ((_balance * _rate) / 1e8).divu(1e6);
    }

    // views the numeraire value of the current balance of the reserve, in this case gyen
    // instead of calculating with chainlink's "rate" it'll be determined by the existing
    // token ratio
    // Mainly to protect LP from losing
    function viewNumeraireBalanceLPRatio(
        uint256 _baseWeight,
        uint256 _quoteWeight,
        address _addr
    ) external view override returns (int128 balance_) {
        uint256 _gyenBal = gyen.balanceOf(_addr);

        if (_gyenBal <= 0) return ABDKMath64x64.fromUInt(0);

        uint256 _usdcBal = usdc.balanceOf(_addr).mul(1e18).div(_quoteWeight);

        // Rate is in 1e6
        uint256 _rate = _usdcBal.mul(1e18).div(_gyenBal.mul(1e18).div(_baseWeight));

        balance_ = ((_gyenBal * _rate) / 1e6).divu(1e18);
    }
}