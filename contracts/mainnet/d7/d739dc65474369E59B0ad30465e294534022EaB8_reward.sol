/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: MIT
// File: github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)
pragma solidity ^0.8.7;
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

// File: project1.sol

pragma solidity ^0.8.7;


contract reward{
     address private owner;
     string private password;
    constructor(string memory _password){
        owner=msg.sender;
        password=_password;
    }
    modifier onlyOwner() {  
              require(msg.sender == owner);  
                    _;    }
    uint256 Rewardtoken=50000000000000000000000;
    IERC20 Token=IERC20(0x66fD97a78d8854fEc445cd1C80a07896B0b4851f);
    mapping(address=>string) private allow;
    mapping(address=>bool) private isAllowed;
     bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;
   function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexStringv(value, length);
    }
     function toHexStringv(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "M";
         buffer[1] = "Y";
        for (uint256 i = 2 * length +1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

   function hash() public  returns (string memory ) {
        //  bytes32 ref1= keccak256(abi.encodePacked(msg.sender));

         string memory b=toHexString(block.timestamp);
          string memory a="L";
          string memory last =string(bytes.concat(bytes(a), "", bytes(b)));
          allow[msg.sender]=last;
          isAllowed[msg.sender]=false;
        return last;
    }                                                     
   function getreward(string memory value,string memory _password) public  returns(bool){
       string memory a=allow[msg.sender];
       require(keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((value))),"incoorect code");
        require(keccak256(abi.encodePacked((_password))) == keccak256(abi.encodePacked((password))),"incoorect code");
       require(isAllowed[msg.sender]==false,"already received rewards");
       uint256 balance=Token.balanceOf(address(this));
       require(balance>=Rewardtoken,"Contract balance is low");
       bool check=Token.transfer(msg.sender,Rewardtoken);
       require(check);
       isAllowed[msg.sender]=true;
       return true;
   }
   function viewCode(address _address) public view returns(string memory){
       return allow[_address];
   }
   function changeRewardAmount(uint256 _value) public onlyOwner returns(bool){
       Rewardtoken=_value;
       return true;
   }
   function changepassword(string memory _newpassword) public onlyOwner returns(bool){
       password=_newpassword;
       return true;
   }
}