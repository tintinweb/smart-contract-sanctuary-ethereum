/**
 *Submitted for verification at Etherscan.io on 2023-03-23
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.0;

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

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
        uint256 tokenId,
        bytes calldata data
    ) external;
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
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


contract ERC721Holder is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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

contract NFT_Staking is Ownable, ERC721Holder {

    IERC20 internal R_Token;
    IERC721 internal NFT;
    
    uint256 public dailyReward = 10_000;
    uint256 public duration = 30 seconds;//24 hours;

    struct slot {
        uint _tokenId;
        uint _stakeTime;
        uint _lastclaimed;
        uint _Claimed;
    }

    struct user {
        uint _totalStaked;
        uint _totalClaimed;
        slot[] _rslot;
    }
    mapping (address => user) public record;

    mapping (uint => uint) public sTokenReward;  //nft id => dailyreward
    uint[] public tokenAdded;

    uint public maxNormalNftReward = 300_000;
    uint public maxSpecialNftReward = 400_000;

    uint256 public totalStaked;
    uint256 public totalRewardDistributed;

    constructor(address _token, address _nft) {
        R_Token = IERC20(_token);
        NFT = IERC721(_nft);
    }

    function stake(uint _id) public {
        address account = msg.sender;
        NFT.transferFrom(account, address(this), _id);
        slot memory newSlot = slot(
            _id,
            block.timestamp,
            block.timestamp,
            0
        );
        record[account]._rslot.push(newSlot);
        record[account]._totalStaked = record[account]._rslot.length;
        totalStaked++;
    }

    function unstake(uint _index) public {
        address account = msg.sender;
        uint length = record[account]._rslot.length;
        require(length>0,"Record Not Found");
        uint _id = record[account]._rslot[_index]._tokenId;
        uint reward = getRewardInfo(account,_id);
        record[account]._rslot[_index] = record[account]._rslot[length - 1];
        record[account]._rslot.pop();
        NFT.transferFrom(address(this),account, _id);
        if(reward > 0) R_Token.transfer(account,reward);
        totalRewardDistributed += reward;
        totalStaked--;
    }

    function claimReward(uint _index) public {
        address account = msg.sender;
        uint length = record[account]._rslot.length;
        require(length>0,"Record Not Found");
        uint _id = record[account]._rslot[_index]._tokenId;
        uint reward = getRewardInfo(account,_id);
        if(reward > 0) {
            record[account]._rslot[_index]._lastclaimed = block.timestamp;
            record[account]._rslot[_index]._Claimed += reward;
            R_Token.transfer(account,reward);
            totalRewardDistributed += reward;
        }
        else {
            revert("Invalid Reward Count!");
        }
    }

    function getRewardInfo(address _user, uint _tokenId) public view returns (uint) {
        uint _index = getTokenindex(_user,_tokenId);
        uint _lastClaimed = record[_user]._rslot[_index]._lastclaimed;
        uint rtransfer = record[_user]._rslot[_index]._Claimed;
        uint factor = block.timestamp - _lastClaimed;
        uint multiplier = factor / duration;
        (uint reward,bool special) = sTokenReward[_tokenId] > 0 ? (sTokenReward[_tokenId]*multiplier,true) : (dailyReward*multiplier,false);
        uint subtotal;
        if(special) {
            subtotal = rtransfer + reward > maxSpecialNftReward ? maxSpecialNftReward - rtransfer : reward;
        }
        else {
            subtotal = rtransfer + reward > maxNormalNftReward ? maxNormalNftReward - rtransfer : reward;
        }   
        return subtotal;
    }

    function getTokenindex(address _user, uint _tokenId) public view returns (uint) {
        uint length = record[_user]._rslot.length;
        for(uint i=0;i<length;i++){
            if(record[_user]._rslot[i]._tokenId == _tokenId) {
                return i;
            }
        }
        revert("Not Found!");
    } 

    function getSlotInfo(address _user, uint _index) public view returns (slot memory)  {
        return record[_user]._rslot[_index];
    }

    function getUserStakeIds(address _user) public view returns (uint256[] memory) {
        uint length = record[_user]._rslot.length;
        uint256[] memory ownedTokenIds = new uint256[](length);
        for(uint i=0;i<length;i++){
            ownedTokenIds[i] = record[_user]._rslot[i]._tokenId;
        }
        return ownedTokenIds;
    }

    function checkSpecialNfts() public view returns (uint256[] memory) {
        uint length = tokenAdded.length;
        uint256[] memory IdsCount = new uint256[](length);
        for(uint i=0;i<length;i++){
            IdsCount[i] = tokenAdded[i];
        }
        return IdsCount;
    }

    //true = add and false = remove
    function addorRemoveNft(uint _ids,uint _value,bool _status) external onlyOwner {
        uint index;
        bool found;
        uint length = tokenAdded.length;
        for(uint i = 0; i < length; i++) {
            if(tokenAdded[i] == _ids) {
                index = i;
                found = true;
                break;
            }
        }
        if(!_status && found){
            sTokenReward[_ids] = 0;
            tokenAdded[index] = tokenAdded[length - 1]; 
            tokenAdded.pop();
        }
        else if (!_status && !found){
            revert("Id not Found!");
        }
        else if (_status && !found) {
            sTokenReward[_ids] = _value;
            tokenAdded.push(_ids);
        }
        else if (_status && found) {
            sTokenReward[_ids] = _value;
        }

    }


    function setDailyReward(uint _value) external onlyOwner {
        dailyReward = _value;
    }

    function setRewardDuration(uint _value) external onlyOwner {
        duration = _value;
    }

    function setMaxNormalNftReward(uint _value) external onlyOwner {
        maxNormalNftReward = _value;
    }

    function setMaxSpecialNftReward(uint _value) external onlyOwner {
        maxSpecialNftReward = _value;
    }

    function withdraw_token(IERC20 _adr) external onlyOwner {
        _adr.transfer(msg.sender,_adr.balanceOf(address(_adr)));
    }

    function withdraw_Nft(address _nft,uint _id) external onlyOwner {
        IERC721(_nft).transferFrom(address(this),msg.sender, _id);
    }
    
    function setNft(address _Nft) external onlyOwner {
        NFT = IERC721(_Nft);
    }

    function setToken(address _token) external onlyOwner {
        R_Token = IERC20(_token);
    }

}