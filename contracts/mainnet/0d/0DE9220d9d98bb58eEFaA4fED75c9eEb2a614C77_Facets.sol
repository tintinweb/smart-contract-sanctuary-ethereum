// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz
/// @artist: Justin Maller
/// @title: Facets

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                    &&&     &&&#                                                    //
//                                              .&&&&&&&&     &&&&&&&&%                                               //
//                                         ,&&&&&&&&&&&&&     &&&&&&&&&&&&&#                                          //
//                                    .&&&&&&&&&&&&&&&&&&     &&&&&&&&&&&&&&&&&&%                                     //
//                               ,&&&&&&&&&&&&(                         ,&&&&&&&&&&&&&                                //
//                          *&&/                                                       ,&&%                           //
//                                            %&&&&&&&           &&&&&&&&,                                            //
//                            .%&&&&&&&&&&&&&&&&&&&&%      &%      &&&&&&&&&&&&&&&&&&&&&.                             //
//              #&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%,              //
//             .&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&(      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&              //
//              (&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&               //
//               %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&.     ,&&&&&&&&&&&&&&&&&&&&&&&&&&&&&                //
//                &&&&&&&&&&&&&&&&&&&&&&&&&&&      #&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&                 //
//                 &&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&&&&&      /&&&&&&&&&&&&&&&&&&&&&&&&                  //
//            ,     &&&&&&&&&&&&&&&&&&&&&&      ,&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&&&&&&&&     &             //
//             &     &&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&      %&&&&&&&&&&&&&&&&&&&     %&             //
//             &&     &&&&&&&&&&&&&&&&&,      &&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&&&     /&#             //
//             &&&     &&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&&&&&&     .&&,             //
//             &&&&     &&&&&&&&&&&&(      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#      &&&&&&&&&&&&,     &&&              //
//             &&&&#     &&&&&&&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&&&&&(     &&&&              //
//             &&&&&/     &&&&&&&%      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&.      &&&&&&&%     &&&&&              //
//             &&&&&&.     &&&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &&&&&&     &&&&&&              //
//             &&&&&&&     .&&&      &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &&&     &&&&&&&              //
//             ,&&&&&&&     /      *&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&      &     &&&&&&&&              //
//              &&&&&&&&          &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&          &&&&&&&&&              //
//              &&&&&&&&&                                                                     &&&&&&&&&&              //
//              &&&&&&%                                                                          &&&&&&,              //
//              &&&        *       &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &        &&&               //
//                      &&&&&&       &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &&&&&&                       //
//                  ,&&&&&&&&&&&       &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &&&&&&&&&&&&                   //
//                 ,&&&&&&&&&&&&&&       %&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &&&&&&&&&&&&&&%                  //
//                      &&&&&&&&&&&&,      /&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &&&&&&&&&&&&*                      //
//                          &&&&&&&&&&/      .&&&&&&&&&&&&&&&&&&&&&&&&&&&&       &&&&&&&&&&                           //
//                              %&&&&&&&#       &&&&&&&&&&&&&&&&&&&&&&&&       &&&&&&&&                               //
//                                  *&&&&&&       &&&&&&&&&&&&&&&&&&&%       &&&&&&                                   //
//                                       &&&&       &&&&&&&&&&&&&&&(      ,&&&#                                       //
//                                           &&       &&&&&&&&&&&*      (&.                                           //
//                                                      &&&&&&&.                                                      //
//                                                        &&&                                                         //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
//                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ERC721/IERC721CreatorExtensionApproveTransfer.sol";

import "./ERC721BurnRedeem.sol";
import "./ERC721CreatorCollectionBase.sol";
import "./DutchAuction.sol";

contract Facets is ERC721CreatorCollectionBase, IERC721CreatorExtensionApproveTransfer, DutchAuction, ReentrancyGuard, AdminControl {

    event SenderRefunded(
        uint256 received,
        uint256 returned
    );

    constructor(address creatorAddress, address signingAddress) {
        _initialize(
            creatorAddress,
            365, // purchaseMax_
            3650000000000000000, // purchasePrice_
            365, // purchaseLimit_
            365, // transactionLimit_ 
            0, // presalePurchasePrice_
            0, // presalePurchaseLimit_ 
            signingAddress, 
            false // useDynamicPresalePurchaseLimit_
        );
        minimumPrice = 500000000000000000;
        priceDropInterval = 300;
        priceDropMagnitude = 50000000000000000;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721CreatorCollectionBase, IERC165, AdminControl) returns (bool) {
        return interfaceId == type(IERC721CreatorExtensionApproveTransfer).interfaceId || ERC721CreatorCollectionBase.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Collection-withdraw}.
     */
    function withdraw(address payable recipient, uint256 amount) external override adminRequired {
        _withdraw(recipient, amount);
    }

    /**
     * @dev See {IERC721Collection-premint}.
     */
    function premint(uint16 amount) external override adminRequired {
        _premint(amount, owner());
    }

    /**
     * @dev See {IERC721Collection-premint}.
     */
    function premint(address[] calldata addresses) external override adminRequired {
        _premint(addresses);
    }

    /**
     * @dev See {ERC721CreatorCollectionBase-purchase}.
     */
    function purchase(uint16 amount, bytes32 message, bytes calldata signature, bytes32 nonce) public override payable nonReentrant {
        ERC721CreatorCollectionBase.purchase(amount, message, signature, nonce);
        uint256 totalPrice = amount * getCurrentPrice(presalePurchasePrice, purchasePrice);
        if (msg.value > totalPrice) {
            Address.sendValue(payable(msg.sender), msg.value - totalPrice);
            emit SenderRefunded(msg.value, msg.value - totalPrice);
        }
    }

    /**
     * Validate price
     */
    function _validatePrice(uint16 amount) internal override {
        require(msg.value >= amount * getCurrentPrice(presalePurchasePrice, purchasePrice), "Invalid purchase amount sent");
    }

    /**
     * @dev See {IERC721Collection-activate}.
     */
    function activate(uint256 startTime_, uint256 duration, uint256 presaleInterval_, uint256 claimStartTime_, uint256 claimEndTime_) external override adminRequired {
        _activate(startTime_, duration, presaleInterval_, claimStartTime_, claimEndTime_);
    }

    /**
     * @dev See {IERC721Collection-deactivate}.
     */
    function deactivate() external override adminRequired {
        _deactivate();
    }

    /**
     *  @dev See {IERC721Collection-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }
    
    function setTransferLocked(bool locked) external override adminRequired {
        _setTransferLocked(locked);
    }

    /**
     * @dev See {IERC721CreatorExtensionApproveTransfer-setApproveTransfer}
     */
    function setApproveTransfer(address creator, bool enabled) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId), "Creator must implement IERC721CreatorCore");
        IERC721CreatorCore(creator).setApproveTransferExtension(enabled);
    }

    /**
     * @dev See {IERC721CreatorExtensionApproveTransfer-approveTransfer}.
     */
    function approveTransfer(address from, address, uint256) external view override returns (bool) {
        return _validateTokenTransferability(from);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./CollectionBase.sol";

/**
 * Faux dutch auction library - purchase price descends to 0 over the duration of the sale at a set rate.
 */
abstract contract DutchAuction is CollectionBase {

    struct DutchAuctionData {
        uint256 minimumPrice;
        uint256 priceDropInterval;
        uint256 priceDropMagnitude;
    }

    // If set, price during sale will not drop below this threshold.
    uint256 public minimumPrice;

    uint256 public priceDropInterval;
    uint256 public priceDropMagnitude;

    /**
     * @dev returns pricing data used to compute current price
     */
    function pricingData() external view returns (DutchAuctionData memory) {
        return DutchAuctionData(minimumPrice, priceDropInterval, priceDropMagnitude);
    }

    /**
     * @dev Get current price for the token sale based on dutch auction pricing mechanics
     * @param presalePurchasePrice The price of the token during the presale interval.
     * @param startPrice The starting price of the token during the public sale.
     */
    function getCurrentPrice(uint256 presalePurchasePrice, uint256 startPrice) internal view returns (uint256) {
        if (_isPresale()) {
            return presalePurchasePrice;
        }
        uint256 timeElapsed = block.timestamp - publicSaleStartTime();
        uint256 discount = (timeElapsed / priceDropInterval) * priceDropMagnitude;
        if (discount > startPrice) {
            return minimumPrice;
        }
        uint256 currentPrice = startPrice - discount;
        return currentPrice > minimumPrice ? currentPrice : minimumPrice;
    }

    function publicSaleStartTime() public view returns (uint256) {
        return startTime + presaleInterval;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/CreatorExtension.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IERC721Collection.sol";
import "./CollectionBase.sol";

/**
 * ERC721 Creator Collection Drop Contract (Base)
 */
abstract contract ERC721CreatorCollectionBase is CollectionBase, CreatorExtension, IERC721Collection {
    
    using Strings for uint256;

    // Immutable variables that should only be set by the constructor or initializer
    address internal _creator;
    uint16 public transactionLimit;
    uint16 public purchaseMax;
    uint256 public purchasePrice;
    uint16 public purchaseLimit;
    uint256 public presalePurchasePrice;
    uint16 public presalePurchaseLimit;
    bool public useDynamicPresalePurchaseLimit;

    // Minted token information
    uint16 public purchaseCount;
    mapping(address => uint16) internal _addressMintCount;

    // Transfer lock
    bool public transferLocked;

    function _initialize(address creator, uint16 purchaseMax_, uint256 purchasePrice_, uint16 purchaseLimit_, uint16 transactionLimit_, uint256 presalePurchasePrice_, uint16 presalePurchaseLimit_, address signingAddress, bool useDynamicPresalePurchaseLimit_) internal {
        require(_creator == address(0) && _signingAddress == address(0), "Already initialized");
        _creator = creator;
        purchaseMax = purchaseMax_;
        purchasePrice = purchasePrice_;
        purchaseLimit = purchaseLimit_;
        transactionLimit = transactionLimit_;
        presalePurchasePrice = presalePurchasePrice_;
        presalePurchaseLimit = presalePurchaseLimit_;
        _signingAddress = signingAddress;
        useDynamicPresalePurchaseLimit = useDynamicPresalePurchaseLimit_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorExtension, IERC165) returns (bool) {
      return interfaceId == type(IERC721Collection).interfaceId || CreatorExtension.supportsInterface(interfaceId);
    }

    /**
     * Premint tokens to the owner.  Sale must not be active.
     */
    function _premint(uint16 amount, address owner) internal virtual {
        require(!active, "Already active");
        _mint(owner, amount);
    }

    /**
     * Premint tokens to the list of addresses.  Sale must not be active.
     */
    function _premint(address[] calldata addresses) internal virtual {
        require(!active, "Already active");
        for (uint i = 0; i < addresses.length; ) {
            _mint(addresses[i], 1);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev override if you want to perform different mint functionality
     */
    function _mint(address to, uint16 amount) internal virtual {
        if (amount == 1) {
            purchaseCount++;
        
            // Mint token
            uint256 tokenId = IERC721CreatorCore(_creator).mintExtension(to);
            
            emit Unveil(purchaseCount, _creator, tokenId);
        } else {
            uint256 tokenStart = purchaseCount+1;
            purchaseCount += amount;
        
            // Mint token
            uint256[] memory tokenIds = IERC721CreatorCore(_creator).mintExtensionBatch(to, amount);

            for (uint i = 0; i < tokenIds.length; ) {
                emit Unveil(tokenStart+i, _creator, tokenIds[i]);
                unchecked {
                    i++;
                }
            }
        }
    }

    /**
     *  Set the tokenURI prefix
     */
    function _setTokenURIPrefix(string calldata prefix) internal virtual {
        IERC721CreatorCore(_creator).setBaseTokenURIExtension(prefix);
    }
    
    /**
     * Validate price (override for custom pricing mechanics)
     */
    function _validatePrice(uint16 amount) internal virtual {
      require(msg.value == amount*purchasePrice, "Invalid purchase amount sent");
    }

    /**
     * Validate price (override for custom pricing mechanics)
     */
    function _validatePresalePrice(uint16 amount) internal virtual {
      require(msg.value == amount*presalePurchasePrice, "Invalid purchase amount sent");
    }

    /**
     * Returns whether or not token transfers are enabled.
     */
    function _validateTokenTransferability(address from) internal view returns(bool) {
        return from == address(0) || !transferLocked;
    }

    /**
     * Set whether or not token transfers are locked
     */
    function _setTransferLocked(bool locked) internal {
        transferLocked = locked;
    }

    /**
     * @dev See {IERC721Collection-claim}.
     */
    function claim(uint16 amount, bytes32 message, bytes calldata signature, bytes32 nonce) external virtual override {
        _validateClaimRestrictions();
        _validateClaimRequest(message, signature, nonce, amount);
        _mint(msg.sender, amount);

        _addressMintCount[msg.sender] += amount;
    }
    
    /**
     * @dev See {IERC721Collection-purchase}.
     */
    function purchase(uint16 amount, bytes32 message, bytes calldata signature, bytes32 nonce) public payable virtual override {
        _validatePurchaseRestrictions();

        bool isPresale = _isPresale();

        // Check purchase amounts
        require(amount <= purchaseRemaining() && ((isPresale && useDynamicPresalePurchaseLimit) || transactionLimit == 0 || amount <= transactionLimit), "Too many requested");

        if (isPresale) {
            if (!useDynamicPresalePurchaseLimit) {
                // Make sure we are not over presalePurchaseLimit
                if (presalePurchaseLimit != 0) {
                    uint16 mintCount = _addressMintCount[msg.sender];
                    require(presalePurchaseLimit > mintCount && amount <= (presalePurchaseLimit-mintCount), "Too many requested");
                }
                // Make sure we are not over purchaseLimit
                if (purchaseLimit != 0) {
                    uint16 mintCount = _addressMintCount[msg.sender];
                    require(purchaseLimit > mintCount && amount <= (purchaseLimit-mintCount), "Too many requested");
                }
            }
            _validatePresalePrice(amount);
            // Only track mint count if needed
            if (!useDynamicPresalePurchaseLimit && (presalePurchaseLimit != 0 || purchaseLimit != 0)) {
                _addressMintCount[msg.sender] += amount;
            }
        } else {
            // Make sure we are not over purchaseLimit
            if (purchaseLimit != 0) {
                uint16 mintCount = _addressMintCount[msg.sender];
                require(purchaseLimit > mintCount && amount <= (purchaseLimit-mintCount), "Too many requested");
            }
            _validatePrice(amount);
            if (purchaseLimit != 0) {
                _addressMintCount[msg.sender] += amount;
            }
        }

        if (isPresale && useDynamicPresalePurchaseLimit) {
            _validatePurchaseRequestWithAmount(message, signature, nonce, amount);
        } else {
            _validatePurchaseRequest(message, signature, nonce);
        }

        _mint(msg.sender, amount);
    }

    /**
     * @dev See {IERC721Collection-state}
     */
    function state() external override view returns(CollectionState memory) {
        return CollectionState(transactionLimit, purchaseMax, purchaseRemaining(), purchasePrice, purchaseLimit, presalePurchasePrice, presalePurchaseLimit, _addressMintCount[msg.sender], active, startTime, endTime, presaleInterval, claimStartTime, claimEndTime, useDynamicPresalePurchaseLimit);
    }

    /**
     * @dev See {IERC721Collection-purchaseRemaining}.
     */
    function purchaseRemaining() public view virtual override returns(uint16) {
        return purchaseMax-purchaseCount;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";

import "./ERC721RedeemBase.sol";
import "./IERC721BurnRedeem.sol";

/**
 * @dev Burn NFT's to receive another lazy minted NFT
 */
contract ERC721BurnRedeem is ReentrancyGuard, ERC721RedeemBase, IERC721BurnRedeem, IERC1155Receiver, IERC721Receiver {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping (address => mapping (uint256 => address)) private _recoverableERC721;

    constructor(address creator, uint16 redemptionRate, uint16 redemptionMax) ERC721RedeemBase(creator, redemptionRate, redemptionMax) {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721RedeemBase, IERC165) returns (bool) {
        return interfaceId == type(IERC721BurnRedeem).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId
            || interfaceId == type(IERC721Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721BurnRedeem-setERC721Recoverable}
     */
    function setERC721Recoverable(address contract_, uint256 tokenId, address recoverer) external virtual override adminRequired {
        require(ERC165Checker.supportsInterface(contract_, type(IERC721).interfaceId), "BurnRedeem: Must implement IERC721");
        _recoverableERC721[contract_][tokenId] = recoverer;
    }

    /**
     * @dev See {IERC721BurnRedeem-recoverERC721}
     */
    function recoverERC721(address contract_, uint256 tokenId) external virtual override {
        address recoverer = _recoverableERC721[contract_][tokenId];
        require(recoverer == msg.sender, "BurnRedeem: Permission denied");
        IERC721(contract_).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    /**
     * @dev See {IERC721BurnRedeem-redeemERC721}
     */
    function redeemERC721(address[] calldata contracts, uint256[] calldata tokenIds) external virtual override nonReentrant {
        require(contracts.length == tokenIds.length, "BurnRedeem: Invalid parameters");
        require(contracts.length == _redemptionRate, "BurnRedeem: Incorrect number of NFTs being redeemed");

        // Attempt Burn
        for (uint i = 0; i < contracts.length; i++) {
            // Check that we can burn
            require(redeemable(contracts[i], tokenIds[i]), "BurnRedeem: Invalid NFT");

            try IERC721(contracts[i]).ownerOf(tokenIds[i]) returns (address ownerOfAddress) {
                require(ownerOfAddress == msg.sender, "BurnRedeem: Caller must own NFTs");
            } catch (bytes memory) {
                revert("BurnRedeem: Bad token contract");
            }

            if (!IERC721(contracts[i]).isApprovedForAll(msg.sender, address(this))) {
                try IERC721(contracts[i]).getApproved(tokenIds[i]) returns (address approvedAddress) {
                    require(approvedAddress == address(this), "BurnRedeem: Contract must be given approval to burn NFT");
                } catch (bytes memory) {
                    revert("BurnRedeem: Bad token contract");
                }
            }
            
            // Then burn
            try IERC721(contracts[i]).transferFrom(msg.sender, address(0xdEaD), tokenIds[i]) {
            } catch (bytes memory) {
                revert("BurnRedeem: Burn failure");
            }
        }

        // Mint reward
        _mintRedemption(msg.sender);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(address, address from, uint256 tokenId, bytes calldata data) external override nonReentrant returns (bytes4) {
        require(redeemable(msg.sender, tokenId), "BurnRedeem: Invalid NFT");
        require(_redemptionRate == 1, "BurnRedeem: Can only allow direct receiving of redemptions of 1 NFT");
        
        
        // Burn it
        try IERC721(msg.sender).safeTransferFrom(address(this), address(0xdEaD), tokenId, data) {
        } catch (bytes memory) {
            revert("BurnRedeem: Burn failure");
        }

        // Mint reward
        _mintRedemption(from);

        return this.onERC721Received.selector;
    }


    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override nonReentrant returns(bytes4) {
        require(redeemable(msg.sender, id), "BurnRedeem: Invalid NFT");
        require(value == _redemptionRate, "BurnRedeem: Incorrect number of NFTs being redeemed");

        // Burn it
        try IERC1155(msg.sender).safeTransferFrom(address(this), address(0xdEaD), id, value, data) {
        } catch (bytes memory) {
            revert("BurnRedeem: Burn failure");
        }

        // Mint reward
        _mintRedemption(from);

        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override nonReentrant returns(bytes4) {
        require(ids.length == values.length, "BurnRedeem: Invalid input");

        uint256 totalValue = 0;
        for (uint i=0; i<ids.length; i++) {
            require(redeemable(msg.sender, ids[i]), "BurnRedeem: Invalid NFT");
            totalValue += values[i];
        }

        require(totalValue == _redemptionRate, "BurnRedeem: Incorrect number of NFTs being redeemed");

        // Burn it
        try IERC1155(msg.sender).safeBatchTransferFrom(address(this), address(0xdEaD), ids, values, data) {
        } catch (bytes memory) {
            revert("BurnRedeem: Burn failure");
        }

        // Mint reward
        _mintRedemption(from);

        return this.onERC1155BatchReceived.selector;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * Implement this if you want your extension to approve a transfer
 */
interface IERC721CreatorExtensionApproveTransfer is IERC165 {

    /**
     * @dev Set whether or not the creator will check the extension for approval of token transfer
     */
    function setApproveTransfer(address creator, bool enabled) external;

    /**
     * @dev Called by creator contract to approve a transfer
     */
    function approveTransfer(address from, address to, uint256 tokenId) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAdminControl.sol";

abstract contract AdminControl is Ownable, IAdminControl, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Track registered admins
    EnumerableSet.AddressSet private _admins;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IAdminControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Only allows approved admins to call the specified function
     */
    modifier adminRequired() {
        require(owner() == msg.sender || _admins.contains(msg.sender), "AdminControl: Must be owner or admin");
        _;
    }   

    /**
     * @dev See {IAdminControl-getAdmins}.
     */
    function getAdmins() external view override returns (address[] memory admins) {
        admins = new address[](_admins.length());
        for (uint i = 0; i < _admins.length(); i++) {
            admins[i] = _admins.at(i);
        }
        return admins;
    }

    /**
     * @dev See {IAdminControl-approveAdmin}.
     */
    function approveAdmin(address admin) external override onlyOwner {
        if (!_admins.contains(admin)) {
            emit AdminApproved(admin, msg.sender);
            _admins.add(admin);
        }
    }

    /**
     * @dev See {IAdminControl-revokeAdmin}.
     */
    function revokeAdmin(address admin) external override onlyOwner {
        if (_admins.contains(admin)) {
            emit AdminRevoked(admin, msg.sender);
            _admins.remove(admin);
        }
    }

    /**
     * @dev See {IAdminControl-isAdmin}.
     */
    function isAdmin(address admin) public override view returns (bool) {
        return (owner() == admin || _admins.contains(admin));
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./ICollectionBase.sol";

/**
 * Collection Drop Contract (Base)
 */
abstract contract CollectionBase is ICollectionBase {
    
    using ECDSA for bytes32;

    // Immutable variables that should only be set by the constructor or initializer
    address internal _signingAddress;

    // Message nonces
    mapping(bytes32 => bool) private _usedNonces;

    // Sale start/end control
    bool public active;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public presaleInterval;

    // Claim period start/end control
    uint256 public claimStartTime;
    uint256 public claimEndTime;

    /**
     * Withdraw funds
     */
    function _withdraw(address payable recipient, uint256 amount) internal {
        (bool success,) = recipient.call{value:amount}("");
        require(success);
    }

    /**
     * Activate the sale
     */
    function _activate(uint256 startTime_, uint256 duration, uint256 presaleInterval_, uint256 claimStartTime_, uint256 claimEndTime_) internal virtual {
        require(!active, "Already active");
        require(startTime_ > block.timestamp, "Cannot activate in the past");
        require(presaleInterval_ <= duration, "Presale Interval cannot be longer than the sale");
        require(claimStartTime_ <= claimEndTime_ && claimEndTime_ <= startTime_, "Invalid claim times");
        startTime = startTime_;
        endTime = startTime + duration;
        presaleInterval = presaleInterval_;
        claimStartTime = claimStartTime_;
        claimEndTime = claimEndTime_;
        active = true;

        emit CollectionActivated(startTime, endTime, presaleInterval, claimStartTime, claimEndTime);
    }

    /**
     * Deactivate the sale
     */
    function _deactivate() internal virtual {
        startTime = 0;
        endTime = 0;
        active = false;
        claimStartTime = 0;
        claimEndTime = 0;

        emit CollectionDeactivated();
    }

    /**
     * Validate claim signature
     */
    function _validateClaimRequest(bytes32 message, bytes calldata signature, bytes32 nonce, uint16 amount) internal virtual {
        _validatePurchaseRequestWithAmount(message, signature, nonce, amount);
    }

    /**
     * Validate claim restrictions
     */
    function _validateClaimRestrictions() internal virtual {
        require(active, "Inactive");
        require(block.timestamp >= claimStartTime && block.timestamp <= claimEndTime, "Outside claim period.");
    }

    /**
     * Validate purchase signature
     */
    function _validatePurchaseRequest(bytes32 message, bytes calldata signature, bytes32 nonce) internal virtual { 
        // Verify nonce usage/re-use
        require(!_usedNonces[nonce], "Cannot replay transaction");
        // Verify valid message based on input variables
        bytes32 expectedMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n52", msg.sender, nonce));
        require(message == expectedMessage, "Malformed message");
        // Verify signature was performed by the expected signing address
        address signer = message.recover(signature);
        require(signer == _signingAddress, "Invalid signature");

        _usedNonces[nonce] = true;
    }

    /**
     * Validate purchase signature with amount
     */
    function _validatePurchaseRequestWithAmount(bytes32 message, bytes calldata signature, bytes32 nonce, uint16 amount) internal virtual {
        // Verify nonce usage/re-use
        require(!_usedNonces[nonce], "Cannot replay transaction");
        // Verify valid message based on input variables
        bytes32 expectedMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n54", msg.sender, nonce, amount));
        require(message == expectedMessage, "Malformed message");
        // Verify signature was performed by the expected signing address
        address signer = message.recover(signature);
        require(signer == _signingAddress, "Invalid signature");

        _usedNonces[nonce] = true;
    }

    /**
     * Perform purchase restriciton checks. Override if more logic is needed
     */
    function _validatePurchaseRestrictions() internal virtual {
        require(active, "Inactive");
        require(block.timestamp >= startTime, "Purchasing not active");
    }

    /**
     * @dev See {ICollectionBase-nonceUsed}.
     */
    function nonceUsed(bytes32 nonce) external view override returns(bool) {
        return _usedNonces[nonce];
    }

    /**
     * @dev Check if currently in presale
     */
    function _isPresale() internal view returns (bool) {
        return block.timestamp > startTime && block.timestamp - startTime < presaleInterval;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./ICollectionBase.sol";

/**
 * @dev ERC721 Collection Interface
 */
interface IERC721Collection is ICollectionBase, IERC165 {

    event Unveil(uint256 collectibleId, address tokenAddress, uint256 tokenId);

    struct CollectionState {
        uint16 transactionLimit;
        uint16 purchaseMax;
        uint16 purchaseRemaining;
        uint256 purchasePrice;
        uint16 purchaseLimit;
        uint256 presalePurchasePrice;
        uint16 presalePurchaseLimit;
        uint16 purchaseCount;
        bool active;
        uint256 startTime;
        uint256 endTime;
        uint256 presaleInterval;
        uint256 claimStartTime;
        uint256 claimEndTime;
        bool useDynamicPresalePurchaseLimit;
    }

    /**
     * @dev Pre-mint
     */
    function premint(uint16 amount) external;

    function premint(address[] calldata addresses) external;

    /**
     *  @dev set the tokenURI prefix
     */
    function setTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev Withdraw funds
     */
    function withdraw(address payable recipient, uint256 amount) external;

    /**
     * @dev Set whether or not token transfers are locked until end of sale.
     * @param locked Whether or not transfers are locked
     */
    function setTransferLocked(bool locked) external;

    /**
     * @dev Activate the contract
     */
    function activate(uint256 startTime_, uint256 duration, uint256 presaleInterval_, uint256 claimStartTime_, uint256 claimEndTime_) external;

    /**
     * @dev Deactivate the contract
     */
    function deactivate() external;

    /**
     * @dev claim
     */
    function claim(uint16 amount, bytes32 message, bytes calldata signature, bytes32 nonce) external;
    
    /**
     * @dev purchase
     */
    function purchase(uint16 amount, bytes32 message, bytes calldata signature, bytes32 nonce) external payable;

    /**
     * @dev returns the collection state
     */
    function state() external view returns(CollectionState memory);

    /**
     * @dev Get number of tokens left
     */
    function purchaseRemaining() external view returns(uint16);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Base creator extension variables
 */
abstract contract CreatorExtension is ERC165 {

    /**
     * @dev Legacy extension interface identifiers
     *
     * {IERC165-supportsInterface} needs to return 'true' for this interface
     * in order backwards compatible with older creator contracts
     */
    bytes4 constant internal LEGACY_EXTENSION_INTERFACE = 0x7005caad;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == LEGACY_EXTENSION_INTERFACE
            || super.supportsInterface(interfaceId);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ICreatorCore.sol";

/**
 * @dev Core ERC721 creator interface
 */
interface IERC721CreatorCore is ICreatorCore {

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBase(address to) external returns (uint256);

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBase(address to, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatch(address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatch(address to, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to) external returns (uint256);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtension(address to, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenIds minted
     */
    function mintExtensionBatch(address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtensionBatch(address to, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev burn a token. Can only be called by token owner or approved address.
     * On burn, calls back to the registered extension's onBurn method
     */
    function burn(uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IERC721RedeemBase.sol";

/**
 * @dev Burn NFT's to receive another lazy minted NFT
 */
interface IERC721BurnRedeem is IERC721RedeemBase {

    /**
     * @dev Enable recovery of a given token. Can only be called by contract owner/admin.
     * This is a special function used in case someone accidentally sends a token to this contract.
     */
    function setERC721Recoverable(address contract_, uint256 tokenId, address recoverer) external;

    /**
     * @dev Recover a token.  Returns it to the recoverer set by setERC721Recoverable
     * This is a special function used in case someone accidentally sends a token to this contract.
     */
    function recoverERC721(address contract_, uint256 tokenId) external;

    /**
     * @dev Redeem ERC721 tokens for redemption reward NFT.
     * Requires the user to grant approval beforehand by calling contract's 'approve' function.
     * If the it cannot redeem the NFT, it will clear approvals
     */
    function redeemERC721(address[] calldata contracts, uint256[] calldata tokenIds) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/CreatorExtension.sol";

import "./ERC721SingleCreatorExtension.sol";

import "./RedeemBase.sol";
import "./IERC721RedeemBase.sol";

/**
 * @dev Redeem NFT base logic
 */
abstract contract ERC721RedeemBase is ERC721SingleCreatorExtension, RedeemBase, CreatorExtension, IERC721RedeemBase {

    uint16 internal immutable _redemptionRate;
    uint16 private _redemptionMax;
    uint16 private _redemptionCount;
    uint256[] private _mintedTokens;
    mapping(uint256 => uint256) internal _mintNumbers;

    constructor(address creator, uint16 redemptionRate_, uint16 redemptionMax_) ERC721SingleCreatorExtension(creator) {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId) ||
                ERC165Checker.supportsInterface(creator, LegacyInterfaces.IERC721CreatorCore_v1), 
                "Redeem: Minting reward contract must implement IERC721CreatorCore");
        _redemptionRate = redemptionRate_;
        _redemptionMax = redemptionMax_;
    }     

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(RedeemBase, CreatorExtension, IERC165) returns (bool) {
        return interfaceId == type(IERC721RedeemBase).interfaceId || RedeemBase.supportsInterface(interfaceId) || CreatorExtension.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721RedeemBase-redemptionMax}
     */
    function redemptionMax() external view virtual override returns(uint16) {
        return _redemptionMax;
    }

    /**
     * @dev See {IERC721RedeemBase-redemptionRate}
     */
    function redemptionRate() external view virtual override returns(uint16) {
        return _redemptionRate;
    }

    /**
     * @dev See {IERC721RedeemBase-redemptionRemaining}
     */
    function redemptionRemaining() public view virtual override returns(uint16) {
        return _redemptionMax-_redemptionCount;
    }

    /**
     * @dev See {IERC721RedeemBase-mintNumber}.
     */
    function mintNumber(uint256 tokenId) external view virtual override returns(uint256) {
        return _mintNumbers[tokenId];
    }

    /**
     * @dev See {IERC721RedeemBase-mintedTokens}.
     */
    function mintedTokens() external view override returns(uint256[] memory) {
        return _mintedTokens;
    }

    /**
     * @dev mint token that was redeemed for
     */
    function _mintRedemption(address to) internal virtual returns (uint256) {
        require(_redemptionCount < _redemptionMax, "Redeem: No redemptions remaining");
        _redemptionCount++;
        
        // Mint token
        uint256 tokenId = _mint(to, _redemptionCount);

        _mintedTokens.push(tokenId);
        _mintNumbers[tokenId] = _redemptionCount;
        return tokenId;
    }

    /**
     * @dev override if you want to perform different mint functionality
     */
    function _mint(address to, uint16) internal virtual returns (uint256) {
        return IERC721CreatorCore(_creator).mintExtension(to);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface for admin control
 */
interface IAdminControl is IERC165 {

    event AdminApproved(address indexed account, address indexed sender);
    event AdminRevoked(address indexed account, address indexed sender);

    /**
     * @dev gets address of all admins
     */
    function getAdmins() external view returns (address[] memory);

    /**
     * @dev add an admin.  Can only be called by contract owner.
     */
    function approveAdmin(address admin) external;

    /**
     * @dev remove an admin.  Can only be called by contract owner.
     */
    function revokeAdmin(address admin) external;

    /**
     * @dev checks whether or not given address is an admin
     * Returns True if they are
     */
    function isAdmin(address admin) external view returns (bool);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * @dev Collection Interface
 */
interface ICollectionBase {

    event CollectionActivated(uint256 startTime, uint256 endTime, uint256 presaleInterval, uint256 claimStartTime, uint256 claimEndTime);
    event CollectionDeactivated();

    /**
     * @dev Check if nonce has been used
     */
    function nonceUsed(bytes32 nonce) external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IRedeemBase.sol";

/**
 * @dev Base redemption interface
 */
interface IERC721RedeemBase is IRedeemBase {
    /**
     * @dev Get the max number of redemptions
     */
    function redemptionMax() external view returns(uint16);

    /**
     * @dev Get the redemption rate
     */
    function redemptionRate() external view returns(uint16);

    /**
     * @dev Get number of redemptions left
     */
    function redemptionRemaining() external view returns(uint16);

    /**
     * @dev Get the mint number of a created token id
     */
    function mintNumber(uint256 tokenId) external view returns(uint256);

    /**
     * @dev Get list of all minted tokens
     */
    function mintedTokens() external view returns(uint256[] memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "./IRedeemBase.sol";

struct range{
   uint256 min;
   uint256 max;
}

/**
 * @dev Burn NFT's to receive another lazy minted NFT
 */
abstract contract RedeemBase is AdminControl, IRedeemBase {
     using EnumerableSet for EnumerableSet.UintSet;

     // approved contract tokens
    mapping(address => bool) internal _approvedContracts;

    // approved specific tokens
    mapping(address => EnumerableSet.UintSet) internal _approvedTokens;
    mapping(address => range[]) internal _approvedTokenRange;
     
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(IRedeemBase).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IRedeemBase-updateApprovedContracts}
     */
    function updateApprovedContracts(address[] memory contracts, bool[] memory approved) public virtual override adminRequired {
        require(contracts.length == approved.length, "Redeem: Invalid input parameters");
        for (uint i=0; i < contracts.length; i++) {
            _approvedContracts[contracts[i]] = approved[i];
        }
        emit UpdateApprovedContracts(contracts, approved);
    }
    
    /**
     * @dev See {IRedeemBase-updateApprovedTokens}
     */
    function updateApprovedTokens(address contract_, uint256[] memory tokenIds, bool[] memory approved) public virtual override adminRequired {
        require(tokenIds.length == approved.length, "Redeem: Invalid input parameters");

        for (uint i=0; i < tokenIds.length; i++) {
            if (approved[i] && !_approvedTokens[contract_].contains(tokenIds[i])) {
                _approvedTokens[contract_].add(tokenIds[i]);
            } else if (!approved[i] && _approvedTokens[contract_].contains(tokenIds[i])) {
                _approvedTokens[contract_].remove(tokenIds[i]);
            }
        }
        emit UpdateApprovedTokens(contract_, tokenIds, approved);
    }

    /**
     * @dev See {IRedeemBase-updateApprovedTokenRanges}
     */
    function updateApprovedTokenRanges(address contract_, uint256[] memory minTokenIds, uint256[] memory maxTokenIds) public virtual override adminRequired {
        require(minTokenIds.length == maxTokenIds.length, "Redeem: Invalid input parameters");
        delete _approvedTokenRange[contract_];
        for (uint i=0; i < minTokenIds.length; i++) {
            require(minTokenIds[i] < maxTokenIds[i], "Redeem: min must be less than max");
            _approvedTokenRange[contract_].push(range(minTokenIds[i], maxTokenIds[i]));
        }
        emit UpdateApprovedTokenRanges(contract_, minTokenIds, maxTokenIds);
    }

    /**
     * @dev See {IRedeemBase-redeemable}
     */    
    function redeemable(address contract_, uint256 tokenId) public view virtual override returns(bool) {
         if (_approvedContracts[contract_]) {
             return true;
         }
         if (_approvedTokens[contract_].contains(tokenId)) {
             return true;
         }
         if (_approvedTokenRange[contract_].length > 0) {
             for (uint i=0; i < _approvedTokenRange[contract_].length; i++) {
                 if (_approvedTokenRange[contract_][i].max != 0 && tokenId >= _approvedTokenRange[contract_][i].min && tokenId <= _approvedTokenRange[contract_][i].max) {
                     return true;
                 }
             }
         }
         return false;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ERC721SingleCreatorExtensionBase.sol";

/**
 * @dev Extension that only uses a single creator contract instance
 */
abstract contract ERC721SingleCreatorExtension is ERC721SingleCreatorExtensionBase {

    constructor(address creator) {
        _setCreator(creator);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Core creator interface
 */
interface ICreatorCore is IERC165 {

    event ExtensionRegistered(address indexed extension, address indexed sender);
    event ExtensionUnregistered(address indexed extension, address indexed sender);
    event ExtensionBlacklisted(address indexed extension, address indexed sender);
    event MintPermissionsUpdated(address indexed extension, address indexed permissions, address indexed sender);
    event RoyaltiesUpdated(uint256 indexed tokenId, address payable[] receivers, uint256[] basisPoints);
    event DefaultRoyaltiesUpdated(address payable[] receivers, uint256[] basisPoints);
    event ExtensionRoyaltiesUpdated(address indexed extension, address payable[] receivers, uint256[] basisPoints);
    event ExtensionApproveTransferUpdated(address indexed extension, bool enabled);

    /**
     * @dev gets address of all extensions
     */
    function getExtensions() external view returns (address[] memory);

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * Returns True if removed, False if already removed.
     */
    function unregisterExtension(address extension) external;

    /**
     * @dev blacklist an extension.  Can only be called by contract owner or admin.
     * This function will destroy all ability to reference the metadata of any tokens created
     * by the specified extension. It will also unregister the extension if needed.
     * Returns True if removed, False if already removed.
     */
    function blacklistExtension(address extension) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     */
    function setBaseTokenURIExtension(string calldata uri) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURIExtension(string calldata uri, bool identical) external;

    /**
     * @dev set the common prefix of an extension.  Can only be called by extension.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefixExtension(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token extension.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of a token extension for multiple tokens.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256[] memory tokenId, string[] calldata uri) external;

    /**
     * @dev set the baseTokenURI for tokens with no extension.  Can only be called by owner/admin.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURI(string calldata uri) external;

    /**
     * @dev set the common prefix for tokens with no extension.  Can only be called by owner/admin.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of multiple tokens with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256[] memory tokenIds, string[] calldata uris) external;

    /**
     * @dev set a permissions contract for an extension.  Used to control minting.
     */
    function setMintPermissions(address extension, address permissions) external;

    /**
     * @dev Configure so transfers of tokens created by the caller (must be extension) gets approval
     * from the extension before transferring
     */
    function setApproveTransferExtension(bool enabled) external;

    /**
     * @dev get the extension of a given token
     */
    function tokenExtension(uint256 tokenId) external view returns (address);

    /**
     * @dev Set default royalties
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of a token
     */
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of an extension
     */
    function setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     */
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    
    // Royalty support for various other standards
    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);
    function getFeeBps(uint256 tokenId) external view returns (uint[] memory);
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";

/**
 * @dev Base redemption interface
 */
interface IRedeemBase is IAdminControl {

    event UpdateApprovedContracts(address[] contracts, bool[] approved);
    event UpdateApprovedTokens(address contract_, uint256[] tokenIds, bool[] approved);
    event UpdateApprovedTokenRanges(address contract_, uint256[] minTokenIds, uint256[] maxTokenIds);

    /**
     * @dev Update approved contracts that can be used to redeem. Can only be called by contract owner/admin.
     */
    function updateApprovedContracts(address[] calldata contracts, bool[] calldata approved) external;

    /**
     * @dev Update approved tokens that can be used to redeem. Can only be called by contract owner/admin.
     */
    function updateApprovedTokens(address contract_, uint256[] calldata tokenIds, bool[] calldata approved) external;

    /**
     * @dev Update approved token ranges that can be used to redeem. Can only be called by contract owner/admin.
     * Clears out old ranges
     */
    function updateApprovedTokenRanges(address contract_, uint256[] calldata minTokenIds, uint256[] calldata maxTokenIds) external;

    /**
     * @dev Check if an NFT is redeemable
     */
    function redeemable(address contract_, uint256 tokenId) external view returns(bool);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";

import "./LegacyInterfaces.sol";
import "./SingleCreatorExtensionBase.sol";

/**
 * @dev Extension that only uses a single creator contract instance
 */
abstract contract ERC721SingleCreatorExtensionBase is SingleCreatorExtensionBase {

    function _setCreator(address creator) internal override {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId) ||
                ERC165Checker.supportsInterface(creator, LegacyInterfaces.IERC721CreatorCore_v1), 
                "Creator contract must implement IERC721CreatorCore");
        super._setCreator(creator);
    }
  
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * @dev Extension that only uses a single creator contract instance
 */
abstract contract SingleCreatorExtensionBase {
    address internal _creator;

    /**
     * @dev Override with appropriate interface checks if necessary
     */
    function _setCreator(address creator) internal virtual {
      _creator = creator;
    }

    function creatorContract() public view returns(address) {
        return _creator;
    }
}

// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * Library of legacy interface constants
 */
library LegacyInterfaces {

    // LEGACY ERC721CreatorCore interface
    bytes4 internal constant IERC721CreatorCore_v1 = 0x478c8530;

}