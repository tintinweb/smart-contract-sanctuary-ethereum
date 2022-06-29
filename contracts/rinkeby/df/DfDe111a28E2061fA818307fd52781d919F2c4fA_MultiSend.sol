// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Multi Send - 允许将多个事务批处理为一个
contract MultiSend {
    address private immutable multisendSingleton;

    constructor() {
        multisendSingleton = address(this);
    }

    /// @dev 发送多个事务并在一个失败时恢复所有事务。 
    /// @param transactions 编码的事务。每个事务都被编码为操作的打包字节作为 uint8， 其中 0 表示调用或 1 表示委托调用（=> 1 字节）， 到地址（=> 20 字节）， value as a uint256 (=> 32 bytes),  data length as a uint256 (=> 32 bytes), data as bytes.  有关打包编码的更多信息，请参阅 abi.encodePacked 
    /// @notice 此方法是付费的，因为委托调用会保留上一次调用的 msg.value 
    /// 如果调用方法（例如 execTransaction）收到 ETH，否则这将恢复
    function multiSend(bytes memory transactions) public payable {
        require(address(this) != multisendSingleton, "MultiSend should only be called via delegatecall");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let length := mload(transactions)
            let i := 0x20
            for {
                // Pre block is not used in "while mode"
            } lt(i, length) {
                // Post block is not used in "while mode"
            } {
                // 数据的第一个字节是操作。 
                // 我们向右移动 248 位（256 - 8 [操作字节]），因为 mload 将始终加载 32 字节（一个字）。 
                // 这也会清零未使用的数据。
                let operation := shr(0xf8, mload(add(transactions, i)))
                // We offset the load address by 1 byte (operation byte)
                // We shift it right by 96 bits (256 - 160 [20 address bytes]) to right-align the data and zero out unused data.
                let to := shr(0x60, mload(add(transactions, add(i, 0x01))))
                // We offset the load address by 21 byte (operation byte + 20 address bytes)
                let value := mload(add(transactions, add(i, 0x15)))
                // We offset the load address by 53 byte (operation byte + 20 address bytes + 32 value bytes)
                let dataLength := mload(add(transactions, add(i, 0x35)))
                // We offset the load address by 85 byte (operation byte + 20 address bytes + 32 value bytes + 32 data length bytes)
                let data := add(transactions, add(i, 0x55))
                let success := 0
                switch operation
                    case 0 {
                        success := call(gas(), to, value, data, dataLength, 0, 0)
                    }
                    case 1 {
                        success := delegatecall(gas(), to, data, dataLength, 0, 0)
                    }
                if eq(success, 0) {
                    revert(0, 0)
                }
                // Next entry starts at 85 byte + data length
                i := add(i, add(0x55, dataLength))
            }
        }
    }
}