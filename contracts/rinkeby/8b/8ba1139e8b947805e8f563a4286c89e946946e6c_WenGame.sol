/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

pragma solidity ^0.5.1;

library SafeMath
{
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        if (a == 0)
            return 0;

        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256)
    {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract WenGame
{
    using SafeMath for *;

    struct Player
    {
        uint256 m_uiBonus;
        address m_adPlayer;
    }
    
    struct Round
    {
        uint256 m_uiBonus;
        uint256 m_uiStartTime;
        uint256 m_uiEndTime;
        uint256 m_uiPlayerCnt;
        address m_adWinner;
    }

    uint256 public c_uiFee              = 0;
    uint256 public c_uiRoundNo          = 0;
    uint256 public c_uiPlayerCnt        = 0;
    address payable public c_adOwner    = 0x0000000000000000000000000000000000000000;

    mapping (uint256 => Round) public c_mapRound;
    mapping (uint256 => mapping (uint256 => Player)) public c_mapPlayer;

    constructor () public
    {
        c_mapRound[1].m_uiBonus     = 0;
        c_mapRound[1].m_uiStartTime = now;
        c_mapRound[1].m_uiEndTime   = c_mapRound[1].m_uiStartTime.add (60);
        c_mapRound[1].m_uiPlayerCnt = 0;
        c_mapRound[1].m_adWinner    = 0x0000000000000000000000000000000000000000;
        c_adOwner                   = msg.sender;
        c_uiRoundNo                 = c_uiRoundNo.add (1);
    }

    modifier onlyHuman()
    {
        address adHuman = msg.sender;
        uint256 uiCodeLength;
        assembly {uiCodeLength := extcodesize (adHuman)}
        require (uiCodeLength == 0, "sorry humans only");
        _;
    }

    modifier isWithinLimits (uint256 _uiEth)
    {
        require (_uiEth >= 1000000000, "pocket lint: not a valid currency");
        require (_uiEth <= 100000000000000000000000, "no vitalik, no");
        _;
    }

    modifier onlyOwner ()
    {
        require (c_adOwner == msg.sender, "only owner can do it");
        _;
    }

    function play() onlyHuman() isWithinLimits(msg.value) public payable
    {
        uint256 uiEth = msg.value;
        uint256 uiNow = now;

        //判斷是否該換下一局了？
        if (c_mapRound[c_uiRoundNo].m_uiEndTime < uiNow)
        {
            //局數加一
            c_uiRoundNo = c_uiRoundNo.add (1);
            //該局初始化
            c_mapRound[c_uiRoundNo].m_uiBonus       = 0;
            c_mapRound[c_uiRoundNo].m_uiStartTime   = uiNow;
            c_mapRound[c_uiRoundNo].m_uiEndTime     = uiNow + 60;
            c_mapRound[c_uiRoundNo].m_uiPlayerCnt   = 0;
            c_mapRound[c_uiRoundNo].m_adWinner      = 0x0000000000000000000000000000000000000000;
        }

        //該局c_mapRound賦值
        c_mapRound[c_uiRoundNo].m_uiBonus     = c_mapRound[c_uiRoundNo].m_uiBonus.add (uiEth.mul (5).div (10)); //50%放入大獎池
        c_mapRound[c_uiRoundNo].m_uiEndTime   = c_mapRound[c_uiRoundNo].m_uiEndTime.add (10); //該局加時
        c_mapRound[c_uiRoundNo].m_uiPlayerCnt = c_mapRound[c_uiRoundNo].m_uiPlayerCnt.add (1); //該局人數加一
        c_mapRound[c_uiRoundNo].m_adWinner    = msg.sender; //最後購買的為贏家
        c_uiPlayerCnt                         = c_mapRound[c_uiRoundNo].m_uiPlayerCnt;

        //40%分給該局所有玩家
        c_mapPlayer[c_uiRoundNo][c_uiPlayerCnt].m_adPlayer = msg.sender;
        for (uint i = 1; i <= c_uiPlayerCnt; i++)
            c_mapPlayer[c_uiRoundNo][i].m_uiBonus = c_mapPlayer[c_uiRoundNo][i].m_uiBonus.add (uiEth.mul (4).div (10).div (c_uiPlayerCnt));

        //10%給我，爽賺
        c_uiFee = c_uiFee.add (uiEth.div (10));
    }

    function ownerWithdrawal () onlyOwner() public
    {
        c_adOwner.transfer (c_uiFee);
        c_uiFee = 0;
    }

    function playerWithdrawal (uint256 _uiRpundNo) onlyHuman() public
    {
        uint uiBonus;
        for (uint i = 1; i <= c_mapRound[_uiRpundNo].m_uiPlayerCnt; i++)
        {
            if (c_mapPlayer[_uiRpundNo][i].m_adPlayer == msg.sender)
            {
                uiBonus = uiBonus.add (c_mapPlayer[_uiRpundNo][i].m_uiBonus);
                c_mapPlayer[_uiRpundNo][i].m_uiBonus = 0;
            }
        }
        msg.sender.transfer (uiBonus);
    }

    function winnerWithdrawal (uint256 _uiRoundNo) onlyHuman() public
    {
        uint256 uiNow = getTime ();
        require (c_mapRound[_uiRoundNo].m_uiEndTime < uiNow, "This round is not over yet.");
        require (c_mapRound[_uiRoundNo].m_adWinner == msg.sender, "Fuck off, looser!");
        msg.sender.transfer (c_mapRound[_uiRoundNo].m_uiBonus);
        c_mapRound[_uiRoundNo].m_uiBonus = 0;
    }

    function getTime () view public returns (uint256 _uiNow)
    {
        uint256  uiNow = now;
        return uiNow;
    }

}