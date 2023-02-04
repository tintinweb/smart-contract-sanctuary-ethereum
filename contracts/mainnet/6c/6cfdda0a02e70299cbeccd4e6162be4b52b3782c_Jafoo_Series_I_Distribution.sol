/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;



interface IERC20 {
    function approve(address _spender, uint _value) external returns (bool);
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    
}

interface IERC721 {
     function ownerOf(uint256 tokenId) external view returns (address owner);
     function balanceOf(address owner) external view returns (uint256 balance);
     function totalSupply() external view returns (uint256);

}




contract Jafoo_Series_I_Distribution  {   /// C&R




address public owner;
IERC20 public token;
IERC721 public nft;
mapping(address => uint256) public balances;
mapping(address => mapping (address => uint256)) allowed;




constructor() public {
    owner = msg.sender;
    token = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);  ///  TETHER LIVE
    nft = IERC721(0x0EF343f73DbBFA84a1d6D63c369084859EB858b5); ///JAFOO LIVE
}


event AdminWithdraw(address indexed _to, uint256 _amount);
event AdminDeposit(address indexed _to, uint256 _amount);
event Approval(address indexed owner, address indexed spender, uint256 value);
event NFTAddressUpdate(address _newAddress);
event TokenAddressUpdate(address _newAddress);


modifier _onlyOwner{
    require(msg.sender == owner, "Not Owner");
    _;
}



////// ADMIN DEPOSIT 

function adminDeposit(uint256 _value) external _onlyOwner{    
    require(_value > 0, "Deposit amount must be greater than 0");
    require(IERC20(token).transferFrom(msg.sender, address(this), _value), "Transfer Failed");
    balances[address(this)] += _value;
    emit AdminDeposit(address(this), _value);
    } /// deposit



///////  ADMINWITHDRAW

function adminWithdraw(uint _value) external _onlyOwner{
    require(IERC20(token).approve(address(this), _value), "Approval Failed");
    require(IERC20(token).transferFrom(address(this), owner, _value), "Transfer Failed");
    balances[address(this)] -= _value;
    emit AdminWithdraw(owner, _value);
}



function approve(address spender, uint256 value)  external  returns (bool) {
    require(spender != address(0), "Error: invalid spender address");
    allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
}


 function allowance(address spender, address value) external view returns (uint) {
        return allowed[spender][value];
    }

function contractBalanceOf() external view returns(uint256){
    return balances[address(this)];
}




function updateNFTAddress(address _newAddress) external _onlyOwner{
     nft = IERC721(_newAddress);
     emit NFTAddressUpdate(_newAddress);
}


function updateTokenAddress(address _newAddress) external _onlyOwner{
    token = IERC20(_newAddress);
    emit TokenAddressUpdate(_newAddress);
}


function totalSupply() external view returns(uint256){
    return IERC721(nft).totalSupply();
}

function nftHolderOf(uint256 _i) external view returns(address){
    return IERC721(nft).ownerOf(_i);
}


function num_of_NFTs(address _holder) external view returns(uint256){
    return IERC721(nft).balanceOf(_holder);
}



}  ///  end contract