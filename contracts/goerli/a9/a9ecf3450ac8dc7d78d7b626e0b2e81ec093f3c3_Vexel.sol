/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: MIT


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: vexel.sol



pragma solidity ^0.8.17;


contract Vexel{

    IERC20 token;
    address owner;

    struct VexelData {
        address from;
        address to;
        uint256 amount; 
    }

    string public future = "Hello, Dolly!";
    mapping(string => VexelData) private vexels;

    uint counter = 1;

    constructor(address _token) {
        token = IERC20(_token);
        owner = msg.sender;
    }
  
    function createVexel(uint256 _amount, address _to) external returns(string memory) {
        string memory vexel = randomString(15);
        require(vexels[vexel].from == address(0x0000000000000000000000000000000000000000), "Bank: Please try again");
        require(token.balanceOf(msg.sender) >= _amount , "Bank: You don't have enough tokens!!!");
        token.transferFrom(msg.sender, address(this), _amount + ((_amount * 1) / 100));
        uint256 fee = (_amount * 1) / 100;
        token.transfer(owner, fee);
        vexels[vexel] = VexelData(msg.sender, _to, _amount - fee);
        return vexel;
    }

    function cashOutVexel(string memory vexel) external returns(bool) {
        require(vexels[vexel].to == msg.sender, "Bank: You are not the recipient of the Vexel!");
        address _to = msg.sender;
        uint256 _amount = vexels[vexel].amount;
        delete vexels[vexel];
        token.transfer(_to, _amount);
        return true;
    }

    function randomString(uint size) internal returns(string memory) {
        bytes memory randomWord = new bytes(size);
        bytes memory chars = new bytes(35);
        chars="abcdefghijklmnopqrstuvwxyz123456789";
        for (uint i=0;i<size;i++){
            uint randomNumber=random(35);
            randomWord[i]=chars[randomNumber];
        }
        return string(randomWord);
    }

    function random(uint number) internal returns(uint) {
        counter++;
        return uint(keccak256(abi.encodePacked(block.timestamp, number, msg.sender, counter))) % number;
    }
}