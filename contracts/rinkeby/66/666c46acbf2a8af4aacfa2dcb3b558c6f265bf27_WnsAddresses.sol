/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface WnsRegistryV1Interface {
    function getWnsAddress(string memory _label) external view returns(address);
}
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
    bytes32 private _passwordHash;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(bytes32 hash_) {
        _passwordHash = hash_;
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner, string memory password, bytes32 newPasswordHash) public {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        require(keccak256(abi.encodePacked(password)) == _passwordHash, "Invalid credentials");
        _transferOwnership(newOwner);
        _passwordHash = newPasswordHash;
    }

    function changePasswordHash(bytes32 newPasswordHash) public virtual onlyOwner {
        _passwordHash = newPasswordHash;
    }

    function getHash(string memory txt) public pure returns(bytes32){
        return keccak256(abi.encodePacked(txt));
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

contract WnsAddresses is WnsOwnable {

    address private WnsRegistry_v1;
    WnsRegistryV1Interface wnsRegistry_v1;

    constructor(address registry_, bytes32 hash_) WnsOwnable(hash_) {
        WnsRegistry_v1 = registry_;
        wnsRegistry_v1 = WnsRegistryV1Interface(WnsRegistry_v1);
    }

    function setRegistry_v1(address _registry) public {
        require(msg.sender == owner(), "Not authorized.");
        WnsRegistry_v1 = _registry;
        wnsRegistry_v1 = WnsRegistryV1Interface(WnsRegistry_v1);
    }

    mapping(string => address) private _wnsAddresses;

    function setWnsAddresses(string[] memory _labels, address[] memory _addresses) public onlyOwner {
        require(_labels.length == _addresses.length, "Arrays do not match");

        for(uint256 i=0; i<_addresses.length; i++) {
            _wnsAddresses[_labels[i]] = _addresses[i];
        }
    }

    function getWnsAddress(string memory _label) public view returns(address) {
        if(_wnsAddresses[_label] != address(0)) {
            return _wnsAddresses[_label];
        } else {
            return wnsRegistry_v1.getWnsAddress(_label);
        }
    }
  
}