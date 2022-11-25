/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: Recurring payment/Paymentsplitter.sol


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
 * @author Elfoly
 */

pragma solidity >=0.7.0 <0.9.0;
//imports

//
interface ERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function balanceOf(address _owner) external view returns (uint256);
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



 contract SubscriptionHandler is Ownable {

    // For payments made in ERC20 tokens
    IERC20 public UsdtToken ;

     // Fees
    uint256 public ethFee = 0 ether; // Fee for ethereum payments
    uint256 public UsdtFee; // Fee for ethereum payments
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
    mapping ( address => Payment ) public userPayment;

function tranfer( address to, uint256 value)public payable{
    UsdtToken.transferFrom(msg.sender ,to ,value );
}

function paymenta()public  onlyOwner view returns (Payment[] memory){
    return payments;
}


    //events
    event UserPaidErc20(address indexed who, uint256 indexed fee, uint256 indexed period);
    event UserPaidEth(address indexed who, uint256 indexed fee, uint256 indexed period);

    constructor() {
        UsdtToken = IERC20(0xBA62BCfcAaFc6622853cca2BE6Ac7d845BC0f2Dc);
    }

    // Check if user paid - modifier
    modifier userPaid() {
        require(block.timestamp < userPayment[msg.sender].paymentExpire || block.timestamp < userPayment[msg.sender].paymentExpire, "Your payment expired!"); // Time now < time when last payment expire
        _;
    }
    function userActive(address _user) public view virtual returns (bool)  {
        if(block.timestamp < userPayment[_user].paymentExpire){
            return true;
        } else return false;

    }
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller can not be another smart contract!");
        _;
    }

    // Make a payment | 1 = eth payment | 2 = erc20 payment
    function paySubscription(uint256 _period, uint256 _paymentOption,uint256 _TokenId) public payable virtual callerIsUser {
        require(_paymentOption == 1 || _paymentOption == 2, "Invalid payment option!"); 
        address Affilator = 0x2C30259E81863eb86b84014AC80D242D661734A6;
        if(_paymentOption == 1) {
            require(msg.value >= ethFee * _period, "Invalid!");



            Payment memory newPayment = Payment(msg.sender, block.timestamp, block.timestamp + _period * 30 days,_TokenId,Affilator, "ETH");
            payments.push(newPayment); // Push the payment in the payments array
            userPayment[msg.sender] = newPayment; // User's last payment

            emit UserPaidEth(msg.sender, ethFee * _period, _period);
        } else if(_paymentOption == 2){
            require(UsdtToken.transfer(address(this), _period * UsdtFee));



            Payment memory newPayment = Payment(msg.sender, block.timestamp, block.timestamp + _period * 30 days,_TokenId,Affilator,"USDT");
            payments.push(newPayment); // Push the payment in the payments array
            userPayment[msg.sender] = newPayment; // User's last payment

            emit UserPaidErc20(msg.sender, UsdtFee * _period, _period);
        }
    }

    // Only-owner functions
    function setEthFee(uint256 _newEthFee) public virtual onlyOwner {
        ethFee = _newEthFee ;
    }

    function setErc20Fee(uint256 _newErc20Fee) public virtual onlyOwner {
        UsdtFee = _newErc20Fee;
    }

    function setUsdtTokenForPayments(address _newUsdtToken) public virtual onlyOwner {
        UsdtToken = IERC20(_newUsdtToken);
    }



    function withdrawUSDT() public virtual onlyOwner {
         UsdtToken.transfer(owner(), UsdtToken.balanceOf(address(this)));
    }

    function withdrawEth() public virtual onlyOwner {
         payable(owner()).transfer(address(this).balance);
    }
}