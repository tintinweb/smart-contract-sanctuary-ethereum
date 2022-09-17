/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// File: contracts/EIP-1822-contract/proxiable.sol
pragma solidity ^0.8.9;

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }
    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}

// File: contracts/EIP-1822-contract/implementation.sol


pragma solidity ^0.8.9;


contract counter is Proxiable {
    address public owner;
    uint count;
    bool set;

    function intialize() external{
        require(owner == address(0) && set == false, "already initialized");
        owner = msg.sender;
        set = true;
    }

    function increment() external {
        count++;
    }

    function getCount() public view returns(uint){
        return count;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "restricted to the owner");
        _; 
    }

    function upgradeContract(address _newAddress) public onlyOwner {
        updateCodeAddress(_newAddress);

    }
}