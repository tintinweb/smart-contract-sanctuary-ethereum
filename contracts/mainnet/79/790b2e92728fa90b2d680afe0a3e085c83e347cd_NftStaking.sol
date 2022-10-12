/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address _owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

contract NftStaking is ERC721TokenReceiver {

    enum StakeType {
        LOTTERY, APY
    }

    struct StakeSettings {
        bool enabled;
        uint256 timeBetweenRewards;
        uint256 rewardPerToken;
        uint256 minimumStakeTime;
        uint256 startTime;
        Stake[] stakings;
    }

    struct StakeInfo {
        StakeType stakeType;
        bool enabled;
        uint256 timeBetweenRewards;
        uint256 rewardPerToken;
        uint256 minimumStakeTime;
    }

    struct Stake
    {
        address holder;
        StakeType stakeType;
        uint256 tokenId;
        uint256 stakeTime;
        uint256 lastClaimTime;
        uint256 unstakeTime;
    }

    struct StakedNftInfo
    {
        StakeType stakeType;
        uint256 tokenId;
        string uri;
        uint256 stakeTime;
        uint256 owed;
        uint256 lastClaimed;
        uint256 timeUntilNextReward;
    }

    struct Map 
    {
        StakeType stakeType;
        uint256 index;
    }

    struct Lottery
    {
        bool running;
        address token;
        uint256 prize;
        uint256 totalTickets;
        address winner;
    }

    address public owner;

    Lottery public currentLottery;
    Lottery[] public lotteryWinners;

    uint256 private nonce;
    mapping (address => uint256[]) private ownerStakings;
    mapping (uint256 => Map) private indexMap;
    mapping (StakeType => StakeSettings) private stakes;
    uint256[] private lotteryMap;

    IERC721Metadata private _nftContract;
    IERC20 private _rewardToken;

    modifier onlyOwner() {
        require(msg.sender == owner, "can only be called by the contract owner");
        _;
    }

    modifier whenEnabled(StakeType t) {
        require(stakes[t].enabled || msg.sender == owner, "staking not enabled");
        _;
    }

    constructor() {
        owner = msg.sender;

        if (block.chainid == 1) {
            _nftContract = IERC721Metadata(0x5b9D7Ee3Ba252c41a07C2D6Ec799eFF8858bf117);
            _rewardToken = IERC20(0xBeC5938FD565CbEc72107eE39CdE1bc78049537d);
        } else if (block.chainid == 3 || block.chainid == 4  || block.chainid == 97 || block.chainid == 5) {
            _nftContract = IERC721Metadata(0xb48408795A879d7e64A356bB71a2a22adE7a75eF);
            _rewardToken = IERC20(0x2891372D5c2727aC939BF111C45333735d537f09);
        } else {
            revert("Unknown Chain ID");
        }

        stakes[StakeType.APY].enabled = true;
        stakes[StakeType.APY].timeBetweenRewards = 60 * 60 * 24;
        stakes[StakeType.APY].startTime = block.timestamp;
        stakes[StakeType.APY].rewardPerToken = 1 * 10 ** 18;
        stakes[StakeType.APY].minimumStakeTime = 60 * 60 * 24 * 7;

        stakes[StakeType.LOTTERY].enabled = true;
        stakes[StakeType.LOTTERY].timeBetweenRewards = 60 * 60 * 24;
        stakes[StakeType.LOTTERY].startTime = block.timestamp;
        stakes[StakeType.LOTTERY].rewardPerToken = 1;
        stakes[StakeType.LOTTERY].minimumStakeTime = 60 * 60 * 24;
    }

    function info() external view returns (
        StakedNftInfo[] memory stakedNfts,
        Lottery memory lottery,
        address rewardToken,
        address nftContract,
        StakeInfo memory apyStake,
        StakeInfo memory lotteryStake
    ) {
        uint256 totalStaked = ownerStakings[msg.sender].length;
        stakedNfts = new StakedNftInfo[](totalStaked);
        for (uint256 i = 0; i < totalStaked; i ++) {

            Map storage m = indexMap[ownerStakings[msg.sender][i]];
            Stake storage s = stakes[m.stakeType].stakings[m.index];

            (uint256 owed,) = rewardsOwed(m.stakeType, s);
            stakedNfts[i] = StakedNftInfo(
                m.stakeType,
                s.tokenId,
                _nftContract.tokenURI(s.tokenId),
                s.stakeTime,
                owed,
                s.lastClaimTime,
                timeUntilReward(m.stakeType, s)
             );
        }

        lottery = currentLottery;

        rewardToken = address(_rewardToken);
        nftContract = address(_nftContract);

        apyStake = StakeInfo(
            StakeType.APY, 
            stakes[StakeType.APY].enabled, 
            stakes[StakeType.APY].timeBetweenRewards, 
            stakes[StakeType.APY].rewardPerToken, 
            stakes[StakeType.APY].minimumStakeTime
        );

        lotteryStake = StakeInfo(
            StakeType.LOTTERY, 
            stakes[StakeType.LOTTERY].enabled, 
            stakes[StakeType.LOTTERY].timeBetweenRewards, 
            stakes[StakeType.LOTTERY].rewardPerToken, 
            stakes[StakeType.LOTTERY].minimumStakeTime
        );
    }

    function stake(StakeType stakeType, uint256 tokenId) external whenEnabled(stakeType) {
        require(_nftContract.getApproved(tokenId) == address(this), "Must approve this contract as an operator");
        _nftContract.safeTransferFrom(msg.sender, address(this), tokenId);
        Stake memory s = Stake(msg.sender, stakeType, tokenId, block.timestamp, block.timestamp, 0);
        indexMap[tokenId] = Map(stakeType, stakes[stakeType].stakings.length);
        if (stakeType == StakeType.LOTTERY) {
            lotteryMap.push(stakes[stakeType].stakings.length);
        }
        stakes[stakeType].stakings.push(s);
        ownerStakings[msg.sender].push(tokenId);
    }

    function unstake(uint256 tokenId) external {

        Map storage m = indexMap[tokenId];
        Stake storage s = stakes[m.stakeType].stakings[m.index];

        require(s.unstakeTime == 0, "This NFT has already been unstaked");
        require(s.holder == msg.sender || msg.sender == owner, "You do not own this token");

        if (m.stakeType == StakeType.APY && stakes[m.stakeType].enabled) {
            claimWalletRewards(s.holder);
        }

        _nftContract.safeTransferFrom(address(this), s.holder, tokenId);
        s.unstakeTime = block.timestamp;
        removeOwnerStaking(s.holder, tokenId);
    }
 
    function claimRewards() external whenEnabled(StakeType.APY) {
        claimWalletRewards(msg.sender);
    }

    function pastLotteries() external view returns (uint256) {
        return lotteryWinners.length;
    }


    // Admin Methods

    function removeEth() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }
    
    function removeTokens(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner, balance);
    }

    function createLottery(address newToken, uint256 newPrize) external onlyOwner {   
        require(currentLottery.running == false, "Already an active lottery");
        currentLottery = Lottery(true, newToken, newPrize, 0, address(0));
        stakes[StakeType.LOTTERY].startTime = block.timestamp;
    }

    function drawLottery() external onlyOwner {   
        IERC20 token = IERC20(currentLottery.token);

        uint256 totalTickets;
        uint256[] memory currentLotteryMap = lotteryMap;
        delete lotteryMap;

        for (uint256 i = 0; i < currentLotteryMap.length; i++) {
            (uint256 owed,) = rewardsOwed(StakeType.LOTTERY, stakes[StakeType.LOTTERY].stakings[currentLotteryMap[i]]);
            totalTickets += owed;
            if (stakes[StakeType.LOTTERY].stakings[currentLotteryMap[i]].unstakeTime > 0) {
                lotteryMap.push(currentLotteryMap[i]);
            }
        }

        if (totalTickets > 0) {
            require(token.balanceOf(address(this)) >= currentLottery.prize, "Not enough tokens to pay winner");

            uint256 roll = requestRandomWords() % totalTickets;
            uint256 current;
            
            for (uint256 i = 0; i < currentLotteryMap.length; i++) {
                (uint256 owed,) = rewardsOwed(StakeType.LOTTERY, stakes[StakeType.LOTTERY].stakings[currentLotteryMap[i]]);
                current += owed;

                if (owed > 0 && current >= roll) {
                    currentLottery.winner = stakes[StakeType.LOTTERY].stakings[currentLotteryMap[i]].holder;
                    currentLottery.totalTickets = totalTickets;
                }
            }

            require(currentLottery.winner != address(0), "Unable to find winner"); 
            token.transfer(currentLottery.winner, currentLottery.prize);
        }

        lotteryWinners.push(currentLottery);
        currentLottery = Lottery(false, address(0), 0, 0, address(0));
    }

    function forceUnstake(uint256 tokenId) external onlyOwner {
        Map storage m = indexMap[tokenId];
        Stake storage s = stakes[m.stakeType].stakings[m.index];
        _nftContract.safeTransferFrom(address(this), s.holder, tokenId);
    }

    function setOwner(address who) external onlyOwner {
        require(who != address(0), "cannot be zero address");
        owner = who;
    }

    function setEnabled(StakeType stakeType, bool on) external onlyOwner {
        stakes[stakeType].enabled = on;
    }

    function configureStake(StakeType stakeType, uint256 _timeBetweenRewards, uint256 _rewardPerToken, uint256 _minimumStakeTime) external onlyOwner {
        stakes[stakeType].timeBetweenRewards = _timeBetweenRewards;
        stakes[stakeType].rewardPerToken = _rewardPerToken;
        stakes[stakeType].minimumStakeTime = _minimumStakeTime;
    }


    // Private Methods

    function removeOwnerStaking(address holder, uint256 tokenId) private {
        bool found;
        uint256 index = 0;
        for (index; index < ownerStakings[holder].length; index++) {
            if (ownerStakings[holder][index] == tokenId) {
                found = true;
                break;
            } 
        }

        if (found) {
            if (ownerStakings[holder].length > 1) {
                ownerStakings[holder][index] = ownerStakings[holder][ownerStakings[holder].length-1];
            }
            ownerStakings[holder].pop();
        }
    }

    function claimWalletRewards(address wallet) private {
        uint256 totalOwed;
        
        for (uint256 i = 0; i < ownerStakings[wallet].length; i ++) {
            
            Map storage m = indexMap[ownerStakings[wallet][i]];
            if (m.stakeType == StakeType.APY) {
                (uint256 owed, uint256 time) = rewardsOwed(m.stakeType, stakes[m.stakeType].stakings[m.index]);
                if (owed > 0) {
                    totalOwed += owed;
                    stakes[m.stakeType].stakings[m.index].lastClaimTime = stakes[m.stakeType].stakings[m.index].lastClaimTime + time;
                }
            }
        }

        if (totalOwed > 0) {
            _rewardToken.transfer(wallet, totalOwed);
        }
    }

    function timeUntilReward(StakeType t, Stake storage stakedToken) private view returns (uint256) {

        if (block.timestamp - stakedToken.stakeTime < stakes[t].minimumStakeTime) {
            return stakes[t].minimumStakeTime - (block.timestamp - stakedToken.stakeTime);
        }

        uint256 lastClaimTime = stakedToken.stakeTime;
        if (stakes[t].startTime > lastClaimTime) {
            lastClaimTime = stakes[t].startTime;
        } else if (stakedToken.lastClaimTime > lastClaimTime) {
            lastClaimTime = stakedToken.lastClaimTime;
        }

        if (block.timestamp - lastClaimTime >= stakes[t].timeBetweenRewards) {
            return stakes[t].timeBetweenRewards - ((block.timestamp - lastClaimTime) % stakes[t].timeBetweenRewards);
        }

        return stakes[t].timeBetweenRewards - (block.timestamp - lastClaimTime);
    }

    function rewardsOwed(StakeType t, Stake storage stakedToken) private view returns (uint256, uint256) {

        if (t == StakeType.LOTTERY && currentLottery.running == false) {
            return (0, 0);
        }

        uint256 unstakeTime = block.timestamp;
        if (stakedToken.unstakeTime > 0) {
            unstakeTime = stakedToken.unstakeTime;
        }

        if (unstakeTime - stakedToken.stakeTime >= stakes[t].minimumStakeTime) {
            uint256 lastClaimTime = stakedToken.stakeTime;
            if (stakes[t].startTime > lastClaimTime) {
                lastClaimTime = stakes[t].startTime;
            } else if (stakedToken.lastClaimTime > lastClaimTime) {
                lastClaimTime = stakedToken.lastClaimTime;
            }

            if (unstakeTime - lastClaimTime >= stakes[t].timeBetweenRewards) {
                uint256 multiplesOwed = (unstakeTime - lastClaimTime) / stakes[t].timeBetweenRewards;
                return (
                    multiplesOwed * stakes[t].rewardPerToken,
                    multiplesOwed * stakes[t].timeBetweenRewards
                );
            }
        }

        return (0, 0);
    }

    function requestRandomWords() private returns (uint256) {
        nonce += 1;
        return uint(keccak256(abi.encodePacked(nonce, msg.sender, blockhash(block.number - 1))));
    }

    function onERC721Received(address, address, uint256, bytes memory) public pure override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

}