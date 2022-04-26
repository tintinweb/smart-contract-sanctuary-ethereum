/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

interface INFT {
    function useNftPrice(address account, uint256 tokenId)
        external
        returns (bool isTemp);

    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IBCKS {
    function burn(address account, uint256 amount) external;

    function mint(address to, uint256 amount) external;
}

library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }
}

contract BCKGAME {
    string public name = "BCKGAME";
    string public symbol = "BCKGAME";
    address public owner;

    uint256 public totalReward; //总奖励
    uint256 public totalPower; //总算力
    uint256 public totalLands; //总土地数
    bool public isSteal = true; //是否开启偷菜

    uint256 public baseBck = 1e18; //基础BCK
    uint256 public landRequried = 2000000 * baseBck; //土地需求
    uint256 public seedRequried = 10000000 * baseBck; //种子需求

    address public depositAddress;
    address public bcksAddress;
    address public bckAddress;
    address public fertAddress;
    address public nftAddress;

    struct GameInfo {
        bool status; //是否激活
        bool isTemp; //是否临时
        uint256 level; //等级
        uint256 exp; //经验
        uint256 upgrade; //升级经验
        uint256 upgradeTime; //升级时间
        uint8 lands; //土地数量
        uint256 totalReward; //总奖励
        uint256 nextHarvestAt; //下一次收获时间
    }

    struct LandInfo {
        bool status; //是否激活
        uint256 nextHarvestAt; //下一次收获时间
        uint8 times; //收获次数
        uint256 steal; //被偷菜次数
        uint256 totalReward; //总奖励
    }

    uint256 public epoch = 300; //周期
    mapping(uint256 => GameInfo) public gameInfo; // 游戏信息
    mapping(uint256 => mapping(uint8 => LandInfo)) public landInfo; // 土地信息

    event StartGame(uint256 _tokenId);
    event OpenLand(uint256 _tokenId, uint8 _position);
    event Harvest(uint256 _tokenId, uint256 _amount);
    event Upgrade(uint256 _tokenId, uint256 _level);
    event Plant(uint256 _tokenId, uint8 _position);
    event Steal(
        address indexed _user,
        uint256 _tokenId,
        uint8 _position,
        uint256 _amount
    );

    constructor(
        address _depositAddress,
        address _bckAddress,
        address _bcksAddress,
        address _fertAddress,
        address _nftAddress
    ) {
        owner = msg.sender;
        depositAddress = _depositAddress;
        bckAddress = _bckAddress;
        bcksAddress = _bcksAddress;
        fertAddress = _fertAddress;
        nftAddress = _nftAddress;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    // 开始游戏
    function startGame(uint256 _tokenId) public {
        GameInfo storage game = gameInfo[_tokenId];
        require(!game.status, "game is already started");

        bool isTemp = INFT(nftAddress).useNftPrice(msg.sender, _tokenId);

        game.status = true; //激活
        if (isTemp) {
            game.isTemp = isTemp; //是否临时
            game.lands = 3; //初始化土地数量
        } else {
            game.lands = 1; //初始化土地数量
        }
        game.upgrade = (game.level + 1) * 50 + game.exp - 25; //升级所需经验
        emit StartGame(_tokenId);
    }

    // 开辟土地
    function openLand(uint256 _tokenId, uint8 _position) public {
        GameInfo storage game = gameInfo[_tokenId];
        require(game.status, "game is not started");
        require(
            _position > 0 && _position <= game.lands,
            "position is not valid"
        );

        LandInfo storage land = landInfo[_tokenId][_position];
        require(!land.status, "land is already open");

        TransferHelper.safeTransferFrom(
            bckAddress,
            msg.sender,
            depositAddress,
            landRequried
        );
        land.status = true;
        emit OpenLand(_tokenId, _position);
    }

    // 升级土地
    function upgradeLand(uint256 _tokenId) public {
        GameInfo storage game = gameInfo[_tokenId];
        require(game.status, "game is not started");
        require(game.level < 100, "game level is max");
        require(!game.isTemp, "game is temp");

        TransferHelper.safeTransferFrom(
            fertAddress,
            msg.sender,
            depositAddress,
            game.upgrade * baseBck
        );

        game.exp = game.upgrade;
        game.upgrade = (game.level + 1) * 50 + game.exp - 25; //升级所需经验
        game.level += 1; //升级
        game.upgradeTime = block.timestamp + game.level * 3600; //升级时间
        game.lands = getMaxLand(_tokenId); //土地数量
        emit Upgrade(_tokenId, game.level);
    }

    // 土地种植
    function plant(uint256 _tokenId, uint8 _position) public {
        GameInfo storage game = gameInfo[_tokenId];
        require(game.status, "game is not started");
        require(
            _position > 0 && _position <= game.lands,
            "position is not valid"
        );

        LandInfo storage land = landInfo[_tokenId][_position];
        require(land.status, "land is not open");
        require(land.times == 0, "land is already planted");

        if (game.isTemp) {
            require(land.nextHarvestAt == 0, "game is temp");
        }

        TransferHelper.safeTransferFrom(
            bckAddress,
            msg.sender,
            depositAddress,
            seedRequried
        );
        land.times = 30;
        land.nextHarvestAt = block.timestamp;
        game.nextHarvestAt = block.timestamp;

        emit Plant(_tokenId, _position);
    }

    // 收获
    function harvest(uint256 _tokenId, uint8 _position) public {
        LandInfo storage land = landInfo[_tokenId][_position];
        require(land.status, "land is not open");
        require(land.times > 0, "land is not ready");
        require(
            block.timestamp > land.nextHarvestAt,
            "Error: nextHarvestAt epoch"
        );
        require(
            INFT(nftAddress).ownerOf(_tokenId) == msg.sender,
            "Error: not owner"
        );
        _harvest(_tokenId, _position);
    }

    // 一键收菜
    function harvestAll(uint256 _tokenId) public {
        GameInfo storage game = gameInfo[_tokenId];
        require(game.status, "game is not started");
        require(
            block.timestamp > game.nextHarvestAt,
            "Error: nextHarvestAt epoch"
        );
        require(
            INFT(nftAddress).ownerOf(_tokenId) == msg.sender,
            "Error: not owner"
        );

        for (uint8 i = 1; i <= game.lands; i++) {
            LandInfo storage land = landInfo[_tokenId][i];
            if (land.status && land.times > 0) {
                _harvest(_tokenId, i);
            }
        }
    }

    function _harvest(uint256 _tokenId, uint8 _position) private {
        uint256 reward = rewardAmount(_tokenId, _position);
        if (reward > 0) {
            LandInfo storage land = landInfo[_tokenId][_position];
            if (land.times > 0) {
                GameInfo storage game = gameInfo[_tokenId];

                land.times -= 1;
                land.nextHarvestAt = block.timestamp + epoch;
                uint256 _epoch_day = land.nextHarvestAt / 86400;
                uint256 _epoch_day2 = game.nextHarvestAt / 86400;
                if (_epoch_day > _epoch_day2) {
                    game.nextHarvestAt = land.nextHarvestAt;
                }

                reward -= (reward * 5 * land.steal) / 100; //被偷菜次数
                TransferHelper.safeTransferFrom(
                    bckAddress,
                    depositAddress,
                    msg.sender,
                    reward
                );

                uint256 bcks = 1 * baseBck;
                if (game.level > 0) {
                    bcks += (game.level * 5 * baseBck) / 100;
                }

                IBCKS(bcksAddress).mint(msg.sender, bcks);
                land.totalReward += reward;
                land.steal = 0;
                emit Harvest(_tokenId, reward);
            }
        }
    }

    // 偷菜
    function steal(uint256 _tokenId, uint8 _position) public {
        require(isSteal, "steal is not open");
        GameInfo storage game = gameInfo[_tokenId];
        require(game.status, "game is not started");

        uint256 reward = rewardAmount(_tokenId, _position);
        require(reward > 0, "land is not ready");

        LandInfo storage land = landInfo[_tokenId][_position];
        require(land.steal < 2, "steal is max");

        land.steal += 1;
        reward = (reward * 5) / 100;
        TransferHelper.safeTransferFrom(
            bckAddress,
            depositAddress,
            msg.sender,
            reward
        );
        emit Steal(msg.sender, _tokenId, _position, reward);
    }

    function rewardAmount(uint256 _tokenId, uint8 _position)
        public
        view
        returns (uint256)
    {
        LandInfo storage land = landInfo[_tokenId][_position];
        if (block.timestamp < land.nextHarvestAt) {
            return 0;
        }

        GameInfo storage game = gameInfo[_tokenId];
        return (game.level + 8) * 10000 * baseBck;
    }

    function getMaxLand(uint256 _tokenId) public view returns (uint8) {
        GameInfo storage game = gameInfo[_tokenId];
        uint8 maxLand = 1;
        if (game.level >= 20) {
            maxLand = 9;
        } else if (game.level >= 10) {
            maxLand = 6;
        } else if (game.level >= 5) {
            maxLand = 3;
        }

        return maxLand;
    }

    function withdrawToken(
        address token,
        address to,
        uint256 amount
    ) public onlyOwner {
        TransferHelper.safeTransfer(token, to, amount);
    }
}