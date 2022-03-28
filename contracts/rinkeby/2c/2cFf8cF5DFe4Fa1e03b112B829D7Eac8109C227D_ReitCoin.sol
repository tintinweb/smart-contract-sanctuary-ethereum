// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ReitCoin is Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 decimalfactor;
    uint256 public Max_Token;
    bool mintAllowed = true;

    //  team address for TESTING
    address public foundersTeam = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;
    address public reservesTeam = 0x976EA74026E726554dB657fA54763abd0C3a0aa9;
    address public charityTeam = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;
    address public strategyInitiativeTeam =
        0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f;

    // team addresses
    // address public foundersTeam = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    // address public reservesTeam = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    // address public charityTeam = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
    // address public strategyInitiativeTeam = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;

    struct Team {
        uint256 teamAmount;
        uint256 claimedAmount;
        uint256 claimTimestamp;
        uint256 nextClaimShare;
        uint256 claimInterval;
        address teamAddress;
    }

    mapping(uint256 => Team) public idToTeam;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor(
        string memory SYMBOL,
        string memory NAME,
        uint8 DECIMALS
    ) {
        symbol = SYMBOL;
        name = NAME;
        decimals = DECIMALS;
        decimalfactor = 10**uint256(decimals);
        Max_Token = 10_000_000_000 * decimalfactor;

        mint(charityTeam, 1_000_000_000 * decimalfactor);
        mint(strategyInitiativeTeam, 5_000_000_00 * decimalfactor);
        mint(address(this), 4_500_000_000 * decimalfactor);

        // team values for production
        createTeam(
            1,
            foundersTeam,
            180 days,
            2_000_000_000 * decimalfactor,
            1000,
            0
        );
        createTeam(
            2,
            reservesTeam,
            365 days,
            2_500_000_000 * decimalfactor,
            100,
            30 days
        );

        // // testing with smaller timestamps for testing
        // createTeam(1,foundersTeam,60, 2_000_000_000*decimalfactor,10000,0);
        // createTeam(2,reservesTeam,120,2_500_000_000*decimalfactor,1000,60);
    }

    function createTeam(
        uint256 _id,
        address _teamAddress,
        uint256 _claimTimestamp,
        uint256 _teamAmount,
        uint256 _nextClaimShare,
        uint256 _claimInterval
    ) internal {
        Team memory newTeam = Team({
            claimTimestamp: block.timestamp + _claimTimestamp,
            teamAmount: _teamAmount,
            teamAddress: _teamAddress,
            claimedAmount: 0,
            nextClaimShare: _nextClaimShare,
            claimInterval: _claimInterval
        });

        idToTeam[_id] = newTeam;
    }

    function claim() external {
        require(
            ((msg.sender == foundersTeam) || (msg.sender == reservesTeam)),
            "Cannot claim token"
        );

        (uint256 tokensToBeClaimed, uint256 _id) = calculateVestedTokens(
            msg.sender
        );
        Team memory currentTeam = idToTeam[_id];
        require(
            currentTeam.teamAmount > currentTeam.claimedAmount,
            "Already claimed all tokens"
        );
        require(
            block.timestamp > currentTeam.claimTimestamp,
            "Cannot claim yet"
        );
        currentTeam.claimedAmount += tokensToBeClaimed;
        currentTeam.claimTimestamp += currentTeam.claimInterval;

        idToTeam[_id] = currentTeam;

        _transfer(address(this), msg.sender, tokensToBeClaimed);
    }

    function calculateVestedTokens(address _userAddress)
        public
        view
        returns (uint256, uint256)
    {
        if ((_userAddress == foundersTeam) || (_userAddress == reservesTeam)) {
            uint256 _teamId = 1;
            if (_userAddress == reservesTeam) {
                _teamId = 2;
            }
            Team memory currentTeam = idToTeam[_teamId];
            if (
                (block.timestamp > currentTeam.claimTimestamp) &&
                (currentTeam.teamAmount != currentTeam.claimedAmount)
            ) {
                return (
                    ((currentTeam.teamAmount * currentTeam.nextClaimShare) /
                        (10**4)),
                    _teamId
                );
            } else {
                return (0, _teamId);
            }
        } else {
            return (0, 0);
        }
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= _value, "Not enough tokens");
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "Allowance error");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function mint(address _to, uint256 _value) public returns (bool success) {
        require(Max_Token >= (totalSupply + _value));
        require(mintAllowed, "Max supply reached");
        if (Max_Token == (totalSupply + _value)) {
            mintAllowed = false;
        }
        require(msg.sender == owner, "Only Owner Can Mint");
        balanceOf[_to] += _value;
        totalSupply += _value;
        require(balanceOf[_to] >= _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }
}