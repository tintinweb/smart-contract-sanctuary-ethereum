/**
 *Submitted for verification at Etherscan.io on 2022-10-22
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

pragma solidity 0.8.7;

interface PnsAddressesInterface {
    function owner() external view returns (address);
    function getPnsAddress(string memory _label) external view returns(address);
}

pragma solidity 0.8.7;

interface PnsPricesOracleInterface {
    function getMaticCost(string memory _name, uint256 expiration) external view returns (uint256);
    function getEthCost(string memory _name, uint256 expiration) external view returns (uint256);
}

pragma solidity 0.8.7;

abstract contract PnsAddressesImplementation is PnsAddressesInterface {
    address private PnsAddresses;
    PnsAddressesInterface pnsAddresses;

    constructor(address addresses_) {
        PnsAddresses = addresses_;
        pnsAddresses = PnsAddressesInterface(PnsAddresses);
    }

    function setAddresses(address addresses_) public {
        require(msg.sender == owner(), "Not authorized.");
        PnsAddresses = addresses_;
        pnsAddresses = PnsAddressesInterface(PnsAddresses);
    }

    function getPnsAddress(string memory _label) public override view returns (address) {
        return pnsAddresses.getPnsAddress(_label);
    }

    function owner() public override view returns (address) {
        return pnsAddresses.owner();
    }
}


pragma solidity 0.8.7;

contract Computation {
    function computeNamehash(string memory _name) public pure returns (bytes32 namehash) {
        namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked('eth')))
        );
        namehash = keccak256(
        abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract PnsRegistrar is Computation, PnsAddressesImplementation {

    constructor(address addresses_) PnsAddressesImplementation(addresses_) {
    }

    bool public isActive = true;

    struct Register {
        string name;
        address registrant;
        uint256 expiration;
    }

    event registerCall(string _name, address _registrant, uint256 _expiration);

    function pnsRegisterMinter(Register[] memory register) public payable {
        require(isActive, "Contract must be active.");
        require(totalCostEth(register) <= msg.value, "Ether value is not correct.");

        for(uint256 i=0; i<register.length; i++) {
            require(checkString(register[i].name) == true, "Invalid name.");
            emit registerCall(register[i].name, register[i].registrant, register[i].expiration);
        }
        
    }

    function totalCostEth(Register[] memory register) public view returns (uint256) {
        PnsPricesOracleInterface pnsPricesOracle = PnsPricesOracleInterface(getPnsAddress("_pnsPricesOracle"));
        uint256 totalCost;
        for(uint256 i=0; i<register.length; i++) {
            totalCost = totalCost + pnsPricesOracle.getEthCost(register[i].name, register[i].expiration);
        }
        return totalCost;
    }

    function checkString(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length > 15) return false;
        if(b.length < 3) return false;

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];
            if(
                (char == 0x2e)
            )
                return false;
        }
        return true;
    }

    function withdraw(address to, uint256 amount) public {
        require(msg.sender == owner());
        require(amount <= address(this).balance);
        payable(to).transfer(amount);
    }
    
    function flipActiveState() public {
        require(msg.sender == owner());
        isActive = !isActive;
    }

}