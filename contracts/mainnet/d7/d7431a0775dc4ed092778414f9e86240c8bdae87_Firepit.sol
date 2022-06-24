// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./Metamallows.sol";
import "./LOVE.sol";
import "./INewFirepit.sol";

contract Firepit is IERC721Receiver,Ownable{

    struct stakedInfo{
        address owner;
        uint256 tokenId;
        uint256 lastUpdate;
        bool exists;
    }
    
    event tokenStaked(address indexed _owner, uint256 indexed _tokenId, uint256 indexed _lastUpdate);
    event claimedLove(uint256 indexed _tokenId, uint256 _loveEarned, bool indexed _unstake, address indexed _owner);

    uint256 constant public LOVE_RATE = 3 ether;
    uint256 public totalMalloStaked;

    mapping(uint256 => stakedInfo) firepit;

    bool public staking = false;

    Metamallows metamallowContract;
    LOVE loveContract;

    function stakingTokens(uint256[] calldata _tokenIds) external{
        require(staking,"Staking not available yet");
        for (uint i = 0; i < _tokenIds.length; i++) {
            require (!firepit[_tokenIds[i]].exists, 'Already in stake');
            require(msg.sender == metamallowContract.ownerOf(_tokenIds[i]),"Not the owner of this token");
            metamallowContract.transferFrom(msg.sender, address(this),_tokenIds[i]);
            uint256 timestamp = uint80(block.timestamp);
            firepit[_tokenIds[i]] = stakedInfo({
                owner: _msgSender(),
                tokenId: _tokenIds[i],
                lastUpdate: timestamp,
                exists: true
            });
            totalMalloStaked += 1;
            emit tokenStaked(_msgSender(), _tokenIds[i], timestamp);
        } 
    }

    function clamingTokens(uint256[] calldata _tokenIds, bool[] calldata _unstake) external{
        require(_tokenIds.length == _unstake.length,"Params must have same lenght");
        uint256 reward = 0;
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(firepit[_tokenIds[i]].exists,"Not in stake");
            require(firepit[_tokenIds[i]].owner == msg.sender, "Not the user which has staked this token");
            reward += LOVE_RATE * (block.timestamp - firepit[_tokenIds[i]].lastUpdate) / 1 days;
            if(_unstake[i]){
                metamallowContract.safeTransferFrom(address(this), msg.sender, _tokenIds[i], ""); // Send back the NFT
                delete firepit[_tokenIds[i]];
                totalMalloStaked -= 1;
            }
            else{
                firepit[_tokenIds[i]].lastUpdate = uint80(block.timestamp);    
            }
            emit claimedLove(_tokenIds[i], reward, _unstake[i], msg.sender);
        }
        loveContract.mint(msg.sender, reward);
    }
    
    function calculateReward(uint256[] calldata _tokenIds) external view returns (uint256){
        uint256 total =0;
        for (uint i = 0; i < _tokenIds.length; i++) {
            require(firepit[_tokenIds[i]].exists,"Not in stake");
            total += (LOVE_RATE * (block.timestamp - firepit[_tokenIds[i]].lastUpdate) / 1 days);
        }
        return total;
    }

    function viewfirepit (uint256 _tokenId) external view returns (stakedInfo memory){
        return firepit[_tokenId];
    }

    function isOwnerOfStakedTokens(uint256[] calldata _tokenIds, address _owner) external view returns (bool){
        for(uint i =0; i <_tokenIds.length; i++){
            if(firepit[_tokenIds[i]].owner != _owner){
                return false;
            }
        }
        return true;
    }

    function setStaking(bool _state) external onlyOwner {
		staking = _state;
	}

    function emergencyMigration(address _newContract) external onlyOwner{
        INewFirepit contractToMigrate = INewFirepit(_newContract);
        uint total =  totalMalloStaked;
        for (uint i = 0; i < total; i++) {
            metamallowContract.safeTransferFrom(address(this), _newContract, firepit[i].tokenId, ""); // Send back the NFT
            contractToMigrate.migration(firepit[i].owner, firepit[i].tokenId, firepit[i].lastUpdate);
            delete firepit[i];
            totalMalloStaked -= 1;
        }
    }

    function setDependencies(address _loveAddress, address _metamallowsAddress) external onlyOwner{
        loveContract = LOVE(_loveAddress);
        metamallowContract = Metamallows(_metamallowsAddress);
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Must use staking function to send tokens to the Firepit");
      return IERC721Receiver.onERC721Received.selector;
    }
}