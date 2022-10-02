pragma solidity ^0.6.6;

import './RawMaterial.sol';

contract Supplier {
    
    mapping (address => address[]) public supplierRawMaterials;
    
    constructor() public {}
    
    function createRawMaterialPackage(
        bytes32 _description,
        uint _quantity,
        address _transporterAddr,
        address _manufacturerAddr
    ) public {

        RawMaterial rawMaterial = new RawMaterial(
            msg.sender,
            address(bytes20(sha256(abi.encodePacked(msg.sender, now)))),
            _description,
            _quantity,
            _transporterAddr,
            _manufacturerAddr
        );
        
        supplierRawMaterials[msg.sender].push(address(rawMaterial));
    }
    
    
    function getNoOfPackagesOfSupplier() public view returns(uint) {
        return supplierRawMaterials[msg.sender].length;
    }
    
    
    function getAllPackages() public view returns(address[] memory) {
        uint len = supplierRawMaterials[msg.sender].length;
        address[] memory ret = new address[](len);
        for (uint i = 0; i < len; i++) {
            ret[i] = supplierRawMaterials[msg.sender][i];
        }
        return ret;
    }
}