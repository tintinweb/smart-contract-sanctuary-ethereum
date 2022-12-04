/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.17;




contract HuluToken {

    struct Locktokeninfo{

        uint256 amount;
        uint256 start;
        uint256 duration;
        
    }

    struct Listing {
        uint256 price;
        address seller;
    }

    //储存每一个地址银葫芦的数量
    mapping(address => uint256) private _s_balances;

    //储存每一个地址金葫芦的数量
    mapping(address => uint256) private _g_balances;
    mapping(address => uint256) private _sell_balances;

    mapping(address => Locktokeninfo[]) private locktokeninfoArray;

   Listing[] private listingArray;


    address owner;
    uint256 private _s_totalSupply =0;
    uint256 private _g_totalSupply =0;

    string private _name;
    string private _symbol;

    constructor(){

        owner=msg.sender;

    }

    
    modifier onlyOwner(){
        require(msg.sender==owner,"Not Owner");
        _;
    }

    function mint (address to, uint amount)public onlyOwner{


        _s_totalSupply += amount;
        _s_balances[to] += amount; 

    }

    function mintLocked (address to,uint amount,uint256 locktime)public onlyOwner{


        _s_totalSupply += amount;
        _s_balances[owner] += amount; 
        Locktokeninfo memory lockten =Locktokeninfo(amount,block.timestamp,locktime);
        locktokeninfoArray[to].push(lockten);

    }

    function listGhulu(uint256 price)public{
        require(balanceOfGhulu(msg.sender)>=1,"you don't have Ghulu to sell");
        require(balanceOfShulu(msg.sender)>=5,"you don't have 5 Shulu to cover trade fee");
        listingArray.push(Listing(price,msg.sender));
        _ShuluinteralTransfer(msg.sender,owner,5);
        _GhuluInternalTransfer(msg.sender,owner,1);

    }




    function getListGhulu(uint256 saleNumber)public  view returns(Listing memory){

        return listingArray[saleNumber];
 
    }

    function buyAGhulu(uint256 saleNumber)public payable{

        require(listingArray[saleNumber].price > 0,"doesn't enough ehth");

        require(saleNumber < listingArray.length,"salenumber do not exsit");
        require(msg.value >= listingArray[saleNumber].price,"doesn't enough ehth");
        
        _GhuluInternalTransfer(owner,msg.sender,1);
        _sell_balances[listingArray[saleNumber].seller] = listingArray[saleNumber].price;
        burnShulu(owner,5);
        delete listingArray[saleNumber];

    }


    function CancleSllerGhulu(uint256 saleNumber)public{

        require(saleNumber < listingArray.length,"salenumber do not exsit");
        require(msg.sender == listingArray[saleNumber].seller,"you are not the seller");
        _GhuluInternalTransfer(owner,msg.sender,1);
        _ShuluinteralTransfer(owner,msg.sender,5);
       
        delete listingArray[saleNumber];



    }

    function claimBalance()public{

        uint256 proceeds = _sell_balances[msg.sender];
        _sell_balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
            if (!success) {
        revert("oh my god ");
        }

    }

    function getBalance()public view returns(uint256){

    return _sell_balances[msg.sender];

    }

    
    function claimtoken()public{


        uint256 claimabeletoken = blanceOfUnlockedHhulu();

        _ShuluinteralTransfer(owner,msg.sender,claimabeletoken);

        uint256 size =locktokeninfoArray[msg.sender].length;

        if( size<=0){
            revert("somethingbadhappend");
        }
        for (uint i = 0; i < size; i++) {

        if(block.timestamp>=(locktokeninfoArray[msg.sender][i].start +locktokeninfoArray[msg.sender][i].duration)){

            delete locktokeninfoArray[msg.sender][i];
                  
        }

    
        }


    }

    function blanceOfUnlockedHhulu()public view returns(uint256){

        uint256 size =locktokeninfoArray[msg.sender].length;
        uint256 unlockedamount=0;
        if( size<=0){
            return unlockedamount;
        }
        for (uint i = 0; i < size; i++) {
        if(block.timestamp>=(locktokeninfoArray[msg.sender][i].start +locktokeninfoArray[msg.sender][i].duration)){

                  unlockedamount+=locktokeninfoArray[msg.sender][i].amount;

        }

  
    
        }
        return unlockedamount;

    }

    function blanceOflockedHhulu()  public  view returns(uint256){

        uint256 size =locktokeninfoArray[msg.sender].length;
        uint256 lockedamount=0;
        if( size<=0){
            return lockedamount;
        }
        for (uint i = 0; i < size; i++) {
        
                if(block.timestamp<(locktokeninfoArray[msg.sender][i].start +locktokeninfoArray[msg.sender][i].duration)){

                  lockedamount+=locktokeninfoArray[msg.sender][i].amount;

        }

    
        }
        return lockedamount;

        
    }





    

    function _GhuluTransfer(address from, address to, uint amount) public onlyOwner{

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(to != from, "ERC20: transfer to sameaddress");

        uint256 fromBalance = _g_balances[from];
        uint256 fromShuluBalance = _s_balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        require(fromShuluBalance >= 5, "ERC20: transfer amount exceeds balance");


            burnShulu(from,5);
            _g_balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _g_balances[to] += amount;
        
    }

    function _GhuluInternalTransfer(address from, address to, uint amount) internal {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(to != from, "ERC20: transfer to sameaddress");

        uint256 fromBalance = _g_balances[from];
        uint256 fromShuluBalance = _s_balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        require(fromShuluBalance >= 5, "ERC20: transfer amount exceeds balance");


            // burnShulu(from,5);
            _g_balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _g_balances[to] += amount;
        
    }




        function _GhuluSelfTransfer( address to, uint amount) public {

        address from =msg.sender;

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(to != from, "ERC20: transfer to you own");

        uint256 fromBalance = _g_balances[from];
        uint256 fromShuluBalance = _s_balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds g_balance");
        require(fromShuluBalance >= 5, "ERC20: transfer amount exceeds s_balance");


            burnShulu(from,5);
            _g_balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _g_balances[to] += amount;
        

    }


    function _ShuluSelfTransfer( address to, uint amount) public {

        address from =msg.sender;

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(to != from, "ERC20: transfer to you own");


        uint256 fromShuluBalance = _s_balances[from];

            _s_balances[from] = fromShuluBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _s_balances[to] += amount;
        
    }

        function _ShuluinteralTransfer( address from,address to, uint amount) internal {


        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(to != from, "ERC20: transfer to you own");


        uint256 fromShuluBalance = _s_balances[from];

            _s_balances[from] = fromShuluBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _s_balances[to] += amount;
        

    }
    // 每次转账永久消耗5个葫芦
    function burnShulu(address addr ,uint amount) internal {

        require(addr != address(0), "ERC20: burn from the zero address");

   

        uint256 accountBalance = _s_balances[addr];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        
        _s_balances[addr] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
        _s_totalSupply -= amount;
     

    }

        function getClaimTime(uint number ) public view returns(uint){

        uint256 size =locktokeninfoArray[msg.sender].length;
         if(size ==0){
             return 0;
         }
         return locktokeninfoArray[msg.sender][number].start+locktokeninfoArray[msg.sender][number].duration;
        
    }


    function getShuluSupply() public view returns(uint){
        return _s_totalSupply;
        
    }
        function getGhuluSupply() public view returns(uint){
        return _g_totalSupply;
        
    }

    function combineShuluToGhulu() public {
        require(balanceOfShulu(msg.sender)>=100,"you need at least 100 silver hulu");
        _s_balances[msg.sender] -=100;
        _g_balances[msg.sender] +=1;
        _g_totalSupply += 1;
        _s_totalSupply -=100;

    }

    function decombineGhuluToShulu() public {
        require(balanceOfGhulu(msg.sender)>=1,"you need at least 1 gold hulu");
        _s_balances[msg.sender] +=100;
        _g_balances[msg.sender] -=1;
        _g_totalSupply -= 1;
        _s_totalSupply +=100;

    }

    


    function balanceOfShulu(address addr) public view returns(uint){
        return _s_balances[addr];
    }


    function balanceOfGhulu(address addr) public view returns(uint){
        return _g_balances[addr];
    }


    
}