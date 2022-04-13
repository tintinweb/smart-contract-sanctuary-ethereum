//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SANDOToken is ERC20, Ownable, AccessControl {
    ERC20 public token;
    using Strings for string;
    bool public paused;

    /*Fix total Supply and disabled burn token.*/
    uint256 public constant _MAX_SUPPLY = uint256(100000000000000 ether);
    uint256 private decimal=10**18;

    address public _owner;
    uint256 public rate_Default;
    uint256 public rate_Private;
    uint256 public rate_ICO;
    uint256 public rate_CEX;
    address public ADDR_AIRDROP = 0x745cF4eD6e477BBE0B96304Bef0A1C250a0E54F0;
    address public ADDR_SEED_SALE = 0x08E65dCd256555E5bAE2AB6973Cba46269814B89;
    address public ADDR_PRIVATE_SALE = 0x9f3b3F3e0596984d91Ff4aeD831E466A6866A6D5;
    address public ADDR_ICO = 0xDE658cb8696501cd74329cCa12c7C9eAC3789F7D;
    address public ADDR_DEX = 0x24acDc79481e8cd742F1D43d11A77966745f93cE;
    address public ADDR_CEX = 0x3760306265B2ba1C852F98BE9EF2e11EDa9160bF;
    address public ADDR_MARKETING = 0x6649cbB590c312db07303d7adF870ae35B1fD179;
    address public ADDR_PL = 0x9B8156dB576Ac096b3dC2adED9c994a193386504;
    address public ADDR_FD = 0x6F7fb3191c2d68BCaB607Fe9dbAbbd11167130FC;
    address public ADDR_RE = 0x3C8FC5030801eA0cB4CA93bB0b8C9BD84D612341;

    uint256 public AMOUNT_AIRDROP = _MAX_SUPPLY * 25 / 100;     //
    uint256 public AMOUNT_SEED = _MAX_SUPPLY * 5 / 100;         //
    uint256 public AMOUNT_PRIVATE_SALE= _MAX_SUPPLY * 20 / 100; //
    uint256 public AMOUNT_ICO = _MAX_SUPPLY *  5 / 100;         //
    uint256 public AMOUNT_DEX = _MAX_SUPPLY *  5 / 100;         //
    uint256 public AMOUNT_CEX = _MAX_SUPPLY *  5 / 100;         //
    uint256 public AMOUNT_MARKETING= _MAX_SUPPLY *  5 / 100;
    uint256 public AMOUNT_PL= _MAX_SUPPLY *  5 / 100;
    uint256 public AMOUNT_FD= _MAX_SUPPLY * 15 / 100;
    uint256 public AMOUNT_RE = _MAX_SUPPLY * 10 / 100;


   constructor(string memory name, string memory symbol) ERC20(name, symbol){
    /*
    _mint(ADDR_AIRDROP, AMOUNT_AIRDROP);
    _mint(ADDR_PRIVATE_SALE, AMOUNT_PRIVATE_SALE);
    _mint(ADDR_ICO, AMOUNT_ICO);
    _mint(ADDR_SEED_SALE, AMOUNT_SEED);
    _mint(ADDR_DEX, AMOUNT_DEX);
    _mint(ADDR_CEX, AMOUNT_CEX);
    _mint(ADDR_MARKETING, AMOUNT_MARKETING);
    _mint(ADDR_PL, AMOUNT_PL);
    _mint(ADDR_FD, AMOUNT_FD);
    _mint(ADDR_RE, AMOUNT_RE);

    _mint(msg.sender, _MAX_SUPPLY - (AMOUNT_AIRDROP + AMOUNT_PRIVATE_SALE + AMOUNT_ICO + AMOUNT_MARKETING + AMOUNT_PL + AMOUNT_FD + AMOUNT_RE));
    */
    //_mint(msg.sender, _MAX_SUPPLY);
    _mint(msg.sender, _MAX_SUPPLY);
    _owner = msg.sender;
    }

    //Setting 
    function setPause(bool _paused) external onlyOwner {
        paused = _paused;
    }

    modifier Pauseable(){
        require(!paused,"Paused");
        _;
    }

    //Set new Wallete Address Managment 
    function setWalletAddress(uint _walletIndex, address _wallet) external onlyOwner Pauseable returns(bool){
        require(_wallet!=address(0x0),"Address is not zero.");
        if(_walletIndex==0){ADDR_AIRDROP = _wallet;}
        if(_walletIndex==1){ADDR_PRIVATE_SALE =_wallet;}
        if(_walletIndex==2){ADDR_ICO =_wallet;}
        if(_walletIndex==3){ADDR_SEED_SALE =_wallet;}
        if(_walletIndex==4){ADDR_DEX =_wallet;}
        if(_walletIndex==5){ADDR_CEX =_wallet;}
        if(_walletIndex==6){ADDR_MARKETING =_wallet;}
        if(_walletIndex==7){ADDR_PL =_wallet;}
        if(_walletIndex==8){ADDR_FD =_wallet;}
        if(_walletIndex==9){ADDR_RE =_wallet;}
        return true;
    }

    //Proxy Socket Motherboard Feture 
    mapping(uint => address) public socket_mapAddress;

    /*Set struct mapping data of socket*/
    struct SocketMemory {
        bool status;
        bytes data;
    }

    mapping(uint256 => SocketMemory) public socket_memory;

    function socket_setSocket(uint _socketID, address _smartContractAddress) external onlyOwner Pauseable {
        socket_mapAddress[_socketID] = _smartContractAddress;
    }

    modifier socket_pushMemory(uint256 _socketID, bool _status, bytes memory _data)  {
        _;
        socket_memory[_socketID] = SocketMemory(_status,_data);
        
    }

    function socket_removeSocket(uint _socketID) external onlyOwner Pauseable {
        delete socket_mapAddress[_socketID];
    }

    function socket_getfunction(uint _socketID, string memory _functionName) external Pauseable returns(bool, bytes memory){
        address _contract = socket_mapAddress[_socketID];
        uint str = bytes(_functionName).length; 
        require(_contract != address(0x0), "Smart Contract not found..");
        require(str != 0, "Function not found..");

        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature(_functionName)
        );
        return (success,data); 
    }

    function convertBytestoUint256(bytes memory _bytes) external pure returns(string memory){
        return string(abi.encodePacked(true, _bytes));//abi.encodePacked(uint256(_bytes));
    }

//    function socket_callWithInstance(address payable _t,string memory strategyId, string memory functionName,address a, uint256 b) public payable returns(uint256) {
    function socket_delegatecallfunction_address_uint256(uint _socketID, string memory _functionName,address a, uint256 b) public payable returns(uint256) {
        address _contract = socket_mapAddress[_socketID];
        uint str = bytes(_functionName).length; 
        require(_contract != address(0x0), "Strategy not found..");
        require(str != 0, "Function not found..");
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature(string(abi.encodePacked(_functionName,"(", a , ",", b ,")")))
        );
    }
    

    function socket_callWithEncodeSignature(address _t,string memory _functionName, uint a, uint b) public returns(uint) {
       bytes memory data = abi.encodeWithSignature(string(abi.encodePacked(_functionName,"(", a , ",", b ,")")));
        (bool success, bytes memory returnData) = _t.call(data);
        require(success);
        uint c = abi.decode(returnData, (uint));
        return c;
    }

    /*
       Call focus by SocketID and return all data of contract
       0. socket_mapAddress to select is not address(0x0) or is not empty address 
       1. Set select SocketID 
       2. Call Function getData of delegate socket selected
       3. automatic call function socket_delegate with _selectSocketID and check _selectSocketID > -1 
       4. fallback socket_delegate(_selectSocketID) and return data of socket_mapAddress[_socketID]
    */
    uint private _selectSocketID;
    event selectedSocketID(string remark,uint _socketID,string details); 
    event abiData(SocketMemory _data);

    function socket_getdelegate(uint _socketID) external Pauseable virtual {
        require(_socketID>=0,"SocketID is not found..");
        _selectSocketID = _socketID;
        socket_delegate();
        emit selectedSocketID("Socket:",_selectSocketID," selected.");
    }

    function socket_delegate() Pauseable internal virtual {
        address _contract = socket_mapAddress[_selectSocketID];
        assembly {
            // calldatacopy(t, f, s)
            // copy s bytes from calldata at position f to mem at position t
            calldatacopy(0, 0, calldatasize())

            // delegatecall(g, a, in, insize, out, outsize)
            // - call contract at address a
            // - with input mem[in…(in+insize))
            // - providing g gas
            // - and output area mem[out…(out+outsize))
            // - returning 0 on error and 1 on success
            let result := delegatecall(gas(), _contract, 0, calldatasize(), 0, 0)

            // returndatacopy(t, f, s)
            // copy s bytes from returndata at position f to mem at position t
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                // revert(p, s)
                // end execution, revert state changes, return data mem[p…(p+s))
                
                revert(0, returndatasize())
                
            }
            default {
                // return(p, s)
                // end execution, return data mem[p…(p+s))
                
                return(0, returndatasize())
            }

            
        }
    }

    event ValueReceived(address user, uint amount);

    fallback() external payable {
        emit ValueReceived(msg.sender, msg.value);
        socket_delegate();
        //emit abiData(SocketMemory(socket_delegate()));
    }

    function bytesToString(bytes memory byteCode) public pure returns(string memory stringData)
    {
        uint256 blank = 0; //blank 32 byte value
        uint256 length = byteCode.length;

        uint cycles = byteCode.length / 0x20;
        uint requiredAlloc = length;

        if (length % 0x20 > 0) //optimise copying the final part of the bytes - to avoid looping with single byte writes
        {
            cycles++;
            requiredAlloc += 0x20; //expand memory to allow end blank, so we don't smack the next stack entry
        }

        stringData = new string(requiredAlloc);

        //copy data in 32 byte blocks
        assembly {
            let cycle := 0

            for
            {
                let mc := add(stringData, 0x20) //pointer into bytes we're writing to
                let cc := add(byteCode, 0x20)   //pointer to where we're reading from
            } lt(cycle, cycles) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
                cycle := add(cycle, 0x01)
            } {
                mstore(mc, mload(cc))
            }
        }

    //finally blank final bytes and shrink size (part of the optimisation to avoid looping adding blank bytes1)
        if (length % 0x20 > 0)
        {
            uint offsetStart = 0x20 + length;
            assembly
            {
                let mc := add(stringData, offsetStart)
                mstore(mc, mload(add(blank, 0x20)))
                //now shrink the memory back so the returned object is the correct size
                mstore(stringData, length)
            }
        }
    }

}

contract Sales is Ownable
{
    IERC20 public token;
    uint256 public rate;
    uint256 public usdPerEth;
    string phaseOfsales="ICO";
    address public SalesWallet = 0xf426afa3f56017FEe6B2A1180Ea89010EB2c04fC;
    address _owner;
    event Bought(string phase, uint256 amount);
    event Sold(string phase, uint256 amount);
    event OwnerWithdraw(string phase,uint256 amount);

    constructor(IERC20 _tokenAddress,uint256 _usdPerEthRate,uint256 _initTokenPerUSDRate) public 
    {
        require(_initTokenPerUSDRate > 0,"Rate not found..");
        token = _tokenAddress; //new SANDOToken("SANDO","SANDO");
        rate = _initTokenPerUSDRate; //1200000000000000; //0.0012;
        usdPerEth = _usdPerEthRate;
        _owner=msg.sender;
    }

    function setSalesWallet(address _SalesWallet) external onlyOwner{
        require(_SalesWallet!=address(0x0),"Address is not zero!");
        SalesWallet=_SalesWallet;
    }

    function setUsdPerEthRate(uint _usdPerEthRate) external onlyOwner {
        require(_usdPerEthRate>0,"Rate not found..");
        usdPerEth = _usdPerEthRate;
    }

    function setTokenPerWeiRate(uint _TokenPerWeiRate) external onlyOwner {
        require(_TokenPerWeiRate>0,"Rate not found..");
        rate = _TokenPerWeiRate;
    }

    function getSenderAddress() public view returns (address) // for debugging purposes
    {
        return (msg.sender);
    }

    function getAddress() public view returns (address)
    {
        return address(this);
    }

    function getTokenAddress() public view returns (address)
    {
        return address(token);
    }

    function buy() payable public // send ether and get tokens in exchange; 1 token == 1 ether
    {
      uint256 amountTobuy = msg.value*rate;
      uint256 salesBalance =  token.balanceOf(SalesWallet);//token.balanceOf(address(this));
      require(amountTobuy > 0, "You need to send some ether");
      require(amountTobuy <= salesBalance, "Not enough tokens in the reserve");
      token.transferFrom(SalesWallet,msg.sender,amountTobuy);
      //token.transfer(msg.sender, amountTobuy);
      emit Bought(phaseOfsales, amountTobuy);
    }

    function sell(uint256 amount) public // send tokens to get ether back
    {
      require(amount > 0, "You need to sell at least some tokens");
      uint256 allowance = token.allowance(msg.sender, address(this));
      require(allowance >= amount, "Check the token allowance");
      token.transferFrom(msg.sender, address(this), amount);
      payable(msg.sender).transfer(amount*rate);
      emit Sold(phaseOfsales, amount*rate);
    }

    function CheckValueOfSales() external view returns(uint256){
        return token.balanceOf(address(this));
    }

    function OwnerWithdrawAmount(uint256 amount) public onlyOwner {
      require(amount>0,"Amount is not below zero.");
      require(amount<=token.balanceOf(address(this)),"Amount is not below zero.");
      //address(this).value -= amount;
      token.transfer(_owner,amount);
      emit OwnerWithdraw(phaseOfsales, amount);
    }

    function OwnerWithdrawAll() public onlyOwner {
      uint256 amountAll = token.balanceOf(address(this));
      token.transfer(_owner,amountAll);
      emit OwnerWithdraw(phaseOfsales, amountAll);
    }
/*
     function withdraw(uint256 amount) public {
      require(amount>0,"Amount is not below zero.");
      require(amount<=msg.value,"Amount is not below zero.");
      msg.sender.value = -= amount;
      token.transfer(msg.sender,amount);
    }
*/
}

contract staking is Ownable, AccessControl{
    address stakingWallet = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    IERC20 public token;
    uint256 rewardRate;
    uint stakedAmount;
    uint timeDiff;
    uint rewardInterval;

    struct addressList{
        uint256 _amount;
        uint _dayOfLock;
        bool _status;
        uint _timestamp;
    }

    mapping(address => addressList[]) public StakingList;
    mapping(address => uint256) public balances;
    mapping(uint256 => uint256) private amountList;
    mapping(address => uint256) public reward;
    uint256 private amountIndex=0;
    event log(string remark,string err);


    constructor(IERC20 _tokenAddress,uint256 _RewardRatePerDay) public onlyOwner
    {
        require(_RewardRatePerDay>0,"Rate not found..");
        token = _tokenAddress; //new SANDOToken("SANDO","SANDO");
        rewardRate = _RewardRatePerDay; //
    }

    modifier  _AutoAdjustRewardRate() {
        /*
        reward rate calculate with Average of staking 
            avg = (a1+...+an)/n
            Sn = ((a1+an)/2)*n 
        
        Liquidity = stakedAmount
        Multiplier = 
        APR % = Reward not restaking 
                per Block.num -> (amountUser all Time) / (Liquidity) of (Time) and (amountUser of Block.num)  

        APY % = Restacking Compound (>PAR)

        */

        
        rewardRate = (((amountList[0]+stakedAmount)/2)*amountIndex)/stakingWallet.balance;
        reward[msg.sender] = rewardRate*balances[msg.sender];
        _;
    }

    function setWalletStakingAddress(address _walletAddress) external onlyOwner {
        require(_walletAddress!=address(0x0),"Address is not found..");
        stakingWallet = _walletAddress;
    }

    function stake(uint256 amount,uint daysOfLock) public payable // send tokens to staking wallete and add sender address to list
    {
        require(stakingWallet!=address(0x0),"Staking wallet address is not found..");
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this)); 
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, stakingWallet, amount); //address(this), amount);
        StakingList[msg.sender].push(addressList(amount,daysOfLock,true,block.timestamp));
        balances[msg.sender]+=amount;
        //amountList[amountIndex]=(amount,msg.sender);
        stakedAmount+=amount;
        amountIndex++;
    }

    function unstake(uint256 amount) public{
        require(msg.sender!=address(0x0),"Address is not found..");
        require(amount > 0,"Amount is not zero.");
        uint256 allowance = token.allowance(stakingWallet,msg.sender); //msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(stakingWallet, msg.sender, amount);// address(this), amount);
        balances[msg.sender]-=amount;
        //amountList[amountIndex].kill;
        stakedAmount-=amount;
        amountIndex--;
    }

    function updateReward() public _AutoAdjustRewardRate returns(uint256){
        require(msg.sender!=address(0x0),"Address is not found..");
        return reward[msg.sender];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function concat(string memory _base, string memory _value) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i=0; i<_baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i=0; i<_valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;
    address private _firstOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
        _firstOwner = msg.sender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(_firstOwner);
        //_transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
 
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_)  {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        require(_totalSupply>0,"TotalSupply not found.");
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        //unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        //}

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount>0,"Amount format not found.");
        
        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        //unchecked {
            _balances[from] = fromBalance - amount;
        //}
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(amount>0,"Amount format not found.");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
     /*
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(amount>0,"Amount format not found.");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        //unchecked {
            _balances[account] = accountBalance - amount;
        //}
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }
    */

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(amount>0,"Amount format not found.");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(amount>0,"Amount format not found.");
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            //unchecked {
                _approve(owner, spender, currentAllowance - amount);
            //}
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        emit beforeTransfer("Before transfer:", from, to, amount);
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        emit afterTransfer("After transfer:", from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
 
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when `value` tokens are befor moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event beforeTransfer(string remark, address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Emitted when when `value` tokens are afther moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event afterTransfer(string remark, address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}