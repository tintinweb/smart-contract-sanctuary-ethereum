// contracts/CryptoshackStaking.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ICryptoshackContract {
    function balanceOf(address owner) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IWorldTokenContract {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract CryptoshackStaking {
    // contract owner
    address public owner;
    // reward token contract
    ICryptoshackContract worldTokenContract;
    // staking token contract
    IWorldTokenContract cryptoshackContract;

    // is staking allowed or not
    bool public stakingAllowed;

    bool public emergencyMode;

    uint public undistributed;

    // total reward tokens claimed
    uint public totalClaimed;
    // general info by token type
    uint[3][5] typeToNumbers;
    
    // token Id to staker
    mapping(uint => address) idToStaker;
    // staker to all staked tokens IDs
    mapping(address => uint[]) stakerToIds;
    // token ID to it's index in stakerToIds
    mapping(uint => uint) tokenIdToStakerIndex;
    // token ID to reward tokens claimed
    mapping(uint => uint) tokenToClaimed;

    constructor() { 
        owner=msg.sender; 

        // staked | allocation percent | reward accumulated
        typeToNumbers[0]=[0,50,0];
        typeToNumbers[1]=[0,50,0];
        typeToNumbers[2]=[0,30,0];
        typeToNumbers[3]=[0,20,0];
        typeToNumbers[4]=[0,20,0];
    }

    // stake tokens
    function stake(uint[] calldata tokenIds) external onlyStakingAllowed noContracts {
        uint tokenId;
        uint tokenType;
        for (uint i;i<tokenIds.length;i++) {
            tokenId=tokenIds[i];
            tokenType=tokenId/10000;

            // increase staked tokens of a type amount
            typeToNumbers[tokenType][0]++;
            // set claimed level to the current reward
            tokenToClaimed[tokenId]=typeToNumbers[tokenType][2];
            // set staker
            idToStaker[tokenId]=msg.sender;
            // set idex of token in staker's wallet
            tokenIdToStakerIndex[tokenId]=stakerToIds[msg.sender].length;
            // push the token to staker's wallet
            stakerToIds[msg.sender].push(tokenId);
            // move the CS token to the contract
            cryptoshackContract.transferFrom(msg.sender, address(this), tokenId);
        }
    }

    // claim and unstake if `unstake` is true
    function claim(uint[] calldata tokenIds, bool unstake) external noContracts { 
        uint[] storage tokensArray;
        uint totalClaimable;
        uint tokenType;
        uint tokenId;
        uint lastIndex;
        uint tokenIndex;

        for (uint i;i<tokenIds.length;i++) {
            tokenId=tokenIds[i];
            require(idToStaker[tokenId]==msg.sender, "You're not the staker");
            tokenType=tokenId/10000;

            totalClaimable+=typeToNumbers[tokenType][2]-tokenToClaimed[tokenId];

            tokenToClaimed[tokenId]=typeToNumbers[tokenType][2];

            if (unstake) {
                tokensArray=stakerToIds[msg.sender];
                lastIndex=tokensArray.length-1;
                tokenIndex=tokenIdToStakerIndex[tokenId];

                //nullify the staker address
                idToStaker[tokenId]=address(0);
                //update staked of a type amount
                typeToNumbers[tokenType][0]--;
                //swap token to be removed with the last one
                tokensArray[tokenIndex]=tokensArray[lastIndex];
                //update swapped token index
                tokenIdToStakerIndex[tokensArray[lastIndex]]=tokenIndex;
                //remove last element
                tokensArray.pop();
                //move token back to the staker wallet
                cryptoshackContract.transferFrom(address(this), msg.sender, tokenId);
            }
        }

        if (totalClaimable > 0) {
            totalClaimed+=totalClaimable;
            worldTokenContract.transfer(msg.sender, totalClaimable);
        }
    }

    // get claimable amount of reward tokens
    function getClaimable(uint[] calldata tokenIds) external view returns(uint) { 
        uint totalClaimable;
        for (uint i;i<tokenIds.length;i++) {
            if (idToStaker[tokenIds[i]]!=address(0)) {
                totalClaimable+=typeToNumbers[tokenIds[i]/10000][2]-tokenToClaimed[tokenIds[i]];
            }
        }
        return totalClaimable;
    }

    // get claimable amount for the wallet
    function getClaimableByWallet(address wallet) external view returns(uint) { 
        uint totalClaimable;
        for (uint i;i<stakerToIds[wallet].length;i++) {
            if (idToStaker[stakerToIds[wallet][i]]!=address(0)) {
                totalClaimable+=typeToNumbers[stakerToIds[wallet][i]/10000][2]-tokenToClaimed[stakerToIds[wallet][i]];
            }
        }
        return totalClaimable;
    }

    // get staker wallet of token Id
    function getStaker(uint tokenId) external view returns(address) { 
        return idToStaker[tokenId];
    }
    
    // get total tokens staked
    function stakedTotal() external view returns(uint) {
        uint totalStaked;
        for (uint8 i;i<5;i++) {
            totalStaked+=typeToNumbers[i][0];
        }
        return totalStaked;
    }

    // get all tokens staked by wallet
    function stakedByWallet(address wallet) external view returns(uint[] memory) { 
        return stakerToIds[wallet];
    }

    // returns the count of the staked tokens of a type
    function getStakedOfType(uint tokenType) external view returns(uint) {
        return typeToNumbers[tokenType][0];
    }

    // top up the balance and distribute the reward token
    function topUp(uint amount) external onlyOwner { 
        // distributing amount + remains from the previous topUp
        uint todistribute=amount+undistributed;
        // total amount of gophers + golden gophers staked
        uint gophersStaked=(typeToNumbers[0][0]+typeToNumbers[1][0]);
        // total amount of members + lege staked
        uint membersStaked=(typeToNumbers[3][0]+typeToNumbers[4][0]);
        // total amount that will be distributed
        uint totalShare;

        if (gophersStaked > 0) {
            // share per gopher or golden gopher
            uint gophersShare=(todistribute*typeToNumbers[0][1]/100)/(gophersStaked);
            typeToNumbers[0][2]+=gophersShare;
            typeToNumbers[1][2]+=gophersShare;
            totalShare+=gophersShare*gophersStaked;
        }
        if (membersStaked > 0) {
            // share per member or lege
            uint membersShare=(todistribute*typeToNumbers[4][1]/100)/(membersStaked);
            typeToNumbers[3][2]+=membersShare;
            typeToNumbers[4][2]+=membersShare;
            totalShare+=membersShare*membersStaked;
        }
        if (typeToNumbers[2][0] > 0) {
            // share per caddie
            uint caddiesShare=(todistribute*typeToNumbers[2][1]/100)/(typeToNumbers[2][0]);
            typeToNumbers[2][2]+=caddiesShare;
            totalShare+=caddiesShare*typeToNumbers[2][0];
        }

        // storing the not distributed amount for the next time
        undistributed=todistribute-totalShare;
        
        worldTokenContract.transferFrom(msg.sender, address(this), amount);
    }

    // allow owner to remove token from stake in case of problems with contract
    function ejectStakingTokens(address wallet, uint tokenId) external onlyOwner onlyEmergency { 
        cryptoshackContract.transferFrom(address(this), wallet, tokenId);
    }

    // allow owner to remove WRLD tokens from the contract in case of a problems
    function ejectRewardTokens(address wallet) external onlyOwner onlyEmergency {
        worldTokenContract.transfer(wallet, worldTokenContract.balanceOf(address(this)));
    }

    // set reward token contract
    function setWorldTokenContract(address worldTokenContract_) external onlyOwner { 
        worldTokenContract=ICryptoshackContract(worldTokenContract_);
    }

    // set staking token contract
    function setCryptoshackContract(address cryptoshackContract_) external onlyOwner { 
        cryptoshackContract=IWorldTokenContract(cryptoshackContract_);
    }

    // switch the stakingAllowed flag
    function switchStakingAllowed() external onlyOwner {
        stakingAllowed=!stakingAllowed;
    }

    // switch the stakingAllowed flag
    function switchEmergencyMode() external onlyOwner {
        emergencyMode=!emergencyMode;
    }

    // transfer ownership
    function transferOwnership(address newOwner) external onlyOwner {
        owner=newOwner;
    }

    // execute only if stakingAllowed
    modifier onlyStakingAllowed {
        require(stakingAllowed,"Staking is not allowed!");
        _;
    }

    // execute only if emergency mode activated
    modifier onlyEmergency  {
        require(emergencyMode, "Emergency mode off");
        _;
    }

    // execute only if caller is not a contract
    modifier noContracts {
        require(msg.sender == tx.origin, "No contracts allowed!");
        _;
    }

    // execute only if caller is an owner
    modifier onlyOwner { 
        require(msg.sender == owner);
        _; 
    }
}