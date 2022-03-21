/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.7.6;



// Part: Eboos

// Part: Eboos

abstract contract  Eboos  {
    //    function mint(address to ) public ;
    function premint(uint256 quantity) virtual external payable ;
    function getPrice() public virtual view returns (uint256);
}

// Part: OpenZeppelin/[email protected]/IERC20

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// File: mint.sol

//interface IERC20 {
//    function transfer(address _to, uint256 _amount) external returns (bool);
//}
// File: CallContract.sol

contract CallContract  {
    address public _owner;
    address public eboos_addr = 0x956d8Ca6511B59d3AC8A3156A9168f49a6aba938;
    Eboos public eboo;

    //0x76FeC53340eEb0B4FCDE5491C778Db80b012B370
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() public{
        _owner = msg.sender;
        eboo = Eboos(eboos_addr);
    }
    function mintfrom() payable  public  {
        eboo.premint{value:msg.value}(1);
    }
    function getPrice() public view returns (uint256){
        return eboo.getPrice();
    }
    receive() external payable{}
    function deposit() public payable{
    }

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data)
    public payable
    returns(bytes4)
    {
        bytes4 return_val =
        bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
        return return_val;
    }
    function withdrawETH() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }
    function kill() public onlyOwner {
        selfdestruct(msg.sender);
    }
    function withdrawToken(address _tokenContract, uint256 _amount) public onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }

    function withdrawERC721() public onlyOwner {


    }
//    function tranferNFT(address to, uint tokenId) external onlyOwner {
//        this.safeTransferFrom(address(this), to,  tokenId);
//    }

}