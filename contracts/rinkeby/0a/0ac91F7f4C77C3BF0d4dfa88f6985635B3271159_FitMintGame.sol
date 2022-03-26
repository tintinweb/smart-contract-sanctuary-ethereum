pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "Ownable.sol";

interface FitMintToken {
    function mintCommunityTokens(uint256 tokenAmount) external;
}

// contract FitMintGame is Ownable {
//     struct Payment {
//         uint amount;
//         uint timestamp;
//     }
//     address MaticToken;
//     struct Balance {
//         uint totalBalance;
//         uint numPayments;
//         mapping(uint => Payment) payments;
//     }

//     address [] invetory_tokens;
//     mapping(address => mapping(address => Balance)) public balanceReceived;

//     event InventoryTxn(address _address, uint _amount, uint _type, address _tokenName);
//     enum InventoryTxnType {Credit, Debit}

//     function getBalance() public view returns (uint) {
//         return address(this).balance;
//     }


//     function sendMoney() public payable {

//         balances[msg.sender].totalBalance += msg.value;
//         Payment memory payment = Payment(msg.value, block.timestamp);
//         balanceReceived[msg.sender].payments[balanceReceived[msg.sender].numPayments] = payment;
//         balanceReceived[msg.sender].numPayments++;
//         // emit InventoryTxn(msg.sender,msg.value,InventoryTxnType.Credit,);
//     }

//     function addEarning(address beneficiary, uint amount) public onlyOwner {
//         balances[msg.sender].totalBalance += msg.value;
//         Payment memory payment = Payment(msg.value, block.timestamp);
//         balanceReceived[msg.sender].payments[balanceReceived[msg.sender].numPayments] = payment;
//         balanceReceived[msg.sender].numPayments++;
//     }

//     function withdrawMoney(address payable _to, uint _amount) public {
//         require(_amount <= balanceReceived[msg.sender].totalBalance, "not enough funds");
//         balanceReceived[msg.sender].totalBalance -= _amount;
//         _to.transfer(_amount);
//     }

//     function withdrawAllMoney(address payable _to) public {
//         uint balanceToSend = balanceReceived[msg.sender].totalBalance;
//         balanceReceived[msg.sender].totalBalance = 0;
//         _to.transfer(balanceToSend);
//     }

// }

contract FitMintGame is Ownable {
    FitMintToken gameTokenInstance;

    // struct userStruct {
    //     uint32 user_id;
    //     uint256 tokenBalance;
    // }
    // mapping(address => userStruct) public userAccount;

    constructor(address _token_address) public {
        gameTokenInstance = FitMintToken(_token_address);
    }
    function claimComminityTokens(uint tokenAmount) public onlyOwner{
        gameTokenInstance.mintCommunityTokens(tokenAmount);
        // userAccount[msg.sender].tokenBalance = userAccount[msg.sender].tokenBalance - tokenAmount;
    }
    // function changeAttributes(address _userAddress, uint256 _userTokenBalance) public onlyOwner {
    //     userAccount[_userAddress].tokenBalance = _userTokenBalance;
    // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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