// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interface/IERC20.sol";
import "./interface/IERC721.sol";
import "./interface/IERC1155.sol";
import "./interface/INFTSwap.sol";
import "./interface/INFTSwapBoxWhitelist.sol";
import "./interface/INFTSwapBoxFees.sol";
contract NFTSwapBox is ReentrancyGuard, Ownable, INFTSwap {
    address payable public swapOwner;
    uint256 public _itemCounter;
    uint64[] public swapConstantFees = [0.0001 ether, 0.0002 ether, 0.0003 ether, 0.0004 ether, 0.0005 ether];
    bool openSwap = false;

    address public NFTSwapBoxWhitelist;
    address public NFTSwapBoxFees;

    mapping(uint256 => SwapBox) public swapBoxes;

    constructor() {
        swapOwner = payable(msg.sender);
    }

    modifier isOpenForSwap() {
        require(openSwap, "Swap is not allowed");
        _;
    }


    function setNFTSwap(address nftSwapboxWhiteList) public onlyOwner {
        NFTSwapBoxWhitelist = nftSwapboxWhiteList;
    }

    function setNFTSwapBoxFees(address nftFees) public onlyOwner {
        NFTSwapBoxFees = nftFees;
    }

    function setSwapState(bool _new) external onlyOwner {
        openSwap = _new;
    }

    function setSwapOwner(address swapper) external onlyOwner {
        swapOwner = payable(swapper);
    }

    /// @notice setSwapFee by owner
    /// @param _index for swapFees array
    /// @param _value new fee value for _index
    /// @dev 4 kinds of fee vaule
    /// _index 0: Initiated
    /// _index 1: Waiting_for_offers
    /// _index 2: Offered
    /// _index 3: Destroyed
    function setSwapFee(uint256 _index, uint64 _value) external onlyOwner {
        swapConstantFees[_index] = _value;
    }

    function getSwapPrices() public view returns (uint64[] memory) {
        return swapConstantFees;
    }

    function destroyAllSwapBox() external onlyOwner {
        for (uint256 i = 1; i <= _itemCounter; i++) {
            if (swapBoxes[i].state != State.Destroyed) {
                swapBoxes[i].state = State.Destroyed;

                INFTSwapBoxWhitelist(NFTSwapBoxWhitelist)._returnAssetsHelper(
                    swapBoxes[i].erc721Tokens,
                    swapBoxes[i].erc20Tokens,
                    swapBoxes[i].erc1155Tokens,
                    swapBoxes[i].gasTokenAmount,
                    address(this),
                    swapBoxes[i].owner
                );
            }
        }
    }

    function _existBoxID(
        SwapBox memory box,
        uint256 boxID,
        bool checkingActive
    ) public pure returns (bool) {
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

    function createBox(
        ERC721Details[] memory erc721Details,
        ERC20Details memory erc20Details,
        ERC1155Details[] memory erc1155Details,
        uint256 gasTokenAmount
    ) public payable isOpenForSwap nonReentrant {

        uint256 createFees =  INFTSwapBoxFees(NFTSwapBoxFees)._checkCreatingBoxFees(erc721Details, erc20Details, erc1155Details, gasTokenAmount);
        require(
            msg.value >= createFees + gasTokenAmount,
            "Insufficient Creating Box Fee"
        );

        INFTSwapBoxWhitelist(NFTSwapBoxWhitelist)._checkAssets(
            erc721Details,
            erc20Details,
            erc1155Details,
            msg.sender
        );

        INFTSwapBoxWhitelist(NFTSwapBoxWhitelist)._transferAssetsHelper(
            erc721Details,
            erc20Details,
            erc1155Details,
            msg.sender
        );

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

        swapOwner.transfer(createFees);

        emit SwapBoxState(
            _itemCounter,
            msg.sender,
            State.Initiated,
            block.timestamp,
            block.timestamp,
            gasTokenAmount,
            erc721Details,
            erc20Details,
            erc1155Details
        );
    }

    function toWaitingForOffers(uint256 boxID)
        public
        payable
        isOpenForSwap
        nonReentrant
    {
        require(
            swapBoxes[boxID].owner == msg.sender,
            "Allowed to only Owner of SwapBox"
        );
        require(
            swapBoxes[boxID].state == State.Initiated,
            "Not Allowed Operation"
        );

        uint256 prePaidFee = INFTSwapBoxFees(NFTSwapBoxFees)._checkSwapFee(swapBoxes[boxID].erc721Tokens, swapBoxes[boxID].erc20Tokens, swapBoxes[boxID].erc1155Tokens, swapBoxes[boxID].gasTokenAmount) + INFTSwapBoxFees(NFTSwapBoxFees)._checkRoyaltyFee(swapBoxes[boxID].erc721Tokens, swapBoxes[boxID].erc1155Tokens);

        require(msg.value >= prePaidFee/1000 + swapConstantFees[2], "Insufficient Listing Fee");

        swapBoxes[boxID].state = State.Waiting_for_offers;

        swapOwner.transfer(swapConstantFees[2]);

        emit SwapBoxState(
            boxID,
            msg.sender,
            State.Waiting_for_offers,
            swapBoxes[boxID].createdTime,
            block.timestamp,
            swapBoxes[boxID].gasTokenAmount,
            swapBoxes[boxID].erc721Tokens,
            swapBoxes[boxID].erc20Tokens,
            swapBoxes[boxID].erc1155Tokens
        );
    }

    function toOffer(uint256 boxID) public payable isOpenForSwap nonReentrant {
        require(
            swapBoxes[boxID].owner == msg.sender,
            "Allowed to only Owner of SwapBox"
        );
        require(
            swapBoxes[boxID].state == State.Initiated,
            "Not Allowed Operation"
        );

        uint256 prePaidFee = INFTSwapBoxFees(NFTSwapBoxFees)._checkSwapFee(swapBoxes[boxID].erc721Tokens, swapBoxes[boxID].erc20Tokens, swapBoxes[boxID].erc1155Tokens, swapBoxes[boxID].gasTokenAmount) + INFTSwapBoxFees(NFTSwapBoxFees)._checkRoyaltyFee(swapBoxes[boxID].erc721Tokens, swapBoxes[boxID].erc1155Tokens);

        require(msg.value >= prePaidFee/1000 + swapConstantFees[2], "Insufficient Offer Fee");

        swapBoxes[boxID].state = State.Offered;

        swapOwner.transfer(swapConstantFees[2]);

        emit SwapBoxState(
            boxID,
            msg.sender,
            State.Offered,
            swapBoxes[boxID].createdTime,
            block.timestamp,
            swapBoxes[boxID].gasTokenAmount,
            swapBoxes[boxID].erc721Tokens,
            swapBoxes[boxID].erc20Tokens,
            swapBoxes[boxID].erc1155Tokens
        );
    }

    function destroyBox(uint256 boxID)
        public
        payable
        isOpenForSwap
        nonReentrant
    {
        require(
            swapBoxes[boxID].state == State.Initiated,
            "Not Allowed Operation"
        );
        require(
            swapBoxes[boxID].owner == msg.sender,
            "Allowed to only Owner of SwapBox"
        );

        require(msg.value >= swapConstantFees[3], "Insufficient Offer Fee");

        swapBoxes[boxID].state = State.Destroyed;

        swapOwner.transfer(swapConstantFees[3]);

        INFTSwapBoxWhitelist(NFTSwapBoxWhitelist)._returnAssetsHelper(
            swapBoxes[boxID].erc721Tokens,
            swapBoxes[boxID].erc20Tokens,
            swapBoxes[boxID].erc1155Tokens,
            swapBoxes[boxID].gasTokenAmount,
            address(this),
            msg.sender
        );

        emit SwapBoxState(
            boxID,
            msg.sender,
            State.Destroyed,
            swapBoxes[boxID].createdTime,
            block.timestamp,
            swapBoxes[boxID].gasTokenAmount,
            swapBoxes[boxID].erc721Tokens,
            swapBoxes[boxID].erc20Tokens,
            swapBoxes[boxID].erc1155Tokens
        );
    }

    function linkBox(uint256 listBoxID, uint256 offerBoxID)
        public
        isOpenForSwap
        nonReentrant
    {
        require(openSwap, "Swap is not opended");
        require(
            swapBoxes[offerBoxID].state == State.Offered,
            "Not Allowed Operation"
        );
        require(
            swapBoxes[offerBoxID].owner == msg.sender,
            "Allowed to only Owner of SwapBox"
        );
        require(
            _existBoxID(swapBoxes[listBoxID], offerBoxID, true) == false,
            "This box is already linked"
        );

        require(
            swapBoxes[listBoxID].state == State.Waiting_for_offers,
            "This Box is not Waiting_for_offer State"
        );

        _putSwapOffer(offerBoxID, listBoxID, true);
        _putSwapOffer(listBoxID, offerBoxID, true);

        emit SwapBoxOffer(listBoxID, offerBoxID);
    }

    function swapBox(uint256 listBoxID, uint256 offerBoxID)
        public
        isOpenForSwap
        nonReentrant
    {
        require(
            swapBoxes[listBoxID].owner == msg.sender,
            "Allowed to only Owner of SwapBox"
        );
        require(
            swapBoxes[listBoxID].state == State.Waiting_for_offers,
            "Not Allowed Operation"
        );
        require(
            swapBoxes[offerBoxID].state == State.Offered,
            "Not offered Swap Box"
        );
        require(
            _existBoxID(swapBoxes[listBoxID], offerBoxID, true),
            "This box is not exist or active"
        );

        uint256 swapFees = INFTSwapBoxFees(NFTSwapBoxFees)._checkSwapFee(swapBoxes[listBoxID].erc721Tokens, swapBoxes[listBoxID].erc20Tokens, swapBoxes[listBoxID].erc1155Tokens, swapBoxes[listBoxID].gasTokenAmount) + INFTSwapBoxFees(NFTSwapBoxFees)._checkSwapFee(swapBoxes[offerBoxID].erc721Tokens, swapBoxes[offerBoxID].erc20Tokens, swapBoxes[offerBoxID].erc1155Tokens, swapBoxes[offerBoxID].gasTokenAmount);

        swapOwner.transfer(swapFees/1000);



        swapBoxes[listBoxID].owner = swapBoxes[offerBoxID].owner;
        swapBoxes[listBoxID].state = State.Initiated;
        delete swapBoxes[listBoxID].offers;

        swapBoxes[offerBoxID].owner = msg.sender;
        swapBoxes[offerBoxID].state = State.Initiated;
        delete swapBoxes[offerBoxID].offers;

        emit Swaped(
            listBoxID,
            swapBoxes[listBoxID].owner,
            offerBoxID,
            swapBoxes[offerBoxID].owner
        );
    }

    function deListBox(uint256 listBoxID) public isOpenForSwap nonReentrant {
        require(
            swapBoxes[listBoxID].owner == msg.sender,
            "Allowed to only Owner of SwapBox"
        );
        require(
            swapBoxes[listBoxID].state == State.Waiting_for_offers,
            "Not Allowed Operation"
        );

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

        emit SwapBoxDeList(
            listBoxID,
            State.Initiated,
            swapBoxes[listBoxID].offers
        );

        swapBoxes[listBoxID].state = State.Initiated;
        delete swapBoxes[listBoxID].offers;
    }

    function deOffer(uint256 offerBoxID) public isOpenForSwap nonReentrant {
        require(
            swapBoxes[offerBoxID].owner == msg.sender,
            "Allowed to only Owner of SwapBox"
        );
        require(
            swapBoxes[offerBoxID].state == State.Offered,
            "Not Allowed Operation"
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

        emit SwapBoxDeOffer(
            offerBoxID,
            State.Initiated,
            swapBoxes[offerBoxID].offers
        );

        swapBoxes[offerBoxID].state = State.Initiated;
        delete swapBoxes[offerBoxID].offers;
    }

    function withDrawOffer(uint256 listBoxID, uint256 offerBoxID)
        public
        isOpenForSwap
        nonReentrant
    {
        require(
            swapBoxes[offerBoxID].owner == msg.sender,
            "Allowed to only Owner of SwapBox"
        );
        require(
            swapBoxes[offerBoxID].state == State.Offered,
            "Not Allowed Operation"
        );
        require(
            _existBoxID(swapBoxes[listBoxID], offerBoxID, true),
            "This box is not linked"
        );
        require(
            _existBoxID(swapBoxes[offerBoxID], listBoxID, true),
            "This box is not linked"
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
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
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
pragma solidity ^0.8.15;

interface INFTSwap {

    event SwapBoxState (
        uint256 swapItemID,
        address owner,
        State state,
        uint256 createdTime,
        uint256 updateTime,
        uint256 gasTokenAmount,
        ERC721Details[] erc721Tokens,
        ERC20Details erc20Tokens,
        ERC1155Details[] erc1155Tokens
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
        uint256 listID,
        address listOwner,
        uint256 offerID,
        address offerOwner
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
    }

    struct SwapBoxConfig {
        bool usingERC721WhiteList;
        bool usingERC1155WhiteList;
        uint256 NFTTokenCount;
        uint256 ERC20TokenCount;
    }

    enum State {
        Initiated,
        Waiting_for_offers,
        Offered,
        Destroyed
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./INFTSwap.sol";

interface INFTSwapBoxWhitelist is INFTSwap {
    function _returnAssetsHelper(
        ERC721Details[] calldata,
        ERC20Details calldata,
        ERC1155Details[] calldata,
        uint256,
        address,
        address
    ) external;

    function _checkAssets(
        ERC721Details[] calldata,
        ERC20Details calldata,
        ERC1155Details[] calldata,
        address
    ) external view;

    function _transferAssetsHelper(
        ERC721Details[] calldata,
        ERC20Details calldata,
        ERC1155Details[] calldata,
        address
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./INFTSwap.sol";
interface INFTSwapBoxFees is INFTSwap {

    function _checkCreatingBoxFees(
        ERC721Details[] calldata,
        ERC20Details calldata,
        ERC1155Details[] calldata,
        uint256
    ) external view returns(uint256);

    function _checkSwapFee(
        ERC721Details[] calldata,
        ERC20Details calldata,
        ERC1155Details[] calldata,
        uint256
    ) external view returns(uint256);

    function _checkRoyaltyFee(
        ERC721Details[] calldata,
        ERC1155Details[] calldata
    ) external view returns(uint256);

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