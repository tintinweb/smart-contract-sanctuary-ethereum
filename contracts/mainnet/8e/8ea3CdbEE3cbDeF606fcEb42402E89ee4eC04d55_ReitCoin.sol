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

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
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

    address public foundersTeam = 0xA899DdF11218D31f2f964a482933869F9602E1AD;
    address public reservesTeam = 0x0B1984712cf5C6d3015297cAEFf74b7fEEc694a0;
    address public charityTeam = 0xAc91f134D522512DAA1337d8897C460B2fa79bf6;
    address public strategyInitiativeTeam =0x320C1a2b6F261A6904c76d5f525719B608816DBC;
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        mintAllowed = true;
        emit Transfer(msg.sender, address(0), _value);
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