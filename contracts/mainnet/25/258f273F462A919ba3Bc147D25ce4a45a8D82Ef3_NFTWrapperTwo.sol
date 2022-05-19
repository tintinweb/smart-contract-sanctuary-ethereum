// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IOrignalNFT{
    function purchaseTo(address _to, uint count) external payable returns (uint256 _tokenId);
    function balanceOf(address owner) external view returns (uint256 balance);
}
contract NFTWrapperTwo is Ownable{

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public whitelistAmount;
    mapping(address => uint256) public amountMinted;
    uint256 public maxMint;
    uint256 public maxBalance;
    address public orignalNFT;
    uint256 public mintCost;
    

    constructor(uint256 _maxMint, address _orignalNFT, uint256 _maxBalance, uint256 _mintCost) {

        require(_orignalNFT != address(0), "OrignalNFT cannot be 0 Address");
        maxMint = _maxMint;
        orignalNFT = _orignalNFT;
        maxBalance = _maxBalance;
        mintCost = _mintCost;
    }

    function balanceOf(address _userAddress) external view returns (uint256 balance) {
        if(_userAddress ==  address(this)){
            return 1;
        }
        else{
            return 0;
        }
    }

    function setMaxMints(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    function setOrignalNFT(address _orignalNFT) external onlyOwner {
        require(_orignalNFT != address(0), "OrignalNFT cannot be 0 Address");
        orignalNFT = _orignalNFT;
    }

    function setMaxBalance(uint256 _maxBalance) external onlyOwner {
        maxBalance = _maxBalance;
    }

    function withdrawBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function addWhitelist(address[] calldata _whitelist, uint256 _amount) external onlyOwner {
        
        for(uint256 i=0; i<_whitelist.length; i++) {
            address userAddress = _whitelist[i];
            whitelist[userAddress] = true;
            whitelistAmount[userAddress] = _amount;
        }
        
    }

    function setMintCost(uint256 _mintCost) external onlyOwner {
        mintCost = _mintCost;
    }

    function revokeWhitelist(address _whitelist) external onlyOwner {
        whitelist[_whitelist] = false;
    }

    function mint(uint256 _count) external returns (uint256 _tokenId) {
        return mintTo(msg.sender, _count);
    }

    receive() external payable {  }
    
    function mintTo(address _user, uint256 _count) internal returns (uint256 _tokenId){

        require(amountMinted[msg.sender] + _count <= maxMint, "Mint count higher than Max Mint");
        require(amountMinted[msg.sender] + _count <= whitelistAmount[msg.sender], "Mint count higher than WL Mint");
        require(whitelist[msg.sender] == true, "Address not in whitelist");
        require(IOrignalNFT(orignalNFT).balanceOf(_user) <= maxBalance, "Max Balance Exceeded");

        amountMinted[msg.sender] = amountMinted[msg.sender] + _count;
        uint256 totalCost = mintCost * _count;
        return IOrignalNFT(orignalNFT).purchaseTo{value:totalCost}(_user, _count);
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