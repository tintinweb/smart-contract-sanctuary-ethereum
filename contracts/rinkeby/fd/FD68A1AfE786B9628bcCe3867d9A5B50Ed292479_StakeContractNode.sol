/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

// 0.Owner 만능 기능
// 1.분할양도,전체양도시 수수료 발생. 이부분 해결이 필요함. (컨트랙트에 쓰기를 하기 때문인듯)

contract StakeContractNode {
    // uint EtherUnit = 1e18; // 1e18 wei = 1 ether
    uint FinneyUnit = 1e9; //1e9(테스트용 0.25ether)  1e15; // 1e15 wei = 1 finney
    address payable ContractOwner ; //컨트랙트 생성권한자
    address payable ContractRecovery ; //컨트랙트 회수권한자 recovery account

    // whole:0, half:1, quarter:2, eight:3, sixteen:4, thirtysecond:5 //
    enum stakeTypes { whole, half, quarter, eight, sixteen, thirtysecond } 

    //기준 단위 finney  (1 ether = 1000 finney)
    uint[6] nodeAmounts = [250000000, 125000000, 62500000, 31250000, 15625000, 7812500];
    uint[6] interests = [380520, 152210, 66590, 28540, 13080, 5950];  // byDay

    struct StakeContract {
        address payable owner;
        uint amount;
        bytes32 hashlock; // sha-2 sha256 hash
        uint timelock; // UNIX timestamp seconds - locked UNTIL this time
        bool withdrawn;
        bool discard;
        // bytes32 preimage;
    }

    struct TermsInfo{
        bytes32 stakeId;
        address payable staker;
        stakeTypes stakeType;  // 0,1,2,3,4,5
        uint amount;   
        uint interest; //이자 1day
        uint salesAuth1; // max2
        uint salesAuth2; // max4
        uint salesAuth3; // max8
        uint salesAuth4; // max16
        uint salesAuth5; // max32
        address transferee ;  //양수인
        bool withdrawn; // 만기출금
        bool discard; // 중도해지
    }

    mapping (bytes32 => StakeContract) Stakes;
    mapping (bytes32 => mapping (address => TermsInfo)) Terms;
    mapping (address => TermsInfo) Stakers; //내부 검증용

    event returnStakeID(bytes32 stakeId);
            
    modifier onlyOwner{ // 기초확인 - 계약 생성자 권한 
        require(msg.sender==ContractOwner, "Only Owner function");
        _;
    }
    modifier fundsSent(uint _value) { // 신규노드 - 스테킹 수량 //test 2.5ether
        require(_value >= 250000000*FinneyUnit, "msg.value must be > 0.25 ether");
        _;
    }
    modifier futureTimelock(uint _time) { // 신규노드 - 스테킹 기간
        require(_time > now, "timelock time must be in the future");
        _;
    }
    modifier sameStaker(address _staker){ // 자기 계정 확인
        require(msg.sender != _staker, "cannot sell to myself");
        _;
    }
    modifier newStaker(address _staker){ // 신규 새게정인지 확인
        require(!haveContract(_staker), "This Staker already join");
        _;
    }
    modifier contractExists(bytes32 _stakeId) { // 계약이 있는지 확인
        require(haveStake(_stakeId), "StakeId does not exist");
        _;
    }
    modifier checkOwnStaker(bytes32 _stakeId, address _staker) { // 양도판매 소유권 유효 확인
        require(Terms[_stakeId][_staker].staker == _staker, "Not This Stake Member");
        _;
    }
    modifier hashlockMatches(bytes32 _stakeId, bytes32 _x) {
        require(Stakes[_stakeId].hashlock == _x, "hashlock hash does not match");
        _;
    }
    modifier endStake(bytes32 _stakeId) { // 만기일 확인
        require(Stakes[_stakeId].timelock <= now, "endStake: staking time not yet passed");
        _;
    }
    modifier checkAuth(bytes32 _stakeId, stakeTypes _shareType) { // 양도판매 - 판매 권한 및 수량 확인
        require(uint(Terms[_stakeId][msg.sender].stakeType) < uint(_shareType), "You don't have permission.");
        _;
    }
    modifier checkTransferee(address _staker) { // 양도해지 확인
        require(Stakers[_staker].transferee == address(0), "already transferred.");
        _;
    }
    modifier checkWithdrawn(address _staker) { // 만기해지 확인
        require(Stakers[_staker].withdrawn == false, "already withdrawn.");
        _;
    }
    modifier checkDiscard(address _staker) { // 중도해지 확인
        require(Stakers[_staker].discard == false, "already Discard Stake.");
        _;
    }

    constructor() public payable{
        ContractOwner = msg.sender;
        ContractRecovery = address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2); //임의 JS VM용
    }

    // 1. 신규노드 판매 (1노드 단위)
    function CheckStakingNewNode(address _staker, bytes32 _hashlock, uint _timelock, uint _value) public view
        onlyOwner fundsSent(_value) futureTimelock(_timelock) newStaker(_staker) returns(bytes32) { 
            bytes32 dmy = sha256( abi.encodePacked(_value, _staker, _hashlock, _timelock )); return dmy;}
    function StakingNewNode(address payable _staker, bytes32 _hashlock, uint _timelock, uint _value)
        external payable onlyOwner fundsSent(_value) futureTimelock(_timelock) newStaker(_staker) returns (bytes32 stakeId )
     {
        stakeId = sha256( abi.encodePacked(msg.sender, _staker, _hashlock, now, _timelock ));

        if (haveStake(stakeId))
            revert("Contract already exists");

        Terms[stakeId][_staker] = TermsInfo(
            stakeId,
            _staker,
            stakeTypes.whole,
            nodeAmounts[uint(stakeTypes.whole)]*FinneyUnit, // 0.25ether 250 finney
            interests[uint(stakeTypes.whole)]*FinneyUnit,
            2,4,8,16,32,
            address(0),
            false,
            false
        );

        Stakers[_staker] = Terms[stakeId][_staker] ;

        Stakes[stakeId] = StakeContract(
            msg.sender,
            nodeAmounts[uint(stakeTypes.whole)]*FinneyUnit,
            _hashlock,
            _timelock,
            false,
            false
        );

        emit returnStakeID(stakeId);
    }

    // 2. 노드 분할 판매
    function CheckStakingNodeShare(bytes32 _stakeId, address _shareStaker, stakeTypes _shareType) public view
        contractExists(_stakeId) checkOwnStaker(_stakeId, msg.sender) checkAuth(_stakeId, _shareType) newStaker(_shareStaker) 
        checkTransferee(msg.sender) checkWithdrawn(msg.sender) checkDiscard( msg.sender)  returns(bytes32) { 
            bytes32 dmy = sha256( abi.encodePacked(_stakeId, _shareStaker, _shareType )); return dmy;}
    function StakingNodeShare(bytes32 _stakeId, address payable _shareStaker, stakeTypes _shareType) 
        contractExists(_stakeId) checkOwnStaker(_stakeId, msg.sender) checkAuth(_stakeId, _shareType) newStaker(_shareStaker) 
        checkTransferee(msg.sender) checkWithdrawn(msg.sender) checkDiscard( msg.sender) external payable 
     {
        //shareType에 따라 분배 / 계약내용 변경
        TermsInfo storage i = Terms[_stakeId][msg.sender];
        i.amount = i.amount - (nodeAmounts[uint(_shareType)]*FinneyUnit) ;
        
        if(uint(_shareType) == 1){
            if(i.salesAuth1 > 0){
               Terms[_stakeId][_shareStaker] = TermsInfo(
                    _stakeId,
                    _shareStaker,
                    _shareType,
                    nodeAmounts[uint(_shareType)]*FinneyUnit,
                    interests[uint(_shareType)]*FinneyUnit,
                    0,2,4,8,16,
                    address(0),
                    false,
                    false
                ); 
                i.interest = i.interest - (interests[uint(_shareType)]*FinneyUnit);

                i.salesAuth5 =  i.salesAuth5-16;
                i.salesAuth4 =  i.salesAuth4-8;
                i.salesAuth3 =  i.salesAuth3-4;
                i.salesAuth2 =  i.salesAuth2-2;
                i.salesAuth1 =  i.salesAuth1-1;
            }
        }

        if(uint(_shareType) == 2){
            if(i.salesAuth2 > 0){
                Terms[_stakeId][_shareStaker] = TermsInfo(
                    _stakeId,
                    _shareStaker,
                    _shareType,
                    nodeAmounts[uint(_shareType)]*FinneyUnit,
                    interests[uint(_shareType)]*FinneyUnit,
                    0,0,2,4,8,
                    address(0),
                    false,
                    false
                );
                i.interest = i.interest - (interests[uint(_shareType)]*FinneyUnit);

                i.salesAuth5 =  i.salesAuth5-8; 
                i.salesAuth4 =  i.salesAuth4-4;
                i.salesAuth3 =  i.salesAuth3-2;
                i.salesAuth2 =  i.salesAuth2-1;
                if(uint(i.stakeType) == 0){
                    if(i.salesAuth2 < 2){ //보정
                        i.salesAuth1 =  0;
                    }else{
                        i.salesAuth1 =  1;
                    } 
                }
            }
        }

        if(uint(_shareType) == 3){
            if(i.salesAuth3 > 0){
                Terms[_stakeId][_shareStaker] = TermsInfo(
                    _stakeId,
                    _shareStaker,
                    _shareType,
                    nodeAmounts[uint(_shareType)]*FinneyUnit,
                    interests[uint(_shareType)]*FinneyUnit,
                    0,0,0,2,4,
                    address(0),
                    false,
                    false
                );
                i.interest = i.interest - (interests[uint(_shareType)]*FinneyUnit);

                i.salesAuth5 =  i.salesAuth5-4;
                i.salesAuth4 =  i.salesAuth4-2;
                i.salesAuth3 =  i.salesAuth3-1;
                if(uint(i.stakeType) == 1){
                    if(i.salesAuth3 < 2){ //보정
                        i.salesAuth2 =  0;
                    }else{
                        i.salesAuth2 =  1;
                    }
                }
                if(uint(i.stakeType) == 0){
                    if(i.salesAuth3/2 < i.salesAuth2){ //보정
                        i.salesAuth2 =  i.salesAuth2-1;
                    }
                    if(i.salesAuth2 < 2){ //보정
                        i.salesAuth1 =  0;
                    }else{
                        i.salesAuth1 =  1;
                    } 
                }
            }
        }

        if(uint(_shareType) == 4){
            if(i.salesAuth4 > 0){
                Terms[_stakeId][_shareStaker] = TermsInfo(
                    _stakeId,
                    _shareStaker,
                    _shareType,
                    nodeAmounts[uint(_shareType)]*FinneyUnit,
                    interests[uint(_shareType)]*FinneyUnit,
                    0,0,0,0,2,
                    address(0),
                    false,
                    false
                );
                i.interest = i.interest - (interests[uint(_shareType)]*FinneyUnit);

                i.salesAuth5 =  i.salesAuth5-2;
                i.salesAuth4 =  i.salesAuth4-1;
                if(uint(i.stakeType) == 2){
                    if(i.salesAuth4 < 2){ //보정
                        i.salesAuth3 =  0;
                    }else{
                        i.salesAuth3 =  1;
                    } 
                }
                if(uint(i.stakeType) == 1){
                    if(i.salesAuth4/2 < i.salesAuth3){ //보정
                        i.salesAuth3 =  i.salesAuth3-1;
                    }
                    if(i.salesAuth3 < 2){ //보정
                        i.salesAuth2 =  0;
                    }else{
                        i.salesAuth2 =  1;
                    } 
                }
                if(uint(i.stakeType) == 0){
                    if(i.salesAuth4/2 < i.salesAuth3){ //보정
                        i.salesAuth3 =  i.salesAuth3-1;
                    }
                    if(i.salesAuth3/2 < i.salesAuth2){ 
                        i.salesAuth2 =  i.salesAuth2-1;
                    }
                    if(i.salesAuth2 < 2){ //보정
                        i.salesAuth1 =  0;
                    }else{
                        i.salesAuth1 =  1;
                    }  
                }
            }
        }

        if(uint(_shareType) == 5){
            if(i.salesAuth5 > 0){
                Terms[_stakeId][_shareStaker] = TermsInfo(
                    _stakeId,
                    _shareStaker,
                    _shareType,
                    nodeAmounts[uint(_shareType)]*FinneyUnit,
                    interests[uint(_shareType)]*FinneyUnit,
                    0,0,0,0,0,
                    address(0),
                    false,
                    false
                );
                i.interest = i.interest - (interests[uint(_shareType)]*FinneyUnit);

                i.salesAuth5 =  i.salesAuth5-1;
                if(uint(i.stakeType) == 3){
                    if(i.salesAuth5 < 2){ //보정
                        i.salesAuth4 =  0;
                    }else{
                        i.salesAuth4 =  1;
                    } 
                }
                if(uint(i.stakeType) == 2){
                    if(i.salesAuth5/2 < i.salesAuth4){ //보정
                        i.salesAuth4 =  i.salesAuth4-1;
                    }
                    if(i.salesAuth4 < 2){ //보정
                        i.salesAuth3 =  0;
                    }else{
                        i.salesAuth3 =  1;
                    } 
                }
                if(uint(i.stakeType) == 1){
                    if(i.salesAuth5/2 < i.salesAuth4){ //보정
                        i.salesAuth4 =  i.salesAuth4-1;
                    }
                    if(i.salesAuth4/2 < i.salesAuth3){ 
                        i.salesAuth3 =  i.salesAuth3-1;
                    }
                    if(i.salesAuth3 < 2){ //보정
                        i.salesAuth2 =  0;
                    }else{
                        i.salesAuth2 =  1;
                    } 
                }
                if(uint(i.stakeType) == 0){
                    if(i.salesAuth5/2 < i.salesAuth4){ //보정
                        i.salesAuth4 =  i.salesAuth4-1;
                    }
                    if(i.salesAuth4/2 < i.salesAuth3){ //보정
                        i.salesAuth3 =  i.salesAuth3-1;
                    }
                    if(i.salesAuth3/2 < i.salesAuth2){ 
                        i.salesAuth2 =  i.salesAuth2-1;
                    }
                    if(i.salesAuth2 < 2){ //보정
                        i.salesAuth1 =  0;
                    }else{
                        i.salesAuth1 =  1;
                    } 
                }
            }
        }
        Stakers[_shareStaker] = Terms[_stakeId][_shareStaker] ;

        // mapping Stakers clone
        TermsInfo storage s = Stakers[msg.sender];
        s.amount = i.amount;  
        s.interest = i.interest;
        s.salesAuth1 = i.salesAuth1;
        s.salesAuth2 = i.salesAuth2;
        s.salesAuth3 = i.salesAuth3;
        s.salesAuth4 = i.salesAuth4;
        s.salesAuth5 = i.salesAuth5;
    }
    // 3. 노드 양도 판매
    function CheckSkakingOwnershipTransfer(bytes32 _stakeId, address _newstaker) public view
        contractExists(_stakeId) checkOwnStaker(_stakeId, msg.sender) newStaker(_newstaker)  
        checkTransferee(msg.sender) checkWithdrawn(msg.sender) checkDiscard(msg.sender) returns(bytes32) { 
            bytes32 dmy = sha256( abi.encodePacked(_stakeId, _newstaker )); return dmy;}
    function SkakingOwnershipTransfer(bytes32 _stakeId, address payable _newstaker)
        contractExists(_stakeId) checkOwnStaker(_stakeId, msg.sender) newStaker(_newstaker) 
        checkTransferee(msg.sender) checkWithdrawn(msg.sender) checkDiscard(msg.sender) external payable 
     {
        TermsInfo storage i = Terms[_stakeId][msg.sender];
        
        Terms[_stakeId][_newstaker] = TermsInfo(
            i.stakeId,
            _newstaker,
            i.stakeType,
            i.amount,
            i.interest,
            i.salesAuth1,
            i.salesAuth2,
            i.salesAuth3,
            i.salesAuth4,
            i.salesAuth5,
            i.transferee,
            i.withdrawn,
            i.discard
        );

        Stakers[_newstaker] = Terms[_stakeId][_newstaker] ;
        i.amount = 0 ;
        i.interest = 0;
        i.transferee = _newstaker;        
    
        TermsInfo storage s = Stakers[msg.sender];
        s.amount = 0 ;
        s.interest = 0;
        s.transferee = _newstaker;        
    }
    
    /* 4. 노드 참여자 일 이자지급
    function SkakingPayInterest(bytes32 _stakeId, address payable _recipient) 
        external payable onlyOwner checkOwner(_stakeId, _recipient) checkStakeNode(_stakeId, _recipient) returns (bool)
     {
        StakeContract memory c = Stakes[_stakeId];
        if(c.timelock+900 > now){ //15분 여유 (추후 보정 필요)
            TermsInfo storage i = Terms[_stakeId][_recipient];            
            // _recipient.transfer(i.interest,"REWARD");
            _recipient.call.value(i.interest)("Rewards");
            return true;
        }
    }*/

    // 5. 노드 참여자 만기출금 (만기출금 true : 업데이트)
    function CheckStakeEnded(bytes32 _stakeId) public view
        contractExists(_stakeId) endStake(_stakeId) checkTransferee(msg.sender) checkWithdrawn(msg.sender) checkDiscard(msg.sender)
        returns(bytes32) { bytes32 dmy = sha256( abi.encodePacked(_stakeId)); return dmy;}
    function StakeEnded(bytes32 _stakeId) external
        contractExists(_stakeId) endStake(_stakeId) checkTransferee(msg.sender) checkWithdrawn(msg.sender) checkDiscard(msg.sender)  
     {
        TermsInfo storage i = Terms[_stakeId][msg.sender];
        i.withdrawn = true;
        i.staker.transfer(i.amount);

        TermsInfo storage s = Stakers[msg.sender];
        s.withdrawn = true ;
        // emit LogHTLCWithdraw(_stakeId);
    } 

    // 6. 노드 참여자 중도해지 
    function CheckStakeDiscard(bytes32 _stakeId, bytes32 _hashlock, address _staker ) public view
        onlyOwner contractExists(_stakeId) hashlockMatches(_stakeId, _hashlock) checkOwnStaker(_stakeId, _staker)
        checkTransferee(_staker) checkWithdrawn(_staker) checkDiscard(_staker)
        returns(bytes32) { bytes32 dmy = sha256( abi.encodePacked(_stakeId, _hashlock, _staker)); return dmy;}
    function StakeDiscard(bytes32 _stakeId, bytes32 _hashlock, address _staker )
        onlyOwner contractExists(_stakeId) hashlockMatches(_stakeId, _hashlock) checkOwnStaker(_stakeId, _staker)
        checkTransferee(_staker) checkWithdrawn(_staker) checkDiscard(_staker) external
      {
        TermsInfo storage i = Terms[_stakeId][_staker];
        i.discard = true;
        i.staker.transfer(i.amount/2); //위약 50%
        ContractRecovery.transfer(i.amount/2);

        TermsInfo storage s = Stakers[_staker];
        s.discard = true ;
    }

    // 9. 자기 노드 계약 내용 보기
    function getContract(bytes32 _stakeId) public view
        contractExists(_stakeId) checkOwnStaker(_stakeId, msg.sender) 
        returns (
            string memory StakeType,
            uint NodeAmount,
            uint interest,
            uint salesAuth,
            address transferee, //기본값 null
            bool withdrawn,
            bool discard
        )
     {
        // StakeContract memory c = Stakes[_stakeId];
        TermsInfo storage i = Terms[_stakeId][msg.sender];
        return (
            // c.owner, //계약 발급자
            // c.amount, //계약 전체 수량
            CallStakeTypes(i.stakeType), //노드 타입
            i.amount, //보유수량
            i.interest, //1일 이자
            i.salesAuth1*1000000+i.salesAuth2*100000+i.salesAuth3*10000+i.salesAuth4*100+i.salesAuth5,
            i.transferee, // 양수인
            i.withdrawn,
            i.discard
        );
    }
    // 0. 지갑주소로 계약 내용 보기 (내부용)
    function getContractByOwner(address _staker) public view
        onlyOwner 
        returns (
            bytes32 stakeId,
            string memory StakeType,
            uint NodeAmount,
            uint interest,
            uint salesAuth,
            address transferee, //기본값 null
            bool withdrawn,
            bool discard
        )
     {
        TermsInfo memory i = Stakers[_staker];
        return (
            i.stakeId,
            CallStakeTypes(i.stakeType), //노드 타입
            i.amount, //보유수량
            i.interest, //1일 이자
            i.salesAuth1*1000000+i.salesAuth2*100000+i.salesAuth3*10000+i.salesAuth4*100+i.salesAuth5,
            i.transferee, // 양수인
            i.withdrawn,
            i.discard
        );
    }


    // stakeType 키값 설명
    function CallStakeTypes(stakeTypes _x) public pure returns (string memory) {
        if (stakeTypes.whole == _x) return "whole";
        if (stakeTypes.half == _x) return "half";
        if (stakeTypes.quarter == _x) return "quarter";
        if (stakeTypes.eight == _x) return "eight";
        if (stakeTypes.sixteen == _x) return "sixteen";
        if (stakeTypes.thirtysecond == _x) return "thirtysecond";
    }  
    // node stakeId 중복확인 -  중복 return true / 신규 false ;
    function haveStake(bytes32 _stakeId) internal view returns (bool exists){
        exists = (Stakes[_stakeId].owner != address(0));
    }
    // stake 참여자 중복확인 - 중복 return true / 신규 false ;
    function haveContract(address _staker) internal view returns (bool exists){
        exists = (Stakers[_staker].stakeId != bytes32(0));
    }
    // stake 남은 수량 확인
    function haveShareStake(address _staker, uint _shareType) internal view returns (bool exists){
        TermsInfo memory i = Stakers[_staker];
        exists = false;
        if(_shareType == 1){
            if(i.salesAuth1 > 0){ exists = true;} 
        }
        if(_shareType == 2){
            if(i.salesAuth2 > 0){ exists = true;} 
        }
        if(_shareType == 3){
            if(i.salesAuth3 > 0){ exists = true;} 
        }
        if(_shareType == 4){
            if(i.salesAuth4 > 0){ exists = true;} 
        }
        if(_shareType == 5){
            if(i.salesAuth5 > 0){ exists = true;} 
        }
    }

    
}