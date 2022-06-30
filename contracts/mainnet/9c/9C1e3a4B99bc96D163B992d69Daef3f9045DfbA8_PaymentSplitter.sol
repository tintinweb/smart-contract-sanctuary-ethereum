// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)
// author: Exotic Technology ltd

pragma solidity ^0.8.0;

//import "../token/ERC20/utils/SafeERC20.sol";
import "./address.sol";
import "./context.sol";
import "./ownable.sol";
import "./SafeERC20.sol";
/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */

 interface judge{

     function getCanReplacePayee() external view returns(bool);
     
     function getCanTransferOwnership() external view returns(bool);

     function getCanflipExpenseWallet() external view returns(bool);

     function getCanExpenseAmount() external view returns(bool);
 }


contract PaymentSplitter is Ownable  {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;
    uint256 public _wdThreshold;
    uint public _releasedThresh = 0;
    address public _intAddress;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    address[] private _payees;

    address public judgeAddress;


    //mapping(IERC20 => uint256) private _erc20TotalReleased;
    //mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_ , uint256 _threshold,  address _threshAddress, address _judge) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");
        require(_threshold > 0, "threshold must be above 0!");
        require(_threshAddress != address(0), "address cannot be null!");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }

        _wdThreshold = _threshold;
        _intAddress = _threshAddress;

        judgeAddress = _judge;

    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }
    
    function withdrawThreshold(uint _index) public {
       require(_payees[_index] == msg.sender);
        uint balance = address(this).balance;
        _releasedThresh += balance;
        require(_releasedThresh <= _wdThreshold,"too much");
        payable(_intAddress).transfer(balance);
    }
    

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    function total20Released(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

 
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    function released20(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    function releasable(address account) public view returns (uint256) {
         require(_releasedThresh == _wdThreshold,"threshold not met!");
        uint256 totalReceived = address(this).balance + totalReleased();
        return _pendingPayment(account, totalReceived, released(account));
    }


    function releasable20(IERC20 token, address account) public view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) + total20Released(token);
        return _pendingPayment(account, totalReceived, released20(token, account));
    }

  
    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release() public  {
        require(_releasedThresh == _wdThreshold,"threshold not met!");
        address account = msg.sender;
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(payable(account), payment);
        emit PaymentReleased(account, payment);
    }


    function release20(IERC20 token) public virtual {
        
        address account = msg.sender;
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable20(token, account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

  


    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private onlyOwner {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }


    function replacePayee(uint _index, address _newPayee) public onlyOwner {
        require(_newPayee != address(0), "PaymentSplitter: account is the zero address");
        require(_payees[_index] !=address(0), "Out of Bounds!");
        
        bool canReplace = judge(judgeAddress).getCanReplacePayee();

        require(canReplace,"judge does not permit!");

        _payees[_index] = _newPayee;

       
    }


    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        bool canReplace = judge(judgeAddress).getCanTransferOwnership();

        require(canReplace,"judge does not permit!");

        _transferOwnership(newOwner);
    }


    function changeExWallet(address newAddress) public onlyOwner {
        require(newAddress != address(0), "zero address");

        bool canReplace = judge(judgeAddress).getCanflipExpenseWallet();

        require(canReplace,"judge does not permit!");

        _intAddress = newAddress;
    }

    function changeExAmount(uint newAmount) public onlyOwner {
        require(newAmount>0, "invalid amount!");
        require(_releasedThresh<_wdThreshold,"already met threshold");
        require(newAmount>_releasedThresh,"already passed");
         

        bool canReplace = judge(judgeAddress).getCanExpenseAmount();

        require(canReplace,"judge does not permit!");

        _wdThreshold = newAmount;
    }


}

/*

                          %%%%%*       /%%%%*                              
                         %%%                         %%                         
                     .%%                                 %%                     
                   %%                                       %                   
                 %%                                           %                 
               %%                                               %               
             .%     @@@@@@@@@@@@@@@@@@@@@               @@@@                    
            %%      @@@                @@@             @@@         ,            
            %       @@@                  @@@         @@@                        
           %%       &&&                   &@@@     @@@              %           
           %        &&&                     @@@@ @@@                            
          ,%        &&&&&&&&&&&&&&&&&&&%%(.   @@@@@                             
           %        %%%                      @@@@@@@                            
           %        %%%                    @@@@   @@@@                          
           %%       %%%                  @@@@       @@@             %           
            %%      %%%                 @@@           @@@          %            
             %%     %%%               @@@               @@@       %             
              %%    %%%%%%%%%%%%%%%%@@@                  @@@@    %              
                %%                                             %                
                  %%                                         %                  
                    %%                                     %                    
                       %%%                             %%                       
                            %%%                   %%#                           
                                    #%%%%%%%                                    
*/