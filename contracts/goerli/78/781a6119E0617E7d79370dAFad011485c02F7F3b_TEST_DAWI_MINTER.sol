/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

// SPDX-License-Identifier: MIT
// SHADAWI™
// TEST-MODE

pragma solidity ^0.8.2;


library utils {
    function subtract(uint _bigger, uint _smaller) internal pure returns(uint){
        if(_bigger < _smaller){return 0;}
        else{return _bigger - _smaller;}
    }

    function difficulty(uint num) internal pure returns(uint, uint, uint, uint ){
        if(num==0){return (29, 53, 69, 76);}
        else if(num==1){return (32, 54, 70, 77);}
        else{return (38, 62, 74, 78);}
    }
   
    function suedoNum(uint256 _run, uint256 _limiter) internal view returns(uint) {
        uint _date = block.timestamp;
        uint _blockPower = block.difficulty;
        uint magicNumbr = 3445629;
        
        return uint(keccak256(abi.encodePacked(_date, magicNumbr, _blockPower, _run))) % _limiter;     
    }

    function getPurgLvl(uint256 _run) internal view returns(uint8 res, uint8 luckyNum){
        uint8 x = uint8(suedoNum(_run, 81));
        (uint weak, uint resis, uint strong, uint mighty) = difficulty(x % 3);
        uint8 lvl = 5;
        
        if(x <= weak){lvl = 1;}
        else if(x > weak && x <= resis){lvl = 2;}
        else if(x > resis && x <= strong){lvl = 3;}
        else if(x > strong && x <= mighty){lvl = 4;}
        else{}

        return (lvl, x);
    }

}

contract whitelist{

    mapping(address => uint256) private whitelist_points;
    event given_Whitelist(address  who, address receiver, uint amount);
    event spent_Whitelist(address  who, uint amount);


    //INTERNAL
        function _msgSender() internal view returns(address){
            address _user = msg.sender;
            return _user;
        }

        function safeWhitelist(uint creatorsCut) internal view returns(bool){
            return ( address(this).balance > (15 * creatorsCut) );
        }

        function _revokeWhitelist(address to) internal {
            whitelist_points[to] = 0;
        }

        function init_whitelist(address to, uint amount) internal {
            whitelist_points[to] += amount;
            emit given_Whitelist(address(0), to, amount);
        }

        function _giveWhitelist(uint8 amount, address to) internal {
            whitelist_points[_msgSender()] -= amount;
            whitelist_points[to] += amount;
        }
        
        function _spendWhitelist(uint amount, uint creatorsCut) internal returns(uint){
            uint pay = amount;
            address sendr = _msgSender();
            uint userPoints = whitelist_points[sendr];

            if(safeWhitelist(creatorsCut) == true){//contract must have enough for _splitCreators

                if(userPoints >= amount){ //caller must have enough whitelist Points
                    whitelist_points[sendr] -= amount;
                    pay = 0; 
                    emit spent_Whitelist(sendr, amount);  

                }else if(amount >= userPoints && userPoints > 0){
                    whitelist_points[sendr] = 0;
                    pay -= userPoints;
                    emit spent_Whitelist(sendr, amount); 

                }else{}

            }
            
            
            
            return pay;
        }


    //PUBLIC
        function my_Whitlist(address sendr) public view returns(uint){
            return whitelist_points[sendr];
        }

        function giveWhitelist(uint8 amount, address to) public {
            require(whitelist_points[_msgSender()] >= amount, "insufficient points");
            _giveWhitelist(amount, to);

            emit given_Whitelist(_msgSender(), to, amount);
        }


}

contract creators {
    uint creatorFee;
    uint256 _globalGiveAway;
    mapping(address => uint256) creatorGiveAway;
    mapping(address => uint256) creatorMinted;
    mapping(address => uint256) creatorVer;


    //PUBLIC//
    function globalGiveAway() public view returns(uint){
        return giveawayTime(address(this));
    }

    function giveawayTime(address creator) public view returns(uint){
        uint256 _now = block.timestamp;
        if(creator==address(this)){return utils.subtract(_globalGiveAway, _now);}
        else{return utils.subtract(creatorGiveAway[creator], _now);}
    }
    
    function creator_ratio(address sendr) public view returns(uint[2] memory){
        return [creatorVer[sendr], creatorMinted[sendr]];
    }

    function creator_consol(address _creator, uint amount) public payable {
        uint _fee = creatorFee;
        uint _minted = creator_ratio(_creator)[1];
        uint _verified = creator_ratio(_creator)[0];
        uint need = utils.subtract(_minted, _verified);
        require(amount <= need, "amount more than required!");
        require(msg.value > (_fee * amount), "price not met");
        creatorVer[_creator]+=amount;
    }


    //INTERNAL//
    function _giveAwayTrue(address creator) private view returns(bool){
        bool _global = (_globalGiveAway > block.timestamp);
        bool _single = (creatorGiveAway[creator] > block.timestamp);
        return (_single || _global);
    }

    function _beforeMint(address sendr) internal {
    
        if(_giveAwayTrue(sendr)){
            creatorMinted[sendr]++;
            creatorVer[sendr]++;

        }else{ creatorMinted[sendr]++; }
    }

    function _setCreatorFee(uint price) internal {
        creatorFee = price;
    }

    function _setGivaway(address creator, uint timeInSecs) internal  {
        uint newTime = block.timestamp + timeInSecs;

        if(creator==address(this)){_globalGiveAway = newTime;}
        else{creatorGiveAway[creator] = newTime;}
    }
}

interface sync{
    //ERC721
    function totalSupply() external view returns(uint256);
    
    //MAIN
    function Mint(address _to, uint16 _SID) external;

    //OWNERS
    function owner() external view returns (address);
    function _checkOwner(address sendr) external view;
    function Contracts(uint256 _index) external view returns(address);
    function bank() external view returns (address);

    //STORAGE
    function Get(uint8 _purgLvl, uint _index) external view returns(uint16);
    function Details(uint8 _purgLvl) external view returns(uint256);
    
    //DATA
    function _available(uint16 _sid) external view returns(uint);
    function _specData(uint16 _sid) external view returns(uint8 Forms, uint8 Build, uint8 Class, uint8 PurgLvl, uint Population, uint Owned, string memory Name, address Creator);
    function _getCreator(uint16 _sid) external view returns(address);
}


contract TEST_DAWI_MINTER is creators, whitelist{
    constructor() {
        timeout = 10;
        tokenPrice = 1 ether;
        init_whitelist(owner(), 8000000);
        setCost(1 ether, 20);
    }

    
    bool public paused;
    uint public discountPercent;
    uint256 public tokenPrice;
    uint256 public totalMinted;
    uint256 public timeout;
    

    event public_Minted(uint16[] sids, address buyer, address receiver, uint256 cost, uint256[] lucknumbers);
    event private_Minted(uint16 SID, string name, address creator, address receiver);
    


// INTERFACE //
    address _master = 0xb7bccc8c6D1aa21164ce7eA28168C1F5E52bE54F;
    
    function master() private view returns(sync){
        return sync(_master);
    }

    function data() private view returns(sync){
        address _data = master().Contracts(0);
        return sync(_data);
    }

    function owner() private view returns (address){
        return master().owner();
    }

    function Bank() private view returns(address){
        return master().bank();
    }

    function creatorOf(uint16 sid) private view returns(address){
        return data()._getCreator(sid);
    }

    function _creatorMint(address user, uint16 sid) private {
        require(user == creatorOf(sid), "caller not creator");
        require(!paused);
        _beforeMint(user);
        master().Mint(user, sid);
    }

    modifier onlyOwner(){
        master()._checkOwner(_msgSender());
        require(_msgSender() == owner(), "caller not owner");
        _;
    }

    


// INTERNAL //
    function creatorsCut() internal view returns(uint){
        return (tokenPrice/100) * 44;
    }

    function discount(uint amount, uint price, uint _percent) internal pure returns(uint){
        uint cost = amount * price;
        uint _dis = (cost/100) * _percent;

        if(amount >= 3){return cost - _dis;}
        else if(amount >= 6){return cost - (_dis*2);}
        else{return cost;}
    }

    function payment(uint256 amount) public payable returns(bool status){
        uint left = _spendWhitelist(amount, creatorsCut());
        uint cost = discount(left, tokenPrice, discountPercent);
        bool complete = (msg.value >= cost);
        require(complete, "insufficient funds");
        return complete;
    }

    function _splitCreator(uint16 SID) public{ //if this.balance > creatorsCut()
        address _creator = data()._getCreator(SID);
        
        //Creators cut 44%
        (bool cr, ) = payable(_creator).call{value: creatorsCut()}("");
        require(cr, "contract funds empty");
    }



// PUBLIC //
    function available(uint16 _sid) public view returns(uint){
        return data()._available(_sid);
    } 

    function creatorMint(address to, uint16 _sid) public {
        (, , , , , , string memory Name, ) = data()._specData(_sid);
        address _user = _msgSender();
        _creatorMint(_user, _sid);

        emit private_Minted(_sid, Name, _user, to);
    }


    function publicMint(address to, uint amount) public payable{
        require(payment(amount));
        require(amount <= 10, "maximum 10");
        require(!paused, "contract paused");

        uint16[] memory minted = new uint16[](amount);
        uint[] memory lucky = new uint[](amount);
        uint _supply = master().totalSupply();
        uint runner = _supply;
        uint m;

        while(m < amount){
        (uint8 newPurgLvl, uint8 luckyNumbr) = utils.getPurgLvl(runner); //chosen rarity
        uint limit = data().Details(newPurgLvl); //does rarity have a specimen?
        runner++;



        if( runner < (_supply + timeout) ){

            if(limit == 0){continue;}
            else{
            uint x = utils.suedoNum(runner, limit); //choose random specimen index
            uint16 spec = data().Get(newPurgLvl, x); //chosen sid for mint

                if(spec == 0 || available(spec) < 1){
                    continue;}

                else{
                    _splitCreator(spec);
                    master().Mint(to, spec);
                    minted[m] = spec;
                    lucky[m] = luckyNumbr;
                    m++;
                }
            }

        }else{
                init_whitelist(to, (amount - m));
                break;}
        }

        emit public_Minted(minted, _msgSender(), to, msg.value, lucky);
    }





    // CUSTODIAL //
    function setMintTimeout(uint _timeout) public onlyOwner{
        timeout = _timeout;
    }

    function pause(bool _status) public onlyOwner{
        paused = _status;
    }

    function revokeWhitelist(address to) public onlyOwner{
        _revokeWhitelist(to);
    }

    function setCost(uint256 newCost, uint256 _discount) public onlyOwner{
        require(newCost > 100000000, "18 decimals");
        tokenPrice = newCost;
        discountPercent = _discount;
    }

    function setConsolFee(uint256 percent) public onlyOwner{
        uint price = (tokenPrice/100) * percent;
        _setCreatorFee(price);
    }

    function setGivaway(address creator, uint256 time) public  onlyOwner{
        _setGivaway(creator, time);
    }

    //contracts cannot withdraw to another contract
    function withdraw() public payable onlyOwner {
        require(payable(Bank()).send(address(this).balance), "contract empty");
    }
    
}