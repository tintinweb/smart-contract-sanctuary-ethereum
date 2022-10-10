/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// File: contracts/LILLYPOOL.sol


pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20Basic is IERC20 {

    string public constant name = "ERC20Basic";
    string public constant symbol = "ERC";
    uint8 public constant decimals = 18;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

mapping
    (address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;

    using SafeMath for uint256;


   constructor(uint256 total) public {
    totalSupply_ = total;
    //balances[msg.sender] = totalSupply_;
    balances[address(this)] = totalSupply_;

    }

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

   function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}


contract Lillypool is IERC20 {

    string public constant name = "Lillypool";
    string public constant symbol = "Lypool";
    uint8 public constant decimals = 18;
    address payable public owner ;
    uint256 public n_user;
    address payable  [] public staff;
    uint256 certificate_value = 1000000000000000;
    uint256 certificate_cost = 25000000000000000;

    mapping (uint => cert_buyer) public CERTIF;
    
    // each cert to obtain eth
    struct cert_buyer {
        uint256  NFT_token;
        bool avaiable;
        address  _address;
    }

    uint256 public next_certificate = 1;
    mapping(address => mapping (address => uint256)) allowed;

        

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Transfer_ownership(address owner, address new_owner);
    event change_lill_mint(uint lilly_mint, uint new_lilly_mint);
    event change_staff (address payable [] staff, address payable [] _newstaff);
    event change_burn_add (address payable burn_address, address payable new_burn_address);
    mapping(address => uint256) balances;
    uint256 totalSupply_;

    /// address to burn
    address payable public burn_address;
    address payable public lilly_bank;
    address public certificate_address;
    uint public cost_to_play;

    using SafeMath  for uint256;

    bool public ritire_auth;


   constructor(uint256 _totalsupply, address payable [] memory _staff, address payable _burn_addr, address payable _lilly_bank, uint _certificate_value) public {
    
    staff = _staff;
    owner = msg.sender;
    totalSupply_ = _totalsupply * (10**18);
    burn_address = _burn_addr;
    lilly_bank = _lilly_bank;
    //balances[msg.sender] = totalSupply_;
    balances[address(this)] = totalSupply_/2;
    balances[owner] = totalSupply_/2;
    certificate_value = _certificate_value;
    }

    ////// function burn --> fatta
    /// distribution prize   //// prize reward da rivedere si dovrebbe aggiornare dopo la funzione update holder
    /// pay to play

    // function to look at the staff member

    function check_staff (address payable intern) public view returns (bool test){
        bool test = false;
        for (uint i = 0 ; i<staff.length; i++){
            if(intern == staff[i]){
                test =  true;
            }
        }
        return test;        
    }




    // set_certificate_address

    function set_certificate_address (address certif_address) public returns (bool){
        require(msg.sender == owner || check_staff(msg.sender));
        certificate_address = certif_address;
        return(true);

    }

    // function to set cost to buy

    function set_certificate_cost(uint256 certif_cost) public returns (bool){
        require(msg.sender == owner || check_staff(msg.sender));
        certificate_cost = certif_cost;
        return(true);
    }


    uint256 public length__ = 0;
    ////function update certificate
    function certificate_update(uint256 [] memory _NFT_token, bool [] memory _avaiable, address [] memory __address) public returns (bool) {   
        require(msg.sender== owner || check_staff(msg.sender));
       for (uint j = 0 ; j< _avaiable.length; j++){
                    CERTIF[j].NFT_token = _NFT_token[j];
                    CERTIF[j].avaiable = _avaiable[j];
                    CERTIF[j]._address = __address[j];
        }
        length__ ==  _avaiable.length;
        return(true);

    }


    ///withdraw ethereum

    function withdraw_ethereum() public returns (bool) {   

        for (uint256 i = 0; i< length__ + 1; i++){
                if(CERTIF[i]._address == msg.sender){
                    if(CERTIF[i].avaiable == true){
                        uint256 value_ = CERTIF[i].NFT_token * certificate_value;
                        sendWithCall(value_ , msg.sender);
                        CERTIF[i].NFT_token = 0;
                        CERTIF[i].avaiable = false;
                    }

                }
        }

    }

    // change staff

    function change_staff_(address payable [] memory _new_staff) public returns (bool){

        require(msg.sender == owner);
        staff = _new_staff;
        emit change_staff(staff, _new_staff);
        return true;
    }



    // change burn address

    function change_burn(address payable new_burn) public returns (bool){
        require (msg.sender == owner);
        burn_address = new_burn;
        emit change_burn_add(burn_address , new_burn);
        return true;
    }


    /// function to burn lilly

    function burn_lilly(uint256 burnable) public returns (bool){

        transfer(burn_address , burnable);
        return true;
    }

    function totalSupply() public override view returns (uint256) {
       return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }


    
    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }


    function transferownership(address payable new_receiver) public returns (bool){
        require(msg.sender == owner);
        emit Transfer_ownership(msg.sender , new_receiver);
        owner = new_receiver;
        return true;
    }
    
    receive () external payable {}
    
    fallback() external payable {}

    function sendWithCall (uint256 _value, address payable receiver__) public returns(bytes memory) {
          (bool success , bytes memory data) = payable(receiver__).call{value:_value}("");
          require(success , "Call failed");

          return data;

      }


    
    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

 

}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}