// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface StakeLaunch_v01{
    function getTierRank(address _sender)external view returns(uint);
}

contract LaunchFactory_v01{

    Launch_v01[] public deployedLaunchs;
    address private owner;

    constructor(){
        owner = msg.sender;
    }

    function createLaunch(address _owner,uint _cap,uint _minCap,string memory _projectName,uint _min,uint _max,uint _minContribute) public onlyOwner  {
        Launch_v01 newLaunch = new Launch_v01(_owner,_cap,_minCap,_projectName,_min,_max,_minContribute);
        deployedLaunchs.push(newLaunch);
    }


    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

}


contract Launch_v01{

    address private owner;
    string public projectName;
    uint public minContribute;
    uint public maxContribute;
    uint public cap;
    uint public minCap;
    uint public raisedCap;

    mapping(address=>uint) private paidBusd;
    mapping(address=>bool) private isContrubuted;
    mapping(uint => uint) private contributionLimit;
    address[]public contributers;
    uint private contributerNumber;
    uint private reFundCounter;
    
    IERC20 public BUSD = IERC20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    StakeLaunch_v01 public Stake;

    constructor(address _owner,uint _cap,uint _minCap,string memory _projectName,uint _min,uint _max,uint _minContribute){
        owner = _owner;
        cap = _cap;
        minCap = _minCap;
        projectName = _projectName;
        minContribute = _min;
        maxContribute = _max;
        _minContribute = minContribute;
        contributionLimit[1] = 100;
        contributionLimit[2] = 200;
        contributionLimit[3] = 300;
    }

    function buyFromProject(uint _price) public canRaise{
        require(raisedCap <= cap,"LaunchContract: Raise is over");
        require(_price>= minContribute,"LaunchContract: You need to contribute more than minimum contrubution");
        require(BUSD.balanceOf(msg.sender)>=_price * 1e18,"You don't have that balance in your address");
        require(Stake.getTierRank(msg.sender)>0,"You don't have tier rank");
        require(contributionLimit[Stake.getTierRank(msg.sender)] >= _price,"LaunchContract: You can't contribute more than your limit");

        BUSD.transferFrom(msg.sender,address (this), _price * 1e18);
        paidBusd[msg.sender] += _price;                        
        isContrubuted[msg.sender] = true;  
        raisedCap += _price;
        if(!isContrubuted[msg.sender]){
            contributers.push(msg.sender);
        }
    }

    function reFund(uint _loopCount)public onlyOwner {                                 
        if(reFundCounter < contributers.length){
            for(uint i = 0;i < _loopCount;i++){
                sendBusd(contributers[reFundCounter * 1e18] );
                reFundCounter++;
            }
        }
    }

    function sendBusd(address _to) private{
        BUSD.transfer(_to,paidBusd[_to] * 1e18);
    }

    function takeMoney()public onlyOwner {
        BUSD.transfer(owner, BUSD.totalSupply() * 1e18);
    }

    function setMinContrubition(uint _minContribute) public onlyOwner {
        minContribute = _minContribute;
    }

    function setMaxContrubitionTier1 (uint _max)public onlyOwner {
        contributionLimit[1] = _max;
    }

    function setMaxContrubitionTier2 (uint _max)public onlyOwner {
        contributionLimit[2] = _max;
    }

    function setMaxContrubitionTier3 (uint _max)public onlyOwner {
        contributionLimit[3] = _max;
    }

    function afterReFund() public onlyOwner {
        reFundCounter = 0;
    }

     modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier canRaise(){
        require(raisedCap<cap);
        _;
    }
}