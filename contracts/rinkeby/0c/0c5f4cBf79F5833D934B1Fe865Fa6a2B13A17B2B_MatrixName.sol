/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// File: Matrix.sol



pragma solidity ^0.8.9;

contract MatrixName {

    struct User {
        uint id;
        address referrer;
        uint levelsInRow;
        uint extraBR;
        uint lostedMoney;
        mapping(uint => bool) levelWasActivated;
        mapping(uint => bool) levelIsActive;
        mapping(uint => uint) levelToPlace;
        mapping(uint => uint) levelToAbsolutePlace;
        mapping(uint => uint) usersBeforePayment;
        mapping(uint => bool) Insurance;
    }

    struct Matrix {
        uint MatrixId;
        address mainTableLevel;
        address[4] firstTableLevel;
        address[6] secondTableLevel;
        uint freePlace;
        bool blocked;
        address closedPart;
    }

    struct Level{
    uint freeAbsolutePlace;
    mapping(uint => Matrix) idToMatrix;
    }

    uint public constant LAST_LEVEL = 15;
    uint public lastUserId = 1;

    mapping(uint => Level) public levelToMatrixIds; 
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(address => uint) public balances;
    mapping(uint => uint) public minFreeSecondlevelMatrix;
    mapping(uint => bool) public levelIsAvailable;
    
    mapping(uint => uint) public levelPrice;
    mapping (uint => uint) public BRPercent;
    mapping (uint => uint) public referralsPercent;
    address public owner;


    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed mainLeve, address indexed caller, uint matrix, uint level);
    event Upgrade(address indexed user, uint matrix, uint level);
    event NewUserPlace(address indexed user, uint matrix, uint level, uint place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint matrix, uint level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint matrix, uint level);
    
    
    constructor(address ownerAddress) {
        serValues();
        owner = ownerAddress;
        
        users[ownerAddress].id = 1;
        users[ownerAddress].referrer = ownerAddress;
        users[ownerAddress].levelsInRow = 12;

        Matrix memory matrix = Matrix({
            MatrixId: 1,
            mainTableLevel: ownerAddress,
            firstTableLevel:[ownerAddress,ownerAddress,ownerAddress,ownerAddress],
            secondTableLevel:[address(0),address(0),address(0),address(0),address(0),address(0)],
            freePlace: 6,
            blocked: false,
            closedPart: address(0)
        });
    
       for (uint i = 1; i <= LAST_LEVEL; i++) {
           users[ownerAddress].levelIsActive[i] = true;
           users[ownerAddress].levelToPlace[i] = 1;
           users[ownerAddress].levelToAbsolutePlace[i] = 1;
           levelToMatrixIds[i].idToMatrix[1] = matrix;
           levelToMatrixIds[i].freeAbsolutePlace = 2;
           levelIsAvailable[i] = true;
       }       
    }
    

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }

    function registration(address userAddress, address referrerAddress) private {
        require(msg.value == 100, "registration cost 1");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        lastUserId++;
        users[userAddress].id = lastUserId;
        idToAddress[lastUserId] = userAddress;
        if (referrerAddress == address(0)){referrerAddress = owner;}
        users[userAddress].referrer = referrerAddress;
                
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    	
    function buyNewLevel(uint level) public payable {
        address userAddress = msg.sender;
        require(isUserExists(userAddress), "user is not exists. Register first.");
        require(msg.value == levelPrice[level], "invalid amount");
        require(level > 0 && level <= LAST_LEVEL, "invalid level");
        require(levelIsAvailable[level], "level not available");
        require(!users[userAddress].levelIsActive[level], "level already activated");
                       
        users[userAddress].levelIsActive[level] = true;
        users[userAddress].levelWasActivated[level] = true;

        if (level > 8){
            uint _levelsInRow;
            for (uint i = 1; i <= 15; i++) {
                if (users[userAddress].levelIsActive[i] == false){
                    break;
                }
                _levelsInRow = i;
            }
            users[userAddress].levelsInRow = _levelsInRow;
            if (_levelsInRow > 8){
            users[userAddress].extraBR = BRPercent[_levelsInRow];
            }
        }

        updateMatrix(msg.sender, minFreeSecondlevelMatrix[level], level);
           
        emit Upgrade(msg.sender, minFreeSecondlevelMatrix[level], level);
    }  

     function buyNewLevelWithInsurance(uint level) external payable {
        address userAddress = msg.sender;
        require(isUserExists(userAddress), "user is not exists. Register first.");
        require(msg.value == levelPrice[level] * 5 / 100, "invalid amount");
        require(level > 0 && level <= LAST_LEVEL, "invalid level");
        require(levelIsAvailable[level], "level not available");
        require(!users[userAddress].levelIsActive[level], "level already activated");
                       
        users[userAddress].levelIsActive[level] = true;
        users[userAddress].levelWasActivated[level] = true;
        users[userAddress].Insurance[level] = true;

        if (level > 8){
            uint _levelsInRow;
            for (uint i = 1; i <= 15; i++) {
                if (users[userAddress].levelIsActive[i] == false){
                    break;
                }
                _levelsInRow = i;
            }
            users[userAddress].levelsInRow = _levelsInRow;
            if (_levelsInRow > 8){
            users[userAddress].extraBR = BRPercent[_levelsInRow];
            }
        }

        updateMatrix(msg.sender, minFreeSecondlevelMatrix[level], level);
           
        emit Upgrade(msg.sender, minFreeSecondlevelMatrix[level], level);
    }  

    function updateMatrix(address userAddress, uint MatrixId, uint level) private {
            users[userAddress].levelToPlace[level] = levelToMatrixIds[level].idToMatrix[MatrixId].freePlace;
            users[userAddress].levelToAbsolutePlace[level] = levelToMatrixIds[level].freeAbsolutePlace;

            levelToMatrixIds[level].idToMatrix[MatrixId].secondTableLevel[(levelToMatrixIds[level].idToMatrix[MatrixId].freePlace) - 6] = userAddress;
            levelToMatrixIds[level].idToMatrix[MatrixId].freePlace++;
            levelToMatrixIds[level].freeAbsolutePlace++;
            emit NewUserPlace(userAddress, MatrixId, level, uint(users[userAddress].levelToPlace[level]));

            sendETHDividends(userAddress, MatrixId, level);

            if (levelToMatrixIds[level].idToMatrix[MatrixId].freePlace == 12){
            upgradeMatrix(MatrixId, level);
            }
    }

    function userDataes(uint level, address userAddress) public view returns(uint id, address ref, uint levelsInRow,
    uint extraBR, uint lostedMoney, bool levelWasActivate, bool levelIsActive, uint placeInMatrix, uint absolutePlaceInLevel, uint usersBeforePayment, bool insurance) {
        address ad = userAddress;
        uint Lev = level;
        return (users[ad].id, users[ad].referrer, users[ad].levelsInRow, users[ad].extraBR,
        users[ad].lostedMoney, users[ad].levelWasActivated[Lev], users[ad].levelIsActive[Lev], users[ad].levelToPlace[Lev],
        users[ad].levelToAbsolutePlace[Lev], users[ad].usersBeforePayment[Lev], users[ad].Insurance[Lev]);
    }

    function upgradeMatrix(uint256 MatrixId, uint level) private {
        if (MatrixId == 1) {
           for(uint i = 0; i < 4; i++) {
        Matrix memory matrix = Matrix({
            MatrixId: i+2,
            mainTableLevel: owner,
            firstTableLevel:[address(0),address(0),address(0),address(0)],
            secondTableLevel:[address(0),address(0),address(0),address(0),address(0),address(0)],
            freePlace: 2,
            blocked: false,
            closedPart: address(0)
        });
        levelToMatrixIds[level].idToMatrix[i+2] = matrix;
        users[levelToMatrixIds[level].idToMatrix[i+2].mainTableLevel].levelToPlace[level] = 1;
           }
        } else {
        address mainAddress = levelToMatrixIds[level].idToMatrix[MatrixId].mainTableLevel;
        users[mainAddress].levelIsActive[level] = false;
        users[mainAddress].levelToPlace[level] = 0;
        users[mainAddress].levelToAbsolutePlace[level] = 0;
        uint _levelsInRow = users[mainAddress].levelsInRow;
        if (_levelsInRow > 8 && level <= _levelsInRow) {
            users[mainAddress].levelsInRow = level - 1;
            if(_levelsInRow > 8 ){
            users[mainAddress].extraBR = BRPercent[_levelsInRow];
            } else {
            users[mainAddress].extraBR = 0;           
            }
        }

        levelToMatrixIds[level].idToMatrix[MatrixId].blocked = true;
        
        for(uint i = 0; i < 4; i++) {
            address newCurrent = levelToMatrixIds[level].idToMatrix[MatrixId].firstTableLevel[i];
        Matrix memory matrix = Matrix({
            MatrixId: users[newCurrent].levelToAbsolutePlace[level],
            mainTableLevel: newCurrent,
            firstTableLevel:[address(0),address(0),address(0),address(0)],
            secondTableLevel:[address(0),address(0),address(0),address(0),address(0),address(0)],
            freePlace: 2,
            blocked: false,
            closedPart: address(0)
        });
        uint256 newMatrixId = users[newCurrent].levelToAbsolutePlace[level];
        levelToMatrixIds[level].idToMatrix[newMatrixId] = matrix;
        users[levelToMatrixIds[level].idToMatrix[newMatrixId].mainTableLevel].levelToPlace[level] = 1;
        }
        }

         for (uint i = 0; i < 6; i++) {
            uint minFreeFirstlevelMatrix = minFreeSecondlevelMatrix[level] - 1; 
            uint newfreePlace = levelToMatrixIds[level].idToMatrix[minFreeFirstlevelMatrix].freePlace;
             if (newfreePlace > 5){
                 minFreeFirstlevelMatrix++;
                 newfreePlace = levelToMatrixIds[level].idToMatrix[minFreeFirstlevelMatrix].freePlace;
             }          
             levelToMatrixIds[level].idToMatrix[minFreeFirstlevelMatrix].firstTableLevel[newfreePlace - 2] = levelToMatrixIds[level].idToMatrix[MatrixId].secondTableLevel[i];
             users[levelToMatrixIds[level].idToMatrix[minFreeFirstlevelMatrix].firstTableLevel[newfreePlace - 2]].levelToPlace[level] = newfreePlace;
             levelToMatrixIds[level].idToMatrix[minFreeFirstlevelMatrix].freePlace++;
         }
         minFreeSecondlevelMatrix[level]++;
    }

        
    function usersActiveLevels(address userAddress, uint level) public view returns(bool) {
        return users[userAddress].levelIsActive[level];
    }

    function MatrixStructure(uint256 MatrixId, uint level) public view returns(address, address[4] memory, address[6] memory, bool, address) {
        return (levelToMatrixIds[level].idToMatrix[MatrixId].mainTableLevel,
               levelToMatrixIds[level].idToMatrix[MatrixId].firstTableLevel,
               levelToMatrixIds[level].idToMatrix[MatrixId].secondTableLevel,
               levelToMatrixIds[level].idToMatrix[MatrixId].blocked,
               levelToMatrixIds[level].idToMatrix[MatrixId].closedPart);
    }
    
    function isUserExists(address userAddress) public view returns (bool) {
        return (users[userAddress].id != 0);
    }


    function sendETHDividends(address userAddress, uint256 MatrixId, uint level) private {
        address payable receiver;
        if (users[userAddress].levelToPlace[level] == 8 || users[userAddress].levelToPlace[level] == 11) {
              receiver = payable(levelToMatrixIds[level].idToMatrix[MatrixId].mainTableLevel);
        } else {
            if (users[userAddress].levelToPlace[level] < 8 ){
              receiver = payable(levelToMatrixIds[level].idToMatrix[MatrixId].firstTableLevel[users[userAddress].levelToPlace[level] - 6]);
            } else {
              receiver = payable(levelToMatrixIds[level].idToMatrix[MatrixId].firstTableLevel[users[userAddress].levelToPlace[level] - 7]);
            }
            users[receiver].Insurance[level] = false;
        }
         uint BR;
             if (users[receiver].extraBR > 0){
                 BR = users[receiver].extraBR;
                 } else {
                     BR = BRPercent[level];
                 }
        receiver.transfer(msg.value*BR/100);

        address nextReferrer = userAddress;
        uint i = 1;
        while (i<= 7){
        address payable _referrer = payable(users[nextReferrer].referrer);
        if (users[_referrer].levelWasActivated[level]){
        _referrer.transfer(msg.value*referralsPercent[i]/100);
        i++;
        } else {
            users[_referrer].lostedMoney = users[_referrer].lostedMoney + msg.value*referralsPercent[i]/100;
        }
        nextReferrer = _referrer;
        }

        address payable _marketing = payable(owner);
        uint marketingPercent = (77 - BR);
        _marketing.transfer(msg.value*marketingPercent/100);
    }

    function paymentOfInsurance() external {
        for (uint i = 2; i <=lastUserId; i++) {
            uint InsurancePayment = 0;
            for (uint j = 1; j <= LAST_LEVEL; j++) {
                if (users[idToAddress[i]].Insurance[j])
                {
                   InsurancePayment = InsurancePayment + levelPrice[j] * 20 / 100; 
                }
            }
            if (InsurancePayment > 0)
            {
                address payable receiver = payable(idToAddress[i]);
                receiver.transfer(InsurancePayment);
            }
        }
    }

    function serValues() private {
        BRPercent[1] = 55;
        BRPercent[2] = 55;
        BRPercent[3] = 55;
        BRPercent[4] = 55;
        BRPercent[5] = 51;
        BRPercent[6] = 52;
        BRPercent[7] = 53;
        BRPercent[8] = 54;
        BRPercent[9] = 56;
        BRPercent[10] = 58;
        BRPercent[11] = 61;
        BRPercent[12] = 64;
        BRPercent[13] = 67;
        BRPercent[14] = 71;
        BRPercent[15] = 75;

        referralsPercent[1] = 8;
        referralsPercent[2] = 5;
        referralsPercent[3] = 3;
        referralsPercent[4] = 2;
        referralsPercent[5] = 2;
        referralsPercent[6] = 2;
        referralsPercent[7] = 1;
        
        for (uint i = 1; i <= LAST_LEVEL; i++) {
            levelPrice[i] = 100;
            minFreeSecondlevelMatrix[i] = 1;
        }
    }
}