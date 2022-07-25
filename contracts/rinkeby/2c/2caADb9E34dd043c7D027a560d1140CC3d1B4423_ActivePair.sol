/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC20 {
    function balanceOf(address account) 
        external 
        view 
        returns (uint256);
}

interface IFactory {
    function allPairs(uint256) 
        external 
        view 
        returns (address pair);

    function allPairsLength() 
        external 
        view 
        returns (uint256);
}

/// @title Active Pair for any Chain
/// @author Matrixswap
contract ActivePair {
    /// @notice Get all the pairs available for the user
    function getActivePairs(address _factory, address _user) 
        external 
        view 
        returns (address[] memory _activePairs) 
    {
        uint256 _allPairsLength = IFactory(_factory).allPairsLength();
        _activePairs = new address[](_allPairsLength);
        for (uint256 i = 0; i < _allPairsLength; i++) {
            address _pair = IFactory(_factory).allPairs(i);
            uint256 _pairBalance = IERC20(_pair).balanceOf(_user);
            if (_pairBalance > 0) {
                _activePairs[i] = _pair;
            }
            else {
                _activePairs[i] = address(0x0);
            }
        }
    }
}