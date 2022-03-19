/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
    uint256 j; 

    function _pickWinners(
        uint128 _nParticipants, 
        uint128 _nWinners,
        uint256 _randomNumber
    ) 
        public 
        returns (uint32[] memory)
    {
        j++;
        require(_randomNumber != 0, "Random number can't equal 0");
        uint32[] memory _winners = new uint32[](_nWinners);
        if (_randomNumber > 2**226) _randomNumber >>= 31; 

        // Linear congruential method
        // a = 1103515245, c = 12345: suggestion in the ISO/IEC 9899 
        // m = _nWinners
        for (uint128 i = 0; i < _nWinners; i++) {
            _randomNumber = uint32(_randomNumber * 1103515245 + 12345) / 65536;
            _winners[i] = uint32((_randomNumber % (_nParticipants + 1)) - 1);
        }
        return _winners;
    }
}