// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interface/INFTSwap.sol";
import "./interface/INFTSwapBoxWhitelist.sol";
import "./interface/INFTSwapBoxFees.sol";
import "./interface/INFTSwapBoxAssets.sol";
import "./interface/INFTSwapBoxHistory.sol";
contract NFTSwapBox is 
    ReentrancyGuard, 
    Ownable, 
    INFTSwap,
    ERC1155Holder
{
    //SwapBox Contract Owner
    address payable public swapOwner;
    //Owner who is recieved swapcontract fees
    address public withdrawOwner;
    uint256 public _itemCounter;
    uint256 private _historyCounter = 1;

    uint64[] public swapConstantFees = [0.0001 ether, 0.0002 ether, 0.0003 ether, 0.0004 ether];
    bool openSwap = false;

    address public NFTSwapBoxWhitelist;
    address public NFTSwapBoxFees;
    address public  NFTSwapBoxAssets;
    address public NFTSwapBoxHistory;

    mapping(uint256 => SwapBox) public swapBoxes;

    constructor() {
        swapOwner = payable(msg.sender);
    }

    modifier isOpenForSwap() {
        require(openSwap, "Swap is not allowed");
        _;
    }

    //controlling WhiteList, Contract address
    function setNFTWhiteListAddress(address nftSwapboxWhiteListAddress) public onlyOwner {
        NFTSwapBoxWhitelist = nftSwapboxWhiteListAddress;
    }
    //controlling SwapBoxFees, Contract address
    function setNFTSwapBoxFeesAddress(address nftFeesAddress) public onlyOwner {
        NFTSwapBoxFees = nftFeesAddress;
    }

    function setNFTAssetsAddress(address  assetsAddress) public onlyOwner {
        NFTSwapBoxAssets = assetsAddress;
    }

    function setNFTSwapBoxHistoryAddress(address historyAddress) public onlyOwner {
        NFTSwapBoxHistory = historyAddress;
    }
    //User can Swapbox if openswap == true
    function setSwapState(bool _new) public onlyOwner {
        openSwap = _new;
    }

    function setSwapOwner(address swapper) public onlyOwner {
        swapOwner = payable(swapper);
    }

    function setWithDrawOwner(address withDrawOwner) public onlyOwner {
        withdrawOwner = withDrawOwner;
    }
    function setSwapFee(uint256 _index, uint64 _value) public onlyOwner {
        swapConstantFees[_index] = _value;
    }
    function getSwapPrices() public view returns (uint64[] memory) {
        return swapConstantFees;
    }

    // Checking the exist boxID. If checkingActive is true, it will check activity
    function _existBoxID(
        SwapBox memory box,
        uint256 boxID,
        bool checkingActive
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < box.offers.length; i++) {
            if (checkingActive) {
                if (
                    checkingActive &&
                    box.offers[i].boxID == boxID &&
                    box.offers[i].active
                ) {
                    return true;
                }
            } else {
                if (box.offers[i].boxID == boxID) {
                    return true;
                }
            }
        }

        return false;
    }
    // Insert & Update the SwapOffer to Swap Box. Set active value of Swap Offer
    function _putSwapOffer(
        uint256 listID,
        uint256 boxID,
        bool active
    ) internal {
        for (uint256 i = 0; i < swapBoxes[listID].offers.length; i++) {
            if (swapBoxes[listID].offers[i].boxID == boxID) {
                swapBoxes[listID].offers[i].active = active;
                return;
            }
        }

        swapBoxes[listID].offers.push(BoxOffer(boxID, active));
    }

    function _transferSwapFees(
        uint256 nftSwapFee,
        uint256 gasTokenFee,
        ERC20Fee[] memory erc20Fees,
        RoyaltyFee[] memory boxRoyaltyFee,
        address to,
        bool swapped
    ) internal {
        payable(to).transfer(nftSwapFee + gasTokenFee);
        INFTSwapBoxAssets(NFTSwapBoxAssets)._transferERC20Fee(erc20Fees, NFTSwapBoxAssets, to, false);
        if(!swapped) {
            for(uint256 i = 0; i < boxRoyaltyFee.length; i++){
                payable(to).transfer(boxRoyaltyFee[i].feeAmount);
            }
        } else {
            for(uint256 i = 0; i < boxRoyaltyFee.length; i++){
                payable(boxRoyaltyFee[i].reciever).transfer(boxRoyaltyFee[i].feeAmount);
            }
        }
    }

    //Insert SwapFees to swapbox
    function _caculateSwapFees(
        uint256 boxID
    ) internal {
        swapBoxes[boxID].nftSwapFee = INFTSwapBoxFees(NFTSwapBoxFees)._checkNFTFee(swapBoxes[boxID].erc721Tokens, swapBoxes[boxID].erc1155Tokens,swapBoxes[boxID].owner);
        ERC20Fee[] memory erc20Fees = INFTSwapBoxFees(NFTSwapBoxFees)._checkERC20Fee(swapBoxes[boxID].erc20Tokens,swapBoxes[boxID].owner);
        for (uint256 i = 0; i < swapBoxes[boxID].erc20Fees.length; i++){
            swapBoxes[boxID].erc20Fees.pop();
        }
        for (uint256 i = 0; i < erc20Fees.length; i++){
            swapBoxes[boxID].erc20Fees.push(erc20Fees[i]);
        }
        swapBoxes[boxID].gasTokenFee = INFTSwapBoxFees(NFTSwapBoxFees)._checkGasTokenFee(swapBoxes[boxID].gasTokenAmount, swapBoxes[boxID].owner);
        RoyaltyFee[] memory royaltyFees = INFTSwapBoxFees(NFTSwapBoxFees)._checkRoyaltyFee(swapBoxes[boxID].erc721Tokens, swapBoxes[boxID].erc1155Tokens);
        for (uint256 i = 0; i < royaltyFees.length; i++){
            swapBoxes[boxID].boxRoyaltyFee.push(royaltyFees[i]);
        }
    }
    // Create Swap Box. Warning User needs to approve assets before list
    function createBox(
        ERC721Details[] memory erc721Details,
        ERC20Details memory erc20Details,
        ERC1155Details[] memory erc1155Details,
        uint256 gasTokenAmount
    ) public payable isOpenForSwap nonReentrant {

        uint256 createFees =  INFTSwapBoxFees(NFTSwapBoxFees)._checkCreatingBoxFees(swapConstantFees[0], erc721Details, erc20Details, erc1155Details, gasTokenAmount);
        require(erc721Details.length + erc20Details.tokenAddrs.length + erc1155Details.length +  gasTokenAmount > 0,"No Assets");
        require(
            msg.value == createFees + gasTokenAmount,
            "Insufficient Creating Fee"
        );

        INFTSwapBoxWhitelist(NFTSwapBoxWhitelist)._checkAssets(
            erc721Details,
            erc20Details,
            erc1155Details,
            msg.sender,
            NFTSwapBoxAssets
        );

        INFTSwapBoxAssets(NFTSwapBoxAssets)._transferAssetsHelper(
            erc721Details,
            erc20Details,
            erc1155Details,
            msg.sender,
            NFTSwapBoxAssets,
            true
        );

        payable(withdrawOwner).transfer(createFees);


        _itemCounter++;

        SwapBox storage box = swapBoxes[_itemCounter];
        box.id = _itemCounter;
        box.erc20Tokens = erc20Details;
        box.owner = msg.sender;
        box.state = State.Initiated;
        box.createdTime = block.timestamp;
        box.gasTokenAmount = gasTokenAmount;
        for (uint256 i = 0; i < erc721Details.length; i++) {
            box.erc721Tokens.push(erc721Details[i]);
        }
        for (uint256 i = 0; i < erc1155Details.length; i++) {
            box.erc1155Tokens.push(erc1155Details[i]);
        }

        emit SwapBoxState(
            box
        );
    }

    // Update the Box to Waiting_for_offers state
    function toWaitingForOffers(uint256 boxID)
        public
        payable
        isOpenForSwap
        nonReentrant
    {
        require(
            swapBoxes[boxID].owner == msg.sender,
            "only Owner of SwapBox"
        );
        require(
            swapBoxes[boxID].state == State.Initiated,
            "Not Allowed"
        );

        _caculateSwapFees(boxID);
        uint256 boxroyaltyFees = 0 ;
        for (uint256 i = 0; i < swapBoxes[boxID].boxRoyaltyFee.length; i++){
            boxroyaltyFees += swapBoxes[boxID].boxRoyaltyFee[i].feeAmount;
        }
        require(msg.value == swapConstantFees[1] + swapBoxes[boxID].nftSwapFee + swapBoxes[boxID].gasTokenFee + boxroyaltyFees, "Insufficient Listing Fee");
        
        INFTSwapBoxAssets(NFTSwapBoxAssets)._transferERC20Fee(swapBoxes[boxID].erc20Fees, msg.sender, NFTSwapBoxAssets, true);
        
        swapBoxes[boxID].state = State.Waiting_for_offers;

        payable(withdrawOwner).transfer(swapConstantFees[1]);
        emit SwapBoxState(
            swapBoxes[boxID]
        );
    }
    // update the Box to Offer state
    function toOffer(uint256 boxID) public payable isOpenForSwap nonReentrant {
        require(
            swapBoxes[boxID].owner == msg.sender,
            "only Owner of SwapBox"
        );
        require(
            swapBoxes[boxID].state == State.Initiated,
            "Not Allowed"
        );

        _caculateSwapFees(boxID);

        uint256 boxroyaltyFees = 0 ;
        for (uint256 i = 0; i < swapBoxes[boxID].boxRoyaltyFee.length; i++){
            boxroyaltyFees += swapBoxes[boxID].boxRoyaltyFee[i].feeAmount;
        }

        require(msg.value == swapBoxes[boxID].nftSwapFee + swapBoxes[boxID].gasTokenFee + boxroyaltyFees, "Insufficient Offer Fee");
        INFTSwapBoxAssets(NFTSwapBoxAssets)._transferERC20Fee(swapBoxes[boxID].erc20Fees, msg.sender, NFTSwapBoxAssets, true);

        swapBoxes[boxID].state = State.Offered;

        emit SwapBoxState(
            swapBoxes[boxID]
        );
    }
    // Destroy Box. all assets back to owner's wallet
    function destroyBox(uint256 boxID)
        public
        isOpenForSwap
        nonReentrant
    {
        require(
            swapBoxes[boxID].state == State.Initiated,
            "Not Allowed"
        );
        require(
            swapBoxes[boxID].owner == msg.sender,
            "only Owner of SwapBox"
        );

        swapBoxes[boxID].state = State.Destroyed;

        INFTSwapBoxAssets(NFTSwapBoxAssets)._transferAssetsHelper(
            swapBoxes[boxID].erc721Tokens,
            swapBoxes[boxID].erc20Tokens,
            swapBoxes[boxID].erc1155Tokens,
            NFTSwapBoxAssets,
            msg.sender,
            false
        );
        if (swapBoxes[boxID].gasTokenAmount > 0) {
            payable(msg.sender).transfer(swapBoxes[boxID].gasTokenAmount);
        }

        emit SwapBoxState(
            swapBoxes[boxID]
        );
    }
    // Link your Box to other's waiting Box. Equal to offer to other Swap Box
    function linkBox(uint256 listBoxID, uint256 offerBoxID)
        public
        payable
        isOpenForSwap
        nonReentrant
    {
        require(openSwap, "not opended");
        require(
            swapBoxes[offerBoxID].state == State.Offered,
            "Not Allowed"
        );
        require(
            swapBoxes[offerBoxID].owner == msg.sender,
            "only Owner of SwapBox"
        );
        require(
            _existBoxID(swapBoxes[listBoxID], offerBoxID, true) == false,
            "already linked"
        );

        require(
            swapBoxes[listBoxID].state == State.Waiting_for_offers,
            "not Waiting_for_offer State"
        );
        require(msg.value == swapConstantFees[2], "Insufficient Fee for making an offer");

        payable(withdrawOwner).transfer(swapConstantFees[2]);
        
        _putSwapOffer(offerBoxID, listBoxID, true);
        _putSwapOffer(listBoxID, offerBoxID, true);

        emit SwapBoxOffer(listBoxID, offerBoxID);
    }

    // Swaping Box. Owners of Each Swapbox should be exchanged
    function swapBox(uint256 listBoxID, uint256 offerBoxID)
        public
        isOpenForSwap
        nonReentrant
    {
        require(
            swapBoxes[listBoxID].owner == msg.sender,
            "only Owner of SwapBox"
        );
        require(
            swapBoxes[listBoxID].state == State.Waiting_for_offers,
            "Not Allowed"
        );
        require(
            swapBoxes[offerBoxID].state == State.Offered,
            "Not offered"
        );
        require(
            _existBoxID(swapBoxes[listBoxID], offerBoxID, true),
            "not exist or active"
        );


        swapBoxes[listBoxID].owner = swapBoxes[offerBoxID].owner;
        swapBoxes[listBoxID].state = State.Initiated;
        delete swapBoxes[listBoxID].offers;

        swapBoxes[offerBoxID].owner = msg.sender;
        swapBoxes[offerBoxID].state = State.Initiated;
        delete swapBoxes[offerBoxID].offers;

        _transferSwapFees(swapBoxes[listBoxID].nftSwapFee, swapBoxes[listBoxID].gasTokenFee, swapBoxes[listBoxID].erc20Fees, swapBoxes[listBoxID].boxRoyaltyFee, withdrawOwner, true);
        _transferSwapFees(swapBoxes[offerBoxID].nftSwapFee, swapBoxes[offerBoxID].gasTokenFee, swapBoxes[offerBoxID].erc20Fees, swapBoxes[offerBoxID].boxRoyaltyFee, withdrawOwner, true);
        INFTSwapBoxHistory(NFTSwapBoxHistory).addHistoryUserSwapFees(_historyCounter, swapBoxes[listBoxID],swapBoxes[offerBoxID]);
        emit Swaped(
            _historyCounter,
            listBoxID,
            swapBoxes[listBoxID],
            offerBoxID,
            swapBoxes[offerBoxID]
        );
        _historyCounter++;
    }
    // Cancel Listing. Box's state should be from Waiting_for_Offers to Initiate
    function deListBox(uint256 listBoxID) public payable isOpenForSwap nonReentrant {
        require(
            swapBoxes[listBoxID].owner == msg.sender,
            "only Owner of SwapBox"
        );
        require(
            swapBoxes[listBoxID].state == State.Waiting_for_offers,
            "Not Allowed"
        );
        uint256 offersCount = 0;
        for (uint256 i = 0; i < swapBoxes[listBoxID].offers.length; i++) {
            if(swapBoxes[listBoxID].offers[i].active == true)
                offersCount++;
        }
        require(msg.value == offersCount * swapConstantFees[3], "Insufficient Fee for deListing");

        for (uint256 i = 0; i < swapBoxes[listBoxID].offers.length; i++) {
            if (
                swapBoxes[listBoxID].offers[i].active &&
                _existBoxID(
                    swapBoxes[swapBoxes[listBoxID].offers[i].boxID],
                    listBoxID,
                    true
                )
            ) {
                _putSwapOffer(
                    swapBoxes[listBoxID].offers[i].boxID,
                    listBoxID,
                    false
                );
            }
        }
        
        _transferSwapFees(swapBoxes[listBoxID].nftSwapFee, swapBoxes[listBoxID].gasTokenFee, swapBoxes[listBoxID].erc20Fees, swapBoxes[listBoxID].boxRoyaltyFee, msg.sender, false);
        emit SwapBoxDeList(
            listBoxID,
            State.Initiated,
            swapBoxes[listBoxID].offers
        );

        swapBoxes[listBoxID].state = State.Initiated;
        delete swapBoxes[listBoxID].offers;
    }
    // Cancel Offer. Box's state should be from Offered to Initiate
    function deOffer(uint256 offerBoxID) public isOpenForSwap nonReentrant {
        require(
            swapBoxes[offerBoxID].owner == msg.sender,
            "only Owner of SwapBox"
        );
        require(
            swapBoxes[offerBoxID].state == State.Offered,
            "Not Allowed"
        );

        for (uint256 i = 0; i < swapBoxes[offerBoxID].offers.length; i++) {
            if (
                swapBoxes[offerBoxID].offers[i].active &&
                _existBoxID(
                    swapBoxes[swapBoxes[offerBoxID].offers[i].boxID],
                    offerBoxID,
                    true
                )
            ) {
                _putSwapOffer(
                    swapBoxes[offerBoxID].offers[i].boxID,
                    offerBoxID,
                    false
                );
            }
        }

        _transferSwapFees(swapBoxes[offerBoxID].nftSwapFee, swapBoxes[offerBoxID].gasTokenFee, swapBoxes[offerBoxID].erc20Fees, swapBoxes[offerBoxID].boxRoyaltyFee, msg.sender,false);

        emit SwapBoxDeOffer(
            offerBoxID,
            State.Initiated,
            swapBoxes[offerBoxID].offers
        );

        swapBoxes[offerBoxID].state = State.Initiated;
        delete swapBoxes[offerBoxID].offers;
    }
    // WithDraw offer from linked offer
    function withDrawOffer(uint256 listBoxID, uint256 offerBoxID)
        public
        isOpenForSwap
        nonReentrant
    {
        require(
            swapBoxes[offerBoxID].owner == msg.sender,
            "only Owner of SwapBox"
        );
        require(
            swapBoxes[offerBoxID].state == State.Offered,
            "Not Allowed"
        );
        require(
            _existBoxID(swapBoxes[listBoxID], offerBoxID, true),
            "not linked"
        );
        require(
            _existBoxID(swapBoxes[offerBoxID], listBoxID, true),
            "not linked"
        );

        _putSwapOffer(listBoxID, offerBoxID, false);
        _putSwapOffer(offerBoxID, listBoxID, false);

        emit SwapBoxWithDrawOffer(listBoxID, offerBoxID);
    }
    /**
     * Get Swap Box by Index
     */
    function getBoxByIndex(uint256 listBoxID)
        public
        view
        returns (SwapBox memory)
    {
        return swapBoxes[listBoxID];
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
pragma solidity ^0.8.15;

interface INFTSwap {

    event SwapBoxState (
        SwapBox box
    );

    event SwapBoxOffer(
        uint256 listSwapBoxID,
        uint256 offerSwapBoxID
    );

    event SwapBoxWithDrawOffer(
        uint256 listSwapBoxID,
        uint256 offerSwapBoxID
    );

    event SwapBoxDeList(
        uint256 listSwapBoxID,
        State state,
        BoxOffer[] offers
    );

    event SwapBoxDeOffer(
        uint256 offerSwapBoxID,
        State state,
        BoxOffer[] offers
    );

    event Swaped (
        uint256 historyID,
        uint256 listID,
        SwapBox listBox,
        uint256 offerID,
        SwapBox offerBox
    );

    struct ERC20Details {
        address[] tokenAddrs;
        uint256[] amounts;
    }
    struct ERC721Details {
        address tokenAddr;
        uint256[] ids;
    }
    struct ERC1155Details {
        address tokenAddr;
        uint256[] ids;
        uint256[] amounts;
    }

    struct BoxOffer {
        uint256 boxID;
        bool active;
    }

    struct ERC20Fee {
        address tokenAddress;
        uint256 feeAmount;
    }

    struct RoyaltyFee {
        address reciever;
        uint256 feeAmount;
    }
    
    struct SwapBox {
        uint256 id;
        address owner;
        ERC721Details[] erc721Tokens;
        ERC20Details erc20Tokens;
        ERC1155Details[] erc1155Tokens;
        uint256 gasTokenAmount;
        uint256 createdTime;
        State state;
        BoxOffer[] offers;
        uint256 nftSwapFee;
        ERC20Fee[] erc20Fees;
        uint256 gasTokenFee;
        RoyaltyFee[] boxRoyaltyFee;
    }

    struct SwapBoxConfig {
        bool usingERC721WhiteList;
        bool usingERC1155WhiteList;
        uint256 NFTTokenCount;
        uint256 ERC20TokenCount;
    }

    struct UserTotalSwapFees {
        address owner;
        uint256 nftFees;
        ERC20Fee[] totalERC20Fees;
    }

    struct SwapHistory {
        uint256 id;
        uint256 listId;
        address listOwner;
        uint256 offerId;
        address offerOwner;
        uint256 swapedTime;
    }

    

    enum State {
        Initiated,
        Waiting_for_offers,
        Offered,
        Destroyed
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./INFTSwap.sol";

interface INFTSwapBoxWhitelist is INFTSwap {

    function _checkAssets(
        ERC721Details[] calldata,
        ERC20Details calldata,
        ERC1155Details[] calldata,
        address,
        address
    ) external view;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./INFTSwap.sol";
interface INFTSwapBoxFees is INFTSwap {

    function _checkCreatingBoxFees(
        uint256,
        ERC721Details[] calldata,
        ERC20Details calldata,
        ERC1155Details[] calldata,
        uint256
    ) external pure returns(uint256);


    function _checkERC20Fee(
        ERC20Details calldata,
        address
    ) external view returns(ERC20Fee[] memory);

    function _checkGasTokenFee(
        uint256,
        address
    ) external view returns(uint256);

    function _checkNFTFee(
        ERC721Details[] calldata,
        ERC1155Details[] calldata,
        address
    ) external view returns(uint256);

    function _checkRoyaltyFee(
        ERC721Details[] calldata,
        ERC1155Details[] calldata
    ) external view returns(RoyaltyFee[] memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./INFTSwap.sol";

interface INFTSwapBoxAssets is INFTSwap {
    
    function _transferERC20Fee(ERC20Fee[] calldata, address, address, bool) external;
    function _transferAssetsHelper(ERC721Details[] calldata, ERC20Details calldata, ERC1155Details[] calldata, address, address, bool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./INFTSwap.sol";

interface INFTSwapBoxHistory is INFTSwap {
    function addHistoryUserSwapFees(uint256, SwapBox memory, SwapBox memory) external;
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