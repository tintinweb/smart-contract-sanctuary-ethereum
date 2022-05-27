/**
 *Submitted for verification at Etherscan.io on 2022-05-26
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

contract LiceneTest is Ownable {

    uint licenceFee = 0.25 ether;
    uint transferFee = 0.01 ether;

    mapping(address => uint16) UserLicenceCount;
    mapping(address => address[]) UserBotWallets;

    modifier onlyLicensed() {
        require(UserLicenceCount[msg.sender] > 0);
        _;
    }

    function _walletRegistered(address _wallet) private view returns (bool) {
        address[] memory userWallets =  UserBotWallets[msg.sender];
        for(uint i=0; i<userWallets.length; i++) {
            if (userWallets[i] == _wallet) return true;
        }

        return false;
    }

    function purchase(address _wallet) external payable {
        require(msg.value == licenceFee, "Incorrect licence fee");
        require(_wallet != address(0), "Invalid bot wallet");
        require(!_walletRegistered(_wallet), "Bot wallet already registered");
        
        UserLicenceCount[msg.sender]++;
        UserBotWallets[msg.sender].push(_wallet);
    }

    function checkLicence(address _wallet) external view onlyLicensed returns (bool) {
        return _walletRegistered(_wallet);
    }

    function updateBotWallet(address _currentWallet, address _newWallet) external payable onlyLicensed {
        require(msg.value == transferFee, "Incorrect upfate fee");
        require(_walletRegistered(_currentWallet), "Current wallet not registered");
        require(!_walletRegistered(_newWallet), "New wallet aleady registered");

        address[] storage userWallets =  UserBotWallets[msg.sender];
        for(uint i=0; i<userWallets.length; i++) {
            if (userWallets[i] == _currentWallet) {
                userWallets[i] = _newWallet;
                return;
            }
        }
    }

    function updateLicenceFee(uint newFee) external onlyOwner {
        require(newFee >= 0);
        licenceFee = newFee;
    }

    function updateTransferFee(uint newFee) external onlyOwner {
        require(newFee >= 0);
        transferFee = newFee;
    }

    function withdraw(address wallet) external onlyOwner {
        require(wallet != address(0), "Can't withdraw to null address");
        require(address(this).balance > 0, "Nothing to withdraw");

        payable(wallet).transfer(address(this).balance);
    }
}