// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FxBaseRootTunnel.sol";
import "./Ownable.sol";
import "./ERC721A.sol";


contract MyStakingContract is FxBaseRootTunnel, Ownable {

    struct Stake {
        uint256[] tokenIds;
        uint256[] timestamps;
    }


    //Store user staking information
    mapping(address => Stake) userInfo;

    uint256 public totalStaked;

    //Store parent contract for staking
    ERC721A public parentContract;

    bool public contractState = true; //To be set to false when go live

    constructor(address _checkPointManager, address _fxRoot, address _contractAddress) FxBaseRootTunnel(_checkPointManager, _fxRoot){
        parentContract = ERC721A(_contractAddress);
    }

    function _processMessageFromChild(bytes memory message) internal override {
        //Required to be included 
        //Nothing is performed here
    }

    function getUserStakedTokens(address _address) public view returns(uint256[] memory){
        return userInfo[_address].tokenIds;
    }

    function getUserStakedTime(address _address) public view returns(uint256[] memory) {
        return userInfo[_address].timestamps;
    }


    //Staking only one at a time
    function stake(uint256 _tokenId) public {
        require(contractState, "Staking is currently paused");
        uint256 currentTime = block.timestamp;
        parentContract.transferFrom(msg.sender, address(this), _tokenId);
        totalStaked += 1;
        userInfo[msg.sender].tokenIds.push(_tokenId);
        userInfo[msg.sender].timestamps.push(currentTime);

        //Send the information to the MATIC network (user wallet address, time stamps, action)
        _sendMessageToChild(abi.encode(msg.sender, userInfo[msg.sender].tokenIds, currentTime, true));
    }


    //Staking multiple at a time
    function stakeMultiple(uint256[] memory _tokenIds) public {
        require(contractState, "Staking is currently paused");
        uint256 currentTime = block.timestamp;

        //Perform staking for each token ids
        for (uint256 counter = 0; counter < _tokenIds.length; counter++){
            parentContract.transferFrom(msg.sender, address(this), _tokenIds[counter]);
            totalStaked += 1;
            userInfo[msg.sender].tokenIds.push(_tokenIds[counter]);
            userInfo[msg.sender].timestamps.push(currentTime);
        }

        //Send the information to the MATIC network (user wallet address, time stamps, action)
        _sendMessageToChild(abi.encode(msg.sender, userInfo[msg.sender].tokenIds, currentTime, true));
    }


    //Unstaking one at a time
    function unstake(uint256 _tokenId) public {
        require(userInfo[msg.sender].tokenIds.length > 0, "User has not staked anything");
        require(totalStaked > 0, "No tokens have been staked");
        uint256 currentTime = block.timestamp;
        //Search the specified token id and unstake
        for (uint256 counter = 0; counter < userInfo[msg.sender].tokenIds.length; counter ++) {
            if(userInfo[msg.sender].tokenIds[counter] == _tokenId) {
                parentContract.transferFrom(address(this), msg.sender, _tokenId);
                delete userInfo[msg.sender].tokenIds[counter];
                delete userInfo[msg.sender].timestamps[counter];
                totalStaked -=1;
                break;
            }
        }
        
        //Send the information to the MATIC network (user wallet address, time stamps, action)
        _sendMessageToChild(abi.encode(msg.sender, userInfo[msg.sender].tokenIds, currentTime, false));

    }

    //Unstake multiple at a time
    function unstakeMultiple(uint256[] memory _tokenIds) public {
        require(userInfo[msg.sender].tokenIds.length > 0, "User has not staked anything");
        require(_tokenIds.length <= userInfo[msg.sender].tokenIds.length, "Exceeded number of token staked");
        uint256 currentTime = block.timestamp;
        //Search for all the specified token ids and unstake them
        for(uint256 index = 0; index < _tokenIds.length; index ++) {

            for(uint256 counter = 0; counter < userInfo[msg.sender].tokenIds.length; counter ++) {
                if(userInfo[msg.sender].tokenIds[counter] == _tokenIds[index]) {
                    parentContract.transferFrom(address(this), msg.sender, _tokenIds[index]);
                    delete userInfo[msg.sender].tokenIds[counter];
                    delete userInfo[msg.sender].timestamps[counter];
                    totalStaked -=1;
                    break;
                }
            }
        }




        //Send the information to the MATIC network (user wallet address, time stamps, action)
        _sendMessageToChild(abi.encode(msg.sender, userInfo[msg.sender].tokenIds, currentTime, false));
    }

    //Unstake everything
    function unstakeAll() public {
        require(userInfo[msg.sender].tokenIds.length > 0, "User has not staked anything");
        uint256 userTotalStaked = userInfo[msg.sender].tokenIds.length;
        uint256 currentTime = block.timestamp;

        for(uint256 counter = 0; counter < userTotalStaked; counter ++) {
            parentContract.transferFrom(address(this), msg.sender, userInfo[msg.sender].tokenIds[counter]);
        }

        totalStaked -= userTotalStaked;

        //Send the information to the MATIC network (user wallet address, time stamps, action)
        _sendMessageToChild(abi.encode(msg.sender, userInfo[msg.sender].tokenIds, currentTime, false));
    }



}