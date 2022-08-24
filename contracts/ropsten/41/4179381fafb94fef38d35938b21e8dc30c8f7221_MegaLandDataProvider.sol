/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// File: contracts/lib/access/Owner.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract Owner {

    address internal _owner;

    event OwnerChanged(address oldOwner, address newOwner);

    /// @notice gives the current owner of this contract.
    /// @return the current owner of this contract.
    function getOwner() external view returns (address) {
        return _owner;
    }

    /// @notice change the owner to be `newOwner`.
    /// @param newOwner address of the new owner.
    function changeOwner(address newOwner) external {
        address owner = _owner;
        require(msg.sender == owner, "only owner can change owner");
        require(newOwner != owner, "it can be only changed to a new owner");
        emit OwnerChanged(owner, newOwner);
        _owner = newOwner;
    }

    modifier onlyOwner() {
        require (msg.sender == _owner, "only owner allowed");
        _;
    }

}

// File: contracts/megaLandDataProvider/Types.sol

pragma solidity 0.8.14;

library Types{
  
    enum Assest{land, homestead, estate, unitassest}

    enum Island{MATIC, SOL, MEGA, BTC, ETH, BNB, ADA, AVAX, DOT, DOGE, FIL, LTC, 
    UNI, XRP, EGLD, XMR, XLM, TRX, LINK, SHIB, ALGO, VET, ATOM}

}

// File: contracts/megaLandDataProvider/MegaLandDataProvider.sol

pragma solidity 0.8.14;


interface IMegaLandDataProvider{ 

    function getLandPrice() external view returns(uint);
    function getEstatePrice() external view returns(uint);
    function getHomesteadPrice() external view returns(uint);
    function getUnitAssestPrice(bytes32 unitNameHash) external view returns(uint);
    function isUnitAssestExist(bytes32 unitNameHash) external view returns(bool);

}

contract MegaLandDataProvider is Owner, IMegaLandDataProvider{ 
  
    uint private price1X1;
    uint private price2X2;
    uint private price3X3;

    struct saleUnit{
        bool isSale;
        uint price;
    }

    mapping(bytes32 => saleUnit) public unitassetInfo;
    // total units 
    bytes32[] public totalUnitassest;

    function addUnits(bytes32[] calldata nameHash, uint[] memory unitPrice) external onlyOwner {
        require(nameHash.length == unitPrice.length, "Invalid array length");
        
        for(uint i=0; i<nameHash.length; i++){
            unitassetInfo[nameHash[i]].isSale = true;
            unitassetInfo[nameHash[i]].price = unitPrice[i];            
            totalUnitassest.push(nameHash[i]);
        }
    }

    function getLandPrice() external view returns(uint){
        return price1X1;
    }

    function getEstatePrice() external view returns(uint){
         return price3X3;
    }

    function getHomesteadPrice() external view returns(uint){
         return price2X2;
    }

    function getUnitAssestPrice(bytes32 unitNameHash) external view returns(uint){
        require(isUnitAssestExist(unitNameHash), "Not found");
        return unitassetInfo[unitNameHash].price;
    }

    function isUnitAssestExist(bytes32 unitNameHash) public view returns(bool){
       return unitassetInfo[unitNameHash].isSale;
    }

}