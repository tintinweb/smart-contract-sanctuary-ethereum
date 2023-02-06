/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

// File: contracts/getprice.sol


pragma solidity ^0.8.0;


/*
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
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

interface NFTToken {
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

interface nftToken {
    function transferFrom(address from, address to, uint256 tokenId) external;

    function getFirstMint(uint256 tokenId) external returns (address);
}

contract Market is Context, Ownable {

    bool public isSaleActive;

    address public nftAddr;// todo NFT address
    address public zeroAddress;// todo zero address
    address public bossAddr;// todo zero address
    uint256 public bossFee; // todo
    uint256 public firstOwnerFee;// todo
    mapping(uint256 => address) public idAddr; // todo tokenID Owner
    mapping(uint256 => uint256) public idPrice; // todo tokenID Price
    mapping(uint256 => bool) public isSell; // todo tokenID true/false
    mapping(address => uint256[]) public sellOrder; // todo tokenID already Sell .Order List
    mapping(address => mapping(uint256 => uint256)) public   sellOrderPrice; // todo tokenID already Sell .Order List
    //------------------------------------------todo  正在出售的订单 先依靠balanceOf 查询当前合约的余额，然后 依靠tokenByIndex 查询具体是哪几个id

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor () {
        zeroAddress = 0x0000000000000000000000000000000000000000;
        bossFee = 5;
        firstOwnerFee = 5;
        bossAddr = msg.sender;
    }
    //
    function flipSaleState() public onlyOwner {
        isSaleActive = !isSaleActive;
    }


    function setNftAddr(address addr) public onlyOwner {
        nftAddr = addr;
    }

    function setBossFee(uint256 fee) public onlyOwner {
        bossFee = fee;
    }

    function setFirstOwnerFee(uint256 fee) public onlyOwner {
        firstOwnerFee = fee;
    }

    function setBossAddr(address addr) public onlyOwner {
        bossAddr = addr;
    }

    function getFlipSaleState() public view returns (bool) {
        return isSaleActive;
    }

    function getSell(uint256 id) public view returns(bool){
        return isSell[id];
    }

    function getPrice(uint256 id) public view returns(uint256){
        return idPrice[id] / (1* 10 ** 14);
    }

    function getIdAddr(uint256 id) public view returns(address){
        return idAddr[id];
    }


    //返回的是 当前地址 出售的历史记录， 即 已经出售了的tokenId的集合 比如返回[1,2,3]代表已经出售了tokenId 为 1 2 3的三个NFT
    function getOrderList() public view returns(uint256[] memory){
        return sellOrder[msg.sender];
    }

    // 返回的是 当前持有人，对某个tokenId的最近一次的出售价格，如果一个人买了一个NFT，出售后，又买回来，重新继续出售，那么这里查询到的就是最近一次出售的价格；暂时不支持历史记录完整的查询
    function getOrderPrice(uint256 tokenId) public view returns(uint256){
        return sellOrderPrice[msg.sender][tokenId];
    }




    // 入参 代表查询发布总量之中多少处于出售状态
    function getSellList(uint256 total) public view returns(uint256[] memory){
        uint256[] memory SellList = new uint256[](total+1);
        for (uint256 i = 0; i < SellList.length; i++) {
            if(isSell[i]){
                SellList[i] = i;
            }else{
                SellList[i] = 0;
            }
        }
        return SellList;
    }


    // 入参 代表查询发布总量之中出售价格
    function getSellPriceList(uint256 total) public view returns(uint256[] memory){
        uint256[] memory SellPriceList = new uint256[](total+1);
        for (uint256 i = 0; i < SellPriceList.length; i++) {
            if(isSell[i]){
                SellPriceList[i] = idPrice[i] / (10 ** 14);
            }else{
                SellPriceList[i] = 0;
            }
        }
        return SellPriceList;
    }

    // 查询我正在出售的 id 比如我正在出售的有 1 2 3 那么返回 [0,1,2,3,0...]
    function getMySelling(uint256 total,address owner) public view returns(uint256[] memory){
        uint256[] memory MySellingList = new uint256[](total+1);
        for (uint256 i = 0; i < MySellingList.length; i++) {
            if(isSell[i] && idAddr[i]==owner){
                MySellingList[i] = i;
            }else{
                MySellingList[i] = 0;
            }
        }
        return MySellingList;
    }


    // todo Sell
    function doSell(address owner, uint256 tokenId, uint256 sPrice) public {
        require(isSaleActive, "Sale is not active");
        require(nftAddr == _msgSender(), "Ownable: caller is not the nftAddr");

        require(!getSell(tokenId), "tokenId already In Sell Order");
        idAddr[tokenId] = owner;
        //set owner
        idPrice[tokenId] = sPrice * 10 ** 14;
        isSell[tokenId] = true;
    }

    // todo do Sell
    function doBuy(uint256 tokenId, address buyAddr) payable public {
        require(isSaleActive, "Sale is not active");
        //(nftAddr == _msgSender(), "Ownable: caller is not the nftAddr");
        require(getSell(tokenId), "sell Out or not Sell");
        nftToken nftT =  nftToken(nftAddr);
        nftT.transferFrom(address(this), buyAddr, tokenId);
        address firstOwner = nftT.getFirstMint(tokenId);
        require(msg.value >= idPrice[tokenId]);
        payable(bossAddr).transfer(msg.value * bossFee / 100);
        payable(firstOwner).transfer(msg.value * firstOwnerFee / 100);
        payable(idAddr[tokenId]).transfer(msg.value * (100 - bossFee - firstOwnerFee) / 100);
        isSell[tokenId] = false;
        sellOrder[idAddr[tokenId]].push(tokenId);
        sellOrderPrice[idAddr[tokenId]][tokenId] = msg.value * 90 / 100;
    }

    // todo do cancel
    function doCancel(uint256 tokenId) public {
        require(nftAddr == _msgSender(), "Ownable: caller is not the nftAddr");
        require(getSell(tokenId), "sell Out or not Sell");
        nftToken nftT =  nftToken(nftAddr);
        isSell[tokenId] = false;
        nftT.transferFrom(address(this), idAddr[tokenId], tokenId);
    }

}