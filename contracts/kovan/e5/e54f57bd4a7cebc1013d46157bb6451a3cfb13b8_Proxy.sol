// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.7.0;

import "./FuncWithSelector.sol";

contract Proxy {
    
    address public immutable admin;
    
    mapping (bytes32 => bytes32) public codeHashBySalt;
    
    constructor() {
        admin = msg.sender;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    // Receive ETH
    receive() external payable {}
    
    // Delegates the call based on selector and salt.
    fallback() external payable {
        // Get selector / contract salt.
        (bytes32 salt, bytes4 selector) = _getSaltAndSelector();

        // Compute address of registered function.
        // See https://solidity.readthedocs.io/en/v0.7.4/control-structures.html#salted-contract-creations-create2
        address addr = address(uint160(uint(codeHashBySalt[salt])));

        // Execute call. Revert on failure or return on success.
        if(selector == bytes4(keccak256("testProxy()")) ||
        selector == bytes4(keccak256("testMulticall()")) ||
        selector == bytes4(keccak256("testMulticall1()"))){
            (bool success, ) = addr.delegatecall(msg.data);
            if(success){
                return;
            }else{
            revert();
            }
        }
    }

    // Registers a new function selector and its corresponding code.
    function register(bytes4 selector, bytes memory code) public onlyAdmin returns (address addr, bytes32 salt) {
        salt = bytes32(selector);

        codeHashBySalt[salt] = keccak256(
            abi.encodePacked(
                bytes1(0xff), address(this), salt, keccak256(code)
            )
        );       
       
        FuncWithSelector _addr = new FuncWithSelector{
            salt: salt
        }();

        addr = address(_addr);

        require(address(addr) == address(uint160(uint(codeHashBySalt[salt])))); 
    }
    
    // Retrieves the selector from calldata and the corresponding salt.
    function _getSaltAndSelector() internal pure returns (bytes32 salt, bytes4 selector) {
        selector = msg.sig;
        salt = bytes32(selector);
    }
}