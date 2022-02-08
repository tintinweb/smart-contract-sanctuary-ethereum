/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.8.0 <0.9.0; //No safemath needed


contract Ownable { //ERC173

    address public _owner;

    constructor() {
        _owner = msg.sender; //set the owner to the deployer of the contract
        emit OwnershipTransferred(address(0), _owner);
    }

    // Make sure a function can only be called by the owner of the contract
    modifier onlyOwner() {
        require(msg.sender == _owner, "You are not the owner of this contract");
        _;
    }

    /// @dev This emits when ownership of a contract changes. 
    event OwnershipTransferred(
        address indexed previousOwner, 
        address indexed newOwner
    );

    /// @notice Get the address of the owner    
    /// @return The address of the owner.
    function owner() view public returns(address) {
        return(_owner);
    }

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract 
    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}


abstract contract Tokens is Ownable { //ERC20

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) public virtual returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool);
    function approve(address _spender, uint256 _value) public virtual returns (bool);
    function increaseApproval(address _spender, uint256 _addedValue) public virtual returns (bool);
    function decreaseApproval(address _spender, uint256 _subtractedValue) public virtual returns (bool);

    function mint(uint256 _value) public virtual returns (bool);
    function burn(uint256 _value) public virtual returns (bool);
    function revoke(address _from, uint256 _value) public virtual returns (bool);
    function freeze(address _from) public virtual returns (bool);
    function unfreeze(address _from) public virtual returns (bool);
    function lock(address _from, uint256 _end) public virtual returns (bool);

    function name() public view virtual returns (string memory);
    function symbol() public view virtual returns (string memory);
    function decimals() public view virtual returns (uint8);
    function totalSupply() public view virtual returns (uint256);
    function balanceOf(address account) public view virtual returns (uint256);
    function allowance(address _owner, address _spender) public view virtual returns (uint256);
    function frozen(address _from) public view virtual returns (bool);
    function locked(address _from) public view virtual returns (uint256);
}


interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator, 
        address _from, 
        uint256 _tokenId, 
        bytes calldata _data
    ) external returns(bytes4);
}


abstract contract Awards is Ownable { //ERC721
    
    struct NFTStructure {
        uint256 tokenId;
        uint256 proposalId;
        uint256 ordinalVote;
        bytes32 hash;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function mint(address _owner, uint256 _proposalId, uint256 _ordinalVote) public virtual;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public payable virtual;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable virtual;
    function transferFrom(address _from, address _to, uint256 _tokenId) public payable virtual;
    function approve(address _approved, uint256 _tokenId) public payable virtual;
    function setApprovalForAll(address _operator, bool _approved) public virtual;
    function balanceOf(address _owner) public view virtual returns (uint256);
    function ownerOf(uint256 _tokenId) public view virtual returns (address);
    function getApproved(uint256 _tokenId) public view virtual returns (address);
    function isApprovedForAll(address _owner, address _operator) public view virtual returns (bool);
    function getNFT(uint256 _tokenId) public view virtual returns (NFTStructure memory);
}


contract DAO is Ownable {

    Tokens private token;
    Awards private award;

    uint256 private _proposalId;
    uint256 private _proposalFee = 1000000000000000 wei; // 0.001 ether
    uint256 private _minRuntime = 5 minutes;
    uint256 private _maxRuntime = 60 minutes;
    uint256 private _auctionPrice = 1000000000000 wei; // 0.000 001 ether

    enum functionChoices {
        changeProposalFee, 
        changeAuctionPrice, 
        changeMinRuntime, 
        changeMaxRuntime, 
        mint, 
        burn, 
        revoke, 
        freeze, 
        unfreeze, 
        donate
    }

    mapping(uint256 => mapping(address => bool)) public votesCasted;
    mapping(uint256 => mapping(address => bool)) private voted;
    mapping(uint256 => uint256) private numberOfVoters;
    mapping(uint256 => ProposalStructure) private allProposals;
    
    struct ProposalStructure {
        uint256 id;
        functionChoices functionToCall;
        address possibleAddress;
        uint256 possibleValue;
        string motivation;
        address proposer;
        uint256 votesFor;
        uint256 votesAgaist;
        uint256 start;
        uint256 runtime;
        bool executed;
    }

    constructor(address _tokenAddress, address _awardAddress) {
        token = Tokens(_tokenAddress);
        award = Awards(_awardAddress);
        _owner = address(this);
    }

    modifier onlyStakeholders() {
        require(token.balanceOf(msg.sender) > 0, "Insufficient number of tokens");
        _;
    }

    modifier notFrozen(address _account) {
        require(!token.frozen(_account));
        _;
    }

    modifier checkProposal(uint256 _id, functionChoices _functionToCall) {
        require(allProposals[_id].votesFor > token.totalSupply() / 2,
         "Proposal was not passed"
         );
        require(allProposals[_id].functionToCall == _functionToCall, 
        "This is not the proposed function");
        require(!allProposals[_id].executed, "This proposal has already been executed");
        _;
    }

    event Contributed(address indexed _contributor, uint256 _amount);
    event ProposalCreated(address indexed _proposer, uint256 _id);
    event Vote(address indexed _voter, uint256 _id, bool _option);

    function contribute() payable public returns (bool) {
        require(msg.value > 0, "You need to contribute a meaningful value");
        emit Contributed(msg.sender, msg.value);

        return true;
    }

    function setProposal(
        functionChoices _functionToCall, 
        address _possibleAddress, 
        uint256 _possibleValue, 
        string memory _motivation, 
        uint256 _start, 
        uint256 _runtime
    ) public payable onlyStakeholders notFrozen(msg.sender) {
        require(msg.value >= _proposalFee, 
            "You need to at least pay the proposal fee"
        );
        require(_minRuntime <= _runtime, 
            "The proposal needs to run at least the minimal runtime"
        );
        require(_runtime <= _maxRuntime, 
            "The proposal cannot run more than the maximal runtime"
        );        
        uint256 _id = _proposalId ++;
        ProposalStructure storage proposal = allProposals[_id];
        proposal.id = _id;
        proposal.functionToCall = _functionToCall;
        proposal.possibleAddress = _possibleAddress;
        proposal.possibleValue = _possibleValue;
        proposal.motivation = _motivation;
        proposal.proposer = msg.sender;
        proposal.start = _start;
        proposal.runtime = _runtime;

        emit ProposalCreated(msg.sender, _id);
    }

    function vote(uint256 _id, bool _option) public onlyStakeholders notFrozen(msg.sender) {
        require(!voted[_id][msg.sender], "You already voted for this proposal");
        require(allProposals[_id].start + allProposals[_id].runtime >= block.timestamp, 
            "This proposal is not active yet"
        );

        voted[_id][msg.sender] = true;
        emit Vote(msg.sender, _id, _option);

        if (allProposals[_id].start + allProposals[_id].runtime > token.locked(msg.sender)) {
            token.lock(msg.sender, allProposals[_id].start + allProposals[_id].runtime);
        }
        if(_option) {
            allProposals[_id].votesFor += token.balanceOf(msg.sender);
        }
        else {
            allProposals[_id].votesAgaist += token.balanceOf(msg.sender);
        }
        votesCasted[_id][msg.sender] = _option;

        numberOfVoters[_id] += 1;
        award.mint(msg.sender, _id, numberOfVoters[_id]);
    }

    function buyTokens(uint256 _amount) payable public returns (bool) {
        require(_amount <= token.balanceOf(address(this)), 
            "There are not enough tokens for sale"
        );
        require(_amount <= token.totalSupply() / 20, 
            "You cannot buy more than 5% of the total supply at once"
        );
        require(msg.value >= _amount * _auctionPrice, 
            "You are not paying enough"
        );
        
        token.transfer(msg.sender, _amount);

        return(true);
    }

    function executeAuctionPriceChange(
        uint256 _id
    ) public checkProposal(_id, functionChoices.changeAuctionPrice) returns (bool) {
        allProposals[_id].executed = true;        
        _auctionPrice = allProposals[_id].possibleValue;

        return true;
    }

    function executeMinRuntimeChange(
        uint256 _id
    ) public checkProposal(_id, functionChoices.changeMinRuntime) returns (bool) {
        allProposals[_id].executed = true;        
        _minRuntime = allProposals[_id].possibleValue;

        return true;
    }

    function executeMaxRuntimeChange(
        uint256 _id
    ) public checkProposal(_id, functionChoices.changeMaxRuntime) returns (bool) {
        allProposals[_id].executed = true;        
        _maxRuntime = allProposals[_id].possibleValue;

        return true;
    }

    function ExecuteProposalFeeChange(
        uint256 _id
    ) public checkProposal(_id, functionChoices.changeProposalFee) returns (bool) {
        allProposals[_id].executed = true;        
        _proposalFee = allProposals[_id].possibleValue;

        return true;
    }

    function executeMint(
        uint256 _id
    ) public checkProposal(_id, functionChoices.mint) returns (bool) {
        allProposals[_id].executed = true;
        token.mint(allProposals[_id].possibleValue);

        return true;
    }

    function executeBurn(
        uint256 _id
    ) public checkProposal(_id, functionChoices.burn) returns (bool) {
        require(token.balanceOf(address(this)) >= allProposals[_id].possibleValue, 
            "Insufficient tokens to burn"
        );
        allProposals[_id].executed = true;        
        token.burn(allProposals[_id].possibleValue);

        return(true);
    }

    function executeRevoke(
        uint256 _id
    ) public checkProposal(_id, functionChoices.revoke) returns (bool) {
        require(
            token.balanceOf(allProposals[_id].possibleAddress) >= allProposals[_id].possibleValue, 
            "Insufficient tokens to revoke"
        );
        allProposals[_id].executed = true;        
        token.revoke(allProposals[_id].possibleAddress, allProposals[_id].possibleValue);

        return(true);
    }

    function executeFreeze(
        uint256 _id
    ) public checkProposal(_id, functionChoices.freeze) returns (bool) {
        allProposals[_id].executed = true;        
        token.freeze(allProposals[_id].possibleAddress);

        return(true);
    }

    function executeUnfreeze(
        uint256 _id
    ) public checkProposal(_id, functionChoices.unfreeze) returns (bool) {
        allProposals[_id].executed = true;        
        token.unfreeze(allProposals[_id].possibleAddress);

        return(true);
    }

    function executeDonate(
        uint256 _id
    ) public checkProposal(_id, functionChoices.donate) returns (bool) {
        allProposals[_id].executed = true;        
        payable(allProposals[_id].possibleAddress).transfer(allProposals[_id].possibleValue);

        return true;
    }

    function getProposal(uint256 _id) public view returns (ProposalStructure memory) {
        require(_id <= _proposalId, "There is no proposal with this ID");
        return(allProposals[_id]);
    }

    function getTokenAddress() public view returns (address) {
        return address(token);
    }

    function getAwardAddress() public view returns (address) {
        return address(award);
    }

    function getLastProposalId() public view returns (uint256) {
        return _proposalId - 1;
    }

    function getProposalFee() public view returns (uint256) {
        return _proposalFee;
    }

    function getMinRuntime() public view returns (uint256) {
        return _minRuntime;
    }

    function getMaxRuntime() public view returns (uint256) {
        return _maxRuntime;
    }

    function getAuctionPrice() public view returns (uint256) {
        return _auctionPrice;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}