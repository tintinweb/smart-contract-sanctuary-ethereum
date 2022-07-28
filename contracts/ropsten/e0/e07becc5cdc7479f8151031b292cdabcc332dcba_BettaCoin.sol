/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// File: contracts/BettaCoin.sol


pragma solidity ^0.8.2;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract BettaCoin is IERC20, Context, Ownable {

    string public constant name = "BettaCoin";
    string public constant symbol = "BETTA";
    uint8 public constant decimals = 18;

    address marketingWallet = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    address burnWallet=0x583031D1113aD414F02576BD6afaBfb302140225;
    address shibaWallet =0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
    address liquidityWallet = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;
    address webDevWallet = 0xd047307BB3e6Dff9FE6E478fdF792De44886f6d7;
    address rewardWallet = 0x6F6F70d02163cfaF37b2d4c1ce289D9Cb7976103;

    uint256 marketingPrcnt = 2;
    uint256 burnPrcnt = 2;
    uint256 shibaPrcnt = 1;
    uint256 liquidityPrcnt = 1;
    uint256 rewardPrcnt = 2;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    mapping (address => bool) private _isExcludedFromFee;

    uint256 constant totalSupply_ = 1000000000 * 10**9 * 10**18;

   constructor() { 
        balances[marketingWallet]= 6600000000 * 10**7 * 10**18;
        balances[webDevWallet]= 2000000000 * 10**7 * 10**18;
        balances[liquidityWallet]= 2000000000 * 10**7 * 10**18;
        balances[msg.sender]= 8940000000 * 10**8 * 10**18;
    }

    function totalSupply() public override pure returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) external override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) external override returns (bool) {
        require(numTokens <= balances[msg.sender], "transfer amount exceeds balance");
        balances[msg.sender] = balances[msg.sender]-numTokens;

        if(_isExcludedFromFee[msg.sender] || _isExcludedFromFee[receiver]){
            balances[receiver] = balances[receiver]+numTokens;
            emit Transfer(msg.sender, receiver, numTokens);
            return true;
        }else{
            balances[marketingWallet] = balances[marketingWallet]+(marketingPrcnt*numTokens/100);
            balances[shibaWallet] = balances[shibaWallet]+(shibaPrcnt*numTokens/100);
            balances[burnWallet] = balances[burnWallet]+(burnPrcnt*numTokens/100);
            balances[liquidityWallet] = balances[liquidityWallet]+(liquidityPrcnt*numTokens/100);
            balances[rewardWallet] = balances[rewardWallet]+(rewardPrcnt*numTokens/100);
            uint256 remaining = 100-marketingPrcnt-shibaPrcnt-burnPrcnt-liquidityPrcnt-rewardPrcnt;
            balances[receiver] = balances[receiver]+(remaining*numTokens/100);
            emit Transfer(msg.sender, receiver, remaining*numTokens/100);
            emit Transfer(msg.sender, marketingWallet, marketingPrcnt*numTokens/100);
            emit Transfer(msg.sender, shibaWallet, shibaPrcnt*numTokens/100);
            emit Transfer(msg.sender, burnWallet, burnPrcnt*numTokens/100);
            emit Transfer(msg.sender, liquidityWallet, liquidityPrcnt*numTokens/100);
            emit Transfer(msg.sender, rewardWallet, rewardPrcnt*numTokens/100);
            return true;
        }
    }

    function approve(address delegate, uint256 numTokens) external override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) external override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) external override returns (bool) {
        require(numTokens <= balances[owner], "transfer amount exceeds balance");
        require(numTokens <= allowed[owner][msg.sender],"insufficient allowance");

        balances[owner] = balances[owner]-numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender]-numTokens;
        if(_isExcludedFromFee[owner] || _isExcludedFromFee[buyer]){
            balances[buyer] = balances[buyer]+numTokens;
            emit Transfer(owner, buyer, numTokens);
            return true;
        }else{
            balances[marketingWallet] = balances[marketingWallet]+(marketingPrcnt*numTokens/100);
            balances[shibaWallet] = balances[shibaWallet]+(shibaPrcnt*numTokens/100);
            balances[burnWallet] = balances[burnWallet]+(burnPrcnt*numTokens/100);
            balances[liquidityWallet] = balances[liquidityWallet]+(liquidityPrcnt*numTokens/100);
            balances[rewardWallet] = balances[rewardWallet]+(rewardPrcnt*numTokens/100);
            uint256 remaining = 100-marketingPrcnt-shibaPrcnt-burnPrcnt-liquidityPrcnt-rewardPrcnt;
            balances[buyer] = balances[buyer]+(remaining*numTokens/100);
            emit Transfer(owner, buyer, remaining*numTokens/100);
            emit Transfer(owner, marketingWallet, marketingPrcnt*numTokens/100);
            emit Transfer(owner, shibaWallet, shibaPrcnt*numTokens/100);
            emit Transfer(owner, burnWallet, burnPrcnt*numTokens/100);
            emit Transfer(owner, liquidityWallet, liquidityPrcnt*numTokens/100);
            emit Transfer(owner, rewardWallet, rewardPrcnt*numTokens/100);
            return true;
        }
    }

    function setAddresses(address _marketingWallet, address _rewardWallet, address _burnWallet, address _shibaWallet, address _liquidityWallet, address _webDevWallet) external onlyOwner() {
        marketingWallet = _marketingWallet;
        rewardWallet = _rewardWallet;
        burnWallet = _burnWallet;
        shibaWallet = _shibaWallet;
        liquidityWallet = _liquidityWallet;
        webDevWallet = _webDevWallet;
    }

    function setPercentages(uint256 _marketingPrcnt, uint256 _burnPrcnt, uint256 _shibaPrcnt, uint256 _liquidityPrcnt, uint256 _rewardPrcnt) external onlyOwner() {
        marketingPrcnt = _marketingPrcnt;
        burnPrcnt = _burnPrcnt;
        shibaPrcnt = _shibaPrcnt;
        liquidityPrcnt = _liquidityPrcnt;
        rewardPrcnt = _rewardPrcnt;
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }
}