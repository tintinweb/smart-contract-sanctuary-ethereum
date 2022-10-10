/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

pragma solidity 0.8.17;

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
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}
contract KEKBridgeV4 is ReentrancyGuard {
      using SafeMath for uint256;

    struct BridgeTx { 
        address receiver;
        uint256 amount;
        uint256 timestamp;
    }

    mapping(uint256=>BridgeTx) transactions;
    mapping(uint256=>bool) confirmedBridgesFromDC;
    mapping(address=>BridgeTx[]) BSCtoDCHistory;



    address public BEP20Doge=0x67954768E721FAD0f0f21E33e874497C73ED6a82;
    IBEP20 public Doge = IBEP20(BEP20Doge);

    address public owner=0x7650F39bA8D036b1f7C7b974a6b02aAd4B7F71F7;
    address public oracle=0x3e697f3373F1a2795996C090eFc2Cef08BcCbcb9;

    address public beneficiary1=address(0);
    address public beneficiary2=address(0);
    address public beneficiary3=address(0);

    uint256 bridgeId=0;

    uint256 lockFee=1;
    uint256 minFee=1500000000000000000000; //Ether unit
    bool public bridge=false;

    function readHistoryBSCtoDC() public view returns (BridgeTx[] memory){
        return BSCtoDCHistory[msg.sender];
    }

    function readTransaction(uint256 id) public view returns(BridgeTx memory){
        return transactions[id];
    }

    function enableBridge() public{
        require(msg.sender==owner);
        bridge=false;
    }
    function disableBridge() public{
        require(msg.sender==owner);
        bridge=true;
    }

    function setBeneficiary1(address wallet) public{
      require(msg.sender==owner);
      beneficiary1=wallet;
    }
    function setBeneficiary2(address wallet) public{
      require(msg.sender==owner);
      beneficiary2=wallet;
    }
    function setBeneficiary3(address wallet) public{
      require(msg.sender==owner);
      beneficiary3=wallet;
    }        
    function currentBridgeId() public view returns(uint256){
        return bridgeId;
    }

    function modifyMinFee(uint256 amt) public{
        require(msg.sender==owner);
        require(minFee>0,"Min fee cannot be 0");
        minFee=amt;
    }

    function modifyOwner(address newowner) public{
        require(msg.sender==owner);
        owner=newowner;
    }

    function modifyOracle(address neworacle) public {
        require(msg.sender==owner);
        oracle=neworacle;
    }

    function withdrawDoge(uint256 amount) public nonReentrant {
        require(msg.sender==owner);
        Doge.transfer(owner, (amount));
    }

    function modifyBSCToDCFee(uint256 newFee) public{
        require(msg.sender==owner);
        lockFee=newFee;
    }

    event BridgeComplete(address indexed receiver, uint256 indexed id, uint256 amount);

    function KEKtoETH(uint256 amount,address requestor,uint256 id) public nonReentrant{
        require(msg.sender==oracle);
        require(!confirmedBridgesFromDC[id]);    
        confirmedBridgesFromDC[id]=true;    
        Doge.transfer(requestor, (amount));
        emit BridgeComplete(requestor, id, amount);

    }

    function addWhitelist(address who,uint256 newWhitelistFee) public {
      require(msg.sender==owner);
      require(newWhitelistFee>=10);
      whitelist[who]=true;
      whitelistFee[who]=newWhitelistFee;
    }
    function removeWhitelist(address who) public {
      require(msg.sender==owner);
      whitelist[who]=false;
      delete whitelistFee[who];
    }    

    mapping(address=>bool) whitelist;
    mapping(address=>uint256) whitelistFee;

    mapping (address=>uint256) addedLiquidity;

    function addLiquidity(uint256 amount) public nonReentrant {
      require(amount>0,"Added liquidity cannot be 0");
        Doge.transferFrom(msg.sender,address(this),amount);
        addedLiquidity[msg.sender]=addedLiquidity[msg.sender].add(amount);      
    }

    function removeLiquidity(uint256 amount) public nonReentrant {
      require(amount<addedLiquidity[msg.sender],"You don't have enough liquidity.");
      addedLiquidity[msg.sender]=addedLiquidity[msg.sender].sub(amount);
      Doge.transfer(msg.sender,amount);
    }


    function ETHToKEK (address receiver,uint256 amount) public nonReentrant
    {   
        require(bridge==false,"Bridge disabled.");
        require(amount>0,"Invalid amount");

        uint256 thisBridgeFee=0;

        if(whitelist[msg.sender]==true){
          thisBridgeFee=whitelistFee[msg.sender];
        } else {
          thisBridgeFee=lockFee;
        }

        uint256 bridgeFee=SafeMath.mul(SafeMath.div(amount,1000),thisBridgeFee);
        if(bridgeFee<minFee){
          bridgeFee=minFee;
        }
        uint256 teamFee=SafeMath.div(bridgeFee,3);

        Doge.transferFrom(msg.sender,address(this),amount);
        
        Doge.transfer(beneficiary1,teamFee);                
        Doge.transfer(beneficiary2,teamFee);                
        Doge.transfer(beneficiary3,teamFee);                

        uint256 amountMinusFees=SafeMath.sub(amount,bridgeFee);
        transactions[bridgeId].receiver=receiver;
        transactions[bridgeId].amount=amountMinusFees;
        transactions[bridgeId].timestamp=block.timestamp;
        BSCtoDCHistory[msg.sender].push(transactions[bridgeId]);
        bridgeId++;
        
    }
    

}