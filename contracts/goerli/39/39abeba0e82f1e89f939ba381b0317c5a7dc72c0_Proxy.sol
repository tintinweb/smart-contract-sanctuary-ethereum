/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// (bool success, bytes memory returndata) = newImplementation.delegatecall(
        //     abi.encodeWithSelector(this.initialize.selector, data)
        // );
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxy {
    event Upgraded(address indexed implementation);

    event log(string  values);
}

contract ProxyStorage {
    
    // 最后一次添加的合约地址
    address internal rootToken;

    // 版本号-> 合约地址
    mapping(string => address) internal logicContracts;

}

contract Proxy is ProxyStorage,IProxy {

// 添加逻辑合约
    function setImplementation(string memory version,address _execToken, bytes calldata data)  public  virtual  returns (bool) {
        rootToken=_execToken;
        logicContracts[version]=rootToken;
        (bool success, bytes memory returndata) = rootToken.delegatecall(
            abi.encodeWithSelector(this.initialize.selector, data)
        );
        require(success, string(returndata));
         emit log(string(returndata));
        emit Upgraded(logicContracts[version]);
        return true;
    }

    function implementation() public view virtual  returns (address _impl) {

        return rootToken;
    }

    function initialize(bytes calldata) external pure {
        revert("CANNOT_CALL_INITIALIZE");
    }

    receive() external payable  {
        emit log("receive");
        revert("CONTRACT_NOT_EXPECTED_TO_RECEIVE");
    }


    fallback() external payable {
         emit log("fallback");
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