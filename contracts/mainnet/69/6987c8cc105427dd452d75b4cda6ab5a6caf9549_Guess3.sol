/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract Guess3 is Ownable {

    event Guessing(uint256 Result, string Outcome);
    event Intro(uint256 Code);
    event Funding(uint256 weiAmt);

    string outcome;
    uint256 public code;
    uint256 public stake;
    uint256 public result;
    uint256 public result1;
    uint256 public result2;
    uint256 public result3;
    uint256[] public results;
    mapping(address => address) public introducers;
    mapping(uint256 => address) public shortCode;
    mapping(address => uint256) public MyCode;
    
    constructor() payable{
        bonus = 60; //percentage
        code = 1000; 
        shortCode[1000] = owner();
        stake = 10**16; // 0.01 Eth
    }
    
    function getIntroduced(uint256 _code) public {
        code++;
        shortCode[code] = _msgSender();
        MyCode[_msgSender()] = code;
        address introducer = shortCode[_code];
        introducers[_msgSender()] = introducer;
        emit Intro(code);
    }
    function getMyCode( )public view returns(uint) {
        return MyCode[_msgSender()];
    }
    function stakeAmount(uint256 _stake) public onlyOwner {
        stake = _stake;
    }
    // Defining a function to generate a random number
    function randMod() internal returns(uint256){
        // increase nonce
        randNonce++;
        result = uint(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randNonce))) % 10;
        result1 = uint(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randNonce+10))) % 10;
        result2 = uint(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randNonce+11))) % 10;
        result3 = uint(keccak256(abi.encodePacked(block.timestamp, _msgSender(), randNonce+12))) % 10;
        return result;
    }
    
    function viewResult() public view returns(uint256 Result) {
        return (result);
    }
    uint8 public bonus;
    
    function setBonus(uint8 _bonus) public onlyOwner {
        bonus = _bonus;
    }
    function guessNumber(uint8 _number, uint8 _number2,uint8 _number3) public payable returns(uint256 Result)  {
        require(msg.value>=stake, " Nill");
        
        randMod();
        bonus = uint8(result*10);
        if(_number == result || _number2 == result || _number3 == result){
            outcome = " Hooray!! You Won";
           uint256 amount = msg.value*(100+bonus)/100;
           payable(_msgSender()).transfer(amount);
        }else {
            outcome = "Ooops You Lost, better luck next time";
            payable(introducers[_msgSender()]).transfer(msg.value/10);
        }
        results.push(result);
        if(results.length>10){
          _removeZero();
        }

        emit Guessing(result,outcome);
        return(result);
    }
    uint256 private randNonce;
    function luckyDip() public payable returns(uint){
        require(msg.value>=stake, " Nill");
        
        randMod();
        bonus = uint8(result*10);
        if(result1 == result || result2 == result || result3 == result){
            outcome = " Hooray!! You Won";
           uint256 amount = msg.value*(100+bonus)/100;
           payable(_msgSender()).transfer(amount);
        }else {
            outcome = "Ooops You Lost, better luck next time";
            payable(introducers[_msgSender()]).transfer(msg.value/10);
        }
        results.push(result);
        if(results.length>10){
          _removeZero();
        }

        emit Guessing(result,outcome);
        return(result);
    }
    function _removeZero() internal {
        for (uint8 i=0; i<results.length-1;i++){
            results[i] = results[i+1];
        }
        results.pop();
    }
    function _remove(uint8 _num) internal {
        for (uint8 i=_num; i<results.length-1;i++){
            results[i] = results[i+1];
        }
        results.pop();
    }
    function countResult() public view returns(uint8,uint8,uint8,uint8,uint8) {
        uint8 evenResult;
        uint8 oddResult;
        uint8 firstGroup;
        uint8 secondGroup;
        uint8 thirdGroup;

        for(uint i=0; i<results.length;i++){
            if(results[i] == 0 || results[i] == 1 ||results[i] == 2 ||results[i] == 3) {
                firstGroup++;
            }else if (results[i] == 4 || results[i] == 5 ||results[i] == 6){
                secondGroup++;
            }else {
                thirdGroup++;
            }
            if(results[i] == 0 || results[i] == 2 ||results[i] == 4 ||results[i] == 6 ||results[i] == 8){
                evenResult++;
            }else{
                oddResult++;
            }    
        }
        return (firstGroup,secondGroup,thirdGroup,evenResult,oddResult);
    }
    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "No funds to withdraw");
        uint256 contractBalance = address(this).balance;
        _withdraw(owner(), contractBalance );
    }
    function withdrawSome(uint256 _amount) external onlyOwner {
        require(address(this).balance > 0, "No funds to withdraw");
        _withdraw(owner(), _amount );
    }
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
    receive() external payable {
        emit Funding(msg.value);
    }
    function close() public onlyOwner { 
        selfdestruct(payable(owner())); 
    }
}