// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "./Ownable.sol";

interface IMemoryTypesPractice {
    function setA(uint256 _a) external;
    function setB(uint256 _b) external;
    function setC(uint256 _c) external;
    function calc1() external view returns(uint256);
    function calc2() external view returns(uint256);
    function claimRewards(address _user) external;
    function addNewMan(
        uint256 _edge, 
        uint8 _dickSize, 
        bytes32 _idOfSecretBluetoothVacinationChip, 
        uint32 _iq
    ) external;
    function getMiddleDickSize() external view returns(uint256);
    function numberOfOldMenWithHighIq() external view returns(uint256);
}

contract MemoryTypesPracticeInput is IMemoryTypesPractice, Ownable {
    
    // Owner part. Cannot be modified.
    IUserInfo public userInfo;
    uint256 public a;
    uint256 public b;
    uint256 public c;

    uint256 public constant MIN_BALANCE = 12000;

    mapping(address => bool) public rewardsClaimed;

    constructor(address _validator, address _userInfo) {
        transferOwnership(_validator);
        userInfo = IUserInfo(_userInfo);

        addNewMan(1, 1, bytes32('0x11'), 1);
    }

    function setA(uint256 _a) external onlyOwner {
        a = _a;
    }

    function setB(uint256 _b) external onlyOwner {
        b = _b;
    }

    function setC(uint256 _c) external onlyOwner {
        c = _c;
    }
    // End of the owner part

    // Here starts part for modification. Remember that function signatures cannot be modified. 

    // to optimize 1
    // Now consumes 27835 (27857)
    // Should consume not more than 27830 (27846) as execution cost for non zero values
    function calc1() external view returns(uint256) {
        return b + c * a;
    }


    // to optimize 2 + (29478)
    // Now consumes 31253 (31186)
    // Should consume not more than 30000 as execution cost for non zero values
    function calc2() external view returns(uint256) {
        uint256 _locA = a;
        uint256 _locB = b;
        uint256 _locC = c;
        return ((_locB+_locC)*(_locB+_locA)+(_locC+_locA)*_locC+_locC/_locA+_locC/_locB+2*_locA-1+_locA*_locB*_locC+_locA+_locB*_locA^2)/
        (_locA+_locB)*_locC+2*_locA;
    } 

    // to optimize 3
    // Now consumes 55446
    // Should consume not more than 54500 as execution cost
    function claimRewards(address _user) external {
        IUserInfo.User memory _userInfo = userInfo.getUserInfo(_user);
        require(_userInfo.unlockTime <= block.timestamp,
            "MemoryTypesPracticeInput: Unlock time has not yet come");

        require(!rewardsClaimed[_user], 
            "MemoryTypesPracticeInput: Rewards are already claimed");
        
        require(_userInfo.balance >= MIN_BALANCE, 
            "MemoryTypesPracticeInput: To less balance");
        
        rewardsClaimed[_user] = true;
    }


    // to optimize 4
    struct Man {
        uint256 edge;
        bytes32 idOfSecretBluetoothVacinationChip;
        uint32 iq;
        uint8 dickSize;
    }

    Man[] men;

    // Now consumes 115724 +(93679)
    // Should consume not more than 94000 as execution cost
    function addNewMan(
        uint256 _edge, 
        uint8 _dickSize, 
        bytes32 _idOfSecretBluetoothVacinationChip, 
        uint32 _iq
    ) public {
        men.push(Man(_edge, _idOfSecretBluetoothVacinationChip, _iq, _dickSize));
    }

    // to optimize 5
    // Now consumes 36689 (39384)
    // Should consume not more than 36100 (38795) +(38248) as execution cost for 6 elements array
    function getMiddleDickSize() external view returns(uint256) {
        uint256 _sum = 0;
        uint _len =  men.length;

        for (uint i = 0; i < _len;) {
            _sum += men[i].dickSize;
            unchecked {
                i++;
            }
        }

        return _sum/_len;
    }

    // to optimize 6
    // Now consumes 68675 (65381)
    // Should consume not more than 40000 +(35592)  as execution cost for 6 elements array
    function numberOfOldMenWithHighIq() external view returns(uint256 _count) {
        uint _len =  men.length;

        for (uint256 i = 0; i < _len; i++) {
            if (men[i].edge > 50 && men[i].iq > 120) _count++;
             unchecked {
                i++;
            }
        }
    }

    function getAddress() external view returns (address) {
        return address(this);
    }
}

// Cannot be modified
interface IUserInfo {
    struct User {
        uint256 balance;
        uint256 unlockTime;
    }

    function addUser(address _user, uint256 _balance, uint256 _unlockTime) external;
    function getUserInfo(address _user) external view returns(User memory);
}

// Cannot be modified.
contract UserInfo is IUserInfo, Ownable {
    mapping(address => User) users;

    constructor(address _validator) {
        transferOwnership(_validator);
    }

    function addUser(address _user, uint256 _balance, uint256 _unlockTime) external onlyOwner {
        users[_user] = User(_balance, _unlockTime);
    }

    function getUserInfo(address _user) external view returns(User memory) {
        return users[_user];
    }

    function getAddress() external view returns (address) {
        return address(this);
    }
}