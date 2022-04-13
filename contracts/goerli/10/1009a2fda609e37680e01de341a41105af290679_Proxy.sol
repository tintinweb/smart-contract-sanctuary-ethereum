/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

    function transferFrom(address form, address to, uint256 amount) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

}

interface IProxy {
    event Upgraded(address indexed implementation);
}

contract ProxyStorage {
    
    // 最后一次添加的合约地址
    address internal rootToken;

    // 版本号-> 合约地址
    mapping(string => address) internal logicContracts;

}


// 代理合约
contract Proxy is ProxyStorage,IProxy {


    function balanceOf(address owner) public view virtual  returns (uint256) {
        return IERC20(rootToken).balanceOf(owner);
    }

    function transferFrom(address form,address to, uint256 amount) public virtual  returns (bool) {

        IERC20(rootToken).transferFrom(form,to,amount);
        return true;
    }
    
    // 添加逻辑合约
    function setImplementation(string memory version,address _execToken)  public  virtual  returns (bool) {
        rootToken=_execToken;
        logicContracts[version]=rootToken;
       emit Upgraded(logicContracts[version]);
        return true;
    }

    function implementation() public view virtual  returns (address _impl) {

        return rootToken;
    }

    function initialize(bytes calldata) external pure {
        revert("CANNOT_CALL_INITIALIZE");
    }

    receive() external payable virtual {
        revert("CONTRACT_NOT_EXPECTED_TO_RECEIVE");
    }


    fallback() external payable virtual{
        address _implementation = implementation();
        require(_implementation != address(0x0), "MISSING_IMPLEMENTATION");

        assembly {
            calldatacopy(0, 0, calldatasize())


            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)


            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
    
}