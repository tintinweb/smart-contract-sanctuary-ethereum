/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}



interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
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
}

library Address {
    
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

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

   
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    
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

    
    function getApproved(uint256 tokenId) external view returns (address operator);

   
    function setApprovalForAll(address operator, bool _approved) external;

  
    function isApprovedForAll(address owner, address operator) external view returns (bool);

   
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    
    function safeApprove(
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract StakingNFT is Ownable {

    using SafeERC20 for IERC20;
    IERC20 public token;
    uint256 public totalTokens;
    uint public toatlPool = 0;
    struct tokenInfo {
        uint256 tokenId;
        uint rType;
        address nftContractAddress;
    }

    uint poolStakers = 0;
    uint poolShare = 0;
    
    mapping(address => mapping(uint256 => tokenInfo)) public tokeninfo;

    struct Staker {
        uint256 poolId;
        address nftContractAddress;
        uint256 tokenId;
        uint256 starttime;
        uint endtime;
        address userAddress;
        uint rType;
    }

    struct Pool {
        uint256 poolId;
        uint starttime;
        uint endtime;
        uint totalStakers;
        uint totalShare;
        bool isupdated;
        bool status;
    }

    struct userReward{
        uint poolId;
        address userAddress;
        uint totalReward;
        bool isClaim;
    }

    struct UserStakingHistory{
        uint256 poolId;
        address nftContractAddress;
        uint256 tokenId;
        uint256 starttime;
        uint endtime;
        uint256 rType;
        uint256 share;
        
    }

   Pool[] public poolinfo;
   Staker[] public stakerinfo;
   mapping(address => mapping(address => mapping(uint256 => Staker))) public staker;
   mapping(address => UserStakingHistory[]) public userhistory;
   mapping(address => userReward[]) public userreward;

    constructor(address _token) {
        token = IERC20(_token);
    }

    event Stake(address indexed owner, uint256 id,  uint256 time);
    event UnStake(address indexed owner, uint256 id, uint256 time, uint256 rewardTokens);

    
    function addPool(uint _starttime , uint256 _endtime ) external onlyOwner {
        require( _endtime > _starttime , "End time must be greater than starttime ");
        poolinfo.push(
            Pool
            (
            toatlPool,
            _starttime,
            _endtime,
            0,
            0,
            false,
            false
        ));

         toatlPool += 1;
    }

    function editPool(uint _poolId ,uint _starttime , uint256 _endtime ) external onlyOwner {
        require(_endtime > _starttime , "End time must be greater than starttime ");
        require(poolinfo[_poolId].endtime < block.timestamp , "Pool Is Over Can't Change");
        poolinfo[_poolId].starttime = _starttime;
        poolinfo[_poolId].endtime = _endtime;
        
    }

    function addBatchTokenId( address _nftContractAddress , uint256[] memory _batchTokenIds , uint256[] memory _rType ) external onlyOwner{
        require(_nftContractAddress != address(0) , "Invalid NFT Address !");
        require(_batchTokenIds.length > 0 , "Invalid length token Ids !");
        
        for (uint256 i = 0; i < _batchTokenIds.length; i++) {
            tokeninfo[_nftContractAddress][_batchTokenIds[i]].tokenId = _batchTokenIds[i];
            tokeninfo[_nftContractAddress][_batchTokenIds[i]].nftContractAddress = _nftContractAddress;
            tokeninfo[_nftContractAddress][_batchTokenIds[i]].rType = _rType[i];
        }
    }


    function removeBatchTokenId(address _nftContractAddress , uint256[] memory _batchTokenIds) external onlyOwner{
        require(_nftContractAddress != address(0) , "Invalid NFT Address !");
        require(_batchTokenIds.length > 0 , "Invalid length token Ids !");
        
        for (uint256 i = 0; i < _batchTokenIds.length; i++) {
            delete tokeninfo[_nftContractAddress][_batchTokenIds[i]];
        }
    }

    function getActivePool() external view returns (uint) {
        uint poolId = 0;
        for (uint256 i = 0; i < poolinfo.length; i++) {
            if(poolinfo[i].starttime <= block.timestamp && poolinfo[i].endtime >= block.timestamp){
                poolId = poolinfo[i].poolId;
            }
        }
        return poolId;
    }

    function getUserStakeInfo(address _userAddress) public view returns (UserStakingHistory[] memory)
    {
        return userhistory[_userAddress];
    }

    function getUserTotalReward(address _userAddress) public view returns (userReward[] memory)
    {
        return userreward[_userAddress];
    }

    function totalRewardAvalible(address _userAddress)  public view returns(uint){
        userReward[] storage userdata = userreward[_userAddress];
        uint total = 0;
        for (uint256 i = 0; i < userdata.length; i++) {
            if(!userdata[i].isClaim){
                total += userdata[i].totalReward;
            }
        }
        return total;
    }

    function claimReward() public{
        userReward[] storage userdata = userreward[msg.sender];
        
        for (uint256 i = 0; i < userdata.length; i++) {
            if(!userdata[i].isClaim){
                uint total = userdata[i].totalReward;
                token.transfer(address(this) , total);
                userdata[i].isClaim = true;
            }
        }
        
    } 

    function _getCurrentPoolId() internal view returns (uint){
        uint poolId = 0;
        bool check = false; 
        for (uint256 i = 0; i < poolinfo.length; i++) {
            if(poolinfo[i].starttime <= block.timestamp && poolinfo[i].endtime >= block.timestamp){
                poolId = poolinfo[i].poolId;
                check = true;
            }
        }

        require(check == true , "Current Pool Not Exist Or Not Stared ");
        return poolId;
    }

    function distributeReward(uint _poolId) external onlyOwner {
        uint poolend =  poolinfo[_poolId].endtime;
        bool isupdated = poolinfo[_poolId].isupdated;
        bool status = poolinfo[_poolId].status;

        require(poolend < block.timestamp , "Pool is not end yet!" );
        require(!status , "Pool Has Already distributed !");
        if(!isupdated){
            poolinfo[_poolId].totalStakers = poolStakers;
            poolinfo[_poolId].totalShare = poolShare;
            poolinfo[_poolId].isupdated = true;
        }

        uint rewardAmount = token.balanceOf(address(this));
        require(rewardAmount > 0 , "Reward Amount must be greater than Zero");

        uint eachShare = rewardAmount /  poolinfo[_poolId].totalShare;

        for (uint256 i = 0; i < stakerinfo.length; i++) {
            uint _tokenId = stakerinfo[i].tokenId;
            address _nftContractAddress = stakerinfo[i].nftContractAddress;
            address _userAddress = stakerinfo[i].userAddress;   
            if(staker[_userAddress][_nftContractAddress][_tokenId].starttime > 0 && staker[_userAddress][_nftContractAddress][_tokenId].starttime <= poolend  ){
                uint user_Reward = staker[_userAddress][_nftContractAddress][_tokenId].rType * eachShare;
                userreward[_userAddress].push(
                    userReward(
                    _poolId,
                    _userAddress,
                    user_Reward,
                    false
                    )
                );
            }
        }
    }

    function _getActivePool() internal view returns (uint) {
        uint poolId = 0;
        for (uint256 i = 0; i < poolinfo.length; i++) {
            if(poolinfo[i].starttime <= block.timestamp && poolinfo[i].endtime >= block.timestamp){
                poolId = poolinfo[i].poolId;
            }
        }
        return poolId;
    }

    function _updatePoolInfo() internal {
        uint cPool = _getActivePool();
        uint lastPool = 0;
        if(cPool == 0){
            lastPool = 0;
        }
        else{
            lastPool = cPool - 1;
        }
        
        if( poolinfo[lastPool].endtime < block.timestamp  &&  !poolinfo[lastPool].isupdated){
            poolinfo[lastPool].totalStakers = poolStakers;
            poolinfo[lastPool].totalShare = poolShare;
            poolinfo[lastPool].isupdated = true;
        }

    }

    function _checkTokenIdEligible(address _nftContractAddress , uint256 _tokenId ) internal view returns (bool){
        require(tokeninfo[_nftContractAddress][_tokenId].nftContractAddress != address(0), "Token Id Not Eligible !");
        return true; 
    }

    function stakeNFT(uint256 _poolId , address _nftContractAddress  ,uint256 _tokenId) public{
        require(_nftContractAddress != address(0) , "Please Enter Valid NFT Address");
        require(IERC721(_nftContractAddress).balanceOf(msg.sender) > 0,"you dont have enough balance");
        require(IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender ,"you dont have enough balance");
        _getCurrentPoolId();
        _updatePoolInfo();
        _checkTokenIdEligible(_nftContractAddress , _tokenId);
        uint rType = tokeninfo[_nftContractAddress][_tokenId].rType;
        
        IERC721(_nftContractAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenId
        );


        staker[msg.sender][_nftContractAddress][_tokenId] = 
            Staker
            (
            _poolId,
            _nftContractAddress,
            _tokenId,
            block.timestamp,
            0,
            msg.sender,
            rType
         );

         stakerinfo.push( 
            Staker
            (
            _poolId,
            _nftContractAddress,
            _tokenId,
            block.timestamp,
            0,
            msg.sender,
            rType
         ));

         userhistory[msg.sender].push(
             UserStakingHistory
                (
                _poolId,
                _nftContractAddress,
                _tokenId,
                block.timestamp,
                poolinfo[_poolId].endtime,
                rType,
                0
            )
         );
         
        poolStakers += 1;
        poolShare += rType;

        emit Stake (msg.sender, _tokenId , block.timestamp);
    }

    function _checkIsUserStaked(address _nftContractAddress  ,uint256 _tokenId)  internal view returns (bool){
        require(staker[msg.sender][_nftContractAddress][_tokenId].nftContractAddress != address(0) , "Token Doesn't Exist");
        return true;
    } 

    function unStakeNFT(address _nftContractAddress , uint256 _tokenId) public {
        require(_nftContractAddress != address(0) , "Please Enter Valid NFT Address");
        _checkIsUserStaked(_nftContractAddress , _tokenId );
        _updatePoolInfo();
        uint rType = tokeninfo[_nftContractAddress][_tokenId].rType;
        
        IERC721(_nftContractAddress).safeTransferFrom( address(this), msg.sender, _tokenId);
        delete staker[msg.sender][_nftContractAddress][_tokenId];
        poolStakers -= 1;
        poolShare -= rType;
         
    }

}