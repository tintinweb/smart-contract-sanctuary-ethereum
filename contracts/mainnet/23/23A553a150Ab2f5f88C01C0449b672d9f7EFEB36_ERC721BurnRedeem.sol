// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";

import "./BurnRedeemCore.sol";
import "./IERC721BurnRedeem.sol";

contract ERC721BurnRedeem is BurnRedeemCore, IERC721BurnRedeem {
    using Strings for uint256;

    // { contractAddress => { tokenId => { redeemIndex } }
    mapping(address => mapping(uint256 => RedeemToken)) internal _redeemTokens;

    // { creatorContractAddress => { index =>  bool } }
    mapping(address => mapping(uint256 => bool)) private _identicalTokenURI;

    function supportsInterface(bytes4 interfaceId) public view virtual override(BurnRedeemCore, IERC165) returns (bool) {
        return interfaceId == type(IERC721BurnRedeem).interfaceId || super.supportsInterface(interfaceId);
    }
    
    /**
     * @dev See {IERC721BurnRedeem-initializeBurnRedeem}.
     */
    function initializeBurnRedeem(
        address creatorContractAddress,
        uint256 index,
        BurnRedeemParameters calldata burnRedeemParameters,
        bool identicalTokenURI
    ) external creatorAdminRequired(creatorContractAddress) {
        _initialize(creatorContractAddress, index, burnRedeemParameters);
        _identicalTokenURI[creatorContractAddress][index] = identicalTokenURI;
    }

    /**
     * @dev See {IERC721BurnRedeem-updateBurnRedeem}.
     */
    function updateBurnRedeem(
        address creatorContractAddress,
        uint256 index,
        BurnRedeemParameters calldata burnRedeemParameters,
        bool identicalTokenURI
    ) external creatorAdminRequired(creatorContractAddress) {
        _update(creatorContractAddress, index, burnRedeemParameters);
        _identicalTokenURI[creatorContractAddress][index] = identicalTokenURI;
    }

    /**
     * See {IERC721BurnRedeem-updateTokenURI}.
     */
    function updateTokenURI(
        address creatorContractAddress,
        uint256 index,
        StorageProtocol storageProtocol,
        string calldata location,
        bool identicalTokenURI
    ) external override creatorAdminRequired(creatorContractAddress) {
        BurnRedeem storage burnRedeemInstance = _getBurnRedeem(creatorContractAddress, index);
        burnRedeemInstance.storageProtocol = storageProtocol;
        burnRedeemInstance.location = location;
        _identicalTokenURI[creatorContractAddress][index] = identicalTokenURI;
    }

    /** 
     * Helper to mint multiple redeem tokens
     */
    function _redeem(address creatorContractAddress, uint256 index, BurnRedeem storage burnRedeemInstance, address to, uint32 count) internal override {
        if (burnRedeemInstance.redeemAmount == 1 && count == 1) {
            ++burnRedeemInstance.redeemedCount;
            uint256 newTokenId = IERC721CreatorCore(creatorContractAddress).mintExtension(to);
            _redeemTokens[creatorContractAddress][newTokenId] = RedeemToken(uint224(index), burnRedeemInstance.redeemedCount);
            emit BurnRedeemMint(creatorContractAddress, index, newTokenId);
        } else {
            uint256 totalCount = burnRedeemInstance.redeemAmount * count;
            require(totalCount <= MAX_UINT_16, "Invalid input");
            uint256 startingCount = burnRedeemInstance.redeemedCount + 1;
            burnRedeemInstance.redeemedCount += uint32(totalCount);
            uint256[] memory newTokenIds = IERC721CreatorCore(creatorContractAddress).mintExtensionBatch(to, uint16(totalCount));
            for (uint256 i; i < totalCount;) {
                _redeemTokens[creatorContractAddress][newTokenIds[i]] = RedeemToken(uint224(index), uint32(startingCount + i));
                emit BurnRedeemMint(creatorContractAddress, index, newTokenIds[i]);
                unchecked { i++; }
            }
        }
    }

    /**
     * See {ICreatorExtensionTokenURI-tokenURI}.
     */
    function tokenURI(address creatorContractAddress, uint256 tokenId) external override view returns(string memory uri) {
        RedeemToken memory token = _redeemTokens[creatorContractAddress][tokenId];
        require(token.burnRedeemIndex > 0, "Token does not exist");
        BurnRedeem memory _burnRedeem = _burnRedeems[creatorContractAddress][token.burnRedeemIndex];

        string memory prefix = "";
        if (_burnRedeem.storageProtocol == StorageProtocol.ARWEAVE) {
            prefix = ARWEAVE_PREFIX;
        } else if (_burnRedeem.storageProtocol == StorageProtocol.IPFS) {
            prefix = IPFS_PREFIX;
        }
        uri = string(abi.encodePacked(prefix, _burnRedeem.location));

        if (!_identicalTokenURI[creatorContractAddress][token.burnRedeemIndex]) {
            uri = string(abi.encodePacked(uri, "/", uint256(token.mintNumber).toString()));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./IBurnRedeemCore.sol";

interface IERC721BurnRedeem is IBurnRedeemCore {
    struct RedeemToken {
        uint224 burnRedeemIndex;
        uint32 mintNumber;
    }

    /**
     * @notice initialize a new burn redeem, emit initialize event, and return the newly created index
     * @param creatorContractAddress    the creator contract the burn will mint redeem tokens for
     * @param index                     the index of the burnRedeem in the mapping of creatorContractAddress' _burnRedeems
     * @param burnRedeemParameters      the parameters which will affect the minting behavior of the burn redeem
     * @param identicalTokenURI         whether or not the tokenURI is identical
     */
    function initializeBurnRedeem(address creatorContractAddress, uint256 index, BurnRedeemParameters calldata burnRedeemParameters, bool identicalTokenURI) external;

    /**
     * @notice update an existing burn redeem at index
     * @param creatorContractAddress    the creator contract corresponding to the burn redeem
     * @param index                     the index of the burn redeem in the list of creatorContractAddress' _burnRedeems
     * @param burnRedeemParameters      the parameters which will affect the minting behavior of the burn redeem
     * @param identicalTokenURI         whether or not the tokenURI is identical
     */
    function updateBurnRedeem(address creatorContractAddress, uint256 index, BurnRedeemParameters calldata burnRedeemParameters, bool identicalTokenURI) external;

    /**
     * @notice update an existing burn redeem at index
     * @param creatorContractAddress    the creator contract corresponding to the burn redeem
     * @param index                     the index of the burn redeem in the list of creatorContractAddress' _burnRedeems
     * @param storageProtocol           the storage protocol for the metadata
     * @param location                  the location of the metadata
     * @param identicalTokenURI         whether or not the URI's are supposed to be identical
     */
    function updateTokenURI(address creatorContractAddress, uint256 index, StorageProtocol storageProtocol, string calldata location, bool identicalTokenURI) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/////////////////////////////////////////////////////////////////////////////////////
//                                                                                 //
//                                                                                 //
//                                     .%(#.                                       //
//                                      #(((#%,                                    //
//                                      (#(((((#%*                                 //
//                                      /#((((((((##*                              //
//                                      (#((((((((((##%.                           //
//                                     ,##(/*/(////((((#%*                         //
//                                   .###(//****/////(((##%,                       //
//                  (,          ,%#((((((///******/////((##%(                      //
//                *((,         ,##(///////*********////((###%*                     //
//              /((((         ,##(//////************/(((((###%                     //
//             /((((         ,##((////***************/((((###%                     //
//             (((          .###((///*****************((((####                     //
//             .            (##((//*******************((((##%*                     //
//               (#.       .###((/********************((((##%.      %.             //
//             ,%(#.       .###(/********,,,,,,,*****/(((###%#     ((%,            //
//            /%#/(/       /###(//****,,,,,,,,,,,****/((((((##%%%%#((#%.           //
//           /##(//(#.    ,###((/****,,,,,,,,,,,,,***/((/(((((((((#####%           //
//          *%##(/////((###((((/***,,,,,,,,,,,,,,,***//((((((((((####%%%/          //
//          ####(((//////(//////**,,,,,,.....,,,,,,****/(((((//((####%%%%          //
//         .####(((/((((((/////**,,,,,.......,,,,,,,,*****/////(#####%%%%          //
//         .#%###((////(((//***,,,,,,..........,,,,,,,,*****//((#####%%%%          //
//          /%%%###/////*****,,,,,,,..............,,,,,,,****/(((####%%%%          //
//           /%%###(////****,,,,,,.....        ......,,,,,,**(((####%%%%           //
//            ,#%###(///****,,,,,....            .....,,,,,***/(/(##%%(            //
//              (####(//****,,....                 ....,,,,,***/(####              //
//                (###(/***,,,...                    ...,,,,***(##/                //
//             #.   (#((/**,,,,..                    ...,,,,*((#,                  //
//               ,#(##(((//,,,,..                   ...,,,*/(((#((/                //
//                  *#(((///*,,....                ....,*//((((                    //
//                      *(///***,....            ...,***//,                        //
//                           ,//***,...       ..,,*,                               //
//                                                                                 //
//                                                                                 //
/////////////////////////////////////////////////////////////////////////////////////

import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/IAdminControl.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "../../libraries/manifold-membership/IManifoldMembership.sol";
import "./IBurnRedeemCore.sol";
import "./Interfaces.sol";

/**
 * @title Burn Redeem Core
 * @author manifold.xyz
 * @notice Core logic for Burn Redeem shared extensions.
 */
abstract contract BurnRedeemCore is ERC165, AdminControl, ReentrancyGuard, IBurnRedeemCore, ICreatorExtensionTokenURI {
    using Strings for uint256;

    uint256 public constant BURN_FEE = 690000000000000;
    uint256 public constant MULTI_BURN_FEE = 990000000000000;

    string internal constant ARWEAVE_PREFIX = "https://arweave.net/";
    string internal constant IPFS_PREFIX = "ipfs://";

    uint256 internal constant MAX_UINT_16 = 0xffff;
    uint256 internal constant MAX_UINT_32 = 0xffffffff;
    uint256 internal constant MAX_UINT_256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // { creatorContractAddress => { index => BurnRedeem } }
    mapping(address => mapping(uint256 => BurnRedeem)) internal _burnRedeems;

    address public manifoldMembershipContract;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165, AdminControl) returns (bool) {
        return interfaceId == type(IBurnRedeemCore).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice This extension is shared, not single-creator. So we must ensure
     * that a burn redeems's initializer is an admin on the creator contract
     * @param creatorContractAddress    the address of the creator contract to check the admin against
     */
    modifier creatorAdminRequired(address creatorContractAddress) {
        require(IAdminControl(creatorContractAddress).isAdmin(msg.sender), "Wallet is not an admin");
        _;
    }

    /**
     * Initialiazes a burn redeem with base parameters
     */
    function _initialize(
        address creatorContractAddress,
        uint256 index,
        BurnRedeemParameters calldata burnRedeemParameters
    ) internal {
        BurnRedeem storage burnRedeemInstance = _burnRedeems[creatorContractAddress][index];

        // Sanity checks
        require(burnRedeemInstance.storageProtocol == StorageProtocol.INVALID, "Burn redeem already initialized");
        _validateParameters(burnRedeemParameters);

        // Create the burn redeem
        _setParameters(burnRedeemInstance, burnRedeemParameters);
        _setBurnGroups(burnRedeemInstance, burnRedeemParameters.burnSet);

        emit BurnRedeemInitialized(creatorContractAddress, index, msg.sender);
    }

    /**
     * Updates a burn redeem with base parameters
     */
    function _update(
        address creatorContractAddress,
        uint256 index,
        BurnRedeemParameters calldata burnRedeemParameters
    ) internal {
        BurnRedeem storage burnRedeemInstance = _getBurnRedeem(creatorContractAddress, index);

        // Sanity checks
        require(burnRedeemInstance.storageProtocol != StorageProtocol.INVALID, "Burn redeem not initialized");
        _validateParameters(burnRedeemParameters);
        // The current redeemedCount must be divisible by redeemAmount
        require(burnRedeemInstance.redeemedCount % burnRedeemParameters.redeemAmount == 0, "Invalid amount");

        // Overwrite the existing burnRedeem
        _setParameters(burnRedeemInstance, burnRedeemParameters);
        _setBurnGroups(burnRedeemInstance, burnRedeemParameters.burnSet);
        _maybeUpdateTotalSupply(burnRedeemInstance);
    }

    /**
     * See {IBurnRedeemCore-getBurnRedeem}.
     */
    function getBurnRedeem(address creatorContractAddress, uint256 index) external override view returns(BurnRedeem memory) {
        return _getBurnRedeem(creatorContractAddress, index);
    }

    /**
     * Helper to get burn redeem instance
     */
    function _getBurnRedeem(address creatorContractAddress, uint256 index) internal view returns(BurnRedeem storage burnRedeemInstance) {
        burnRedeemInstance = _burnRedeems[creatorContractAddress][index];
        require(burnRedeemInstance.storageProtocol != StorageProtocol.INVALID, "Burn redeem not initialized");
    }

    /**
     * Helper to get active burn redeem instance
     */
    function _getActiveBurnRedeem(address creatorContractAddress, uint256 index) private view returns(BurnRedeem storage burnRedeemInstance) {
        burnRedeemInstance = _burnRedeems[creatorContractAddress][index];
        require(burnRedeemInstance.storageProtocol != StorageProtocol.INVALID, "Burn redeem not initialized");
        require(
            burnRedeemInstance.startDate <= block.timestamp && 
            (block.timestamp < burnRedeemInstance.endDate || burnRedeemInstance.endDate == 0),
            "Burn redeem not active"
        );
    }

    /**
     * Helper to update total supply if redeemedCount exceeds totalSupply after airdrop or instance update.
     */
    function _maybeUpdateTotalSupply(BurnRedeem storage burnRedeemInstance) private {
        if (
            burnRedeemInstance.totalSupply != 0 &&
            burnRedeemInstance.redeemedCount > burnRedeemInstance.totalSupply
        ) {
            burnRedeemInstance.totalSupply = burnRedeemInstance.redeemedCount;
        }
    }

    /**
     * See {IBurnRedeemCore-burnRedeem}.
     */
    function burnRedeem(address creatorContractAddress, uint256 index, uint32 burnRedeemCount, BurnToken[] calldata burnTokens) external payable override nonReentrant {
        uint256 payableCost = _burnRedeem(msg.value, creatorContractAddress, index, burnRedeemCount, burnTokens, _isActiveMember(msg.sender), true);
        if (msg.value > payableCost) {
            _forwardValue(payable(msg.sender), msg.value - payableCost);
        }
    }

    /**
     * (Batch overload) see {IBurnRedeemCore-burnRedeem}.
     */
    function burnRedeem(address[] calldata creatorContractAddresses, uint256[] calldata indexes, uint32[] calldata burnRedeemCounts, BurnToken[][] calldata burnTokens) external payable override nonReentrant {
        require(
            creatorContractAddresses.length == indexes.length &&
            creatorContractAddresses.length == burnRedeemCounts.length &&
            creatorContractAddresses.length == burnTokens.length,
            "Invalid calldata"
        );

        bool isActiveMember = _isActiveMember(msg.sender);
        uint256 msgValueRemaining = msg.value;
        for (uint256 i; i < creatorContractAddresses.length;) {
            msgValueRemaining -= _burnRedeem(msgValueRemaining, creatorContractAddresses[i], indexes[i], burnRedeemCounts[i], burnTokens[i], isActiveMember, false);
            unchecked { ++i; }
        }

        if (msgValueRemaining != 0) {
            _forwardValue(payable(msg.sender), msgValueRemaining);
        }
    }

    /**
     * See {IBurnRedeemCore-airdrop}.
     */
    function airdrop(address creatorContractAddress, uint256 index, address[] calldata recipients, uint32[] calldata amounts) external override creatorAdminRequired(creatorContractAddress) {
        require(recipients.length == amounts.length, "Invalid calldata");
        BurnRedeem storage burnRedeemInstance = _getBurnRedeem(creatorContractAddress, index);

        uint256 totalAmount;
        for (uint256 i; i < amounts.length;) {
            totalAmount += amounts[i] * burnRedeemInstance.redeemAmount;
            unchecked{ ++i; }
        }
        require(
            totalAmount + burnRedeemInstance.redeemedCount <= MAX_UINT_32,
            "Invalid amount"
        );

        // Airdrop the tokens
        for (uint256 i; i < recipients.length;) {
            _redeem(creatorContractAddress, index, burnRedeemInstance, recipients[i], amounts[i]);
            unchecked{ ++i; }
        }

        _maybeUpdateTotalSupply(burnRedeemInstance);
    }

    function _burnRedeem(uint256 msgValue, address creatorContractAddress, uint256 index, uint32 burnRedeemCount, BurnToken[] calldata burnTokens, bool isActiveMember, bool revertNoneRemaining) private returns (uint256) {
        BurnRedeem storage burnRedeemInstance = _getActiveBurnRedeem(creatorContractAddress, index);

        // Get the amount that can be burned
        burnRedeemCount = _getAvailableBurnRedeemCount(burnRedeemInstance.totalSupply, burnRedeemInstance.redeemedCount, burnRedeemInstance.redeemAmount, burnRedeemCount);
        if (burnRedeemCount == 0) {
            if (revertNoneRemaining) revert("No tokens available");
            return 0;
        }

        uint256 payableCost = burnRedeemInstance.cost;
        uint256 cost = burnRedeemInstance.cost;
        if (!isActiveMember) {
            payableCost += _getManifoldFee(burnTokens.length);
        }
        if (burnRedeemCount > 1) {
            payableCost *= burnRedeemCount;
            cost *= burnRedeemCount;
        }
        require(msgValue >= payableCost, "Invalid amount");
        if (cost > 0) {
            _forwardValue(burnRedeemInstance.paymentReceiver, cost);
        }

        // Do burn redeem
        _burnTokens(burnRedeemInstance, burnTokens, burnRedeemCount, msg.sender);
        _redeem(creatorContractAddress, index, burnRedeemInstance, msg.sender, burnRedeemCount);

        return payableCost;
    }

    /**
     * @dev See {IBurnRedeemCore-recoverERC721}.
     */
    function recoverERC721(address tokenAddress, uint256 tokenId, address destination) external override adminRequired {
        IERC721(tokenAddress).transferFrom(address(this), destination, tokenId);
    }

    /**
     * @dev See {IBurnRedeemCore-withdraw}.
     */
    function withdraw(address payable recipient, uint256 amount) external override adminRequired {
        (bool sent, ) = recipient.call{value: amount}("");
        require(sent, "Failed to transfer to recipient");
    }

    /**
     * @dev See {IBurnRedeemCore-setManifoldMembership}.
     */
    function setMembershipAddress(address addr) external override adminRequired {
        manifoldMembershipContract = addr;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address from,
        uint256 id,
        bytes calldata data
    ) external override nonReentrant returns(bytes4) {
        _onERC721Received(from, id, data);
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
        // Check calldata is valid
        require(data.length % 32 == 0, "Invalid data");

        address creatorContractAddress;
        uint256 burnRedeemIndex;
        uint32 burnRedeemCount;
        uint256 burnItemIndex;
        bytes32[] memory merkleProof;
        (creatorContractAddress, burnRedeemIndex, burnRedeemCount, burnItemIndex, merkleProof) = abi.decode(data, (address, uint256, uint32, uint256, bytes32[]));

        // Do burn redeem
        _onERC1155Received(from, id, value, creatorContractAddress, burnRedeemIndex, burnRedeemCount, burnItemIndex, merkleProof);

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
        // Check calldata is valid
        require(data.length % 32 == 0, "Invalid data");

        address creatorContractAddress;
        uint256 burnRedeemIndex;
        uint32 burnRedeemCount;
        BurnToken[] memory burnTokens;
        (creatorContractAddress, burnRedeemIndex, burnRedeemCount, burnTokens) = abi.decode(data, (address, uint256, uint32, BurnToken[]));

        // Do burn redeem
        _onERC1155BatchReceived(from, ids, values, creatorContractAddress, burnRedeemIndex, burnRedeemCount, burnTokens);

        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @notice ERC721 token transfer callback
     * @param from      the person sending the tokens
     * @param id        the token id of the burn token
     * @param data      bytes indicating the target burnRedeem and, optionally, a merkle proof that the token is valid
     */
    function _onERC721Received(
        address from,
        uint256 id,
        bytes calldata data
    ) private {
        // Check calldata is valid
        require(data.length % 32 == 0, "Invalid data");

        address creatorContractAddress;
        uint256 burnRedeemIndex;
        uint256 burnItemIndex;
        bytes32[] memory merkleProof;
        (creatorContractAddress, burnRedeemIndex, burnItemIndex, merkleProof) = abi.decode(data, (address, uint256, uint256, bytes32[]));

        BurnRedeem storage burnRedeemInstance = _getActiveBurnRedeem(creatorContractAddress, burnRedeemIndex);

        // A single ERC721 can only be sent in directly for a burn if:
        // 1. There is no cost to the burn (because no payment can be sent with a transfer)
        // 2. The burn only requires one NFT (one burnSet element and one count)
        // 3. They are an active member (because no fee payment can be sent with a transfer)
        require(
            burnRedeemInstance.cost == 0 &&
            burnRedeemInstance.burnSet.length == 1 &&
            burnRedeemInstance.burnSet[0].requiredCount == 1 &&
            _isActiveMember(from),
            "Invalid input"
        );

        uint256 burnRedeemCount = _getAvailableBurnRedeemCount(burnRedeemInstance.totalSupply, burnRedeemInstance.redeemedCount, burnRedeemInstance.redeemAmount, 1);
        require(burnRedeemCount != 0, "No tokens available");

        // Check that the burn token is valid
        BurnItem memory burnItem = burnRedeemInstance.burnSet[0].items[burnItemIndex];

        // Can only take in one burn item
        require(burnItem.tokenSpec == TokenSpec.ERC721, "Invalid input");
        _validateBurnItem(burnItem, msg.sender, id, merkleProof);

        // Do burn and redeem
        _burn(burnItem, address(this), msg.sender, id, 1);
        _redeem(creatorContractAddress, burnRedeemIndex, burnRedeemInstance, from, 1);
    }

    /**
     * Execute onERC1155Received burn/redeem
     */
    function _onERC1155Received(address from, uint256 tokenId, uint256 value, address creatorContractAddress, uint256 burnRedeemIndex, uint32 burnRedeemCount, uint256 burnItemIndex, bytes32[] memory merkleProof) private {
        BurnRedeem storage burnRedeemInstance = _getActiveBurnRedeem(creatorContractAddress, burnRedeemIndex);

        // A single 1155 can only be sent in directly for a burn if:
        // 1. There is no cost to the burn (because no payment can be sent with a transfer)
        // 2. The burn only requires one NFT (one burn set element and one required count in the set)
        // 3. They are an active member (because no fee payment can be sent with a transfer)
        require(
            burnRedeemInstance.cost == 0 &&
            burnRedeemInstance.burnSet.length == 1 &&
            burnRedeemInstance.burnSet[0].requiredCount == 1 &&
            _isActiveMember(from),
            "Invalid input"
        );

        uint32 availableBurnRedeemCount = _getAvailableBurnRedeemCount(burnRedeemInstance.totalSupply, burnRedeemInstance.redeemedCount, burnRedeemInstance.redeemAmount, burnRedeemCount);
        require(availableBurnRedeemCount != 0, "No tokens available");

        // Check that the burn token is valid
        BurnItem memory burnItem = burnRedeemInstance.burnSet[0].items[burnItemIndex];
        require(value == burnItem.amount * burnRedeemCount, "Invalid input");
        _validateBurnItem(burnItem, msg.sender, tokenId, merkleProof);

        _burn(burnItem, address(this), msg.sender, tokenId, availableBurnRedeemCount);
        _redeem(creatorContractAddress, burnRedeemIndex, burnRedeemInstance, from, availableBurnRedeemCount);

        // Return excess amount
        if (availableBurnRedeemCount != burnRedeemCount) {
            IERC1155(msg.sender).safeTransferFrom(address(this), from, tokenId, (burnRedeemCount - availableBurnRedeemCount) * burnItem.amount, "");
        }
    }

    /**
     * Execute onERC1155BatchReceived burn/redeem
     */
    function _onERC1155BatchReceived(address from, uint256[] memory tokenIds, uint256[] memory values, address creatorContractAddress, uint256 burnRedeemIndex, uint32 burnRedeemCount, BurnToken[] memory burnTokens) private {
        BurnRedeem storage burnRedeemInstance = _getActiveBurnRedeem(creatorContractAddress, burnRedeemIndex);

        // A single 1155 can only be sent in directly for a burn if:
        // 1. There is no cost to the burn (because no payment can be sent with a transfer)
        // 2. We have the right data length
        // 3. They are an active member (because no fee payment can be sent with a transfer)
        require(
            burnRedeemInstance.cost == 0 &&
            burnTokens.length == tokenIds.length &&
            _isActiveMember(from),
            "Invalid input"
        );
        uint32 availableBurnRedeemCount = _getAvailableBurnRedeemCount(burnRedeemInstance.totalSupply, burnRedeemInstance.redeemedCount, burnRedeemInstance.redeemAmount, burnRedeemCount);
        require(availableBurnRedeemCount != 0, "No tokens available");

        // Verify the values match what is needed
        uint256[] memory returnValues = new uint256[](tokenIds.length);
        for (uint256 i; i < burnTokens.length;) {
            BurnToken memory burnToken = burnTokens[i];
            BurnItem memory burnItem = burnRedeemInstance.burnSet[burnToken.groupIndex].items[burnToken.itemIndex];
            require(burnToken.id == tokenIds[i], "Invalid token");
            require(burnItem.amount * burnRedeemCount == values[i], "Invalid amount");
            if (availableBurnRedeemCount != burnRedeemCount) {
                returnValues[i] = values[i] - burnItem.amount * availableBurnRedeemCount;
            }
            unchecked { ++i; }
        }

        // Do burn redeem
        _burnTokens(burnRedeemInstance, burnTokens, availableBurnRedeemCount, address(this));
        _redeem(creatorContractAddress, burnRedeemIndex, burnRedeemInstance, from, availableBurnRedeemCount);

        // Return excess amount
        if (availableBurnRedeemCount != burnRedeemCount) {
            IERC1155(msg.sender).safeBatchTransferFrom(address(this), from, tokenIds, returnValues, "");
        }
    }

    /**
     * Send funds to receiver
     */
    function _forwardValue(address payable receiver, uint256 amount) private {
        (bool sent, ) = receiver.call{value: amount}("");
        require(sent, "Failed to transfer to recipient");
    }

    /**
     * Burn all listed tokens and check that the burn set is satisfied
     */
    function _burnTokens(BurnRedeem storage burnRedeemInstance, BurnToken[] memory burnTokens, uint256 burnRedeemCount, address owner) private {
        // Check that each group in the burn set is satisfied
        uint256[] memory groupCounts = new uint256[](burnRedeemInstance.burnSet.length);

        for (uint256 i; i < burnTokens.length;) {
            BurnToken memory burnToken = burnTokens[i];
            BurnItem memory burnItem = burnRedeemInstance.burnSet[burnToken.groupIndex].items[burnToken.itemIndex];

            _validateBurnItem(burnItem, burnToken.contractAddress, burnToken.id, burnToken.merkleProof);

            _burn(burnItem, owner, burnToken.contractAddress, burnToken.id, burnRedeemCount);
            groupCounts[burnToken.groupIndex] += burnRedeemCount;

            unchecked { ++i; }
        }

        for (uint256 i; i < groupCounts.length;) {
            require(groupCounts[i] == burnRedeemInstance.burnSet[i].requiredCount * burnRedeemCount, "Invalid number of tokens");
            unchecked { ++i; }
        }
    }

    /**
     * Helper to validate the parameters for a burn redeem
     */
    function _validateParameters(BurnRedeemParameters calldata burnRedeemParameters) internal pure {
        require(burnRedeemParameters.storageProtocol != StorageProtocol.INVALID, "Storage protocol invalid");
        require(burnRedeemParameters.paymentReceiver != address(0), "Payment receiver required");
        require(burnRedeemParameters.endDate == 0 || burnRedeemParameters.startDate < burnRedeemParameters.endDate, "startDate after endDate");
        require(burnRedeemParameters.totalSupply % burnRedeemParameters.redeemAmount == 0, "Remainder left from totalSupply");
    }

    /**
     * Helper to set top level properties for a burn redeem
     */
    function _setParameters(BurnRedeem storage burnRedeemInstance, BurnRedeemParameters calldata burnRedeemParameters) private {
        burnRedeemInstance.startDate = burnRedeemParameters.startDate;
        burnRedeemInstance.endDate = burnRedeemParameters.endDate;
        burnRedeemInstance.redeemAmount = burnRedeemParameters.redeemAmount;
        burnRedeemInstance.totalSupply = burnRedeemParameters.totalSupply;
        burnRedeemInstance.storageProtocol = burnRedeemParameters.storageProtocol;
        burnRedeemInstance.location = burnRedeemParameters.location;
        burnRedeemInstance.cost = burnRedeemParameters.cost;
        burnRedeemInstance.paymentReceiver = burnRedeemParameters.paymentReceiver;
    }

    /**
     * Helper to set the burn groups for a burn redeem
     */
    function _setBurnGroups(BurnRedeem storage burnRedeemInstance, BurnGroup[] calldata burnGroups) private {
        delete burnRedeemInstance.burnSet;
        for (uint256 i; i < burnGroups.length;) {
            burnRedeemInstance.burnSet.push();
            BurnGroup storage burnGroup = burnRedeemInstance.burnSet[i];
            require(
                burnGroups[i].requiredCount > 0 &&
                burnGroups[i].requiredCount <= burnGroups[i].items.length,
                "Invalid input"
            );
            burnGroup.requiredCount = burnGroups[i].requiredCount;
            for (uint256 j; j < burnGroups[i].items.length;) {
                BurnItem memory burnItem = burnGroups[i].items[j];
                require(
                    (
                        (burnItem.tokenSpec == TokenSpec.ERC1155 && burnItem.amount > 0) ||
                        (burnItem.tokenSpec == TokenSpec.ERC721 && burnItem.amount == 0)
                    ) &&
                    burnItem.validationType != ValidationType.INVALID,
                    "Invalid input");
                burnGroup.items.push(burnGroups[i].items[j]);
                unchecked { ++j; }
            }
            unchecked { ++i; }
        }
    }

    /**
     * Helper to get the Manifold fee for the sender
     */
    function _getManifoldFee(uint256 burnTokenCount) private pure returns(uint256 fee) {
        fee = burnTokenCount <= 1 ? BURN_FEE : MULTI_BURN_FEE;
    }

    /**
     * Helper to check if the sender holds an active Manifold membership
     */
    function _isActiveMember(address sender) private view returns(bool) {
        return manifoldMembershipContract != address(0) &&
            IManifoldMembership(manifoldMembershipContract).isActiveMember(sender);
    }

    /*
     * Helper to validate burn item
     */
    function _validateBurnItem(BurnItem memory burnItem, address contractAddress, uint256 tokenId, bytes32[] memory merkleProof) private pure {
        require(contractAddress == burnItem.contractAddress, "Invalid burn token");
        if (burnItem.validationType == ValidationType.CONTRACT) {
            return;
        } else if (burnItem.validationType == ValidationType.RANGE) {
            require(tokenId >= burnItem.minTokenId && tokenId <= burnItem.maxTokenId, "Invalid token ID");
            return;
        } else if (burnItem.validationType == ValidationType.MERKLE_TREE) {
            bytes32 leaf = keccak256(abi.encodePacked(tokenId));
            require(MerkleProof.verify(merkleProof, burnItem.merkleRoot, leaf), "Invalid merkle proof");
            return;
        }
        revert("Invalid burn item");
    }

    /**
     * Helper to get the number of burn redeems the person can accomplish
     */
    function _getAvailableBurnRedeemCount(uint32 totalSupply, uint32 redeemedCount, uint32 redeemAmount, uint32 desiredCount) internal pure returns(uint32 burnRedeemCount) {
        if (totalSupply == 0) {
            burnRedeemCount = desiredCount;
        } else {
            uint32 remainingCount = (totalSupply - redeemedCount) / redeemAmount;
            if (remainingCount > desiredCount) {
                burnRedeemCount = desiredCount;
            } else {
                burnRedeemCount = remainingCount;
            }
        }
    }

    /** 
     * Abstract helper to mint multiple redeem tokens. To be implemented by inheriting contracts.
     */
    function _redeem(address creatorContractAddress, uint256 index, BurnRedeem storage burnRedeemInstance, address to, uint32 count) internal virtual;

    /**
     * Helper to burn token
     */
    function _burn(BurnItem memory burnItem, address from, address contractAddress, uint256 tokenId, uint256 burnRedeemCount) private {
        if (burnItem.tokenSpec == TokenSpec.ERC1155) {
            uint256 amount = burnItem.amount * burnRedeemCount;

            if (burnItem.burnSpec == BurnSpec.NONE) {
                // Send to 0xdEaD to burn if contract doesn't have burn function
                IERC1155(contractAddress).safeTransferFrom(from, address(0xdEaD), tokenId, amount, "");

            } else if (burnItem.burnSpec == BurnSpec.MANIFOLD) {
                // Burn using the creator core's burn function
                uint256[] memory tokenIds = new uint256[](1);
                tokenIds[0] = tokenId;
                uint256[] memory amounts = new uint256[](1);
                amounts[0] = amount;
                Manifold1155(contractAddress).burn(from, tokenIds, amounts);

            } else if (burnItem.burnSpec == BurnSpec.OPENZEPPELIN) {
                // Burn using OpenZeppelin's burn function
                OZBurnable1155(contractAddress).burn(from, tokenId, amount);

            } else {
                revert("Invalid burn spec");
            }
        } else if (burnItem.tokenSpec == TokenSpec.ERC721) {
            require(burnRedeemCount == 1, "Invalid burn count");
            if (burnItem.burnSpec == BurnSpec.NONE) {
                // Send to 0xdEaD to burn if contract doesn't have burn function
                IERC721(contractAddress).safeTransferFrom(from, address(0xdEaD), tokenId, "");

            } else if (burnItem.burnSpec == BurnSpec.MANIFOLD || burnItem.burnSpec == BurnSpec.OPENZEPPELIN) {
                if (from != address(this)) {
                    // 721 `burn` functions do not have a `from` parameter, so we must verify the owner
                    require(IERC721(contractAddress).ownerOf(tokenId) == from, "Sender is not owner");
                }
                // Burn using the contract's burn function
                Burnable721(contractAddress).burn(tokenId);

            } else {
                revert("Invalid burn spec");
            }
        } else {
            revert("Invalid token spec");
        }
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

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * Burn Redeem Core interface
 */
interface IBurnRedeemCore is IERC165, IERC721Receiver, IERC1155Receiver  {
    enum StorageProtocol { INVALID, NONE, ARWEAVE, IPFS }

    /**
     * @notice the validation type used for a `BurnItem`
     * CONTRACT                 any token from a specific contract is valid
     * RANGE                    token IDs within a range (inclusive) are valid
     * MERKLE_TREE              various individual token IDs included in a merkle tree are valid
     */
    enum ValidationType { INVALID, CONTRACT, RANGE, MERKLE_TREE }

    enum TokenSpec { INVALID, ERC721, ERC1155 }
    enum BurnSpec { NONE, MANIFOLD, OPENZEPPELIN }

    /**
     * @notice a `BurnItem` indicates which tokens are eligible to be burned
     * @param validationType    which type of validation used to check that the burn item is 
     *                          satisfied
     * @param tokenSpec         whether the token is an ERC721 or ERC1155
     * @param burnSpec          whether the contract for a token has a `burn` function and, if so,
     *                          what interface
     * @param amount            (only for ERC1155 tokens) the amount (value) required to burn
     * @param minTokenId        (only for RANGE validation) the minimum valid token ID
     * @param maxTokenId        (only for RANGE validation) the maximum valid token ID
     * @param merkleRoot        (only for MERKLE_TREE validation) the root of the merkle tree of
     *                          valid token IDs
     */
    struct BurnItem {
        ValidationType validationType;
        address contractAddress;
        TokenSpec tokenSpec;
        BurnSpec burnSpec;
        uint72 amount;
        uint256 minTokenId;
        uint256 maxTokenId;
        bytes32 merkleRoot;
    }

    /**
     * @notice a `BurnGroup` is a group of valid `BurnItem`s
     * @param requiredCount     the number of `BurnItem`s (0 < requiredCount <= items.length) that 
     *                          need to be included in a burn
     * @param items             the list of `BurnItem`s
     */
    struct BurnGroup {
        uint256 requiredCount;
        BurnItem[] items;
    }

    /**
     * @notice parameters for burn redeem intialization/updates
     * @param paymentReceiver   the address to forward proceeds from paid burn redeems
     * @param storageProtocol   the type of storage used for the redeem token URIs
     * @param redeemAmount      the number of redeem tokens to mint for each burn redeem
     * @param totalSupply       the maximum number of redeem tokens to mint (0 for unlimited)
     * @param startDate         the starting time for the burn redeem (0 for immediately)
     * @param endDate           the end time for the burn redeem (0 for never)
     * @param cost              the cost for each burn redeem
     * @param location          used to construct the token URI (Arweave hash, full URI, etc.)
     * @param burnSet           a list of `BurnGroup`s that must each be satisfied for a burn redeem
     */
    struct BurnRedeemParameters {
        address payable paymentReceiver;
        StorageProtocol storageProtocol;
        uint16 redeemAmount;
        uint32 totalSupply;
        uint48 startDate;
        uint48 endDate;
        uint160 cost;
        string location;
        BurnGroup[] burnSet;
    }

    struct BurnRedeem {
        address payable paymentReceiver;
        StorageProtocol storageProtocol;
        uint32 redeemedCount;
        uint16 redeemAmount;
        uint32 totalSupply;
        uint48 startDate;
        uint48 endDate;
        uint160 cost;
        string location;
        BurnGroup[] burnSet;
    }

    /**
     * @notice a pointer to a `BurnItem` in a `BurnGroup` used in calls to `burnRedeem`
     * @param groupIndex        the index of the `BurnGroup` in `BurnRedeem.burnSet`
     * @param itemIndex         the index of the `BurnItem` in `BurnGroup.items`
     * @param contractAddress   the address of the contract for the token
     * @param id                the token ID
     * @param merkleProof       the merkle proof for the token ID (only for MERKLE_TREE validation)
     */
    struct BurnToken {
        uint48 groupIndex;
        uint48 itemIndex;
        address contractAddress;
        uint256 id;
        bytes32[] merkleProof;
    }

    event BurnRedeemInitialized(address indexed creatorContract, uint256 indexed index, address initializer);
    event BurnRedeemMint(address indexed creatorContract, uint256 indexed index, uint256 indexed tokenId);

    /**
     * @notice get a burn redeem corresponding to a creator contract and index
     * @param creatorContractAddress    the address of the creator contract
     * @param index                     the index of the burn redeem
     * @return BurnRedeem               the burn redeem object
     */
    function getBurnRedeem(address creatorContractAddress, uint256 index) external view returns(BurnRedeem memory);
    
    /**
     * @notice burn tokens and mint a redeem token
     * @param creatorContractAddress    the address of the creator contract
     * @param index                     the index of the burn redeem
     * @param burnRedeemCount           the number of burn redeems we want to do
     * @param burnTokens                the tokens to burn with pointers to the corresponding BurnItem requirement
     */
    function burnRedeem(address creatorContractAddress, uint256 index, uint32 burnRedeemCount, BurnToken[] calldata burnTokens) external payable;

    /**
     * @notice burn tokens and mint redeem tokens multiple times in a single transaction
     * @param creatorContractAddresses  the addresses of the creator contracts
     * @param indexes                   the indexes of the burn redeems
     * @param burnRedeemCounts          the burn redeem counts for each burn
     * @param burnTokens                the tokens to burn for each burn redeem with pointers to the corresponding BurnItem requirement
     */
    function burnRedeem(address[] calldata creatorContractAddresses, uint256[] calldata indexes, uint32[] calldata burnRedeemCounts, BurnToken[][] calldata burnTokens) external payable;

    /**
     * @notice allow admin to airdrop arbitrary tokens 
     * @param creatorContractAddress    the creator contract to mint tokens for
     * @param index                     the index of the burn redeem in the list of creatorContractAddress' _burnRedeems
     * @param recipients                addresses to airdrop to
     * @param amounts                   number of redeems to perform for each address in recipients
     */
    function airdrop(address creatorContractAddress, uint256 index, address[] calldata recipients, uint32[] calldata amounts) external;

    /**
     * @notice recover a token that was sent to the contract without safeTransferFrom
     * @param tokenAddress              the address of the token contract
     * @param tokenId                   the id of the token
     * @param destination               the address to send the token to
     */
    function recoverERC721(address tokenAddress, uint256 tokenId, address destination) external;

    /**
     * @notice withdraw Manifold fee proceeds from the contract
     * @param recipient                 recepient of the funds
     * @param amount                    amount to withdraw in Wei
     */
    function withdraw(address payable recipient, uint256 amount) external;

    /**
     * @notice set the Manifold Membership contract address
     * @param addr                      the address of the Manifold Membership contract 
     */
    function setMembershipAddress(address addr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Burnable721 {
    function burn(uint256 tokenId) external;
}

interface OZBurnable1155 {
    function burn(address account, uint256 id, uint256 value) external;
}

interface Manifold1155 {
    function burn(address account, uint256[] memory tokenIds, uint256[] memory amounts) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * Manifold Membership interface
 */
interface IManifoldMembership {
   function isActiveMember(address sender) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Implement this if you want your extension to have overloadable URI's
 */
interface ICreatorExtensionTokenURI is IERC165 {

    /**
     * Get the uri for a given creator/tokenId
     */
    function tokenURI(address creator, uint256 tokenId) external view returns (string memory);
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
    event ApproveTransferUpdated(address extension);
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

    /**
     * @dev Set the default approve transfer contract location.
     */
    function setApproveTransfer(address extension) external; 

    /**
     * @dev Get the default approve transfer contract location.
     */
    function getApproveTransfer() external view returns (address);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}