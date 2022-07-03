/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Neverlander{

    string name="Neverlander";



    function getname() public view returns (string memory){

    
        return name;
    }

    function changename(string memory newname) public pure returns(string memory){

        return newname;


    }

    bool test1 = true;
    bool test2 = false;
    function panduan() public view returns(bool){


        return test1!=test2;
    
    }

    function yuhuo1() public view returns(bool){

        return !panduan()||false;



    }



    function yu(uint a,uint b) public pure returns(uint){
        
        return a&b;

    }

    function huo(uint a,uint b) public pure returns(uint){
        
        return a|b;

    }

    function yuhuo(uint a,uint b) public pure returns(uint){
        
        return a^b;

    }

    function zuoyi(uint a,uint b) public pure returns(uint){
        
        return a<<1+b<<1;

    }

    function youyi(uint a,uint b) public pure returns(uint){
        
        return a>>1+b>>1;

    }

    uint256 public xxx=1000;

    bytes public age=new bytes(1);


    function changelength() public{

        age=new bytes(5);

    }


    address[] abc=[0x5FC5B2fC589967b5Fe482E33DdCe64881547a016,0x5FC5B2fC589967b5Fe482E33DdCe64881547a016];

    address public xbc=abc[0];


    uint256[] public abcc=[0x11,0x22,0x33];

    uint256 public cgv=abcc[1];

    bytes5 abcd=0x1111112222;
    bytes1 public by1=bytes1(abcd);
    bytes2 public by2=bytes2(abcd);
    bytes10 public by10=bytes10(abcd);


    function returnlength() public view returns(uint){

        uint abdd=age.length;
        return abdd;
    }

    function tovalue () public returns(bytes memory){

        age[0]=0x11;
        age[1]=0x22;        
        age[2]=0x33;     
        age[3]=0x44;     
        age[4]=0x55;
        age.push(0x66);
        return age;
    
    }

    string abc1="hello neverlander";
    
    function get_string_bytes() public view returns(bytes memory)
    {

        return bytes(abc1);


    }


    bytes5 abc2=0x1122334455;
    
    function todynamicbytes() public view returns(bytes memory){

        uint n=abc2.length;

        bytes memory abc3=new bytes(n);


        for(uint i=0;i<n;i++) {
            abc3[i]=abc2[i];
        }
        return abc3;

    }

    //固定数组转字符串

    bytes12 abc4=0x112233440000000000550000;

    function fixedtostring() public view returns(string memory){
        uint count;
        for(uint i=0;i<abc4.length;i++){
            
            if(abc4[i]!=0){
                
                count=i+1;
            }  
        }
        bytes memory abc5=new bytes(count);
        for(uint j=0;j<count;j++){
            abc5[j]=abc4[j];
        }
        return string(abc5);
    }

    //Done;

    //uint数组；

    uint[] public abcde;

    function touintvalue() public returns(uint[] memory){
        abcde=[1,2,3,4,5];
        abcde.push(6);
        return abcde;

    }



    //Done;

    //二维数组；

    uint [3][5] public abcarray=[[1,2,3],[4,5,6],[7,8,9],[10,11,12],[13,14,15]];

    uint [] public xxxx=abcarray[3];//第四个数组
    uint public xxxxx=abcarray[4][2];//=15；第五个数组，第三位元素

    //遍历并改变数组元素的值；
    function changearrayvalue() public returns(uint[3][5] memory){
        uint x;
        for(uint i=0;i<5;i++){
            for(uint n=0;n<3;n++){         
                abcarray[i][n]=11+x;
                x++;
            }
        }
        return abcarray;
    }

    //Done;

    //二维可变数组；
    uint [][] public abcdarray=[[1,2,3],[4,5,6],[7,8,9],[10,11,12],[13,14,15]];

    uint [] public xxxx1=abcdarray[3];//第四个数组
    uint public xxxxx1=abcdarray[4][2];//=15；第五个数组，第三位元素

    //遍历并改变数组元素的值；
    function changearrayvalue1() public returns(uint[][] memory){
        uint x;
        for(uint i=0;i<5;i++){
            for(uint n=0;n<3;n++){         
                abcdarray[i][n]=11+x;
                x++;
            }
        }
        return abcdarray;
    }

    //Done;    




    //Transfer转账;

    //给当前合约转账
     function transfer0() public payable {
     }


    //从当前合约提款
    function withdraw(address payable _to, uint256 _amount) public  {
        _to.transfer(_amount);
    }

    //用当前地址给其他地址转账
    function transferotheraddress(address payable to) public payable{
        to.transfer(msg.value);
    }


     function getthis() public view returns(address){
         return address(this);
     }

    //Done; 

    // Mapping映射;

    mapping (address=>uint)idnumber;
    mapping (uint=>bool)boolnumber;    

    function tovalue1() public returns(bool){
        idnumber[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4]=1;
        boolnumber[1]=true;
        idnumber[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2]=2;
        boolnumber[2]=false;  
        return boolnumber[idnumber[0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2]];    

    }

    //映射嵌套
    mapping (address=>mapping (uint=>bool))iddnumber;

    function toidnumbervalue()public returns(bool){
    iddnumber[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4][1]=true;
    return iddnumber[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4][1];
    }

    //Done; 

    //在函数里重新定义同名变量，会新生成一个同名变量;
    uint public acv =100;

    function changeacv() public returns(uint){
        acv=300;
        return acv;

    } 

    //Done; 


    //modifier加上参数
    uint public balala =256;
    
    modifier onlyme (uint balle){
        if (msg.sender==0x5B38Da6a701c568545dCfcB03FcB875f56beddC4){ 
            balala=balle;
             _;
        }

    }

    function changebalala(uint bala) public onlyme(bala) returns(uint balla){
        balla=balala;

    }
    //Done;

    //多重modifier执行顺序l;

    uint public sololo=999;

    modifier multimod(){
        sololo=100;
        _;
        sololo=200;
    }

    function changesololo()  public multimod{
        sololo=150;
    }

    //Done;

    //全局变量加上public会默认自动生成隐藏函数external getter()，变成可调用;
    mapping (uint=>string) public balala1;

    function returnbalala1() public returns(string memory){
        balala1[2]="neverland";
        return this.balala1(2);
    }

    mapping (uint=>string) public balala2;

    function returnbalala2() public returns(string memory){
        balala2[2]="neverland";
        return balala2[2];
    }
    //Done;
    
    //多重嵌套mapping,实际上就是往getter函数里加多个参数;
    mapping (uint=>mapping(uint=>mapping(uint=>string))) public map;
    function getmap() public returns(string memory){
        map[0][1][2]="neverland";
        return map[0][1][2];
    }

    mapping (uint=>mapping(uint=>mapping(uint=>string))) public map2;
    function getmap2() public returns(string memory){
        map2[0][1][2]="neverland";
        return this.map2(0,1,2);
    }
    //Done;





    //重要-----------

    //当两个storage结构用=号连接时，其中任何一个结构元素的变化，都会影响到另外一个。
    struct student {
        uint grade;
        string name;

    }


    student stu=student(99,"abb");


    function test0()public {

        student storage meimei=stu;
        stu.grade=100;
        stu.name="ddd";
        meimei.name="neverlander";

    }

    function call() public view returns(string memory){
        return stu.name;
    }
    //Done;


    //可变数组在使用前需要初始化！！
    //数组与结构类似，当两个storage数组用=号连接时，其中任何一个数组元素的变化，都会影响到另外一个。

    uint [] xva;

    function getxvb() public returns(uint){
        xva=new uint[](3);
        uint [] storage xvb=xva;
        xva[0]=100;
        xvb[0]=99;
        return xva[0];
    }
    //Done;

    //如果其中一个是memory，改变memory数组，则不影响storage数组的值。
    //甚至改变storage数组，也不会影响memory数组的值。
    uint [] xvc;

    function getxvc() public returns(uint){
        xvc=new uint[](3);
        uint [] memory xvd=xvc;
        xvc[0]=100;
        return xvd[0];
    }
    //Done;

    //数组与结构类似，当两个memory数组用=号连接时，其中任何一个数组元素的变化，都会影响到另外一个。
    function testmemory(student memory s)pure internal{
        student memory ss=s;
        ss.name="ss";
    
    }
    function callmemory() public pure returns(string memory){
        student memory sss=student(1,"sss");
        testmemory(sss);
        return sss.name;
    }
    //Done;

    //如何是两个storage的uint，则互不影响。
    uint public abb=1000;
    uint public acc=2000;

    function changeacc()public{
        acc=abb;
        acc=3000;
    }
    //重要-----------Done!
    

    struct proposal {
        bytes2 name;   // 简称（最长32个字节）
        uint voteCount;
    }

    proposal[] public proposals;

    proposal pro=proposal(0x1122,256);

    struct student0 {
        uint grade;
        string name;

    }


    student0 stu0=student0(99,"abb");



    uint price;
    uint Price;
    

    














    


}