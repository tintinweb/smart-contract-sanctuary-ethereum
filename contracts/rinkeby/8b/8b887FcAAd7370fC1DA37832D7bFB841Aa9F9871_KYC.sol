//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./TimeLine.sol";


contract KYC{
    struct Investors {
        string name;
        bool added; 
        address payable wallet;
        uint balance;
    }

    event Invest(
        string name,
        address wallet
    );

    TimeLine public timeLine;
    mapping(uint => Investors) public pioneers;
    uint public customerCount;
    address admin;
    uint256 public maxPioneers = 100;
    uint256 public pioneersAmount;
    mapping(address => bool) public stakers;

    constructor(TimeLine _timeLine){
        admin = msg.sender;
        timeLine = _timeLine;
    }

     modifier notOwner(){
        require(msg.sender != admin);
        _;
    }

     modifier onlyOwner(){
        require(msg.sender == admin);
        _;
    }

     function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function incrementPioneersCnt() internal{
        customerCount += 1;
    }

    function compareStringsbyBytes(string memory s1, string memory s2) public pure returns(bool){
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function invest(string memory _name) public notOwner{
        require(!stakers[msg.sender],"Pioneer already added");
        require(customerCount <= maxPioneers, "Maximum number of Pioneers added");
        
        pioneers[customerCount+1] = Investors(_name, true, payable(msg.sender), 0);

        /* pioneers[customerCount+1].name = _name;
        pioneers[customerCount+1].added = true;
        pioneers[customerCount+1].wallet = payable(msg.sender);
        pioneers[customerCount+1].balance = 0; */

        stakers[msg.sender] = true;
        incrementPioneersCnt();
        emit Invest(_name,msg.sender);
    }

    function rewardPioneers() public onlyOwner{
        pioneersAmount = div(timeLine.balanceOf(address(this)) , maxPioneers);
        for(uint i=1; i<customerCount+1; i++){
            address addr = pioneers[i].wallet;
            if(pioneers[i].balance <= 0){
                timeLine.transfer(addr , pioneersAmount);
                pioneers[i].balance = pioneersAmount;
            }
        }
    }

    function displayPioneers() public view onlyOwner returns(Investors[] memory){
        Investors[] memory investorsBlock = new Investors[](customerCount);
        uint currentIndex = 0;
        for(uint i=0; i<customerCount; i++){
            Investors storage currentInvestor = pioneers[i+1];
            investorsBlock[currentIndex] = currentInvestor;
            currentIndex++;
        }
        return investorsBlock;
    }

    function returnPioneer(string memory _name) public view returns(bool){
        for(uint i=1; i<customerCount+1; i++){
            if(compareStringsbyBytes(_name,pioneers[i].name)){
                return true;
            }
        }
        return false;
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract TimeLine {
    string  public name = "TimeLine coin";
    string  public symbol = "TL";
    uint256 public totalSupply = 3000000000000000000000000; // 3 million TimeLine tokens
    uint8   public decimals = 18;



    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    //address[] public investors;
    mapping(uint256 => address) public investors;
    uint256 public investorsIndex = 1;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        investors[investorsIndex] = msg.sender;
        investorsIndex++;
    }

     function returnInvestorsArray() public view returns(address[] memory){
        address[] memory _investors = new address[](investorsIndex);
        for(uint i=0; i<investorsIndex; i++){
            _investors[i] = investors[i];
        }
        return _investors;
     }

     function addToInvestorArray(address _investor) private{
         require(balanceOf[_investor] >= 0);
         for(uint i = 1; i<investorsIndex; i++){
            if(investors[i] == _investor){
                return;
            }
         }
         investors[investorsIndex] = _investor;
         investorsIndex++;
     }
   /* 
     function removeInvestorArray(address _investor) private{
         if(balanceOf[_investor] <= 0){
             for(uint i=0; i<investors.length; i++){
                 if(investors[i] == _investor){
                    _burn(i);
                 }
             }
         }
         } */

      function removeInvestorArray(address _investor)private{
        if(balanceOf[_investor] <= 0){
            for(uint i=1; i<investorsIndex; i++){
                if(investors[i] == _investor){
                    delete investors[i];
                    investorsIndex--;
                    return;
                }
            }
        }
      }

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        //add to investors array to use For DAO propagation

        addToInvestorArray(_to);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        removeInvestorArray(_from);
        addToInvestorArray(_to);
        return true;
    }
}