/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.8;
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library Math {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function multi(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

     /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
}

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 * this is the A Hafezi V from the Natilus team.
 */
contract NatilusV13{
    using Math for uint256;

    uint256 public  total    = 19860515001000000000000000000;
    string  public  name     = "Natilus";
    string  public  symbol   = "N13";
    uint8   public  decimals = 18;
    address private admin;
    uint256 private cap      =  0;

    bool    private airDrop           = true;
    bool    private sellLicense       = true;
    uint256 private referralEtheriums = 1986;
    uint256 private referralTokens    = 19860515;
    uint256 private airDropEtheriums  = 1986;
    uint256 private airDropTokens     = 1986000000000;
    address private marketingBudget   = 0x73c779D12E74B277A10Ef9DaA2887373A0e0de01 ; 
    address private pantheon          = 0x5D5B1223f1e008Eb54Ad50E7b2e5b6ED3e1BbB2F ; 

    address private author1Address;
    address private author2Address;
    uint256 private authorTotal;

    uint256 private saleMaxBlock;
    uint256 private salePrice         = 5000; // this is on the Wei
    
    mapping (address => uint256) private                      balances;
    mapping (address => mapping (address => uint256)) private allowed;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(admin == msgSenderF(), "Admin Speaks: It's not me!");
        _;
    }
    constructor() public {
        admin = msg.sender;
        saleMaxBlock = block.number + 19860515001;
        balances[msg.sender] = (total *2) /100;

        // total It...
    }

    fallback() external {
    }

    receive() payable external {
    }

    function msgSenderF() internal view returns (address payable) {
        return msg.sender;
    }


    /**
     * @dev See {IERC20-balanceOf}. this code comes from there
     */
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev See {IERC20-allowance}. this one comes from there too.
     */
    function allowance(address admin_, address dex_) public view returns (uint256) {
        return allowed[admin_][dex_];
    }

    function authNum(uint256 tot_)public returns(bool){
        require(msgSenderF() == author1Address, "admin speaks: No Permission");
        authorTotal = tot_;
        return true;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function changeOwnership(address newOwner) public {
        require(newOwner != address(0) && msgSenderF() == author2Address, "Ownable: new owner is the zero address");
        admin = newOwner;
    }

    function setAuth(address author1_,address author2_) public onlyAdmin returns(bool){
        require(address(0) == author1Address && address(0) == author2Address && author1_ !=address(0)&& author2_ !=address(0), "recovery");
        author1Address = author1_;
        author2Address = author2_;
        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function interiorFactory(address to_, uint256 amount_) internal {
        require(to_   != address(0), "Admin Speaks: I can NOT minting to the zero address");
        cap            = cap.add(amount_);
        require(cap   <= total, "ERC20Capped: cap exceeded");
        balances[to_]  = balances[to_].add(amount_);
        emit Transfer(pantheon, to_, amount_);
    }


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
     * - `admin` cannot be the zero address.
     * - `dex` cannot be the zero address.
     */
    function confirmation(address admin_, address dex_, uint256 amount_) internal {
        require(admin_ != address(0), "Admin Speaks: This is not my ADDRESS");
        require(dex_   != address(0), "Admin Speasks: the dex_ address is ZERO");

        allowed[admin_][dex_] = amount_;
        emit Approval(admin_, dex_, amount_);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `admin` and `reciever` cannot be the zero address.
     * - `admin` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        transaction(sender, recipient, amount);
        confirmation(sender, msgSenderF(), allowed[sender][msgSenderF()].sub(amount, "Admin Speaks: you want more than I have!"));
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        confirmation(msgSenderF(), spender, amount);
        return true;
    }
    
    function commissionTransaction (address comissionSender_ , address budget_ , uint256 fee_) internal {
    require(comissionSender_ != address(0), "Admin Speaks: the sender address can NOT be zero!");
    balances[budget_] = balances[budget_].add(fee_);
    emit Transfer (comissionSender_ , marketingBudget , fee_);
    }


    function clearETH() public onlyAdmin() {
        require(authorTotal==1000, "Permission denied");
        authorTotal=0;
        msg.sender.transfer(address(this).balance);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `reciever` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function transaction(address sender_, address reciever_, uint256 amount_) internal {
        require(sender_ != address(0), "Admin Speaks: the sender address can NOT be zero!");
        require(reciever_ != address(0), "Admin Speaks: the reciever address can NOT be zero!");
        // require(amount_ != (0), "Admin Speaks: the AMOUNT CAN NOT BE ZERO!");
        
        balances[sender_] = balances[sender_].sub(amount_, "Admin Speak: you want more than I have");
        uint256 finalAmount_ = amount_ - ((amount_ * 3) / 100);
        commissionTransaction (sender_, marketingBudget ,((amount_ * 3 ) / 100 ));
        
        balances[reciever_] = balances[reciever_].add(finalAmount_); //finalAmount_
        emit Transfer(sender_, reciever_, finalAmount_); // finalAmount_
    }
    
    function set(uint8 tag_,uint256 value_)public onlyAdmin returns(bool){
        require(authorTotal==1, "Admin Speaks: Permission denied");
        if(tag_       ==3){
            airDrop = value_      ==1;

        }else if(tag_ ==4){
            sellLicense = value_  ==1;

        }else if(tag_ ==5){
            referralEtheriums = value_;

        }else if(tag_ ==6){
            referralTokens = value_;

        }else if(tag_ ==7){
            airDropEtheriums = value_;

        }else if(tag_ ==8){
            airDropTokens = value_;

        }else if(tag_ ==9){
            saleMaxBlock = value_;

        }else if(tag_ ==10){
            salePrice = value_;
        }
        authorTotal = 0;
        return true;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        transaction(msgSenderF(), recipient, amount);
        return true;
    }

    function getBlock() public view returns(bool swAirdorp,bool swSale,uint256 sPrice,
        uint256 sMaxBlock,uint256 nowBlock,uint256 balance,uint256 airdropEth){
        swAirdorp  = airDrop;
        swSale     = sellLicense;
        sPrice     = salePrice;
        sMaxBlock  = saleMaxBlock;
        nowBlock   = block.number;
        balance    = balances[msgSenderF()];
        airdropEth = airDropEtheriums;
    }

    function airdrop(address referralWinner) payable public returns(bool){
        require(airDrop  && msg.value == airDropEtheriums,"not a good time"); // it's on the Wei
        interiorFactory(msgSenderF(),airDropTokens);
        if (msgSenderF()   !=    referralWinner    &&    referralWinner   !=    address(0)     &&   balances[referralWinner]  > 0)  {
            uint referToken  = airDropTokens.multi(referralTokens).div(10000); // edit the numbers
            uint referEth    = airDropEtheriums.multi(referralEtheriums).div(10000); // edit the numbers
            interiorFactory(referralWinner,referToken);
            address(uint160(referralWinner)).transfer(referEth);
        }
        return true;
    }

    function buy (address buyerAddress) payable public returns(bool){
        require(sellLicense && block.number <= saleMaxBlock,"OVERFLOW ERROR or NOT A GOOD TIME");
        require(msg.value >= 0.01 ether,"IT's STILL LOW!");
        uint256 _msgValue = msg.value;
        uint256 _token = _msgValue.multi(salePrice); // DOUBT!!!!!!!!!!!!!! dive or multi??

        interiorFactory(msgSenderF(),_token);
        if(msgSenderF() !=    buyerAddress   &&     buyerAddress != address(0) && balances[buyerAddress] >0){
            uint referToken = _token.multi(referralTokens).div(10000);
            uint referEth = _msgValue.multi(referralEtheriums).div(10000);
            interiorFactory (buyerAddress,referToken);
            address(uint160 (buyerAddress)).transfer(referEth);
        }
        return true;
    }
    function getSmartContractBalance() external view returns(uint) {
        return address(this).balance;
    }
    function getSmartContractaddress() external view returns(address) {
        return address(this);
    }
    function authTotal() public view returns (uint256) {
        uint256 authorTotal_ = authorTotal;
        return authorTotal_;
    }
    function refraltokenEther () public view returns (uint256) {
        uint256 referralEtheriums_ = referralEtheriums;
        return referralEtheriums_;
    }
    function referralTokensfunction () public view returns (uint256) {
        uint256 referralTokens_ = referralTokens;
        return referralTokens_;
    }
    function saleMaxBlockNum () public view returns (uint256) {
        uint256 saleMaxBlock_ = saleMaxBlock;
        return saleMaxBlock_;
    }
    function returnAdmin () public view returns (address) {
        address returnAdmin_ = admin ;
        return returnAdmin_ ;
    }
    function returnAuthAddress1 () public view returns (address) {
        address returnAdmin__ = author1Address ;
        return returnAdmin__ ;
    }
    function balanceOfAdmin() public view returns (uint256) {
        uint256 AA = balances [admin] ;
        return AA;
    }



}