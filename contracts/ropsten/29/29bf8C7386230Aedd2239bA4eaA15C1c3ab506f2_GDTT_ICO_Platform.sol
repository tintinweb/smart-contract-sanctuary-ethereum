/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20{
    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function totalSupply() external view returns (uint );

    function decimals() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function approve(address sender , uint value)external returns(bool);

    function allowance(address sender, address spender) external view returns (uint256);

    function transfer(address recepient , uint value) external returns(bool);

    function transferFrom(address sender,address recepient, uint value) external returns(bool);

    function mint(address toAddr,uint256 amount) external returns (bool);

    event Transfer(address indexed from , address indexed to , uint value);

    event Approval(address indexed sender , address indexed  spender , uint value);
}

contract Context{
    constructor () {}
   function _msgsender() internal view returns (address) {
    return msg.sender;
  }
}

contract Ownable is Context{
    address private _Owner;

    event transferOwnerShip(address indexed _previousOwner , address indexed _newOwner);

    constructor(){
        address msgsender = _msgsender();
        _Owner = msgsender;
        emit transferOwnerShip(address(0),msgsender);
    }

    function checkOwner() public view returns(address){
        return _Owner;
    }

    modifier OnlyOwner(){
       require(_Owner == _msgsender(),"Only owner can change the Ownership");
       _; 
    }
   
    function transferOwnership(address _newOwner) public OnlyOwner {
      _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
      require(_newOwner != address(0),"Owner should not be 0 address");
      emit transferOwnerShip(_Owner,_newOwner);
      _Owner = _newOwner;
    }
}

contract GDTT is Context, IERC20, Ownable {
    mapping(address => uint) _balances;
    mapping(address => mapping(address => uint)) _allowances;
    mapping(address => bool) public hasRole;

    address public Owner;

    string private _name;
    string private _symbol;
    uint private _decimal;
    uint private _totalSupply;

    constructor(){
        Owner = msg.sender;
       _name = "GDTT_Token";
       _symbol = "GDTT";
       _decimal = 18;
    //    _totalSupply = 700000000 * 10 ** 18;
    //    _balances[msg.sender] = _totalSupply;
       emit Transfer(address(0), msg.sender, _totalSupply);
    }

    modifier _OnlyOwnerAndRole{
        require(Owner == msg.sender || hasRole[msg.sender],"only owner can update or caller doesn't have role!!!");
        _;
    }

    function name() external override view returns(string memory){
        return _name;
    }
    function symbol() external view override returns(string memory){
        return _symbol;
    }
    function decimals() external view override  returns(uint){
        return _decimal;
    }
    function balanceOf(address owner) external view override  returns(uint){
        return _balances[owner];
    }
    function totalSupply() external view override  returns(uint){
        return _totalSupply;
    }
    function approve(address spender , uint value) external override returns(bool){
        _approve(_msgsender(), spender , value);
        return true;
    }
    function allowance(address sender , address spender) external view override returns(uint){
          return _allowances[sender][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
      _approve(_msgsender(), spender, _allowances[_msgsender()][spender]+(addedValue));
      return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
     _approve(_msgsender(), spender, _allowances[_msgsender()][spender] - subtractedValue);
     return true;
    }

    function transfer(address recepient , uint value) external override returns(bool){
        _transfer(msg.sender, recepient,value);
         return true;
    }

     function transferFrom(address sender ,address recepient, uint amount) external override returns(bool){
        _approve(sender, _msgsender(), _allowances[sender][_msgsender()] - amount);
        _transfer(sender,recepient,amount);
        return true;
    }

    function mint(address addressToMint,uint256 amount) public _OnlyOwnerAndRole  returns (bool) {
        _mint(addressToMint, amount);
        return true;
    }

    function burn(address addressToBurn,uint256 amount) public _OnlyOwnerAndRole returns (bool) {
        _burn(addressToBurn, amount);
        return true;
    }

    function _transfer(address sender,address recepient, uint value) internal  returns(bool success){
        require(_balances[sender] >= value,"Balance not enough");
        _balances[sender] = _balances[sender] - value;
        _balances[recepient] = _balances[recepient] + value;
        emit Transfer(_msgsender(), recepient , value);
        return true;
    }

    function _approve(address sender,address spender, uint amount) internal returns(bool success){
        require(sender != address(0),"Should not be 0 address");
        require(spender != address(0),"Should not be zero address");
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "GDTT: mint to the zero address");
        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal {
       require(account != address(0), "GDTT: burn from the zero address");
       _balances[account] = _balances[account] - amount;
       _totalSupply = _totalSupply - amount;
       emit Transfer(account, address(0), amount);
    }

    function addRole(address userAddr) public _OnlyOwnerAndRole{
        require(userAddr != address(0) , "Role cant't be 0 address!!!");
        hasRole[userAddr] = true;
    }
}

contract GDTT_ICO_Platform{
    address public Owner;
    address public signerAddress;

    IERC20 public GDTT_Token;
    IERC20 public USDT_Token;
    IERC20 public BUSD_Token;

    mapping(address => bool) public isApprovedToken;

    enum AssetType{
        /* AssetType 0 for ETHER*/
        ETHER,
        /* AssetType 1 for USDC*/
        ERC20Token
    }

    struct Order{
        address toAddr;
        address tokenAddress;
        uint depositTokenAmount;
        uint mintTokenAmount;
        uint expiryTime;
        AssetType assetType;
    }

    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    event TransferredETH(address indexed userAddr, uint amountDeposited);
    event TransferredToken(address indexed userAddr, uint amountDeposited);
    event NewTokenAdded(address indexed newAddedTokenAddress);
    event DepositedEthAndGotGDTT(uint depositedETH, uint tokenAmount);
    event DepositedTokenAndGotGDTT(address tokenAddress,uint depositTokenAmount,uint mintTokenAmount);

    error invalidAssetType();

    modifier OnlyOwner(){
        require(msg.sender != address(0) ,"Only Admin!!!");
        _;
    }
    receive() external payable {}

    constructor(address GDTTAdress, address USDTAddress, address BUSDAddress, address _signerAddress) {
        assembly{
            sstore(Owner.slot, caller())
            sstore(signerAddress.slot, _signerAddress)
        }
        isApprovedToken[USDTAddress] = true;
        isApprovedToken[BUSDAddress] = true;
        GDTT_Token = IERC20(GDTTAdress);
        USDT_Token = IERC20(USDTAddress);
        BUSD_Token = IERC20(BUSDAddress);
    }    

    function BuyToken(Order memory _Order, Sig memory sig) public payable{
        require(msg.sender != address(0), "Zero address!!!");
        if(_Order.assetType == AssetType.ETHER){
            require(msg.value > 0,"Must be > 0 ether");
            require(validateOrderHash(_Order,sig), "Invalid signature while depositing ETHER");
            (bool success, ) = address(this).call{value : msg.value}("");
            if(success){
                GDTT_Token.mint(_Order.toAddr, _Order.mintTokenAmount);
                emit DepositedEthAndGotGDTT(msg.value,_Order.mintTokenAmount);
            }else{
                revert("ETHER transfer failed");
            }
        }else if(_Order.assetType == AssetType.ERC20Token){
            require(isApprovedToken[_Order.tokenAddress],"Only approved token's can be deposited!!!");
            require(_Order.depositTokenAmount > 0, "Must be > 0 Tokens");
            require(validateOrderHash(_Order,sig), "Invalid signature while depositing TOKEN");
            (bool success, ) = address(_Order.tokenAddress).call(abi.encodeWithSignature("transferFrom(address,address,uint256)", _Order.toAddr, address(this), _Order.depositTokenAmount));
            if(success){
                GDTT_Token.mint(_Order.toAddr, _Order.mintTokenAmount);
                emit DepositedTokenAndGotGDTT(_Order.tokenAddress,_Order.depositTokenAmount,_Order.mintTokenAmount);
            }else{
                revert("Token transfer failed");
            }
        }else{
            revert invalidAssetType();
        }
    } 

    function approveToken(address approvingTokenAddr)public OnlyOwner{
        require(approvingTokenAddr != address(0) || !isApprovedToken[approvingTokenAddr],"Zero address cant't be approved or TokenAddress already approved");
        isApprovedToken[approvingTokenAddr] = true;
    }

    function withdrawAsset(AssetType assetType, address tokenAddr, uint amount) public OnlyOwner returns(bool){
        if(assetType == AssetType.ETHER){
            require(address(this).balance >= amount,"insufficient balance");
            require(payable(msg.sender).send(amount), "Transaction failed");
            return true;
        }else if(assetType == AssetType.ERC20Token){
            require(IERC20(tokenAddr).balanceOf(address(this)) >= amount);
            IERC20(tokenAddr).transfer(msg.sender,amount);
            return true;
        }else{
            revert invalidAssetType();
        }
    } 

    function updateSignerAddress(address NewSignerAddress) public {
        require(NewSignerAddress != address(0) ,"Zero address");
        assembly{sstore(signerAddress.slot, NewSignerAddress)}
    }

    function validateOrderHash(Order memory _Order, Sig memory sig)internal view returns(bool result){
        bytes32 Hash = prepareOrderHash(_Order);
        bytes32 fullMessage = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", Hash)
        );
        address signatoryAddress = ecrecover(fullMessage,sig.v,sig.r,sig.s);
        result = signatoryAddress == signerAddress;
    }

    function prepareOrderHash(Order memory _Order)public pure returns(bytes32){
        return keccak256(
            abi.encodePacked(
                _Order.toAddr,
                _Order.tokenAddress,
                _Order.depositTokenAmount,
                _Order.mintTokenAmount,
                _Order.expiryTime
            )
        );
    }
}