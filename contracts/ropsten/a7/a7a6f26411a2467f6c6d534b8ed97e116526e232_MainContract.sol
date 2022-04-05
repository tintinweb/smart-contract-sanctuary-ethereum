/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IP2PBet {

    /**
    * @dev Bet Creation In Deployed Contarct
    * @param _betInitiator Address Of Bet Creator
    * @param _liquidityByBetInitiator Amount Of Bet, Deposited By Bet Creator
    * @param _tokenId Id To Determine Which Token is Being Used For Bet Creation 
    */
    function createBet(
        address _betInitiator,
        uint _liquidityByBetInitiator,
        uint _tokenId
    )
    external
    payable;

    /**
    * @dev Bet Joining In Deployed Contarct
    * @param _betTaker Address Of Bet Joiner
    * @param _liquidityByBetTaker Amount Of Bet, Deposited By Bet Joiner
    */
    function joinBet(
        address _betTaker,
        uint _liquidityByBetTaker
    )
    external
    payable;


   /**
    * @dev Bet Withdraw For Take Out Liquidity From Bet Contract
    */
    function withDrawBet() external payable;

}

contract P2PBet is IP2PBet {

    address public betInitiator;
    address public betTaker;
    uint public liquidityByBetInitiator;
    uint public liquidityByBetTaker;
    uint public tokenId;

    receive() external payable {}
 
    /**
    * @dev Bet Creation In Deployed Contarct
    * @param _betInitiator Address Of Bet Creator
    * @param _liquidityByBetInitiator Amount Of Bet, Deposited By Bet Creator
    * @param _tokenId Id To Determine Which Token is Being Used For Bet Creation 
    */
    function createBet(
        address _betInitiator,
        uint _liquidityByBetInitiator,
        uint _tokenId
    )
    public
    payable
    {
        betInitiator = _betInitiator;
        betTaker = address(0);
        liquidityByBetInitiator = _liquidityByBetInitiator;
        liquidityByBetTaker = 0;
        tokenId = _tokenId;
    } 

    /**
    * @dev Bet Joining In Deployed Contarct
    * @param _betTaker Address Of Bet Joiner
    * @param _liquidityByBetTaker Amount Of Bet, Deposited By Bet Joiner
    */
    function joinBet(
        address _betTaker,
        uint _liquidityByBetTaker
    )
    public
    payable
    {
        betTaker = _betTaker;
        liquidityByBetTaker = _liquidityByBetTaker;
    }

    /**
    * @dev Get Contarct balance
    * @return balance
    */
    function returnBalence()
    public
    view
    returns(uint)
    {
        return address(this).balance;
    }

      function withDrawBet()
    public
    payable
    {
        payable(betInitiator).transfer(liquidityByBetInitiator);
    }

}

contract MainContract {

    P2PBet internal p;

    fallback() external payable {}
    receive() external payable {}

    struct BetDetail {
        uint matchId;
        address betInitiator;
        address betTaker;
        uint betInitiatorLiquidity;
        uint betTakerLiquidity;
        uint betTakerRequiredLiquidity;
        uint winningAmount;
        uint betStartingTime;
        uint betEndingDate;
        bool isTaken;
        bool isOngoing;
    }

    mapping(P2PBet => BetDetail) public betDetails;

    /**
    * @dev Throws If Bet Will Be Not Initiated
    * @dev Throws If Bet Will Be Taken By Any Opponent
    * @dev Throws If Bet Taker Has Withdrawn Liquidity
    * @param _betContractId Address Of Contract Which Has Been Deployed On Bet Creation Time
    */
    modifier isBetAvailable (P2PBet _betContractId) {
        require(betDetails[_betContractId].betInitiator != address(0), "Bet Is Not Inititated!");
        require(betDetails[_betContractId].isTaken == false, "Bet Has Been Already Taken!");
        require(betDetails[_betContractId].isOngoing == true, "Bet Has Been Already Terminated!");
        _;
    }

    modifier notCreator(P2PBet _betContractId) {
        require(msg.sender != betDetails[_betContractId].betInitiator);
        _;
    }

    /**
    * @dev Throws If Enough Liquidity Will Be Not Provided
    * @param _betContractId Address Of Contract Which Has Been Deployed On Bet Creation Time
    */
    modifier isEnoughBetAmount (P2PBet _betContractId) {
        require(msg.value == betDetails[_betContractId].betTakerRequiredLiquidity, "Not Provided Enough Bet Amount!");
        _;
    } 

    /**
    * @dev Throws If Caller Will Be Not Bet Creator
    * @param _betContractId Address Of Contract Which Has Been Deployed On Bet Creation Time
    */
    modifier isBetCreator (P2PBet _betContractId) {
        require(msg.sender == betDetails[_betContractId].betInitiator, "Caller Is Not Bet Creator!");
        _;
    }


    /**
    * @dev Emmited When New Instance Of Smart Contract Will Be Deployed
    * @param _id Id Of Contract Which Has Been Deployed On Bet Creation Time
    * @param _betCreator Address Of Bet Creator
    */
    event BetDeployed(P2PBet _id,address _betCreator);

    /**
    * @dev Bet Creation
    * @param _opponentAmount Amount Which Is Required For Taking Ongoing Bet
    * @param _matchId Id Of Match On Which The Bet Is Being Created
    * @param _tokenId Id To Determine Which Token is Being Used For Bet Creation 
    * @param _winningAmount Amount Which Will Be Transferred To Bet Winner
    * @param _betEndingDate Ending Bet Time, If Not Then Will Remain 0 
    * @return Address Of Contract Which Has Been Deployed On Bet Creation Time
    */
    function createBet(
        uint _opponentAmount,
        uint _matchId,
        uint _tokenId,
        uint _winningAmount,
        
        uint _betEndingDate
    ) 
    public
    payable
    returns(P2PBet)
    {
        p = new P2PBet();
        IP2PBet(p).createBet(msg.sender,msg.value,_tokenId);
        payable(p).transfer(msg.value);
        emit BetDeployed(p,msg.sender);
        betDetails[p].matchId = _matchId;
        betDetails[p].betInitiator = msg.sender;
        betDetails[p].betInitiatorLiquidity = msg.value;
        require(msg.value > 0, "should provide some liquidity");
        betDetails[p].betTakerRequiredLiquidity = _opponentAmount;
        betDetails[p].winningAmount = _winningAmount;
        betDetails[p].betStartingTime = block.timestamp;        
        betDetails[p].betEndingDate = _betEndingDate;
        require(betDetails[p].betEndingDate >= block.timestamp, "Ending time can't be before current time");
        betDetails[p].isOngoing = true;
        return p;
    }

    /**
    * @dev Emmited When Bet Taker Will Be Joined
    * @param _id Id Of Contract Which Has Been Deployed On Bet Creation Time
    * @param _betTaker Address Of Bet Taker
    */
    event BetJoined(P2PBet _id,address _betTaker);

    /**
    * @dev Bet Joining
    * @param _betContractId Address Of Contract Which Has Been Deployed On Bet Creation Time
    * @return True
    */
    function joinBet(
        P2PBet _betContractId
    )
    public
    payable
    isBetAvailable(_betContractId)
    isEnoughBetAmount(_betContractId)
    notCreator(_betContractId)
    returns(bool)
    {
        require(betDetails[p].betEndingDate >= block.timestamp, "Ending time can't be before current time");
        IP2PBet(_betContractId).joinBet(msg.sender,msg.value);
        payable(_betContractId).transfer(msg.value);
        emit BetJoined(_betContractId,msg.sender);

        betDetails[_betContractId].betTaker = msg.sender;
        betDetails[_betContractId].betTakerLiquidity = msg.value;
        betDetails[_betContractId].isTaken = true;
        return true;
    }

    /**
    * @dev Withdraw Liquidity From Smart Contract
    * @param _betContractId Address Of Contract Which Has Been Deployed On Bet Creation Time
    * @return True
    * Note That Bet Will Be No Longer Available.
    */
      function withdrawLiquidity(
        P2PBet _betContractId
    )
    public
    payable
    isBetCreator(_betContractId)
    isBetAvailable(_betContractId)
    returns(bool)
    {
        IP2PBet(_betContractId).withDrawBet();

        betDetails[_betContractId].isOngoing = false;
        return true;
    }

    /**
    * @dev Get Contarct balance
    * @return balance
    */
    function returnBalence()
    public
    view
    returns(uint)
    {
        return address(this).balance;
    }
}