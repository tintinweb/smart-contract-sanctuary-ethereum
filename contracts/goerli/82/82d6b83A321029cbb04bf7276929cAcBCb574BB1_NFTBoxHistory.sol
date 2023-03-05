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

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/INFTBox.sol";
// import "./NFTBox.sol";
contract NFTBoxHistory is Ownable, INFTBox {

    uint256 _swapFeeCounter = 1;
    uint256 public totalSwapCounter = 0;
    
    mapping(address => UserTotalSwapFees) public userTotalSwapFees;
    SwapHistory[] private swapHistory;
    // mapping(uint256 => SwapHistory)  public swapHistory;

    address public boxAddress;
    // UserTotalSwapFees[] totalSwapFees;
    // SwapHistory [] swapHistory;
    function setBoxAddress(address _new) public {
        require(_new != address(0), "Invalid Address");
        boxAddress = _new;
    }

    function getUserTotalSwapFees(address userAddress) public view returns(UserTotalSwapFees memory) {
        return userTotalSwapFees[userAddress];
    }

    function getSwapHistoryById(uint256 historyId) public view returns(SwapHistory memory) {
        require(historyId <= swapHistory.length && historyId != 0, "Invalid history Id");
        return swapHistory[historyId - 1];
    }
// , address listOwner, address offerOwner, uint256 list_nft_gas_fee, uint256 offer_nft_gas_fee, ERC20Fee[] calldata list_erc20Fee, ERC20Fee[] calldata offer_erc20Fee
    function addHistoryUserSwapFees(
        uint256 historyId, 
        uint256 listId, 
        uint256 offerId, 
        address listOwner, 
        address offerOwner, 
        uint256 list_prePaidNFTGasFee, 
        uint256 offer_prePaidNFTGasFee, 
        ERC20Fee[] calldata list_prePaidERC20Fee, 
        ERC20Fee[] calldata offer_prePaidERC20Fee, 
        uint256 swapType) external {
        SwapHistory memory history;
        history.swapId = uint32(historyId);

        history.listId = uint32(listId);
        history.listOwner = listOwner;
        history.offerId = uint32(offerId);
        history.offerOwner = offerOwner;
        history.swapedTime = uint32(block.timestamp);
        history.historyType = uint8(swapType);
        swapHistory.push(history);

        userTotalSwapFees[listOwner].totalPrePaidNFTFees += uint96(list_prePaidNFTGasFee);
        userTotalSwapFees[offerOwner].totalPrePaidNFTFees += uint96(offer_prePaidNFTGasFee);
        // ERC20Fee[] memory list_prePaidERC20Fee = INFTBox(boxAddress).getERC20Fee(listId);
        // ERC20Fee[] memory offer_prePaidERC20Fee = INFTBox(boxAddress).getERC20Fee(offerId);
       ERC20Fee[] memory list_totalPrePaidERC20Fee = userTotalSwapFees[history.listOwner].totalPrePaidERC20Fees; 
       uint256 index;
        for (uint256 i ; i < list_prePaidERC20Fee.length; ++i) {
            index = 0;
            for(uint256 j; j < list_totalPrePaidERC20Fee.length; ++j) {
                if(list_totalPrePaidERC20Fee[i].tokenAddr == list_prePaidERC20Fee[i].tokenAddr) {
                    userTotalSwapFees[history.listOwner].totalPrePaidERC20Fees[i].feeAmount += list_prePaidERC20Fee[j].feeAmount;
                    ++index;
                }
            }
            if(index == 0)
                userTotalSwapFees[history.listOwner].totalPrePaidERC20Fees.push(list_prePaidERC20Fee[i]);
        }

        ERC20Fee[] memory offer_totalPrePaidERC20Fee = userTotalSwapFees[history.offerOwner].totalPrePaidERC20Fees; 
        for (uint256 i ; i < offer_prePaidERC20Fee.length; ++i) {
            index = 0;
            for(uint256 j; j < offer_totalPrePaidERC20Fee.length; ++j) {
                 if(offer_totalPrePaidERC20Fee[i].tokenAddr == offer_prePaidERC20Fee[i].tokenAddr)
                    userTotalSwapFees[history.offerOwner].totalPrePaidERC20Fees[i].feeAmount += offer_prePaidERC20Fee[j].feeAmount;
            }
            if(index == 0)
                userTotalSwapFees[history.offerOwner].totalPrePaidERC20Fees.push(offer_prePaidERC20Fee[i]);
        }
    }

    function addPurchaseUserSwapFees(uint256 historyId, uint256 listId, address listOwner, address buyer, uint256 list_prePaidNFTGasFee, ERC20Fee[] calldata list_prePaidERC20Fee, uint256 swapType) external {
        SwapHistory memory history;
        history.swapId = uint32(historyId);

        history.listId = uint32(listId);
        history.listOwner = listOwner;
        history.offerOwner = buyer;
        history.swapedTime = uint32(block.timestamp);
        history.historyType = uint8(swapType);
        swapHistory.push(history);

        userTotalSwapFees[listOwner].totalPrePaidNFTFees += uint96(list_prePaidNFTGasFee);
        ERC20Fee[] memory list_totalPrePaidERC20Fee = userTotalSwapFees[history.listOwner].totalPrePaidERC20Fees; 
        uint256 index;
        for (uint256 i ; i < list_prePaidERC20Fee.length; ++i) {
            index = 0;
            for(uint256 j; j < list_totalPrePaidERC20Fee.length; ++j) {
                 if(list_totalPrePaidERC20Fee[i].tokenAddr == list_prePaidERC20Fee[i].tokenAddr)
                    userTotalSwapFees[history.listOwner].totalPrePaidERC20Fees[i].feeAmount += list_prePaidERC20Fee[j].feeAmount;
            }
            if(index == 0)
                userTotalSwapFees[history.listOwner].totalPrePaidERC20Fees.push(list_prePaidERC20Fee[i]);
        }
    }
}