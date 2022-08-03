/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);    

    function approve(address spender, uint value) external returns (bool);              
    function transfer(address to, uint value) external returns (bool);                  
    function transferFrom(address from, address to, uint value) external returns (bool); 

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
}

struct  allowanceOne{
    address  to;                        
    uint  i;                           
}

struct lockOne{
    uint nowClockSum;                        
    uint allClockSum;                        
    uint cTime;                              
}

struct lockSetuOne{
    uint timeLength;                          
    uint intVal;                            
}



contract bmg_main is ERC20{
    string public name;                                
    uint8 public decimals;                            
    string public symbol;                             
    uint public totalSupply;                          
    mapping(address=>uint) public allData;            
    
    mapping(string=>address) public hasSetup;    

    uint constant ALLINT=2000000000;                             

    mapping(address=>allowanceOne[]) public allowanceData;        
    uint public cTime;                                           
    address public mainAddress;                                  
    mapping(address=>lockOne) public lockBufferInfo;              //simu lock buffer
    mapping(address=>lockOne) public IDOlockBufferInfo;           //ido lock buffer
    mapping(address=>lockOne) public JIGUOlockBufferInfo;         //jigou lock buffer

    uint constant simuAllFreeTime=60*60*24*365*4;                 //all lock time
    
    lockSetuOne[] public IDOLockTimeSetup;                        //IDO lock time setup
    lockSetuOne[] public lockTimeSetup;                           //SIMU lock time setup
    lockSetuOne[] public JIGUOLockTimeSetup;                      //JIGUO lock time setup



    constructor (){                            
        mainAddress =msg.sender;                
        cTime=block.timestamp;                 
        symbol="BMG";                           
        name="BMG";
        decimals=18;
        totalSupply=ALLINT;                      

        //IDO
        uint monthTime=60*60*24*30;       
        IDOLockTimeSetup.push(lockSetuOne(monthTime,1000));                   //1 month  10%
        IDOLockTimeSetup.push(lockSetuOne(monthTime*2,1000));                 //1 month  10%
        IDOLockTimeSetup.push(lockSetuOne(monthTime*3,1000));                 //1 month  10%
        IDOLockTimeSetup.push(lockSetuOne(monthTime*4,1000));                 //1 month  10%
        IDOLockTimeSetup.push(lockSetuOne(monthTime*5,1000));                 //1 month  10%
        IDOLockTimeSetup.push(lockSetuOne(monthTime*6,1000));                 //1 month  10%
        IDOLockTimeSetup.push(lockSetuOne(monthTime*7,1000));                 //1 month  10%
        IDOLockTimeSetup.push(lockSetuOne(monthTime*8,1000));                 //1 month  10%
        IDOLockTimeSetup.push(lockSetuOne(monthTime*9,1000));                 //1 month  10%

        //SIMU 
        uint yearTime =60*60*24*365;
        uint quarterTime=60*60*24*90;

        lockTimeSetup.push(lockSetuOne(yearTime,850));                           //1 year   8.5%
        lockTimeSetup.push(lockSetuOne(yearTime+quarterTime,850));               //1 year + quarter 8.5%
        lockTimeSetup.push(lockSetuOne(yearTime+quarterTime*2,830));            //1 year + quarter*2 8.3%
        lockTimeSetup.push(lockSetuOne(yearTime+quarterTime*3,830));            //1 year + quarter*2 8.3%
        lockTimeSetup.push(lockSetuOne(yearTime+quarterTime*4,830));            //1 year + quarter*2 8.3%
        lockTimeSetup.push(lockSetuOne(yearTime+quarterTime*5,830));            //1 year + quarter*2 8.3%
        lockTimeSetup.push(lockSetuOne(yearTime+quarterTime*6,830));            //1 year + quarter*2 8.3%
        lockTimeSetup.push(lockSetuOne(yearTime+quarterTime*7,830));            //1 year + quarter*2 8.3%
        lockTimeSetup.push(lockSetuOne(yearTime+quarterTime*8,830));            //1 year + quarter*2 8.3%
        lockTimeSetup.push(lockSetuOne(yearTime+quarterTime*9,830));            //1 year + quarter*2 8.3%
        lockTimeSetup.push(lockSetuOne(yearTime+quarterTime*10,830));           //1 year + quarter*2 8.3%
        lockTimeSetup.push(lockSetuOne(yearTime+quarterTime*11,830));           //1 year + quarter*2 8.3%
        //JIGUO
        JIGUOLockTimeSetup.push(lockSetuOne(yearTime,850));                           //1 year   8.5%
        JIGUOLockTimeSetup.push(lockSetuOne(yearTime+quarterTime,850));               //1 year + quarter 8.5%
        JIGUOLockTimeSetup.push(lockSetuOne(yearTime+quarterTime*2,830));            //1 year + quarter*2 8.3%
        JIGUOLockTimeSetup.push(lockSetuOne(yearTime+quarterTime*3,830));            //1 year + quarter*2 8.3%
        JIGUOLockTimeSetup.push(lockSetuOne(yearTime+quarterTime*4,830));            //1 year + quarter*2 8.3%
        JIGUOLockTimeSetup.push(lockSetuOne(yearTime+quarterTime*5,830));            //1 year + quarter*2 8.3%
        JIGUOLockTimeSetup.push(lockSetuOne(yearTime+quarterTime*6,830));            //1 year + quarter*2 8.3%
        JIGUOLockTimeSetup.push(lockSetuOne(yearTime+quarterTime*7,830));            //1 year + quarter*2 8.3%
        JIGUOLockTimeSetup.push(lockSetuOne(yearTime+quarterTime*8,830));            //1 year + quarter*2 8.3%
        JIGUOLockTimeSetup.push(lockSetuOne(yearTime+quarterTime*9,830));            //1 year + quarter*2 8.3%
        JIGUOLockTimeSetup.push(lockSetuOne(yearTime+quarterTime*10,830));           //1 year + quarter*2 8.3%
        JIGUOLockTimeSetup.push(lockSetuOne(yearTime+quarterTime*11,830));           //1 year + quarter*2 8.3%





        hasSetup["IDO"]=0xaD35740e0e5aa24F16270D399FcEb961573b31c3;
        hasSetup["SIMU"]=0xFB4C6a7FDAe51ECFde7180Fd9Ae9A56E936caBB1;
        hasSetup["JIGUO"]=0x9DD01d1d7Efbf6aa642A4c8e239E0602f9005aB1;
        hasSetup["WAGUANG"]=0xFD2bBc0a70e0ceb5ACd80F64d4f3Ea64272ea820;
        hasSetup["GAMEFI"]=0xc6aF9E2f39e9f74883E1acD8128dDf9eE60e33e8;
        hasSetup["HUODONG"]=0x556Bfd377a8DB3a43d6dB6E8e64FCa246933a139;
        hasSetup["HEZUO"]=0x67b93CD00756b6E38184dC86686d6943D55B7369;
        hasSetup["BAO"]=0x96f6568db82B1EBBBfdEA888975FC08dD1A65C53;
        hasSetup["JISHU"]=0x16c896da547E2200F25a5BBC6f1230f7Bd978380;

    
        allData[hasSetup["IDO"]]=ALLINT/100*4*1000000000000000000;
        allData[hasSetup["SIMU"]]=ALLINT/100*2*1000000000000000000;
        allData[hasSetup["JIGUO"]]=ALLINT/100*5*1000000000000000000;
        allData[hasSetup["WAGUANG"]]=ALLINT/100*10*1000000000000000000;
        allData[hasSetup["GAMEFI"]]=ALLINT/100*59*1000000000000000000;
        allData[hasSetup["HUODONG"]]=ALLINT/100*8*1000000000000000000;
        allData[hasSetup["HEZUO"]]=ALLINT/100*5*1000000000000000000;
        allData[hasSetup["BAO"]]=ALLINT/100*5*1000000000000000000;
        allData[hasSetup["JISHU"]]=ALLINT/100*2*1000000000000000000;
    }

    function balanceOf(address addressId) public view returns(uint){
        return allData[addressId];
    }
    function allowance(address owner, address spender) external view returns (uint){            
        uint rInt=0;
        if(allowanceData[owner].length>0){
            allowanceOne[] storage thisdata=allowanceData[owner];
            uint ll=uint( thisdata.length);
            for (uint i=0;i<ll;i++){
               allowanceOne storage thisOne= thisdata[i];
               if(thisOne.to==spender){
                   rInt=thisOne.i;
                   break;
               }
            }
        }
        return rInt;
    }
    function approve (address spender, uint value) external  returns (bool){               
        address from =msg.sender;
        if(allowanceData[from].length>0){
            bool isState=true;

            allowanceOne[] storage thisdata=allowanceData[from];
            uint ll=uint( thisdata.length);
            for (uint i=0;i<ll;i++){
               allowanceOne storage thisOne= thisdata[i];
               if(thisOne.to==spender){
                   thisOne.i+=value;
                   isState =false;
                   break;
               }
            }
            if(isState){
                allowanceOne memory aa;
                aa.to=spender;
                aa.i=value;
                allowanceData[from].push(aa);
            }
        }else{

            allowanceOne memory aa;
            aa.to=spender;
            aa.i=value;
            allowanceData[from].push(aa);
        }
        return true;
    }
    

    function transfer(address to, uint value) external returns (bool){
        address from =msg.sender;                          

        uint nowTime=block.timestamp;                     

        address simuAddress=hasSetup["SIMU"];              //simu id
        address IDOAddress=hasSetup["IDO"];                //ido id
        address jigouAddress= hasSetup["JIGUO"];           //jigou id





        if(from ==simuAddress){                           
            if(allData[from]>=value){
                allData[from]-=value;
                allData[to]+=value;
                lockOne memory co=lockOne(value,value,block.timestamp);     
                lockBufferInfo[to]=co;
                return true;
            }else{
                return false;
            }
        }else if(from==IDOAddress){                     
            if(allData[from]>=value){
                allData[from]-=value;
                allData[to]+=value;
                lockOne memory co=lockOne(value,value,block.timestamp);     
                IDOlockBufferInfo[to]=co;
                return true;
            }else{
                return false;
            }
        }else if(from==jigouAddress){                   
            if(allData[from]>=value){
                allData[from]-=value;
                allData[to]+=value;
                lockOne memory co=lockOne(value,value,block.timestamp);     
                JIGUOlockBufferInfo[to]=co;
                return true;
            }else{
                return false;
            }
        }else{
            lockOne memory thisCo= lockBufferInfo[from];
            //lockOne memory thisCo_ido = IDOlockBufferInfo [from];
            //lockOne memory thisCo_jigou= JIGUOlockBufferInfo [from];
            if(thisCo.nowClockSum>0){                              
                uint timeLength=nowTime-thisCo.cTime;             
                if(timeLength<simuAllFreeTime){                   
                    uint getMoveInt=0;                           
                    for(uint i=0;i<lockTimeSetup.length;i++){
                       lockSetuOne memory thislockSetuOne=lockTimeSetup[i] ;
                       if(thislockSetuOne.timeLength<=timeLength){
                           getMoveInt+=thislockSetuOne.intVal;
                       }else{
                           break;
                       }
                    }
                    uint allowMoveInt=thisCo.allClockSum/10000*getMoveInt;     
                    uint oldInt =allData[from];                                 
                    if ((oldInt-value)>=(thisCo.allClockSum-allowMoveInt)){
                        if(allData[from]>=value){
                            allData[from]-=value;
                            allData[to]+=value;
                            return true;
                        }else{
                            return false;
                        }
                    }else{
                        return false;
                    }
                }else{   
                    thisCo.nowClockSum=0;                   
                    if(allData[from]>=value){
                        allData[from]-=value;
                        allData[to]+=value;
                        return true;
                    }else{
                        return false;
                    }
                }
            }else{   
               jigouWorker(from,to,value,nowTime);
            }
        }
    }
    function jigouWorker(address from,address to,uint value,uint nowTime) public returns(bool) {
        lockOne memory thisCo_jigou= JIGUOlockBufferInfo [from];
        if(thisCo_jigou.nowClockSum>0){
            uint timeLength=nowTime-thisCo_jigou.cTime;             
            if(timeLength<simuAllFreeTime){                  
                uint getMoveInt=0;                            
                for(uint i=0;i<JIGUOLockTimeSetup.length;i++){
                    lockSetuOne memory thislockSetuOne=JIGUOLockTimeSetup[i] ;
                    if(thislockSetuOne.timeLength<=timeLength){
                        getMoveInt+=thislockSetuOne.intVal;
                    }else{
                        break;
                    }
                }
                uint allowMoveInt=thisCo_jigou.allClockSum/10000*getMoveInt;      
                uint oldInt =allData[from];                                              
                if ((oldInt-value)>=(thisCo_jigou.allClockSum-allowMoveInt)){
                    if(allData[from]>=value){
                        allData[from]-=value;
                        allData[to]+=value;
                        return true;
                    }else{
                        return false;
                    }
                }else{
                    return false;
                }
            }else{                                      
                thisCo_jigou.nowClockSum=0;                                             
                if(allData[from]>=value){
                    allData[from]-=value;
                    allData[to]+=value;
                    return true;
                }else{
                    return false;
                }
            }
        }else{
            if(allData[from]>=value){
                allData[from]-=value;
                allData[to]+=value;
                return true;
            }else{
                return false;
            }
        }
    }


    function transferFrom(address from, address to, uint value) external returns (bool){                     
        if(allData[from]>=value){
           allData[from]-=value;
           allData[to]+=value;
           return true;
        }else{
            return false;
        }
    }
    /*function kill() public{                             
        if(msg.sender==mainAddress){
            selfdestruct(payable(mainAddress));
        }
    }*/
}