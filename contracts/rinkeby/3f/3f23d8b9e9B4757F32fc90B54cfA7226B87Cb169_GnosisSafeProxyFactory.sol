// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title IProxy - 访问链上 Proxy 的 masterCopy 的 Helper 接口
interface IProxy {
    function masterCopy() external view returns (address);
}

/// @title GnosisSafeProxy - 通用代理合约允许执行应用主合约代码的所有交易
contract GnosisSafeProxy {
    // 单例总是需要首先声明变量，以确保它在委托调用的合约中的相同位置， 为了降低部署成本，这个变量是内部变量，需要通过 `getStorageAt` 检索
    address internal singleton;

    /// @dev 构造函数设置单例合约的地址。
    /// @param _singleton Singleton address.
    constructor(address _singleton) {
        require(_singleton != address(0), "Invalid singleton address provided");
        singleton = _singleton;
    }

    /// @dev Fallback 函数转发所有交易并返回所有收到的返回数据
    fallback() external payable {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let _singleton := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            // 0xa619486e == keccak("masterCopy()"). The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, _singleton)
                return(0, 0x20)
            }
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./GnosisSafeProxy.sol";
import "./IProxyCreationCallback.sol";

/// @title Proxy Factory - 允许在一个事务中创建新的代理联系人并执行对新代理的消息调用
/// @author Stefan George - <[email protected]>
contract GnosisSafeProxyFactory {
    event ProxyCreation(GnosisSafeProxy proxy, address singleton);

    /// @dev 允许在一个事务中 创建新的代理联系人 并执行 对新代理的消息调用 
    /// @param singleton 单例合约的地址
    /// @param data 发送到新代理合约的消息调用的有效载荷
    function createProxy(address singleton, bytes memory data) public returns (GnosisSafeProxy proxy) {
        proxy = new GnosisSafeProxy(singleton);
        if (data.length > 0)
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if eq(call(gas(), proxy, 0, add(data, 0x20), mload(data), 0, 0), 0) {
                    revert(0, 0)
                }
            }
        emit ProxyCreation(proxy, singleton);
    }

    /// @dev 允许检索已部署代理的运行时代码。这可用于检查是否部署了预期的代理
    function proxyRuntimeCode() public pure returns (bytes memory) {
        return type(GnosisSafeProxy).runtimeCode;
    }

   /// @dev 允许检索用于代理部署的创建代码。这样就可以很容易地计算预测地址
   function proxyCreationCode() public pure returns (bytes memory) {
        return type(GnosisSafeProxy).creationCode;
    }

    /// @dev 允许使用 CREATE2 创建新的代理联系人，但它不运行初始化程序 
    /// 此方法仅用作从其他方法调用的实用程序 
    /// @param _singleton 单例合约的地址
    /// @param initializer 发送到新代理合约的消息调用的有效载荷 
    /// @param saltNonce Nonce 将用于生成盐以计算新代理合约的地址
    function deployProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) internal returns (GnosisSafeProxy proxy) {
        // 如果初始化器改变了代理地址也应该改变。散列初始化数据比仅仅连接它更便宜
        bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), saltNonce));
        bytes memory deploymentData = abi.encodePacked(type(GnosisSafeProxy).creationCode, uint256(uint160(_singleton)));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            proxy := create2(0x0, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        require(address(proxy) != address(0), "Create2 call failed");
    }

   /// @dev 允许在一个事务中 创建新的代理联系人 并执行 对新代理的消息调用 
   /// @param _singleton 单例合约地址
   /// @param initializer 发送到新代理合约的消息调用的有效载荷 
   /// @param saltNonce Nonce 将用于生成盐以计算新代理合约的地址
   function createProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) public returns (GnosisSafeProxy proxy) {
        proxy = deployProxyWithNonce(_singleton, initializer, saltNonce);
        if (initializer.length > 0)
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if eq(call(gas(), proxy, 0, add(initializer, 0x20), mload(initializer), 0, 0), 0) {
                    revert(0, 0)
                }
            }
        emit ProxyCreation(proxy, _singleton);
    }

    /// @dev 允许创建新的代理联系人， 对新代理执行消息调用，并在一个事务中调用指定的回调 
    /// @param _singleton 单例合约的地址
    /// @param initializer 发送到新代理合约的消息调用的有效载荷 
    /// @param saltNonce Nonce 将用于生成盐以计算新代理合约的地址 
    /// @param callback 新代理合约成功部署和初始化后调用的回调
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) public returns (GnosisSafeProxy proxy) {
        uint256 saltNonceWithCallback = uint256(keccak256(abi.encodePacked(saltNonce, callback)));
        proxy = createProxyWithNonce(_singleton, initializer, saltNonceWithCallback);
        if (address(callback) != address(0)) callback.proxyCreated(proxy, _singleton, initializer, saltNonce);
    }

    /// @dev 允许获取 通过`createProxyWithNonce`创建的新代理联系人的地址 
    /// 此方法仅用于地址计算目的，当您使用将恢复的初始化程序时， 因此返回响应一个回复。调用此方法时，将 `from` 设置为代理工厂的地址 
    /// @param _singleton 单例合约地址
    /// @param initializer 发送到新代理合约的消息调用的有效载荷
    /// @param saltNonce Nonce 将用于生成盐以计算新代理合约的地址 
    function calculateCreateProxyWithNonceAddress(
        address _singleton,
        bytes calldata initializer,
        uint256 saltNonce
    ) external returns (GnosisSafeProxy proxy) {
        proxy = deployProxyWithNonce(_singleton, initializer, saltNonce);
        revert(string(abi.encodePacked(proxy)));
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "./GnosisSafeProxy.sol";

interface IProxyCreationCallback {
    function proxyCreated(
        GnosisSafeProxy proxy,
        address _singleton,
        bytes calldata initializer,
        uint256 saltNonce
    ) external;
}