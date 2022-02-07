/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.8.0 <0.9.0; //No safemath needed


contract Ownable { //ERC173

    address public _owner;

    constructor() {
        _owner = msg.sender; //set the owner to the deployer of the contract
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


contract Tokens is Ownable { //ERC20

    string private _name = "DAO MIP Token";
    string private _symbol = "DMT";
    uint8 private _decimals = 2;
    uint256 private _totalSupply = 100 * (10 ** _decimals);
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _frozen;
    mapping(address => uint256) private _locked;

    constructor() {
        _balances[_owner] += _totalSupply;
    }

    // make sure the caller of a function is not frozen
    modifier notFrozen(address _from) {
        require(!_frozen[_from], "This account is frozen");
        _;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) public notFrozen(msg.sender) returns (bool) {
        require(_balances[msg.sender] >= _value, "Insufficient funds");
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value); 

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public notFrozen(_from) returns (bool) {
        require(_balances[_from] >= _value, "Insufficient funds");
        require(_allowances[_from][msg.sender] >= _value, "Insufficient allowance");
        _balances[_from] -= _value;
        _allowances[_from][msg.sender] -= _value;
        _balances[_to] += _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public notFrozen(msg.sender) returns (bool) {
        require(_balances[msg.sender] >= _value, "Insufficient funds");
        _allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function increaseApproval(address _spender, uint256 _addedValue) public notFrozen(msg.sender) returns (bool) {
        require(_balances[msg.sender] >= _allowances[msg.sender][_spender] + _addedValue, "Insufficient funds");
        _allowances[msg.sender][_spender] += _addedValue;

        emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);

        return true;
    }

    function decreaseApproval(address _spender, uint256 _subtractedValue) public notFrozen(msg.sender) returns (bool) {
        require(_allowances[msg.sender][_spender] >= _subtractedValue, "Insufficient allowance");
        _allowances[msg.sender][_spender] -= _subtractedValue;

        emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);

        return true;
    }

    function mint(uint256 _value) public onlyOwner returns (bool) {
        _balances[_owner] += _value;

        return true;
    }

    function burn(uint256 _value) public onlyOwner returns (bool) {
        _balances[_owner] -= _value;

        return true;
    }

    function revoke(address _from, uint256 _value) public onlyOwner returns (bool) {
        _balances[_from] -= _value;
        _balances[_owner] += _value;

        return true;
    }

    function freeze(address _from) public onlyOwner returns (bool) {
        _frozen[_from] = true;

        return true;
    }

    function unfreeze(address _from) public onlyOwner returns (bool) {
        _frozen[_from] = false;

        return true;
    }

    function lock(address _from, uint256 _end) public onlyOwner returns (bool) {
        _locked[_from] = _end;

        return true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function frozen(address _from) public view returns (bool) {
        return _frozen[_from];
    }

    function locked(address _from) public view returns (uint256) {
        return _locked[_from];
    }
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
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}


/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
contract Awards is Ownable { //ERC721

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => NFTStructure) _nfts;
    uint256 _numberOfNfts;
    struct NFTStructure {
        uint256 tokenId;
        uint256 proposalId;
        uint256 ordinalVote;
        bytes32 hash;
    }

    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function mint(address _owner, uint256 _proposalId, uint256 _ordinalVote) public onlyOwner {
        uint256 _tokenId = _numberOfNfts ++;
        NFTStructure storage nft = _nfts[_tokenId];
        nft.tokenId = _tokenId;
        nft.proposalId = _proposalId;
        nft.ordinalVote = _ordinalVote;
        nft.hash = keccak256(abi.encodePacked(_tokenId, _proposalId, _ordinalVote, _owner));
        _balances[_owner] += 1;
        _owners[_tokenId] = _owner;
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public payable onlyOwner {
        transferFrom(_from, _to, _tokenId);
        if (_to.code.length > 0) {
            require(ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data) == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")), "ERC721Receiver not implemented");
            }
    }
    

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable onlyOwner {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) public payable onlyOwner {
        address tokenOwner = _owners[_tokenId];
        require(msg.sender == tokenOwner || _operatorApprovals[tokenOwner][msg.sender] || msg.sender == _tokenApprovals[_tokenId], "You are not authorized");
        require(_from == tokenOwner, "The sender does not own this NFT");
        require(_to != address(0), "This is not a valid address");
        require(_owners[_tokenId] != address(0), "This is not a valid NFT");
        _tokenApprovals[_tokenId] = address(0);
        _balances[_from] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) public payable {
        address tokenOwner = _owners[_tokenId];
        require(msg.sender == tokenOwner || _operatorApprovals[tokenOwner][msg.sender], "You are not the owner");
        _tokenApprovals[_tokenId] = _approved;
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) public {
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "This is not a valid address");
        return _balances[_owner];
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) public view returns (address) {
        require(_owners[_tokenId] != address(0), "Invalid NFT");
        return _owners[_tokenId];
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) public view returns (address) {
        require(_owners[_tokenId] != address(0), "This is not a valid NFT");
        return _tokenApprovals[_tokenId];
    }


    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function getNFT(uint256 _tokenId) public view returns (NFTStructure memory) {
        return _nfts[_tokenId];
    }
}


contract DAO is Ownable {

    Tokens private token;
    Awards private award;
    uint256 private _proposalId;
    uint256 private _proposalFee = 0.001 ether;
    uint256 private _minRuntime = 24 hours;
    uint256 private _maxRuntime = 7 days;
    uint256 private _auctionPrice = 10 ** 13;
    enum functionChoices {changeProposalFee, changeAuctionPrice, changeMinRuntime, changeMaxRuntime, mint, burn, revoke, freeze, unfreeze, donate}
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
        require(allProposals[_id].votesFor > token.totalSupply()/2,
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

    function setProposal(functionChoices _functionToCall, address _possibleAddress, uint256 _possibleValue, string memory _motivation, uint256 _start, uint256 _runtime) public payable onlyStakeholders notFrozen(msg.sender) {
        require(msg.value >= _proposalFee, "You need to at least pay the proposal fee");
        require(_minRuntime <= _runtime, "The proposal needs to run at least the minimal runtime");
        require(_runtime <= _maxRuntime, "The proposal cannot run more than the maximal runtime");        
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
        require(allProposals[_id].start + allProposals[_id].runtime >= block.timestamp, "This proposal is not active yet");

        voted[_id][msg.sender] = true;

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
        emit Vote(msg.sender, _id, _option);

        numberOfVoters[_id] += 1;
        award.mint(msg.sender, _id, numberOfVoters[_id]);
    }

    function buyTokens(uint256 _amount) payable public returns (bool) {
        require(_amount <= token.balanceOf(address(this)), "There are not enough tokens for sale");
        require(msg.value >= _amount * _auctionPrice, "You are not paying enough");
        require(_amount <= token.totalSupply()/100, "You cannot buy more than 5% of the total supply at once");
        
        token.transfer(msg.sender, _amount);

        return(true);
    }

    function executeAuctionPriceChange(uint256 _id) public checkProposal(_id, functionChoices.changeAuctionPrice) returns (bool) {
        allProposals[_id].executed = true;        
        _auctionPrice = allProposals[_id].possibleValue;

        return true;
    }

    function executeMinRuntimeChange(uint256 _id) public checkProposal(_id, functionChoices.changeMinRuntime) returns (bool) {
        allProposals[_id].executed = true;        
        _minRuntime = allProposals[_id].possibleValue;

        return true;
    }

    function executeMaxRuntimeChange(uint256 _id) public checkProposal(_id, functionChoices.changeMaxRuntime) returns (bool) {
        allProposals[_id].executed = true;        
        _maxRuntime = allProposals[_id].possibleValue;

        return true;
    }

    function ExecuteProposalFeeChange(uint256 _id) public checkProposal(_id, functionChoices.changeProposalFee) returns (bool) {
        allProposals[_id].executed = true;        
        _proposalFee = allProposals[_id].possibleValue;

        return true;
    }

    function executeMint(uint256 _id) public checkProposal(_id, functionChoices.mint) returns (bool) {
        allProposals[_id].executed = true;
        token.mint(allProposals[_id].possibleValue);

        return true;
    }

    function executeBurn(uint256 _id) public checkProposal(_id, functionChoices.burn) returns (bool) {
        require(token.balanceOf(address(this)) >= allProposals[_id].possibleValue, "Insufficient tokens to burn");
        allProposals[_id].executed = true;        
        token.burn(allProposals[_id].possibleValue);

        return(true);
    }

    function executeRevoke(uint256 _id) public checkProposal(_id, functionChoices.revoke) returns (bool) {
        require(token.balanceOf(allProposals[_id].possibleAddress) >= allProposals[_id].possibleValue, "Insufficient tokens to revoke");
        allProposals[_id].executed = true;        
        token.revoke(allProposals[_id].possibleAddress, allProposals[_id].possibleValue);

        return(true);
    }

    function executeFreeze(uint256 _id) public checkProposal(_id, functionChoices.freeze) returns (bool) {
        allProposals[_id].executed = true;        
        token.freeze(allProposals[_id].possibleAddress);

        return(true);
    }

    function executeUnfreeze(uint256 _id) public checkProposal(_id, functionChoices.unfreeze) returns (bool) {
        allProposals[_id].executed = true;        
        token.unfreeze(allProposals[_id].possibleAddress);

        return(true);
    }

    function executeDonate(uint256 _id) public checkProposal(_id, functionChoices.donate) returns (bool) {
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