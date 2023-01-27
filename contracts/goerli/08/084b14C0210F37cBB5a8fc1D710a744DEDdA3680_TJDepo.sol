/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// File: Jafoo_Distribution.sol

pragma solidity ^0.8.0;



interface IERC20 {
    function approve(address _spender, uint _value) external returns (bool);
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    
}

interface IERC721 {
     function ownerOf(uint256 tokenId) external view returns (address owner);
     function balanceOf(address owner) external view returns (uint256 balance);
     function totalSupply() external view returns (uint256);

}



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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


contract TJDepo {

using SafeMath for uint256;

address public owner;
IERC20 public token;
IERC721 public nft;
mapping(address => uint256) public balanceOf;
mapping(address => bool) public isNFTHolder;
bool public withdrawalInProgress;
bool public withdrawalIsEnable;



event Deposit(address indexed _from, uint256 _amount);
event Withdrawal(address indexed _to, uint256 _amount);
event NFTAddressUpdate(address _newAddress);
event TokenAddressUpdate(address _newAddress);
event AdminWithdraw(address indexed _to, uint256 _amount);
event AdminDeposit(address indexed _to, uint256 _amount);
event WithdrawalToggle(bool _enabled);



constructor() public {
    owner = msg.sender;
    withdrawalIsEnable = false;
    token = IERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);  ///  usdc contract
    nft = IERC721(0x3B4af56899041F03C197120e7232E67617D65562); /// test TJFO contract
}




modifier _onlyOwner{
    require(msg.sender == owner, "Not Owner");
    _;
}

modifier _withdrawalIsEnabled {
    require(withdrawalIsEnable == true, "Withdrawal is disabled");
    _;
}

function updateNFTAddress(address _newAddress) public _onlyOwner{
     nft = IERC721(_newAddress);
     emit NFTAddressUpdate(_newAddress);
}


function updateTokenAddress(address _newAddress) public _onlyOwner{
    token = IERC20(_newAddress);
    emit TokenAddressUpdate(_newAddress);
}



//  mapping (address => mapping (address => uint256)) public allowances;

////   Desposit and Distribute Funds 
/*
function approve(address spender, uint256 value) public {
        require(token.approve(spender, value));
        token.allowance(msg.sender, spender);
         allowances[msg.sender][spender] = value;

 }

 function setAllowance(address spender, uint256 value) public {
        require(token.approve(spender, value));
        allowances[msg.sender][spender] = value;
    }

  function checkAllowance(address spender) public view returns (uint256) {
        return allowances[msg.sender][spender];
    }
*/

function deposit_n_distribute(uint256 _value) public {    ///1000000  usdc = 1 
    require(_value > 0, "Deposit amount must be greater than 0");
 //  require(allowances[msg.sender][address(this)] >= _value);
    require(IERC20(token).transferFrom(msg.sender, address(this), _value), "Transfer Failed");

    balanceOf[address(this)] += _value;

    uint256 totalSupply = IERC721(nft).totalSupply();
    uint256 distributionAmount = _value.div(totalSupply);

    for(uint256 i =0; i < totalSupply; i++){
    address holder = IERC721(nft).ownerOf(i+1);
    isNFTHolder[holder] = true;
    ///  add the distribution to the holders balance
    balanceOf[holder] = balanceOf[holder].add(distributionAmount);
    }  
    emit Deposit(msg.sender, _value);
    } /// deposit


function holderShareBalance(address _holder) public view returns(uint256){
     return balanceOf[_holder];
     
}



function checkIERC20ContractTokenBalance() public view returns(uint256){
    return IERC20(token).balanceOf(address(this));
}


function contractBalanceOf() public view returns(uint256){
    return balanceOf[address(this)];
}

function num_of_NFTs(address _holder) public view returns(uint256){
    return IERC721(nft).balanceOf(_holder);
}


function updateWithDrawalStatus(bool _status) public _onlyOwner{
    withdrawalIsEnable = _status;
    emit WithdrawalToggle(_status);
}

function registerAsNFTHolder(address _address) public _onlyOwner{
    require(_address !=address(0), "Cannot register address 0 as NFT Holder");
    isNFTHolder[_address] = true;
}

function unregisterAsNFTHolder(address _address) public _onlyOwner{
    require(_address != address(0), "Cannot register address 0 as NFT Holder");
    isNFTHolder[_address] = false;
}



function withdraw() public _withdrawalIsEnabled {
    ///  prevent reentrancy
    
    require(balanceOf[msg.sender] > 0, "Sender has no funds to withdraw"); 
    uint256 withdrawAmount = balanceOf[msg.sender];

    require(IERC721(nft).balanceOf(msg.sender) > 0 || isNFTHolder[msg.sender] == true, "This wallet has No Jafoo NFTs");
    require(address(this).balance > 0, "Contract has Insufficient funds");
    require(IERC20(token).approve(address(this), withdrawAmount), "Approval Failed"); 
    require(!withdrawalInProgress,  "Another Withdrawal is in progress");
    
    withdrawalInProgress = true;  
    address sender = msg.sender; 
     
    

    balanceOf[msg.sender] = 0;
   // require(token.approve(address(this), withdrawAmount), "Approval withdraw failed");
    require(IERC20(token).transfer(sender, withdrawAmount), "Transfer Failed");
   
    emit Withdrawal(msg.sender, withdrawAmount);
    withdrawalInProgress = false;
}

function adminWithdraw(uint _value) public _onlyOwner{
    uint256 totalBalance = token.balanceOf(address(this));
    require(IERC20(token).approve(address(this), _value), "Approval Failed");
    require(IERC20(token).transferFrom(address(this), owner, _value), "Transfer Failed");
    balanceOf[address(this)] -= _value;
    emit AdminWithdraw(owner, _value);
}

function adminDeposit(uint256 _value) public {    ///1000000  usdc = 1 
    require(_value > 0, "Deposit amount must be greater than 0");
    require(IERC20(token).transferFrom(msg.sender, address(this), _value), "Transfer Failed");
    balanceOf[address(this)] += _value;


    emit AdminDeposit(address(this), _value);
    } /// deposit

}  /// end contract