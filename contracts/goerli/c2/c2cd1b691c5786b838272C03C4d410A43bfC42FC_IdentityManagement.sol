/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// SPDX-License-Identifier: MIT

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;
}
pragma solidity ^0.8.6;

contract IdentityManagement {

    address payable public owner;
    address[] public serviceProviders;

    struct User {
        string name;
        string contact_no;
        string email;
        string city;
        string state;
        bool status;
        uint256 no_of_token;
        bool alreadyExists;
    }

    struct TokenInfos {
        uint256 tokenID;
        address tokenOwner;
        string name;
        string contact_no;
        string email;
        string city;
        string state;
        uint256 validtill;
        address accessBy;
        bool active;
    }

    struct OwnerTokenIDs{
        uint256 tokenIDs;
    }

    struct ProposalCount{
        uint256 count;
    }
    struct Proposal {
        address user;
        uint256 tokenId;
        bool isApprove;
    }

    mapping(uint256 => TokenInfos) public _tokenInfo;
    mapping(address => User) public _tokenOwner;
    mapping(address => mapping(uint256 => OwnerTokenIDs)) public _usersToken;


    //token identify
    mapping(address => Proposal[]) public proposalsbyProvier;
    mapping(address => ProposalCount) public _proposalCount;

    modifier onlyOwner() {
        require(owner == msg.sender, "only owner");
        _;
    }

    constructor(address payable _owner) {
        owner = _owner; // Address of contract owner
    }

    function addProvider(address _provider) public onlyOwner {
        for(uint256 i = 0; i < serviceProviders.length ;i++) {
            require(_provider != serviceProviders[i], "This provider is exited.");
        }

        _proposalCount[_provider].count = 0;
        serviceProviders.push(_provider);
    }

    function getServiceProviders() public view returns(address[] memory){
        return serviceProviders;
    }
    
    function requestProposal(address _provider, uint256 _id) public {
        TokenInfos storage _token = _tokenInfo[_id];
        require(_token.tokenOwner == msg.sender, "You are not owner of this token.");
        require(isExistedProvider(_provider) == true, "This provider is not registered.");
        Proposal memory _prop = Proposal(msg.sender, _id, false);
        proposalsbyProvier[_provider].push(_prop);
        _proposalCount[_provider].count++;
    }

    function approveProposal(uint256 _id) public {
        require(isProvider(msg.sender) == true, "You are not provider.");
        Proposal[] storage _myproposal = proposalsbyProvier[msg.sender];
        bool isExisted = false;
        for(uint256 i = 0; i < _myproposal.length ;i++) {
            if(_id == _myproposal[i].tokenId) {
                isExisted = true;
                _myproposal[i].isApprove = true;
            }
        }
        require(isExisted == true, "This token is not proposal.");
    }

    function validToken(address _provider, uint256 _token) public view returns(bool) {
        require(isProvider(_provider) == true,"This provider is invalid.");
        Proposal[] storage _proposal = proposalsbyProvier[_provider];
        for(uint256 i = 0; i < _proposal.length ;i++) {
            if(_token == _proposal[i].tokenId)
                return true;
        }
        return false;
    }

    function isProvider(address _user) public view returns(bool) {
        for(uint256 i = 0; i < serviceProviders.length ;i++){
            if(_user == serviceProviders[i])
                return true;
        }
        return false;
    }

    function isExistedProvider(address _provider) public view returns(bool) {
        for(uint256 i = 0;i < serviceProviders.length;i++) {
            if(_provider == serviceProviders[i])
                return true;
        }
        return false;
    }

    function register(string memory name,string memory contact_no,string memory email,string memory city,string memory state) public {
         if (!_tokenOwner[msg.sender].alreadyExists){
             _tokenOwner[msg.sender].alreadyExists = true;
         }
         _tokenOwner[msg.sender].name  = name;
         _tokenOwner[msg.sender].contact_no  = contact_no;
         _tokenOwner[msg.sender].email  = email;
         _tokenOwner[msg.sender].city  = city;
         _tokenOwner[msg.sender].state  = state;
         _tokenOwner[msg.sender].status  = true;
    }

    function generateToken(string memory name,string memory contact_no,string memory email,string memory city,string memory state,uint256 validity_timestamp) public {
        require(_tokenOwner[msg.sender].status == true,"User disabled");
        uint256 tempToken = block.timestamp;
        uint256 index = _tokenOwner[msg.sender].no_of_token;
        _usersToken[msg.sender][index].tokenIDs = tempToken;
        _tokenInfo[tempToken].tokenID = tempToken;
        _tokenInfo[tempToken].tokenOwner = msg.sender;
        _tokenInfo[tempToken].name = name;
        _tokenInfo[tempToken].contact_no = contact_no;
        _tokenInfo[tempToken].email = email;
        _tokenInfo[tempToken].city = city;
        _tokenInfo[tempToken].state = state;
        _tokenInfo[tempToken].validtill = validity_timestamp;
        _tokenInfo[tempToken].active = true;
        _tokenOwner[msg.sender].no_of_token++;
    }
    
    function terminateToken(uint256 tokenId) public{
        require(_tokenInfo[tokenId].tokenOwner == msg.sender,"Not Authorized" );
        require(_tokenInfo[tokenId].active == true,"Already Terminated" );
        
        _tokenInfo[tokenId].active = false;
    }

    function addAccess(uint256 tokenID) public{
        require(_tokenInfo[tokenID].active == true,"Terminated" );
        require(_tokenInfo[tokenID].validtill > block.timestamp,"Not Allow");
        _tokenInfo[tokenID].accessBy = msg.sender;
        _tokenInfo[tokenID].active = false;
    }

    function viewTokenData(uint256 tokenId) public view returns(string memory,string memory,string memory,string memory,string memory,address){
        return (_tokenInfo[tokenId].name,_tokenInfo[tokenId].contact_no,_tokenInfo[tokenId].email,_tokenInfo[tokenId].city,_tokenInfo[tokenId].state,_tokenInfo[tokenId].tokenOwner);

    }
    /** This method is used to base currency */

    function withdrawBaseCurrency() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "does not have any balance");
        payable(msg.sender).transfer(balance);
    }

    /** These two methods will enable the owner in withdrawing any incorrectly deposited tokens
    * first call initToken method, passing the token contract address as an argument
    * then call withdrawToken with the value in wei as an argument */
    
    function withdrawToken(address addr,uint256 amount) public onlyOwner {
        IERC20(addr).transfer(msg.sender, amount);
    }
    
    // important to receive ETH
    receive() payable external {} 
}