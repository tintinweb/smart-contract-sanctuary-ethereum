// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721{
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
}

contract CheckPass is Ownable {

    address public CheckBirdsNft=0xc597A66d3c37dB76eB0bC08A5bD5908c2beBe489;
    address public CheckBirdsburn=0x0000000000000000000000000000000000000000;
    bool public BurnMintStatus;
    bool public RareBurnMintStatus;

    mapping(uint256 => bool) public rarecheckbirdslist;
    mapping(address => uint256) public burninfos;
    mapping(address => uint256) public rareburninfos;
    constructor() {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Must from real wallet address");
        _;
    }

    function burn(uint256[] memory tokenids) public payable callerIsUser{
        require(BurnMintStatus,"Error: Burn stage closed");
        require(tokenids.length == 3, "Error: Wrong quantity");
        require(burninfos[msg.sender] == 0, "Error: You have only have one chance");
        for (uint i = 0; i < tokenids.length; i++) {
            address owner = IERC721(CheckBirdsNft).ownerOf(tokenids[i]);
            require(msg.sender == owner, "Error: Not ERC721 owner");
            IERC721(CheckBirdsNft).safeTransferFrom(msg.sender,CheckBirdsburn,tokenids[i]);
        }
        burninfos[msg.sender] += 1;
    }

   function rareburn(uint256[] memory tokenids) public payable callerIsUser{
        require(RareBurnMintStatus,"Error: Burn stage closed");
        require(tokenids.length == 3, "Error: Wrong quantity");
        require(rareburninfos[msg.sender] == 0, "Error: You have only have one chance");
        for (uint i = 0; i < tokenids.length; i++) {
            require(rarecheckbirdslist[tokenids[i]],"Error: Not 1/1 Nft");
            address owner = IERC721(CheckBirdsNft).ownerOf(tokenids[i]);
            require(msg.sender == owner, "Error: Not ERC721 owner");
            IERC721(CheckBirdsNft).safeTransferFrom(msg.sender,CheckBirdsburn,tokenids[i]);
        }
        rareburninfos[msg.sender] += 1;
    }


    function setBurnStatus(bool status) external onlyOwner {
        BurnMintStatus = status;
    }

    function setRareBurnStatus(bool status) external onlyOwner {
        RareBurnMintStatus = status;
    }

    function setCheckBirdsNft(address checkbirdsnft) external onlyOwner {
        CheckBirdsNft = checkbirdsnft;
    }

    function setCheckBirdsBurn(address checkbirdsburn) external onlyOwner {
        CheckBirdsburn = checkbirdsburn;
    }

    function setRarecheckbirdslist(uint256[] memory tokenids, bool status) external onlyOwner {
        for (uint256 i; i < tokenids.length; ++i) {
            rarecheckbirdslist[tokenids[i]] = status;
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
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