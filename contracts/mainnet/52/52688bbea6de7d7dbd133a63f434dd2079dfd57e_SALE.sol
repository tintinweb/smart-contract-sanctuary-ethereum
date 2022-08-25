/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

pragma solidity ^0.6.0;
    
    // SPDX-License-Identifier: MIT
    
    /**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
 
library SafeMathUpgradeable {
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

    
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


abstract contract ContextUpgradeable is Initializable {
     function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

contract OwnableUpgradeable is Initializable,ContextUpgradeable{
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = msg.sender;
        _owner = payable(msgSender);
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }

     uint256[50] private __gap;
}
    
interface IERC20Upgradeable {
        function decimals() external view returns (uint256 balance);
        function transfer(address to, uint256 tokens) external returns (bool success);
        function burnTokens(uint256 _amount) external;
        function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
        function balanceOf(address tokenOwner) external view returns (uint256 balance);
}
    
    
contract SALE is ContextUpgradeable, OwnableUpgradeable {
        using SafeMathUpgradeable for uint256;
        
        bool public isPresaleOpen;
        
        address public tokenAddress; 
        uint256 public tokenDecimals;
        
        address public BUSD; // busd
        
        uint256 public tokenRatePerEth;
        uint256 public tokenRatePerBUSD;
        uint256 public rateDecimals;
        
        uint256 public minEthLimit;
        uint256 public maxEthLimit;

        uint256 public expectedBNB;
        uint256 public expectedBUSD;
        
        uint256 public totalSupply;
        
        uint256 public soldTokens;
        
        uint256 public totalsold;
        
        uint256 public intervalDays;
        
        uint256 public endTime;
        
        bool public isClaimable;
        
        bool public isWhitelisted;

        mapping(address => mapping(address => uint256)) public usersInvestments;

       
        mapping(address => mapping(address => uint256)) public balanceOf;
        
        mapping(address => mapping(address => uint256)) public whitelistedAddresses;
        
        function initialize() public initializer  {
            __Ownable_init();
            tokenAddress = 0xb98461993032A5f76b1D5324AC4e68C3F7820639 ; // Ditmax
            tokenDecimals = 18;
            tokenRatePerEth = 60000000000;
            tokenRatePerBUSD = 1000;
            rateDecimals = 0;
            minEthLimit = 1e17; // 0.1 BNB
            maxEthLimit = 10e18; // 10 BNB
            expectedBNB = 1 ether;
            expectedBUSD = 500e18;
        
        }
        
        function startPresale(uint256 numberOfdays) external onlyOwner{
            require(IERC20Upgradeable(tokenAddress).balanceOf(address(this)) > 0,"No Funds");
            require(!isPresaleOpen, "Presale is open");
            intervalDays = numberOfdays.mul(1 days);
            endTime = block.timestamp.add(intervalDays);
            isPresaleOpen = true;
            isClaimable = false;
        }
        
        function closePresale() external onlyOwner{
            require(isPresaleOpen, "Presale is not open yet or ended.");
            isPresaleOpen = false;
            
        }
        
        function setTokenAddress(address token) external onlyOwner {
            tokenAddress = token;
            tokenDecimals = IERC20Upgradeable(tokenAddress).decimals();
        }
        
        function setTokenDecimals(uint256 decimals) external onlyOwner {
           tokenDecimals = decimals;
        }
        
        function setMinEthLimit(uint256 amount) external onlyOwner {
            minEthLimit = amount;    
        }
        
        function setMaxEthLimit(uint256 amount) external onlyOwner {
            maxEthLimit = amount;    
        }
        
        function setTokenRatePerEth(uint256 rate) external onlyOwner {
            tokenRatePerEth = rate;
        }

        function setTokenRatePerBUSD(uint256 rate) external onlyOwner {
            tokenRatePerBUSD = rate;
        }

      
        
        function setRateDecimals(uint256 decimals) external onlyOwner {
            rateDecimals = decimals;
        }

        function setexpectedBNB(uint256 _expectedBNB) external onlyOwner {
            expectedBNB = _expectedBNB;
        }

         function setexpectedBUSD(uint256 _expectedBUSD) external onlyOwner {
            expectedBUSD = _expectedBUSD;
        }

         function setBUSD(address _busd) external onlyOwner {
            BUSD = _busd;
        }
        
        function getUserInvestments(address user) public view returns (uint256){
            return usersInvestments[tokenAddress][user];
        }
        
        function getUserClaimbale(address user) public view returns (uint256){
            return balanceOf[tokenAddress][user];
        }
        
        function addWhitelistedAddress(address _address, uint256 _allocation) external onlyOwner {
            whitelistedAddresses[tokenAddress][_address] = _allocation;
        }
        
        function addMultipleWhitelistedAddresses(address[] calldata _addresses, uint256[] calldata _allocation) external onlyOwner {
            isWhitelisted = true;
             for (uint i=0; i<_addresses.length; i++) {
                 whitelistedAddresses[tokenAddress][_addresses[i]] = _allocation[i];
             }
        }
    
        function removeWhitelistedAddress(address _address) external onlyOwner {
            whitelistedAddresses[tokenAddress][_address] = 0;
        }
        
        receive() external payable{
            if(block.timestamp > endTime)
            isPresaleOpen = false;
            
            require(isPresaleOpen, "Presale is not open.");
            require(
                    usersInvestments[tokenAddress][msg.sender].add(msg.value) <= maxEthLimit
                    && usersInvestments[tokenAddress][msg.sender].add(msg.value) >= minEthLimit,
                    "Installment Invalid."
                );
            if(isWhitelisted){
                require(whitelistedAddresses[tokenAddress][msg.sender] > 0, "you are not whitelisted");
                require(whitelistedAddresses[tokenAddress][msg.sender] >= msg.value, "amount too high");
                require(usersInvestments[tokenAddress][msg.sender].add(msg.value) <= whitelistedAddresses[tokenAddress][msg.sender], "Maximum purchase cap hit");
                whitelistedAddresses[tokenAddress][msg.sender] = whitelistedAddresses[tokenAddress][msg.sender].sub(msg.value);
            }
            require( (IERC20Upgradeable(tokenAddress).balanceOf(address(this))).sub(soldTokens) > 0 ,"No Presale Funds left");
            uint256 tokenAmount = getTokensPerEth(msg.value);
            balanceOf[tokenAddress][msg.sender] = balanceOf[tokenAddress][msg.sender].add(tokenAmount);
            soldTokens = soldTokens.add(tokenAmount);
            usersInvestments[tokenAddress][msg.sender] = usersInvestments[tokenAddress][msg.sender].add(msg.value);
            
        }

        function contributeBUSD(uint256 _amount) public{
          
            require(isPresaleOpen, "Presale is not open.");
            require(
                    usersInvestments[tokenAddress][msg.sender].add(_amount) <= maxEthLimit
                    && usersInvestments[tokenAddress][msg.sender].add(_amount) >= minEthLimit,
                    "Installment Invalid."
                );
            if(isWhitelisted){
                require(whitelistedAddresses[tokenAddress][msg.sender] > 0, "you are not whitelisted");
                require(whitelistedAddresses[tokenAddress][msg.sender] >= _amount, "amount too high");
                require(usersInvestments[tokenAddress][msg.sender].add(_amount) <= whitelistedAddresses[tokenAddress][msg.sender], "Maximum purchase cap hit");
                whitelistedAddresses[tokenAddress][msg.sender] = whitelistedAddresses[tokenAddress][msg.sender].sub(_amount);
            }
            require(IERC20Upgradeable(BUSD).transferFrom(msg.sender,address(this), _amount),"Insufficient Funds !");
            uint256 tokenAmount = getTokensPerBUSD(_amount);
            require( (IERC20Upgradeable(tokenAddress).balanceOf(address(this))).sub(soldTokens.add(tokenAmount)) > 0 ,"No Presale Funds left");
          
            balanceOf[tokenAddress][msg.sender] = balanceOf[tokenAddress][msg.sender].add(tokenAmount);
            soldTokens = soldTokens.add(tokenAmount);
            usersInvestments[tokenAddress][msg.sender] = usersInvestments[tokenAddress][msg.sender].add(_amount);
            
            
        }
        
        function claimTokens() public{
           require(!isPresaleOpen, "You cannot claim tokens until the presale is closed.");
           require(isClaimable,"Wait until the owner finalise the sale !");
            require(balanceOf[tokenAddress][msg.sender] > 0 , "No Tokens left !");
            require(IERC20Upgradeable(tokenAddress).transfer(msg.sender, balanceOf[tokenAddress][msg.sender]), "Insufficient balance of presale contract!");
            balanceOf[tokenAddress][msg.sender] = 0;
        }
        
        function finalizeSale() public onlyOwner{
            isClaimable = !(isClaimable);
            totalsold = totalsold.add(soldTokens);
            soldTokens = 0;
           
        }
        
        function whitelistedSale() public onlyOwner{
            isWhitelisted = !(isWhitelisted);
        }
        
        function getTokensPerEth(uint256 amount) public view returns(uint256) {
            return amount.mul(tokenRatePerEth).div(
                10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
                );
        }

        function getTokensPerBUSD(uint256 amount) public view returns(uint256) {
            return (amount.mul(tokenRatePerBUSD)).div(10**(uint256(9))).div(
                10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
                );
        }

        function getCollectedBUSD() public view returns (uint256) {
            return IERC20Upgradeable(BUSD).balanceOf(address(this));
        }

        function getUserInvestmentsBUSD() public view returns (uint256) {
            return usersInvestments[tokenAddress][msg.sender];
        }
        
        function withdrawBNB() public onlyOwner{
            // require(address(this).balance > 0 , "No Funds Left");
             payable(owner()).transfer(address(this).balance);
            
        }
        
        function getUnsoldTokensBalance() public view returns(uint256) {
            return IERC20Upgradeable(tokenAddress).balanceOf(address(this));
        }
        
        function burnUnsoldTokens() external onlyOwner {
            require(!isPresaleOpen, "You cannot burn tokens untitl the presale is closed.");
            
            IERC20Upgradeable(tokenAddress).burnTokens(IERC20Upgradeable(tokenAddress).balanceOf(address(this)));   
        }
        
        function getUnsoldTokens() external onlyOwner {
            require(!isPresaleOpen, "You cannot get tokens until the presale is closed.");
            IERC20Upgradeable(tokenAddress).transfer(owner(), (IERC20Upgradeable(tokenAddress).balanceOf(address(this))).sub(soldTokens) );
        }
    }