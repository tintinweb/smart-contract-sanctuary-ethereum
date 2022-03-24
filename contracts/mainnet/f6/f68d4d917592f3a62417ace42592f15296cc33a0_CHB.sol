/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// File: utils/Ownable.sol


pragma solidity ^0.8.4;

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function _setOwner(address newOwner) internal {
        owner = newOwner;
    }
}

// File: CHB.sol


pragma solidity ^0.8.4;


contract CHB is Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 decimalfactor;
    uint256 public Max_Token;
    bool mintAllowed = true;

    address public TRADE_MINING = 0x2c649c31Ce2DE8a75c00d0E6501D71A0e829A217;
    address public STRATEGIC_RESERVES =
        0xe63C3d7c3c6f1d19e222Ecb78B9117925950c9Fb;
    address public PRIVATE_SALE = 0x94ee53171b02518b29da4F75A0cFFe75F31F501c;
    address public SURPRISE = 0x20a16C7EeD05e4395111135F47C1D47aEedcFE79;

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
        Max_Token = 10_000_000_001 * decimalfactor; // 10 Billion and 1

        mint(TRADE_MINING, 5_000_000_000 * decimalfactor);
        mint(STRATEGIC_RESERVES, 2_000_000_000 * decimalfactor);
        mint(SURPRISE, 1 * decimalfactor);
        mint(PRIVATE_SALE, 300_000_000 * decimalfactor);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(
            balanceOf[_from] >= _value,
            "ERC20: 'from' address balance is low"
        );
        require(
            balanceOf[_to] + _value >= balanceOf[_to],
            "ERC20: Value is negative"
        );

        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value)
        public
        virtual
        returns (bool)
    {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual returns (bool success) {
        require(
            _value <= allowance[_from][msg.sender],
            "ERC20: Allowance error"
        );
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
        require(
            balanceOf[msg.sender] >= _value,
            "ERC20: Transfer amount exceeds user balance"
        );

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        mintAllowed = true;

        emit Burn(msg.sender, _value);
        return true;
    }

    function mint(address _to, uint256 _value) public returns (bool success) {
        require(
            Max_Token >= (totalSupply + _value),
            "ERC20: Max Token limit exceeds"
        );
        require(mintAllowed, "ERC20: Max supply reached");

        if (Max_Token == (totalSupply + _value)) {
            mintAllowed = false;
        }

        require(msg.sender == owner, "ERC20: Only Owner Can Mint");

        balanceOf[_to] += _value;
        totalSupply += _value;

        require(
            balanceOf[_to] >= _value,
            "ERC20: Transfer amount cannot be negative"
        );

        emit Transfer(address(0), _to, _value);
        return true;
    }
}