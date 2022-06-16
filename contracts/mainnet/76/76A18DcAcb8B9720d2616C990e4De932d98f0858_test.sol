/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// File: transfer.sol



pragma solidity >= 0.8.9 < 0.9.0;

enum HowToCall { Call, DelegateCall }

interface AuthenticatedProxy{

    function  proxy(address dest, HowToCall howToCall, bytes calldata)
        external
        returns (bool);
} 

contract test {    
    function mint(address proxy, address target, uint256 i, bytes calldata _calldata) external {
        if(i == 0 ){
            AuthenticatedProxy(proxy).proxy(target, HowToCall.Call, _calldata);
        }
        else{
            AuthenticatedProxy(proxy).proxy(target, HowToCall.DelegateCall, _calldata);
        }
        
    }
}