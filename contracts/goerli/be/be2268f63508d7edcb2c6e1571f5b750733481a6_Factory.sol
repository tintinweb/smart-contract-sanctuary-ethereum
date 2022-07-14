/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleWallet {

    address public owner;
    // Only owners can call transactions marked with this modifier

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    constructor(address _owner) payable {
        owner = _owner;
    }

    // Allows the owner to transfer ownership of the contract
    function transferOwnership(address _newOwner) external onlyOwner {
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
}

contract Factory {
    // Returns the address of the newly deployed contract

    function deploy(
        uint _salt
    ) public payable returns (address) {
        // This syntax is a newer way to invoke create2 without assembly, you just need to pass salt
        // https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2
        return address(new SimpleWallet{salt: bytes32(_salt)}(msg.sender));
    }

    // 1. Get bytecode of contract to be deployed
    function getBytecode()
        public
        view
        returns (bytes memory)
    {
        bytes memory bytecode = type(SimpleWallet).creationCode;
        return abi.encodePacked(bytecode, abi.encode(msg.sender));
    }

    /** 2. Compute the address of the contract to be deployed
        params:
            _salt: random unsigned number used to precompute an address
    */ 
    function getAddress(uint256 _salt)
        public
        view
        returns (address)
    {
        // Get a hash concatenating args passed to encodePacked
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), // 0
                address(this), // address of factory contract
                _salt, // a random salt
                keccak256(getBytecode()) // the wallet contract bytecode
            )
        );
        // Cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }
}