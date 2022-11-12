/**
 *Submitted for verification at Etherscan.io on 2022-11-11
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

interface VRFCoordinatorV2Interface {
    function getRequestConfig() external view returns (uint16, uint32, bytes32[] memory);
    function requestRandomWords(bytes32 keyHash, uint64 subId, uint16 minimumRequestConfirmations, uint32 callbackGasLimit, uint32 numWords) external returns (uint256 requestId);
    function createSubscription() external returns (uint64 subId);
    function getSubscription(uint64 subId) external view returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers);
    function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;
    function acceptSubscriptionOwnerTransfer(uint64 subId) external;
    function addConsumer(uint64 subId, address consumer) external;
    function removeConsumer(uint64 subId, address consumer) external;
    function cancelSubscription(uint64 subId, address to) external;
}

abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address internal vrfCoordinator;

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

contract NftLotteryStaking is ERC721TokenReceiver, VRFConsumerBaseV2 {

    bool public enabled;
    uint256 public timeBetweenRewards;
    uint256 public rewardPerToken;
    uint256 public minimumStakeTime;
    uint256 public startTime;
    Stake[] public stakings;

    struct Stake
    {
        address holder;
        uint256 tokenId;
        uint256 stakeTime;
    }

    struct StakedNftInfo
    {
        uint256 tokenId;
        string uri;
        uint256 stakeTime;
        uint256 owed;
        uint256 timeUntilNextReward;
    }

    struct Lottery
    {
        bool running;
        address token;
        uint256 prize;
        uint256 requestId;
        uint256 random;
        uint256 totalTickets;
        address winner;
    }

    address public owner;

    Lottery public currentLottery;
    Lottery[] public lotteryWinners;

    mapping (address => uint256[]) public ownerStakings;
    mapping (uint256 => uint256) public indexMap;

    IERC721Metadata private _nftContract;

    // Chainlink
    VRFCoordinatorV2Interface private COORDINATOR;
    uint64 private subscriptionId;
    bytes32 private keyHash;
    uint32 private callbackGasLimit;
    uint16 private requestConfirmations;
    uint32 private numberOfWords;

    modifier onlyOwner() {
        require(msg.sender == owner, "can only be called by the contract owner");
        _;
    }

    modifier whenEnabled() {
        require(enabled || msg.sender == owner, "staking not enabled");
        _;
    }

    constructor() {
        owner = msg.sender;

        if (block.chainid == 1) {
            _nftContract = IERC721Metadata(0x67536f6E4412663E2D3Ee7Ffc7b9F79440F8e42A);
            subscriptionId = 514;
            setChainlink(
                0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92,
                250_000,
                3,
                1
            );
            vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
        } else if (block.chainid == 5) {
            _nftContract = IERC721Metadata(0xb48408795A879d7e64A356bB71a2a22adE7a75eF);
            subscriptionId = 6341;
            setChainlink(
                0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15,
                250_000,
                3,
                1
            );
            vrfCoordinator = 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D;
        } else {
            revert("Unknown Chain ID");
        }

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);

        enabled = true;
        timeBetweenRewards = 1 days;
        startTime = block.timestamp;
        rewardPerToken = 1;
        minimumStakeTime = 1 days;
    }

    function info() external view returns (
        StakedNftInfo[] memory stakedNfts,
        Lottery memory lottery,
        address nftContract,
        bool _enabled,
        uint256 _timeBetweenRewards,
        uint256 _rewardPerToken,
        uint256 _minimumStakeTime
    ) {
        uint256 totalStaked = ownerStakings[msg.sender].length;
        stakedNfts = new StakedNftInfo[](totalStaked);
        for (uint256 i = 0; i < totalStaked; i ++) {
            Stake storage s = stakings[indexMap[ownerStakings[msg.sender][i]]];
            if (s.tokenId == ownerStakings[msg.sender][i]) {
                (uint256 owed,) = rewardsOwed(s);
                stakedNfts[i] = StakedNftInfo(
                    s.tokenId,
                    _nftContract.tokenURI(s.tokenId),
                    s.stakeTime,
                    owed,
                    timeUntilReward(s)
                );
            }
        }

        lottery = currentLottery;

        nftContract = address(_nftContract);
 
        _enabled = enabled;
        _timeBetweenRewards = timeBetweenRewards; 
        _rewardPerToken = rewardPerToken;
        _minimumStakeTime = minimumStakeTime;
    }

    function stake(uint256[] memory tokenIds) external whenEnabled {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _nftContract.safeTransferFrom(msg.sender, address(this), tokenIds[i]);
            Stake memory s = Stake(msg.sender, tokenIds[i], block.timestamp);
            indexMap[tokenIds[i]] = stakings.length;
            stakings.push(s);
            ownerStakings[msg.sender].push(tokenIds[i]);
        }
    }

    function unstake(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint index = indexMap[tokenIds[i]];
            Stake storage s = stakings[index];

            require(s.holder == msg.sender || msg.sender == owner, "You do not own this token");
            require(s.tokenId == tokenIds[i], "token mismatch - use force");

            _nftContract.safeTransferFrom(address(this), s.holder, tokenIds[i]);
            removeOwnerStaking(s.holder, tokenIds[i]);

            if (stakings.length > 1 && index != stakings.length - 1) {
                stakings[index] = stakings[stakings.length-1];
            }

            indexMap[tokenIds[i]] = 0;
            indexMap[stakings[index].tokenId] = index;
            stakings.pop();
        }
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
        currentLottery = Lottery(true, newToken, newPrize, 0, 0, 0, address(0));
        startTime = block.timestamp;
    }

    function prepareLottery() external onlyOwner {
        require(currentLottery.random == 0 && currentLottery.running, "Lottery not prepared for draw");  
        currentLottery.requestId = requestRandomWords();
    }

    function cancelLottery() external onlyOwner {
        currentLottery = Lottery(false, address(0), 0, 0, 0, 0, address(0));
    }

    function drawLottery() external onlyOwner { 
        require(currentLottery.random > 0 && currentLottery.running, "Lottery not prepared for draw");  
        IERC20 token = IERC20(currentLottery.token);

        uint256 totalTickets;

        for (uint256 i = 0; i < stakings.length; i++) {
            (uint256 owed,) = rewardsOwed(stakings[i]);
            totalTickets += owed;
        }

        if (totalTickets > 0) {
            require(token.balanceOf(address(this)) >= currentLottery.prize, "Not enough tokens to pay winner");

            uint256 roll = currentLottery.random % totalTickets;
            uint256 current;
            
            for (uint256 i = 0; i < stakings.length; i++) {
                (uint256 owed,) = rewardsOwed(stakings[i]);
                current += owed;

                if (owed > 0 && current >= roll) {
                    currentLottery.winner = stakings[i].holder;
                    currentLottery.totalTickets = totalTickets;
                }
            }

            require(currentLottery.winner != address(0), "Unable to find winner"); 
            token.transfer(currentLottery.winner, currentLottery.prize);
        }

        lotteryWinners.push(currentLottery);
        currentLottery = Lottery(false, address(0), 0, 0, 0, 0, address(0));
    }

    function forceUnstake(uint256 tokenId) external onlyOwner {
        Stake storage s = stakings[indexMap[tokenId]];
        require(s.holder != address(0), "could not find holder");
        _nftContract.safeTransferFrom(address(this), s.holder, tokenId);
    }

    function setOwner(address who) external onlyOwner {
        require(who != address(0), "cannot be zero address");
        owner = who;
    }

    function setEnabled(bool on) external onlyOwner {
        enabled = on;
    }

    function setChainlink(bytes32 hash, uint32 gasLimit, uint16 confirmations, uint32 numWords) public onlyOwner {
        keyHash = hash;
        callbackGasLimit = gasLimit;
        requestConfirmations = confirmations;
        numberOfWords = numWords;
    }
    
    function setChainlinkSubscription(uint64 subId) external onlyOwner {
        subscriptionId = subId;
    }

    function setParameters(uint256 _timeBetweenRewards, uint256 _rewardPerToken, uint256 _minimumStakeTime) external onlyOwner {
        timeBetweenRewards = _timeBetweenRewards;
        rewardPerToken = _rewardPerToken;
        minimumStakeTime = _minimumStakeTime;
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
            if (ownerStakings[holder].length > 1 && index != ownerStakings[holder].length - 1) {
                ownerStakings[holder][index] = ownerStakings[holder][ownerStakings[holder].length-1];
            }
            ownerStakings[holder].pop();
        }
    }

    function timeUntilReward(Stake storage stakedToken) private view returns (uint256) {

        if (block.timestamp - stakedToken.stakeTime < minimumStakeTime) {
            return minimumStakeTime - (block.timestamp - stakedToken.stakeTime);
        }

        uint256 lastClaimTime = stakedToken.stakeTime;
        if (startTime > lastClaimTime) {
            lastClaimTime = startTime;
        }

        if (block.timestamp - lastClaimTime >= timeBetweenRewards) {
            return timeBetweenRewards - ((block.timestamp - lastClaimTime) % timeBetweenRewards);
        }

        return timeBetweenRewards - (block.timestamp - lastClaimTime);
    }

    function rewardsOwed(Stake storage stakedToken) private view returns (uint256, uint256) {

        if (currentLottery.running == false) {
            return (0, 0);
        }

        if (block.timestamp - stakedToken.stakeTime >= minimumStakeTime) {
            uint256 lastClaimTime = stakedToken.stakeTime;
            if (startTime > lastClaimTime) {
                lastClaimTime = startTime;
            }

            if (block.timestamp - lastClaimTime >= timeBetweenRewards) {
                uint256 multiplesOwed = (block.timestamp - lastClaimTime) / timeBetweenRewards;
                return (
                    multiplesOwed * rewardPerToken,
                    multiplesOwed * timeBetweenRewards
                );
            }
        }

        return (0, 0);
    }

    function requestRandomWords() private returns (uint256) {
        return COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numberOfWords
        );
    }
  
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(currentLottery.random == 0 && currentLottery.running, "Lottery already prepared");
        require(currentLottery.requestId == requestId, "request mismatch - were you impatient while requesting?");
        currentLottery.random = randomWords[0];
    }

    function onERC721Received(address, address, uint256, bytes memory) public pure override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

}