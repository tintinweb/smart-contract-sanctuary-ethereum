/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Market {
    struct Erc {
        address ercContractAddress;
        uint256 assetId;
        uint256 assetPrice;
        uint256 assetsCount;
        address paymentAddress;
    }
    mapping(uint256 => Erc) public registeredErcs;
    mapping(uint => uint) public salesRecord;
    uint256 constant feeNum = 55;
    uint256 constant feeDeno = 100;
    uint256 feeCollection = 0;

    modifier validAddress(address _address, string memory message) {
        require(_address != address(0), message);
        _;
    }

    function registerSale(address _address, uint256 _assetId, uint256 _assetPrice, uint256 _assetsCount,address _paymentAddress, uint ErcType)
    external 
    validAddress(_address, "Contract address is not valid")
    validAddress(_paymentAddress, "Payment address is not valid")
    returns(bool) {
        registeredErcs[ErcType] = Erc({
            ercContractAddress: _address,
            assetId: _assetId,
            assetPrice: _assetPrice,
            assetsCount: _assetsCount,
            paymentAddress: _paymentAddress
        });
        return true;
    }

    function buyAssets(uint256 _assetId, uint256 _numberOfAssets, uint256 _ercType) external returns(bool) {
        Erc storage erc = registeredErcs[_ercType];
        require(erc.assetId == _assetId, "Asset id does not exist");
        require(erc.assetsCount >= _numberOfAssets, "Insufficient assets available." );
        uint256 cost = _numberOfAssets*erc.assetPrice;
        uint256 marketFee = (_numberOfAssets*erc.assetPrice)*(feeNum/feeDeno);
        (bool success,) = erc.paymentAddress.call{value: cost}("");
        require(success, "transaction failed");
        erc.assetsCount -= _numberOfAssets;
        feeCollection += marketFee;
        return true;
    }
}