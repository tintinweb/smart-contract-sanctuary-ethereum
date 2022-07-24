/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

error NotOwner();

contract CompoundInterestTest {
    address[] public peopleThatHaveParticipated;

    mapping(address => uint256) public amountAdded;

    address public CoinAddress;

    address internal immutable i_owner;

    mapping(address => uint256) internal RewardDue;

    uint256 public coinRewardValuePer1ETH;

    mapping(address => uint256) public EthDue;

    constructor() {
        i_owner = msg.sender;
    }

    function SetRewardCoinAddress(address rcAddress) public onlyOwner {
        CoinAddress = rcAddress;
    }

    function addToInterest() public payable {
        require(
            msg.value > 0.001 * 1e18,
            "Didn't send enough... The minimum is 0.001 eth"
        );
        peopleThatHaveParticipated.push(msg.sender);
        amountAdded[msg.sender] = msg.value;
        EthDue[msg.sender] = msg.value;
        RewardDue[msg.sender] = msg.value / 1e13;
    }

    function SetNumberOfMintPer1ETH(uint256 value) public onlyOwner{
       coinRewardValuePer1ETH = value;
    }

    function retrieveRewards() public {
        (bool callSuccess, ) = payable(msg.sender).call{
            value: EthDue[msg.sender]
        }("");
        require(callSuccess, "Call failed");
    }

    function mintRewards() public returns (bool) {
        CrypticCoin(CoinAddress).interestMint(msg.sender, RewardDue[msg.sender]);
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

}

abstract contract ERC20Token {
    function name() virtual public view returns (string memory);
    function symbol() virtual public view returns (string memory);
    function decimals() virtual public view returns (uint8);
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address _owner) virtual public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) virtual public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success);
    function approve(address _spender, uint256 _value) virtual public returns (bool success);
    function allowance(address _owner, address _spender) virtual public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address _to) public {
        require(msg.sender == owner);
        newOwner = _to;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

}

contract CrypticCoin is ERC20Token, Owned {

    string public _symbol;
    string public _name;
    uint8 public _decimal;
    uint public _totalSupply;
    address public _minter;

    address internal immutable i_developer;

    address internal CompoundInterestAddress;

    mapping(address => uint) balances;

    modifier onlyInterestAddress {
        if (msg.sender != CompoundInterestAddress) {
            revert NotOwner();
        }
        _;
    }

    modifier onlyDeveloper {
        if (msg.sender != i_developer) {
            revert NotOwner();
        }
        _;
    }

    constructor() {
        i_developer = msg.sender;
        _symbol = "CCC";
        _name = "Cryptic";
        _decimal = 8;
        _totalSupply = 100;
        _minter = msg.sender;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), _minter, _totalSupply);
    }

    function name() public override view returns (string memory) {
        return _name;
    }

    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function decimals() public override view returns (uint8) {
        return _decimal;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(balances[_from] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return 0;
    }

    function mint(uint amount) public onlyDeveloper returns (bool) {
        balances[msg.sender] += amount;
        _totalSupply += amount;
        return true;
    }

    function burn(uint amountToBurn) public returns (bool) {
        require(balances[msg.sender] >= amountToBurn);
        balances[msg.sender] -= amountToBurn;
        _totalSupply -= amountToBurn;
        return true;
    }

    function setContractInterestAddress(address i_CompoundInterestAddress) public onlyDeveloper returns (bool) {
        CompoundInterestAddress = i_CompoundInterestAddress;
        return true;
    }

    function interestMint(address rewarded, uint256 amountToBeRewarded) public onlyInterestAddress returns (bool) {
        balances[rewarded] += amountToBeRewarded;
        _totalSupply += amountToBeRewarded;
        return true;
    }

}