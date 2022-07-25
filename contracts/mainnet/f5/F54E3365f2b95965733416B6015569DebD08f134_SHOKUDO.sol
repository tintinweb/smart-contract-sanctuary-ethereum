/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.9;

contract SHOKUDO is Ownable {

    uint256 public whitelistCounter;
    mapping(uint => Whitelist) whitelists;
    mapping(uint => mapping(address => bool)) _hasPurchased;
    address public bambooAddress;
    ICHANKO public CHANCO = ICHANKO(0xced7c61617aD24b076729Af8EE607A4b30CBf2E4);

    struct Whitelist {
        uint256 id;
        uint256 price;
        uint256 amount;
    }

    event Purchase (uint256 indexed _id, address indexed _address);

    function addWhitelist(uint256 _amount, uint256 _price) external onlyOwner {
        Whitelist memory wl = Whitelist(
            whitelistCounter,
            _price * 10 ** 18,
            _amount
        );

        whitelists[whitelistCounter++] = wl;
    }

    function purchase(uint256 _id) public {
        require(
            whitelists[_id].amount != 0,
            "No spots left"
        );
       require(
           !_hasPurchased[_id][msg.sender],
           "Address has already purchased"
        );
        require(
            CHANCO.balanceOf(msg.sender) >= whitelists[_id].price,
            "Not enough tokens!"
        );

        unchecked {
            whitelists[_id].amount--;
        }

        _hasPurchased[_id][msg.sender] = true;

        CHANCO.burnFrom(msg.sender, whitelists[_id].price);

        emit Purchase(_id, msg.sender);
    }

    function getWhitelist(uint256 _id) public view returns (Whitelist memory) {
        return whitelists[_id];
    }

    function hasPurchased(uint256 _id, address _address) public view returns (bool) {
        return _hasPurchased[_id][_address];
    }

    function setCHANCO(address address_) external onlyOwner {
        CHANCO = ICHANKO(address_);
    }
}

interface ICHANKO {
    function owner() external view returns (address);
    function balanceOf(address address_) external view returns (uint256);
    function transferFrom(address from_, address to_, uint256 amount_) external;
    function burnFrom(address from_, uint256 amount_) external;
}