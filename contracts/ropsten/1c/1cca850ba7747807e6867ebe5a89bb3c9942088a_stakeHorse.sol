/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;


library AddressUpgradeable {
    function isContract(address account) internal view returns (bool) {
   
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


pragma solidity ^0.8.0;


abstract contract Initializable {
    bool private _initialized;

    bool private _initializing;

    modifier initializer() {
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


pragma solidity ^0.8.0;

interface IERC20Upgradeable {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.8.0;

library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }


    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


pragma solidity ^0.8.0;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC165Upgradeable {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Upgradeable is IERC165Upgradeable {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

   event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}



contract stakeHorse is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;

    struct Staked_Data{
        uint256[] NFT;
        uint256 stake_time;                 // when user staked and then it will update with last time when user claim stake reward 
        uint256 reward_claim;               // total amount of reward user have claimed
    }
    mapping(address => Staked_Data) public stakes;      // return Data of single staked NFT
        
    IERC20Upgradeable private  _token;
    address public NFTAddress;

    uint    private activeUsers;    // No. of stakers
    address private owner;
    uint256 private APY;
    uint256 updatedTime;
    uint256 public totalLocked;       // No. of NFT staked
    uint256 public totalRedeemed;    //  No. of tokens claimed in reward
    uint256 private stakersLimit;   //   No. of users can stake
    uint256 public maturityDays;    
    
    event Staked(uint256 amount, address staker);
    
    function initialize(IERC20Upgradeable token_, uint256 apy0) public initializer  {
        _token = token_;
        NFTAddress = 0xc597ce4c81f09eDCB397671bba19447bA24115e3;
        owner = msg.sender;
        updatedTime = block.timestamp;
        
        // 1000 = 100% or 100 = 1% or 10 = 0.1% or 1 = 0.01% 
        APY = apy0;
        maturityDays = 2;
        stakersLimit = 100000;
    }


    function StakeAmount(uint256[] memory _id) public {
        require(IERC721Upgradeable(NFTAddress).isApprovedForAll(msg.sender, address(this)) == true, "You should approve nft to the staking contract" );
        
        for (uint256 i = 0; i < _id.length; i++) {
            require(_id[i] >= 0 && _id[i] <= 10000, "Invalid ID");
            _locker( _id[i], msg.sender );
        }
    }
    
    function _locker(uint256 _id, address _user) internal {
        require( IERC721Upgradeable(NFTAddress).ownerOf(_id) == _user, "You are not a owner of the nft" );

        IERC721Upgradeable(NFTAddress).transferFrom( _user, address(this), _id );

        totalLocked += 1;
        stakes[msg.sender].NFT.push(_id);
        stakes[msg.sender].stake_time = block.timestamp;

        if(stakes[msg.sender].NFT.length == 1) activeUsers++;

        emit Staked(_id, msg.sender);
    }
    
    function My_Stakes(address _user) public view returns(uint256, uint256[] memory, uint256, uint256) {
        uint256 amount = stakes[_user].NFT.length;
        uint256[] memory IDs = stakes[_user].NFT;
        
        return(amount, IDs, stakes[_user].stake_time, stakes[_user].reward_claim);
    }
    
    function claimAble(address _user) public view returns(uint256, uint256){
        require(stakes[_user].NFT.length > 0,'You are not a staker');
        Staked_Data memory stakee = stakes[_user];
        uint256 perDayReward = stakee.NFT.length.mul(APY).div(5);
        uint256 claimableDays;
        if(stakee.stake_time > updatedTime){
            claimableDays = block.timestamp.sub(stakee.stake_time).div(2 minutes);
        }else{
            if(updatedTime > block.timestamp){
                claimableDays = 0;
            }else{
                claimableDays = block.timestamp.sub(updatedTime).div(2 minutes);
            }
        }
        return (claimableDays,perDayReward.mul(claimableDays));
    }

    function stakersActive() external view virtual returns (uint256) {
        return activeUsers;
    }
    
    function redeem() public{
        require(msg.sender == tx.origin, 'Invalid');
        require(stakes[msg.sender].NFT.length > 0,'You are not a staker');
        require(block.timestamp.sub(stakes[msg.sender].stake_time).div(2 minutes) > maturityDays,'Rewards not matured');

        (uint256 claimableDays, uint256 perDayReward) = claimAble(msg.sender);

        uint256 claimableReward = perDayReward.mul(claimableDays);
        require(claimableReward < RewardPot(), 'Reward Pot is empty');
        stakes[msg.sender].stake_time = block.timestamp;
        stakes[msg.sender].reward_claim += claimableReward;
        totalRedeemed += claimableReward;
    
    
        _token.safeTransfer(msg.sender,claimableReward);
    }

    function UnStake(uint256[] memory __ids) public {
        for (uint256 i = 0; i < __ids.length; i++) {
            _unStake(__ids[i]);
        }

    }

   function _unStake(uint256 __ids) public {

        for (uint256 i = 0; i < stakes[msg.sender].NFT.length; i++) {
            if (stakes[msg.sender].NFT[i] == __ids) {
                IERC721Upgradeable(NFTAddress).transferFrom( address(this), msg.sender, __ids );

                stakes[msg.sender].NFT[i] = stakes[msg.sender].NFT[stakes[msg.sender].NFT.length - 1];
                stakes[msg.sender].NFT.pop();
                
                totalLocked --;
                if(stakes[msg.sender].NFT.length == 0) activeUsers--;
            }
        }

    }

    function calculatePerDayRewards(uint256 amount) external view returns(uint256){
        uint256 perDayReward = amount.mul(APY).div(10000).div(365);
        return (perDayReward);
    }
    
    function RewardPot() public view virtual returns (uint256) {
        return token().balanceOf(address(this)) - totalLocked;
    }
    
    function withdrawRewardsPot(uint256 amount) external onlyOwner {
        require(amount < RewardPot(), 'Insufficient');
        _token.safeTransfer(msg.sender, amount);
    }

    function transferOwnership(address newOwner) external onlyOwner{
    	require(newOwner != address(0), "ZeroAddress");
    	owner = newOwner;
    }
    
    function setToken(IERC20Upgradeable Token_) external onlyOwner {
        _token = Token_;
    }

    function changeStakersLimit(uint256 _limit) external onlyOwner{
        require(_limit > 0,"> 0");
        stakersLimit = _limit;
    }

    function changeMaturityDays(uint256 _days) external onlyOwner{
    	require(_days > 0,"> 0");
        maturityDays = _days;
    }

    function currentTimestamp() external view returns(uint256){
        return block.timestamp;
    }
    
    /**
     * Change APY Functions:
     * Change APY with update time , so every staker should need to claim their rewards,
     * before any change apy event occurs
    **/
    function changeStakingAPY(uint256 newAPY, uint256 _stoppedTill) public onlyOwner{
        require(newAPY < 150000, '> 1500%');
        APY = newAPY;
        updatedTime = _stoppedTill;
    }
      
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function token() public view virtual returns (IERC20Upgradeable) {
        return _token;
    }
    
    function NFT() public view virtual returns (address) {
        return NFTAddress;
    }

}