// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/INFTSwap.sol";

contract NFTSwapBoxFees is Ownable,INFTSwap {

    uint256[] public swapConstantFees = [0.0001 ether, 0.0002 ether, 0.0003 ether, 0.0004 ether, 0.0005 ether];

    uint256 public defaultNFTSwapFee = 0.0001 ether;
    uint256 public defaultTokenSwapPercentage = 200;
    uint256 public defaultGasTokenSwapPercentage = 500;

    mapping(address => uint256) public NFTSwapFee;
    mapping(address => uint256) public RoyaltyFee;
    mapping(address => address) public RoyaltiesReceiver;

    function setDefaultNFTSwapFee(uint256 fee) external onlyOwner {
        require(fee >0 , "fee must be greate than 0");
        defaultNFTSwapFee = fee;
    }

    function setDefaultTokenSwapPercentage(uint256 fee) external onlyOwner {
        require(fee >0 , "fee must be greate than 0");
        defaultTokenSwapPercentage = fee;
    }

    function setDefaultGasTokenSwapPercentage(uint256 fee) external onlyOwner {
        require(fee >0 , "fee must be greate than 0");
        defaultGasTokenSwapPercentage = fee;
    }

    function setNFTSwapFee(address nftAddress, uint256 fee) external onlyOwner {
        require(fee >0 , "fee must be greate than 0");
        NFTSwapFee[nftAddress] = fee;
    }

     function setNFTRoyaltyFee(address nftAddress, uint256 fee, address receiver) external onlyOwner {
        require(fee >0 , "fee must be greate than 0");
        RoyaltyFee[nftAddress] = fee;
        RoyaltiesReceiver[nftAddress] = receiver;
    }

    function getNFTSwapFee(address nftAddress) public view returns(uint256) {
        return NFTSwapFee[nftAddress];
    }

    function getRoyaltyFee(address nftAddress) public view returns(uint256) {
        return RoyaltyFee[nftAddress];
    }

    function _checkCreatingBoxFees(
        ERC721Details[] memory erc721Details,
        ERC20Details memory erc20Details,
        ERC1155Details[] memory erc1155Details,
        uint256 gasTokenAmount
    ) external view returns (uint256) {

        uint256 elementCount = 0;

        for(uint256 i = 0 ; i < erc721Details.length ; i++) {
            elementCount += erc721Details[i].ids.length;
        }

        for(uint256 i = 0 ; i < erc1155Details.length ; i++) {
            elementCount += erc721Details[i].ids.length;
        }

        if(erc20Details.tokenAddrs.length > 0)
            elementCount += erc20Details.tokenAddrs.length;

        if(gasTokenAmount > 0)  
            elementCount++;

        return elementCount * swapConstantFees[0];
    }

    function _checkSwapFee(
        ERC721Details[] memory erc721Details,
        ERC20Details memory erc20Details,
        ERC1155Details[] memory erc1155Details,
        uint256 gasTokenAmount
    ) external view returns(uint256) {
        uint256 fee = 0;

        for(uint256 i = 0 ; i < erc721Details.length; i ++){
            if(NFTSwapFee[erc721Details[i].tokenAddr] > 0)
                fee +=  NFTSwapFee[erc721Details[i].tokenAddr] * erc721Details[i].ids.length * 100;
            else
                fee +=  defaultNFTSwapFee * erc721Details[i].ids.length * 100;
        }

        for(uint256 i = 0 ; i < erc1155Details.length; i ++){
            if(NFTSwapFee[erc1155Details[i].tokenAddr] > 0)
                fee +=  NFTSwapFee[erc1155Details[i].tokenAddr] * erc1155Details[i].ids.length * 100;
            else
                fee +=  defaultNFTSwapFee * erc1155Details[i].ids.length * 100;
        }

        for(uint256 i = 0 ; i < erc20Details.tokenAddrs.length ; i++) {
            fee += erc20Details.amounts[i] * defaultTokenSwapPercentage;
        }

        if(gasTokenAmount > 0) {
            fee += gasTokenAmount * defaultGasTokenSwapPercentage;
        }
        
        return fee;
    }

    function _checkRoyaltyFee(
        ERC721Details[] memory erc721Details,
        ERC1155Details[] memory erc1155Details
    ) external view returns(uint256) {
        uint256 fee = 0;

        for(uint256 i = 0 ; i < erc721Details.length; i ++){
            if(RoyaltyFee[erc721Details[i].tokenAddr] > 0)
                fee +=  RoyaltyFee[erc721Details[i].tokenAddr] * erc721Details[i].ids.length * 100;
        }

        for(uint256 i = 0 ; i < erc1155Details.length; i ++){
            if(NFTSwapFee[erc1155Details[i].tokenAddr] > 0)
                fee +=  RoyaltyFee[erc1155Details[i].tokenAddr] * erc1155Details[i].ids.length * 100;
        }

        return fee;
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