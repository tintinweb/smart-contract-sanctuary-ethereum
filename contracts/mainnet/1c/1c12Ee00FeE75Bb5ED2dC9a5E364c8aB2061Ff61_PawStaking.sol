/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-28
*/

// File: @openzeppelin/[email protected]/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/[email protected]/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol


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

// File: investmentStaking.sol



pragma solidity ^0.8.4;



struct stake {
    uint256 stakedAmount;
    uint256 dateAtStake;
    uint256 totalFeesAtEntry;
}

struct feeCollectionArchive {
    uint256 feeCollected;
    uint256 cumulativeFeesCollected;
    uint256 stakedTokens;
    uint256 amountClaimedByStakers;
    uint256 timestamp;
}

interface IERC20Burn {
    function burn(uint256 amount) external;
}

contract PawStaking is Ownable {

    address public immutable _investmentTokenAddress;
    address public feeHandlerAddress = address(0);
    mapping(address => stake[]) public _accountStakingInfo;
    feeCollectionArchive[] public _feeCollectionValues;
    mapping(address => uint256) public _amountOfStakes;

    uint256 public _totalFeesCollected = 0;
    uint256 public _amountOfStakers = 0;
    uint256 public _totalTokensStaked = 0;
    bool public acceptingNewStakes = true;

    event feesDeposited(
        uint256 amountDeposited
    );

    constructor(address investmentTokenAddress_){
        _investmentTokenAddress = investmentTokenAddress_;
        _feeCollectionValues.push(feeCollectionArchive(0,0,0,0,block.timestamp));
    }

    function isAddressStaking(address _address) public view returns (bool) {
        if(_amountOfStakes[_address] == 0){
            return false;
        } else {
            return true;
        }
        
    }
    function getFeeCollectionValues() public view returns (feeCollectionArchive[] memory) {
        return _feeCollectionValues;
    }

    function removeEntryFromStakingInfo(address _address, uint256 index) internal {
        if(_amountOfStakes[_address] == index + 1){
            _accountStakingInfo[_address].pop();
        } else {
            _accountStakingInfo[_address][index] = _accountStakingInfo[_address][_accountStakingInfo[_address].length-1];
            _accountStakingInfo[_address].pop();
        }
        _amountOfStakes[_address]--;
        if(_amountOfStakes[_address] == 0){
            _amountOfStakers--;
        }
    }

    function getFeesAvailableToCollect(uint256 stakedAmount, uint256 amountOfFeesAtEntry) public view returns (uint256) {
        uint256 feestoCollect = 0;
        for(uint i = 0; i < _feeCollectionValues.length; i++){
            if(_feeCollectionValues[i].cumulativeFeesCollected > amountOfFeesAtEntry){
                uint256 shareOfFees = stakedAmount * 10**18 / _feeCollectionValues[i].stakedTokens;
                feestoCollect += _feeCollectionValues[i].feeCollected * shareOfFees / 10**18;
            }
        }
        return feestoCollect;
    }

    function changeStakeAcceptance(bool newValue) public onlyOwner {
        acceptingNewStakes = newValue;
    }

    function setFeeHandlerAddress(address _feeHandlerAddress) public onlyOwner {
        feeHandlerAddress = _feeHandlerAddress;
    }

    function addFees(uint256 feeAmount) public {
        require(msg.sender == feeHandlerAddress);
        require(IERC20(_investmentTokenAddress).allowance(msg.sender, address(this)) >= feeAmount, "You must approve the staking contract to use the fees you wish to add!");
        require(IERC20(_investmentTokenAddress).balanceOf(msg.sender) >= feeAmount, "You do not have enough tokens to add!");
        require(feeAmount > 0, "You must deposit more than 0 tokens!");

        IERC20(_investmentTokenAddress).transferFrom(msg.sender, address(this), feeAmount);
        _totalFeesCollected += feeAmount;

        if(block.timestamp - _feeCollectionValues[_feeCollectionValues.length - 1].timestamp >= 60 ){  // * 60 * 24
            feeCollectionArchive memory lastFeeCollectionValue = _feeCollectionValues[_feeCollectionValues.length - 1];
            _feeCollectionValues.push(feeCollectionArchive(
                _totalFeesCollected - lastFeeCollectionValue.cumulativeFeesCollected,
                _totalFeesCollected,
                _totalTokensStaked,
                0,
                block.timestamp
            )); 
            if(_feeCollectionValues.length > 120){ 
                uint256 amountToBurn = _feeCollectionValues[0].feeCollected - _feeCollectionValues[0].amountClaimedByStakers;
                if(amountToBurn > 0){
                    IERC20(_investmentTokenAddress).approve(_investmentTokenAddress, amountToBurn);
                    IERC20Burn(_investmentTokenAddress).burn(amountToBurn);
                }
                for (uint i = 0; i<_feeCollectionValues.length-1; i++){
                    _feeCollectionValues[i] = _feeCollectionValues[i+1];
                }
                _feeCollectionValues.pop();
            }       
        }
        emit feesDeposited(feeAmount);
    }

    function deposit(uint256 amountToDeposit) public {
        require(acceptingNewStakes == true, "This contract is no longer accepting new stakes. This may be because a new staking contract has been created. Users may still withdraw.");
        require(IERC20(_investmentTokenAddress).allowance(msg.sender, address(this)) >= amountToDeposit, "You must approve the staking contract to use the tokens you wish to stake!");
        require(IERC20(_investmentTokenAddress).balanceOf(msg.sender) >= amountToDeposit, "You do not have enough tokens to stake!");
        require(amountToDeposit > 0, "You must deposit more than 0 tokens!");

        IERC20(_investmentTokenAddress).transferFrom(msg.sender, address(this), amountToDeposit);
        _accountStakingInfo[msg.sender].push(stake(amountToDeposit, block.timestamp, _totalFeesCollected));

        if(_amountOfStakes[msg.sender] == 0){
            _amountOfStakers++;
        }
        _amountOfStakes[msg.sender]++;
        _totalTokensStaked += amountToDeposit;
    }

    function withdraw(uint256 indexToWithdraw) public {
        require(indexToWithdraw <= _amountOfStakes[msg.sender] - 1, "This position does not exist!");
        require(block.timestamp - _accountStakingInfo[msg.sender][indexToWithdraw].dateAtStake >= 60, "Your tokens must be staked for at least 60 days!");

        uint256 stakedAmount = _accountStakingInfo[msg.sender][indexToWithdraw].stakedAmount;
        uint256 totalFeesAtEntry = _accountStakingInfo[msg.sender][indexToWithdraw].totalFeesAtEntry;

        removeEntryFromStakingInfo(msg.sender, indexToWithdraw);
        
        uint256 amountToCollect = getFeesAvailableToCollectAnAddToClaims(stakedAmount, totalFeesAtEntry);
        IERC20(_investmentTokenAddress).transfer(msg.sender, amountToCollect + stakedAmount);
        _totalTokensStaked -= stakedAmount; 

    }

    function getFeesAvailableToCollectAnAddToClaims(uint256 stakedAmount, uint256 amountOfFeesAtEntry) internal returns (uint256) {
        uint256 feestoCollect = 0;
        for(uint i = 0; i < _feeCollectionValues.length; i++){
            if(_feeCollectionValues[i].cumulativeFeesCollected > amountOfFeesAtEntry){
                uint256 shareOfFees = stakedAmount * 10**18 / _feeCollectionValues[i].stakedTokens;
                uint256 amountToClaim = _feeCollectionValues[i].feeCollected * shareOfFees / 10**18;
                feestoCollect += amountToClaim;
                _feeCollectionValues[i].amountClaimedByStakers += amountToClaim;
            }
        }
        return feestoCollect;
    }

}