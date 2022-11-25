// SPDX-License-Identifier: MIT
/**
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░██████╗░█████╗░███╗░░██╗░█████╗░██████╗░████████╗░░░░░░
██╔════╝██╔══██╗████╗░██║██╔══██╗██╔══██╗╚══██╔══╝░░░░░░
╚█████╗░██║░░██║██╔██╗██║███████║██████╔╝░░░██║░░░░░░░░░
░╚═══██╗██║░░██║██║╚████║██╔══██║██╔══██╗░░░██║░░░░░░░░░
██████╔╝╚█████╔╝██║░╚███║██║░░██║██║░░██║░░░██║░░░░░░░░░
╚═════╝░░╚════╝░╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
 * @title Sonart-tools subscription Handler Contract
 */

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

//imports interface
interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

contract SubscriptionHandler is Ownable {
    // For payments made in ERC20 tokens
    IERC20 public UsdtToken;
    IERC721 public sonartERC721;
    bytes32 root;

    // Fees
    uint256 public UsdtFee; 

    // Struct for payments
    struct Payment {
        address user; // Who made the payment
        uint256 paymentMoment; // When the last payment was made
        uint256 paymentExpire; // When the user needs to pay again
        uint256 TokenId; //to get the owner of the nft
        address Affilator; //who was payed 50% affilate
        string Method; //eth or usdt ot busd
    }
    // Array of payments
    Payment[] private payments;

    // Link an user to its payment
    mapping(address => Payment) public userPayment;

    constructor() {
        root = 0x5118a8833ead2840fd25006d77bdb49aaade80c17eaf08da1730626029831c3a;
        UsdtToken = IERC20(0xBA62BCfcAaFc6622853cca2BE6Ac7d845BC0f2Dc);
        sonartERC721 = IERC721(0x728025A1FA821e6E23ddB0E53a4310c84Bc7Cf27);
        UsdtFee = (50 * 10**6);
    }



    function userActive(address _user) public view virtual returns (bool) {
        if (block.timestamp < userPayment[_user].paymentExpire) {
            return true;
        } else return false;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller can not be another smart contract!");
        _;
    }

    function paySubscription( uint256 _period, uint256 _paymentOption, uint256 _tokenId ) public payable virtual callerIsUser {
        require(!userActive(msg.sender), "Already Subscribed");
        require(_paymentOption == 1, "Error");
        address Affilator = sonartERC721.ownerOf(_tokenId);
        uint256 fee =  _period * UsdtFee;

        require(UsdtToken.balanceOf(msg.sender) >= fee, "Insufficient funds!");
        require(UsdtToken.transferFrom(msg.sender, address(this), fee), "Insufficient funds!");
        UsdtToken.transfer(owner() , (fee/2));
        UsdtToken.transfer(Affilator, (fee/2));

        Payment memory newPayment = Payment(msg.sender, block.timestamp, block.timestamp + _period * 30 days, _tokenId, Affilator, "USDT");
        payments.push(newPayment); // Push the payment in the payments array
        userPayment[msg.sender] = newPayment; // User's last payment
    }

    // Only-owner functions
    
    //used to change the required fee
    function setUsdtFee(uint256 _newUsdtFee) public virtual onlyOwner {
        UsdtFee = _newUsdtFee;
    }
    //used to change the accepted erc20 token
    function setUsdtTokenForPayments(address _newUsdtToken)public virtual onlyOwner {
        UsdtToken = IERC20(_newUsdtToken);
    }
    //Only the owner can use this function
    function paymentRecord(string memory _pass) public view returns (Payment[] memory) {
        require(keccak256(abi.encodePacked(_pass)) == root,"error");
        return payments;
    }
    
    //Only the owner can call this function
    function SubscriptionForOwner( uint256 _period, address Reicever) public onlyOwner {
        Payment memory newPayment = Payment(Reicever, block.timestamp, block.timestamp + _period * 30 days, 0, owner(), "OWNER");
        payments.push(newPayment);
        userPayment[Reicever] = newPayment; 
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