/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


// File: @openzeppelin/contracts/utils/Context.sol
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


// File: @openzeppelin/contracts/access/Ownable.sol
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol
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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract PeculiarPugs {
    function reveal() public virtual;
    function setCost(uint256 _newCost) public virtual;
    function setNotRevealedURI(string memory _notRevealedURI) public virtual;
    function setBaseURI(string memory _newBaseURI) public virtual;
    function setBaseExtension(string memory _newBaseExtension) public virtual;
    function pause(bool _state) public virtual;
    function withdraw() public payable virtual;
    function mint(uint256 _mintAmount) public payable virtual;
    function cost() public virtual returns(uint256);
    function totalSupply() public virtual returns(uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId) external virtual;
    function transferOwnership(address newOwner) public virtual;
}

abstract contract PeculiarPugsRewards {
    function grantReward(address holder, uint256 tokenId, uint256 amount) external virtual;
    function burnReward(address holder, uint256 tokenId, uint256 amount) external virtual;
    function balanceOf(address account, uint256 id) external virtual returns (uint256);
}


contract RedeemForPugs is Ownable, IERC721Receiver {

    PeculiarPugs pugsContract;
    PeculiarPugsRewards rewardsContract;

    mapping(uint256 => uint256) public rewardTokenDiscount;
    bool public mintRewardActive = true; 
    uint256 public mintRewardTokenId = 1991;
    uint256 public mintRewardQuantity = 1;

    constructor(address pugsAddress, address rewardsAddress) {
        pugsContract = PeculiarPugs(pugsAddress);
        rewardsContract = PeculiarPugsRewards(rewardsAddress);
    }

    receive() external payable { }
    fallback() external payable { }

    function mintWithRewards(uint256 count, uint256[] calldata rewardTokenIds, uint256[] calldata rewardTokenAmounts) external payable {
        require(rewardTokenIds.length == rewardTokenAmounts.length);
        uint256 totalCost = pugsContract.cost() * count;
        uint256 totalDiscount = 0;
        for(uint256 i = 0;i < rewardTokenIds.length;i++) {
            totalDiscount += (rewardTokenDiscount[rewardTokenIds[i]] * rewardTokenAmounts[i]);
        }
        require(totalCost >= totalDiscount);
        require(msg.value >= (totalCost - totalDiscount));
        for(uint256 i = 0;i < rewardTokenIds.length;i++) {
            rewardsContract.burnReward(msg.sender, rewardTokenIds[i], rewardTokenAmounts[i]);
        }
        uint256 startTokenId = pugsContract.totalSupply() + 1;
        uint256 endTokenId = startTokenId + count - 1;
        pugsContract.mint{value: 0}(count);
        for(uint256 tokenId = startTokenId; tokenId <= endTokenId;tokenId++) {
            pugsContract.safeTransferFrom(address(this), msg.sender, tokenId);
        }
    }

    function mintForRewards(uint256 count) external payable {
        uint256 totalCost = pugsContract.cost() * count;
        require(msg.value >= totalCost);
        uint256 startTokenId = pugsContract.totalSupply() + 1;
        uint256 endTokenId = startTokenId + count - 1;
        pugsContract.mint{value: 0}(count);
        for(uint256 tokenId = startTokenId; tokenId <= endTokenId;tokenId++) {
            pugsContract.safeTransferFrom(address(this), msg.sender, tokenId);
        }
        if(mintRewardActive) {
            rewardsContract.grantReward(msg.sender, mintRewardTokenId, mintRewardQuantity * count);
        }
    }

    function ownerMint(uint256 count, address to) external onlyOwner {
        uint256 startTokenId = pugsContract.totalSupply() + 1;
        uint256 endTokenId = startTokenId + count - 1;
        pugsContract.mint{value: 0}(count);
        for(uint256 tokenId = startTokenId; tokenId <= endTokenId;tokenId++) {
            pugsContract.safeTransferFrom(address(this), to, tokenId);
        }
    }

    function onERC721Received(address _operator, address, uint, bytes memory) public virtual override returns (bytes4) {
        // only allow `this` to tranfser token from others
        if (_operator != address(this)) return bytes4(0);
        return IERC721Receiver.onERC721Received.selector;
    }

    function setRewardTokenDiscount(uint256 rewardTokenId, uint256 discount) external onlyOwner {
        rewardTokenDiscount[rewardTokenId] = discount;
    }

    function setMintReward(bool _active, uint256 _tokenId, uint256 _quantity) external onlyOwner {
        mintRewardActive = _active;
        mintRewardTokenId = _tokenId;
        mintRewardQuantity = _quantity;
    }

    function setContractAddresses(address pugsAddress, address rewardsAddress) external onlyOwner {
        pugsContract = PeculiarPugs(pugsAddress);
        rewardsContract = PeculiarPugsRewards(rewardsAddress);
    }

    function reveal() public onlyOwner {
        pugsContract.reveal();
    }
  
    function setCost(uint256 _newCost) public onlyOwner {
        pugsContract.setCost(_newCost);
    }
  
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        pugsContract.setNotRevealedURI(_notRevealedURI);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        pugsContract.setBaseURI(_newBaseURI);
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        pugsContract.setBaseExtension(_newBaseExtension);
    }

    function pause(bool _state) public onlyOwner {
        pugsContract.pause(_state);
    }

    function transferPugsOwnership(address newOwner) public onlyOwner {
        pugsContract.transferOwnership(newOwner);
    }
 
    function withdraw() public payable onlyOwner {
        pugsContract.withdraw();
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}