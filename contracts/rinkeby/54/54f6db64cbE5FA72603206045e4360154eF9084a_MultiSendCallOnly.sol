// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;


/// @title Multi Send Call Only - 允许将多个事务批处理为一个 
/// @notice 此处不需要保护逻辑，因为此合约不支持嵌套委托调用
contract MultiSendCallOnly {
    /// @dev 发送多个事务并在一个失败时恢复所有事务。 
    /// @param transactions 编码的事务。每个事务都被编码为 操作的打包字节在这个版本中必须是 uint8(0)（=> 1 字节）， 到作为地址（=> 20 字节），
    /// 值作为 uint256 (=> 32 bytes), 数据长度为 uint256 (=> 32 bytes), 数据为字节。 有关打包编码的更多信息，请参阅 abi.encodePacked 
    /// @notice 代码大部分与正常的 MultiSend 相同（以保持兼容性）， 但如果事务尝试使用委托调用，则会恢复。 
    /// @notice 这个方法是有偿的，因为delegatecalls 保留了前一次调用的 msg.value 如果调用方法（例如execTransaction）收到 ETH，否则这将恢复
    function multiSend(bytes memory transactions) public payable {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let length := mload(transactions)
            let i := 0x20
            for {
                // 在 "while mode" 中不使用预块
            } lt(i, length) {
                // 帖子块不用于 "while mode"
            } {
                // 数据的第一个字节是操作。 我们向右移动 248 位（256 - 8 [操作字节]）， 因为 mload 将始终加载 32 字节（一个字）。 
                // 这也会清零未使用的数据。
                let operation := shr(0xf8, mload(add(transactions, i)))
                // 我们将加载地址偏移 1 个字节（操作字节） 
                // 我们将其右移 96 位（256 - 160 [20 地址字节]）以右对齐数据并将未使用的数据清零。
                let to := shr(0x60, mload(add(transactions, add(i, 0x01))))
                // 我们将加载地址偏移 21 个字节（操作字节 + 20 个地址字节）
                let value := mload(add(transactions, add(i, 0x15)))
                // 我们将加载地址偏移 53 个字节（操作字节 + 20 个地址字节 + 32 个值字节）
                let dataLength := mload(add(transactions, add(i, 0x35)))
                // 我们将加载地址偏移 85 个字节（操作字节 + 20 个地址字节 + 32 个值字节 + 32 个数据长度字节）
                let data := add(transactions, add(i, 0x55))
                let success := 0
                switch operation
                    case 0 {
                        success := call(gas(), to, value, data, dataLength, 0, 0)
                    }
                    // 此版本不允许委托调用
                    case 1 {
                        revert(0, 0)
                    }
                if eq(success, 0) {
                    revert(0, 0)
                }
                // 下一个条目从 85 字节 + 数据长度开始
                i := add(i, add(0x55, dataLength))
            }
        }
    }
}