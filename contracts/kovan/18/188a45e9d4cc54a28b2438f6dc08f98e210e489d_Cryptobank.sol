/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}
interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}
// File: Cryptobank.sol


pragma solidity ^0.8.0;

contract Cryptobank {
    AggregatorV3Interface priceFeed= AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    IERC20 Token=IERC20(0xc717B38Fb94Ba98B00872e544E6710A2750F4CdE);
    struct Lendinfo{
        uint256 index;
        uint256 lendtime;
        uint256 closetime;
        uint256 amount;
        uint256 months;
        address lenderaddress;
        address borroweraddress;
        uint256 finalamountforlender;
        uint256 finalamountforborrower;
        bool isBorrowed;
        bool isReturned;
        uint256 collateral;
    }
    mapping(address=>Lendinfo) public lenddata;
    Lendinfo[] public totallenddata;
    uint256 public totalLendamount;
    uint256 public currentIndex;
//      function getLatestPrice() public view returns (int) {
//      (
//         uint80 roundID, 
//         int price,
//          uint startedAt,
//          uint timeStamp,
//         uint80 answeredInRound
//     ) = priceFeed.latestRoundData();
//     return price;
// }
function getLatestPrice() public view returns (int) {
    (
        uint80 roundID, 
        int price,
        uint startedAt,
        uint timeStamp,
        uint80 answeredInRound
    ) = priceFeed.latestRoundData();
    return price/100000000;
}
    function lend(uint256 amount, uint256 months) public {
        require(
            months == 1 ||
                months == 3 ||
                months == 6 ||
                months == 9 ||
                months == 12
        );
        uint USDallowedAmt=Token.allowance(msg.sender,address(this));
        require(amount<=USDallowedAmt,"Please approve from usd contract");
        //allowance statement check was missing(tarun change)
        require(amount>0,"enter valid amount");
         bool transfer=Token.transferFrom(msg.sender,address(this),amount);
          require(transfer==true,"amount not transferred");
        totalLendamount+=amount;
        currentIndex=totallenddata.length;
        totallenddata.push(
            Lendinfo(
                totallenddata.length,
                block.timestamp,
                block.timestamp+months*30,
                amount,
                months,
                msg.sender,
                address(this),
                amount+(amount*3*months)/1200,
                amount+(amount*5*months)/1200,
                false,
                false,
                0
            )
        );
        
    }
    function balanceOf() public view returns(uint256){
        return Token.balanceOf(address(this));
    }
    function borrow(uint256 index) payable public{
        uint ethusd=uint(getLatestPrice())*(msg.value/10^18);
        uint payableprice=totallenddata[index].amount+(totallenddata[index].amount*20)/100;
        require(ethusd>=(payableprice/10^20),"enter correct amount");
        uint256 amount = totallenddata[index].amount;
        require(index<totallenddata.length,"invalid index");
        require(totallenddata[index].isBorrowed==false,"already borrowed");
        require(totallenddata[index].lenderaddress!=msg.sender,"you can t borrow your own lending");
        bool transfer=Token.transfer(msg.sender,amount);
        require(transfer==true,"amount not transferred");
        totallenddata[index].borroweraddress=msg.sender;
        totallenddata[index].isBorrowed=true;
        totallenddata[index].lendtime=block.timestamp;
        totallenddata[index].closetime=block.timestamp+totallenddata[index].months*30;
        totallenddata[index].collateral+=msg.value;
        totalLendamount-=amount;
    }
    function balanceOF() public view returns(uint256){
        return address(this).balance;
    }
    function withdraw(uint256 index) public {
        require(msg.sender==totallenddata[index].lenderaddress);
        uint time = totallenddata[index].closetime;
        require(block.timestamp > time,"time not completed yet");
        bool check=totallenddata[index].isReturned;
        if(check==true){
            uint256 amount=totallenddata[index].finalamountforlender;
            bool transfer=Token.transfer(msg.sender,amount);
        require(transfer==true,"amount not transferred");
        }else{
            require(totallenddata[index].collateral>0,"already received collatreal");
            address payable receiver = payable(msg.sender);
   receiver.transfer(totallenddata[index].collateral-1);
   totallenddata[index].collateral=0;
//    totallenddata[index].isLost==true;
        }
    }
    function payback(uint256 index) public {
        require(Token.balanceOf(msg.sender)>=totallenddata[index].finalamountforborrower,"Balance is low");
        require(totallenddata[index].isReturned==false,"already returned");
        require(totallenddata[index].collateral>0,"already received collatreal");
        require(msg.sender==totallenddata[index].borroweraddress,"you have not borrowed");
         uint USDallowedAmt=Token.allowance(msg.sender,address(this));
         require(totallenddata[index].amount<=USDallowedAmt,"Please approve from usd contract");
        //allowance statement check was missing(tarun change)
        bool transfer=Token.transferFrom(msg.sender,address(this),totallenddata[index].finalamountforborrower);
        require(transfer==true,"not transfered");
        totallenddata[index].isReturned=true;   
   address payable receiver = payable(msg.sender);
   receiver.transfer(totallenddata[index].collateral-1);
    }
    function viewalldata() public view returns(Lendinfo[] memory){
        Lendinfo[] storage ret=totallenddata;
        return ret;
    }
    function withdrawlendamount(uint index) public returns(bool){
        require(msg.sender==totallenddata[index].lenderaddress,"U are not lender");
        require(totallenddata[index].isBorrowed==false,"already borrowed");
         bool transfer=Token.transfer(msg.sender,totallenddata[index].amount);
        require(transfer==true,"amount not transferred");
        return true;
    }
}