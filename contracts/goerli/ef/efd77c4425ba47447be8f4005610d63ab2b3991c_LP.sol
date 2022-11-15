// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract LP {
    uint256 public liquidity = 1e12;
    uint256 public multiplier = 1e6;
    uint256[3] public ratiosWin = [45000000, 25000000, 30000000];
    uint256 public totalNetBet;
    uint256 public totalPayOut;

    function placeBet(uint256 _amount, uint8 _outcome) public returns (uint256, uint8, uint256) {
        if (_outcome != 0 && _outcome != 1 && _outcome != 2) revert IncorectOutcome();
        uint256 _odd = (liquidity + _amount) / (liquidity * ratiosWin[_outcome] / multiplier + _amount);
        if (totalPayOut + _amount * _odd >= liquidity) revert NotEnoughLiquidity();
        for (uint8 i = 0; i < 3; i++) {
            if (i != _amount) {
                ratiosWin[i] = (ratiosWin[i] / 100 * liquidity / multiplier) / (liquidity + _amount);
            } else {
                ratiosWin[i] = (ratiosWin[i] / 100 * liquidity / multiplier + _amount) / (liquidity + _amount);
            }
        }
        liquidity += _amount;
        totalPayOut += _amount * _odd;
        return (_amount, _outcome, _odd);
    }

    error IncorectOutcome();
    error NotEnoughLiquidity();
}