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

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Yebelo {
    //creating a instance of erc20 token
    IERC20 token;
    //User defined data type, structure to store slab and depsoitedAmount
    struct Slab{
    uint8[] slab;
    uint16 depositedAmount;
    }

    uint16 totalCapacity;

    //constructor for passing custom values for the slabs
    constructor(uint16[] memory temp) {
        for (uint8 i = 0; i < 5; i++) {
            slabsToCapacity[i] = temp[i];
            totalCapacity += temp[i];
        }
    }

    //mapping to show slabs and their capacity
    mapping(uint16 => uint16) public slabsToCapacity;

    //address of user mapp to structure to show slab and deposited Amount
    mapping(address => Slab) userDetail;

    //deposit function
    //It takes two argument address of the ERC20 token and the amount that user wants to deposit
    function depositToken(
        address _token ,
        uint16 _amount
    ) public {
        token = IERC20(_token);
        require(_amount > 0, "Amount must be greater than Zero");
        //checking whether user have enough tokens
        require(
            token.balanceOf(msg.sender) >= _amount,
            "You dont have enough Token to deposit"
        ); 
        //Checking whether amount exceed the slab capacity
        require(_amount <= totalCapacity, "Don't have space");
        userDetail[msg.sender].depositedAmount = _amount;
        //Current Capacity 
        totalCapacity -= _amount;
        uint amountTransfer = _amount;
        for (uint8 i = 4; i >= 0; i--) {
            if (_amount != 0) {
                if (slabsToCapacity[i] != 0) {
                    if (slabsToCapacity[i] <= _amount) {
                        _amount -= slabsToCapacity[i];
                        slabsToCapacity[i] = 0;
                        userDetail[msg.sender].slab.push(i + 1);
                    } else {
                        slabsToCapacity[i] -= _amount;
                        userDetail[msg.sender].slab.push(i + 1);
                        break;
                    }
                }
            }
        }
        //tranfering tokens from user to contract address
        require(
            token.transferFrom(msg.sender, address(this), amountTransfer),
            "You dont have allowance"
        ); 
    }

    //Function to show the slab money deposited
    function showSlab() public view returns (uint8[] memory) {
        require(userDetail[msg.sender].slab.length > 0, "Deposit Token First");
        return userDetail[msg.sender].slab;
    }
}