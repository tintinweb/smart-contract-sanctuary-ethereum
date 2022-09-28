// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/INFTSwap.sol";

contract NFTSwapBoxHistory is Ownable, INFTSwap {

    uint256 _swapFeeCounter = 1;

    mapping(uint256 =>UserTotalSwapFees) public totalSwapFees;
    mapping(uint256 => SwapHistory)  public swapHistory;
    // UserTotalSwapFees[] totalSwapFees;
    // SwapHistory [] swapHistory;

    function _existAddress(address userAddress) internal view returns(bool) {
        for(uint256 i = 0 ; i < _swapFeeCounter ; i++){
            if(totalSwapFees[i].owner == userAddress)
                return true;
        }
        return false;
    }

    function _existERC20Fees(ERC20Fee[] memory historyFee, ERC20Fee[] memory addFees ) internal pure returns(bool) {
        for(uint256 i = 0 ; i < historyFee.length ; i++) {
            for(uint256 j = 0 ; j < addFees.length ; j++) {
                if(historyFee[i].tokenAddress == addFees[j].tokenAddress)
                    return true;
            }
        }
        return false;
    }

    function _addERC20Fees(uint256 index, ERC20Fee[] memory addFees ) internal {
        for(uint256 i = 0 ; i < totalSwapFees[index].totalERC20Fees.length ; i++) {
            for(uint256 j = 0 ; j < addFees.length ; j++) {
                if(totalSwapFees[index].totalERC20Fees[i].tokenAddress == addFees[j].tokenAddress)
                    totalSwapFees[index].totalERC20Fees[i].feeAmount += addFees[j].feeAmount;
            }
        }
    }

    
    function getUserTotalSwapFees(address userAddress) public view returns(UserTotalSwapFees memory) {

        require(_existAddress(userAddress) == true, "No History");
        UserTotalSwapFees memory userFees;
        for(uint256 i = 0 ; i < _swapFeeCounter ; i++){
            if(totalSwapFees[i].owner == userAddress) {
                userFees.owner = totalSwapFees[i].owner;
                userFees.nftFees = totalSwapFees[i].nftFees;
                userFees.totalERC20Fees = totalSwapFees[i].totalERC20Fees;
            }
        }
        return userFees;
    }

    function getSwapHistoryById(uint256 id) public view returns(SwapHistory memory) {
        return swapHistory[id];
    }

    function addHistoryUserSwapFees(uint256 historyId, SwapBox memory listBox, SwapBox memory offerBox) external {
        
        for(uint256 i = 0 ; i < _swapFeeCounter; i++) {
            if(totalSwapFees[i].owner == listBox.owner){

                totalSwapFees[i].nftFees = totalSwapFees[i].nftFees + listBox.nftSwapFee + listBox.gasTokenFee;
                if(_existERC20Fees(totalSwapFees[i].totalERC20Fees, listBox.erc20Fees) == true)
                    _addERC20Fees(i, listBox.erc20Fees);
                else {
                    for(uint256 j = 0 ; j < listBox.erc20Fees.length ; j++){
                        totalSwapFees[i].totalERC20Fees.push(listBox.erc20Fees[j]);
                    }
                }

            } else if(totalSwapFees[i].owner == offerBox.owner) {
                 totalSwapFees[i].nftFees = totalSwapFees[i].nftFees + offerBox.nftSwapFee + offerBox.gasTokenFee;
                 if(_existERC20Fees(totalSwapFees[i].totalERC20Fees, offerBox.erc20Fees) == true)
                    _addERC20Fees(i, offerBox.erc20Fees);
                else {
                    for(uint256 j = 0 ; j < offerBox.erc20Fees.length ; j++){
                        totalSwapFees[i].totalERC20Fees.push(offerBox.erc20Fees[j]);
                    }
                }
            } else {
                UserTotalSwapFees storage listBoxswapFees = totalSwapFees[_swapFeeCounter];
                listBoxswapFees.owner = listBox.owner;
                listBoxswapFees.nftFees = listBox.nftSwapFee + listBox.gasTokenFee;
                for(uint256 j = 0 ; j < listBox.erc20Fees.length ; j++) {
                    listBoxswapFees.totalERC20Fees.push(listBox.erc20Fees[j]);
                }

                _swapFeeCounter++;
                
                UserTotalSwapFees storage offerBoxswapFees = totalSwapFees[_swapFeeCounter];
                offerBoxswapFees.owner = offerBox.owner;
                offerBoxswapFees.nftFees = offerBox.nftSwapFee + offerBox.gasTokenFee;
                for(uint256 j = 0 ; j < offerBox.erc20Fees.length ; j++) {
                    offerBoxswapFees.totalERC20Fees.push(offerBox.erc20Fees[j]);
                }
                _swapFeeCounter++;
            }
        }
        
        SwapHistory storage history = swapHistory[historyId];

        history.id = historyId;
        history.listId = listBox.id;
        history.listOwner = listBox.owner;
        history.offerId = offerBox.id;
        history.offerOwner =  offerBox.owner;
        history.swapedTime = block.timestamp;
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