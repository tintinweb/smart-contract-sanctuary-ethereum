/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

pragma solidity ^0.6.12;

//import "https://github.com/ApeSwapFinance/apeswap-banana-farm/blob/master/contracts/BananaToken.sol";
//import "https://github.com/pancakeswap/pancake-swap-lib/blob/master/contracts/token/BEP20/IBEP20.sol";
interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BananaBurner{
    struct Details {
          uint256 _totalBurned;
        uint256 _burnTime;
        uint256 _lastBurnAmount;
        uint8 _decimals;
        address _tokenContract;
        string _name;
        string _symbol;
    }
    mapping (address => Details) public burnDetails;
    uint256  public burnTime;
    uint256  public amountToBurn;
    uint256  public totalBurned;
    uint256  public lastBurnAmount;
    uint256  public  burnedBlockNum;   
    address public BananaAddre;
    address public burner;
    constructor(address payable _tokenAddress) public {
        BananaAddre= _tokenAddress;
        burner= msg.sender;
    }
    
    
    function depositBanana(uint256 amount)public  {
             IBEP20(BananaAddre).transfer(address(this),amount);
             amountToBurn+=amount;
    }
        function getTokenCOntractAddress() public view returns (address){
            return BananaAddre;
        }
    function transferTo0xDead(uint256 amount) internal{
        IBEP20(BananaAddre).approve(msg.sender,amount);
        IBEP20(BananaAddre).transfer(0x000000000000000000000000000000000000dEaD,amount);
        }
        function burnerAdress() public view returns (address){
            return address(this);
        }
    
    function burnApe(uint256 _amount) public {
         transferTo0xDead(_amount);
         totalBurned+=_amount;
         burnTime= now;
        burnDetails[BananaAddre]._totalBurned= totalBurned;
        burnDetails[BananaAddre]._burnTime=burnTime=burnTime;
        burnDetails[BananaAddre]._lastBurnAmount=lastBurnAmount;
        burnDetails[BananaAddre]._decimals=getDecimal();
        burnDetails[BananaAddre]._tokenContract=getOwner();
        burnDetails[BananaAddre]._name= getName();
        burnDetails[BananaAddre]._symbol=getSymbol();
               }
    function getOwner() public view returns(address) {
        return IBEP20(BananaAddre).getOwner();
    }
    function getName() public view returns(string memory) {
        return IBEP20(BananaAddre).name();
    }
       function getSymbol() public view returns(string memory) {
        return IBEP20(BananaAddre).symbol();
    }
    function getDecimal() public view returns(uint8) {
        return IBEP20(BananaAddre).decimals();
    }
   
    function getTotalSupply() public view returns(uint256) {
        return IBEP20(BananaAddre).totalSupply();
    }
    function BanlanceOF()public view returns(uint256){
        return IBEP20(BananaAddre).balanceOf(msg.sender);
    }
    function getContractTokenAmount() public view returns(uint256){
        return IBEP20(BananaAddre).balanceOf(address(this));
    }
}