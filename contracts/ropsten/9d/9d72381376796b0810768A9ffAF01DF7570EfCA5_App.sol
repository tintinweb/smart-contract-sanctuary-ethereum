/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

/**
 *Submitted for verification at polygonscan.com on 2022-04-17
 contract scammers on the network polygon: 0x2772b5dce4d5Dd17a0aD2B55A8B3a0cDBd9Ed75B
 Shit scammers!
*/

pragma solidity ^0.8.4;

library PlayerLib {
    function bricks(uint256 _data) internal pure returns (uint256) {
        return (_data >> 224) & 0xffffffff;
    }

    function addBricks(uint256 _data, uint256 _value) internal pure returns (uint256) {
        _value = ((_data >> 224) & 0xffffffff) + _value;
        require(_value <= 0xffffffff, "bricksAdd_outOfBounds");
        return (_data & 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | (_value << 224);
    }

    function subBricks(uint256 _data, uint256 _value) internal pure returns (uint256) {
        _value = ((_data >> 224) & 0xffffffff) - _value;
        return (_data & 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff) | (_value << 224);
    }

    function transferPermission(uint256 _data) internal pure returns (uint256) {
        return (_data >> 223) & 0x1;
    }

    function setTransferPermission(uint256 _data, uint256 _value) internal pure returns (uint256) {
        require(_value <= 0x1, "transferPermission_outOfBounds");
        return (_data & 0xffffffff7fffffffffffffffffffffffffffffffffffffffffffffffffffffff) | (_value << 223);
    }

    function purchasedBricks(uint256 _data) internal pure returns (uint256) {
        return (_data >> 216) & 0x7f;
    }

    function addPurchasedBricks(uint256 _data, uint256 _value) internal pure returns (uint256) {
        _value = ((_data >> 216) & 0x7f) + _value;
        _value = _value <= 0x7f ? _value : 0x7f;
        return (_data & 0xffffffff80ffffffffffffffffffffffffffffffffffffffffffffffffffffff) | (_value << 216);
    }

    function swappedBricks(uint256 _data) internal pure returns (uint256) {
        return (_data >> 200) & 0xffff;
    }

    function addSwappedBricks(uint256 _data, uint256 _value) internal pure returns (uint256) {
        _value = ((_data >> 200) & 0xffff) + _value;
        _value = _value <= 0xffff ? _value : 0xffff;
        return (_data & 0xffffffffff0000ffffffffffffffffffffffffffffffffffffffffffffffffff) | (_value << 200);
    }

    function coins(uint256 _data) internal pure returns (uint256) {
        return (_data >> 160) & 0xffffffffff;
    }

    function addCoins(uint256 _data, uint256 _value) internal pure returns (uint256) {
        _value = ((_data >> 160) & 0xffffffffff) + _value;
        require(_value <= 0xffffffffff, "coinsAdd_outOfBounds");
        return (_data & 0xffffffffffffff0000000000ffffffffffffffffffffffffffffffffffffffff) | (_value << 160);
    }

    function subCoins(uint256 _data, uint256 _value) internal pure returns (uint256) {
        _value = ((_data >> 160) & 0xffffffffff) - _value;
        return (_data & 0xffffffffffffff0000000000ffffffffffffffffffffffffffffffffffffffff) | (_value << 160);
    }

    function coinsPerHour(uint256 _data) internal pure returns (uint256) {
        return (_data >> 136) & 0xffffff;
    }

    function setCoinsPerHour(uint256 _data, uint256 _value) internal pure returns (uint256) {
        require(_value <= 0xffffff, "coinsPerHour_outOfBounds");
        return (_data & 0xffffffffffffffffffffffff000000ffffffffffffffffffffffffffffffffff) | (_value << 136);
    }

    function uncollectedCoins(uint256 _data) internal pure returns (uint256) {
        return (_data >> 96) & 0xffffffffff;
    }

    function setUncollectedCoins(uint256 _data, uint256 _value) internal pure returns (uint256) {
        require(_value <= 0xffffffffff, "uncollectedCoins_outOfBounds");
        return (_data & 0xffffffffffffffffffffffffffffff0000000000ffffffffffffffffffffffff) | (_value << 96);
    }

    function addUncollectedCoins(uint256 _data, uint256 _value) internal pure returns (uint256) {
        _value = ((_data >> 96) & 0xffffffffff) + _value;
        require(_value <= 0xffffffffff, "uncollectedCoinsAdd_outOfBounds");
        return (_data & 0xffffffffffffffffffffffffffffff0000000000ffffffffffffffffffffffff) | (_value << 96);
    }

    function collectedCoins(uint256 _data) internal pure returns (uint256) {
        return (_data >> 72) & 0xffffff;
    }

    function addCollectedCoins(uint256 _data, uint256 _value) internal pure returns (uint256) {
        _value = ((_data >> 72) & 0xffffff) + _value;
        _value = _value <= 0xffffff ? _value : 0xffffff;
        return (_data & 0xffffffffffffffffffffffffffffffffffffffff000000ffffffffffffffffff) | (_value << 72);
    }

    function coinsHour(uint256 _data) internal pure returns (uint256) {
        return (_data >> 52) & 0xfffff;
    }

    function setCoinsHour(uint256 _data, uint256 _value) internal pure returns (uint256) {
        require(_value <= 0xfffff, "coinsHour_outOfBounds");
        return (_data & 0xffffffffffffffffffffffffffffffffffffffffffffff00000fffffffffffff) | (_value << 52);
    }

    function uncollectedAirdrop(uint256 _data) internal pure returns (uint256) {
        return (_data >> 28) & 0xffffff;
    }

    function setUncollectedAirdrop(uint256 _data, uint256 _value) internal pure returns (uint256) {
        require(_value <= 0xffffff, "uncollectedAirdrop_outOfBounds");
        return (_data & 0xfffffffffffffffffffffffffffffffffffffffffffffffffff000000fffffff) | (_value << 28);
    }

    function airdropDay(uint256 _data) internal pure returns (uint256) {
        return (_data >> 12) & 0xffff;
    }

    function setAirdropDay(uint256 _data, uint256 _value) internal pure returns (uint256) {
        require(_value <= 0xffff, "airdropDay_outOfBounds");
        return (_data & 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000fff) | (_value << 12);
    }

    function pendingStarsProfit(uint256 _data) internal pure returns (uint256) {
        return (_data >> 10) & 0x3;
    }

    function setPendingStarsProfit(uint256 _data, uint256 _value) internal pure returns (uint256) {
        require(_value <= 0x3, "pendingStarsProfit_outOfBounds");
        return (_data & 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3ff) | (_value << 10);
    }

    function pendingStarsBuild(uint256 _data) internal pure returns (uint256) {
        return (_data >> 8) & 0x3;
    }

    function setPendingStarsBuild(uint256 _data, uint256 _value) internal pure returns (uint256) {
        require(_value <= 0x3, "pendingStarsBuild_outOfBounds");
        return (_data & 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffcff) | (_value << 8);
    }

    function starsCollect(uint256 _data) internal pure returns (uint256) {
        return (_data >> 6) & 0x3;
    }

    function setStarsCollect(uint256 _data, uint256 _value) internal pure returns (uint256) {
        require(_value <= 0x3, "starsCollect_outOfBounds");
        return (_data & 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3f) | (_value << 6);
    }

    function starsBuild(uint256 _data) internal pure returns (uint256) {
        return (_data >> 4) & 0x3;
    }

    function setStarsBuild(uint256 _data, uint256 _value) internal pure returns (uint256) {
        require(_value <= 0x3, "starsBuild_outOfBounds");
        return (_data & 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffcf) | (_value << 4);
    }

    function starsSwap(uint256 _data) internal pure returns (uint256) {
        return (_data >> 2) & 0x3;
    }

    function setStarsSwap(uint256 _data, uint256 _value) internal pure returns (uint256) {
        require(_value <= 0x3, "starsSwap_outOfBounds");
        return (_data & 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3) | (_value << 2);
    }

    function starsProfit(uint256 _data) internal pure returns (uint256) {
        return (_data >> 0) & 0x3;
    }

    function setStarsProfit(uint256 _data, uint256 _value) internal pure returns (uint256) {
        require(_value <= 0x3, "starsProfit_outOfBounds");
        return (_data & 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc) | (_value << 0);
    }
}

contract App {
    using PlayerLib for uint256;
    mapping(address => uint256) players;
    address constant owner = 0x7EB4b53Fd48af1D00AE8cdf63a06bFc67892D88e;
    event Log(address addr, uint256 player, uint256 commandSize, uint256 command);

    fallback() external payable {
        require(msg.sender == tx.origin, "fallback_onlyEOA");
        uint256 player = players[msg.sender];
        if (player.airdropDay() == 0) {
            player = register(player);
        }
        player = update(player);
        if (msg.value > 0) {
            player = buy(player);
        }
        uint256 payloadSize = msg.data.length;
        uint256 payloadOffset = 0;
        while (payloadOffset < payloadSize) {
            uint256 commandSize = uint8(msg.data[payloadOffset]);
            require(commandSize > 0 && commandSize <= 32, "commandSize_outOfBounds");
            payloadOffset += 1;
            uint256 command;
            bytes memory b = msg.data[payloadOffset:(payloadOffset + commandSize)];
            assembly {
                command := mload(add(b, 0x20))
            }
            command = command >> ((32 - commandSize) * 8);
            if (commandSize == 1) {
                player = claim(player, command);
            } else if (commandSize == 4) {
                player = swap(player, command);
            } else if (commandSize == 5) {
                player = sell(player, command);
            } else if (commandSize == 15) {
                player = editMap(player, command);
            } else if (commandSize == 20) {
                allowTransfer(command);
            } else if (commandSize == 24) {
                player = transfer(player, command);
            }
            emit Log(msg.sender, player, commandSize, command);
            payloadOffset += commandSize;
        }
        players[msg.sender] = player;
    }

    function register(uint256 _player) internal view returns (uint256) {
        return _player.addBricks(20).setAirdropDay(block.timestamp / 86400 + 1);
    }

    function update(uint256 _player) internal view returns (uint256) {
        uint256 hourNow = block.timestamp / 3600;
        uint256 hoursPassed = hourNow - _player.coinsHour();
        if (hoursPassed > 0) {
            _player = _player.addUncollectedCoins(_player.coinsPerHour() * hoursPassed).setCoinsHour(hourNow);
        }
        uint256 dayNow = block.timestamp / 86400;
        uint256 airdropDay = _player.airdropDay();
        if (dayNow >= airdropDay && _player.uncollectedAirdrop() == 0) {
            uint256 coins = _player.coinsPerHour();
            _player = _player.setUncollectedAirdrop(coins > 0 ? (coins * 35) / 10 : 2);
        }
        return _player;
    }

    function buy(uint256 _player) internal returns (uint256) {
        uint256 bricks = msg.value / 4e15;
        require(bricks > 0, "buy_requireNonZero");
        _player = _player.addBricks(bricks).addPurchasedBricks(bricks);
        sendFee(bricks);
        emit Log(msg.sender, _player, 0, bricks);
        return _player;
    }

    function swap(uint256 _player, uint256 _bricks) internal returns (uint256) {
        require(_bricks > 0, "swap_requireNonZero");
        _player = _player.subCoins(_bricks * 80).addBricks(_bricks).addSwappedBricks(_bricks);
        if (_player.purchasedBricks() >= 100) {
            sendFee(_bricks);
        }
        return _player;
    }

    function sell(uint256 _player, uint256 _coins) internal returns (uint256) {
        require(_player.purchasedBricks() >= 100, "sell_paywall");
        require(_coins >= 10_00, "sell_tooLittleAmount");
        uint256 total = address(this).balance / 4e13;
        _coins = _coins <= total ? _coins : total;
        require(_coins > 0, "sell_requireNonZero");
        _player = _player.subCoins(_coins);
        payable(msg.sender).transfer(_coins * 4e13);
        return _player;
    }

    function allowTransfer(uint256 _command) internal {
        require(msg.sender == owner, "allowTransfer_onlyOwner");
        address addr = address(uint160(_command));
        uint256 player = players[addr];
        require(player != 0, "allowTransfer_notRegistered");
        players[addr] = player.setTransferPermission(1);
    }

    function transfer(uint256 _player, uint256 _command) internal returns (uint256) {
        require(msg.sender == owner || _player.transferPermission() == 1, "transfer_notAllowed");
        require(_player.purchasedBricks() >= 100, "transfer_paywall");
        uint256 bricks = _command & type(uint32).max;
        require(bricks >= 100, "transfer_tooLittleAmount");
        require(bricks + 20 <= _player.bricks(), "transfer_tooMuchAmount");
        address to = address(uint160(_command >> 32));
        require(msg.sender != to, "transfer_sameAddress");
        uint256 recipient = players[to];
        require(recipient != 0, "transfer_notRegistered");
        _player = _player.setCoinsPerHour(0).subBricks(bricks);
        bricks = (bricks * 9) / 10;
        recipient = recipient.addBricks(bricks);
        players[to] = recipient;
        emit Log(to, recipient, 0, bricks);
        return _player;
    }

    function sendFee(uint256 _bricks) internal {
        if (msg.sender != owner) {
            players[owner] = players[owner].addCoins(_bricks * 10);
        }
    }

    function claim(uint256 _player, uint256 _type) internal view returns (uint256) {
        if (_type == 1) {
            uint256 coins = _player.uncollectedCoins();
            require(coins > 0, "collect_requireNonZero");
            return _player.addCoins(coins).addCollectedCoins(coins).setUncollectedCoins(0);
        } else if (_type == 2) {
            uint256 airdropAmount = _player.uncollectedAirdrop();
            require(airdropAmount > 0, "airdrop_requireNonZero");
            return _player.addCoins(airdropAmount).setUncollectedAirdrop(0).setAirdropDay(block.timestamp / 86400 + 1); // next day
        } else if (_type == 3) {
            uint256 stars = _player.starsCollect();
            uint256 target = _player.collectedCoins();
            if (stars == 0 && target >= 500_00) {
                return _player.setStarsCollect(1).addBricks(50);
            } else if (stars == 1 && target >= 5_000_00) {
                return _player.setStarsCollect(2).addBricks(500);
            } else if (stars == 2 && target >= 50_000_00) {
                return _player.setStarsCollect(3).addBricks(5_000);
            }
        } else if (_type == 4) {
            uint256 stars = _player.starsBuild();
            uint256 target = _player.pendingStarsBuild();
            if (stars == 0 && target >= 1) {
                return _player.setStarsBuild(1).addBricks(100);
            } else if (stars == 1 && target >= 2) {
                return _player.setStarsBuild(2).addBricks(1_000);
            } else if (stars == 2 && target == 3) {
                return _player.setStarsBuild(3).addBricks(10_000);
            }
        } else if (_type == 5) {
            uint256 stars = _player.starsSwap();
            uint256 target = _player.swappedBricks();
            if (stars == 0 && target >= 500) {
                return _player.setStarsSwap(1).addBricks(100);
            } else if (stars == 1 && target >= 5_000) {
                return _player.setStarsSwap(2).addBricks(1_000);
            } else if (stars == 2 && target >= 50_000) {
                return _player.setStarsSwap(3).addBricks(10_000);
            }
        } else if (_type == 6) {
            uint256 stars = _player.starsProfit();
            uint256 target = _player.pendingStarsProfit();
            if (stars == 0 && target >= 1) {
                return _player.setStarsProfit(1).addBricks(150);
            } else if (stars == 1 && target >= 2) {
                return _player.setStarsProfit(2).addBricks(1_500);
            } else if (stars == 2 && target == 3) {
                return _player.setStarsProfit(3).addBricks(15_000);
            }
        }
        revert("claim_noChanges");
    }

    function editMap(uint256 _player, uint256 _map) internal pure returns (uint256) {
        uint256 count;
        uint256 bricks;
        uint256 coinsPerHour;
        uint256 c0;
        uint256 c1;
        uint256 c2;
        uint256 c3;
        count = (_map >> 112) & 0xff;
        if (count > 0) {
            coinsPerHour += count * 1;
            bricks += count * 20;
            c0 += count;
        }
        count = (_map >> 104) & 0xff;
        if (count > 0) {
            coinsPerHour += count * 4;
            bricks += count * 70;
            c0 += count;
        }
        count = (_map >> 96) & 0xff;
        if (count > 0) {
            coinsPerHour += count * 11;
            bricks += count * 180;
            c0 += count;
        }
        count = (_map >> 88) & 0xff;
        if (count > 0) {
            coinsPerHour += count * 22;
            bricks += count * 340;
            c1 += count;
        }
        count = (_map >> 80) & 0xff;
        if (count > 0) {
            coinsPerHour += count * 46;
            bricks += count * 700;
            c1 += count;
        }
        count = (_map >> 72) & 0xff;
        if (count > 0) {
            coinsPerHour += count * 1_00;
            bricks += count * 1_500;
            c2 += count;
        }
        count = (_map >> 64) & 0xff;
        if (count > 0) {
            coinsPerHour += count * 2_72;
            bricks += count * 4_000;
            c2 += count;
        }
        count = (_map >> 56) & 0xff;
        if (count > 0) {
            coinsPerHour += count * 5_54;
            bricks += count * 8_000;
            c2 += count;
        }
        count = (_map >> 48) & 0xff;
        if (count > 0) {
            coinsPerHour += count * 10_60;
            bricks += count * 15_000;
            c2 += count;
        }
        count = (_map >> 40) & 0xff;
        if (count > 0) {
            coinsPerHour += count * 18_00;
            bricks += count * 25_000;
            c3 += count;
        }
        count = (_map >> 32) & 0xff;
        if (count > 0) {
            coinsPerHour += count * 36_70;
            bricks += count * 50_000;
            c3 += count;
        }
        count = (_map >> 24) & 0xff;
        if (count > 0) {
            coinsPerHour += count * 75_00;
            bricks += count * 100_000;
            c3 += count;
        }
        count = (_map >> 16) & 0xff;
        if (count > 0) {
            coinsPerHour += count * 153_00;
            bricks += count * 200_000;
            c3 += count;
        }
        count = (_map >> 8) & 0xff;
        if (count > 0) {
            coinsPerHour += count * 234_00;
            bricks += count * 300_000;
            c3 += count;
        }
        count = _map & 0xff;
        if (count > 0) {
            coinsPerHour += count * 400_00;
            bricks += count * 500_000;
            c3 += count;
        }
        require(c0 + c1 + c2 + c3 <= 60, "setMap_tooManyBuildings");
        require(_player.bricks() >= bricks, "setMap_notEnoughBricks");
        _player = _player.setCoinsPerHour(coinsPerHour);
        uint256 stars = _player.pendingStarsBuild();
        if (stars == 0 && c1 + c2 + c3 >= 3) stars = 1;
        if (stars == 1 && c2 + c3 >= 7) stars = 2;
        if (stars == 2 && c3 >= 4) stars = 3;
        _player = _player.setPendingStarsBuild(stars);
        stars = _player.pendingStarsProfit();
        if (stars == 0 && coinsPerHour >= 1_00) stars = 1;
        if (stars == 1 && coinsPerHour >= 10_00) stars = 2;
        if (stars == 2 && coinsPerHour >= 100_00) stars = 3;
        _player = _player.setPendingStarsProfit(stars);
        return _player;
    }
}