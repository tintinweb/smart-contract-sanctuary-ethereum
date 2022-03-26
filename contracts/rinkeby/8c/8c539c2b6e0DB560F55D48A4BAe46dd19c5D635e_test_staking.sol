// contracts/test_staking.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ITestStakerRewardToken {
    function balanceOf(address owner) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface ITestStakerToken {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract test_staking {
    // contract owner
    address public owner;
    // reward token contract
    ITestStakerRewardToken testStakerRewardContract;
    // staking token contract
    ITestStakerToken testStakerTokenContract;

    // is staking allowed or not
    bool public stakingAllowed;

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
        for (uint i;i<tokenIds.length;i++) {
            tokenId=tokenIds[i];
            typeToNumbers[tokenId/10000][0]++;
            tokenToClaimed[tokenId]=typeToNumbers[tokenId/10000][2];
            idToStaker[tokenId]=msg.sender;
            tokenIdToStakerIndex[tokenId]=stakerToIds[msg.sender].length;
            stakerToIds[msg.sender].push(tokenId);
            testStakerTokenContract.transferFrom(msg.sender, address(this), tokenId);
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
                testStakerTokenContract.transferFrom(address(this), msg.sender, tokenId);
            }
        }

        if (totalClaimable > 0) {
            totalClaimed+=totalClaimable;
            testStakerRewardContract.transfer(msg.sender, totalClaimable);
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
    
    // get all tokens staked by wallet
    function stakedByWallet(address wallet) external view returns(uint[] memory) { 
        return stakerToIds[wallet];
    }

    // top up the balance and distribute the reward token
    // TODO: SHOULD BE OWNER ONLY
    function topUp(uint amount) external { 
        uint typeOneStaked=(typeToNumbers[0][0]+typeToNumbers[1][0]);
        uint typeTwoStaked=(typeToNumbers[3][0]+typeToNumbers[4][0]);

        if (typeOneStaked > 0) {
            uint oneShare=(amount*typeToNumbers[0][1]/100)/(typeOneStaked);
            typeToNumbers[0][2]+=oneShare;
            typeToNumbers[1][2]+=oneShare;
        }
        if (typeTwoStaked > 0) {
            uint twoShare=(amount*typeToNumbers[4][1]/100)/(typeTwoStaked);
            typeToNumbers[3][2]+=twoShare;
            typeToNumbers[4][2]+=twoShare;
        }
        if (typeToNumbers[2][0] > 0) {
            uint threeShare=(amount*typeToNumbers[2][1]/100)/(typeToNumbers[2][0]);
            typeToNumbers[2][2]+=threeShare;
        }
        
        testStakerRewardContract.transferFrom(msg.sender, address(this), amount);
    }

    // allow owner to remove token from stake in case of problems
    // @note remove?
    function ejectStakingTokens(address wallet, uint tokenId) external onlyOwner() { 
        testStakerTokenContract.transferFrom(address(this), wallet, tokenId);
    }

    function ejectRewardTokens(address wallet) external onlyOwner {
        testStakerRewardContract.transfer(wallet, testStakerRewardContract.balanceOf(address(this)));
    }

    // set reward token contract
    function settestStakerRewardContract(address testStakerRewardContract_) external onlyOwner { 
        testStakerRewardContract=ITestStakerRewardToken(testStakerRewardContract_);
    }

    // set staking token contract
    function settestStakerTokenContract(address testStakerTokenContract_) external onlyOwner { 
        testStakerTokenContract=ITestStakerToken(testStakerTokenContract_);
    }

    // switch the stakingAllowed flag
    function switchStakingAllowed() external onlyOwner {
        stakingAllowed=!stakingAllowed;
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