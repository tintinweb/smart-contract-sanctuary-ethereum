/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.7;

    // CAUTION
    // This version of SafeMath should only be used with Solidity 0.8 or later,
    // because it relies on the compiler's built in overflow checks.


    /**
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

    /**
    * @dev Wrappers over Solidity's arithmetic operations.
    *
    * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
            _transferOwnership(_msgSender());
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
            _transferOwnership(address(0));
        }

        /**
        * @dev Transfers ownership of the contract to a new account (`newOwner`).
        * Can only be called by the current owner.
        */
        function transferOwnership(address newOwner) public virtual onlyOwner {
            require(newOwner != address(0), "Ownable: new owner is the zero address");
            _transferOwnership(newOwner);
        }

        /**
        * @dev Transfers ownership of the contract to a new account (`newOwner`).
        * Internal function without access restriction.
        */
        function _transferOwnership(address newOwner) internal virtual {
            address oldOwner = _owner;
            _owner = newOwner;
            emit OwnershipTransferred(oldOwner, newOwner);
        }
    }

    /**
    * @dev Interface of the ERC20 standard as defined in the EIP.
    */
    interface IERC20 {

        function decimals() external view returns (uint8);
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

    /**
    * @title Pausable
    * @dev Base contract which allows children to implement an emergency stop mechanism.
    */
    contract Pausable is Ownable {
        event Pause();
        event Unpause();

        bool public paused = false;


        /**
        * @dev Modifier to make a function callable only when the contract is not paused.
        */
        modifier whenNotPaused() {
            require(!paused);
            _;
        }

        /**
        * @dev Modifier to make a function callable only when the contract is paused.
        */
        modifier whenPaused() {
            require(paused);
            _;
        }

        /**
        * @dev called by the owner to pause, triggers stopped state
        */
        function pause() onlyOwner whenNotPaused public {
            paused = true;
            emit Pause();
        }

        /**
        * @dev called by the owner to unpause, returns to normal state
        */
        function unpause() onlyOwner whenPaused public {
            paused = false;
            emit Unpause();
        }
    }

    contract BlackList is Ownable {

        /////// Getters to allow the same blacklist to be used also by other contracts (including upgraded BOM) ///////
        function getBlackListStatus(address _maker) external view returns (bool) {
            return isBlackListed[_maker];
        }

        mapping (address => bool) public isBlackListed;
        
        function addBlackList (address _evilUser) public onlyOwner {
            isBlackListed[_evilUser] = true;
            emit AddedBlackList(_evilUser);
        }

        function removeBlackList (address _clearedUser) public onlyOwner {
            isBlackListed[_clearedUser] = false;
            emit RemovedBlackList(_clearedUser);
        }

        event DestroyedBlackFunds(address _blackListedUser, uint _balance);

        event AddedBlackList(address _user);

        event RemovedBlackList(address _user);

    }

    abstract contract IBOM716 is Ownable {

        using SafeMath for uint;

        struct Weight {
            uint pastWeight;
            uint curWeight;
            bool isActive;
            uint pastCnt;
            uint curCnt;
        }

        uint public totalReward;
        mapping(uint => uint) public rewardBalances;

        uint public redistID;
        mapping(uint => Weight) public weights;
        uint public decVal;

        uint public distDelayDuration = 3 days;
        uint public lastDistTime;

        address public lppairaddress;
        uint public currentPrice;
        bool    public isUpdatePriceFromLP;
        
        
        // Internal functions
        function _addTxnWeightCnt(uint _nftID, uint _txnAmount) internal {
            Weight storage _weight = weights[_nftID];
            _weight.curWeight = _weight.curWeight + _txnAmount;
            _weight.curCnt = _weight.curCnt + 1;
        }

        // Public functions
        function rewardBalanceOf(uint _nftID) public view onlyOwner returns (uint) {
            return rewardBalances[_nftID];
        }
        function getTotalReward() public view returns (uint) {
            return totalReward;
        }
        
        function changeDistDelay(uint _distDelay) public onlyOwner {
            distDelayDuration = _distDelay;
        }
        function setCurrentPrice(uint _price) public onlyOwner {
            currentPrice = _price;
        }
        function setLPpairaddress(address _pairAddress) public onlyOwner {
            lppairaddress = _pairAddress;
        }
        function setUpdatePriceFromLP(bool _flag) public onlyOwner {
            isUpdatePriceFromLP = _flag;
        }

        // function updatePriceFromLP() public {}

        // Abstract functions
        function transferByNFT(uint _nftID, uint _amount, uint _key) virtual external returns (bool);
        function transferFromByNFT(address _from, uint _nftID, uint _value, uint _key) virtual external returns (bool);
        function distRewardToNFTHolders() virtual public;
        function withdrawReward(address _to, uint _amount, uint _nftID) virtual external;
        function calcTxnFee(uint _amount) virtual public returns(uint);
        function updatePriceFromLP() virtual external;
        // Test functions

        // Events
        // Called when transferbynft
        event TransferByNFT(address from, uint amount, uint key);
        event DistributRewardToNFTHolders(address to, uint amount);
    }

    interface IUniswapV2Pair {
        function token0() external view returns (address);
        function token1() external view returns (address);
        function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
        function price0CumulativeLast() external view returns (uint);
        function price1CumulativeLast() external view returns (uint);
    }

    interface BOMNft {
        function owner(uint _nftID) external view returns(address);
        function totalSupply() external view returns(uint);
    }

    contract BOMToken is Context, IERC20, Ownable, IBOM716, BlackList, Pausable {
        using SafeMath for uint256;
        uint public constant MAX_UINT = 2**256 - 1;
        BOMNft bomnft;

        mapping(address => uint256) private _balances;

        mapping(address => mapping(address => uint256)) private _allowances;

        uint256 private _totalSupply;
        uint8 public _decimals;
        string public _symbol;
        string public _name;

        address public bomnftaddress = address(this);
        address public lpAddress;
        address public marketingWallet;
        address public teamWallet;
        address public investorWallet1;
        address public investorWallet2;
        address public investorWallet3;
        address public techWallet;

        uint public nfttsply;

        constructor(address _investor1, address _investor2, address _investor3, address _bomnftaddress) {
            _name = 'BOM Token';
            _symbol = 'BOM';
            _decimals = 10;
            _totalSupply = 10 ** 8 * 10 ** 10;
            _balances[msg.sender] = _totalSupply;
            decVal = 10 ** _decimals;
            currentPrice = 3000000000;
            totalReward = 0;

            investorWallet1 = _investor1;
            investorWallet2 = _investor2;
            investorWallet3 = _investor3;

            bomnftaddress = _bomnftaddress;
            bomnft = BOMNft(_bomnftaddress);

            nfttsply = bomnft.totalSupply();

            emit Transfer(address(0), msg.sender, _totalSupply);
        }

        // Set the reward wallets
        function setRewardWalletAddress(address _lpAddress, address _marketingWallet, address _teamWallet, address _techWallet) public onlyOwner {
            require(_lpAddress != address(0));
            require(_marketingWallet != address(0));
            require(_teamWallet != address(0));
            require(_techWallet != address(0));

            lpAddress = _lpAddress;
            marketingWallet = _marketingWallet;
            teamWallet = _teamWallet;
            techWallet = _techWallet;
        }

        /**
        * @dev Returns the erc token owner.
        */
        function getOwner() external view returns (address) {
            return owner();
        }

        /**
        * @dev Returns the token decimals.
        */
        function decimals() external override view returns (uint8) {
            return _decimals;
        }

        /**
        * @dev Returns the token symbol.
        */
        function symbol() external view returns (string memory) {
            return _symbol;
        }

        /**
        * @dev Returns the token name.
        */
        function name() external view returns (string memory) {
            return _name;
        }

        /**
        * @dev See {ERC20-totalSupply}.
        */
        function totalSupply() external view virtual override returns (uint256) {
            return _totalSupply;
        }

        /**
        * @dev See {ERC20-balanceOf}.
        */
        function balanceOf(address account)
            external
            view
            virtual
            override
            returns (uint256)
        {
            return _balances[account];
        }

        /**
        * @dev See {ERC20-transfer}.
        *
        * Requirements:
        *
        * - `recipient` cannot be the zero address.
        * - the caller must have a balance of at least `amount`.
        */
        function transfer(address recipient, uint256 amount)
            external
            override
            returns (bool)
        {
            require(!isBlackListed[msg.sender]);
            // _transfer(_msgSender(), recipient, amount);
            uint txn_fee = calcTxnFee(amount);
            uint sendAmount = amount.sub(txn_fee);

            totalReward = totalReward.add(txn_fee);
            _balances[msg.sender] = _balances[msg.sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(sendAmount);
            return true;
        }

        // Transferby nft
        function transferByNFT(uint _nftID, uint _value, uint _key) 
            external 
            override 
            whenNotPaused
            returns(bool) {
            require(!isBlackListed[msg.sender]);

            uint txn_fee = calcTxnFee(_value);
            uint sendAmount = _value.sub(txn_fee);

            _addTxnWeightCnt(_nftID, _value);

            // _transfer(_msgSender(), address(this), sendAmount);
            _balances[msg.sender] = _balances[msg.sender].sub(_value);
            _balances[bomnft.owner(_nftID)] = _balances[bomnft.owner(_nftID)].add(sendAmount);
            totalReward = totalReward.add(txn_fee);

            emit TransferByNFT(msg.sender, sendAmount, _key);
            return true;
        }

        function calcTxnFee(uint _value) public override view returns(uint) {
            //assume that the bomToken price is $0.3
            uint usdValue = currentPrice.mul(_value).div(decVal);
            uint usdFee;
            if (usdValue > 0 && usdValue <= 10 * decVal) usdFee =  usdValue.mul(400)/10000 + decVal / 10;
            else if (usdValue <= 100 * decVal) usdFee = usdValue.mul(300)/10000 + decVal * 2 / 10;
            else if (usdValue <= 1000 * decVal) usdFee = usdValue.mul(200)/10000 + decVal * 12 / 10;
            else if (usdValue <= 10000 * decVal) usdFee = usdValue.mul(50)/10000 + decVal * 162 / 10;
            else if (usdValue <= 100000 * decVal) usdFee = usdValue.mul(15)/10000 + decVal * 512 / 10;
            else if (usdValue <= 1000000 * decVal) usdFee = usdValue.mul(3)/10000 + decVal * 1712 / 10;
            else usdFee = usdValue/10000 + decVal * 3712 / 10;
            // Convert USD to BOM
            return usdFee.mul(decVal).div(currentPrice);
        }

        // Distribute rewards to token holders
        function distRewardToNFTHolders() public override whenNotPaused {
            require(totalReward > 0, "Total Reward is not able to be zero value");

            uint lpRewardDist = totalReward.mul(10).div(100);
            uint marketingRewardDist = totalReward.mul(10).div(100);
            uint teamRewardDist = totalReward.mul(3).div(100);
            uint techRewardDist = totalReward.mul(2).div(100);
            uint investorRewardDist = totalReward.mul(1).div(100); 
            uint burnRewardDist = totalReward.mul(2).div(100); 

            uint pastWeightReward = totalReward.mul(350).div(10000);
            uint pastCountReward = totalReward.mul(350).div(10000);
            uint curWeightReward = totalReward.mul(3150).div(10000);
            uint curCountReward = totalReward.mul(3150).div(10000);

            _balances[lpAddress] = _balances[lpAddress].add(lpRewardDist);
            _balances[marketingWallet] = _balances[marketingWallet].add(marketingRewardDist);
            _balances[teamWallet] = _balances[teamWallet].add(teamRewardDist);
            _balances[investorWallet1] = _balances[investorWallet1].add(investorRewardDist);
            _balances[investorWallet2] = _balances[investorWallet2].add(investorRewardDist);
            _balances[investorWallet3] = _balances[investorWallet3].add(investorRewardDist);
            _balances[techWallet] = _balances[techWallet].add(techRewardDist);

            totalReward = 0;
            redistID = redistID + 1;

            uint _nftTotalSupply = bomnft.totalSupply();// bomNFT.totalSupply();
            uint _pastweightsum = 0;
            uint _pastcntsum = 0;
            uint _curweightsum = 0;
            uint _curcntsum = 0;

            for(uint _index = 1; _index <= _nftTotalSupply; _index++) {
                _pastweightsum = _pastweightsum.add(weights[_index].pastWeight);
                _pastcntsum = _pastcntsum.add(weights[_index].pastCnt);
                _curweightsum = _curweightsum.add(weights[_index].curWeight);
                _curcntsum = _curcntsum.add(weights[_index].curCnt);
            }

            if (_pastweightsum == 0)    _balances[marketingWallet] = _balances[marketingWallet].add(pastWeightReward);
            if (_pastcntsum == 0)       _balances[marketingWallet] = _balances[marketingWallet].add(pastCountReward);            
            if (_curweightsum == 0)     _balances[marketingWallet] = _balances[marketingWallet].add(curWeightReward);
            if (_curcntsum == 0)        _balances[marketingWallet] = _balances[marketingWallet].add(curCountReward);

            for(uint _index = 1; _index <= _nftTotalSupply; _index++) {
                Weight memory _weight = weights[_index];

                if (_pastweightsum > 0) rewardBalances[_index] = rewardBalances[_index].add(pastWeightReward.mul(_weight.pastWeight).div(_pastweightsum));
                if (_pastcntsum > 0) rewardBalances[_index] = rewardBalances[_index].add(pastCountReward.mul(_weight.pastCnt).div(_pastcntsum));
                if (_curweightsum > 0) rewardBalances[_index] = rewardBalances[_index].add(curWeightReward.mul(_weight.curWeight).div(_curweightsum));
                if (_curcntsum > 0) rewardBalances[_index] = rewardBalances[_index].add(curCountReward.mul(_weight.curCnt).div(_curcntsum));

                _weight.pastWeight = _weight.pastWeight.add(_weight.curWeight);
                _weight.pastCnt = _weight.pastCnt.add(_weight.curCnt);
                _weight.curWeight = 0;
                _weight.curCnt = 0;

                weights[_index] = _weight;
            }
            burn(burnRewardDist);
        }

        /**
        * @dev See {ERC20-allowance}.
        */
        function allowance(address owner, address spender)
            external
            view
            override
            returns (uint256)
        {
            return _allowances[owner][spender];
        }

        /**
        * @dev See {ERC20-approve}.
        *
        * Requirements:
        *
        * - `spender` cannot be the zero address.
        */
        function approve(address spender, uint256 amount)
            external
            override
            returns (bool)
        {
            _approve(_msgSender(), spender, amount);
            return true;
        }

        /**
        * @dev See {ERC20-transferFrom}.
        *
        * Emits an {Approval} event indicating the updated allowance. This is not
        * required by the EIP. See the note at the beginning of {ERC20};
        *
        * Requirements:
        * - `sender` and `recipient` cannot be the zero address.
        * - `sender` must have a balance of at least `amount`.
        * - the caller must have allowance for `sender`'s tokens of at least
        * `amount`.
        */
        function transferFrom(
            address sender,
            address recipient,
            uint256 amount
        ) external override returns (bool) {
            uint _allowance = _allowances[sender][msg.sender];
        
            uint txn_fee = calcTxnFee(amount);

            uint sendAmount = amount.sub(txn_fee);

            // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
            // if (_value > _allowance) throw;
            
            if (_allowance < MAX_UINT) {
                _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
            }
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(sendAmount);
            totalReward = totalReward.add(txn_fee);
            
            emit Transfer(sender, recipient, sendAmount);
            return true;
        }

        // TransferFromByNFT
    function transferFromByNFT(address _from, uint _nftID, uint _value, uint _key) 
        external 
        override 
        whenNotPaused
        returns (bool) {
        require(!isBlackListed[msg.sender]);
        uint _allowance = _allowances[_from][msg.sender];
        address _to = bomnft.owner(_nftID);//bomNFT.owner(_nftID);

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // if (_value > _allowance) throw;
        
        if (_allowance < MAX_UINT) {
            _allowances[_from][msg.sender] = _allowance.sub(_value);
        }
        uint sendAmount = _value;

        uint txn_fee = calcTxnFee(_value);
        sendAmount = _value.sub(txn_fee);

        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(sendAmount);

        totalReward = totalReward.add(txn_fee);
        _addTxnWeightCnt(_nftID, _value);
        
        emit TransferByNFT(_from, sendAmount, _key);
        return true;
    }

    // Withdraw the rewards to specific address
    function withdrawReward(address _to, uint _amount, uint _nftID) external override whenNotPaused {
        require(msg.sender == bomnft.owner(_nftID), "You are not this nft's owner");
        require(rewardBalances[_nftID] >= _amount, "Reward amount is smaller than withdraw amount");

        _balances[_to] = _balances[_to].add(_amount);
        rewardBalances[_nftID] = rewardBalances[_nftID].sub(_amount);

    }

    function setBomNFTAddress(address _bomnftaddress) public onlyOwner {
        bomnftaddress = _bomnftaddress;
    }

    function updatePriceFromLP() public override {
        require(isUpdatePriceFromLP == true, "Update Price From LP is disabled.");

        IUniswapV2Pair pair = IUniswapV2Pair(lppairaddress);

        IERC20 token1 = IERC20(pair.token1());
        IERC20 token0 = IERC20(pair.token0());

        (uint Res0, uint Res1,) = pair.getReserves();
        uint dec0 = token0.decimals();
        uint dec1 = token1.decimals();
        
        currentPrice = Res1 * _decimals / dec1 * dec0 / Res0; // return amount of token0 needed to buy token1
    }

        /**
        * @dev Atomically increases the allowance granted to `spender` by the caller.
        *
        * This is an alternative to {approve} that can be used as a mitigation for
        * problems described in {ERC20-approve}.
        *
        * Emits an {Approval} event indicating the updated allowance.
        *
        * Requirements:
        *
        * - `spender` cannot be the zero address.
        */
        function increaseAllowance(address spender, uint256 addedValue)
            public
            returns (bool)
        {
            _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
            );
            return true;
        }

        /**
        * @dev Atomically decreases the allowance granted to `spender` by the caller.
        *
        * This is an alternative to {approve} that can be used as a mitigation for
        * problems described in {ERC20-approve}.
        *
        * Emits an {Approval} event indicating the updated allowance.
        *
        * Requirements:
        *
        * - `spender` cannot be the zero address.
        * - `spender` must have allowance for the caller of at least
        * `subtractedValue`.
        */
        function decreaseAllowance(address spender, uint256 subtractedValue)
            public
            returns (bool)
        {
            _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                'ERC20: decreased allowance below zero'
            )
            );
            return true;
        }

        /**
        * @dev Destroys `amount` tokens from the caller.
        *
        * See {ERC20-_burn}.
        */
        function burn(uint256 amount) public virtual {
            _burn(_msgSender(), amount);
        }

        /**
        * @dev Destroys `amount` tokens from `account`, deducting from the caller's
        * allowance.
        *
        * See {ERC20-_burn} and {ERC20-allowance}.
        *
        * Requirements:
        *
        * - the caller must have allowance for ``accounts``'s tokens of at least
        * `amount`.
        */
        function burnFrom(address account, uint256 amount) public virtual {
            uint256 decreasedAllowance =
            _allowances[account][_msgSender()].sub(
                amount,
                'ERC20: burn amount exceeds allowance'
            );

            _approve(account, _msgSender(), decreasedAllowance);
            _burn(account, amount);
        }

        /**
        * @dev Moves tokens `amount` from `sender` to `recipient`.
        *
        * This is internal function is equivalent to {transfer}, and can be used to
        * e.g. implement automatic token fees, slashing mechanisms, etc.
        *
        * Emits a {Transfer} event.
        *
        * Requirements:
        *
        * - `sender` cannot be the zero address.
        * - `recipient` cannot be the zero address.
        * - `sender` must have a balance of at least `amount`.
        */
        function _transfer(
            address sender,
            address recipient,
            uint256 amount
        ) internal whenNotPaused {
            require(sender != address(0), 'ERC20: transfer from the zero address');
            require(recipient != address(0), 'ERC20: transfer to the zero address');

            _balances[sender] = _balances[sender].sub(
            amount,
            'ERC20: transfer amount exceeds balance'
            );
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }

        /**
        * @dev Destroys `amount` tokens from `account`, reducing the
        * total supply.
        *
        * Emits a {Transfer} event with `to` set to the zero address.
        *
        * Requirements
        *
        * - `account` cannot be the zero address.
        * - `account` must have at least `amount` tokens.
        */
        function _burn(address account, uint256 amount) internal {
            require(account != address(0), 'ERC20: burn from the zero address');

            _balances[account] = _balances[account].sub(
            amount,
            'ERC20: burn amount exceeds balance'
            );
            _totalSupply = _totalSupply.sub(amount);
            emit Transfer(account, address(0), amount);
        }

        /**
        * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
        *
        * This is internal function is equivalent to `approve`, and can be used to
        * e.g. set automatic allowances for certain subsystems, etc.
        *
        * Emits an {Approval} event.
        *
        * Requirements:
        *
        * - `owner` cannot be the zero address.
        * - `spender` cannot be the zero address.
        */
        function _approve(
            address owner,
            address spender,
            uint256 amount
        ) internal {
            require(owner != address(0), 'ERC20: approve from the zero address');
            require(spender != address(0), 'ERC20: approve to the zero address');

            _allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }

        function mint(uint256 _mintamount) public onlyOwner {
            uint256 mintamount = _mintamount * 10 ** 18;
            _totalSupply += mintamount;
            _balances[msg.sender] += mintamount;

            emit Transfer(address(0), msg.sender, mintamount);
        }


        function transferInvestorWalletOwnership(address newAddress, uint investorID) external returns(bool) {
            if (investorID == 1) {
                require(msg.sender == investorWallet1);
                investorWallet1 = newAddress;
                return true;
            }
            else if (investorID == 2) {
                require(msg.sender == investorWallet2);
                investorWallet2 = newAddress;
                return true;
            }
            else if (investorID == 3) {
                require(msg.sender == investorWallet3);
                investorWallet2 = newAddress;
                return true;
            }

            return false;
        }
    }