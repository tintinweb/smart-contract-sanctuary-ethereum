/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

/**
 * @dev 逻辑合约，执行被委托的调用
 */
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
contract UUPS1_test{
    // 状态变量和proxy合约一致，防止插槽冲突
    address public implementation; 
    address public admin; 
    uint public _ff;

    event ffevent(uint ff);
    function increase() public{
        _ff++;
        emit ffevent(_ff);
    }

    function decrease() public{
        _ff--;
        emit ffevent(_ff);
    }
    
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }

    function getff() public view returns (uint){
        return _ff;
    }
}