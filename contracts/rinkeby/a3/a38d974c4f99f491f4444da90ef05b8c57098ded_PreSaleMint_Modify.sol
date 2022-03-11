/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

contract PreSaleMint_Modify {
    address public immutable           _owner;
    mapping(address => uint256) public addressMintedBalance;
    mapping(address => bool) public    whitelistedAddresses;
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }
    
    constructor() {
        _owner = msg.sender;
    }
    
    function whitelistUsers(address[] calldata _users) public onlyOwner {        
        for(uint i = 0; i < _users.length; i++) {
            whitelistedAddresses[_users[i]] = true;
        }
    }
    
    function preSaleMint(uint256 _mintAmount) public payable {
        if(msg.sender != _owner) { 
            require(whitelistedAddresses[msg.sender], "User is not in the whitelist.");
        }
        
        for(uint256 i = 1; i <= _mintAmount; i++) 
            addressMintedBalance[msg.sender]++;
    }
}