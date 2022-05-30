pragma solidity =0.7.6;

import "OMS.sol";

interface ITRAF {
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    
}

interface ITRAF_Token {
    
    function O_transfer(address recipient, uint256 amount) external;
    
}

contract TRAF_Genesis_Staking is OMS {
    ITRAF TRAF = ITRAF(0xF6e4ED6d2f749701A606FCb7e009c54D1dC80956);
    ITRAF_Token TRAF_Token = ITRAF_Token(0x0557Cf04d3E8337A32AB75835b62056941f79747);

    mapping(uint256 /*Lock Time*/ => uint256 /*TRAF Reward*/) private _reward; //Amount of TRAF tokens received at the end of the lock time

    mapping(uint256 /*NFT ID*/ => address) private _owner; //Owner of the staked NFT
    mapping(uint256 /*NFT ID*/ => uint256) private _startingTime; //Strating time of the staking
    mapping(uint256 /*NFT ID*/ => uint256) private _lockTime; //Lock time of the staking

    event Stake(address indexed user, uint256 indexed nftId);
    event Unstake(address indexed user, uint256 indexed nftId);

    constructor() {
        _reward[2592000] =  1;
    }
    
    //Read Functions====================================================================================================================================================
    function stakingStats(uint256 nftId) external view returns(address owner, uint256 startingTime, uint256 lockTime, uint256 earned) {
        owner = _owner[nftId];
        startingTime = _startingTime[nftId];
        lockTime = _lockTime[nftId];

        uint256 passedTime = block.timestamp - startingTime;
        earned = _reward[lockTime] * passedTime / lockTime;
        if(passedTime > lockTime) {earned = _reward[lockTime];}
    }

    function reward(uint256 lockTime) external view returns(uint256) {
        return _reward[lockTime];
    }
    //Write Functions===================================================================================================================================================
    function stake(uint256 nftId, uint256 lockTime) external {
        require(nftId < 1000, "NOT_GENSIS_TOKEN"); //Only ep1, 2, 3 NFTs are allowed to stake on this contract
        TRAF.transferFrom(msg.sender, address(this), nftId);

        _owner[nftId] = msg.sender;
        _startingTime[nftId] = block.timestamp;
        _lockTime[nftId] = lockTime;

        emit Stake(msg.sender, nftId);
    }

    function stake(uint256[] calldata nftId, uint256[] calldata lockTime) external {
        uint256 size = nftId.length;

        for(uint256 t; t < size; ++t) {
            uint256 nft = nftId[t];
            require(nft < 1000, "NOT_GENSIS_TOKEN"); //Only ep1, 2, 3 NFTs are allowed to stake on this contract
            TRAF.transferFrom(msg.sender, address(this), nft);

            _owner[nft] = msg.sender;
            _startingTime[nft] = block.timestamp;
            _lockTime[nft] = lockTime[t];
            
            emit Stake(msg.sender, nft);
        } 
    }

    function unstake(uint256 nftId) external {
        require(msg.sender == _owner[nftId], "NOT_OWNER");

        if(block.timestamp < _startingTime[nftId] + _lockTime[nftId]) {
            TRAF.transferFrom(address(this), msg.sender, nftId);
        }
        else {
            TRAF.transferFrom(address(this), msg.sender, nftId);
            TRAF_Token.O_transfer(msg.sender, _reward[_lockTime[nftId]]);
        }

        emit Unstake(_owner[nftId], nftId);
    }

    function unstake(uint256[] calldata nftId) external {
        uint256 size = nftId.length;

        for(uint256 t; t < size; ++t) {
            uint256 nft = nftId[t];

            require(msg.sender == _owner[nft], "NOT_OWNER");

            if(block.timestamp > _startingTime[nft] + _lockTime[nft]) {
                TRAF_Token.O_transfer(msg.sender, _reward[_lockTime[nft]]);  
            }

            TRAF.transferFrom(address(this), msg.sender, nft);

            emit Unstake(_owner[nft], nft);
        }
    }

    //Mod Functions=====================================================================================================================================================

    function setReward(uint256 lockTime, uint256 trafReward) external Manager {
        _reward[lockTime] = trafReward;
    }

    function setTRAF(address trafAddress) external Manager {
        TRAF = ITRAF(trafAddress);
    }

    function setTRAFToken(address trafTokenAddress) external Manager {
        TRAF_Token = ITRAF_Token(trafTokenAddress);
    }
}