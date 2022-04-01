// SPDX-License-Identifier: GPL-3.0
//
//
//
//
//                                __                                     
//                               /  |                                    
//   ______   __    __   ______  $$ |____   __    __   ______   _______  
//  /      \ /  |  /  | /      \ $$      \ /  |  /  | /      \ /       \ 
// /$$$$$$  |$$ |  $$ |/$$$$$$  |$$$$$$$  |$$ |  $$ |/$$$$$$  |$$$$$$$  |
// $$ |  $$/ $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$/ $$ |  $$ |
// $$ |      $$ \__$$ |$$ \__$$ |$$ |__$$ |$$ \__$$ |$$ |      $$ |  $$ |
// $$ |      $$    $$/ $$    $$ |$$    $$/ $$    $$/ $$ |      $$ |  $$ |
// $$/        $$$$$$/   $$$$$$$ |$$$$$$$/   $$$$$$/  $$/       $$/   $$/ 
//                     /  \__$$ |                                        
//                     $$    $$/                                         
//                      $$$$$$/ 
//
//
//
//
// Contract: STAKING with early yeilds in exchange for locking periods.

pragma solidity ^0.8.7;



interface IERC721 {
    function transferFrom(address _from, address _to, uint _tokenid) external;
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address owner) external view;
}


contract Staker {
    
    address public tokenContract;
    address public paymentContract;
    address internal owner;
    uint256 public daily;
    uint public staked;
    bool public open;
    uint public maxLoanDays = 90;
    mapping (uint256 => address) public holder;
    mapping (uint256 => uint64) public timestamp;
    mapping (uint256 => uint64) public locktime;
    mapping(address=>uint) public balanceOf;

    event Staked(uint indexed _tokenid, address indexed _owner);
    event Unstaked(uint indexed _tokenid, address indexed _owner);

    constructor(address _tokenContract, address _ercContract, uint256 _daily) {
        tokenContract = _tokenContract;
        paymentContract = _ercContract;
        daily = _daily/86400;
        owner = tx.origin;
    }

    modifier isOpen(){
        require(open == true,'not open');
        _;
    }
    modifier onlyOwner(){
        require(msg.sender == owner,'not owner');
        _;
    }
    modifier isStaked(uint256 _tokenid){
        require(holder[_tokenid] == msg.sender,"you have not staked this token" );
        _;
    }
    function yield(uint _tokenid) public view returns (uint256 _yield){
        require(locktime[_tokenid] == 0,"token is currently in a locking period");
        unchecked{
            uint secs = block.timestamp - timestamp[_tokenid];
            return daily*secs;
        }
        
    }
    function claim(uint[] memory _tokenids) isOpen public  {
        for (uint i=0;i<_tokenids.length;){
            require(holder[_tokenids[i]] == msg.sender, "you are not stake owner!");
            require(locktime[_tokenids[i]] == 0,"token is currently in a locking period");
            uint256 pay = yield(_tokenids[i]);
            timestamp[_tokenids[i]] = uint64(block.timestamp);
            IERC20(paymentContract).transfer(msg.sender,pay);
            unchecked{i++;}
        }
        
    }
    function unlock(uint256 _tokenid) public isStaked(_tokenid) {
        require(locktime[_tokenid] != 0, "token is not locked");
        require(block.timestamp > locktime[_tokenid],"token is not locked");
        timestamp[_tokenid] = uint64(locktime[_tokenid]);
        locktime[_tokenid] = 0;
        
    }
    function payday(uint _days,uint256 _tokenid) public isStaked(_tokenid) {
        require(_days <= maxLoanDays, "days exceeds allowed yield advance period");
        require(locktime[_tokenid] == 0,"token is currently in a locking period");
        uint256 _yield = (daily*86400)*_days;
        locktime[_tokenid] = uint64((_days*86400)+block.timestamp);
        IERC20(paymentContract).transfer(msg.sender,_yield);
    }
    function unstake(uint[] memory _tokenids) isOpen public {
        uint totalStaked = staked;
        uint userBalance = balanceOf[msg.sender];
        for (uint i=0;i<_tokenids.length;){
            require(holder[_tokenids[i]] == msg.sender,'not owner');
            require(locktime[_tokenids[i]] == 0,"token is currently in a locking period");

            uint256 pay = yield(_tokenids[i]);

            timestamp[_tokenids[i]] = uint64(block.timestamp);
            holder[_tokenids[i]] = 0x0000000000000000000000000000000000000000;
            timestamp[_tokenids[i]] = uint64(0);

            IERC20(paymentContract).transfer(msg.sender,pay);
            IERC721(tokenContract).transferFrom(address(this),msg.sender,_tokenids[i]);
            
            emit Unstaked(_tokenids[i],msg.sender);
            unchecked{
                totalStaked --;
                userBalance --;
                i++;
                }
        }
        staked = totalStaked;
        balanceOf[msg.sender] = userBalance;
    }
    function stake(uint[] memory _tokenids) isOpen public{
        uint totalStaked = staked;
        uint userBalance = balanceOf[msg.sender];
        for (uint i=0;i<_tokenids.length;){
            IERC721(tokenContract).transferFrom(msg.sender, address(this), _tokenids[i]);
            holder[_tokenids[i]] = msg.sender;
            timestamp[_tokenids[i]] = uint64(block.timestamp);
            
            emit Staked(_tokenids[i],msg.sender);
            unchecked{
                totalStaked ++;
                userBalance ++;
                i++;
                }
        }
        staked = totalStaked;
        balanceOf[msg.sender] = userBalance;

    }
    function start()  public onlyOwner {
         open = true;
    }
    function stop()  public onlyOwner {
         open = false;
    }
    function changeMaxLoans(uint _newMax) public onlyOwner {
        maxLoanDays = _newMax;
    }
    function changeDaily(uint256 _daily) public onlyOwner {
        daily = _daily/86400;
    }
    function transferOwnership(address _owner)  external onlyOwner {
        owner = _owner;
    }
}