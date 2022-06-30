// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
library Create2 {
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IOwnable {
    function transferOwnership(address newOwner) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract Create {
    address public beneficiary;
    constructor(){
        beneficiary = msg.sender;
    }
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) external returns (address) {
        return Create2.deploy(amount, salt, bytecode);
    }
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) external view returns (address) {
        return Create2.computeAddress(salt, bytecodeHash);
    }
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) external pure returns (address) {
        return Create2.computeAddress(salt, bytecodeHash, deployer);
    }
    function claimETH() external {
        payable(beneficiary).transfer(address(this).balance);
    }
    function claimToken(address token) external {
        IERC20(token).transfer(beneficiary, IERC20(token).balanceOf(address(this)));
    }
    function claimNFT(address token, uint256 id) external {
        IERC721(token).transferFrom(address(this), beneficiary, id);
    }
    function transferOwnership(address contract_) external {
        IOwnable(contract_).transferOwnership(beneficiary);
    }
    receive() external payable {
    }
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}