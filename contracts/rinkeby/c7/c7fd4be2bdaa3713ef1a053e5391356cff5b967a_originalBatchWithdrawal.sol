/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/4_BatchWithdrawal_ED.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


/**
 * @dev minimum ERC20 interface to be used by the BatchWithdraw contract
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
}

/**
 * @dev Contract for sending multiple transaction requests from multiple currencies (ERC20, ETH)
 */
contract originalBatchWithdrawal is Ownable{

    event Received(address, uint256);

    /**
     * @dev just to log the ETH topups for this contract
     */
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

     /**
     * @dev sends a internal transaction based on the currency specified in the
     * parameters, it use the ERC20 interface for currencies stored in the contracts
     * map
     */
    function withdrawalERC (IERC20 iERC20, address _client, uint256 _amount) private {
        require(_client != address(0), "address needs to be given");
        require(_amount > 0, "amount needs to be greater than 0");

        require(iERC20.balanceOf(address(this)) >= _amount, "not enough token funds to send transaction");
        iERC20.transfer(_client, _amount);
    }

     /**
     * @dev sends multiple internal transactions based on the currency specified in the
     * parameters, check "withdrawalERC" for more details, this method just handles the parameters list
     */
    function batchWithdrawalERC(address token_addr, address[] calldata _clients, uint256[] calldata _amounts) external onlyOwner {
        require(_clients.length == _amounts.length, "address, amount array length need to be equal");
        require(token_addr != address(0), "invalid contract address");

        IERC20 iERC20 = IERC20(token_addr);
        for (uint16 i=0; i < _clients.length; i++) {
            withdrawalERC(iERC20, _clients[i], _amounts[i]);
        }
    }


     /**
     * @dev sends a internal eth transaction
     */
    function withdrawalEth (address payable _client, uint256 _amount) private {
        require(_client != address(0), "address needs to be given");
        require(_amount > 0, "amount needs to be greater than 0");

        require(address(this).balance >= _amount, "not enough funds to send transaction");
        _client.transfer(_amount);
    }


     /**
     * @dev sends multiple internal eth transactions
     * params : list of address (amount receiver), list of amount
     */
    function batchWithdrawalEth(address[] calldata _clients, uint256[] calldata _amounts) external onlyOwner {
        require(_clients.length == _amounts.length, "address, amount array length need to be equal");
        for (uint16 i=0; i < _clients.length; i++) {
            withdrawalEth(payable(_clients[i]), _amounts[i]);
        }
    }

     /**
     * @dev Sending all funds to owner
     * @param token_addresses ERC20 contract address array from which the tokens to be moved to owner
     * @notice All ethereum balance at this contract will be moved to owner.
     */
    function moveFundsToOwner(address[] calldata token_addresses) payable external onlyOwner {

        for (uint8 i=0; i < token_addresses.length; i++) {
            require(token_addresses[i] != address(0), "token address needs to be given");
            IERC20 iERC20 = IERC20(token_addresses[i]);
            if(iERC20.balanceOf(address(this)) > 0){
                iERC20.transfer(msg.sender, iERC20.balanceOf(address(this)));
            }
        }

        if(address(this).balance > 0){
            payable (msg.sender).transfer(address(this).balance);
        }

    }
}