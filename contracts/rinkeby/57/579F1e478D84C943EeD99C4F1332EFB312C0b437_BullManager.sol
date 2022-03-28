// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @openzeppelin/contracts/utils/math/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

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

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/RewardPool.sol

contract RewardPool is Ownable {
    using SafeMath for uint256;

    address public bull = 0x19bA730dE2BB49F2929A6D36a2641ecB57BE7c4A;

	mapping(address => bool) public _managers;

    modifier onlyManager() {
        require(_managers[msg.sender] == true, "Only managers can call this function");
        _;
    }

    constructor () {
		_managers[msg.sender] = true;
    }

	function addManager(address manager) external onlyOwner {
		_managers[manager] = true;
	}

	function removeManager(address manager) external onlyOwner {
		_managers[manager] = false;
	}

    function setBULLAddress(address _bull) external onlyOwner {
        require(_bull != address(0), "Zero Address");
        bull = _bull;
    }

    function rewardTo(address _account, uint256 _rewardAmount) external onlyManager {
        require(IERC20(bull).balanceOf(address(this)) > _rewardAmount, "Insufficient Balance");
        IERC20(bull).transfer(_account, _rewardAmount);
    }

    function withdrawToken(address _account) external onlyManager {
        uint256 balance = IERC20(bull).balanceOf(address(this));
        require (balance > 0, "Insufficient Balance");
        IERC20(bull).transfer(_account, balance);
    }
}


// File contracts/BullManager.sol

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForTokens(
  
    //amount of tokens we are sending in
    uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
    uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
    address[] calldata path,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}


contract BullManager {
    using SafeMath for uint256;

    enum TreeState {Active, Inactive}

    struct Tree {
        string name;
        uint lastClaimTime;
        uint expiration;
        uint creationDate;
    }

    IERC20 public token;
    IERC20 public presaleToken;
    // IERC20 private USDC = IERC20(0x3e5570072f96a72703B0276109232eDe994e241E); // mumbai
    IERC20 private USDC = IERC20(0x7dAA6eb798cf8cDdD1B9D73236694371C0Cb58B7); // rinkeby
    
    uint256 public totalTrees; 
    uint public maxTreesPerUser;

    mapping(address => Tree[]) public treesOwned;
    mapping(address => uint) public totalClaimed;
    mapping(address => bool) public blacklist;
    mapping(address => bool) private admins;

    // CHANGE THIS 
    address private TREASURY = 0xaA09C0dA3bF83633A6B445e1E3090d4B573D6dee;
    address private REWARDS = 0xbfBac4711EB8553da4520E67E57Ee292B20EB9fd; 
    address private LIQUIDITY = 0x637AdE8fFdD65D7D82F98D1cC253c067D9CD40Ee;
    address private OPERATING_COST = 0x9741De8EbCc09D4e0405Ed2d5581Cc9166c893C9;
    // address private constant UNISWAP_V2_ROUTER = 0x8954AfA98594b838bda56FE4C12a09D7739D179b; // Mumbai
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Rinkeby
    address owner;

    // PER DAY 
    uint rewardPerTree = 0.225*10**18; 

    // Cost to buy a tree 
    uint costPerTree = 10*10**18;
    // Cost to refresh
    uint refreshCost = 30*10**18;
    uint claimFee = 5*10**18;
    
    event TreeCreated(address indexed _owner);
    // event TreeExpired(address indexed _owner, string _treeName, uint _expiration);
    
    // MODIFIERS
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner can Access!");
        _;
    }

    modifier checkNameConflict(address _owner, string memory _name) {
        bool conflict = false;
        for (uint i = 0; i < treesOwned[_owner].length; i ++) {
            if (keccak256(abi.encodePacked((treesOwned[_owner][i].name))) == keccak256(abi.encodePacked((_name)))) {
                conflict = true;
            }
        }
        require(conflict == false, "This name is used for another tree!");
        _;
    }
    modifier NotBlacklist() {
        require(blacklist[msg.sender] == false, "You are in Black List!");
        _;
    }
    modifier onlyAdmin() {
        require(admins[msg.sender] == true, "Admin is allowed only");
        _;
    }

    // FUNCTIONS
    constructor(address _token, address _presaleToken) {
        token = IERC20(_token);
        presaleToken = IERC20(_presaleToken);
        admins[msg.sender] = true;
        owner = msg.sender;
    }
    
    function addBlacklist(address _user) external onlyAdmin {
        blacklist[_user] = true;
    }
    function removeBlacklist(address _user) external onlyAdmin {
        blacklist[_user] = false;
    }
    function addAdmin(address _user) external onlyOwner {
        admins[_user] = true;
    }
    function removeAdmin(address _user) external onlyOwner {
        admins[_user] = false;
    }
    //// Create a tree given enough tokens 
    function createTreeWithTokens(string memory _treeName) external NotBlacklist checkNameConflict(msg.sender, _treeName) {
        require(treesOwned[msg.sender].length < maxTreesPerUser, "You have reached the maximum amount of trees!");
        require(msg.sender != TREASURY && msg.sender != REWARDS, "Treasury and Reward pools cannot create Trees!");
        require(token.balanceOf(msg.sender) >= costPerTree, "Not enough tokens to create Tree!");

        token.transferFrom(msg.sender, address(this), costPerTree);
        splitToken();
        Tree memory newTree = Tree(_treeName, block.timestamp, block.timestamp + 10 minutes, block.timestamp);
        treesOwned[msg.sender].push(newTree);
        totalTrees++;
        emit TreeCreated(msg.sender);
    }
    function createTreeTo(string memory _treeName, address _to) external onlyAdmin checkNameConflict(_to, _treeName) {
        require(treesOwned[_to].length < maxTreesPerUser, "User have reached the maximum amount of trees!");
        require(_to != TREASURY && _to != REWARDS, "Treasury and Reward pools cannot create Trees!");
        Tree memory newTree = Tree(_treeName, block.timestamp, block.timestamp + 10 minutes, block.timestamp);
        treesOwned[_to].push(newTree);
        totalTrees++;
    }
    function splitToken() internal {
        uint _treasury = costPerTree * 2 / 10;
        uint _liquidity = costPerTree / 10;
        uint _reward = costPerTree * 7 / 10;
        swap(_treasury, TREASURY); // Sending 20% of BULL to treasury as USDC
        token.transfer(LIQUIDITY, _liquidity / 2); // Sending 5% of BULL to Liquidity Pool
        swap(_liquidity / 2, LIQUIDITY); //Sending 5% of BULL to Liquidity Pool as USDC
        token.transfer(REWARDS, _reward); //Sending 70% of BULL
    }
    function createTreeWithPresaleTokens(string memory _treeName) external NotBlacklist checkNameConflict(msg.sender, _treeName) {
        require(treesOwned[msg.sender].length < maxTreesPerUser, "You have reached the maximum amount of trees!");
        require(msg.sender != TREASURY && msg.sender != REWARDS, "Treasury and Reward pools cannot create Trees");
        require(presaleToken.balanceOf(msg.sender) >= costPerTree, "Not enough tokens to create Tree!");

        presaleToken.transferFrom(msg.sender, address(this), costPerTree);
        // 90days for real
        Tree memory newTree = Tree(_treeName, block.timestamp, block.timestamp + 10 minutes, block.timestamp); 
        treesOwned[msg.sender].push(newTree);
        totalTrees++;
        emit TreeCreated(msg.sender);
    }

    // CALCULATIONS
    //// Calculate Rewards
    function calculateRewards(address _user) public view returns(uint) {
        require(treesOwned[_user].length > 0, "You own no trees!");
        uint _totalRewards = 0;
        for (uint i=0; i<treesOwned[_user].length; i++) {
            if (treesOwned[_user][i].expiration >= block.timestamp) {
                uint epochsPassed = (block.timestamp - treesOwned[_user][i].lastClaimTime) / 1 minutes;
                _totalRewards += epochsPassed * rewardPerTree;
            }
        }
        return _totalRewards;
    }

    //// Calculate Claim Fee
    function calculateClaimFee(address _user) internal view returns(uint) {
        uint _totalFee = 0;
        for (uint i=0; i<treesOwned[_user].length; i++) {
            if (treesOwned[_user][i].expiration >= block.timestamp) {
                uint epochsPassed = (block.timestamp - treesOwned[_user][i].lastClaimTime) / 1 minutes;
                if(epochsPassed > 0) _totalFee += claimFee;
            }
        }
        return _totalFee;
    }

    //// Calculate Rewards of single tree
    function calculateRewardsWithTreeIndex(address _user, uint _treeIndex) public view returns (uint) {
        require(treesOwned[_user].length > 0, "You own no trees!");
        uint _treeRewards = 0;
        if (treesOwned[_user][_treeIndex].expiration >= block.timestamp) {
            uint epochsPassed = (block.timestamp - treesOwned[_user][_treeIndex].lastClaimTime) / 1 minutes;
            _treeRewards += epochsPassed * rewardPerTree;
        }
        else {
            uint epochsPassed = (treesOwned[_user][_treeIndex].expiration - treesOwned[_user][_treeIndex].lastClaimTime) / 1 minutes;
            _treeRewards += epochsPassed * rewardPerTree;
        }
        return _treeRewards;
    }

    function calculateRewardsForEachTree(address _user) external view returns(string memory) {
        if(treesOwned[_user].length == 0) return "0";
        string memory rewardsArray = string(abi.encodePacked(calculateRewardsWithTreeIndex(_user, 0)));
        for (uint i=1; i<treesOwned[_user].length; i++) {
            uint reward = calculateRewardsWithTreeIndex(_user, i);
            rewardsArray = string(
                abi.encodePacked(
                    rewardsArray,
                    ",",
                    reward
                )
            );
        }
        return rewardsArray;
    }

    //// Calculate the cost to refresh trees (10 minutes) 
    function calculateRefreshCost(address _user) public view returns(uint) {
        uint _totalCost = 0;
        for (uint i=0; i<treesOwned[_user].length; i++) {
            if (treesOwned[_user][i].expiration < block.timestamp) {
                _totalCost += refreshCost;
            }
        }
        return _totalCost;
    }

    //// Refresh Trees
    function refreshTrees() external NotBlacklist {
        uint _cost = calculateRefreshCost(msg.sender);
        require(USDC.balanceOf(msg.sender) >= _cost, "You don't have enough USDC for Refresh Fee!");
        // OPERATING_COST.transfer(_cost);
        USDC.transferFrom(msg.sender, OPERATING_COST, _cost);
        for (uint i=0; i<treesOwned[msg.sender].length; i++) {
            if (treesOwned[msg.sender][i].expiration < block.timestamp) {
                uint _reward = calculateRewardsWithTreeIndex(msg.sender, i);
                // require(token.balanceOf(address(this)) > _reward, "Not enough tokens for rewards!");
                if( _reward > 0) {
                    // token.transfer(msg.sender, _reward);
                    RewardPool(REWARDS).rewardTo(msg.sender, _reward);
                    totalClaimed[msg.sender] += _reward;
                }
                treesOwned[msg.sender][i].expiration = block.timestamp + 10 minutes;
                treesOwned[msg.sender][i].lastClaimTime = block.timestamp;
            }
        }
    }   

    //// Refresh single Tree
    function refreshTreeWithIndex(uint _treeIndex) external NotBlacklist {
        uint _cost = refreshCost; // we only want one tree
        require(treesOwned[msg.sender][_treeIndex].expiration < block.timestamp, "It is already Active!");
        require(USDC.balanceOf(msg.sender) >= _cost, "You don't have enough USDC for Refresh Fee!");
        uint _reward = calculateRewardsWithTreeIndex(msg.sender, _treeIndex);
        // require(token.balanceOf(address(this)) > _reward, "Not enough tokens for rewards!");
        if( _reward > 0) {
            RewardPool(REWARDS).rewardTo(msg.sender, _reward);
            // token.transfer(msg.sender, _reward);
            totalClaimed[msg.sender] += _reward;
        }
        USDC.transferFrom(msg.sender, OPERATING_COST, _cost);
        treesOwned[msg.sender][_treeIndex].expiration = block.timestamp + 10 minutes;
        treesOwned[msg.sender][_treeIndex].lastClaimTime = block.timestamp;
    }

    //// CLAIMING
    //// Claim Rewards
    function claimRewards() external NotBlacklist {
        uint _rewards = calculateRewards(msg.sender);
        require(_rewards > 0, "There isn't any rewards you can claim");
        uint _claimFees = calculateClaimFee(msg.sender);
        require(USDC.balanceOf(msg.sender) >= _claimFees, "You don't have enough USDC for Claim Fee!");
        RewardPool(REWARDS).rewardTo(msg.sender, _rewards);
        USDC.transferFrom(msg.sender, OPERATING_COST, _claimFees);
        // token.transfer(msg.sender, _rewards);
        // Set new Claim Time
        for (uint i=0; i<treesOwned[msg.sender].length; i++) {
            treesOwned[msg.sender][i].lastClaimTime = block.timestamp;
        }
        totalClaimed[msg.sender] += _rewards;
    }
    //// Claim Rewards for single tree
    function claimSingleTreeReward(uint _treeID) external NotBlacklist {
        uint _rewards = calculateRewardsWithTreeIndex(msg.sender, _treeID);
        require(USDC.balanceOf(msg.sender) >= claimFee, "You don't have enough USDC for Claim Fee!");
        require(treesOwned[msg.sender][_treeID].expiration >= block.timestamp, "Can't claim rewards unless tree is Active!");
        // token.transfer(msg.sender, _rewards);
        RewardPool(REWARDS).rewardTo(msg.sender, _rewards);
        USDC.transferFrom(msg.sender, OPERATING_COST, claimFee);
        treesOwned[msg.sender][_treeID].lastClaimTime = block.timestamp;
        totalClaimed[msg.sender] += _rewards;
    }

    function swap(uint256 _amountIn, address _to) internal {
        IERC20(token).approve(UNISWAP_V2_ROUTER, _amountIn * 11  / 10);

        address[] memory path;
        path = new address[](2);
        path[0] = address(token);
        path[1] = address(USDC); 

        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_amountIn, 0, path, _to, block.timestamp);
    }

    // SETTERS
    function setCostPerTree(uint256 _cost) external onlyAdmin {
        costPerTree = _cost;
    }
    function setRewardsPerTree(uint _reward) external onlyAdmin {
        rewardPerTree = _reward;
    }
    function setMaxTreesPerUser(uint _max) external onlyAdmin {
        maxTreesPerUser = _max;
    }
    function setRefreshCostPerTree(uint _refreshCost) external onlyAdmin {
        refreshCost = _refreshCost;
    }
    function setClaimFee(uint _claimFee) external onlyAdmin {
        claimFee = _claimFee;
    }
    function setRewardsAddress(address _address) external onlyAdmin {
        REWARDS = _address;
    }
    function setLiquidityAddress(address _address) external onlyAdmin {
        LIQUIDITY = _address;
    }
    function setTreasuryAddress(address _address) external onlyAdmin {
        TREASURY = _address;
    }
    function setOperatingCostAddress(address _address) external onlyAdmin {
        OPERATING_COST = _address;
    }
    // GETTERS
    function getOwnedTreeInfo(address _user) external view returns (Tree[] memory){
        return treesOwned[_user];
    }
    

    // Recover tokens that were accidentally sent to this address 
    function recoverTokens(IERC20 _erc20, address _to) public onlyOwner {
        require(address(_erc20) != address(token), "You can't recover default token");
        uint256 _balance = _erc20.balanceOf(address(this));
        _erc20.transfer(_to, _balance);
    }

    // Withdraw Reward Pool
    function withdrawRewardPool() external onlyOwner() {
        RewardPool(REWARDS).withdrawToken(address(this));
        uint balance = IERC20(token).balanceOf(address(this));
        swap(balance, TREASURY); // Sending to treasury as USDC
    }
}