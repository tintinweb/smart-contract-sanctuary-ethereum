/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

// Implementing Contract-for-Difference Arrangements for Hedging Electricity Price Risks of Renewable Generators on a Blockchain Marketplace

// For IEEE Transactions on Industrial Informatics

// Adding the DAI ERC-20 token (stable coin) interface 
interface DaiToken {
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

contract CFD {   
    // Initialization of all storage variables
    // Although fees and penalties are in USD or DAI, gas costs remain in ETH
    
    // address of the contract deployer
    address payable cfdDeployer;
    
    // Creating a variable for the DAI ERC-20 token (stable coin) interface 
    DaiToken daitoken;

    // address of the Market Operator (Oracle).
    address marketOperator;
    
    // Trading period time of the electricity market.
    uint tradingPeriod;

    // Fees for decentralised and incentivized participants 
    // Registration fee paid to the cfdDeployer.
    uint cfdDeployerFee;
    // Fee paid to Oracle for inputting spot price.
    uint oracleInputFee;
    
    // PPA grace period.
    uint gracePeriod;
    
    // Other variables for looping and control of smart contract
    uint idPairCount;
    // A low number is chosen to cap gas costs
    uint numberPairAddresses = 3;
    uint close = 1;
    uint lastDifferenceTime;
    
    // CfD smart contract mappings
    // Determine the typeOfParty during registeration 
    mapping (address => uint) public partyType;
    
    // Map the strikePrice selection
    mapping (address => uint) public strikePrice;
    
    // Map the contractedCapacity selection
    mapping (address => uint) public contractedCapacity;
    
    // Map maintenanceMargin of contracting party
    mapping (address => uint) public maintenanceMargin;
    
    // Map ppaLength of contracting party
    mapping (address => uint) public ppaLength;
    
    // Map terminationPenalty of contracting party
    mapping (address => uint) public terminationPenalty;
    
    // Map terminationPenalty of contracting party
    mapping (address => uint) public minimumEscrowRequirement;
    
    // Track enrolled contracting parties
    mapping (address => uint) public enrolledIntoContract;
    
    // Track the account balance of contracting participants in smart contract
    mapping (address => uint) public accountBalance;

    // Track the account balance of smart contract deployer
    mapping (address => uint) public deployerBalance;

    // Track the account balance of market operator
    mapping (address => uint) public moBalance;
    
    // Track account balance of participants that have expressed their interest to enrol into the smart contract
    mapping (address => uint) public accountExpressionOfInterest;
    
    // Track list of enrolled participants // Close account of expelled participants
    mapping (address => uint) public addressValidity;
    
    // Mappings for looping through enrolled participants 
    mapping (uint => address payable) public idGen;
    mapping (uint => address payable) public idOff;
    mapping (address => uint) public genId;
    mapping (address => uint) public offId;
    
    // Creating events in certain functions for use in front-end/decentralized applications (DApp)
    event EoIDeposit (address indexed from, uint amount);
    event EoIWithdraw (address indexed from, uint amount);
    event addParties (address indexed generator, address indexed offtaker);
    event generatorDeposit (address indexed from, uint amount);
    event offtakerDeposit (address indexed from, uint amount);
    event generatorWithdrawal (address indexed to, uint amount);
    event offtakerWithdrawal (address indexed to, uint amount);
    event winningOraclesFirst (address indexed winningOracleOne, address indexed winningOracleTwo); 
    event winningOraclesSecond (address indexed winningOracleThree, address indexed winningOracleFour);   
    
    // Smart contract modifiers
    // Check if function is called only within the PPA duration of the contracting party
    modifier withinPPA {
    require (block.timestamp < ppaLength[msg.sender]);
    _;
    }
    // Check that at least a pair of contracting parties have registered into the contract 
    modifier participantsEnrolled {
        require (idPairCount > 0);
        _;
    }
    // Check if participant is enrolled & not expelled
    modifier checkValidity {
        require (addressValidity[msg.sender] != close);
        _;
    }

    // Constructor
    /* Chose arbitrary values
    marketOperator = payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
    tradingPeriod = 60 minutes;
    cfdDeployerFee = 10 * 10e18;
    oracleInputFee = 10 * 10e18;
    gracePeriod = 30 days; */
    constructor (address payable _marketOperator, uint _tradingPeriod, uint _fees, uint _gracePeriod) {
        cfdDeployer = payable(msg.sender);
        // Adding the MKR smart contract address where the DAI ERC-20 token resides
        daitoken = DaiToken(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        _marketOperator = payable(marketOperator);
        tradingPeriod = _tradingPeriod * 1 minutes;
        cfdDeployerFee = _fees * 10e18; oracleInputFee = _fees * 10e18;
        gracePeriod = _gracePeriod * 1 days;
     }    
    // Block A: Registering into the CfD smart contract arrangment
    // Expression of Interest (EoI): All parties that want to express their interest to join the smart contract will have to make an EoI deposit
    // Select one (1) for registeration as generator and two (2) for registeration as offtaker
    // Select strikePrice, contractedCapacity, terminationPenalty and ppaLength
    function expressionOfInterestDeposit (uint typeOfParty, uint _strikePrice, uint _contractedCapacity, uint _terminationPenalty, uint _ppaLength) public payable withinPPA checkValidity {
        // Check that party type is either generator or supplier
        require (typeOfParty == 1 || typeOfParty == 2);
        // Check that the calling address has not been enrolled into the contract before
        require (enrolledIntoContract[msg.sender] == 0);
        // Update partyType
        partyType[msg.sender] = typeOfParty;
        // Update strikePrice selection
        strikePrice[msg.sender] = _strikePrice;
        // Update contractedCapacity selection
        contractedCapacity[msg.sender] = _contractedCapacity;
        // Update ppaLength where 31,536,000 seconds are in a non-leap year (365 days)
        ppaLength[msg.sender] = _ppaLength;
        // Update terminationPenalty selection
        terminationPenalty[msg.sender] = _terminationPenalty;
        // Update maintenanceMargin of contracting party
        maintenanceMargin[msg.sender] = strikePrice[msg.sender] * contractedCapacity[msg.sender];
        // Set minimumEscrowRequirement of party which will also be equal to the expressionOfInterestDeposit
        minimumEscrowRequirement [msg.sender] = maintenanceMargin[msg.sender] + terminationPenalty[msg.sender];
        // Update registeration balance
        accountExpressionOfInterest [msg.sender] = accountExpressionOfInterest [msg.sender] + minimumEscrowRequirement [msg.sender];
        // Incoporate the event data in the transaction logs of a DAPP
        emit EoIDeposit (msg.sender, minimumEscrowRequirement [msg.sender]);
        /* Transfer registeration fee to smart contract's account. NB: The ERC-20 token standard already checks that the 
        caller's dai token balance is greater than the registeration fee. If this is not the case, the transaction reverts */  
        daitoken.transferFrom(msg.sender, address(this), minimumEscrowRequirement [msg.sender]);
    }     
    /* Withdraw EoI Deposit: All parties that reevaluates their position and as a result no longer want to enter the contract can withdraw their EoI Deposit
    It is important to note however, that once a participant is added, its EoI deposit becomes locked in the contract. */
    function expressionOfInterestWithdrawal (uint amount) public payable checkValidity {
        // Check that the msg.sender has enough stake to withdraw
        require (accountExpressionOfInterest [msg.sender] >= amount);
        // Update registeration balance
        accountExpressionOfInterest [msg.sender] = accountExpressionOfInterest [msg.sender] - amount;
        // Incoporate the event data in the transaction logs of a DAPP
        emit EoIWithdraw (msg.sender, amount);
        /* Transfer registeration fee to the deployer of the smart contract. NB: The ERC-20 token standard already checks that the 
        caller's dai token balance is greater than the registeration fee. If this is not the case, the transaction reverts */  
        daitoken.transferFrom(address(this), msg.sender, amount);
    }
    // Registeration: registers generator and offtaker addresses, along with their id pair
    function enrolParticipants (address payable gen, address payable off, uint idPair) public payable checkValidity {
        /* Check that: (a) the idPair doesn't exceed the number of allowable pair of participants 
        (b) the idPair is assigned sequentially (i.e where n = 1 and k = allowable pair of participants; 
        the series will be n, n+1, n+2, ... k) (c) idPair is never equals to zero */
        require (idPair <= numberPairAddresses && idPair == (idPairCount + 1) && idPair != 0);
        // Check that the parties registered have selected to be either generator or offtaker
        require (partyType[gen] == 1 && partyType[off] == 2);
        // Check that the offered strike price and contracted capacity corresponds
        require (strikePrice[gen] == strikePrice[off] && contractedCapacity[gen] == contractedCapacity[off]);
        // Check that the offered ppaLength and terminationPenalty corresponds
        require (ppaLength[gen] == ppaLength[off] && terminationPenalty[gen] == terminationPenalty[off]);
        // Check that the address pair is unique and that the addresses have not been expelled from the contract before
        require (gen != off && addressValidity[gen] != close && addressValidity[off] != close);
        // Check that the generator and offtaker have paid the registeration fee
        require (accountExpressionOfInterest [gen] >= minimumEscrowRequirement[gen] && accountExpressionOfInterest [off] >= minimumEscrowRequirement[off]);
        // Check that the calling address has not been enrolled into the contract before
        require (enrolledIntoContract[gen] == 0 && enrolledIntoContract[off] == 0);
        // Update parties' accountBalance in the contract 
        accountBalance[gen] = accountBalance[gen] + accountExpressionOfInterest[gen] - cfdDeployerFee;
        accountBalance[off] = accountBalance[off] + accountExpressionOfInterest[off] - cfdDeployerFee;
        accountExpressionOfInterest[gen] = 0;
        accountExpressionOfInterest[off] = 0;
        // Update account of cfdDeployer
        deployerBalance[cfdDeployer] = deployerBalance[cfdDeployer] + cfdDeployerFee;
        // Effect ppaLength of parties into contract
        ppaLength[gen] = block.timestamp + ppaLength[gen];
        ppaLength[off] = ppaLength[gen];
        // Update enrollment position of contracting parties
        enrolledIntoContract[gen] = 1;
        enrolledIntoContract[off] = 1; 
        // Map the idPair integer to the addresses
        idGen[idPair] = gen;
        idOff[idPair] = off;
        // Map the addresses to a common idPair
        genId [gen] = idPair;
        offId [off] = idPair;
        // Increase the idPairCount by 1
        idPairCount ++;
        emit addParties (gen, off);
    }   
    // Block B: During the CfD smart contract arrangement
    // Deposit: Allow only valid generator addresses to deposit into their internal account in the smart contract
    function depositGenerator (uint idPair, uint amount) public payable withinPPA checkValidity {
        // Check that generator is still 
        // Check if the address corresponds with the idPair assigned 
        require (idGen[idPair] == msg.sender);
        // Update the address' balance in smart contract
        accountBalance [msg.sender] = accountBalance [msg.sender] + amount;
        emit generatorDeposit (msg.sender, amount);
        // Transfer deposit to smart contract's account balance
        daitoken.transferFrom(msg.sender, address(this), amount);
    }   
    // Deposit: Allow only valid offtaker addresses to deposit into their internal account in smart contract
    function depositOfftaker (uint idPair, uint amount) public payable withinPPA checkValidity {
        require (idOff[idPair] == msg.sender);
        accountBalance [msg.sender] = accountBalance [msg.sender] + amount;
        emit offtakerDeposit (msg.sender, amount);
        daitoken.transferFrom(msg.sender, address(this), amount);
    }    
    // Withdraw: Allow only valid generator addresses to withdraw up to the allowable amount from their internal account in smart contract
    // This function can be invoked only during the PPA
    function generatorWithdrawdDuringPPA (uint amount, uint idPair) public payable withinPPA checkValidity {
        require (idGen[idPair] == msg.sender);
        // Check that the amount to be withdrawn does not exceed the allowable amount
        require (accountBalance [idGen[idPair]] >= minimumEscrowRequirement[msg.sender]);
        // Update the address' internal account in smart contract
        accountBalance [idGen[idPair]] = accountBalance [idGen[idPair]] - amount;
        emit generatorWithdrawal (msg.sender, amount);
        // Transfer the withdrawn amount from the smart contract's internal account to the message sender's public address
        daitoken.transferFrom(address(this), msg.sender, amount);
        }       
    // Withdraw: Allow only valid offtaker addresses to withdraw up to the allowable amount from their internal account in smart contract
    // This function can be invoked only during the PPA
    function offtakerWithdrawDuringPPA (uint amount, uint idPair) public payable withinPPA checkValidity {
        require (idOff[idPair] == msg.sender);
        require (accountBalance [idOff[idPair]] >= minimumEscrowRequirement[msg.sender]);
        accountBalance [idOff[idPair]] = accountBalance [idOff[idPair]] - amount;
        emit offtakerWithdrawal (msg.sender, amount);
        daitoken.transferFrom(address(this), msg.sender, amount);
        }
    // Smart contract deployer can withdraw accumulated deployer fees paid by enrolled participants during registeration
    function deployerWithdraw (uint amount) public payable {
    require (msg.sender == cfdDeployer);
    require (deployerBalance[msg.sender] >= amount);
    deployerBalance[msg.sender] = deployerBalance[msg.sender] - amount;
    daitoken.transferFrom(address(this), msg.sender, amount);
    }
    // Market Operator can withdraw accumulated spot price input fees funded by enrolled participants
    function moWithdraw (uint amount) public payable {
        require (moBalance[msg.sender] >= amount);
        moBalance[msg.sender] = moBalance[msg.sender] - amount;
        daitoken.transferFrom(address(this), msg.sender, amount);
    }
   
    // Difference: CfD payout is transferred to the due participant(s) at every trading period and invoked by the market operator    
    function differencePayment (uint spotPrice) public payable {
        // Check that message sender is the Market Operator
        require (msg.sender == marketOperator);
        // Check that this function has not being invoked before the trading Period Time
        require (block.timestamp >= lastDifferenceTime + tradingPeriod);
        // Let the _oracleInputFee be a function of the number of pair of participants
        uint _oracleInputFee = oracleInputFee/(idPairCount * 2);
        // Subtract the _oracleInputFee from each enrolled participant
        for (uint i=1; i<=idPairCount; i++) {
            accountBalance [idGen[i]] -= _oracleInputFee;
            accountBalance [idOff[i]] -= _oracleInputFee;
        }
        // Update the account of the market operator in smart contract
        moBalance [msg.sender] += oracleInputFee;
        // Pay CFD payoff based on the current spotPrice
        for (uint i=1; i<=idPairCount; i++) {
            if (strikePrice [idGen[i]] > spotPrice) {
                uint diff = (strikePrice [idGen[i]] - spotPrice) * contractedCapacity[idGen[i]];
                accountBalance[idGen[i]] = accountBalance [idGen[i]] + diff;
            }
            else if (strikePrice [idGen[i]] < spotPrice) {
                uint diff = (spotPrice - strikePrice [idGen[i]]) * contractedCapacity[idGen[i]];
                accountBalance [idGen[i]] = accountBalance [idGen[i]] - diff;
            }
            else if (strikePrice [idOff[i]] > spotPrice) {
                uint diff = (strikePrice [idOff[i]] - spotPrice) * contractedCapacity[idOff[i]];
                accountBalance [idOff[i]] = accountBalance [idOff[i]] + diff;
            }
            else if (strikePrice [idOff[i]] < spotPrice) {
                uint diff = (spotPrice - strikePrice [idOff[i]]) * contractedCapacity[idOff[i]];
                accountBalance [idOff[i]] = accountBalance [idOff[i]] - diff;
            }
            else {
                revert ();
            }
        }
        lastDifferenceTime = block.timestamp;
    }
    // Block C: Exiting the CfD smart contract arrangement
    //  Exit function for the generator: This should be invoked when a generator intends to voluntarily exit the smart contract
    function activeExitGenerator (uint idPair) public payable withinPPA {
        // Check that the msg.sender corresponds to the idPair @registeration
        require (idGen[idPair] == msg.sender);
        // Create a new address variable that holds the value of the address mapped to idPair
        address payable _holdOfftaker = idOff[idPair];
        /* The non-exiting party receives the termination penalty from the exiting party that shares the same idPair
        On the other hand, the exiting party receives the remainder of its escrow account, save for its terminationPenalty
        penalty deposit */
        accountBalance [idOff[genId[msg.sender]]] = accountBalance [idOff[genId[msg.sender]]] + terminationPenalty[idOff[genId[msg.sender]]];
        accountBalance [msg.sender] = accountBalance [msg.sender] - terminationPenalty[msg.sender];
        // Close pair addresses from accessing the rest of the contract
        addressValidity[idOff[genId[msg.sender]]] = close;
        addressValidity[msg.sender] = close;
        // Re-assign mappings (i.e idPair to addresses and vice-versa)
        for (uint i=idPair; i<=idPairCount; i++) {
            genId[idGen[i+1]] = i;
            offId[idOff[i+1]] = i;
            idGen[i] = idGen[i+1];
            idOff[i] = idOff[i+1];
        }
        // Remove affected idPair from mapping
        genId[msg.sender] = 0;
        offId[_holdOfftaker] = 0;
        idGen[0] = payable(msg.sender);
        idOff[0] = _holdOfftaker;
        idPairCount --;
    }    
    //  Exit function for the offtaker: This should be invoked when an offtaker intends to voluntarily exit the smart contract
    function activeExitOfftaker (uint idPair) public payable withinPPA {
        require (idOff[idPair] == msg.sender);
        address payable _holdGenerator = idGen[idPair];
        accountBalance [idGen[offId[msg.sender]]] = accountBalance [idGen[offId[msg.sender]]] + terminationPenalty[idGen[offId[msg.sender]]];
        accountBalance [msg.sender] = accountBalance [msg.sender] - terminationPenalty[msg.sender];
        addressValidity[msg.sender] = close;
        addressValidity[idGen[offId[msg.sender]]] = close;
        for (uint i=idPair; i<=idPairCount; i++) {
            genId[idGen[i+1]] = i;
            offId[idOff[i+1]] = i;
            idGen[i] = idGen[i+1];
            idOff[i] = idOff[i+1];
        }
        offId[msg.sender] = 0;
        genId[_holdGenerator] = 0;
        idGen[0] = _holdGenerator;
        idOff[0] = payable(msg.sender);
        idPairCount --;
    }  
    // This function can be called by the non-defaulting offtaker counterparty 
    function exitDueToGeneratorDefault (uint idPair) public payable withinPPA {
        require (idOff[idPair] == msg.sender);
        require (accountBalance [idGen[idPair]] < minimumEscrowRequirement[idGen[idPair]]);
        address payable _holdGenerator = idGen[idPair];
        /* The non-defaulting party receives the termination penalty from the exiting party that shares the same idPair
        On the other hand, the defaulting party receives the remainder of its escrow account, save for its terminationPenalty
        penalty deposit */
        accountBalance [idGen[offId[msg.sender]]] = accountBalance [idGen[offId[msg.sender]]] - terminationPenalty [idGen[offId[msg.sender]]];
        accountBalance [msg.sender] = accountBalance [msg.sender] + terminationPenalty[msg.sender];
        // Close pair addresses from accessing the rest of the contract
        addressValidity[idGen[offId[msg.sender]]] = close;
        addressValidity[msg.sender] = close;
         // Re-assign mappings (i.e idPair to addresses and vice-versa)       
        for (uint i=idPair; i<=idPairCount; i++) {
            genId[idGen[i+1]] = i;
            offId[idOff[i+1]] = i;
            idGen[i] = idGen[i+1];
            idOff[i] = idOff[i+1];
        }
        // Remove affected idPair from mapping
        offId[msg.sender] = 0;
        genId[_holdGenerator] = 0;
        idGen[0] = _holdGenerator;
        idOff[0] = payable(msg.sender);
        idPairCount --;
    }       
    // This function can be called by the non-defaulting generator counterparty 
    function exitDueToOfftakerDefault (uint idPair) public payable withinPPA {
            require (idGen[idPair] == msg.sender);
            require (accountBalance [idOff[idPair]] < minimumEscrowRequirement [idOff[idPair]]);
            address payable _holdOfftaker = idOff[idPair];
            accountBalance [idOff[genId[msg.sender]]] = accountBalance [idOff[genId[msg.sender]]] - terminationPenalty[idOff[genId[msg.sender]]];
            accountBalance [msg.sender] = accountBalance [msg.sender] + terminationPenalty[msg.sender];
            addressValidity[idOff[genId[msg.sender]]] = close;
            addressValidity[msg.sender] = close;
            
            for (uint i=idPair; i<=idPairCount; i++) {
                genId[idGen[i+1]] = i;
                offId[idOff[i+1]] = i;
                idGen[i] = idGen[i+1];
                idOff[i] = idOff[i+1];
            }
            offId[_holdOfftaker] = 0;
            genId[msg.sender] = 0;
            idGen[0] = payable(msg.sender);
            idOff[0] = _holdOfftaker;
            idPairCount --;
        }        
    // This is the withdraw function for all participants who have exited the smart contract
    function expelledWithdraw (uint amount) public payable withinPPA {
        require (addressValidity[msg.sender] == close);
        require (accountBalance [msg.sender] >= amount);
        accountBalance[msg.sender] = accountBalance[msg.sender] - amount;
        daitoken.transferFrom(address(this), msg.sender, amount);
    }   
    // Block D: After the CfD smart contract arrangement
    // Withdraw: Allow only valid generator addresses to withdraw up to the allowable amount from their internal account in smart contract
    // This function can be invoked only during the period between post-ppa and pre-end-of-gracePeriod
    function generatorWithdrawAfterPPA (uint amount, uint idPair) public payable checkValidity {
        // Allow address to withdraw following expiration of PPA
        require (block.timestamp > ppaLength[msg.sender] && block.timestamp <= (ppaLength[msg.sender] + gracePeriod)); 
        require (accountBalance [idGen[idPair]] >= amount);
        accountBalance [idGen[idPair]] = accountBalance [idGen[idPair]] - amount;
        emit generatorWithdrawal (msg.sender, amount);
        // Transfer the withdrawn amount from the smart contract's internal account to the message sender's public address
        daitoken.transferFrom(address(this), msg.sender, amount);
        }       
    // Withdraw: Allow only valid offtaker addresses to withdraw up to the allowable amount from their internal account in smart contract
    // This function can be invoked only during the period between post-ppa and pre-end-of-gracePeriod     
    function offtakerWithdrawAfterPPA (uint amount, uint idPair) public payable checkValidity {    
        require (block.timestamp > ppaLength[msg.sender] && block.timestamp <= (ppaLength[msg.sender] + gracePeriod));
        require (accountBalance [idOff[idPair]] >= amount);
        accountBalance [idOff[idPair]] = accountBalance [idOff[idPair]] - amount;
        emit offtakerWithdrawal (msg.sender, amount);
        daitoken.transferFrom(address(this), msg.sender, amount);
    }    
    // This function is invoked by smart contract's deployer if no one is longer registered in the smart contract
    function closeContract () public payable {
        require (idPairCount == 0);
        require (cfdDeployer == msg.sender);
        selfdestruct(payable(msg.sender));
    }
}