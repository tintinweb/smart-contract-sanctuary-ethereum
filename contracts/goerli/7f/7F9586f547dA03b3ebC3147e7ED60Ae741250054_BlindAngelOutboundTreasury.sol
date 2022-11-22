// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlindAngelOutboundTreasury is Ownable {
    
    event Transfer(address indexed createdBy, address indexed dealedBy, address to, uint256 value);
    event Deposit(address indexed dealer, uint256 amount);
    event Withdraw(address indexed dealer, address indexed creator, address to, uint256 amount);
    event AddSigner(address indexed dealer, address indexed creator, address signer);
    event RemoveSigner(address indexed dealer, address indexed creator, address signer);

    struct TransferRequest {
        bool isActive;
        address createdBy;
        address to;
        uint256 value;
        uint256 created_at;
    }

    struct SignerRequest {
        address createdBy;
        address signer;
        bool status;
        bool isActive;
    }

    struct AdminExist {
        uint256 index;
        bool status;
    }

    struct WithdrawStruct {
        address creator;
        address to;
        uint256 amount;
        bool isActive;
    }

    TransferRequest public transferRequest;
    SignerRequest public signerRequest;
    WithdrawStruct public withdrawRequest;

    address[] private admins;
    mapping(address => AdminExist) public adminsExist;

    modifier onlySigners() {
        require(adminsExist[msg.sender].status, "not signer");
        _;
    }
    
    constructor(
        address[] memory _owners
    ) {
        require(_owners.length > 1, "Signer is 2 at least." );
        for (uint256 i = 0; i < _owners.length; i ++) {
            admins.push(_owners[i]);
            adminsExist[_owners[i]] = AdminExist(i, true);
        }
    }

    // start transfer part
    
    function newTransferRequest(address to, uint256 value) public onlySigners {
        transferRequest = TransferRequest({
            to: to,
            value: value,
            isActive: true,
            createdBy: msg.sender,
            created_at: block.timestamp
        });
        
    }
    
    function declineTransferRequest() public onlySigners {
        require(transferRequest.isActive);
        
        transferRequest.isActive = false;
    }

    function approveTransferRequest() public onlySigners {
        require(transferRequest.isActive);
        require(transferRequest.createdBy != msg.sender, "can't approve transaction you created");
        
        (bool sent, ) = payable(transferRequest.to).call{value: transferRequest.value}("");

        require(sent, "Failure! Not withdraw");

        transferRequest.isActive = false;
        emit Transfer(transferRequest.createdBy, msg.sender, transferRequest.to, transferRequest.value);
    }

    // end transfer part

    function newSignerRequest(address signer, bool status) public onlySigners {
        require(signer != msg.sender, "can't request self address");
        require(signer != address(0), "invalid address");

        if (adminsExist[signer].status == status) {
            if (status) revert("signer is already existed");
            else revert("signer is not existed");
        }

        if (!status) {
            require(admins.length > 2, "admin count is 2 at least");
        }

        signerRequest = SignerRequest({
            createdBy: msg.sender,
            signer: signer,
            isActive: true,
            status: status
        });
        
    }
    
    function declineSignerRequest() public onlySigners {
        require(signerRequest.isActive);
        
        signerRequest.isActive = false;
    }

    function approveSignerRequest() public onlySigners {
        require(signerRequest.isActive);
        require(signerRequest.createdBy != msg.sender, "can't approve transaction you created");
        
        address signer = signerRequest.signer;
        if (signerRequest.status) {
            admins.push(signer);
            adminsExist[signer] = AdminExist(admins.length - 1, true);
            emit AddSigner(msg.sender, signerRequest.createdBy, signer);
        } else {
            uint256 index = adminsExist[signer].index;
            if (index != admins.length - 1) {
                admins[index] = admins[admins.length -1];
                adminsExist[admins[index]].index = index;
            }
            emit RemoveSigner(msg.sender, signerRequest.createdBy, signer);
            delete adminsExist[signer];
        }
    }
    
    function newWithdrawRequest(address to, uint256 amount) external onlySigners {
        require(amount > 0, "withdraw amount must be greater than zero");
        require(to != address(0), "withdraw not allow to empty address");

        withdrawRequest = WithdrawStruct({
            creator: msg.sender,
            to: to,
            amount: amount,
            isActive: true
        });
    }

    function approveWithdrawRequest() external onlySigners {
        require(withdrawRequest.isActive, "withdraw is not requested");
        require(withdrawRequest.creator != msg.sender, "caller is not available to approve");

        (bool sent, ) = payable(withdrawRequest.to).call{value: withdrawRequest.amount}("");

        require(sent, "Failure! Not withdraw");

        withdrawRequest.isActive = false;
        emit Withdraw(msg.sender, withdrawRequest.creator, withdrawRequest.to, withdrawRequest.amount);
    }

    function declineWithdrawRequest() external onlySigners {
        require(withdrawRequest.isActive, "withdraw is not requested");

        withdrawRequest.isActive = false;
    }

    function deposit() external payable {
        require(msg.value > 0, "insufficient funds");
        emit Deposit(msg.sender, msg.value);
    }

    function getAdmins() public view returns(address[] memory) {
        return admins;
    }

    receive() external payable {}
    
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