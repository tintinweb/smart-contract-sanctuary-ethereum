// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. WhitList Storage
pragma solidity 0.8.16;

import "Ownable.sol";
import "IAdvancedWhiteList.sol";
import "LibEnvelopTypes.sol";
//import "IERC721Mintable.sol";

contract AdvancedWhiteList is Ownable, IAdvancedWhiteList {

    
    mapping(address => ETypes.WhiteListItem) internal whiteList;
    mapping(address => bool) internal blackList;
    mapping(address => ETypes.Rules) internal rulesChecker;
    ETypes.Asset[] public whiteListedArray;
    ETypes.Asset[] public blackListedArray;

    /////////////////////////////////////////////////////////////////////
    //                    Admin functions                              //
    /////////////////////////////////////////////////////////////////////
    function setWLItem(ETypes.Asset calldata _asset, ETypes.WhiteListItem calldata _assetItem) 
        external onlyOwner 
    {
        require(_assetItem.transferFeeModel != address(0), 'Cant be zero, use default instead');
        whiteList[_asset.contractAddress] = _assetItem;
        bool alreadyExist;
        for (uint256 i = 0; i < whiteListedArray.length; i ++) {
            if (whiteListedArray[i].contractAddress == _asset.contractAddress){
                alreadyExist = true;
                break;
            }
        }
        if (!alreadyExist) {
               whiteListedArray.push(_asset); 
        }
        emit WhiteListItemChanged(
            _asset.contractAddress, 
            _assetItem.enabledForFee, 
            _assetItem.enabledForCollateral, 
            _assetItem.enabledRemoveFromCollateral,
            _assetItem.transferFeeModel
        );
    }

    function removeWLItem(ETypes.Asset calldata _asset) external onlyOwner {
        uint256 deletedIndex;
        for (uint256 i = 0; i < whiteListedArray.length; i ++) {
            if (whiteListedArray[i].contractAddress == _asset.contractAddress){
                deletedIndex = i;
                break;
            }
        }
        // Check that deleting item is not last array member
        // because in solidity we can remove only last item from array
        if (deletedIndex != whiteListedArray.length - 1) {
            // just replace deleted item with last item
            whiteListedArray[deletedIndex] = whiteListedArray[whiteListedArray.length - 1];
        } 
        whiteListedArray.pop();
        delete whiteList[_asset.contractAddress];
        emit WhiteListItemChanged(
            _asset.contractAddress, 
            false, false, false, address(0)
        );
    }

    function setBLItem(ETypes.Asset calldata _asset, bool _isBlackListed) external onlyOwner {
        blackList[_asset.contractAddress] = _isBlackListed;
        if (_isBlackListed) {
            for (uint256 i = 0; i < blackListedArray.length; i ++){
                if (blackListedArray[i].contractAddress == _asset.contractAddress) {
                    return;
                }
            }
            // There is no this address in array so  just add it
            blackListedArray.push(_asset);
        } else {
            uint256 deletedIndex;
            for (uint256 i = 0; i < blackListedArray.length; i ++){
                if (blackListedArray[i].contractAddress == _asset.contractAddress) {
                    deletedIndex = i;
                    break;
                }
            }
            // Check that deleting item is not last array member
            // because in solidity we can remove only last item from array
            if (deletedIndex != blackListedArray.length - 1) {
                // just replace deleted item with last item
                blackListedArray[deletedIndex] = blackListedArray[blackListedArray.length - 1];
            } 
            blackListedArray.pop();
            delete blackList[_asset.contractAddress];

        }
        emit BlackListItemChanged(_asset.contractAddress, _isBlackListed);
    }

    function setRules(address _asset, bytes2 _only, bytes2 _disabled) public onlyOwner {
        rulesChecker[_asset].onlythis = _only;
        rulesChecker[_asset].disabled = _disabled;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////
    
    function getWLItem(address _asset) external view returns (ETypes.WhiteListItem memory) {
        return whiteList[_asset];
    }

    function getWLItemCount() external view returns (uint256) {
        return whiteListedArray.length;
    }

    function getWLAddressByIndex(uint256 _index) external view returns (ETypes.Asset memory) {
        return whiteListedArray[_index];
    }

    function getWLAddresses() external view returns (ETypes.Asset[] memory) {
        return whiteListedArray;
    }

     
    function getBLItem(address _asset) external view returns (bool) {
        return blackList[_asset];
    }

    function getBLItemCount() external view returns (uint256) {
        return blackListedArray.length;
    }

    function getBLAddressByIndex(uint256 _index) external view returns (ETypes.Asset memory) {
        return blackListedArray[_index];
    }

    function getBLAddresses() external view returns (ETypes.Asset[] memory) {
        return blackListedArray;
    }

    function enabledForCollateral(address _asset) external view returns (bool) {
        return whiteList[_asset].enabledForCollateral;
    }

    function enabledForFee(address _asset) external view returns (bool) {
        return whiteList[_asset].enabledForFee;
    }

    function enabledRemoveFromCollateral(address _asset) external view returns (bool) {
        return whiteList[_asset].enabledRemoveFromCollateral;
    }
    
    function rulesEnabled(address _asset, bytes2 _rules) external view returns (bool) {

        if (rulesChecker[_asset].onlythis != 0x0000) {
            return rulesChecker[_asset].onlythis == _rules;
        }

        if (rulesChecker[_asset].disabled != 0x0000) {
            return (rulesChecker[_asset].disabled & _rules) == 0x0000;
        }
        return true;
    }

    function validateRules(address _asset, bytes2 _rules) external view returns (bytes2) {
        if (rulesChecker[_asset].onlythis != 0x0000) {
            return rulesChecker[_asset].onlythis;
        }

        if (rulesChecker[_asset].disabled != 0x0000) {
            return (~rulesChecker[_asset].disabled) & _rules;
        }
        return _rules;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

pragma solidity 0.8.16;

//import "IERC721Enumerable.sol";
import "LibEnvelopTypes.sol";

interface IAdvancedWhiteList  {


    event WhiteListItemChanged(
        address indexed asset,
        bool enabledForFee,
        bool enabledForCollateral,
        bool enabledRemoveFromCollateral,
        address transferFeeModel
    );
    event BlackListItemChanged(
        address indexed asset,
        bool isBlackListed
    );
    function getWLItem(address _asset) external view returns (ETypes.WhiteListItem memory);
    function getWLItemCount() external view returns (uint256);
    function getBLItem(address _asset) external view returns (bool);
    function getBLItemCount() external view returns (uint256);
    function enabledForCollateral(address _asset) external view returns (bool);
    function enabledForFee(address _asset) external view returns (bool);
    function enabledRemoveFromCollateral(address _asset) external view returns (bool);
    function rulesEnabled(address _asset, bytes2 _rules) external view returns (bool);
    function validateRules(address _asset, bytes2 _rules) external view returns (bytes2);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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