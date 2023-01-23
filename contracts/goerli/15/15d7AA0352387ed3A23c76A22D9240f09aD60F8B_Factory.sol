/**
 *Submitted for verification at Etherscan.io on 2023-01-23
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
    receive() external payable {}

    // Allows the owner to send ETH to any address

    function send(address payable _to, uint256 _amount) external onlyOwner {
        _to.transfer(_amount);
    }

    //depsit eth

    function deposit() external payable {}

    
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
    event newWallet(address wallet);


    function deploy() public payable returns (address) {         
        uint256 _salt = convertAddr(msg.sender);
        
        address newAddress =  address(new SimpleWallet{salt: bytes32(_salt), value: msg.value}(msg.sender));
        emit newWallet(newAddress);
        return newAddress;
    }

    // 1. Get bytecode of contract to be deployed
    function getBytecode() public view returns (bytes memory) {
        bytes memory bytecode = type(SimpleWallet).creationCode;
        return abi.encodePacked(bytecode, abi.encode(msg.sender));
    }

    /** 2. Compute the address of the contract to be deployed
        params:
            _salt: random unsigned number used to precompute an address
    */
    function getAddress(uint256 _salt) public view returns (address) {
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
    function convertAddr(address _addr) public pure returns(uint)
    {
        uint256 i = uint256(uint160(_addr));
        return i;

    }
}