/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface NFTMINT {
    function stakeMint(address _to) external returns(uint256);
}


contract MRSTAKE is Context, Ownable {
    using SafeMath for uint256;
    IERC20 public token;
    uint256 public stakeAmount;
    uint256 public stakeTime = 30 days;
    NFTMINT public nftToken;
    mapping(address => uint256[]) private userMintIds;

    struct Stake {
        uint256 nftId;
        uint256 unlockTime;
        uint256 stakedAmount;
        address owner;
    }

    mapping(uint256 => Stake) private stakeInfo;

    constructor(
        address _token,
        uint256 _stakeAmount,
        address _nftToken
    ){
        token = IERC20(_token);
        stakeAmount = _stakeAmount;
        nftToken = NFTMINT(_nftToken);
    }

    /**
    * @dev Stake the stakeAmount of token and mint new nft
    * Mint new NFT to msg.sender
    * Emits a {Staked} event
    */
    event Staked(
        address indexed account, 
        uint256 stakeAmount, 
        uint256 _nftId
    );
    function stake() external {
        token.transferFrom(_msgSender(), address(this), stakeAmount);
        uint256 _nftId = nftToken.stakeMint(_msgSender());
        userMintIds[_msgSender()].push(_nftId);
        Stake memory _stakeInfo = stakeInfo[_nftId];
        _stakeInfo.nftId = _nftId;
        _stakeInfo.unlockTime = block.timestamp.add(stakeTime);
        _stakeInfo.stakedAmount = stakeAmount;
        _stakeInfo.owner = _msgSender();
        stakeInfo[_nftId] = _stakeInfo;
        emit Staked(_msgSender(), stakeAmount, _nftId);
    }

    /**
    * @dev Restake if the unlock time is over 
    * Mint new NFT to msg.sender
    * Emits a {Staked} event
     */
    function reStake(
        uint256 _nftId
    ) external {
        Stake memory _stakeInfo = stakeInfo[_nftId];
        require(_stakeInfo.owner == _msgSender(), "caller is not the owner of nft");
        require(
            _stakeInfo.unlockTime != 0 && 
            _stakeInfo.nftId != 0 , 
            "stake not found"
        );
        require(block.timestamp >= _stakeInfo.unlockTime, "lock is not completed");
        removeNftId(_nftId, _msgSender());
        delete(stakeInfo[_nftId]);
        _nftId = nftToken.stakeMint(_msgSender());
        _stakeInfo.nftId = _nftId;
        _stakeInfo.unlockTime = block.timestamp.add(stakeTime);
        stakeInfo[_nftId] = _stakeInfo;
        userMintIds[_msgSender()].push(_nftId);
        emit Staked(_msgSender(), stakeAmount, _nftId);
    }

    /**
    * @dev Unstake based on nft id only if unlock time is over
    * Transfer staked amount of token to the msg.sender
    * Emits a {Unstaked} event
     */
    event Unstaked(
        address indexed account,
        uint256 stakeAmount,
        uint256 _nftId
    );

    function unstake(
        uint256 _nftId
    ) external {
        Stake memory _stakeInfo = stakeInfo[_nftId];
        require(_stakeInfo.owner == _msgSender(), "caller is not the owner of the stake");
        require(
            _stakeInfo.nftId != 0 && 
            _stakeInfo.unlockTime != 0, 
            "stake not found"
        );
        require(block.timestamp >= _stakeInfo.unlockTime, "lock is not completed.");
        removeNftId(_nftId, _msgSender());
        uint256 _stakedAmount = _stakeInfo.stakedAmount;
        delete(stakeInfo[_nftId]);
        token.transfer(_msgSender(), _stakedAmount);
        emit Unstaked(_msgSender(), _stakedAmount, _nftId);
    }

    function removeNftId(
        uint256 _nftId,
        address user
    ) internal {
        uint256 index;
        if(userMintIds[user].length != 0) {
            for(uint256 i; i < userMintIds[user].length; i++) {
                if(userMintIds[user][i] == _nftId){
                    index = i;
                    break;
                }
            }
            userMintIds[user][index] = userMintIds[user][userMintIds[user].length - 1];
            userMintIds[user].pop();
        }
    }

    /**
    * @dev Update the token address
    * Emits a {UpdateToken} event
     */
    event UpdateToken(address indexed _newToken);
    function updateToken(
        address _newToken
    ) external onlyOwner {
        token = IERC20(_newToken);
        emit UpdateToken(_newToken);
    }

    /**
    * @dev Update token stake amount
    * Emits a {UpdateStakeAmount} event 
     */
    event UpdateStakeAmount(uint256 _stakeAmount);
    function updateStakeAmount(
        uint256 _stakeAmount
    ) external onlyOwner {
        stakeAmount = _stakeAmount;
        emit UpdateStakeAmount(_stakeAmount);
    }

    /**
    * @dev Update token stake time
    * Emits a {UpdateStakeTime} event
     */
    event UpdateStakeTime(uint256 _stakeTime);
    function updateStakeTime(
        uint256 _stakeTime
    ) external onlyOwner {
        stakeTime = _stakeTime;
        emit UpdateStakeTime(_stakeTime);
    }

    /**
    * @dev Take any `_token` from the contract
     */
    function withdrawToken(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }


    /**
    * @dev Take `_amount` of eth out from the contract to `_to` wallet address
     */
    function withdrawETH(
        address _to,
        uint256 _amount
    ) external onlyOwner {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "eth sending failed.");
    }

    /**
    * @dev Get user stake nft ids
     */
    function userStakedIds(
        address _user
    ) external view returns(uint256[] memory ) {
        return userMintIds[_user];
    }

    /**
    * @dev Get stake detail based on minted nft id
     */
    function getStakeInfo(
        uint256 _nftId
    ) external view returns(Stake memory) {
        return stakeInfo[_nftId];
    }

    /**
    * @dev Update the NFT address
    * Emits a {UpdateNftAddress} event
     */
    event UpdateNftAddress(address indexed _nftAddress);
    function updateNftAddress(
        address _nftAddress
    ) external onlyOwner {
        nftToken = NFTMINT(_nftAddress);
        emit UpdateNftAddress(_nftAddress);
    }

}