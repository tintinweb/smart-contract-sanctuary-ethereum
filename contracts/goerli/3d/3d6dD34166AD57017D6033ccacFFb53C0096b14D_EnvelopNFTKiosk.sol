// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) NFT(wNFT) Kiosk.

pragma solidity 0.8.16;

import "TokenServiceExtended.sol";

import "ERC721Holder.sol";
import "ERC1155Holder.sol";
//import "ReentrancyGuard.sol";

import "DefaultPriceModel.sol";



contract EnvelopNFTKiosk is TokenServiceExtended, DefaultPriceModel {

    uint256 constant public DEFAULT_INDEX = 0;
    uint256 constant public PERCENT_DENOMINATOR = 10000;
    bytes32 immutable public DEFAULT_DISPLAY = hlpHashString('NFTKiosk');

    mapping(bytes32 => KTypes.Display) public displays;

    // mapping from contract address & tokenId to Place(displayHash and index)
    mapping(address => mapping(uint256 => KTypes.Place)) public assetAtDisplay;

    event DisplayChanged(
        bytes32 indexed display,
        address indexed owner,
        address indexed beneficiary, // who will receive assets from sale
        uint256 enableAfter,
        uint256 disableAfter,
        address priceModel,
        string name
    );

    event DisplayTransfer(
        bytes32 indexed display,
        address indexed from,
        address indexed newOwner
    );

    event ItemAddedToDisplay(
        bytes32 indexed display,
        address indexed assetContract,
        uint256 indexed assetTokenId,
        uint256 placeIndex
    );

    event ItemPriceChanged(
        bytes32 indexed display,
        address indexed assetContract,
        uint256 indexed assetTokenId
    );

    event EnvelopPurchace(
        bytes32 indexed display,
        address indexed assetContract,
        uint256 indexed assetTokenId
    );

    constructor (address _beneficiary)
       DefaultPriceModel(address(this))
    {
        KTypes.Display storage d = displays[DEFAULT_DISPLAY];
        d.owner = msg.sender;
        d.beneficiary  = _beneficiary;
        d.enableAfter  = 0;
        d.disableAfter = type(uint256).max;
        d.priceModel   = address(this);
        emit DisplayChanged(
            DEFAULT_DISPLAY,
            msg.sender,
            _beneficiary, // who will receive assets from sale
            0,
            d.disableAfter,
            address(this),
            'NFTKiosk'
        );
    }

    
    function setDisplayParams(
        string calldata _name,
        address _beneficiary, // who will receive assets from sale
        uint256 _enableAfter,
        uint256 _disableAfter,
        address _priceModel
    ) external 
    {
        bytes32 _displayNameHash = hlpHashString(_name);
        require(
            (displays[_displayNameHash].owner == msg.sender    // edit existing
            ||displays[_displayNameHash].owner == address(0)), // create new
            "Only for Display Owner"
        );
        _setDisplayParams(
                _displayNameHash,
                msg.sender, 
                _beneficiary, // who will receive assets from sale
                _enableAfter,
                _disableAfter,
                _priceModel
        );
        
        emit DisplayChanged(
            _displayNameHash,
            msg.sender,
            _beneficiary, // who will receive assets from sale
            _enableAfter,
            _disableAfter,
            _priceModel,
            _name
        );
    }

    function transferDisplay(address _to, bytes32 _displayNameHash) 
        external 
    {
        require(displays[_displayNameHash].owner == msg.sender, "Only for Display Owner");
        displays[_displayNameHash].owner = _to;
        emit DisplayTransfer(_displayNameHash, msg.sender, _to);
    }

    // TODO  Check that display exists
    function addItemToDisplay(
        bytes32 _displayNameHash,
        ETypes.AssetItem memory _assetItem,
        KTypes.Price[] calldata _prices
    ) 
        public 
        returns  (KTypes.Place memory place) 
    {
        // We need two checks. 
        // 1. Only item with zero place (display and index) can be added 
        // to exact display
        
        KTypes.Place memory p = 
            assetAtDisplay[_assetItem.asset.contractAddress][_assetItem.tokenId];
        require(
            p.display == bytes32(0) && p.index == 0, 
            "Already at display"
        );
        
        // 2. Item has been transfered to this contract
        // Next check is For 721 only. Because 1155 standard 
        // has no `ownerOf` method. Hence we can't use simple (implicit)
        // erc1155 transfer for put item at display. 
        if (_ownerOf(_assetItem) != address(this)) {
            // Do transfer to this contract
            require(_assetItem.amount
                <=_transferSafe(_assetItem, msg.sender, address(this)),
                "Insufficient balance after NFT transfer"    
            );
        }

        // DEFAULT_DISPLAY accept items from any  addresses
        if (msg.sender != displays[_displayNameHash].owner) {
            require(
                _displayNameHash == DEFAULT_DISPLAY, 
                "Only Default Display allow for any"
            );
        }

        place = _addItemRecordAtDisplay(
            _displayNameHash, 
            msg.sender,  // Item Owner
            _assetItem,
            _prices
        );

        emit ItemAddedToDisplay(
            place.display,
            _assetItem.asset.contractAddress,
            _assetItem.tokenId,
            place.index
        );
    }

    function addBatchItemsToDisplayWithSamePrice(
        bytes32 _displayNameHash,
        ETypes.AssetItem[] memory _assetItems,
        KTypes.Price[] calldata _prices
    ) 
        external 
        returns  (KTypes.Place[] memory) 
    {
        
        // Lets calc and create array var for result
        KTypes.Place[] memory pls = new KTypes.Place[](_assetItems.length);
        for (uint256 i = 0; i < _assetItems.length; ++i){
            pls[i] = addItemToDisplay(_displayNameHash,_assetItems[i],_prices);
        }
        return pls;
    }

    function addAssetItemPriceAtIndex(
        ETypes.AssetItem calldata _assetItem,
        KTypes.Price[] calldata _prices
    ) 
        external 
    {
        KTypes.Place memory p = getAssetItemPlace(_assetItem);
        // check that sender is item owner or display owner(if item owner not set)
        if (displays[p.display].items[p.index].owner != msg.sender) 
        {
            require(
                displays[p.display].owner == msg.sender, 
                "Only display owner can edit price"
            );
        }
        _addItemPriceAtIndex(p.display, p.index, _prices);
        emit ItemPriceChanged(
            p.display,
            _assetItem.asset.contractAddress,
            _assetItem.tokenId
        ); 
    }

    function editAssetItemPriceAtIndex(
        ETypes.AssetItem calldata _assetItem,
        uint256 _priceIndex,
        KTypes.Price calldata _price
    ) 
        external 
    {

        KTypes.Place memory p = getAssetItemPlace(_assetItem);
        // check that sender is item owner or display owner(if item owner not set)
        if (displays[p.display].items[p.index].owner != msg.sender) 
        {
            require(displays[p.display].owner == msg.sender, "Only for display owner");
        }
        _editItemPriceAtIndex(p.display, p.index, _priceIndex ,_price);
        emit ItemPriceChanged(
            p.display,
            _assetItem.asset.contractAddress,
            _assetItem.tokenId
        );

    }

    function removeLastPersonalPriceForAssetItem(
        ETypes.AssetItem calldata _assetItem
    ) 
        external 
    {
        KTypes.Place memory p = getAssetItemPlace(_assetItem);
        // check that sender is item owner or display owner(if item owner not set)
        if (displays[p.display].items[p.index].owner != msg.sender) 
        {
            require(displays[p.display].owner == msg.sender, "Only for display owner");
        }
        
        KTypes.Price[] storage priceArray = displays[p.display].items[p.index].prices;
        priceArray.pop();
        emit ItemPriceChanged(
            p.display,
            _assetItem.asset.contractAddress,
            _assetItem.tokenId
        );
    }

    function buyAssetItem(
        ETypes.AssetItem calldata _assetItem,
        uint256 _priceIndex,
        address _buyer,
        address _referrer,
        string calldata _promo
    ) external payable
    {
        // 1.Define exact asset price with discounts
        ETypes.AssetItem memory payWithItem;
        { // Against stack too deep
            (KTypes.Price[] memory pArray, KTypes.Discount[] memory dArray) 
                = _getAssetItemPricesAndDiscounts(
                    _assetItem, _buyer, _referrer, hlpHashString(_promo)
            );

            uint256 totalDiscountPercent;
            for (uint256 i = 0; i < dArray.length; ++ i){
                totalDiscountPercent += dArray[i].dsctPercent;
            } 
            
            payWithItem = ETypes.AssetItem(    
                ETypes.Asset(
                    pArray[_priceIndex].payWith == address(0)
                        ?ETypes.AssetType.NATIVE
                        :ETypes.AssetType.ERC20, 
                        pArray[_priceIndex].payWith
                ), 
                0, 
                pArray[_priceIndex].amount 
                    * (PERCENT_DENOMINATOR - totalDiscountPercent) / PERCENT_DENOMINATOR
            );
        }
        
        // 2. Manage display records for different cases
        address beneficiary;
        KTypes.Place memory p = getAssetItemPlace(_assetItem);
        //  Case when NFT just transfered to kiosk contract
        if (p.display == bytes32(0)) {
            //isImplicitAdded = true;
            beneficiary = displays[DEFAULT_DISPLAY].beneficiary;
            p.display = DEFAULT_DISPLAY;
            p.index = DEFAULT_INDEX;
        } else {
            beneficiary = displays[p.display].items[p.index].owner; 
            // 2.1 remove item from display
            if (p.index != displays[p.display].items.length - 1) {
                // if asset item is not last array element
                // then replace it with last element
                displays[p.display].items[p.index] = displays[p.display].items[
                    displays[p.display].items.length - 1
                ]; 
                // and change last element that was moved in above string
                assetAtDisplay[
                    displays[p.display].items[p.index].nft.asset.contractAddress // address of just moved nft
                ][
                    displays[p.display].items[p.index].nft.tokenId
                ] = KTypes.Place(
                   p.display,
                   p.index
                );
            }
            // remove last element from array
            displays[p.display].items.pop();
            
            // delete mapping element
            delete assetAtDisplay[_assetItem.asset.contractAddress][_assetItem.tokenId];
        }
        
        require(
            displays[p.display].enableAfter < block.timestamp
            && displays[p.display].disableAfter >= block.timestamp, 
            "Only in time"
        );

               
        // 3.Receive payment
        // There are two different cases: native token and erc20
        if (payWithItem.asset.assetType ==ETypes.AssetType.NATIVE )
        //if (pArray[_priceIndex].payWith == address(0)) 
        {
            // Native token payment
            require(payWithItem.amount 
                <= _transferSafe(payWithItem, address(this), beneficiary),
                "Insufficient balance after payment transfer"
            );
            // Return change
            if  ((msg.value - payWithItem.amount) > 0) {
                address payable s = payable(msg.sender);
                s.transfer(msg.value - payWithItem.amount);
            }
        } else {
            // ERC20 token payment
            require(msg.value == 0, "Only ERC20 tokens");
            require(payWithItem.amount 
                <=_transferSafe(payWithItem, msg.sender, beneficiary),
                "Insufficient balance after payment transfer"
            );
        }

        // 4. Send asset to buyer
        _transferSafe(_assetItem, address(this), _buyer);

        emit EnvelopPurchace(p.display, _assetItem.asset.contractAddress, _assetItem.tokenId);
    }

    //////////////////////////////////////////////////////////////
    function getDisplayOwner(bytes32 _displayNameHash) public view returns (address) {
        return displays[_displayNameHash].owner;
    }

    function getDisplay(bytes32 _displayNameHash) 
        public 
        view 
        returns (KTypes.Display memory) 
    {
        return displays[_displayNameHash];
    }

    function getAssetItemPlace(ETypes.AssetItem memory _assetItem) 
        public 
        view 
        returns  (KTypes.Place memory) 
    {
        if (_assetItem.asset.assetType == ETypes.AssetType.ERC721) {
            // ERC721
            require(
                _ownerOf(_assetItem) == address(this), 
                "Asset not transfered to kiosk"
            );
        } else {
            //ERC1155 or other**
            require(
                _balanceOf(_assetItem, address(this)) >= _assetItem.amount, 
                "Asset not transfered to kiosk"
            );
        }
        return assetAtDisplay[_assetItem.asset.contractAddress][_assetItem.tokenId];
    }

    function getAssetItemPricesAndDiscounts(
        ETypes.AssetItem memory _assetItem,
        address _buyer,
        address _referrer,
        string calldata _promo
    ) 
        external 
        view
        returns (KTypes.Price[] memory, KTypes.Discount[] memory)
    {
        return _getAssetItemPricesAndDiscounts(
            _assetItem,
            _buyer,
            _referrer,
            hlpHashString(_promo)
        );
    }

    /// @notice Returns ONLY items that was added with `addItemToDisplay`.
    /// @dev For obtain all items please use envelop oracle
    function getDisplayAssetItems(bytes32 _displayNameHash) 
        public 
        view 
        virtual
        returns (KTypes.ItemForSale[] memory) 
    {
        return displays[_displayNameHash].items; 
    }

    function getAssetItem(ETypes.AssetItem memory _assetItem)
        public
        view
        returns (KTypes.ItemForSale memory)
    {
        KTypes.Place memory p = getAssetItemPlace(_assetItem);
        return displays[p.display].items[p.index];

    } 

    function hlpHashString(string memory _name) public pure returns (bytes32) {
        return keccak256(abi.encode(_name));
    }

    /////////////////////////////
    ///       Internals        //
    /////////////////////////////
    function _setDisplayParams(
        bytes32 _displayNameHash,
        address _owner,
        address _beneficiary, // who will receive assets from sale
        uint256 _enableAfter,
        uint256 _disableAfter,
        address _priceModel
    ) 
        internal 
    {
        KTypes.Display storage d = displays[_displayNameHash];
        d.owner = _owner;
        d.beneficiary  = _beneficiary;
        d.enableAfter  = _enableAfter;
        d.disableAfter = _disableAfter;
        d.priceModel   = _priceModel;
    }

    function _addItemRecordAtDisplay(
        bytes32 _displayNameHash,
        address _itemOwner,
        ETypes.AssetItem memory _nft,
        KTypes.Price[] calldata _prices
    ) 
        internal 
        returns (KTypes.Place memory)
    {
        KTypes.ItemForSale storage it = displays[_displayNameHash].items.push();
        it.owner = _itemOwner;
        it.nft = _nft;
        if (_prices.length > 0){
            for (uint256 i = 0; i < _prices.length; ++ i) {
                it.prices.push(_prices[i]);    
            }
        }
        // add to mapping assetAtDisplay
        assetAtDisplay[_nft.asset.contractAddress][_nft.tokenId] = KTypes.Place(
            _displayNameHash,
            displays[_displayNameHash].items.length - 1
        );
        return assetAtDisplay[_nft.asset.contractAddress][_nft.tokenId];
    }

    function _addItemPriceAtIndex(
        bytes32 _displayNameHash,
        uint256 _itemIndex,
        KTypes.Price[] calldata _prices
    )
        internal
    {
        KTypes.ItemForSale storage it = displays[_displayNameHash].items[_itemIndex];
        for (uint256 i = 0; i < _prices.length; ++ i) {
            it.prices.push(_prices[i]);    
        }

    }


    function _editItemPriceAtIndex(
        bytes32 _displayNameHash,
        uint256 _itemIndex,
        uint256 _priceIndex,
        KTypes.Price calldata _price
    )
        internal
    {
        displays[_displayNameHash].items[_itemIndex].prices[_priceIndex] = _price;
    }

    function _getAssetItemPricesAndDiscounts(
        ETypes.AssetItem memory _assetItem,
        address _buyer,
        address _referrer,
        bytes32 _promoHash
    ) 
        internal
        view
        virtual
        returns(KTypes.Price[] memory, KTypes.Discount[] memory) 
    {
        // Define current asset Place
        KTypes.Place memory pl = getAssetItemPlace(_assetItem);
        if (pl.display == bytes32(0) && pl.index == 0){
            return (
                IDisplayPriceModel(displays[DEFAULT_DISPLAY].priceModel).getItemPrices(_assetItem),
                IDisplayPriceModel(displays[DEFAULT_DISPLAY].priceModel).getItemDiscounts(
                    _assetItem,
                    _buyer,
                    _referrer,
                    _promoHash
                )
            );
            //}
        }

        if (displays[pl.display].items[pl.index].prices.length > 0) 
        {
            return (
                displays[pl.display].items[pl.index].prices,
                IDisplayPriceModel(displays[pl.display].priceModel).getItemDiscounts(
                    _assetItem,
                    _buyer,
                    _referrer,
                    _promoHash
                )
            );
        }

        // If there is no individual prices then need ask priceModel contract of display
        return (
            IDisplayPriceModel(displays[pl.display].priceModel).getItemPrices(_assetItem),
            IDisplayPriceModel(displays[pl.display].priceModel).getItemDiscounts(
                _assetItem,
                _buyer,
                _referrer,
                _promoHash
            )
        );
    }
}

// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. Wrapper - main protocol contract
pragma solidity 0.8.16;

import "TokenService.sol";

abstract contract TokenServiceExtended is TokenService {
	

    function _balanceOf(
        ETypes.AssetItem memory _assetItem,
        address _holder
    ) internal view virtual returns (uint256 _balance){
        if (_assetItem.asset.assetType == ETypes.AssetType.NATIVE) {
            _balance = _holder.balance;
        
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC20) {
            _balance = IERC20Extended(_assetItem.asset.contractAddress).balanceOf(_holder);
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC721) {
            _balance = IERC721Mintable(_assetItem.asset.contractAddress).balanceOf(_holder); 
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC1155) {
            _balance = IERC1155Mintable(_assetItem.asset.contractAddress).balanceOf(_holder, _assetItem.tokenId);
        } else {
            revert UnSupportedAsset(_assetItem);
        }
    }

    function _ownerOf(
        ETypes.AssetItem memory _assetItem
    ) internal view virtual returns (address _owner){
        if (_assetItem.asset.assetType == ETypes.AssetType.NATIVE) {
            _owner = address(0);
        
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC20) {
            _owner = address(0);
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC721) {
            _owner = IERC721Mintable(_assetItem.asset.contractAddress).ownerOf(_assetItem.tokenId); 
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC1155) {
            _owner = address(0);
        } else {
            revert UnSupportedAsset(_assetItem);
        }
    }
}

// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. Wrapper - main protocol contract
pragma solidity 0.8.16;

import "SafeERC20.sol";
import "IERC20Extended.sol";
import "LibEnvelopTypes.sol";
import "IERC721Mintable.sol";
import "IERC1155Mintable.sol";
//import "ITokenService.sol";

abstract contract TokenService {
	using SafeERC20 for IERC20Extended;
    
    error UnSupportedAsset(ETypes.AssetItem asset);
	
    function _mintNFT(
        ETypes.AssetType _mint_type, 
        address _contract, 
        address _mintFor, 
        uint256 _tokenId, 
        uint256 _outBalance
    ) 
        internal 
        virtual
    {
        if (_mint_type == ETypes.AssetType.ERC721) {
            IERC721Mintable(_contract).mint(_mintFor, _tokenId);
        } else if (_mint_type == ETypes.AssetType.ERC1155) {
            IERC1155Mintable(_contract).mint(_mintFor, _tokenId, _outBalance);
        }
    }

    function _burnNFT(
        ETypes.AssetType _burn_type, 
        address _contract, 
        address _burnFor, 
        uint256 _tokenId, 
        uint256 _balance
    ) 
        internal
        virtual 
    {
        if (_burn_type == ETypes.AssetType.ERC721) {
            IERC721Mintable(_contract).burn(_tokenId);

        } else if (_burn_type == ETypes.AssetType.ERC1155) {
            IERC1155Mintable(_contract).burn(_burnFor, _tokenId, _balance);
        }
        
    }

    function _transfer(
        ETypes.AssetItem memory _assetItem,
        address _from,
        address _to
    ) internal virtual returns (bool _transfered){
        if (_assetItem.asset.assetType == ETypes.AssetType.NATIVE) {
            (bool success, ) = _to.call{ value: _assetItem.amount}("");
            require(success, "transfer failed");
            _transfered = true; 
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC20) {
            require(IERC20Extended(_assetItem.asset.contractAddress).balanceOf(_from) <= _assetItem.amount, "UPS!!!!");
            IERC20Extended(_assetItem.asset.contractAddress).safeTransferFrom(_from, _to, _assetItem.amount);
            _transfered = true;
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC721) {
            IERC721Mintable(_assetItem.asset.contractAddress).transferFrom(_from, _to, _assetItem.tokenId);
            _transfered = true;
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC1155) {
            IERC1155Mintable(_assetItem.asset.contractAddress).safeTransferFrom(_from, _to, _assetItem.tokenId, _assetItem.amount, "");
            _transfered = true;
        } else {
            revert UnSupportedAsset(_assetItem);
        }
        return _transfered;
    }

    function _transferSafe(
        ETypes.AssetItem memory _assetItem,
        address _from,
        address _to
    ) internal virtual returns (uint256 _transferedValue){
        //TODO   think about try catch in transfers
        uint256 balanceBefore;
        if (_assetItem.asset.assetType == ETypes.AssetType.NATIVE) {
            balanceBefore = _to.balance;
            (bool success, ) = _to.call{ value: _assetItem.amount}("");
            require(success, "transfer failed");
            _transferedValue = _to.balance - balanceBefore;
        
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC20) {
            balanceBefore = IERC20Extended(_assetItem.asset.contractAddress).balanceOf(_to);
            if (_from == address(this)){
                IERC20Extended(_assetItem.asset.contractAddress).safeTransfer(_to, _assetItem.amount);
            } else {
                IERC20Extended(_assetItem.asset.contractAddress).safeTransferFrom(_from, _to, _assetItem.amount);
            }    
            _transferedValue = IERC20Extended(_assetItem.asset.contractAddress).balanceOf(_to) - balanceBefore;
        
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC721 &&
            IERC721Mintable(_assetItem.asset.contractAddress).ownerOf(_assetItem.tokenId) == _from) {
            balanceBefore = IERC721Mintable(_assetItem.asset.contractAddress).balanceOf(_to); 
            IERC721Mintable(_assetItem.asset.contractAddress).transferFrom(_from, _to, _assetItem.tokenId);
            if (IERC721Mintable(_assetItem.asset.contractAddress).ownerOf(_assetItem.tokenId) == _to &&
                IERC721Mintable(_assetItem.asset.contractAddress).balanceOf(_to) - balanceBefore == 1
                ) {
                _transferedValue = 1;
            }
        
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC1155) {
            balanceBefore = IERC1155Mintable(_assetItem.asset.contractAddress).balanceOf(_to, _assetItem.tokenId);
            IERC1155Mintable(_assetItem.asset.contractAddress).safeTransferFrom(_from, _to, _assetItem.tokenId, _assetItem.amount, "");
            _transferedValue = IERC1155Mintable(_assetItem.asset.contractAddress).balanceOf(_to, _assetItem.tokenId) - balanceBefore;
        
        } else {
            revert UnSupportedAsset(_assetItem);
        }
        return _transferedValue;
    }

    // This function must never revert. Use it for unwrap in case some 
    // collateral transfers are revert
    function _transferEmergency(
        ETypes.AssetItem memory _assetItem,
        address _from,
        address _to
    ) internal virtual returns (uint256 _transferedValue){
        //TODO   think about try catch in transfers
        uint256 balanceBefore;
        if (_assetItem.asset.assetType == ETypes.AssetType.NATIVE) {
            balanceBefore = _to.balance;
            (bool success, ) = _to.call{ value: _assetItem.amount}("");
            //require(success, "transfer failed");
            _transferedValue = _to.balance - balanceBefore;
        
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC20) {
            if (_from == address(this)){
               (bool success, ) = _assetItem.asset.contractAddress.call(
                   abi.encodeWithSignature("transfer(address,uint256)", _to, _assetItem.amount)
               );
            } else {
                (bool success, ) = _assetItem.asset.contractAddress.call(
                    abi.encodeWithSignature("transferFrom(address,address,uint256)", _from,  _to, _assetItem.amount)
                );
            }    
            _transferedValue = _assetItem.amount;
        
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC721) {
            (bool success, ) = _assetItem.asset.contractAddress.call(
                abi.encodeWithSignature("transferFrom(address,address,uint256)", _from,  _to, _assetItem.tokenId)
            );
            _transferedValue = 1;
        
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC1155) {
            (bool success, ) = _assetItem.asset.contractAddress.call(
                abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", _from, _to, _assetItem.tokenId, _assetItem.amount, "")
            );
            _transferedValue = _assetItem.amount;
        
        } else {
            revert UnSupportedAsset(_assetItem);
        }
        return _transferedValue;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "draft-IERC20Permit.sol";
import "Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "IERC20.sol";

interface IERC20Extended is  IERC20 {
     function mint(address _to, uint256 _value) external;
}

// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. 
pragma solidity 0.8.16;

library ETypes {

    enum AssetType {EMPTY, NATIVE, ERC20, ERC721, ERC1155, FUTURE1, FUTURE2, FUTURE3}
    
    struct Asset {
        AssetType assetType;
        address contractAddress;
    }

    struct AssetItem {
        Asset asset;
        uint256 tokenId;
        uint256 amount;
    }

    struct NFTItem {
        address contractAddress;
        uint256 tokenId;   
    }

    struct Fee {
        bytes1 feeType;
        uint256 param;
        address token; 
    }

    struct Lock {
        bytes1 lockType;
        uint256 param; 
    }

    struct Royalty {
        address beneficiary;
        uint16 percent;
    }

    struct WNFT {
        AssetItem inAsset;
        AssetItem[] collateral;
        address unWrapDestination;
        Fee[] fees;
        Lock[] locks;
        Royalty[] royalties;
        bytes2 rules;

    }

    struct INData {
        AssetItem inAsset;
        address unWrapDestination;
        Fee[] fees;
        Lock[] locks;
        Royalty[] royalties;
        AssetType outType;
        uint256 outBalance;      //0- for 721 and any amount for 1155
        bytes2 rules;

    }

    struct WhiteListItem {
        bool enabledForFee;
        bool enabledForCollateral;
        bool enabledRemoveFromCollateral;
        address transferFeeModel;
    }

    struct Rules {
        bytes2 onlythis;
        bytes2 disabled;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "IERC721Metadata.sol";

interface IERC721Mintable is  IERC721Metadata {
     function mint(address _to, uint256 _tokenId) external;
     function burn(uint256 _tokenId) external;
     function exists(uint256 _tokenId) external view returns(bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "IERC1155MetadataURI.sol";

interface IERC1155Mintable is  IERC1155MetadataURI {
     function mint(address _to, uint256 _tokenId, uint256 _amount) external;
     function burn(address _to, uint256 _tokenId, uint256 _amount) external;
     function totalSupply(uint256 _id) external view returns (uint256); 
     function exists(uint256 _tokenId) external view returns(bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. 
pragma solidity 0.8.16;

import "LibEnvelopTypes.sol";


interface ITokenService {

    error UnSupportedAsset(ETypes.AssetItem asset);
	
	function mintNFT(
        ETypes.AssetType _mint_type, 
        address _contract, 
        address _mintFor, 
        uint256 _tokenId, 
        uint256 _outBalance
    ) 
        external;
    

    function burnNFT(
        ETypes.AssetType _burn_type, 
        address _contract, 
        address _burnFor, 
        uint256 _tokenId, 
        uint256 _balance
    ) 
        external; 

    function transfer(
        ETypes.AssetItem memory _assetItem,
        address _from,
        address _to
    ) external  returns (bool _transfered);

    function transferSafe(
        ETypes.AssetItem memory _assetItem,
        address _from,
        address _to
    ) external  returns (uint256 _transferedValue);

    // This function must never revert. Use it for unwrap in case some 
    // collateral transfers are revert
    function transferEmergency(
        ETypes.AssetItem memory _assetItem,
        address _from,
        address _to
    ) external  returns (uint256 _transferedValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "IERC1155Receiver.sol";
import "ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) NFT(wNFT) Kiosk Default Price Model;

pragma solidity 0.8.16;

import "IDisplayPriceModel.sol";
import "IEnvelopNFTKiosk.sol";
import "IWNFT.sol";

/// @title Default price model implementation
/// @author Envelop Team
/// @notice This model operate sellings of erc20 collateral inside wNFTS V1
/// @dev ..
contract DefaultPriceModel is IDisplayPriceModel {

    struct DiscountUntil {
        uint256 untilDate;
        KTypes.Discount discount;
    }

    // mapping from displayNameHash to ERC20 collateral prices
    mapping (bytes32 => mapping(address => KTypes.DenominatedPrice[])) public erc20CollateralPricesForDisplays;

    // mapping from displayNameHash to default price for all NFT at the display
    mapping (bytes32 => KTypes.Price[]) public defaultNFTPriceForDisplay;
    
    // mapping from displayNameHash to time discounts
    mapping (bytes32 => DiscountUntil[]) public timeDiscounts;

    // mapping from displayNameHash to PROMO hash to PROMO discount
    mapping (bytes32 => mapping (bytes32 => DiscountUntil)) public promoDiscounts;

    // mapping from displayNameHash to referrer hash to PROMO discount
    mapping (bytes32 => mapping (bytes32 => DiscountUntil)) public referrerDiscounts;


    IEnvelopNFTKiosk public kiosk;

    event CollateralPriceChanged(
        bytes32 indexed display,
        address indexed erc20Collateral
    );

    constructor (address _kiosk){
        kiosk = IEnvelopNFTKiosk(_kiosk);
    }

    /**
     * @dev Throws if called by any account other than the display owner.
     */
    modifier onlyDisplayOwner(bytes32 _displayNameHash) {
        require(
            kiosk.getDisplayOwner(_displayNameHash) == msg.sender, 
            "Only for Display Owner"
        );
        _;
    }

    function setCollateralPriceForDisplay(
        bytes32 _displayNameHash,
        address _erc20,
        KTypes.DenominatedPrice[] calldata _prices
    ) 
        external virtual
        onlyDisplayOwner(_displayNameHash) 

    {
        KTypes.DenominatedPrice[] storage prices = erc20CollateralPricesForDisplays[_displayNameHash][_erc20];
        for (uint256 i = 0; i < _prices.length; ++ i) {
            prices.push(_prices[i]);
            emit CollateralPriceChanged(_displayNameHash, _erc20);    
        }
    }

    function editCollateralPriceRecordForDisplay(
        bytes32 _displayNameHash,
        address _erc20,
        uint256 _priceIndex,
        KTypes.DenominatedPrice calldata _price
    )
        external virtual
        onlyDisplayOwner(_displayNameHash)
    {
        erc20CollateralPricesForDisplays[_displayNameHash][_erc20][_priceIndex] = _price;
        emit CollateralPriceChanged(_displayNameHash, _erc20);
    }

    function setDefaultNFTPriceForDisplay(
        bytes32 _displayNameHash,
        KTypes.Price[] calldata _prices
    ) 
       external virtual
       onlyDisplayOwner(_displayNameHash)
    {
        KTypes.Price[] storage prices = defaultNFTPriceForDisplay[_displayNameHash];
        for (uint256 i = 0; i < _prices.length; ++ i) {
            prices.push(_prices[i]);    
        }
    }

    function editDefaultNFTPriceRecordForDisplay(
        bytes32 _displayNameHash,
        uint256 _priceIndex,
        KTypes.Price calldata _price
    )
        external virtual
        onlyDisplayOwner(_displayNameHash)
    {
        defaultNFTPriceForDisplay[_displayNameHash][_priceIndex] = _price;
    }

    function setTimeDiscountsForDisplay(
        bytes32 _displayNameHash,
        DiscountUntil[] calldata _discounts
    ) 
       external virtual
       onlyDisplayOwner(_displayNameHash)
    {
        DiscountUntil[] storage discounts = timeDiscounts[_displayNameHash];
        for (uint256 i = 0; i < _discounts.length; ++ i) {
            discounts.push(_discounts[i]);
            emit DiscountChanged(
            _displayNameHash,
            uint8(KTypes.DiscountType.TIME),
            bytes32(_discounts[i].untilDate),
            _discounts[i].discount.dsctPercent
        );    
        }
    }

    function editTimeDiscountsForDisplay(
        bytes32 _displayNameHash,
        uint256 _discountIndex,
        DiscountUntil calldata _discount
    )
        external virtual
        onlyDisplayOwner(_displayNameHash)
    {
        timeDiscounts[_displayNameHash][_discountIndex] = _discount;
        emit DiscountChanged(
            _displayNameHash,
            uint8(KTypes.DiscountType.TIME),
            bytes32(_discount.untilDate),
            _discount.discount.dsctPercent
        );
    }

    function setPromoDiscountForDisplay(
        bytes32 _displayNameHash,
        bytes32 _promoHash,
        DiscountUntil calldata _discount
    ) 
        external virtual
        onlyDisplayOwner(_displayNameHash) 

    {
        promoDiscounts[_displayNameHash][_promoHash] = _discount;
        emit DiscountChanged(
            _displayNameHash,
            uint8(KTypes.DiscountType.PROMO),
            _promoHash,
            _discount.discount.dsctPercent
        );
    }

    function setRefereerDiscountForDisplay(
        bytes32 _displayNameHash,
        address _referrer,
        DiscountUntil calldata _discount
    ) 
        external virtual
        onlyDisplayOwner(_displayNameHash) 

    {
        referrerDiscounts[_displayNameHash][keccak256(abi.encode(_referrer))] = _discount; 
        emit DiscountChanged(
            _displayNameHash,
            uint8(KTypes.DiscountType.REFERRAL),
            keccak256(abi.encode(_referrer)),
            _discount.discount.dsctPercent
        );
    }
    /////////////////////////

    function getItemPrices(
        ETypes.AssetItem memory _assetItem
    ) external view virtual returns (KTypes.Price[] memory)
    {
        // 1. Try get collateral
        IWNFT wnftContract = IWNFT(_assetItem.asset.contractAddress);
        try wnftContract.wnftInfo(_assetItem.tokenId) returns (ETypes.WNFT memory wnft){
            KTypes.Place memory pl = _getVirtualPlace(_assetItem);
            // Only first collateral asset is tradable in this pricemodel
            KTypes.DenominatedPrice[] memory denPrices = _getCollateralUnitPrice(
                pl.display,
                wnft.collateral[0].asset.contractAddress
            );
            KTypes.Price[] memory prices = new KTypes.Price[](denPrices.length);
            for (uint256 i = 0; i < denPrices.length; ++ i ){
                // Calc wNFT price
                prices[i].payWith = denPrices[i].payWith;
                prices[i].amount = denPrices[i].amount 
                    * wnft.collateral[0].amount / denPrices[i].denominator;
            }
            return prices; 
        } catch {
            return getDefaultDisplayPrices(_assetItem);
        }
    }

    function getDefaultDisplayPrices(
        ETypes.AssetItem memory _assetItem
    ) public view virtual returns (KTypes.Price[] memory _prices)
    {
        // get display of given item
        KTypes.Place memory pl = _getVirtualPlace(_assetItem);
        _prices = defaultNFTPriceForDisplay[pl.display];
    }

    function getDisplayTimeDiscounts(
        bytes32 _displayNameHash
    ) public view virtual returns (DiscountUntil[] memory)

    {
        return timeDiscounts[_displayNameHash];
    } 

    function getItemDiscounts(
        ETypes.AssetItem memory _assetItem,
        address _buyer,
        address _referrer,
        bytes32 _promoHash
    ) public view virtual returns (KTypes.Discount[] memory)
    {
        uint256 totalDiscountsCount;
        KTypes.Place memory pl = _getVirtualPlace(_assetItem);
        // 1.First check time discounts for this display
        DiscountUntil[] storage tdArray = timeDiscounts[pl.display];
        KTypes.Discount memory td;
        for (uint256 i = 0; i < tdArray.length; ++ i){
            if (tdArray[i].untilDate > block.timestamp){
                ++ totalDiscountsCount; 
                td = tdArray[i].discount;
                break;
            }
        }

        // 2. Check PROMO Discount
        if (promoDiscounts[pl.display][_promoHash].untilDate > block.timestamp) {
            ++ totalDiscountsCount;
        }
        
        // 3. Check Referre Discount
        if (referrerDiscounts[pl.display][keccak256(abi.encode(_referrer))].untilDate > block.timestamp) {
            ++ totalDiscountsCount; 
        }
        //////////////////////////////////////
        KTypes.Discount[] memory discounts = new KTypes.Discount[](totalDiscountsCount);
        for (uint256 i = 0; i < discounts.length; ++ i){
            // add time discount to result
            if (td.dsctPercent > 0) {
                discounts[i] = td;
                continue;    
            }

            // add promo discount to result
            if (promoDiscounts[pl.display][_promoHash].untilDate > block.timestamp) {
                discounts[i] = KTypes.Discount(
                    promoDiscounts[pl.display][_promoHash].discount.dsctType,
                    promoDiscounts[pl.display][_promoHash].discount.dsctPercent
                );
                continue;
            }

            // add ref discount
            if (referrerDiscounts[pl.display][keccak256(abi.encode(_referrer))].untilDate > block.timestamp) {
                discounts[i] = KTypes.Discount(
                    referrerDiscounts[pl.display][keccak256(abi.encode(_referrer))].discount.dsctType,
                    referrerDiscounts[pl.display][keccak256(abi.encode(_referrer))].discount.dsctPercent
                );
                continue;
            }

        }
        return discounts;
    }

    function getBatchPrices(
        ETypes.AssetItem[] memory _assetItemArray
    ) external view virtual returns (KTypes.Price[] memory)
    {

    }
    
    function getBatchDiscounts(
        ETypes.AssetItem[] memory _assetItemArray,
        address _buyer,
        address _referrer,
        bytes32 _promoHash
    ) external view virtual returns (KTypes.Discount[] memory)
    {

    }

    function getCollateralUnitPrice(
        bytes32 _displayNameHash, 
        address _erc20
    ) external view returns(KTypes.DenominatedPrice[] memory){
        return _getCollateralUnitPrice(_displayNameHash,_erc20);
    }
    ///////////////////////////////////////////////////////////////////
    function _getCollateralUnitPrice(
        bytes32 _displayNameHash, 
        address _erc20
    ) internal view returns(KTypes.DenominatedPrice[] memory){
        return erc20CollateralPricesForDisplays[_displayNameHash][_erc20];
    }

    function _getVirtualPlace(ETypes.AssetItem memory _assetItem) 
        internal view returns(KTypes.Place memory place) 
    {
        place = kiosk.getAssetItemPlace(_assetItem);
        if (place.display == bytes32(0)) {
               place.display = kiosk.DEFAULT_DISPLAY();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

//import "IERC721Enumerable.sol";
import "LibEnvelopTypes.sol";
import "KTypes.sol";

interface IDisplayPriceModel  {
    
    event DiscountChanged(
        bytes32 indexed display,
        uint8 indexed DiscountType,
        bytes32 DiscountParam,
        uint16 DiscountPercent
    );

    function getItemPrices(
        ETypes.AssetItem memory _assetItem
    ) external view returns (KTypes.Price[] memory);

    function getDefaultDisplayPrices(
        ETypes.AssetItem memory _assetItem
    ) external view returns (KTypes.Price[] memory);
    
    function getItemDiscounts(
        ETypes.AssetItem memory _assetItem,
        address _buyer,
        address _referrer,
        bytes32 _promoHash
    ) external view returns (KTypes.Discount[] memory);

    function getBatchPrices(
        ETypes.AssetItem[] memory _assetItemArray
    ) external view returns (KTypes.Price[] memory);
    
    function getBatchDiscounts(
        ETypes.AssetItem[] memory _assetItemArray,
        address _buyer,
        address _referrer,
        bytes32 _promoHash
    ) external view returns (KTypes.Discount[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. 
import "LibEnvelopTypes.sol";

pragma solidity 0.8.16;
library KTypes {
	enum DiscountType {PROMO, REFERRAL, BATCH, TIME, WHITELIST, CUSTOM1, CUSTOM2, CUSTOM3}

    struct Price {
        address payWith;
        uint256 amount;
    }

    struct DenominatedPrice {
        address payWith;
        uint256 amount;
        uint256 denominator;
    }

    struct Discount {
        DiscountType dsctType;
        uint16 dsctPercent; // 100%-10000, 20%-2000, 3%-300
    }

    struct ItemForSale {
        address owner;
        ETypes.AssetItem nft;
        Price[] prices;
    }

    struct Display {
        address owner;
        address beneficiary; // who will receive assets from sale
        uint256 enableAfter;
        uint256 disableAfter;
        address priceModel;
        ItemForSale[] items;
    }

    struct Place {
        bytes32 display;
        uint256 index;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;
import "LibEnvelopTypes.sol";
import "KTypes.sol";

interface IEnvelopNFTKiosk  {

    function DEFAULT_DISPLAY() external view returns (bytes32);
    
    function getDisplayOwner(
        bytes32 _displayNameHash
    ) external view returns (address);
    
    function getAssetItemPlace(
        ETypes.AssetItem memory _assetItem
    ) external view returns (KTypes.Place memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;
import "LibEnvelopTypes.sol";

interface IWNFT  {
    function wnftInfo(uint256 tokenId) 
        external view returns (ETypes.WNFT memory);
}