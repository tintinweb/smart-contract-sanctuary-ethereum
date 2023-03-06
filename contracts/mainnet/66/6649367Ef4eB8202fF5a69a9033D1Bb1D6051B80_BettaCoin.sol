/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: MIT
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

    address public potentialOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnerNominated(address pendingOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() external view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address pendingOwner) external onlyOwner {
    require(pendingOwner != address(0), "potential owner can not be the zero address.");
    potentialOwner = pendingOwner;
    emit OwnerNominated(pendingOwner);
    }

    function acceptOwnership() external {
        require(msg.sender == potentialOwner, "You must be nominated as potential owner before you can accept ownership");
        emit OwnershipTransferred(_owner, potentialOwner);
        _owner = potentialOwner;
        potentialOwner = address(0); 
    }
}


contract BettaCoin is IERC20, Context, Ownable {

    string public constant name = "BettaCoin";
    string public constant symbol = "BETTA";
    uint8 public constant decimals = 18;

    address marketingWallet = 0x0009f5692B761E4791279BF85B7c8e8429191787;
    address burnWallet=0x0000000000000000000000000000000000000000;
    address shibaWallet =0xaB51220576E0ce98A5400D194f9380a23Ee258E6;
    address liquidityWallet = 0xc5ea23aa9b95Def4500bacB0B9f3DD9D052D6b97;
    address webDevWallet = 0x72273Bb9B7aD29B80Fa0E18675fbc6b3a449c93b;
    address rewardWallet = 0xD49a958d6cd895a07db32d9A9C082658eFcA5cB5;

    uint256 marketingPrcnt = 2;
    uint256 burnPrcnt = 2;
    uint256 shibaPrcnt = 1;
    uint256 liquidityPrcnt = 1;
    uint256 rewardPrcnt = 2;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    mapping (address => bool) private _isExcludedFromFee;

    uint256 constant totalSupply_ = 1000000000 * 10**9 * 10**18;

    event AddressesUpdated(address marketing, address reward, address burn, address shiba,address liquidity, address web);
    event FeeUpdated(uint256 marketingPrcnt, uint256 burnPrcnt, uint256 shibaPrcnt, uint256 liquidityPrcnt,uint256 rewardPrcnt);
    event ExcludedFromFee(address account);
    event IncludedInFee(address account);

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

    function _approve(
        address owner,
        address delegate,
        uint256 numTokens
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(delegate != address(0), "ERC20: approve to the zero address");
        allowed[owner][delegate] = numTokens;
        emit Approval(owner, delegate, numTokens);
    }

    function approve(address delegate, uint256 numTokens) external override returns (bool) {
        address owner = _msgSender();
        _approve(owner, delegate, numTokens);
        return true;
    }

    function increaseAllowance(address delegate, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, delegate, allowance(owner, delegate) + addedValue);
        return true;
    }

     function decreaseAllowance(address delegate, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, delegate);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, delegate, currentAllowance - subtractedValue);
        }

        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
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
        require(
            _marketingWallet!= address(0)&&
            _rewardWallet!= address(0)&&
            _burnWallet!= address(0)&&
            _shibaWallet!= address(0)&&
            _liquidityWallet!= address(0)&&
            _webDevWallet!= address(0), "address cannot be zero address"
        );
        marketingWallet = _marketingWallet;
        rewardWallet = _rewardWallet;
        burnWallet = _burnWallet;
        shibaWallet = _shibaWallet;
        liquidityWallet = _liquidityWallet;
        webDevWallet = _webDevWallet;
        emit AddressesUpdated(_marketingWallet, _rewardWallet, _burnWallet, _shibaWallet, _liquidityWallet, _webDevWallet);
    }

    function setPercentages(uint256 _marketingPrcnt, uint256 _burnPrcnt, uint256 _shibaPrcnt, uint256 _liquidityPrcnt, uint256 _rewardPrcnt) external onlyOwner() {
        require((_marketingPrcnt + _burnPrcnt + _shibaPrcnt + _liquidityPrcnt + _rewardPrcnt) <= 20,"Fees are too high");
        marketingPrcnt = _marketingPrcnt;
        burnPrcnt = _burnPrcnt;
        shibaPrcnt = _shibaPrcnt;
        liquidityPrcnt = _liquidityPrcnt;
        rewardPrcnt = _rewardPrcnt;
        emit FeeUpdated( _marketingPrcnt,  _burnPrcnt,  _shibaPrcnt,  _liquidityPrcnt, _rewardPrcnt);
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludedFromFee(account);
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludedInFee( account);
    }

    function isExcludedFromFee(address account) public view returns(bool){
        return _isExcludedFromFee[account];
    }
}