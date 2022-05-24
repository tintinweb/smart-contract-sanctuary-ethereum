/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// SPDX-License-Identifier: MIT


// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.0;

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



// import "OpenZeppelin/[email protected]/contracts/access/Ownable.sol";
// import "OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol";


// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity 0.8.0;


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



// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


//payment splitter equally to nft ribbon holders
interface Iakyllers {
    function iakyllers() external;
}


contract AkyllersRoyalties is Ownable {
    address iakyllersAddr = address(0x35886Bc0740f019319E3aeccd6736AF88ac5ac69);
    function akyllersroyalties() public {
        Iakyllers(iakyllersAddr).iakyllers();
    }
    // userIndex > 0 for existing payee
    struct UserBalance {
        uint256 userIndex;
        uint256 balance;
    }

    // list of all who are allowed to get royalties
    address[] public payees;

    // A record of total withdrawal amounts per payee address
    mapping(address => UserBalance) public balances;

    constructor(address[] memory _payees) {
        payees = _payees;
        for (uint256 i = 0; i < payees.length; i++) {
            balances[payees[i]] = UserBalance({userIndex : i+1,
            balance : 0});
        }
    }
    
    


    // split each payment equally to payees
    receive() external payable {
        uint256 amount = msg.value;
        uint256 royaltyPerPayee = amount / payees.length;
        for (uint256 i = 0; i < payees.length; i++) {
            balances[payees[i]].balance += royaltyPerPayee;
        }

    }

    // if address in in the list or no 
    // "user" is the parameter address to verify
    // return true if user is a payee , else false
    function _isPayee(address user) internal
    returns(bool) {
        return balances[user].userIndex > 0;
    }

    //let a user withdraw some of their royalties 
    // "amount" is the amount to withdraw
    function withdraw(uint256 amount) external isPayee(msg.sender) {
        require(amount > 0);
        require(amount <= balances[msg.sender].balance,
            "Insufficient balance");
        balances[msg.sender].balance -= amount;
        msg.sender.call{value: amount}('');
    }

    // let a user withdraw all of their royalties 
    function withdrawAll() external isPayee(msg.sender) {
        require(balances[msg.sender].balance > 0);
        uint256 balance = balances[msg.sender].balance;
        balances[msg.sender].balance = 0;
        msg.sender.call{value: balance}('');
    }

    // clear all balances by paying out all payees their royalties
    function _payAll() internal {
        for (uint256 i = 0; i < payees.length; i++) {
            address payee = payees[i];
            uint256 availableBalance = balances[payee].balance;
            if (availableBalance > 0) {
                balances[payee].balance = 0;
                payee.call{value: availableBalance}('');
            }
        }
    }

    // pay all users their balances
    function payAll() external onlyOwner {
        _payAll();
    }

    // remove a userr from the list of payees
    // "payee" is te he address of the user to remove
    function removePayee(address payee) external onlyOwner {
        // the address needs to be a payee
        require(_isPayee(payee));
        // first pay everybody off and clear their balances
        _payAll();
        // fetch the index of the payee to remove , userIndex starts at 1
        uint256 removalIndex = balances[payee].userIndex - 1;
        // move the last payee on the list in its place
        payees[removalIndex] = payees[payees.length - 1];
        // removes the last entry on the array
        payees.pop();
        // if the removed payee was also the last on the list
        if (removalIndex != payees.length) {
            //   update the last payee index to its new position
            balances[payees[removalIndex]].userIndex = removalIndex + 1;
        }
        // set payee userIndex to false by deleting the entry and removing payee status
        delete (balances[payee]);
    }

    // function timelock(AkyllersRoyalties){
        
    // }
    // add a user to the list of payees
    function addPayee(address payee) external onlyOwner {
        // the address can't already be a payee
        require(!_isPayee(payee));
        // first pay everybody off and clear their balances
        _payAll();
        // add the new member
        payees.push(payee);
        balances[payee] = UserBalance(payees.length, 0);
    }

    // allow to withdraw payments made in eth
    // will split evenly between all current payees only, function is not called when payee is added or removed
    // "token" the token to split among all current payees
    function withdrawErc20(IERC20 token) external onlyOwner {
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0);
        uint256 payeeRoyalty = tokenBalance / payees.length;
        for (uint256 i = 0; i < payees.length; i++) {
            token.transfer(payees[i], payeeRoyalty);
        }
    }

    modifier isPayee(address user) {
        require(_isPayee(user),
            "Not payee");
        _;
    }
    

}

//   function walletHoldsToken(address memory _wallet, address memory _contract) public view returns (bool) {
//     return IERC1155(_contract).balanceOf(_wallet) > 0  ;

//   }
 


    // interface AKYLLESXT {
    // function ownerof() external;   
    // }
    // contract AKYLLESXT {
    // // Declaration
    // AKYLLESXT ak = AKYLLESXT("0x35886Bc0740f019319E3aeccd6736AF88ac5ac69");
    // // Usage
    // ak.ownerof();
    // }
     


//      interface contract2 {
//   function link() external;
// }
// contract contract1 {
// // Declaration
// contract2 cont2 = contract2("Address_of_contract2");
// // Usage
// cont2.link();
// }


// interface AKYLLESXT {
//   function ownerof() external;

// // Declaration
//  AKYLLESXT ak = AKYLLESXT("0x35886Bc0740f019319E3aeccd6736AF88ac5ac69");
// // Usage
// // ak.link();
// // }

//  interface InterfaceAK {
//     function ownerof() external;   
// }

// contract AKYLLESXT {
//     // Declaration
//     AnotherName ak = AnotherName("address");
//     // Usage
//     ak.ownerof();
// }