/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
    function mint(address to, uint amount) external;
    function burn(address owner, uint amount) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BridgeBase {
    IToken public token;
    address public admin;
    mapping(address => mapping(uint => bool )) public processedNonces;
    enum Step { Burn, Mint}
    event Transfer(address from, address to, uint amount, uint date, uint nonce, bytes signature, Step indexed step);
    
    constructor(address _token) {
        admin = msg.sender;
        token = IToken(_token);
    }
    
    function burn(address to, uint amount, uint nonce, bytes calldata signature) external {
        require(processedNonces[msg.sender][nonce] == false, 'transfer already processed');
        processedNonces[msg.sender][nonce] == true;
        token.burn(msg.sender, amount);
        emit Transfer(msg.sender, to, amount, block.timestamp, nonce, signature, Step.Burn);
    }
    
    function mint(address from, address to, uint amount, uint nonce, bytes calldata signature) external {
        token.mint(to, amount);
        emit Transfer(from, to, amount, block.timestamp, nonce, signature, Step.Mint);
    }
    
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash));
    }
    
    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }
    
    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            
            s := mload(add(sig, 64))
            
            v := byte(0, mload(add(sig, 96)))
        }
        
        return (v, r, s);
    }
}

contract BridgeEth is BridgeBase {
    constructor(address token) BridgeBase (token){
    }
}