/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//将存储单独拆1个合约(不需要部署)，方便进行继承
contract ProxyStore {
    address public impl;
    event log(bytes);
}

pragma solidity ^0.8.0;
//import "./ProxyStore.sol";
contract ImplV1Store is ProxyStore {
    uint public t;
}

pragma solidity ^0.8.0;
//import "./ImplV1Store.sol";
//因为本例中V2暂未新增状态
contract ImplV2Store is ImplV1Store {}

pragma solidity ^0.8.0;
// import "./ProxyStore.sol";
/**
    调用者合约
**/
contract Proxy is ProxyStore{
    fallback () external payable{
        (bool success, bytes memory res) = impl.delegatecall(msg.data);
        emit log(res);
        assembly {
            //分配空闲区域指针
            let ptr := mload(0x40)
            //将返回值从返回缓冲去copy到指针所指位置
            returndatacopy(ptr, 0, returndatasize())

            //根据是否调用成功决定是返回数据还是直接revert整个函数
            switch success
            case 0 { revert(ptr, returndatasize()) }
            default { return(ptr, returndatasize()) }
        }
    }
    receive() external payable{}
    function setImpl(address addr) public{
        impl = addr;
    }
}

pragma solidity ^0.8.0;
//import "./ImplV1Store.sol";
/**
    实现合约 V1，继承自己的存储合约
**/
contract ImplV1 is ImplV1Store{
    // 
    function addT() public payable {
        t = t + 1;
    }

    function getT() public view returns (uint res){
        return t;
    }

}

pragma solidity ^0.8.0;
//import "./ImplV2Store.sol";
/**
    实现合约 V2，继承自己的存储合约
**/
contract ImplV2 is ImplV2Store{
    function addT() public payable {
        t = t + 2;
    }
    function getT() public view returns (uint res){
        return t;
    }
}