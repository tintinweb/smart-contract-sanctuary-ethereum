//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
 
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Bank is Pausable {
    address public owner;

    /// @dev this a mapping of the users address to their ether balances
    mapping(address => uint) private balance;
    /// @dev this is a mapping for tracking user address to erc20 token address to their value
    mapping(address => mapping(address => uint)) private tokenList;



    event _transfer_ether(address indexed from, address indexed to, uint amount); // event to log transfer
    event _deposit_ether(address indexed _owner, uint amount); // event to log withdraw
    event _transfer_erc20(address token, address indexed _owner, address indexed to, uint amount); // event to log withdraw
    event _deposit_erc20(address token, address indexed owner, uint amount);
    event _recover(address indexed _to, address indexed _tokenAddress, uint _amt); // event to log recovered funds

    constructor() {
        owner = msg.sender;
    }

    // only owner modifier
    modifier onlyOwner(){
        require(msg.sender == owner, "You can't perform this transaction");
        _;
    }
    
    // modifier to verify address and amount
    modifier verifyAddress(uint _amount){
        require(msg.sender != address(0), "You can't withdraw here!!");
        require(balance[msg.sender] >= _amount, "Insufficeint balance");
        _;
    }

    /// @dev this function will deposit erc20 token into the contract
    function depositERC20Token(address _tokenAddress, uint amount) external whenNotPaused {
       bool transfer_status = IERC20(_tokenAddress).transferFrom(msg.sender, address(this), amount); // this is the line that is failing
       require(transfer_status, "Transfer failed");

       tokenList[msg.sender][_tokenAddress] += amount;

       emit _deposit_erc20(_tokenAddress,msg.sender,amount);
    }

    /// @dev this function will withdraw erc20 token from the contract
    function transferERC20Token(address _to, address _tokenAddress, uint _amount) external whenNotPaused {
        require(msg.sender != _to, "sender can't be reciever");
        uint userBalance = tokenList[msg.sender][_tokenAddress];
        require(userBalance >= _amount, "Insufficient fund");
        tokenList[msg.sender][_tokenAddress] -= _amount;
        bool transfer_status = IERC20(_tokenAddress).transfer(_to, _amount);

    // question: revert changes the state of a contract to the init tate right? if this transaction fails, the money deducted from the bal, would it be reverted to the init state

       require(transfer_status, "Withdraw Error");
       emit _transfer_erc20(_tokenAddress, msg.sender, _to, _amount); 
    }

    function getERC20TokenBalance(address _tokenAddress) external view returns(uint ) {
        return tokenList[msg.sender][_tokenAddress];
    }

    // function to deposit ether into the contract
    function deposit() public payable whenNotPaused {
        require(msg.value > 0, "Zero not allowed");
        balance[msg.sender] += msg.value;
        emit _deposit_ether(msg.sender, msg.value);
    }

    //a recieve function that gets money that is mistakenly sent to the contract
    receive() external payable {
        deposit();
    }

    // function to transfer ether from one address to another
    function transfer(address _to, uint _amt) external payable verifyAddress(_amt) whenNotPaused {
        require(_to != address(0), "Invalid address");
        require(_to != msg.sender, "this address can't spend tokens");
        balance[msg.sender] -= _amt;
        payable(_to).transfer(_amt);
        emit _transfer_ether(msg.sender, _to, _amt);
    }

    // function to get the balance of ether
    function getBalance() external view returns(uint) {
        return balance[msg.sender];
    }

    // function to get theh balance of the contract
    function getWalletBalance() external view returns(uint){
        return address(this).balance;
    }

    // function to pause some function in the contract
    function pause() external onlyOwner {
        _pause();
    }

    // function to unpause some function in the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev this function would be used by admin to withdraw an ERC20 token locked in the contract, providing the token address ans the amount they wish to withdraw
    function recoverTrappedMoney(address _to, address _tokenAddress, uint _amt) external onlyOwner returns (bool) {
        require(_to != address(0), "ERC20: transfer to the zero address");

        bool transfer_status = IERC20(_tokenAddress).transfer(_to, _amt);

        if(transfer_status) {
            emit _recover(_to, _tokenAddress, _amt);
            return true;
        }else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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