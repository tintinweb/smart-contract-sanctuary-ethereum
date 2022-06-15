// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface iCryptoNerdz {
    function balanceOf(address owner) external view returns(uint256);
    function transferFrom(address, address, uint) external;
    function ownerOf(uint) external;
}

contract NerdzClaim is Ownable {
    iCryptoNerdz public CryptoNerdz;

    bool public claimPaused = true;
    address public signerAddress;
    address public nerdzWallet;
    uint256 private nextToken;
    mapping(address => bool) public claimed;

    constructor(address cnAddress)  {
        CryptoNerdz = iCryptoNerdz(cnAddress);
    }

    /*
     * @dev Requires msg.sender to have valid claim.
     * @param _qty Amount msg.sender can claim.
     * @param _v ECDSA signature parameter v.
     * @param _r ECDSA signature parameters r.
     * @param _s ECDSA signature parameters s.
     */
    modifier onlyValidClaims( uint256 _qty, bytes32 _r, bytes32 _s, uint8 _v) {
        require(isValidClaim(msg.sender, _qty, _r, _s, _v), "SignatureMismatch");
        _;
    }

    function claimNerdz(uint256 qty, bytes32 r, bytes32 s, uint8 v) external onlyValidClaims(qty,r,s,v) {
        require(!claimPaused, "ClaimingPaused"); 
        require(!claimed[msg.sender], "NoneAvailableForAddress");
        uint currToken = nextToken;

        for(uint i=0; i<qty; i++) {
            if(currToken == 1262 || currToken == 1555) {
                currToken++;
            }

            CryptoNerdz.transferFrom(nerdzWallet, msg.sender, currToken);
            currToken++;
        }

        nextToken = currToken;
        claimed[msg.sender] = true;
    }

    function checkClaimed(address user) external view returns(bool) {
        return claimed[user];
    }

    function setNerdzWallet(address wallet) external onlyOwner {
        nerdzWallet = wallet;
    }

    function setStartToken(uint token) external onlyOwner{
        nextToken = token;
    }

    function setSignerWallet(address wallet) external onlyOwner {
        signerAddress = wallet;
    }

    function toggleClaim() external onlyOwner {
        claimPaused = !claimPaused;
    }

    /*
     * @dev Verifies if message was signed by owner to give access to _add for this contract.
     *      Assumes Geth signature prefix.
     * @param _add Address of agent with access.
     * @param _qty Amount available to claim.
     * @param _v ECDSA signature parameter v.
     * @param _r ECDSA signature parameters r.
     * @param _s ECDSA signature parameters s.
     * @return Validity of access message for a given address.
     */
    function isValidClaim( address _add, uint256 _qty, bytes32 _r, bytes32 _s, uint8 _v) public view returns (bool) {
        bytes32 hash = keccak256(abi.encode(owner(), _add, _qty));
        bytes32 message = keccak256( abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        address sig = ecrecover(message, _v, _r, _s);
        return signerAddress == sig;
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