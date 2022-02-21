// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

    constructor(string memory _credential) {
        credential = keccak256(abi.encodePacked(_credential));
    }

    function setCredential(string memory _newCredential) external onlyOwner {
        credential = keccak256(abi.encodePacked(_newCredential));
    }

    function deposit() external payable {
        require(msg.value > 0, "Value is Zero or Negative");
    }

    function withdraw(
        address dest,
        uint256 percent,
        string memory passKey
    ) external onlyOwner {
        bytes32 secret = keccak256(abi.encodePacked(passKey));
        require(secret == credential, "PassKey is incorrect");

        uint256 curBalance = address(this).balance;
        require(
            curBalance > 0,
            "Contract balance is Zero. Try later to withdraw"
        );
        payable(dest).transfer((curBalance * percent) / 100);
    }
}