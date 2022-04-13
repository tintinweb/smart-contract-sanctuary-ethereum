/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: Apache-2.0.

pragma solidity ^0.8.0;

interface IERC20 {

    function transferFrom(address form, address to, uint256 amount) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

}

contract MyTokenStorage {
    
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;


    mapping(address => uint256) internal balances;

    mapping(address => mapping(address => uint256)) internal _allowances;
}

interface IProxy  {

    function implementation() external view returns (address _impl);

}

contract Proxy is MyTokenStorage,IProxy {
    
    address public token;

    function balanceOf(address owner) public view virtual  returns (uint256) {
        return IERC20(token).balanceOf(owner);
    }

    function transferFrom(address form,address to, uint256 amount) public virtual  returns (bool) {

        IERC20(token).transferFrom(form,to,amount);
        return true;
    }
    
    // 逻辑合约指定
    function setExecToken(address _execToken)  public  virtual  returns (bool) {
        token=_execToken;
        return true;
    }

    function implementation() public view virtual override returns (address _impl) {

        return token;
    }

    function proxyType() public pure returns (uint256 proxyTypeId) {
        return 2;
    }

    function initialize(bytes calldata) external pure {
        revert("CANNOT_CALL_INITIALIZE");
    }

    receive() external payable virtual {
        revert("CONTRACT_NOT_EXPECTED_TO_RECEIVE");
    }

    /*
      Contract's default function. Delegates execution to the implementation contract.
      It returns back to the external caller whatever the implementation delegated code returns.
    */
    fallback() external payable virtual{
        address _implementation = token;
        require(_implementation != address(0x0), "MISSING_IMPLEMENTATION");

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 for now, as we don't know the out size yet.
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
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