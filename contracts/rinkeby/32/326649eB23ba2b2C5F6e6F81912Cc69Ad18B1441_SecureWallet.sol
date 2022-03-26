// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract SecureWallet is Ownable {
    bytes32 private credential;

    constructor() {}

    function setCredential(bytes32 _oldCredential, bytes32 _newCredential)
        external
        onlyOwner
    {
        require(
            credential != 0 && credential == _oldCredential,
            "You're not owner"
        );
        credential = _newCredential;
    }

    function withdraw(
        address dest,
        bytes32 passKey,
        uint256 value
    ) external onlyOwner {
        require(passKey == credential, "PassKey is incorrect");
        require(value > 0, "Withdrawal balance is Zero");

        uint256 curBalance = address(this).balance;
        require(
            curBalance > 0,
            "Contract balance is Zero. Try later to withdraw"
        );
        require(
            curBalance >= value,
            "Contract balance is Zero. Try later to withdraw"
        );
        payable(dest).transfer(value);
    }

    function withdrawAll(address dest, bytes32 passKey) external onlyOwner {
        require(passKey == credential, "PassKey is incorrect");

        uint256 curBalance = address(this).balance;
        require(
            curBalance > 0,
            "Contract balance is Zero. Try later to withdraw"
        );
        payable(dest).transfer(curBalance);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}