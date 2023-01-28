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
pragma solidity ^0.8.17;


// @Author: Alireza Haghshenas github: alireza1691


interface IMain {


// event Deposit(address indexed from, uint256 indexed amount, address indexed tokenAddress);
// event Whithdraw(address indexed to, uint256 indexed amount, address indexed tokenAddress);

function updateUserBalances (uint256 amount, address userAddress, address tokenAddress, bool isSum) external;
function getUserBalances (address userAddress, address tokenAddress) external returns(uint256);
// function depositToken (uint256 amount, address tokenContractAddress) external;
// function withdrawToken (uint256 amount, address tokenContractAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./IMain.sol";

// Author: Alireza Haghshenas    git: @alireza1691
// This contract will update balance of users and return the their balances which Gate contract and Pair contracts are in have been interacted with this

error Main__InsufficientBalance();
error Main__ContractNotAllowed();
contract Main is IMain{

// Owner can add contracts(Pair & Gate) that they can call update function.
address payable private owner;

// Set owner in constructor
constructor() {
    owner = payable(msg.sender);
}
// Shows user balances for each token (Useer address => Token Address => 'Balance')
mapping (address => mapping(address => uint256)) public userBalances;
// A boolean that shows if enterd cotract address allowed to call updateBalance function or not
mapping (address => bool) private isAllowed;

// Show balance of user for specific token
function getUserBalances(address userAddress, address tokenAddress) public view returns (uint256){
    return userBalances[userAddress][tokenAddress];
}
// Update balance of token, This function could called by pair contracts and gate
// When user deposits or withdraws tokens, gate contract updates balance of user by this function in interface.
function updateUserBalances(uint256 amount, address userAddress, address tokenAddress, bool isSum) external onlyAllowedContracts{
    if (isSum) {
        _increaseBalance(amount, userAddress, tokenAddress);
    } else {
        _decreaseBalance(amount, userAddress, tokenAddress);
    }
}
// Private funcs that they called by last function and depend on isSum balance of user increases or decreases.
function _increaseBalance (uint256 amount, address userAddress, address tokenAddress) private{
    userBalances[userAddress][tokenAddress] += amount;
}
function _decreaseBalance (uint256 amount, address userAddress, address tokenAddress) private{
    userBalances[userAddress][tokenAddress] -= amount;
}
// Pair contracs and Gate s contracs sould added by owner using this function which they can interact with this contract
function addNewAllowedContract(address newPairAddress) external onlyOwner{
    require(msg.sender == owner );
    isAllowed[newPairAddress] = true;
}
// Update function just can called by the contracts that owner added as a Pair or Gate.
modifier onlyAllowedContracts() {
    // require(isAllowed[msg.sender] == true);
    if (isAllowed[msg.sender] == false) {
        revert Main__ContractNotAllowed();
    }
    _;
}
// Just owner can add new pair or gate contract , so in the addNewPairContract we use this modifer.
modifier onlyOwner(){
    // require(msg.sender == owner);
    if (msg.sender != owner) {
        revert Main__ContractNotAllowed();
    }
    _;
}


}