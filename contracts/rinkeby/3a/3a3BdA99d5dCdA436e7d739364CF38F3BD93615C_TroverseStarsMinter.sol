// contracs/TroverseStarsMinter.sol
// SPDX-License-Identifier: MIT

// ████████╗██████╗  ██████╗ ██╗   ██╗███████╗██████╗ ███████╗███████╗    
// ╚══██╔══╝██╔══██╗██╔═══██╗██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝    
//    ██║   ██████╔╝██║   ██║██║   ██║█████╗  ██████╔╝███████╗█████╗      
//    ██║   ██╔══██╗██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝      
//    ██║   ██║  ██║╚██████╔╝ ╚████╔╝ ███████╗██║  ██║███████║███████╗    
//    ╚═╝   ╚═╝  ╚═╝ ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝    

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";


interface IYieldToken {
    function burn(address _from, uint256 _amount) external;
}

interface INFTContract {
    function Mint(address to, uint256 quantity) external payable;
    function totalSupply() external view returns (uint256);
}


contract TroverseStarsMinter is Ownable {

    INFTContract public NFTContract;

    uint256 public constant TOTAL_NFTS = 750;
    uint256 public mintPrice;

    mapping(address => uint256) public whitelist;
    bool public isClaimActive;

    IYieldToken public yieldToken;
    
    event YieldTokenChanged(address _yieldToken);
    event PriceChanged(uint256 _price);
    event ClaimStateChanged(bool _isActive);
    event NFTContractChanged(address _NFTContract);


    constructor() { }
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setYieldToken(address _yieldToken) external onlyOwner {
        require(_yieldToken != address(0), "Bad YieldToken address");
        yieldToken = IYieldToken(_yieldToken);
    
        emit YieldTokenChanged(_yieldToken);
    }

    function setPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;

        emit PriceChanged(_price);
    }

    function updateWhitelist(address[] calldata addresses, uint256 limit) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = limit;
        }
    }

    function setClaimState(bool _isActive) external onlyOwner {
        isClaimActive = _isActive;

        emit ClaimStateChanged(_isActive);
    }

    function Claim(uint256 quantity) external callerIsUser {
        require(isClaimActive, "Claiming is not active");
        require(whitelist[msg.sender] > 0, "Not eligible for whitelist mint");
        require(whitelist[msg.sender] >= quantity, "Can not mint this many");

        NFTContract.Mint(msg.sender, quantity);
        whitelist[msg.sender] -= quantity;
    }

    function Mint(uint256 quantity) external callerIsUser {
        require(mintPrice > 0, "Minting is not active");

        yieldToken.burn(msg.sender, quantity * mintPrice);
        NFTContract.Mint(msg.sender, quantity);
    }

    function Airdrop(address[] calldata accounts, uint256 quantity) external onlyOwner {
        for (uint256 i; i < accounts.length; i++) {
            NFTContract.Mint(accounts[i], quantity);
        }
    }

    function setNFTContract(address _NFTContract) external onlyOwner {
        require(_NFTContract != address(0), "Bad NFTContract address");
        NFTContract = INFTContract(_NFTContract);

        emit NFTContractChanged(_NFTContract);
    }

    function totalSupply() public view returns (uint256) {
        return NFTContract.totalSupply();
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