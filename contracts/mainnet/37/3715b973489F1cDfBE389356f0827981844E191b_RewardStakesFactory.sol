/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC721 {

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
}

interface ERC721TokenReceiver {

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}


library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    address private _factory;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FactoryOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        _factory = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyFactory() {
        require(_factory == _msgSender(), "Ownable: caller is not the Factory");
        _;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function transferFactoryOwnership(address newOwner) public virtual onlyFactory {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit FactoryOwnershipTransferred(_factory, newOwner);
        _factory = newOwner;
    }
}

interface EverRiseNFT is IERC721 {

    function withdrawRewards() external;
    function unclaimedRewardsBalance(address) external view returns (uint256);
    function getTotalRewards(address) external view returns (uint256);
}

contract RewardStakes is Context, Ownable, ERC721TokenReceiver {
    using Address for address;

    error StakeStillLocked(); //0x7f6699f6
    error NotEnoughRewards(); //0x1e6918b1
    
    string private _name = "RiseStakeHolder";
    string private _symbol = "RSH";
    address public everRiseNFTStakeAddress = 0x23cD2E6b283754Fd2340a75732f9DdBb5d11807e;
    address public everRiseAddress = 0xC17c30e98541188614dF99239cABD40280810cA3;
    uint256 public constant month = 30 days;
    uint256 public end_time;
    
    constructor (address newOwner) {
        end_time = block.timestamp + (1 * month);
        transferOwnership(newOwner);
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function updateEndTime() external onlyFactory {
        end_time = 0;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns(bytes4) {
        return this.onERC721Received.selector;
    }


    function updateEverRiseInfo (address erAddress, address erStakeAddress) external onlyFactory {
        everRiseAddress = erAddress;
        everRiseNFTStakeAddress = erStakeAddress;
    }

    function claimRewards(address toAddress) external onlyFactory {
        uint256 availableRewards = unclaimedRewardsBalance();
        if (availableRewards <= 0) {
            revert NotEnoughRewards(); 
        }
        EverRiseNFT(everRiseNFTStakeAddress).withdrawRewards();
        IERC20(everRiseAddress).transfer(toAddress, availableRewards);
    }

    function transferNFT(address toAddress, uint256 tokenID) external onlyFactory {
        if (isStillLocked()) {
            revert StakeStillLocked();
        }
        IERC721(everRiseNFTStakeAddress).safeTransferFrom(address(this), toAddress, tokenID);
    }

    function isStillLocked() public view returns (bool) {
        return (end_time > block.timestamp);
    }

    function unclaimedRewardsBalance() public view returns (uint256) {
        return EverRiseNFT(everRiseNFTStakeAddress).unclaimedRewardsBalance(address(this));
    }

    function totalRewards() public view returns (uint256) {
        return EverRiseNFT(everRiseNFTStakeAddress).getTotalRewards(address(this));
    }

    function totalStakedAmount() public view returns (uint256) {
        return IERC20(everRiseAddress).balanceOf(address(this));
    }
    
    function transferTokens(address tokenAddress, address toAddress) public onlyFactory {
        uint256 amount = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(toAddress, amount);
    }
}

contract RewardStakesFactory is Context, Ownable {
    
    using Address for address;

    error AccountAlreadyAdded();
    error NotZeroAddress();

    mapping (address => RewardStakes) private _rewardStakes;
    mapping (address => uint256[]) private _nftLists;
    string private _name = "RiseRewardStakes";
    string private _symbol = "RRS";
    address newOwner = 0x33280D3A65b96EB878dD711aBe9B2c0Dbf740579;

    constructor () {       
        transferOwnership(newOwner); 
    }

    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function createRiseStake(address toAddress, uint256[] calldata nftIDs) public onlyOwner {
        if (toAddress == address(0)) revert NotZeroAddress();
        if (_rewardStakes[toAddress] != RewardStakes(address(0))) revert AccountAlreadyAdded();
        RewardStakes rs = new RewardStakes(toAddress);
        _rewardStakes[toAddress] = rs;
        _nftLists[toAddress] = nftIDs;
    }

    function addNFT(address toAddress, uint256 id) external onlyOwner {
        _nftLists[toAddress].push(id);
    }

    function getNFTIDs() external view returns (uint256[] memory) {
        return _nftLists[_msgSender()];
    }

    function claimRewards() external {
        _rewardStakes[_msgSender()].claimRewards(_msgSender());
    }

    function isStillLocked() external view returns (bool) {
        return _rewardStakes[_msgSender()].isStillLocked();
    }

    function transferNFT(uint256 tokenID) external {
        _rewardStakes[_msgSender()].transferNFT(_msgSender(), tokenID);
    }

    function transferNFT(address toAddress, uint256 tokenID) external {
        _rewardStakes[_msgSender()].transferNFT(toAddress, tokenID);
    }

    function unclaimedRewardsBalance() external view returns (uint256) {
        return _rewardStakes[_msgSender()].unclaimedRewardsBalance() / 10**18;
    }

    function totalRewards() external view returns (uint256) {
        return _rewardStakes[_msgSender()].totalRewards() / 10**18;
    }

    function totalStakedAmount() external view returns (uint256) {
        return _rewardStakes[_msgSender()].totalStakedAmount() / 10**18;
    }
    
    function transferTokens(address tokenAddress, address toAddress) public onlyOwner {
        uint256 amount = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transferFrom(address(this), toAddress, amount);
    }

    function updateEverRiseInfo (address erAddress, address erStakeAddress) external onlyOwner {
        _rewardStakes[_msgSender()].updateEverRiseInfo(erAddress, erStakeAddress);
    }

    function updateLock(address toAddress) external onlyOwner {
        _rewardStakes[toAddress].updateEndTime();
    }
    
}