// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTSwapBox is 
  ReentrancyGuard,
  Ownable
{
    address payable public swapOwner;

    using Counters for Counters.Counter;
    Counters.Counter private _itemCounter;

    uint256[] public swapFees = [0.01 ether, 0.02 ether, 0.01 ether, 0.01 ether];

    bool openSwap = false;

    struct ERC20Details {
        address[] tokenAddrs;
        uint256[] amounts;
    }

    struct ERC721Details {
        address tokenAddr;
        uint256[] ids;
    }

    enum State { Initiated, Waiting_for_offers, Offered, Destroyed }

    struct BoxOffer {
        uint256 boxID;
        bool active;
    }

    struct SwapBox {
        uint256 id;
        address owner;
        ERC721Details[] erc721Tokens;
        ERC20Details erc20Tokens;
        uint256 createdTime;
        State state;
        // this shows the offered ID lists If this box state is waiting
        // this shows the waiting ID lists If this box state is offer
        BoxOffer[] offers;
    }

    address[] public whitelistERC20Tokens;
    address[] public whitelistERC721Tokens;
    mapping(uint256 => SwapBox) private swapBoxes;

    event SwapBoxState (
        uint256 swapItemID,
        address owner,
        State state,
        uint256 createdTime,
        uint256 updateTime,
        ERC721Details[] erc721Tokens,
        ERC20Details erc20Tokens
    );

    event Swaped (
        uint256 listID,
        address listOwner,
        uint256 offerID,
        address offerOwner
    );

    constructor() {
        swapOwner = payable(msg.sender);
    }

    /**
     * Check the swap is active
     */
    modifier isOpenForSwap() {
        require(openSwap, "Swap is not allowed");
        _;
    }

    /**
     * Set the Swap state
     */
    function setSwapState(bool _new) external onlyOwner {
        openSwap = _new;
    }

    /**
     * Set the Swap Owner Address
     */
    function setSwapOwner(address swapper) external onlyOwner {
        swapOwner = payable(swapper);
    }

    /**
     * Set SwapContract Fees
     */
    function setSwapPrices(uint256[] memory fees) external onlyOwner {
        swapFees = fees;
    }

    /**
     * Get SwapContract Fees
     */
    function getSwapPrices() public view returns (uint256[] memory) {
        return swapFees;
    }

    /**
     * Add whitelist ERC20 Token
     */
    function addWhiteListToken(address erc20Token) external onlyOwner {
        require(validateWhiteListERC20Token(erc20Token) == false, "Exist Token");
        whitelistERC20Tokens.push(erc20Token);
    }

    /**
     * Get whitelist ERC20 Tokens
     */
    function getERC20WhiteListTokens() public view returns (address[] memory) {
        return whitelistERC20Tokens;
    }

    /**
     * Remove From ERC20 Whitelist
     */
    function removeFromERC20WhiteList(uint256 index) external onlyOwner {
        require(index < whitelistERC20Tokens.length, "Invalid element");
        whitelistERC20Tokens[index] = whitelistERC20Tokens[whitelistERC20Tokens.length - 1];
        whitelistERC20Tokens.pop();
    }

    /**
     * Add whitelist ERC721 Tokens
     */
    function addWhiliteListERC721Token(address erc721Token) external onlyOwner {
        require(validateWhiteListERC721Token(erc721Token) == false, "Exist Token");
        whitelistERC721Tokens.push(erc721Token);
    }

    /**
     * Get Whitelist ERC721 Tokens
     */
    function getERC721WhiteListTokens() public view returns (address[] memory) {
        return whitelistERC721Tokens;
    }

    /**
     * Remove From ERC721 Whitelist
     */
    function removeFromERC721WhiteList(uint256 index) external onlyOwner {
        require(index < whitelistERC721Tokens.length, "Invalid element");
        whitelistERC721Tokens[index] = whitelistERC721Tokens[whitelistERC721Tokens.length - 1];
        whitelistERC721Tokens.pop();
    }

    /**
     * Checking whitelist ERC20 Token
     */
    function validateWhiteListERC20Token(
        address erc20Token
    ) public view returns(bool) {
        for (uint256 i = 0; i < whitelistERC20Tokens.length; i++) {
            if (whitelistERC20Tokens[i] == erc20Token) {
                return true;
            }
        }

        return false;
    }

    /**
     * Checking whitelist ERC721 Token
     */
    function validateWhiteListERC721Token(
        address erc721Token
    ) public view returns(bool) {
        for (uint256 i = 0; i < whitelistERC721Tokens.length; i++) {
            if (whitelistERC721Tokens[i] == erc721Token) {
                return true;
            }
        }

        return false;
    }

    /**
     * Destroy All SwapBox
     * Emergency Function
     */
    function destroyAllSwapBox() external onlyOwner {
        uint256 total = _itemCounter.current();
        for (uint256 i = 1; i <= total; i++) {
            swapBoxes[i].state = State.Destroyed;

            _returnAssetsHelper(
                swapBoxes[i].erc721Tokens,
                swapBoxes[i].erc20Tokens,
                address(this),
                swapBoxes[i].owner
            );
        }
    }

    /**
     * WithDraw fees
     */
    function withDraw() external onlyOwner {
        uint balance = address(this).balance;
        swapOwner.transfer(balance);
    }

    /**
     * Checking the assets
     */
    function _checkAssets(
        ERC721Details[] memory erc721Details,
        ERC20Details memory erc20Details,
        address offer
    ) internal view{
        for (uint256 i = 0; i < erc721Details.length; i++) {
            require(validateWhiteListERC721Token(erc721Details[i].tokenAddr), "Not Allowed ERC721 Token");
            require(erc721Details[i].ids.length > 0, "Non included ERC721 token");

            for (uint256 j = 0; j < erc721Details[i].ids.length; j++) {
                require(IERC721(erc721Details[i].tokenAddr).getApproved(erc721Details[i].ids[j]) == address(this), "ERC721 tokens must be approved to swap contract");
            }
        }

        // check duplicated token address
        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            uint256 tokenCount = 0;
            for (uint256 j = 0; j < erc20Details.tokenAddrs.length; j++) {
                if (erc20Details.tokenAddrs[i] == erc20Details.tokenAddrs[j]) {
                    tokenCount ++;
                }
            }

            require(tokenCount == 1, "Invalid ERC20 tokens");
        }

        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            require(validateWhiteListERC20Token(erc20Details.tokenAddrs[i]), "Not Allowed ERC20 Tokens");
            require(IERC20(erc20Details.tokenAddrs[i]).allowance(offer, address(this)) >= erc20Details.amounts[i], "ERC20 tokens must be approved to swap contract");
            require(IERC20(erc20Details.tokenAddrs[i]).balanceOf(offer) >= erc20Details.amounts[i], "Insufficient ERC20 tokens");
        }
    }

    /**
     * Transfer assets to Swap Contract
     */
    function _transferAssetsHelper(
        ERC721Details[] memory erc721Details,
        ERC20Details memory erc20Details,
        address from,
        address to
    ) internal {
        for (uint256 i = 0; i < erc721Details.length; i++) {
            for (uint256 j = 0; j < erc721Details[i].ids.length; j++) {
                IERC721(erc721Details[i].tokenAddr).transferFrom(
                    from,
                    to,
                    erc721Details[i].ids[j]
                );
            }
        }

        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            IERC20(erc20Details.tokenAddrs[i]).transferFrom(from, to, erc20Details.amounts[i]);
        }
    }

    /**
     * Return assets to holders
     * ERC20 requires approve from contract to holder
     */
    function _returnAssetsHelper(
        ERC721Details[] memory erc721Details,
        ERC20Details memory erc20Details,
        address from,
        address to
    ) internal {
        for (uint256 i = 0; i < erc721Details.length; i++) {
            for (uint256 j = 0; j < erc721Details[i].ids.length; j++) {
                IERC721(erc721Details[i].tokenAddr).transferFrom(
                    from,
                    to,
                    erc721Details[i].ids[j]
                );
            }
        }

        for (uint256 i = 0; i < erc20Details.tokenAddrs.length; i++) {
            IERC20(erc20Details.tokenAddrs[i]).transfer(to, erc20Details.amounts[i]);
        }
    }

    /**
     * Checking the exist boxID
     * If checkingActive is true, it will check activity
     */
    function _existBoxID(
        SwapBox memory box,
        uint256 boxID,
        bool checkingActive
    ) internal pure returns (bool){
        for (uint256 i = 0; i < box.offers.length; i++) {
            if (checkingActive) {
                if (checkingActive && box.offers[i].boxID == boxID && box.offers[i].active) {
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

    /**
     * Insert & Update the SwapOffer to Swap Box
     * Set active value of Swap Offer
     */
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

        swapBoxes[listID].offers.push(
            BoxOffer (
                boxID,
                active
            )
        );
    }

    /**
     * Create Swap Box
     * Warning User needs to approve assets before list
     */
    function createBox(
        ERC721Details[] memory erc721Details,
        ERC20Details memory erc20Details
    ) public payable isOpenForSwap nonReentrant {
        require(erc721Details.length > 0, "SwapItems must include ERC721");

        require(msg.value >= swapFees[0], "Insufficient Creating Box Fee");

        _checkAssets(erc721Details, erc20Details, msg.sender);
        _transferAssetsHelper(erc721Details, erc20Details, msg.sender, address(this));

        _itemCounter.increment();
        uint256 id = _itemCounter.current();

        SwapBox storage box = swapBoxes[id];
        box.id = id;
        box.erc20Tokens = erc20Details;
        box.owner = msg.sender;
        box.state = State.Initiated;
        box.createdTime = block.timestamp;
        for (uint256 i = 0; i < erc721Details.length; i++) {
            box.erc721Tokens.push(erc721Details[i]);
        }

        emit SwapBoxState(
            id,
            msg.sender,
            State.Initiated,
            block.timestamp,
            block.timestamp,
            erc721Details,
            erc20Details
        );
    }

    /**
     * Update the Box to Waiting_for_offers state
     */
    function toWaitingForOffers(
        uint256 boxID
    ) public payable isOpenForSwap nonReentrant {
        require(swapBoxes[boxID].owner == msg.sender, "Allowed to only Owner of SwapBox");
        require(swapBoxes[boxID].state == State.Initiated, "Not Allowed Operation");

        require(msg.value >= swapFees[1], "Insufficient Listing Fee");

        swapBoxes[boxID].state = State.Waiting_for_offers;

        emit SwapBoxState(
            boxID,
            msg.sender,
            State.Waiting_for_offers,
            swapBoxes[boxID].createdTime,
            block.timestamp,
            swapBoxes[boxID].erc721Tokens,
            swapBoxes[boxID].erc20Tokens
        );
    }

    /**
     * update the Box to Offer state
     */
    function toOffer(
        uint256 boxID
    ) public payable isOpenForSwap nonReentrant {
        require(swapBoxes[boxID].owner == msg.sender, "Allowed to only Owner of SwapBox");
        require(swapBoxes[boxID].state == State.Initiated, "Not Allowed Operation");

        require(msg.value >= swapFees[2], "Insufficient Offer Fee");

        swapBoxes[boxID].state = State.Offered;

        emit SwapBoxState(
            boxID,
            msg.sender,
            State.Offered,
            swapBoxes[boxID].createdTime,
            block.timestamp,
            swapBoxes[boxID].erc721Tokens,
            swapBoxes[boxID].erc20Tokens
        );
    }

    /**
     * Destroy Box
     * all assets back to owner's wallet
     */
    function destroyBox(
        uint256 boxID
    ) public payable isOpenForSwap nonReentrant {
        require(swapBoxes[boxID].state == State.Initiated, "Not Allowed Operation");
        require(swapBoxes[boxID].owner == msg.sender, "Allowed to only Owner of SwapBox");

        require(msg.value >= swapFees[3], "Insufficient Offer Fee");
        
        swapBoxes[boxID].state = State.Destroyed;

        _returnAssetsHelper(
            swapBoxes[boxID].erc721Tokens,
            swapBoxes[boxID].erc20Tokens,
            address(this),
            msg.sender
        );

        emit SwapBoxState(
            boxID,
            msg.sender,
            State.Destroyed,
            swapBoxes[boxID].createdTime,
            block.timestamp,
            swapBoxes[boxID].erc721Tokens,
            swapBoxes[boxID].erc20Tokens
        );
    }

    /**
     * Link your Box to other's waiting Box
     * Equal to offer to other Swap Box
     */
    function linkBox(
        uint256 listBoxID,
        uint256 offerBoxID
    ) public isOpenForSwap nonReentrant {
        require(openSwap, "Swap is not opended");
        require(swapBoxes[offerBoxID].state == State.Offered, "Not Allowed Operation");
        require(swapBoxes[offerBoxID].owner == msg.sender, "Allowed to only Owner of SwapBox");
        require(_existBoxID(swapBoxes[listBoxID], offerBoxID, true) == false, "This box is already linked");

        require(swapBoxes[listBoxID].state == State.Waiting_for_offers, "This Box is not Waiting_for_offer State");

        _putSwapOffer(offerBoxID, listBoxID, true);
        _putSwapOffer(listBoxID, offerBoxID, true);

        emit SwapBoxState(
            offerBoxID,
            msg.sender,
            State.Offered,
            swapBoxes[offerBoxID].createdTime,
            block.timestamp,
            swapBoxes[offerBoxID].erc721Tokens,
            swapBoxes[offerBoxID].erc20Tokens
        );
    }

    /**
     * Swaping Box
     * Owners of Each Swapbox should be exchanged
     */
    function swapBox(
        uint256 listBoxID,
        uint256 offerBoxID
    ) public isOpenForSwap nonReentrant {
        require(swapBoxes[listBoxID].owner == msg.sender, "Allowed to only Owner of SwapBox");
        require(swapBoxes[listBoxID].state == State.Waiting_for_offers, "Not Allowed Operation");
        require(swapBoxes[offerBoxID].state == State.Offered, "Not offered Swap Box");
        require(_existBoxID(swapBoxes[listBoxID], offerBoxID, true), "This box is not exist or active");

        swapBoxes[listBoxID].owner = swapBoxes[offerBoxID].owner;
        swapBoxes[listBoxID].state = State.Initiated;
        delete swapBoxes[listBoxID].offers;
        
        swapBoxes[offerBoxID].owner = msg.sender;
        swapBoxes[offerBoxID].state = State.Initiated;
        delete swapBoxes[offerBoxID].offers;

        emit SwapBoxState(
            listBoxID,
            swapBoxes[listBoxID].owner,
            State.Initiated,
            swapBoxes[listBoxID].createdTime,
            block.timestamp,
            swapBoxes[listBoxID].erc721Tokens,
            swapBoxes[listBoxID].erc20Tokens
        );

        emit SwapBoxState(
            offerBoxID,
            swapBoxes[offerBoxID].owner,
            State.Initiated,
            swapBoxes[offerBoxID].createdTime,
            block.timestamp,
            swapBoxes[offerBoxID].erc721Tokens,
            swapBoxes[offerBoxID].erc20Tokens
        );

        emit Swaped(
            listBoxID,
            swapBoxes[listBoxID].owner,
            offerBoxID,
            swapBoxes[offerBoxID].owner
        );
    }

    /**
     * Cancel Listing
     * Box's state should be from Waiting_for_Offers to Initiate
     */
    function deListBox(
        uint256 listBoxID
    ) public isOpenForSwap nonReentrant {
        require(swapBoxes[listBoxID].owner == msg.sender, "Allowed to only Owner of SwapBox");
        require(swapBoxes[listBoxID].state == State.Waiting_for_offers, "Not Allowed Operation");

        for(uint256 i = 0; i < swapBoxes[listBoxID].offers.length; i++) {
            if (swapBoxes[listBoxID].offers[i].active && _existBoxID(swapBoxes[swapBoxes[listBoxID].offers[i].boxID], listBoxID, true)) {
                _putSwapOffer(swapBoxes[listBoxID].offers[i].boxID, listBoxID, false);
            }
        }

        swapBoxes[listBoxID].state = State.Initiated;
        delete swapBoxes[listBoxID].offers;
        
        emit SwapBoxState(
            listBoxID,
            msg.sender,
            State.Initiated,
            swapBoxes[listBoxID].createdTime,
            block.timestamp,
            swapBoxes[listBoxID].erc721Tokens,
            swapBoxes[listBoxID].erc20Tokens
        );
    }

    /**
     * Cancel Offer
     * Box's state should be from Offered to Initiate
     */
    function deOffer(
        uint256 offerBoxID
    ) public isOpenForSwap nonReentrant {
        require(swapBoxes[offerBoxID].owner == msg.sender, "Allowed to only Owner of SwapBox");
        require(swapBoxes[offerBoxID].state == State.Offered, "Not Allowed Operation");

        for(uint256 i = 0; i < swapBoxes[offerBoxID].offers.length; i++) {
            if (swapBoxes[offerBoxID].offers[i].active && _existBoxID(swapBoxes[swapBoxes[offerBoxID].offers[i].boxID], offerBoxID, true)) {
                _putSwapOffer(swapBoxes[offerBoxID].offers[i].boxID, offerBoxID, false);
            }
        }

        swapBoxes[offerBoxID].state = State.Initiated;
        delete swapBoxes[offerBoxID].offers;

        emit SwapBoxState(
            offerBoxID,
            msg.sender,
            State.Initiated,
            swapBoxes[offerBoxID].createdTime,
            block.timestamp,
            swapBoxes[offerBoxID].erc721Tokens,
            swapBoxes[offerBoxID].erc20Tokens
        );
    }

    /**
     * WithDraw offer from linked offer
     */
    function deLink(
        uint256 listBoxID,
        uint256 offerBoxID
    ) public isOpenForSwap nonReentrant {
        require(swapBoxes[offerBoxID].owner == msg.sender, "Allowed to only Owner of SwapBox");
        require(swapBoxes[offerBoxID].state == State.Offered, "Not Allowed Operation");
        require(_existBoxID(swapBoxes[listBoxID], offerBoxID, true), "This box is not linked");
        require(_existBoxID(swapBoxes[offerBoxID], listBoxID, true), "This box is not linked");

        _putSwapOffer(listBoxID, offerBoxID, false);
        _putSwapOffer(offerBoxID, listBoxID, false);

        emit SwapBoxState(
            offerBoxID,
            msg.sender,
            State.Initiated,
            swapBoxes[offerBoxID].createdTime,
            block.timestamp,
            swapBoxes[offerBoxID].erc721Tokens,
            swapBoxes[offerBoxID].erc20Tokens
        );
    }

    /**
     * Get Specific State Swap Boxed by Specific Wallet Address
     */
    function getOwnedSwapBoxes(
        address boxOwner,
        State state
    ) public view returns (SwapBox[] memory) {
        uint256 total = _itemCounter.current();
        uint itemCount = 0;

        for (uint256 i = 1; i <= total; i++) {
            if (swapBoxes[i].owner == boxOwner && swapBoxes[i].state == state) {
                itemCount++;
            }
        }

        SwapBox[] memory boxes = new SwapBox[](itemCount);
        uint256 itemIndex = 0;

        for (uint256 i = 1; i <= total; i++) {
            if (swapBoxes[i].owner == boxOwner && swapBoxes[i].state == state) {
                boxes[itemIndex] = swapBoxes[i];
                itemIndex++;
            }
        }

        return boxes;
    }

    /**
     * Get offered Boxes to specifix box in Waiting_for_offer
     */
    function getOfferedSwapBoxes(
        uint256 listBoxID
    ) public view returns (SwapBox[] memory) {
        uint itemCount = 0;

        if (swapBoxes[listBoxID].state == State.Waiting_for_offers) {
            for (uint256 i = 0; i < swapBoxes[listBoxID].offers.length; i++) {
                if (swapBoxes[listBoxID].offers[i].active && _existBoxID(swapBoxes[swapBoxes[listBoxID].offers[i].boxID], listBoxID, true)) {
                    itemCount++;
                }
            }
        }

        SwapBox[] memory boxes = new SwapBox[](itemCount);
        uint256 itemIndex = 0;

        for (uint256 i = 0; i < swapBoxes[listBoxID].offers.length; i++) {
            if (swapBoxes[listBoxID].offers[i].active && _existBoxID(swapBoxes[swapBoxes[listBoxID].offers[i].boxID], listBoxID, true)) {
                boxes[itemIndex] = swapBoxes[swapBoxes[listBoxID].offers[i].boxID];
                itemIndex++;
            }
        }
    
        return boxes;
    }

    /**
     * Get waiting Boxes what offered Box link to
     */
    function getWaitingSwapBoxes(
        uint256 offerBoxID
    ) public view returns (SwapBox[] memory) {
        uint itemCount = 0;

        if (swapBoxes[offerBoxID].state == State.Offered) {
            for (uint256 i = 0; i < swapBoxes[offerBoxID].offers.length; i++) {
                if (swapBoxes[offerBoxID].offers[i].active && _existBoxID(swapBoxes[swapBoxes[offerBoxID].offers[i].boxID], offerBoxID, true)) {
                    itemCount++;
                }
            }
        }

        SwapBox[] memory boxes = new SwapBox[](itemCount);
        uint256 itemIndex = 0;

        for (uint256 i = 0; i < swapBoxes[offerBoxID].offers.length; i++) {
            if (swapBoxes[offerBoxID].offers[i].active && _existBoxID(swapBoxes[swapBoxes[offerBoxID].offers[i].boxID], offerBoxID, true)) {
                boxes[itemIndex] = swapBoxes[swapBoxes[offerBoxID].offers[i].boxID];
                itemIndex++;
            }
        }
    
        return boxes;
    }

    /**
     * Get Swap Box by Index
     */
    function getBoxByIndex(
        uint256 listBoxID
    ) public view returns (SwapBox memory) {
        return swapBoxes[listBoxID];
    }

    /**
     * Get specific state of Swap Boxes 
     */
    function getBoxesByState(
        State state
    ) public view returns (SwapBox[] memory) {
        uint256 total = _itemCounter.current();
        uint itemCount = 0;

        for (uint256 i = 1; i <= total; i++) {
            if (swapBoxes[i].state == state) {
                itemCount++;
            }
        }

        SwapBox[] memory boxes = new SwapBox[](itemCount);
        uint256 itemIndex = 0;

        for (uint256 i = 1; i <= total; i++) {
            if (swapBoxes[i].state == state) {
                boxes[itemIndex] = swapBoxes[i];
                itemIndex++;
            }
        }

        return boxes;
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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