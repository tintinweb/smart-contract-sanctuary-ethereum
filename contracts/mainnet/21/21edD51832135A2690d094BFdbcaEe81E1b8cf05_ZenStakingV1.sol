// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

/**
 * @title Zen Apes Staking contract
 * @author The Core Devs (@thecoredevs)
 */

interface IZenApes {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256 balance);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function multiTransferFrom(address from_, address to_, uint256[] memory tokenIds_) external;
}

interface IZenToken {
    function mintAsController(address to_, uint256 amount_) external;
}

contract ZenStakingV1 {
    
    uint private yieldPerDay;
    uint40 private _requiredStakeTime;
    address public owner;

    struct StakedToken {
        uint40 stakingTimestamp;
        uint40 lastClaimTimestamp;
        address tokenOwner;
    }

    // seconds in 24 hours: 86400

    mapping(uint16 => StakedToken) private stakedTokens;
    mapping(address => uint) public stakedTokensAmount;
    
    IZenApes zenApesContract;
    IZenToken zenTokenContract;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller Not Owner!");
        _;
    }

    constructor (
        uint yieldAmountPerDay,
        uint40 requiredStakeTimeInSeconds, 
        address zenApesContractAddr,
        address zenTokenContractAddr
        ) {
        _setZenApesContractAddr(zenApesContractAddr);
        _setZenTokenContractAddr(zenTokenContractAddr);
        yieldPerDay = yieldAmountPerDay;
        _requiredStakeTime = requiredStakeTimeInSeconds;
        owner = msg.sender;
    }

    function setYieldPerDay(uint amount) external onlyOwner {
        yieldPerDay = amount;
    }
    
    function setRequiredStakeTime(uint40 timeInSeconds) external onlyOwner {
        _requiredStakeTime = timeInSeconds;
    }

    function setZenApesContractAddr(address contractAddress) external onlyOwner {
        _setZenApesContractAddr(contractAddress);
    }

    function _setZenApesContractAddr(address _contractAddress) private {
        _requireContract(_contractAddress);
        zenApesContract = IZenApes(_contractAddress);
    }

    function setZenTokenContractAddr(address contractAddress) external onlyOwner {
        _setZenTokenContractAddr(contractAddress);
    }

    function _setZenTokenContractAddr(address _contractAddress) private {
        _requireContract(_contractAddress);
        zenTokenContract = IZenToken(_contractAddress);
    }

    function _requireContract(address contractAddr) private view {
        uint256 size;
        assembly {
            size := extcodesize(contractAddr)
        }
        require(size > 0, "Not A Contract!");
    }

    function claim(uint tokenId) external {
        StakedToken memory tokenInfo = stakedTokens[uint16(tokenId)];
        require(tokenInfo.tokenOwner == msg.sender, "Caller is not token owner!");

        uint claimAmount = _getClaimableAmount(tokenInfo);

        require(claimAmount > 0, "No claimable Tokens!");

        stakedTokens[uint16(tokenId)].lastClaimTimestamp = uint40(block.timestamp);
        zenTokenContract.mintAsController(msg.sender, claimAmount);
    }

    function batchClaim(uint[] memory tokenIds) external {
        uint length = tokenIds.length;
        uint claimAmount;
        uint cId;
        StakedToken memory tokenInfo;

        for (uint i; i < length;) {
            assembly {
                cId := mload(add(add(tokenIds, 0x20), mul(i, 0x20)))
            }

            tokenInfo = stakedTokens[uint16(cId)];
            require(tokenInfo.tokenOwner == msg.sender, "Caller is not token owner!");

            claimAmount += _getClaimableAmount(tokenInfo);
            stakedTokens[uint16(cId)].lastClaimTimestamp = uint40(block.timestamp);
            
            unchecked { ++i; }
        }

        zenTokenContract.mintAsController(msg.sender, claimAmount);
    }

    function _getClaimableAmount(StakedToken memory tokenInfo) private view returns(uint claimAmount) {

        if (tokenInfo.lastClaimTimestamp == 0) {
            uint timeStaked;
            unchecked { timeStaked = block.timestamp - tokenInfo.stakingTimestamp; }
            uint requiredStakeTime = _requiredStakeTime;

            require(timeStaked >= requiredStakeTime, "Required stake time not met!");
            claimAmount = ((timeStaked - requiredStakeTime) / 86400) * yieldPerDay ;
        } else {
            uint secondsSinceLastClaim;
            unchecked { secondsSinceLastClaim = block.timestamp - tokenInfo.lastClaimTimestamp; }
            require(secondsSinceLastClaim > 86399, "Cannot cliam zero tokens!");

            claimAmount = (secondsSinceLastClaim / 86400) * yieldPerDay ;
        }
    }


    function stake(uint tokenId) external {
        require(zenApesContract.ownerOf(tokenId) == msg.sender);
        stakedTokens[uint16(tokenId)].stakingTimestamp = uint40(block.timestamp);
        stakedTokens[uint16(tokenId)].tokenOwner = msg.sender;
        unchecked { ++stakedTokensAmount[msg.sender]; }
        zenApesContract.transferFrom(msg.sender, address(this), tokenId);
    }

    function stakeBatch(uint[] memory tokenIds) external {
        uint amount = tokenIds.length;
        uint cId;
        for(uint i; i < amount;) {

            assembly {
                cId := mload(add(add(tokenIds, 0x20), mul(i, 0x20)))
            }

            require(zenApesContract.ownerOf(cId) == msg.sender);
            stakedTokens[uint16(cId)].stakingTimestamp = uint40(block.timestamp);
            stakedTokens[uint16(cId)].tokenOwner = msg.sender;

            unchecked {
                ++stakedTokensAmount[msg.sender];
                ++i;
            }
        }
        zenApesContract.multiTransferFrom(msg.sender, address(this), tokenIds);
    }

    function unstake(uint tokenId) external {
        require(stakedTokens[uint16(tokenId)].tokenOwner == msg.sender);
        delete stakedTokens[uint16(tokenId)];
        unchecked { --stakedTokensAmount[msg.sender]; }
        zenApesContract.transferFrom(address(this), msg.sender, tokenId);
    }

    function unstakeBatch(uint[] memory tokenIds) external {
        uint amount = tokenIds.length;
        uint cId;
        for(uint i; i < amount;) {

            assembly {
                cId := mload(add(add(tokenIds, 0x20), mul(i, 0x20)))
            }

            require(stakedTokens[uint16(cId)].tokenOwner == msg.sender);
            delete stakedTokens[uint16(cId)];

            unchecked {
                ++i;
                --stakedTokensAmount[msg.sender]; 
            }
        }
        
        zenApesContract.multiTransferFrom(address(this), msg.sender, tokenIds);
    }

    function ownerUnstakeBatch(uint[] memory tokenIds) external onlyOwner {
        uint amount = tokenIds.length;
        uint cId;
        for(uint i; i < amount;) {

            assembly {
                cId := mload(add(add(tokenIds, 0x20), mul(i, 0x20)))
            }

            zenApesContract.transferFrom(address(this), stakedTokens[uint16(cId)].tokenOwner, cId);
            delete stakedTokens[uint16(cId)];

            unchecked {
                ++i;
                --stakedTokensAmount[msg.sender]; 
            }
        }
    }


    function getTokenInfo(uint16 id) external view returns(uint40 stakingTimestamp, uint40 lastClaimTimestamp, address tokenOwner) {
        return (stakedTokens[id].stakingTimestamp, stakedTokens[id].lastClaimTimestamp, stakedTokens[id].tokenOwner);
    }

    function getUserTokenInfo(address user) external view returns(uint[] memory stakingTimestamp, uint[] memory lastClaimTimestamp, uint[] memory tokenIds) {
        uint x;
        uint stakedAmount = stakedTokensAmount[user];
        StakedToken memory st;

        stakingTimestamp = new uint[](stakedAmount);
        lastClaimTimestamp = new uint[](stakedAmount);
        tokenIds = new uint[](stakedAmount);

        for(uint i = 1; i < 5001;) {
            st = stakedTokens[uint16(i)];
            if(st.tokenOwner == user) {
                stakingTimestamp[x] = st.stakingTimestamp;
                lastClaimTimestamp[x] = st.lastClaimTimestamp;
                tokenIds[x] = i;
                unchecked { ++x; }
            }
            unchecked { ++i; }
        }
    }

    function getStakingSettings() external view returns (uint, uint40) {
        return (yieldPerDay, _requiredStakeTime);
    }

    function getContractAddresses() external view returns(address zenApes, address zenToken) {
        return(address(zenApesContract), address(zenTokenContract));
    }

}