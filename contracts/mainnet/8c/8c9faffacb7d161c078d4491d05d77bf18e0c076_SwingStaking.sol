/**
 *Submitted for verification at Etherscan.io on 2022-10-18
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

contract SwingStaking is ERC721TokenReceiver {

    enum StakeType {
        SIMPLE1, SIMPLE2, STAKE2MINT
    }

    struct StakeSettings {
        StakeInfo info;
        Stake[] stakings;
    }

    struct StakeInfo {
        StakeType stakeType;
        bool enabled;
        uint256 timeBetweenRewards;
        uint256 rewardPercentage;
        uint256 minimumStakeTime;
        uint256 minimumDeposit;
        uint256 earlyWithdrawalPenalty;
    }

    struct Stake
    {
        address holder;
        StakeType stakeType;
        uint256 tokenAmount;
        uint256 stakeTime;
        uint256 lastClaimTime;
        uint256 unstakeTime;
    }

    struct StakedTokenInfo
    {
        StakeType stakeType;
        uint256 tokenAmount;
        uint256 stakeTime;
        uint256 owed;
        uint256 lastClaimed;
        uint256 timeUntilNextReward;
        bool hasPenalty;
    }

    struct Map 
    {
        StakeType stakeType;
        uint256 index;
    }

    address public owner;
    uint256 public totalStaked;

    uint256 private accuracy = 9;
    uint256 private nonce;
    mapping (address => Map[]) private ownerStakings;
    mapping (StakeType => StakeSettings) private stakes;
    uint256[] private nftTokenIds;
    
    IERC20 private _token;
    IERC721 private _nftReward;

    modifier onlyOwner() {
        require(msg.sender == owner, "can only be called by the contract owner");
        _;
    }

    modifier whenEnabled(StakeType t) {
        require(stakes[t].info.enabled || msg.sender == owner, "staking not enabled");
        _;
    }

    constructor() {
        owner = msg.sender;

        if (block.chainid == 1) {
            _token = IERC20(0xBeC5938FD565CbEc72107eE39CdE1bc78049537d);
            _nftReward = IERC721(0x67536f6E4412663E2D3Ee7Ffc7b9F79440F8e42A);
        } else if (block.chainid == 3 || block.chainid == 4  || block.chainid == 97 || block.chainid == 5) {
            _token = IERC20(0x2891372D5c2727aC939BF111C45333735d537f09);
            _nftReward = IERC721(0xb48408795A879d7e64A356bB71a2a22adE7a75eF);
        } else {
            revert("Unknown Chain ID");
        }

        stakes[StakeType.SIMPLE1].info.enabled = true;
        stakes[StakeType.SIMPLE1].info.timeBetweenRewards = 24 hours;
        stakes[StakeType.SIMPLE1].info.rewardPercentage = (12 * 10 ** accuracy) / uint256(365);
        stakes[StakeType.SIMPLE1].info.minimumStakeTime = 30 days;
        stakes[StakeType.SIMPLE1].info.minimumDeposit = 0;
        stakes[StakeType.SIMPLE1].info.earlyWithdrawalPenalty = 25;

        stakes[StakeType.SIMPLE2].info.enabled = true;
        stakes[StakeType.SIMPLE2].info.timeBetweenRewards = 24 hours;
        stakes[StakeType.SIMPLE2].info.rewardPercentage = (14 * 10 ** accuracy) / uint256(365);
        stakes[StakeType.SIMPLE2].info.minimumStakeTime = 90 days;
        stakes[StakeType.SIMPLE2].info.minimumDeposit = 0;
        stakes[StakeType.SIMPLE2].info.earlyWithdrawalPenalty = 25;

        stakes[StakeType.STAKE2MINT].info.enabled = true;
        stakes[StakeType.STAKE2MINT].info.timeBetweenRewards = 24 hours;
        stakes[StakeType.STAKE2MINT].info.rewardPercentage = (18 * 10 ** accuracy) / uint256(365);
        stakes[StakeType.STAKE2MINT].info.minimumStakeTime = 180 days;
        stakes[StakeType.STAKE2MINT].info.minimumDeposit = 2_000_000 * 10 ** 18;
        stakes[StakeType.STAKE2MINT].info.earlyWithdrawalPenalty = 25;
    }

    function info() external view returns (
        StakedTokenInfo[] memory stakedTokens,
        address tokenAddress,
        uint256 tokenBalance,
        uint256 tokenApproved,
        uint256 amountStaked,
        StakeInfo memory simple1,
        StakeInfo memory simple2,
        StakeInfo memory stake2mint
    ) {
        uint256 numStaked = ownerStakings[msg.sender].length;
        stakedTokens = new StakedTokenInfo[](numStaked);
        for (uint256 i = 0; i < numStaked; i ++) {

            Map storage m = ownerStakings[msg.sender][i];
            Stake storage s = stakes[m.stakeType].stakings[m.index];

            (uint256 owed,) = rewardsOwed(m.stakeType, s);
            stakedTokens[i] = StakedTokenInfo(
                m.stakeType,
                s.tokenAmount,
                s.stakeTime,
                owed,
                s.lastClaimTime,
                timeUntilReward(m.stakeType, s),
                hasPenalty(s)
             );
        }

        amountStaked = totalStaked;
        tokenAddress = address(_token);
        tokenBalance = _token.balanceOf(msg.sender);
        tokenApproved = _token.allowance(msg.sender, address(this));

        simple1 = stakes[StakeType.SIMPLE1].info;
        simple2 = stakes[StakeType.SIMPLE2].info;
        stake2mint = stakes[StakeType.STAKE2MINT].info;
    }

    function stake(StakeType stakeType, uint256 tokenAmount) external whenEnabled(stakeType) {
        require(tokenAmount >= stakes[stakeType].info.minimumDeposit, "Does not meet minimum requirement");
        require(_token.allowance(msg.sender, address(this)) >= tokenAmount, "Not enough approved");
        _token.transferFrom(msg.sender, address(this), tokenAmount);
        Stake memory s = Stake(msg.sender, stakeType, tokenAmount, block.timestamp, block.timestamp, 0);
        ownerStakings[msg.sender].push(Map(stakeType, stakes[stakeType].stakings.length));
        stakes[stakeType].stakings.push(s);
        totalStaked += tokenAmount;
    }

    function unstake(uint256 ownerIndex) external {

        Map storage m = ownerStakings[msg.sender][ownerIndex];
        Stake storage s = stakes[m.stakeType].stakings[m.index];

        require(s.unstakeTime == 0, "This NFT has already been unstaked");
        require(s.holder == msg.sender || msg.sender == owner, "You do not own this token");

        if (stakes[m.stakeType].info.enabled) {
            if (hasPenalty(stakes[m.stakeType].stakings[m.index])) {  
                (uint256 owed, uint256 time) = rewardsOwed(m.stakeType, stakes[m.stakeType].stakings[m.index]);

                uint256 penalty = (owed * stakes[m.stakeType].info.earlyWithdrawalPenalty) / 100;
                owed = owed - penalty;

                if (owed > 0) {
                    _token.transfer(s.holder, owed);
                    stakes[m.stakeType].stakings[m.index].lastClaimTime = stakes[m.stakeType].stakings[m.index].lastClaimTime + time;
                }
            } else  {
                if (m.stakeType == StakeType.STAKE2MINT && nftTokenIds.length > 0) {
                    uint256 roll = requestRandomWords() % nftTokenIds.length;
                    _nftReward.safeTransferFrom(address(this), s.holder, nftTokenIds[roll]);
                    if (nftTokenIds.length > 1) {
                        nftTokenIds[roll] = nftTokenIds[nftTokenIds.length-1];
                    }
                    nftTokenIds.pop();
                }

                (uint256 owed, uint256 time) = rewardsOwed(m.stakeType, stakes[m.stakeType].stakings[m.index]);
                if (owed > 0) {
                    stakes[m.stakeType].stakings[m.index].lastClaimTime = stakes[m.stakeType].stakings[m.index].lastClaimTime + time;
                    _token.transfer(s.holder, owed);
                }
            }
        }

        _token.transfer(s.holder, s.tokenAmount);
        s.unstakeTime = block.timestamp;
        removeOwnerStaking(s.holder, ownerIndex);
        totalStaked -= s.tokenAmount;
    }
 

    // Admin Methods

    function removeEth() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }
    
    function removeTokens(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));

        if (token == address(_token)) {
            balance = balance - totalStaked;
        }

        IERC20(token).transfer(owner, balance);
    }

    function removeNft(address nftContract, uint256 tokenId) external onlyOwner {
        require (nftContract != address(_nftReward), "You cannot remove the reward nfts");
        _nftReward.safeTransferFrom(address(this), owner, tokenId);
    }

    function forceUnstake(address who) external onlyOwner {
        for (uint256 i = 0; i < ownerStakings[who].length; i++) {
            Map storage m = ownerStakings[who][i];
            Stake storage s = stakes[m.stakeType].stakings[m.index];
            _token.transfer(s.holder, s.tokenAmount);
            totalStaked -= s.tokenAmount;
            s.unstakeTime = block.timestamp;
        }
        delete ownerStakings[who];
    }

    function setOwner(address who) external onlyOwner {
        require(who != address(0), "cannot be zero address");
        owner = who;
    }

    function setEnabled(StakeType stakeType, bool on) external onlyOwner {
        stakes[stakeType].info.enabled = on;
    }

    function setStakeParameters(StakeType stakeType, uint256 _timeBetweenRewards, uint256 _rewardPercentage, uint256 _minimumStakeTime, uint256 _minimumDeposit, uint256 _earlyWithdrawalPenalty) external onlyOwner {
        stakes[stakeType].info.timeBetweenRewards = _timeBetweenRewards;
        stakes[stakeType].info.rewardPercentage = _rewardPercentage;
        stakes[stakeType].info.minimumStakeTime = _minimumStakeTime;
        stakes[stakeType].info.minimumDeposit = _minimumDeposit;
        stakes[stakeType].info.earlyWithdrawalPenalty = _earlyWithdrawalPenalty;
    }

    function setNewRewardNft(address nftContract) external onlyOwner {
        _nftReward = IERC721(nftContract);
        delete nftTokenIds;
    }

    function addNftReward(uint256[] memory tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _nftReward.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            nftTokenIds.push(tokenIds[i]);
        }
    }


    // Private Methods

    function removeOwnerStaking(address holder, uint256 index) private {
        if (ownerStakings[holder].length > 1) {
            ownerStakings[holder][index] = ownerStakings[holder][ownerStakings[holder].length-1];
        }
        ownerStakings[holder].pop();
    }

    function timeUntilReward(StakeType t, Stake storage stakedToken) private view returns (uint256) {

        if (block.timestamp - stakedToken.stakeTime < stakes[t].info.minimumStakeTime) {
            return stakes[t].info.minimumStakeTime - (block.timestamp - stakedToken.stakeTime);
        }

        uint256 lastClaimTime = stakedToken.stakeTime;
        if (stakedToken.lastClaimTime > lastClaimTime) {
            lastClaimTime = stakedToken.lastClaimTime;
        }

        if (block.timestamp - lastClaimTime >= stakes[t].info.timeBetweenRewards) {
            return stakes[t].info.timeBetweenRewards - ((block.timestamp - lastClaimTime) % stakes[t].info.timeBetweenRewards);
        }

        return stakes[t].info.timeBetweenRewards - (block.timestamp - lastClaimTime);
    }

    function rewardsOwed(StakeType t, Stake storage stakedToken) private view returns (uint256, uint256) {

        uint256 lastClaimTime = stakedToken.stakeTime;
        if (stakedToken.lastClaimTime > lastClaimTime) {
            lastClaimTime = stakedToken.lastClaimTime;
        }

        if (block.timestamp - lastClaimTime >= stakes[t].info.timeBetweenRewards) {
            uint256 multiplesOwed = (block.timestamp - lastClaimTime) / stakes[t].info.timeBetweenRewards;
            return (
                (stakedToken.tokenAmount * multiplesOwed * stakes[t].info.rewardPercentage) / (100 * 10 ** accuracy),
                multiplesOwed * stakes[t].info.timeBetweenRewards
            );
        }
        
        return (0, 0);
    }

    function hasPenalty(Stake storage stakedToken) private view returns (bool) {
        return block.timestamp < stakedToken.stakeTime + stakes[stakedToken.stakeType].info.minimumStakeTime;
    }

    function requestRandomWords() private returns (uint256) {
        nonce += 1;
        return uint(keccak256(abi.encodePacked(nonce, msg.sender, blockhash(block.number - 1))));
    }

    function onERC721Received(address, address, uint256, bytes memory) public pure override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

}