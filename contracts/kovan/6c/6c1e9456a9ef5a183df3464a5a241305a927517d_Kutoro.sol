/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

pragma solidity ^0.8.0;

contract Math {
    function Add(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function Sub (uint a, uint b) public pure returns (uint c) {
        c = a - b;
        require(b <= a);

    }

    function Mult (uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);

    }

    function Div (uint a, uint b) public pure returns (uint c) {
        c = a / b;
        require(b > 0);

    }

    function Precentage (uint a, uint b) public pure returns (uint d) {
        d = b / a;
        return d;
    }

    function calculateVotes (uint tokens,uint voteToTokenRate) public pure returns (uint d){
        d = tokens / voteToTokenRate;
    }
}

//
// Some interface borrowed from https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
//
abstract contract KutoroInterface{
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    /// function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    /// function approve(address spender, uint tokens) virtual public returns (bool success);
    /// function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
}



contract Owned{
    address public owner;
    address public newOwner;

    event OwnershipTransferred (address indexed _from, address indexed _to);

    // Rest ripped
    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Kutoro is KutoroInterface, Math, Owned{
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public _totalBurned;

    address authorized1;
    address authorized2;
    address authorized3;

    bool public isBillboardEnabled;
    string public billboardMessage;
    uint public billboardPrice;

    address payable faucetAddress;
    uint faucetLimit;
    uint public faucetPayout;
    bool public isFaucetEnabled;

    address payable christmasAddress;
    
    uint faucetCut;
    uint christmasCut;
    uint remaining;

    bool public electionHappening;
    uint public electionVotePrice;
    string public electionTitle;
    uint public voteToTokenRate;
    address public ElectionRunner;

    uint public option1Votes;
    uint public option2Votes;
    uint public totalVotes;

    struct vote{
        uint quantityofVotes;
        uint tokensDelegated;
        uint vote;
    }

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping (uint => mapping (address => uint)) mappedAccounts;
    mapping(address => vote) voter;

    constructor() {
        symbol = "KTU1";
        name = "Kutoro_Phase1";
        decimals = 0;
        _totalSupply = 100000000;
        _totalBurned = 0;
        balances[0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52] = _totalSupply;

        authorized1 = 0xa693190103733280E23055BE70C838d9b6708b9a;
        authorized2 = 0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52;
        authorized3 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

        isBillboardEnabled = true;
        billboardMessage = "With Love From Kutoro <3";
        billboardPrice = 1;

        faucetAddress = payable(0xD0872B948CD0C32Add3F1EA62086Caa61C2a6cCb);
        christmasAddress = payable(0x82F58B7451E4c11b29d27416E39E9373d9CB6E67);

        faucetLimit = 1;
        faucetPayout = 1;

        /*
            The cuts are set at what the total should be devided at. For example, 100/faucetcut= 25. That is 25 that will be sent to the faucet
        */
        faucetCut = 4;
        christmasCut = 4;
        remaining = 2;

        electionHappening = false;
        electionVotePrice = 1;
        electionTitle = "Made With Love <3 Kutoro";
        voteToTokenRate = 1;

        option1Votes = 0;
        option2Votes = 0;
        totalVotes = 0;
    }


    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function totalBurned() public view returns (uint) {
        return _totalBurned;
    }

    function balanceOf(address wallet) public override view returns (uint balance) {
        return balances[wallet];
    }

    function faucetBalance() public view returns (uint){
        return balances[faucetAddress];
    }

    function ChristmasBalance() public view returns (uint){
        return balances[christmasAddress];
    }

    function Billboard() public view returns (string memory){
        return billboardMessage;
    }

    function VoterStats(address t) public view returns (vote memory){
        return voter[t];
    }

    function TotalVotes() public view returns (uint){
        return totalVotes;
    }

    function merryChristmas() public view returns (bool success){
        
    }

    function Burn(uint tokens) public returns(bool success){
        require(balances[msg.sender] >= tokens);

        balances[msg.sender] = Sub(balances[msg.sender], tokens);

        _totalSupply = Sub(_totalSupply, tokens);
        _totalBurned = Add(_totalBurned, tokens);
        return true;
    }

    function communityTransfer(uint tokens, uint account, address to) public KutoNoYouDont returns (bool success){
        if(account == 1){
            uint a = tokens / 1;
            require(balances[faucetAddress] >= a);
            balances[faucetAddress] = Sub(balances[faucetAddress], a);

            balances[to] = Add(balances[to], a);
            emit Transfer(faucetAddress, to, a);
            return true;
        } else if (account == 2){
            uint a = tokens / 1;
            require(balances[christmasAddress] >= a);
            balances[christmasAddress] = Sub(balances[christmasAddress], a);

            balances[to] = Add(balances[to], a);
            emit Transfer(christmasAddress, to, a);
            return true;
        } else if (account == 12){
            uint a = tokens / 2;
            require(balances[christmasAddress] >= a);
            require(balances[faucetAddress] >= a);
            balances[christmasAddress] = Sub(balances[christmasAddress], a);
            balances[faucetAddress] = Sub(balances[faucetAddress], a);
            
            balances[to] = Add(balances[to], tokens);
            emit Transfer(faucetAddress, to, a);
            emit Transfer(christmasAddress, to, a);
            return true;
        } else {
            revert("Invalid Account Selected!");
        }
    }

    function communityBurn(uint tokens) public KutoNoYouDont returns (bool success){
        uint a = tokens / 2;

        require(balances[christmasAddress] >= a);
        require(balances[faucetAddress] >= a);

        balances[christmasAddress] = Sub(balances[christmasAddress], a);
        balances[faucetAddress] = Sub(balances[faucetAddress], a);
        _totalSupply = Sub(_totalSupply, a);
        _totalBurned = Add(_totalBurned, a);
        return true;
    }

    function communityMint(uint tokens) public KutoNoYouDont returns (bool success){
        _totalSupply = Add(_totalSupply, tokens);

        uint faucetC = Precentage(faucetCut, tokens);
        uint ChristmasC = Precentage(christmasCut, tokens);
        uint rem = Precentage(remaining, tokens);

        balances[christmasAddress] = Add(balances[christmasAddress], faucetC);
        balances[faucetAddress] = Add(balances[faucetAddress], ChristmasC);
        balances[msg.sender] = Add(balances[msg.sender], rem);
        
        return true;
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = Sub(balances[msg.sender], tokens);
        balances[to] = Add(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function useFaucet() public faucet returns (bool success){
        balances[msg.sender] = Add(balances[msg.sender], faucetPayout);
        balances[faucetAddress] = Sub(balances[faucetAddress], faucetPayout);
        return true;
    }

    function setBillboard(string memory message) public returns (bool success){
        require(isBillboardEnabled == true);
        require(balances[msg.sender] == billboardPrice);
        
        balances[msg.sender] = Sub(balances[msg.sender], billboardPrice);
        billboardMessage = message;
    }

    function configureBillboard(bool toggle, string memory message, uint price) public KutoNoYouDont returns (bool success){
        isBillboardEnabled = toggle;
        billboardMessage = message;
        billboardPrice = price;
    }

    function configureFaucet(bool enabled, uint price, uint limit) public KutoNoYouDont returns (bool success){
        isFaucetEnabled = enabled;
        faucetPayout = price;
        faucetLimit = limit;
        return true;
    }

    function toggleBillboard(bool enabled) public KutoNoYouDont returns (bool success){
        isBillboardEnabled = enabled;
        return true;
    }

    function createElection(string memory title) public KutoNoYouDont returns (bool success){
        require(electionHappening == false);
        electionTitle = title;
        electionHappening = true;
        ElectionRunner = msg.sender;
    }

    function Vote(uint choice, uint tokens) public election returns (bool success){
        require(balances[msg.sender] >= tokens);
        require(choice <= 2);
        uint votes = calculateVotes(tokens, voteToTokenRate);

        if(choice == 1){
            option1Votes = Add(option1Votes, votes);
        } else if(choice == 2){
            option2Votes = Add(option2Votes, votes);
        }
        totalVotes = Add(totalVotes, votes);

        voter[msg.sender].quantityofVotes = votes;
        voter[msg.sender].tokensDelegated = tokens;
        voter[msg.sender].vote = choice;
        
    }

    function endElection() public election returns(bool success){
        require(msg.sender == ElectionRunner);
        require(electionHappening == true);

        electionHappening = false;
        electionTitle = "";
        return true;
    }

    function withdrawlTokensFromElection() public returns (bool success){

    }

    function setAuthorized(int slot, address address1) public KutoNoYouDont returns (bool success){
        require(slot <= 3);
        require(slot > 0);

        if(slot == 1){
            authorized1 = address1;
            return true;
        } else if(slot == 2){
            authorized2 = address1;
            return true;
        } else if(slot == 3){
            authorized3 = address1;
            return true;
        }
    }

    function setAllAuthorized(address address1, address address2, address address3) public KutoNoYouDont returns (bool success){
        authorized1 = address1;
        authorized2 = address2;
        authorized3 = address3;

        return true;
    }

    function transferAnyToken (address tokenAddress, uint tokens) public onlyOwner returns (bool success)  {
        transfer(owner, tokens);
        return KutoroInterface(tokenAddress).transfer(owner, tokens);
    }

    modifier faucet{
        require(isFaucetEnabled == true);
        if(balances[faucetAddress] < faucetPayout){
            revert("Please Refill The Faucet or Vote For A Community Mint");
        }
        _;
    }

    modifier election{
        require(electionHappening == true);
        require(voter[msg.sender].quantityofVotes <= 0);
        _;
    }

    modifier KutoNoYouDont{
        if(msg.sender == authorized1){
        } else if(msg.sender == authorized2){
        } else if(msg.sender == authorized3){
        } else{
            revert("Not Authorized");
        }
        _;
    }
}

/*
        if (doBurn){
            uint toBurn = Precentage(tokens, 1);
            tokens = tokens - toBurn;
            // Burns 1% if selected
            _totalSupply = _totalSupply - toBurn;
            _totalBurned = _totalBurned + toBurn;
            uint tokensBurned = toBurn;
    
            balances[to] = Add(balances[to], tokens);
            string memory result = "Tokens Transfered Successfully: Tokens Burned Successfully.";

            return result;


        } else {
            uint tokensBurned = 0;

            balances[to] = Add(balances[to], tokens);

            string memory result = "Tokens Transfered Successfully: None Burned";
            return result;

        }
*/