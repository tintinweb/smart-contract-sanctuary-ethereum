/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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



/***We can store the slab information in a single uint256 using a bitmap. The uint256 can be divided into sets of 
16 slabs each containing 16 bits accounting for 256 bits. The specific slabs can be accessed using a mask. One
16 bit slab either the highest [2**240 to 2**256(not inclusive)] or the lowest [2**0 to 2**16(not inclusive)]
can be reserved for current slab position. The aforementioned design pattern enables us to store slab information
in a very efficient manner because a single uint256 is used. Also for operations they will be less gas intensive
because the same storage slot of the uint256 will be accessed multiple times saving lots of gas.
*/
contract ERC20Collector {
    //Define number of slabs and size of slabs in slab array. The array index serves as slab level
    //So slab[4] is slab of highest level with slab size of 500. If ERC20 deposit exceeds 500 it shifts to next slab
    //which is slab[3]
    uint16[] public slab = [100, 200, 300, 400, 500];

    //mask field which we can use to extract values of certain range of bits from bitmap using xor
    uint256 mask = type(uint16).max;
    uint256 slabBitmap = (slab.length - 1) << 240;

    //Specific ERC20 token to be deposited. Can allow depositing multiple erc20 tokens by using a mapping(address => uint256).
    //Will add if time remains.
    address public tokenAddress;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function deposit(uint256 amount, address _tokenAddress) external {
        require(tokenAddress == _tokenAddress, "ERC20 addresses don't match");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        _updateSlabs(amount);
    }

    function _updateSlabs(uint256 amount) internal {
        uint256 currentSlab = checkCurrentSlab(); //Access current slab position from the 16th slab
        uint256 value;
        uint256 currentSlabDepositedValue = _fetchSlabValue(currentSlab);
        uint256 spaceInCurrentSlab = slab[currentSlab] -
            currentSlabDepositedValue;

        if (spaceInCurrentSlab >= amount) {
            //amount deposited fits into current slab, current slab stays the same
            value = currentSlabDepositedValue + amount;
            _updateSlabBitmap(currentSlab, value);
        } else {
            amount -= spaceInCurrentSlab;
            //amount deposited does not fit into current slab, current slab fills up, current slab changes, leftover amount deducts from new slab
            _updateSlabBitmap(currentSlab, slab[currentSlab]);
            // If depositor exceeds the amount of total tokens which can be deposited transaction will revert here as well in the recursive calls
            require(
                currentSlab > 0,
                "Slabs are all filled up. Cannot accept any more tokens"
            );
            --currentSlab; // The token is deposited on a lower level so current slab position decreases by 1. --x is more gas efficient than x--
            _updateSlabBitmap(15, currentSlab); //Update currentSlab value to its position which is the 16th slab
            _updateSlabs(amount); // Recursive calls can be dangerous. Have to test this rigorously.
        }
    }

    function _fetchSlabValue(uint256 position)
        internal
        view
        returns (uint256 value)
    {
        // check slab value by shifting mask to the same bits as slab bits and using bitwise and we can isolate
        // the value. Then using left shift and shifting it according to its slab position we can get the actual value
        value = slabBitmap & (mask << (16 * position));
        value = value >> (16 * position);
    }

    function _updateSlabBitmap(uint256 position, uint256 value) internal {
        slabBitmap = slabBitmap & ~(mask << (16 * position)); //Change slab value in slabbitmap to all zeroes. Rest of the map stays the same
        slabBitmap = slabBitmap | (value << (16 * position)); //Update slabbitmap value to value we desire
    }

    function checkCurrentSlab() public view returns (uint256 slabPosition) {
        slabPosition = _fetchSlabValue(15);
    }
}