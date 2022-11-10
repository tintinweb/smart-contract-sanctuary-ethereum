/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

interface IExchange {

    /// @notice Emitted when the global funding growth is updated
    /// @param baseToken Address of the base token
    /// @param markTwap The market twap price when the funding growth is updated
    /// @param indexTwap The index twap price when the funding growth is updated
    event FundingUpdated(address indexed baseToken, uint256 markTwap, uint256 indexTwap);
}

contract mockEventcall is IExchange {

    function emitFundingUpdated(uint _mktPrice, uint _idxPrice) public {
        emit FundingUpdated (msg.sender, _mktPrice, _idxPrice);
    }

}