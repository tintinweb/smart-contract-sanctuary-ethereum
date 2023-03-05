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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

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

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

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

pragma solidity ^0.8.0;
interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;
interface IERC721{
    function balanceOf(address owner) external view returns (uint256 balance);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTBox {

    event BoxState(
        uint32 boxID,
        uint8 state,
        string chainName
    );

    event BoxOffer(
        uint32 listBoxID,
        uint32 OfferBoxID,
        string chainName
    );

    event Swaped (
        uint256 historyID,
        uint256 listID,
        address listBoxOwner,
        uint256 offerID,
        address offerBoxOwner,
        string chainName
    );

    event Purchased (
        uint256 historyID,
        uint256 boxID,
        address seller,
        address buyer,
        string chainName
    );

    event BoxWithDrawOffer(
        uint32 listBoxID,
        uint32 offerBoxID,
        string chainName
    );

    struct ERC20Details {
        address tokenAddr;
        uint96 amounts;
    }

    struct ERC721Details {
        address tokenAddr;
        uint32 id1;
        uint32 id2;
        uint32 id3;
    }

    struct ERC1155Details {
        address tokenAddr;
        uint32 id1;
        uint32 id2;
        uint16 amount1;
        uint16 amount2;
    }

    struct ERC20Fee {
        address tokenAddr;
        uint96 feeAmount;
    }

    struct RoyaltyFee {
        address reciever;
        uint96 feeAmount;
    }


    struct Box {
        address owner;
        uint32 id;
        uint32 state;
        uint32 whiteListOffer;
    }
    
    struct BoxConfig {
        uint8 usingERC721WhiteList;
        uint8 usingERC1155WhiteList;
        uint8 NFTTokenCount;
        uint8 ERC20TokenCount;
    }

    struct UserTotalSwapFees {
        // address owner;
        uint96 totalPrePaidNFTFees;
        ERC20Fee[] totalPrePaidERC20Fees;
    }

    struct SwapHistory {
        uint32 swapId;
        uint32 listId;
        address listOwner;
        uint32 offerId;
        address offerOwner;
        uint32 swapedTime;
        uint8 historyType; //1 : swap, 2:purchase
    }

    struct Discount {
        address user;
        address nft;
    }

    struct FixedPrice {
        address tokenAddr;
        uint96 amount;
    }

    struct PaymentTokenFee {
        address tokenAddr;
        uint96 percentage;
    }

    enum State {    
        Listed,
        NotListed
    }

    // function boxes(uint256) external returns(Box memory);
    // function prePaidGasFee(uint256) external returns(uint256);
    // function getERC20Fee(uint256) external returns(ERC20Fee[] memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTBox.sol";

interface INFTBoxAssets is INFTBox {
    
    function _transferERC20Fee(ERC20Fee[] calldata, address, address, bool) external;
    function _transferAssetsHelper(ERC721Details[] calldata, ERC20Details[] calldata, ERC1155Details[] calldata, address, address, bool) external;
    function _setOfferAdddress(uint256, address[] calldata) external;
    function _checkAvailableOffer(uint256, address) external view returns(bool);
    function _deleteOfferAddress(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTBox.sol";
interface INFTBoxFees is INFTBox {

    function _checkerc20Fees(
        ERC20Details[] calldata,
        address
    ) external view returns(ERC20Fee[] memory);

    function _checknftgasfee(
        ERC721Details[] calldata,
        ERC1155Details[] calldata,
        uint256,
        address
    ) external view returns(uint256);

    function _checkRoyaltyFee(
        ERC721Details[] calldata,
        ERC1155Details[] calldata,
        address
    ) external view returns(RoyaltyFee[] memory);

    function _checkPaymentTokenFee(
        FixedPrice calldata _fixedPrice,
        address
    ) external view returns(uint256);

    function _checkWhiteListToken(
        address
    ) external view returns(bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTBox.sol";

interface INFTBoxHistory is INFTBox {
    function addHistoryUserSwapFees(uint256, uint256, uint256,address,address, uint256, uint256, ERC20Fee[] memory, ERC20Fee[] memory, uint256) external;
    function addPurchaseUserSwapFees(uint256, uint256, address,address, uint256, ERC20Fee[] memory, uint256) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTBox.sol";

interface INFTBoxWhitelist is INFTBox {

    function _checkAssets(
        ERC721Details[] calldata,
        ERC20Details[] calldata,
        ERC1155Details[] calldata,
        address,
        address
    ) external view;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interface/INFTBox.sol";
import "./interface/INFTBoxWhitelist.sol";
import "./interface/INFTBoxFees.sol";
import "./interface/INFTBoxAssets.sol";
import "./interface/INFTBoxHistory.sol";
import "./interface/IERC20.sol";
import "./interface/IERC721.sol";
import "./interface/IERC1155.sol";
contract NFTBox is
    ReentrancyGuard,
    Ownable,
    INFTBox,
    ERC1155Holder
{
    /**
        @notice Check Box by boxId
    */
    mapping(uint256 => Box) public boxes;
    mapping(uint256 => ERC20Details[]) private erc20Details;
    mapping(uint256 => ERC721Details[]) private erc721Details;
    mapping(uint256 => ERC1155Details[]) private erc1155Details;
    mapping(uint256 => uint256) public gasTokenDetails;
    mapping(uint256 => uint256[]) private offers;
    mapping(uint256 => uint256[]) private offeredList;
    mapping(uint256 => uint256) public prePaidGasFee;
    mapping(uint256 => ERC20Fee[])  private prePaidErc20Fees;
    mapping(uint256 => RoyaltyFee[]) private prePaidRoyaltyFees;

    /**
        @notice Getting  address and amount of fixed price by boxID(parameter : boxID)
     */
    mapping(uint256 => FixedPrice) public fixedPrice;
    mapping(uint256 => address[]) public addWhitelistedOffer;

    address[] private whitelistAffiliate;
    /**
        @notice Check Influencer by userAddress
    */
    mapping(address => address) public affiliatedList;
    uint256 public affiliatedFeePercentage;


    uint256 private _boxesCounter;
    uint256 private _historyCounter;

    string private chainName;
    /**
        Fees List
        0: Creating a box
        1: Listing a box
        2: Offering a box
        3: Delisting a box
    */

    uint256[] public swapConstantFees = [0.0001 ether, 0.0002 ether, 0.0003 ether, 0.0004 ether];

    bool openSwap = true;

    address public NFTBoxWhitelist;
    address public NFTBoxFees;
    address public NFTBoxHistory;
    address public SwapFeeRecipient;

    constructor(
        address whiteList,
        address boxFee,
        address withdraw,
        string memory _chainName
    ) {
        NFTBoxWhitelist = whiteList;
        NFTBoxFees = boxFee;
        SwapFeeRecipient =  withdraw;
        chainName = _chainName;
    }

    modifier isOpenForSwap() {
        require(openSwap, "Swap is not allowed");
        _;
    }

    /**
        Controlling WhiteListContract, BoxFees, History Address
     */
    function setNFTWhiteListAddress(address nftBoxWhiteListAddress) public onlyOwner {
        NFTBoxWhitelist = nftBoxWhiteListAddress;
    }

    function setNFTBoxFeesAddress(address nftFeesAddress) public onlyOwner {
        NFTBoxFees = nftFeesAddress;
    }

    function setNFTBoxHistoryAddress(address historyAddress) public onlyOwner {
        NFTBoxHistory = historyAddress;
    }
    

    /**
    Box Contract State
    _new : true(possilbe Box)
    _new : false(impossilbe Box)
     */
    function pause(bool _new) public onlyOwner {
        openSwap = _new;
    }

    function setWithDrawOwner(address owner) public onlyOwner {
        SwapFeeRecipient = owner;
    }
    function setSwapFee(uint256 _index, uint64 _value) public onlyOwner {
        swapConstantFees[_index] = _value;
    }

    function transferBoxOwnerShip(uint256 boxId, address transferAddress) public isOpenForSwap {
        require(transferAddress != address(0), "Invalid address");
        require(boxes[boxId].owner == msg.sender, "You are not Box Owner");
        require(boxes[boxId].state == 2, "Box must be unliste state");
        uint256 count;
        for(uint256 i; i < offeredList[boxId].length; ++i) {
            if(offeredList[boxId][i] != 0)
                ++count;
        }
        require(count == 0, "You must withdraw all offers");
        boxes[boxId].owner = transferAddress;
    }

    /**
        add whitelist influencer 
    */
    function addWhitelistAffiliate(address influencer) public isOpenForSwap onlyOwner {
        require(influencer != address(0) , "Invalid address");
        for(uint256 i; i < whitelistAffiliate.length; ++i) {
            require(whitelistAffiliate[i] != influencer, "Already Whitelisted");
        }
        whitelistAffiliate.push(influencer);
    }

    /** 
        Set AffiliatedFee Percentage
    */
    function setAffiliateFeePercentage(uint256 percentage) public onlyOwner {
        require(percentage >=0 || percentage < 10000, "Invalid Percentage");
        affiliatedFeePercentage = percentage;
    }

    /**
        Link User to influencer
    */
    function setAffiliate(address influencer) public isOpenForSwap {
        require(influencer != address(0), "Invalid Address");
        uint256 count;
        for(uint256 i; i < whitelistAffiliate.length; ++i) {
            if(whitelistAffiliate[i] == influencer)
                ++count;
        }
        require(count == 1, "Not Whitelisted Influencer");
        require(affiliatedList[msg.sender] == address(0), "Already Register");

        affiliatedList[msg.sender] = influencer;
    }

    /**
        Remove User from influencer
    */
    function changeAffiliate(address user, address otherInfluencer) public onlyOwner {
        require(affiliatedList[user] != address(0), "Not Register");
        affiliatedList[user] = otherInfluencer;
    }
    

    /**
        remove whitelist influencer
    */
    function removeWhitelistAffiliate(uint256 index) public onlyOwner {
        require(index < whitelistAffiliate.length, "Invalid Index");
        whitelistAffiliate[index] = whitelistAffiliate[
            whitelistAffiliate.length - 1
        ];
        whitelistAffiliate.pop();
    }

    function getWhiteOffersList(uint256 boxId) public view returns(address[] memory) {
        return addWhitelistedOffer[boxId];
    }

    function getWhiteListAffiliate() public view returns(address[] memory) {
        return whitelistAffiliate;
    }

    function getSwapPrices() public view returns (uint256[] memory) {
        return swapConstantFees;
    }

    /**
        Get Assets 
    */

    function getERC20Data(uint256 _boxId) public view returns(ERC20Details[] memory) {
        return erc20Details[_boxId];
    }

    function getERC721Data(uint256 _boxId) public view returns(ERC721Details[] memory) {
        return erc721Details[_boxId];
    }

    function getERC1155Data(uint256 _boxId) public view returns(ERC1155Details[] memory) {
        return erc1155Details[_boxId];
    }

    function getERC20Fee(uint256 _boxId) external view returns(ERC20Fee[] memory) {
        return prePaidErc20Fees[_boxId];
    }

    function getRoyaltyFee(uint256 _boxId) public view returns(RoyaltyFee[] memory) {
        return prePaidRoyaltyFees[_boxId];
    }

    function getOffers(uint256 _boxId) public view returns(uint256[] memory) {
        return offers[_boxId];
    }

    function getofferedList(uint256 _boxId) public view returns(uint256[] memory) {
        return offeredList[_boxId];
    }

    function _transferERC20Fee(
        ERC20Fee[] memory erc20fee,
        address from, 
        address to, 
        bool transferFrom,
        uint256 transferPercentage
    ) internal {
        for(uint256 i = 0 ; i < erc20fee.length ; i ++) {
            if(transferFrom == true) {
                require(
                        IERC20(erc20fee[i].tokenAddr).allowance(
                            from,
                            to
                            ) >= erc20fee[i].feeAmount,
                        "not approved to swap contract"
                        );

                    IERC20(erc20fee[i].tokenAddr).transferFrom(
                        from,
                        to,
                        erc20fee[i].feeAmount
                    );
            } else {
                    IERC20(erc20fee[i].tokenAddr).transfer(
                        to,
                        erc20fee[i].feeAmount * transferPercentage / 10000
                    );
            }
        }
    }
    /**
        Transferring Box Assets including erc721, erc20, erc1155
        for creating box, destroy box
     */
    function _transferAssetsHelper(
        ERC721Details[] memory erc721Detail,
        ERC20Details[]  memory erc20Detail,
        ERC1155Details[] memory erc1155Detail,
        address from,
        address to,
        bool transferFrom
    ) internal {
        for (uint256 i = 0; i < erc721Detail.length; i++) {

            if(erc721Detail[i].id1 == 4294967295) continue;

            IERC721(erc721Detail[i].tokenAddr).transferFrom(
                from,
                to,
                erc721Detail[i].id1
            );

            if(erc721Detail[i].id2 == 4294967295) continue;

            IERC721(erc721Detail[i].tokenAddr).transferFrom(
                from,
                to,
                erc721Detail[i].id2
            );

            if(erc721Detail[i].id3 == 4294967295) continue;

            IERC721(erc721Detail[i].tokenAddr).transferFrom(
                from,
                to,
                erc721Detail[i].id3
            );
        }
        if(transferFrom == true) {
            for (uint256 i = 0; i < erc20Detail.length; i++) {
                IERC20(erc20Detail[i].tokenAddr).transferFrom(
                    from,
                    to,
                    erc20Detail[i].amounts
                );
            }
        } else {
            for (uint256 i = 0; i < erc20Detail.length; i++) {
                IERC20(erc20Detail[i].tokenAddr).transfer(to, erc20Detail[i].amounts);
            }
        }

        for (uint256 i = 0; i < erc1155Detail.length; i++) {
            if(erc1155Detail[i].amount1 == 0) continue;
            if(erc1155Detail[i].amount2 == 0) {
                uint256 [] memory ids = new uint256[](1);
                ids[0] = erc1155Detail[i].id1;
                uint256 [] memory amounts = new uint256[](1);
                amounts[0] = erc1155Detail[i].amount1; 
                IERC1155(erc1155Detail[i].tokenAddr).safeBatchTransferFrom(
                    from,
                    to,
                    ids,
                    amounts,
                    ""
                );
            } else {
                uint256 [] memory ids = new uint256[](2);
                ids[0] = erc1155Detail[i].id1;
                ids[1] = erc1155Detail[i].id2;
                uint256 [] memory amounts = new uint256[](2);
                amounts[0] = erc1155Detail[i].amount1;
                amounts[1] = erc1155Detail[i].amount2;
                IERC1155(erc1155Detail[i].tokenAddr).safeBatchTransferFrom(
                    from,
                    to,
                    ids,
                    amounts,
                    ""
                );
            }
        }
    }
    /**
    Check OfferState
    if return is true : it is offered
    if return is false : it is not offered
    */
    function _checkOfferState(
        uint256 listBoxId,
        uint256 offerBoxId
    ) internal view returns (bool) {
        for (uint256 i = 0; i < offers[listBoxId].length; i++) {
            if(offers[listBoxId][i] == offerBoxId)
                return true;
        }
        return false;
    }

    function _transferSwapFees(
        uint256 boxId,
        address to,
        bool swapped,
        uint256 transferPercentage
    ) internal {
        payable(to).transfer(prePaidGasFee[boxId] * transferPercentage / 10000);
        _transferERC20Fee(prePaidErc20Fees[boxId], address(this), to, false, transferPercentage);

        uint256 royaltyFeeLength = prePaidRoyaltyFees[boxId].length;
        if(!swapped) {
            for(uint256 i = 0; i < royaltyFeeLength; i++){
                payable(to).transfer(prePaidRoyaltyFees[boxId][i].feeAmount);
            }
        } else {
            for(uint256 i = 0; i < royaltyFeeLength; i++){
                payable(prePaidRoyaltyFees[boxId][i].reciever).transfer(prePaidRoyaltyFees[boxId][i].feeAmount);
            }
        }
    }

    function _checkingBoxAssetsCounter(
        ERC721Details[] memory _erc721Details,
        ERC20Details[] memory _erc20Details,
        ERC1155Details[] memory _erc1155Details,
        uint256 _gasTokenDetails
    ) internal pure returns (uint256) {
        uint256 assetCounter;

        for(uint256 i ; i < _erc721Details.length ; ++i){
            if(_erc721Details[i].id1 == 4294967295) continue;
                ++assetCounter;
            if(_erc721Details[i].id2 == 4294967295) continue;
                ++assetCounter;
            if(_erc721Details[i].id3 == 4294967295) continue;
                ++assetCounter;
        }

        for(uint256 i ; i < _erc1155Details.length ; ++i){
            if(_erc1155Details[i].amount1 == 0) continue;
                assetCounter += _erc1155Details[i].amount1;
            if(_erc1155Details[i].amount2 == 0) continue;
                assetCounter += _erc1155Details[i].amount2;
        }

        if(_erc20Details.length > 0)
            ++assetCounter;

        if(_gasTokenDetails > 0)
            ++assetCounter;

        return assetCounter;
    }

     //check availabe offerAddress for listing box
    function _checkAvailableOffer(uint256 boxId, address offerAddress) internal view returns(bool) {
        for(uint256 i = 0; i < addWhitelistedOffer[boxId].length; i++) {
            if(addWhitelistedOffer[boxId][i] == offerAddress)
                return true;
        }
        return false;
    }

    //Delet SwapBoxAssets

    function _deleteAssets(uint256 boxId) internal {
        delete boxes[boxId];
        delete erc20Details[boxId];
        delete erc721Details[boxId];
        delete erc1155Details[boxId];
        delete gasTokenDetails[boxId];
        delete prePaidErc20Fees[boxId];
        delete prePaidRoyaltyFees[boxId];
        delete prePaidGasFee[boxId];
        delete offers[boxId];
        delete offeredList[boxId];
        delete addWhitelistedOffer[boxId];
        delete fixedPrice[boxId];
    }

    function createBox(
        ERC721Details[] calldata _erc721Details,
        ERC20Details[] calldata _erc20Details,
        ERC1155Details[] calldata _erc1155Details,
        uint256 _gasTokenDetails,
        address[] calldata offerAddress,
        uint256 state,
        FixedPrice calldata _fixedPrice
    ) public payable isOpenForSwap nonReentrant returns(uint256) {

        require(_erc721Details.length + _erc20Details.length + _erc1155Details.length + _gasTokenDetails > 0,"No Assets");
        require(state == 1 || state == 2, "Invalid state");

        if(_fixedPrice.amount > 0 && _fixedPrice.tokenAddr != address(0)) {
           INFTBoxFees(NFTBoxFees)._checkWhiteListToken(_fixedPrice.tokenAddr);
        }

        uint256 createFees = _checkingBoxAssetsCounter(_erc721Details, _erc20Details, _erc1155Details, _gasTokenDetails) * swapConstantFees[0];

        uint256 prePaid_nft_gas_Fees = INFTBoxFees(NFTBoxFees)._checknftgasfee(
            _erc721Details,
            _erc1155Details,
            _gasTokenDetails,
            msg.sender
        );

        RoyaltyFee[] memory royaltyFees = INFTBoxFees(NFTBoxFees)._checkRoyaltyFee(
            _erc721Details,
            _erc1155Details,
            msg.sender
        );

        ERC20Fee[] memory prePaid_erc20Fees = INFTBoxFees(NFTBoxFees)._checkerc20Fees(
            _erc20Details,
            msg.sender
        );
        
        uint256 boxroyaltyFees; 
          for (uint256 i = 0; i < royaltyFees.length; i++){
            boxroyaltyFees += royaltyFees[i].feeAmount;
        }

        if(state == 1){
            require(
                msg.value == createFees + _gasTokenDetails + swapConstantFees[1] + prePaid_nft_gas_Fees + boxroyaltyFees, "Insufficient Creating Fee"
            );
        } else {
            require(
                msg.value == createFees + _gasTokenDetails + swapConstantFees[2] + prePaid_nft_gas_Fees + boxroyaltyFees, "Insufficient Offering Fee"
            );
        }

        INFTBoxWhitelist(NFTBoxWhitelist)._checkAssets(
            _erc721Details,  
            _erc20Details,
            _erc1155Details,
            msg.sender,
            address(this)
        );

        _transferAssetsHelper(
            _erc721Details,
            _erc20Details,
            _erc1155Details,
            msg.sender,
            address(this),
            true
        );


        _transferERC20Fee(prePaid_erc20Fees, msg.sender, address(this), true, 10000);


        ++_boxesCounter;


        Box storage box = boxes[_boxesCounter];
        box.id = uint32(_boxesCounter);
        box.owner = msg.sender;
        box.state = uint32(state);

        for(uint256 i ; i < _erc20Details.length; ++i) 
            erc20Details[_boxesCounter].push(_erc20Details[i]);

        for(uint256 i ; i < _erc721Details.length; ++i)
            erc721Details[_boxesCounter].push(_erc721Details[i]);

        for(uint256 i ; i < _erc1155Details.length; ++i)
            erc1155Details[_boxesCounter].push(_erc1155Details[i]);

        gasTokenDetails[_boxesCounter] = _gasTokenDetails;

        prePaidGasFee[_boxesCounter] = prePaid_nft_gas_Fees;
        for(uint256 i ; i < prePaid_erc20Fees.length ; ++i)
            prePaidErc20Fees[_boxesCounter].push(prePaid_erc20Fees[i]);
        for(uint256 i ; i < royaltyFees.length ; ++i)
            prePaidRoyaltyFees[_boxesCounter].push(royaltyFees[i]);

        if(state == 1)
            payable(SwapFeeRecipient).transfer(swapConstantFees[1] + createFees);
        else 
            payable(SwapFeeRecipient).transfer(createFees);

        if(offerAddress.length > 0) {
            // for(uint256 i ; i < offerAddress.length ; ++i){
                addWhitelistedOffer[_boxesCounter]= offerAddress;
            // }
            box.whiteListOffer = 1;
        }

        if(_fixedPrice.amount > 0)
            fixedPrice[_boxesCounter] = _fixedPrice;

        emit BoxState(
            uint32(_boxesCounter),
            uint8(state),
            chainName
        );

        return _boxesCounter;
    }

    // Destroy Box. all assets back to owner's wallet
    function withdrawBox(uint256 boxId)
        payable
        public
        nonReentrant
    {

        require(
            boxes[boxId].owner == msg.sender,
            "only Owner of Box"
        );

        if(boxes[boxId].state == 1) {
            uint256 offerCount;
            for(uint256 i; i < offers[boxId].length; ++i){
                if(offers[boxId][i] != 0)
                    ++offerCount;
            }
            require(msg.value == offerCount * swapConstantFees[3], "Insufficient Fee for Delisting");

        }

        _transferAssetsHelper(
            erc721Details[boxId],
            erc20Details[boxId],
            erc1155Details[boxId],
            address(this),
            msg.sender,
            false
        );

        if (gasTokenDetails[boxId] > 0) {
            payable(msg.sender).transfer(gasTokenDetails[boxId]);
        }

        _transferSwapFees(
            boxId,
            msg.sender,
            false,
            10000
        );

        for(uint256 i ; i < offeredList[boxId].length ; ++i) {
            for(uint256 j ; j < offers[offeredList[boxId][i]].length ; ++j) {
                if(offers[offeredList[boxId][i]][j] == boxId) {
                    delete offers[offeredList[boxId][i]][j];
                }
            }
        }

        for(uint256 i ; i < offers[boxId].length ; ++i) {
            for(uint256 j ; j < offeredList[offers[boxId][i]].length ; ++j) {
                if(offeredList[offers[boxId][i]][j] == boxId) {
                    delete offeredList[offers[boxId][i]][j];
                }
            }
        }

        if(keccak256(abi.encodePacked(chainName)) != keccak256(abi.encodePacked("Goerli")))
            boxes[boxId].state = 3;
        else {
            _deleteAssets(boxId);
        }

        emit BoxState(
            uint32(boxId),
            3,
            chainName
        );
    }
    /**
        Unlist Box State
        Box sate will be set as 2(unlist)
     */
    function UnlistBoxState (
        uint256 boxId
    ) public payable isOpenForSwap nonReentrant {
        require(
            boxes[boxId].owner == msg.sender,
            "only Owner of Box"
        );

        uint256 offerCount;
        for(uint256 i; i < offers[boxId].length; ++i){
            if(offers[boxId][i] != 0)
                ++offerCount;
        }
        require(msg.value ==  offerCount * swapConstantFees[3], "Insufficient Fee for Delisting");

        for(uint256 i ; i < offers[boxId].length ; ++i) {
            for(uint256 j ; j < offeredList[offers[boxId][i]].length ; ++j) {
                if(offeredList[offers[boxId][i]][j] == boxId) {
                    delete offeredList[offers[boxId][i]][j];
                }
            }
        }

        delete offers[boxId];
        delete addWhitelistedOffer[boxId];
        delete fixedPrice[boxId];

        boxes[boxId].state = 2;

        emit BoxState(
            uint32(boxId),
            uint8(2),
            chainName
        );    
    }

    /**
        list Box State
        Box sate will be set as 1(list)
     */
    function ListBoxState (
        uint256 boxId,
        address[] memory offerAddress,
        FixedPrice calldata _fixedPrice
    ) public payable isOpenForSwap nonReentrant {
        require(
            boxes[boxId].owner == msg.sender,
            "only Owner of Box"
        );
        
        require(msg.value == swapConstantFees[1], "Insufficient Fee for listing");

        for(uint256 i ; i < offeredList[boxId].length ; ++i) {
            for(uint256 j ; j < offers[offeredList[boxId][i]].length ; ++j) {
                if(offers[offeredList[boxId][i]][j] == boxId) {
                    delete offers[offeredList[boxId][i]][j];
                }
            }
        }
        delete offeredList[boxId];

        if(_fixedPrice.amount > 0 && _fixedPrice.tokenAddr != address(0)) {
            INFTBoxFees(NFTBoxFees)._checkWhiteListToken(_fixedPrice.tokenAddr);
        }

        if(_fixedPrice.amount > 0)
            fixedPrice[boxId] = _fixedPrice;

        boxes[boxId].state = 1;
        if(offerAddress.length > 0) {
            // for(uint256 i ; i < offerAddress.length ; ++i){
                addWhitelistedOffer[_boxesCounter] = offerAddress;
            // }
            boxes[boxId].whiteListOffer = 1;
        }

        emit BoxState(
            uint32(boxId),
            uint8(1),
            chainName
        );
    }

    // Link your Box to other's waiting Box. Equal to offer to other Swap Box
    function offerBox(uint256 listBoxId, uint256 offerBoxId)
        public
        payable
        isOpenForSwap
        nonReentrant
    {
        require(
            boxes[offerBoxId].state == 2,
            "Not allowed!"
        );
        require(
            boxes[offerBoxId].owner == msg.sender,
            "Only owner of Box can make offer!"
        );
        require(
            _checkOfferState(listBoxId, offerBoxId) == false,
            "Already offered!"
        );
        require(
            boxes[listBoxId].state == 1,
            "Unlist state!"
        );
        require(msg.value == swapConstantFees[2], "Insufficient Fee for making an offer!");

        if(boxes[listBoxId].whiteListOffer == 1)
            require(_checkAvailableOffer(listBoxId, msg.sender) == true, "Not listed Offer Address!");

        payable(SwapFeeRecipient).transfer(swapConstantFees[2]);

        offers[listBoxId].push(offerBoxId);
        offeredList[offerBoxId].push(listBoxId);

        emit BoxOffer(uint32(listBoxId), uint32(offerBoxId),chainName);
    }
    /**
        purchase Box as a fixed price
    */

    function purchaseBox(uint256 BoxId) payable public isOpenForSwap {
        require(boxes[BoxId].state == 1, "Not Allowed");
        require(msg.sender != boxes[BoxId].owner,"Can't purchase own box");
        if(boxes[BoxId].whiteListOffer == 1)
            require(_checkAvailableOffer(BoxId, msg.sender) == true, "Not listed Offer Address");
        uint256 tokenFee = INFTBoxFees(NFTBoxFees)._checkPaymentTokenFee(fixedPrice[BoxId], msg.sender);

        if(fixedPrice[BoxId].tokenAddr == address(0)){
            require(msg.value == fixedPrice[BoxId].amount + tokenFee, "Insufficient Balance");
            payable(boxes[BoxId].owner).transfer(fixedPrice[BoxId].amount);
            payable(SwapFeeRecipient).transfer(tokenFee);
        }
        else {  
            require(
                IERC20(fixedPrice[BoxId].tokenAddr).balanceOf(msg.sender) >=
                   fixedPrice[BoxId].amount + tokenFee,
                "Insufficient ERC20 tokens"
            );
            require(
                IERC20(fixedPrice[BoxId].tokenAddr).allowance(
                    msg.sender,
                    address(this)
                ) >= fixedPrice[BoxId].amount + tokenFee,
                "not approved to swap contract"
            );
            
            IERC20(fixedPrice[BoxId].tokenAddr).transferFrom(
                    msg.sender,
                    address(this),
                    fixedPrice[BoxId].amount + tokenFee
            );

            IERC20(fixedPrice[BoxId].tokenAddr).transfer(
                    boxes[BoxId].owner,
                    fixedPrice[BoxId].amount
            );

            IERC20(fixedPrice[BoxId].tokenAddr).transfer(
                    SwapFeeRecipient,
                    tokenFee
            );
        }
        if(affiliatedList[boxes[BoxId].owner] !=  address(0)) {
            _transferSwapFees(
                BoxId,
                affiliatedList[boxes[BoxId].owner],
                true,
                affiliatedFeePercentage
            );
            _transferSwapFees(
                BoxId,
                SwapFeeRecipient,
                true,
                10000 - affiliatedFeePercentage
            );
        } else {
            _transferSwapFees(
                BoxId,
                SwapFeeRecipient,
                true,
                10000
             );
        }

         if(keccak256(abi.encodePacked(chainName)) != keccak256(abi.encodePacked("Goerli")))
            INFTBoxHistory(NFTBoxHistory).addPurchaseUserSwapFees(
                _historyCounter,
                BoxId,
                boxes[BoxId].owner,
                msg.sender,
                prePaidGasFee[BoxId],
                prePaidErc20Fees[BoxId],
                2
            );

        _transferAssetsHelper(
            erc721Details[BoxId],
            erc20Details[BoxId],
            erc1155Details[BoxId],
            address(this),
            msg.sender,
            false
        );

        if(gasTokenDetails[BoxId] > 0)
            payable(msg.sender).transfer(gasTokenDetails[BoxId]);

        _historyCounter++;
        
        emit Purchased(
            _historyCounter,
            BoxId,
            boxes[BoxId].owner,
            msg.sender,
            chainName
        );
        _deleteAssets(BoxId);

    }

    // Swaping Box. Owners of Each Box should be exchanged
    function swapBox(uint256 listBoxId, uint256 offerBoxId)
        public
        isOpenForSwap
    {
        require(
            boxes[listBoxId].owner == msg.sender,
            "only Owner of Box"
        );
        require(
            boxes[listBoxId].state == 1,
            "Not Allowed"
        );
        require(
            boxes[offerBoxId].state == 2,
            "Not NotListed"
        );
        require(
            _checkOfferState(listBoxId, offerBoxId),
            "not exist or active"
        );
        if(affiliatedList[boxes[listBoxId].owner] != address(0)) {
            _transferSwapFees(
                listBoxId,
                affiliatedList[boxes[listBoxId].owner],
                true,
                affiliatedFeePercentage
            );
            _transferSwapFees(
                listBoxId,
                SwapFeeRecipient,
                true,
                10000 - affiliatedFeePercentage
            );
        } else {
            _transferSwapFees(
                listBoxId,
                SwapFeeRecipient,
                true,
                10000
            );
        }
        if(affiliatedList[boxes[offerBoxId].owner] != address(0)) {
            _transferSwapFees(
                offerBoxId,
                affiliatedList[boxes[offerBoxId].owner],
                true,
                affiliatedFeePercentage
            );
            _transferSwapFees(
                offerBoxId,
                SwapFeeRecipient,
                true,
                10000 - affiliatedFeePercentage
            );
        } else {
             _transferSwapFees(
                offerBoxId,
                SwapFeeRecipient,
                true,
                10000
            );
        }

       

        _transferAssetsHelper(
            erc721Details[listBoxId],
            erc20Details[listBoxId],
            erc1155Details[listBoxId],
            address(this),
            boxes[offerBoxId].owner,
            false
        );

        if(gasTokenDetails[listBoxId] > 0)
            payable(boxes[offerBoxId].owner).transfer(gasTokenDetails[listBoxId]);

        _transferAssetsHelper(
            erc721Details[offerBoxId],
            erc20Details[offerBoxId],
            erc1155Details[offerBoxId],
            address(this),
            boxes[listBoxId].owner,
            false
        );

        if(gasTokenDetails[offerBoxId] > 0)
            payable(boxes[offerBoxId].owner).transfer(gasTokenDetails[listBoxId]);

       if(keccak256(abi.encodePacked(chainName)) != keccak256(abi.encodePacked("Goerli")))
            INFTBoxHistory(NFTBoxHistory).addHistoryUserSwapFees(
                _historyCounter,
                listBoxId,
                offerBoxId,
                boxes[listBoxId].owner,
                boxes[offerBoxId].owner,
                prePaidGasFee[listBoxId],
                prePaidGasFee[offerBoxId],
                prePaidErc20Fees[listBoxId],
                prePaidErc20Fees[offerBoxId],
                1
            );
        _historyCounter++;
        emit Swaped(
            _historyCounter,
            listBoxId,
            boxes[listBoxId].owner,
            offerBoxId,
            boxes[offerBoxId].owner,
            chainName
        );
        
        if(keccak256(abi.encodePacked(chainName)) != keccak256(abi.encodePacked("Goerli"))) {
            boxes[listBoxId].state = 3;
            boxes[offerBoxId].state = 3;
        } else {
            _deleteAssets(listBoxId);
            _deleteAssets(offerBoxId);
        }
        for(uint256 i ; i < offers[listBoxId].length ; ++i) {
            for(uint256 j ; j < offeredList[offers[listBoxId][i]].length ; ++j) {
                if(offeredList[offers[listBoxId][i]][j] == listBoxId) {
                    delete offeredList[offers[listBoxId][i]][j];
                }
            }
        }
        

    }
    // WithDraw offer from linked offer
    function withDrawOffer(uint256 listBoxId, uint256 offerBoxId)
        public
        isOpenForSwap
        nonReentrant
    {
        require(
            boxes[offerBoxId].owner == msg.sender,
            "only Owner of Box"
        );

        uint256 offerLength =  offers[listBoxId].length;
        for(uint256 i ; i < offerLength ; ++i) {
            if(offers[listBoxId][i] == offerBoxId) {
               delete offers[listBoxId][i];
            }
        }

        for(uint256 i ; i < offeredList[offerBoxId].length; ++i){
            if(offeredList[offerBoxId][i] == listBoxId) {
                delete offeredList[offerBoxId][i];
            }
        }

        emit BoxWithDrawOffer(uint32(listBoxId), uint32(offerBoxId),chainName);
    }

}