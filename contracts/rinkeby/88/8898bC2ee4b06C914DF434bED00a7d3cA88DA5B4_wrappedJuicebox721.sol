// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface IJuicebox721 {
    function _tokenId() external view returns (uint256);
    function isMintingLocked() external view returns (bool);

    function renounceOwnership() external;
    function transferOwnership(address newOwner) external;
    function setRebcAddr(address newAddress) external;
    function lockMinting() external;
    function setBaseUri(string memory baseUri) external;
    function mintToAddress(address _address, uint256 _count) external;
}

contract wrappedJuicebox721 is Context, Ownable {
    IJuicebox721 public juicebox721Contract;
    uint256 public maxSupply = 5565;
    uint256 public constant maxTokenPerTx = 5;
    uint256 public tokenPrice = 0.055 ether;
    uint256 public reedemableSupply = 0;
    bool public mintingStatus = false;

    address public constant creatorAddress = 0x4d46ecA8c64115A475193E5888343E073919B2DB;

    constructor(address _juicebox721Contract, uint256 _reedemableSupply) {
        juicebox721Contract = IJuicebox721(_juicebox721Contract);
        reedemableSupply = _reedemableSupply;
    }

    modifier notLocked() {
        require(isMintingLocked() == false, "Locked!");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return juicebox721Contract._tokenId();
    }

    function mintableAmount() public view returns (uint256) {
        return maxSupply - reedemableSupply - totalSupply();
    }

    function isMintingLocked() public view returns (bool) {
        return juicebox721Contract.isMintingLocked();
    }

    function toggleMintingStatus() public onlyOwner notLocked {
        mintingStatus = !mintingStatus;
    }

    function setMaxSupply(uint256 newSupply) public onlyOwner notLocked {
        maxSupply = newSupply;
    }
    
    function setReedemableSupply(uint256 _count) public onlyOwner notLocked {
        reedemableSupply = _count;
    }

    function renounceOwnershipOfJuicebox721() public virtual onlyOwner {
        juicebox721Contract.renounceOwnership();
    }

    function transferOwnershipOfJuicebox721(address newOwner) public virtual onlyOwner {
        juicebox721Contract.transferOwnership(newOwner);
    }

    function setRebcAddrOfJuicebox721(address newAddress) public onlyOwner {
        juicebox721Contract.setRebcAddr(newAddress);
    }

    function setJuicebox721Contract(address newContract) public onlyOwner notLocked {
        juicebox721Contract = IJuicebox721(newContract);
    }

    function lockMintingOfJuicebox721() public onlyOwner notLocked {
        juicebox721Contract.lockMinting();
    }

    function setBaseUriOfJuicebox721(string memory baseUri) public onlyOwner {
        juicebox721Contract.setBaseUri(baseUri);
    }

    function mint(uint256 _count) public payable notLocked {
        require(mintingStatus == true, "Minting has been closed");
        require(msg.value >= tokenPrice * _count, "Not enough money");
        require(_count <= maxTokenPerTx, "Only 5 token can be minted per transaction");
        require(_count + mintableAmount() <= maxSupply, "Max supply limit reached");
        
        juicebox721Contract.mintToAddress(msg.sender, _count);
    }

    function ownerMint(address _address, uint256 _count) public onlyOwner notLocked {
        require(mintingStatus == true, "Minting has been closed");
        require(_count + mintableAmount() <= maxSupply, "Max supply limit reached");
        
        juicebox721Contract.mintToAddress(_address, _count);
    }


    function sendEth(address _address, uint256 _amount) internal {
        uint256 balance = address(this).balance;
        require (balance > 0, "No balance in contract");
        require (_amount <= balance, "Not enough balance in contract");
        _widthdraw(_address, _amount);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require (balance > 0, "No balance in contract");

        _widthdraw(creatorAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) internal {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
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