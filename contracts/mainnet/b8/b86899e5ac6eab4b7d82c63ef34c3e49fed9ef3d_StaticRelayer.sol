/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

// Lightweight interface for Collybus
// Source: https://github.com/fiatdao/fiat-lux/blob/f49a9457fbcbdac1969c35b4714722f00caa462c/src/interfaces/ICollybus.sol
interface ICollybus {
    function updateDiscountRate(uint256 tokenId_, uint256 rate_) external;

    function updateSpot(address token_, uint256 spot_) external;
}interface IRelayer {
    enum RelayerType {
        DiscountRate,
        SpotPrice,
        COUNT
    }

    function execute() external returns (bool);

    function executeWithRevert() external;
}
contract StaticRelayer is IRelayer {
    /// @notice Emitted during executeWithRevert() if the Collybus was already updated
    error StaticRelayer__executeWithRevert_collybusAlreadyUpdated(
        IRelayer.RelayerType relayerType
    );

    /// ======== Events ======== ///

    event UpdatedCollybus(
        bytes32 tokenId,
        uint256 rate,
        IRelayer.RelayerType relayerType
    );

    /// ======== Storage ======== ///

    address public immutable collybus;
    IRelayer.RelayerType public immutable relayerType;
    bytes32 public immutable encodedTokenId;
    uint256 public immutable value;

    // Flag used to ensure that the value is pushed to Collybus only once
    bool private _updatedCollybus;

    constructor(
        address collybusAddress_,
        IRelayer.RelayerType type_,
        bytes32 encodedTokenId_,
        uint256 value_
    ) {
        collybus = collybusAddress_;
        relayerType = type_;
        encodedTokenId = encodedTokenId_;
        value = value_;
        _updatedCollybus = false;
    }

    /// @notice Pushes the hardcoded value to Collybus for the hardcoded token id
    /// @dev The execute will exit early after the first update
    function execute() public override(IRelayer) returns (bool) {
        if (_updatedCollybus) return false;

        _updatedCollybus = true;
        if (relayerType == IRelayer.RelayerType.DiscountRate) {
            ICollybus(collybus).updateDiscountRate(
                uint256(encodedTokenId),
                value
            );
        } else if (relayerType == IRelayer.RelayerType.SpotPrice) {
            ICollybus(collybus).updateSpot(
                address(uint160(uint256(encodedTokenId))),
                value
            );
        }

        emit UpdatedCollybus(encodedTokenId, value, relayerType);
        return true;
    }

    /// @notice The function will call `execute()` and will revert if _updatedCollybus is true
    function executeWithRevert() public override(IRelayer) {
        if (!execute()) {
            revert StaticRelayer__executeWithRevert_collybusAlreadyUpdated(
                relayerType
            );
        }
    }
}