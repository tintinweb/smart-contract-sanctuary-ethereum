// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//////////////////////////////////////////////////////////////////////////////////////
// @title   Peanut Protocol
// @dev     This contract is used to send non front-runnable link payments. These can
//          be erc20, erc721, or just plain eth. The recipient address is arbitrary.
// @version 2.0
// @author  H & K
// @dev     This contract is used to send link payments.
// @dev     more at: https://peanut.to
//////////////////////////////////////////////////////////////////////////////////////
//⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
//                         ⠀⠀⢀⣀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣶⣶⣦⣌⠙⠋⢡⣴⣶⡄⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠀⣿⣿⣿⡿⢋⣠⣶⣶⡌⠻⣿⠟⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⡆⠸⠟⢁⣴⣿⣿⣿⣿⣿⡦⠉⣴⡇⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⠟⠀⠰⣿⣿⣿⣿⣿⣿⠟⣠⡄⠹⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⢸⡿⢋⣤⣿⣄⠙⣿⣿⡿⠟⣡⣾⣿⣿⠀⠀⠀
// ⠀⠀⠀⠀⠀⠀⠀⠀⣠⣴⣾⠿⠀⢠⣾⣿⣿⣿⣦⠈⠉⢠⣾⣿⣿⣿⠏⠀⠀⠀
// ⠀⠀⠀⠀⣀⣤⣦⣄⠙⠋⣠⣴⣿⣿⣿⣿⠿⠛⢁⣴⣦⡄⠙⠛⠋⠁⠀⠀⠀⠀
// ⠀⠀⢀⣾⣿⣿⠟⢁⣴⣦⡈⠻⣿⣿⡿⠁⡀⠚⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠘⣿⠟⢁⣴⣿⣿⣿⣿⣦⡈⠛⢁⣼⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⢰⡦⠀⢴⣿⣿⣿⣿⣿⣿⣿⠟⢀⠘⠿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠘⢀⣶⡀⠻⣿⣿⣿⣿⡿⠋⣠⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⢿⣿⣿⣦⡈⠻⣿⠟⢁⣼⣿⣿⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠈⠻⣿⣿⣿⠖⢀⠐⠿⠟⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
// ⠀⠀⠀⠀⠈⠉⠁⠀⠀⠀⠀⠀
//
//////////////////////////////////////////////////////////////////////////////////////

// imports
import "Ownable.sol"; //
import "IERC20.sol";
import "IERC721.sol";
import "IERC1155.sol";

contract PeanutV2 is Ownable {
    struct deposit {
        address tokenAddress; // address of the token being sent. 0x0 for eth
        uint8 contractType; // 0 for eth, 1 for erc20, 2 for erc721, 3 for erc1155
        uint256 amount; // amount of tokens being sent
        uint256 tokenId; // id of the token being sent if erc721 or erc1155
        address sender; // sender can always withdraw (20 bytes)
        bytes32 key; // hash of the deposit password. Could also be asymmetric crypto. (20 bytes)
        address claimer; // inits to 0x0 (20 bytes)
        uint256 unlockUntilBlockNumber; // Block window up until which the deposit is locked (32 bytes)
        uint256 lockCost; // to protect against DoS Attacks(32 bytes)
        bool senderCanWithdraw; // whether the sender can withdraw their own tx (1 byte)
        bool ownerCanWithdraw; // whether this is a trusted sponsored transaction (1 byte)
    } // bytes: 20 + 1 + 32 + 32 + 20 + 32 + 20 + 32 + 32 + 1 + 1 = 223 bytes. Can be optimized.

    deposit[] public deposits; // array of deposits

    // events
    event Deposit(address indexed sender, uint256 amount, uint256 index);
    event Withdraw(address indexed recipient, uint256 amount);

    // constructor
    constructor() public {
        // nothing to do here
    }

    /**
     * @dev Function to make a deposit
     * @param _tokenAddress address of the token being sent. 0x0 for eth
     * @param _contractType uint8 for the type of contract being sent. 0 for eth, 1 for erc20, 2 for erc721, 3 for erc1155
     * @param _amount uint256 of the amount of tokens being sent (if erc20)
     * @param _tokenId uint256 of the id of the token being sent if erc721 or erc1155
     * @param _key bytes32 of the hash of the deposit password.
     * @param _lockCost uint256 of the cost in wei to lock the deposit to claimer
     * @param _senderCanWithdraw bool of whether the sender can withdraw the deposit
     * @param _ownerCanWithdraw bool of whether the owner can withdraw the deposit
     * @return uint256 of the index of the deposit
     */
    function makeDeposit(
        address _tokenAddress,
        uint8 _contractType,
        uint256 _amount,
        uint256 _tokenId,
        bytes32 _key,
        uint256 _lockCost,
        bool _senderCanWithdraw,
        bool _ownerCanWithdraw
    ) external payable returns (uint256) {
        // check that the contract type is valid
        require(_contractType < 4, "Invalid contract type");

        // handle eth deposits
        if (_contractType == 0) {
            // check that the amount sent is equal to the amount being deposited
            require(msg.value > 0, "No eth sent");

            // create the deposit
            deposits.push(
                deposit({
                    tokenAddress: _tokenAddress,
                    contractType: _contractType,
                    amount: _amount,
                    tokenId: _tokenId,
                    sender: msg.sender,
                    key: _key,
                    claimer: address(0),
                    unlockUntilBlockNumber: 0,
                    lockCost: _lockCost,
                    senderCanWithdraw: _senderCanWithdraw,
                    ownerCanWithdraw: _ownerCanWithdraw
                })
            );
        } else if (_contractType == 1) {
            IERC20 token = IERC20(_tokenAddress);
            token.transferFrom(msg.sender, address(this), _amount);

            // create the deposit
            deposits.push(
                deposit({
                    tokenAddress: _tokenAddress,
                    contractType: _contractType,
                    amount: _amount,
                    tokenId: _tokenId,
                    sender: msg.sender,
                    key: _key,
                    claimer: address(0),
                    unlockUntilBlockNumber: 0,
                    lockCost: _lockCost,
                    senderCanWithdraw: _senderCanWithdraw,
                    ownerCanWithdraw: _ownerCanWithdraw
                })
            );
        } else if (_contractType == 2) {
            IERC721 token = IERC721(_tokenAddress);
            token.transferFrom(msg.sender, address(this), _tokenId);

            // create the deposit
            deposits.push(
                deposit({
                    tokenAddress: _tokenAddress,
                    contractType: _contractType,
                    amount: _amount,
                    tokenId: _tokenId,
                    sender: msg.sender,
                    key: _key,
                    claimer: address(0),
                    unlockUntilBlockNumber: 0,
                    lockCost: _lockCost,
                    senderCanWithdraw: _senderCanWithdraw,
                    ownerCanWithdraw: _ownerCanWithdraw
                })
            );
        } else if (_contractType == 3) {
            IERC1155 token = IERC1155(_tokenAddress);
            token.safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId,
                _amount,
                ""
            );

            // TODO: Support IERC1155Receiver

            // create the deposit
            deposits.push(
                deposit({
                    tokenAddress: _tokenAddress,
                    contractType: _contractType,
                    amount: _amount,
                    tokenId: _tokenId,
                    sender: msg.sender,
                    key: _key,
                    claimer: address(0),
                    unlockUntilBlockNumber: 0,
                    lockCost: _lockCost,
                    senderCanWithdraw: _senderCanWithdraw,
                    ownerCanWithdraw: _ownerCanWithdraw
                })
            );
        }

        // emit the deposit event
        emit Deposit(msg.sender, _amount, deposits.length - 1);

        // return id of new deposit
        return deposits.length - 1;
    }

    // sender can withdraw deposited assets at any time
    function withdrawSender(uint256 _index) external {
        require(_index < deposits.length, "DEPOSIT INDEX DOES NOT EXIST");
        require(
            deposits[_index].senderCanWithdraw,
            "DEPOSIT DOES NOT ALLOW SENDER TO WITHDRAW"
        );
        require(
            deposits[_index].sender == msg.sender,
            "MUST BE SENDER TO WITHDRAW"
        );

        // handle eth deposits
        if (deposits[_index].contractType == 0) {
            // send eth to sender
            payable(msg.sender).transfer(deposits[_index].amount);
        } else if (deposits[_index].contractType == 1) {
            IERC20 token = IERC20(deposits[_index].tokenAddress);
            token.transfer(msg.sender, deposits[_index].amount);
        } else if (deposits[_index].contractType == 2) {
            IERC721 token = IERC721(deposits[_index].tokenAddress);
            token.transferFrom(
                address(this),
                msg.sender,
                deposits[_index].tokenId
            );
        } else if (deposits[_index].contractType == 3) {
            IERC1155 token = IERC1155(deposits[_index].tokenAddress);
            token.safeTransferFrom(
                address(this),
                msg.sender,
                deposits[_index].tokenId,
                deposits[_index].amount,
                ""
            );
        }

        // emit the withdraw event
        emit Withdraw(msg.sender, deposits[_index].amount);

        // delete the deposit
        delete deposits[_index];
    }

    // centralized transfer function to transfer ether to recipients newly created wallet
    function withdrawDepositOwner(uint256 _index, address _recipient)
        external
        onlyOwner
    {
        require(_index < deposits.length, "DEPOSIT INDEX DOES NOT EXIST");
        // require that the deposits[idx] is not deleted
        require(
            deposits[_index].sender != address(0),
            "DEPOSIT ALREADY WITHDRAWN"
        );

        // handle eth deposits
        if (deposits[_index].contractType == 0) {
            // send eth to recipient
            payable(_recipient).transfer(deposits[_index].amount);
        } else if (deposits[_index].contractType == 1) {
            IERC20 token = IERC20(deposits[_index].tokenAddress);
            token.transfer(_recipient, deposits[_index].amount);
        } else if (deposits[_index].contractType == 2) {
            IERC721 token = IERC721(deposits[_index].tokenAddress);
            token.transferFrom(
                address(this),
                _recipient,
                deposits[_index].tokenId
            );
        } else if (deposits[_index].contractType == 3) {
            IERC1155 token = IERC1155(deposits[_index].tokenAddress);
            token.safeTransferFrom(
                address(this),
                _recipient,
                deposits[_index].tokenId,
                deposits[_index].amount,
                ""
            );
        }

        // emit the withdraw event
        emit Withdraw(_recipient, deposits[_index].amount);

        // delete the deposit
        delete deposits[_index];
    }

    // Decentralized claim function.

    // 1. claimer lock functionality. Sets the recipient address and opens a 100 block timewindow in which the claimer can withdraw the deposit.
    // Costs some ETH to prevent spamming and DoS attacks. Is later refunded to the sender.
    function openDepositWindow(uint256 _depositIdx) public payable {
        require(
            msg.value >= deposits[_depositIdx].lockCost,
            "NOT ENOUGH ETH TO OPEN DEPOSIT WINDOW"
        );
        require(
            block.number > deposits[_depositIdx].unlockUntilBlockNumber,
            "DEPOSIT WINDOW STILL OPEN"
        );

        // set the claimer
        deposits[_depositIdx].claimer = msg.sender;

        // set the unlock block number
        deposits[_depositIdx].unlockUntilBlockNumber = block.number + 100;

        // emit the deposit window open event
        // emit DepositWindowOpen(msg.sender, _depositIdx);
    }

    // 2. claimer withdraw functionality. Withdraws the deposit to the recipient address.
    function withdrawDeposit(
        uint256 _index,
        bytes32 _key,
        address _recipient
    ) external {
        require(_index < deposits.length, "DEPOSIT INDEX DOES NOT EXIST");
        require(
            deposits[_index].claimer == msg.sender,
            "MUST BE CLAIMER TO WITHDRAW"
        );
        require(
            block.number < deposits[_index].unlockUntilBlockNumber,
            "DEPOSIT WINDOW NOT OPEN"
        );
        require(
            keccak256(abi.encodePacked(_key)) == deposits[_index].key,
            "KEY DOES NOT MATCH"
        );

        // handle eth deposits
        if (deposits[_index].contractType == 0) {
            // send eth to recipient
            payable(_recipient).transfer(deposits[_index].amount);
        } else if (deposits[_index].contractType == 1) {
            IERC20 token = IERC20(deposits[_index].tokenAddress);
            token.transfer(_recipient, deposits[_index].amount);
        } else if (deposits[_index].contractType == 2) {
            IERC721 token = IERC721(deposits[_index].tokenAddress);
            token.transferFrom(
                address(this),
                _recipient,
                deposits[_index].tokenId
            );
        } else if (deposits[_index].contractType == 3) {
            IERC1155 token = IERC1155(deposits[_index].tokenAddress);
            token.safeTransferFrom(
                address(this),
                _recipient,
                deposits[_index].tokenId,
                deposits[_index].amount,
                ""
            );
        }

        // emit the withdraw event
        emit Withdraw(_recipient, deposits[_index].amount);

        // delete the deposit
        delete deposits[_index];
    }

    //// Some utility functions ////
    function getDepositCount() external view returns (uint256) {
        return deposits.length;
    }

    function getDeposit(uint256 _index) external view returns (deposit memory) {
        return deposits[_index];
    }

    function getDepositsSent(address _sender)
        external
        view
        returns (deposit[] memory)
    {
        deposit[] memory depositsSent = new deposit[](deposits.length);
        uint256 count = 0;
        for (uint256 i = 0; i < deposits.length; i++) {
            if (deposits[i].sender == _sender) {
                depositsSent[count] = deposits[i];
                count++;
            }
        }
        return depositsSent;
    }

    // and that's all! Have a nutty day!
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}