/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

pragma solidity >=0.4.24;

contract Matrix {
    struct User {
        uint id;
        address referrer;
        uint personalMatrixCnt;
        uint personalMatrixNum;
        uint personalMatrixFills;
        uint totalReferrals;
        uint levelsOpen;
    }

    mapping(uint => uint) public LEVEL_PRICE;
    mapping(uint => uint) public LEVEL_SLOTS;
    mapping(uint => uint) public EXTRA_SLOTS;

    mapping(address => User) public users;
    mapping(uint => address) public binaryUsers;
    mapping(uint => address) public usersById;

    mapping(address => mapping (uint => uint)) public positionsByAddress;
    mapping(address => uint) public positionsByAddressCnt;
    mapping(uint => uint) public binaryPositionsLevels;

    uint public lastUserId = 2;
    uint public lastBinaryId = 1;
    uint public lastPersonalMatrixId = 2;
    address public owner;

    uint REGISTRATION_COST = 0.05 ether;

    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event LevelUpgraded(address indexed user, uint indexed userId, uint indexed level);
    event LevelFilled(address indexed user, uint indexed userId, uint indexed level);
    event Transfer(address indexed user, uint indexed userId, uint indexed amount);

   

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    constructor(address ownerAddress) public {
        owner = ownerAddress;

        User memory user = User({
            id: 1,
            referrer: address(0),
            personalMatrixCnt: 0,
            personalMatrixNum: 1,
            personalMatrixFills: 0,
            totalReferrals: 0,
            levelsOpen: 1
            });

        users[ownerAddress] = user;
        usersById[1] = ownerAddress;

        LEVEL_PRICE[1] = 0.05 ether;
        LEVEL_PRICE[2] = 0.1 ether;
        LEVEL_PRICE[3] = 0.2 ether;
        LEVEL_PRICE[4] = 1 ether;
        LEVEL_PRICE[5] = 6 ether;
        LEVEL_PRICE[6] = 50 ether;
        LEVEL_PRICE[7] = 50 ether;
        LEVEL_PRICE[8] = 100 ether;
        LEVEL_PRICE[9] = 400 ether;
        LEVEL_PRICE[10] = 1600 ether;

        LEVEL_SLOTS[1] = 2;
        LEVEL_SLOTS[2] = 4;
        LEVEL_SLOTS[3] = 8;
        LEVEL_SLOTS[4] = 16;
        LEVEL_SLOTS[5] = 32;
        LEVEL_SLOTS[6] = 2;
        LEVEL_SLOTS[7] = 4;
        LEVEL_SLOTS[8] = 8;
        LEVEL_SLOTS[9] = 16;
        LEVEL_SLOTS[10] = 32;

        EXTRA_SLOTS[1] = 0;
        EXTRA_SLOTS[2] = 1;
        EXTRA_SLOTS[3] = 6;
        EXTRA_SLOTS[4] = 20;
        EXTRA_SLOTS[5] = 200;
        EXTRA_SLOTS[6] = 200;
        EXTRA_SLOTS[7] = 400;
        EXTRA_SLOTS[8] = 2000;
        EXTRA_SLOTS[9] = 16000;
        EXTRA_SLOTS[10] = 124000;
    }

    function reg(address referrer) public payable {
        registration(msg.sender, referrer);
    }

    function purchasePosition() public payable {
        require(msg.value == 0.05 ether, "purchase cost 0.05");
        require(isUserExists(msg.sender), "user not exists");

        updateBinaryMatrix(msg.sender);
    }

    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == 0.1 ether, "registration cost 0.1");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        users[userAddress] = User({
            id: lastUserId,
            referrer: referrerAddress,
            levelsOpen: 1,
            personalMatrixCnt: 0,
            personalMatrixFills: 0,
            personalMatrixNum: lastPersonalMatrixId,
            totalReferrals: 0
            });
        usersById[lastUserId] = userAddress;

        lastUserId++;
        lastPersonalMatrixId++;

        updatePersonalMatrix(referrerAddress);
        updateBinaryMatrix(userAddress);

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function updatePersonalMatrix(address referrer) private {
        users[referrer].totalReferrals++;
        if (users[referrer].personalMatrixCnt < 2) {
            payRegDividends(referrer);
            users[referrer].personalMatrixCnt++;
        } else if (users[referrer].personalMatrixCnt == 2) {
            updateBinaryMatrix(referrer);
            users[referrer].personalMatrixCnt++;
        } else {
            if (users[referrer].referrer == address(0)) {
                payRegDividends(referrer);
            } else {
                updatePersonalMatrix(users[referrer].referrer);
            }
            users[referrer].personalMatrixCnt = 0;
            users[referrer].personalMatrixNum = lastPersonalMatrixId;
            users[referrer].personalMatrixFills++;
            lastPersonalMatrixId++;
        }
    }

    function payRegDividends(address user) private {
        emit Transfer(user, users[user].id, REGISTRATION_COST);
        address(uint160(user)).transfer(REGISTRATION_COST);
    }

    function updateBinaryMatrix(address user) private {
        positionsByAddress[user][positionsByAddressCnt[user]] = lastBinaryId;
        positionsByAddressCnt[user]++;
        binaryPositionsLevels[lastBinaryId] = 1;

        binaryUsers[lastBinaryId] = user;
        lastBinaryId++;

        uint div = 1;
        uint level = 0;
        uint initIndex = lastBinaryId-1;
        uint index = lastBinaryId-1;

        while (level < 5) {
            level++;
            div *= 2;

            if (index % div == div - 1) {
                index = index / div;

                if (index != 0) {
                    binaryPositionsLevels[index] = level;
                    fillLevel(binaryUsers[index], level);
                } else {
                    return;
                }
            } else {
                return;
            }
        }

        index = initIndex;

        while (level < 10) {
            level++;
            div *= 2;

            if (index % div == div - 1) {
                index = index / div;

                if (index != 0) {
                    binaryPositionsLevels[index] = level;
                    fillLevel(binaryUsers[index], level);
                } else {
                    return;
                }
            } else {
                return;
            }
        }
    }
    event Div(uint indexed level, uint indexed div);
    event FinalIndex(uint indexed index, uint indexed level);
    function getdiv()  {
        lastBinaryId = 5326;
        lastBinaryId++;
        uint div = 1;
        uint level = 0;
        uint initIndex = lastBinaryId-1;
        uint index = lastBinaryId-1;

        while (level < 5) {
            level++;
            div *= 2;
            Div(level,div);

            if (index % div == div - 1) {
                index = index / div;

                if (index != 0) {
                    FinalIndex(index,level);
                    // binaryPositionsLevels[index] = level;
                    // fillLevel(binaryUsers[index], level);
                } else {
                    return;
                }
            } else {
                return;
            }
        }
        index = initIndex;

        while (level < 10) {
            level++;
            div *= 2;
            Div(level,div);
            if (index % div == div - 1) {
                index = index / div;

                if (index != 0) {
                     FinalIndex(index,level);
                    // binaryPositionsLevels[index] = level;
                    // fillLevel(binaryUsers[index], level);
                } else {
                    return;
                }
            } else {
                return;
            }
        }
    }

    function fillLevel(address user, uint level) private {
        emit LevelFilled(user, users[user].id, level);

        level = level + 1;

        uint payment = LEVEL_PRICE[level - 1] * LEVEL_SLOTS[level - 1];

        if (users[user].levelsOpen < level) {
            users[user].levelsOpen++;
            emit LevelUpgraded(user, users[user].id, level);
        }

        payment -= LEVEL_PRICE[level];
        payment -= REGISTRATION_COST * EXTRA_SLOTS[level-1];

        if (level > 2) {
            emit Transfer(user, users[user].id, payment);

            address(uint160(user)).transfer(payment);
        }

        uint i = 0;
        while (i < EXTRA_SLOTS[level-1]) {
            updateBinaryMatrix(user);
            i++;
        }
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}