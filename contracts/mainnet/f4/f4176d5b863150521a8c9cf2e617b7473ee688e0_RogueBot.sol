/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
   ______  _____   ______ _     _ _______
  |_____/ |     | |  ____ |     | |______
  |    \_ |_____| |_____| |_____| |______
                                        
  nft sniper bot by Aeson

*/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

contract RogueBot is Ownable {

    uint public licenceFee = 2 ether;

    address[] licenceHolders;

    modifier onlyLicensed() {
        require(_addressIsLicensed(msg.sender));
        _;
    }

    function _addressIsLicensed(address _address) private view returns (bool) {
        for(uint i=0; i<licenceHolders.length; i++) {
            if (licenceHolders[i] == _address) return true;
        }

        return false;
    }


    function purchase() external payable {
        require(msg.value == licenceFee, "Incorrect licence fee");
        require(!_addressIsLicensed(msg.sender), "Address already licensed");
        
        licenceHolders.push(msg.sender);
    }

    function checkIfLicenced(address _address) external view returns (bool) {
        return _addressIsLicensed(_address);
    }

    function updateLicenceFee(uint newFee) external onlyOwner {
        licenceFee = newFee;
    }

    function withdraw(address wallet) external onlyOwner {
        require(wallet != address(0), "Can't withdraw to null address");
        require(address(this).balance > 0, "Nothing to withdraw");

        payable(wallet).transfer(address(this).balance);
    }
}