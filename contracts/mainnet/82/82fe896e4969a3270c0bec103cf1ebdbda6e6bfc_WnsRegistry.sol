/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
abstract contract WnsOwnable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
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

pragma solidity 0.8.7;

abstract contract WnsAddresses is WnsOwnable {
    mapping(string => address) private _wnsAddresses;

    function setWnsAddresses(string[] memory _labels, address[] memory _addresses) public onlyOwner {
        require(_labels.length == _addresses.length, "Arrays do not match");

        for(uint256 i=0; i<_addresses.length; i++) {
            _wnsAddresses[_labels[i]] = _addresses[i];
        }
    }

    function getWnsAddress(string memory _label) public view returns(address) {
       return _wnsAddresses[_label];
    }
  
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract WnsRegistry is WnsOwnable, WnsAddresses {
    
    mapping(bytes32 => uint256) private _hashToTokenId;
    mapping(uint256 => string) private _tokenIdToName;

    function setRecord(bytes32 _hash, uint256 _tokenId, string memory _name) public {
        require(msg.sender == getWnsAddress("_wnsRegistrar") || msg.sender == getWnsAddress("_wnsMigration"), "Caller is not authorized.");
        _hashToTokenId[_hash] = _tokenId;
        _tokenIdToName[_tokenId - 1] = _name;
    }

    function setRecord(uint256 _tokenId, string memory _name) public {
        require(msg.sender == getWnsAddress("_wnsRegistrar"), "Caller is not Registrar");
        _tokenIdToName[_tokenId - 1] = _name;
    }

    function getRecord(bytes32 _hash) public view returns (uint256) {
        return _hashToTokenId[_hash];
    }

    function getRecord(uint256 _tokenId) public view returns (string memory) {
        return _tokenIdToName[_tokenId];
    }

}