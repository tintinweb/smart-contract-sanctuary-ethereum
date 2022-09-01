/**
 *Submitted for verification at Etherscan.io on 2022-08-31
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
        require(newOwner != address(0x000), "Zero address");
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

// File: contracts/megaLandDataProvider/IMegaLandDataProvider.sol

pragma solidity 0.8.14;

interface IMegaLandDataProvider{ 

    function getLandPrice() external view returns(uint);
    function getEstatePrice() external view returns(uint);
    function getHomesteadPrice() external view returns(uint);
    function getUnitAssestPrice(bytes32 unitNameHash) external view returns(uint);
    function getPrice(bytes32 unitHash) external view returns(uint);
    function isAssestExist(bytes32 unitNameHash) external view returns(bool);

}

// File: contracts/megaLandDataProvider/MegaLandDataProvider.sol

pragma solidity 0.8.14;



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

    constructor(
        address owner_
    ) {
        require(owner_ != address(0x00), "Zero address");
        _owner = owner_;
    }

    function addUnits(bytes32[] calldata nameHash, uint[] memory unitPrice) external onlyOwner {
        require(nameHash.length == unitPrice.length, "Invalid array length");
        
        for(uint i=0; i<nameHash.length; i++){
            unitassetInfo[nameHash[i]].isSale = true;
            unitassetInfo[nameHash[i]].price = unitPrice[i];            
            totalUnitassest.push(nameHash[i]);
        }
    }

    function setPrice(uint _price1X1, uint _price2X2, uint _price3X3) external onlyOwner {
        price1X1 = _price1X1;
        price2X2 = _price2X2;
        price3X3 = _price3X3;
    }

    // Read methods

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

    function isAssestExist(bytes32 unitHash) public view returns(bool){
        if(unitHash == keccak256("LAND")) {
            return true;
        }else if(unitHash == keccak256("HOMESTEAD")) {
            return true;
        }else if(unitHash == keccak256("ESTATE")) {
            return true;
        } else {
            return unitassetInfo[unitHash].isSale;
        }
    }

    function getPrice(bytes32 unitHash) public view returns(uint price){
        if(unitHash == keccak256("LAND")) {
            return price1X1;
        }else if(unitHash == keccak256("HOMESTEAD")) {
            return price2X2;
        }else if(unitHash == keccak256("ESTATE")) {
            return price3X3;
        } else if(unitassetInfo[unitHash].isSale){
            return unitassetInfo[unitHash].price;
        }
    }

}