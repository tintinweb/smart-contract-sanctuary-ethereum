// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';

interface IERC721 {
     /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

       /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns the token IDs owned by `owner`.
     */
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
}

contract DobbysRoyalties  {
    uint256 public totalRoyalties; // Total royalties that have been received by the contract
    uint256 public totalPayouts;   // Total royalties that have been paid out to holders
    uint256 public totalReserved;  // Total reserved tokens percentage
    uint256 public totalReservedCount; // Total reserved tokens count
    IERC721 public tokenContract;  // Contract of the token holders

    mapping(uint256 => uint256) private payouts; // Mapping of tokenId and the royalties that have been paid out to its holders
    mapping(uint256 => uint256) private reservedShares; // Mapping of tokenId and the permille of the total royalties that are being reserved for it

    constructor(address _tokenContract) {
        tokenContract = IERC721(_tokenContract);
    }

    receive() external payable {
        totalRoyalties += msg.value;
    }

    function funds() public view returns(uint256) {
        return fundsOfAddress(msg.sender);
    }

    // Returns the sum of the value of all tokens
    function fundsOfAddress(address _address) public view returns(uint256) {
        uint256 pending = 0;
        uint256[] memory tokens = tokenContract.walletOfOwner(_address);
        require(tokens.length > 0, "This wallet does not have any tokens!");

        for (uint256 i = 0; i < tokens.length; i++) {
            pending+=fundsOfToken(tokens[i]);
        }
        
        return pending;
    }

    function fundsOfToken(uint256 _tokenId) public view returns(uint256) {
        uint256 totalSupply = tokenContract.totalSupply();        
        require(_tokenId <= totalSupply, "Enter a valid tokenId!");
        if (reservedShares[_tokenId] != 0) {
            return totalRoyalties * reservedShares[_tokenId] / 100 - payouts[_tokenId];
        } else {
            return totalRoyalties / ((100 - totalReserved) / (totalSupply - totalReservedCount)) - payouts[_tokenId];
        }
    }

    function payOut() public {
        payOutForAddress(msg.sender);
    }

    function payOutForAddress(address _address) public{
        uint256 payoutAmount = 0;        
        uint256[] memory tokens = tokenContract.walletOfOwner(_address);

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tokenId = tokens[i];
            uint256 payout = fundsOfToken(tokenId);
            if (payout > 0) {
                payouts[tokenId] += payout;
                payoutAmount+=payout;
            }
        }        

        require(payoutAmount > 0, "There is nothing to withdraw!");

        totalPayouts+=payoutAmount;
        payable(_address).transfer(payoutAmount);
    }

    function reserve(uint256 _tokenId, uint256 _percentage) public {
        uint256 totalSupply = tokenContract.totalSupply();        
        require(_tokenId <= totalSupply, "Enter a valid tokenId!");
        uint256 _totalReserved = 0;
        if(reservedShares[_tokenId] != 0) {
            _totalReserved = totalReserved - reservedShares[_tokenId] + _percentage;
        } else {
            _totalReserved = totalReserved + _percentage;
            totalReservedCount++;
        }
        require(_totalReserved <= 100, "The totalReserved can't be above 100%!");
        reservedShares[_tokenId] = _percentage;
        totalReserved = _totalReserved;
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