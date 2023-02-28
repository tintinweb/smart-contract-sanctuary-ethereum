// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/// @notice LayerZero Omnichain Fungible Token interface
interface IOFTCore {
    function estimateSendFee(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        bool _useZro,
        bytes calldata _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);
}

/// @notice LayerZero Goerli/Mainnet ETH bridge interface
interface ISwappableBridge {
    function swapAndBridge(
        uint256 amountIn,
        uint256 amountOutMin,
        uint16 dstChainId,
        address to,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) external payable;

    function oft() external returns (address);
}

/// @title GoerliFriends
/// @notice Dump Goerli ETH, send proceeds to Protocol Guild
/// @author horsefacts <[email protected]>
contract GoerliFriends {
    event Dump(address indexed caller, uint256 amount);
    event Contribute(address indexed goerliFriend, uint256 amount);

    /// @notice LayerZero mainnet chain ID
    uint16 public constant LZ_MAINNET_CHAIN_ID = 101;

    /// @notice Mainnet protocol guild split contract
    /// https://protocol-guild.readthedocs.io/en/latest/3-smart-contract.html#split-contract
    address payable public constant PROTOCOL_GUILD_SPLIT = payable(address(0x84af3D5824F0390b9510440B6ABB5CC02BB68ea1));

    /// @notice LayerZero Goerli/Mainnet ETH bridge
    ISwappableBridge public constant bridge = ISwappableBridge(0x0A9f824C05A74F577A536A8A0c673183a872Dff4);

    /// @notice LayerZero Omnichain Fungible Token contract, used to estimate native gas fee
    IOFTCore public immutable oft;

    constructor() {
        oft = IOFTCore(bridge.oft());
    }

    /// @notice Dump Goerli ETH for mainnet ETH and send proceeds to the mainnet Protocol Guild split contract.
    /// Dumps the full contract balance. If contract balance is less than 100 Goerli ETH, your contribution
    /// will be pooled and dumped once the balance is sufficient to swap and bridge. You may also send Goerli ETH
    /// directly to this contract to contribute to the pooled balance.
    function dump() external payable {
        emit Contribute(msg.sender, msg.value);

        // We'll dump the full contract balance if it's above a minimum amount
        uint256 balance = address(this).balance;
        // Only dump if contract balance is > 100 Goerli ETH
        if (balance > 100 ether) {
            // Calculate native gas fee in Goerli ETH
            (uint256 nativeFee,) =
                oft.estimateSendFee(LZ_MAINNET_CHAIN_ID, abi.encodePacked(PROTOCOL_GUILD_SPLIT), balance, false, "");
            // 100 ETH is just a heuristic and fees might change. Revert with a nice message if bridge fee exceeds balance
            if (nativeFee > balance) revert("Bridge fee > contract balance");
            // Swap, bridge, and send ETH proceeds to mainnet Protocol Guild split contract
            bridge.swapAndBridge{value: balance}(
                balance - nativeFee, 0, LZ_MAINNET_CHAIN_ID, PROTOCOL_GUILD_SPLIT, PROTOCOL_GUILD_SPLIT, address(0), ""
            );
            emit Dump(msg.sender, balance);
        }
    }

    receive() external payable {
        emit Contribute(msg.sender, msg.value);
    }
}