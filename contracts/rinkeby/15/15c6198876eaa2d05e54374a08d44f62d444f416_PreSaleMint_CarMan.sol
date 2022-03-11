/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

contract PreSaleMint_CarMan {
    address public immutable           _owner;
    mapping(address => uint256) public addressMintedBalance;
    address[] public                   whitelistedAddresses;
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }
    
    constructor() {
        _owner = msg.sender;
    }
    
    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }
    
    function isWhitelisted(address _user) public view returns (bool) {
        for(uint i = 0; i < whitelistedAddresses.length; i++) {
            if(whitelistedAddresses[i] == _user) 
                return true;
        }
        
        return false;
    }
    
    function preSaleMint(uint256 _mintAmount) public payable {
        if(msg.sender != _owner) {
            require(isWhitelisted(msg.sender), "user is not whitelisted");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) 
            addressMintedBalance[msg.sender]++;
    }
}