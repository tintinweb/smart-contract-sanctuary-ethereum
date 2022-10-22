pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicense

import "./Ownable.sol";
import "./SafeMath.sol";

import "./ERC1155.sol";

contract FortunaAssets is Ownable, ERC1155 {

   

    bool public isTransferEnabled = true;

    // constructor

    constructor() ERC1155("") {}

    // getters

    function balanceOfAllAssets(
        address _account
    ) external view returns (uint256[] memory) {
       
        uint256[] memory allAssetBalances = new uint256[](10);
        for (uint256 i = 0 ; i < 11 ; i++) {
            allAssetBalances[i] = balanceOf(_account, i + 1);
        }

        return allAssetBalances;
    }


   function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    // setters

    
    function setIsTransferEnabled(
        bool _state
    ) external onlyOwner {
    
        isTransferEnabled = _state;
    }

    function setURI(
        string memory _uri
    ) external onlyOwner {
        _setURI(_uri);
    }

    // functions

    function mintWithCheck(
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) external {
               _mint(_msgSender(), _tokenId, _amount, _data);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) public override {
    

        super.safeTransferFrom(_from, _to, _tokenId, _amount, _data);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        bytes memory _data
    ) public override {

      
        super.safeBatchTransferFrom(_from, _to, _tokenIds, _amounts, _data);
    }

    function safeTransferFromWithCheck(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) public {
        super.safeTransferFrom(_from, _to, _tokenId, _amount, _data);
    }

    function burnWithCheck(
        address _from,
        uint256 _tokenId,
        uint256 _amount
    ) external {
        _burn(_from, _tokenId, _amount);
    }

    // modifiers
}