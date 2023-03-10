/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
contract Vote {
    address public owner;

    
    string private name;
    string private symbol;
    uint256 private decimal;
    uint private totalSupply;

        struct votes {
            uint256 totalvote;

        }


    // mapping (address => uint256) public Holders;
    mapping (address => uint256) public balanceOf;
    mapping (address => votes) public candidateVotes;
    
    uint256 totalVotes;

    address[] public candidates;
    address[] public Admin;
    mapping(address => uint256) public voted;
    mapping(address => mapping(address => uint256)) public votefor;
    bool votingactive;












    event transfer_(address indexed from, address to, uint amount);
    event _mint(address indexed from, address to, uint amount);

    // SAVES THE OWNER ADDRESS, TOKEN NAME, DECIMAL AND SYMBOL TO THE BYTECODE  
    constructor(string memory _name, string memory _symbol){
        owner = msg.sender;
        Admin.push(owner);

        name = _name;
        symbol = _symbol;
        decimal = 1e8;

        mint(owner , 100);

    }
    modifier onlyowner {
        require(msg.sender == owner);

        _;
        
    }
     modifier onlyAdmin(address _admin) {
        bool valid;
        for (uint256 i = 0; i < Admin.length; i++) {
            if (_admin == Admin[i]) {
                valid = true;
            }
        }
        require(valid, "not admin");
        _;
    }
      /// @notice THIS RETURNS THE TOKEN NAME
    function name_() public view returns(string memory){
        return name;
    }

    /// @notice THIS RETURNS THE TOKEN SYMBOL
    function symbol_() public view returns(string memory){
        return symbol;
    }

    /// @notice THIS RETURNS THE TOKEN DECIMAL
    function _decimal() public view returns(uint256){
        return decimal;
    }


    /// @notice THIS RETURNS THE TOKEN'S TOTAL SUPPLY
    function _totalSupply() public view returns(uint256){
        return totalSupply;
    }

    /// @custom:bancesofallowance  GETS THE BALANCE TOKEN OF EACH TOKEN HOLDER
    function _balanceOf(address who) public view returns(uint256){
        return balanceOf[who];
    }


     function addAdmin(address _newAdmin) external onlyAdmin (msg.sender) {
        require(Admin.length <= 3);
        Admin.push(_newAdmin);
       
    }
   function getAdmin(address _adminaddress) public view returns(bool _isadmin) {
    for(uint i = 0; i <= Admin.length; i++) {
        if (_adminaddress == Admin[i]) {
            _isadmin = true;
            return _isadmin;
        }
    }
    _isadmin = false;
    return _isadmin;
}


    /// @custom:transfer ALLOWS TOKEN HOLDERS TO TRANSFER THEIR TOKENS TO OTHERS
    /// @notice THIS IS THE FUNCTION CALLED WHEN A TRANSFER IS MADE
    function transfer(address _to, uint amount)public {
        _transfer(msg.sender, _to, amount);
        emit transfer_(msg.sender, _to, amount);

    }

    /// @dev KEEP TRACK OF STATE CHANGES AFTER EVERY TRANSACTION
    /// @notice THIS FUNCTION CONTAINS THE MAIN TRANSFER LOGIC
    function _transfer(address from, address to, uint amount) internal {
        require(balanceOf[from] >= amount, "insufficient fund");
        require(to != address(0), "transferr to address(0)");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }






    /// @notice this function creates new tokens and increases the total supply variable
    // MINT/PRODUCTION NEW TOKENS ONLY BY OWNER 
    function mint (address to, uint amount) public {
        require(msg.sender == owner, "Access Denied");
        require(to != address(0), "transferr to address(0)");
        totalSupply += amount;
        balanceOf[to] += amount * _decimal();
        // emit _mint(address(0), to, amount);


    }

    /// @notice this function burns tokens 
    /// @custom:burn DESTROY/BURN TOKENS BY ANY TOKEN HOLDER BURNING 90% AND SENDS 10% TO THE TOKEN OWNER
    function burn(uint256 _value) public returns (bool burnt) {
            require(balanceOf[msg.sender] >= _value, "insufficient balance");
            // uint256 burning  = _value * decimal;
            // uint256 sendtoowner = ((burning * 10)/100);
            // uint256 amounttoburn = _value - sendtoowner;
            totalSupply -= _value;
            // _transfer(msg.sender, owner, sendtoowner);
            burntozero(address(0), _value);


            burnt = true;
        }


    /// @custom:handleburnttoken SEND BURNT TOKENS TO THE ZERO ADDRESS
    function burntozero(address to, uint amount) internal {

            to = address(0);
        balanceOf[to] += amount;
    }  


    /// THE VOTING LOGIC


    function vote(address _candidate, uint256 _Votedtoken) public returns (bool) {
        uint256 _noOfVote = _Votedtoken * 1e8; 
        require(votingactive);
        require(balanceOf[msg.sender] >= _noOfVote, "not enough token");
        require(voted[msg.sender] < 3, "max vote excedeed");
        bool valid;
        for (uint i = 0; i <= candidates.length; i++) {
            if (_candidate == candidates[i]) {
                valid = true;
                break;
            }
        }
        require(valid, "choosen candidate not registered");
        require(_noOfVote <= _noOfVote * 3, "max vote reached");
        balanceOf[msg.sender] -= _noOfVote;
        votefor[msg.sender][_candidate] += _noOfVote;
        voted[msg.sender] += 1; 
        candidateVotes[_candidate].totalvote += _noOfVote;

        totalVotes += _noOfVote;

        burn(_noOfVote);

        return true;
}

function getWinner() public view returns (address, uint) {
    address winningCandidate;
    uint winningVoteCount = 0;
    for (uint p = 0; p < candidates.length; p++) {
        address candidateAddress = candidates[p];
        uint candidateVoteCount = candidateVotes[candidateAddress].totalvote;
        if (candidateVoteCount > winningVoteCount) {
            winningCandidate = candidateAddress;
            winningVoteCount = candidateVoteCount;
        }
    }
    return (winningCandidate, winningVoteCount);
}

function getTotalVotes() public view returns (uint) {
        return totalVotes;
    }

 
function getCandidateVotes() public view returns (address[] memory, uint[] memory) {
    address[] memory candidateAddresses = new address[](candidates.length);
    uint[] memory voteCounts = new uint[](candidates.length);
    for (uint i = 0; i < candidates.length; i++) {
        candidateAddresses[i] = candidates[i];
        voteCounts[i] = candidateVotes[candidates[i]].totalvote;
    }
    return (candidateAddresses, voteCounts);
}


function getcandidate(address _checkk) public view returns(bool _iscandidate){
     for(uint i = 0; i <= candidates.length; i++) {
        if(_checkk == candidates[i]){
            _iscandidate = true;
        }
        else{
            _iscandidate = false;
        }
    }
}

    function getCandidateVotes(address _candidate) public view returns (uint256 ) {
        for (uint i = 0; i< candidates.length; i++) {
          _candidate = candidates[i];
        }
        return candidateVotes[_candidate].totalvote;
}





    function registerCandidate(address _candidateaddress) public onlyAdmin(msg.sender) returns (bool candidateregistered) {
        require(candidates.length < 3, "maximum candidates reached");
        for (uint i = 0; i < candidates.length; i++) {
            if (_candidateaddress == candidates[i]) {
                candidateregistered = true;
            }
             }
        require(candidateregistered == false);
        candidates.push(_candidateaddress);

        votingactive = true;

    return true;
    }

         
function registerCandidate(address _candidateAddress1, address _candidateAddress2, address _candidateAddress3) public onlyAdmin(msg.sender) returns (bool) {
    require(candidates.length < 3, "maximum candidates reached");
    for (uint i = 0; i < candidates.length; i++) {
        if (_candidateAddress1 == candidates[i] || _candidateAddress2 == candidates[i] || _candidateAddress3 == candidates[i]) {
            return false;
        }
    }
    candidates.push(_candidateAddress1);
    candidates.push(_candidateAddress2);
    candidates.push(_candidateAddress3);
    votingactive = true;
    return true;

}

   function endVoting() public onlyAdmin(msg.sender){
    require(votingactive, "Voting period is already over");
    votingactive = false;
    delete candidates;
}


}