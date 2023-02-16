// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error Manager__AccountAlreadyExists(address);
error Manager__NotVaildForOwner();
error Manager_NotOwner(address);
error Manager__TransferFailed();
error Manager__AccountNotEmpty(address);
error Manager__NotSameOwner(address, address);
error Manager__InvalidWithdraw();
error Manager__InvalidDeletion();

contract Manager is ReentrancyGuard {
    mapping(address => address[]) private s_ownerToWalletAccounts;
    mapping(address => uint256) private s_accountToBalance;
    mapping(address => address) private s_accountToOwner;
    mapping(address => uint256) private s_accountToWithdrawAmount;

    event ManagerCreated(address owner);
    event AccountAdded(address account, address ownerAccount);
    event TransferSuccess(address accountFrom, address accountTo, uint256 amount);
    event Withdrawn(address account, uint256 amount);
    event AccountDeleted(address account);
    event ManagerDeleted(address account);

    modifier notOwner(address account) {
        if (account == s_accountToOwner[account]) {
            revert Manager__NotVaildForOwner();
        }
        _;
    }

    modifier isOwner(address account) {
        if (account != s_accountToOwner[account]) {
            revert Manager_NotOwner(account);
        }
        _;
    }

    modifier accountExists(address account) {
        if (s_accountToOwner[account] != address(0)) {
            revert Manager__AccountAlreadyExists(account);
        }
        _;
    }

    modifier sameOwner(address sender, address receiver) {
        if (s_accountToOwner[sender] != s_accountToOwner[receiver]) {
            revert Manager__NotSameOwner(sender, receiver);
        }
        _;
    }

    modifier validWithdraw(address receiver, uint256 amount) {
        if (amount > s_accountToWithdrawAmount[receiver]) {
            revert Manager__InvalidWithdraw();
        }
        _;
    }

    modifier ifChild(address owner, address account) {
        if (s_accountToOwner[account] != owner) {
            revert Manager__InvalidDeletion();
        }
        _;
    }

    //////////////////////
    /// Main Functions ///
    //////////////////////

    function createManager() external accountExists(msg.sender) {
        s_ownerToWalletAccounts[msg.sender].push(msg.sender);
        s_accountToBalance[msg.sender] = msg.sender.balance; //msg.sender.balance;
        s_accountToOwner[msg.sender] = msg.sender;
        s_accountToWithdrawAmount[msg.sender] = 0;

        emit ManagerCreated(msg.sender);
    }

    // msg.sender is the new account which is requesting to be added
    // new accounts can only be added with password along with the owner account and NOT THE MAIN ACCOUNT
    // Front End will require both of these
    function addAccount(address ownerAccount) external accountExists(msg.sender) {
        s_ownerToWalletAccounts[ownerAccount].push(msg.sender);
        s_accountToBalance[msg.sender] = msg.sender.balance;
        s_accountToOwner[msg.sender] = ownerAccount;
        s_accountToWithdrawAmount[msg.sender] = 0;

        emit AccountAdded(msg.sender, ownerAccount);
    }

    function transferTo(
        address account
    ) external payable nonReentrant sameOwner(msg.sender, account) {
        uint256 value = msg.value;
        s_accountToBalance[msg.sender] -= value;
        s_accountToWithdrawAmount[account] += value;

        emit TransferSuccess(msg.sender, account, value);
    }

    // not send msg.value. balance will be transferred (max possible)
    function transferAll() external payable nonReentrant notOwner(msg.sender) {
        uint256 value = msg.value;
        s_accountToBalance[s_accountToOwner[msg.sender]] += value;
        s_accountToWithdrawAmount[s_accountToOwner[msg.sender]] += value;
        s_accountToBalance[msg.sender] -= value;

        emit TransferSuccess(msg.sender, s_accountToOwner[msg.sender], value);
    }

    function withdraw() external nonReentrant {
        uint256 toPay = s_accountToWithdrawAmount[msg.sender];
        s_accountToBalance[msg.sender] += toPay;
        s_accountToWithdrawAmount[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: toPay}("");

        if (!success) {
            revert Manager__TransferFailed();
        }

        emit Withdrawn(msg.sender, toPay);
    }

    function deleteManager() external isOwner(msg.sender) {
        address[] memory allAccounts = s_ownerToWalletAccounts[msg.sender];
        uint256 size = allAccounts.length;

        for (uint256 i = 0; i < size; i++) {
            if (s_accountToWithdrawAmount[allAccounts[i]] != 0) {
                revert Manager__AccountNotEmpty(allAccounts[i]);
            }
        }

        for (uint256 i = 0; i < size; i++) {
            delete (s_accountToBalance[allAccounts[i]]);
            delete (s_accountToOwner[allAccounts[i]]);
        }

        delete (s_ownerToWalletAccounts[msg.sender]);
        emit ManagerDeleted(msg.sender);
    }

    function deleteAccount(address account) external ifChild(msg.sender, account) {
        require(s_accountToWithdrawAmount[account] == 0, "Account Not Empty");

        delete (s_accountToBalance[account]);
        delete (s_accountToOwner[account]);
        delete (s_accountToWithdrawAmount[account]);

        emit AccountDeleted(msg.sender);
    }

    ///////////////////////
    /// Getter Functions///
    ///////////////////////
    // function getAccounts() public view returns (address[] memory) {
    //     address owner = s_accountToOwner[msg.sender];
    //     return s_ownerToWalletAccounts[owner];
    // }

    function getBalanceOf(address account) public view returns (uint256) {
        // add if owner to this funtion and the owner will be the main account
        return s_accountToBalance[account];
    }

    function getOwnerOf(address account) public view returns (address) {
        return s_accountToOwner[account];
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getWithdrawAmount() public view returns (uint256) {
        return s_accountToWithdrawAmount[msg.sender];
    }
}