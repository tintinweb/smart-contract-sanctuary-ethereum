/**
 *Submitted for verification at Etherscan.io on 2023-02-11
*/

/**
 *  SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.7;


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
        return msg.data;
    }
}


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IToken{

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
   
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    function amountForEth(uint256 ethAmount) external view returns(uint256 tokenAmount);
}

contract WhiteListSale is Ownable{
     using SafeMath for uint256;
     
     uint256 public preToken;
     
     uint256 public minContribe; //1bnb
     uint256 public maxContribe; // 2bnb
     
     address public tokenAddress;
     
     uint256 public softHardBnb; 

     uint256 public totalBnb; 

     uint256 public leftSellBnb; 

     uint256 public totalSellBnb;
     
     uint256 public startTime;
     uint256 public endTime;

     uint256 public releaseBlock;//
	 
	 bool public openWhiteList;//
     
     struct userContribute{
         uint256 bnbAmount;
         uint256 tokenAmount;
         uint256 preRawToken;//
         uint256 tegToken;//
         uint256 claimTotal; //
         uint256 lastClaimBlock; //
         bool hasClaim;
     }
     
    mapping(address=>userContribute) public userContributeList;

    bool public isSuccess; 

      
    mapping(address=>bool) public whiteList;//

    bool private locked;
    
    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    bool inited; 
    
    function init(
        address _tokenAddress
    ) public {

        require(!inited,"invalid init");

        _setOwner(_msgSender());

        tokenAddress = _tokenAddress;

        openWhiteList = true;
        
        preToken = 1245 * 10 ** 12;//1245,000,000,000,000
     
        minContribe = 2 * 10**17; //1bnb
        maxContribe = 1 * 10**18; // 1bnb
     
     
        softHardBnb = 1 * 10 ** 18; //1 bnb 
        totalBnb = 200 * 10 ** 18; //200 bnb
        leftSellBnb = totalBnb; 


        inited = true;
    }
    
    function doContribute() public payable {

        uint256 currentStage = getCurrentStage();
        require(currentStage > 0,"has not started.");
        require(currentStage < 2,"has end.");
        
        require(leftSellBnb > 0,"Sold out");

        uint256 buyAmount =  msg.value;

        //0
        require(buyAmount >=0.2 ether, "single minimum 0.2.");

        require(buyAmount % 0.1 ether == 0, "only multiples of 0.1.");

        uint256 leftBuyBnb = 0;
        
        userContribute memory _userContribute = userContributeList[msg.sender];

        if(buyAmount > leftSellBnb){
            leftBuyBnb = buyAmount.sub(leftSellBnb);
            buyAmount = leftSellBnb;
        }
		if(openWhiteList){
			require(whiteList[msg.sender],"not in whilelist");
		}
        require(buyAmount >= minContribe ,"accumulated minimum 0.2.");
        require(_userContribute.bnbAmount.add(buyAmount) <= maxContribe,"accumulated maximum 5.0.");

        
        _userContribute.bnbAmount =  _userContribute.bnbAmount.add(buyAmount);
        uint256 tokenAmount = buyAmount.mul(preToken).div(10**18);
        _userContribute.tokenAmount =  _userContribute.tokenAmount.add(tokenAmount);
        //_userContribute.tegToken = _userContribute.tokenAmount.mul(20).div(100);//
        //_userContribute.preRawToken = _userContribute.tokenAmount.sub(_userContribute.tegToken).div(28800).div(60);//
        _userContribute.tegToken = _userContribute.tokenAmount;
        _userContribute.preRawToken = 0;


        userContributeList[msg.sender] = _userContribute;

        totalSellBnb = totalSellBnb.add(buyAmount);
        leftSellBnb = leftSellBnb.sub(buyAmount);

        //
        if(totalSellBnb >= softHardBnb){
            isSuccess = true;
        }
       
        //return
        if(leftBuyBnb > 0){
            payable(msg.sender).transfer(leftBuyBnb);
        }
        
        //payable(devAddress).transfer(address(this).balance);
    }

    function getCurrentStage() private view returns(uint256){
        if (endTime > 0 && endTime < block.timestamp) {
            return 2;
        }
        if (startTime > 0 && startTime < block.timestamp) {
            return 1;
        }

        return 0;
    }
    
    receive() external payable{
        doContribute();
    }

   //
   function refund() public noReentrancy(){
        require(tx.origin==msg.sender,"must be human");
        require(endTime<block.timestamp,"presale not end");
        require(!isSuccess,"presale is success.");

       
        userContribute storage _userContribute = userContributeList[msg.sender];

        if(_userContribute.bnbAmount > 0 &&  _userContribute.hasClaim == false){
            _userContribute.hasClaim = true;
            payable(msg.sender).transfer(_userContribute.bnbAmount);
        }
        

      
   }
    
   //
   function claim() public noReentrancy{
        require(tx.origin==msg.sender,"must be human");
        require(releaseBlock<block.number,"not yet release");
        require(isSuccess,"presale is fail.");
        
        uint256 claimTotal = 0;
        uint256 nowBlock =  block.number;
       
        userContribute storage _userContribute = userContributeList[msg.sender];
        
        if(_userContribute.tokenAmount > 0 &&  _userContribute.hasClaim == false){
            
            claimTotal =  nowBlock - (_userContribute.lastClaimBlock > 0 ? _userContribute.lastClaimBlock : releaseBlock);
            claimTotal = claimTotal.mul(_userContribute.preRawToken);

            if(_userContribute.lastClaimBlock == 0){
                claimTotal = claimTotal.add(_userContribute.tegToken);
            }

            if(_userContribute.claimTotal.add(claimTotal) > _userContribute.tokenAmount){
                claimTotal = _userContribute.tokenAmount.sub(_userContribute.claimTotal);
                _userContribute.claimTotal = _userContribute.tokenAmount;
                _userContribute.hasClaim = true;
            }
            else
                _userContribute.claimTotal = _userContribute.claimTotal.add(claimTotal);

            _userContribute.lastClaimBlock = nowBlock;

        }
       

         if(claimTotal > 0)
            IToken(tokenAddress).transfer(msg.sender,claimTotal);
        
    }

    //
    function pedding(address _address) public view returns(uint256){
          uint256 claimTotal = 0;
          uint256 nowBlock =  block.number;
          uint256 peddingTotal = 0;

          if(nowBlock < releaseBlock){
              return  0;
          }

          userContribute memory _userContribute = userContributeList[_address];
          if(_userContribute.tokenAmount > 0 &&  _userContribute.hasClaim == false){
                
                claimTotal =   nowBlock - (_userContribute.lastClaimBlock > 0 ? _userContribute.lastClaimBlock : releaseBlock);
                claimTotal = claimTotal.mul(_userContribute.preRawToken);

                if(_userContribute.lastClaimBlock == 0){
                    claimTotal = claimTotal.add(_userContribute.tegToken);
                }

                if(_userContribute.claimTotal.add(claimTotal) >= _userContribute.tokenAmount){
                    claimTotal = _userContribute.tokenAmount.sub(_userContribute.claimTotal);
                }

                peddingTotal = peddingTotal.add(claimTotal);
          }


          return peddingTotal;
    }
    
    
    function setRoundTime(uint256 _starttime,uint256 _endtime) public onlyOwner {
        startTime = _starttime;
        endTime = _endtime;
    }

    function startRelease(uint256 _block) public onlyOwner{
        if(_block > 0){
            releaseBlock = _block;
        }
        else{
            releaseBlock = block.number;
        }
    }
  
    
    function addRound1WhiteList(address[] memory _address) public onlyOwner{
        for(uint256 i = 0; i < _address.length ; i++){
            whiteList[_address[i]] = true;
        }
    }
    
    function removeRound1WhiteList(address[] memory _address) public onlyOwner{
       for(uint256 i = 0; i < _address.length ; i++){
            whiteList[_address[i]] = false;
        }
    }
    
    function sweep(uint256 _type) public onlyOwner {
        if(_type == 0){
            payable(msg.sender).transfer(address(this).balance);
        }
        else{
            uint256 amount = IToken(tokenAddress).balanceOf(address(this));
            if(amount > 0){
                IToken(tokenAddress).transfer(msg.sender,amount);
            }
        }
    }

    function fixData(address _address,uint256 claimTotal ) public onlyOwner {
        userContribute storage _userContribute = userContributeList[_address];

        _userContribute.claimTotal = claimTotal;
    }

    function setTotalBnb(uint256 _totalBnb) public onlyOwner {
        leftSellBnb = _totalBnb;
        totalBnb = _totalBnb;
    }

    function setSoftHard(uint256 _softhard)  public onlyOwner {
        softHardBnb = _softhard;
    }
    
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }
	
	function setOpenWhiteList(bool _bool) public onlyOwner {
		openWhiteList = _bool;
	}
}