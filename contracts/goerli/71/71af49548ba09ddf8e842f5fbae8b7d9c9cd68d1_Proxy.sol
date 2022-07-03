/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

pragma solidity ^0.7.6;

contract Proxy {
    
    address public immutable admin;
    
    mapping (bytes32 => bytes32) public codeHashBySalt;

    event LogRegister(address indexed contractAddr, bytes32 salt, bytes32 codeHash);
    
    constructor(address adminAddr) {
        admin = adminAddr;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    // Receive ETH
    receive() external payable {}
    
    // Delegates the call based on selector and salt.
    fallback(bytes calldata input) external payable returns (bytes memory output) {
        // Get selector / contract salt.
       (bytes32 salt, bytes4 selector) =  _getSaltAndSelector(input);

        // Compute address of registered function.
        // See https://solidity.readthedocs.io/en/v0.7.4/control-structures.html#salted-contract-creations-create2
        address contractAddr = address(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
	        address(this),
	        salt,
	        codeHashBySalt[salt]
        ))));
        require(contractAddr != address(0), "fallback: failed on deploy");

        // Execute call. Revert on failure or return on success.
        bool success;
        (success, output) = contractAddr.call(abi.encodeWithSelector(selector));

        require(success, "fallback: failed to execute call");
    }



    // Registers a new function selector and its corresponding code.
    function register(bytes4 selector, bytes memory code) public onlyAdmin returns (address addr, bytes32 salt) {
        require(code.length != 0, "register: bytecode length is zero");

        salt = bytes32(selector);

        bytes32 codeHash = keccak256(code);

        codeHashBySalt[salt] = codeHash;

        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
        }
        
        require(addr != address(0), "register: failed on deploy");

        emit LogRegister(addr, salt, codeHash);
    }
    


    // Retrieves the selector from calldata and the corresponding salt.
    function _getSaltAndSelector(bytes calldata input) internal pure returns (bytes32 salt, bytes4 selector) {
        selector = abi.decode(input[:4], (bytes4));

        salt = bytes32(selector);
    }
}