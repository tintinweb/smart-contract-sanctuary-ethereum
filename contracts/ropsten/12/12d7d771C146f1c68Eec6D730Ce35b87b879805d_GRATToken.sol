/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

//SPDX-License-Identifier:Unlicensed
pragma solidity ^0.8.13;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        assembly {
            c := add(a,b)
        }
        require(c >= a, "SafeMath: addition overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "SafeMath subraction overFloe");
        assembly {
            c := sub(a,b)
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        assembly {
            c := mul(a,b)
        }
        require(c / a == b, "SafeMath: multiplication overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0,  "SafeMath: division by zero");
        assembly {
            c := div(a,b)
        }
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256 res) {
        require(b != 0, "SafeMath: modulo by zero");
        assembly {
            res := mod(a,b)
        }
    }

}

interface IERC20 {

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint256);
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

    function _msgSender() internal view returns(address){
        return(msg.sender);
    }

    function _msgData() internal pure returns(bytes memory){
        return(msg.data);
    }

}

abstract contract Pausable is Context {

    event Paused(address indexed account);
    event Unpaused(address indexed account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view returns(bool){
        return _paused;
    }

    modifier whenNotPaused{
        require(!paused(),"Pasuable : Paused");
        _;
    }

    modifier whenPaused(){
        require(paused(),"Pasuable : Not Paused");
        _;
    }

    function _pause() internal whenNotPaused{
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal whenPaused{
        _paused = false;
        emit Unpaused(_msgSender());
    }

}

abstract contract Ownable is Context{

    address private _owner;

    event TransferOwnerShip(address oldOwner, address newOwner);

    constructor (address _owner_) {
        _owner = _owner_;
        emit TransferOwnerShip(address(0), _owner);
    }

    function owner() public view returns(address){
        return _owner;
    }

    modifier onlyOwner {
        require(_owner == _msgSender(),"Only allowed to Owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0),"ZEROADDRESS");
        require(newOwner != _owner, "Entering OLD_OWNER_ADDRESS");
        emit TransferOwnerShip(_owner, newOwner);
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal onlyOwner {
        _owner = newOwner;
    }

    function renonceOwnerShip() public onlyOwner {
        _owner = address(0);
    }

}

contract GRATToken is Ownable, IERC20, Pausable{

    using SafeMath for uint256;

    string private name_;
    string private symbol_;
    uint8 private decimals_;
    uint256 private totalSupply_;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply, address _owner_) Ownable(_owner_) {

        name_ = _name;
        symbol_ = _symbol;
        decimals_ = _decimals;
        totalSupply_ = _totalSupply;

        balances[owner()] = totalSupply_ ;
        emit Transfer(address(0), owner(), totalSupply_);
    }

    function name() external view returns(string memory){
        return name_;
    }

    function symbol() external view returns(string memory){
        return symbol_;
    }

    function decimals() external view returns(uint256){
        return decimals_;
    }

    function totalSupply() external view returns (uint256){
        return totalSupply_;
    }

    function transfer(address receiver, uint256 numTokens) external whenNotPaused returns (bool) {
        require(numTokens <= balances[_msgSender()],"INSUFFICIENT_BALANCE");
        require(numTokens > 0, "INVALID_AMOUNT");
        require(receiver != address(0),"TRANSFERING_TO_ZEROADDRESS");

        balances[_msgSender()] = balances[_msgSender()].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(_msgSender(), receiver, numTokens);
        return true;
    }

    function balanceOf(address account) external view returns (uint256){
        return balances[account];
    }   

    function approve(address delegate, uint256 numTokens) external returns (bool) {
        require(delegate != address(0),"APPROVING_TO_ZEROADDRESS");
        require(numTokens > 0, "INVALID_AMOUNT");

        allowed[_msgSender()][delegate] = numTokens;
        emit Approval(_msgSender(), delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) external view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) external whenNotPaused returns (bool) {
        require(numTokens <= balances[owner],"INSUFFICIENT_BALANCE");
        require(numTokens <= allowed[owner][_msgSender()],"INSUFFICIENT_APPROVAL");
        require(buyer != address(0),"TRANSFERING_TO_ZEROADDRESS");

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][_msgSender()] = allowed[owner][_msgSender()].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _numTokens) external returns(bool){
        require(_spender != address(0), "INCREASING ALLOWANCE TO ZEROADDRESS");
        require(_numTokens > 0 , "INVALID NUMTOKENS");

        allowed[_msgSender()][_spender] = allowed[_msgSender()][_spender].add(_numTokens);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _numTokens) external returns(bool){
        require(_spender != address(0), "INCREASING ALLOWANCE TO ZEROADDRESS");
        require(_numTokens > 0 , "INVALID NUMTOKENS");

        allowed[_msgSender()][_spender] = allowed[_msgSender()][_spender].sub(_numTokens);
        return true;
    }

    function mint(address account, uint256 amount) external onlyOwner whenNotPaused {
        require(account != address(0), "MINT_TO_ZEROADDRESS");
        require(amount > 0, "INVALID_AMOUNT");

        totalSupply_ = totalSupply_.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner whenNotPaused {
        require(account == _msgSender(), "ONLY_ALLOWED_TO_BURN_OWN_TOKENS");
        require(account != address(0), "BURN_FROM_ZEROADDRESS");
        require(amount > 0, "INVALID_AMOUNT");

        balances[account] = balances[account].sub(amount);
        totalSupply_ = totalSupply_.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

}

contract GRATTokenPresale is Ownable{

    using SafeMath for uint256;

    IERC20 private token;

    uint8 private _rate = 10;
    uint256 private _weiRaised;
    uint256 public pendingTokens;
    uint256 private breakTime;
    bool private saleStatus;
    IERC20 private GRTAddress;

    bytes4 private constant SELECTORTRANSFERFROM = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    bytes4 private constant SELECTORTRANFSFER = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant SELECTORMINT = bytes4(keccak256(bytes('mint(address,uint256)')));
    bytes4 private constant SELECTORTRANSFEROWNERSHIP = bytes4(keccak256(bytes('transferOwnership(address)')));

    mapping(address => uint256) private preSaleToken;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 indexed value, uint256 amount);
    event TokenClaim(address indexed beneficiary, uint256 indexed amount);

    uint256 private lock;
    modifier onlyOnce(){
        require(lock == 0, "ALREADY DEPLOYED");
        _;
        lock = 1;

    }

    constructor(address _token, address _owner_) Ownable(_owner_){
        token = IERC20(_token);
        deploy();
    }

    function rate() external view returns(uint256){
        return _rate;
    }

    function weiRaised() external view returns(uint256){
        return _weiRaised;
    }

    function startSale() external onlyOwner{
        require(!saleStatus,"SALE_ALREADY_STARTED");
        saleStatus = true;
    }

    function stopSale() external onlyOwner{
        require(saleStatus,"SALE_ALREADY_STOPPED");
        saleStatus = false;
        breakTime = block.timestamp + 30;
    }

    function updateRate(uint8 rate_) external onlyOwner returns(bool) {
        _rate = rate_;
        return true;
    }

    function buyToken(address _receiver) external payable{
        require(saleStatus,"SALE_STOPED OR NOT_STARTED");
        require(_receiver != address(0),"RECEIVER_IS_ZEROADDRESS");
        require(msg.value > 0,"INVALID_ETHER");

        uint256 _msgValue = msg.value;
        _transferFund(_msgValue);

        uint256 _tokenAmount = _getTokenAmount(_msgValue);
        pendingTokens = pendingTokens.add(_tokenAmount);

        _selectorMint(_tokenAmount);
        _selectorTransfer(address(GRTAddress), _receiver,_tokenAmount);

        _weiRaised = _weiRaised.add(_msgValue);
        preSaleToken[_receiver] = preSaleToken[_receiver].add(_tokenAmount);

        emit TokenPurchase(_msgSender(), _receiver, _msgValue, _tokenAmount);
    }

    function claimPreSaleToken() external{
        require(preSaleToken[_msgSender()] > 0,"INSUFFICIENT_PRESALETOKEN");
        require(!saleStatus,"PRESALE_IS_NOT_COMPLETED");
        require(block.timestamp > breakTime, "MAINTAINENCE_BREAK");

        uint256 _tokenAmount = preSaleToken[_msgSender()];
        _selectorTransfer(address(token), _msgSender(), _tokenAmount);

        preSaleToken[_msgSender()] = preSaleToken[_msgSender()].sub(_tokenAmount);

        emit TokenClaim(_msgSender(), _tokenAmount);
    }

    function deposit() external onlyOwner {
        require(!saleStatus, "SALE_IS_NOT_ENDED");

        _selectorTransferFrom(pendingTokens);
        _reAllocatingPending();
    }

    function preSaleBalanceOf(address _account) external view returns(uint256){
        return preSaleToken[_account];
    }

    function balanceOf(address _address) external view returns(uint256){
        return token.balanceOf(_address);
    }

    function statusOfPreSale() external view returns(bool){
        return saleStatus;
    }

    function rewardTokenAddress() external view returns(address){
        return address(GRTAddress);
    }

    function _transferFund(uint256 _msgValue) internal {
        (bool success) = payable(owner()).send(_msgValue);
        require(success,"TRANSFERFUND_FAILED!!!");
    }

    function _selectorTransfer(address _contract, address _receiver, uint256 _tokenAmount) internal {
        (bool suc, ) = _contract.call(abi.encodeWithSelector(SELECTORTRANFSFER,_receiver,_tokenAmount));
        require(suc,"TRANSFER_FAILED");
    }

    function _getTokenAmount(uint256 _amount) internal view returns(uint256 tokenAmount){
        tokenAmount = _amount.mul(_rate);
    }

    function _selectorTransferFrom(uint256 _amount) internal {
        (bool success, ) = address(token).call(abi.encodeWithSelector(SELECTORTRANSFERFROM,_msgSender(),address(this),_amount));
        require(success, "TRANSFERFROM_FAILED");
    }

    function _selectorMint(uint256 _amount) internal {
        (bool suc, ) = address(GRTAddress).call(abi.encodeWithSelector(SELECTORMINT,address(this),_amount));
        require(suc,"MINT_FAILED");
    }

    function _reAllocatingPending() internal {
        pendingTokens = 0;
    }

    function deploy() internal onlyOnce returns(bool){
        GRATToken _lpContract = new GRATToken("GRT","GRT",18,0,address(this));
        GRTAddress = IERC20(_lpContract);
        return true;
    }

    function transferOwnerShipGRT(address _newOwner) external onlyOwner {
        (bool success, ) = address(GRTAddress).call(abi.encodeWithSelector(SELECTORTRANSFEROWNERSHIP,_newOwner));
        require(success, "TRANSFER_OWNERSHIP_FAILED");
    }

}