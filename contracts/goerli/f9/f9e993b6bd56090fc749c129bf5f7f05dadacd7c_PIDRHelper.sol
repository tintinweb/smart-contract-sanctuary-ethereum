// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./pidrtest.sol";

contract PIDRHelper is PIDRTest {
    bool onSale = false;
    address buyer;

    function saleTo(address _buyer) external ownerOnly {
        require(onSale == false);
        onSale = true;
        buyer = _buyer;
    }

    function cancelSale() external ownerOnly {
        onSale = false;
    }

    function buy() external payable {
        require(onSale == true);
        require(msg.sender == buyer);
        require(msg.value == salePrice);

        payable(artwork.owner).transfer(msg.value);
        _changeOwner(msg.sender);
        onSale = false;
    }

    function setSalePrice(uint _newPrice) external ownerOnly {
        require(onSale == false);
        salePrice = _newPrice * 1 ether;
    }

    function getSalePrice() external view returns(uint) {
        return salePrice;
    }

    function getIdArtwork() external view returns(uint) {
        return artwork.idArtwork;
    }

    function getOwner() external view returns(address) {
        return artwork.owner;
    }

    function getOnSale() external view returns(bool) {
        return onSale;
    }

    function getBuyer() external view returns(address) {
        return buyer;
    }
}