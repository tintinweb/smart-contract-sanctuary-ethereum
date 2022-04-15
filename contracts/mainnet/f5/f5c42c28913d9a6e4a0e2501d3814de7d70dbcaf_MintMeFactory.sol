/*
This file is part of the MintMe project.

The MintMe Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The MintMe Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the MintMe Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <[email protected]>
*/
// SPDX-License-Identifier: GNU lesser General Public License

pragma solidity ^0.8.0;

import "./mintme.sol";

contract MintMeFactory is Ownable, IMintMeFactory
{
    using Address for address payable;

    event FeeChanged(uint256 feeWei);
    event CollectionCreated(address indexed collection, address indexed creator, string contentCID, string licenseCID, string name, string symbol);
    event CollectionUpdated(address indexed collection, string contentCID);
    event CollectionTransfer(address indexed collection, address indexed newOwner);
    event TokenUpdated(address indexed collection, uint256 indexed tokenId, string contentCID);
    event Transfer(address collection, address indexed sender, address indexed receiver, uint256 indexed tokenId);

    uint256 private                      _feeWei;
    address payable private              _fundsReceiver;
    string  private                      _base;
    mapping (address => address) private _collections;

    constructor ()
    {
        setFee(1 ether / 10);
        _fundsReceiver = payable(_msgSender());
        // can be replaced by setBaseURI("ipfs://");
        setBaseURI("https://ipfs.io/ipfs/");
    }

    function setFee(uint256 newFeeWei) public onlyOwner
    {
        _feeWei = newFeeWei;
        emit FeeChanged(_feeWei);
    }

    function feeWei() view external override returns(uint256)
    {
        return _feeWei;
    }

    function setFundsReceiver(address newFundsReceiver) public onlyOwner
    {
        require(newFundsReceiver != address(0), "MintMe: zero address");
        _fundsReceiver = payable(newFundsReceiver);
    }

    function fundsReceiver() view external override returns(address payable)
    {
        return _fundsReceiver;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner
    {
        _base = newBaseURI;
    }

    function baseURI() view external override returns(string memory)
    {
        return _base;
    }

    function createCollection(
        string memory name,
        string memory symbol,
        string memory contentCID,
        string memory licenseCID) public payable
    {
        require(msg.value == _feeWei, "MintMeFactory: insufficient funds");
        if (_feeWei != 0)
        {
            _fundsReceiver.sendValue(_feeWei);
        }
        MintMe collection = new MintMe(address(this), name, symbol, contentCID, licenseCID);
        _collections[address(collection)] = _msgSender();
        emit CollectionCreated(address(collection), _msgSender(), contentCID, licenseCID, name, symbol);
        collection.transferOwnership(_msgSender());
    }

    function onTransfer(address sender, address receiver, uint256 tokenId) public override
    {
        validateCollection();
        emit Transfer(_msgSender(), sender, receiver, tokenId);
    }

    function onCollectionUpdated(string memory contentCID) public override
    {
        validateCollection();
        emit CollectionUpdated(_msgSender(), contentCID);
    }

    function onCollectionTransfer(address newOwner) public override
    {
        validateCollection();
        emit CollectionTransfer(_msgSender(), newOwner);
    }

    function onTokenUpdated(uint256 tokenId, string memory contentCID) public override
    {
        validateCollection();
        emit TokenUpdated(_msgSender(), tokenId, contentCID);
    }

    function validateCollection() internal view
    {
        require(_collections[_msgSender()] != address(0), "MintMeFactory: unknown collection");
    }
}