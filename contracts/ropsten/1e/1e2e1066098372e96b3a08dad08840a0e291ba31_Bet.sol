/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

pragma solidity^0.4.24;

interface IBEP20 {
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract Bet {
    address public usdtAddr;
    IBEP20 usdt;
    address public cto;
    bool public canReset = true;
    struct Game {
        string hostTeamName;
        string guestTeamName;
        uint16 point;
    }
    Game game;
    struct Player {
        address addr;
        uint amount;
    }
    Player[] teamHost; //zhu
    Player[] teamGuest; //ke
    Player[] teamFlat; //ping
    uint totalHost;
    uint totalGuest;
    uint totalFlat;

    constructor(address _cto, address _usdtAddr) public {
        usdtAddr = _usdtAddr;
        usdt = IBEP20(_usdtAddr);
        cto = _cto;
        totalHost = 0;
        totalGuest = 0;
        canReset = true;
    }

    //(address from,  address recipient, uint256 amount) public returns (bool);
    //function approve(address spender, uint256 value) public returns (bool);


    function getTeamHost() public view returns (string) {
        return game.hostTeamName;
    }
    function getTeamGuest() public view returns (string) {
        return game.guestTeamName;
    }
    function getPoint() public view returns (uint16) {
        return game.point;
    }
    function getTotalHost() public view returns (uint) {
        return totalHost;
    }
    function getTotalGuest() public view returns (uint) {
        return totalGuest;
    }
    function getTotalFlat() public view returns (uint) {
        return totalFlat;
    }

    function balanceOf(address who) external view returns (uint256) {
        return usdt.balanceOf(who);
    }
    
    function setGame(string _hostTeamName, string _guestTeamName, uint16 _point) public {
        require( msg.sender == cto, 'not cto' );
        require( canReset , 'have game playing' );
        delete teamHost;
        delete teamGuest;
        delete teamFlat;
        totalHost = 0;
        totalGuest = 0;
        totalFlat = 0;
        game.hostTeamName = _hostTeamName;
        game.guestTeamName = _guestTeamName;
        game.point = _point;
        canReset = false;
    }

    function stakeIn(uint8 flag, uint256 value) public {
        require(!canReset, 'game not begin');
        require(usdt.balanceOf(msg.sender) >= value);
        usdt.transferFrom(msg.sender, address(this), value);
        Player memory p = Player(msg.sender, value);
        if(flag==1) { //zhu win
            teamHost.push(p);
            totalHost += p.amount;
        }
        else if(flag==2) {  //guest win
            teamGuest.push(p);
            totalGuest += p.amount;
        }
        else { // ping : no win
            teamFlat.push(p);
            totalFlat += p.amount;
        }
    }

    function open(uint8 hostGoal, uint8 guestGoal) payable public {
        require( msg.sender == cto, 'not cto' );
        require( !canReset, 'game set yet' );
        Player p;
        uint i;
        uint totalNums;
        uint totalCtoNums;
        uint totalPlayerNums;
        if( hostGoal*100 - game.point > guestGoal*100) {
            //host win
            //ping tai chou shui 5%
            totalNums = totalGuest+totalFlat; 
            totalPlayerNums = totalNums * 95/100;
            //totalCtoNums = totalNums - totalPlayerNums;
            for(i=0; i<teamHost.length; i++) {
                p = teamHost[i];
                usdt.transfer(p.addr, totalPlayerNums / (p.amount/totalHost) + p.amount);
            }
            usdt.transfer(cto, usdt.balanceOf(address(this)) );
        }
        else if(guestGoal*100 - game.point > hostGoal*100) {
            //guest win
            //ping tai chou shui 5%
            totalNums = totalHost+totalFlat; 
            totalPlayerNums = totalNums * 95/100;
            //totalCtoNums = totalNums - totalPlayerNums;
            for(i=0; i<teamGuest.length; i++) {
                p = teamGuest[i];
                usdt.transfer(p.addr, totalPlayerNums / (p.amount/totalGuest) + p.amount );
            }
            usdt.transfer(cto, usdt.balanceOf(address(this)) );
        }
        else {
            //ping
            totalNums = totalHost+totalGuest;
            totalPlayerNums = totalNums * 95/100;
            //totalCtoNums = totalNums - totalPlayerNums;
            for(i=0; i<teamFlat.length; i++) {
                p = teamFlat[i];
                usdt.transfer(p.addr, totalPlayerNums / (p.amount/totalFlat) + p.amount );
            }
            usdt.transfer(cto, usdt.balanceOf(address(this)) );
        }
        canReset = true;
    }
}