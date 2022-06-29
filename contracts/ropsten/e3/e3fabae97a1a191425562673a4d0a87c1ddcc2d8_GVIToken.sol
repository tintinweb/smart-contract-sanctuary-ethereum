// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Strings.sol";

contract GVIToken is ERC20 {
    struct GameMaker {
        string name;
        uint256 code;

        uint256 balance; // total token burn in game
        uint256 lastMintTime; // token can mint

        uint256 capitalPercentage; // all = 100%
        string hisCap;
        uint256 ownerBalance; // total token burn in game
        //uint256 profitPercentage; // < 30%
    }

    //config
    mapping(address => GameMaker) gameMakers;
    address[] admins;

    //owner
    address private owner;
    uint256 startTimeMint;

    //all
    mapping(address => uint256) balances;

    //constant
    uint256 _SECOND_OF_YEAR = 31536000; //365 day
    uint256 _SECOND_OF_DAY = 86400;
    uint256 _MINT_FROM = 100000 * (10 ** uint256(decimals())); //
    uint _MAX_PERCENT_MINT = 1825; // MINT FOR FIRST YEAR 18.25%
    uint256[] _TOTAL_SUPPLY_SEGMENT = [_MINT_FROM,305910286465544837288009,458832142469272957454728,530546865473545702369028,586053806169640448889881,647368000976434311344172,715097017161791585557573,789911986972470808597346,872554257937318392647304,963842738939317005779899,1064682014849305078165462];

    constructor() ERC20("GVI Token", "GVI") {
        owner = msg.sender;
        startTimeMint = block.timestamp;
        _mint(owner, _MINT_FROM);
    }

    //function for owner --- start ---
    function addGameMaker(address inAdminAddress, string memory inName, uint256 inCode) public {
        require(msg.sender == owner, "UnAuth");
        require(!findAdmin(inAdminAddress), "admin already exist");
        // require(inProfitPercentage > 0 && inProfitPercentage <= 30, "profitPercentage incorrect");
        require(inCode > 0, "code incorrect");
        require(!checkCode(inCode), "code already exist");

        admins.push(inAdminAddress);
        gameMakers[inAdminAddress].name = inName;
        // gameMakers[inAdminAddress].profitPercentage = inProfitPercentage;
        gameMakers[inAdminAddress].code = inCode; 
    }

    function deposit(address inPlayerAddress, uint256 inAmount, uint256 inCode) public {
        require(msg.sender == owner, "UnAuth");
        gameMakers[findGameMakers(inCode)].balance += inAmount*90/100;
        _transfer(inPlayerAddress, owner, inAmount*10/100);
        _burn(msg.sender, inAmount*90/100);
    }

    function updateCapitalPercentage(address inAdminAddress, uint inCapitalPercentage) public {
        require(msg.sender == owner, "UnAuth");
        require(findAdmin(inAdminAddress), "inAdminAddress incorrect");
        uint totalCap = 0;
        uint256 t = block.timestamp;

        for(uint i = 0; i < admins.length; i++) {
            if(admins[i] != inAdminAddress) {
                totalCap += gameMakers[admins[i]].capitalPercentage;
            }
        }

        require((totalCap + inCapitalPercentage) <= 100, "inCapitalPercentage incorrect");

        if(gameMakers[inAdminAddress].capitalPercentage > 0) {
            gameMakers[inAdminAddress].balance += timeMint(inAdminAddress, t);
        }
        
        gameMakers[inAdminAddress].lastMintTime = t;
        gameMakers[inAdminAddress].capitalPercentage = inCapitalPercentage;
        string memory tmp = string(abi.encodePacked(gameMakers[inAdminAddress].hisCap, Strings.toString(t), ",", Strings.toString(gameMakers[inAdminAddress].capitalPercentage) , ";"));
        gameMakers[inAdminAddress].hisCap = tmp;
    }

    function getGameMaker() public view returns (string memory) {
        require(msg.sender == owner, "UnAuth");
        string memory rs = "";
        for(uint i = 0; i < admins.length; i++) {
            rs = string(abi.encodePacked(rs, "NAME=" , gameMakers[admins[i]].name, 
           ",ADD=" , toHexString(admins[i]), 
           ",COD=" , Strings.toString(gameMakers[admins[i]].code),
           ",CAP=" , Strings.toString(gameMakers[admins[i]].capitalPercentage),";"));
        }
        return rs;
    }

    function rmGameMaker(address inAdminAddress, uint256 inCode) public {
        require(msg.sender == owner, "UnAuth");
        require(findAdmin(inAdminAddress), "inAdminAddress incorrect");
        require(gameMakers[inAdminAddress].code == inCode, "inCode incorrect");
        require(admins.length > 0, "admins is empty");
        uint256 bl = balanceOfMint(inAdminAddress, block.timestamp);

        for(uint i = 0; i < admins.length; i++) {
            if(admins[i] == inAdminAddress) {
                admins[i] = admins[admins.length - 1];
                admins.pop();
                break;
            }
        }

        gameMakers[inAdminAddress].code = 0;
        gameMakers[inAdminAddress].capitalPercentage = 0;
        gameMakers[inAdminAddress].hisCap = "";
        gameMakers[inAdminAddress].lastMintTime = 0;
        _mint(inAdminAddress, bl);
    }

    function mintTo(address inMintTo, uint256 inAmount) public {
        require(msg.sender == owner, "UnAuth");
        require(gameMakers[owner].ownerBalance >= inAmount, "not enough money");

        gameMakers[owner].ownerBalance -= inAmount;
        _mint(inMintTo, inAmount);
    }

    function ownerBalance() public view returns (uint256) {
        require(msg.sender == owner, "UnAuth");
        return  gameMakers[owner].ownerBalance;
    }
    //function for owner --- end --- ---------------------------------------------------------------------------------------- //


    //function for admin game --- start --- //

    function bonus(address inAddressGamer, uint256 inCode, uint256 inAmount) public {
        require(findAdmin(msg.sender), "UnAuth");
        require(gameMakers[msg.sender].code == inCode, "inCode incorrect");
        require(findCode(msg.sender) == inCode, "inCode incorrect");
        require(gameMakers[msg.sender].balance >= inAmount, "not enough money");

        gameMakers[msg.sender].balance -= inAmount;
        _mint(inAddressGamer, inAmount);
    }

    //
    function hisCap() public view returns (string memory) {
        require(findAdmin(msg.sender), "UnAuth");
        require(gameMakers[msg.sender].code > 0, "request error code = 1001");
        return gameMakers[msg.sender].hisCap;
    }

    function gameEstimateBalance(uint256 balanceTo) public view returns (uint256) {
        require(findAdmin(msg.sender), "UnAuth");
        require(gameMakers[msg.sender].code > 0, "request error code = 1001");
        require(gameMakers[msg.sender].lastMintTime > startTimeMint, "request error code = 1002");
 
        return balanceOfMint(msg.sender, balanceTo);
    }

    function gameMint(uint256 inCode) public {
        require(findAdmin(msg.sender), "UnAuth");
        require(gameMakers[msg.sender].code > 0, "request error code = 1001");
        require(gameMakers[msg.sender].code == inCode, "request error code = 1003");
        require(gameMakers[msg.sender].lastMintTime > startTimeMint, "request error code = 1002");

        uint256 t = block.timestamp;
        gameMakers[msg.sender].balance += timeMint(msg.sender, t);

        gameMakers[msg.sender].lastMintTime = t;
    }

    function gameBalance() public view returns (uint256) {
        require(findAdmin(msg.sender), "UnAuth");
        require(gameMakers[msg.sender].code > 0, "request error code = 1001");
        require(gameMakers[msg.sender].lastMintTime > startTimeMint, "request error code = 1002");
 
        return gameMakers[msg.sender].balance;
    }
    //function for admin game --- end --- ---------------------------------------------------------------------------------------- //

    //function for players --- start --- //
    function writeToPay(uint256 inAmount, uint256 inCode) public {
        require(balanceOf(msg.sender) >= inAmount, "not enough money");
        require(checkCode(inCode), "inCode incorrect");

        gameMakers[owner].ownerBalance += inAmount*10/100;
        gameMakers[findGameMakers(inCode)].balance += inAmount*90/100;

        _burn(msg.sender, inAmount);
    }
    //function for players --- end --- ---------------------------------------------------------------------------------------- //


    //util --------------------------------------------------------------------------------------------------------------------------------------- //
    // find in list admins -> default result == false 
    function findAdmin(address inAddr) private view returns (bool) {
        bool rs = false;
        if(admins.length > 0) {
            for(uint i = 0; i < admins.length; i++) {
                if(inAddr == admins[i]) {
                    rs = true;
                    break;
                }
            }
        }
        return rs;
    }

    //GVI mint on second
    function mintSecond(uint year) public view returns (uint256) {
        // uint256 maxSub = _MINT_FROM;
        uint256 maxSub = getLimitSupply(year/10);

        uint tmp = year/10;
        uint start = 0;
        if(tmp < _TOTAL_SUPPLY_SEGMENT.length) {
            start = tmp*10;
        } else {
            start = (_TOTAL_SUPPLY_SEGMENT.length - 1)*10;
        }
        year++;

        uint256 rs = 0;
        for(uint i = start; i < year; i++) {
            if(i < 28){
                rs =  (maxSub * 1825 * 9**i) / (10000*10**i);
                maxSub += rs;
            } else {
                rs =  maxSub * 1/100;
                maxSub += rs;
            }
        }
        return rs/_SECOND_OF_YEAR;
    }

    //
    function getLimitSupply(uint s) private view returns (uint256) {
        if(s < _TOTAL_SUPPLY_SEGMENT.length) {
            return _TOTAL_SUPPLY_SEGMENT[s];
        } else {
            return _TOTAL_SUPPLY_SEGMENT[_TOTAL_SUPPLY_SEGMENT.length - 1];
        }
    }

    //find code gameMakers by admin address -> default result = 0
    function findCode(address inAddress) private view returns (uint256) {
        uint256 rs;
        if(admins.length > 0) {
            for(uint i = 0; i < admins.length; i++) {
                if(inAddress == admins[i]) {
                    rs = gameMakers[inAddress].code;
                    break;
                }
            }
        }
        return rs;
    }

    //find code gameMakers by admin address -> default result = 0
    function findGameMakers(uint256 inCode) private view returns (address) {
        address rs;
        if(admins.length > 0) {
            for(uint i = 0; i < admins.length; i++) {
                if(gameMakers[admins[i]].code == inCode) {
                    rs = admins[i];
                    break;
                }
            }
        }
        return rs;
    }

    //
    function checkCode(uint256 inCode) private view returns (bool) {
        bool rs = false;
        if(admins.length > 0) {
            for(uint i = 0; i < admins.length; i++) {
                if(gameMakers[admins[i]].code == inCode) {
                    rs = true;
                    break;
                }
            }
        }
        return rs;
    }

    function balanceOfMint(address addr, uint256 balanceTo) private view returns (uint256) {
        if(gameMakers[addr].lastMintTime < startTimeMint || gameMakers[addr].code == 0) {
            return 0;
        }

        uint256 rs = gameMakers[addr].balance;
        rs += timeMint(addr, balanceTo);
        
        return rs;
    }

    function timeMint(address addr, uint256 balanceTo) private view returns (uint256) {
        uint256 rs = 0;
        if(balanceTo > gameMakers[addr].lastMintTime) {
            uint yFrom = (gameMakers[addr].lastMintTime - startTimeMint)/_SECOND_OF_YEAR;
            uint yTo = (balanceTo - startTimeMint)/_SECOND_OF_YEAR;
            if(yTo >= yFrom) {
                uint256 am = 0;
                uint256 startIn = gameMakers[addr].lastMintTime;
                for(uint i = yFrom; i< yTo + 1; i++) {
                    uint256 limitTime = startTimeMint + _SECOND_OF_YEAR*(i + 1);
                    if(balanceTo >= limitTime) {
                        am += (limitTime - startIn) * mintSecond(i);
                        startIn = limitTime;
                    } else {
                        am += (balanceTo - startIn) * mintSecond(i);
                        startIn = balanceTo;
                    }
                }

                rs += am*gameMakers[addr].capitalPercentage/100;
            }
        }
        return rs;
    }

    function toHexString(address addr) internal pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(addr)), 20);
    }
}