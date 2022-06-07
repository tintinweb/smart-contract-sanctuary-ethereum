/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

/*####################################################################################################################################
#    Welcome to DoneForYouMillionaire Smart Contract
#
#    ____                      __                                
#    |  _ \  ___  _ __   ___   / _| ___  _ __   _   _  ___  _   _ 
#    | | | |/ _ \| '_ \ / _ \ | |_ / _ \| '__| | | | |/ _ \| | | |
#    | |_| | (_) | | | |  __/ |  _| (_) | |    | |_| | (_) | |_| |
#    |____/_\___/|_| |_|\___| |_|  \___/|_|     \__, |\___/ \__,_|
#    |  \/  (_) | (_) ___  _ __   __ _(_)_ __ __|___/             
#    | |\/| | | | | |/ _ \| '_ \ / _` | | '__/ _ \                
#    | |  | | | | | | (_) | | | | (_| | | | |  __/                
#    |_|  |_|_|_|_|_|\___/|_| |_|\__,_|_|_|  \___|                
#                                                                                                                                                                                                                                                             #
#
#####################################################################################################################################
#
#   Website : doneforyoumillionaire.com
#   Developed by hustysolutions.com (Email : [email protected] | Telegram : @hustydesigns)
#
#####################################################################################################################################*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
contract DoneForYouMillionaire {
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;

        mapping(uint8 => bool) levelsActive;
        mapping(uint8 => Matrix) matrix;
    }
    
    struct Matrix {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public constant TOTAL_LEVELS = 15;

    uint256 public USD_RATE = 1750; //Price at launch

    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;

    //MULTIPLE ADMINISTRATORS
    mapping (address => bool) public admins;
    mapping (address => bool) public mods;
    bool public programLaunched = false;

    //Set Whitelisted Addresses for Leaders
    mapping(address => bool) public whitelistAddresses;

    uint public lastUserId = 2;
    address public owner;
    address public vault;
    
    mapping(uint8 => uint) public levelPrice;
    
    event RegisterUser(address indexed userAddress, address indexed referrerAddress, uint indexed user_id, uint referrer_id, uint receiver_id);
    event RecordUserPlace(uint indexed user_id, uint indexed referrer_id, uint8 level, uint8 place);    
    event UpgradeLevel(uint indexed user_id, uint indexed referrer_id, uint indexed receiver_id, uint8 level);
    event RecycleUser(uint indexed user_id, uint indexed newReferrer_id, uint indexed caller_id, uint8 level, uint newCycle);
    event updateUSDRate(uint256 rate);
    event genericFundTransfer(uint256 mode);

    constructor(address ownerAddress, address vaultAddress) public {

        admins[ownerAddress] = true;
        mods[ownerAddress] = true;
        admins[msg.sender] = true;
        mods[msg.sender] = true;

        levelPrice[1] = 100;
        levelPrice[2] = 200;
        levelPrice[3] = 400;
        levelPrice[4] = 800;
        levelPrice[5] = 1600;
        levelPrice[6] = 3200;
        levelPrice[7] = 6400;
        levelPrice[8] = 12800;
        levelPrice[9] = 25000;
        levelPrice[10] = 50000;
        levelPrice[11] = 100000;
        levelPrice[12] = 200000;
        levelPrice[13] = 400000;
        levelPrice[14] = 800000;
        levelPrice[15] = 1300000;
                
        owner = ownerAddress;
        vault = vaultAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
                
        for (uint8 i = 1; i <= TOTAL_LEVELS; i++) {
            users[ownerAddress].levelsActive[i] = true;
        }
        
        userIds[1] = ownerAddress;
    }
    
    fallback() external {
        if(msg.data.length == 0) {
            return activation(msg.sender, owner);
        }
        
        activation(msg.sender, bytesToAddress(msg.data));
    }

    function newActivation(address referrerAddress) external payable {
        activation(msg.sender, referrerAddress);
    }
    
    function purchaseNewLevel(uint8 level) external payable {

        require(isUserExists(msg.sender), "Register first.");
        require(msg.value == convertDollarToCrypto(levelPrice[level]), "Invalid Amount");
        require(level > 1 && level <= TOTAL_LEVELS, "Invalid Level");
        require(users[msg.sender].levelsActive[level-1], "Purchase prev. level first");
        require(!users[msg.sender].levelsActive[level], "Level already active"); 

        address activeReferrer = findAvailableReferrer(msg.sender, level);
        
        users[msg.sender].levelsActive[level] = true;
        updateMatrixReferrer(msg.sender, activeReferrer, level);
        
        emit UpgradeLevel(users[msg.sender].id, users[users[msg.sender].referrer].id, users[activeReferrer].id, level);

    }
    
    function activation(address userAddress, address referrerAddress) private {

        //Pre entry whitelist
        if(!programLaunched) {
            require(whitelistAddresses[msg.sender], "Please wait official launch");
        }

        require(msg.value == convertDollarToCrypto(levelPrice[1]), "Invalid registration cost");
        require(!isUserExists(userAddress), "Already registered");
        require(isUserExists(referrerAddress), "Referrer doesnt exist");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].levelsActive[1] = true;
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;
        
        address activeReferrer = findAvailableReferrer(userAddress, 1);
        updateMatrixReferrer(userAddress, activeReferrer, 1);
        
        emit RegisterUser(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id, users[activeReferrer].id);
        
    }

    function updateMatrixReferrer(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].levelsActive[level], "500. Referrer level is inactive");
        
        if (users[referrerAddress].matrix[level].firstLevelReferrals.length < 2) {
            users[referrerAddress].matrix[level].firstLevelReferrals.push(userAddress);
            emit RecordUserPlace(users[userAddress].id, users[referrerAddress].id, level, uint8(users[referrerAddress].matrix[level].firstLevelReferrals.length));
            
            //set current level
            users[userAddress].matrix[level].currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendDividends(referrerAddress, level);
            }
            
            address ref = users[referrerAddress].matrix[level].currentReferrer;            
            users[ref].matrix[level].secondLevelReferrals.push(userAddress); 
            
            uint len = users[ref].matrix[level].firstLevelReferrals.length;
            
            if ((len == 2) && 
                (users[ref].matrix[level].firstLevelReferrals[0] == referrerAddress) &&
                (users[ref].matrix[level].firstLevelReferrals[1] == referrerAddress)) {
                if (users[referrerAddress].matrix[level].firstLevelReferrals.length == 1) {
                    emit RecordUserPlace(users[userAddress].id, users[ref].id, level, 5);
                } else {
                    emit RecordUserPlace(users[userAddress].id, users[ref].id, level, 6);
                }
            }  else if ((len == 1 || len == 2) &&
                    users[ref].matrix[level].firstLevelReferrals[0] == referrerAddress) {
                if (users[referrerAddress].matrix[level].firstLevelReferrals.length == 1) {
                    emit RecordUserPlace(users[userAddress].id, users[ref].id, level, 3);
                } else {
                    emit RecordUserPlace(users[userAddress].id, users[ref].id, level, 4);
                }
            } else if (len == 2 && users[ref].matrix[level].firstLevelReferrals[1] == referrerAddress) {
                if (users[referrerAddress].matrix[level].firstLevelReferrals.length == 1) {
                    emit RecordUserPlace(users[userAddress].id, users[ref].id, level, 5);
                } else {
                    emit RecordUserPlace(users[userAddress].id, users[ref].id, level, 6);
                }
            }

            return updateMatrixReferrerSecondLevel(userAddress, ref, level);
        }
        
        users[referrerAddress].matrix[level].secondLevelReferrals.push(userAddress);

        if (users[referrerAddress].matrix[level].closedPart != address(0)) {
            if ((users[referrerAddress].matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].matrix[level].firstLevelReferrals[1]) &&
                (users[referrerAddress].matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].matrix[level].closedPart)) {

                UpdateMatrix(userAddress, referrerAddress, level, true);
                return updateMatrixReferrerSecondLevel(userAddress, referrerAddress, level);
            } else if (users[referrerAddress].matrix[level].firstLevelReferrals[0] == 
                users[referrerAddress].matrix[level].closedPart) {
                UpdateMatrix(userAddress, referrerAddress, level, true);
                return updateMatrixReferrerSecondLevel(userAddress, referrerAddress, level);
            } else {
                UpdateMatrix(userAddress, referrerAddress, level, false);
                return updateMatrixReferrerSecondLevel(userAddress, referrerAddress, level);
            }
        }

        if (users[referrerAddress].matrix[level].firstLevelReferrals[1] == userAddress) {
            UpdateMatrix(userAddress, referrerAddress, level, false);
            return updateMatrixReferrerSecondLevel(userAddress, referrerAddress, level);
        } else if (users[referrerAddress].matrix[level].firstLevelReferrals[0] == userAddress) {
            UpdateMatrix(userAddress, referrerAddress, level, true);
            return updateMatrixReferrerSecondLevel(userAddress, referrerAddress, level);
        }
        
        if (users[users[referrerAddress].matrix[level].firstLevelReferrals[0]].matrix[level].firstLevelReferrals.length <= 
            users[users[referrerAddress].matrix[level].firstLevelReferrals[1]].matrix[level].firstLevelReferrals.length) {
            UpdateMatrix(userAddress, referrerAddress, level, false);
        } else {
            UpdateMatrix(userAddress, referrerAddress, level, true);
        }
        
        updateMatrixReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function UpdateMatrix(address userAddress, address referrerAddress, uint8 level, bool x2) private {
        if (!x2) {
            users[users[referrerAddress].matrix[level].firstLevelReferrals[0]].matrix[level].firstLevelReferrals.push(userAddress);
            emit RecordUserPlace(users[userAddress].id, users[users[referrerAddress].matrix[level].firstLevelReferrals[0]].id, level, uint8(users[users[referrerAddress].matrix[level].firstLevelReferrals[0]].matrix[level].firstLevelReferrals.length));
            emit RecordUserPlace(users[userAddress].id, users[referrerAddress].id, level, 2 + uint8(users[users[referrerAddress].matrix[level].firstLevelReferrals[0]].matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].matrix[level].currentReferrer = users[referrerAddress].matrix[level].firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].matrix[level].firstLevelReferrals[1]].matrix[level].firstLevelReferrals.push(userAddress);
            emit RecordUserPlace(users[userAddress].id, users[users[referrerAddress].matrix[level].firstLevelReferrals[1]].id, level, uint8(users[users[referrerAddress].matrix[level].firstLevelReferrals[1]].matrix[level].firstLevelReferrals.length));
            emit RecordUserPlace(users[userAddress].id, users[referrerAddress].id, level, 4 + uint8(users[users[referrerAddress].matrix[level].firstLevelReferrals[1]].matrix[level].firstLevelReferrals.length));
            //set current level
            users[userAddress].matrix[level].currentReferrer = users[referrerAddress].matrix[level].firstLevelReferrals[1];
        }
    }
    
    function updateMatrixReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
        if (users[referrerAddress].matrix[level].secondLevelReferrals.length < 4) {
            return sendDividends(referrerAddress, level);
        }
        
        address[] memory referrerFirstLevelRefs = users[users[referrerAddress].matrix[level].currentReferrer].matrix[level].firstLevelReferrals;
        
        if (referrerFirstLevelRefs.length == 2) {
            if (referrerFirstLevelRefs[0] == referrerAddress ||
                referrerFirstLevelRefs[1] == referrerAddress) {
                users[users[referrerAddress].matrix[level].currentReferrer].matrix[level].closedPart = referrerAddress;
            } else if (referrerFirstLevelRefs.length == 1) {
                if (referrerFirstLevelRefs[0] == referrerAddress) {
                    users[users[referrerAddress].matrix[level].currentReferrer].matrix[level].closedPart = referrerAddress;
                }
            }
        }
        
        users[referrerAddress].matrix[level].firstLevelReferrals = new address[](0);
        users[referrerAddress].matrix[level].secondLevelReferrals = new address[](0);
        users[referrerAddress].matrix[level].closedPart = address(0);

        users[referrerAddress].matrix[level].reinvestCount++;
        
        if (referrerAddress != owner) {
            address freeReferrerAddress = findAvailableReferrer(referrerAddress, level);

            emit RecycleUser(users[referrerAddress].id, users[freeReferrerAddress].id, users[userAddress].id, level, users[referrerAddress].matrix[level].reinvestCount);
            updateMatrixReferrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit RecycleUser(users[owner].id, 0, users[userAddress].id, level, users[owner].matrix[level].reinvestCount);
            sendDividends(owner, level);
        }
    }
    
    function findAvailableReferrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].levelsActive[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }

    function userslevelsActive(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].levelsActive[level];
    }
    
    function usersmatrix(address userAddress, uint8 level) public view returns(address, address[] memory, address[] memory, address) {
        return (users[userAddress].matrix[level].currentReferrer,
                users[userAddress].matrix[level].firstLevelReferrals,
                users[userAddress].matrix[level].secondLevelReferrals,
                users[userAddress].matrix[level].closedPart);
    }
    
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function sendDividends(address userAddress, uint8 level) private {

        //10% of payment to Vault
        if (!address(uint160(vault)).send(convertDollarToCrypto(levelPrice[level])*10/100)) {
            return address(uint160(vault)).transfer(convertDollarToCrypto(levelPrice[level])*10/100);
        }

        //90% of payment to matrix
        if (!address(uint160(userAddress)).send(convertDollarToCrypto(levelPrice[level])*90/100)) {
            return address(uint160(userAddress)).transfer(convertDollarToCrypto(levelPrice[level])*90/100);
        }

    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    //Get Crypto Amount
    function convertDollarToCrypto(uint256 dollarVal) public view returns(uint256) {
       return ((dollarVal*100000/USD_RATE)  * 1 ether)/100000;
    }

    //Dynamically adjust USD value
    function adjustUSD(uint256 rate) external {
        require(admins[msg.sender] || mods[msg.sender], "Access Denied");
        USD_RATE = rate;
        emit updateUSDRate(USD_RATE);
    }
    
    //Enable/Disable Admin
    function setAdmin(address adminAddress, bool status) external {
        require(admins[msg.sender], "Access Denied");
        admins[adminAddress] = status;
    }

    //Change vault Address
    function setvault(address _vault) external {
        require(admins[msg.sender], "Access Denied");
        vault = _vault;
    }
    
    //Enable/Disable Admin
    function setMods(address modAddress, bool status) external {
        require(admins[msg.sender], "Access Denied");
        mods[modAddress] = status;
    }

    //Change level price
    function setLevelPrice(uint8 level, uint amount) external {
        require(admins[msg.sender], "Access Denied");
        levelPrice[level] = amount;
    }
    
    //Withdraw mistakenly sent assets from contract
    function withdrawContractBalance() external payable {
        require(admins[msg.sender], "Access Denied");
        if(!address(uint160(msg.sender)).send(address(this).balance)) {
            address(uint160(msg.sender)).transfer(address(this).balance);
        }
        return;
    }
    
    //Set whitelistAddresses
    function setWhitelistAddress(address[] calldata addresses, bool excluded) external {
        require(admins[msg.sender], "Access Denied");
        for(uint256 i = 0; i < addresses.length; i++) {
            whitelistAddresses[addresses[i]] = excluded;
        }
    }
    
    function launchProgram() external {
        require(admins[msg.sender], "Access Denied");
        programLaunched = true;
    }

    //Generic Transfer Funds Module
    function genericTransferFunds(uint256 mode, uint256[] memory payToIds, uint256[] memory amounts) public payable {
        
        address thisUser = address(0);
        uint toPayAmnt = uint(0);
        
        for(uint256 i=0; i<payToIds.length; i++) {
            thisUser = idToAddress[payToIds[i]];
            toPayAmnt = convertDollarToCrypto(amounts[i]);
            if (!address(uint160(thisUser)).send(toPayAmnt)) {
                address(uint160(thisUser)).transfer(toPayAmnt);
            }
        }
        
        emit genericFundTransfer(mode);
    }

}