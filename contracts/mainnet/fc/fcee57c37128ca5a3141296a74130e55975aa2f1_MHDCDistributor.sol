/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: Unlicense
// Sources flattened with hardhat v2.8.3 https://hardhat.org
pragma solidity ^0.8.4;

// File @openzeppelin/contracts/utils/[email protected]
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// File @openzeppelin/contracts/access/[email protected]
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


// File contracts/MHDCDistributor.sol
// MHDC Distributor Contract

contract MHDCDistributor is Ownable {
    // primary distributions
    struct Dist {
        uint256 share;
        uint256 loc;
        string name;
    }

    mapping(address => Dist) private _distMap;
    address[] private _distList;
    uint256 private _shareTotal = 0;

    event Distribution(uint256 amount);
    event DistributionListChange(address indexed target, bool isIncluded);

    constructor(
        address[] memory addresses,
        string[] memory names,
        uint256[] memory shares
    ) {
        for (uint256 i = 0; i < addresses.length; i++) {
            addDist(addresses[i], names[i], shares[i]);
        }
    }

    receive() external payable {}

    fallback() external payable {}

    function getShareTotal() public view returns (uint256) {
        return _shareTotal;
    }

    function getShare(address account) public view returns (uint256) {
        return _distMap[account].share;
    }

    function getName(address account) public view returns (string memory) {
        return _distMap[account].name;
    }

    function allDist() public view returns (address[] memory) {
        return _distList;
    }

    function isDist(address account) public view returns (bool) {
        return (getShare(account) > 0);
    }

    function shareTotal() private {
        uint256 sum;
        for (uint256 i = 0; i < _distList.length; i++) {
            sum += _distMap[_distList[i]].share;
        }
        _shareTotal = sum;
    }

    function addDist(
        address _address,
        string memory _Name,
        uint256 _share
    ) public onlyOwner {
        require(_address != address(0), "Invalid address");
        require(_share > 0, "Share must be greater than zero");
        Dist storage d = _distMap[_address];
        require(d.share == 0, "Address already in distribution list");

        d.share = _share;
        d.loc = _distList.length;
        d.name = _Name;

        _distList.push(_address);
        emit DistributionListChange(_address, true);
        shareTotal();
    }

    function removeDist(address _address) public onlyOwner {
        Dist storage d = _distMap[_address];
        require(d.share > 0, "Address not in distribution list");
        d.share = 0;

        address _last = _distList[_distList.length - 1];
        _distMap[_last].loc = d.loc;
        _distList[d.loc] = _last;
        _distList.pop();

        emit DistributionListChange(_address, false);
        shareTotal();
    }

    function editDistName(address _address, string memory _Name)
        external
        onlyOwner
    {
        Dist storage d = _distMap[_address];
        require(d.share > 0, "Address not in distribution list");
        d.name = _Name;
    }

    function editDistShare(address _address, uint256 _share)
        external
        onlyOwner
    {
        require(_share > 0, "To set share to zero, use removeDist()");
        Dist storage d = _distMap[_address];
        require(d.share > 0, "Address not in distribution list");

        d.share = _share;
        shareTotal();
    }

    function editDistAddress(string memory _Name, address _newAddress)
	external
	onlyOwner
    {
	address _oldAddress;
	Dist memory d;

	for (uint256 i = 0; i < _distList.length; i++) {
	_oldAddress = _distList[i];
	d = _distMap[_oldAddress];

	    if (keccak256(bytes(d.name)) == keccak256(bytes(_Name))) {
		removeDist(_oldAddress);
		addDist(_newAddress, _Name, d.share);
	    }
	}
    }

    function distribute() external onlyOwner {
        if (_distList.length > 0) {
            uint256 balance = address(this).balance;
            uint256 unit = balance / _shareTotal;
            address _address;

            for (uint256 i = 0; i < _distList.length; i++) {
                _address = _distList[i];
                payable(_address).transfer(_distMap[_address].share * unit);
            }
            emit Distribution(balance);
        }
    }
}