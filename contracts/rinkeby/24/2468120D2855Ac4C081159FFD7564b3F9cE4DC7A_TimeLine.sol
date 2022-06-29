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