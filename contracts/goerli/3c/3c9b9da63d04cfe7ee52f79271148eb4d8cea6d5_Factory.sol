// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.16 <0.9.0;

import "./interfaces/IFactory.sol";
import "./did/Account.sol";

contract Factory is IFactory {
    /**
     * @dev See {IFactory-deploy}.
     */
    function deploy() public payable returns (address) {
        return address(new Account(msg.sender));
    }

    /**
     * @dev See {IFactory-deploy2}.
     */
    function deploy2(bytes32 _salt) public payable returns (address) {
        return address(new Account{salt: _salt}(msg.sender));
    }

    // 1. 获取待部署合约字节码
    function getBytecode() public view returns (bytes memory) {
        bytes memory bytecode = type(Account).creationCode;
        return abi.encodePacked(bytecode, abi.encode(msg.sender));
    }

    /** 2. 计算待部署合约地址
        params:
            _salt: 随机整数，用于预计算地址
    */
    function getAddress(uint256 _salt) public view returns (address) {
        // Get a hash concatenating args passed to encodePacked
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), // 0=hex'ff'
                address(this), // address of factory contract
                _salt, // a random salt
                keccak256(getBytecode()) // the wallet contract bytecode
            )
        );
        // Cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.16 <0.9.0;

interface IFactory {
    /**
     * @dev deploy with create.
     *
     * @notice address deployed on deployer address and nonce
     * @dev deployer MUST be EOA
     * @return address of new contract
     */
    function deploy() external payable returns (address);

    /**
     * @dev deploy with create2 use {salt: _salt}.
     *
     * @notice address deployed on _salt
     * @dev deployer MUST be EOA
     * @param _salt  bytes32 salt
     * @return address of new contract
     */
    function deploy2(bytes32 _salt) external payable returns (address);

    function getAddress(uint256 _salt) external view returns (address);

    function getBytecode() external view returns (bytes memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.16 <0.9.0;

contract Account {
    address public owner;
    // Only owners can call transactions marked with this modifier
    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    constructor(address _owner) payable {
        owner = payable(_owner);
    }

    // Allows the owner to transfer ownership of the contract
    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    // Returns ETH balance from this contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Allows contract owner to withdraw all funds from the contract
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Destroys this contract instance
    function destroy(address payable recipient) public onlyOwner {
        selfdestruct(recipient);
    }

    function deposit() public payable {}

    // msg.data = null
    receive() external payable {}

    // msg.data != null
    fallback() external payable {}
}