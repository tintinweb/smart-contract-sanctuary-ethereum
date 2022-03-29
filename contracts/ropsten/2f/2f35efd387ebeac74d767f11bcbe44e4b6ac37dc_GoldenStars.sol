/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

pragma solidity 0.6.6;

// ----------------------------------------------------------------------------
// 'GoldenStars' token contract
//
// Deployed to : 0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52
// Symbol      : GDS
// Name        : Golden Stars
// Total supply: 1000000
// Decimals    : 18
//
// Enjoy.
//
// (c) by Ahiwe Onyebuchi Valentine.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) virtual public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract GoldenStars is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint public darePrice;
    uint public photoPrice;
    uint public moviePrice;
    uint public nicknamePrice;
    uint public videoPrice;
    uint public anythingYouWantPrice;
    uint public iDecideForTheNightPrice;

    string public custom1;
    string public custom2;
    string public custom3;

    uint public custom1Price;
    uint public custom2Price;
    uint public custom3Price;

    bool isCustom1Set;
    bool isCustom2Set;
    bool isCustom3Set;

    bool dareOpen;
    bool photoOpen;
    bool movieOpen;
    bool nicknameOpen;
    bool videoOpen;
    bool anythingOpen;
    bool decideOpen;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "GS";
        name = "Golden Stars";
        decimals = 0;
        _totalSupply = 1000000;

        darePrice = 5;
        photoPrice = 10;
        moviePrice = 15;
        nicknamePrice = 20;
        videoPrice = 40;
        anythingYouWantPrice = 80;
        iDecideForTheNightPrice = 100;

        dareOpen = true;
        photoOpen = true;
        movieOpen = true;
        nicknameOpen = true;
        videoOpen = true;
        anythingOpen = true;
        decideOpen = true;

        custom1 = "Not Set";
        custom2 = "Not Set";
        custom3 = "Not Set";

        isCustom1Set = false;
        isCustom2Set = false;
        isCustom3Set = false;

        custom1Price = 0;
        custom2Price = 0;
        custom3Price = 0;

        balances[0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52] = _totalSupply;
        emit Transfer(address(0), 0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52, _totalSupply);
    }

    function redeemDare() public returns (bool success){
        require(dareOpen == true);
        address to = 0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52;

        require(balances[msg.sender] >= darePrice, "Insufficient Balance");
        balances[msg.sender] = safeSub(balances[msg.sender], darePrice);
        balances[to] = safeAdd(balances[to], darePrice);
        return true;
    }

    function redeemPhoto() public returns (bool success){
        require(photoOpen == true);
        address to = 0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52;

        require(balances[msg.sender] >= photoPrice, "Insufficient Balance");
        balances[msg.sender] = safeSub(balances[msg.sender], photoPrice);
        balances[to] = safeAdd(balances[to], photoPrice);
        return true;
    }

    function redeemMovie() public returns (bool success){
        require(movieOpen == true);
        address to = 0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52;

        require(balances[msg.sender] >= moviePrice, "Insufficient Balance");
        balances[msg.sender] = safeSub(balances[msg.sender], moviePrice);
        balances[to] = safeAdd(balances[to], moviePrice);
        return true;
    }

    function redeemNickname() public returns (bool success){
        require(nicknameOpen == true);
        address to = 0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52;

        require(balances[msg.sender] >= nicknamePrice, "Insufficient Balance");
        balances[msg.sender] = safeSub(balances[msg.sender], nicknamePrice);
        balances[to] = safeAdd(balances[to], nicknamePrice);
        return true;
    }

    function redeemVideo() public returns (bool success){
        require(videoOpen == true);
        address to = 0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52;

        require(balances[msg.sender] >= videoPrice, "Insufficient Balance");
        balances[msg.sender] = safeSub(balances[msg.sender], videoPrice);
        balances[to] = safeAdd(balances[to], videoPrice);
        return true;
    }

    function redeemAnythingYouWant() public returns (bool success){
        require(anythingOpen == true);
        address to = 0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52;

        require(balances[msg.sender] >= anythingYouWantPrice, "Insufficient Balance");
        balances[msg.sender] = safeSub(balances[msg.sender], anythingYouWantPrice);
        balances[to] = safeAdd(balances[to], anythingYouWantPrice);
        return true;
    }

    function redeemiDecideForTheNight() public returns (bool success){
        require(decideOpen == true);
        address to = 0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52;

        require(balances[msg.sender] >= iDecideForTheNightPrice, "Insufficient Balance");
        balances[msg.sender] = safeSub(balances[msg.sender], iDecideForTheNightPrice);
        balances[to] = safeAdd(balances[to], iDecideForTheNightPrice);
        return true;
    }

    function redeemCustom1() public returns (bool success){
        require(isCustom1Set == true);
        address to = 0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52;

        balances[msg.sender] = safeSub(balances[msg.sender], custom1Price);
        balances[to] = safeAdd(balances[to], custom1Price);
    }

    function redeemCustom2() public returns (bool success){
        require(isCustom2Set == true);
        address to = 0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52;

        balances[msg.sender] = safeSub(balances[msg.sender], custom2Price);
        balances[to] = safeAdd(balances[to], custom2Price);
    }

    function redeemCustom3() public returns (bool success){
        require(isCustom3Set == true);
        address to = 0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52;

        balances[msg.sender] = safeSub(balances[msg.sender], custom3Price);
        balances[to] = safeAdd(balances[to], custom3Price);
    }

    function setCustom1(string memory Name, uint Price) public coulterOnly returns (bool success){
        isCustom1Set = true;
        custom1Price = Price;
        custom1 = Name;

        return true;
    }


    function setCustom2(string memory Name, uint Price) public coulterOnly returns (bool success){
        isCustom2Set = true;
        custom2Price = Price;
        custom2 = Name;

        return true;
    }

    function setCustom3(string memory Name, uint Price) public coulterOnly returns (bool success){
        isCustom3Set = true;
        custom3Price = Price;
        custom3 = Name;

        return true;
    }

    function configure(bool dare, bool photo, bool movie, bool nickname, bool video, bool anything, bool decide, uint setDare, uint setPhoto, uint setMovie, uint setNickname, uint setVideo, uint setAnything, uint setDecide) public coulterOnly returns(bool success){
    
        dareOpen = dare;
        photoOpen = photo;
        movieOpen = movie;
        nicknameOpen = nickname;
        videoOpen = video;
        anythingOpen = anything;
        decideOpen = decide;

        darePrice = setDare;
        photoPrice = setPhoto;
        moviePrice = setMovie;
        nicknamePrice = setNickname;
        videoPrice = setVideo;
        anythingYouWantPrice = setAnything;
        iDecideForTheNightPrice = setDecide;
    
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------

    function totalSupply() public override view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function Custom3Price() public view returns (uint) {
        return custom1Price;
    }

    function Custom2Price() public view returns (uint) {
        return custom2Price;
    }

    function Custom1Price() public view returns (uint) {
        return custom1Price;
    }

    function IdecideForTheNightPrice() public view returns (uint) {
        return iDecideForTheNightPrice;
    }

    function AnythingYouWantPrice() public view returns (uint) {
        return anythingYouWantPrice;
    }

    function VideoPrice() public view returns (uint) {
        return videoPrice;
    }

    function NicknamePrice() public view returns (uint) {
        return nicknamePrice;
    }

    function MoviePrice() public view returns (uint) {
        return moviePrice;
    }

    function PhotoPrice() public view returns (uint) {
        return photoPrice;
    }
    
    function DarePrice() public view returns (uint) {
        return darePrice;
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function SafeMint(uint Tokens) public coulterOnly returns (bool success){

        _totalSupply = safeAdd(_totalSupply, Tokens);
        balances[msg.sender] = safeAdd(balances[msg.sender], Tokens);
        return true;
    }

    function Burn(uint Tokens) public coulterOnly returns (bool success){
        require(balances[msg.sender] >= Tokens);

        _totalSupply = safeSub(_totalSupply, Tokens);
        balances[msg.sender] = safeSub(balances[msg.sender], Tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept BNB
    // ------------------------------------------------------------------------
    // function () external payable {
    //     revert();
    // }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    modifier coulterOnly{
        require(msg.sender == 0xEf54Ca02be4D7628f11d3638E13CAD6D38f2bD52);
        _;
    }
}