/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Forsage {

    struct User {
        uint id;
        address referrer;
        uint partnersCount;
    }

    mapping(address => User) public users;

    address public owner;
}

contract XGoldStorage {

    address payable public xGold;
    address public owner;

    constructor(address ownerAddress) public payable {
        xGold = msg.sender;
        owner = ownerAddress;
    }

    fallback() external payable {
    }

    receive() external payable {
    }

    function transferTo(address to, uint value) public {
        require(msg.sender == xGold);

        if(to == xGold) {
            XGoldBasic(xGold).receiveEth{value: value}();
        } else {
            address(uint160(to)).transfer(value);
        }
        
    }

    function withdrawLostTokens(address tokenAddress) public {
        require(msg.sender == owner);        
        IERC20(tokenAddress).transfer(owner, IERC20(tokenAddress).balanceOf(address(this)));
    }
}

contract XGoldBasic {
    
    // -----DON'T REMOVE-----------
    address public impl;
    address public contractOwner;

    address public fourthLevelUpdater;
    // -----------------------------

    uint8 public MAX_LEVEL = 15;

    struct User {
        uint id;
        address referrer;
        bool exists;
        
        mapping(uint8 => bool) activeX6Levels;        
        mapping(uint8 => X6) x6Matrix;
    }
    
    struct X6 {
        address currentReferrerAddress;

        address[2] firstLevelReferrals;
        address[4] secondLevelReferrals;
        address[8] thirdLevelReferrals;
        address[16] fourthLevelReferrals;

        uint128 reinvestCount;
        uint8 currentReferrerIndex;
        bool blocked;
    }

    Forsage public forsage;
    XGoldStorage public xGoldStorage;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint8 => uint) public levelPrice;

    address public owner;
    address lastReinvestAddress;
    address public multisig;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 level);
    event StoredETH(address indexed from, address indexed to, uint8 level, uint value);
    event ReleasedETH(address indexed from, address indexed to, uint8 level, uint value);

    function receiveEth() external payable {}
}


contract XGold is XGoldBasic {
    
    modifier onlyContractOwner() { 
        require(msg.sender == contractOwner, "onlyOwner"); 
        _; 
    }
 
    // FORSAGE - 0xad5A2656E82D24B78EC65Fa0e4b99e6685f281e3
    function init(address _forsage,
                    address _fourthLevelUpdater,
                    address _multisig) public onlyContractOwner() {
        require(forsage == Forsage(address(0)), "already inited");

        multisig = _multisig;

        MAX_LEVEL = 15;
        
        // controller = Controller(_controllerAddress);
        forsage = Forsage(_forsage);
        
        fourthLevelUpdater = _fourthLevelUpdater;

        contractOwner = msg.sender;
        
        levelPrice[1] = 0.05e18;
        levelPrice[2] = 0.1e18;
        levelPrice[3] = 0.2e18;
        levelPrice[4] = 0.3e18;
        levelPrice[5] = 0.5e18;
        levelPrice[6] = 0.8e18;
        levelPrice[7] = 1.3e18;
        levelPrice[8] = 2.1e18;
        levelPrice[9] = 3.4e18;
        levelPrice[10] = 5.5e18;
        levelPrice[11] = 8.9e18;
        levelPrice[12] = 14.4e18;
        levelPrice[13] = 23.3e18;
        levelPrice[14] = 37.7e18;
        levelPrice[MAX_LEVEL] = 61e18;
        
        owner = forsage.owner();
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            exists: true
        });
        
        users[owner] = user;
        idToAddress[1] = owner;
        
        for (uint8 i = 1; i <= MAX_LEVEL; i++) {
            users[owner].activeX6Levels[i] = true;
        }

        xGoldStorage = new XGoldStorage(owner);
    }
    

    function setFourthLevelUpdater(address _fourthLevelUpdater) public onlyContractOwner {
        fourthLevelUpdater = _fourthLevelUpdater;
    }
    
    receive() external payable {
        require(gasleft() > uint(400000), "too low gas limit");
        uint8 _level = findNextUserLevel(msg.sender);
        require(_level > 0, "nothing to buy");

        buyNewLevel(_level);
    }

    function registrationExt() public payable {
        require(gasleft() > uint(400000), "too low gas limit");
        registration(msg.sender);
    }

    function findNextUserLevel(address user) public view returns(uint8) {
        for (uint8 i = 1; i <= MAX_LEVEL; i++) {
            if(!users[user].activeX6Levels[i]) {
                return i;
            }
        }
    }
    
    
    function buyNewLevel(uint8 level) public payable {
        require(gasleft() > uint(400000), "too low gas limit");

        if (!isUserExists(msg.sender)) {
            return registration(msg.sender);
        }

        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= MAX_LEVEL, "invalid level");
        require(!users[msg.sender].activeX6Levels[level], "level already activated");
        require(users[msg.sender].activeX6Levels[level-1], "buy previoul level first");

        if (users[msg.sender].x6Matrix[level-1].blocked) {
            users[msg.sender].x6Matrix[level-1].blocked = false;
        }

        address freeX6Referrer = findFreeX6Referrer(msg.sender, level);
        
        users[msg.sender].activeX6Levels[level] = true;
        updateX6Referrer(msg.sender, freeX6Referrer, level, msg.value);
        // controller.update(msg.sender, level, msg.value, 0);
        
        emit Upgrade(msg.sender, freeX6Referrer, level);
    }    
    
    function registration(address userAddress) private {
    
        (uint _id ,address referrerAddress, ) = forsage.users(userAddress);

        require(referrerAddress != address(0), "register in Forsage first");
        require(msg.value == levelPrice[1], "registration cost 0.05 ETH");
        require(!isUserExists(userAddress), "user exists");
        require(msg.sender == tx.origin, "cannot be a contract");
        
        User memory user = User({
            id: _id,
            referrer: referrerAddress,
            exists: true
        });

        users[userAddress] = user;

        idToAddress[_id] = userAddress;
        users[userAddress].activeX6Levels[1] = true;

        address currentReferrer = findFreeX6Referrer(userAddress, 1);

        updateX6Referrer(userAddress, currentReferrer, 1, msg.value);
        // controller.update(userAddress, 1, msg.value, 0);
        
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }

    function updateX6Referrer(address userAddress, address referrerAddress, uint8 level, uint ethValue) internal {
        uint8 buf = 0;
        uint8 a = 0;
        uint8 n = 0;

        X6 memory referrerMemoryArray = users[referrerAddress].x6Matrix[level];

        while(n < 2) {
            if(users[referrerAddress].x6Matrix[level].firstLevelReferrals[n] == address(0)) {

                users[referrerAddress].x6Matrix[level].firstLevelReferrals[n] = userAddress;
                emit NewUserPlace(userAddress, referrerAddress, level, n);
                
                //set current level
                users[userAddress].x6Matrix[level].currentReferrerAddress = referrerAddress;
                users[userAddress].x6Matrix[level].currentReferrerIndex = n;

                if (referrerAddress == owner) {
                    return sendOwnerETHDividends(userAddress, level);
                }
                
                address ref = users[referrerAddress].x6Matrix[level].currentReferrerAddress;

                if (users[referrerAddress].x6Matrix[level].currentReferrerIndex == 0) {
                    users[ref].x6Matrix[level].secondLevelReferrals[n] = userAddress;
                    emit NewUserPlace(userAddress, ref, level, n+2);
                    buf = 0;
                } else if (users[referrerAddress].x6Matrix[level].currentReferrerIndex == 1) {
                    users[ref].x6Matrix[level].secondLevelReferrals[n+2] = userAddress;
                    emit NewUserPlace(userAddress, ref, level, n+4);
                    buf = 1;
                }

                if (ref == owner) {
                    return sendOwnerETHDividends(userAddress, level);
                }

                sendETHDividends(userAddress, ref, level, ethValue/5);

                address ref2 = users[ref].x6Matrix[level].currentReferrerAddress;

                if (users[ref].x6Matrix[level].currentReferrerIndex == 0) {
                    if (buf == 0) {
                        users[ref2].x6Matrix[level].thirdLevelReferrals[n] = userAddress;
                        emit NewUserPlace(userAddress, ref2, level, n+6);
                        buf = 0;
                    } else {
                        users[ref2].x6Matrix[level].thirdLevelReferrals[n+2] = userAddress;
                        emit NewUserPlace(userAddress, ref2, level, n+8);
                        buf = 1;
                    }
                    
                } else if (users[ref].x6Matrix[level].currentReferrerIndex == 1) {
                    if (buf == 0) {
                        users[ref2].x6Matrix[level].thirdLevelReferrals[n+4] = userAddress;
                        emit NewUserPlace(userAddress, ref2, level, n+10);
                        buf = 2;
                    } else {
                        users[ref2].x6Matrix[level].thirdLevelReferrals[n+6] = userAddress;
                        emit NewUserPlace(userAddress, ref2, level, n+12);
                        buf = 3;
                    }
                }

                if (ref2 == owner) {
                    return sendOwnerETHDividends(userAddress, level);
                }

                sendETHDividends(userAddress, ref2, level, ethValue*3/10);

                address ref3 = users[ref2].x6Matrix[level].currentReferrerAddress;

                if (users[ref2].x6Matrix[level].currentReferrerIndex == 0) {
                    if (buf == 0) {
                        users[ref3].x6Matrix[level].fourthLevelReferrals[n] = userAddress;
                        emit NewUserPlace(userAddress, ref3, level, n+14);
                    } else if (buf == 1) {
                        users[ref3].x6Matrix[level].fourthLevelReferrals[n+2] = userAddress;
                        emit NewUserPlace(userAddress, ref3, level, n+16);
                    } else if (buf == 2) {
                        users[ref3].x6Matrix[level].fourthLevelReferrals[n+4] = userAddress;
                        emit NewUserPlace(userAddress, ref3, level, n+18);
                    } else if (buf == 3) {
                        users[ref3].x6Matrix[level].fourthLevelReferrals[n+6] = userAddress;
                        emit NewUserPlace(userAddress, ref3, level, n+20);
                    }
                    
                } else if (users[ref2].x6Matrix[level].currentReferrerIndex == 1) {
                    if (buf == 0) {
                        users[ref3].x6Matrix[level].fourthLevelReferrals[n+8] = userAddress;
                        emit NewUserPlace(userAddress, ref3, level, n+22);
                    } else if (buf == 1) {
                        users[ref3].x6Matrix[level].fourthLevelReferrals[n+10] = userAddress;
                        emit NewUserPlace(userAddress, ref3, level, n+24);
                    } else if (buf == 2) {
                        users[ref3].x6Matrix[level].fourthLevelReferrals[n+12] = userAddress;
                        emit NewUserPlace(userAddress, ref3, level, n+26);
                    } else if (buf == 3) {
                        users[ref3].x6Matrix[level].fourthLevelReferrals[n+14] = userAddress;
                        emit NewUserPlace(userAddress, ref3, level, n+28);
                    }
                }

                uint total4LevelUsers = 0;

                for(uint i = 0; i < 16; i++) {
                    if (users[ref3].x6Matrix[level].fourthLevelReferrals[i] != address(0)) {
                        total4LevelUsers++;
                    }
                }

                if(total4LevelUsers >= 15) {
                    storeETH(userAddress, ref3, level, ethValue/2);
                } else {
                    if(ref3 == owner) {
                        return sendOwnerETHDividends(userAddress, level);
                        // return address(0);
                    }

                    sendETHDividends(userAddress, ref3, level,  ethValue/2);
                }

                if(total4LevelUsers == 16) {
                    return reinvest(msg.sender, ref3, level);
                }

                return;
            }
    
            n++;
        }

        //---------------------------- SECOND LEVEL -------------------------------------

        n = 0;
        while(true) {
            if (users[referrerAddress].x6Matrix[level].secondLevelReferrals[n] == address(0)) {
                users[referrerAddress].x6Matrix[level].secondLevelReferrals[n] = userAddress;
                emit NewUserPlace(userAddress, referrerAddress, level, n+2);
                
                //move to bottom
                a = n > 1 ? 1 : 0;
                address currentReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[a];
                users[currentReferrer].x6Matrix[level].firstLevelReferrals[n%2] = userAddress; 

                //set current level
                users[userAddress].x6Matrix[level].currentReferrerAddress = currentReferrer;
                users[userAddress].x6Matrix[level].currentReferrerIndex = n%2;
                emit NewUserPlace(userAddress, currentReferrer, level, n%2);

                if (referrerAddress == owner) {
                    return sendOwnerETHDividends(userAddress, level);
                }

                sendETHDividends(userAddress, referrerAddress, level, ethValue/5);
                
                address ref = users[referrerAddress].x6Matrix[level].currentReferrerAddress;

                if (users[referrerAddress].x6Matrix[level].currentReferrerIndex == 0) {
                    users[ref].x6Matrix[level].thirdLevelReferrals[n] = userAddress;
                    emit NewUserPlace(userAddress, ref, level, n+6);
                    buf = 0;
                } else if (users[referrerAddress].x6Matrix[level].currentReferrerIndex == 1) {
                    users[ref].x6Matrix[level].thirdLevelReferrals[n+4] = userAddress;
                    emit NewUserPlace(userAddress, ref, level, n+10);
                    buf = 4; 
                }

                if (ref == owner) {
                    return sendOwnerETHDividends(userAddress, level);
                }

                sendETHDividends(userAddress, ref, level, ethValue*3/10);

                address ref2 = users[ref].x6Matrix[level].currentReferrerAddress;

                if (users[ref].x6Matrix[level].currentReferrerIndex == 0) {
                    if (buf == 0) {
                        users[ref2].x6Matrix[level].fourthLevelReferrals[n] = userAddress;
                        emit NewUserPlace(userAddress, ref2, level, n+14);
                    } else {
                        users[ref2].x6Matrix[level].fourthLevelReferrals[n+4] = userAddress;
                        emit NewUserPlace(userAddress, ref2, level, n+18);
                    }
                    
                } else if (users[ref].x6Matrix[level].currentReferrerIndex == 1) {
                    if (buf == 0) {
                        users[ref2].x6Matrix[level].fourthLevelReferrals[n+8] = userAddress;
                        emit NewUserPlace(userAddress, ref2, level, n+22);
                    } else {
                        users[ref2].x6Matrix[level].fourthLevelReferrals[n+12] = userAddress;
                        emit NewUserPlace(userAddress, ref2, level, n+26);
                    }
                }

                uint total4LevelUsers = 0;

                for (uint i = 0; i < 16; i++) {
                    if (users[ref2].x6Matrix[level].fourthLevelReferrals[i] != address(0)) {
                        total4LevelUsers++;
                    }
                }

                if (total4LevelUsers >= 15) {
                    storeETH(userAddress, ref2, level, ethValue/2);
                } else {
                    if (ref2 == owner) {
                        return sendOwnerETHDividends(userAddress, level);
                    }

                    sendETHDividends(userAddress, ref2, level, ethValue/2);
                }

                if (total4LevelUsers == 16) {
                    return reinvest(msg.sender, ref2, level);
                }

                return;
            }

            if(n == 0) {
                n = 2;
            } else if(n==2) {
                n = 1;
            } else if(n==1) {
                n = 3;
            } else {
                break;
            }
        }

        //---------------------------- THIRD LEVEL -------------------------------------

        n = 0;
        while(true) {
            if (users[referrerAddress].x6Matrix[level].thirdLevelReferrals[n] == address(0)) {
                users[referrerAddress].x6Matrix[level].thirdLevelReferrals[n] = userAddress;
                emit NewUserPlace(userAddress, referrerAddress, level, n+6);

                sendETHDividends(userAddress, referrerAddress, level, ethValue*3/10);
                
                //move to bottom
                a = n > 3 ? 1 : 0;
                address secondLevelReferrer = users[referrerAddress].x6Matrix[level].firstLevelReferrals[a];

                //there
                // uint8 c;
                if(n == 0 || n == 4) {
                    a = 0;
                } else if(n == 2 || n == 6) {
                    a = 2;
                } else if(n == 1 || n == 5) {
                    a = 1;
                } else {
                    a = 3;
                }
                users[secondLevelReferrer].x6Matrix[level].secondLevelReferrals[a] = userAddress;
                emit NewUserPlace(userAddress, secondLevelReferrer, level, a+2);

                sendETHDividends(userAddress, secondLevelReferrer, level, ethValue/5);

                //2, 3, 6, 7 - 1
                a = (n == 2 || n == 3 || n == 6 || n == 7) ? 1 : 0;

                address currentReferrer = users[secondLevelReferrer].x6Matrix[level].firstLevelReferrals[a];
                users[currentReferrer].x6Matrix[level].firstLevelReferrals[n%2] = userAddress; 

                //set current level
                users[userAddress].x6Matrix[level].currentReferrerAddress = currentReferrer;
                users[userAddress].x6Matrix[level].currentReferrerIndex = n%2;
                emit NewUserPlace(userAddress, currentReferrer, level, n%2);

                if (referrerAddress == owner) {
                    return sendOwnerETHDividends(userAddress, level);
                }
                
                address ref = users[referrerAddress].x6Matrix[level].currentReferrerAddress;

                if (users[referrerAddress].x6Matrix[level].currentReferrerIndex == 0) {
                    users[ref].x6Matrix[level].fourthLevelReferrals[n] = userAddress;
                    emit NewUserPlace(userAddress, ref, level, n+14);
                } else if (users[referrerAddress].x6Matrix[level].currentReferrerIndex == 1) {
                    users[ref].x6Matrix[level].fourthLevelReferrals[n+8] = userAddress;
                    emit NewUserPlace(userAddress, ref, level, n+22);
                }

                uint total4LevelUsers = 0;

                for (uint i = 0; i < 16; i++) {
                    if (users[ref].x6Matrix[level].fourthLevelReferrals[i] != address(0)) {
                        total4LevelUsers++;
                    }
                }

                if (total4LevelUsers >= 15) {
                    storeETH(userAddress, ref, level, ethValue/2);
                } else {
                    if (ref == owner) {
                        return sendOwnerETHDividends(userAddress, level);
                    }

                    sendETHDividends(userAddress, ref, level, ethValue/2);
                }

                if (total4LevelUsers == 16) {
                    return reinvest(msg.sender, ref, level);
                }

                return;
            }

            if(n == 0) {
                n = 4;
            } else if(n==4) {
                n = 2;
            } else if(n==2) {
                n = 6;
            } else if(n==6) {
                n = 1;
            } else if(n==1) {
                n = 5;
            } else if(n==5) {
                n = 3;
            } else if(n==3) {
                n = 7;
            } else {
                break;
            }
        }

        //---------------------------- FOURTH LEVEL -------------------------------------
        
        uint total4LevelUsers = 0;
        for (uint i = 0; i < 16; i++) {
            if (referrerMemoryArray.fourthLevelReferrals[i] != address(0)) {
                total4LevelUsers++;
            }
        }

        if (total4LevelUsers >= 14) {
            storeETH(userAddress, referrerAddress, level, ethValue/2);
        } else {
            sendETHDividends(userAddress, referrerAddress, level, ethValue/2);
        }
        
        (bool res, ) = fourthLevelUpdater.delegatecall(abi.encodeWithSignature("updateFourthLevel(address,address,uint8,uint256)", userAddress, referrerAddress, level, ethValue));
        require(res, "smth wrong with 4th level updater");
        
        if(lastReinvestAddress != address(0)) {
            address bufAddress = lastReinvestAddress;
            lastReinvestAddress = address(0);

            return reinvest(msg.sender, bufAddress, level);
        }
        
        if(total4LevelUsers >= 15) {
            reinvest(msg.sender, referrerAddress, level);
        }
    }

    function reinvest(address caller, address userAddress, uint8 level) internal {
        address referrer = findFreeX6Referrer(userAddress, level);

        address[2] memory a2;
        address[4] memory a4;
        address[8] memory a8;
        address[16] memory a16;
        
        users[userAddress].x6Matrix[level].currentReferrerAddress = referrer;
        users[userAddress].x6Matrix[level].firstLevelReferrals = a2;
        users[userAddress].x6Matrix[level].secondLevelReferrals = a4;
        users[userAddress].x6Matrix[level].thirdLevelReferrals = a8;
        users[userAddress].x6Matrix[level].fourthLevelReferrals = a16;

        if (userAddress == owner) {
            xGoldStorage.transferTo(owner, levelPrice[level]);
            // controller.update(owner, level, levelPrice[level], 1);
            emit ReleasedETH(userAddress, owner, level, levelPrice[level]);
        } else {
            xGoldStorage.transferTo(address(this), levelPrice[level]);
            // controller.update(referrer, level, levelPrice[level], 1);
            emit ReleasedETH(userAddress, referrer, level, levelPrice[level]);
        }

        // controller.update(userAddress, level, levelPrice[level], 2);
        emit Reinvest(userAddress, referrer, caller, level);

        if (level != MAX_LEVEL && !users[userAddress].activeX6Levels[level+1]) {
            users[userAddress].x6Matrix[level].blocked = true;
        }

        if(referrer == address(0)) {
            return;
        }

        updateX6Referrer(userAddress, referrer, level, levelPrice[level]);
    }
        
    function findFreeX6Referrer(address userAddress, uint8 level) public view returns(address) {
        if (userAddress == owner) {
            return address(0);
        }

        address userBuf = userAddress;
        uint maxIterations = 50;
        uint iterations = 0;

        // while(true) {
            while(true) {
                ( , address ref, ) = forsage.users(userBuf);

                iterations++;
                if(iterations >= maxIterations || ref == owner) {
                    return owner;
                }

                userBuf = ref;

                if(users[ref].referrer != address(0)) {
                    if(users[userBuf].exists && users[userBuf].activeX6Levels[level]) {
                        return userBuf;
                    }
                    // break;
                }
            }

            // if(users[userBuf].exists && users[userBuf].activeX6Levels[level]) {
            //     return userBuf;
            // }
        // }
    }

    function usersActiveX6Levels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activeX6Levels[level];
    }

    function usersX6Matrix(address userAddress, uint8 level) public view returns(uint, address, address[2] memory, address[4] memory, address[8] memory, address[16] memory) {
        return (users[userAddress].x6Matrix[level].currentReferrerIndex,
                users[userAddress].x6Matrix[level].currentReferrerAddress,
                users[userAddress].x6Matrix[level].firstLevelReferrals,
                users[userAddress].x6Matrix[level].secondLevelReferrals,
                users[userAddress].x6Matrix[level].thirdLevelReferrals,
                users[userAddress].x6Matrix[level].fourthLevelReferrals);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 level) private returns(address) {
        address receiver = userAddress;

        uint8 iter = 0;
        while(true) {
            if(users[receiver].x6Matrix[level].blocked) {
                emit MissedEthReceive(receiver, _from, level);
                receiver = users[receiver].x6Matrix[level].currentReferrerAddress;

                iter++;
                if(iter >= 25) {
                    return owner;
                }
            } else {
                return (receiver);
            }
        }
    }

    function sendETHDividends(address _from, address _to, uint8 _level, uint _value) private {
        address ethReceiver = findEthReceiver(_to, _from, _level);

        if(ethReceiver == owner) {
            multisig.call.value(_value)("");
            return;
        }

        if(!address(uint160(ethReceiver)).send(_value)) {
            if(!address(uint160(ethReceiver)).send(address(this).balance)) {
                multisig.call.value(address(this).balance)("");
                // address(uint160(multisig)).transfer(address(this).balance);
            }   
        }
    }

    function sendOwnerETHDividends(address _from, uint8 level) private {
        return sendETHDividends(_from, owner, level, address(this).balance);
    }

    function storeETH(address from, address to, uint8 level, uint value) private {
        address(xGoldStorage).transfer(value);
        emit StoredETH(from, to, level, value);
    }
    
    function withdrawLostTokens(address tokenAddress) public onlyContractOwner {
        if (tokenAddress == address(0)) {
            address(uint160(multisig)).transfer(address(this).balance);
        } else {
            IERC20(tokenAddress).transfer(multisig, IERC20(tokenAddress).balanceOf(address(this)));
        }
    }

    function withdrawStoredETH(address to, uint value) public onlyContractOwner {
        xGoldStorage.transferTo(to, value);
    }
}